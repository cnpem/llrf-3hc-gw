#-------------------------------------------------------------------------------
# Project     : 3rd Harmonic Low-Level Radio Frequency
#-------------------------------------------------------------------------------
# File        : Makefile
# Platform    : Xilinx Vivado 2022.2
#-------------------------------------------------------------------------------
# Description : Build the SIS8300KU LLRF project using the ESS FPGA Framework
#               included as a Git submodule.
#-------------------------------------------------------------------------------

################################################################################
# Paths
################################################################################

ROOT_DIR := $(patsubst %/,%,$(dir $(abspath $(lastword $(MAKEFILE_LIST)))))

ESSFPGA_FRAMEWORK_DIR := \
	$(ROOT_DIR)/hdl/ip_cores/essffw

BUILD_SCRIPT_DIR := \
	$(ESSFPGA_FRAMEWORK_DIR)/lib/fpga_build_automation/scripts/build_automation

BUILD_DIR := \
	$(ROOT_DIR)/build/sis8300ku_llrf

BITSTREAM_DIR := \
	$(ROOT_DIR)/bitstream

################################################################################
# Project selection
################################################################################

PROJECT ?= cfg/sis8300ku_llrf.cfg

# Compatibility with the ESSFFW command syntax:
#
#   make project=sis8300ku_llrf.cfg
#
ifdef project
PROJECT := $(project)
endif

# Accept either:
#
#   make project=sis8300ku_llrf.cfg
#
# or:
#
#   make project=cfg/sis8300ku_llrf.cfg
#
ifneq ($(wildcard $(PROJECT)),)
PROJECT_CFG := $(abspath $(PROJECT))
else
PROJECT_CFG := $(abspath cfg/$(PROJECT))
endif

PROJECT_NAME := sis8300ku_llrf
SW_NAME := sis8300ku_llrf_config

################################################################################
# Generated files
################################################################################

FPGA_BIT := \
	$(BUILD_DIR)/$(PROJECT_NAME).bit

FPGA_LTX := \
	$(BUILD_DIR)/$(PROJECT_NAME).ltx

SW_BIT := \
	$(BUILD_DIR)/$(PROJECT_NAME)-$(SW_NAME).bit

SW_BIN := \
	$(BUILD_DIR)/$(PROJECT_NAME)-$(SW_NAME).bin

SW_PRM := \
	$(BUILD_DIR)/$(PROJECT_NAME)-$(SW_NAME).prm

################################################################################
# Environment
################################################################################

export ESSFPGA_FRAMEWORK_DIR

.DEFAULT_GOAL := project

################################################################################
# Phony targets
################################################################################

.PHONY: \
	all \
	project \
	fpga \
	gui_project \
	synthesis \
	implementation \
	bitstream \
	sw \
	prepare \
	check_submodules \
	check_project \
	check_vivado \
	check_vitis \
	publish_bitstream \
	publish_software \
	clean \
	clean_all

################################################################################
# Complete FPGA build
################################################################################

all: project

# Complete hardware flow:
#
#   project creation
#   synthesis
#   implementation
#   bitstream generation
#
project: check_submodules check_project check_vivado prepare
	@echo
	@echo "============================================================"
	@echo "Building SIS8300KU LLRF FPGA project"
	@echo "Project: $(PROJECT_CFG)"
	@echo "Build:   $(BUILD_DIR)"
	@echo "Output:  $(BITSTREAM_DIR)"
	@echo "============================================================"
	@echo
	$(MAKE) gui_project
	$(MAKE) synthesis
	$(MAKE) implementation
	$(MAKE) bitstream

# Alias for the hardware flow without project creation.
fpga: check_submodules check_project check_vivado prepare
	$(MAKE) synthesis
	$(MAKE) implementation
	$(MAKE) bitstream

################################################################################
# Validation
################################################################################

check_submodules:
	@test -f "$(ESSFPGA_FRAMEWORK_DIR)/makefile" || { \
		echo "ERROR: ESS FPGA Framework submodule is not initialized."; \
		echo "Run:"; \
		echo "  git submodule sync --recursive"; \
		echo "  git submodule update --init --recursive"; \
		exit 1; \
	}
	@test -f \
		"$(ROOT_DIR)/hdl/ip_cores/general-cores/modules/wishbone/wishbone_pkg.vhd" \
		|| { \
		echo "ERROR: General Cores submodule is not initialized."; \
		echo "Run:"; \
		echo "  git submodule update --init --recursive"; \
		exit 1; \
	}

check_project:
	@test -f "$(PROJECT_CFG)" || { \
		echo "ERROR: project configuration was not found:"; \
		echo "  $(PROJECT_CFG)"; \
		exit 1; \
	}

check_vivado:
	@command -v vivado >/dev/null 2>&1 || { \
		echo "ERROR: vivado was not found in PATH."; \
		echo "Load the Xilinx Vivado 2022.2 environment."; \
		exit 1; \
	}

check_vitis:
	@command -v xsct >/dev/null 2>&1 || { \
		echo "ERROR: xsct was not found in PATH."; \
		echo "Load the Xilinx Vitis/XSCT environment."; \
		exit 1; \
	}

################################################################################
# Build-directory preparation
################################################################################

prepare:
	@mkdir -p "$(BUILD_DIR)"
	@mkdir -p "$(BUILD_DIR)/output"
	@mkdir -p "$(BITSTREAM_DIR)"

################################################################################
# Vivado project creation
################################################################################

