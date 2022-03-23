library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.dw.all;

ENTITY SYNC IS
PORT(
CLK: IN STD_LOGIC;
HSYNC: buffer STD_LOGIC;
VSYNC: buffer STD_LOGIC;
R: OUT STD_LOGIC_VECTOR(3 downto 0);
G: OUT STD_LOGIC_VECTOR(3 downto 0);
B: OUT STD_LOGIC_VECTOR(3 downto 0);
KEYS: IN STD_LOGIC_VECTOR(3 DOWNTO 0);
S: IN STD_LOGIC_VECTOR(1 downto 0)
);
END SYNC;


ARCHITECTURE MAIN OF SYNC IS
-----640x480 @ 60 Hz pixel clock 25 MHz
constant		h_pulse 	:	INTEGER := 96;    	--horiztonal sync pulse width in pixels
constant		h_bp	 	:	INTEGER := 48;		--horizontal back porch width in pixels
constant		h_pixels	:	INTEGER := 640;		--horiztonal display width in pixels
constant		h_fp	 	:	INTEGER := 16;			--horiztonal front porch width in pixels
constant		v_pulse 	:	INTEGER := 2;			--vertical sync pulse width in rows
constant		v_bp	 	:	INTEGER := 33;			--vertical back porch width in rows
constant		v_pixels	:	INTEGER := 480;		--vertical display width in rows
constant		v_fp	 	:	INTEGER := 10;			--vertical front porch width in rows

SIGNAL RGB: STD_LOGIC_VECTOR(3 downto 0);
SIGNAL SQ_X1: INTEGER RANGE 0 TO 639:=200;
SIGNAL SQ_Y1: INTEGER RANGE 0 TO 639:=200;
SIGNAL SQ_X2: INTEGER RANGE 0 TO 479:=300;
SIGNAL SQ_Y2: INTEGER RANGE 0 TO 479:=300;
SIGNAL DRAW1,DRAW2:STD_LOGIC:='0';
SIGNAL HPOS: INTEGER RANGE 0 TO 799:=0;
SIGNAL VPOS: INTEGER RANGE 0 TO 524:=0;
signal sixtyHz: integer range 0 to 6 := 0;
signal count100ms: integer range 0 to 9999 := 0;
signal scale: integer range 0 to 32 := 8;
signal asteroid1 : std_logic_vector(99 downto 0) := 
									  ('0','0','0','0','1','1','0','0','0','0',
										'0','0','0','1','1','1','1','0','0','0',
										'0','0','0','1','1','1','1','1','1','0',
										'0','0','1','1','1','1','1','1','1','0',
										'1','1','1','1','0','0','1','1','1','1',
										'1','1','1','0','0','0','0','1','1','1',
										'1','1','1','1','0','0','1','1','1','1',
										'0','0','1','1','1','1','1','1','1','0',
										'0','0','1','1','1','1','1','0','0','0',
										'0','0','0','1','1','1','0','0','0','0');
signal asteroid2 : std_logic_vector(99 downto 0) := 
									  ('0','0','0','0','1','1','0','0','0','0',
										'0','0','0','1','0','0','1','0','0','0',
										'0','0','0','1','0','0','0','1','1','0',
										'0','0','1','0','0','0','0','0','1','0',
										'0','1','0','0','0','0','0','0','0','1',
										'1','0','0','0','0','0','0','0','0','1',
										'1','1','0','0','0','0','0','0','0','1',
										'0','0','1','0','0','0','0','1','1','0',
										'0','0','1','0','0','0','1','0','0','0',
										'0','0','0','1','1','1','0','0','0','0');
--signal asteroid : std_logic_vector(120 downto 0) := 
--									  ('1','1','1','1','1','1','1','1','1','1','1',
--										'1','1','1','1','1','1','1','1','1','1','1',
--										'1','1','1','1','1','1','1','1','1','1','1',
--										'1','1','1','1','1','1','1','1','1','1','1',
--										'1','1','1','1','0','1','1','1','1','1','1',
--										'1','1','1','0','0','0','1','1','1','1','1',
--										'1','1','1','1','0','1','1','1','1','1','1',
--										'1','1','1','1','1','1','1','1','1','1','1',
--										'1','1','1','1','1','1','1','1','1','1','1',
--										'1','1','1','1','1','1','1','1','1','1','1',
--										'1','1','1','1','1','1','1','1','1','1','1');
BEGIN
SP(HPOS,VPOS,SQ_X1,SQ_Y1,asteroid1,scale,DRAW1);
SP(HPOS,VPOS,SQ_X2,SQ_Y2,asteroid2,scale,DRAW2);
 PROCESS(CLK)
 BEGIN
	IF(CLK'EVENT AND CLK='0')THEN
      IF(DRAW1='1')THEN
		  IF(S(0)='1')THEN
			R<=(others=>'1');
			G<=(others=>'0');
			B<=(others=>'0');
			ELSE
			R<=(others=>'0');
			G<=(others=>'0');
			B<=(others=>'1');
			END IF;
      END IF;
		 IF(DRAW2='1')THEN
		  IF(S(1)='1')THEN
			R<=(others=>'0');
			G<=(others=>'1');
			B<=(others=>'0');
			ELSE
			R<=(others=>'0');
			G<=(others=>'1');
			B<=(others=>'1');
		  END IF;
      END IF;
		IF (DRAW1='0' AND DRAW2='0')THEN
		   R<=(others=>'0');
	      G<=(others=>'0');
	      B<=(others=>'0');
		END IF;
		IF(HPOS<h_pixels + h_fp + h_pulse + h_bp)THEN
		HPOS<=HPOS+1;
		ELSE
		HPOS<=0;
		  IF(VPOS<v_pixels + v_fp + v_pulse + v_bp)THEN
			  VPOS<=VPOS+1;
			  ELSE
			  VPOS<=0; 
			      IF(S(0)='1')THEN
					    IF(KEYS(0)='1')THEN
						  SQ_X1<=(SQ_X1+5) MOD 640;
						 END IF;
                   IF(KEYS(1)='1')THEN
						  SQ_X1<=(SQ_X1-5) MOD 640;
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
						  SQ_X2<=(SQ_X2+5) MOD 640;
						 END IF;
                   IF(KEYS(1)='1')THEN
						  SQ_X2<=(SQ_X2-5) MOD 640;
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
		IF((HPOS>h_pixels) OR (VPOS>v_pixels))THEN
			R<=(others=>'0');
			G<=(others=>'0');
			B<=(others=>'0');
		END IF;
		IF(HPOS> (h_pixels + h_fp) AND HPOS<(h_pixels + h_fp + h_pulse))THEN----HSYNC
			HSYNC<='0';
		eLSE
			HSYNC<='1';
		END IF;
		IF (vpos > (v_pixels + v_fp) AND VPOS<(v_pixels + v_fp + v_pulse))THEN----------vsync
			VSYNC<='0';
		ELSE
			VSYNC<='1';
		END IF;
	END IF;
 END PROCESS;
 process (vsync)
 begin
	if (vsync'event and vsync = '0') then
		sixtyHz <= sixtyHz + 1;
		if (sixtyHz > 5) then
			count100ms <= count100ms + 1;
			sixtyHz <= 0;
--			if ((count100ms mod 10) = 0) then
				scale <= scale + 1;
--			end if;
		end if;
	end if;

 
 end process;
 END MAIN;