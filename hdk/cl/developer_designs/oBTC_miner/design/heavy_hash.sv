//TODO draw new diagram regarding the new code
//!Heavy hash core 
//!     ┌──────────────┐         ┌───────┐
//!     │              │         │       │
//!────►│hashin_fifo_in├────────►│sha3_in│
//!     │              │         │       │
//!     └──────────────┘         └───┬───┘
//!                                  │
//!                                  ▼
//!                              ┌───────────────┐
//!                              │hashin_fifout  │
//!                              │               │
//!                              └────┬──────────┘
//!                                   │
//!                                   │
//!                                   ▼
//!    ┌────────────────┐        ┌───────────┐
//!───►│ matrix_fifo_in │        │matrix_mult│
//!    │                ├───────►│           │
//!    └────────────────┘        └────┬──────┘
//!                                   │
//!                                   ▼
//!                              ┌───────────────┐
//!                              │matrix_fifo_out│
//!                              │               │
//!                              └────┬──────────┘
//!                                   │
//!                                   │
//!                              ┌────▼───┐                 ┌────────────────┐
//!                              │sha3_out├────────────────►│hashout_fifo_out│────►│
//!                              │        │                 │                │
//!                              └────────┘                 └────────────────┘

`timescale  1ns / 1ps
module heavy_hash #(parameter WCOUNT = 4 )
  (
    //!global clk
    input logic clk,
    //!global reset
    input logic rst,

    /*ports of hash_in_fifo_in*/
    //!write enable of hashin_fifo_in
    input logic hashin_fifo_in_we,
    //!64-bit data in of hashin_fifo_in
    input logic [63:0] hashin_fifo_in_din,
    //!full flag of hash_in_fifo_in
    output logic hashin_fifo_in_full,



    /*ports of matrix_in_fifo_in*/
    //!write enable of matrix_fifo_in
    input logic matrix_fifo_in_we,
    //!32-bit data in of matrix_fifo_in
    input logic [31:0] matrix_fifo_in_din,
    //!full flag of matrix_fifo_in
    output logic matrix_fifo_in_full,


    /*ports of hashout_fifo_in*/
    //!read enable of hashout_fifo_out
    input logic hashout_fifo_out_re,
    //!64-bit data out of hashout_fifo_out
    output logic [255:0] hashout_fifo_out_dout,
    //!empty flag of hashout_fifo_in_fifo_in
    output logic hashout_fifo_out_empty,
    //!nonce fifo full flag
    output logic nonce_fifo_full,
    //!nonce fifo data in
    input logic [31:0] nonce_fifo_din,
    //!nonce fifo write enable
    input logic nonce_fifo_we,
    //!nonce output
    output logic [31:0] nonce,
    //! or operation of the empty signals of all fifos
    output logic heavy_hash_all_empty
  );

  /*internal signal definitions for hashin_fifo_in*/
  //!64-bit data out of hashin_fifo_in
  logic [63 : 0] hashin_fifo_in_dout;
  //!read enable of hashin_fifo_in
  logic hashin_fifo_in_re;
  //!empty flag of hashin_fifo_in
  logic hashin_fifo_in_empty;


  /*internal signal definitions for matrix_fifo_in*/
  //!data out of matrix_fifo_in
  logic [WCOUNT*4 - 1 : 0] matrix_fifo_in_dout;
  //!read enable of matrix_fifo_in
  logic matrix_fifo_in_re;
  //!empty flag of matrix_fifo_in
  logic matrix_fifo_in_empty;

  /*internal signal definitions for hashin_fifo_out*/
  //!data in of hashin_fifo_out
  logic [255 : 0] hashin_fifo_out_din;
  //!data out of hashin_fifo_out
  logic [WCOUNT*4 - 1 : 0] hashin_fifo_out_dout;
  //!read enable of hashin_fifo_out
  logic hashin_fifo_out_re;
  //!write enable of hashin_fifo_out
  logic hashin_fifo_out_we;
  //!empty flag of hashin_fifo_out
  logic hashin_fifo_out_empty;
  //!full flag of hashin_fifo_out
  logic hashin_fifo_out_full;

  /*internal signal definitions for matrix_fifo_out*/
  //!data in of matrix_fifo_out
  logic [63 : 0] matrix_fifo_out_din;
  //!data out of matrix_fifo_out
  logic [63 : 0] matrix_fifo_out_dout;
  //!read enable of matrix_fifo_out
  logic matrix_fifo_out_re;
  //!write enable of matrix_fifo_out
  logic matrix_fifo_out_we;
  //!empty flag of matrix_fifo_out
  logic matrix_fifo_out_empty;
  //!full flag of matrix_fifo_out
  logic matrix_fifo_out_full;

  /*internal signal definitions for hashout_fifo_out*/
  //!data in of hashout_fifo_out
  logic [255 : 0] hashout_fifo_out_din;
  //!write enable of hashout_fifo_out
  logic hashout_fifo_out_we;
  //!full flag of hashout_fifo_out
  logic hashout_fifo_out_full;

  /*internal signal definitions for sha3in*/
  logic sha3in_dst_write;
  logic [63 : 0] sha3in_dout;

  /*internal signal definitions for sha3out*/
  logic sha3out_dst_write;
  logic [63 : 0] sha3out_dout;



  logic [63:0] matrix_out;
  logic matrix_out_we;

  logic  [63:0] sha3_result_dout;
  logic sha3_result_full;
  logic sha3_result_empty;

  logic nonce_fifo_empty;


  assign heavy_hash_all_empty = nonce_fifo_empty & hashin_fifo_in_empty 
                                  & sha3_result_empty  & hashin_fifo_out_empty 
                                  & matrix_fifo_in_empty & matrix_fifo_out_empty
                                  & hashout_fifo_out_empty;
                                
  fifo_in_out
    #(
      .DINWIDTH(32 ),
      .DOUTWIDTH (32),
      .DEPTH(128)
    )
    nonce_fifo (
      .clk (clk ),
      .rst (rst ),
      .wr_en (nonce_fifo_we ),
      .rd_en (hashout_fifo_out_we ),
      .din (nonce_fifo_din ),
      .dout (nonce ),
      .full (nonce_fifo_full ),
      .empty  ( nonce_fifo_empty)
    );


  fifo_in_out
    #(
      .DINWIDTH(64 ),
      .DOUTWIDTH (64),
      .DEPTH(128)
    )
    hashin_fifo_in (
      .clk (clk ),
      .rst (rst ),
      .wr_en (hashin_fifo_in_we ),
      .rd_en (hashin_fifo_in_re ),
      .din (hashin_fifo_in_din ),
      .dout (hashin_fifo_in_dout ),
      .full (hashin_fifo_in_full ),
      .empty  ( hashin_fifo_in_empty)
    );


  keccak_top
    #(.HS(256))
    sha3_in (
      .rst(rst),
      .clk(clk),
      .src_ready(hashin_fifo_in_empty),
      .src_read(hashin_fifo_in_re),
      .dst_ready(hashin_fifo_out_full | sha3_result_full),
      .dst_write(sha3in_dst_write),
      .din(hashin_fifo_in_dout),
      .dout(sha3in_dout)
    );
  //! The fifo in order to hold values for XOR operations
  fifo_in_out
    #(
      .DINWIDTH(64 ),
      .DOUTWIDTH (64),
      .DEPTH(128)
    )
    sha3_result_fifo (
      .clk (clk ),
      .rst (rst ),
      .wr_en (sha3in_dst_write ),
      .rd_en (matrix_out_we ),
      .din (sha3in_dout ),
      .dout (sha3_result_dout ),
      .full (sha3_result_full ),
      .empty  ( sha3_result_empty)
    );

  //TODO: Better way is to change the sha3 to generate 256-bit output
  fsm_64to256 fsm64to256_in
              (
                .clk(clk),
                .rst(rst),
                .we_in(sha3in_dst_write),
                .din(sha3in_dout),
                .we_out(hashin_fifo_out_we),
                .dout(hashin_fifo_out_din)
              );

  fifo_in_out
    #(
      .DINWIDTH(256 ),
      .DOUTWIDTH (WCOUNT * 4),
      .DEPTH(128)
    )
    hashin_fifo_out (
      .clk (clk ),
      .rst (rst ),
      .wr_en (hashin_fifo_out_we ),
      .rd_en (hashin_fifo_out_re ),
      .din (hashin_fifo_out_din ),
      .dout (hashin_fifo_out_dout ),
      .full (hashin_fifo_out_full ),
      .empty  ( hashin_fifo_out_empty)
    );

  fifo_in_out
    #(
      .DINWIDTH(32 ),
      .DOUTWIDTH (WCOUNT * 4 ),
      .DEPTH(512)
    )
    Matrix_fifo_in (
      .clk (clk ),
      .rst (rst ),
      .wr_en (matrix_fifo_in_we ),
      .rd_en (matrix_fifo_in_re ),
      .din (matrix_fifo_in_din ),
      .dout (matrix_fifo_in_dout ),
      .full (matrix_fifo_in_full ),
      .empty  ( matrix_fifo_in_empty)
    );


  matrix_top
    #(
      .WCOUNT (WCOUNT )
    )
    matrix_inst (
      .clk (clk ),
      .rst (rst ),
      .m_empty (matrix_fifo_in_empty ),
      .hashin_empty (hashin_fifo_out_empty ),
      .hashin_dout (hashin_fifo_out_dout ),
      .m_dout (matrix_fifo_in_dout ),
      .m_re (matrix_fifo_in_re ),
      .hashin_re (hashin_fifo_out_re ),
      .hashout_we (matrix_out_we ),
      .hashout_din  ( matrix_out)
    );

  fifo_in_out
    #(
      .DINWIDTH(64 ),
      .DOUTWIDTH (64 ),
      .DEPTH(128)
    )
    Matrix_fifo_out (
      .clk (clk ),
      .rst (rst ),
      .wr_en (matrix_fifo_out_we ),
      .rd_en (matrix_fifo_out_re ),
      .din (matrix_fifo_out_din ),
      .dout (matrix_fifo_out_dout ),
      .full (matrix_fifo_out_full ),
      .empty  ( matrix_fifo_out_empty)
    );

  fsm_matrix2hash
    fsm_matrix2hash_inst
    (.clk(clk),
     .rst(rst),
     .we_in(matrix_out_we),
     .we_out(matrix_fifo_out_we),
     .din(matrix_out ^ sha3_result_dout),
     .dout(matrix_fifo_out_din)
    );


  keccak_top
    #(.HS(256))
    sha3_out (
      .rst(rst),
      .clk(clk),
      .src_ready(matrix_fifo_out_empty),
      .src_read(matrix_fifo_out_re),
      .dst_ready(hashout_fifo_out_full),
      .dst_write(sha3out_dst_write),
      .din(matrix_fifo_out_dout),
      .dout(sha3out_dout)
    );
  //TODO: Better way is to change the sha3 to generate 256-bit output
  fsm_64to256 fsm64to256_out
              (
                .clk(clk),
                .rst(rst),
                .we_in(sha3out_dst_write),
                .din(sha3out_dout),
                .we_out(hashout_fifo_out_we),
                .dout(hashout_fifo_out_din)
              );




  fifo_in_out
    #(
      .DINWIDTH(256 ),
      .DOUTWIDTH (256),
      .DEPTH(128)
    )
    hashout_fifo_out (
      .clk (clk ),
      .rst (rst ),
      .wr_en (hashout_fifo_out_we ),
      .rd_en (hashout_fifo_out_re ),
      .din (hashout_fifo_out_din ),
      .dout (hashout_fifo_out_dout ),
      .full (hashout_fifo_out_full ),
      .empty  ( hashout_fifo_out_empty)
    );


endmodule
