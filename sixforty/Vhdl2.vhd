library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.my.all;

ENTITY SYNC IS
PORT(
CLK: IN STD_LOGIC;
HSYNC: OUT STD_LOGIC;
VSYNC: OUT STD_LOGIC;
R: OUT STD_LOGIC_VECTOR(3 downto 0);
G: OUT STD_LOGIC_VECTOR(3 downto 0);
B: OUT STD_LOGIC_VECTOR(3 downto 0);
KEYS: IN STD_LOGIC_VECTOR(3 DOWNTO 0);
S: IN STD_LOGIC_VECTOR(1 downto 0)
);
END SYNC;


ARCHITECTURE MAIN OF SYNC IS
-----1280x1024 @ 60 Hz pixel clock 108 MHz
constant		h_pulse 	:	INTEGER := 112;    	--horiztonal sync pulse width in pixels
constant		h_bp	 	:	INTEGER := 248;		--horizontal back porch width in pixels
constant		h_pixels	:	INTEGER := 1280;		--horiztonal display width in pixels
constant		h_fp	 	:	INTEGER := 48;			--horiztonal front porch width in pixels
constant		v_pulse 	:	INTEGER := 3;			--vertical sync pulse width in rows
constant		v_bp	 	:	INTEGER := 38;			--vertical back porch width in rows
constant		v_pixels	:	INTEGER := 1024;		--vertical display width in rows
constant		v_fp	 	:	INTEGER := 1;			--vertical front porch width in rows

SIGNAL RGB: STD_LOGIC_VECTOR(3 downto 0);
SIGNAL SQ_X1: INTEGER RANGE 0 TO 1279:=500;
SIGNAL SQ_Y1: INTEGER RANGE 0 TO 1023:=500;
SIGNAL SQ_X2: INTEGER RANGE 0 TO 1279:=600;
SIGNAL SQ_Y2: INTEGER RANGE 0 TO 1023:=600;
SIGNAL DRAW1,DRAW2:STD_LOGIC:='0';
SIGNAL HPOS: INTEGER RANGE 0 TO 1688:=0;
SIGNAL VPOS: INTEGER RANGE 0 TO 1066:=0;
BEGIN
SQ(HPOS,VPOS,SQ_X1,SQ_Y1,RGB,DRAW1);
SQ(HPOS,VPOS,SQ_X2,SQ_Y2,RGB,DRAW2);
 PROCESS(CLK)
 BEGIN
IF(CLK'EVENT AND CLK='1')THEN
      IF(DRAW1='1')THEN
		  IF(S(0)='1')THEN
			R<=(others=>'1');
			G<=(others=>'0');
			B<=(others=>'0');
			ELSE
			R<=(others=>'1');
			G<=(others=>'1');
			B<=(others=>'1');
			END IF;
      END IF;
		 IF(DRAW2='1')THEN
		  IF(S(1)='1')THEN
			R<=(others=>'1');
			G<=(others=>'0');
			B<=(others=>'0');
			ELSE
			R<=(others=>'1');
			G<=(others=>'1');
			B<=(others=>'1');
		  END IF;
      END IF;
		IF (DRAW1='0' AND DRAW2='0')THEN
		   R<=(others=>'0');
	      G<=(others=>'0');
	      B<=(others=>'0');
		END IF;
		IF(HPOS<h_pixels)THEN
		HPOS<=HPOS+1;
		ELSE
		HPOS<=0;
		  IF(VPOS<v_pixels)THEN
			  VPOS<=VPOS+1;
			  ELSE
			  VPOS<=0; 
			      IF(S(0)='1')THEN
					    IF(KEYS(0)='1')THEN
						  SQ_X1<=(SQ_X1+5) MOD 1280;
						 END IF;
                   IF(KEYS(1)='1')THEN
						  SQ_X1<=(SQ_X1-5) MOD 1280;
						 END IF;
						  IF(KEYS(2)='1')THEN
						  SQ_Y1<=SQ_Y1-5;
						 END IF;
						 IF(KEYS(3)='1')THEN
						  SQ_Y1<=SQ_Y1+5;
						 END IF;  
					END IF;
			      IF(S(1)='1')THEN
					    IF(KEYS(0)='1')THEN
						  SQ_X2<=(SQ_X2+5) MOD 1280;
						 END IF;
                   IF(KEYS(1)='1')THEN
						  SQ_X2<=(SQ_X2-5) MOD 1280;
						 END IF;
						 IF(KEYS(2)='1')THEN
						  SQ_Y2<=SQ_Y2-5;
						 END IF;
						 IF(KEYS(3)='1')THEN
						  SQ_Y2<=SQ_Y2+5;
						 END IF; 
					END IF;  
		      END IF;
		END IF;
--   IF((HPOS>0 AND HPOS<408) OR (VPOS>0 AND VPOS<42))THEN
   IF((HPOS>=h_pixels) OR (VPOS>=v_pixels))THEN
		R<=(others=>'0');
		G<=(others=>'0');
		B<=(others=>'0');
	END IF;
   IF(HPOS>(h_pixels + h_fp) AND HPOS<(h_pixels + h_fp + h_pulse))THEN----HSYNC
	   HSYNC<='0';
	ELSE
	   HSYNC<='1';
	END IF;
   IF (vpos > (v_pixels + v_fp) AND VPOS<(v_pixels + v_fp + v_pulse))THEN----------vsync
	   VSYNC<='0';
	ELSE
	   VSYNC<='1';
	END IF;
 END IF;
 END PROCESS;
 END MAIN;