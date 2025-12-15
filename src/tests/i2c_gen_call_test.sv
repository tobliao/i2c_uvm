`ifndef I2C_GEN_CALL_TEST_SV
`define I2C_GEN_CALL_TEST_SV

class i2c_gen_call_test extends i2c_test_base;
  `uvm_component_utils(i2c_gen_call_test)

  function new(string name = "i2c_gen_call_test", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  task run_phase(uvm_phase phase);
    i2c_master_write_seq seq;
    phase.raise_objection(this);
    
    `uvm_info("TEST", "Starting General Call Test", UVM_LOW)
    
    seq = i2c_master_write_seq::type_id::create("seq");
    
    repeat(10) begin
      seq.req = i2c_transaction::type_id::create("req");
      seq.start_item(seq.req);
      if (!seq.req.randomize() with {
          addr == 0; // General Call Address
          direction == I2C_WRITE; // Must be Write
          data.size() inside {[1:8]};
      }) `uvm_error("TEST", "Randomization failed")
      seq.finish_item(seq.req);
    end
    
    #100us;
    phase.drop_objection(this);
  endtask

endclass

`endif // I2C_GEN_CALL_TEST_SV

