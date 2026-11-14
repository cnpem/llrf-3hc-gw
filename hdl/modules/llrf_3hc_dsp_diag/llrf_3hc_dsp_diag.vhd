--------------------------------------------------------------------------------
-- Title      : 3rd Hamonic Low-Level Radio Frequency Top-Level Digital Signal
--              Processing Chain With Diagnostics
-- Project    : 3rd Hamonic Low-Level Radio Frequency
--------------------------------------------------------------------------------
-- File       : llrf_3hc_dsp_diag.vhd
-- Author     : Guilherme Ricioli Cruz
-- Company    : CNPEM
-- Platform   : Synthesis
-- Standard   : VHDL'08
--------------------------------------------------------------------------------
-- Description: 3rd Hamonic (3HC) Low-Level Radio Frequency (LLRF) top-level
--              digital signal processing chain with diagnostics.
--------------------------------------------------------------------------------
-- Copyright (c) 2026 CNPEM
--------------------------------------------------------------------------------

library ieee;
  use ieee.std_logic_1164.all;

library work;
  use work.llrf_3hc_pkg.all;
  use work.wishbone_pkg.all;

entity llrf_3hc_dsp_diag is
  generic (
    -- Number of ADC channels
    g_NUM_ADC_CHANNELS  : positive;

    -- ADC data width
    g_ADC_DATA_WIDTH    : positive
  );
  port (
    -- System reset
    -- Domain: clk_sys_i
    rst_sys_i           : in  std_logic;

    -- System clock
    clk_sys_i           : in  std_logic;

    -- Sampling clock
    clk_sampling_i      : in  std_logic;

    -- ADC data input
    -- Format: signed Q(g_ADC_DATA_WIDTH).0
    -- Domain: clk_sampling_i
    --
    -- NOTE: It's assumed that ADC data is valid in every cycle of
    --       clk_sampling_i
    adc_data_arr_i      : in  t_slv_arr(
                                g_NUM_ADC_CHANNELS-1 downto 0
                              )(
                                g_ADC_DATA_WIDTH-1 downto 0
                              );

    -- Wishbone interface
    -- Domain: clk_sys_i
    wb_i                : in  t_wishbone_slave_in;
    wb_o                : out t_wishbone_slave_out
  );
end entity;

architecture structural of llrf_3hc_dsp_diag is
  ------------------------------------------------------------------------------
  -- Constants
  ------------------------------------------------------------------------------
  -- The Wishbone ABI supports up to 10 ADC channels, matching the channel count
  -- of SIS8300-KU
  constant WB_NUM_ADC_CHANNELS_SUPPORTED  : natural := 10;

  -- The Slow Diagnostics data rate is defined as the ADC Rate (125 MHz) divided
  -- by 2**24, resulting in approximately 7.5 Hz. By decimating (and filtering)
  -- to that frequency, we prevent aliasing to happen in software accesses to
  -- Wishbone registers.
  constant c_LOG2_ADC_TO_SLOW_DIAG_RATIO  : natural := 24;

  -- Signals
  ------------------------------------------------------------------------------
  -- Format: signed Q(g_ADC_DATA_WIDTH).0
  -- Domain: clk_sampling_i
  signal  diag_adc_data_arr,
          slow_diag_adc_data_arr          : t_slv_arr(
                                              WB_NUM_ADC_CHANNELS_SUPPORTED-1
                                              downto 0
                                            )(
                                              g_ADC_DATA_WIDTH-1 downto 0
                                            );
  -- Format: signed Q(g_ADC_DATA_WIDTH+1).0
  -- Domain: clk_sampling_i
  signal  diag_iq_demodulator_i_arr,
          diag_iq_demodulator_q_arr,
          slow_diag_iq_demodulator_i_arr,
          slow_diag_iq_demodulator_q_arr  : t_slv_arr(
                                              WB_NUM_ADC_CHANNELS_SUPPORTED-1
                                              downto 0
                                            )(
                                              g_ADC_DATA_WIDTH downto 0
                                            ) := (others => (others => '0'));
  signal  diag_adc_data_valid_arr,
          slow_diag_adc_data_valid_arr,
          diag_iq_demodulator_valid_arr,
          slow_diag_iq_demodulator_i_valid_arr,
          slow_diag_iq_demodulator_q_valid_arr
                                          : std_logic_vector(
                                              WB_NUM_ADC_CHANNELS_SUPPORTED-1
                                              downto 0
                                            ) := (others => '0');

  -- Format: signed Q(g_ADC_DATA_WIDTH).0
  -- Domain: clk_sys_i
  signal  wb_slow_diag_adc_data_arr       : t_slv_arr(
                                              WB_NUM_ADC_CHANNELS_SUPPORTED-1
                                              downto 0
                                            )(
                                              g_ADC_DATA_WIDTH-1 downto 0
                                            );
  -- Format: signed Q(g_ADC_DATA_WIDTH+1).0
  -- Domain: clk_sys_i
  signal  wb_slow_diag_iq_demodulator_i_arr,
          wb_slow_diag_iq_demodulator_q_arr
                                          : t_slv_arr(
                                             WB_NUM_ADC_CHANNELS_SUPPORTED-1
                                             downto 0
                                           )(
                                             g_ADC_DATA_WIDTH downto 0
                                           ) := (others => (others => '0'));
  -- Domain: clk_sys_i
  signal wb_llrf_3hc_dsp_diag_regs_io_intf_i
                                          : t_io_intf_slave_out;
