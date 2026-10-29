--------------------------------------------------------------------------------
-- Title        : Top-Level Testbench
-- Project      : 3rd Hamonic Low-Level Radio Frequency
--------------------------------------------------------------------------------
-- File         : TbLLRF3HCDSP.vhd
-- Author       : Guilherme Ricioli Cruz
-- Company      : CNPEM
-- Platform     : Simulation
-- Standard     : VHDL'08
--------------------------------------------------------------------------------
-- Description  : Top-level testbench for verification of 3rd Hamonic (3HC)
--                Low-Level Radio Frequency (LLRF) top-level digital signal
--                processing chain.
--------------------------------------------------------------------------------
-- Copyright (c) 2026 CNPEM
--------------------------------------------------------------------------------

library ieee;
  use ieee.std_logic_1164.all;
  use ieee.math_real.all;

library osvvm;
  context osvvm.OSVVMContext;

library work;
  use work.llrf_3hc_pkg.all;
  use work.LLRF3HCDSPVCPkg.all;

entity TbLLRF3HCDSP is
  generic (
    -- Number of ADC channels
    NUM_ADC_CHANNELS  : positive := 10;

    -- ADC data width
    ADC_DATA_WIDTH    : positive := 16
  );
end entity TbLLRF3HCDSP;

architecture TestHarness of TbLLRF3HCDSP is
  ------------------------------------------------------------------------------
  -- Constants
  ------------------------------------------------------------------------------
  constant CLK_PERIOD                         : time := 10 ns;
  constant RST_TIME                           : time := 10 * CLK_PERIOD;

  ------------------------------------------------------------------------------
  -- Signals
  ------------------------------------------------------------------------------
  signal Clk                                  : std_logic := '0';
  signal Reset                                : std_logic := '1';
  signal TestCtrlToDUTIface                   : TestCtrlToDUTIfaceRec(
                                                  DataArr(
                                                    NUM_ADC_CHANNELS-1 downto 0
                                                  )(
                                                    ADC_DATA_WIDTH-1 downto 0
                                                  ),
                                                  ValidArr(
                                                    NUM_ADC_CHANNELS-1 downto 0
                                                  )
                                                );
  signal DUTDiagADCDataToTestCtrlIface        :
    DUTDiagADCDataToTestCtrlIfaceRec(
      DataArr(
        NUM_ADC_CHANNELS-1 downto 0
      )(
        ADC_DATA_WIDTH-1 downto 0
      ),
      ValidArr(
        NUM_ADC_CHANNELS-1 downto 0
      )
    );
  signal DUTDiagIQDemodulatorToTestCtrlIface  :
    DUTDiagIQDemodulatorToTestCtrlIfaceRec(
      IArr(
        NUM_ADC_CHANNELS-1 downto 0
      )(
        ADC_DATA_WIDTH downto 0
      ),
      QArr(
        NUM_ADC_CHANNELS-1 downto 0
      )(
        ADC_DATA_WIDTH downto 0
      ),
      ValidArr(
        NUM_ADC_CHANNELS-1 downto 0
      )
   );
begin
  ------------------------------------------------------------------------------
  -- Clock
  ------------------------------------------------------------------------------
  CreateClock(
    Clk      => Clk,
    Period   => CLK_PERIOD
  );

  ------------------------------------------------------------------------------
  -- Synchronous reset
  ------------------------------------------------------------------------------
  CreateReset(
    Reset       => Reset,
    ResetActive => '1',
    Clk         => Clk,
    Period      => RST_TIME
  );

  ------------------------------------------------------------------------------
  -- Entities instantiation
  ------------------------------------------------------------------------------
  CmpTestCtrl : entity work.TestCtrl
    generic map (
      NUM_ADC_CHANNELS                      => NUM_ADC_CHANNELS,
      ADC_DATA_WIDTH                        => ADC_DATA_WIDTH
    )
    port map (
      Clk                                   => Clk,
      Reset                                 => Reset,
      DUTDiagADCDataToTestCtrlIfaceIn       => DUTDiagADCDataToTestCtrlIface,
      DUTDiagIQDemodulatorToTestCtrlIfaceIn =>
        DUTDiagIQDemodulatorToTestCtrlIface,
      TestCtrlToDUTIfaceOut                 => TestCtrlToDUTIface
    );

  DUT : entity work.llrf_3hc_dsp
  generic map (
    g_NUM_ADC_CHANNELS              => NUM_ADC_CHANNELS,
    g_ADC_DATA_WIDTH                => ADC_DATA_WIDTH
  )
  port map (
    rst_sys_i                       => Reset,
    clk_sys_i                       => Clk,
    -- IQ demodulator assumes ADC data is feed is every sampling clock
    clk_sampling_i                  => Clk,
    adc_data_arr_i                  => TestCtrlToDUTIface.DataArr,
    diag_adc_data_arr_o             => DUTDiagADCDataToTestCtrlIface.DataArr,
    diag_adc_data_valid_arr_o       => DUTDiagADCDataToTestCtrlIface.ValidArr,
    diag_iq_demodulator_i_arr_o     => DUTDiagIQDemodulatorToTestCtrlIface.IArr,
    diag_iq_demodulator_q_arr_o     => DUTDiagIQDemodulatorToTestCtrlIface.QArr,
    diag_iq_demodulator_valid_arr_o =>
      DUTDiagIQDemodulatorToTestCtrlIface.ValidArr
  );
end architecture TestHarness;
