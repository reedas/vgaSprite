library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.dw.all;
use work.dw2.all;
use work.CHAR2STD.all;

entity SYNC is
  port(
    CLK      : in     std_logic;
    HSYNC    : buffer std_logic;
    VSYNC    : buffer std_logic;
    R        : out    std_logic_vector(3 downto 0);
    G        : out    std_logic_vector(3 downto 0);
    B        : out    std_logic_vector(3 downto 0);
    KEYS     : in     std_logic_vector(9 downto 0);
    S        : in     std_logic_vector(1 downto 0);
    encoder1 : in     std_logic_vector(2 downto 0);
    encoder2 : in     std_logic_vector(2 downto 0);
	 led      : out    std_logic_vector(9 downto 0);
	 HEX0		: out std_logic_vector(7 downto 0);
	 HEX1		: out std_logic_vector(7 downto 0);
	 HEX2		: out std_logic_vector(7 downto 0);
	 HEX3		: out std_logic_vector(7 downto 0);
	 HEX4		: out std_logic_vector(7 downto 0);
	 HEX5		: out std_logic_vector(7 downto 0);
	 audio	: out std_logic

    );
end SYNC;


architecture MAIN of SYNC is
	component paddles is
		port (
			-- Clocks
			MAX10_CLK1_50   : in std_logic;
			-- KEY
			reset           : in std_logic;
			-- paddle postioins from adc
			player1			 : out std_logic_vector(7 downto 0);
			player2			 : out std_logic_vector(7 downto 0)
		);
	end component paddles;
  component quadrature_decoder is
    port(
      clk          : in     std_logic;  --system clock
      a            : in     std_logic;  --quadrature encoded signal a
      b            : in     std_logic;  --quadrature encoded signal b
      set_origin_n : in     std_logic;  --active-low synchronous clear of position counter
      direction    : out    std_logic;  --direction of last change, 1 = positive, 0 = negative
      position     : buffer integer range 0 to 63 := 31  --current position relative to index or initial value
      );
  end component quadrature_decoder;
  
  component txtScreen is
    port(
      hp, vp :    integer;
      addr   : in std_logic_vector(11 downto 0);         -- text screen ram
      data   : in std_logic_vector(7 downto 0);
      nWr    : in std_logic;
      pClk   : in std_logic;
      nblnk  : in std_logic;

      pix : out std_logic

      );
  end component txtScreen;
  
  component sevsegxdec is
	PORT
	(
		binIn		:	 IN STD_LOGIC_vector (3 downto 0);
		hexout	:	 out STD_LOGIC_vector (6 downto 0)
	);

  end component sevsegxdec;
-----640x480 @ 60 Hz pixel clock 25. MHz
  constant h_pulse  : integer := 96;    --horiztonal sync pulse width in pixels
  constant h_bp     : integer := 48;    --horizontal back porch width in pixels
  constant h_pixels : integer := 640;   --horiztonal display width in pixels
  constant h_fp     : integer := 16;   --horiztonal front porch width in pixels
  constant v_pulse  : integer := 2;     --vertical sync pulse width in rows
  constant v_bp     : integer := 33;    --vertical back porch width in rows
  constant v_pixels : integer := 480;   --vertical display width in rows
  constant v_fp     : integer := 10;    --vertical front porch width in rows
