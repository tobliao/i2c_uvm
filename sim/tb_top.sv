`timescale 1ns/1ps

module tb_top;
  import uvm_pkg::*;
  import i2c_test_pkg::*;

  // ============================================================
  // SINGLE SOURCE OF TRUTH: DUT Slave Address
  // Both RTL and VIP must use this same value to stay in sync
  // ============================================================
  localparam bit [6:0] DUT_SLAVE_ADDR = 7'h55;

  // Clock and Reset for RTL Master
  reg clk;
  reg rst_n;
  
  // RTL Interface connections (Slave)
  wire slv_scl_o, slv_sda_o, slv_scl_oe, slv_sda_oe;
  
  // RTL Interface connections (Master)
  wire mst_scl_o, mst_sda_o, mst_scl_oe, mst_sda_oe;
  reg  mst_req;
  reg  mst_rw;      // Control for R/W
  reg  [6:0] mst_addr; // Control for Address
  reg  [7:0] mst_data; // Control for Write Data (randomized for toggle coverage)
  wire mst_done;
  wire mst_ack_error;

  // Interface Instance
  i2c_if intf();

  // Pull-up Resistors (Simulating the board pull-ups)
  pullup(intf.scl);
  pullup(intf.sda);

  // DUT Instance: SLAVE (Uses DUT_SLAVE_ADDR)
  i2c_slave #(
    .SLAVE_ADDR(DUT_SLAVE_ADDR)
  ) dut_slave (
    .scl_i(intf.scl), 
    .sda_i(intf.sda),
    .scl_o(slv_scl_o),    
    .sda_o(slv_sda_o),
    .scl_oe(slv_scl_oe),
    .sda_oe(slv_sda_oe),
    .rst_n(rst_n)      
  );
  
  // DUT Instance: MASTER (Used for Slave-Mode Tests)
  i2c_master #(
    .CLK_DIV(50)
  ) dut_master (
    .clk(clk),
    .rst_n(rst_n),
    .req_i(mst_req),
    .rw_i(mst_rw),
    .addr_i(mst_addr),
    .data_in(mst_data),  // Randomized for toggle coverage
    .data_out(),
    .done_o(mst_done),
    .ack_error_o(mst_ack_error),
    .scl_i(intf.scl),
    .sda_i(intf.sda),
    .scl_o(mst_scl_o),
    .sda_o(mst_sda_o),
    .scl_oe(mst_scl_oe),
    .sda_oe(mst_sda_oe)
  );

  // Tri-state Driver Logic
  // Slave Drivers
  assign intf.scl = (slv_scl_oe && !slv_scl_o) ? 1'b0 : 1'bz;
  assign intf.sda = (slv_sda_oe && !slv_sda_o) ? 1'b0 : 1'bz;
  
  // Master Drivers
  assign intf.scl = (mst_scl_oe && !mst_scl_o) ? 1'b0 : 1'bz;
  assign intf.sda = (mst_sda_oe && !mst_sda_o) ? 1'b0 : 1'bz;

  // Clock Generation
  initial begin
    clk = 0;
    forever #10 clk = ~clk; // 50 MHz
  end

  // Test Control
  initial begin
    rst_n = 0;
    mst_req = 0;
    mst_rw = 0;
    mst_addr = DUT_SLAVE_ADDR; // Use the same address
    mst_data = 8'h00;
    
    #100;
    rst_n = 1;
    #100;
    
    // Toggle reset again for coverage
    #1000;
    rst_n = 0;
    #100;
    rst_n = 1;
    #100;
    
    // Trigger RTL Master if running Slave Test
    // Phase 1 (Master Mode) runs 20 mixed packets (approx 4ms).
    // We wait 10ms to ensure VIP is in Slave Mode.
    
    #10000000; // 10ms
    
    $display("TB_TOP: Triggering RTL Master Sequence...");

    // Trigger RTL Master multiple times to generate traffic for Slave Mode
    repeat(100) begin
      @(posedge clk);
      mst_req = 1;
      
      // Randomize traffic type
      mst_rw = $random % 2; // Random Read/Write
      
      // Randomize data for write transactions (toggle coverage)
      mst_data = $random;
      
      // Vary addresses to toggle all addr_i bits while maintaining high valid rate
      // 80% valid address for good slave coverage, 20% varied for toggle coverage
      case ($random % 20)
        0: mst_addr = ~DUT_SLAVE_ADDR;          // 0x2A = 0101010 (inverted for toggle)
        1: mst_addr = 7'h00;                    // All zeros
        2: mst_addr = 7'h7F;                    // All ones  
        3: mst_addr = $random;                  // Random
        default: mst_addr = DUT_SLAVE_ADDR;     // Valid address (80%)
      endcase
      
      // Wait for ACK of request
      #5000; 
      mst_req = 0;
      
      // Wait for transaction to complete
      @(posedge mst_done);
      
      #50000; // 50us gap between transactions
    end
  end

  // Connect Interface and Configuration to UVM DB
  initial begin
    // Pass the interface
    uvm_config_db#(virtual i2c_if)::set(null, "*", "vif", intf);
    
    // Pass the slave address so VIP sequences can use it
    uvm_config_db#(bit[6:0])::set(null, "*", "slave_addr", DUT_SLAVE_ADDR);
    
    run_test();
  end

  // Waveform Dump (VCS)
  initial begin
    $fsdbDumpfile("waves.fsdb");
    $fsdbDumpvars(0, tb_top);
  end

endmodule
