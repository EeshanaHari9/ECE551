module rst_synch(RST_n, clk, rst_n);

input RST_n, clk;
output reg rst_n;
reg reg1;


always@(negedge clk, negedge RST_n)begin;
    if(!RST_n)begin
        reg1 <= 0;
        rst_n <= 0;
    end
    else begin
        reg1 <= 1'b1;
        rst_n <= reg1;
    end
end

endmodule
