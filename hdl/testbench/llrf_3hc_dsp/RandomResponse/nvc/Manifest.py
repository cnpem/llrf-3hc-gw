action = "simulation"
sim_tool = "nvc"
top_module = "TbLLRF3HCDSP"
target = "generic"

modules = {
    "local" : [
        "..",
    ]
}

nvc_opt = (
    "--std=2008"
    " --map osvvm:osvvm"
    " --map osvvm_common:osvvm_common"
    " --map osvvm_wishbone:osvvm_wishbone"
)
nvc_elab_opt = "--no-collapse"

sim_post_cmd = (
    "nvc"
    " --map osvvm:osvvm"
    " --map osvvm_common:osvvm_common"
    " --map osvvm_wishbone:osvvm_wishbone"
    " -r --dump-arrays --exit-severity=error"
    " %s --wave=%s.fst --format=fst"
    % (top_module, top_module)
)
