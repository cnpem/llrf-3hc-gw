--------------------------------------------------------------------------------
-- Title        : Reference Model
-- Project      : General Cores Collection library
--------------------------------------------------------------------------------
-- File         : LLRF3HCDSPRefModelPkg.vhd
-- Author       : Guilherme Ricioli Cruz
-- Company      : CNPEM
-- Platform     : Simulation
-- Standard     : VHDL'08
--------------------------------------------------------------------------------
-- Description  : Package containing the reference model of 3rd Hamonic (3HC)
--                Low-Level Radio Frequency (LLRF) top-level digital signal
--                processing chain.
--------------------------------------------------------------------------------
-- Copyright (c) 2026 CNPEM
--------------------------------------------------------------------------------

library ieee;
  use ieee.numeric_std.all;

library work;
  use work.llrf_3hc_pkg.all;
  use work.IQDemodulatorRefModelPkg.all;

package LLRF3HCDSPRefModelPkg is
  ------------------------------------------------------------------------------
  -- Types
  ------------------------------------------------------------------------------
  alias LLRF3HCDSPRefModelStateEnum is
    work.IQDemodulatorRefModelPkg.IQDemodulatorRefModelStateEnum;

  ------------------------------------------------------------------------------
  -- Procedures signatures
  ------------------------------------------------------------------------------
  -- Initialize internal state
  procedure LLRF3HCDSPRefModelInit(
    signal    StateOut      : out LLRF3HCDSPRefModelStateEnum
  );

  -- Iterate the reference model
  procedure LLRF3HCDSPRefModelIterate(
    constant  NUM_ADC_CHANNELS  : in    positive;
    signal    StateInOut        : inout LLRF3HCDSPRefModelStateEnum;
    constant  ADCDataArrIn      : in    integer_vector;
    variable  IArrOut           : out   integer_vector;
    variable  QArrOut           : out   integer_vector;
    variable  IQValidArrOut     : out   boolean_vector
  );

end package;

package body LLRF3HCDSPRefModelPkg is
  ------------------------------------------------------------------------------
  -- Procedures implementations
  ------------------------------------------------------------------------------
  procedure LLRF3HCDSPRefModelInit(
    signal    StateOut      : out LLRF3HCDSPRefModelStateEnum
  ) is
  begin
    -- llrf_3hc_dsp registers ADC data, which inserts a 1-cycle delay into the
    -- pipeline. Consequently, IQ demodulators start to demodulate on its -Q
    -- state.
    StateOut <= MINUS_Q;
  end procedure;

  procedure LLRF3HCDSPRefModelIterate(
    constant  NUM_ADC_CHANNELS  : in    positive;
    signal    StateInOut        : inout LLRF3HCDSPRefModelStateEnum;
    constant  ADCDataArrIn      : in    integer_vector;
    variable  IArrOut           : out   integer_vector;
    variable  QArrOut           : out   integer_vector;
    variable  IQValidArrOut     : out   boolean_vector
  ) is
  begin
    for chan in 0 to NUM_ADC_CHANNELS-1 loop
      work.IQDemodulatorRefModelPkg.IQDemodulatorRefModelIterate(
        StateInOut,
        ADCDataArrIn(chan),
        IArrOut(chan),
        QArrOut(chan)
      );
      IQValidArrOut(chan) := TRUE;
    end loop;
  end procedure;
end package body;
