ESSFPGA_FRAMEWORK_DIR ?= $(HOME)/repos/BSP/ess_fpga_framework
PROJECT ?= cfg/sis8300ku_llrf.cfg

PROJECT_CFG := $(abspath $(PROJECT))

export ESSFPGA_FRAMEWORK_DIR

.PHONY: all project gui_project clean

all: project

project:
	$(MAKE) -C $(ESSFPGA_FRAMEWORK_DIR) \
		project="$(PROJECT_CFG)"

gui_project:
	$(MAKE) -C $(ESSFPGA_FRAMEWORK_DIR) \
		gui_project \
		project="$(PROJECT_CFG)"

clean:
	$(MAKE) -C $(ESSFPGA_FRAMEWORK_DIR) \
		project="$(PROJECT_CFG)" \
		clean

.PHONY: all project gui_project synthesis clean

all: project

project:
	$(MAKE) -C $(ESSFPGA_FRAMEWORK_DIR) \
		project="$(PROJECT_CFG)"

gui_project:
	$(MAKE) -C $(ESSFPGA_FRAMEWORK_DIR) \
		gui_project \
		project="$(PROJECT_CFG)"

synthesis:
	$(MAKE) -C $(ESSFPGA_FRAMEWORK_DIR) \
		synthesis \
		project="$(PROJECT_CFG)"

clean:
	$(MAKE) -C $(ESSFPGA_FRAMEWORK_DIR) \
		project="$(PROJECT_CFG)" \
		clean