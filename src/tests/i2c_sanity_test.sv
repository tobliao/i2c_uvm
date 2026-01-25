`ifndef I2C_SANITY_TEST_SV
`define I2C_SANITY_TEST_SV

class i2c_sanity_test extends i2c_test_base;
  `uvm_component_utils(i2c_sanity_test)

  function new(string name = "i2c_sanity_test", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  task run_phase(uvm_phase phase);
    i2c_mixed_sequence seq;
    bit timed_out;
    
    phase.raise_objection(this);
    
    // ---------------------------------------------------------
    // PHASE 1: Master Mode (VIP acts as Master)
    // ---------------------------------------------------------
    `uvm_info("TEST", $sformatf(">>> PHASE 1: VIP Master -> RTL Slave (addr=0x%0h)", cfg.slave_addr), UVM_LOW)
    
    seq = i2c_mixed_sequence::type_id::create("seq");
    seq.target_addr = cfg.slave_addr; // Use configured address
    if (!seq.randomize() with { num_transactions == 20; }) 
       `uvm_fatal("TEST", "Randomization failed")

    seq.start(env.agent.sequencer);
    
    #10us; // Small drain time
    
    // ---------------------------------------------------------
    // PHASE 2: Switch to Slave Mode
    // ---------------------------------------------------------
    `uvm_info("TEST", ">>> PHASE 2: Switching VIP to Slave Mode", UVM_LOW)
    
    // Ensure we commit switching at a protocol boundary (STOP + bus-free).
    // Reset BUS_IDLE so we wait for the post-sequence idle window.
    i2c_event_pool::reset_event(i2c_event_pool::BUS_IDLE);
    i2c_event_pool::wait_for_event_timeout(i2c_event_pool::BUS_IDLE, 200us, timed_out);
    if (timed_out) `uvm_warning("TEST", "BUS_IDLE not observed before role switch; switching anyway")

    // Change configuration and trigger ROLE_UPDATE to wake the driver if it is idle-polling.
    cfg.is_master = 0;
    i2c_event_pool::trigger_event(i2c_event_pool::ROLE_UPDATE);

    `uvm_info("TEST", ">>> VIP is now in Slave Mode (Waiting for RTL Master)", UVM_LOW)

    // ---------------------------------------------------------
    // PHASE 3: Slave Mode (VIP acts as Slave)
    // ---------------------------------------------------------
    
    fork
        begin
            repeat(100) begin
                wait (env.agent.vif.scl === 0);
                wait (env.agent.vif.scl === 1);
            end
             
            `uvm_info("TEST", ">>> Activity Detected (Saw 100 SCL Toggles)", UVM_LOW)
            #200ms; 
        end
        begin
            #2000ms; 
            `uvm_fatal("TEST", "Timeout waiting for RTL Master activity")
        end
    join_any
    disable fork;
    
    `uvm_info("TEST", ">>> Sanity Test Complete", UVM_LOW)
    phase.drop_objection(this);
  endtask

endclass

`endif // I2C_SANITY_TEST_SV
