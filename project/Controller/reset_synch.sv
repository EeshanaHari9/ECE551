// reset_synch.sv
// Synchronizes an asynchronous active-low external reset signal (`RST_n`) to the
// system clock domain using a simple two-stage flop.
//
// This module prevents metastability by ensuring the internal reset signal (`rst_n`) 
// is safely aligned with `clk` before being propagated to other synchronous logic.
//
// Usage: Feed external push-button or system reset (`RST_n`) into this module to generate 
// a clean, stable `rst_n` for use across the design.
//
// Team VeriLeBron (Dustin, Shane, Quinn, Eeshana)


module reset_synch(RST_n, clk, rst_n);

input logic RST_n, clk;
output logic rst_n;
logic reg1;


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
