#!/bin/bash

mkdir -p doc
cheby \
  -i wb_llrf_3hc_dsp_diag_regs.cheby \
  --hdl vhdl --gen-hdl wb_llrf_3hc_dsp_diag_regs.vhd \
  --doc html --gen-doc doc/wb_llrf_3hc_dsp_diag_regs.html \
  --gen-c wb_llrf_3hc_dsp_diag_regs.h \
  --consts-style vhdl-ohwr --gen-consts ../../../sim/regs/wb_llrf_3hc_dsp_diag_regs_consts_pkg.vhd
