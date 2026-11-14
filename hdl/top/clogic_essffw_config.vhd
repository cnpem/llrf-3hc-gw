--------------------------------------------------------------------------------
-- Project     : ESS FPGA Framework
--------------------------------------------------------------------------------
-- File        : custom_logic_test_essffw_config_pkg.vhdl
-- Authors     : Christian Amstutz
-- Created     : 2018-03-07
-- Platform    :
-- Standard    : VHDL'93
--------------------------------------------------------------------------------
-- Description : Package containing the specific configuration for the ESS FPGA
--               Framework for the test custom logic.
--------------------------------------------------------------------------------
-- Copyright (c) 2017 - 2025  European Spallation Source ERIC
--------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;

library essffw_config;
use essffw_config.essffw_config_types.all;
use essffw_config.board_essffw_config;
use essffw_config.blank_fsp_essffw_config;
use essffw_config.clogic_essffw_config_helpers.all;


package clogic_essffw_config is

  -- Select the ADC channels processed by the framework core
  constant CORE_ADC_CH_SELECT : t_core_adc_ch_select_config := (
    BSP  => (offset => 0, count  => board_essffw_config.NR_ADC_CHANNELS),
    RSP  => (offset => 0, count  => 0),
    FSP1 => (offset => 0, count  => 0),
    FSP2 => (offset => 0, count  => 0)
  );

  --! Number of total ADC channels (must be written as number)
  constant NR_ADC_CHANNELS      : integer := 10;

  --! Switch to enable/disable the ADC preprocessing block in the framework core
  constant ADC_PREPROC_ENABLE   : boolean := true;

  --! Switches to run ADC pre-processing of each channel synchronous with the ADC clocks.
  constant ADC_PREPROC_SYNC_OP     : boolean_vector(0 to 9) := (others => false);

  --! Switches to include the near-IQ sampling for the individual channels of the ADC pre-processing
  constant ADC_PREPROC_NEARIQ_INCL : boolean_vector(0 to 9) := (others => true);

  --! Switches to include the low-pass filters for the individual channels of the ADC pre-processing
  constant ADC_PREPROC_LP_INCL     : boolean_vector(0 to 9) := (others => true);

  --! Switch to include the memory interface of the ADC pre-processing block
  constant ADC_PREPROC_MEM_IF_INCL : boolean := true;

  --! Switch to select pre-processing clock (internal or external)
  constant INTERNAL_PREPROC_CLK_ENABLE  : boolean := true;

  --! Resolution of the ADCs
  constant ADC_RESOLUTION       : integer := 16;

  --! Resolution for saturation check
  constant ADC_SAT_RESOLUTION   : integer := ADC_RESOLUTION;

  --! Timestamp max count
  constant TIMESTAMP_MAX_CNT : natural := 125000000;

  --! Driving frontpanel LED from custom logic
  constant LED_FROM_CSTMLOG : boolean := false;

  --! BSP P2P enable
  constant P2P_SUBSYS_ENABLE : boolean := true;

  --! Framework waveform replay subsystem enable
  constant REPLAY_SUBSYS_ENABLE : boolean := true;

  --! Number of channels of the replay system
  constant REPLAY_SUBSYS_CHANNEL_CNT : natural := 10;

  --! Mapping of replay channels to the ADC input channels
  constant REPLAY_TO_INPUT_CH_MAPPING : t_replay_ch_mapping := (
    0 => 0,
    1 => 1,
    2 => 8,
    3 => 9,
    others => 0
  );
  -- := direct_mapping;

  constant REPLAY_REVERSE_MAPPING : t_reverse_mapping := get_reverse_mapping(REPLAY_TO_INPUT_CH_MAPPING);

  --! Switch to include the offset and scaler mdule to all ADC channels
  constant ADC_OFFSET_SCALE_INCL : boolean := true;

  --! Framework DAQ Pipeline feature enable
  constant FW_DAQ_PIPELINE_INCL : boolean := true;

  --! Framework DOD buffer enabled instead of axis2maxi
  constant FW_DOD_INCL : boolean := false;

  --! Framework Linear buffer(Axis2maxi) enabled
  constant FW_AXIS2MAXI_INCL : boolean := true;

  --! Switch to override the daq done and active signal by the custom logic layer
  constant OVR_DAQ_DONE_ACTIVE_ENABLE : boolean := true;

  --! Mapping addresses, set to 0xFFFFFFFF if not used.
  --! Note currently its not possible to change the address decoding based on
  --! these constant. So changing the offset will require manual update of
  --! the register interconnect inside the framework.
  constant BSP_BASE_ADDR     : std_logic_vector(31 downto 0) := x"0040_0000";
  constant RSP_BASE_ADDR     : std_logic_vector(31 downto 0) := x"0080_0000";
  constant FSP1_BASE_ADDR    : std_logic_vector(31 downto 0) := x"FFFF_FFFF";
  constant FSP2_BASE_ADDR    : std_logic_vector(31 downto 0) := x"FFFF_FFFF";
  constant CSTMLOG_BASE_ADDR : std_logic_vector(31 downto 0) := x"00C0_0000";

  --! Project ID (should probably match custom logic ID...)
  --! All zeroes is reserved for an empty project.
  constant PROJECT_ID : std_logic_vector(31 downto 0) := x"0000_0000";

  --! Updated by scripts (DO NOT MODIFY!)
  constant PROJECT_GIT_HASH : std_logic_vector(31 downto 0) := x"00999db7";
  constant PROJECT_BUILD_NR : integer := 125 ;

  ------------------------------------------------------------------------------
  -- Configuration of FSP feature types. (Blank for sis8300)
  ------------------------------------------------------------------------------

  -- FMC 1 features
  constant FSP1_ADC_CH_COUNT   : natural  := blank_fsp_essffw_config.ADC_CHANNEL_COUNT;
  constant FSP1_ADC_RESOLUTION : positive := blank_fsp_essffw_config.ADC_RESOLUTION;

  -- FMC 2 features
  constant FSP2_ADC_CH_COUNT   : natural  := blank_fsp_essffw_config.ADC_CHANNEL_COUNT;
  constant FSP2_ADC_RESOLUTION : positive := blank_fsp_essffw_config.ADC_RESOLUTION;

end clogic_essffw_config;


package body clogic_essffw_config is
  -- EMPTY
end clogic_essffw_config;