gui_project: check_submodules check_project check_vivado prepare
	@echo
	@echo "Creating Vivado GUI project..."
	@echo
	cd "$(BUILD_DIR)" && \
	vivado \
		-nojournal \
		-mode batch \
		-source "$(BUILD_SCRIPT_DIR)/create_gui_project.tcl" \
		-log output/create_gui_project.log \
		-tclargs "$(PROJECT_CFG)"

################################################################################
# Synthesis
################################################################################

synthesis: check_submodules check_project check_vivado prepare
	@echo
	@echo "Running synthesis..."
	@echo
	cd "$(BUILD_DIR)" && \
	vivado \
		-nojournal \
		-mode batch \
		-source "$(BUILD_SCRIPT_DIR)/synthesis.tcl" \
		-log output/synthesis.log \
		-tclargs "$(PROJECT_CFG)"

################################################################################
# Implementation
################################################################################

implementation: check_submodules check_project check_vivado prepare
	@echo
	@echo "Running implementation..."
	@echo
	cd "$(BUILD_DIR)" && \
	vivado \
		-nojournal \
		-mode batch \
		-source "$(BUILD_SCRIPT_DIR)/implementation.tcl" \
		-log output/implementation.log \
		-tclargs "$(PROJECT_CFG)"

################################################################################
# Hardware bitstream
################################################################################

bitstream: check_submodules check_project check_vivado prepare
	@echo
	@echo "Generating hardware bitstream..."
	@echo
	cd "$(BUILD_DIR)" && \
	vivado \
		-nojournal \
		-mode batch \
		-source "$(BUILD_SCRIPT_DIR)/write_bitfile.tcl" \
		-log output/write_bitfile.log \
		-tclargs "$(PROJECT_CFG)"
	$(MAKE) publish_bitstream

publish_bitstream:
	@test -f "$(FPGA_BIT)" || { \
		echo "ERROR: hardware bitstream was not generated:"; \
		echo "  $(FPGA_BIT)"; \
		exit 1; \
	}
	@mkdir -p "$(BITSTREAM_DIR)"
	cp -f \
		"$(FPGA_BIT)" \
		"$(BITSTREAM_DIR)/"
	@if [ -f "$(FPGA_LTX)" ]; then \
		cp -f \
			"$(FPGA_LTX)" \
			"$(BITSTREAM_DIR)/"; \
	fi
	@echo
	@echo "Hardware bitstream generated:"
	@ls -lh "$(BITSTREAM_DIR)/$(PROJECT_NAME).bit"
	@if [ -f "$(BITSTREAM_DIR)/$(PROJECT_NAME).ltx" ]; then \
		ls -lh "$(BITSTREAM_DIR)/$(PROJECT_NAME).ltx"; \
	fi

################################################################################
# MicroBlaze software and SPI configuration image
################################################################################

sw: check_submodules check_project check_vivado check_vitis prepare
	@echo
	@echo "============================================================"
	@echo "Building SIS8300KU LLRF MicroBlaze software"
	@echo "Project: $(PROJECT_CFG)"
	@echo "Build:   $(BUILD_DIR)"
	@echo "Output:  $(BITSTREAM_DIR)"
	@echo "============================================================"
	@echo
	@test -f "$(BUILD_DIR)/output/$(PROJECT_NAME).hdf" \
		-o -f "$(BUILD_DIR)/output/$(PROJECT_NAME).xsa" || { \
		echo "ERROR: hardware platform was not found."; \
		echo "Run the FPGA build first:"; \
		echo "  make project=sis8300ku_llrf.cfg"; \
		exit 1; \
	}
	cd "$(BUILD_DIR)" && \
	xsct \
		"$(BUILD_SCRIPT_DIR)/create_software.tcl" \
		"$(PROJECT_CFG)"
	cd "$(BUILD_DIR)" && \
	vivado \
		-nojournal \
		-mode batch \
		-source "$(BUILD_SCRIPT_DIR)/generate_flash.tcl" \
		-log output/generate_flash.log \
		-tclargs "$(PROJECT_CFG)"
	$(MAKE) publish_software

publish_software:
	@test -f "$(SW_BIT)" || { \
		echo "ERROR: bitstream with MicroBlaze software was not generated:"; \
		echo "  $(SW_BIT)"; \
		exit 1; \
	}
	@test -f "$(SW_BIN)" || { \
		echo "ERROR: SPI flash image was not generated:"; \
		echo "  $(SW_BIN)"; \
		exit 1; \
	}
	@test -f "$(SW_PRM)" || { \
		echo "ERROR: configuration-memory report was not generated:"; \
		echo "  $(SW_PRM)"; \
		exit 1; \
	}
	@mkdir -p "$(BITSTREAM_DIR)"
	cp -f \
		"$(SW_BIT)" \
		"$(SW_BIN)" \
		"$(SW_PRM)" \
		"$(BITSTREAM_DIR)/"
	@echo
	@echo "Final firmware files generated:"
	@ls -lh \
		"$(BITSTREAM_DIR)/$(PROJECT_NAME)-$(SW_NAME).bit" \
		"$(BITSTREAM_DIR)/$(PROJECT_NAME)-$(SW_NAME).bin" \
		"$(BITSTREAM_DIR)/$(PROJECT_NAME)-$(SW_NAME).prm"

################################################################################
# Cleanup
################################################################################

# Remove build intermediates, but preserve the files under bitstream/.
clean:
	rm -rf "$(BUILD_DIR)"

# Remove build intermediates and published firmware files.
clean_all: clean
	rm -rf "$(BITSTREAM_DIR)"