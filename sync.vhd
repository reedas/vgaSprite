library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.dw.all;
use work.dw2.all;

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
    encoder2 : in     std_logic_vector(2 downto 0)
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
  signal P_Y1                        : integer range 0 to 479  := 60;
  signal P_X2                        : integer range 0 to 639  := 620;
  signal P_Y2                        : integer range 0 to 479  := 60;
  signal SQ_X1                       : integer range 0 to 639  := 200;
  signal SQ_Y1                       : integer range 0 to 479  := 200;
  signal SQ_X2                       : integer range 0 to 639  := 300;
  signal SQ_Y2                       : integer range 0 to 479  := 300;
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
  signal DRAW0, DRAW1, DRAW2, drawBL : std_logic               := '0';
  signal HPOS                        : integer range 0 to 799  := 0;
  signal VPOS                        : integer range 0 to 524  := 0;
  signal sixtyHz                     : integer range 0 to 6    := 0;
  signal count100ms                  : integer range 0 to 9999 := 0;
  signal scale                       : integer range 1 to 32   := 8;
  signal scaleP                      : integer range 1 to 32   := 8;
  signal scaleBL                     : integer range 1 to 32   := 2;
  signal colCount                    : integer range 0 to 9999 := 0;
  signal colCount2                   : integer range 0 to 9999 := 0;
  signal direction1                  : std_logic;
  signal position1                   : integer;
  signal direction2                  : std_logic;
  signal position2                   : integer;
  signal bl_xdelta                   : integer range -2 to 2   := 1;
  signal bl_ydelta                   : integer range -2 to 2   := 1;
  signal collision                   : integer range 0 to 1    := 0;
  signal current_dir                 : integer range -1 to 1   := 1;
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

--signal asteroid1 : std_logic_vector(99 downto 0) := 
--                                                                        ('0','0','0','0','1','1','0','0','0','0',
--                                                                              '0','0','0','1','1','1','1','0','0','0',
--                                                                              '0','0','0','1','1','1','1','1','1','0',
--                                                                              '0','0','1','1','1','1','1','1','1','0',
--                                                                              '1','1','1','1','0','0','1','1','1','1',
--                                                                              '1','1','1','0','0','0','0','1','1','1',
--                                                                              '1','1','1','1','0','0','1','1','1','1',
--                                                                              '0','0','1','1','1','1','1','1','1','0',
--                                                                              '0','0','1','1','1','1','1','0','0','0',
--                                                                              '0','0','0','1','1','1','0','0','0','0');
--signal asteroid2 : std_logic_vector(99 downto 0) := 
--                                                                        ('0','0','0','0','1','1','0','0','0','0',
--                                                                              '0','0','0','1','0','0','1','0','0','0',
--                                                                              '0','0','0','1','0','0','0','1','1','0',
--                                                                              '0','0','1','0','0','0','0','0','1','0',
--                                                                              '0','1','0','0','0','0','0','0','0','1',
--                                                                              '1','0','0','0','0','0','0','0','0','1',
--                                                                              '1','1','0','0','0','0','0','0','0','1',
--                                                                              '0','0','1','0','0','0','0','1','1','0',
--                                                                              '0','0','1','0','0','0','1','0','0','0',
--                                                                              '0','0','0','1','1','1','0','0','0','0');
  signal ablock : std_logic_vector(99 downto 0) :=
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
  thousands <= 48 + ((colcount / 1000) mod 10);
  hundreds  <= 48 + ((colcount / 100) mod 10);
  tens      <= 48 + ((colcount / 10) mod 10);
  unit      <= 48 + (colcount mod 10);
  SPR(HPOS, VPOS, P_X1, P_Y1, paddle, scaleP, DRAW0);
  SPR(HPOS, VPOS, P_X2, P_Y2, paddle, scaleP, DRAW1);
