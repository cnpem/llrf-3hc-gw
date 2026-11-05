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

entity llrf_3hc_dsp is
  generic (
    -- Number of ADC channels
    g_NUM_ADC_CHANNELS              : positive;

    -- ADC data width
    g_ADC_DATA_WIDTH                : positive
  );
  port (
    -- System reset
    -- Domain: clk_sys_i
    rst_sys_i                       : in std_logic;

    -- System clock
    clk_sys_i                       : in std_logic;

    -- Sampling clock
    clk_sampling_i                  : in std_logic;

    -- ADC data input in 2's complement
    -- Domain: clk_sampling_i
    -- It's assumed that ADC data is valid in every cycle of sampling clock
    adc_data_arr_i                  : in t_slv_arr(
                                           g_NUM_ADC_CHANNELS-1 downto 0
                                         )(
                                           g_ADC_DATA_WIDTH-1 downto 0
                                         );

    ----------------------------------------------------------------------------
    -- Debug ports
    ----------------------------------------------------------------------------
    -- ADC data demodulated IQ components
    -- Domain: clk_sampling_i
    dbg_iq_demodulator_i_arr_o      : out t_slv_arr(
                                            g_NUM_ADC_CHANNELS-1 downto 0
                                          )(
                                            g_ADC_DATA_WIDTH downto 0
                                          );
    dbg_iq_demodulator_q_arr_o      : out t_slv_arr(
                                            g_NUM_ADC_CHANNELS-1 downto 0
                                          )(
                                            g_ADC_DATA_WIDTH downto 0
                                          );
    dbg_iq_demodulator_valid_arr_o  : out std_logic_vector(
                                              g_NUM_ADC_CHANNELS-1 downto 0
                                            )
  );
end entity;

architecture structural of llrf_3hc_dsp is
  ------------------------------------------------------------------------------
  -- Signals
  ------------------------------------------------------------------------------
  signal iq_demodulator_i_arr     : t_slv_arr(
                                      g_NUM_ADC_CHANNELS-1 downto 0
                                    )(
                                      g_ADC_DATA_WIDTH downto 0
                                    ) := (others => (others => '0'));
  signal iq_demodulator_q_arr     : t_slv_arr(
                                      g_NUM_ADC_CHANNELS-1 downto 0
                                    )(
                                      g_ADC_DATA_WIDTH downto 0
                                    ) := (others => (others => '0'));
  signal iq_demodulator_valid_arr : std_logic_vector(
                                      g_NUM_ADC_CHANNELS-1 downto 0
                                    ) := (others => '0');
begin
  ----------------------------------------------------------------------------
  -- Reset handling
  ----------------------------------------------------------------------------
  p_rst_handling : process(clk_sys_i)
  begin
    if rising_edge(clk_sys_i) then
      for chan in 0 to g_NUM_ADC_CHANNELS-1 loop
        if rst_sys_i = '1' then
          iq_demodulator_valid_arr(chan) <= '0';
        else
          -- IQ demodulator's output is always valid as it's assumed that ADC
          -- data is valid in every cycle of sampling clock
          iq_demodulator_valid_arr(chan) <= '1';
        end if;
      end loop;
    end if;
  end process p_rst_handling;

  gen_rf_measurement_chain : for chan in 0 to g_NUM_ADC_CHANNELS-1 generate
  begin
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
        adc_data_i  => adc_data_arr_i(chan),
        i_o         => iq_demodulator_i_arr(chan),
        q_o         => iq_demodulator_q_arr(chan)
      );

    ----------------------------------------------------------------------------
    -- Debug signals
    ----------------------------------------------------------------------------
    dbg_iq_demodulator_i_arr_o(chan) <= iq_demodulator_i_arr(chan);
    dbg_iq_demodulator_q_arr_o(chan) <= iq_demodulator_q_arr(chan);
    dbg_iq_demodulator_valid_arr_o(chan) <= iq_demodulator_valid_arr(chan);
  end generate gen_rf_measurement_chain;
end architecture structural;
