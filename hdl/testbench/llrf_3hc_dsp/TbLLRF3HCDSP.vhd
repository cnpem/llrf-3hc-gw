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

library osvvm_wishbone;
  context osvvm_wishbone.WishboneContext;

library work;
  use work.llrf_3hc_pkg.all;
  use work.LLRF3HCDSPVCPkg.all;
  use work.sim_wishbone.all;
  use work.wishbone_pkg.all;
  use work.WishboneGenericSignalsPkgDefault.all;

entity TbLLRF3HCDSP is
  generic (
    -- Number of ADC channels
    NUM_ADC_CHANNELS        : positive := 10;

    -- ADC data width
    ADC_DATA_WIDTH          : positive := 16;

    -- CIC differential delay
    CIC_DIFF_DELAY          : positive := 1;

    -- CIC number of stages
    CIC_NUM_STAGES          : positive := 1;

    -- CIC maximum decimation/interpolation ratio
    CIC_MAX_RATIO           : positive := 8;

    -- Wishbone generics
    WB_INTERFACE_MODE       : t_wishbone_interface_mode;
    WB_ADDRESS_GRANULARITY  : t_wishbone_address_granularity
  );
end entity TbLLRF3HCDSP;

architecture TestHarness of TbLLRF3HCDSP is
  ------------------------------------------------------------------------------
  -- Constants
  ------------------------------------------------------------------------------
  constant CLK_PERIOD           : time := 10 ns;
  constant RST_TIME             : time := 10 * CLK_PERIOD;

  ------------------------------------------------------------------------------
  -- Signals
  ------------------------------------------------------------------------------
  signal Clk                    : std_logic := '0';
  signal Reset                  : std_logic := '1';
  alias ClkSampling is Clk;

  -- Domain: ClkSampling
  signal ADCDataIface           : DataArrRec(
                                    -- Format: signed Q(g_ADC_DATA_WIDTH).0
                                    DataArr(
                                      NUM_ADC_CHANNELS-1 downto 0
                                    )(
                                      ADC_DATA_WIDTH-1 downto 0
                                    ),
                                    ValidArr(
                                      NUM_ADC_CHANNELS-1 downto 0
                                    )
                                  );

  -- Domain: ClkSampling
  signal DiagADCDataIface       : DataArrRec(
                                    -- Format: signed Q(g_ADC_DATA_WIDTH).0
                                    DataArr(
                                      NUM_ADC_CHANNELS-1 downto 0
                                    )(
                                      ADC_DATA_WIDTH-1 downto 0
                                    ),
                                    ValidArr(
                                      NUM_ADC_CHANNELS-1 downto 0
                                    )
                                  );

  -- Domain: ClkSampling
  signal DiagIQDemodulatorIface : IQDataArrRec(
                                    -- Format: signed Q(g_ADC_DATA_WIDTH+1).0
                                    IArr(
                                      NUM_ADC_CHANNELS-1 downto 0
                                    )(
                                      ADC_DATA_WIDTH downto 0
                                    ),
                                    -- Format: signed Q(g_ADC_DATA_WIDTH+1).0
                                    QArr(
                                      NUM_ADC_CHANNELS-1 downto 0
                                    )(
                                      ADC_DATA_WIDTH downto 0
                                    ),
                                    ValidArr(
                                      NUM_ADC_CHANNELS-1 downto 0
                                    )
                                  );

  -- Domain: ClkSampling
  signal DiagCICIIface          : DataArrRec(
                                    -- Format: signed Q(g_ADC_DATA_WIDTH+1).0
                                    DataArr(
                                      NUM_ADC_CHANNELS-1 downto 0
                                    )(
                                      ADC_DATA_WIDTH downto 0
                                    ),
                                    ValidArr(
                                      NUM_ADC_CHANNELS-1 downto 0
                                    )
                                  );
  -- Domain: ClkSampling
  signal DiagCICQIface          : DataArrRec(
                                    -- Format: signed Q(g_ADC_DATA_WIDTH+1).0
                                     DataArr(
                                       NUM_ADC_CHANNELS-1 downto 0
                                     )(
                                       ADC_DATA_WIDTH downto 0
                                     ),
                                     ValidArr(
                                       NUM_ADC_CHANNELS-1 downto 0
                                     )
                                   );

  -- Domain: Clk
  signal WbSlaveGlueIfaceIn     : t_wishbone_slave_in;
  signal WbSlaveGlueIfaceOut    : t_wishbone_slave_out;
  signal WbCICIArrIn            : t_wishbone_slave_in_array;
  signal WbCICQArrIn            : t_wishbone_slave_in_array;
  signal WbCICIArrOut           : t_wishbone_slave_out_array;
  signal WbCICQArrOut           : t_wishbone_slave_out_array;
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
  -- Test Control
  ------------------------------------------------------------------------------
  CmpTestCtrl : entity work.TestCtrl
    generic map (
      NUM_ADC_CHANNELS            => NUM_ADC_CHANNELS,
      ADC_DATA_WIDTH              => ADC_DATA_WIDTH
      CIC_DIFF_DELAY              => CIC_DIFF_DELAY,
      CIC_NUM_STAGES              => CIC_NUM_STAGES,
      CIC_MAX_RATIO               => CIC_MAX_RATIO
    )
    port map (
      Clk                         => Clk,
      Reset                       => Reset,
      DUTDiagADCDataIfaceIn       => DiagADCDataIface,
      DUTDiagIQDemodulatorIfaceIn => DiagIQDemodulatorIface,
      DUTDiagCICIIfaceIn          => DiagCICIIface,
      DUTDiagCICIQfaceIn          => DiagCICQIface,
      ADCDataIfaceOut             => ADCDataIface,
      WishboneSlaveTypeOut        => WishboneSlaveType,
      WishboneSlaveChanOut        => WishboneSlaveChan,
      TransRec                    => TransRec
    );

  ------------------------------------------------------------------------------
  -- Wishbone Manager VC
  ------------------------------------------------------------------------------
  CmpWishboneManager : entity osvvm_wishbone.WishboneManager
    generic map (
      WISHBONE_PIPELINED  => WB_INTERFACE_MODE = PIPELINED
    )
    port map (
      Clk                 => Clk,
      nReset              => not Reset,
      WishboneBus         => WishboneBus,
      TransRec            => TransRec
    );

  ------------------------------------------------------------------------------
  -- DUT: LLRF 3HC DSP
  ------------------------------------------------------------------------------
  DUT : entity work.llrf_3hc_dsp
    generic map (
      g_NUM_ADC_CHANNELS              => NUM_ADC_CHANNELS,
      g_ADC_DATA_WIDTH                => ADC_DATA_WIDTH
      g_CIC_DIFF_DELAY                => CIC_DIFF_DELAY,
      g_CIC_NUM_STAGES                => CIC_NUM_STAGES,
      g_CIC_MAX_RATIO                 => CIC_MAX_RATIO,
      g_WB_INTERFACE_MODE             => WB_INTERFACE_MODE,
      g_WB_ADDRESS_GRANULARITY        => WB_ADDRESS_GRANULARITY
    )
    port map (
      rst_sys_i                       => Reset,
      clk_sys_i                       => Clk,
      clk_sampling_i                  => ClkSampling,
      -- IQ demodulator assumes ADC data is feed is every sampling clock
      adc_data_arr_i                  => ADCDataIface.DataArr,
      wb_cic_i_wb_arr_i               => WbCICIArrIn,
      wb_cic_i_wb_arr_o               => WbCICIArrOut,
      wb_cic_q_wb_arr_i               => WbCICQArrIn,
      wb_cic_q_wb_arr_o               => WbCICQArrOut,
      diag_adc_data_arr_o             => DiagADCDataIface.DataArr,
      diag_adc_data_valid_arr_o       => DiagADCDataIface.ValidArr,
      diag_iq_demodulator_i_arr_o     => DiagIQDemodulatorIface.IArr,
      diag_iq_demodulator_q_arr_o     => DiagIQDemodulatorIface.QArr,
      diag_iq_demodulator_valid_arr_o => DiagIQDemodulatorIface.ValidArr
      diag_cic_i_arr_o                => DiagCICIIface.DataArr,
      diag_cic_i_valid_arr_o          => DiagCICIIface.ValidArr,
      diag_cic_q_arr_o                => DiagCICQIface.DataArr,
      diag_cic_q_valid_arr_o          => DiagCICQIface.ValidArr
    );

  ------------------------------------------------------------------------------
  -- Connections between Wishbone Manager VC and LLRF 3HC DSP
  ------------------------------------------------------------------------------
  -- Wishbone Manager VC => Wishbone Slave Glue Layer
  WbSlaveGlueIfaceIn.adr <=
    f_convert_granularity(
      WishboneBus.Adr,
      BYTE,
      WB_ADDRESS_GRANULARITY
    );
  WbSlaveGlueIfaceIn.cyc <= WishboneBus.Cyc;
  WbSlaveGlueIfaceIn.dat <= WishboneBus.oDat;
  WbSlaveGlueIfaceIn.sel <= WishboneBus.Sel;
  WbSlaveGlueIfaceIn.stb <= WishboneBus.Stb;
  WbSlaveGlueIfaceIn.we  <= WishboneBus.We;

  -- Wishbone Slave Glue Layer => Wishbone Manager VC
  WishboneBus.Ack   <= WbSlaveGlueIfaceOut.ack;
  WishboneBus.Err   <= WbSlaveGlueIfaceOut.err;
  WishboneBus.iDat  <= WbSlaveGlueIfaceOut.dat;
  WishboneBus.Rty   <= WbSlaveGlueIfaceOut.rty;
  WishboneBus.Stall <= WbSlaveGlueIfaceOut.stall;

  -- Wishbone Slave Glue Layer <=> LLRF 3HC DSP
  WishboneSlaveMuxProc : process
  begin
    for chan in 0 to g_NUM_ADC_CHANNELS-1 loop
      -- CIC I
      WbCICIArrIn(chan)   <= c_DUMMY_WB_SLAVE_IN;
      WbCICIArrOut(chan)  <= c_DUMMY_WB_SLAVE_OUT;
      -- CIC Q
      WbCICQArrIn(chan)   <= c_DUMMY_WB_SLAVE_IN;
      WbCICQArrOut(chan)  <= c_DUMMY_WB_SLAVE_OUT;
    end loop;

    case WishboneSlaveType is
      when CICI =>
        WbCICIArrIn(WishboneSlaveChan)  <= WbSlaveGlueIfaceIn;
        WbSlaveGlueIfaceOut             <= WbCICIArrOut(chan);
      when CICQ =>
        WbCICQArrIn(WishboneSlaveChan)  <= WbSlaveGlueIfaceIn;
        WbSlaveGlueIfaceOut             <= WbCICQArrOut(chan);
    end case;
  end process WishboneSlaveMuxProc;

end architecture TestHarness;
