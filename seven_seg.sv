module seven_seg(
  input  logic       clk_100mhz,
  input  logic       nrst,

  output logic       ca,
  output logic       cb,
  output logic       cc,
  output logic       cd,
  output logic       ce,
  output logic       cf,
  output logic       cg,
  output logic       dp,
  output logic [7:0] an,

  input  logic [3:0] val,
  input  logic       d,
  input  logic       valid,
  output logic [2:0] can
);
  localparam ZERO   = 7'b000_0001;
  localparam ONE    = 7'b100_1111;
  localparam TWO    = 7'b001_0010;
  localparam THREE  = 7'b000_0110;
  localparam FOUR   = 7'b100_1100;
  localparam FIVE   = 7'b010_0100;
  localparam SIX    = 7'b010_0000;
  localparam SEVEN  = 7'b000_1111;
  localparam EIGHT  = 7'b000_0000;
  localparam NINE   = 7'b000_0100;
  localparam CHAR_A = 7'b000_1000;
  localparam CHAR_B = 7'b110_0000;
  localparam CHAR_C = 7'b111_0010;
  localparam CHAR_D = 7'b100_0010;
  localparam CHAR_E = 7'b011_0000;
  localparam CHAR_F = 7'b011_1000;
  localparam NONE   = 7'b111_1111;

  localparam STEP   = 10000;

  logic [13:0] cnt, cnt_r;
  logic [2:0]  idx, idx_r;

  /*
   * Counter and anode selection
   */
  always_comb begin
    cnt = cnt_r + 1;
    idx = idx_r;

    if (cnt_r == STEP - 1) begin
      cnt = 0;
      idx = idx_r + 1;
    end
  end

  always_ff @(posedge clk_100mhz, negedge nrst)
    if (!nrst) begin
      cnt_r <= 0;
      idx_r <= 0;
    end else begin
      cnt_r <= cnt;
      idx_r <= idx;
    end

  always_comb
    case (idx_r)
      0: an = 8'b1111_1110;
      1: an = 8'b1111_1101;
      2: an = 8'b1111_1011;
      3: an = 8'b1111_0111;
      4: an = 8'b1110_1111;
      5: an = 8'b1101_1111;
      6: an = 8'b1011_1111;
      7: an = 8'b0111_1111;
    endcase

  /*
   * Segment setting
   */
  assign dp = !(valid && d);

  always_comb
    if (valid)
      case (val)
        0:  {ca, cb, cc, cd, ce, cf, cg} = ZERO;
        1:  {ca, cb, cc, cd, ce, cf, cg} = ONE;
        2:  {ca, cb, cc, cd, ce, cf, cg} = TWO;
        3:  {ca, cb, cc, cd, ce, cf, cg} = THREE;
        4:  {ca, cb, cc, cd, ce, cf, cg} = FOUR;
        5:  {ca, cb, cc, cd, ce, cf, cg} = FIVE;
        6:  {ca, cb, cc, cd, ce, cf, cg} = SIX;
        7:  {ca, cb, cc, cd, ce, cf, cg} = SEVEN;
        8:  {ca, cb, cc, cd, ce, cf, cg} = EIGHT;
        9:  {ca, cb, cc, cd, ce, cf, cg} = NINE;
        10: {ca, cb, cc, cd, ce, cf, cg} = CHAR_A;
        11: {ca, cb, cc, cd, ce, cf, cg} = CHAR_B;
        12: {ca, cb, cc, cd, ce, cf, cg} = CHAR_C;
        13: {ca, cb, cc, cd, ce, cf, cg} = CHAR_D;
        14: {ca, cb, cc, cd, ce, cf, cg} = CHAR_E;
        15: {ca, cb, cc, cd, ce, cf, cg} = CHAR_F;
      endcase
    else
      {ca, cb, cc, cd, ce, cf, cg} = NONE;

  /*
   * Other outputs
   */
  assign can = idx_r;
endmodule