--

  signal ohsync                      : std_logic;
  signal ovsync                      : std_logic;
  signal oohsync                     : std_logic;
  signal oovsync                     : std_logic;
  signal cycle                       : std_logic               := '0';
  signal P_X1                        : integer range 0 to 639  := 8;
  signal P_Y1                        : integer range 0 to 479  := 220;
  signal P_X2                        : integer range 0 to 639  := 620;
  signal P_Y2                        : integer range 0 to 479  := 220;
  signal blipcnt                     : integer range 0 to 100000000  := 0;
  signal blopcnt                     : integer range 0 to 100000000  := 0;
  signal bloopcnt                    : integer range 0 to 100000000  := 0;
  signal blip                        : std_logic;
  signal blop                        : std_logic;
  signal bloop                       : std_logic;
  signal collblip                    : std_logic;
  signal collblop                    : std_logic;
  signal sideblip                    : std_logic;
  signal BL_X1                       : integer range 0 to 639  := 60;
  signal BL_Y1                       : integer range 0 to 479  := 220;
  signal nBlanking                   : std_logic               := '1';
  signal txtRGB                      : std_logic;
  signal scrAddress                  : std_logic_vector(11 downto 0);
  signal charpos                     : integer range 0 to 4191 := 0;
  signal thousands                   : integer range 0 to 255  := 0;
  signal hundreds                    : integer range 0 to 255  := 0;
  signal tens1                        : integer range 0 to 255  := 0;
  signal unit1                        : integer range 0 to 255  := 0;
  signal thousands2                  : integer range 0 to 255  := 0;
  signal hundreds2                   : integer range 0 to 255  := 0;
  signal tens2                       : integer range 0 to 255  := 0;
  signal unit2                       : integer range 0 to 255  := 0;
  signal scrData                     : std_logic_vector(7 downto 0);
  signal nWr                         : std_logic;
  signal RD0                         : std_logic_vector(3 downto 0); -- Player 1 
  signal GD0                         : std_logic_vector(3 downto 0);
  signal BD0                         : std_logic_vector(3 downto 0);
  signal RD1                         : std_logic_vector(3 downto 0); -- Player 2
  signal GD1                         : std_logic_vector(3 downto 0);
  signal BD1                         : std_logic_vector(3 downto 0);
  signal RT                          : std_logic_vector(3 downto 0); -- Text display
  signal GT                          : std_logic_vector(3 downto 0);
  signal BT                          : std_logic_vector(3 downto 0);
  signal RBL                         : std_logic_vector(3 downto 0); -- Ball
  signal GBL                         : std_logic_vector(3 downto 0);
  signal BBL                         : std_logic_vector(3 downto 0);
  signal GRIDR, GRIDG, GRIDB         : std_logic_vector(3 downto 0); -- side walls
  signal DRAW0, DRAW1, drawBL 		 : std_logic               := '0';
  signal HPOS                        : integer range 0 to 799  := 0; -- Current pixel position counters
  signal VPOS                        : integer range 0 to 524  := 0;
  signal counter                     : integer range 0 to 9999 := 0;
  signal flash                       : std_logic;
  signal scaleP                      : integer range 1 to 32   := 8; -- paddle scaling
  signal scaleBL                     : integer range 1 to 32   := 2; -- ball scaling
  signal player1score                 : integer range 0 to 9999 := 0;
  signal player2score                : integer range 0 to 9999 := 0;
  signal direction1                  : std_logic;
  signal player1serve                : std_logic 					:= '1';
  signal player2serve                : std_logic					:= '0';
  signal position1                   : integer;
  signal paddlepos1                  : std_logic_vector(7 downto 0); --
  signal direction2                  : std_logic;
  signal paddlepos2                  : std_logic_vector(7 downto 0); --
  signal position2                   : integer;
  signal bl_xdelta                   : integer range -20 to 20   := 2;
  signal bl_ydelta                   : integer range -20 to 20   := 2;
  signal collision                   : integer range 0 to 1    := 0;
  signal current_dir                 : integer range -1 to 1   := 1;
  signal ballSpeed                   : integer range 1 to 20   := 2;
  signal audioblip, audioblop			 : std_logic;
  signal audiobloop			          : std_logic;
-- sprite for paddles
  signal paddle                      : std_logic_vector(19 downto 0) :=
    ('1', '1',
     '1', '1',
     '1', '1',
     '1', '1',
     '1', '1',
     '1', '1',
     '1', '1',
     '1', '1',
     '1', '1',
     '1', '1');
