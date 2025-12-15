`ifndef I2C_SCOREBOARD_SV
`define I2C_SCOREBOARD_SV

class i2c_scoreboard extends uvm_scoreboard;
  `uvm_component_utils(i2c_scoreboard)

  // Analysis Port Import
  uvm_analysis_imp #(i2c_transaction, i2c_scoreboard) item_imp;

  function new(string name, uvm_component parent);
    super.new(name, parent);
    item_imp = new("item_imp", this);
  endfunction

  // Write function called by Monitor
  function void write(i2c_transaction tr);
    `uvm_info("SCB", $sformatf("Received transaction: %s", tr.convert2string()), UVM_LOW)
    // TODO: Add protocol checking / data integrity logic
  endfunction

endclass

`endif // I2C_SCOREBOARD_SV

