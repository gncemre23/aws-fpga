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
  logic [7 :0] mul_reg_reg[WCOUNT-1:0];
  logic [13 : 0] sum[WCOUNT : 0];
  logic [13 : 0] PE_reg;
  logic [13 : 0] PE_reg_reg;
  logic [13 : 0] sum_m;
  logic [35 : 0] mult_out;
  
  logic [17 : 0] mult_in_A;
  logic [17 : 0] mult_in_B;


  logic delayed_clr;
  logic delayed_clr_reg;

  assign mult_in_A = (!delayed_clr) ? {2'b0,M[7:4], 8'd0, M[3:0]} : 18'd0;
  assign mult_in_B = (!delayed_clr) ? {2'b0,X[7:4], 8'd0, X[3:0]} : 18'd0;

  MULT_MACRO #(
               .DEVICE("7SERIES"), // Target Device: "7SERIES"
               .LATENCY(2),        // Desired clock cycle latency, 0-4
               .WIDTH_A(18),       // Multiplier A-input bus width, 1-25
               .WIDTH_B(18)        // Multiplier B-input bus width, 1-18
             ) MULT_MACRO_inst (
               .P(mult_out),     // Multiplier output bus, width determined by WIDTH_P parameter
               .A(mult_in_A),     // Multiplier input A bus, width determined by WIDTH_A parameter
               .B(mult_in_B),     // Multiplier input B bus, width determined by WIDTH_B parameter
               .CE(1'b1),   // 1-bit active high input clock enable
               .CLK(clk), // 1-bit positive edge clock input
               .RST(delayed_clr | rst)  // 1-bit input active high reset
             );

  
  // always_comb
  // begin
  //   dsp_mult(M[3:0], M[7:4], X[3:0], X[7:4], mul[0], mul[1]);
  // end

  logic [7:0] mul2;
  logic [7:0] mul3;


  assign mul2 = M[11:8]  * X[11:8];
  assign mul3 = M[15:12] * X[15:12];

  assign mul[0] = mult_out[7:0] & {~delayed_clr,~delayed_clr,~delayed_clr,~delayed_clr,~delayed_clr,~delayed_clr,~delayed_clr,~delayed_clr};
  assign mul[1] = mult_out[31:24] & {~delayed_clr,~delayed_clr,~delayed_clr,~delayed_clr,~delayed_clr,~delayed_clr,~delayed_clr,~delayed_clr};
  assign mul[2] = mul2 & {~delayed_clr,~delayed_clr,~delayed_clr,~delayed_clr,~delayed_clr,~delayed_clr,~delayed_clr,~delayed_clr};
  assign mul[3] = mul3 & {~delayed_clr,~delayed_clr,~delayed_clr,~delayed_clr,~delayed_clr,~delayed_clr,~delayed_clr,~delayed_clr};


  //TODO: make it generic in respect to WCOUNT
  assign sum_m = PE_reg + {6'd0,mul[0]} + {6'd0,mul[1]} + {6'd0,mul_reg_reg[2]} + {6'd0,mul_reg_reg[3]};



  //!pe_reg register generation
  always_ff @(posedge clk )
  begin : pe_reg_blk
    delayed_clr <= clr;
    delayed_clr_reg <= delayed_clr;
    if(rst | clr)
    begin
      PE_reg         <= 14'd0;
      PE_reg_reg     <= 14'd0;
      mul_reg[0]     <= 8'd0;
      mul_reg[1]     <= 8'd0;
      mul_reg[2]     <= 8'd0;
      mul_reg[3]     <= 8'd0;
      mul_reg_reg[0] <= 8'd0;
      mul_reg_reg[1] <= 8'd0;
      mul_reg_reg[2] <= 8'd0;
      mul_reg_reg[3] <= 8'd0;
    end
    else
    begin
      if(en)
      begin
        PE_reg         <= sum_m;
        PE_reg_reg     <= PE_reg;
        mul_reg[0]     <= mul[0];
        mul_reg[1]     <= mul[1];
        mul_reg[2]     <= mul[2];
        mul_reg[3]     <= mul[3];
        mul_reg_reg[0] <= mul_reg[0];
        mul_reg_reg[1] <= mul_reg[1];
        mul_reg_reg[2] <= mul_reg[2];
        mul_reg_reg[3] <= mul_reg[3];
      end
    end
  end
  assign PE_out = PE_reg;
endmodule
