// PWM.sv
// Generates a glitch-free PWM signal (`PWM_sig`) with a specified duty cycle,
// and emits a single-cycle synchronization pulse (`PWM_synch`) once per PWM cycle.
//
// Features:
// - 11-bit internal counter (0 to 2047) gives fine-grained duty control
// - `PWM_sig` is high when the counter is less than the input `duty`
// - `PWM_synch` pulses high when the counter equals 1, used by commutation logic
//   (e.g., brushless.sv) to align switching with the PWM cycle
// - Fully glitch-free through flopped logic (`q1`, `PWM_sig`)
//
// Used within `mtr_drv.sv` to generate PWM waveforms for FET drivers.
//
// Team VeriLeBron (Dustin, Shane, Quinn, Eeshana)


module PWM (
	input logic clk,	
	input logic rst_n,		//asynch reset
	input logic [10:0] duty,	//specified duty cycle
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
