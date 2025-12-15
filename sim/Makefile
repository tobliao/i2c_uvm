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
# REMOVED -ntb_opts uvm-1.2 because it can cause conflicts with explicit imports if not handled carefully regarding timescale.
# Added explicit -timescale=1ns/1ps to force a global default if files are missing it (safety net),
# although we fixed the files.
# The real issue is likely that 'ntb_opts uvm-1.2' compiles the UVM library *before* our files.
# If the UVM library (pre-compiled or included via that flag) doesn't have a timescale matching ours,
# or if it sets a precedent that we violate, it errors.
# However, usually UVM has a timescale.
# The error "Package i2c_test_pkg has `timescale but previous module(s)/package(s) do not"
# strongly suggests that WHATEVER was compiled immediately before i2c_test_pkg did NOT have a timescale.
# In the line: $(VCS) $(PKG) ...
# PKG expands to: src/i2c_pkg.sv src/i2c_test_pkg.sv
# So i2c_pkg.sv is compiled first. Does it have a timescale? YES.
# But wait, the error says "previous module(s)/package(s) do not".
# If i2c_pkg.sv has it, then i2c_test_pkg.sv should be fine.
# UNLESS 'uvm_pkg' is considered the "previous" one and IT doesn't have one (unlikely) 
# OR there is something else.

# Let's try reordering: Interface first, then Packages, then RTL. 
# Interfaces are often needed by packages if packages import them, but here packages just use classes.
# Actually, the error is likely due to the UVM library itself being compiled implicitly without a matching timescale context.
# We will use -timescale=1ns/1ps to force the default for any unit that doesn't have one.

VCS = vcs -full64 -sverilog -ntb_opts uvm-1.2 \
      -timescale=1ns/1ps \
      -debug_access+all -kdb -lcomp.log \
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
