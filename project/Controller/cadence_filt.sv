module cadence_filt #(
    parameter FAST_SIM = 1
)(
    input  logic clk,
    input  logic rst_n,
    input  logic cadence,
    output logic cadence_filt,
    output logic cadence_rise
);

    logic q1, q2, q3, q6;
    logic [15:0] counter;
    wire chnged_n;
    wire count_flag;

    // Flip-flop chain for metastability and edge detection
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) q1 <= 1'b0;
        else        q1 <= cadence;
    end

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) q2 <= 1'b0;
        else        q2 <= q1;
    end

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) q3 <= 1'b0;
        else        q3 <= q2;
    end

    assign cadence_rise = q2 & ~q3;
    assign chnged_n = (q2 ~^ q3);  // same state = stable

    // Counter for stability window
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) counter <= 16'd0;
        else if (chnged_n) counter <= counter + 1;
        else counter <= 16'd0;
    end

    // FAST_SIM-dependent count_flag logic
    //assign count_flag = FAST_SIM ? (&counter[8:0]) : (counter == 16'd50000);
    assign count_flag = FAST_SIM ? (counter[4:0]) : (counter == 16'd50000);
    // Debounce logic
    wire s1 = count_flag ? q3 : q6;

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) q6 <= 1'b0;
        else        q6 <= s1;
    end

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) cadence_filt <= 1'b0;
        else        cadence_filt <= q6;
    end

endmodule
