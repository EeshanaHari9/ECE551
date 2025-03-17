module reset_synch (
    	input  wire RST_n,  //aynch low reset
    	input  wire clk,    //clk
    	output wire rst_n   //reset
);

   	
   	reg r0, r1;

   	//two flops for metastability
   	always @(negedge clk or negedge RST_n) begin
      		if (!RST_n) begin
         		r0 <= 1'b0;
         		r1 <= 1'b0;
      		end
      		else begin
         		r0 <= 1'b1;
         		r1 <= r0;
      		end
   	end

   	//assign to r1 to ensure it takes the value once its gone through each flop
   	assign rst_n = r1;

endmodule