begin
  assert g_NUM_ADC_CHANNELS <= WB_NUM_ADC_CHANNELS_SUPPORTED
  report
    "llrf_3hc_dsp_diag supports at most "
    & integer'image(WB_NUM_ADC_CHANNELS_SUPPORTED) & "ADC channels, but got "
    & integer'image(g_NUM_ADC_CHANNELS)
  severity failure;

  ------------------------------------------------------------------------------
  -- Top-level DSP
  ------------------------------------------------------------------------------
  cmp_llrf_3hc_dsp : entity work.llrf_3hc_dsp
  generic map (
    g_NUM_ADC_CHANNELS              =>  g_NUM_ADC_CHANNELS,
    g_ADC_DATA_WIDTH                =>  g_ADC_DATA_WIDTH
  )
  port map (
    rst_sys_i                       =>  rst_sys_i,
    clk_sys_i                       =>  clk_sys_i,
    clk_sampling_i                  =>  clk_sampling_i,
    adc_data_arr_i                  =>  adc_data_arr_i(
                                          g_NUM_ADC_CHANNELS-1 downto 0
                                        ),
    diag_adc_data_arr_o             =>  diag_adc_data_arr(
                                          g_NUM_ADC_CHANNELS-1 downto 0
                                        ),
    diag_adc_data_valid_arr_o       =>  diag_adc_data_valid_arr(
                                          g_NUM_ADC_CHANNELS-1 downto 0
                                        ),
    diag_iq_demodulator_i_arr_o     =>  diag_iq_demodulator_i_arr(
                                          g_NUM_ADC_CHANNELS-1 downto 0
                                        ),
    diag_iq_demodulator_q_arr_o     =>  diag_iq_demodulator_q_arr(
                                          g_NUM_ADC_CHANNELS-1 downto 0
                                        ),
    diag_iq_demodulator_valid_arr_o =>  diag_iq_demodulator_valid_arr(
                                          g_NUM_ADC_CHANNELS-1 downto 0
                                        )
  );

  ------------------------------------------------------------------------------
  -- Slow diagnostics
  ------------------------------------------------------------------------------
  gen_slow_diagnostics : for chan in 0 to g_NUM_ADC_CHANNELS-1 generate
  begin
    -- ADCs
    cmp_gc_cic_adc_data : entity work.gc_cic
      generic map (
        g_DATA_IN_WIDTH   => g_ADC_DATA_WIDTH,
        g_DATA_OUT_WIDTH  => g_ADC_DATA_WIDTH+c_LOG2_ADC_TO_SLOW_DIAG_RATIO,
        g_DIFF_DELAY      => 1,
        g_NUM_STAGES      => 1,
        g_MAX_RATIO       => 2**c_LOG2_ADC_TO_SLOW_DIAG_RATIO,
        g_IS_INTERPOLATOR => false
      )
      port map (
        clk_i             => clk_sampling_i,
        rst_i             => rst_sys_i,
        ce_i              => '1',
        ratio_sel_i       => (others => '1'),
        data_i            => diag_adc_data_arr(chan),
        valid_i           => diag_adc_data_valid_arr(chan),
        -- Perform division by 2**c_LOG2_ADC_TO_SLOW_DIAG_RATIO with truncation
        data_o(
          g_ADC_DATA_WIDTH+c_LOG2_ADC_TO_SLOW_DIAG_RATIO-1 downto
          c_LOG2_ADC_TO_SLOW_DIAG_RATIO
        )                 => slow_diag_adc_data_arr(chan),
        data_o(
          c_LOG2_ADC_TO_SLOW_DIAG_RATIO-1 downto 0
        )                 => open,
        valid_o           => slow_diag_adc_data_valid_arr(chan)
      );
    cmp_cdc_slow_diag_adc_data : entity work.gc_sync_word_wr
      generic map (
        g_AUTO_WR   => false,
        g_WIDTH     => g_ADC_DATA_WIDTH
      )
      port map (
        clk_in_i    => clk_sampling_i,
        rst_in_n_i  => not rst_sys_i,
        clk_out_i   => clk_sys_i,
        rst_out_n_i => not rst_sys_i,
        data_i      => slow_diag_adc_data_arr(chan),
        wr_i        => slow_diag_adc_data_valid_arr(chan),
        busy_o      => open,
        ack_o       => open,
        data_o      => wb_slow_diag_adc_data_arr(chan),
        wr_o        => open
      );

    -- IQ demodulators: I component
    cmp_gc_cic_iq_demodulator_i : entity work.gc_cic
      generic map (
        g_DATA_IN_WIDTH   => g_ADC_DATA_WIDTH+1,
        g_DATA_OUT_WIDTH  => g_ADC_DATA_WIDTH+c_LOG2_ADC_TO_SLOW_DIAG_RATIO+1,
        g_DIFF_DELAY      => 1,
        g_NUM_STAGES      => 1,
        g_MAX_RATIO       => 2**c_LOG2_ADC_TO_SLOW_DIAG_RATIO,
        g_IS_INTERPOLATOR => false
      )
      port map (
        clk_i             => clk_sampling_i,
        rst_i             => rst_sys_i,
        ce_i              => '1',
        ratio_sel_i       => (others => '1'),
        data_i            => diag_iq_demodulator_i_arr(chan),
        valid_i           => diag_iq_demodulator_valid_arr(chan),
        -- Perform division by 2**c_LOG2_ADC_TO_SLOW_DIAG_RATIO with truncation
        data_o(
          g_ADC_DATA_WIDTH+c_LOG2_ADC_TO_SLOW_DIAG_RATIO downto
          c_LOG2_ADC_TO_SLOW_DIAG_RATIO
        )                 => slow_diag_iq_demodulator_i_arr(chan),
        data_o(
          c_LOG2_ADC_TO_SLOW_DIAG_RATIO-1 downto 0
        )                 => open,
        valid_o           => slow_diag_iq_demodulator_i_valid_arr(chan)
      );
    cmp_cdc_slow_diag_iq_demodulator_i : entity work.gc_sync_word_wr
      generic map (
        g_AUTO_WR   => false,
        g_WIDTH     => g_ADC_DATA_WIDTH+1
      )
      port map (
        clk_in_i    => clk_sampling_i,
        rst_in_n_i  => not rst_sys_i,
        clk_out_i   => clk_sys_i,
        rst_out_n_i => not rst_sys_i,
        data_i      => slow_diag_iq_demodulator_i_arr(chan),
        wr_i        => slow_diag_iq_demodulator_i_valid_arr(chan),
        busy_o      => open,
        ack_o       => open,
        data_o      => wb_slow_diag_iq_demodulator_i_arr(chan),
        wr_o        => open
      );

    -- IQ demodulators: Q component
    cmp_gc_cic_iq_demodulator_q : entity work.gc_cic
      generic map (
        g_DATA_IN_WIDTH   => g_ADC_DATA_WIDTH+1,
        g_DATA_OUT_WIDTH  => g_ADC_DATA_WIDTH+c_LOG2_ADC_TO_SLOW_DIAG_RATIO+1,
        g_DIFF_DELAY      => 1,
        g_NUM_STAGES      => 1,
        g_MAX_RATIO       => 2**c_LOG2_ADC_TO_SLOW_DIAG_RATIO,
        g_IS_INTERPOLATOR => false
      )
      port map (
        clk_i             => clk_sampling_i,
        rst_i             => rst_sys_i,
        ce_i              => '1',
        ratio_sel_i       => (others => '1'),
        data_i            => diag_iq_demodulator_q_arr(chan),
        valid_i           => diag_iq_demodulator_valid_arr(chan),
        -- Perform division by 2**c_LOG2_ADC_TO_SLOW_DIAG_RATIO with truncation
        data_o(
          g_ADC_DATA_WIDTH+c_LOG2_ADC_TO_SLOW_DIAG_RATIO downto
          c_LOG2_ADC_TO_SLOW_DIAG_RATIO
        )                 => slow_diag_iq_demodulator_q_arr(chan),
        data_o(
          c_LOG2_ADC_TO_SLOW_DIAG_RATIO-1 downto 0
        )                 => open,
        valid_o           => slow_diag_iq_demodulator_q_valid_arr(chan)
      );
    cmp_cdc_slow_diag_iq_demodulator_q : entity work.gc_sync_word_wr
      generic map (
        g_AUTO_WR   => false,
        g_WIDTH     => g_ADC_DATA_WIDTH+1
      )
      port map (
        clk_in_i    => clk_sampling_i,
        rst_in_n_i  => not rst_sys_i,
        clk_out_i   => clk_sys_i,
        rst_out_n_i => not rst_sys_i,
        data_i      => slow_diag_iq_demodulator_q_arr(chan),
        wr_i        => slow_diag_iq_demodulator_q_valid_arr(chan),
        busy_o      => open,
        ack_o       => open,
        data_o      => wb_slow_diag_iq_demodulator_q_arr(chan),
        wr_o        => open
      );
  end generate gen_slow_diagnostics;

  ------------------------------------------------------------------------------
  --  Wishbone ABI for slow diagnostics
  ------------------------------------------------------------------------------
  cmp_wb_llrf_3hc_dsp_diag_regs : entity work.wb_llrf_3hc_dsp_diag_regs
    port map (
      rst_n_i   => not rst_sys_i,
      clk_i     => clk_sys_i,
      wb_i      => wb_i,
      wb_o      => wb_o,
      io_intf_i => wb_llrf_3hc_dsp_diag_regs_io_intf_i
    );

  ------------------------------------------------------------------------------
  -- Connections between slow diagnostics and its Wishbone ABI
  ------------------------------------------------------------------------------
  wb_llrf_3hc_dsp_diag_regs_io_intf_i <= (
    ch_0_rf_measurement_adc =>
      f_align_lsb_32(wb_slow_diag_adc_data_arr(0)),
    ch_0_rf_measurement_iq_demodulator_i =>
      f_align_lsb_32(wb_slow_diag_iq_demodulator_i_arr(0)),
    ch_0_rf_measurement_iq_demodulator_q =>
      f_align_lsb_32(wb_slow_diag_iq_demodulator_q_arr(0)),
    ch_1_rf_measurement_adc =>
      f_align_lsb_32(wb_slow_diag_adc_data_arr(1)),
    ch_1_rf_measurement_iq_demodulator_i =>
      f_align_lsb_32(wb_slow_diag_iq_demodulator_i_arr(1)),
    ch_1_rf_measurement_iq_demodulator_q =>
      f_align_lsb_32(wb_slow_diag_iq_demodulator_q_arr(1)),
    ch_2_rf_measurement_adc =>
      f_align_lsb_32(wb_slow_diag_adc_data_arr(2)),
    ch_2_rf_measurement_iq_demodulator_i =>
      f_align_lsb_32(wb_slow_diag_iq_demodulator_i_arr(2)),
    ch_2_rf_measurement_iq_demodulator_q =>
      f_align_lsb_32(wb_slow_diag_iq_demodulator_q_arr(2)),
    ch_3_rf_measurement_adc =>
      f_align_lsb_32(wb_slow_diag_adc_data_arr(3)),
    ch_3_rf_measurement_iq_demodulator_i =>
      f_align_lsb_32(wb_slow_diag_iq_demodulator_i_arr(3)),
    ch_3_rf_measurement_iq_demodulator_q =>
      f_align_lsb_32(wb_slow_diag_iq_demodulator_q_arr(3)),
    ch_4_rf_measurement_adc =>
      f_align_lsb_32(wb_slow_diag_adc_data_arr(4)),
    ch_4_rf_measurement_iq_demodulator_i =>
      f_align_lsb_32(wb_slow_diag_iq_demodulator_i_arr(4)),
    ch_4_rf_measurement_iq_demodulator_q =>
      f_align_lsb_32(wb_slow_diag_iq_demodulator_q_arr(4)),
    ch_5_rf_measurement_adc =>
      f_align_lsb_32(wb_slow_diag_adc_data_arr(5)),
    ch_5_rf_measurement_iq_demodulator_i =>
      f_align_lsb_32(wb_slow_diag_iq_demodulator_i_arr(5)),
    ch_5_rf_measurement_iq_demodulator_q =>
      f_align_lsb_32(wb_slow_diag_iq_demodulator_q_arr(5)),
    ch_6_rf_measurement_adc =>
      f_align_lsb_32(wb_slow_diag_adc_data_arr(6)),
    ch_6_rf_measurement_iq_demodulator_i =>
      f_align_lsb_32(wb_slow_diag_iq_demodulator_i_arr(6)),
    ch_6_rf_measurement_iq_demodulator_q =>
      f_align_lsb_32(wb_slow_diag_iq_demodulator_q_arr(6)),
    ch_7_rf_measurement_adc =>
      f_align_lsb_32(wb_slow_diag_adc_data_arr(7)),
    ch_7_rf_measurement_iq_demodulator_i =>
      f_align_lsb_32(wb_slow_diag_iq_demodulator_i_arr(7)),
    ch_7_rf_measurement_iq_demodulator_q =>
      f_align_lsb_32(wb_slow_diag_iq_demodulator_q_arr(7)),
    ch_8_rf_measurement_adc =>
      f_align_lsb_32(wb_slow_diag_adc_data_arr(8)),
    ch_8_rf_measurement_iq_demodulator_i =>
      f_align_lsb_32(wb_slow_diag_iq_demodulator_i_arr(8)),
    ch_8_rf_measurement_iq_demodulator_q =>
      f_align_lsb_32(wb_slow_diag_iq_demodulator_q_arr(8)),
    ch_9_rf_measurement_adc =>
      f_align_lsb_32(wb_slow_diag_adc_data_arr(9)),
    ch_9_rf_measurement_iq_demodulator_i =>
      f_align_lsb_32(wb_slow_diag_iq_demodulator_i_arr(9)),
    ch_9_rf_measurement_iq_demodulator_q =>
      f_align_lsb_32(wb_slow_diag_iq_demodulator_q_arr(9))
  );

  ------------------------------------------------------------------------------
  -- Fast diagnostics through acquisition cores
  ------------------------------------------------------------------------------
  -- TODO
end architecture structural;
