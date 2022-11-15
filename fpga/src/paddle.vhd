library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;


entity paddles is
    port (
        -- Clocks
        MAX10_CLK1_50   : in std_logic;
        -- KEY
        reset           : in std_logic;
        -- paddle postioins from adc
        player1			: out std_logic_vector(7 downto 0);
        player2			: out std_logic_vector(7 downto 0)
    );
end entity;


architecture A of paddles is
    component hello_adc is
        port (
            --  adc_control_core_command.valid
            adc_control_core_command_valid          : in  std_logic;
            -- .channel
            adc_control_core_command_channel        : in  std_logic_vector(4 downto 0) := (others => '0');
            -- .startofpacket
            adc_control_core_command_startofpacket  : in  std_logic := '0';
            -- .endofpacket
            adc_control_core_command_endofpacket    : in  std_logic := '0';
            -- .ready
            adc_control_core_command_ready          : out std_logic;
            -- adc_control_core_response.valid
            adc_control_core_response_valid         : out std_logic;
            -- .channel
            adc_control_core_response_channel       : out std_logic_vector(4 downto 0);
            -- .data
            adc_control_core_response_data          : out std_logic_vector(11 downto 0);
            -- .startofpacket
            adc_control_core_response_startofpacket : out std_logic;
            -- .endofpacket
            adc_control_core_response_endofpacket   : out std_logic;
            -- clk.clk
            clk_clk                                 : in  std_logic := '0';
            -- clock_bridge_out_clk.clk
            clock_bridge_out_clk_clk                : out std_logic;
            -- reset.reset_n
            reset_reset_n                           : in  std_logic := '0'
        );
    end component hello_adc;

    -- ADC signals
    signal req_channel, cur_channel : std_logic_vector(4 downto 0);
    signal sample_data1              : std_logic_vector(11 downto 0);
    signal sample_data2              : std_logic_vector(11 downto 0);
    signal sample_data3              : std_logic_vector(11 downto 0);
    signal adc_cc_command_ready     : std_logic;
    signal adc_cc_response_valid    : std_logic;
    signal adc_cc_response_channel  : std_logic_vector(4 downto 0);
    signal adc_cc_response_data     : std_logic_vector(11 downto 0);
	 
	 -- paddle selection (Channel 001 or 011)
--	 signal paddle : std_logic_vector(4 downto 0) := "00001";
	 signal player : std_logic;

    -- BCD signals
    signal ones        : std_logic_vector(3 downto 0);
    signal tenths      : std_logic_vector(3 downto 0);
    signal hundredths  : std_logic_vector(3 downto 0);
    signal thousandths : std_logic_vector(3 downto 0);

    -- system clock and reset
    signal sys_clk, nreset : std_logic;
begin
    -- system reset
--    reset <= not KEY(0);
    nreset <= not reset;

    -- calculate channel used for sampling
    -- Available channels on DE10-Lite are 1-6
    -- use paddle vector to select the channel
    -- player = '0' map to arduino ADC_IN0
    -- player = '1' map to arduino ADC_IN2
    adc_command : process(sys_clk, player, adc_cc_command_ready)
        variable temp : std_logic_vector(4 downto 0) := "00001";
    begin
        if rising_edge(sys_clk) then
            if (adc_cc_command_ready = '1') then
					if player = '0' then
						req_channel <= "00001";
					else
						req_channel <= "00011";
					end if;
--			temp := std_logic_vector(unsigned(paddle));
            end if;
        end if;

    end process;

    -- read the sampled value from the ADC
    adc_read : process(sys_clk, adc_cc_response_valid)
        variable reading : std_logic_vector(11 downto 0) := (others => '0');
        variable ch      : std_logic_vector(4 downto 0) := (others => '0');
    begin
        if rising_edge(sys_clk) then
            if (adc_cc_response_valid = '1') then
                reading := adc_cc_response_data;
                ch := adc_cc_response_channel;
					if (ch = "00001") then
						player1 <= reading(11 downto 4);
						player <= '1' ; -- flip to channel 3
					elsif (ch = "00011") then
						player2 <= reading(11 downto 4);
						player <= '0'; -- flip to channel 1
					end if;
				end if;
        end if;
        cur_channel <= ch;

    end process;
	 

    -- instantiate QSYS subsystem with ADC and PLL
    qsys_u0 : component hello_adc
    port map (
        -- command always valid
        adc_control_core_command_valid => '1',
        adc_control_core_command_channel => req_channel,
        -- startofpacket and endofpacket are ignored in adc_control_core
        adc_control_core_command_startofpacket => '1',
        adc_control_core_command_endofpacket => '1',
        adc_control_core_command_ready => adc_cc_command_ready,
        adc_control_core_response_valid => adc_cc_response_valid,
        adc_control_core_response_channel => adc_cc_response_channel,
        adc_control_core_response_data => adc_cc_response_data,
        adc_control_core_response_startofpacket => open,
        adc_control_core_response_endofpacket => open,
        clk_clk => MAX10_CLK1_50,
        clock_bridge_out_clk_clk => sys_clk,
        reset_reset_n => nreset
    );
end architecture A;
