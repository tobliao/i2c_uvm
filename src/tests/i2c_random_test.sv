`ifndef I2C_RANDOM_TEST_SV
`define I2C_RANDOM_TEST_SV

class i2c_random_test extends i2c_test_base;
  `uvm_component_utils(i2c_random_test)

  function new(string name = "i2c_random_test", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  task run_phase(uvm_phase phase);
    i2c_mixed_sequence seq;
    
    phase.raise_objection(this);
    
    `uvm_info("TEST", ">>> Starting Random Mixed Traffic Test", UVM_LOW)
    
    seq = i2c_mixed_sequence::type_id::create("seq");
    
    // Randomize sequence parameters if needed
    if (!seq.randomize() with { num_transactions == 100; }) 
       `uvm_error("TEST", "Sequence randomization failed")
    
    seq.start(env.agent.sequencer);
    
    #100us; // Drain time
    
    `uvm_info("TEST", ">>> Random Test Complete", UVM_LOW)
    phase.drop_objection(this);
  endtask

endclass

`endif // I2C_RANDOM_TEST_SV
