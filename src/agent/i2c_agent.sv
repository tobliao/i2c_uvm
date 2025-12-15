`ifndef I2C_AGENT_SV
`define I2C_AGENT_SV

// Forward declaration of components to resolve circular or ordering dependencies
typedef class i2c_driver;
typedef class i2c_monitor;
typedef class i2c_sequencer;

class i2c_agent extends uvm_agent;
  `uvm_component_utils(i2c_agent)

  i2c_driver    driver;
  i2c_monitor   monitor;
  i2c_sequencer sequencer;
  
  i2c_config    cfg;
  virtual i2c_if vif;

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    
    // Get Configuration
    if (!uvm_config_db#(i2c_config)::get(this, "", "cfg", cfg)) begin
      `uvm_info("AGENT", "Config not found in DB, creating default", UVM_LOW)
      cfg = i2c_config::type_id::create("cfg");
    end

    // Get Interface
    if (!uvm_config_db#(virtual i2c_if)::get(this, "", "vif", vif)) begin
      `uvm_fatal("AGENT", "Virtual interface 'vif' not found in config_db")
    end

    // Create Monitor (Always present)
    monitor = i2c_monitor::type_id::create("monitor", this);
    
    // Create Driver/Sequencer only if Active
    if (cfg.is_active == UVM_ACTIVE) begin
      driver    = i2c_driver::type_id::create("driver", this);
      sequencer = i2c_sequencer::type_id::create("sequencer", this);
    end
  endfunction

  function void connect_phase(uvm_phase phase);
    // Connect Monitor
    monitor.vif = vif;
    monitor.cfg = cfg;
    
    // Connect Driver
    if (cfg.is_active == UVM_ACTIVE) begin
      driver.seq_item_port.connect(sequencer.seq_item_export);
      driver.vif = vif;
      driver.cfg = cfg;
    end
  endfunction

endclass

`endif // I2C_AGENT_SV
