module cadence_meas (
    	input clk,
    	input rst_n,
    	input cadence_filt,
    	input FAST_SIM,
    	output reg [7:0] cadence_per,
    	output reg not_pedaling
);

    	//constants given as per brief 
    	localparam [23:0] THIRD_SEC_REAL = 24'hE4E1C0;
    	localparam [23:0] THIRD_SEC_FAST = 24'h007271;
    	localparam [7:0]  THIRD_SEC_UPPER = 8'hE4;

    	logic [23:0] THIRD_SEC = (FAST_SIM) ? THIRD_SEC_FAST : THIRD_SEC_REAL;

    	//rising edge logic
    	logic cadence_filt_d, cadence_rise;
	//pass prev value to cadence_filt_d
    	always_ff @(posedge clk or negedge rst_n) begin
        	if (!rst_n)
            		cadence_filt_d <= 1'b0;
        	else
            		cadence_filt_d <= cadence_filt;
    	end
	//if new val is high and prev is low that is a rising edge
    	assign cadence_rise = cadence_filt & ~cadence_filt_d;

    	//counter logic
    	logic [23:0] cadence_count;
    	always_ff @(posedge clk or negedge rst_n) begin
        	if (!rst_n)
            		cadence_count <= 0;
        	else if (cadence_rise)
            		cadence_count <= 0;
        	else if (cadence_count != THIRD_SEC)
            		cadence_count <= cadence_count + 1;
    	end

    	//capture cadence_per val depending on counter val
    	logic [7:0] cadence_per_q;
    	always_ff @(posedge clk or negedge rst_n) begin
        	if (!rst_n)
            		cadence_per_q <= THIRD_SEC_UPPER;
        	else if (cadence_rise)
            		cadence_per_q <= FAST_SIM ? cadence_count[14:7] : cadence_count[23:16];
        	else if (cadence_count == THIRD_SEC)
            		cadence_per_q <= THIRD_SEC_UPPER;
    	end

    	assign cadence_per = cadence_per_q;
    	assign not_pedaling = (cadence_per_q == THIRD_SEC_UPPER);
/*
	//fast sim logic

	generate if (FAST_SIM)
		assign THIRD_SEC = THIRD_SEC_FAST;
	else
		assign THIRD_SEC = THIRD_SEC_REAL;
	endgenerate
*/
endmodule

