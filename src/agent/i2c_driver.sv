`ifndef I2C_DRIVER_SV
`define I2C_DRIVER_SV

class i2c_driver extends uvm_driver #(i2c_transaction);
  `uvm_component_utils(i2c_driver)

  virtual i2c_if vif;
  i2c_config     cfg;
  time           idle_poll_time = 1000ns; // prevents busy-spins when no items are available

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  task run_phase(uvm_phase phase);
    // Initialize Bus Drive to High-Z (Released)
    vif.scl_drive <= 1'b1;
    vif.sda_drive <= 1'b1;
    
    forever begin
      // NOTE: cfg.is_master is allowed to change at runtime (dual-role).
      // The driver must therefore avoid indefinitely blocking in MASTER mode
      // when no new items are pending; otherwise role switching requires hacks
      // (e.g., injecting a "dummy" item to unblock get_next_item()).
      if (cfg.is_master) begin
        // --- MASTER MODE ---
        // Non-blocking pull to allow role changes to take effect promptly.
        req = null;
        seq_item_port.try_next_item(req);
        if (req != null) begin
          drive_transfer(req);
          seq_item_port.item_done();
        end else begin
          // No item available: wait briefly or until a role-update event is triggered.
          bit timed_out;
          i2c_event_pool::wait_for_event_timeout(i2c_event_pool::ROLE_UPDATE, idle_poll_time, timed_out);
        end
      end else begin
        // --- SLAVE MODE ---
        // Listen to the bus (passive timing: SCL is observed, never driven).
        wait_for_request();
      end
    end
  endtask

  // -----------------------------------------------------------------------
  // MASTER MODE TASKS
  // -----------------------------------------------------------------------
  task drive_transfer(i2c_transaction tr);
    // Enhanced Logging: Print full transaction details
    `uvm_info("DRV", $sformatf("Master Driving: %s", tr.convert2string()), UVM_LOW)
    
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

  // -----------------------------------------------------------------------
  // SLAVE MODE TASKS
  // -----------------------------------------------------------------------
  task wait_for_request();
      logic [7:0] addr_byte;
      logic [7:0] data_byte;
      i2c_direction_e dir;
      bit [6:0] rcv_addr;
      
      // 1. Detect Start Condition
      wait(vif.sda == 0 && vif.scl == 1);
      
      // 2. Read Address (8 bits) - PASSIVE mode (Slave)
      slave_read_byte(addr_byte);
      
      rcv_addr = addr_byte[7:1];
      dir      = i2c_direction_e'(addr_byte[0]);
      
      // 3. Send ACK
      slave_send_ack();
      
      // 4. Data Phase
      if (dir == I2C_WRITE) begin
          // Master Write -> Slave Read
          slave_read_byte(data_byte);
          slave_send_ack();
          
          `uvm_info("DRV_SLV", $sformatf("\n--------------------------------------------------\n SLAVE RECEIVED TRANSACTION\n Address      : 0x%0x (7-bit)\n Direction    : MASTER_WRITE\n Data Payload : 0x%02x\n Status       : ACK_SENT\n--------------------------------------------------", rcv_addr, data_byte), UVM_LOW)

      end else begin
          // Master Read -> Slave Write
          // Placeholder: Drive 0xFF
          slave_send_byte(8'hFF);
          // Master sends NACK/ACK. 
          slave_wait_ack_or_nack();
          
          `uvm_info("DRV_SLV", $sformatf("\n--------------------------------------------------\n SLAVE SERVICED TRANSACTION\n Address      : 0x%0x (7-bit)\n Direction    : MASTER_READ\n Data Driven  : 0xFF\n Status       : COMPLETED\n--------------------------------------------------", rcv_addr), UVM_LOW)
      end
      
      // 5. Wait for Stop (SDA rising while SCL high)
      wait(vif.sda == 1 && vif.scl == 1);
      
  endtask


  // -----------------------------------------------------------------------
  // BIT BANGING HELPERS (MASTER - Active SCL Drive)
  // -----------------------------------------------------------------------
  
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
  endtask
  
  task read_byte(output bit [7:0] data);
    vif.sda_drive <= 1'b1; 
    
    for(int i=7; i>=0; i--) begin
       wait_half_period(0);
       
       vif.scl_drive <= 1'b1;
       wait_half_period(1);
       
       data[i] = vif.sda; 
       
       vif.scl_drive <= 1'b0;
    end
  endtask
  
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
  endtask

  task send_ack();
    vif.sda_drive <= 1'b0;
    wait_half_period(0);
    vif.scl_drive <= 1'b1;
    wait_half_period(1);
    vif.scl_drive <= 1'b0;
  endtask

  task send_nack();
    vif.sda_drive <= 1'b1;
    wait_half_period(0);
    vif.scl_drive <= 1'b1;
    wait_half_period(1);
    vif.scl_drive <= 1'b0;
  endtask

  // -----------------------------------------------------------------------
  // BIT BANGING HELPERS (SLAVE - Passive SCL Observe)
  // -----------------------------------------------------------------------

  task slave_read_byte(output bit [7:0] data);
    vif.sda_drive <= 1'b1; // Release SDA to read
    vif.scl_drive <= 1'b1; // Ensure we don't drive SCL
    
    for(int i=7; i>=0; i--) begin
       // Wait for SCL Rising Edge (Sample point)
       wait(vif.scl == 1); 
       data[i] = vif.sda;
       // Wait for SCL Falling Edge (Next bit setup)
       wait(vif.scl == 0);
    end
  endtask

  task slave_send_byte(input bit [7:0] data);
    vif.scl_drive <= 1'b1; // Ensure we don't drive SCL
    
    for(int i=7; i>=0; i--) begin
       // Data setup (after SCL fell)
       vif.sda_drive <= data[i];
       
       // Wait for SCL Rising Edge (Master samples)
       wait(vif.scl == 1);
       // Wait for SCL Falling Edge
       wait(vif.scl == 0);
    end
    // Release SDA after last bit
    vif.sda_drive <= 1'b1;
  endtask

  task slave_send_ack();
    vif.scl_drive <= 1'b1; 
    
    // Drive ACK (Low)
    vif.sda_drive <= 1'b0;
    
    // Wait for Master to clock the ACK
    wait(vif.scl == 1);
    wait(vif.scl == 0);
    
    // Release SDA
    vif.sda_drive <= 1'b1;
  endtask

  task slave_wait_ack_or_nack();
    vif.scl_drive <= 1'b1;
    vif.sda_drive <= 1'b1; // Release SDA
    
    wait(vif.scl == 1);
    // Sample if needed: ack = vif.sda;
    wait(vif.scl == 0);
  endtask

endclass

`endif // I2C_DRIVER_SV