--SP(HPOS,VPOS,SQ_X1,SQ_Y1,asteroid1,scale,DRAW1);
--SP(HPOS,VPOS,SQ_X2,SQ_Y2,asteroid2,scale,DRAW2);
  SP(HPOS, VPOS, BL_X1, BL_Y1, ablock, scaleBL, DRAWBL);

  process(CLK)
  begin
    if(CLK'event and CLK = '0')then
--SPR(HPOS,VPOS,P_X1,P_Y1,paddle,scaleP,DRAW0);
--SP(HPOS,VPOS,SQ_X1,SQ_Y1,asteroid1,scale,DRAW1);
--SP(HPOS,VPOS,SQ_X2,SQ_Y2,asteroid2,scale,DRAW2);
--SP(HPOS,VPOS,BL_X1,BL_Y1,ablock,scaleBL,DRAWBL);
      if (cycle = '0') then
        cycle <= '1';
        nwr   <= '0';
      end if;
      if (cycle = '1') then
        cycle <= '0';
        if (charpos = 0) then
          scrData <= std_logic_vector(to_unsigned(thousands, scrData'length));
          nwr     <= '1';
        end if;
        if (charpos = 1) then
          scrData <= std_logic_vector(to_unsigned(hundreds, scrdata'length));
          nwr     <= '1';
        end if;
        if (charpos = 2) then
          scrData <= std_logic_vector(to_unsigned(tens, scrdata'length));
          nwr     <= '1';
        end if;
        if (charpos = 3) then
          scrData <= std_logic_vector(to_unsigned(unit, scrdata'length));
          nwr     <= '1';
        end if;

        charpos    <= charpos + 1;
        scrAddress <= std_logic_vector(to_unsigned(charpos, scraddress'length));
      end if;
--      IF(DRAW1='1')THEN
--                      IF(S(0)='1')THEN
--                              RD1<=(others=>'1');
--                              GD1<=(others=>'0');
--                              BD1<=(others=>'0');
--                      ELSE
--                              RD1<=(others=>'0');
--                              GD1<=(others=>'0');
--                              BD1<=(others=>'1');
--                      END IF;
--              else
--                      RD1<=(others=>'0');
--            GD1<=(others=>'0');
--            BD1<=(others=>'0');
--      END IF;
--              IF(DRAW2='1')THEN
--                      IF(S(1)='1')THEN
--                              RD2<=(others=>'0');
--                              GD2<=(others=>'1');
--                              BD2<=(others=>'0');
--                      ELSE
--                              RD2<=(others=>'0');
--                              GD2<=(others=>'1');
--                              BD2<=(others=>'1');
--                END IF;
--              else
--                      RD2<=(others=>'0');
--            GD2<=(others=>'0');
--            BD2<=(others=>'0');
--      END IF;
      if(DRAWBL = '1')then
        RBL <= (others => '1');
        GBL <= (others => '0');
        BBL <= (others => '1');
      else
        RBL <= (others => '0');
        GBL <= (others => '0');
        BBL <= (others => '0');
      end if;
--              if (txtRGB = '1') then
--                      RT<=(others=>'1');
--                      GT<=(others=>'1');
--                      BT<=(others=>'1');
--              ELSE
--                      RT<=(others=>'0');
--                      GT<=(others=>'0');
--                      BT<=(others=>'0');
--              END IF;
      if(DRAW0 = '1')then
        RD0 <= (others => '1');
        GD0 <= (others => '1');
        BD0 <= (others => '1');
      else
        RD0 <= (others => '0');
        GD0 <= (others => '0');
        BD0 <= (others => '0');
      end if;
      if(DRAW1 = '1')then
        RD1 <= (others => '1');
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
--                            IF(S(0)='1')THEN
--                                          IF(KEYS(0)='1')THEN
--                                                SQ_X1<=(SQ_X1+5) MOD 640;
--                                               END IF;
--                   IF(KEYS(1)='1')THEN
--                                                SQ_X1<=(SQ_X1-5) MOD 640;
--                                               END IF;
--                                                IF(KEYS(2)='1')THEN
--                                                SQ_Y1<=SQ_Y1-5;
--                                               END IF;
--                                               IF(KEYS(3)='1')THEN
--                                                SQ_Y1<=SQ_Y1+5;
--                                               END IF; 
--                                               if(KEYS(9)='1') then
--                                                P_y1<=p_y1-1;
--                                               end if;
--                                      END IF;
--                            IF(S(1)='1')THEN
--                                          IF(KEYS(0)='1')THEN
--                                                SQ_X2<=(SQ_X2+5) MOD 640;
--                                               END IF;
--                   IF(KEYS(1)='1')THEN
--                                                SQ_X2<=(SQ_X2-5) MOD 640;
--                                               END IF;
--                                               IF(KEYS(2)='1')THEN
--                                                SQ_Y2<=SQ_Y2-5;
--                                               END IF;
--                                               IF(KEYS(3)='1')THEN
--                                                SQ_Y2<=SQ_Y2+5;
--                                               END IF; 
----                                             if(KEYS(9)='1') then
----                                              P_y1<=p_y1+1;
----                                             end if;
--                                      END IF;  
        end if;
      end if;
      if((HPOS > h_pixels) or (VPOS > v_pixels))then
        R         <= (others => '0');
        G         <= (others => '0');
        B         <= (others => '0');
        nblanking <= '0';
      else
--                      R<= RD0 or RD1 or RD2 or RBL or RT;
--                      G<= GD0 or GD1 or GD2 or GBL or GT;
--                      B<= BD0 or BD1 or BD2 or BBL or BT;
        R         <= RD0 or RD1 or RBL or RT;
        G         <= GD0 or GD1 or GBL or GT;
        B         <= BD0 or BD1 or BBL or BT;
        nBlanking <= '1';
--                      if (RBL = "1111" and GD0 = "1111") then 
--                              collision <= 1;
--                              --scaleBL <= 1;
--                              current_dir <= current_dir * (-1);
--                              colCount <= colCount + 1;
----                            scrData <= std_logic_vector(to_unsigned(colCount, scrdata'length));
----                            scrAddress(7 downto 0) <= scrData;
----                            nwr <= '1';
--                              if BL_Y1 = 0 then BL_y1 <= 470; end if;
--                              
--                      end if;
--                      if (RBL = "1111" and GD0 = "0000") then
--                              collision <= 0;
--                              --scaleBL <= 2;
--
--                      end if;

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
      if ((p_X1 + 2 * scaleP) = bl_x1) and ((BL_y1 - p_y1) > 0) and ((bl_y1 - p_y1) < 10 * scaleP) then  -- bat hits ball
--                      current_dir <= 1;
        bl_xdelta <= 1;
        bl_x1     <= p_x1 + 20;
        colCount  <= colCount + 1;
        if ((bl_y1 - p_y1) < 16) then
          bl_ydelta <= -2;
        else
          if ((bl_y1 - p_y1) < 32) then
            bl_ydelta <= -1;
          else
            if ((bl_y1 - p_y1) < 48) then
              bl_ydelta <= 0;
            else
              if ((bl_y1 - p_y1) < 64) then
                bl_ydelta <= 1;

              else
                bl_ydelta <= 2;
              end if;
            end if;
          end if;
        end if;
      else
        if (p_X2 = (bl_x1 + scaleP)) and ((BL_y1 - p_y2) > 0) and ((bl_y1 - p_y2) < 10 * scaleP) then  -- bat hits ball
          bl_xdelta <= bl_xdelta * (-1);
          bl_x1     <= p_x2 - 10;
          colCount2 <= colCount2 + 1;
          if ((bl_y1 - p_y2) < 16) then
            bl_ydelta <= -2;
          else
            if ((bl_y1 - p_y2) < 32) then
              bl_ydelta <= -1;
            else
              if ((bl_y1 - p_y2) < 48) then
                bl_ydelta <= 0;
              else
                if ((bl_y1 - p_y2) < 64) then
                  bl_ydelta <= 1;

                else
                  bl_ydelta <= 2;
                end if;
              end if;
            end if;
          end if;
--        end if;
        else

          if bl_x1 >= (h_pixels - scalebl*5) then
            bl_xdelta <= -1;
            bl_x1     <= h_pixels - scalebl*6;

--                              current_dir <= -1;
          else
            if bl_x1 < 5*scalebl then
              bl_xdelta <= 1;
              bl_x1     <= 380;
              colCount  <= 0;
--                              current_dir <= 1;
            else
              bl_x1 <= bl_x1 + bl_xdelta;
            end if;
          end if;
        end if;
        if ((bl_y1 <= 5*scalebl)) then
          bl_ydelta <= bl_ydelta *(-1);
          bl_y1     <= 5*scalebl + 1;

        else
          if (bl_y1 >= (v_pixels -5 *scalebl)) then
            bl_ydelta <= bl_ydelta *(-1);
            bl_y1     <= v_pixels - 6*scalebl;
          else
            bl_y1 <= bl_y1 + bl_ydelta;

          end if;
        end if;
      end if;
      sixtyHz <= sixtyHz + 1;
      if (sixtyHz > 5) then
        count100ms <= count100ms + 1;
        sixtyHz    <= 0;
        scale      <= scale + 1;
      end if;
    end if;


  end process;
end MAIN;