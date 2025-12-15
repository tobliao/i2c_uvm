`ifndef I2C_PKG_SV
`define I2C_PKG_SV

package i2c_pkg;
  import uvm_pkg::*;
  `include "uvm_macros.svh"

  // Common Types
  `include "common/i2c_types.sv"

  // Agent Objects
  `include "agent/i2c_config.sv"
  `include "agent/i2c_transaction.sv"
  
  // Components
  `include "agent/i2c_sequencer.sv"
  `include "agent/i2c_driver.sv"
  `include "agent/i2c_monitor.sv"
  `include "agent/i2c_agent.sv"
  
  // Environment
  `include "env/i2c_scoreboard.sv"
  `include "env/i2c_coverage.sv"
  `include "env/i2c_env.sv"
  
  // Sequences
  `include "seq/i2c_base_sequence.sv"
  
endpackage

`endif // I2C_PKG_SV

