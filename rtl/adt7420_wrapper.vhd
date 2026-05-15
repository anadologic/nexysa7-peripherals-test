library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use work.periph_pkg.all;

entity adt7420_wrapper is
generic (
c_clkfreq 		: integer := 100_000_000;
c_i2cfreq 		: integer := 400_000
);
port (
clk             : in std_logic;
rstn            : in std_logic;
start_temp_i    : in std_logic;
stop_temp_i     : in std_logic;
temp_o          : out std_logic_vector (12 downto 0);
temp_valid_o    : out std_logic;
sda_io          : inout std_logic;
scl_io          : inout std_logic
);
end adt7420_wrapper;

architecture rtl of adt7420_wrapper is

signal ena                  : std_logic := '0';
signal ack_error            : std_logic := '0';
signal rw                   : std_logic := '0';
signal busy                 : std_logic := '0';
signal addr                 : std_logic_vector(6 DOWNTO 0) := "1001011";
signal data_wr              : t_byte := ZEROS(8);
signal data_rd              : t_byte := ZEROS(8);

constant c_timer250mslim    : integer := c_clkfreq/4-1;
signal timer250mstick       : std_logic := '0';
signal timer250ms           : integer range 0 to c_timer250mslim := 0;

signal busyPrev : std_logic := '0';
signal waitEn   : std_logic := '0';
signal busyCntr : integer range 0 to 7 := 0;

constant c_timer2uslim    : integer := c_clkfreq/500_000-1;
signal timer2us : integer range 0 to c_timer2uslim := 0;

signal state                : t_state_adt7420 := S_POWERON;

begin

i_i2c_master : entity work.i2c_master
GENERIC map (
input_clk => c_clkfreq,
bus_clk   => c_i2cfreq
)
PORT map(
clk       => clk,
reset_n   => rstn,
ena       => ena,
addr      => addr,
rw        => rw,
data_wr   => data_wr,
busy      => busy,
data_rd   => data_rd,
ack_error => ack_error,
sda       => sda_io,
scl       => scl_io
);

process (clk) begin
if rising_edge(clk) then
if rstn = '0' then
    state       <= S_POWERON;
    busyPrev    <= '0';
    ena         <= '0';
    rw          <= '0';
    waitEn      <= '0';
    busyCntr    <= 0;
    timer2us    <= 0;
    data_wr     <= ZEROS(8);
else

    case state is 
    when S_POWERON =>
        if (timer250mstick = '1') then 
            state <= S_IDLE;
        end if;

    when S_IDLE =>

        if (start_temp_i = '1') then 
            state <= S_I2CWR;
        end if;

    when S_I2CWR =>

        busyPrev	<= busy;        
        if (busyPrev = '0' and busy = '1') then
            busyCntr <= busyCntr + 1;
        end if;		    

        if (busyCntr = 0 and waitEn = '0') then		-- first byte write
            ena 	<= '1';
            rw		<= '0';		-- write
            data_wr	<= x"00";	-- temperature MSB
        elsif (busyCntr = 1) then
            ena 	<= '0';
            if (busy = '0') then
                waitEn		<= '1';
                busyCntr	<= 0;				
            end if;						
        end if;

        if (waitEn = '1') then 
            timer2us <= timer2us + 1;
            if (timer2us = c_timer2uslim) then 
                timer2us    <= 0;
                waitEn      <= '0';
                state       <= S_I2CRD;
                busyCntr	<= 0;
            end if;
        end if;

        if (stop_temp_i = '1') then 
            state           <= S_IDLE;
            temp_valid_o    <= '0';
            busyCntr		<= 0;
            ena 	        <= '0';
            timer2us        <= 0;
            waitEn          <= '0';
            busyCntr	    <= 0;
        end if;

    when S_I2CRD =>

        busyPrev	<= busy;
        if (busyPrev = '0' and busy = '1') then
            busyCntr <= busyCntr + 1;
        end if;		
        
        temp_valid_o <= '0';
        if (busyCntr = 0) then		
            ena 	<= '1';
            rw		<= '1';		-- read
            data_wr	<= x"00";	
        elsif (busyCntr = 1) then	-- read starts
            if (busy = '0') then
                temp_o(12 downto 5)	<= data_rd;
            end if;					
            rw 		<= '1';
        elsif (busyCntr = 2) then	-- data read
            ena	<= '0';
            if (busy = '0') then
                temp_o(4 downto 0)	<= data_rd(7 downto 3);
                temp_valid_o        <= '1';
                busyCntr			<= 0;
            end if;						
        end if;

        if (stop_temp_i = '1') then 
            state           <= S_IDLE;
            temp_valid_o    <= '0';
            busyCntr		<= 0;
            ena 	        <= '0';
        end if;

    when others =>
    end case;
    
end if;
end if;
end process;

process (clk)
begin
if rising_edge(clk) then
if rstn = '0' then
    timer250mstick  <= '0';
    timer250ms      <= 0;
else
    timer250mstick  <= '0';
    timer250ms <= timer250ms + 1;
    if (timer250ms = c_timer250mslim) then 
        timer250mstick  <= '1';
        timer250ms      <= 0;
    end if;
    if (start_temp_i = '1') then 
        timer250ms      <= 0;
        timer250mstick  <= '0';
    end if;
end if;
end if;
end process;

end rtl;