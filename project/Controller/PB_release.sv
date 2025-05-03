module PB_rise(PB, rst_n, clk, released);

input logic PB;
input logic rst_n, clk;
output logic released;

logic ff1_out, ff2_out, ff3_out;

always_ff@(posedge clk, negedge rst_n)
    if(!rst_n)
    ff1_out <= 1;
    else ff1_out <= PB;


always_ff@(posedge clk, negedge rst_n)
    if(!rst_n)
    ff2_out <= 1;
    else ff2_out <= ff1_out;


 always_ff@(posedge clk, negedge rst_n)
    if(!rst_n)
    ff3_out <= 1;
    else ff3_out <= ff2_out;   


assign released = (ff2_out & ~ff3_out);


endmodule