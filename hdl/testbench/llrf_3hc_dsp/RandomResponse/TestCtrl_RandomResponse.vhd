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
  signal ADCScoreboardIDArr       : ScoreboardIDArrType(
                                      NUM_ADC_CHANNELS-1 downto 0
                                    );
  signal IScoreboardIDArr         : ScoreboardIDArrType(
                                      NUM_ADC_CHANNELS-1 downto 0
                                    );
  signal QScoreboardIDArr         : ScoreboardIDArrType(
                                      NUM_ADC_CHANNELS-1 downto 0
                                    );
  signal CICIScoreboardIDArr      : ScoreboardIDArrType(
                                      NUM_ADC_CHANNELS-1 downto 0
                                    );
  signal CICQScoreboardIDArr      : ScoreboardIDArrType(
                                      NUM_ADC_CHANNELS-1 downto 0
                                    );
  signal LLRF3HCDSPRefModelState  : LLRF3HCDSPRefModelStateRec(
                                      CICIStateArr(
                                        NUM_ADC_CHANNELS-1 downto 0
                                      ),
                                      CICQStateArr(
                                        NUM_ADC_CHANNELS-1 downto 0
                                      )
                                    );
  signal TbID                     : AlertLogIDType;
  signal TestDoneBarrier          : integer_barrier := 4;
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
      ADCScoreboardIDArr(chan) <=
        NewID(
          "ADCScoreboard[" & integer'image(chan) & "]",
          TbID
        );
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
      CICIScoreboardIDArr(chan) <=
        NewID(
          "CICIScoreboard[" & integer'image(chan) & "]",
          TbID
        );
      CICQScoreboardIDArr(chan) <=
        NewID(
          "CICQScoreboard[" & integer'image(chan) & "]",
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
    variable RV                   : RandomPType;
    variable ADCDataArr           : integer_vector(
                                      NUM_ADC_CHANNELS-1 downto 0
                                    );
    variable RefModelIArr         : integer_vector(
                                      NUM_ADC_CHANNELS-1 downto 0
                                    );
    variable RefModelQArr         : integer_vector(
                                      NUM_ADC_CHANNELS-1 downto 0
                                    );
    variable RefModelIQValidArr   : boolean_vector(
                                      NUM_ADC_CHANNELS-1 downto 0
                                    );
    variable RefModelCICIArr      : integer_vector(
                                      NUM_ADC_CHANNELS-1 downto 0
                                    );
    variable RefModelCICQArr      : integer_vector(
                                      NUM_ADC_CHANNELS-1 downto 0
                                    );
    variable RefModelCICIValidArr : boolean_vector(
                                      NUM_ADC_CHANNELS-1 downto 0
                                    );
    variable RefModelCICQValidArr : boolean_vector(
                                      NUM_ADC_CHANNELS-1 downto 0
                                    );
  begin
    RV.InitSeed(
      to_lower(
        SendADCDataProc'INSTANCE_NAME
      )
    );

    LLRF3HCDSPRefModelInit(
      NUM_ADC_CHANNELS,
      CIC_DIFF_DELAY,
      CIC_NUM_STAGES,
      LLRF3HCDSPRefModelState
    );

    -- Wait for design reset
    wait until Reset = '0';

    for CICRatio in 0 to CIC_MAX_RATIO loop
      -- Any changes to CIC ratio reinitializes its internal state
      LLRF3HCDSPRefModelCICReInit
        NUM_ADC_CHANNELS,
        CIC_DIFF_DELAY,
        CIC_NUM_STAGES,
        LLRF3HCDSPRefModelState
      );

      for i in 0 to NUM_SAMPLES_PER_TEST-1 loop
        ------------------------------------------------------------------------
        -- Generate random stimulus
        ------------------------------------------------------------------------
        for chan in 0 to NUM_ADC_CHANNELS-1 loop
          ADCDataArr(chan) :=
            RV.RandInt(
              -2**(ADC_DATA_WIDTH-1),
               2**(ADC_DATA_WIDTH-1)-1
            );
        end loop;

        ------------------------------------------------------------------------
        -- Iterate reference model
        ------------------------------------------------------------------------
        work.LLRF3HCDSPRefModelPkg.LLRF3HCDSPRefModelIterate(
          NUM_ADC_CHANNELS,
          ADC_DATA_WIDTH,
          CIC_DIFF_DELAY,
          CIC_NUM_STAGES,
          LLRF3HCDSPRefModelState,
          ADCDataArr,
          CICRatio,
          RefModelIArr,
          RefModelQArr,
          RefModelIQValidArr,
          RefModelCICIArr,
          RefModelCICQArr,
          RefModelCICIValidArr,
          RefModelCICQValidArr
        );

        ------------------------------------------------------------------------
        -- Push valid expected values
        ------------------------------------------------------------------------
        for chan in 0 to NUM_ADC_CHANNELS-1 loop
          -- Push valid ADC values
          Push(
            ADCScoreboardIDArr(chan),
            std_logic_vector(
              to_signed(
                ADCDataArr(chan),
                DUTDiagADCDataIfaceIn.DataArr(chan)'LENGTH
              )
            )
          );

          -- Push valid IQ demodulators values
          if RefModelIQValidArr(chan) = TRUE then
            Push(
              IScoreboardIDArr(chan),
              std_logic_vector(
                to_signed(
                  RefModelIArr(chan),
                  DUTDiagIQDemodulatorIfaceIn.IDataArr(chan)'LENGTH
                )
              )
            );
            Push(
              QScoreboardIDArr(chan),
              std_logic_vector(
                to_signed(
                  RefModelQArr(chan),
                  DUTDiagIQDemodulatorIfaceIn.QDataArr(chan)'LENGTH
                )
              )
            );
          end if;

          -- Push valid CIC values
          if RefModelCICIArrOut(chan) = TRUE then
            Push(
              CICIScoreboardIDArr(chan),
              std_logic_vector(
                to_signed(
                  RefModelCICIArr(chan),
                  DUTDiagIQDemodulatorIfaceIn.IArr(chan)'LENGTH
                )
              )
            );
          end if;
          if RefModelCICQArrOut(chan) = TRUE then
            Push(
              CICQScoreboardIDArr(chan),
              std_logic_vector(
                to_signed(
                  RefModelCICQArr(chan),
                  DUTDiagIQDemodulatorIfaceIn.IArr(chan)'LENGTH
                )
              )
            );
          end if;
        end loop;

        ------------------------------------------------------------------------
        -- Send ADC data
        ------------------------------------------------------------------------
        SendADCData(
          NUM_ADC_CHANNELS,
          Clk,
          ADCDataArr,
          ADCDataIfaceOut
        );
      end loop;
    end loop;

    WaitForBarrier(TestDoneBarrier);

    wait;
  end process SendADCDataProc;

  -- Get diagnostic data from 3HC LLRF DSP's ADCs and check it against expected
  -- values
  ADCDataGetCheckDataProc : process
    ----------------------------------------------------------------------------
    -- Variables
    ----------------------------------------------------------------------------
    variable DUTADCDataArr      : integer_vector(
                                    NUM_ADC_CHANNELS-1 downto 0
                                  );
    variable DUTADCDataValidArr : boolean_vector(
                                    NUM_ADC_CHANNELS-1 downto 0
                                  );
  begin
    -- Wait for design reset
    wait until Reset = '0';

    for i in 0 to NUM_SAMPLES_PER_TEST-1 loop
      --------------------------------------------------------------------------
      -- Get valid diagnostic data from ADCs
      --------------------------------------------------------------------------
      loop
        GetDiagADCData(
          NUM_ADC_CHANNELS,
          Clk,
          DUTDiagADCDataIfaceIn,
          DUTADCDataArr,
          DUTADCDataValidArr
        );
        exit when and DUTADCDataValidArr = TRUE;
      end loop;

      for chan in 0 to NUM_ADC_CHANNELS-1 loop
        ------------------------------------------------------------------------
        -- Check actual values against the expected ones
        ------------------------------------------------------------------------
        Check(
          ADCScoreboardIDArr(chan),
          std_logic_vector(
            to_signed(
              DUTADCDataArr(chan),
              DUTDiagADCDataIfaceIn.DataArr(chan)'LENGTH
            )
          )
        );
      end loop;
    end loop;

    WaitForBarrier(TestDoneBarrier);

    wait;
  end process ADCDataGetCheckDataProc;

  -- Get diagnostic data from 3HC LLRF DSP's IQ demodulators and check it
  -- against expected values
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
      -- Get valid diagnostic data from IQ demodulators
      --------------------------------------------------------------------------
      loop
        GetDiagIQDemodulatorData(
          NUM_ADC_CHANNELS,
          Clk,
          DUTDiagIQDemodulatorIfaceIn,
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
              DUTDiagIQDemodulatorIfaceIn.IArr(chan)'LENGTH
            )
          )
        );
        Check(
          QScoreboardIDArr(chan),
          std_logic_vector(
            to_signed(
              DUTQArr(chan),
              DUTDiagIQDemodulatorIfaceIn.QArr(chan)'LENGTH
            )
          )
        );
      end loop;
    end loop;

    WaitForBarrier(TestDoneBarrier);

    wait;
  end process IQDemodulatorGetCheckDataProc;

  -- Get diagnostic data from 3HC LLRF DSP's I component CICs and check it
  -- against expected values
  CICIGetCheckDataProc : process
    ----------------------------------------------------------------------------
    -- Variables
    ----------------------------------------------------------------------------
    variable DUTCICIArr       : integer_vector(
                                  NUM_ADC_CHANNELS-1 downto 0
                                );
    variable DUTCICIValidArr  : boolean_vector(
                                  NUM_ADC_CHANNELS-1 downto 0
                                );
  begin
    -- Wait for design reset
    wait until Reset = '0';

    for i in 0 to NUM_SAMPLES_PER_TEST-1 loop
      --------------------------------------------------------------------------
      -- Get valid diagnostic data from I component CICs
      --------------------------------------------------------------------------
      loop
        GetDiagCICData(
          NUM_ADC_CHANNELS,
          Clk,
          DUTDiagCICIfaceIn,
          DUTCICIArr,
          DUTCICIValidArr
        );
        exit when and DUTCICIValidArr = TRUE;
      end loop;

      for chan in 0 to NUM_ADC_CHANNELS-1 loop
        ------------------------------------------------------------------------
        -- Check actual values against the expected ones
        ------------------------------------------------------------------------
        Check(
          CICIScoreboardIDArr(chan),
          std_logic_vector(
            to_signed(
              DUTCICIArr(chan),
              DUTDiagCICIfaceIn.DataArr(chan)'LENGTH
            )
          )
        );
      end loop;
    end loop;

    WaitForBarrier(TestDoneBarrier);

    wait;
  end process CICIGetCheckDataProc;

  -- Get diagnostic data from 3HC LLRF DSP's Q component CICs and check it
  -- against expected values
  CICQGetCheckDataProc : process
    ----------------------------------------------------------------------------
    -- Variables
    ----------------------------------------------------------------------------
    variable DUTCICQArr       : integer_vector(
                                  NUM_ADC_CHANNELS-1 downto 0
                                );
    variable DUTCICQValidArr  : boolean_vector(
                                  NUM_ADC_CHANNELS-1 downto 0
                                );
  begin
    -- Wait for design reset
    wait until Reset = '0';

    for i in 0 to NUM_SAMPLES_PER_TEST-1 loop
      --------------------------------------------------------------------------
      -- Get valid diagnostic data from Q component CICs
      --------------------------------------------------------------------------
      loop
        GetDiagCICData(
          NUM_ADC_CHANNELS,
          Clk,
          DUTDiagCICIfaceIn,
          DUTCICQArr,
          DUTCICQValidArr
        );
        exit when and DUTCICQValidArr = TRUE;
      end loop;

      for chan in 0 to NUM_ADC_CHANNELS-1 loop
        ------------------------------------------------------------------------
        -- Check actual values against the expected ones
        ------------------------------------------------------------------------
        Check(
          CICIScoreboardIDArr(chan),
          std_logic_vector(
            to_signed(
              DUTCICQArr(chan),
              DUTDiagCICQfaceIn.DataArr(chan)'LENGTH
            )
          )
        );
      end loop;
    end loop;

    WaitForBarrier(TestDoneBarrier);

    wait;
  end process CICQGetCheckDataProc;
end RandomResponse;
