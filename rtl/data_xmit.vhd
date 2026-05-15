library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use work.periph_pkg.all;

entity data_xmit is
generic (
c_clkfreq   : integer := 100_000_000;
c_baudrate	: integer := 115_200
);
port (
clk         : in std_logic;
rstn        : in std_logic;
tx_o        : out std_logic;
accx_i      : in std_logic_vector (15 downto 0);
accy_i      : in std_logic_vector (15 downto 0);
accz_i      : in std_logic_vector (15 downto 0);
temp_i      : in std_logic_vector (12 downto 0);
acc_valid_i : in std_logic
);
end data_xmit;

architecture Behavioral of data_xmit is

signal din          : t_byte := x"00";
signal tx_start     : std_logic := '0';
signal tx_done_tick : std_logic := '0';
signal cntr         : integer range 0 to 7 := 0;

signal temp_msb     : t_byte := ZEROS(8);
signal temp_lsb     : t_byte := ZEROS(8);

signal state : t_state_xmit := S_IDLE;

begin

temp_msb <= temp_i(12) & temp_i(12) & temp_i(12) & temp_i(12 downto 8);
temp_lsb <= temp_i(7 downto 0);

uart_tx_i : entity work.uart_tx
generic map (
c_clkfreq		=> c_clkfreq,
c_baudrate		=> c_baudrate,
c_stopbit		=> 2
)
port map(
clk				=> clk,
din_i			=> din,
tx_start_i		=> tx_start,
tx_o			=> tx_o,
tx_done_tick_o	=> tx_done_tick
);

process (clk) begin
if rising_edge(clk) then
if rstn = '0' then
    state       <= S_IDLE;
    cntr        <= 0;
    tx_start    <= '0';
    din         <= ZEROS(8);
else
    
    case state is 
    when S_IDLE => 
        if (acc_valid_i = '1') then
            din         <= accx_i(15 downto 8);
            tx_start    <= '1';
            state       <= S_XMIT;
            cntr        <= 0;
        end if;
    when S_XMIT =>
        if (cntr = 0) then 
            din <= accx_i(7 downto 0);
            if (tx_done_tick = '1') then 
                cntr <= cntr + 1;
            end if;
        elsif (cntr = 1) then 
            din <= accy_i(15 downto 8);
            if (tx_done_tick = '1') then 
                cntr <= cntr + 1;
            end if;    
        elsif (cntr = 2) then 
            din <= accy_i(7 downto 0);
            if (tx_done_tick = '1') then 
                cntr <= cntr + 1;
            end if;    
        elsif (cntr = 3) then 
            din <= accz_i(15 downto 8);
            if (tx_done_tick = '1') then 
                cntr <= cntr + 1;
            end if;    
        elsif (cntr = 4) then 
            din <= accz_i(7 downto 0);
            if (tx_done_tick = '1') then 
                cntr <= cntr + 1;
            end if;    
        elsif (cntr = 5) then 
            din <= temp_msb;
            if (tx_done_tick = '1') then 
                cntr <= cntr + 1;
            end if;  
        elsif (cntr = 6) then 
            din <= temp_lsb;
            if (tx_done_tick = '1') then 
                cntr <= cntr + 1;
            end if;                                  
        elsif (cntr = 7) then 
            tx_start    <= '0';
            if (tx_done_tick = '1') then 
                cntr    <= 0;
                state   <= S_IDLE;
            end if;                       
        end if;
    when others => 
    end case;

end if;
end if;
end process;

end Behavioral;