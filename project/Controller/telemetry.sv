// telemetry.sv
// 
// Dustin Nguyen (danguyen2@wisc.edu)
// E C E 551

module telemetry(
    input wire clk,
    input wire rst_n,
    input wire [11:0] batt_v,
    input wire [11:0] avg_curr,
    input wire [11:0] avg_torque,
    output logic TX,
    output logic tx_done
);

    logic [7:0] tx_data;
    logic trmt;
    logic uart_tx_done;
    logic [3:0] packet;

    UART_tx uart(
        .clk(clk), .rst_n(rst_n),
        .TX(TX), .trmt(trmt), .tx_data(tx_data), .tx_done(uart_tx_done)
    );

    typedef enum logic [2:0] { IDLE, SEND, DONE } state_t;

    state_t state, nxt_state; // Current and next state variables
    logic [4:0] timer; // 5-bit timer (used for pacing transmissions)
    
    // 5-bit timer to pace transmissions
    always_ff @ (posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            timer <= 0;
        end else begin
            timer <= timer + 1; // Increment timer every clock cycle
            if (timer[4]) begin
                timer <= 0; // Reset timer when the MSB is asserted
            end
        end
    end

    // Packet Selection for transmission
    always_comb begin
        case (packet)
            4'd1: begin
                tx_data = 8'hAA;
            end
            4'd2: begin
                tx_data = 8'h55;
            end
            4'd3: begin
                tx_data = {4'h0, batt_v[11:8]};
            end
            4'd4: begin
                tx_data = batt_v[7:0];
            end
            4'd5: begin
                tx_data = {4'h0, avg_curr[11:8]};
            end
            4'd6: begin
                tx_data = avg_curr[7:0];
            end
            4'd7: begin
                tx_data = {4'h0,avg_torque[11:8]};
            end
            4'd8: begin
                tx_data = avg_torque[7:0];
            end
            default begin
                tx_data = 8'h00;
            end
        endcase 
    end

    // State machine
    always @(posedge clk, negedge rst_n) begin
        if (!rst_n) begin
            state <= IDLE; // Reset state to IDLE
        end else begin
            state <= nxt_state; // Transition to the next state
        end;
    end

    // flop trmt

    always_comb begin
        trmt = 0;
        tx_done = 0;
        
        case (state)
            IDLE: begin
                if (timer[4]) begin // Waits for the timer to expire before initiating transmission.
                    trmt = 1; // Start transmission
                    nxt_state = SEND;
                end else begin
                    packet = 0; // Reset packet counter to send 0 data
                    nxt_state = IDLE;
                end
            end
            // Sends data and waits for transmission to complete.
            SEND: begin
                if (uart_tx_done) begin
                    trmt = 0; // Stop transmission
                    nxt_state = DONE;
                end else begin
                    nxt_state = SEND;
                end
            end
            // Moves to the next packet or resets the process.
            DONE: begin
                tx_done = 1;
                if (packet == 4'b1001) begin // If the packet counter reaches its max, return to IDLE.
                    packet = 0;
                    trmt = 0;
                    nxt_state = IDLE;
                end else begin
                    packet = packet + 1; // Move to next packet
                    trmt = 1; // Start new transmission
                    nxt_state = SEND;
                end
            end
        endcase
    end

endmodule;
