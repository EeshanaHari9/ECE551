module cadence_filt(
    	input clk,        
    	input rst_n,       
    	input cadence,     
    	output reg cadence_filt, 
    	output reg cadence_rise 
);

   
    	
	reg q1,q2,q3,q6; //flip flop registers
    	wire chnged_n; //signal to check if input cadence has changed state (compare past and current value to make sure theyre the same)
    	reg [15:0] counter; //counter to allow 1ms delay
    	wire count_flag;	//flag when counter is full
	//flip flop for metastability
	always_ff @(posedge clk or negedge rst_n) begin 
		if (!rst_n)
			q1 <= 0;
		else 
			q1 <= cadence;
	end

	//first flip flop to store current cadence input
	always_ff @(posedge clk or negedge rst_n) begin 
		if (!rst_n)
			q2 <= 0;
		else 
			q2 <= q1;
	end	
	//second ff to store last cadence input for comparison
	always_ff @(posedge clk or negedge rst_n) begin
		if (!rst_n)
			q3 <= 0;
		else 
			q3 <= q2;
	end


    	//if last value low and curr value is high - rising edge 
    	assign cadence_rise = (q2 & ~q3);

    	//check if both past and curr are the same - stays low or stays high
    	assign chnged_n = (q2 ~^ q3); 
    

    	//counter logic ß if chnged_n is high (both q2 and q3 are both high or both low) increment counter each clock cycle
    	always_ff @(posedge clk or negedge rst_n) begin
        	if (!rst_n)
            		counter <= 16'b0;
        	else if (chnged_n)
            		counter <= counter + 1'b1;
        	else
            		counter <= 16'b0; 
    	end

    	//detect when counter if full - this value is chosen as a 1ms delay with a 50MHz clk is 50000 clock cycles to increment counter
    	assign count_flag = (counter == 16'd50000);

    	//if count flag is high output q3 if not keep looping whats in the flop already
    	wire s1 = count_flag ? q3 : q6;
    	//store value in q6 - either q3 or loop value that was already in flop
	always_ff @(posedge clk or negedge rst_n) begin
        	if (!rst_n)
            		q6 <= 1'b0;
        	else
            		q6 <= s1;
    	end

    	//assign final filtered output
    	always_ff @(posedge clk or negedge rst_n) begin
        	if (!rst_n)
            		cadence_filt <= 1'b0;
        	else
            		cadence_filt <= q6;
    	end

endmodule
