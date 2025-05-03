`ifndef TB_TASKS_SV
`define TB_TASKS_SV
//============================================================
//  tb_tasks.sv – helper tasks for eBike test-bench
//============================================================

// -----------------------------------------------------------------------------
// 1) Power-on analogue defaults
// -----------------------------------------------------------------------------
task automatic initialize
     (ref [11:0] BATT,
      ref [11:0] BRAKE,
      ref [11:0] TORQUE,
      ref [11:0] CURR,
      ref [15:0] YAW_RT
	  );
   begin
      BATT   = 12'hB00;   // ≈44 V
      BRAKE  = 12'hFFF;   // lever released
      TORQUE = 12'h580;   // rider torque
      CURR   = 12'h000;   // physics drives later
      YAW_RT = 16'h0000;  // level ground
   end
endtask

// -----------------------------------------------------------------------------
// 2) Constant uphill pitch for *cycles* system clocks
// -----------------------------------------------------------------------------
task automatic hill_climb
     (input  int           cycles,
      input  logic [15:0]  yaw_rt_value,
      ref    [15:0]        YAW_RT,
      ref         clk);
   begin
      YAW_RT = yaw_rt_value;
      repeat (cycles) @(posedge clk);
      YAW_RT = 16'h0000;
   end
endtask

// -----------------------------------------------------------------------------
// 3) Brake-lever pull for *cycles* clocks
// -----------------------------------------------------------------------------
task automatic brake_test
     (input  int     cycles,
      ref    [11:0]  BRAKE,
      ref   clk);
   begin
      BRAKE = 12'h000;                // lever squeezed
      repeat (cycles) @(posedge clk);
      BRAKE = 12'hFFF;                // lever released
   end
endtask



// -----------------------------------------------------------------------------
// 4) Single push-button tap
// -----------------------------------------------------------------------------
task automatic assist_press
     (ref   logic tgglMd,
      ref clk);
   begin
      tgglMd = 1'b1;   // blocking assignments – legal for ref vars
      @(posedge clk);
      tgglMd = 1'b0;
   end
endtask



// -----------------------------------------------------------------------------
// 5) Incline profile: up → flat → down
// -----------------------------------------------------------------------------
task automatic incline_profile
     (input int         cycles_up,
      input int         cycles_flat,
      input int         cycles_down,
      input logic [15:0] yaw_rt_up,
      input logic [15:0] yaw_rt_down,
      ref   [15:0]      YAW_RT,
      ref       clk);
   begin
      YAW_RT = yaw_rt_up;            repeat (cycles_up)  @(posedge clk);
      YAW_RT = 16'h0000;             repeat (cycles_flat)@(posedge clk);
      YAW_RT = yaw_rt_down;          repeat (cycles_down)@(posedge clk);
      YAW_RT = 16'h0000;
   end
endtask



// -----------------------------------------------------------------------------
// 6) Cycle assist button N times, fixed spacing
// -----------------------------------------------------------------------------
task automatic assist_cycle
     (input int   presses,
      input int   cycles_between,
      ref   logic tgglMd,
      ref clk);
   for (int i = 0; i < presses; i++) begin
      assist_press(tgglMd, clk);
      repeat (cycles_between) @(posedge clk);
   end
endtask

// -----------------------------------------------------------------------------
// 7) Set torque for *cycles* clock cycles
// -----------------------------------------------------------------------------
task automatic set_torque
     (input  int           cycles,
      input  logic [11:0] torque_value,
      ref    [11:0]        TORQUE,
      ref         clk);
   begin
      TORQUE = torque_value;
      repeat (cycles) @(posedge clk);
      TORQUE = 12'h000;
   end
endtask


`endif  // TB_TASKS_SV
