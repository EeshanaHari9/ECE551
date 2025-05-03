// A2D_intf.sv
// Interfaces with the ADC128S A2D converter over SPI to collect sensor readings (battery, current, brake, torque) from four 
// analog channels in a round-robin fashion using SPI_mnrch.sv.
// Team VeriLeBron (Dustin, Shane, Quinn, Eeshana) 

module A2D_intf(
     input logic         clk,
     input logic        rst_n,
     output reg [11:0] batt,    // Battery voltage (channel 0)
     output reg [11:0] curr,    // Motor current (channel 1)
     output reg [11:0] brake,   // Brake lever position (channel 3)
     output reg [11:0] torque,  // Crank spindle torque sensor (channel 4)
     output logic        SS_n,       // Active low slave select (to A2D)
     output logic        SCLK,       // Serial clock to the A2D
     output logic        MOSI,       // Master Out Slave In (to A2D)
     input logic         MISO        // Master In Slave Out (from A2D)
 );
   
   // State machine states
   typedef enum logic[3:0] {
		IDLE,
		REQUEST, REQUEST_WAIT, REQUEST_DONE,
		READ, READ_WAIT, READ_DONE
	} state_t;
 
   state_t state, nxt_state;
 
   logic cnv_cmplt; // Conversion complete signal (from SPI_mnrch)
   // 2-bit sensor selector: 0 -> battery, 1 -> current, 2 -> brake, 3 -> torque.
   logic [1:0] sensor_sel;
   logic snd; // Start transaction signal for SPI_mnrch
 
   // 14-bit free-running delay counter
   logic [13:0] conv_timer;
 
   // SPI command register and wires for SPI_mnrch interface
   logic [15:0] spi_cmd;
   logic       spi_done;
   logic [15:0] spi_resp;
 
   // Enable signals
   logic batt_en, curr_en, brake_en, torque_en;
 
   // ---------------------------------------------------------------------------
   // SPI_mnrch Module Instantiation
   // ---------------------------------------------------------------------------
   SPI_mnrch spi_inst (
     .clk   (clk),
     .rst_n (rst_n),
     .cmd   (spi_cmd),
     .done  (spi_done),
     .resp  (spi_resp),
     .snd   (snd),
     .SS_n  (SS_n),
     .SCLK  (SCLK),
     .MOSI  (MOSI),
     .MISO  (MISO)
   );
 
   // ---------------------------------------------------------------------------
   // 14-bit Free-Running Delay Counter
   // ---------------------------------------------------------------------------
   always @(posedge clk or negedge rst_n) begin
     if (!rst_n) begin
       conv_timer <= 0;
     end else begin
       conv_timer <= conv_timer + 1; // Increment the counter
     end
   end
 
   // ---------------------------------------------------------------------------
   // Channel round-robin counter (increments after each complete conversion)
   // ---------------------------------------------------------------------------
   always @(posedge clk or negedge rst_n) begin
     if (!rst_n) begin
       sensor_sel <= 0;
     end else begin
      if (cnv_cmplt) begin
        sensor_sel <= sensor_sel + 1; // Increment the counter
      end
     end
   end

   assign spi_cmd = (sensor_sel == 2'b00) ? {2'b00, 3'b000, 11'h000} :
				    (sensor_sel == 2'b01) ? {2'b00, 3'b001, 11'h000} :
				    (sensor_sel == 2'b10) ? {2'b00, 3'b011, 11'h000} :
								            {2'b00, 3'b100, 11'h000};

   // ---------------------------------------------------------------------------
   // Enable signals for each channel
   // ---------------------------------------------------------------------------
   always_comb begin
		batt_en = 0;
		curr_en = 0;
		brake_en = 0;
		torque_en = 0;
		
		if (cnv_cmplt) begin
			case(sensor_sel)
				2'b00: batt_en = 1;
				2'b01: curr_en = 1;
				2'b10: brake_en = 1;
				2'b11: torque_en = 1;
			endcase
		end
	end
 
   // ---------------------------------------------------------------------------
   // Stores the latest ADC result into the correct output 
   // ---------------------------------------------------------------------------
   always_ff @(posedge clk, negedge rst_n) begin
		if (!rst_n) begin
      batt <= 0;
     end else if (batt_en) begin
      batt <= spi_resp[11:0];
     end
   end

   always_ff @(posedge clk, negedge rst_n) begin
		if (!rst_n) begin
      curr <= 0;
     end else if (curr_en) begin
      curr <= spi_resp[11:0];
     end
   end

   always_ff @(posedge clk, negedge rst_n) begin
		if (!rst_n) begin
      brake <= 0;
     end else if (brake_en) begin
      brake <= spi_resp[11:0];
     end
   end

   always_ff @(posedge clk, negedge rst_n) begin
		if (!rst_n) begin
      torque <= 0;
     end else if (torque_en) begin
      torque <= spi_resp[11:0];
     end
   end
		
   // ---------------------------------------------------------------------------
   // A2D Interface State Machine
   // ---------------------------------------------------------------------------
   always_ff @(posedge clk or negedge rst_n) begin
     if (!rst_n)
       state <= IDLE; // Reset state machine to IDLE
     else
       state <= nxt_state; // Update state based on the next state logic
   end
 
   // State machine logic
  always_comb begin
     // Default signal assignments for this clock cycle
    snd = 1'b0;             // Default: do not start SPI transaction
    cnv_cmplt = 1'b0;       // Default: conversion not complete
    nxt_state = state;      // Default: hold current state unless conditions met

    // State machine definition
    case (state)
      // Wait for conversion timer to signal it's time to start a new conversion
      IDLE:
          if (&conv_timer)            // All bits of conv_timer are 1 → time to convert
              nxt_state = REQUEST;

      // Begin sending the SPI command to request A2D conversion (first transaction)
      REQUEST: begin
          snd = 1;                    // Assert snd to start SPI command
          nxt_state = REQUEST_WAIT;  // Wait for transaction to initiate
      end

      // Wait 1 clock cycle (needed between SPI transactions)
      REQUEST_WAIT:
          nxt_state = REQUEST_DONE;

      // Wait for the SPI request to complete
      REQUEST_DONE:
          if (spi_done)              // SPI transaction done
              nxt_state = READ;

      // Begin second SPI transaction to read A2D result (dummy write)
      READ: begin
          snd = 1;                    // Assert snd to start SPI read
          nxt_state = READ_WAIT;
      end

      // Wait 1 clock cycle before checking if read is done
      READ_WAIT:
          nxt_state = READ_DONE;

      // After read is done, raise conversion complete signal and return to IDLE
      READ_DONE:
          if (spi_done) begin         // SPI read completed
              cnv_cmplt = 1;          // Signal that conversion is complete
              nxt_state = IDLE;       // Go back to IDLE to wait for next timer event
          end
      endcase
   end
 endmodule