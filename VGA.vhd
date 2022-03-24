library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;


ENTITY VGA IS
PORT(
MAX10_CLK1_50: IN STD_LOGIC;
VGA_HS,VGA_VS:OUT STD_LOGIC;
SEL: STD_LOGIC_VECTOR(1 downto 0);
SW: STD_LOGIC_VECTOR(9 DOWNTO 0);
VGA_R: OUT STD_LOGIC_VECTOR(3 downto 0);
VGA_G: OUT STD_LOGIC_VECTOR(3 downto 0);
VGA_B: OUT STD_LOGIC_VECTOR(3 downto 0);
GPIO: in std_logic_vector(35 downto 0)
);
END VGA;


ARCHITECTURE MAIN OF VGA IS
SIGNAL VGACLK,RESET:STD_LOGIC;
signal KEY:std_logic_vector(1 downto 0);
---------------
component pll
	PORT
	(
		inclk0		: IN STD_LOGIC  := '0';
		c0		: OUT STD_LOGIC 
	);
end component pll;
--------------
 COMPONENT SYNC IS
 PORT(
	CLK: IN STD_LOGIC;
	HSYNC: OUT STD_LOGIC;
	VSYNC: OUT STD_LOGIC;
	R: OUT STD_LOGIC_VECTOR(3 downto 0);
	G: OUT STD_LOGIC_VECTOR(3 downto 0);
	B: OUT STD_LOGIC_VECTOR(3 downto 0);
	KEYS: IN STD_LOGIC_VECTOR(9 DOWNTO 0);
   S: IN STD_LOGIC_VECTOR(1 downto 0);
	encoder1: in std_logic_vector(2 downto 0);
	encoder2: in std_logic_vector(2 downto 0)
	);
END COMPONENT SYNC;

signal encoder1 : std_logic_vector(2 downto 0);
signal encoder2 : std_logic_vector(2 downto 0);
 BEGIN
 KEY(0) <= not SEL(0);
 KEY(1) <= not sel(1);
 encoder1(0) <= gpio(0);
 encoder1(1) <= gpio(2);
 encoder1(2) <= gpio(4);
 encoder2(0) <= gpio(1);
 encoder2(1) <= gpio(3);
 encoder2(2) <= gpio(5);
 
 C: pll PORT MAP (MAX10_CLK1_50, VGACLK);
 C1: SYNC PORT MAP(VGACLK, VGA_HS, VGA_VS, VGA_R, VGA_G, VGA_B, SW, KEY, encoder1, encoder2);
 
 END MAIN;
 