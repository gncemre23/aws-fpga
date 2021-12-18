`timescale  1ns / 1ps
module counter
  (
    input logic rst,
    input logic clk,
    input logic ld,
    input logic [6:0] ld_data,
    input logic en,
    output logic [6:0]counter_out
  );

  always_ff @( posedge clk ) begin : seq
    if(rst)
        counter_out <= 7'd0;
    else if(ld)
        counter_out <= ld_data;
    else if (en)
        counter_out <= counter_out + 7'd1;
  end


endmodule
