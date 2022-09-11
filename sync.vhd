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
	 led      : out    std_logic_vector(9 downto 0)

    );
end SYNC;


architecture MAIN of SYNC is
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
-----640x480 @ 60 Hz pixel clock 25 MHz
  constant h_pulse  : integer := 96;    --horiztonal sync pulse width in pixels
  constant h_bp     : integer := 48;    --horizontal back porch width in pixels
  constant h_pixels : integer := 640;   --horiztonal display width in pixels
  constant h_fp     : integer := 16;   --horiztonal front porch width in pixels
  constant v_pulse  : integer := 2;     --vertical sync pulse width in rows
  constant v_bp     : integer := 33;    --vertical back porch width in rows
  constant v_pixels : integer := 480;   --vertical display width in rows
  constant v_fp     : integer := 10;    --vertical front porch width in rows

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
  signal blip                        : std_logic;
  signal blop                        : std_logic;
  signal collblip                    : std_logic;
  signal collblop                    : std_logic;
  signal BL_X1                       : integer range 0 to 639  := 400;
  signal BL_Y1                       : integer range 0 to 479  := 400;
  signal nBlanking                   : std_logic               := '1';
  signal txtRGB                      : std_logic;
  signal scrAddress                  : std_logic_vector(11 downto 0);
  signal charpos                     : integer range 0 to 4191 := 0;
  signal thousands                   : integer range 0 to 255  := 0;
  signal hundreds                    : integer range 0 to 255  := 0;
  signal tens                        : integer range 0 to 255  := 0;
  signal unit                        : integer range 0 to 255  := 0;
  signal thousands2                  : integer range 0 to 255  := 0;
  signal hundreds2                   : integer range 0 to 255  := 0;
  signal tens2                       : integer range 0 to 255  := 0;
  signal unit2                       : integer range 0 to 255  := 0;
  signal scrData                     : std_logic_vector(7 downto 0);
  signal nWr                         : std_logic;
  signal RD0                         : std_logic_vector(3 downto 0);
  signal GD0                         : std_logic_vector(3 downto 0);
  signal BD0                         : std_logic_vector(3 downto 0);
  signal RD1                         : std_logic_vector(3 downto 0);
  signal GD1                         : std_logic_vector(3 downto 0);
  signal BD1                         : std_logic_vector(3 downto 0);
  signal RD2                         : std_logic_vector(3 downto 0);
  signal GD2                         : std_logic_vector(3 downto 0);
  signal BD2                         : std_logic_vector(3 downto 0);
  signal RT                          : std_logic_vector(3 downto 0);
  signal GT                          : std_logic_vector(3 downto 0);
  signal BT                          : std_logic_vector(3 downto 0);
  signal RBL                         : std_logic_vector(3 downto 0);
  signal GBL                         : std_logic_vector(3 downto 0);
  signal BBL                         : std_logic_vector(3 downto 0);
  signal GRIDR, GRIDG, GRIDB         : std_logic_vector(3 downto 0);
  signal DRAW0, DRAW1, drawBL 		 : std_logic               := '0';
  signal HPOS                        : integer range 0 to 799  := 0;
  signal VPOS                        : integer range 0 to 524  := 0;
--  signal sixtyHz                     : integer range 0 to 6    := 0;
  signal counter                     : integer range 0 to 9999 := 0;
  signal flash                       : std_logic;
--  signal scale                       : integer range 1 to 32   := 8;
  signal scaleP                      : integer range 1 to 32   := 8;
  signal scaleBL                     : integer range 1 to 32   := 2;
  signal playerScore                 : integer range 0 to 9999 := 0;
  signal playerScore2                : integer range 0 to 9999 := 0;
  signal direction1                  : std_logic;
  signal position1                   : integer;
  signal direction2                  : std_logic;
  signal position2                   : integer;
  signal bl_xdelta                   : integer range -4 to 4   := 1;
  signal bl_ydelta                   : integer range -4 to 4   := 1;
  signal collision                   : integer range 0 to 1    := 0;
  signal current_dir                 : integer range -1 to 1   := 1;
  signal ballSpeed                   : integer range 1 to 10   := 1;
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

  signal ball : std_logic_vector(99 downto 0) :=
    ('0', '0', '0', '0', '1', '1', '0', '0', '0', '0',
     '0', '0', '1', '1', '1', '1', '1', '1', '0', '0',
     '0', '1', '1', '1', '1', '1', '1', '1', '1', '0',
     '0', '1', '1', '1', '1', '1', '1', '1', '1', '0',
     '1', '1', '1', '1', '1', '1', '1', '1', '1', '1',
     '1', '1', '1', '1', '1', '1', '1', '1', '1', '1',
     '0', '1', '1', '1', '1', '1', '1', '1', '1', '0',
     '0', '1', '1', '1', '1', '1', '1', '1', '1', '0',
     '0', '0', '1', '1', '1', '1', '1', '1', '0', '0',
     '0', '0', '0', '0', '1', '1', '0', '0', '0', '0');
