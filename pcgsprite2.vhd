library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

PACKAGE DW2 IS
PROCEDURE SPR(SIGNAL Xcur,Ycur,Xpos,Ypos:IN INTEGER;signal sprite:IN std_logic_vector(19 downto 0);
signal scale: in integer; SIGNAL DRAW: OUT STD_LOGIC);
END DW2;

PACKAGE BODY DW2 IS
PROCEDURE SPR(SIGNAL Xcur,Ycur,Xpos,Ypos:IN INTEGER;signal sprite:IN std_logic_vector(19 downto 0);
signal scale: in integer; SIGNAL DRAW: OUT STD_LOGIC) IS
BEGIN

 IF(Xpos-Xcur)/scale>=0 AND (Xpos-xcur)/scale<2 AND (Ypos-Ycur)/scale>=0 AND (Ypos-ycur)/scale<9 THEN
	 if sprite(1+((xpos - xcur)/scale) + ((1+((ypos - ycur)/scale))*2)) = '1' then 
		DRAW<='1';
	 else
		DRAW<='0';
	 end if;
 ELSE
	 DRAW<='0';
 END IF;
 
END SPR;
END DW2;