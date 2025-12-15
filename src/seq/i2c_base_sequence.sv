`ifndef I2C_BASE_SEQUENCE_SV
`define I2C_BASE_SEQUENCE_SV

class i2c_base_sequence extends uvm_sequence #(i2c_transaction);
  `uvm_object_utils(i2c_base_sequence)

  function new(string name = "i2c_base_sequence");
    super.new(name);
  endfunction

  task body();
    `uvm_info("SEQ", "Executing Base Sequence", UVM_HIGH)
  endtask

endclass

// Example: Simple Master Write Sequence
class i2c_master_write_seq extends i2c_base_sequence;
  `uvm_object_utils(i2c_master_write_seq)
  
  function new(string name = "i2c_master_write_seq");
    super.new(name);
  endfunction

  task body();
    req = i2c_transaction::type_id::create("req");
    
    start_item(req);
    if (!req.randomize() with {
      direction == I2C_WRITE;
      addr_mode == I2C_ADDR_7BIT;
    }) begin
      `uvm_fatal("SEQ", "Randomization failed")
    end
    finish_item(req);
    
    `uvm_info("SEQ", $sformatf("Finished Write Sequence: %s", req.convert2string()), UVM_LOW)
  endtask
endclass

`endif // I2C_BASE_SEQUENCE_SV

