`ifndef I2C_VIRTUAL_SEQUENCER_SV
`define I2C_VIRTUAL_SEQUENCER_SV

//==============================================================================
// I2C Virtual Sequencer
//
// Provides coordination for complex multi-agent scenarios.
// Supports synchronization barriers and event-driven sequencing.
//==============================================================================

class i2c_virtual_sequencer extends uvm_sequencer;
  `uvm_component_utils(i2c_virtual_sequencer)
  
  //----------------------------------------------------------------------------
  // Sub-Sequencer Handles
  //----------------------------------------------------------------------------
  i2c_sequencer master_sqr;  // Master sequencer handle
  i2c_sequencer slave_sqr;   // Slave sequencer handle (for dual-agent env)
  
  //----------------------------------------------------------------------------
  // Synchronization Barriers
  //----------------------------------------------------------------------------
  uvm_barrier phase_barrier;
  uvm_barrier_pool barrier_pool;
  
  //----------------------------------------------------------------------------
  // Event Pool Reference
  //----------------------------------------------------------------------------
  uvm_event_pool event_pool;
  
  //----------------------------------------------------------------------------
  // Configuration
  //----------------------------------------------------------------------------
  i2c_config cfg;
  
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
    
    // Get configuration
    if (!uvm_config_db#(i2c_config)::get(this, "", "cfg", cfg)) begin
      cfg = i2c_config::type_id::create("cfg");
    end
    
    // Create barrier pool
    barrier_pool = new("barrier_pool");
    
    // Create phase barrier (for sequence synchronization)
    phase_barrier = new("phase_barrier", 2); // Default 2 agents
    
    // Get global event pool
    event_pool = i2c_event_pool::get_global_pool();
    
    `uvm_info("VSEQR", "Virtual sequencer built", UVM_MEDIUM)
  endfunction
  
  //----------------------------------------------------------------------------
  // Get Barrier by Name
  //----------------------------------------------------------------------------
  function uvm_barrier get_barrier(string name);
    return barrier_pool.get(name);
  endfunction
  
  //----------------------------------------------------------------------------
  // Wait for Event (convenience wrapper)
  //----------------------------------------------------------------------------
  task wait_for_event(string event_name);
    uvm_event ev = event_pool.get(event_name);
    ev.wait_trigger();
  endtask
  
  //----------------------------------------------------------------------------
  // Trigger Event (convenience wrapper)
  //----------------------------------------------------------------------------
  function void trigger_event(string event_name, uvm_object data = null);
    uvm_event ev = event_pool.get(event_name);
    ev.trigger(data);
  endfunction

endclass

`endif // I2C_VIRTUAL_SEQUENCER_SV
