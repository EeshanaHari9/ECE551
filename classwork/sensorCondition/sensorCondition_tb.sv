`timescale 1ns/1ps

module sensorCondition_tb;

    logic clk, rst_n;
    logic [11:0] torque, curr;
    logic [12:0] incline;
    logic [2:0]  scale;
    logic [11:0] batt;
    logic        cadence_raw;
    logic [12:0] error;
    logic        not_pedaling, TX;

    // Clock generation (100MHz)
    always #5 clk = ~clk;

    // DUT
    sensorCondition #(.FAST_SIM(1)) dut (
        .clk(clk), 
	.rst_n(rst_n),
        .torque(torque), 
	.cadence_raw(cadence_raw),
        .curr(curr), 
	.incline(incline), 
	.scale(scale), 
	.batt(batt),
        .error(error), 
	.not_pedaling(not_pedaling), 
	.TX(TX)
    );

    initial begin
        

	 //initial value same as 
        clk = 0;
        rst_n = 0;
        torque = 12'h0;       // matches target waveform
        curr   = 12'h3FF;
        incline = 13'd0;
        scale = 3'd3;
        batt = 12'hFFF;
        cadence_raw = 0;

	#400;
	//set reset back to 1
        #20 rst_n = 1;

        //initial value same as 
        //clk = 0;
        //rst_n = 0;
        torque = 12'h2FF;       // matches target waveform
        curr   = 12'h3FF;
        incline = 13'd0;
        scale = 3'd3;
        batt = 12'hFFF;
        //cadence_raw = 0;

        

        //simulate fast pedaling, cadence_raw val iterates quickly
        repeat (10000000) begin
            #500 cadence_raw = 1;
            #500 cadence_raw = 0;
        end

        // Wait to observe exponential average behavior
        #50000;

        $finish;
    end

endmodule

