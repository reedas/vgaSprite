library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;


entity VGA is
  port(
    MAX10_CLK1_50  : in  std_logic;
    VGA_HS, VGA_VS : out std_logic;
    SEL            :     std_logic_vector(1 downto 0);
    SW             :     std_logic_vector(9 downto 0);
    VGA_R          : out std_logic_vector(3 downto 0);
    VGA_G          : out std_logic_vector(3 downto 0);
    VGA_B          : out std_logic_vector(3 downto 0);
    GPIO           : inout std_logic_vector(35 downto 0);
	 LEDR			    : out std_logic_vector(9 downto 0);
	 HEX0				 : out std_logic_vector(6 downto 0);
	 HEX1				 : out std_logic_vector(6 downto 0);
	 HEX2				 : out std_logic_vector(6 downto 0);
	 HEX3				 : out std_logic_vector(6 downto 0);
	 HEX4				 : out std_logic_vector(6 downto 0);
	 HEX5				 : out std_logic_vector(6 downto 0)

    );
end VGA;


architecture MAIN of VGA is
  signal VGACLK, RESET : std_logic;
  signal KEY           : std_logic_vector(1 downto 0);
---------------
  component pll
    port
      (
        inclk0 : in  std_logic := '0';
        c0     : out std_logic
        );
  end component pll;
--------------
  component SYNC is
    port(
      CLK      : in  std_logic;
      HSYNC    : out std_logic;
      VSYNC    : out std_logic;
      R        : out std_logic_vector(3 downto 0);
      G        : out std_logic_vector(3 downto 0);
      B        : out std_logic_vector(3 downto 0);
      KEYS     : in  std_logic_vector(9 downto 0);
      S        : in  std_logic_vector(1 downto 0);
      encoder1 : in  std_logic_vector(2 downto 0);
      encoder2 : in  std_logic_vector(2 downto 0);
      led      : out std_logic_vector(9 downto 0);
	   HEX0		: out std_logic_vector(6 downto 0);
	   HEX1		: out std_logic_vector(6 downto 0);
--	   HEX2		: out std_logic_vector(6 downto 0);
--	   HEX3		: out std_logic_vector(6 downto 0);
	   HEX4		: out std_logic_vector(6 downto 0);
	   HEX5		: out std_logic_vector(6 downto 0);
		audio		: out std_logic
      );
  end component SYNC;

  signal encoder1 : std_logic_vector(2 downto 0);
  signal encoder2 : std_logic_vector(2 downto 0);
  signal audio    : std_logic;
begin
  KEY(0)      <= not SEL(0);
  KEY(1)      <= not sel(1);
  encoder1(0) <= gpio(0);
  encoder1(1) <= gpio(2);
  encoder1(2) <= gpio(4);
  encoder2(0) <= gpio(1);
  encoder2(1) <= gpio(3);
  encoder2(2) <= gpio(5);
  gpio(9)     <= audio;

  C  : pll port map (MAX10_CLK1_50, VGACLK);
  C1 : SYNC port map(VGACLK, VGA_HS, VGA_VS, VGA_R, VGA_G, VGA_B, SW, KEY, encoder1, encoder2, LEDR, 
							hex0, hex1, hex4, hex5, audio);

end MAIN;
