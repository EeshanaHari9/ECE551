module PB_release (
    	input  wire clk,     //clock
    	input  wire rst_n,   //asynch negedge reset
    	input  wire PB,      //push button input
    	output wire released //output to let you know when a button has been released
);

   	reg q0, q1, q2;
	//double flop for metastability and then last flop is for rising edge detection
   	always @(posedge clk or negedge rst_n) begin
      		if (!rst_n) begin
         		q0 <= 1'b0;
         		q1 <= 1'b0;
         		q2 <= 1'b0;
      		end
      		else begin
         		q0 <= PB;      ////take in push button input
         		q1 <= q0;      //second flop for safety
         		q2 <= q1;      //edge detection
      		end
   	end

   	//q1=1 and q2=0 means there is a rising edge because you are comparing the last value with the current
   	assign released = (q1 & ~q2);

endmodule
