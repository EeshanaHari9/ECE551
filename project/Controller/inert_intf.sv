// inert_intf.sv
// Interfaces with a 6-DOF inertial sensor (IMU) over SPI to read real-time
// accelerometer and gyroscope data. After initialization, the module collects
// measurements on pitch, roll, and yaw, and forwards processed results to the
// `inertial_integrator` to compute road incline (pitch-based).
//
// The module operates with a state machine that performs:
// - Sensor configuration through SPI commands during INIT states
// - Interrupt-based data acquisition after initialization
// - Sequential reads of 8-bit sensor registers (AY, AZ, roll, yaw)
// - Double-flop synchronization of asynchronous INT signal
// - Safe transaction handshaking with `SPI_mnrch`
// - Real-time processing and valid flagging of incline results
//
// Outputs:
// - `incline`: Signed 13-bit pitch result from inertial_integrator
// - `vld`    : Indicates when a new incline value is available
//
// Team VeriLeBron (Dustin, Shane, Quinn, Eeshana)

module inert_intf(
    input logic clk,
    input logic rst_n,
    output logic SS_n,
    input logic MISO,
    output logic SCLK,
    output logic MOSI,
    input logic INT,
    output logic [12:0] incline,
    output logic vld
);

 typedef enum logic [3:0] {
    // Initialize Sensor
    INIT1, // Enable interrupt upon data ready
    INIT2, // Setup accel for 208Hz data rate, +/- 2g accel range, 50Hz LPF
    INIT3, // Setup gyro for 208Hz data rate, +/- 245�/sec range.
    INIT4, // Turn rounding on for both accel and gryo
    CHECKINT, // Check if INT is high
    // Start reading once INTerrupt is high
    ROLLL,
    ROLLH,
    YAWL,
    YAWH,
    AYL_READ,
    AYH_READ,
    AZL_READ,
    AZH_READ,
    VALRDY // Indicate to inertial integrator that valid readings are ready
  } state_t;

state_t state, nxt_state;

logic [15:0] timer;

logic [15:0] cmd, cmded;
logic [15:0] resp;

logic snd, sent;
logic done, done_prev, done_changed;

logic C_R_H, C_R_L, C_Y_H, C_Y_L, C_AY_H, C_AY_L, C_AZ_H, C_AZ_L; // enables for the registers
logic [7:0] H_ROLL_ff, L_ROLL_ff, H_YAW_ff, L_YAW_ff, H_AY_ff, L_AY_ff, H_AZ_ff, L_AZ_ff; // 8 bit holding reg

logic [7:0] rollL, rollH, yawL, yawH, AYL, AYH, AZL, AZH;
logic [15:0] roll_rt, yaw_rt, AY, AZ;

// ---------------------------------------------------------------------------
// SPI_mnrch Module Instantiation
// ---------------------------------------------------------------------------
SPI_mnrch spi_inst (
    .clk   (clk),
    .rst_n (rst_n),
    .cmd   (cmd),
    .done  (done),
    .resp  (resp),
    .snd   (snd),
    .SS_n  (SS_n),
    .SCLK  (SCLK),
    .MOSI  (MOSI),
    .MISO  (MISO)
);

// ---------------------------------------------------------------------------
// inertial_integrator Module Instantiation
// ---------------------------------------------------------------------------
inertial_integrator inert_ingtr_inst (
    .clk(clk),
    .rst_n(rst_n),
    .vld(vld),
    .roll_rt(roll_rt),
    .yaw_rt(yaw_rt),
    .AY(AY),
    .AZ(AZ),
    .incline(incline),
    .LED()
);

// ---------------------------------------------------------------------------
// Double-flop active high INT signal for metastability
// ---------------------------------------------------------------------------
logic INT_ff1, INT_ff2;

always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        INT_ff1 <= 1'b0;
        INT_ff2 <= 1'b0;
    end else begin
        INT_ff1 <= INT;
        INT_ff2 <= INT_ff1;
    end
end

// ---------------------------------------------------------------------------
// 16-bit timer
// ---------------------------------------------------------------------------
always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        timer <= 16'b0;
    end else begin
        timer <= timer + 1;
    end
end

// ---------------------------------------------------------------------------
// Flop the 8-bit sensor readings
// ---------------------------------------------------------------------------
// always_ff @(posedge clk or negedge rst_n) begin
//     if (!rst_n) begin
//         roll_rt <= 0;
//         yaw_rt <= 0;
//         AY <= 0;
//         AZ <= 0;
//     end else begin
//         roll_rt <= {rollH, rollL};
//         yaw_rt <= {yawH, yawL};
//         AY <= {AYH, AYL};
//         AZ <= {AZH, AZL};
//     end
// end
always_comb begin 
    roll_rt = {H_ROLL_ff, L_ROLL_ff};
    yaw_rt = {H_YAW_ff, L_YAW_ff};
    AY = {H_AY_ff, L_AY_ff};
    AZ = {H_AZ_ff, L_AZ_ff};
end

// ---------------------------------------------------------------------------
// Change detection logic
// ---------------------------------------------------------------------------
always_ff @(posedge clk, negedge rst_n) begin
    if (!rst_n) begin
        done_prev <= 0;
    end else begin
        done_prev <= done;
    end
end

assign done_changed = done & ~done_prev;

