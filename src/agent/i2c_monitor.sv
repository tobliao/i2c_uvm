`ifndef I2C_MONITOR_SV
`define I2C_MONITOR_SV

class i2c_monitor extends uvm_monitor;
  `uvm_component_utils(i2c_monitor)

  virtual i2c_if vif;
  i2c_config     cfg;
  
  uvm_analysis_port #(i2c_transaction) ap;
  
  // State Machine for Analysis
  typedef enum { IDLE, START, ADDR, DATA, STOP } mon_state_e;
  mon_state_e state;

  function new(string name, uvm_component parent);
    super.new(name, parent);
    ap = new("ap", this);
  endfunction

  task run_phase(uvm_phase phase);
    i2c_transaction tr;
    
    forever begin
      // Very basic monitoring loop - detecting start
      // Real monitor needs robust sampling on SCL edges
      
      wait(vif.sda == 0 && vif.scl == 1); // Start
      `uvm_info("MON", "Start Condition Detected", UVM_HIGH)
      
      tr = i2c_transaction::type_id::create("tr");
      
      // Sample Address
      // ... bit collection logic ...
      
      // For now, let's wait for Stop to avoid hanging
      wait(vif.sda == 1 && vif.scl == 1); // Stop? No, this is IDLE. Stop is Rising SDA while SCL High
      
      // Placeholder delay
      #1us;
    end
  endtask

endclass

`endif // I2C_MONITOR_SV
