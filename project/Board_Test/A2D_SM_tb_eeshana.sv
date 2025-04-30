`timescale 1ns/1ps

module A2D_tb;
  // Clock and reset signals
  reg clk;
  reg rst_n;

  // A2D_intf output signals
  wire [11:0] batt;
  wire [11:0] curr;
  wire [11:0] brake;
  wire [11:0] torque;
  wire        SS_n;
  wire        SCLK;
  wire        MOSI;

  // SPI bidirectional signal: driven by ADC128S model to A2D_intf
  wire        MISO;

  // Instantiate the A2D interface module (your design)
  A2D_intf dut (
    .clk    (clk),
    .rst_n  (rst_n),
    .batt   (batt),
    .curr   (curr),
    .brake  (brake),
    .torque (torque),
    .SS_n   (SS_n),
    .SCLK   (SCLK),
    .MOSI   (MOSI),
    .MISO   (MISO)
  );

  // Instantiate the ADC128S model (A2D converter model)
  ADC128S adc (
    .clk   (clk),
    .rst_n (rst_n),
    .SS_n  (SS_n),
    .SCLK  (SCLK),
    .MOSI  (MOSI),
    .MISO  (MISO)
  );

  // Clock generation: 50 MHz clock (20 ns period)
  initial begin
    clk = 0;
    forever #5 clk = ~clk;
  end

  // Dump waveforms for post-simulation analysis
  initial begin
    rst_n = 0;
    #10;
    rst_n = 1;
    $dumpfile("A2D_tb.vcd");
    $dumpvars(0, A2D_tb);
  end

endmodule