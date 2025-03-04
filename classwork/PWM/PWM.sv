module PWM (
	input clk,	
	input rst_n,		//asynch reset
	input [10:0] duty,	//specified duty cycle
	output reg PWM_sig,		//PWM signal out 
	output reg PWM_synch	//when cnt is 11'h001 output a signal to allow commutator to synch PWM


);
	//reg to hold count value 
	reg [10:0] cnt;
	reg [2:0] synch_cnt;
	reg q1;
	//at posedge clock increment counter by 1 - largest value from 11 bit pwm is 2047
	always_ff @(posedge clk or negedge rst_n) begin
		if (!rst_n)
			cnt <= 11'd0;
		else if (cnt == 11'd2047)
			cnt <= 11'd0;
		else 
			cnt <= cnt + 11'd1;
	
	end

	//generate pwm signal
	//comapre cnt with duty input - value is high when duty is greater than cnt - or when PWM_Synch is 1
	always_ff @(posedge clk) begin
		q1 <= (cnt < duty) | (PWM_synch & 1'b1);
	end
	//flop for PWM_sig output to ensure no glitching
	always_ff @(posedge clk) begin
		if (!rst_n)
			PWM_sig <= 1'b0;
		else
			PWM_sig <= q1;
	end
	//when cnt equals 1 set PWM_Synch high for one clk cycle
	always_ff @(posedge clk) begin
		PWM_synch <= (cnt == 11'h001);
	end
	

endmodule
