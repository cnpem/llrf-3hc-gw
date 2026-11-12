--------------------------------------------------------------------------------
-- Title        : 3rd Hamonic Low-Level Radio Frequency Top-Level Digital Signal
--                Processing Chain With Diagnostics ESSFFW Configuration Package
-- Project      : 3rd Hamonic Low-Level Radio Frequency
--------------------------------------------------------------------------------
-- File         : custom_logic_test_essffw_config_pkg.vhdl
-- Author       : Guilherme Ricioli Cruz
-- Company      : CNPEM
-- Platform     : Synthesis
-- Standard     : VHDL'08
--------------------------------------------------------------------------------
-- Description : Package containing the custom logic configurations expected by
--               European Spallation Source FPGA Framework.
--------------------------------------------------------------------------------
-- Copyright (c) 2026 CNPEM
--------------------------------------------------------------------------------

library ieee;
  use ieee.std_logic_1164.all;

library essffw_config;
  use essffw_config.board_essffw_config;
  use essffw_config.blank_fsp_essffw_config;
  use essffw_config.clogic_essffw_config_helpers.all;
  use essffw_config.essffw_config_types.all;

package clogic_essffw_config is
  ------------------------------------------------------------------------------
  -- ADC
  ------------------------------------------------------------------------------
  -- Channels processed by the Framework
  constant CORE_ADC_CH_SELECT           : t_core_adc_ch_select_config := (
    BSP  => (
      offset => 0,
      count  => board_essffw_config.NR_ADC_CHANNELS
    ),
    RSP  => (
      offset => 0,
      count  => 0
    ),
    FSP1 => (
      offset => 0,
      count  => 0
    ),
    FSP2 => (
      offset => 0,
      count  => 0
    )
  );

  -- Number of channels
  constant NR_ADC_CHANNELS              : integer := 10;

  -- Resolution
  constant ADC_RESOLUTION               : integer := 16;

  -- Resolution for saturation check
  constant ADC_SAT_RESOLUTION           : integer := ADC_RESOLUTION;

  ------------------------------------------------------------------------------
  -- ADC Pre-Processing
  ------------------------------------------------------------------------------
  -- Enable
  -- TODO: Check what this does
  constant ADC_PREPROC_ENABLE   : boolean := true;

  -- Run ADC Pre-Processing synchronous with the ADC clocks
  constant ADC_PREPROC_SYNC_OP          : boolean_vector(0 to 9) := (
    others => false
  );

  -- Include near-IQ sampling
  -- TODO: Check this
  constant ADC_PREPROC_NEARIQ_INCL      : boolean_vector(0 to 9) := (
    others => true
  );

  -- Include low-pass filters
  -- TODO: Check this
  constant ADC_PREPROC_LP_INCL          : boolean_vector(0 to 9) := (
    others => true
  );

  -- Include ADC Pre-processing memory interface
  constant ADC_PREPROC_MEM_IF_INCL      : boolean := true;

  -- Select ADC Pre-processing clock source
  constant INTERNAL_PREPROC_CLK_ENABLE  : boolean := true;

  -- Include offset and scaler module to all channels
  constant ADC_OFFSET_SCALE_INCL        : boolean := true;

  ------------------------------------------------------------------------------
  -- BSP P2P
  ------------------------------------------------------------------------------
  -- Enable
  constant P2P_SUBSYS_ENABLE            : boolean := true;

  ------------------------------------------------------------------------------
  -- Framework Waveform Replay
  ------------------------------------------------------------------------------
  -- Enable
  constant REPLAY_SUBSYS_ENABLE         : boolean := true;

  -- Number of channels
  constant REPLAY_SUBSYS_CHANNEL_CNT    : natural := 10;

  --! Mapping of replay channels to the ADC input channels
  constant REPLAY_TO_INPUT_CH_MAPPING   : t_replay_ch_mapping := (
    0 => 0,
    1 => 1,
    2 => 8,
    3 => 9,
    others => 0
  );
  constant REPLAY_REVERSE_MAPPING       : t_reverse_mapping :=
    get_reverse_mapping(
      REPLAY_TO_INPUT_CH_MAPPING
    );

  ------------------------------------------------------------------------------
  -- Framework DAQ
  ------------------------------------------------------------------------------
  -- Enable
  constant FW_DAQ_PIPELINE_INCL         : boolean := true;

  -- DOD buffer enabled (instead of AXI-Stream-to-M-AXI)
  constant FW_DOD_INCL                  : boolean := false;

  -- Linear buffer (Axis2maxi) enabled
  constant FW_AXIS2MAXI_INCL            : boolean := true;

  -- Override the DAQ done and active signals by the custom logic
  constant OVR_DAQ_DONE_ACTIVE_ENABLE   : boolean := true;

  ------------------------------------------------------------------------------
  -- ABI Address Map
  ------------------------------------------------------------------------------
  --! Mapping addresses (set to 0xFFFFFFFF if not used)
  --! NOTE: Currently its not possible to change the address decoding based on
  --!       these constants. So, changing the offsets will require manual update
  --!       of the register interconnect inside the framework.
  constant BSP_BASE_ADDR                : std_logic_vector(31 downto 0) :=
                                            x"0040_0000";
  constant RSP_BASE_ADDR                : std_logic_vector(31 downto 0) :=
                                            x"0080_0000";
  constant FSP1_BASE_ADDR               : std_logic_vector(31 downto 0) :=
                                            x"FFFF_FFFF";
  constant FSP2_BASE_ADDR               : std_logic_vector(31 downto 0) :=
                                            x"FFFF_FFFF";
  constant CSTMLOG_BASE_ADDR            : std_logic_vector(31 downto 0) :=
                                            x"00C0_0000";

  ------------------------------------------------------------------------------
  -- FMCs (none for SIS8300-KU)
  ------------------------------------------------------------------------------
  -- FMC 1
  constant FSP1_ADC_CH_COUNT            : natural  :=
    blank_fsp_essffw_config.ADC_CHANNEL_COUNT;

  constant FSP1_ADC_RESOLUTION          : positive :=
    blank_fsp_essffw_config.ADC_RESOLUTION;

  -- FMC 2
  constant FSP2_ADC_CH_COUNT            : natural  :=
    blank_fsp_essffw_config.ADC_CHANNEL_COUNT;

  constant FSP2_ADC_RESOLUTION          : positive :=
    blank_fsp_essffw_config.ADC_RESOLUTION;

  ------------------------------------------------------------------------------
  -- Timestamp
  ------------------------------------------------------------------------------
  -- Maximum count
  constant TIMESTAMP_MAX_CNT            : natural := 125000000;

  ------------------------------------------------------------------------------
  -- Frontpanel LED
  ------------------------------------------------------------------------------
  -- Drive from custom logic
  constant LED_FROM_CSTMLOG             : boolean := false;

  ------------------------------------------------------------------------------
  -- Versioning
  ------------------------------------------------------------------------------
  --! Project ID (should probably match custom logic ID...)
  --! All zeroes is reserved for an empty project.
  constant PROJECT_ID                   : std_logic_vector(31 downto 0) :=
                                            x"0000_0000";

  --! Updated by scripts (DO NOT MODIFY!)
  constant PROJECT_GIT_HASH             : std_logic_vector(31 downto 0) :=
                                            x"0000_0000";

  constant PROJECT_BUILD_NR             : integer := 0;
end package clogic_essffw_config;
