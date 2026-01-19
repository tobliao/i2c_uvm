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
    bit [6:0] slave_addr;
    
    super.build_phase(phase);
    env = i2c_env::type_id::create("env", this);
    
    // Configure the environment
    cfg = i2c_config::type_id::create("cfg");
    cfg.is_master = 1;
    cfg.is_active = UVM_ACTIVE;
    cfg.speed = I2C_STANDARD_MODE;
    cfg.set_default_timings();
    
    // Get slave address from testbench (single source of truth)
    if (uvm_config_db#(bit[6:0])::get(null, "*", "slave_addr", slave_addr)) begin
      cfg.slave_addr = slave_addr;
      `uvm_info("TEST_BASE", $sformatf("Got slave_addr from config_db: 0x%0h", slave_addr), UVM_LOW)
    end else begin
      `uvm_info("TEST_BASE", $sformatf("Using default slave_addr: 0x%0h", cfg.slave_addr), UVM_LOW)
    end
    
    // Set config for the agent
    uvm_config_db#(i2c_config)::set(this, "env.agent", "cfg", cfg);
  endfunction

  function void end_of_elaboration_phase(uvm_phase phase);
    uvm_top.print_topology();
  endfunction
  
  function void report_phase(uvm_phase phase);
     uvm_report_server svr;
     super.report_phase(phase);
     
     svr = uvm_report_server::get_server();
     
     if (svr.get_severity_count(UVM_FATAL) + svr.get_severity_count(UVM_ERROR) == 0) begin
        $display("\n========================================================");
        $display("    TEST STATUS: PASSED");
        $display("========================================================\n");
     end else begin
        $display("\n========================================================");
        $display("    TEST STATUS: FAILED");
        $display("========================================================\n");
     end
  endfunction

endclass

`endif // I2C_TEST_BASE_SV
