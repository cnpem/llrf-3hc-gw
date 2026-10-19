set ::adc_clk_period  8.0
set ::proc_clk_freq   125

source "../ip_cores/ess-fpga-framework/essffw_configuration.cfg"
source "../ip_cores/ess-fpga-framework/lib/fpga_build_automation/scripts/build_automation/templating.tcl"

set ::essffw::core::adc_resolution            16
set ::essffw::core::daq::channel_count        10
set ::essffw::core::daq::daq_pipeline_present true
set ::essffw::core::daq::dod_present          1
set ::essffw::core::daq::sample_data_bits     16
set ::essffw::core::processing_clk_freq       $proc_clk_freq
set ::essffw::core::replay::channel_count     10

set ::essffw::core::daq::_sample_data_bytes   [expr {$::essffw::core::daq::sample_data_bits / 8}]

set ::essffw::modules::bsp  sis8300ku
set ::essffw::modules::rsp  dwc8vm1
set ::essffw::modules::fsp1 blank
set ::essffw::modules::fsp2 blank
