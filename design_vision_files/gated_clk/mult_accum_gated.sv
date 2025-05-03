module mult_accum_gated(clk, clr, en, A, B, accum);

    input clk, clr, en;
    input  [15:0] A, B;
    output reg [63:0] accum;

    //register to hold the product of A and B, same width as original (32-bit).
    reg [31:0] prod_reg;


    //latch the en signal so there is always a for the gated clk
    reg clk_en_lat;
    always begin
        if (~clk)
            clk_en_lat <= en;
    end

      //AND clk and enable as per diagram - this will serve as the input to the gated clock
    wire gated_clk;
    assign gated_clk = clk & clk_en_lat;

    ///////////////////////////////////////////
    // Generate and flop product if enabled //
    /////////////////////////////////////////
    always_ff @(posedge gated_clk) begin
        if (clk_en_latch)
            prod_reg <= A*B;
    end

    //accum is triggered by posedge gated_clk
    always_ff @(posedge gated_clk or clr) begin
        if (clr)
            accum <= 64'h0000000000000000;
        else
            accum <= accum + prod_reg;
    end





endmodule
