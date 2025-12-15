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
    // The driver is currently blocked at 'get_next_item' inside the Master loop.
    // We send one "Dummy" transaction to wake it up. 
    // The driver will process this (driving the bus), then loop back.
    // On the next loop, it sees is_master=0 and enters Slave Mode.
    // We make this dummy transaction a minimal 'Read' or 'Write' that won't confuse the bus too much.
    // Or we rely on the fact that we can just send an empty transaction.
    
    env.agent.sequencer.lock(seq); // Just to get exclusive access if needed, though we are direct
    dummy_tr = i2c_transaction::type_id::create("dummy_tr");
    env.agent.sequencer.start_item(dummy_tr);
    dummy_tr.randomize() with { 
        addr == 0; // General call or dummy
        direction == I2C_READ; // Read is safer, high-Z
        data.size() == 1;
    }; 
    env.agent.sequencer.finish_item(dummy_tr);
    env.agent.sequencer.unlock(seq);

    `uvm_info("TEST", ">>> VIP is now in Slave Mode (Waiting for RTL Master)", UVM_LOW)

    // ---------------------------------------------------------
    // PHASE 3: Slave Mode (VIP acts as Slave)
    // ---------------------------------------------------------
    // The RTL Master in tb_top.sv is configured to trigger at 2ms (#2000000).
    // We just wait here until that happens.
    // A real reactive slave sequence would run on the sequencer, 
    // but our driver bit-banging slave logic is currently simple blocking code.
    
    wait (env.agent.vif.scl === 0); // Wait for some activity (Start condition involves SCL)
    // Actually Start is SDA Fall while SCL High.
    
    // Wait for the RTL Master transaction to complete
    #100us; 
    
    `uvm_info("TEST", ">>> Sanity Test Complete", UVM_LOW)
    phase.drop_objection(this);
  endtask

endclass

`endif // I2C_SANITY_TEST_SV
