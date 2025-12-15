`ifndef I2C_ENV_SV
`define I2C_ENV_SV

class i2c_env extends uvm_env;
  `uvm_component_utils(i2c_env)

  i2c_agent      agent;
  i2c_scoreboard scoreboard;
  i2c_coverage   coverage;

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    
    // Create Components
    agent      = i2c_agent::type_id::create("agent", this);
    scoreboard = i2c_scoreboard::type_id::create("scoreboard", this);
    coverage   = i2c_coverage::type_id::create("coverage", this);
  endfunction

  function void connect_phase(uvm_phase phase);
    // Connect Monitor to Scoreboard and Coverage
    agent.monitor.ap.connect(scoreboard.item_imp);
    agent.monitor.ap.connect(coverage.analysis_export);
  endfunction

endclass

`endif // I2C_ENV_SV
