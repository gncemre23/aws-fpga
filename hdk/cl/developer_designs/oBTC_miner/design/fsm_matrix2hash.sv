//! The module to generate data from matrix out for fifo_input
//! of the sha3_out

module fsm_matrix2hash (
    input logic clk,
    input logic rst,
    input logic we_in,
    input logic [63:0] din,
    input logic fifo_full,

    output logic we_out,
    output logic [63:0] dout
  );


  typedef enum {
            WRITE_HEADER,
            WRITE_DATA0,
            WRITE_DATA1,
            WRITE_DATA2,
            WRITE_DATA3} state_type;
  state_type state_reg, state_next;

  logic [63:0] din_next, din_reg;

  always_ff @( posedge clk )
  begin
    if(rst)
    begin
      state_reg <= WRITE_HEADER;
      din_reg <= 64'd0;
    end
    else
    begin
      state_reg <= state_next;
      din_reg <= din_next;
    end
  end

  always_comb
  begin
    //default assignments
    state_next = state_reg;
    dout = 64'd0;
    we_out = 1'b0;
    din_next = din_reg;
    case(state_reg)
      WRITE_HEADER:
        if(we_in)
        begin
          state_next = WRITE_DATA0;
          dout = 64'h8000000000000100;
          we_out = 1'b1;
          din_next = din;
        end

      WRITE_DATA0:
        if(we_in)
        begin
          state_next = WRITE_DATA1;
          dout = din_reg;
          we_out = 1'b1;
          din_next = din;
        end

      WRITE_DATA1:
        if(we_in)
        begin
          state_next = WRITE_DATA2;
          dout = din_reg;
          we_out = 1'b1;
          din_next = din;
        end

      WRITE_DATA2:
        if(we_in)
        begin
          state_next = WRITE_DATA3;
          dout = din_reg;
          we_out = 1'b1;
          din_next = din;
        end

      WRITE_DATA3:
      begin
        state_next = WRITE_HEADER;
        dout = din_reg;
        we_out = 1'b1;
        din_next = din;
      end

    endcase
    ;
  end



endmodule
