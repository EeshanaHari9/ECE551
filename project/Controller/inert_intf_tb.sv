module inert_intf_tb();

    reg clk;
    reg RST_n;
    
    wire SS_n;
    wire SCLK;
    reg MISO;
    wire MOSI;

    reg INT;

    wire rst_n;
    wire [12:0] incline;
    wire vld;

    wire [7:0] LED;

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

    initial begin
        clk = 0;
        RST_n = 0;
        MISO = 1'b0;
        INT = 1'b0;

        repeat (10) @(posedge clk);
        RST_n = 1; // Release reset

        MISO = 1'b1;
        @(posedge clk);

        repeat (67300) @(posedge clk);
        INT = 1'b1; // Simulate interrupt signal

        repeat (15000) @(posedge clk);

        INT = 1'b0; // Simulate interrupt signal

        repeat (4353) @(posedge clk);

        $stop;
    end

    always #5 clk = ~clk;

endmodule