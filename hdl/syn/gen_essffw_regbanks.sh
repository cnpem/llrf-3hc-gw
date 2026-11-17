#! /bin/bash

REGBANKS=(
  "./modules/adc3117_fsp/hw/ip/adc3117_fsp_regbank/adc3117_fsp_regbank_gen.py"
  "./modules/dio3118_fsp/hw/ip/dio3118_fsp_regbank/dio3118_fsp_regbank_gen.py"
  "./hw/ip/sis8900_rsp/sis8900_rsp_regbank/sis8900_rsp_regbank_gen.py"
  "./hw/ip/framework_core_regbank/framework_core_regbank_gen.py"
  "./hw/ip/rcc1466_rsp/rcc1466_piggyback_rsp_regbank/rcc1466_piggyback_rsp_regbank_gen.py"
  "./hw/ip/sis8300ku_bsp/sis8300ku_bsp_regbank/sis8300ku_bsp_regbank_gen.py"
  "./hw/ip/sis8300ku_bsp/ll_link_regbank/ll_link_regbank_gen.py"
  "./hw/ip/sis8300ku_test/sis8300ku_test_regbank/sis8300ku_test_regbank_gen.py"
  "./hw/ip/replay_main_regbank/replay_main_regbank_gen.py"
  "./hw/ip/lo_rtm_rsp/lo_rtm_rsp_regbank/lo_rtm_rsp_regbank_gen.py"
  "./hw/ip/input_block_channel_regbank/input_block_channel_regbank_gen.py"
  "./hw/ip/fmc2zup_test/fmc2zup_test_regbank/fmc2zup_test_regbank_gen.py"
  "./hw/ip/p2p_regbank/p2p_regbank_gen.py"
  "./hw/ip/rtm_carrier_bsp/rtm_carrier_bsp_regbank/rtm_carrier_bsp_regbank_gen.py"
  "./hw/ip/ifc1410_test/ifc1410_test_regbank/ifc1410_test_regbank_gen.py"
  "./hw/ip/fmc2zup_bsp/fmc2zup_bsp_regbank/fmc2zup_bsp_regbank_gen.py"
  "./hw/ip/piezo_rsp/piezo_rsp_regbank/piezo_rsp_regbank_gen.py"
  "./hw/ip/dummy_regbank/dummy_regbank_gen.py"
  "./hw/ip/sis8160_bsp/sis8160_bsp_regbank/sis8160_bsp_regbank_gen.py"
  "./hw/ip/sis8160_bsp/p2p_regbank/p2p_regbank_gen.py"
  "./hw/ip/dwc8vm1_rsp/dwc8vm1_rsp_regbank/dwc8vm1_rsp_regbank_gen.py"
  "./lib/ess_common/srcs/ip/esscom_clock_monitor/ip/clock_monitor_regbank/clock_monitor_regbank_gen.py"
  "./lib/ess_common/srcs/ip/esscom_ave/ip/aveu_regbank/aveu_regbank_gen.py"
  "./lib/ess_common/srcs/ip/esscom_maxi2data/ip/maxi2data_regbank/maxi2data_regbank_gen.py"
  "./lib/ess_common/srcs/ip/esscom_dod_channel/ip/dod_regbank/dod_regbank_gen.py"
  "./lib/ess_common/srcs/ip/axis2maxi/ip/axis2maxi_regbank/axis2maxi_regbank_gen.py"
)

pushd ../ip_cores/essffw

for regbank in "${REGBANKS[@]}"; do
    python3 ${regbank}
done

popd
