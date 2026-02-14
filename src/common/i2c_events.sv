`ifndef I2C_EVENTS_SV
`define I2C_EVENTS_SV

//==============================================================================
// I2C Event Definitions
// 
// Uses uvm_event_pool for global event synchronization across components.
// Events enable loose coupling between testbench components.
//==============================================================================

class i2c_event_pool extends uvm_object;
  `uvm_object_utils(i2c_event_pool)
  
  // Global Event Pool (singleton pattern)
  static uvm_event_pool global_pool;
  
  // Event Names (constants for consistency)
  static string RESET_DONE       = "reset_done";
  static string START_DETECTED   = "start_detected";
  static string STOP_DETECTED    = "stop_detected";
  static string ADDR_PHASE_DONE  = "addr_phase_done";
  static string DATA_PHASE_DONE  = "data_phase_done";
  static string TRANS_COMPLETE   = "trans_complete";
  static string NACK_RECEIVED    = "nack_received";
  static string ARB_LOST         = "arb_lost";
  static string BUS_IDLE         = "bus_idle";
  static string ROLE_UPDATE      = "role_update";   // Config/role change request (wake-up hint)
  static string ROLE_COMMITTED   = "role_committed"; // Role change committed (optional)
  static string ERROR_DETECTED   = "error_detected";
  
  function new(string name = "i2c_event_pool");
    super.new(name);
  endfunction
  
  //----------------------------------------------------------------------------
  // Get Global Pool (Singleton)
  //----------------------------------------------------------------------------
  static function uvm_event_pool get_global_pool();
    if (global_pool == null) begin
      global_pool = new("i2c_global_event_pool");
      `uvm_info("I2C_EVENT_POOL", "Created global event pool", UVM_LOW)
    end
    return global_pool;
  endfunction
  
  //----------------------------------------------------------------------------
  // Get Event by Name (creates if doesn't exist)
  //----------------------------------------------------------------------------
  static function uvm_event get_event(string name);
    uvm_event_pool pool = get_global_pool();
    return pool.get(name);
  endfunction
  
  //----------------------------------------------------------------------------
  // Trigger Event with Optional Data
  //----------------------------------------------------------------------------
  static function void trigger_event(string name, uvm_object data = null);
    uvm_event ev = get_event(name);
    ev.trigger(data);
    `uvm_info("I2C_EVENT", $sformatf("Event '%s' triggered", name), UVM_HIGH)
  endfunction
  
  //----------------------------------------------------------------------------
  // Wait for Event (blocking task)
  //----------------------------------------------------------------------------
  static task wait_for_event(string name, output uvm_object data);
    uvm_event ev = get_event(name);
    ev.wait_trigger_data(data);
    `uvm_info("I2C_EVENT", $sformatf("Event '%s' received", name), UVM_HIGH)
  endtask
  
  //----------------------------------------------------------------------------
  // Wait for Event with Timeout
  //----------------------------------------------------------------------------
  static task wait_for_event_timeout(string name, time timeout, output bit timed_out);
    uvm_event ev = get_event(name);
    timed_out = 0;
    
    fork
      begin
        ev.wait_trigger();
        timed_out = 0;
      end
      begin
        #timeout;
        timed_out = 1;
      end
    join_any
    disable fork;
    
    if (timed_out)
      `uvm_info("I2C_EVENT", $sformatf("Event '%s' timed out after %0t", name, timeout), UVM_HIGH)
  endtask
  
  //----------------------------------------------------------------------------
  // Reset Event (clear trigger state)
  //----------------------------------------------------------------------------
  static function void reset_event(string name);
    uvm_event ev = get_event(name);
    ev.reset();
  endfunction
  
  //----------------------------------------------------------------------------
  // Reset All Events
  //----------------------------------------------------------------------------
  static function void reset_all_events();
    uvm_event_pool pool = get_global_pool();
    string event_names[$];
    
    // Reset known events
    reset_event(RESET_DONE);
    reset_event(START_DETECTED);
    reset_event(STOP_DETECTED);
    reset_event(ADDR_PHASE_DONE);
    reset_event(DATA_PHASE_DONE);
    reset_event(TRANS_COMPLETE);
    reset_event(NACK_RECEIVED);
    reset_event(ARB_LOST);
    reset_event(BUS_IDLE);
    reset_event(ROLE_UPDATE);
    reset_event(ROLE_COMMITTED);
    reset_event(ERROR_DETECTED);
  endfunction

endclass

`endif // I2C_EVENTS_SV
