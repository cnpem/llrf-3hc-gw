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
  use work.CICRefModelPkg.all;

package LLRF3HCDSPRefModelPkg is
  ------------------------------------------------------------------------------
  -- Types
  ------------------------------------------------------------------------------
  type CICRefModelStateRecArr is array
    (natural range <>) of CICRefModelStateRec;

  type LLRF3HCDSPRefModelStateRec is record
    IQDemodulatorState  : IQDemodulatorRefModelStateEnum;
    CICIStateArr        : CICRefModelStateRecArr;
    CICQStateArr        : CICRefModelStateRecArr;
  end record;

  ------------------------------------------------------------------------------
  -- Procedures signatures
  ------------------------------------------------------------------------------
  -- ReInitialize CIC internal state
  procedure LLRF3HCDSPRefModelCICReInit(
    constant  NUM_ADC_CHANNELS  : in    positive;
    constant  CIC_DIFF_DELAY    : in    positive;
    constant  CIC_NUM_STAGES    : in    positive;
    variable  StateOut          : out   LLRF3HCDSPRefModelStateRec
  );

  -- Initialize internal state
  procedure LLRF3HCDSPRefModelInit(
    constant  NUM_ADC_CHANNELS  : in    positive;
    constant  CIC_DIFF_DELAY    : in    positive;
    constant  CIC_NUM_STAGES    : in    positive;
    variable  StateOut          : out   LLRF3HCDSPRefModelStateRec
  );

  -- Iterate the reference model
  procedure LLRF3HCDSPRefModelIterate(
    constant  NUM_ADC_CHANNELS  : in    positive;
    constant  ADC_DATA_WIDTH    : in    positive;
    constant  CIC_DIFF_DELAY    : in    positive;
    constant  CIC_NUM_STAGES    : in    positive;
    signal    StateInOut        : inout LLRF3HCDSPRefModelStateRec;
    constant  ADCDataArrIn      : in    integer_vector;
    constant  CICRatio          : in    positive;
    variable  IArrOut           : out   integer_vector;
    variable  QArrOut           : out   integer_vector;
    variable  IQValidArrOut     : out   boolean_vector;
    variable  CICIArrOut        : out   integer_vector;
    variable  CICQArrOut        : out   integer_vector;
    variable  CICIValidArrOut   : out   boolean_vector;
    variable  CICQValidArrOut   : out   boolean_vector
  );

end package;

package body LLRF3HCDSPRefModelPkg is
  ------------------------------------------------------------------------------
  -- Procedures implementations
  ------------------------------------------------------------------------------
  procedure LLRF3HCDSPRefModelCICReInit(
    constant  NUM_ADC_CHANNELS  : in    positive;
    constant  CIC_DIFF_DELAY    : in    positive;
    constant  CIC_NUM_STAGES    : in    positive;
    variable  StateOut          : out   LLRF3HCDSPRefModelStateRec
  ) is
  begin
    for chan in 0 to NUM_ADC_CHANNELS-1 loop
      CICRefModelInit(
        CIC_DIFF_DELAY,
        CIC_NUM_STAGES,
        StateOut.CICIStateArr(chan)
      );
      CICRefModelInit(
        CIC_DIFF_DELAY,
        CIC_NUM_STAGES,
        StateOut.CICQStateArr(chan)
      );
    end loop;
  end procedure;

  procedure LLRF3HCDSPRefModelInit(
    constant  NUM_ADC_CHANNELS  : in    positive;
    constant  CIC_DIFF_DELAY    : in    positive;
    constant  CIC_NUM_STAGES    : in    positive;
    variable  StateOut          : out   LLRF3HCDSPRefModelStateRec
  ) is
  begin
    -- llrf_3hc_dsp registers ADC data, which inserts a 1-cycle delay into the
    -- pipeline. Consequently, IQ demodulators start to demodulate on its -Q
    -- state.
    StateOut.IQDemodulatorState := MINUS_Q;

    LLRF3HCDSPRefModelCICReInit(
      NUM_ADC_CHANNELS,
      CIC_DIFF_DELAY,
      CIC_NUM_STAGES,
      StateOut
    );
  end procedure;

  procedure LLRF3HCDSPRefModelIterate(
    constant  NUM_ADC_CHANNELS  : in    positive;
    constant  ADC_DATA_WIDTH    : in    positive;
    constant  CIC_DIFF_DELAY    : in    positive;
    constant  CIC_NUM_STAGES    : in    positive;
    signal    StateInOut        : inout LLRF3HCDSPRefModelStateRec;
    constant  ADCDataArrIn      : in    integer_vector;
    constant  CICRatio          : in    positive;
    variable  IArrOut           : out   integer_vector;
    variable  QArrOut           : out   integer_vector;
    variable  IQValidArrOut     : out   boolean_vector;
    variable  CICIArrOut        : out   integer_vector;
    variable  CICQArrOut        : out   integer_vector;
    variable  CICIValidArrOut   : out   boolean_vector;
    variable  CICQValidArrOut   : out   boolean_vector
  ) is
    variable CICIState,
             CICQState          : CICRefModelStateRec(
                                    Integrators(
                                      CIC_NUM_STAGES-1 downto 0
                                    ),
                                    Combs(
                                      CIC_NUM_STAGES-1 downto 0
                                    )(
                                      CIC_DIFF_DELAY-1 downto 0
                                    )
                                  );
  begin
    for chan in 0 to NUM_ADC_CHANNELS-1 loop
      CICIState := StateInOut.CICIStateArr(chan);
      CICQState := StateInOut.CICQStateArr(chan);

      --------------------------------------------------------------------------
      -- IQ demodulator
      --------------------------------------------------------------------------
      IQDemodulatorRefModelIterate(
        StateInOut.IQDemodulatorState,
        ADCDataArrIn(chan),
        IArrOut(chan),
        QArrOut(chan)
      );
      IQValidArrOut(chan) := TRUE;

      --------------------------------------------------------------------------
      -- CIC for I component
      --------------------------------------------------------------------------
      CICRefModelIterate(
        -- IQ demodulators' output is 1 bit larger than ADC data
        ADC_DATA_WIDTH+1,
        CIC_DIFF_DELAY,
        CIC_NUM_STAGES,
        FALSE,
        CICIState,
        CICRatio,
        IArrOut(chan),
        TRUE,
        CICIArrOut(chan),
        CICIValidArrOut(chan)
      );
      --------------------------------------------------------------------------
      -- CIC for Q component
      --------------------------------------------------------------------------
      CICRefModelIterate(
        -- IQ demodulators' output is 1 bit larger than ADC data
        ADC_DATA_WIDTH+1,
        CIC_DIFF_DELAY,
        CIC_NUM_STAGES,
        FALSE,
        CICQState,
        CICRatio,
        QArrOut(chan),
        TRUE,
        CICQArrOut(chan),
        CICQValidArrOut(chan)
      );

      StateInOut.CICIStateArr(chan) <= CICIState;
      StateInOut.CICQStateArr(chan) <= CICQState;
    end loop;
  end procedure;
end package body;
