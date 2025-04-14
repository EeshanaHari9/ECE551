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