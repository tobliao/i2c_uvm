`timescale 1ns/1ps

module tb_top;
  import uvm_pkg::*;
  import i2c_test_pkg::*;

  // Logic wires
  wire scl;
  wire sda;
  
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
    // Ideally this should be controlled via a virtual sequence or signal agent
    // For now, we hardcode a trigger after some delay
    // Delay needs to be long enough for the Master-Mode Sanity test to finish (approx 1ms)
    #2000000; // 2ms
    mst_req = 1;
    #20;
    mst_req = 0;
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
