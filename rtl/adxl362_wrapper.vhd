library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use work.periph_pkg.all;

entity adxl362_wrapper is
generic (
c_clkfreq 		: integer := 100_000_000;
c_sclkfreq 		: integer := 1_000_000;
c_cpol			: std_logic := '0';
c_cpha			: std_logic := '0'
);
port (
clk         : in std_logic;
rstn        : in std_logic;
start_acc_i : in std_logic;
stop_acc_i  : in std_logic;
accx_o      : out std_logic_vector (15 downto 0);
accy_o      : out std_logic_vector (15 downto 0);
accz_o      : out std_logic_vector (15 downto 0);
acc_valid_o : out std_logic;
cs_o 		: out std_logic;
sclk_o 		: out std_logic;
mosi_o 		: out std_logic;
miso_i 		: in  std_logic
);
end adxl362_wrapper;

architecture Behavioral of adxl362_wrapper is

signal en_spi       : std_logic := '0';
signal data_ready   : std_logic := '0';
signal mosi_data    : t_byte := ZEROS(8);
signal miso_data    : t_byte := ZEROS(8);

signal state        : t_state_adxl362 := S_POWERON;
signal cntr         : integer range 0 to 255 := 0;
constant c_timer100ms_lim   : integer := c_clkfreq/10-1;
signal timer100ms   : integer range 0 to c_timer100ms_lim := 0;
signal timer_event : std_logic := '0';
signal timer_enable: std_logic := '0';

begin

spi_master_i : entity work.spi_master
generic map (
c_clkfreq 		=> c_clkfreq 	,
c_sclkfreq 		=> c_sclkfreq 	,
c_cpol			=> c_cpol		,
c_cpha			=> c_cpha		
)
Port map ( 
clk_i 			=> clk,
en_i 			=> en_spi,
mosi_data_i 	=> mosi_data,
miso_data_o 	=> miso_data,
data_ready_o 	=> data_ready,
cs_o 			=> cs_o,
sclk_o 			=> sclk_o,
mosi_o 			=> mosi_o,
miso_i 			=> miso_i
);

-- Independent 100 ms timer process
process (clk) begin
if rising_edge(clk) then
    if rstn = '0' then
        timer100ms  <= 0;
        timer_event <= '0';
    else
        if timer_enable = '1' then
            if timer100ms = c_timer100ms_lim then
                timer100ms  <= 0;
                timer_event <= '1';
            else
                timer100ms  <= timer100ms + 1;
                timer_event <= '0';
            end if;
        else
            timer100ms  <= 0;
            timer_event <= '0';
        end if;
    end if;
end if;
end process;

process (clk) begin
if rising_edge(clk) then
if rstn = '0' then
    state        <= S_POWERON;
    cntr         <= 0;
    timer_enable <= '0';
    en_spi       <= '0';
    acc_valid_o  <= '0';
    mosi_data    <= ZEROS(8);
    accx_o       <= ZEROS(16);
    accy_o       <= ZEROS(16);
    accz_o       <= ZEROS(16);
else
    
    case state is
    when S_POWERON =>
        if (cntr = 0) then
            en_spi 		<= '1';
            mosi_data	<= c_wr_cmd;	-- write command to ADXL362
            if (data_ready = '1') then
                mosi_data	<= c_power_ctl;	-- POWER_CTL register address
                cntr		<= cntr + 1;
            end if;
        elsif (cntr = 1) then
            if (data_ready = '1') then
                mosi_data	<= c_meas_mode;	-- enable measurmenet mode
                cntr		<= cntr + 1;
            end if;					
        elsif (cntr = 2) then
            if (data_ready = '1') then
                cntr		<= 0;
                en_spi		<= '0';
                state		<= S_IDLE;
            end if;
        end if;        
    when S_IDLE =>
        acc_valid_o			<= '0';
        timer_enable           <= '0';
        if (start_acc_i = '1') then
            timer_enable <= '1';
            state        <= S_TIMER;
        end if;
    when S_TIMER =>
        acc_valid_o            <= '0';
        if (timer_event = '1') then
            state <= S_READDEVICE;
        end if;
        if (stop_acc_i = '1') then
            en_spi       <= '0';
            timer_enable <= '0';
            state        <= S_IDLE;
            cntr         <= 0;
        end if;
    when S_READDEVICE =>
        if (cntr = 0) then
            en_spi 	    <= '1';
            mosi_data	<= c_rd_cmd;	-- read command to ADXL362
            if (data_ready = '1') then
                mosi_data	<= c_xdata_l;	-- XDATA_L register address
                cntr		<= cntr + 1;
            end if;		
        elsif (cntr = 1) then
            if (data_ready = '1') then
                mosi_data			<= x"00";	-- in continious read mode, only first address is enough
                cntr				<= cntr + 1;
            end if;	
        elsif (cntr = 2) then
            if (data_ready = '1') then
                cntr				<= cntr + 1;
                accx_o(7 downto 0)  <= miso_data;
            end if;
        elsif (cntr = 3) then
            if (data_ready = '1') then
                cntr				<= cntr + 1;
                accx_o(15 downto 8) <= miso_data;
            end if;		
        elsif (cntr = 4) then
            if (data_ready = '1') then
                cntr				<= cntr + 1;
                accy_o(7 downto 0)  <= miso_data;
            end if;		
        elsif (cntr = 5) then
            if (data_ready = '1') then
                cntr				<= cntr + 1;
                accy_o(15 downto 8) <= miso_data;
            end if;		
        elsif (cntr = 6) then
            if (data_ready = '1') then
                cntr				<= cntr + 1;
                accz_o(7 downto 0)  <= miso_data;
            end if;		
        elsif (cntr = 7) then
            if (data_ready = '1') then
                accz_o(15 downto 8)	<= miso_data;
                cntr				<= 0;
                acc_valid_o			<= '1';
                en_spi 				<= '0';
                state               <= S_TIMER;
            end if;					
        end if;
        if (stop_acc_i = '1') then
            en_spi       <= '0';
            timer_enable <= '0';
            state        <= S_IDLE;
            cntr         <= 0;
        end if;    
    when others =>
    end case;

end if;
end if;
end process;

end Behavioral;