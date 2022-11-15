-- adc_sample_to_dec.vhd 2 digits of decimal
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;


entity adc_sample_to_DEC is
    port (
        adc_sample  : in std_logic_vector(11 downto 0);
        vol         : out std_logic_vector(12 downto 0);
        ones        : out std_logic_vector(3 downto 0);
        tens        : out std_logic_vector(3 downto 0)
    );
end entity;


architecture A of adc_sample_to_DEC is
    signal voltage : unsigned(vol'range);
begin
    voltage <= resize(unsigned(adc_sample) * 2 * 2500 / 4095, 13);

    vol <= std_logic_vector(voltage);

    ones <= std_logic_vector(resize(voltage / 1000, 4));
    tens <= std_logic_vector(resize((voltage / 100) - ((voltage / 1000) * 10), 4));
end architecture A;
