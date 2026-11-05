modules = dict()
modules["local"] = list()

# ESSFFW
modules["local"].append(
    "../ip_cores/essffw",
)

# SIS8300-KU BSP
modules["local"].append(
    "../ip_cores/essffw/hw/rtl/sis8300ku_bsp",
    "../ip_cores/essffw/hw/bd/sis8300ku_bsp",
    "../ip_cores/essffw/hw/constraints/sis8300ku_bsp",
    "../ip_cores/essffw/hw/ip/sis8300ku_bsp",
)

# FSP (None)
modules["local"].append(
    "../ip_cores/essffw/hw/rtl/blank_fsp",
)

# DWC8VM1 RSP
modules["local"].append(
    "../ip_cores/essffw/hw/rtl/dwc8vm1_rsp",
)

files = [
    "custom_logic_wrapper.vhd",
    "clogic_essffw_config.vhd",
]
