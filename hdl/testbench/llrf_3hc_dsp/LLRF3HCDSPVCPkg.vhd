--------------------------------------------------------------------------------
-- Title        : Testbench Verification Components
-- Project      : 3rd Hamonic Low-Level Radio Frequency
--------------------------------------------------------------------------------
-- File         : LLRF3HCDSPVCPkg.vhd
-- Author       : Guilherme Ricioli Cruz
-- Company      : CNPEM
-- Platform     : Simulation
-- Standard     : VHDL'08
--------------------------------------------------------------------------------
-- Description  : Verification components for testing the 3rd Hamonic (3HC)
--                Low-Level Radio Frequency (LLRF) top-level digital signal
--                processing chain using OSVVM.
--------------------------------------------------------------------------------
-- Copyright (c) 2026 CNPEM
--------------------------------------------------------------------------------

library osvvm;
  context osvvm.OSVVMContext;

library ieee;
  use ieee.numeric_std.all;
  use ieee.std_logic_1164.all;

library work;
  use work.llrf_3hc_pkg.all;

package LLRF3HCDSPVCPkg is
  ------------------------------------------------------------------------------
  -- Types
  ------------------------------------------------------------------------------
  type TestCtrlToDUTIfaceRec is record
    DataArr   : t_slv_arr;
    ValidArr  : std_logic_vector;
  end record;

  subtype DUTDiagADCDataToTestCtrlIfaceRec is TestCtrlToDUTIfaceRec;

  type DUTDiagIQDemodulatorToTestCtrlIfaceRec is record
    IArr        : t_slv_arr;
    QArr        : t_slv_arr;
    ValidArr    : std_logic_vector;
  end record;


  ------------------------------------------------------------------------------
  -- Procedures signatures
  ------------------------------------------------------------------------------
  -- Send ADC data to 3HC LLRF DSP
  procedure SendADCData(
    constant NUM_ADC_CHANNELS                       : in  positive;
    signal   Clk                                    : in  std_logic;
    constant DataArrIn                              : in  integer_vector;
    signal   TestCtrlToDUTIfaceOut                  : out TestCtrlToDUTIfaceRec
  );

  -- Get diagnostics data from 3HC LLRF DSP's ADCs
  procedure GetDiagADCData(
    constant NUM_ADC_CHANNELS                       : in  positive;
    signal   Clk                                    : in  std_logic;
    signal   DUTDiagADCDataToTestCtrlIfaceIn        :
      in  DUTDiagADCDataToTestCtrlIfaceRec;
    variable DiagADCDataArrOut                      : out integer_vector;
    variable DiagADCDataValidArrOut                 : out boolean_vector
  );

  -- Get diagnostics data from 3HC LLRF DSP's IQ demodulators
  procedure GetDiagIQDemodulatorData(
    constant NUM_ADC_CHANNELS                       : in  positive;
    signal   Clk                                    : in  std_logic;
    signal   DUTDiagIQDemodulatorToTestCtrlIfaceIn  :
      in  DUTDiagIQDemodulatorToTestCtrlIfaceRec;
    variable DiagIQDemodulatorIArrOut               : out integer_vector;
    variable DiagIQDemodulatorQArrOut               : out integer_vector;
    variable DiagIQDemodulatorValidArrOut           : out boolean_vector
  );
end package;

