module brushless (
    	input wire clk,		//clk signal	
    	input wire rst_n,	//active low reset
    	input wire [11:0] drv_mag,	//drive magnitude from PID control - how much the motor will assist
    	input wire hallGrn,		//raw hall effect sensors Green (asynch)	
    	input wire hallYlw,		//raw hall effect sensors Yellow (asynch)
    	input wire hallBlu,		//raw hall effect sensors Blue (asynch)
    	input wire brake_n,		//if low activate regenerative braking at 75% duty cycle
    	input wire PWM_synch,		//used to synchrnoise hall reading effect with PWM cycle
    	output reg [10:0] duty,		//Duty cycle to be used for PWM inside mtr_drv - should be 0x400+drv_mag for normal operations and 0x600 when brakes applied 
    	output reg [1:0] selGrn,	//2 bit vector for determining how mtr_drive will drive the FET's
    	output reg [1:0] selYlw,
    	output reg [1:0] selBlu


	/*
	00->HIGH_Z
	01 -> rev_curr 
	10 -> frwd_curr 
	*/
);

    	//sznch to clk signal - flop hall inputs and store in reg
    	reg hallGrn_d, hallYlw_d, hallBlu_d;
	reg hallGrn_meta, hallYlw_meta, hallBlu_meta;
	reg synchGrn, synchYlw, synchBlu;

	//first flop for metastability
	always_ff @(posedge clk or negedge rst_n) begin
		if (!rst_n) begin
			hallGrn_meta <= 1'b0;	// on reset set each meta reg to 0
            		hallYlw_meta <= 1'b0;	// on reset set each meta reg to 0
            		hallBlu_meta <= 1'b0;
		end
		else begin
			hallGrn_meta <= hallGrn;
            		hallYlw_meta <= hallYlw;
            		hallBlu_meta <= hallBlu;
		end
	end	
	//synchrnoise with the clk edge 
	//take in reg from meta flop and pass to next reg hall<>_d
    	always @(posedge clk or negedge rst_n) begin
        	if (!rst_n) begin
            		hallGrn_d <= 1'b0;
            		hallYlw_d <= 1'b0;
            		hallBlu_d <= 1'b0;
        	end 
		else begin
            		hallGrn_d <= hallGrn_meta;
            		hallYlw_d <= hallYlw_meta;
            		hallBlu_d <= hallBlu_meta;
        	end
    	end
    
    	//synch with PWM take in signal from clk synch flop and pass value when PWM synch is high and posedge clk
    	always @(posedge clk or negedge rst_n) begin
        	if (!rst_n) begin	//on reset set all to 0
            		synchGrn <= 1'b0;
            		synchYlw <= 1'b0;
            		synchBlu <= 1'b0;
        	end else if (PWM_synch) begin //when PWM_synch is high pass value from last flop to the next
            		synchGrn <= hallGrn_d;	
            		synchYlw <= hallYlw_d;
            		synchBlu <= hallBlu_d;
        	end
    	end
    
    	//define new wire which will hold the 3 synchronised values and will define the rotation state for the case statements 
    	wire [2:0] rotation_state = {synchGrn, synchYlw, synchBlu};

	always @(posedge clk or negedge rst_n) begin
    		if (!rst_n) 
        		duty <= 11'h400;		// Default to 50% duty cycle
    		else if (!brake_n)
        		duty <= 11'h600;		// Brake mode at 75% duty cycle
    		else if (drv_mag !== 12'bx) // Ensure drv_mag is not undefined
        		duty <= 11'h400 + drv_mag[11:2];
   	 	else
        		duty <= 11'h400;  // Safety fallback to 50% duty cycle
	end

    	//determine coil drive states
	//use table given in brief to understand the definition of each dombination code
    	always @(posedge clk or negedge rst_n) begin
        	if (!rst_n) begin //set all to 0 on reset
            		selGrn <= 2'b00;
            		selYlw <= 2'b00;
            		selBlu <= 2'b00;
        	end else begin
            		case (rotation_state)	//case statement based on the state of the 3 bit vector of coils 
                		3'b101: begin 
					selGrn <= 2'b10; 	//frwd_curr
					selYlw <= 2'b01; 	//rev_curr
					selBlu <= 2'b00; 	//High Z
				end
                		3'b100: begin 
					selGrn <= 2'b10; 	//frwd_curr
					selYlw <= 2'b00;	//High_Z 
					selBlu <= 2'b01; 	//rev_curr 
				end
                		3'b110: begin 
					selGrn <= 2'b00; 	//High_Z
					selYlw <= 2'b10; 	//frwd_curr
					selBlu <= 2'b01; 	//rev_curr 
				end
                		3'b010: begin 
					selGrn <= 2'b01; 	//rev_curr
					selYlw <= 2'b10; 	//for_curr
					selBlu <= 2'b00; 	//High_Z
				end
                		3'b011: begin 
					selGrn <= 2'b01; 	//rev_curr
					selYlw <= 2'b00; 	//High_Z
					selBlu <= 2'b10; 	//frwd_curr
				end	
                		3'b001: begin 
					selGrn <= 2'b00; 	//High_Z
					selYlw <= 2'b01; 	//rev_curr
					selBlu <= 2'b10; 	//frwd_curr
				end
                		default: begin 			//for any other combination set all to 0 (better safe than sorry)
					selGrn <= 2'b00; 	
					selYlw <= 2'b00; 
					selBlu <= 2'b00; 
				end
            		endcase
            
            		//set when user breaks 
            		if (!brake_n) begin
                		selGrn <= 2'b11;
                		selYlw <= 2'b11;
                		selBlu <= 2'b11;
            		end
        	end
    	end
endmodule

