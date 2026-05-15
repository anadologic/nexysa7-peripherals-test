library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity moving_avg is
generic (
c_width     : integer := 16;
c_log2m     : integer := 4
);
port (
clk         : in  std_logic;
rstn        : in  std_logic;
data_i      : in  std_logic_vector (c_width - 1 downto 0);
valid_i     : in  std_logic;
data_o      : out std_logic_vector (c_width - 1 downto 0)
);
end entity;

architecture rtl of moving_avg is

constant c_m    : integer := 2 ** c_log2m;

type t_buffer is array (0 to c_m - 1) of signed (c_width - 1 downto 0);
signal buf      : t_buffer := (others => (others => '0'));

signal acc      : signed (c_width + c_log2m - 1 downto 0) := (others => '0');
signal wr_ptr   : integer range 0 to c_m - 1 := 0;

begin

process (clk) begin
if rising_edge(clk) then
if rstn = '0' then
    buf     <= (others => (others => '0'));
    acc     <= (others => '0');
    wr_ptr  <= 0;
    data_o  <= (others => '0');
else
    if (valid_i = '1') then
        acc            <= acc + resize(signed(data_i), acc'length) - resize(buf(wr_ptr), acc'length);
        buf(wr_ptr)    <= signed(data_i);
        if (wr_ptr = c_m - 1) then
            wr_ptr <= 0;
        else
            wr_ptr <= wr_ptr + 1;
        end if;
        data_o <= std_logic_vector(acc(c_width + c_log2m - 1 downto c_log2m));
    end if;
end if;
end if;
end process;

end rtl;
