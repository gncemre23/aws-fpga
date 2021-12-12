`timescale  1ns / 1ps
module pipeLine
  //! REGCNT = 1 - 5
  #(parameter DWIDTH = 32, parameter REGCNT = 1)
   (
     input logic clk,
     input logic [DWIDTH - 1 : 0] din,
     output logic [DWIDTH - 1 : 0] dout
   );
  logic [DWIDTH - 1 : 0] data_reg [0:4];

  always_ff @( posedge clk )
  begin : blockName
    data_reg[0] <= din;
    data_reg[1] <= data_reg[0];
    data_reg[2] <= data_reg[1];
    data_reg[3] <= data_reg[2];
    data_reg[4] <= data_reg[3];
  end

  assign dout = data_reg[REGCNT - 1];

endmodule
