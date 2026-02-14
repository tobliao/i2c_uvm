`ifndef I2C_BASE_SEQUENCE_SV
`define I2C_BASE_SEQUENCE_SV

class i2c_base_sequence extends uvm_sequence #(i2c_transaction);
  `uvm_object_utils(i2c_base_sequence)
  
  // Target slave address - configurable by test
  bit [6:0] target_addr = 7'h55;

  function new(string name = "i2c_base_sequence");
    super.new(name);
  endfunction

  task body();
    `uvm_info("SEQ", "Executing Base Sequence", UVM_HIGH)
  endtask

endclass

//------------------------------------------------------------------------------
// Single Transaction Sequence - Flexible wrapper for any transaction
//------------------------------------------------------------------------------
class i2c_single_transaction_seq extends i2c_base_sequence;
  `uvm_object_utils(i2c_single_transaction_seq)
  
  rand i2c_direction_e direction;
  rand i2c_addr_mode_e addr_mode;
  rand bit [9:0] addr;
  rand bit [7:0] data[];
  rand bit repeated_start;
  
  constraint c_default {
    addr_mode == I2C_ADDR_7BIT;
    data.size() inside {[1:8]};
    repeated_start == 0;
  }

  function new(string name = "i2c_single_transaction_seq");
    super.new(name);
    direction = I2C_WRITE;
    addr = 7'h55;
    data = new[1];
  endfunction

  task body();
    req = i2c_transaction::type_id::create("req");
    
    start_item(req);
    req.direction = direction;
    req.addr_mode = addr_mode;
    req.addr = addr;
    req.data = data; // Deep copy of dynamic array
    req.repeated_start = repeated_start;
    finish_item(req);
    
    `uvm_info("SEQ", $sformatf("Finished Single Transaction: %s", req.convert2string()), UVM_LOW)
  endtask
endclass

//------------------------------------------------------------------------------
// Write Sequence - sends specific data to slave
//------------------------------------------------------------------------------
class i2c_write_sequence extends i2c_base_sequence;
  `uvm_object_utils(i2c_write_sequence)
  
  // Data to write
  bit [7:0] data[$];
  
  function new(string name = "i2c_write_sequence");
    super.new(name);
  endfunction

  task body();
    req = i2c_transaction::type_id::create("req");
    
    start_item(req);
    req.direction = I2C_WRITE;
    req.addr_mode = I2C_ADDR_7BIT;
    req.addr = target_addr;
    req.data = data;
    if (data.size() == 0) begin
      // Generate random data if none provided
      req.data = new[4];
      foreach(req.data[i]) req.data[i] = $urandom_range(0, 255);
    end
    finish_item(req);
    
    `uvm_info("SEQ", $sformatf("Write Sequence done: %s", req.convert2string()), UVM_LOW)
  endtask
endclass

//------------------------------------------------------------------------------
// Read Sequence - reads specified number of bytes from slave
//------------------------------------------------------------------------------
class i2c_read_sequence extends i2c_base_sequence;
  `uvm_object_utils(i2c_read_sequence)
  
  // Number of bytes to read
  int num_bytes = 1;
  
  function new(string name = "i2c_read_sequence");
    super.new(name);
  endfunction

  task body();
    req = i2c_transaction::type_id::create("req");
    
    start_item(req);
    req.direction = I2C_READ;
    req.addr_mode = I2C_ADDR_7BIT;
    req.addr = target_addr;
    req.data = new[num_bytes];
    finish_item(req);
    
    `uvm_info("SEQ", $sformatf("Read Sequence done: %s", req.convert2string()), UVM_LOW)
  endtask
endclass

//------------------------------------------------------------------------------
// Master Write Sequence (legacy name)
//------------------------------------------------------------------------------
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
      addr == local::target_addr;
    }) begin
      `uvm_fatal("SEQ", "Randomization failed")
    end
    finish_item(req);
    
    `uvm_info("SEQ", $sformatf("Finished Write Sequence: %s", req.convert2string()), UVM_LOW)
  endtask
endclass

//------------------------------------------------------------------------------
// Master Read Sequence (legacy name)
//------------------------------------------------------------------------------
class i2c_master_read_seq extends i2c_base_sequence;
  `uvm_object_utils(i2c_master_read_seq)
  
  function new(string name = "i2c_master_read_seq");
    super.new(name);
  endfunction

  task body();
    req = i2c_transaction::type_id::create("req");
    
    start_item(req);
    if (!req.randomize() with {
      direction == I2C_READ;
      addr_mode == I2C_ADDR_7BIT;
      addr == local::target_addr;
      data.size() inside {[1:8]};
    }) begin
      `uvm_fatal("SEQ", "Randomization failed")
    end
    finish_item(req);
    
    `uvm_info("SEQ", $sformatf("Finished Read Sequence: %s", req.convert2string()), UVM_LOW)
  endtask
endclass

`endif // I2C_BASE_SEQUENCE_SV
