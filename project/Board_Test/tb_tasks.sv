
`ifndef TB_TASKS_SV
`define TB_TASKS_SV

// -----------------------------------------------------------------------------
//  Power-on analogue defaults
// -----------------------------------------------------------------------------
task automatic initialize
     (ref [11:0] BATT,
      ref [11:0] BRAKE,
      ref [11:0] TORQUE,
      ref [11:0] CURR,
      ref [15:0] YAW_RT);
   begin
      BATT   = 12'hB00;   // ?44 V pack
      BRAKE  = 12'hFFF;   // lever released
      TORQUE = 12'h980;   // modest rider torque
      CURR   = 12'h000;   // physics will drive later
      YAW_RT = 16'h0000;  // level ground
   end
endtask

// -----------------------------------------------------------------------------
//  Constant uphill pitch for *cycles* clock cycles
// -----------------------------------------------------------------------------
task automatic hill_climb
     (input int cycles,
      input  logic [15:0] yaw_rt_value,
      ref    [15:0] YAW_RT,
      input  logic       clk);
   begin
      YAW_RT = yaw_rt_value;
      repeat (cycles) @(posedge clk);
      YAW_RT = 16'h0000;
   end
endtask

// -----------------------------------------------------------------------------
//  Brake-lever pull for *cycles* clock cycles
// -----------------------------------------------------------------------------
task automatic brake_test
     (input int cycles,
      ref   [11:0] BRAKE,
      input logic clk);
   begin
      BRAKE = 12'h000;                // lever squeezed
      repeat (cycles) @(posedge clk);
      BRAKE = 12'hFFF;                // lever released
   end
endtask

`endif  // TB_TASKS_SV
