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
