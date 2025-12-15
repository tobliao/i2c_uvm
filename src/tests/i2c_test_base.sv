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
    // Disable noisy reports
    uvm_top.print_topology();
    
    // Suppress "demoted/caught" summary
    // UVM doesn't have a simple switch for just that table, 
    // but we can use report_server to disable specific summary outputs
    // or just rely on simulator specific flags.
    // However, usually this is managed via the UVM report server.
    // For now, let's just keep topology print.
  endfunction
  
  function void report_phase(uvm_phase phase);
     uvm_report_server svr;
     super.report_phase(phase);
     
     svr = uvm_report_server::get_server();
     // svr.summarize(); // This is called by default by run_test()
     // To hide the "demoted/caught" counts, we have to override the report server or accept it.
     // Standard UVM always prints these if they are zero.
     // But we can check if there are errors and only print failure message.
     
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
