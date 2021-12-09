//! This process element is multiply inputs and accumulate
//! with the previous value
//! The number of inputs to be multiplied is determined by
//!WCOUNT: word(4-bit) count
`timescale  1ns / 1ps
module PE #(parameter WCOUNT = 4 )
  (
    input logic rst,
    input logic clk,
    input logic en,
    input logic clr,
    //! Matrice multiplicant
    input logic [WCOUNT*4-1 : 0] M,
    //! SHA3 multiplicant
    input logic [WCOUNT*4-1 : 0] X,
    output logic [13 : 0] PE_out
  );

  //! This task provides the M0X0, M0X1, M1X0, M1X1 multiplications using one DSP by combining the multiplication
  //! in the following manner:
  //!     {M1, 8'd0, M0}
  //!     {X1, 8'd0, X0}
  //! *----------------
  //! M1*X1 16'd0 M0*X0
  task automatic dsp_mult(
      input [WCOUNT-1:0] M0,
      input [WCOUNT-1:0] M1,
      input [WCOUNT-1:0] X0,
      input [WCOUNT-1:0] X1,
      output [2*WCOUNT-1:0] M0X0,
      output [2*WCOUNT-1:0] M1X1
    );
    begin
      logic [8*WCOUNT -1 : 0] mult_out;
      logic [4*WCOUNT -1 : 0] mult_in0;
      logic [4*WCOUNT -1 : 0] mult_in1;


      mult_in0 = {M1, {2*WCOUNT{1'b0}},M0};
      mult_in1 = {X1, {2*WCOUNT{1'b0}},X0};
      mult_out = mult_in0 * mult_in1;
      M0X0 = mult_out[2*WCOUNT - 1 : 0];
      M1X1 = mult_out[8*WCOUNT - 1 : 8*WCOUNT - 8];
    end
  endtask //automatic

  //TODO: make it generic in respect to WCOUNT
  logic [7 :0] mul[WCOUNT-1:0];
  logic [7 :0] mul_reg[WCOUNT-1:0];
  logic [13 : 0] sum[WCOUNT : 0];
  logic [13 : 0] PE_reg;
  logic [13 : 0] sum_m;

  //! Multiplying and accumulation operation
  //assign sum[0] = PE_reg;
  // assign mul[0] = M[3:0]   * X[3:0];
  // assign mul[1] = M[7:4]   * X[7:4];
  // assign mul[2] = M[11:8]  * X[11:8];
  // assign mul[3] = M[15:12] * X[15:12];

  //TODO: make it generic in respect to WCOUNT
  always_comb
  begin : dsb_blks
    dsp_mult(M[3:0],M[7:4],X[3:0],X[7:4],mul[0],mul[1]);
  end
  assign mul[2] = M[11:8]  * X[11:8];
  assign mul[3] = M[15:12] * X[15:12];


  //TODO: make it generic in respect to WCOUNT
  assign sum_m = PE_reg + {6'd0,mul_reg[0]} + {6'd0,mul_reg[1]} + {6'd0,mul_reg[2]} + {6'd0,mul_reg[3]};



  //!pe_reg register generation
  always_ff @(posedge clk )
  begin : pe_reg_blk
    if(rst | clr)
    begin
      PE_reg <= #1 14'd0;
      mul_reg[0] <= #1 8'd0;
      mul_reg[1] <= #1 8'd0;
      mul_reg[2] <= #1 8'd0;
      mul_reg[3] <= #1 8'd0;
    end
    else
    begin
      if(en)
      begin
        PE_reg <= #1 sum_m;
        mul_reg[0] <= #1 mul[0];
        mul_reg[1] <= #1 mul[1];
        mul_reg[2] <= #1 mul[2];
        mul_reg[3] <= #1 mul[3];
      end
    end
  end
  assign PE_out = PE_reg;
endmodule
