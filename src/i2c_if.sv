`timescale 1ns/1ps

interface i2c_if;

  // I2C Bus Signals (Bidirectional)
  wire scl;
  wire sda;

  // Internal driver signals (Driven by the VIP Driver)
  // '1' = Release bus (High-Z), '0' = Drive Low
  logic scl_drive; 
  logic sda_drive;

  // Open-Drain Modeling
  // These assigns model the "Driver's" contribution to the bus.
  // The actual bus value 'scl'/'sda' is the resolved value of all drivers (DUT + VIP).
  assign scl = (scl_drive === 1'b0) ? 1'b0 : 1'bz;
  assign sda = (sda_drive === 1'b0) ? 1'b0 : 1'bz;

  // Pull-up Resistors moved to Testbench (tb_top.sv) due to tool limitations in Interface

  // Initialization
  initial begin
    scl_drive = 1'b1;
    sda_drive = 1'b1;
  end

endinterface
