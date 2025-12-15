`ifndef I2C_NACK_TEST_SV
`define I2C_NACK_TEST_SV

class i2c_nack_test extends i2c_test_base;
  `uvm_component_utils(i2c_nack_test)

  function new(string name = "i2c_nack_test", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  task run_phase(uvm_phase phase);
    i2c_master_write_seq seq;
    phase.raise_objection(this);
    
    `uvm_info("TEST", "Starting Address NACK Test", UVM_LOW)
    
    seq = i2c_master_write_seq::type_id::create("seq");
    
    // Target an address that the Slave DOES NOT respond to (e.g., 0x10)
    // Slave is at 0x55.
    repeat(10) begin
      seq.req = i2c_transaction::type_id::create("req");
      seq.start_item(seq.req);
      if (!seq.req.randomize() with {
          addr != 7'h55; // Force non-matching address
          data.size() == 1;
      }) `uvm_error("TEST", "Randomization failed")
      seq.finish_item(seq.req);
    end
    
    #100us;
    phase.drop_objection(this);
  endtask

endclass

`endif // I2C_NACK_TEST_SV

