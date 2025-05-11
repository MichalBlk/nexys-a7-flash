module top(
  input  logic        CLK100MHZ,
  input  logic        CPU_RESETN,

  output logic [15:0] LED,

  output logic        CA,
  output logic        CB,
  output logic        CC,
  output logic        CD,
  output logic        CE,
  output logic        CF,
  output logic        CG,
  output logic        DP,
  output logic [7:0]  AN,

  input  logic        QSPI_MISO,
  output logic        QSPI_MOSI,
  output logic        QSPI_WPN,
  output logic        QSPI_RESETN,
  output logic        QSPI_CSN
);
  logic       qspi_sclk;
  logic [3:0] dc;

  logic [7:0] fl_out;

  STARTUPE2 STARTUPE2_0(
    .CFGCLK    (dc[0]),
    .CFGMCLK   (dc[1]),
    .EOS       (dc[2]),
    .PREQ      (dc[3]),
    .CLK       (0),
    .GSR       (0),
    .GTS       (0),
    .KEYCLEARB (0),
    .PACK      (0),
    .USRCCLKO  (qspi_sclk),
    .USRCCLKTS (0),
    .USRDONEO  (1),
    .USRDONETS (1)
  );

  flash FLASH(
    .clk_100mhz (CLK100MHZ),
    .nrst       (CPU_RESETN),
    .miso       (QSPI_MISO),
    .mosi       (QSPI_MOSI),
    .sclk       (qspi_sclk),
    .wpn        (QSPI_WPN),
    .rstn       (QSPI_RESETN),
    .csn        (QSPI_CSN),
    .out        (fl_out)
  );

  /*
   * Seven-segment display handling
   */
  logic [3:0] ss_val;
  logic       ss_valid;
  logic [2:0] ss_can;

  assign ss_val   = !ss_can ? fl_out[3:0] : fl_out[7:4];
  assign ss_valid = !ss_can || ss_can == 1;

  seven_seg SEVEN_SEG(
    .clk_100mhz (CLK100MHZ),
    .nrst       (CPU_RESETN),
    .ca         (CA),
    .cb         (CB),
    .cc         (CC),
    .cd         (CD),
    .ce         (CE),
    .cf         (CF),
    .cg         (CG),
    .dp         (DP),
    .an         (AN),
    .val        (ss_val),
    .d          (0),
    .valid      (ss_valid),
    .can        (ss_can)
  );

  /*
   * Other output signals
   */
  assign LED = fl_out;
endmodule
