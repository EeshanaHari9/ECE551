module mtr_drive(
	input clk,
	input rst_n,
	input [10:0] duty,
	input [1:0] selGrn,
	input [1:0] selYlw,
	input [1:0] selBlu,
	output PWM_synch,
	output highGrn,
	output lowGrn,
	output highYlw,
	output lowYlw,
	output highBlu,
	output lowBlu 

);
	wire PWM_sig;
    	//wire PWM_synch;	

	reg q1Grn,q2Grn;
	reg q1Ylw, q2Ylw;
	reg q1Blu, q2Blu;

	//first call PWM module to take duty and output PWM_synch and PWM_sig
	PWM PWM11 (
		.clk(clk),
		.rst_n(rst_n),
		.duty(duty),
		.PWM_sig(PWM_sig), //output help in wires 
		.PWM_synch(PWM_synch)	//output held in wire 
	);

	//we need values from brushless for selGrn and so on
	//wire [1:0] selGrn;
	//wire [1:0] selYlw;
	//wire [1:0] selBlu;

	//wire [2:0] selGrn_wire,selYlw_wire, selBlu_wire;
/*
	brushless brush(
		.clk(clk),
		.rst_n(rst_n),
    		.duty(duty),
    		.selGrn(selGrn_wire),
    		.selYlw(selYlw_wire),
    		.selBlu(selBlu_wire) 
  	);
*/
	// GREEN LOGIC
	//1st flopper mux for Grn
	always_ff @(posedge clk or negedge rst_n) begin
		if(!rst_n) begin
		//reset logic
			q1Grn <= 1'b0;
		end
		case(selGrn) 
			2'b00: begin
				q1Grn <= 1'b0;
			end

			2'b01: begin
				q1Grn <= ~(PWM_sig);
			end

			2'b10: begin
				q1Grn <= PWM_sig;
			end

			2'b11: begin
				q1Grn <= 1'b0;
			end

		endcase
	end
	//2nd flopper for green repeat this process for Yellow and Blue and well be flying
	always_ff @ (posedge clk or negedge rst_n) begin
		if(!rst_n) begin
		//reset logic
			q2Grn <= 1'b0;
		end
		case(selGrn) 
			2'b00: begin
				q2Grn <= 1'b0;
			end

			2'b01: begin
				q2Grn <= PWM_sig;
			end

			2'b10: begin
				q2Grn <= ~(PWM_sig);
			end

			2'b11: begin
				q2Grn <= PWM_sig;
			end

		endcase
	end


	//YELLOW LOGIC
	//1st flopper mux for Grn
	always_ff @(posedge clk or negedge rst_n) begin
		if(!rst_n) begin
		//reset logic
			q1Ylw <= 1'b0;
		end
		case(selYlw) 
			2'b00: begin
				q1Ylw <= 1'b0;
			end

			2'b01: begin
				q1Ylw <= ~(PWM_sig);
			end

			2'b10: begin
				q1Ylw <= PWM_sig;
			end

			2'b11: begin
				q1Ylw <= 1'b0;
			end

		endcase
	end
	//2nd flopper for green repeat this process for Yellow and Blue and well be flying
	always_ff @ (posedge clk or negedge rst_n) begin
		if(!rst_n) begin
		//reset logic
			q2Ylw <= 1'b0;
		end
		case(selYlw) 
			2'b00: begin
				q2Ylw <= 1'b0;
			end

			2'b01: begin
				q2Ylw <= PWM_sig;
			end

			2'b10: begin
				q2Ylw <= ~(PWM_sig);
			end

			2'b11: begin
				q2Ylw <= PWM_sig;
			end

		endcase
	end

	//BLUE LOGIC
	//1st flopper mux for Grn
	always_ff @(posedge clk or negedge rst_n) begin
		if(!rst_n) begin
			q1Blu <= 1'b0;
		end
		case(selBlu) 
			2'b00: begin
				q1Blu <= 1'b0;
			end

			2'b01: begin
				q1Blu <= ~(PWM_sig);
			end

			2'b10: begin
				q1Blu <= PWM_sig;
			end

			2'b11: begin
				q1Blu <= 1'b0;
			end

		endcase
	end
	//2nd flopper for green repeat this process for Yellow and Blue and well be flying
	always_ff @(posedge clk or negedge rst_n) begin
		if(!rst_n) begin
		//reset logic
			q2Blu <= 1'b0;
		end
		case(selBlu) 
			2'b00: begin
				q2Blu <= 1'b0;
			end

			2'b01: begin
				q2Blu <= PWM_sig;
			end

			2'b10: begin
				q2Blu <= ~(PWM_sig);
			end

			2'b11: begin
				q2Blu <= PWM_sig;
			end

		endcase
	end
	
	//3 non overlap modules at the end 
	nonoverlap NO_OVERLAP_GRN (
		.clk(clk),
		.rst_n(rst_n),
		.highIn(q1Grn),
		.lowIn(q2Grn),
		.highOut(highGrn),
		.lowOut(lowGrn)
	);

	nonoverlap NO_OVERLAP_YLW (
		.clk(clk),
		.rst_n(rst_n),
		.highIn(q1Ylw),
		.lowIn(q2Ylw),
		.highOut(highYlw),
		.lowOut(lowYlw)
	);

	nonoverlap NO_OVERLAP_BLU (
		.clk(clk),
		.rst_n(rst_n),
		.highIn(q1Blu),
		.lowIn(q2Blu),
		.highOut(highBlu),
		.lowOut(lowBlu)
	);
	

endmodule

