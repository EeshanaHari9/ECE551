// sensorCondition.sv
// Performs signal conditioning for various sensor inputs used in e-bike control logic,
// including torque, cadence, current, and battery voltage. This module computes
// key metrics such as filtered cadence, exponential averages for current and torque,
// and an `error` signal to drive the PID controller.
//
// Features:
// - Debounces and filters raw cadence input (via `cadence_filt`)
// - Measures time between pedal strokes to detect pedaling vs coasting
// - Smooths motor current and torque input using exponential averaging
// - Computes a target current based on rider effort, incline, and scale
// - Outputs the error signal: target current - average current (only if pedaling & battery OK)
// - Drives UART telemetry with battery, torque, and current information
//
// Also supports FAST_SIM mode to accelerate simulation via reduced timer windows.
//
// Team VeriLeBron (Dustin, Shane, Quinn, Eeshana)


module sensorCondition #(parameter FAST_SIM = 0)
(
    input logic  clk,
    input logic  rst_n,
    input logic  [11:0] torque,
    input logic  cadence_raw,
    input logic  [11:0] curr,
    input logic  [12:0] incline,
    input logic  [2:0]  scale,
    input logic  [11:0] batt,
    output reg [12:0] error,
    output logic not_pedaling,
    output logic TX
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
            curr_accu m <= (curr_accum * 3 >> 2) + curr;
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