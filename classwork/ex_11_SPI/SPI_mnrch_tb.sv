module SPI_mnrch_tb();

 	logic clk, rst_n;
 	logic snd;
 	logic MISO;
 	logic [15:0] cmd;
 	logic SS_n, SCLK, MOSI;
 	logic done;
 	logic [15:0] resp;

	
 	SPI_mnrch SPI_mnrch_tb(
		.clk(clk), 
		.rst_n(rst_n), 
		.SS_n(SS_n), 
		.SCLK(SCLK), 
		.MOSI(MOSI), 
		.MISO(MISO), 
		.snd(snd), 
		.cmd(cmd), 
		.done(done), 
		.resp(resp)
	);

 	ADC128S ADC128S(
		.clk(clk), 
		.rst_n(rst_n), 
		.SS_n(SS_n), 
		.SCLK(SCLK), 
		.MOSI(MOSI), 
		.MISO(MISO)
	);

 	initial begin
  		clk = 1'b0;
  		rst_n = 1'b0;
  		snd = 1'b0;
		//Test 1: Read from channel 1
 		cmd = {2'b00,3'b001,11'h000};
 		@(posedge clk);
 		@(negedge clk);
   		rst_n = 1'b1;   //release reset after 1 clk cycle

 		@(negedge clk); 
   		snd = 1'b1;	//start sending
 		@(negedge clk);
   		snd = 1'b0;	//set back to 0
 		@(posedge done);	//wait until done is asserted
   		if (resp !== 16'h0C00) begin //check against expected response
    			$display("TEST FAILED: response should be 16'h0C00, resp = %b",resp);	
    			$stop();
   		end 
		else
    			$display("PASSED:YIPPEE");

		//Test 2: Read from channel 1 again
 		cmd = {2'b00,3'b001,11'h000};
 		@(posedge clk);
 		@(negedge clk);
   		snd = 1'b1;
 		@(negedge clk);
   		snd = 1'b0;
 		@(posedge done);
   		if (resp !== 16'h0C01) begin
    			$display("TEST FAILED: response should be 16'h0C00, resp = %b",resp);
    			$stop();
   		end 
		else
    			$display("Test 2: im allowed have a coke zero now");

		//Test 3: Read from channel 4
 		cmd = {2'b00,3'b100,11'h000};
 		@(posedge clk);
 		@(negedge clk);
   		snd = 1'b1;
 		@(negedge clk);
   		snd = 1'b0;
 		@(posedge done);
   		if (resp !== 16'h0BF1) begin
    			$display("TEST FAILED: response should be 16'h0C00, resp = %b",resp);
    			$stop();
   		end 
		else
    			$display("Test Passed Banny");

		//Test 4: Read from channel 4 again
 		cmd = {2'b00,3'b100,11'h000};
 		@(posedge clk);
 		@(negedge clk);
   		snd = 1'b1;
 		@(negedge clk);
   		snd = 1'b0;
 		@(posedge done);
   		if (resp !== 16'h0BF4) begin
    			$display("TEST FAILED: response should be 16'h0C00, resp = %b",resp);
    			$stop();
   		end else
    			$display("TEST PASSED");
    			$stop();
   		end

 		always #5 clk = ~clk; 

endmodule
