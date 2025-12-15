`ifndef I2C_RESTART_TEST_SV
`define I2C_RESTART_TEST_SV

class i2c_restart_test extends i2c_test_base;
  `uvm_component_utils(i2c_restart_test)

  function new(string name = "i2c_restart_test", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  task run_phase(uvm_phase phase);
    i2c_master_write_seq seq;
    phase.raise_objection(this);
    
    `uvm_info("TEST", "Starting Repeated Start Test", UVM_LOW)
    
    seq = i2c_master_write_seq::type_id::create("seq");
    
    repeat(10) begin
      // Transaction 1: Write with Repeated Start
      seq.req = i2c_transaction::type_id::create("req");
      seq.start_item(seq.req);
      if (!seq.req.randomize() with {
          direction == I2C_WRITE;
          repeated_start == 1; // Force Restart
          data.size() == 1;
      }) `uvm_error("TEST", "Randomization failed")
      seq.finish_item(seq.req);
      
      // Transaction 2: Read (follows immediately)
      seq.req = i2c_transaction::type_id::create("req");
      seq.start_item(seq.req);
      if (!seq.req.randomize() with {
          direction == I2C_READ;
          repeated_start == 0; // Stop at end
          data.size() == 1;
      }) `uvm_error("TEST", "Randomization failed")
      seq.finish_item(seq.req);
    end
    
    #100us;
    phase.drop_objection(this);
  endtask

endclass

`endif // I2C_RESTART_TEST_SV

