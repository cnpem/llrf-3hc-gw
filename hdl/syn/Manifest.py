syn_pre_project_cmd = (
    "(grep -Fqx 'source essffw_build_env.tcl' project.tcl || "
    "sed -i '1i source essffw_build_env.tcl' project.tcl) && "
    "(grep -Fqx 'source assign_general_cores_lib.tcl' project.tcl || "
    "sed -i '/source files.tcl/a source assign_general_cores_lib.tcl' project.tcl)"
)

syn_pre_synthesize_cmd = (
    "(grep -Fqx 'source essffw_build_env.tcl' synthesize.tcl || "
    "sed -i '1i source essffw_build_env.tcl' synthesize.tcl) && "
    "(grep -Fqx 'source synthesize_fix.tcl' synthesize.tcl || "
    "sed -i '/open_project/a source synthesize_fix.tcl' synthesize.tcl) && "
    "(grep -Fqx 'launch_runs synth_1 -jobs 8' synthesize.tcl || "
    "sed -i 's/launch_runs synth_1/launch_runs synth_1 -jobs 8/g' synthesize.tcl)"
)

syn_pre_par_cmd = (
    "(grep -Fqx 'launch_runs impl_1 -jobs 8' par.tcl || "
    "sed -i 's/launch_runs impl_1/launch_runs impl_1 -jobs 8/g' par.tcl)"
)

syn_pre_bitstream_cmd = (
    "(grep -Fqx 'launch_runs impl_1 -jobs 8' bitstream.tcl || "
    "sed -i 's/launch_runs impl_1/launch_runs impl_1 -jobs 8/g' bitstream.tcl)"
)

target = "xilinx"
action = "synthesis"

language = "vhdl"

syn_device = "xcku040"
syn_grade = "-1-c"
syn_package = "-ffva1156"
syn_top = "sis8300ku_fw_to_chip"
syn_project = "custom_logic"
syn_tool = "vivado"

modules = {
    "local" : [
        "../top",
    ]
}
