module inert_intf_test(
    input logic clk,
    input logic RST_n,
    input logic MISO,
    input logic INT,
    output logic SS_n,
    output logic SCLK,
    output logic MOSI,
    output logic [7:0] LED
);

    wire rst_n;
    wire [12:0] incline;
    wire vld;

    reset_synch rst_synch_inst(
        .clk(clk),
        .RST_n(RST_n),
        .rst_n(rst_n)
    );

    inert_intf iDUT(
        .clk(clk),
        .rst_n(rst_n),
        .MISO(MISO),
        .INT(INT),
        .SS_n(SS_n),
        .SCLK(SCLK),
        .MOSI(MOSI),
        .incline(incline),
        .vld(vld)
    );

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            LED <= 8'b0;
        end else begin
            if (vld) begin
                LED <= incline[8:1]; // Display the 8:1 bits of incline on the LED
            end
        end
    end

endmodule