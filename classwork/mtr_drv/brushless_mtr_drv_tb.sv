module brushless_mtr_drv_tb();

  /// stimulus declared as type reg;
  reg clk, rst_n;
  reg [11:0] drv_mag;
  reg [2:0] hallStim;	/// {hallGrn,hallYlw,hallBlu} ///
  reg brake_n;
  
  /// internal signals connecting brushless to mtr_drv ///
  wire PWM_synch;
  wire [10:0] duty;
  wire [1:0] selGrn,selYlw,selBlu;
  
  /// mtr_drv output signals being monitored ///
  wire highGrn,lowGrn;
  wire highYlw,lowYlw;
  wire highBlu,lowBlu;
  
  ////////////////////////////////
  // Instantiate brushless DUT //
  //////////////////////////////
  brushless DUT1(.clk(clk),.rst_n(rst_n),.drv_mag(drv_mag),
                 .PWM_synch(PWM_synch),.hallGrn(hallStim[2]),
				 .hallYlw(hallStim[1]),.hallBlu(hallStim[0]),
				 .brake_n(brake_n),.duty(duty),.selGrn(selGrn),
				 .selYlw(selYlw),.selBlu(selBlu));	

  //////////////////////////////
  // Instantiate mtr_drv DUT //
  ////////////////////////////	
  mtr_drive DUT2(.clk(clk),.rst_n(rst_n),.duty(duty),.selGrn(selGrn),
               .selYlw(selYlw),.selBlu(selBlu),.highGrn(highGrn),
			   .lowGrn(lowGrn),.highYlw(highYlw),.lowYlw(lowYlw),
			   .highBlu(highBlu),.lowBlu(lowBlu),.PWM_synch(PWM_synch));
			   
  initial begin
  
 	clk = 0;
    	rst_n = 0;
    	drv_mag = 12'h400;  // Default power level (50%)
    	hallStim = 3'b101;  // Start at a valid Hall state
    	brake_n = 1'b1;  // Normal operation (not braking)

    	// **Assert reset for a few cycles**
    	#20 rst_n = 1;  // Release reset

    	// **Wait for negedge of clock before deasserting reset**
    	@(negedge clk);
    	rst_n = 1; 

    	// **Wait for PWM synchronization signal before changing hall states**
    	@(posedge PWM_synch);
    
    	// **Loop through all valid Hall states (simulate full motor rotation)**
    	repeat (2) begin
        	#50 hallStim = 3'b101; // State 1
        	#50 hallStim = 3'b100; // State 2
        	#50 hallStim = 3'b110; // State 3
        	#50 hallStim = 3'b010; // State 4
        	#50 hallStim = 3'b011; // State 5
        	#50 hallStim = 3'b001; // State 6
    	end

    	// **Test an invalid Hall state (should result in no movement)**
    	#50 hallStim = 3'b000; // Invalid state
    	#50 hallStim = 3'b111; // Another invalid state

    	// **Test braking mode (simulate regenerative braking)**
    	#50 brake_n = 1'b0; // Activate braking
    	#50 brake_n = 1'b1; // Back to normal

    	// **Test different drive magnitudes (simulating speed control)**
   	#50 drv_mag = 12'h200; // Decrease power to 25%
    	#50 drv_mag = 12'h600; // Increase power to 75%
    	#50 drv_mag = 12'h7FF; // Max power close to 100%

    	// **Check behavior when `rst_n` is toggled (reset test)**
    	#50 rst_n = 0;  // Assert reset
    	#50 rst_n = 1;  // Release reset

    	// **End Simulation**
    	#100;
    	$display("Test completed.");

	$stop();
	
  end

  always
    #5 clk = ~clk;  
				 
endmodule