module nonoverlap_tb;
    
    	logic clk;
    	logic rst_n;
    	logic highIn;
    	logic lowIn;
    	logic highOut;
    	logic lowOut;

    	// Instantiate the module under test
    	nonoverlap dut (
        	.clk(clk),
        	.rst_n(rst_n),
        	.highIn(highIn),
        	.lowIn(lowIn),
        	.highOut(highOut),
        	.lowOut(lowOut)
    	);

    	// Clock generation (10ns period)
    	always #5 clk = ~clk; 

    	initial begin
        // Initialize signals
        	clk = 0;
        	rst_n = 0;
        	highIn = 0;
        	lowIn = 0;

        	
        	#20 rst_n = 1;

        	//keep inputs low for at least 32 clock cycles
        	repeat (35) #10;

        	//apply high input and check if output follows after 32 cycles
        	highIn = 1;
        	#10;

        	repeat (31) begin
            		#10;
            		if (highOut !== 0) begin
                		$display("FAIL: highOut went high before 32 cycles");
                		$stop;
            		end
        	end

        	#10;
        	if (highOut == 1) 
            		$display("PASS: highOut went high after 32 cycles");
       		else 
            		$display("FAIL: highOut did not go high after 32 cycles");

        	#100;
    
        	//repeat test for low input
        	highIn = 0;
        	#50;
        	lowIn = 1;
        	#10;

        	repeat (31) begin
            		#10;
            		if (lowOut !== 0) begin
                		$display("FAIL: lowOut went high before 32 cycles");
                		$stop;
            		end
        	end

        	#10;
        	if (lowOut == 1) 
            		$display("PASS: lowOut went high after 32 cycles");
        	else 
            		$display("FAIL: lowOut did not go high after 32 cycles");

        	#100;
    
        	//ensure non overlap logic works
        	highIn = 0;
        	lowIn = 0;
        	#50;
        	highIn = 1;
        	lowIn = 1;
        	#10;

        	repeat (31) begin
           		#10;
            		if (lowOut !== 0 || highOut !== 0) begin
                		$display("FAIL: highOut or lowOut went high before 32 cycles");
                		$stop;
            		end
        	end

        	#10;
        	if (lowOut == 0 && highOut == 0) 
            		$display("PASS: stayed low for as long as expected");
        	else 
            		$display("FAIL: Neither outputs should go high");

        	#100;

		//ensure non overlap logic works
        	highIn = 0;
        	lowIn = 0;
        	#50;
        	highIn = 1;
        	lowIn = 0;
        	#300;

		highIn = 1;
        	lowIn = 1;
        	#300;

		#100

		//repeat test for low input
        	highIn = 0;
        	lowIn = 0;
        	#200;

        	//repeat test for low input
        	highIn = 1;
        	#500;
        	lowIn = 0;
        	#60;

		highIn = 1;
		lowIn = 1;
		

        	#800;

		highIn = 0;
		lowIn = 0;

		#50;

		highIn=1;	
		lowIn = 0;

		#400
    
        	$display("Testbench completed successfully");
        	$stop;
    	end
endmodule

