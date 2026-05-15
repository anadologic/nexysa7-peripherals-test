library ieee;
use ieee.std_logic_1164.all;
use work.periph_pkg.all;

entity top is
generic (
c_clkfreq   : integer := 100_000_000;
c_spifreq   : integer := 1_000_000;
c_i2cfreq   : integer := 400_000;
c_baud      : integer := 115_200
);
port (
clk         : in std_logic;
rstn        : in std_logic;
filt_en     : in std_logic;
uart_rx_i   : in std_logic;
uart_tx_o   : out std_logic;
cs_o 		: out std_logic;
sclk_o 		: out std_logic;
mosi_o 		: out std_logic;
miso_i 		: in  std_logic;
sda_io      : inout std_logic;
scl_io      : inout std_logic
);
end entity;

architecture rtl of top is

signal start        : std_logic := '0';
signal stop         : std_logic := '0';
signal acc_valid    : std_logic := '0';
signal temp         : std_logic_vector (12 downto 0) := ZEROS(13);
signal accx         : std_logic_vector (15 downto 0) := ZEROS(16);
signal accy         : std_logic_vector (15 downto 0) := ZEROS(16);
signal accz         : std_logic_vector (15 downto 0) := ZEROS(16);

signal accx_filt    : std_logic_vector (15 downto 0) := ZEROS(16);
signal accy_filt    : std_logic_vector (15 downto 0) := ZEROS(16);
signal accz_filt    : std_logic_vector (15 downto 0) := ZEROS(16);
signal temp_filt    : std_logic_vector (12 downto 0) := ZEROS(13);

signal accx_mux     : std_logic_vector (15 downto 0) := ZEROS(16);
signal accy_mux     : std_logic_vector (15 downto 0) := ZEROS(16);
signal accz_mux     : std_logic_vector (15 downto 0) := ZEROS(16);
signal temp_mux     : std_logic_vector (12 downto 0) := ZEROS(13);

signal temp_valid   : std_logic := '0';

begin

i_adt7420_wrapper : entity work.adt7420_wrapper
generic map (
c_clkfreq 		=> c_clkfreq,
c_i2cfreq 		=> c_i2cfreq
)
port map (
clk             => clk  ,
rstn            => rstn ,
start_temp_i    => start,
stop_temp_i     => stop ,
temp_o          => temp,
temp_valid_o    => temp_valid,
sda_io          => sda_io,
scl_io          => scl_io
);

i_adxl362_wrapper : entity work.adxl362_wrapper
generic map (
c_clkfreq 		=> c_clkfreq,
c_sclkfreq 		=> c_spifreq,
c_cpol			=> '0',
c_cpha			=> '0'
)
port map (
clk         => clk  ,
rstn        => rstn ,
start_acc_i => start,
stop_acc_i  => stop ,
accx_o      => accx,
accy_o      => accy,
accz_o      => accz,
acc_valid_o => acc_valid,
cs_o 		=> cs_o ,
sclk_o 		=> sclk_o,
mosi_o 		=> mosi_o,
miso_i 		=> miso_i
);

i_command_read : entity work.command_read
generic map (
c_clkfreq   => c_clkfreq,
c_baudrate	=> c_baud
)
port map (
clk     => clk  ,
rstn    => rstn ,
rx_i    => uart_rx_i,
start_o => start,
stop_o  => stop
);

i_moving_avg_accx : entity work.moving_avg
generic map (
c_width     => 16,
c_log2m     => 4
)
port map (
clk     => clk,
rstn    => rstn,
data_i  => accx,
valid_i => acc_valid,
data_o  => accx_filt
);

i_moving_avg_accy : entity work.moving_avg
generic map (
c_width     => 16,
c_log2m     => 4
)
port map (
clk     => clk,
rstn    => rstn,
data_i  => accy,
valid_i => acc_valid,
data_o  => accy_filt
);

i_moving_avg_accz : entity work.moving_avg
generic map (
c_width     => 16,
c_log2m     => 4
)
port map (
clk     => clk,
rstn    => rstn,
data_i  => accz,
valid_i => acc_valid,
data_o  => accz_filt
);

i_moving_avg_temp : entity work.moving_avg
generic map (
c_width     => 13,
c_log2m     => 4
)
port map (
clk     => clk,
rstn    => rstn,
data_i  => temp,
valid_i => temp_valid,
data_o  => temp_filt
);

accx_mux <= accx_filt when filt_en = '1' else accx;
accy_mux <= accy_filt when filt_en = '1' else accy;
accz_mux <= accz_filt when filt_en = '1' else accz;
temp_mux <= temp_filt when filt_en = '1' else temp;

i_data_xmit : entity work.data_xmit
generic map (
c_clkfreq   => c_clkfreq,
c_baudrate	=> c_baud
)
port map (
clk         => clk  ,
rstn        => rstn ,
tx_o        => uart_tx_o,
accx_i      => accx_mux,
accy_i      => accy_mux,
accz_i      => accz_mux,
temp_i      => temp_mux,
acc_valid_i => acc_valid
);

end rtl;