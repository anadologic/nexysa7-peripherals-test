library ieee;
use ieee.std_logic_1164.all;

package periph_pkg is

subtype t_byte is std_logic_vector(7 downto 0);

function ZEROS(n : natural) return std_logic_vector;

constant c_header       : t_byte := x"BA";
constant c_footer       : t_byte := x"AE";
constant c_start_acc    : t_byte := x"A0";
constant c_stop_acc     : t_byte := x"A1";

-- ADXL362 Register Descriptions
constant c_power_ctl        : t_byte := x"2D";
constant c_xdata            : t_byte := x"08";

-- ADXL362 Commands
constant c_meas_mode        : t_byte := x"02";
constant c_wr_cmd           : t_byte := x"0A";
constant c_rd_cmd           : t_byte := x"0B";

type t_state_adxl362 is (S_POWERON, S_IDLE, S_TIMER, S_READDEVICE);    
type t_state_adt7420 is (S_POWERON, S_IDLE, S_I2CWR, S_I2CRD);    
type t_state_xmit is (S_IDLE, S_XMIT);    

end package;

package body periph_pkg is

    function ZEROS(n : natural) return std_logic_vector is
        variable v : std_logic_vector(n - 1 downto 0) := (others => '0');
    begin
        return v;
    end function;

end package body;