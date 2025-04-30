module PB_intf(
    input clk,
    input rst_n,
    input tgglMd,
    output reg [2:0] scale,
    output [1:0] LED
);

    reg tgglMd_q;
 

    PB_rise PB_rise(
        .clk(clk),
        .rst_n(rst_n),
        .PB(tgglMd),
        .released(tgglMd_q)
    );

    // State register that cycles through 00->01->10->11
    logic [1:0] setting;

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            setting <= 2'b10;           // power-on default
        else if (tgglMd_q)
            setting <= setting + 2'b01; // advance on button release
    end

    assign LED = setting;

    always_comb begin
        unique case (setting)
            2'b00:  scale = 3'b000;
            2'b01:  scale = 3'b011;
            2'b10:  scale = 3'b101;
            2'b11:  scale = 3'b111;
            default:scale = 3'b101;     // synthesis lint-silencer
        endcase
    end

endmodule