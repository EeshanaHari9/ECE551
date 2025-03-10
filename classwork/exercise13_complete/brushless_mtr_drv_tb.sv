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
  mtr_drv DUT2(.clk(clk),.rst_n(rst_n),.duty(duty),.selGrn(selGrn),
               .selYlw(selYlw),.selBlu(selBlu),.highGrn(highGrn),
			   .lowGrn(lowGrn),.highYlw(highYlw),.lowYlw(lowYlw),
			   .highBlu(highBlu),.lowBlu(lowBlu),.PWM_synch(PWM_synch));
			   
  initial begin
  
 	clk = 0;
    	rst_n = 0;
    	drv_mag = 12'h400;  //default power level
    	hallStim = 3'b101;  //start at a valid hall state
    	brake_n = 1'b1;  //not braking

    	
    	#20 rst_n = 1;  //release reset

    	//at negedge
    	@(negedge clk);
    	rst_n = 1; 

    	//wait for positive edge of PWM_synch
    	@(posedge PWM_synch);
    
    	//loop through different hall states 
    	repeat (2) begin
        	#50 hallStim = 3'b101; // State 1
        	#50 hallStim = 3'b100; // State 2
        	#50 hallStim = 3'b110; // State 3
        	#50 hallStim = 3'b010; // State 4
        	#50 hallStim = 3'b011; // State 5
        	#50 hallStim = 3'b001; // State 6
    	end

    	//test invalid hall states
    	#50 hallStim = 3'b000; //invalid state
    	#50 hallStim = 3'b111; //invalid state

    	//test the brakes
    	#50 brake_n = 1'b0; //activate braking
    	#50 brake_n = 1'b1; //back to normal

    	//different magnitudes of duty
   	#50 drv_mag = 12'h200; //25%
    	#50 drv_mag = 12'h600; //75%
    	#50 drv_mag = 12'h7FF; //100%

    	//check reaction after a reset
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