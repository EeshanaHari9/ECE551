`timescale 1ns/1ps
`define CLK_PER 20          // 20-ns period → 50 MHz

`include "tb_tasks.sv"      // initialize, hill_climb, brake_test, incline_profile, assist_cycle

module ebike_tb;

   //---------------------------------------------------------------------------
   //  CLOCK / RESET
   //---------------------------------------------------------------------------
   reg  clk  = 0;
   reg  RST_n;

   always #(`CLK_PER/2) clk = ~clk;

   wire rst_n;
   reset_synch u_rst (.RST_n(RST_n), .clk(clk), .rst_n(rst_n));

   //---------------------------------------------------------------------------
   //  DUT-FACING SIGNALS
   //---------------------------------------------------------------------------
   /*  ADC SPI  */
   wire A2D_SS_n, A2D_SCLK, A2D_MOSI;
   wire A2D_MISO;

   /*  BLDC hall sensors & gate drives  */
   reg  hallGrn, hallYlw, hallBlu;
   wire highGrn, lowGrn,
        highYlw, lowYlw,
        highBlu, lowBlu;

   /*  Inertial-sensor SPI  */
   wire inertSS_n, inertSCLK, inert_MOSI;
   wire inertMISO, inertINT;

   /*  Misc I/O  */
   reg tgglMd;
   wire TX_RX;
   wire [1:0] LED;

   /*  UART monitor  */
   wire       vld_TX;
   wire [7:0] rx_data;

   /*  Analogue / physics stimuli  */
   reg  [11:0] TORQUE, BRAKE, CURR, BATT;
   reg  [15:0] YAW_RT;
   reg cadence;
   
   logic cadence_slow;
   logic cadence_med;
   logic cadence_fast;

   //---------------------------------------------------------------------------
   //  DEVICE UNDER TEST
   //---------------------------------------------------------------------------
   eBike #(.FAST_SIM(1)) DUT (
      .clk       (clk),
      .RST_n     (RST_n),

      // --- ADC SPI master ---
      .A2D_SS_n  (A2D_SS_n),
      .A2D_MOSI  (A2D_MOSI),
      .A2D_SCLK  (A2D_SCLK),
      .A2D_MISO  (A2D_MISO),

      // --- Hall sensors ---
      .hallGrn   (hallGrn),
      .hallYlw   (hallYlw),
      .hallBlu   (hallBlu),

      // --- Gate drives to physics model ---
      .highGrn   (highGrn), .lowGrn(lowGrn),
      .highYlw   (highYlw), .lowYlw(lowYlw),
      .highBlu   (highBlu), .lowBlu(lowBlu),

      // --- Inertial-sensor SPI master ---
      .inertSS_n (inertSS_n),
      .inertSCLK (inertSCLK),
      .inertMOSI (inert_MOSI),
      .inertMISO (inertMISO),
      .inertINT  (inertINT),

      // --- rider inputs ---
      .cadence   (cadence),
      .tgglMd    (tgglMd),

      // --- telemetry & LEDs ---
      .TX        (TX_RX),
      .LED       (LED)
   );

   //---------------------------------------------------------------------------
   //  UART RECEIVER (telemetry monitor)
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
   //  PHYSICS MODEL  – hub motor + inertial sensor stub
   //---------------------------------------------------------------------------
   eBikePhysics u_phys (
      .clk      (clk),
      .RST_n    (rst_n),

      // SPI slave lines
      .SS_n     (inertSS_n),
      .SCLK     (inertSCLK),
      .MOSI     (inert_MOSI),
      .MISO     (inertMISO),
      .INT      (inertINT),

      // yaw-rate stimulus
      .yaw_rt   (YAW_RT),

      // gate drives from DUT
      .highGrn  (highGrn), .lowGrn(lowGrn),
      .highYlw  (highYlw), .lowYlw(lowYlw),
      .highBlu  (highBlu), .lowBlu(lowBlu),

      // hall sensors back to DUT
      .hallGrn  (hallGrn),
      .hallYlw  (hallYlw),
      .hallBlu  (hallBlu),

      // average motor current → ADC model
      .avg_curr (CURR)
   );

   //---------------------------------------------------------------------------
   //  ADC BEHAVIOURAL MODEL (National ADC128S022)
   //---------------------------------------------------------------------------
   AnalogModel u_adc (
      .clk     (clk),
      .rst_n   (RST_n),

      .BATT    (BATT),
      .CURR    (CURR),
      .BRAKE   (BRAKE),
      .TORQUE  (TORQUE),

      .SS_n    (A2D_SS_n),
      .SCLK    (A2D_SCLK),
      .MOSI    (A2D_MOSI),
      .MISO    (A2D_MISO)
   );

   //=====================================================================
   //  STIMULUS SEQUENCE
   //=====================================================================
   initial begin
		/*
	 //---------------- discrete defaults ----------------
      hallGrn = 0; hallYlw = 0; hallBlu = 0;
	  */
      cadence = 0; tgglMd  = 0;
	
      //---------------- analogue defaults ----------------
      initialize(BATT, BRAKE, TORQUE, CURR, YAW_RT);

      //---------------- reset pulse ----------------------
      RST_n = 0; repeat (10) @(posedge clk); RST_n = 1;
      $display("[%0t] TB started", $time);

      repeat (1000) @(posedge clk);   // settle

      //---------------- unit checks ----------------------
      hill_climb(250000, 16'd1500, YAW_RT, clk);   // 5 ms uphill
	  $display("Hi", $time);
      brake_test(100000, BRAKE, clk);              // 2 ms brake
	  $display("[%0t] Unit tests finished", $time);
	  

      //---------------- functional run -------------------
	  
	  //1: Variable terrain with slow cadence and low torque 
         incline_profile(200000, 50000, 200000,
                         16'h2000, 16'hE000,      // up / down rates
                         YAW_RT, clk);
		 set_torque(200000, 12'h300, TORQUE, clk);
		 cadence = cadence_slow;

         assist_cycle(3, 40_000, tgglMd, clk);     // 3 presses ~0.8 ms apart
                                           // wait for both
	  cadence = 1'b0;
	  repeat (1000) @(posedge clk);   // settle
	  $display("[%0t] Functional run 1 finished", $time);
	  
	  //2: Uphill with high torque and fast cadence 
		
		set_torque(200000, 12'h900, TORQUE, clk);			
		cadence = cadence_fast;
		hill_climb(200000, 16'd1500, YAW_RT, clk);
		
		assist_cycle(3, 40_000, tgglMd, clk);				//cycle assist 3 times
		
	  cadence = 1'b0;
	  repeat (1000) @(posedge clk);   // settle
	  $display("[%0t] Functional run 2 finished", $time);
	  
	  //3: Downhill with medium torque and medium cadence
	  	set_torque(200000, 12'h600, TORQUE, clk);			//uphill at a medium cadence
		cadence = cadence_med;
		hill_climb(200000, -16'd1500, YAW_RT, clk);
		
		assist_cycle(3, 40000, tgglMd, clk);				//cycle assist 3 times
	  cadence = 1'b0;
	  repeat (1000) @(posedge clk);   // settle
	  $display("[%0t] Functional run 3 finished", $time);

      //---------------- finish ---------------------------
      repeat (50000) @(posedge clk);
      $display("[%0t] Simulation finished", $time);
      $stop;
   end

   //---------------------------------------------------------------------------
   //  Slow cadence pulse train (≈90 rpm scaled for sim)
   //---------------------------------------------------------------------------
   always begin
      cadence_slow = 1'b0; #(1000);   // 10 µs low
      cadence_slow = 1'b1; #(1000);   // 10 µs high
   end
   
   //---------------------------------------------------------------------------
   // Medium cadence pulse train (≈180 rpm scaled for sim)
   //---------------------------------------------------------------------------
   always begin
      cadence_med = 1'b0; #(500);   // 5 µs low
      cadence_med = 1'b1; #(500);   // 5 µs high
   end
   
   //---------------------------------------------------------------------------
   // Fast cadence pulse train (≈360 rpm scaled for sim)
   //---------------------------------------------------------------------------
   always begin
      cadence_fast = 1'b0; #(250);   // 2 µs low
      cadence_fast = 1'b1; #(250);   // 2 µs high
   end

endmodule
