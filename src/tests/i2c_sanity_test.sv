`ifndef I2C_SANITY_TEST_SV
`define I2C_SANITY_TEST_SV

class i2c_sanity_test extends i2c_test_base;
  `uvm_component_utils(i2c_sanity_test)

  function new(string name = "i2c_sanity_test", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  task run_phase(uvm_phase phase);
    i2c_mixed_sequence seq;
    i2c_transaction      dummy_tr;
    
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
    
    // 1. Change Configuration
    cfg.is_master = 0;
    
    // 2. Unblock the Driver
    seq.req = i2c_transaction::type_id::create("dummy_tr");
    seq.start_item(seq.req);
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
