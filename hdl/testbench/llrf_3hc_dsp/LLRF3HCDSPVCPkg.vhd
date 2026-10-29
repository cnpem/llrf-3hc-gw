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

library osvvm_common;
  context osvvm_common.OsvvmCommonContext;

library ieee;
  use ieee.numeric_std.all;
  use ieee.std_logic_1164.all;

library work;
  use work.llrf_3hc_pkg.all;

package LLRF3HCDSPVCPkg is
  ------------------------------------------------------------------------------
  -- Types
  ------------------------------------------------------------------------------
  type DataArrRec is record
    DataArr   : t_slv_arr;
    ValidArr  : std_logic_vector;
  end record;

  type IQDataArrRec is record
    IDataArr  : t_slv_arr;
    QDataArr  : t_slv_arr;
    ValidArr  : std_logic_vector;
  end record;

  type WishboneSlaveEnum is (
    CICI,
    CICQ
  );

  ------------------------------------------------------------------------------
  -- Procedures signatures
  ------------------------------------------------------------------------------
  -- Send ADC data to 3HC LLRF DSP
  procedure SendADCData(
    constant NUM_ADC_CHANNELS             : in  positive;
    signal   Clk                          : in  std_logic;
    constant DataArrIn                    : in  integer_vector;
    signal   TestCtrlToDUTIfaceOut        : out DataArrRec
  );

  procedure ReadFromWishboneSlave(
    constant NUM_ADC_CHANNELS             : in    positive;
    signal   Clk                          : in    std_logic;
    constant WishboneSlaveType            : in    WishboneSlaveEnum;
    constant WishboneSlaveChan            : in    positive;
    constant Address                      : in    integer;
    signal   TransRecInOut                : inout AddressBusRecType;
    signal   WishboneSlaveTypeOut         : out   WishboneSlaveEnum;
    signal   WishboneSlaveChanOut         : out   positive;
    variable ReadData                     : out   std_logic_vector(31 downto 0)
  );

  -- Get diagnostics data from 3HC LLRF DSP's ADCs
  procedure GetDiagADCData(
    constant NUM_ADC_CHANNELS             : in  positive;
    signal   Clk                          : in  std_logic;
    signal   DUTDiagADCDataIfaceIn        : in  DataArrRec;
    variable DiagADCDataArrOut            : out integer_vector;
    variable DiagADCDataValidArrOut       : out boolean_vector
  );

  -- Get diagnostics data from 3HC LLRF DSP's IQ demodulators
  procedure GetDiagIQDemodulatorData(
    constant NUM_ADC_CHANNELS             : in  positive;
    signal   Clk                          : in  std_logic;
    signal   DUTDiagIQDemodulatorIfaceIn  : in  IQDataArrRec;
    variable DiagIQDemodulatorIArrOut     : out integer_vector;
    variable DiagIQDemodulatorQArrOut     : out integer_vector;
    variable DiagIQDemodulatorValidArrOut : out boolean_vector
  );

  -- Get diagnostics data from 3HC LLRF DSP's CICs
  procedure GetDiagCICData(
    constant NUM_ADC_CHANNELS             : in  positive;
    signal   Clk                          : in  std_logic;
    signal   DUTDiagCICIfaceIn            : in  DataArrRec;
    variable DiagCICArrOut                : out integer_vector;
    variable DiagCICValidArrOut           : out boolean_vector
  );
end package;

