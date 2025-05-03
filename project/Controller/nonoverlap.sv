// nonoverlap.sv
// Ensures safe switching between high-side and low-side FETs on a motor leg by
// enforcing a dead time whenever input signals change. This prevents shoot-through
// conditions by delaying the propagation of changes to gate drive outputs.
//
// The module monitors `highIn` and `lowIn` for changes. When a change is detected,
// it resets an internal 5-bit counter and holds both outputs (`highOut`, `lowOut`) low
// until 32 clock cycles of stability have passed. Once the dead time elapses without
// further changes, outputs are allowed to follow their respective inputs.
//
// This module is used in `mtr_drv.sv` to apply non-overlap protection between
// high-side and low-side gate signals for each motor phase.
//
// Team VeriLeBron (Dustin, Shane, Quinn, Eeshana)

module nonoverlap(clk, rst_n, highIn, lowIn, highOut, lowOut);

 input logic clk, rst_n, highIn, lowIn;
 output logic highOut, lowOut;

 logic [4:0] dead_t; //the counter
 logic changed;//whether hignin or lowin changed
 logic det_highIn, det_lowIn;//the highIn & lowIn after a flop

//detect whether hignin or lowin changed
 always_ff @ (posedge clk) begin
   det_highIn <= highIn;
   det_lowIn <= lowIn;
 end
 assign changed = (det_highIn ^ highIn) | (det_lowIn ^ lowIn);//whether hignin or lowin changed, changed will be 1

//the counter 
 always_ff @ (posedge clk)begin
   if(changed)
      dead_t <= 5'b00000;//if the input changed, the counter will be cleared
   else if(dead_t !== 5'b11111)
      dead_t <= dead_t + 1;
   end

//the output
 always_ff @ (posedge clk, negedge rst_n) begin
   if (!rst_n) begin
     highOut <= 1'b0;
     lowOut <= 1'b0;//asynch reset
   end else if(dead_t == 5'b11111) begin
     highOut <= highIn;
     lowOut <= lowIn;//after 32 clocks, output was allowed to get input
   end else begin
     highOut <= 1'b0;
     lowOut <= 1'b0;//or the output will be force low
   end
 end
endmodule