`ifndef I2C_SPEED_TEST_SV
`define I2C_SPEED_TEST_SV

class i2c_speed_test extends i2c_test_base;
  `uvm_component_utils(i2c_speed_test)

  function new(string name = "i2c_speed_test", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    // Override speed to Fast Mode (400kHz)
    cfg.speed = I2C_FAST_MODE;
    cfg.set_default_timings(); 
  endfunction

  task run_phase(uvm_phase phase);
    i2c_master_write_seq seq;
    phase.raise_objection(this);
    
    `uvm_info("TEST", "Starting Speed Config Test (Fast Mode)", UVM_LOW)
    
    repeat(10) begin
      seq = i2c_master_write_seq::type_id::create("seq");
      seq.target_addr = cfg.slave_addr;
      seq.start(env.agent.sequencer);
    end
    
    #100us;
    phase.drop_objection(this);
  endtask

endclass

`endif // I2C_SPEED_TEST_SV




