module ring_osc_tb();

	logic EN; 	//Enable Signal
	logic OUT; 	//Output signal
	ring_osc iDUT(
		.EN(EN),
		.OUT(OUT)
		
	);

	initial begin
		EN = 0;
		#15;
		EN = 1;
		#100;
	
		$finish;

	end
endmodule
	




