// Update i2c_driver.sv to publish transactions to the monitor's analysis port (via a side channel or direct hook)
// Or better, give the Driver its own analysis port? 
// Standard UVM: Monitor publishes.
// Let's implement a "Cheat" Monitor that spies on the transaction object from the Sequencer/Driver? No.

// Let's implement the Monitor properly (Simplified)
// 1. Wait Start
// 2. Sample 8 bits (Address)
// 3. Sample ACK
// 4. Sample Data Loop
// 5. Wait Stop

// Updated i2c_monitor.sv
`ifndef I2C_MONITOR_SV
`define I2C_MONITOR_SV

class i2c_monitor extends uvm_monitor;
  `uvm_component_utils(i2c_monitor)

  virtual i2c_if vif;
  i2c_config     cfg;
  
  uvm_analysis_port #(i2c_transaction) ap;

  function new(string name, uvm_component parent);
    super.new(name, parent);
    ap = new("ap", this);
  endfunction

  task run_phase(uvm_phase phase);
    i2c_transaction tr;
    logic [7:0] captured_byte;
    logic ack_bit;
    bit stop_or_restart;
    
    forever begin
      // 1. Detect START (SDA falling while SCL is high)
      @(negedge vif.sda);
      if (vif.scl !== 1'b1) begin
        // Not a protocol START (could be data transition while SCL low)
        continue;
      end
      i2c_event_pool::trigger_event(i2c_event_pool::START_DETECTED);
      
      tr = i2c_transaction::type_id::create("tr");
      tr.data = new[0]; // Empty dynamic array
      
      // 2. Decode Address
      sample_byte(captured_byte);
      tr.addr = captured_byte[7:1];
      tr.direction = i2c_direction_e'(captured_byte[0]);
      
      // ACK bit
      sample_bit(ack_bit); // 0=ACK, 1=NACK
      tr.status = (ack_bit == 1'b0) ? I2C_STATUS_OK : I2C_STATUS_ADDR_NACK;
      if (ack_bit)
        i2c_event_pool::trigger_event(i2c_event_pool::NACK_RECEIVED);
      
      // 3. Data Phase
      // Sample bytes until STOP or repeated START is observed.
      // Practical note: For this VIP, a STOP boundary is sufficient to publish a transaction
      // for checking/coverage and to provide a switching boundary.
      stop_or_restart = 0;
      fork
        begin : watch_stop
          @(posedge vif.sda);
          if (vif.scl === 1'b1) begin
            stop_or_restart = 1;
            i2c_event_pool::trigger_event(i2c_event_pool::STOP_DETECTED);
            // "Bus idle" is defined as bus-free after STOP (tBUF).
            #(cfg.t_buf_ns * 1ns);
            if (vif.scl === 1'b1 && vif.sda === 1'b1)
              i2c_event_pool::trigger_event(i2c_event_pool::BUS_IDLE);
          end
        end
        begin : watch_restart
          @(negedge vif.sda);
          if (vif.scl === 1'b1) begin
            // repeated START
            stop_or_restart = 1;
            i2c_event_pool::trigger_event(i2c_event_pool::START_DETECTED);
          end
        end
        begin : sample_data
          // Only sample data if address was ACKed
          if (tr.status == I2C_STATUS_OK) begin
            forever begin
              sample_byte(captured_byte);
              tr.data = new[tr.data.size() + 1] (tr.data);
              tr.data[tr.data.size()-1] = captured_byte;
              sample_bit(ack_bit);
              tr.nack_received = ack_bit;
              if (ack_bit) begin
                i2c_event_pool::trigger_event(i2c_event_pool::NACK_RECEIVED);
                // In write direction, NACK typically terminates the transfer.
                if (tr.direction == I2C_WRITE) disable sample_data;
              end
            end
          end
        end
      join_any
      disable fork;
      
      ap.write(tr);
      i2c_event_pool::trigger_event(i2c_event_pool::TRANS_COMPLETE, tr);
    end
  endtask
  
  task sample_byte(output logic [7:0] b);
    for(int i=7; i>=0; i--) begin
      wait(vif.scl == 1);
      b[i] = vif.sda;
      wait(vif.scl == 0);
    end
  endtask
  
  task sample_bit(output logic b);
      wait(vif.scl == 1);
      b = vif.sda;
      wait(vif.scl == 0);
  endtask

endclass

`endif // I2C_MONITOR_SV