begin
  txtscr : txtScreen
    port map (hpos, vpos, scrAddress, scrData, nWr, Clk, nBlanking, txtRGB);
  paddleLeft  : quadrature_decoder port map (clk, encoder1(0), encoder1(1), not s(1), direction1, position1);
  paddleRight : quadrature_decoder port map (clk, encoder2(0), encoder2(1), not s(1), direction2, position2);
  thousands  <= 48 + ((playerScore / 1000) mod 10);
  hundreds   <= 48 + ((playerScore / 100) mod 10);
  tens       <= 48 + ((playerScore / 10) mod 10);
  unit       <= 48 + (playerScore mod 10);
  thousands2 <= 48 + ((playerScore2 / 1000) mod 10);
  hundreds2  <= 48 + ((playerScore2 / 100) mod 10);
  tens2      <= 48 + ((playerScore2 / 10) mod 10);
  unit2      <= 48 + (playerScore2 mod 10);
  SPR(HPOS, VPOS, P_X1, P_Y1, paddle, scaleP, DRAW0);
  SPR(HPOS, VPOS, P_X2, P_Y2, paddle, scaleP, DRAW1);
  SP(HPOS, VPOS, BL_X1, BL_Y1, ball, scaleBL, DRAWBL);

  process(CLK)
  begin
    if(CLK'event and CLK = '0')then
		if (collblip = '1') or (blip = '1') then
			if (blipcnt < 5000000) then
           blipcnt <= blipcnt + 1;
			  blip <= '1';
			  led(9) <= '1';
			else
			  blip <= '0';
			  led(9) <= '0';
			  blipcnt <= 1;
			end if;
		end if;
		if (collblop = '1') or (blop = '1') then
			if (blopcnt < 10000000) then
			  blopcnt <= blopcnt + 1;
           blop <= '1';
			  led(8) <= '1';
			else
			  blop <= '0';
			  led(8) <= '0';
			  blopcnt <= 1;
			end if;
		end if;
      if (cycle = '0') then             -- write data to text screen ram
        cycle <= '1';
        nwr   <= '0';
      end if;
      if (cycle = '1') then
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
        if (charpos = 84) then
          scrData <= std_logic_vector(to_unsigned(thousands, scrData'length));
          nwr     <= '1';
        end if;
        if (charpos = 85) then
          scrData <= std_logic_vector(to_unsigned(hundreds, scrdata'length));
          nwr     <= '1';
        end if;
        if (charpos = 86) then
          scrData <= std_logic_vector(to_unsigned(tens, scrdata'length));
          nwr     <= '1';
        end if;
        if (charpos = 87) then
          scrData <= std_logic_vector(to_unsigned(unit, scrdata'length));
          nwr     <= '1';
        end if;
        if (charpos = 152) then
          scrData <= std_logic_vector(to_unsigned(thousands2, scrData'length));
          nwr     <= '1';
        end if;
        if (charpos = 153) then
          scrData <= std_logic_vector(to_unsigned(hundreds2, scrdata'length));
          nwr     <= '1';
        end if;
        if (charpos = 154) then
          scrData <= std_logic_vector(to_unsigned(tens2, scrdata'length));
          nwr     <= '1';
        end if;
        if (charpos = 155) then
          scrData <= std_logic_vector(to_unsigned(unit2, scrdata'length));
          nwr     <= '1';
        end if;
-- net
		  if (charpos > 400) and ((charpos MOD 80) = 40) and (charpos < 3160) then
          scrData <= char2std('|');
          nwr     <= '1';
        end if;
--		  if (charpos = 541) then
--          scrData <= x"a1";
--          nwr     <= '1';
--        end if;
--		  if (charpos = 542) then
--          scrData <= x"a2";
--          nwr     <= '1';
--        end if;
--		  if (charpos = 543) then
--          scrData <= x"a3";
--          nwr     <= '1';
--        end if;
--		  if (charpos = 544) then
--          scrData <= x"a4";
--          nwr     <= '1';
--        end if;
--		  if (charpos = 545) then
--          scrData <= x"a5";
--          nwr     <= '1';
--        end if;
--		  if (charpos = 546) then
--          scrData <= x"a6";
--          nwr     <= '1';
--        end if;
--		  if (charpos = 547) then
--          scrData <= x"a7";
--          nwr     <= '1';
--        end if;
--		  if (charpos = 548) then
--          scrData <= x"a8";
--          nwr     <= '1';
--        end if;
--		  if (charpos = 549) then
--          scrData <= x"a9";
--          nwr     <= '1';
--        end if;
--		  if (charpos = 550) then
--          scrData <= x"aa";
--          nwr     <= '1';
--        end if;
--		  if (charpos = 551) then
--          scrData <= x"ab";
--          nwr     <= '1';
--        end if;
--		  if (charpos = 552) then
--          scrData <= x"ac";
--          nwr     <= '1';
--        end if;
--		  if (charpos = 553) then
--          scrData <= x"ad";
--          nwr     <= '1';
--        end if;
--		  if (charpos = 554) then
--          scrData <= x"ae";
--          nwr     <= '1';
--        end if;
--		  if (charpos = 555) then
--          scrData <= x"af";
--          nwr     <= '1';
--        end if;

        charpos    <= charpos + 1;
        scrAddress <= std_logic_vector(to_unsigned(charpos, scraddress'length));
      end if;
      if (keys(9) = '1') then
        ballSpeed <= 2;
      else
        ballSpeed <= 1;
      end if;
      if(DRAWBL = '1')then
        RBL <= (others => '1');
        GBL <= (others => '1');
        BBL <= (others => '1');
      else
        RBL <= (others => '0');
        GBL <= (others => '0');
        BBL <= (others => '0');
      end if;
      if(DRAW0 = '1')then
        RD0 <= (others => '1');
        GD0 <= (others => '0');
        BD0 <= (others => '1');
      else
        RD0 <= (others => '0');
        GD0 <= (others => '0');
        BD0 <= (others => '0');
      end if;
      if(DRAW1 = '1')then
        RD1 <= (others => '0');
        GD1 <= (others => '1');
        BD1 <= (others => '1');
      else
        RD1 <= (others => '0');
        GD1 <= (others => '0');
        BD1 <= (others => '0');
      end if;
      if (txtRGB = '1') then
        RT <= (others => '1');
        GT <= (others => '1');
        BT <= (others => '1');
      else
        RT <= (others => '0');
        GT <= (others => '0');
        BT <= (others => '0');
      end if;
		if (VPOS = 50) or (VPOS = (v_pixels - 7)) then
		  GRIDR <= (others => '1');
		  GRIDG <= (others => '1');
		  GRIDB <= (others => '1');
		else
		  GRIDR <= (others => '0');
		  GRIDG <= (others => '0');
		  GRIDB <= (others => '0');
		end if;
      P_y1 <= position1 * 8;
      p_y2 <= position2 * 8;
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
      if(HPOS > (h_pixels + h_fp) and HPOS < (h_pixels + h_fp + h_pulse))then  ----HSYNC
        ooHSYNC <= '0';
        hsync   <= oohsync;
      else
        ooHSYNC <= '1';
        hsync   <= oohsync;
      end if;
      if (vpos > (v_pixels + v_fp) and VPOS < (v_pixels + v_fp + v_pulse))then  ----------vsync
        oovSYNC <= '0';
        vsync   <= oovsync;

      else
        ooVSYNC <= '1';
        vsync   <= oovsync;

      end if;
    end if;
  end process;
  process (vsync)
  begin  -- move or scale stuff
    if (vsync'event and vsync = '0') then
		if (collblip = '1') then collblip <= '0'; end if;
		if (collblop = '1') then collblop <= '0'; end if;
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
                  bl_ydelta <= ballSpeed * (2);
                end if;
              end if;
            end if;
          end if;
        else

          if bl_x1 >= (h_pixels - scalebl*5) then
            bl_xdelta   <= ballSpeed *(-1);
            bl_x1       <= 380;
            playerScore <= playerScore + 1;
				collblop <= '1';
				led(6) <= '1';
          else
            if bl_x1 < 5*scalebl then
              bl_xdelta    <= ballSpeed;
              bl_x1        <= 280;
              playerScore2 <= playerScore2 + 1;
				  collblop <= '1';
				  led(6) <= '1';
            else
              bl_x1 <= bl_x1 + bl_xdelta;
            end if;
          end if;
        end if;
        if ((bl_y1 <= 51 + 4*scalebl)) then
          bl_ydelta <= abs (bl_ydelta);
          bl_y1     <= 51 + 6*scaleBl;

        else
          if (bl_y1 >= (v_pixels - 10 - 4*scalebl)) then
            bl_ydelta <= bl_ydelta *(-1);
            bl_y1     <= v_pixels - 10 - 6*scalebl;
          else
            bl_y1 <= bl_y1 + bl_ydelta;

          end if;
        end if;
      end if;
		counter <= counter + 1;
		if (counter = 50) then
--			collblip <= '0';
--			collblop <= '0';
			counter <= 0;
			led(0) <= flash;
			flash <= not flash;
			led(7) <= '0';
			led(6) <= '0';
		end if;
		
    end if;
  end process;
end MAIN;
