`ifndef I2C_SLAVE_READ_TEST_SV
`define I2C_SLAVE_READ_TEST_SV

// This test exercises the RTL Slave's Read path (DATA_TX)
// VIP acts as Master and sends READ transactions to the RTL Slave
class i2c_slave_read_test extends i2c_test_base;
  `uvm_component_utils(i2c_slave_read_test)

  function new(string name = "i2c_slave_read_test", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  task run_phase(uvm_phase phase);
    i2c_master_read_seq read_seq;
    i2c_master_write_seq write_seq;
    
    phase.raise_objection(this);
    
    `uvm_info("TEST", ">>> Starting Slave Read Coverage Test", UVM_LOW)
    `uvm_info("TEST", $sformatf(">>> Target Slave Address: 0x%0h", cfg.slave_addr), UVM_LOW)

    // ---------------------------------------------------------
    // VIP Master Mode: Send Write transactions first to populate
    // the Slave's memory (so Reads return meaningful data)
    // ---------------------------------------------------------
    `uvm_info("TEST", ">>> Phase 1: Writing data to RTL Slave memory", UVM_LOW)
    repeat(10) begin
      write_seq = i2c_master_write_seq::type_id::create("write_seq");
      write_seq.target_addr = cfg.slave_addr; // Use configured address
      write_seq.start(env.agent.sequencer);
    end
    
    #10us;
    
    // ---------------------------------------------------------
    // VIP Master Mode: Send Read transactions to exercise
    // the RTL Slave's DATA_TX and ACK_DATA_TX states
    // ---------------------------------------------------------
    `uvm_info("TEST", ">>> Phase 2: Reading data from RTL Slave (exercises DATA_TX)", UVM_LOW)
    repeat(20) begin
      read_seq = i2c_master_read_seq::type_id::create("read_seq");
      read_seq.target_addr = cfg.slave_addr; // Use configured address
      read_seq.start(env.agent.sequencer);
    end
    
    #10us;
    
    `uvm_info("TEST", ">>> Slave Read Coverage Test Complete", UVM_LOW)
    phase.drop_objection(this);
  endtask

endclass

`endif // I2C_SLAVE_READ_TEST_SV
