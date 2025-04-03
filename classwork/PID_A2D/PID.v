module PID(
	input clk,
	input rst_n,
	input [12:0] error,
	input not_pedaling,
	output [11:0] drv_mag
);

	reg [17:0] error_ext;
	reg [17:0] error_accum;
	reg [17:0] integrator;
	reg [17:0] error_pos; //ensure value is pos mux
	reg [17:0] error_no_ovfl;
	reg [17:0] error_timed;
	reg [19:0] timer;
	reg [17:0] q1;
	reg [17:0] q2;
	reg done;
	wire pos_ov;

	///P AND I LOGIC ///

	//sign extend error to 18 bits
	//maybe flop this instead but get the gist first!!
	assign error_ext = {5{error[12]},error[12:0]};
	
	

	//feedback adder 
	always_ff @ (posedge clk, negedge rst_n) begin
		if(!rst_n) begin
			error_accum <= 18'h00000;
		end
		else begin
			error_accum <= error_ext + integrator;
		end
	end
	
	
	//mux controlled by MSB of error - if 0 taek current accum val
	//if MSB is 1 reset to 18'h00000
	
	assign error_pos = error_accum[17] ? (18'b00000) : (error_accum[18:0]);

	//logic to determine pos overflow - using bit 17 of adder and and 16 of current accumulator val
	//if pos oveflow is high set to 18'h1FFFF
	//if not take value form last mux
	//if error_pos[17] & integrator[16] pos overflow
	assign pos_ov = error_accum[17] & integrator[16];
	assign error_no_ovfl = pos_ov ? (18'h1FFFF):(error_pos[17:0]);

	//mux to only allow accumulation to occur every 1/48 sec
	//when counter is not high you pass the last output value


	//change timer logic so that whenever all bits are asserted go high
	always_ff @ (posedge clk or negedge rst_n) begin
		if(!rst_n) begin
			timer <= 18'h0; //one reset set timer to 0
		end
		else if (timer == '1) begin //when timer full (all bits asserted) -> assert done so you know you can pass current value
			timer <=18'h0;
			done <= 1;
		end
		else begin
			timer <= timer + 1; //increment timer each clk 
		end
	end

	//mux to determine output with timer
	assign error_timed = done ? (error_no_ovfl):(integrator);

	//not pedaling logic - if low take value from last mux 
	//if high set to 0
	assign q1 = not_pedaling ? (18'h00000):(error_timed);


	//flop value 
	always_ff @(posedge clk, negedge rst_n) begin
		if (!rst_n) begin
			q2 <= 18'h00000;
		end
		else begin
			q2 <= q1;
		end
	end
	
	assign integrator = q2;

	
	/// DECIMATOR ///

	
	

	


endmodule 
