ESSFPGA_FRAMEWORK_DIR ?= $(HOME)/repos/BSP/ess_fpga_framework
PROJECT ?= cfg/sis8300ku_llrf.cfg
HOST ?= localhost

PROJECT_CFG := $(abspath $(PROJECT))

export ESSFPGA_FRAMEWORK_DIR

.PHONY: all project gui_project synthesis implementation bitstream fpga sw \
        deploy_fpga deploy_cfgmem clean

all: fpga

project: gui_project

gui_project:
	$(MAKE) -C $(ESSFPGA_FRAMEWORK_DIR) \
		gui_project \
		project="$(PROJECT_CFG)"

synthesis:
	$(MAKE) -C $(ESSFPGA_FRAMEWORK_DIR) \
		synthesis \
		project="$(PROJECT_CFG)"

implementation:
	$(MAKE) -C $(ESSFPGA_FRAMEWORK_DIR) \
		implementation \
		project="$(PROJECT_CFG)"

bitstream:
	$(MAKE) -C $(ESSFPGA_FRAMEWORK_DIR) \
		write_bitfile \
		project="$(PROJECT_CFG)"

fpga:
	$(MAKE) -C $(ESSFPGA_FRAMEWORK_DIR) \
		fpga \
		project="$(PROJECT_CFG)"

sw:
	$(MAKE) -C $(ESSFPGA_FRAMEWORK_DIR) \
		sw \
		project="$(PROJECT_CFG)"

deploy_fpga:
	$(MAKE) -C $(ESSFPGA_FRAMEWORK_DIR) \
		deploy_fpga \
		project="$(PROJECT_CFG)" \
		host="$(HOST)"

deploy_cfgmem:
	$(MAKE) -C $(ESSFPGA_FRAMEWORK_DIR) \
		deploy_cfgmem \
		project="$(PROJECT_CFG)" \
		host="$(HOST)"

clean:
	$(MAKE) -C $(ESSFPGA_FRAMEWORK_DIR) \
		clean \
		project="$(PROJECT_CFG)"