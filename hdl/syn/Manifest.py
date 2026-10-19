import os

syn_pre_project_cmd = (
    "(grep -Fqx 'source essffw_build_env.tcl' project.tcl || "
    "sed -i '1i source essffw_build_env.tcl' project.tcl)"
)

syn_pre_synthesize_cmd = (
    "(grep -Fqx 'source essffw_build_env.tcl' synthesize.tcl || "
    "sed -i '1i source essffw_build_env.tcl' synthesize.tcl) && "
    "(grep -Fqx 'source synthesize_fix.tcl' synthesize.tcl || "
    "sed -i '/open_project/a source synthesize_fix.tcl' synthesize.tcl)"
)

target = "xilinx"
action = "synthesis"

language = "vhdl"

syn_device = "xcku040"
syn_grade = "-1-c"
syn_package = "-ffva1156"
syn_top = "sis8300ku_fw_to_chip"
syn_project = "custom_logic_test"
syn_tool = "vivado"

modules = {
    "local" : [
        "../top",
    ]
}
