module nonoverlap(highOut, lowOut, highIn, lowIn, clk, rst_n);

	input clk;
	input rst_n;
	input highIn;
	input lowIn;

	output logic highOut;
	output logic lowOut;

	logic highIn_q1;
	logic lowIn_q1;
	logic changed;
	logic [4:0] deadtime;

	//Logic to compare previous and current inputs and make sure they're equals
	//if previous and current value for either input dont match then the changed is asserted
	always_comb begin
   		changed = (lowIn_q1 != lowIn) || (highIn_q1 != highIn);
	end


	always_ff @(posedge clk, negedge rst_n) begin
   		if(!rst_n) begin
     			highOut <= 1'b0;
     			lowOut <= 1'b0;
   		end 
		//whenever the input changes you set outputs to 0 for 32 
		else if (changed) begin 
     			highOut <= 1'b0;
     			lowOut <= 1'b0;
   		//once 32 clk cycles are complete assign input to output
   		end 
		else if(&deadtime) begin
     			highOut <= highIn;
     			lowOut <= lowIn;
   		end 
	end
	//counter logic for nonoverlap
	always_ff @(posedge clk, negedge rst_n) begin
		//on reset set the counter to full 
   		if(!rst_n) begin
     			deadtime <= '1;
   		//If either signal has changed we want to restart counting 32 clk cycles deadtime
   		end 
		//if changed go back to 0 counter
		else if (changed) begin
     			deadtime <= 5'b0;
		//while counter isnt full incrememt
   		end else if (deadtime != '1)
     			deadtime <= deadtime + 5'b1;
		end

		//on reset set flopped input to 0
		always_ff @(posedge clk, negedge rst_n) begin
   			if(!rst_n) begin
      				highIn_q1 <= 1'b0;
      				lowIn_q1 <= 1'b0;
   			end 
			//else load input into flopped reg
			else begin
      				highIn_q1 <= highIn;
      				lowIn_q1 <= lowIn;
   			end
		end

		
  
endmodule
