 module eBike(clk,RST_n,A2D_SS_n,A2D_MOSI,A2D_SCLK,
             A2D_MISO,hallGrn,hallYlw,hallBlu,highGrn,
			 lowGrn,highYlw,lowYlw,highBlu,lowBlu,
			 inertSS_n,inertSCLK,inertMOSI,inertMISO,
			 inertINT,cadence,TX,tgglMd,LED);
			 
  parameter FAST_SIM = 1;		// accelerate simulation by default

  input clk;				// 50MHz clk
  input RST_n;				// active low RST_n from push button
  output A2D_SS_n;			// Slave select to A2D on DE0
  output A2D_SCLK;			// SPI clock to A2D on DE0
  output A2D_MOSI;			// serial output to A2D (what channel to read)
  input A2D_MISO;			// serial input from A2D
  input hallGrn;			// hall position input for "Green" phase
  input hallYlw;			// hall position input for "Yellow" phase
  input hallBlu;			// hall position input for "Blue" phase
  output highGrn;			// high side gate drive for "Green" phase
  output lowGrn;			// low side gate drive for "Green" phase
  output highYlw;			// high side gate drive for "Yellow" phase
  output lowYlw;			// low side gate drive for "Yellow" phas
  output highBlu;			// high side gate drive for "Blue" phase
  output lowBlu;			// low side gate drive for "Blue" phase
  output inertSS_n;			// Slave select to inertial (tilt) sensor
  output inertSCLK;			// SCLK signal to inertial (tilt) sensor
  output inertMOSI;			// Serial out to inertial (tilt) sensor  
  input inertMISO;			// Serial in from inertial (tilt) sensor
  input inertINT;			// Alerts when inertial sensor has new reading
  input cadence;			// pulse input from pedal cadence sensor
  input tgglMd;				// used to select setting[1:0] (from PB switch)
  output TX;				// serial output of measured batt,curr,torque
  output [1:0] LED;			// Lower 2-bits of LED (setting) 11 => easy, 10 => medium, 01 => hard, 00 => off
  
  ////////////////////////////////////////////
  // Declare internal interconnect signals //
  //////////////////////////////////////////
  wire rst_n;									// global reset from reset_synch
  
  wire signed [12:0] error;
  wire cadence;
  wire not_pedaling;
  wire [10:0] duty;
  wire [1:0] selGrn, selYlw, selBlu;
  wire signed [12:0] incline;
  wire [11:0] drv_mag;
  wire brake_n;
  wire PWM_synch;
  wire [2:0] scale;
  
  ////////////////////////////////////////////////////////
  // Brake lever input is converted as analog, but     //
  // treated as digital (if below mid rail it is low) //
  /////////////////////////////////////////////////////
  assign brake_n = (brake<12'h800) ? 1'b0 : 1'b1;
	
  /////////////////////////////////////
  // Instantiate reset synchronizer //
  ///////////////////////////////////
  <instantiate reset_synch>
  //pretty sure this is already made
    reset_synch reset_synch(
                .clk(clk),
                .rst_n(RST_n),
                .rst_n_out(rst_n)
            );

  ///////////////////////////////////////////////////////
  // Instantiate A2D_intf to read torque & batt level //
  /////////////////////////////////////////////////////
  //pass these onto the sensorCondition module
  wire [11:0] torque, batt, curr, brake;		// Raw A2D results

  //<instantiate A2D_intf>
  A2D_intf A2D_intf(
            .clk(clk),
            .rst_n(rst_n),
            .A2D_SS_n(A2D_SS_n),
            .A2D_SCLK(A2D_SCLK),
            .A2D_MOSI(A2D_MOSI),
            .A2D_MISO(A2D_MISO),
            .torque(torque), //this is the torque value from the A2D converter
            .batt(batt), //this is the battery voltage from the A2D converter
            .curr(curr), //this is the current from the A2D converter
            .brake(brake) //this is the brake lever value from the A2D converter
        );
				 
  ////////////////////////////////////////////////////////////
  // Instantiate SensorCondition block to filter & average //
  // readings and provide cadence_vec, and zero_cadence   //
  /////////////////////////////////////////////////////////
  //<instantiate sensorCondition> (include FAST_SIM)
  //exercise 22 -> make into one module 
    sensorCondition sensorCondition #(paramater FAST_SIM = 1)(
            .clk(clk),
            .rst_n(rst_n),
            .torque(torque), //comes from A2D_intf
            .cadence_raw(cadence), //comes from cadence sensor
            .curr(curr), //comes from A2D_intf
            .incline(incline), //comes from inertial sensor
            .scale(scale), //comes from PB_intf
            .batt(batt), //comes from A2D_intf
            .error(error), //this is the error value from the PID controller
            .not_pedaling(not_pedaling), //this is the not pedaling value from the cadence sensor
            .TX(TX) //this is the TX value from the PB_intf
    );
					   
  ///////////////////////////////////////////////////
  // Instantiate PID to determine drive magnitude //
  /////////////////////////////////////////////////		   
 // <instantiate PID> (include FAST_SIM)
    PID PID(
            .clk(clk),
            .rst_n(rst_n),
            .error(/*not sure yet*/),
            .not_pedalling(/*not sure yet*/),
            .drv_mag(drv_mag)
        
    );
  ////////////////////////////////////////////////
  // Instantiate brushless DC motor controller //
  //////////////////////////////////////////////
  //<instantiate brushless>
  brushless brushless(
            .clk(clk),
            .rst_n(rst_n),
            .drv_mag(drv_mag),
            .hallGrn(/*not sure yet (comes from BLDC motor)*/),
            .hallYlw(/*not sure yet (comes from BLDC motor)*/),
            .hallBlu(/*not sure yet (comes from BLDC motor)*/),
            .brake_n(brake_n), //this signal will come from A2D_intf?
            //look back at the mtr_drv and brishless connection exercise for this one
            .PWM_synch(PWM_synch), //this signal will come from the PWM module -> remember how mtr_drv and brushless connected to eachother
            .duty(duty), //this signal will come from the PWM module -> remember how mtr_drv and brushless connected to eachother
            .selGrn(selGrn), //this signal will come from the PWM module -> remember how mtr_drv and brushless connected to eachother
            .selYlw(selYlw), //this signal will come from the PWM module -> remember how mtr_drv and brushless connected to eachother
            .selBlu(selBlu) //this signal will come from the PWM module -> remember how mtr_drv and brushless connected to eachother
        );
  ///////////////////////////////
  // Instantiate motor driver //
  /////////////////////////////
  <instantiate mtr_drv>
  mtr_drv mtr_drv(
            .clk(clk),
            .rst_n(rst_n),
            .duty(duty), //this signal will come from the PWM module -> remember how mtr_drv and brushless connected to eachother
            .selGrn(selGrn), //this signal will come from the PWM module -> remember how mtr_drv and brushless connected to eachother
            .selYlw(selYlw), //this signal will come from the PWM module -> remember how mtr_drv and brushless connected to eachother
            .selBlu(selBlu), //this signal will come from the PWM module -> remember how mtr_drv and brushless connected to eachother
            .PWM_synch(PWM_synch), //this signal will come from the PWM module -> remember how mtr_drv and brushless connected to eachother
            .highGrn(highGrn), //this signal will come from the PWM module -> remember how mtr_drv and brushless connected to eachother
            .lowGrn(lowGrn), //this signal will come from the PWM module -> remember how mtr_drv and brushless connected to eachother
            .highYlw(highYlw), //this signal will come from the PWM module -> remember how mtr_drv and brushless connected to eachother
            .lowYlw(lowYlw), //this signal will come from the PWM module -> remember how mtr_drv and brushless connected to eachother
            .highBlu(highBlu), //this signal will come from the PWM module -> remember how mtr_drv and brushless connected to eachother
            .lowBlu(lowBlu) //this signal will come from the PWM module -> remember how mtr_drv and brushless connected to eachother
        );
  /////////////////////////////////////////////////////////////
  // Instantiate inertial sensor to measure incline (pitch) //
  ///////////////////////////////////////////////////////////
  <instantiate inert_intf>
				//exercise 22 	
  /////////////////////////////////////////////////////////////////
  // Instantiate PB_intf block to establish setting/LED & scale //
  ///////////////////////////////////////////////////////////////
  <instantiate PB_intf>
  //havent a clue where this is 

endmodule
