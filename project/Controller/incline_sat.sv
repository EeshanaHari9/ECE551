// incline_sat.sv
// Performs 10-bit saturation on a signed 13-bit incline input.
// Prevents out-of-range incline values from skewing the assist computation
// by clipping positive overflow to +511 and negative overflow to -512.
// For non-overflowing inputs, it sign-extends and passes through the value.
//
// This is used in the `desiredDrive` module to safely include incline in the assist
// product calculation, keeping values within a controlled range.
//
// Team VeriLeBron (Dustin, Shane, Quinn, Eeshana)

module incline_sat(
	input logic [12:0] incline,
    	output logic [9:0] incline_sat
);

    	wire ovfl_bits_pos, ovfl_bits_neg;
    	wire [9:0] s1; //wire to output

    
       
    	//Overflow conditions
    	assign ovfl_bits_pos = (incline[11] | incline[10]) & ~incline[12];  //if any of bit [11] or [10] is 1 and sign is 0 (positive number), saturate to max
    	assign ovfl_bits_neg = ~(incline[11] & incline[10]) & incline[12]; //if any of [11] or [10] is 0 and sign is 1 (negative number), saturate to min

   	
    	assign s1 = ovfl_bits_neg ? 10'b1000000000 : 
                       ovfl_bits_pos ? 10'b0111111111 : 
                       {incline[12], incline[8:0]}; //preserve sign for non-saturating values

    

    	assign incline_sat = s1; //assign saturated value to output

endmodule
