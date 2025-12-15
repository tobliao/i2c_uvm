`ifndef I2C_TEST_BASE_SV
`define I2C_TEST_BASE_SV

class i2c_test_base extends uvm_test;
  `uvm_component_utils(i2c_test_base)

  i2c_env env;
  i2c_config cfg;

  function new(string name = "i2c_test_base", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    env = i2c_env::type_id::create("env", this);
    
    // Configure the environment
    cfg = i2c_config::type_id::create("cfg");
    cfg.is_master = 1;
    cfg.is_active = UVM_ACTIVE;
    cfg.speed = I2C_STANDARD_MODE;
    cfg.set_default_timings();
    
    // Set config for the agent
    uvm_config_db#(i2c_config)::set(this, "env.agent", "cfg", cfg);
  endfunction

  function void end_of_elaboration_phase(uvm_phase phase);
    uvm_top.print_topology();
  endfunction

endclass

`endif // I2C_TEST_BASE_SV
