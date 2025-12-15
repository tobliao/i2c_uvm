`timescale 1ns/1ps

module tb_top;
  import uvm_pkg::*;
  import i2c_test_pkg::*;

  // Clock and Reset for RTL Master
  reg clk;
  reg rst_n;
  
  // RTL Interface connections (Slave)
  wire slv_scl_o, slv_sda_o, slv_scl_oe, slv_sda_oe;
  
  // RTL Interface connections (Master)
  wire mst_scl_o, mst_sda_o, mst_scl_oe, mst_sda_oe;
  reg  mst_req;
  wire mst_done;
  wire mst_ack_error;

  // Interface Instance
  i2c_if intf();

  // Pull-up Resistors (Simulating the board pull-ups)
  pullup(intf.scl);
  pullup(intf.sda);

  // DUT Instance: SLAVE (Used for Master-Mode Tests)
  i2c_slave #(
    .SLAVE_ADDR(7'h55)
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
    .rw_i(1'b0), // Write
    .addr_i(7'h55),
    .data_in(8'hAA),
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
    #100;
    rst_n = 1;
    #100;
    
    // Trigger Master RTL if running Slave Test
    // Phase 1 (Master Mode) takes ~100-200us per packet. 
    // 1000 pkts * 200us = 200ms.
    // So we wait 300ms before triggering RTL Master.
    
    // ADJUSTMENT: The timeout error suggests 300ms might be barely missing the mark or something else.
    // Let's reduce this wait to ensure we definitely trigger while the test is waiting.
    // The test switches to Slave Mode immediately after Phase 1.
    // If Phase 1 takes 108ms (from previous log), triggering at 120ms is safer than 300ms.
    
    #120000000; // 120ms (was 300ms)
    
    // Trigger RTL Master multiple times to generate traffic for Slave Mode
    repeat(100) begin
      mst_req = 1;
      #5000; // Trigger pulse extended to 5us (must be > 4*CLK_DIV*clk_period approx 1us)
      mst_req = 0;
      
      // Wait for transaction to complete
      wait(mst_done);
      #50000; // 50us gap between transactions
    end
  end

  // Connect Interface to UVM DB
  initial begin
    uvm_config_db#(virtual i2c_if)::set(null, "*", "vif", intf);
    run_test();
  end

  // Waveform Dump (VCS)
  initial begin
    $fsdbDumpfile("waves.fsdb");
    $fsdbDumpvars(0, tb_top);
  end

endmodule
