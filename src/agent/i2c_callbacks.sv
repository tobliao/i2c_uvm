`ifndef I2C_CALLBACKS_SV
`define I2C_CALLBACKS_SV

//==============================================================================
// I2C Callback Classes
//
// UVM Callbacks provide extensibility hooks without modifying base components.
// Users can extend these classes to inject custom behavior at key points.
//==============================================================================

//------------------------------------------------------------------------------
// Driver Callbacks - Hooks for transaction injection/modification
//------------------------------------------------------------------------------
class i2c_driver_callback extends uvm_callback;
  `uvm_object_utils(i2c_driver_callback)
  
  function new(string name = "i2c_driver_callback");
    super.new(name);
  endfunction
  
  // Called before driving a transaction
  virtual task pre_drive(i2c_driver drv, i2c_transaction tr);
    // Override to inject delays, modify transactions, etc.
  endtask
  
  // Called after driving a transaction
  virtual task post_drive(i2c_driver drv, i2c_transaction tr);
    // Override for post-processing
  endtask
  
  // Called on error condition
  virtual function void on_error(i2c_driver drv, i2c_transaction tr, string error_msg);
    // Override for error handling
  endfunction
  
endclass

//------------------------------------------------------------------------------
// Monitor Callbacks - Hooks for observed transaction processing
//------------------------------------------------------------------------------
class i2c_monitor_callback extends uvm_callback;
  `uvm_object_utils(i2c_monitor_callback)
  
  function new(string name = "i2c_monitor_callback");
    super.new(name);
  endfunction
  
  // Called when Start condition detected
  virtual function void on_start(i2c_monitor mon);
  endfunction
  
  // Called when Stop condition detected
  virtual function void on_stop(i2c_monitor mon);
  endfunction
  
  // Called when address phase complete
  virtual function void on_address(i2c_monitor mon, bit [6:0] addr, bit rw);
  endfunction
  
  // Called when data byte received
  virtual function void on_data_byte(i2c_monitor mon, bit [7:0] data, bit ack);
  endfunction
  
  // Called when complete transaction observed
  virtual function void on_transaction(i2c_monitor mon, i2c_transaction tr);
  endfunction
  
endclass

//------------------------------------------------------------------------------
// Scoreboard Callbacks - Hooks for checking customization
//------------------------------------------------------------------------------
class i2c_scoreboard_callback extends uvm_callback;
  `uvm_object_utils(i2c_scoreboard_callback)
  
  function new(string name = "i2c_scoreboard_callback");
    super.new(name);
  endfunction
  
  // Called before comparison
  virtual function bit pre_compare(i2c_transaction expected, i2c_transaction actual);
    return 1; // Return 1 to continue, 0 to skip comparison
  endfunction
  
  // Called after comparison
  virtual function void post_compare(i2c_transaction expected, i2c_transaction actual, bit matched);
  endfunction
  
  // Called on mismatch
  virtual function void on_mismatch(i2c_transaction expected, i2c_transaction actual);
  endfunction
  
endclass

//------------------------------------------------------------------------------
// Example: Error Injection Callback
//------------------------------------------------------------------------------
class i2c_error_injection_callback extends i2c_driver_callback;
  `uvm_object_utils(i2c_error_injection_callback)
  
  // Configuration
  int unsigned error_rate = 0;  // Percentage (0-100)
  bit inject_nack = 0;
  bit inject_arb_lost = 0;
  
  function new(string name = "i2c_error_injection_callback");
    super.new(name);
  endfunction
  
  virtual task pre_drive(i2c_driver drv, i2c_transaction tr);
    int rand_val = $urandom_range(0, 99);
    
    if (rand_val < error_rate) begin
      if (inject_nack) begin
        `uvm_info("CB_ERR_INJ", "Injecting NACK error", UVM_MEDIUM)
        tr.status = I2C_STATUS_DATA_NACK;
      end
      if (inject_arb_lost) begin
        `uvm_info("CB_ERR_INJ", "Injecting ARB_LOST error", UVM_MEDIUM)
        tr.status = I2C_STATUS_ARB_LOST;
      end
    end
  endtask
  
endclass

//------------------------------------------------------------------------------
// Example: Transaction Logger Callback
//------------------------------------------------------------------------------
class i2c_transaction_logger_callback extends i2c_monitor_callback;
  `uvm_object_utils(i2c_transaction_logger_callback)
  
  // Log file handle
  int log_file;
  string log_filename = "i2c_transactions.log";
  int transaction_count = 0;
  
  function new(string name = "i2c_transaction_logger_callback");
    super.new(name);
  endfunction
  
  function void open_log();
    log_file = $fopen(log_filename, "w");
    if (log_file == 0)
      `uvm_error("CB_LOGGER", $sformatf("Failed to open log file: %s", log_filename))
    else
      $fdisplay(log_file, "=== I2C Transaction Log ===");
  endfunction
  
  function void close_log();
    if (log_file != 0) begin
      $fdisplay(log_file, "=== End of Log (Total: %0d transactions) ===", transaction_count);
      $fclose(log_file);
    end
  endfunction
  
  virtual function void on_transaction(i2c_monitor mon, i2c_transaction tr);
    transaction_count++;
    if (log_file != 0) begin
      $fdisplay(log_file, "[%0t] Transaction #%0d:", $time, transaction_count);
      $fdisplay(log_file, "  Address: 0x%02h, R/W: %s", tr.addr, tr.direction.name());
      $fdisplay(log_file, "  Data: %p", tr.data);
      $fdisplay(log_file, "  Status: %s", tr.status.name());
    end
  endfunction
  
endclass

`endif // I2C_CALLBACKS_SV
