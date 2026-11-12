modules = dict()
modules["local"] = list()

# Custom Logic
modules["local"].append(
    "hdlmake_library"
)

# LLRF 3HC Modules
# ESSFFW
# General Cores
modules["local"].append(
    ".."
)

# SIS8300-KU BSP
modules["local"].extend([
        "../ip_cores/essffw/hw/rtl/sis8300ku_bsp",
        "../ip_cores/essffw/hw/bd/sis8300ku_bsp",
        "../ip_cores/essffw/hw/constraints/sis8300ku_bsp",
        "../ip_cores/essffw/hw/ip/sis8300ku_bsp",
    ]
)

# FSP (None)
modules["local"].append(
    "../ip_cores/essffw/hw/rtl/blank_fsp"
)

# DWC8VM1 RSP
modules["local"].extend([
        "../ip_cores/essffw/hw/rtl/dwc8vm1_rsp",
        "../ip_cores/essffw/hw/ip/dwc8vm1_rsp",
    ]
)
