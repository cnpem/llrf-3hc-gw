--------------------------------------------------------------------------------
-- Title        : 3rd Hamonic Low-Level Radio Frequency Top-Level Digital Signal
--                Processing Chain With Acquisition Wrapper
-- Project      : 3rd Hamonic Low-Level Radio Frequency
--------------------------------------------------------------------------------
-- File         : custom_logic_wrapper.vhdl
-- Author       : Guilherme Ricioli Cruz
-- Company      : CNPEM
-- Platform     : Synthesis
-- Standard     : VHDL'08
--------------------------------------------------------------------------------
-- Description  : Wrapper to connect the 3rd Hamonic (3HC) Low-Level Radio
--                Frequency (LLRF) top-level digital signal processing chain
--                with acquisition with European Spallation Source FPGA
--                Framework (ESSFFW).
--------------------------------------------------------------------------------
-- Copyright (c) 2026 CNPEM
--------------------------------------------------------------------------------

library ieee;
  use ieee.std_logic_1164.all;

library work;
  use work.llrf_3hc_pkg.all;

library essffw_config;
  use essffw_config.essffw_config.all;

library essffw_intf;
  use essffw_intf.essffw_intf_types.all;

entity custom_logic_wrapper is
  port (
    framework_core_i  : in  t_intf_core_to_cstmlog;
    framework_core_o  : out t_intf_cstmlog_to_core
  );
end entity;

architecture structural of custom_logic_wrapper is
  signal adc_data_arr : t_slv_arr(
                          ESSFFW_NR_ADC_CHANNELS-1 downto 0
                        )(
                          ESSFFW_ADC_RESOLUTION-1 downto 0
                        );
begin
  ------------------------------------------------------------------------------
  -- Top-level 3HC LLRF DSP with acquisition
  ------------------------------------------------------------------------------
  cmp_llrf_3hc_dsp_acq : entity work.llrf_3hc_dsp_acq
  generic (
    g_NUM_ADC_CHANNELS  => ESSFFW_NR_ADC_CHANNELS,
    g_ADC_DATA_WIDTH    => ESSFFW_ADC_RESOLUTION
  );
  port (
    rst_sys_i           => framework_core_i.reset_n,
    clk_sys_i           => framework_core_i.processing_clock,
    -- Use ADC0 AXI-Stream clock as the sampling clock
    clk_sampling_i      => framework_core_i.adc_preproc_aclk(0),
    adc_data_arr_i      => adc_data_arr
  );

  gen_framework_conn : for chan in 0 to ESSFFW_NR_ADC_CHANNELS-1 generate
  begin
      adc_data_arr(chan) <= adc_preproc_axis.ch(chan).tdata;
  end generate gen_llrf_3hc_dsp_acq_framework_conn;
end architecture structural;
