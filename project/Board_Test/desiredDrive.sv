// desiredDrive.sv
// The desiredDrive module computes a 12-bit target current (target_curr) for a motor or drive system
// The module first processes the incline by saturating it to a 10-bit range and adjusting it with an offset to ensure meaningful contributions.
// The cadence is adjusted to account for low pedaling speeds, and the torque is normalized by subtracting a minimum threshold (TORQUE_MIN),
// ensuring only values above this threshold influence the output. These factors are combined into a 30-bit assist product (assist_prod),
// which represents the desired power assist level. If the rider is not pedaling, the assist product is set to zero.
// Finally, the target current is derived from the assist product, saturating to the maximum value (12'hFFF) if the product exceeds a certain range,
// or extracting a 12-bit value otherwise.
// Dustin Nguyen (danguyen2@wisc.edu)
// E C E 551

module desiredDrive (
    input wire [11:0] avg_torque,
    input wire [4:0] cadence,
    input wire not_pedaling,
    input wire [12:0] incline,
    input wire [2:0] scale,
    output wire [11:0] target_curr
);

    // Define a torque offset minimum value (constant parameter)
    localparam TORQUE_MIN = 12'h380;

    // Saturated incline value (limited to a 10-bit range)
    logic [9:0] saturated_incline;

    incline_sat incline_sat (
        .incline(incline),
        .incline_sat(saturated_incline)
    );

    // Compute incline factor by adding an offset (256)
    logic [10:0] incline_factor;
    assign incline_factor = {{saturated_incline[9]}, saturated_incline} + 11'd256;

    // Limited incline value (9-bit), clipped to 0 if negative, capped at 511
    logic [8:0] incline_lim;
    assign incline_lim = (incline_factor[10]) ? 9'h000 : (incline_factor > 10'd511) ? 9'h1FF : incline_factor[8:0];

    // Compute cadence factor, ensuring values adjust for low cadence
    logic [5:0] cadence_factor;
    assign cadence_factor = (cadence > 6'h1) ? cadence + 6'd32 : 6'd0;

    // Compute torque offset by subtracting TORQUE_MIN from avg_torque
    logic [12:0] torque_off;
    assign torque_off = {1'b0, avg_torque} - {1'b0, TORQUE_MIN};

    // Compute torque_pos: Zero-clipped version of torque_off
    logic [11:0] torque_pos;
    assign torque_pos = (~torque_off[12]) ? torque_off[11:0] : 12'h000;

    // Compute assist product (power assist level) using incline, torque, and cadence factors
    logic [29:0] assist_prod;
    assign assist_prod = (~not_pedaling) ? (torque_pos * incline_lim * cadence_factor * scale) : 30'd0;  

    // Determine target current for PID control
    // If any of the top 3 bits [29:27] of assist_prod are set, saturate to max (12'hFFF)
    // Otherwise, extract bits [26:15] as the output value
    assign target_curr = (|assist_prod[29:27] == 1'b1) ? 12'hFFF : assist_prod[26:15];

endmodule  