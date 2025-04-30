`timescale 1ns/1ps
`define CLK_PER 20          // 20 ns  -> 50 MHz

`include "tb_tasks.sv"      // << brings in initialize, hill_climb, brake_test

module ebike_tb;

   //---------------------------------------------------------------------------
   // DUT-facing signals
   //---------------------------------------------------------------------------
   reg  clk;
   reg  RST_n;

   // ADC SPI
   wire A2D_SS_n, A2D_SCLK, A2D_MOSI;
   wire A2D_MISO;

   // BLDC hall sensors & FETs
   reg  hallGrn, hallYlw, hallBlu;
   wire highGrn, lowGrn, highYlw, lowYlw, highBlu, lowBlu;

   // Inertial-sensor SPI
   wire inertSS_n, inertSCLK, inert_MOSI;
   wire inertMISO, inertINT;

   // Misc I/O
   reg  cadence, tgglMd;
   wire TX_RX;
   wire [1:0] LED;

   // UART monitor
   wire       vld_TX;
   wire [7:0] rx_data;

   // Analogue & physics stimulus (shared with tasks)
   reg  [11:0] TORQUE, BRAKE, CURR, BATT;
   reg  [15:0] YAW_RT;

   //---------------------------------------------------------------------------
   // Clock generation
   //---------------------------------------------------------------------------
   initial clk = 0;
   always #(`CLK_PER/2) clk = ~clk;

   //---------------------------------------------------------------------------
   // Reset synchroniser (same as DUT)
   //---------------------------------------------------------------------------
   wire rst_n;
   reset_synch u_rst (.RST_n(RST_n), .clk(clk), .rst_n(rst_n));

   //---------------------------------------------------------------------------
   // Device-under-test
   //---------------------------------------------------------------------------
   eBike DUT (
      .clk       (clk),
      .RST_n     (RST_n),

      .A2D_SS_n  (A2D_SS_n),
      .A2D_MOSI  (A2D_MOSI),
      .A2D_SCLK  (A2D_SCLK),
      .A2D_MISO  (A2D_MISO),

      .hallGrn   (hallGrn),  .hallYlw(hallYlw), .hallBlu(hallBlu),
      .highGrn   (highGrn),  .lowGrn (lowGrn),
      .highYlw   (highYlw),  .lowYlw (lowYlw),
      .highBlu   (highBlu),  .lowBlu (lowBlu),

      .inertSS_n (inertSS_n), .inertSCLK(inertSCLK),
      .inertMOSI (inert_MOSI), .inertMISO(inertMISO), .inertINT(inertINT),

      .cadence   (cadence),
      .tgglMd    (tgglMd),

      .TX        (TX_RX),
      .LED       (LED)
   );

   //---------------------------------------------------------------------------
   // UART receiver (monitors telemetry TX line)
   //---------------------------------------------------------------------------
   UART_rcv u_uart (
      .clk     (clk),
      .rst_n   (RST_n),
      .RX      (TX_RX),
      .clr_rdy (vld_TX),
      .rdy     (vld_TX),
      .rx_data (rx_data)
   );

   //---------------------------------------------------------------------------
   // Physics model & ADC behavioural model (instantiate as before)
   //---------------------------------------------------------------------------
   //---------------------------------------------------------------------------
// Physics model  –  motor + inertial-sensor stub
//---------------------------------------------------------------------------
eBikePhysics u_phys (
   //---------------------------------------------------------------- clk / rst
   .clk      (clk),
   .RST_n    (rst_n),          // <<< synchronised reset (double-flop inside)
   //---------------------------------------------------------------- SPI slave
   .SS_n     (inertSS_n),
   .SCLK     (inertSCLK),
   .MOSI     (inert_MOSI),
   .MISO     (inertMISO),
   .INT      (inertINT),
   //---------------------------------------------------------------- yaw stimulus
   .yaw_rt   (YAW_RT),
   //---------------------------------------------------------------- FET gate drives from DUT
   .highGrn  (highGrn), .lowGrn(lowGrn),
   .highYlw  (highYlw), .lowYlw(lowYlw),
   .highBlu  (highBlu), .lowBlu(lowBlu),
   //---------------------------------------------------------------- Hall sensors → DUT
   .hallGrn  (hallGrn),
   .hallYlw  (hallYlw),
   .hallBlu  (hallBlu),
   //---------------------------------------------------------------- Avg motor current → ADC model
   .avg_curr (CURR)
);


//---------------------------------------------------------------------------
// ADC behavioural model  –  National ADC128S022 stub
//---------------------------------------------------------------------------
AnalogModel u_adc (
   .clk     (clk),
   .rst_n   (RST_n),        // raw asynchronous reset, per ADC model

   // analogue channels driven by TB & physics
   .BATT    (BATT),
   .CURR    (CURR),
   .BRAKE   (BRAKE),
   .TORQUE  (TORQUE),

   // SPI slave interface
   .SS_n    (A2D_SS_n),
   .SCLK    (A2D_SCLK),
   .MOSI    (A2D_MOSI),
   .MISO    (A2D_MISO)
);

   //=====================================================================
   //  STIMULUS SEQUENCE
   //=====================================================================
   initial begin
      // raw defaults for discrete inputs
      hallGrn = 0; hallYlw = 0; hallBlu = 0;
      cadence = 0; tgglMd  = 0;

      // analogue defaults via helper task
      initialize(BATT, BRAKE, TORQUE, CURR, YAW_RT);
      

      // reset pulse
      RST_n = 0; repeat (10) @(posedge clk); RST_n = 1;
      $display("[%0t] TB started", $time);

      repeat (1000) @(posedge clk);       // settle

      // 1) hill climb – 5 ms at yaw_rt 1500
      hill_climb(250_000, 16'd1500, YAW_RT, clk);

      // 2) toggle assist level once
      repeat (1000) @(posedge clk);
      tgglMd <= 1; @(posedge clk); tgglMd <= 0;
      repeat (5_000) @(posedge clk);

      // 3) 2-ms brake pulse
      brake_test(100_000, BRAKE, clk);

      // end simulation
      repeat (50_000) @(posedge clk);
      $display("[%0t] Simulation finished", $time);
      $stop;
   end

   //---------------------------------------------------------------------------
   // Simple cadence pulse train (~90 rpm equivalent, scaled)
   //---------------------------------------------------------------------------
   always begin
      cadence = 1'b0; #(1000);   // 10 µs low
      cadence = 1'b1; #(1000);   // 10 µs high
   end

endmodule
