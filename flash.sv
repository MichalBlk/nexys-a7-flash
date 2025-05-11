module flash(
  input  logic       clk_100mhz,
  input  logic       nrst,

  inout  logic       miso,
  inout  logic       mosi,
  output logic       sclk,
  output logic       wpn,
  output logic       rstn,
  output logic       csn,

  output logic [7:0] out
);
  localparam TICK       = 2;
  localparam MS         = 100000;
  localparam SEC        = 1000 * MS;

  localparam CMD_RESET  = 8'hf0;
  localparam CMD_READ   = 8'h03;

  localparam START_ADDR = 24'h000000;

  typedef enum logic [3:0] {
    ST_WAIT,
    ST_RESET_CS,
    ST_RESET_CMD,
    ST_RESET_WAIT,
    ST_RD_CS,
    ST_RD_CMD,
    ST_RD_ADDR,
    ST_RD_DATA,
    ST_RD_WAIT
  } state_t;

  state_t      state, state_r;
  logic [29:0] cnt, cnt_r;
  logic        clk_cnt, clk_cnt_r;
  logic [23:0] addr, addr_r;
  logic [7:0]  data, data_r;
  logic [23:0] wshr, wshr_r;
  logic [7:0]  rshr, rshr_r;
  logic        sclk_en, sclk_en_r;
  logic        cs, cs_r;
  logic        clk_50mhz;

  /*
   * Clock counter
   */
  assign clk_cnt = clk_cnt_r ^ 1;

  always_ff @(posedge clk_100mhz, negedge nrst)
    if (!nrst)
      clk_cnt_r <= 1;
    else
      clk_cnt_r <= clk_cnt;

  assign clk_50mhz = clk_cnt_r;

  /*
   * Chip select handling
   */
  always_comb begin
    cs = cs_r;

    case (state_r)
      ST_WAIT, ST_RESET_WAIT:
        if (cnt_r == MS - 1)
          cs = 1;

      ST_RESET_CMD, ST_RD_DATA:
        if (cnt_r == 8 * TICK - 2)
          cs = 0;

      ST_RD_WAIT:
        if (cnt_r == SEC - 1)
          cs = 1;
    endcase
  end

  always_ff @(posedge clk_100mhz, negedge nrst)
    if (!nrst)
      cs_r <= 0;
    else
      cs_r <= cs;

  /*
   * Slave clock handling
   */
  always_comb begin
    sclk_en = sclk_en_r;

    case (state_r)
      ST_RESET_CS, ST_RD_CS:
        if (!cnt_r)
          sclk_en = 1;

      ST_RESET_CMD, ST_RD_DATA:
        if (cnt_r == 8 * TICK - 2)
          sclk_en = 0;
    endcase
  end

  always_ff @(posedge clk_100mhz, negedge nrst)
    if (!nrst)
      sclk_en_r <= 0;
    else
      sclk_en_r <= sclk_en;

  /*
   * Address handling
   */
  always_comb begin
    addr = addr_r;

    if (state_r == ST_RD_WAIT && cnt_r == MS - 1)
      addr = addr_r + 1;
  end

  always_ff @(posedge clk_100mhz, negedge nrst)
    if (!nrst)
      addr_r <= START_ADDR;
    else
      addr_r <= addr;

  /*
   * Serial output
   */
  always_comb begin
    wshr = wshr_r;

    if (!(cnt_r & 1))
      wshr = wshr_r << 1;

    case (state_r)
      ST_RESET_CS:
        wshr[23:16] = CMD_RESET;

      ST_RD_CS:
        wshr[23:16] = CMD_READ;

      ST_RD_CMD:
        if (cnt_r == 8 * TICK - 2)
          wshr = addr_r;
    endcase
  end

  always_ff @(posedge clk_100mhz)
    wshr_r <= wshr;

  /*
   * Serial input
   */
  assign rshr = !(cnt_r & 1) ? {rshr_r[6:0], miso} : rshr_r;

  always_ff @(posedge clk_100mhz)
    rshr_r <= rshr;

  always_comb begin
    data = data_r;

    if (state_r == ST_RD_DATA && cnt_r == 8 * TICK - 1)
      data = rshr_r;
  end

  always_ff @(posedge clk_100mhz, negedge nrst)
    if (!nrst)
      data_r <= 0;
    else
      data_r <= data;

  /*
   * State and counter handling
   */
  always_comb begin
    state = state_r;
    cnt   = cnt_r + 1;

    case (state_r)
      ST_WAIT:
        if (cnt_r == MS - 1) begin
          state = ST_RESET_CS;
          cnt   = 0;
        end

      ST_RESET_CS:
        if (cnt_r == TICK - 1) begin
          state = ST_RESET_CMD;
          cnt   = 0;
        end

      ST_RESET_WAIT:
        if (cnt_r == MS - 1) begin
          state = ST_RD_CS;
          cnt   = 0;
        end

      ST_RD_CS:
        if (cnt_r == TICK - 1) begin
          state = ST_RD_CMD;
          cnt   = 0;
        end

      ST_RD_ADDR:
        if (cnt_r == 24 * TICK - 1) begin
          state = ST_RD_DATA;
          cnt   = 0;
        end

      ST_RD_WAIT:
        if (cnt_r == SEC - 1) begin
          state = ST_RD_CS;
          cnt   = 0;
        end

      default:
        if (cnt_r == 8 * TICK - 1) begin
          state = state_t'(state_r + 1);
          cnt   = 0;
        end
    endcase
  end

  always_ff @(posedge clk_100mhz, negedge nrst)
    if (!nrst) begin
      state_r <= ST_WAIT;
      cnt_r   <= 0;
    end else begin
      state_r <= state;
      cnt_r   <= cnt;
    end

  /*
   * SPI output signals
   */ 
  assign mosi = wshr_r[23];
  assign sclk = sclk_en_r ? clk_50mhz : 1;
  assign wpn  = 1;
  assign rstn = 1;
  assign csn  = !cs_r;

  /*
   * Other output signals
   */
  assign out = data_r;
endmodule
