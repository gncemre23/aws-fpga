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
  logic [7 :0] mul[WCOUNT-1:0];
  logic [7 :0] mul_reg[WCOUNT-1:0];
  logic [13 : 0] sum[WCOUNT : 0];
  logic [13 : 0] PE_reg;
  logic [13 : 0] sum_m;

  //! Multiplying and accumulation operation
  //assign sum[0] = PE_reg;
  assign mul[0] = M[3:0]   * X[3:0];
  assign mul[1] = M[7:4]   * X[7:4];
  assign mul[2] = M[11:8]  * X[11:8];
  assign mul[3] = M[15:12] * X[15:12];
  
  assign sum_m = PE_reg + mul_reg[0] + mul_reg[1] + mul_reg[2] + mul_reg[3];
  
  
  
//agenvar  i;
//  generate
//    for ( i = 0 ;i < WCOUNT/2 ; i = i + 1 )
//    begin
//      assign mul[i] = M[(i+1)*4 -1 : (i+1)*4 -4] * X[(i+1)*4 -1 : (i+1)*4 -4];
//      assign sum[i+1] = sum[i] + {6'd0,mul[i]};
//    end
    
    
//  endgenerate

  //!pe_reg register generation
  always_ff @(posedge clk )
  begin : pe_reg_blk
    if(rst | clr) begin
      PE_reg <= #1 14'd0;
      mul_reg[0] <= #1 8'd0;
      mul_reg[1] <= #1 8'd0;
      mul_reg[2] <= #1 8'd0;
      mul_reg[3] <= #1 8'd0;
    end
    else begin
      if(en) begin
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
