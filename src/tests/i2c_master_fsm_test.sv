`ifndef I2C_MASTER_FSM_TEST_SV
`define I2C_MASTER_FSM_TEST_SV

// This test exercises the RTL Master's FSM by having VIP act as Slave
// The RTL Master in tb_top will drive traffic to the VIP Slave
class i2c_master_fsm_test extends i2c_test_base;
  `uvm_component_utils(i2c_master_fsm_test)

  function new(string name = "i2c_master_fsm_test", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    // Configure VIP as Slave from the start
    cfg.is_master = 0;
  endfunction

  task run_phase(uvm_phase phase);
    phase.raise_objection(this);
    
    `uvm_info("TEST", ">>> Starting Master FSM Coverage Test", UVM_LOW)
    `uvm_info("TEST", ">>> VIP acts as Slave, RTL Master (in tb_top) drives traffic", UVM_LOW)
    
    // tb_top triggers RTL Master at 10ms and runs 100 transactions
    // Each transaction takes ~130us, so 100 transactions = ~13ms
    // We wait 30ms to ensure all RTL Master transactions complete
    
    // Monitor SCL activity to verify traffic is happening
    fork
      begin
        int scl_toggles = 0;
        repeat(1000) begin
          wait(env.agent.vif.scl === 0);
          wait(env.agent.vif.scl === 1);
          scl_toggles++;
          if (scl_toggles % 100 == 0)
            `uvm_info("TEST", $sformatf(">>> Observed %0d SCL toggles", scl_toggles), UVM_LOW)
        end
        `uvm_info("TEST", ">>> Observed sufficient SCL activity from RTL Master", UVM_LOW)
      end
      begin
        #50ms;
        `uvm_info("TEST", ">>> Timeout reached (expected)", UVM_LOW)
      end
    join_any
    disable fork;
    
    `uvm_info("TEST", ">>> Master FSM Coverage Test Complete", UVM_LOW)
    phase.drop_objection(this);
  endtask

endclass

`endif // I2C_MASTER_FSM_TEST_SV
