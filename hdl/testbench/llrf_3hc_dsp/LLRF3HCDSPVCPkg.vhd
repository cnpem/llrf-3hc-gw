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
    ADCDataArr  : t_slv_arr;
  end record;

  type DUTDbgIQDemodulatorToTestCtrlIfaceRec is record
    IArr        : t_slv_arr;
    QArr        : t_slv_arr;
    ValidArr    : std_logic_vector;
  end record;

  ------------------------------------------------------------------------------
  -- Procedures signatures
  ------------------------------------------------------------------------------
  -- Send data to 3HC LLRF DSP
  procedure SendADCData(
    constant NUM_ADC_CHANNELS                     : in  positive;
    signal   Clk                                  : in  std_logic;
    constant DataArrIn                            : in  integer_vector;
    signal   TestCtrlToDUTIfaceOut                : out TestCtrlToDUTIfaceRec
  );

  -- Get data from 3HC LLRF DSP's IQ demodulators
  procedure GetDbgIQDemodulatorData(
    constant NUM_ADC_CHANNELS                     : in  positive;
    signal   Clk                                  : in  std_logic;
    signal   DUTDbgIQDemodulatorToTestCtrlIfaceIn :
      in  DUTDbgIQDemodulatorToTestCtrlIfaceRec;
    variable DbgIQDemodulatorIArrOut              : out integer_vector;
    variable DbgIQDemodulatorQArrOut              : out integer_vector;
    variable DbgIQDemodulatorValidArrOut          : out boolean_vector
  );
end package;

package body LLRF3HCDSPVCPkg is
  ------------------------------------------------------------------------------
  -- Procedures implementations
  ------------------------------------------------------------------------------
  procedure SendADCData(
    constant NUM_ADC_CHANNELS                     : in  positive;
    signal   Clk                                  : in  std_logic;
    constant DataArrIn                            : in  integer_vector;
    signal   TestCtrlToDUTIfaceOut                : out TestCtrlToDUTIfaceRec
  ) is
  begin
    for chan in 0 to NUM_ADC_CHANNELS-1 loop
      TestCtrlToDUTIfaceOut.ADCDataArr(chan) <=
        std_logic_vector(
          to_signed(
            DataArrIn(chan),
            TestCtrlToDUTIfaceOut.ADCDataArr(chan)'LENGTH
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

  procedure GetDbgIQDemodulatorData(
    constant NUM_ADC_CHANNELS                     : in  positive;
    signal   Clk                                  : in  std_logic;
    signal   DUTDbgIQDemodulatorToTestCtrlIfaceIn :
      in  DUTDbgIQDemodulatorToTestCtrlIfaceRec;
    variable DbgIQDemodulatorIArrOut              : out integer_vector;
    variable DbgIQDemodulatorQArrOut              : out integer_vector;
    variable DbgIQDemodulatorValidArrOut          : out boolean_vector
  ) is
  begin
    WaitForClock(Clk, 1);
    for chan in 0 to NUM_ADC_CHANNELS-1 loop
      DbgIQDemodulatorIArrOut(chan) :=
        to_integer(
          signed(
            DUTDbgIQDemodulatorToTestCtrlIfaceIn.IArr(chan)
          )
        );
      DbgIQDemodulatorQArrOut(chan) :=
        to_integer(
          signed(
            DUTDbgIQDemodulatorToTestCtrlIfaceIn.QArr(chan)
          )
        );
      DbgIQDemodulatorValidArrOut(chan) :=
        (DUTDbgIQDemodulatorToTestCtrlIfaceIn.ValidArr(chan) = '1');

      Log(
        "Got from DUT: " &
        "DbgIQDemodulatorIArrOut[" & integer'image(chan) & "] = " &
          "0x" & to_hstring(to_signed(DbgIQDemodulatorIArrOut(chan), 32)),
        DEBUG
      );
      Log(
        "Got from DUT: " &
        "DbgIQDemodulatorQArrOut[" & integer'image(chan) & "] = " &
          "0x" & to_hstring(to_signed(DbgIQDemodulatorQArrOut(chan), 32)),
        DEBUG
      );
      Log(
        "Got from DUT: " &
        "DbgIQDemodulatorValidArrOut[" & integer'image(chan) & "] = " &
          boolean'image(DbgIQDemodulatorValidArrOut(chan)),
        DEBUG
      );
    end loop;
  end procedure;
end package body;
