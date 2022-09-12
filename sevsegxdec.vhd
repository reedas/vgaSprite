-- seven segment hexadecimal decoder


library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity sevSegxDec is

	PORT
	(
		binIn		:	 IN STD_LOGIC_vector (3 downto 0);
		hexout	:	 out STD_LOGIC_vector (6 downto 0)
	);

end sevSegxDec;

architecture bhv of sevSegxDec is
begin
	process(binIn)
	begin
		case binIn is
			when x"0" => hexout <= "1000000";
			when x"1" => hexout <= "1111001";
			when x"2" => hexout <= "0100100";
			when x"3" => hexout <= "0110000";
			when x"4" => hexout <= "0011001";
			when x"5" => hexout <= "0010010";
			when x"6" => hexout <= "0000010";
			when x"7" => hexout <= "1111000";
			when x"8" => hexout <= "0000000";
			when x"9" => hexout <= "0010000";
			when x"A" => hexout <= "0001000";
			when x"B" => hexout <= "0000011";
			when x"C" => hexout <= "1000110";
			when x"D" => hexout <= "0100001";
			when x"E" => hexout <= "0000110";
			when x"F" => hexout <= "0001110";
			when others => hexout <= "1111111";
		end case;


	end process;
	
end bhv;
