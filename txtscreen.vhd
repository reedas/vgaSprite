library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;


entity txtScreen is
--       generic(); -- pixel position
  port(
    hp, vp :    integer;
    addr   : in std_logic_vector(11 downto 0);  -- text screen ram
    data   : in std_logic_vector(7 downto 0);
    nWr    : in std_logic;
    pClk   : in std_logic;
    nblnk  : in std_logic;

    pix : out std_logic

    );
end txtScreen;

architecture RTL of txtScreen is

  component charrom
    port
      (
        address : in  std_logic_vector (10 downto 0);
        clock   : in  std_logic := '1';
        q       : out std_logic_vector (7 downto 0)
        );
  end component;
  component dispmem
    port
      (
        clock     : in  std_logic := '1';
        data      : in  std_logic_vector (7 downto 0);
        rdaddress : in  std_logic_vector (11 downto 0);
        wraddress : in  std_logic_vector (11 downto 0);
        wren      : in  std_logic := '0';
        q         : out std_logic_vector (7 downto 0)
        );
  end component;
  signal char_row_addr : std_logic_vector(10 downto 0);
  signal q_8x12        : std_logic_vector(7 downto 0);
  signal vaddr         : std_logic_vector(11 downto 0);
  signal vdata         : std_logic_vector(7 downto 0);
  signal shifter       : std_logic_vector(7 downto 0);
  signal nClk          : std_logic;
  signal hpi           : integer range 0 to 2000;

begin

  font8x12_inst : charrom port map (
    address => char_row_addr,
    clock   => pClk,
    q       => q_8x12
    );
  dispmem_inst : dispmem port map (
    clock     => pClk,
    data      => data,
    rdaddress => vAddr,
    wraddress => addr,
    wren      => nWr,
    q         => vData
    );
  vAddr         <= std_logic_vector(to_unsigned(80*((vp)/12) + (hp/8), 12));
  char_row_addr <= std_logic_vector(to_unsigned(((conv_integer(vdata(7 downto 0)) -32)*12 + vp mod 12), 11));
--      process(pClk)
--              begin
--                      if pClk'event and pClk = '1' then
--                              if nblnk = '1' then
--                                      hpi <= hpi + 1;
--                              else 
--                                      hpi <= 0;
--                                      
--                              end if;
--                      end if;                                 
--      end process;

--      process(pclk)
--              begin
----            if (nblnk = '1' and hp mod 8 = 0) then shifter(7 downto 0) <= q_8x12(7 downto 0);
----            else 
----            end if; 
--      end process;
  process(pClk)
  begin
    shifter(7 downto 0) <= q_8x12(7 downto 0);
    if (pClk'event and pClk = '0') then
      pix <= shifter(7- (hp-1 mod 8));
    end if;
  end process;
end RTL;
