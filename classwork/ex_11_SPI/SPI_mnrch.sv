module SPI_mnrch (
    	input clk,    // 50MHz system clock
    	input rst_n,  //low reset
    	input snd,    //initiate transaction flag
    	input [15:0] cmd,   //data to send
    	output reg done,   //SPI transaction complete flag
    	output reg [15:0] resp,  //received response
    	output reg SS_n,   //Slave Select
    	output reg SCLK,   //SPI Clock
    	output reg MOSI,   //master Out Slave In
    	input  MISO    //master In Slave Out
);

    	reg [15:0] shft_reg;
    	reg [4:0] SCLK_div;
    	reg [3:0] bit_cntr;
    	reg [1:0] state;
    
    	localparam IDLE = 2'b00,
               	LOAD = 2'b01,
               	SHIFT = 2'b10,
               	DONE = 2'b11;

    	always @(posedge clk or negedge rst_n) begin
        	if (!rst_n) begin
            		SS_n <= 1'b1;
            		SCLK <= 1'b1;
            		MOSI <= 1'b0;
            		done <= 1'b0;
            		state <= IDLE;
            		SCLK_div <= 5'b10111;
            		bit_cntr <= 4'b0000;
        	end 
		else begin
            		case (state)
                		IDLE: begin
                    			done <= 1'b0;
                    			SS_n <= 1'b1;
                    			if (snd) begin	//if snd goes high load the followijg values and change state to LOAD for next clk cycle
                        				shft_reg <= cmd;	//load data to send into shift reg
                        				SS_n <= 1'b0;		//set slave select to 0
                        				//SCLK_div <= 5'b10111;	//set SCLK to 10111
							SCLK_div <= 5'b10111;
                        				bit_cntr <= 4'b0000;
                        				state <= LOAD;
                    			end
                		end

                		LOAD: begin
                    			if (SCLK_div == 5'b00000) begin
                        				SCLK <= 1'b0;
                        				MOSI <= shft_reg[15];
                        				SCLK_div <= 5'b10111;
                        				state <= SHIFT;
                    			end 
				else begin
                        				//SCLK_div <= SCLK_div + 1;
							SCLK_div <= SCLK_div - 1;
                    			end
                		end

                		SHIFT: begin
                    			if (SCLK_div == 5'b00000) begin
                        				SCLK <= ~SCLK;
                        				if (SCLK) begin
                            					shft_reg <= {shft_reg[14:0], MISO};
                            					bit_cntr <= bit_cntr + 1;
                            					MOSI <= shft_reg[14];
                            					if (bit_cntr == 4'b1111) begin
                                						state <= DONE;
                            					end
                        				end
                        				SCLK_div <= 5'b10111;
                    			end 
				else begin
                        				SCLK_div <= SCLK_div - 1;
                    			end
                		end

                		DONE: begin
                    			SS_n <= 1'b1;
                    			done <= 1'b1;
                    			resp <= shft_reg;
                    			state <= IDLE;
                		end
            		endcase
        	end
    	 end
endmodule
