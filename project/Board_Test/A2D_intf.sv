module A2D_intf(
    input         clk,
    input         rst_n,
    output reg [11:0] batt,    // Battery voltage (channel 0)
    output reg [11:0] curr,    // Motor current (channel 1)
    output reg [11:0] brake,   // Brake lever position (channel 3)
    output reg [11:0] torque,  // Crank spindle torque sensor (channel 4)
    output         SS_n,       // Active low slave select (to A2D)
    output         SCLK,       // Serial clock to the A2D
    output         MOSI,       // Master Out Slave In (to A2D)
    input          MISO        // Master In Slave Out (from A2D)
);

  // Assign an overflow of all 1s to the conversion timer
  localparam [13:0] CONV_OVERFLOW = '1;

  typedef enum logic [3:0] {
    IDLE,             // Wait for delay counter overflow to start sequence
    SENSOR_START,     // Initiate conversion transaction for current sensor
    SENSOR_WAIT,      // Wait for conversion SPI transaction to finish
    INTERIM_1,        // One-cycle pause after conversion transaction
    SENSOR_READ,      // Initiate read transaction for conversion result
    SENSOR_WAIT_READ, // Wait for read transaction to finish
    INTERIM_2,        // One-cycle pause after read transaction
    STORE,            // Store conversion result and update sensor selector
    WAIT_NEW_ROUND    // Wait until delay counter moves off its overflow value
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

  // SPI channel interface signal
  logic [2:0] channel;

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
    if (!rst_n)
      conv_timer <= 0;
    else
      if (cnv_cmplt == 1'b0)
        conv_timer <= conv_timer + 1; // Increment the counter
      else
        conv_timer <= 0; // Reset the counter when conversion is complete
  end

  // ---------------------------------------------------------------------------
  // Channel round-robin counter (increments after each complete conversion)
  // ---------------------------------------------------------------------------
  always_ff @(posedge clk or negedge rst_n) begin
      if (!rst_n) begin
          sensor_sel <= 0; // Start at channel 0
      end else begin
          if (cnv_cmplt) begin
            // Wrap around after channel 3 (2'b11)
            if (sensor_sel == 2'b11) begin
              sensor_sel <= 2'b00; // Wrap around to channel 0
            end else begin
              sensor_sel <= sensor_sel + 1; // Increment the sensor selector for the next conversion
            end
          end else begin
            sensor_sel <= sensor_sel; // Hold the current value if not complete
          end
      end
  end

  // ---------------------------------------------------------------------------
  // Stores the latest ADC result into the correct output 
  // ---------------------------------------------------------------------------
  always_ff @(posedge clk or negedge rst_n) begin
      if (!rst_n) begin
          batt <= 0;
          curr    <= 0;
          brake   <= 0;
          torque  <= 0;
      end else begin
          if (cnv_cmplt) begin
              // Assign the conversion result based on which channel was just read
              if (sensor_sel == 2'b00) begin
                  batt <= spi_resp[11:0]; // Channel 0 result
              end else if (sensor_sel == 2'b01) begin
                  curr <= spi_resp[11:0];    // Channel 1 result
              end else if (sensor_sel == 2'b10) begin
                  brake <= spi_resp[11:0];   // Channel 3 result
              end else if (sensor_sel == 2'b11) begin
                  torque <= spi_resp[11:0];  // Channel 4 result
              end
          end
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
    // ---------- deterministic defaults ----------
    nxt_state  = state;       // stay in same state unless we say otherwise
    snd        = 1'b0;
    spi_cmd    = 16'h0000;    // <- a benign value
    cnv_cmplt  = 1'b0;

    // Map sensor_sel to the proper A2D channel
    case (sensor_sel)
      2'b00: channel = 3'b000; // Channel 0: Battery voltage
      2'b01: channel = 3'b001; // Channel 1: Motor current
      2'b10: channel = 3'b011; // Channel 3: Brake lever position
      2'b11: channel = 3'b100; // Channel 4: Crank spindle torque
      default: channel = 3'b000; // Default to battery voltage for safety
    endcase

    case (state)
      // Wait for conv_timer overflow before starting a conversion sequence
      IDLE: begin
        cnv_cmplt = 1'b0;
        if (conv_timer == CONV_OVERFLOW)
          nxt_state = SENSOR_START;
      end

      // Issue the conversion command for the current sensor.
      SENSOR_START: begin
        spi_cmd = {2'b00, channel, 11'b000};
        snd = 1'b1; // Start the SPI transaction
        nxt_state = SENSOR_WAIT;
      end

      // Wait for the SPI conversion transaction to complete
      SENSOR_WAIT: begin
        snd = 1'b0; // Deassert snd after the command is sent
        if (spi_done)
          nxt_state = INTERIM_1;
      end

      // One clock cycle pause before reading
      INTERIM_1: begin
        nxt_state = SENSOR_READ;
      end

      // Initiate the SPI transaction to read the conversion result
      SENSOR_READ: begin
        spi_cmd = 0;  // Dummy command; the sent value can be junk
        snd = 1'b1; // Start the SPI read transaction
        nxt_state = SENSOR_WAIT_READ;
      end

      // Wait for the read SPI transaction to complete
      SENSOR_WAIT_READ: begin
        snd = 1'b0;
        if (spi_done)
          nxt_state = STORE;
      end

      // Copy the SPI response to the registers
      STORE: begin
        cnv_cmplt = 1'b1; // Signal to store the response and to increment sensor_sel
        nxt_state = INTERIM_2;
      end

      // One clock cycle pause after store transaction
      INTERIM_2: begin
        nxt_state = IDLE;
      end

      default:
        nxt_state = IDLE; // Default to IDLE state for safety
    endcase
  end
endmodule