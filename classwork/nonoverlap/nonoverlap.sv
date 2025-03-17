module nonoverlap (
    	input logic clk,     
    	input logic rst_n,   
    	input logic highIn,  
    	input logic lowIn,   
    	output logic highOut, 
    	output logic lowOut  
);

    	typedef enum logic [1:0] {IDLE, WAIT, CNT_32, OUT_STATE} state_t; 
    	state_t state, next_state;

    	logic highIn_curr, highIn_prev; //use for flip flop reg's holds previous value inputted
    	logic lowIn_curr, lowIn_prev;	//use for flip flop reg's holds previous value inputted
    	logic [4:0] cnt;		//counter reg to iterate to 32 - account for state changes as they are one clock cycle
    	logic changed;			//flag for changed input

    	//flop for highIn to reduce metastability
    	always_ff @(posedge clk or negedge rst_n) begin
        	if (!rst_n)
            		highIn_curr <= 0;
        	else 
            		highIn_curr <= highIn;
    	end

    	//flop for previous value of highIn
    	always_ff @(posedge clk or negedge rst_n) begin
        	if (!rst_n)
            		highIn_prev <= 0;
        	else 
            		highIn_prev <= highIn_curr;
    	end

    	// Flop for lowIn to reduce metastability
    	always_ff @(posedge clk or negedge rst_n) begin
        	if (!rst_n)
            		lowIn_curr <= 0;
        	else 
            		lowIn_curr <= lowIn;
    	end

    	//flop for previous value of lowIn
    	always_ff @(posedge clk or negedge rst_n) begin
        	if (!rst_n)
            		lowIn_prev <= 0;
        	else 
            		lowIn_prev <= lowIn_curr;
    	end
	
	logic highChanged, lowChanged;

	assign highChanged = (highIn_prev != highIn_curr);
	assign lowChanged = (lowIn_prev != lowIn_curr);

    	//change detection logic - compare current and previous value to see if theyre different
    	always_ff @(posedge clk or negedge rst_n) begin
        	if (!rst_n)
            		changed <= 0;
       	 	else 
            		changed <=  highChanged | lowChanged;
    	end
	
    	//FSM change state logic at each posedge of clock change load new state value
    	always_ff @(posedge clk or negedge rst_n) begin
       		if (!rst_n) 
            		state <= IDLE;
        	else 
            		state <= next_state;
    	end

    	always_comb begin
        	case (state)
            		IDLE:   	//stay in IDLE until change it detected 
                		if (changed)  
                    			next_state = WAIT;	//once change is detected change state to wait 
                		else 
                    			next_state = IDLE;  

            		WAIT: 	//use this state to ensure no other change has occured in the next clock cycle - makes sure no glitches
                		if (changed)  
                    			next_state = WAIT;
                		else
                    			next_state = CNT_32;  //if change is low go to CNT_32 to start counter

            		CNT_32:  
                		if (cnt == 27)  //counter val changed to 27 to account for states taking up a clk cycle and metastability flops
                   			next_state = OUT_STATE;

				else if (changed) 
					next_state = IDLE;
                		else 
                    			next_state = CNT_32; //until counter is full 

            		OUT_STATE:	//if output changes go to IDLE
                		if (changed)
                    			next_state = IDLE;
               			else
                    			next_state = OUT_STATE;	//until change it detected stay in the out state

            		default: 
                	next_state = IDLE;
        	endcase
    	end

    	//counter logic
    	always_ff @(posedge clk or negedge rst_n) begin
        	if (!rst_n) 
            		cnt <= 0;
        	else if (state == WAIT)  //keep count at 0 when in WAIT stage
            		cnt <= 0;
        	else if (state == CNT_32)	//once in count stage begin counter - this is the way the logic is set up so the 
            		cnt <= cnt + 1;
		else if (changed)
			cnt <= 0;
        	else  
            		cnt <= 0;		//keep at 0 otherwise
    	end

    	//0utput logic
    	always_ff @(posedge clk or negedge rst_n) begin
    		if (!rst_n) begin	//active reset low set outputs to 0 when reset low
        		highOut <= 0;
        		lowOut <= 0;
    		end 
		
		//logic for output - stop overlap
		else if (state == OUT_STATE) begin
        		if (highIn_curr && !lowIn_curr) begin	//if high highIn and low lowIn -> let highIn be high
            			highOut <= 1;
            			lowOut <= 0;
        		end 
			else if (!highIn_curr && lowIn_curr) begin	//if high lowIn and low highIn -> let lowIn be high
            			highOut <= 0;
            			lowOut <= 1;
        		end 
			else begin
            			highOut <= 0;
            			lowOut <= 0;  // Ensures mutual exclusivity
        		end
    		end

		else if (state == WAIT || state == CNT_32) begin	//in state WAIT OR CNT_32 keep outputs low
        		highOut <= 0;
        		lowOut <= 0;
    		end 
	end

endmodule
