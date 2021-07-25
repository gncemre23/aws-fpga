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


  typedef enum { READ0,
                 READ1,
                 READ2,
                 READ3,
                 WRITE_HEADER,
                 WRITE_DATA0,
                 WRITE_DATA1,
                 WRITE_DATA2,
                 WRITE_DATA3} state_type;
  state_type state_reg, state_next;

  logic [63:0] din_reg;
  logic [63:0] data_next0, data_reg0;
  logic [63:0] data_next1, data_reg1;
  logic [63:0] data_next2, data_reg2;
  logic [63:0] data_next3, data_reg3;

  always_ff @( posedge clk )
  begin
    if(rst)
    begin
      state_reg <= READ0;
      data_reg0 <= 64'd0;
      data_reg1 <= 64'd0;
      data_reg2 <= 64'd0;
      data_reg3 <= 64'd0;
    end
    else
    begin
      state_reg <= state_next;
      data_reg0 <= data_next0;
      data_reg1 <= data_next1;
      data_reg2 <= data_next2;
      data_reg3 <= data_next3;
    end
  end

  always_comb 
  begin
    //default assignments
    state_next = state_reg;
    data_next0 = data_reg0;
    data_next1 = data_reg1;
    data_next2 = data_reg2;
    data_next3 = data_reg3;
    dout = 64'd0;
    we_out = 1'b0;

    case(state_reg)
    READ0:
    begin
      if(we_in)
      begin
        state_next = READ1;
        data_next0 = din;
      end
    end
    READ1:
    begin
      state_next = READ2;
      data_next1 = din;
    end
    READ2:
    begin
      state_next = READ3;
      data_next2 = din;
    end
    READ3:
    begin
      state_next = WRITE_HEADER;
      data_next3 = din;
    end
    WRITE_HEADER:
    begin
      if(!fifo_full)
      begin
        state_next = WRITE_DATA0;
        dout = 64'h8000000000000100;
        we_out = 1'b1;
      end
    end
    WRITE_DATA0:
    begin
      if(!fifo_full)
      begin
        state_next = WRITE_DATA1;
        dout = data_reg0;
        we_out = 1'b1;
      end
    end
    WRITE_DATA1:
    begin
      if(!fifo_full)
      begin
        state_next = WRITE_DATA2;
        dout = data_reg1;
        we_out = 1'b1;
      end
    end
    WRITE_DATA2:
    begin
      if(!fifo_full)
      begin
        state_next = WRITE_DATA3;
        dout = data_reg2;
        we_out = 1'b1;
      end
    end
    WRITE_DATA3:
    begin
      if(!fifo_full)
      begin
        state_next = READ0;
        dout = data_reg3;
        we_out = 1'b1;
      end
    end

    endcase;
  end

  

endmodule
