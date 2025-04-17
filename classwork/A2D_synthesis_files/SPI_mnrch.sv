module SPI_mnrch(
  	input logic clk, 
	input logic rst_n,
  	input logic snd, //start transaction
  	input logic MISO, //MISO holds shft msb
  	input logic [15:0] cmd, //cmd to be sent
  	output logic SS_n, 
	output logic SCLK, 	//1/32 clock signal
	output logic MOSI, //to be shifted into shft in LSB
  	output logic done, //flags when transaction is complete 
  	output logic [15:0] resp //response is the output after shifts
);

  	//SCLK generation
  	logic [4:0] SCLK_div; //divider for SCLK signal
  	logic ld_SCLK; //load SCLK
  	logic full; //signal to trigger when SCLK_div is maxed out - this means SCLK is about to go low
  	logic SCLK_rise; //trigger after 2 clk signals of being high

	//when ld_CLK is high set SCLK_div to its initial bal of 10111
	//if not then each clk posedge incremenent by 1
  	always_ff @(posedge clk) begin
    		if (ld_SCLK) 
      			SCLK_div <= 5'b10111; //initialise SCLK to value as described in brief
    		else 
      			SCLK_div <= SCLK_div + 1; //increment each clk cycle
  	end

  	assign SCLK = SCLK_div[4]; //SCLK signal depends on MSB of SCLK_div - oscillates as SCLK_div increments
  	assign full = (SCLK_div == 5'b11111); //full when SCLK is full - about to go low
  	assign SCLK_rise = (SCLK_div == 5'b10001); //detects time for shift to occur - 2 clks after rising

	logic shft; //shift signal 
  	logic init; //load command into shft when init is high
  	logic [15:0] shft_reg; //shift reg to hold response
  	

  	always_ff @(posedge clk) begin
    		if (init)  //if init is high - load cmd into shift_reg
      			shft_reg <= cmd;
    		else if (shft) 		//if shft is high you load MISO into LSB and shift rest to the left
      			shft_reg <= {shft_reg[14:0], MISO}; 
  		end

  	assign MOSI = shft_reg[15]; 	//MOSI sent the MSB of shft_reg
  	assign resp = shft_reg; 	//hold the current shifted value - once all shifts are complete the output will be here 

  	
  	logic [4:0] cnt; //counter to keep track of shifts
  	logic done_shifts; //flag for when all shifts are done Signals when 16 bits have been transferred

  	always_ff @(posedge clk) begin
    		if (init) 
      			cnt <= 5'b00000; //when init is high set cnt to
    		else if (shft) 
      			cnt <= cnt + 1; //increment counter when shift is high
  	end

  	always_comb begin
    		done_shifts = (cnt == 5'b10000); //high when shift counter has reached 16
  	end

  	
  	logic done_transaction;
	//define 3 states 
  	typedef enum reg[1:0] {IDLE,SHIFT,DONE} state_t;
  	state_t state, next_state;

	//state change logic
  	always_ff @(posedge clk, negedge rst_n) begin
    		if (!rst_n) 
      			state <= IDLE; //when reset return to IDLE
    		else 
      			state <= next_state; //at each posedge clk update state
  	end
	//FSM logic
 	always_comb begin
    		shft = 1'b0;	//shft is initially low 
    		ld_SCLK = 1'b0;	//set ld_SCLK to 0
    		init = 1'b0;	
    		done_transaction = 1'b0;
    		next_state = state; 
		
		case(state) 
    			IDLE: begin
      				ld_SCLK = 1'b1; //keep SCLK high in IDLE
      				if (snd) begin
        				init = 1'b1; //set high whhen snd is high - this will load cmd into shft 
        				next_state = SHIFT; //move to shift
      				end
    			end 

    			SHIFT: begin
      				if (done_shifts)
        				next_state = DONE; // Move to back porch when done
      				else if (SCLK_rise) begin
        				shft = 1'b1; //shift data at posedge SCLK
        				next_state = SHIFT;	//stay in shfit until done_shifts is high - counter reaches 16
      				end
    			end 

    			DONE: begin
       				// Immediately flag that the transaction is complete
       				done_transaction = 1'b1;
				ld_SCLK = 1'b1;
       				next_state = IDLE;
   			end
  		endcase
	end

  	
 	always_ff @(posedge clk, negedge rst_n) begin
      		if (!rst_n)
         		done <= 1'b0;
      		else if (done_transaction)
         		done <= 1'b1;
     	 	else if (init)
         		done <= 1'b0;
   	end


  	
  	always_ff @(posedge clk, negedge rst_n) begin
    		if (!rst_n) begin //set high on reset trigger
      			SS_n <= 1'b1;
		end
    		else if (done_transaction) begin //set high when transacton is done
      			SS_n <= 1'b1;
			//ld_SCLK <= 1'b1;
		end
    		else if (init) begin 	//low when init is high
      			SS_n <= 1'b0;
		end
		
  	end

endmodule

