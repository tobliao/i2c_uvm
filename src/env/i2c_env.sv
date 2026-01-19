`ifndef I2C_ENV_SV
`define I2C_ENV_SV

//==============================================================================
// I2C Environment
//
// Professional UVM environment with:
// - uvm_event_pool integration for synchronization
// - uvm_barrier for phase coordination
// - Virtual sequencer for complex scenarios
// - Statistics and reporting
//==============================================================================

class i2c_env extends uvm_env;
  `uvm_component_utils(i2c_env)
  
  //----------------------------------------------------------------------------
  // Components
  //----------------------------------------------------------------------------
  i2c_agent             agent;
  i2c_scoreboard        scoreboard;
  i2c_coverage          coverage;
  i2c_virtual_sequencer virtual_sqr;
  
  //----------------------------------------------------------------------------
  // Configuration
  //----------------------------------------------------------------------------
  i2c_config cfg;
  
  //----------------------------------------------------------------------------
  // Synchronization
  //----------------------------------------------------------------------------
  uvm_event_pool   event_pool;
  uvm_barrier_pool barrier_pool;
  
  //----------------------------------------------------------------------------
  // Statistics
  //----------------------------------------------------------------------------
  time test_start_time;
  time test_end_time;
  
  //----------------------------------------------------------------------------
  // Constructor
  //----------------------------------------------------------------------------
  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction
  
  //----------------------------------------------------------------------------
  // Build Phase
  //----------------------------------------------------------------------------
  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    
    // Get/Create Configuration
    if (!uvm_config_db#(i2c_config)::get(this, "", "cfg", cfg)) begin
      cfg = i2c_config::type_id::create("cfg");
    end
    
    // Propagate config to children
    uvm_config_db#(i2c_config)::set(this, "*", "cfg", cfg);
    
    // Create Components
    agent       = i2c_agent::type_id::create("agent", this);
    scoreboard  = i2c_scoreboard::type_id::create("scoreboard", this);
    coverage    = i2c_coverage::type_id::create("coverage", this);
    virtual_sqr = i2c_virtual_sequencer::type_id::create("virtual_sqr", this);
    
    // Initialize Event Pool (global singleton)
    event_pool = i2c_event_pool::get_global_pool();
    
    // Create Barrier Pool
    barrier_pool = new("barrier_pool");
    
    `uvm_info("ENV", "Environment built", UVM_LOW)
  endfunction
  
  //----------------------------------------------------------------------------
  // Connect Phase
  //----------------------------------------------------------------------------
  function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
    
    // Connect Monitor to Scoreboard and Coverage
    agent.monitor.ap.connect(scoreboard.item_imp);
    agent.monitor.ap.connect(coverage.analysis_export);
    
    // Connect Virtual Sequencer
    virtual_sqr.master_sqr = agent.sequencer;
    
    `uvm_info("ENV", "Components connected", UVM_MEDIUM)
  endfunction
  
  //----------------------------------------------------------------------------
  // Run Phase
  //----------------------------------------------------------------------------
  task run_phase(uvm_phase phase);
    test_start_time = $time;
    `uvm_info("ENV", $sformatf("Run phase started at %0t", test_start_time), UVM_LOW)
  endtask
  
  //----------------------------------------------------------------------------
  // Extract Phase
  //----------------------------------------------------------------------------
  function void extract_phase(uvm_phase phase);
    super.extract_phase(phase);
    test_end_time = $time;
  endfunction
  
  //----------------------------------------------------------------------------
  // Report Phase
  //----------------------------------------------------------------------------
  function void report_phase(uvm_phase phase);
    real duration_ms;
    super.report_phase(phase);
    
    duration_ms = (test_end_time - test_start_time) / 1_000_000.0;
    
    `uvm_info("ENV", "╔════════════════════════════════════╗", UVM_NONE)
    `uvm_info("ENV", "║    ENVIRONMENT SUMMARY             ║", UVM_NONE)
    `uvm_info("ENV", "╠════════════════════════════════════╣", UVM_NONE)
    `uvm_info("ENV", $sformatf("║ Duration:    %8.3f ms          ║", duration_ms), UVM_NONE)
    `uvm_info("ENV", $sformatf("║ Transactions: %7d            ║", scoreboard.total_received), UVM_NONE)
    `uvm_info("ENV", "╚════════════════════════════════════╝", UVM_NONE)
  endfunction
  
  //----------------------------------------------------------------------------
  // Utility: Trigger Global Event
  //----------------------------------------------------------------------------
  function void trigger_event(string name, uvm_object data = null);
    i2c_event_pool::trigger_event(name, data);
  endfunction
  
  //----------------------------------------------------------------------------
  // Utility: Wait for Global Event
  //----------------------------------------------------------------------------
  task wait_for_event(string name);
    uvm_object data;
    i2c_event_pool::wait_for_event(name, data);
  endtask
  
  //----------------------------------------------------------------------------
  // Utility: Get/Create Barrier
  //----------------------------------------------------------------------------
  function uvm_barrier get_barrier(string name, int threshold = 2);
    uvm_barrier b = barrier_pool.get(name);
    b.set_threshold(threshold);
    return b;
  endfunction

endclass

`endif // I2C_ENV_SV
