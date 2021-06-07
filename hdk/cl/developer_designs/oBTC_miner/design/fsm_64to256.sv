//! The module to collecting 64-bit data for 4 clk cycle
//! and generate 256-bit output

module fsm_64to256 (
    input logic clk,
    input logic rst,
    input logic we_in,
    input logic [63:0] din,

    output logic we_out,
    output logic [255:0] dout
  );

  logic [1:0] state;

  always_ff @( posedge clk )
  begin : seq
    if(rst)
    begin
      we_out <= 1'b0;
      dout <= 256'd0;
      state <= 0;
    end
    else
    begin
      case (state)
        0:
        begin
          we_out <= 1'b0;
          if(we_in)
          begin
            state <= 1;
            dout[255:192] <= din;
          end
        end
        1:
        begin
          we_out <= 1'b0;
          dout[191:128] <= din;
          state <= 2;
        end
        2:
        begin
          we_out <= 1'b0;
          dout[127:64] <= din;
          state <= 3;
        end
        3:
        begin
          we_out <= 1'b1;
          dout[63:0] <= din;
          state <= 0;
        end
      endcase
    end
  end

endmodule
