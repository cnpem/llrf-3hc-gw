--------------------------------------------------------------------------------
-- Title        : 3rd Hamonic Low-Level Radio Frequency Top-Level Digital Signal
--                Processing Chain
-- Project      : 3rd Hamonic Low-Level Radio Frequency
--------------------------------------------------------------------------------
-- File         : llrf_3hc_dsp.vhd
-- Author       : Guilherme Ricioli Cruz
-- Company      : CNPEM
-- Platform     : Synthesis
-- Standard     : VHDL'08
--------------------------------------------------------------------------------
-- Description  : 3rd Hamonic (3HC) Low-Level Radio Frequency (LLRF) top-level
--                digital signal processing chain.
--
--                Its assumed that the intermediate frequency is locked to and
--                exactly 1/4 of the sampling frequency.
--------------------------------------------------------------------------------
-- Copyright (c) 2026 CNPEM
--------------------------------------------------------------------------------

library ieee;
  use ieee.std_logic_1164.all;

library work;
  use work.llrf_3hc_pkg.all;
  use work.wishbone_pkg.all;

entity llrf_3hc_dsp is
  generic (
    -- Number of ADC channels
    g_NUM_ADC_CHANNELS              : positive;

    -- ADC data width
    g_ADC_DATA_WIDTH                : positive;

    -- CIC differential delay
    g_CIC_DIFF_DELAY                : positive;

    -- CIC number of stages
    g_CIC_NUM_STAGES                : positive;

    -- CIC maximum decimation/interpolation rate
    g_CIC_MAX_RATIO                 : positive;

    -- Wishbone generics
    g_WB_INTERFACE_MODE             : t_wishbone_interface_mode;
    g_WB_ADDRESS_GRANULARITY        : t_wishbone_address_granularity
  );
  port (
    -- System reset
    -- Domain: clk_sys_i
    rst_sys_i                       : in std_logic;

    -- System clock
    clk_sys_i                       : in std_logic;

    -- Sampling clock
    clk_sampling_i                  : in std_logic;

    -- ADC data input
    -- Format: signed Q(g_ADC_DATA_WIDTH).0
    -- Domain: clk_sampling_i
    --
    -- NOTE: IQ sampling scheme assumes that ADC data is valid on every cycle of
    --       clk_sampling_i
    adc_data_arr_i                  : in t_slv_arr(
                                           g_NUM_ADC_CHANNELS-1 downto 0
                                         )(
                                           g_ADC_DATA_WIDTH-1 downto 0
                                         );

    ----------------------------------------------------------------------------
    -- Wishbone
    ----------------------------------------------------------------------------
    -- CIC for I component of IQ demodulator
    -- Domain: clk_sys_i
    wb_cic_i_wb_arr_i               : in  t_wishbone_slave_in_array;
    wb_cic_i_wb_arr_o               : out t_wishbone_slave_out_array;

    -- CIC for Q component of IQ demodulator
    -- Domain: clk_sys_i
    wb_cic_q_wb_arr_i               : in  t_wishbone_slave_in_array;
    wb_cic_q_wb_arr_o               : out t_wishbone_slave_out_array;

    ----------------------------------------------------------------------------
    -- Diagnostics
    ----------------------------------------------------------------------------
    -- ADC data
    -- Format: signed Q(g_ADC_DATA_WIDTH).0
    -- Domain: clk_sampling_i
    diag_adc_data_arr_o             : out t_slv_arr(
                                            g_NUM_ADC_CHANNELS-1 downto 0
                                          )(
                                            g_ADC_DATA_WIDTH-1 downto 0
                                          );
    diag_adc_data_valid_arr_o       : out std_logic_vector(
                                            g_NUM_ADC_CHANNELS-1 downto 0
                                          );

    -- ADC data demodulated IQ components
    -- Format: signed Q(g_ADC_DATA_WIDTH+1).0
    -- Domain: clk_sampling_i
    diag_iq_demodulator_i_arr_o     : out t_slv_arr(
                                            g_NUM_ADC_CHANNELS-1 downto 0
                                          )(
                                            g_ADC_DATA_WIDTH downto 0
                                          );
    diag_iq_demodulator_q_arr_o     : out t_slv_arr(
                                            g_NUM_ADC_CHANNELS-1 downto 0
                                          )(
                                            g_ADC_DATA_WIDTH downto 0
                                          );
    diag_iq_demodulator_valid_arr_o : out std_logic_vector(
                                              g_NUM_ADC_CHANNELS-1 downto 0
                                          );

    -- CIC for I component of IQ demodulator
    -- Format: signed Q(g_ADC_DATA_WIDTH+1).0
    -- Domain: clk_sampling_i
    diag_cic_i_arr_o                  : out t_slv_arr(
                                            g_NUM_ADC_CHANNELS-1 downto 0
                                          )(
                                            g_ADC_DATA_WIDTH downto 0
                                          );
    diag_cic_i_valid_arr_o            : out std_logic_vector(
                                              g_NUM_ADC_CHANNELS-1 downto 0
                                          );

    -- CIC for Q component of IQ demodulator
    -- Format: signed Q(g_ADC_DATA_WIDTH+1).0
    -- Domain: clk_sampling_i
    diag_cic_q_arr_o                  : out t_slv_arr(
                                            g_NUM_ADC_CHANNELS-1 downto 0
                                          )(
                                            g_ADC_DATA_WIDTH downto 0
                                          );
    diag_cic_q_valid_arr_o            : out std_logic_vector(
                                              g_NUM_ADC_CHANNELS-1 downto 0
                                          )
  );
