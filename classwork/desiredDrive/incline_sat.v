/*
if ((number is negative) &&
(any upper bits (in certain range) are zero)) {
saturate to most negative number
}
else if ((number is positive) &&
(any upper bits (in certain range) are one)) {
saturate to most positive number
}
else {
number not too positive so just copy over lower bits
}

*/
module incline_sat(
	input [12:0] incline,
    	output [9:0] incline_sat
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
