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
    reg MISO_samp; // Delayed MISO sampling
    reg SS_n_reg;
    reg done_reg;
    
    localparam IDLE  = 2'b00,
               WAIT  = 2'b01,
               SHIFT = 2'b10,
               DONE  = 2'b11;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            SS_n <= 1'b1;
            SS_n_reg <= 1'b1;
            SCLK <= 1'b1;   // SCLK normally high
            MOSI <= 1'b0;
            //done <= 1'b0;
            done_reg <= 1'b0;
            state <= IDLE;
            SCLK_div <= 5'b10111;
            bit_cntr <= 4'b0000;
            MISO_samp <= 1'b0;
        end else begin
            case (state)
                IDLE: begin
                    done_reg <= 1'b0;
                    SS_n <= 1'b1;
                    if (snd) begin    
                        shft_reg <= cmd;    
                        SS_n <= 1'b0;   // Activate slave select
                        SS_n_reg <= 1'b0;
                        SCLK_div <= 5'b10111;
                        bit_cntr <= 4'b0000;
                        state <= WAIT;
                    end
                end
                
                WAIT: begin
                    if (SCLK_div == 5'b00000) begin
                        state <= SHIFT;
                        SCLK_div <= 5'b10111;
                    end else begin
                        SCLK_div <= SCLK_div - 1;
                    end
                end

                SHIFT: begin
                    if (SCLK_div == 5'b00000) begin
                        SCLK <= ~SCLK;  // Toggle clock
                        
                        if (SCLK == 1'b0) begin
                            MOSI <= shft_reg[14];  
                        end else begin
                            MISO_samp <= MISO; // Sample MISO on the correct edge
                            shft_reg <= {shft_reg[14:0], MISO_samp};  
                            bit_cntr <= bit_cntr + 1;
                        end
                        //change 5 bit
                        if (bit_cntr == 4'b1111) begin  // Stop at 15 shifts (16 bits total)
                            state <= DONE;
                        end
                        SCLK_div <= 5'b10111;
                    end else begin
                        SCLK_div <= SCLK_div - 1;
                    end
                end

                DONE: begin
                    SS_n_reg <= 1'b1;
                    if (SCLK_div == 5'b00000) begin
                        SS_n <= SS_n_reg;
                        done_reg <= 1'b1;
                        resp <= shft_reg;
                        state <= IDLE;
                    end else begin
                        SCLK_div <= SCLK_div - 1;
                    end
                end
            endcase
        end
    end

    
/*
	always_ff @(posedge clk or negedge rst_n) begin
		if(!rst_n) begin
			done <= 1'd0;
		end
		else begin
			done <= done_reg;
		end
	end
	

*/
	assign done = done_reg;
endmodule