end entity llrf_3hc_dsp;

architecture structural of llrf_3hc_dsp is
  ------------------------------------------------------------------------------
  -- Signals
  ------------------------------------------------------------------------------
  -- Format: signed Q(g_ADC_DATA_WIDTH-1).0
  -- Domain: clk_sampling_i
  signal adc_data_arr               : t_slv_arr(
                                        g_NUM_ADC_CHANNELS-1 downto 0
                                      )(
                                        g_ADC_DATA_WIDTH-1 downto 0
                                      ) := (others => (others => '0'));
  -- Format: signed Q(g_ADC_DATA_WIDTH).0
  -- Domain: clk_sampling_i
  signal  iq_demodulator_i_arr,
          iq_demodulator_q_arr,
          cic_i_arr,
          cic_q_arr                 : t_slv_arr(
                                        g_NUM_ADC_CHANNELS-1 downto 0
                                      )(
                                        g_ADC_DATA_WIDTH downto 0
                                      ) := (others => (others => '0'));
  -- Domain: clk_sampling_i
  signal  adc_data_valid_arr,
          iq_demodulator_valid_arr,
          cic_i_valid_arr,
          cic_q_valid_arr           : std_logic_vector(
                                        g_NUM_ADC_CHANNELS-1 downto 0
                                      ) := (others => '0');
