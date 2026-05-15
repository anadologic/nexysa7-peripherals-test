library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use work.periph_pkg.all;

entity command_read is
generic (
c_clkfreq   : integer := 100_000_000;
c_baudrate	: integer := 115_200
);
port (
clk     : in std_logic;
rstn    : in std_logic;
rx_i    : in std_logic;
start_o : out std_logic;
stop_o  : out std_logic
);
end command_read;

architecture Behavioral of command_read is

signal async_ff : std_logic_vector(1 downto 0) := "11";
attribute ASYNC_REG : string;
attribute ASYNC_REG of async_ff : signal is "TRUE";

signal dout         : std_logic_vector (7 downto 0) := ZEROS(8);
signal rx_done_tick : std_logic := '0';

signal data_buffer  : std_logic_vector (2*8-1 downto 0) := ZEROS(16);

begin

process (clk) begin 
if (rising_edge(clk)) then
    if (rstn = '0') then
        async_ff <= "11";
    else
        async_ff(0) <= rx_i;
        async_ff(1) <= async_ff(0);
    end if;
end if;
end process;

uart_rx_i : entity work.uart_rx
generic map(
c_clkfreq		=> c_clkfreq,
c_baudrate		=> c_baudrate
)
port map (
clk				=> clk,
rx_i			=> async_ff(1),
dout_o			=> dout,
rx_done_tick_o	=> rx_done_tick
);

process (clk)
begin
if rising_edge(clk) then
if rstn = '0' then
    start_o     <= '0'; 
    stop_o      <= '0'; 
    data_buffer     <= (others => '0');
else    
    start_o     <= '0';
    stop_o      <= '0';
    if (rx_done_tick = '1') then                
        if ((data_buffer(2*8-1 downto 1*8) = c_header) and (dout = c_footer)) then
            if (data_buffer(1*8-1 downto 0) = c_start_acc) then 
                start_o <= '1';
            elsif (data_buffer(1*8-1 downto 0) = c_stop_acc) then 
                stop_o <= '1';
            end if;            
        end if;
        data_buffer <= data_buffer(1*8-1 downto 0) & dout;
    end if;
end if;
end if;
end process;

end Behavioral;