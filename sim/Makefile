# Variables
UVM_HOME = $(VCS_HOME)/etc/uvm-1.2
WORK_DIR = $(shell pwd)
PROJ_ROOT = ..

# Source Files
RTL = $(PROJ_ROOT)/rtl/i2c_slave.sv $(PROJ_ROOT)/rtl/i2c_master.sv
PKG = $(PROJ_ROOT)/src/i2c_pkg.sv $(PROJ_ROOT)/src/i2c_test_pkg.sv
INTF = $(PROJ_ROOT)/src/i2c_if.sv
TOP = $(PROJ_ROOT)/sim/tb_top.sv

# Coverage Options
COV_OPTS = -cm line+tgl+cond+fsm+branch -cm_dir coverage.vdb

# Tools
VCS = vcs -full64 -sverilog -ntb_opts uvm-1.2 \
      -timescale=1ns/1ps \
      -debug_access+all -kdb -l comp.log \
      +incdir+$(PROJ_ROOT)/src \
      $(COV_OPTS)

SIM = ./simv $(COV_OPTS)

# Targets
all: clean comp run

comp:
	$(VCS) $(PKG) $(INTF) $(RTL) $(TOP)

run: comp
	$(SIM) +UVM_TESTNAME=i2c_sanity_test -l run.log

run_slave: comp
	$(SIM) +UVM_TESTNAME=i2c_slave_test -l run_slave.log

clean:
	rm -rf csrc simv* *.log *.fsdb ucli.key vc_hdrs.h coverage.vdb
