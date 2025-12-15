module i2c_slave #(
  parameter logic [6:0] SLAVE_ADDR = 7'h55
)(
  input  wire scl_i,
  input  wire sda_i,
  output wire scl_o,
  output wire sda_o,
  output wire scl_oe,
  output wire sda_oe,
  
  input  wire rst_n
);

  // State Machine
  typedef enum logic [3:0] {
    IDLE,
    ADDR,
    ACK_ADDR,
    DATA_RX,
    ACK_DATA_RX,
    DATA_TX,
    ACK_DATA_TX,
    STOP
  } state_t;

  state_t state, next_state;
  
  // Internal Registers
  logic [7:0] shift_reg;
  logic [2:0] bit_cnt;
  logic [7:0] memory [0:255]; // Simple 256-byte memory
  logic [7:0] mem_addr;       // Pointer
  logic       rw_bit;         // 1=Read, 0=Write
  logic       addr_match;
  
  // Start/Stop Detection
  logic sda_d, scl_d;
  logic start_det, stop_det;
  
  // Tri-state control
  logic sda_out_reg;
  
  assign sda_o  = 1'b0; // Open-drain: always drive low when active
  assign sda_oe = !sda_out_reg; // OE high when we want to drive '0' (sda_out_reg=0)
  
  assign scl_o  = 1'b0; // Slave never stretches clock in this simple model
  assign scl_oe = 1'b0;

  // Detection Logic (Async)
  // Start: SCL High, SDA High->Low
  // Stop:  SCL High, SDA Low->High
  always_ff @(posedge sda_i or negedge sda_i) begin
    if (scl_i) begin
      if (!sda_i) start_det = 1; // Falling edge SDA while SCL High
      else        stop_det  = 1; // Rising edge SDA while SCL High
    end
  end
  
  // Reset detectors on SCL edges or system reset (simplified)
  // Real implementation needs robust filtering. 
  // For VIP testing, we use behavioral start/stop blocks inside the FSM always block
  // or use edge detection synchronized to a fast system clock. 
  // Since we don't have a system clock here (pure I2C model), we rely on SCL edges.

  // --- Simplified Behavioral Implementation for VIP testing ---
  
  // Synchronization / Edge detection logic
  // We treat SCL as the clock for the FSM, but we need to handle asynchronous Start/Stop.
  
  logic sda_shadow;
  assign sda_shadow = sda_i;

  always @(negedge sda_i) begin
    if (scl_i) begin
      // Start Condition
      state   <= ADDR;
      bit_cnt <= 7;
      shift_reg <= 0;
      sda_out_reg <= 1; // Release bus
      $display("RTL: Start Condition Detected");
    end
  end
  
  always @(posedge sda_i) begin
    if (scl_i) begin
      // Stop Condition
      state <= IDLE;
      $display("RTL: Stop Condition Detected");
    end
  end

  // FSM on SCL edges
  always @(posedge scl_i or negedge rst_n) begin
    if (!rst_n) begin
      // Reset logic handled elsewhere or assumed init
    end else begin
      // Sample Data on Rising Edge
      case (state)
        ADDR: begin
          shift_reg[bit_cnt] <= sda_i;
        end
        DATA_RX: begin
          shift_reg[bit_cnt] <= sda_i;
        end
        ACK_DATA_TX: begin
          if (sda_i == 1'b1) begin // NACK from Master
             state <= IDLE; 
          end
        end
      endcase
    end
  end

  always @(negedge scl_i or negedge rst_n) begin
    if (!rst_n) begin
      state <= IDLE;
      sda_out_reg <= 1;
      bit_cnt <= 0;
    end else begin
      // Drive Data on Falling Edge
      case (state)
        IDLE: begin
          sda_out_reg <= 1;
        end
        
        ADDR: begin
          if (bit_cnt == 0) begin
            // Check Address
            if (shift_reg[7:1] == SLAVE_ADDR) begin
               addr_match = 1;
               rw_bit = shift_reg[0];
               state <= ACK_ADDR;
               sda_out_reg <= 0; // ACK
               $display("RTL: Address Match. RW=%b", rw_bit);
            end else begin
               addr_match = 0;
               state <= IDLE; // Ignore rest
            end
          end else begin
            bit_cnt <= bit_cnt - 1;
            sda_out_reg <= 1;
          end
        end
        
        ACK_ADDR: begin
          sda_out_reg <= 1; // Release for data
          bit_cnt <= 7;
          if (rw_bit == 0) begin // Write
             state <= DATA_RX;
          end else begin // Read
             state <= DATA_TX;
             shift_reg <= memory[mem_addr]; // Load data
             sda_out_reg <= memory[mem_addr][7]; // Drive MSB
             mem_addr <= mem_addr + 1;
          end
        end
        
        DATA_RX: begin
           if (bit_cnt == 0) begin
             state <= ACK_DATA_RX;
             memory[mem_addr] <= shift_reg; // Store data
             $display("RTL: Received Data: %h", shift_reg);
             mem_addr <= mem_addr + 1;
             sda_out_reg <= 0; // ACK
           end else begin
             bit_cnt <= bit_cnt - 1;
             sda_out_reg <= 1;
           end
        end
        
        ACK_DATA_RX: begin
           sda_out_reg <= 1; // Release
           bit_cnt <= 7;
           state <= DATA_RX; // Expect next byte
        end
        
        DATA_TX: begin
           if (bit_cnt == 0) begin
              state <= ACK_DATA_TX;
              sda_out_reg <= 1; // Release for ACK
           end else begin
              bit_cnt <= bit_cnt - 1;
              sda_out_reg <= shift_reg[bit_cnt]; // Drive next bit
           end
        end
        
        ACK_DATA_TX: begin
           // Check ACK/NACK in posedge block
           // If ACK (0), continue
           state <= DATA_TX;
           shift_reg <= memory[mem_addr];
           sda_out_reg <= memory[mem_addr][7];
           mem_addr <= mem_addr + 1;
           bit_cnt <= 7;
        end

      endcase
    end
  end

endmodule

