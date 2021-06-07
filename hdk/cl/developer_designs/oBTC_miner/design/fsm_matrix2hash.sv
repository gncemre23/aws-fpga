//! The module to generate data from matrix out for fifo_input
//! of the sha3_out

module fsm_matrix2hash (
    input logic clk,
    input logic rst,
    input logic we_in,
    input logic [63:0] din,

    output logic we_out,
    output logic [63:0] dout
  );

  logic [2:0] state;
  logic [63:0] din_reg;

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
          if(we_in)
          begin
            state <= 1;
            dout <= 64'h8000000000000100;
            we_out <= 1'b1;
            din_reg <= din;
          end
          else begin
            state <= state;
            dout <= dout;
            we_out <= 1'b0;
            din_reg <= din;
          end

        end
        1:
        begin
          we_out <= 1'b1;
          din_reg <= din;
          dout <= din_reg;
          state <= 2;
        end
        2:
        begin
          we_out <= 1'b1;
          din_reg <= din;
          dout <= din_reg;
          state <= 3;
        end
        3:
        begin
          we_out <= 1'b1;
          din_reg <= din;
          dout <= din_reg;
          state <= 4;
        end
        4:
        begin
          we_out <= 1'b1;
          din_reg <= din;
          dout <= din_reg;
          state <= 0;
        end
      endcase
    end
  end

endmodule
