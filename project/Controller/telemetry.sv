// telemetry.sv
// Sends periodic telemetry packets over UART containing battery voltage, average
// motor current, and average torque values. The module transmits a fixed 8-byte
// packet once every ~48Hz based on a 20-bit timing counter.
//
// Packet format (8 bytes total):
//   Byte 0: 0xAA      (delimiter 1)
//   Byte 1: 0x55      (delimiter 2)
//   Byte 2: batt_v[11:8] (padded upper nibble)
//   Byte 3: batt_v[7:0]
//   Byte 4: avg_curr[11:8] (padded upper nibble)
//   Byte 5: avg_curr[7:0]
//   Byte 6: avg_torque[11:8] (padded upper nibble)
//   Byte 7: avg_torque[7:0]
//
// Features:
// - UART transmission using external `UART_tx` module
// - Clock-based pacing: 50 MHz system clock divided down using a 20-bit counter
// - Rotates out 8-byte packet using a shifter and byte counter
// - Outputs single-byte `tx_data` and pulses `trmt` to request UART transmission
//
// Used to monitor e-bike status wirelessly or over serial connection.
//
// Team VeriLeBron (Dustin, Shane, Quinn, Eeshana)

module telemetry (batt_v, avg_curr, avg_torque, clk, rst_n, TX);

 input logic [11:0] batt_v;
 input logic [11:0] avg_curr;
 input logic [11:0] avg_torque;
 input logic clk, rst_n;
 output logic TX;

//-----intialize the uart_tx-----------------------------------
 logic trmt;
 logic [7:0] tx_data;
 logic tx_done;

 UART_tx U_tx(.clk(clk), .rst_n(rst_n), .TX(TX), .trmt(trmt), .tx_data(tx_data), .tx_done(tx_done));

//----packet-----------------------------------------------------
 logic [7:0] delim1, delim2;
 logic [7:0] payload1, payload2, payload3, payload4, payload5, payload6;
 logic [63:0] data; //the whole 8 bytes data

 assign delim1 = 8'hAA;
 assign delim2 = 8'h55;
 assign payload1 = {4'h0, batt_v[11:8]};
 assign payload2 = batt_v[7:0];
 assign payload3 = {4'h0, avg_curr[11:8]};
 assign payload4 = avg_curr[7:0];
 assign payload5 = {4'h0, avg_torque[11:8]};
 assign payload6 = avg_torque[7:0];

//----counter for clock----------------------------
//50M/47.68=2^20, so the counter should be 20 bits
 logic [19:0] cnt_clk;
 logic full_clk;

 always_ff @( posedge clk, negedge rst_n)begin
    if (!rst_n) 
       cnt_clk <= 20'b0;
    else 
       cnt_clk <= cnt_clk + 1;
 end

 assign full_clk = &cnt_clk;

//----shifter reg used to transmit data (byte)-----
//8 bytes, so the counter will be 3 bits
 logic [2:0] cnt_shft;
 logic clr, shft;//clr--clear the counter, shft--shft 1 byte when assert
 logic full_shft;
 
 always_ff @( posedge clk, negedge rst_n)begin
   if (!rst_n) begin
     cnt_shft <= 3'b000;
     data <= {delim1, delim2, payload1, payload2, payload3, payload4, payload5, payload6};//asynch reset
   end else if (clr) begin
     cnt_shft <= 3'b000;
     data <= {delim1, delim2, payload1, payload2, payload3, payload4, payload5, payload6};//enable signal
   end else if (shft) begin
     cnt_shft <= cnt_shft + 1;
     data <= {data[55:00], data[63:56]};//rotate left, and tx will be the MSbyte
   end else begin
     cnt_shft <= cnt_shft;
     data <= data;//hold the state
   end
 end

 assign full_shft = &cnt_shft;
 assign tx_data = data[63:56];

//----SM---------------------------------------
typedef enum reg [1:0] {BEGIN, WAIT, IDLE} state_t;
state_t state, nxt_state;

 always_ff @(posedge clk, negedge rst_n)
   if (!rst_n)
       state <= BEGIN;
   else	
       state <= nxt_state;//asynch reset

 always_comb begin
   clr = 0;
   shft = 0;
   trmt = 0;
  case(state)
       BEGIN: begin
	   nxt_state = WAIT;
	   trmt = 1;//hold trmt high when want to transmit data_tx
       end
       WAIT: begin 
	     if (full_shft)
		 nxt_state = IDLE;//all 8 bytes are transmitted
	     else if (tx_done) begin
                 nxt_state = BEGIN;
		 shft = 1;//tx_done assert, start to shift 1 by 1 byte
	     end else
                 nxt_state = WAIT;//wait until tx_done assert
	end
	IDLE: begin
	      if (full_clk) begin
		clr = 1;
		nxt_state = BEGIN;
	      end else
	        nxt_state = IDLE;
	end
	default: nxt_state = BEGIN;	
   endcase
 end
endmodule