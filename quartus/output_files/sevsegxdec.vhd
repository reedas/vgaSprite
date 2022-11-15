-- seven segment hexadecimal decoder


library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity sevSegxDec is

	PORT
	(
		binIn		:	 IN STD_LOGIC_vector (3 downto 0);
		hexOut	:	 out STD_LOGIC_vector (7 downto 0)
	);

end sevSegxDec;

architecture bhv of sevSegxDec is
begin
	process(binIn)
	begin
		case binIn is
			when x"0" => hexout <= "11000000";
			when x"1" => hexout <= "11111001";
			when x"2" => hexout <= "10100100";
			when x"3" => hexout <= "10110000";
			when x"4" => hexout <= "10011001";
			when x"5" => hexout <= "10010010";
			when x"6" => hexout <= "10000010";
			when x"7" => hexout <= "11111000";
			when x"8" => hexout <= "10000000";
			when x"9" => hexout <= "10010000";
			when x"A" => hexout <= "10001000";
			when x"B" => hexout <= "10000011";
			when x"C" => hexout <= "11000110";
			when x"D" => hexout <= "10100001";
			when x"E" => hexout <= "10000110";
			when x"F" => hexout <= "10001110";
			when others => hexout <= "01111111";
		end case;


	end process;
	
end bhv;