package body LLRF3HCDSPVCPkg is
  ------------------------------------------------------------------------------
  -- Procedures implementations
  ------------------------------------------------------------------------------
  procedure SendADCData(
    constant NUM_ADC_CHANNELS             : in  positive;
    signal   Clk                          : in  std_logic;
    constant DataArrIn                    : in  integer_vector;
    signal   TestCtrlToDUTIfaceOut        : out DataArrRec
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

  procedure ReadFromWishboneSlave(
    constant NUM_ADC_CHANNELS             : in    positive;
    signal   Clk                          : in    std_logic;
    constant WishboneSlaveType            : in    WishboneSlaveEnum;
    constant WishboneSlaveChan            : in    positive;
    constant Address                      : in    integer;
    signal   TransRecInOut                : inout AddressBusRecType;
    signal   WishboneSlaveTypeOut         : out   WishboneSlaveEnum;
    signal   WishboneSlaveChanOut         : out   positive;
    variable ReadData                     : out   std_logic_vector(31 downto 0)
  ) is
  begin
    assert WishboneSlaveChan < NUM_ADC_CHANNELS
    report
      "llrf_3hc_dsp is parametrized with "
      & integer'image(NUM_ADC_CHANNELS) & "ADC channels, but got "
      & integer'image(WishboneSlaveChan)
    severity failure;

    WishboneSlaveTypeOut <= WishboneSlaveType;
    WishboneSlaveChanOut <= WishboneSlaveChan;

    Read(
      TransRecInOut,
      std_logic_vector(
        to_unsigned(Address, 32)
      ),
      ReadData
    );
  end procedure;

  procedure GetDiagADCData(
    constant NUM_ADC_CHANNELS             : in  positive;
    signal   Clk                          : in  std_logic;
    signal   DUTDiagADCDataIfaceIn        : in  DataArrRec;
    variable DiagADCDataArrOut            : out integer_vector;
    variable DiagADCDataValidArrOut       : out boolean_vector
  ) is
  begin
    WaitForClock(Clk, 1);
    for chan in 0 to NUM_ADC_CHANNELS-1 loop
      DiagADCDataArrOut(chan) :=
        to_integer(
          signed(
            DUTDiagADCDataIfaceIn.DataArr(chan)
          )
        );
      DiagADCDataValidArrOut(chan) :=
        (DUTDiagADCDataIfaceIn.ValidArr(chan) = '1');

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
    constant NUM_ADC_CHANNELS             : in  positive;
    signal   Clk                          : in  std_logic;
    signal   DUTDiagIQDemodulatorIfaceIn  : in  IQDataArrRec;
    variable DiagIQDemodulatorIArrOut     : out integer_vector;
    variable DiagIQDemodulatorQArrOut     : out integer_vector;
    variable DiagIQDemodulatorValidArrOut : out boolean_vector
  ) is
  begin
    WaitForClock(Clk, 1);
    for chan in 0 to NUM_ADC_CHANNELS-1 loop
      DiagIQDemodulatorIArrOut(chan) :=
        to_integer(
          signed(
            DUTDiagIQDemodulatorIfaceIn.IDataArr(chan)
          )
        );
      DiagIQDemodulatorQArrOut(chan) :=
        to_integer(
          signed(
            DUTDiagIQDemodulatorIfaceIn.QDataArr(chan)
          )
        );
      DiagIQDemodulatorValidArrOut(chan) :=
        (DUTDiagIQDemodulatorIfaceIn.ValidArr(chan) = '1');

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

  procedure GetDiagCICData(
    constant NUM_ADC_CHANNELS             : in  positive;
    signal   Clk                          : in  std_logic;
    signal   DUTDiagCICIfaceIn            : in  DataArrRec;
    variable DiagCICArrOut                : out integer_vector;
    variable DiagCICValidArrOut           : out boolean_vector
  ) is
  begin
    WaitForClock(Clk, 1);
    for chan in 0 to NUM_ADC_CHANNELS-1 loop
      DiagCICArrOut(chan) :=
        to_integer(
          signed(
            DUTDiagCICIfaceIn.DataArr(chan)
          )
        );
      DiagCICValidArrOut(chan) :=
        (DUTDiagCICIfaceIn.ValidArr(chan) = '1');

      Log(
        "Got from DUT: " &
        "DiagCICArrOut[" & integer'image(chan) & "] = " &
          "0x" & to_hstring(to_signed(DiagCICArrOut(chan), 32)),
        DEBUG
      );
      Log(
        "Got from DUT: " &
        "DiagCICValidArrOut[" & integer'image(chan) & "] = " &
          boolean'image(DiagCICValidArrOut(chan)),
        DEBUG
      );
    end loop;
  end procedure;
end package body;
