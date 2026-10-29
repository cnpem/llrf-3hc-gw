action = "simulation"
sim_tool = "nvc"
top_module = "TbLLRF3HCDSP"
target = "generic"

modules = {
    "local" : [
        "..",
    ]
}

nvc_opt = "--std=2008 --map osvvm:osvvm"
nvc_elab_opt = "--no-collapse"

sim_post_cmd = "nvc --map osvvm:osvvm -r --dump-arrays --exit-severity=error " \
        "%s --wave=%s.fst --format=fst" % (top_module, top_module)