-- sprite for ball
  signal ball : std_logic_vector(99 downto 0) :=
    ('0', '0', '0', '0', '1', '1', '0', '0', '0', '0',
     '0', '0', '1', '1', '1', '1', '1', '1', '0', '0',
     '0', '1', '1', '1', '1', '1', '1', '1', '1', '0',
     '0', '1', '1', '1', '1', '1', '1', '1', '1', '0',
     '1', '1', '1', '1', '0', '0', '1', '1', '1', '1',
     '1', '1', '1', '1', '0', '0', '1', '1', '1', '1',
     '0', '1', '1', '1', '1', '1', '1', '1', '1', '0',
     '0', '1', '1', '1', '1', '1', '1', '1', '1', '0',
     '0', '0', '1', '1', '1', '1', '1', '1', '0', '0',
     '0', '0', '0', '0', '1', '1', '0', '0', '0', '0');
begin
-- There are effectively two displays overlayed over each other an 80 column 24 line text display
-- and the hardware sprites for paddles and ball
  txtscr : txtScreen -- memory mapped screen display for 80 x 24 ascii characters
    port map (hpos, vpos, scrAddress, scrData, nWr, clk, nBlanking, txtRGB);
-- Get the current paddle positions
--  paddleLeft  : quadrature_decoder port map (clk, encoder1(0), encoder1(1), not s(1), direction1, position1);
--  paddleRight : quadrature_decoder port map (clk, encoder2(0), encoder2(1), not s(1), direction2, position2);
	paddlePositions : paddles port map (clk, S(0), paddlepos1, paddlepos2);
	position1 <= (to_integer(unsigned(paddlepos1)));
	position2 <= (to_integer(unsigned(paddlepos2)));

-- Enumarate the digits of the scores
  thousands  <= 48 + ((player1score / 1000) mod 10); -- probably won't need to go to 9999
  hundreds   <= 48 + ((player1score / 100) mod 10);
  tens1       <= 48 + ((player1score / 10) mod 10);
  unit1       <= 48 + (player1score mod 10);
  thousands2 <= 48 + ((player2score / 1000) mod 10);
  hundreds2  <= 48 + ((player2score / 100) mod 10);
  tens2      <= 48 + ((player2score / 10) mod 10);
  unit2      <= 48 + (player2score mod 10);
-- Draw all sprites
  SPR(HPOS, VPOS, P_X1, P_Y1, paddle, scaleP, DRAW0);
  SPR(HPOS, VPOS, P_X2, P_Y2, paddle, scaleP, DRAW1);
  SP(HPOS, VPOS, BL_X1, BL_Y1, ball, scaleBL, DRAWBL);
  
