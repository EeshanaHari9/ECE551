module desiredDrive(
    	input [11:0] avg_torque,
    	input [4:0] cadence,
    	input not_pedaling,
    	input [12:0] incline,
    	input [2:0] scale,
    	output reg [11:0] target_curr
);
    	wire [9:0] incline_sat;
    	wire [10:0] incline_factor; 	//saturation of incline input
    	wire [8:0] incline_lim;		
    	wire [6:0] cadence_factor;	//ask bit width for this
	wire [12:0] torque_off;
	wire [11:0] torque_pos;
	wire [29:0] assist_prod;
	wire ovfl_bits_pos, ovfl_bits_neg;
    
    
    	//local param for torque
    	localparam [11:0] TORQUE_MIN = 12'h380;  

    	//instantiate incline saturation module to get 10 bit saturation
	incline_sat sat1(.incline(incline), .incline_sat(incline_sat));
	//sign extend by 1 bit - take MSB and copy and then add 256 to value
	assign incline_factor = {incline_sat[9], incline_sat[9:0]}+{11'd256};
	
	
	//create a 9 bit number that clips incline factor
	
    	// Overflow conditions
    	assign ovfl_bits_pos = (incline_factor[9]) & ~incline_factor[10];  
	assign ovfl_bits_neg = ~(incline_factor[9] & incline_factor[8]) & incline_factor[10];
	
	
	assign incline_lim = incline_factor[10] ? 9'b000000000 : 
                     ovfl_bits_pos ? 9'b111111111 : 
                     {incline_factor[8], incline_factor[7:0]};
	//if MSB is 1 its neg so set to 0
	//if MSB is 0 add 32 decimal 
	assign cadence_factor = (|cadence[4:1]) ? (cadence + 6'd32) : 6'b000000;
	//assign cadence_factor = (|cadence[4:1]) ? (cadence + 6'd32) : 7'd0;
	//extend each by 1 0 bit and then subtract TORQUE MIN
	assign torque_off = ({1'b0, avg_torque}) - ({1'b0,TORQUE_MIN});
	//Sign check - if negative set to 0 - if mot drop sign bit and keep the rest as we know its positive
	assign torque_pos = (torque_off[12]) ? 12'b000000000000 : torque_off[11:0];

	//Compute assist product (set to zero if not pedaling)
    	assign assist_prod = not_pedaling ? 30'b0 : (torque_pos * incline_lim * cadence_factor * scale);

	//compute target current - if bit 29, 28 or 27 are high set current to FFF and if none are high take bits 26 to 16
    	always @(*) begin
		target_curr = (assist_prod[29]|assist_prod[28]|assist_prod[27]) ? (12'hFFF):(assist_prod[26:15]);
    	end

	
endmodule
