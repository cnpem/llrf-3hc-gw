--------------------------------------------------------------------------------
-- Title        : 3rd Hamonic Low-Level Radio Frequency Top-Level Digital Signal
--                Processing Chain Top-Level Testbench Entity Declaration
-- Project      : 3rd Hamonic Low-Level Radio Frequency
--------------------------------------------------------------------------------
-- File         : TestCtrl_e.vhd
-- Author       : Guilherme Ricioli Cruz
-- Company      : CNPEM
-- Platform     : Simulation
-- Standard     : VHDL'08
--------------------------------------------------------------------------------
-- Description  : Test control entity declaration for 3rd Hamonic (3HC)
--                Low-Level Radio Frequency (LLRF) top-level digital signal
--                processing chain.
--------------------------------------------------------------------------------
-- Copyright (c) 2026 CNPEM
--------------------------------------------------------------------------------

library ieee;
  use ieee.numeric_std.all;
  use ieee.std_logic_1164.all;

library osvvm;
  context osvvm.OSVVMContext;

library work;
  use work.llrf_3hc_pkg.all;
  use work.LLRF3HCDSPRefModelPkg.all;
  use work.LLRF3HCDSPVCPkg.all;

entity TestCtrl is
  generic (
    -- Number of ADC channels
    NUM_ADC_CHANNELS                      : positive;

    -- IQ demodulator ADC data width
    ADC_DATA_WIDTH                        : positive
  );
  port (
    -- Clock
    Clk                                   : in  std_logic;

    -- Reset
    Reset                                 : in  std_logic;

    -- Interface from DUT's IQ demodulators to TestCtrl
    DUTDbgIQDemodulatorToTestCtrlIfaceIn  :
      in  DUTDbgIQDemodulatorToTestCtrlIfaceRec;

    -- Interface from TestCtrl to DUT
    TestCtrlToDUTIfaceOut                 : out TestCtrlToDUTIfaceRec

  );
end entity TestCtrl;