-- update seven segment displays with score
  digit0 : sevsegxdec port map (std_logic_vector(to_unsigned((player2score mod 10), 4)), HEX0(6 downto 0));
  digit1 : sevsegxdec port map (std_logic_vector(to_unsigned(((player2score / 10) mod 10), 4)), HEX1(6 downto 0));
  digit4 : sevsegxdec port map (std_logic_vector(to_unsigned((player1score mod 10), 4)), HEX4(6 downto 0));
  digit5 : sevsegxdec port map (std_logic_vector(to_unsigned(((player1score / 10) mod 10), 4)), HEX5(6 downto 0));

  process(CLK)
  begin -- make noises and update display
    if(CLK'event and CLK = '0')then
		if (collblip = '1') or (blip = '1') then
			if (blipcnt < 5000000) then
           blipcnt <= blipcnt + 1;
			  if ((blipcnt mod 20000) = 0) then
			      audioblip <= not audioblip;
			  end if;
			  blip <= '1';
			  led(9) <= '1';
			else
			  blip <= '0';
			  led(9) <= '0';
			  blipcnt <= 0;
			end if;
		end if;
		if (collblop = '1') or (blop = '1') then
			if (blopcnt < 10000000) then
			  blopcnt <= blopcnt + 1;
			  if ((blopcnt mod 100000) = 0) then
			      audioblop <= not audioblop;
			  end if;
			  
           blop <= '1';
			  led(8) <= '1';
			else
			  blop <= '0';
			  led(8) <= '0';
			  blopcnt <= 0;
			end if;
		end if;
		if (sideblip = '1') or (bloop = '1') then
			if (bloopcnt < 5000000) then
			  bloopcnt <= bloopcnt + 1;
			  if ((bloopcnt mod 50000) = 0) then
			      audiobloop <= not audiobloop;
			  end if;
			  
           bloop <= '1';
			  led(5) <= '1';
			else
			  bloop <= '0';
			  led(5) <= '0';
			  bloopcnt <= 0;
			end if;
		end if;
		audio <= audioblip xor audioblop xor audiobloop;
      if (cycle = '0') then             -- write data to text screen ram
        cycle <= '1';
        nwr   <= '0';
      end if;
      if (cycle = '1') then -- complete write to screen ram cycles 
        cycle <= '0';
		  if (charpos = 2) then
          scrData <= char2std('P');
          nwr     <= '1';
        end if;
		  if (charpos = 3) then
          scrData <= char2std('l');
          nwr     <= '1';
        end if;
		  if (charpos = 4) then
          scrData <= char2std('a');
          nwr     <= '1';
        end if;
		  if (charpos = 5) then
          scrData <= char2std('y');
          nwr     <= '1';
        end if;
		  if (charpos = 6) then
          scrData <= char2std('e');
          nwr     <= '1';
        end if;
		  if (charpos = 7) then
          scrData <= char2std('r');
          nwr     <= '1';
        end if;
		  if (charpos = 9) then
          scrData <= char2std('1');
          nwr     <= '1';
        end if;
		  if (charpos = 70) then
          scrData <= char2std('P');
          nwr     <= '1';
        end if;
		  if (charpos = 71) then
          scrData <= char2std('l');
          nwr     <= '1';
        end if;
		  if (charpos = 72) then
          scrData <= char2std('a');
          nwr     <= '1';
        end if;
		  if (charpos = 73) then
          scrData <= char2std('y');
          nwr     <= '1';
        end if;
		  if (charpos = 74) then
          scrData <= char2std('e');
          nwr     <= '1';
        end if;
		  if (charpos = 75) then
          scrData <= char2std('r');
          nwr     <= '1';
        end if;
		  if (charpos = 77) then
          scrData <= char2std('2');
          nwr     <= '1';
        end if;
--        if (charpos = 84) then
--          scrData <= std_logic_vector(to_unsigned(thousands, scrData'length));
--          nwr     <= '1';
--        end if;
--        if (charpos = 85) then
--          scrData <= std_logic_vector(to_unsigned(hundreds, scrdata'length));
--          nwr     <= '1';
--        end if;
        if (charpos = 85) then
          scrData <= std_logic_vector(to_unsigned(tens1, scrdata'length));
          nwr     <= '1';
        end if;
        if (charpos = 86) then
          scrData <= std_logic_vector(to_unsigned(unit1, scrdata'length));
          nwr     <= '1';
        end if;
--        if (charpos = 152) then
--          scrData <= std_logic_vector(to_unsigned(thousands2, scrData'length));
--          nwr     <= '1';
--        end if;
--        if (charpos = 153) then
--          scrData <= std_logic_vector(to_unsigned(hundreds2, scrdata'length));
--          nwr     <= '1';
--        end if;
        if (charpos = 153) then
          scrData <= std_logic_vector(to_unsigned(tens2, scrdata'length));
          nwr     <= '1';
        end if;
        if (charpos = 154) then
          scrData <= std_logic_vector(to_unsigned(unit2, scrdata'length));
          nwr     <= '1';
        end if;
-- draw the net
		  if (charpos > 400) and ((charpos MOD 80) = 40) and (charpos < 3160) then
          scrData <= char2std('|');
          nwr     <= '1';
        end if;

		  charpos    <= charpos + 1;
        scrAddress <= std_logic_vector(to_unsigned(charpos, scraddress'length));
      end if;
      if (keys(9) = '1') then -- selectable ball speed
        ballSpeed <= 4;
      else
        ballSpeed <= 2;
      end if;
      if(DRAWBL = '1')then -- draw the ball sprite
        RBL <= (others => '1');
        GBL <= (others => '1');
        BBL <= (others => '1');
      else
        RBL <= (others => '0');
        GBL <= (others => '0');
        BBL <= (others => '0');
      end if;
      if(DRAW0 = '1')then -- draw the player 1 paddle
        RD0 <= (others => '1');
        GD0 <= (others => '0');
        BD0 <= (others => '1');
      else
        RD0 <= (others => '0');
        GD0 <= (others => '0');
        BD0 <= (others => '0');
      end if;
      if(DRAW1 = '1')then -- draw the player 2 paddle
        RD1 <= (others => '0');
        GD1 <= (others => '1');
        BD1 <= (others => '1');
      else
        RD1 <= (others => '0');
        GD1 <= (others => '0');
        BD1 <= (others => '0');
      end if;
      if (txtRGB = '1') then -- add the text screen
        RT <= (others => '1');
        GT <= (others => '1');
        BT <= (others => '1');
      else
        RT <= (others => '0');
        GT <= (others => '0');
        BT <= (others => '0');
      end if;
		if (VPOS = 50) or (VPOS = (v_pixels - 7)) then -- draw the side walls
		  GRIDR <= (others => '1');
		  GRIDG <= (others => '1');
		  GRIDB <= (others => '1');
		else
		  GRIDR <= (others => '0');
		  GRIDG <= (others => '0');
		  GRIDB <= (others => '0');
		end if;
      P_y1 <= position1*3/2 + 40; -- encoder/potentiometer positioning the paddle for player 1
      p_y2 <= position2*3/2 + 40; -- encoder/potentiometer positioning the paddle for player 2
      if(HPOS < h_pixels + h_fp + h_pulse + h_bp)then
        HPOS <= HPOS+1;
      else
        HPOS <= 0;
        if(VPOS < v_pixels + v_fp + v_pulse + v_bp)then
          VPOS <= VPOS+1;
        else
          VPOS <= 0;
        end if;
      end if;
      if((HPOS > h_pixels) or (VPOS > v_pixels))then 
        R         <= (others => '0');
        G         <= (others => '0');
        B         <= (others => '0');
        nblanking <= '0';
      else
        R         <= RD0 or RD1 or RBL or GRIDR or RT;
        G         <= GD0 or GD1 or GBL or GRIDG or GT;
        B         <= BD0 or BD1 or BBL or GRIDB or BT;
        nBlanking <= '1';
      end if;
      if(HPOS > (h_pixels + h_fp) and HPOS < (h_pixels + h_fp + h_pulse))then  -- HSYNC goes low
        ooHSYNC <= '0';
        hsync   <= oohsync;
      else -- Hsync goes high
        ooHSYNC <= '1';
        hsync   <= oohsync;
      end if;
      if (vpos > (v_pixels + v_fp) and VPOS < (v_pixels + v_fp + v_pulse))then  -- Vsync goes low
        oovSYNC <= '0';
        vsync   <= oovsync;

      else --Vsync goes high
        ooVSYNC <= '1';
        vsync   <= oovsync;

      end if;
    end if;
  end process;
  process (vsync) -- display is in blanking so do stuff to avoid interference on display
  begin  -- move stuff and check for collisions
    if (vsync'event and vsync = '0') then
		if (collblip = '1') then collblip <= '0'; end if; -- end all audio bloops
		if (collblop = '1') then collblop <= '0'; end if;
		if (sideblip = '1') then sideblip <= '0'; end if;
      if ((bl_x1 < 32) and ((BL_y1 - p_y1) > 0) 
		   and ((bl_y1 - p_y1) < 10 * scaleP)) then  -- bat hits ball
        bl_xdelta <= ballSpeed;
        bl_x1     <= 32;
		  collblip <= '1';
		  led(7) <= '1';
        if ((bl_y1 - p_y1) < 16) then
          bl_ydelta <= ballSpeed * (-2);
        else
          if ((bl_y1 - p_y1) < 32) then
            bl_ydelta <= ballSpeed * (-1);
          else
            if ((bl_y1 - p_y1) < 48) then
              bl_ydelta <= 0;
            else
              if ((bl_y1 - p_y1) < 64) then
                bl_ydelta <= ballSpeed * (1);

              else
                bl_ydelta <= ballSpeed * (2);
              end if;
            end if;
          end if;
        end if;
      else
        if (bl_x1 > h_pixels - 30) and 
				(bl_x1 < h_pixels -10)and
				((BL_y1 - p_y2) > 0) and
				((bl_y1 - p_y2) < 10 * scaleP) then  -- bat hits ball
          bl_xdelta <= bl_xdelta * (-1);
          bl_x1     <= p_x2 - 10;
			 collblip <= '1';
			 led(7) <= '1';
          if ((bl_y1 - p_y2) < 16) then
            bl_ydelta <= ballSpeed * (-2);
          else
            if ((bl_y1 - p_y2) < 32) then
              bl_ydelta <= ballSpeed * (-1);
            else
              if ((bl_y1 - p_y2) < 48) then
                bl_ydelta <= 0;
              else
                if ((bl_y1 - p_y2) < 64) then
                  bl_ydelta <= ballSpeed * (1);

                else
                  bl_ydelta <= ballSpeed  * (2);
                end if;
              end if;
            end if;
          end if;
        else
				if (player1serve = '0') AND (player2serve = '0') then
					if bl_x1 >= (h_pixels - scalebl*5) then -- player2 loses ball
						bl_xdelta   <= ballSpeed *(-1);
						bl_x1       <= 580;
						if player1score = 14 then -- game over player 1 wins 14+1 == 15
							player1score <= 0;
							player2score <= 0;
							hex5(7) <= '0'; -- indicate player 1 won the game
						else
							player1score <= player1score + 1;
							hex1(7) <= '0'; -- player 1 to serve
						end if;
						player2serve <='1';
						hex5(7) <= '1'; -- turn off player 1 won last game
						hex4(7) <= '1'; -- turn off player 1 serve request
						collblop <= '1';
						led(6) <= '1';
				
					elsif bl_x1 < 5*scalebl then  -- player1 loses ball
						bl_xdelta    <= ballSpeed;
						bl_x1        <= 60;
						if player2score = 14 then -- game over player 2 wins
							player2score <= 0;
							player1score <= 0;
							hex0(7) <= '0'; -- player 2 wins game
						else
							player2score <= player2score + 1;
							hex5(7) <= '1'; 
						end if;
						player1serve <='1';
						collblop <= '1';
						led(6) <= '1';
						hex1(7) <= '1'; -- turn off player 2 serve request
						hex0(7) <= '1'; -- turn off player 2 won last game
					else
						bl_x1 <= bl_x1 + bl_xdelta; -- ball is in play or being bounced prior to serving
					end if;
				else -- someone has to serve the ball
					if (P_y1 > 400) and (player1serve = '1') then
						player1serve <= '0';
						hex5(7) <= '1';
					elsif (P_y2 > 400) and (player2serve = '1') then
						player2serve <= '0';
						hex0(7) <= '1';
					end if;
				end if;
        end if;
        if ((bl_y1 <= 60)) then
          bl_ydelta <= abs (bl_ydelta);
          bl_y1     <= 64;
			 sideblip <= '1';

        elsif (bl_y1 >= (v_pixels - 10 - 4*scalebl)) then
            bl_ydelta <= bl_ydelta *(-1);
            bl_y1     <= v_pixels - 10 - 6*scalebl;
				sideblip <= '1';
        else
            bl_y1 <= bl_y1 + bl_ydelta;

        
        end if;
      end if;
		counter <= counter + 1; -- led light feedback for debugging sounds etc
		if (counter = 50) then
			counter <= 0;
			led(0) <= flash;
			flash <= not flash;
			led(7) <= '0';
			led(6) <= '0';
		end if;
		
    end if;
  end process;
end MAIN;