begin
  gen_rf_measurement_chain : for chan in 0 to g_NUM_ADC_CHANNELS-1 generate
  begin
    p_adc_data_valid_handler : process(clk_sys_i)
    begin
      if rising_edge(clk_sys_i) then
        if rst_sys_i = '1' then
          adc_data_valid_arr(chan) <= '0';
        else
          adc_data_arr(chan) <= adc_data_arr_i(chan);
          -- ADC data is assumed to be valid on every cycle of clk_sampling_i
          adc_data_valid_arr(chan) <= '1';
        end if;
      end if;
    end process p_adc_data_valid_handler;

    ----------------------------------------------------------------------------
    -- IQ Demodulator
    ----------------------------------------------------------------------------
    cmp_iq_demodulator : entity work.gc_iq_demodulator
      generic map (
        g_N         => g_ADC_DATA_WIDTH
      )
      port map (
        clk_i       => clk_sampling_i,
        rst_i       => rst_sys_i,
        -- No plans for synchronizing this
        sync_p1_i   => '0',
        adc_data_i  => adc_data_arr(chan),
        i_o         => iq_demodulator_i_arr(chan),
        q_o         => iq_demodulator_q_arr(chan)
      );

    p_iq_demodulator_valid_handler : process(clk_sys_i)
    begin
      if rising_edge(clk_sys_i) then
        if rst_sys_i = '1' then
          iq_demodulator_valid_arr(chan) <= '0';
        else
          -- Level IQ demodulator valid delay
          iq_demodulator_valid_arr(chan) <= adc_data_valid_arr(chan);
        end if;
      end if;
    end process p_iq_demodulator_valid_handler;

    ----------------------------------------------------------------------------
    -- CIC for I component
    ----------------------------------------------------------------------------
    cmp_wb_cic_i : entity work.wb_cic
      generic map (
        g_DATA_IN_WIDTH       => iq_demodulator_i_arr(chan)'length,
        g_DATA_OUT_WIDTH      => iq_demodulator_i_arr(chan)'length,
        g_DIFF_DELAY          => g_CIC_DIFF_DELAY,
        g_NUM_STAGES          => g_CIC_NUM_STAGES,
        g_MAX_RATIO           => g_CIC_MAX_RATIO,
        g_IS_INTERPOLATOR     => false,
        g_INTERFACE_MODE      => g_WB_INTERFACE_MODE,
        g_ADDRESS_GRANULARITY => g_WB_ADDRESS_GRANULARITY
      )
      port map (
        rst_sys_i             => rst_sys_i,
        clk_sys_i             => clk_sys_i,
        clk_sampling_i        => clk_sampling_i,
        ce_i                  => '1',
        data_i                => iq_demodulator_i_arr(chan),
        valid_i               => iq_demodulator_valid_arr(chan),
        data_o                => cic_i_arr(chan),
        valid_o               => cic_i_valid_arr(chan),
        wb_i                  => wb_cic_i_wb_arr_i(chan),
        wb_o                  => wb_cic_i_wb_arr_o(chan)
      );
    ----------------------------------------------------------------------------
    -- CIC for Q component
    ----------------------------------------------------------------------------
    cmp_wb_cic_q : entity work.wb_cic
      generic map (
        g_DATA_IN_WIDTH       => iq_demodulator_q_arr(chan)'length,
        g_DATA_OUT_WIDTH      => iq_demodulator_q_arr(chan)'length,
        g_DIFF_DELAY          => g_CIC_DIFF_DELAY,
        g_NUM_STAGES          => g_CIC_NUM_STAGES,
        g_MAX_RATIO           => g_CIC_MAX_RATIO,
        g_IS_INTERPOLATOR     => false,
        g_INTERFACE_MODE      => g_WB_INTERFACE_MODE,
        g_ADDRESS_GRANULARITY => g_WB_ADDRESS_GRANULARITY
      )
      port map (
        rst_sys_i             => rst_sys_i,
        clk_sys_i             => clk_sys_i,
        clk_sampling_i        => clk_sampling_i,
        ce_i                  => '1',
        data_i                => iq_demodulator_q_arr(chan),
        valid_i               => iq_demodulator_valid_arr(chan),
        data_o                => cic_q_arr(chan),
        valid_o               => cic_q_valid_arr(chan),
        wb_i                  => wb_cic_q_wb_arr_i(chan),
        wb_o                  => wb_cic_q_wb_arr_o(chan)
      );

    ----------------------------------------------------------------------------
    -- Diagnostics
    ----------------------------------------------------------------------------
    diag_adc_data_arr_o(chan) <= adc_data_arr(chan);
    diag_adc_data_valid_arr_o(chan) <= adc_data_valid_arr(chan);
    diag_iq_demodulator_i_arr_o(chan) <= iq_demodulator_i_arr(chan);
    diag_iq_demodulator_q_arr_o(chan) <= iq_demodulator_q_arr(chan);
    diag_iq_demodulator_valid_arr_o(chan) <= iq_demodulator_valid_arr(chan);
    diag_cic_i_arr_o(chan) <= cic_i_arr(chan);
    diag_cic_i_valid_arr_o(chan) <= cic_i_valid_arr(chan);
    diag_cic_q_arr_o(chan) <= cic_q_arr(chan);
    diag_cic_q_valid_arr_o(chan) <= cic_q_valid_arr(chan);
  end generate gen_rf_measurement_chain;
end architecture structural;