// ---------------------------------------------------------------------------
// Avoiding overlapping done and send signal
// ---------------------------------------------------------------------------
always_ff @(posedge clk, negedge rst_n) begin 
    if (!rst_n) begin
        snd <= 0;
        cmd <= 0;
    end else begin
        snd <= sent;
        cmd <= cmded;
    end
end

// ---------------------------------------------------------------------------
// Holding Registers for the sensor readings
// ---------------------------------------------------------------------------

// holding register for ROLL High
always_ff @(posedge clk, negedge rst_n) begin 
    if (!rst_n)
        H_ROLL_ff <= 0;
    else if (C_R_H) 
        H_ROLL_ff <= resp[7:0];
end 

// holding register for ROLL Low
always_ff @(posedge clk, negedge rst_n) begin 
    if (!rst_n)
        L_ROLL_ff <= 0;
    else if (C_R_L) 
        L_ROLL_ff <= resp[7:0];
end 

// holding register for YAW High 
always_ff @(posedge clk, negedge rst_n) begin 
    if (!rst_n)
        H_YAW_ff <= 0;
    else if (C_Y_H) 
        H_YAW_ff <= resp[7:0];
end 

// holding register for YAW Low
always_ff @(posedge clk, negedge rst_n) begin 
    if (!rst_n)
        L_YAW_ff <= 0;
    else if (C_Y_L) 
        L_YAW_ff <= resp[7:0];
end 

// holding register for AY High
always_ff @(posedge clk, negedge rst_n) begin 
    if (!rst_n) 
        H_AY_ff <= 0;
    else if (C_AY_H) 
        H_AY_ff <= resp[7:0];
end 

// holding register for AY Low 
always_ff @(posedge clk, negedge rst_n) begin 
    if (!rst_n) 
        L_AY_ff <= 0;
    else if (C_AY_L) 
        L_AY_ff <= resp[7:0];
end 

// holding register for AZ High
always_ff @(posedge clk, negedge rst_n) begin 
    if (!rst_n) 
        H_AZ_ff <= 0;
    else if (C_AZ_H) 
        H_AZ_ff <= resp[7:0];
end 

// holding register for AZ Low 
always_ff @(posedge clk, negedge rst_n) begin 
    if (!rst_n) 
        L_AZ_ff <= 0;
    else if (C_AZ_L) 
        L_AZ_ff <= resp[7:0];
end 

/** End of Holding Registers **/

// ---------------------------------------------------------------------------
// State machine for the inertial interface
// ---------------------------------------------------------------------------
always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        state <= INIT1;
    end else begin
        state <= nxt_state;
    end
end

always_comb begin
    // Default values
    sent = 1'b0;
    cmded = 16'h0000;
    vld = 1'b0;

    C_R_H = 1'b0;
    C_R_L = 1'b0;
    C_Y_H = 1'b0;
    C_Y_L = 1'b0;
    C_AY_H = 1'b0;
    C_AY_L = 1'b0;
    C_AZ_H = 1'b0;
    C_AZ_L = 1'b0; 

    nxt_state = state;

    case (state)
        INIT1: begin
            cmded = 16'h0d02;
            if (&timer) begin
                nxt_state = INIT2;
                sent = 1;
            end
        end
        INIT2: begin
            cmded = 16'h1053;
            if (done_changed) begin
                nxt_state = INIT3;
                sent = 1;
            end
        end
        INIT3: begin
            cmded = 16'h1150;
            if (done_changed) begin
                nxt_state = INIT4;
                sent = 1;
            end
        end
        INIT4: begin
            cmded = 16'h1460;
            if (done_changed) begin
                nxt_state = CHECKINT;
                sent = 1;
            end
        end
        CHECKINT: begin
            cmded = 16'hA4xx;
            if (INT_ff2) begin
                nxt_state = ROLLL;
                sent = 1;
            end
        end
        ROLLL: begin
            if (done_changed) begin
                nxt_state = ROLLH;
                sent = 1;
                cmded = 16'hA5xx;
                C_R_L = 1;
            end 
        end
        ROLLH: begin
            if (done_changed) begin
                nxt_state = YAWL;
                sent = 1;
                cmded = 16'hA6xx;
                C_R_H = 1;
            end 
        end
        YAWL: begin
            if (done_changed) begin
                nxt_state = YAWH;
                sent = 1;
                cmded = 16'hA7xx;
                C_Y_L = 1;
            end 
        end
        YAWH: begin
            if (done_changed) begin
                nxt_state = AYL_READ;
                sent = 1;
                cmded = 16'hAAxx;
                C_Y_H = 1;
            end 
        end
        AYL_READ: begin
            if (done_changed) begin
                nxt_state = AYH_READ;
                sent = 1;
                cmded = 16'hABxx;
                C_AY_L = 1;
            end 
        end
        AYH_READ: begin
            if (done_changed) begin
                nxt_state = AZL_READ;
                sent = 1;
                cmded = 16'hACxx;
                C_AY_H = 1;
            end 
        end
        AZL_READ: begin
            sent = 1;
            if (done_changed) begin
                nxt_state = AZH_READ;
                sent = 1;
                cmded = 16'hADxx;
                C_AZ_L = 1;
            end 
        end
        AZH_READ: begin
            if (done_changed) begin
                nxt_state = VALRDY;
                C_AZ_H = 1;
            end 
        end
        VALRDY: begin
            vld = 1;
            nxt_state = CHECKINT;
        end
        default: begin
            nxt_state = INIT1;
        end
    endcase
end

endmodule