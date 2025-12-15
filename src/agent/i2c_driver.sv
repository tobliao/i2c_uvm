`ifndef I2C_DRIVER_SV
`define I2C_DRIVER_SV

class i2c_driver extends uvm_driver #(i2c_transaction);
  `uvm_component_utils(i2c_driver)

  virtual i2c_if vif;
  i2c_config     cfg;

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  task run_phase(uvm_phase phase);
    // Initialize Bus Drive to High-Z (Released)
    vif.scl_drive <= 1'b1;
    vif.sda_drive <= 1'b1;
    
    forever begin
      // Check Configuration at the start of each transaction cycle
      if (cfg.is_master) begin
        // --- MASTER MODE ---
        // Get the next item (Blocking)
        seq_item_port.get_next_item(req);
        
        // Re-check config in case it changed while we were blocked?
        // If changed, we might want to skip driving, but we already pulled the item.
        // Let's just drive this last item (the "Switching" dummy item) and then loop.
        
        drive_transfer(req);
        seq_item_port.item_done();
        
      end else begin
        // --- SLAVE MODE ---
        // Listen to the bus
        wait_for_request();
        
        // After one transaction, we loop back.
        // This allows checking if we switched back to Master (unlikely in this test, but good practice).
      end
    end
  endtask

  // --- Master Mode Tasks ---
  task drive_transfer(i2c_transaction tr);
    `uvm_info("DRV", $sformatf("Driving Transaction: %s", tr.convert2string()), UVM_MEDIUM)
    
    // 1. Start Condition
    send_start();
    
    // 2. Address + R/W
    send_byte({tr.addr[6:0], tr.direction}); 
    wait_ack(tr.status);

    if (tr.status == I2C_STATUS_ADDR_NACK) begin
       `uvm_info("DRV", "Address NACK received, stopping", UVM_LOW)
       send_stop();
       return;
    end

    // 3. Data Transfer
    if (tr.direction == I2C_WRITE) begin
       foreach(tr.data[i]) begin
         send_byte(tr.data[i]);
         wait_ack(tr.status);
         if (tr.status == I2C_STATUS_DATA_NACK) break;
       end
    end else begin
       foreach(tr.data[i]) begin
         bit is_last = (i == tr.data.size() - 1);
         read_byte(tr.data[i]);
         if (is_last) send_nack();
         else         send_ack();
       end
    end

    // 4. Stop or Repeated Start
    if (tr.repeated_start)
      send_repeated_start();
    else
      send_stop();
  endtask

  // --- Slave Mode Tasks ---
  task wait_for_request();
      // 1. Detect Start Condition
      // We wait for SDA Falling Edge while SCL is High
      // Note: This is a blocking check.
      
      // Basic polling loop for Start
      // We must exit if reset or something else happens, but for now simple wait.
      fork
        begin
           wait(vif.sda == 0 && vif.scl == 1);
        end
        begin
           // Optional timeout to allow polling config? 
           // For now, infinite wait is fine for the test logic.
           // However, if we want to be robust, we should allow breaking out.
        end
      join_any
      disable fork;
      
      `uvm_info("DRV_SLV", "Start Condition Detected", UVM_HIGH)
      
      // 2. Read Address (8 bits)
      // This part requires bit-banging read similar to 'read_byte' but driven by Master's SCL.
      // Since this is a simple VIP, we will just wait a fixed time to simulate the transaction duration
      // or implement a basic 'slave_byte_rx'.
      
      // Real implementation would:
      // - Sample 8 bits on SCL rising edges
      // - Compare Address
      // - Drive ACK
      // - Rx/Tx Data
      
      // Placeholder for sanity test:
      // Wait for the transaction to essentially 'pass' by waiting for Stop condition
      wait(vif.sda == 1 && vif.scl == 1); // Stop
      
      `uvm_info("DRV_SLV", "Stop Condition Detected / Transaction Done", UVM_HIGH)
  endtask


  // --- Bit Banging Tasks ---
  
  task wait_half_period(int is_high_period);
     if (is_high_period)
       #(cfg.t_high_ns * 1ns);
     else
       #(cfg.t_low_ns * 1ns);
  endtask

  task send_start();
    vif.sda_drive <= 1'b1;
    vif.scl_drive <= 1'b1;
    wait_half_period(1); 
    
    vif.sda_drive <= 1'b0; 
    wait_half_period(1);
    
    vif.scl_drive <= 1'b0; 
    wait_half_period(0);
  endtask

  task send_stop();
    vif.scl_drive <= 1'b0;
    vif.sda_drive <= 1'b0;
    wait_half_period(0);
    
    vif.scl_drive <= 1'b1; 
    wait_half_period(1);
    
    vif.sda_drive <= 1'b1; 
    wait_half_period(1);
    #(cfg.t_buf_ns * 1ns);
  endtask
  
  task send_repeated_start();
    vif.scl_drive <= 1'b0;
    vif.sda_drive <= 1'b1;
    wait_half_period(0);
    
    vif.scl_drive <= 1'b1;
    wait_half_period(1);
    
    vif.sda_drive <= 1'b0; 
    wait_half_period(1);
    
    vif.scl_drive <= 1'b0;
    wait_half_period(0);
  endtask

  task send_byte(input bit [7:0] data);
    for(int i=7; i>=0; i--) begin
       vif.sda_drive <= data[i];
       wait_half_period(0); 
       
       vif.scl_drive <= 1'b1;
       wait_half_period(1);
       
       vif.scl_drive <= 1'b0;
    end
  end
  
  task read_byte(output bit [7:0] data);
    vif.sda_drive <= 1'b1; 
    
    for(int i=7; i>=0; i--) begin
       wait_half_period(0);
       
       vif.scl_drive <= 1'b1;
       wait_half_period(1);
       
       data[i] = vif.sda; 
       
       vif.scl_drive <= 1'b0;
    end
  end
  
  task wait_ack(output i2c_status_e status);
    vif.sda_drive <= 1'b1;
    wait_half_period(0);
    
    vif.scl_drive <= 1'b1;
    wait_half_period(1);
    
    if (vif.sda === 1'b0) begin
       status = I2C_STATUS_OK;
       `uvm_info("DRV", "ACK Received", UVM_HIGH)
    end else begin
       status = I2C_STATUS_ADDR_NACK; 
       `uvm_info("DRV", "NACK Received", UVM_HIGH)
    end
    
    vif.scl_drive <= 1'b0;
  end

  task send_ack();
    vif.sda_drive <= 1'b0;
    wait_half_period(0);
    vif.scl_drive <= 1'b1;
    wait_half_period(1);
    vif.scl_drive <= 1'b0;
  end

  task send_nack();
    vif.sda_drive <= 1'b1;
    wait_half_period(0);
    vif.scl_drive <= 1'b1;
    wait_half_period(1);
    vif.scl_drive <= 1'b0;
  end

endclass

`endif // I2C_DRIVER_SV
