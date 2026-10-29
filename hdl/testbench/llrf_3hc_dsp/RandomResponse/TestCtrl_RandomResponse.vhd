--------------------------------------------------------------------------------
-- Title        : Random Data Test Control Architecture
-- Project      : 3rd Hamonic Low-Level Radio Frequency
--------------------------------------------------------------------------------
-- File         : TestCtrl_RandomResponse.vhd
-- Author       : Guilherme Ricioli Cruz
-- Company      : CNPEM
-- Platform     : Simulation
-- Standard     : VHDL'08
--------------------------------------------------------------------------------
-- Description  : Architecture for verifying the 3rd Hamonic (3HC) Low-Level
--                Radio Frequency (LLRF) top-level digital signal processing
--                chain response to random data.
--------------------------------------------------------------------------------
-- Copyright (c) 2026 CNPEM
--------------------------------------------------------------------------------

architecture RandomResponse of TestCtrl is
  ------------------------------------------------------------------------------
  -- Constants
  ------------------------------------------------------------------------------
  constant NUM_SAMPLES_PER_TEST   : natural := 10000;

  ------------------------------------------------------------------------------
  -- Types
  ------------------------------------------------------------------------------
  use osvvm.ScoreboardPkg_slv.all;
  type ScoreboardIDArrType is array (natural range <>) of
    osvvm.ScoreboardPkg_slv.ScoreboardIDType;

  ------------------------------------------------------------------------------
  -- Signals
  ------------------------------------------------------------------------------
  signal IScoreboardIDArr         : ScoreboardIDArrType(
                                      NUM_ADC_CHANNELS-1 downto 0
                                    );
  signal QScoreboardIDArr         : ScoreboardIDArrType(
                                      NUM_ADC_CHANNELS-1 downto 0
                                    );


  signal LLRF3HCDSPRefModelState  : LLRF3HCDSPRefModelStateEnum;

  signal TbID                     : AlertLogIDType;
  signal TestDoneBarrier          : integer_barrier := 3;
