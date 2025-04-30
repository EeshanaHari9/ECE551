module sensorCondition #(parameter FAST_SIM = 1) (
    input  clk,
    input  rst_n,
    input  [11:0] torque,
    input  cadence_raw,
    input  [11:0] curr,
    input  [12:0] incline,
    input  [2:0]  scale,
    input  [11:0] batt,
    output reg [12:0] error,
    output not_pedaling,
    output TX
);

    localparam [11:0] LOW_BATT_THRES = 12'hA98;

    reg cadence_filt, cadence_rise;
    //cadence filter instantiation
     cadence_filt #(.FAST_SIM(FAST_SIM)) u_filt (
        .clk(clk),
        .rst_n(rst_n),
        .cadence(cadence_raw),
        .cadence_filt(cadence_filt),
        .cadence_rise(cadence_rise)
    );
	
    //cadence measure and not pedaling logic
    reg [7:0] cadence_per;

    cadence_meas #(.FAST_SIM(FAST_SIM)) u_meas (
        .clk(clk),
        .rst_n(rst_n),
        .cadence_filt(cadence_filt),
        //.FAST_SIM(FAST_SIM),
        .cadence_per(cadence_per),
        .not_pedaling(not_pedaling)
    );

    //cadence_LU instantiation
    logic [4:0] cadence;

    cadence_LU u_LU (
        .cadence_per(cadence_per),
        .cadence(cadence)
    );


    //exponential everage for current

    reg [13:0] curr_accum;
    reg [11:0] avg_curr;
    reg [21:0] curr_timer;

    wire include_curr = (FAST_SIM) ? (&curr_timer[15:0]) : curr_timer[21];
    //timer counter 
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            curr_timer <= 1'b0;
        end
        else begin
            curr_timer <= curr_timer + 1'b1;
        end
    end

    always_ff @(posedge clk or negedge rst_n) begin
        if(!rst_n) begin
            curr_accum <= 1'b0;
        end
        else if (include_curr) begin
            curr_accum <= (curr_accum * 3 >> 2) + curr;
        end
    end

    assign avg_curr = curr_accum[13:2];

    //exponential average for torquew
    reg [16:0] torque_accum;
    reg [11:0] avg_torque;
    reg not_pedaling_torque;
    wire pedaling_start;

    assign pedaling_start = not_pedaling_torque & (~not_pedaling); 

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            torque_accum <= 1'b0;
            not_pedaling_torque <= 1'b1;
        end
        else begin
            not_pedaling_torque <= not_pedaling;
	
            if (pedaling_start) begin
                torque_accum <= {1'b0,torque,4'b0};
	    end
            else if (cadence_rise) begin
                torque_accum <= ((torque_accum * 31) >> 5) + torque;
	    end
	
        end
    end
/*
	always_ff @(posedge clk or negedge rst_n) begin
		if (pedaling_start) begin
                	torque_accum <= {1'b0,torque,4'b0};
	    	end
            	else if (cadence_rise) begin
                	torque_accum <= ((torque_accum * 31) >> 5) + torque;
	    	end
	end
*/

    assign avg_torque = torque_accum[16:5];

    reg [11:0] target_curr;

    desiredDrive desiredDrive (
        .avg_torque(avg_torque),
        .cadence(cadence),
        .not_pedaling(not_pedaling),
        .incline(incline),
        .scale(scale),
        .target_curr(target_curr)
    );

    //error logic
    always_comb begin
        if (batt < LOW_BATT_THRES || not_pedaling)
            error = 13'd0;
        else
            error = $signed(target_curr) - $signed(avg_curr);
    end

    //=== Telemetry ===//
    logic tx_done;

    telemetry u_tel (
        .clk(clk),
        .rst_n(rst_n),
        .batt_v(batt),
        .avg_curr(avg_curr),
        .avg_torque(avg_torque),
        .TX(TX)
    );



endmodule