`ifndef I2C_SANITY_TEST_SV
`define I2C_SANITY_TEST_SV

class i2c_sanity_test extends i2c_test_base;
  `uvm_component_utils(i2c_sanity_test)

  function new(string name = "i2c_sanity_test", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  task run_phase(uvm_phase phase);
    i2c_master_write_seq seq;
    i2c_transaction      dummy_tr;
    
    phase.raise_objection(this);
    
    // ---------------------------------------------------------
    // PHASE 1: Master Mode (VIP acts as Master)
    // ---------------------------------------------------------
    `uvm_info("TEST", ">>> PHASE 1: VIP Master -> RTL Slave", UVM_LOW)
    seq = i2c_master_write_seq::type_id::create("seq");
    seq.start(env.agent.sequencer);
    
    #10us; // Small drain time
    
    // ---------------------------------------------------------
    // PHASE 2: Switch to Slave Mode
    // ---------------------------------------------------------
    `uvm_info("TEST", ">>> PHASE 2: Switching VIP to Slave Mode", UVM_LOW)
    
    // 1. Change Configuration
    cfg.is_master = 0;
    
    // 2. Unblock the Driver
    // Use the sequencer's execute_item() convenience method if available, 
    // BUT since we are in a test (which is a component), we CANNOT call start_item/finish_item 
    // because those are methods of uvm_sequence_base, not uvm_component/uvm_sequencer.
    //
    // The correct way to send a single item from a test without a sequence object is:
    // Create a generic sequence and start it, OR reuse the existing sequence object.
    
    seq.req = i2c_transaction::type_id::create("dummy_tr");
    seq.start_item(seq.req); // reusing the 'seq' object which is already a sequence
    if (!seq.req.randomize() with {
        addr == 0; 
        direction == I2C_READ;
        data.size() == 1;
    }) `uvm_error("TEST", "Randomization failed")
    seq.finish_item(seq.req);

    `uvm_info("TEST", ">>> VIP is now in Slave Mode (Waiting for RTL Master)", UVM_LOW)

    // ---------------------------------------------------------
    // PHASE 3: Slave Mode (VIP acts as Slave)
    // ---------------------------------------------------------
    
    wait (env.agent.vif.scl === 0); // Wait for some activity
    
    #100us; 
    
    `uvm_info("TEST", ">>> Sanity Test Complete", UVM_LOW)
    phase.drop_objection(this);
  endtask

endclass

`endif // I2C_SANITY_TEST_SV