begin
  ------------------------------------------------------------------------------
  -- Processes
  ------------------------------------------------------------------------------
  -- Set AlertLog and wait for end of test
  ControlProc : process
  begin
    SetTestName(
      "RandomResponse"
    );

    -- Enable PASSED logs
    SetLogEnable(
      PASSED,
      TRUE
    );
    -- Enable INFO logs
    SetLogEnable(
      INFO,
      TRUE
    );

    TranscriptOpen(
      "RandomResponse.txt"
    );
    SetTranscriptMirror(
      TRUE
    );

    -- Default with 2024.01
    SetAlertLogOptions(
      WriteTimeLast => FALSE
    );
    -- Default with 2024.01
    SetAlertLogOptions(
      TimeJustifyAmount => 8
    );

    TbID <=
      NewID(
        "RandomResponse"
      );
    wait for 0 ns;
    for chan in 0 to NUM_ADC_CHANNELS-1 loop
      IScoreboardIDArr(chan) <=
        NewID(
          "IScoreboard[" & integer'image(chan) & "]",
          TbID
        );
      QScoreboardIDArr(chan) <=
        NewID(
          "QScoreboard[" & integer'image(chan) & "]",
          TbID
        );
    end loop;

    -- Wait for design reset
    wait until Reset = '0';
    ClearAlerts;

    -- Wait for test to finish
    WaitForBarrier(
      TestDoneBarrier,
      40 ms
    );
    AlertIf(
      now >= 40 ms,
      "Test finished due to timeout"
    );

    TranscriptClose;

    print("");
    EndOfTestReports;
    print("");

    std.env.stop(
      GetAlertCount
    );

    wait;
  end process ControlProc;

  -- Send data to 3HC LLRF DSP
  SendADCDataProc : process
    ----------------------------------------------------------------------------
    -- Variables
    ----------------------------------------------------------------------------
    variable RV                 : RandomPType;
    variable ADCDataArr         : integer_vector(
                                    NUM_ADC_CHANNELS-1 downto 0
                                  );
    variable RefModelIArr       : integer_vector(
                                    NUM_ADC_CHANNELS-1 downto 0
                                  );
    variable RefModelQArr       : integer_vector(
                                    NUM_ADC_CHANNELS-1 downto 0
                                  );
    variable RefModelIQValidArr : boolean_vector(
                                    NUM_ADC_CHANNELS-1 downto 0
                                  );
  begin
    RV.InitSeed(
      to_lower(
        SendADCDataProc'INSTANCE_NAME
      )
    );

    LLRF3HCDSPRefModelInit(
      LLRF3HCDSPRefModelState
    );

    -- Wait for design reset
    wait until Reset = '0';

    for i in 0 to NUM_SAMPLES_PER_TEST-1 loop
      --------------------------------------------------------------------------
      -- Generate random stimulus
      --------------------------------------------------------------------------
      for chan in 0 to NUM_ADC_CHANNELS-1 loop
        ADCDataArr(chan) :=
          RV.RandInt(
            -2**(ADC_DATA_WIDTH-1),
             2**(ADC_DATA_WIDTH-1)-1
          );
      end loop;

      --------------------------------------------------------------------------
      -- Iterate reference model
      --------------------------------------------------------------------------
      work.LLRF3HCDSPRefModelPkg.LLRF3HCDSPRefModelIterate(
        NUM_ADC_CHANNELS,
        LLRF3HCDSPRefModelState,
        ADCDataArr,
        RefModelIArr,
        RefModelQArr,
        RefModelIQValidArr
      );

      --------------------------------------------------------------------------
      -- Push valid expected values
      --------------------------------------------------------------------------
      for chan in 0 to NUM_ADC_CHANNELS-1 loop
        -- Push valid IQ demodulators values
        if RefModelIQValidArr(chan) = TRUE then
          Push(
            IScoreboardIDArr(chan),
            std_logic_vector(
              to_signed(
                RefModelIArr(chan),
                DUTDbgIQDemodulatorToTestCtrlIfaceIn.IArr(chan)'LENGTH
              )
            )
          );
          Push(
            QScoreboardIDArr(chan),
            std_logic_vector(
              to_signed(
                RefModelQArr(chan),
                DUTDbgIQDemodulatorToTestCtrlIfaceIn.QArr(chan)'LENGTH
              )
            )
          );
        end if;
      end loop;

      --------------------------------------------------------------------------
      -- Send data
      --------------------------------------------------------------------------
      work.LLRF3HCDSPVCPkg.SendADCData(
        NUM_ADC_CHANNELS,
        Clk,
        ADCDataArr,
        TestCtrlToDUTIfaceOut
      );
    end loop;

    WaitForBarrier(TestDoneBarrier);

    wait;
  end process SendADCDataProc;

  -- Get data from 3HC LLRF DSP's IQ demodulators and check it against expected
  -- values
  IQDemodulatorGetCheckDataProc : process
    ----------------------------------------------------------------------------
    -- Variables
    ----------------------------------------------------------------------------
    variable DUTIArr        : integer_vector(
                                NUM_ADC_CHANNELS-1 downto 0
                              );
    variable DUTQArr        : integer_vector(
                                NUM_ADC_CHANNELS-1 downto 0
                              );
    variable DUTIQValidArr  : boolean_vector(
                                NUM_ADC_CHANNELS-1 downto 0
                              );
  begin
    -- Wait for design reset
    wait until Reset = '0';

    for i in 0 to NUM_SAMPLES_PER_TEST-1 loop
      --------------------------------------------------------------------------
      -- Get valid data from IQ demodulators
      --------------------------------------------------------------------------
      loop
        work.LLRF3HCDSPVCPkg.GetDbgIQDemodulatorData(
          NUM_ADC_CHANNELS,
          Clk,
          DUTDbgIQDemodulatorToTestCtrlIfaceIn,
          DUTIArr,
          DUTQArr,
          DUTIQValidArr
        );
        exit when and DUTIQValidArr = TRUE;
      end loop;

      for chan in 0 to NUM_ADC_CHANNELS-1 loop
        ------------------------------------------------------------------------
        -- Check actual values against the expected ones
        ------------------------------------------------------------------------
        Check(
          IScoreboardIDArr(chan),
          std_logic_vector(
            to_signed(
              DUTIArr(chan),
              DUTDbgIQDemodulatorToTestCtrlIfaceIn.IArr(chan)'LENGTH
            )
          )
        );
        Check(
          QScoreboardIDArr(chan),
          std_logic_vector(
            to_signed(
              DUTQArr(chan),
              DUTDbgIQDemodulatorToTestCtrlIfaceIn.QArr(chan)'LENGTH
            )
          )
        );
      end loop;
    end loop;

    WaitForBarrier(TestDoneBarrier);

    wait;
  end process IQDemodulatorGetCheckDataProc;
end RandomResponse;
