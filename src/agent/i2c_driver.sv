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
        
        drive_transfer(req);
        seq_item_port.item_done();
        
      end else begin
        // --- SLAVE MODE ---
        // Listen to the bus
        wait_for_request();
      end
    end
  endtask

  // --- Master Mode Tasks ---
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

  // --- Slave Mode Tasks ---
  task wait_for_request();
      logic [7:0] addr_byte;
      logic [7:0] data_byte;
      i2c_direction_e dir;
      bit [6:0] rcv_addr;
      
      // 1. Detect Start Condition
      // We must detect Start OR if the test wants to end.
      // Since we don't have an easy way to interrupt 'wait', 
      // we rely on the bus activity or reset.
      
      wait(vif.sda == 0 && vif.scl == 1);
      
      // 2. Read Address (8 bits)
      // Since we don't have a full bit-banging slave RX implementation in this VIP version yet,
      // we will perform a 'snoop' or cheat by reading the byte using the same timing helper
      // assuming the RTL master follows standard timing.
      
      // Wait for first SCL rise to sample address
      read_byte(addr_byte);
      
      rcv_addr = addr_byte[7:1];
      dir      = i2c_direction_e'(addr_byte[0]);
      
      // 3. Send ACK (We acknowledge everything for now)
      send_ack();
      
      // 4. Read Data (Assume 1 byte Write for simple sanity test)
      // In a real robust driver, we would loop until Stop.
      if (dir == I2C_WRITE) begin
          read_byte(data_byte);
          send_ack();
          
          `uvm_info("DRV_SLV", $sformatf("Slave Received Write: Addr=0x%0h Data=0x%0h", rcv_addr, data_byte), UVM_LOW)
      end else begin
          // For Read, we should drive data.
          // Placeholder: Drive 0xFF
          send_byte(8'hFF);
          // Master sends NACK/ACK
          // wait_ack(status); // Ignore status for now
          
          `uvm_info("DRV_SLV", $sformatf("Slave Serviced Read: Addr=0x%0h Driven=0xFF", rcv_addr), UVM_LOW)
      end
      
      // 5. Wait for Stop
      wait(vif.sda == 1 && vif.scl == 1);
      
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

endclass

`endif // I2C_DRIVER_SV
