library ieee;
  use ieee.std_logic_1164.all;

library essffw_config;
  use essffw_config.essffw_config_types.all;

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

  --! Resolution of the ADCs
  constant ADC_RESOLUTION       : integer := 16;

end clogic_essffw_config;
