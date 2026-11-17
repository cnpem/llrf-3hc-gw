--------------------------------------------------------------------------------
-- Title        : 3rd Hamonic Low-Level Radio Frequency Top-Level Digital Signal
--                Processing Chain With Diagnostics ESSFFW Wrapper
-- Project      : 3rd Hamonic Low-Level Radio Frequency
--------------------------------------------------------------------------------
-- File         : custom_logic_wrapper.vhdl
-- Author       : Guilherme Ricioli Cruz
-- Company      : CNPEM
-- Platform     : Synthesis
-- Standard     : VHDL'08
--------------------------------------------------------------------------------
-- Description  : Wrapper to connect the 3rd Hamonic (3HC) Low-Level Radio
--                Frequency (LLRF) top-level digital signal processing chain
--                with diagnostics with European Spallation Source FPGA
--                Framework (ESSFFW).
--------------------------------------------------------------------------------
-- Copyright (c) 2026 CNPEM
--------------------------------------------------------------------------------

library ieee;
  use ieee.std_logic_1164.all;

library essffw_config;
  use essffw_config.essffw_config.all;

library essffw_intf;
  use essffw_intf.essffw_intf_types.all;

library general_cores;
  use general_cores.wishbone_pkg.all;

library llrf_3hc;
  use llrf_3hc.llrf_3hc_pkg.all;

entity custom_logic_wrapper is
  port (
    framework_core_i  : in  t_intf_core_to_cstmlog;
    framework_core_o  : out t_intf_cstmlog_to_core
  );
end entity;

architecture structural of custom_logic_wrapper is
  signal adc_data_arr               : t_slv_arr(
                                        ESSFFW_NR_ADC_CHANNELS-1 downto 0
                                      )(
                                        ESSFFW_ADC_RESOLUTION-1 downto 0
                                      );
  signal cmp_llrf_3hc_dsp_diag_wb_i : t_wishbone_slave_in;
  signal cmp_llrf_3hc_dsp_diag_wb_o : t_wishbone_slave_out;
begin
  ------------------------------------------------------------------------------
  -- AXI4-Lite-to-Wishbone brigde
  ------------------------------------------------------------------------------
  cmp_wb_axi4lite_bridge : entity general_cores.wb_axi4lite_bridge
    port map (
      clk_sys_i   => framework_core_i.processing_clock,
      rst_n_i     => framework_core_i.reset_n,
      ARVALID     => framework_core_i.regbus_axi_ms.arvalid,
      AWVALID     => framework_core_i.regbus_axi_ms.awvalid,
      BREADY      => framework_core_i.regbus_axi_ms.bready,
      RREADY      => framework_core_i.regbus_axi_ms.rready,
      WLAST       => '1',
      WVALID      => framework_core_i.regbus_axi_ms.wvalid,
      ARADDR      => f_align_lsb_32(
        framework_core_i.regbus_axi_ms.araddr
      ),
      AWADDR      => f_align_lsb_32(
        framework_core_i.regbus_axi_ms.awaddr
      ),
      WDATA       => framework_core_i.regbus_axi_ms.wdata,
      WSTRB       => framework_core_i.regbus_axi_ms.wstrb,
      ARREADY     => framework_core_o.regbus_axi_sm.arready,
      AWREADY     => framework_core_o.regbus_axi_sm.awready,
      BVALID      => framework_core_o.regbus_axi_sm.bvalid,
      RLAST       => open,
      RVALID      => framework_core_o.regbus_axi_sm.rvalid,
      WREADY      => framework_core_o.regbus_axi_sm.wready,
      BRESP       => framework_core_o.regbus_axi_sm.bresp,
      RRESP       => framework_core_o.regbus_axi_sm.rresp,
      RDATA       => framework_core_o.regbus_axi_sm.rdata,
      -- TODO: Remaining AXI4-Lite signals
      -- framework_core_i.regbus_axi_aclk,
      -- framework_core_i.regbus_axi_aresetn,
      -- framework_core_i.regbus_axi_ms.awprot,
      -- framework_core_i.regbus_axi_ms.arprot,
      wb_adr      => cmp_llrf_3hc_dsp_diag_wb_i.adr,
      wb_dat_m2s  => cmp_llrf_3hc_dsp_diag_wb_i.dat,
      wb_sel      => cmp_llrf_3hc_dsp_diag_wb_i.sel,
      wb_cyc      => cmp_llrf_3hc_dsp_diag_wb_i.cyc,
      wb_stb      => cmp_llrf_3hc_dsp_diag_wb_i.stb,
      wb_we       => cmp_llrf_3hc_dsp_diag_wb_i.we,
      wb_dat_s2m  => cmp_llrf_3hc_dsp_diag_wb_o.dat,
      wb_err      => cmp_llrf_3hc_dsp_diag_wb_o.err,
      wb_rty      => cmp_llrf_3hc_dsp_diag_wb_o.rty,
      wb_ack      => cmp_llrf_3hc_dsp_diag_wb_o.ack,
      wb_stall    => cmp_llrf_3hc_dsp_diag_wb_o.stall
    );

  ------------------------------------------------------------------------------
  -- Top-level 3HC LLRF DSP with diagnostics
  ------------------------------------------------------------------------------
  cmp_llrf_3hc_dsp_diag : entity llrf_3hc.llrf_3hc_dsp_diag
  generic map (
    g_NUM_ADC_CHANNELS  => ESSFFW_NR_ADC_CHANNELS,
    g_ADC_DATA_WIDTH    => ESSFFW_ADC_RESOLUTION
  )
  port map (
    rst_sys_i           => framework_core_i.reset_n,
    clk_sys_i           => framework_core_i.processing_clock,
    -- Use ADC0 AXI-Stream clock as the sampling clock
    clk_sampling_i      => framework_core_i.adc_preproc_aclk(0),
    adc_data_arr_i      => adc_data_arr,
    wb_i                => cmp_llrf_3hc_dsp_diag_wb_i,
    wb_o                => cmp_llrf_3hc_dsp_diag_wb_o
  );


  gen_framework_conn : for chan in 0 to ESSFFW_NR_ADC_CHANNELS-1 generate
  begin
      adc_data_arr(chan) <=
        framework_core_i.adc_preproc_axis.ch(chan).tdata(
            adc_data_arr(chan)'left downto 0
        );
  end generate gen_framework_conn;
end architecture structural;
