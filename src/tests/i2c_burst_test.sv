`ifndef I2C_BURST_TEST_SV
`define I2C_BURST_TEST_SV

class i2c_burst_test extends i2c_test_base;
  `uvm_component_utils(i2c_burst_test)

  function new(string name = "i2c_burst_test", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  task run_phase(uvm_phase phase);
    i2c_single_transaction_seq seq;
    phase.raise_objection(this);
    
    `uvm_info("TEST", "Starting Burst Test", UVM_LOW)
    
    // Run multiple burst transactions with varying sizes
    repeat(20) begin
      seq = i2c_single_transaction_seq::type_id::create("seq");
      if (!seq.randomize() with {
          direction == I2C_WRITE;
          data.size() inside {[16:64]}; // Burst sizes
      }) `uvm_error("TEST", "Randomization failed")
      seq.start(env.agent.sequencer);
    end
    
    #100us;
    phase.drop_objection(this);
  endtask

endclass

`endif // I2C_BURST_TEST_SV

