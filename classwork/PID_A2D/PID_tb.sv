
module PID_tb();

    
    reg clk;
    reg rst_n;

    //wires connecting PID and plant
    wire [12:0] error;
    wire not_pedaling;
    wire [11:0] drv_mag;
    wire test_over;

    //clock gen
    initial clk = 0;
    always #10 clk = ~clk; //20 ns period

    //reset szstem
    initial begin
        rst_n = 0;
        #100;
        rst_n = 1;
    end

    //PID istantiation with fast sim high to begin
    PID #(.FAST_SIM(1)) dut (
        .clk(clk),
        .rst_n(rst_n),
        .error(error),
        .not_pedaling(not_pedaling),
        .drv_mag(drv_mag)
    );

    //plant module istantiation
    plant_PID plant (
        .clk(clk),
        .rst_n(rst_n),
        .drv_mag(drv_mag),
        .error(error),
        .not_pedaling(not_pedaling),
        .test_over(test_over)
    );

    //wait for test over to assert and then end test
    initial begin

        wait(test_over);
        $display("Test complete.");
        #100;
        $stop;
    end

endmodule