package body LLRF3HCDSPVCPkg is
  ------------------------------------------------------------------------------
  -- Procedures implementations
  ------------------------------------------------------------------------------
  procedure SendADCData(
    constant NUM_ADC_CHANNELS                       : in  positive;
    signal   Clk                                    : in  std_logic;
    constant DataArrIn                              : in  integer_vector;
    signal   TestCtrlToDUTIfaceOut                  : out TestCtrlToDUTIfaceRec
  ) is
  begin
    for chan in 0 to NUM_ADC_CHANNELS-1 loop
      TestCtrlToDUTIfaceOut.DataArr(chan) <=
        std_logic_vector(
          to_signed(
            DataArrIn(chan),
            TestCtrlToDUTIfaceOut.DataArr(chan)'LENGTH
          )
        );

      Log(
        "Sent to DUT: " &
        "ADCDataArr[" & integer'image(chan) & "] = " &
          "0x" & to_hstring(to_signed(DataArrIn(chan), 32)),
        DEBUG
      );
    end loop;
    WaitForClock(Clk, 1);
  end procedure;

  procedure GetDiagADCData(
    constant NUM_ADC_CHANNELS                       : in  positive;
    signal   Clk                                    : in  std_logic;
    signal   DUTDiagADCDataToTestCtrlIfaceIn        :
      in  DUTDiagADCDataToTestCtrlIfaceRec;
    variable DiagADCDataArrOut                      : out integer_vector;
    variable DiagADCDataValidArrOut                 : out boolean_vector
  ) is
  begin
    WaitForClock(Clk, 1);
    for chan in 0 to NUM_ADC_CHANNELS-1 loop
      DiagADCDataArrOut(chan) :=
        to_integer(
          signed(
            DUTDiagADCDataToTestCtrlIfaceIn.DataArr(chan)
          )
        );
      DiagADCDataValidArrOut(chan) :=
        (DUTDiagADCDataToTestCtrlIfaceIn.ValidArr(chan) = '1');

      Log(
        "Got from DUT: " &
        "DiagADCDataArrOut[" & integer'image(chan) & "] = " &
          "0x" & to_hstring(to_signed(DiagADCDataArrOut(chan), 32)),
        DEBUG
      );
      Log(
        "Got from DUT: " &
        "DiagADCDataValidArrOut[" & integer'image(chan) & "] = " &
          boolean'image(DiagADCDataValidArrOut(chan)),
        DEBUG
      );
    end loop;
  end procedure;

  procedure GetDiagIQDemodulatorData(
    constant NUM_ADC_CHANNELS                       : in  positive;
    signal   Clk                                    : in  std_logic;
    signal   DUTDiagIQDemodulatorToTestCtrlIfaceIn  :
      in  DUTDiagIQDemodulatorToTestCtrlIfaceRec;
    variable DiagIQDemodulatorIArrOut               : out integer_vector;
    variable DiagIQDemodulatorQArrOut               : out integer_vector;
    variable DiagIQDemodulatorValidArrOut           : out boolean_vector
  ) is
  begin
    WaitForClock(Clk, 1);
    for chan in 0 to NUM_ADC_CHANNELS-1 loop
      DiagIQDemodulatorIArrOut(chan) :=
        to_integer(
          signed(
            DUTDiagIQDemodulatorToTestCtrlIfaceIn.IArr(chan)
          )
        );
      DiagIQDemodulatorQArrOut(chan) :=
        to_integer(
          signed(
            DUTDiagIQDemodulatorToTestCtrlIfaceIn.QArr(chan)
          )
        );
      DiagIQDemodulatorValidArrOut(chan) :=
        (DUTDiagIQDemodulatorToTestCtrlIfaceIn.ValidArr(chan) = '1');

      Log(
        "Got from DUT: " &
        "DiagIQDemodulatorIArrOut[" & integer'image(chan) & "] = " &
          "0x" & to_hstring(to_signed(DiagIQDemodulatorIArrOut(chan), 32)),
        DEBUG
      );
      Log(
        "Got from DUT: " &
        "DiagIQDemodulatorQArrOut[" & integer'image(chan) & "] = " &
          "0x" & to_hstring(to_signed(DiagIQDemodulatorQArrOut(chan), 32)),
        DEBUG
      );
      Log(
        "Got from DUT: " &
        "DiagIQDemodulatorValidArrOut[" & integer'image(chan) & "] = " &
          boolean'image(DiagIQDemodulatorValidArrOut(chan)),
        DEBUG
      );
    end loop;
  end procedure;
end package body;
