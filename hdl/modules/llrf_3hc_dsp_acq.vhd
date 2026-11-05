--------------------------------------------------------------------------------
-- Title      : 3rd Hamonic Low-Level Radio Frequency Top-Level Digital Signal
--              Processing Chain With Acquisition
-- Project    : 3rd Hamonic Low-Level Radio Frequency
--------------------------------------------------------------------------------
-- File       : llrf_3hc_dsp_acq.vhd
-- Author     : Guilherme Ricioli Cruz
-- Company    : CNPEM
-- Platform   : Synthesis
-- Standard   : VHDL'08
--------------------------------------------------------------------------------
-- Description: 3rd Hamonic (3HC) Low-Level Radio Frequency (LLRF) top-level
--              digital signal processing chain with acquisition.
--------------------------------------------------------------------------------
-- Copyright (c) 2026 CNPEM
--------------------------------------------------------------------------------

library ieee;
  use ieee.std_logic_1164.all;

library work;
  use work.llrf_3hc_pkg.all;

entity llrf_3hc_dsp_acq is
  generic (
    -- Number of ADC channels
    g_NUM_ADC_CHANNELS  : positive;

    -- ADC data width
    g_ADC_DATA_WIDTH    : positive
  );
  port (
    -- System reset
    -- Domain: clk_sys_i
    rst_sys_i           : in std_logic;

    -- System clock
    clk_sys_i           : in std_logic;

    -- Sampling clock
    clk_sampling_i      : in std_logic;

    -- ADC data input in 2's complement
    -- Domain: clk_sampling_i
    -- It's assumed that ADC data is valid in every cycle of sampling clock
    adc_data_arr_i      : in t_slv_arr(
                               g_NUM_ADC_CHANNELS-1 downto 0
                             )(
                               g_ADC_DATA_WIDTH-1 downto 0
                             )
  );
end entity;

architecture structural of llrf_3hc_dsp_acq is
  ------------------------------------------------------------------------------
  -- Signals
  ------------------------------------------------------------------------------
  signal dbg_iq_demodulator_i_arr     : t_slv_arr(
                                          g_NUM_ADC_CHANNELS-1 downto 0
                                        )(
                                          g_ADC_DATA_WIDTH downto 0
                                        ) := (others => (others => '0'));
  signal dbg_iq_demodulator_q_arr     : t_slv_arr(
                                          g_NUM_ADC_CHANNELS-1 downto 0
                                        )(
                                          g_ADC_DATA_WIDTH downto 0
                                        ) := (others => (others => '0'));
  signal dbg_iq_demodulator_valid_arr : std_logic_vector(
                                          g_NUM_ADC_CHANNELS-1 downto 0
                                        ) := (others => '0');
begin
  ------------------------------------------------------------------------------
  -- Top-level DSP
  ------------------------------------------------------------------------------
  cmp_llrf_3hc_dsp : entity work.llrf_3hc_dsp
  generic (
    g_NUM_ADC_CHANNELS              => g_NUM_ADC_CHANNELS,
    g_ADC_DATA_WIDTH                => g_ADC_DATA_WIDTH
  );
  port (
    rst_sys_i                       => rst_sys_i,
    clk_sys_i                       => clk_sys_i,
    clk_sampling_i                  => clk_sampling_i,
    adc_data_arr_i                  => adc_data_arr_i,
    dbg_iq_demodulator_i_arr_o      => dbg_iq_demodulator_i_arr,
    dbg_iq_demodulator_q_arr_o      => dbg_iq_demodulator_q_arr,
    dbg_iq_demodulator_valid_arr_o  => dbg_iq_demodulator_valid_arr
  );

  ------------------------------------------------------------------------------
  -- Acquisition
  ------------------------------------------------------------------------------
  -- TODO
end architecture structural;
