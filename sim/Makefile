# Variables
UVM_HOME = $(VCS_HOME)/etc/uvm-1.2
WORK_DIR = $(shell pwd)
PROJ_ROOT = ..

# Source Files
RTL = $(PROJ_ROOT)/rtl/i2c_slave.sv $(PROJ_ROOT)/rtl/i2c_master.sv
PKG = $(PROJ_ROOT)/src/i2c_pkg.sv $(PROJ_ROOT)/src/i2c_test_pkg.sv
INTF = $(PROJ_ROOT)/src/i2c_if.sv
TOP = $(PROJ_ROOT)/sim/tb_top.sv

# Coverage Options (Code + Functional)
# -cm line+tgl+cond+fsm+branch: Code Coverage
# -cm_dir: Output directory
# -cm_hier: Coverage hierarchy config (optional, kept simple here)
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

# Run Sanity Test
run: comp
	$(SIM) +UVM_TESTNAME=i2c_sanity_test -l run.log

# Run Slave Test (Explicit Slave Mode)
run_slave: comp
	$(SIM) +UVM_TESTNAME=i2c_slave_test -l run_slave.log

# Run Random Mixed Traffic Test
run_random: comp
	$(SIM) +UVM_TESTNAME=i2c_random_test -l run_random.log

# Regression Target: Runs all tests and merges coverage
# Note: 'simv' handles merging into the same 'coverage.vdb' by default if run sequentially
regr: comp
	$(SIM) +UVM_TESTNAME=i2c_sanity_test   -l run_sanity.log   -cm_name sanity_test
	$(SIM) +UVM_TESTNAME=i2c_slave_test    -l run_slave.log    -cm_name slave_test
	$(SIM) +UVM_TESTNAME=i2c_burst_test    -l run_burst.log    -cm_name burst_test
	$(SIM) +UVM_TESTNAME=i2c_nack_test     -l run_nack.log     -cm_name nack_test
	$(SIM) +UVM_TESTNAME=i2c_10bit_test    -l run_10bit.log    -cm_name 10bit_test
	$(SIM) +UVM_TESTNAME=i2c_restart_test  -l run_restart.log  -cm_name restart_test
	$(SIM) +UVM_TESTNAME=i2c_gen_call_test -l run_gen_call.log -cm_name gen_call_test
	$(SIM) +UVM_TESTNAME=i2c_speed_test    -l run_speed.log    -cm_name speed_test
	$(SIM) +UVM_TESTNAME=i2c_random_test   -l run_random.log   -cm_name random_test
	$(SIM) +UVM_TESTNAME=i2c_slave_read_test -l run_slave_read.log -cm_name slave_read_test
	$(SIM) +UVM_TESTNAME=i2c_master_fsm_test -l run_master_fsm.log -cm_name master_fsm_test
	@echo "Regression Complete. Coverage data in coverage.vdb"

# Generate Coverage Report (URG)
cov_rpt:
	urg -dir coverage.vdb -report cov_report
	@echo "Coverage Report generated in cov_report/dashboard.html"

# View Coverage (Verdi)
view_cov:
	verdi -cov -covdir coverage.vdb

clean:
	rm -rf csrc simv* *.log *.fsdb ucli.key vc_hdrs.h coverage.vdb cov_report
