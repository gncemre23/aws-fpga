//! The module to collecting 64-bit data for 4 clk cycle
//! and generate 256-bit output

module fsm_sha3_fifo (
    input logic clk,
    input logic rst,
    input logic we_in,
    input logic fifo_full,
    input logic [63:0] din,
    output logic ready,
    output logic fifo_we,
    output logic [63:0] dout
  );




  typedef enum {
            READ_HASH0,
            READ_HASH1,
            READ_HASH2,
            READ_HASH3,
            WRITE_FIFO0,
            WRITE_FIFO1,
            WRITE_FIFO2,
            WRITE_FIFO3
          } state_type;

  state_type state_next, state_reg;
  logic [255:0] hash_next, hash_reg;


  always_ff @( posedge clk )
  begin
    if(rst)
    begin
      state_reg <= READ_HASH0;
      hash_reg <= 256'd0;
    end
    else
    begin
      state_reg <= state_next;
      hash_reg <= hash_next;
    end

  end

  always_comb
  begin
    //default assignments
    hash_next = hash_reg;
    ready  = 1'b1;
    dout = 64'd0;
    fifo_we = 1'b0;
    state_next = state_reg;
    case (state_reg)
      READ_HASH0:
      begin
        ready = 1'b0;
        if(we_in)
        begin
          hash_next[255:192] = din;
          state_next = READ_HASH1;
        end
      end

      READ_HASH1:
      begin
        ready = 1'b0;
        if(we_in)
        begin
          hash_next[191:128] = din;
          state_next = READ_HASH2;
        end
      end

      READ_HASH2:
      begin
        ready = 1'b0;
        if(we_in)
        begin
          hash_next[127:64] = din;
          state_next = READ_HASH3;
        end
      end

      READ_HASH3:
      begin
        ready = 1'b0;
        if(we_in)
        begin
          hash_next[63:0] = din;
          state_next = WRITE_FIFO0;
        end
      end
      WRITE_FIFO0:
      begin
        ready = 1'b1;
        if(!fifo_full)
        begin
          fifo_we = 1'b1;
          dout = hash_reg[63:0];
          state_next = WRITE_FIFO1;
        end
      end

      WRITE_FIFO1:
      begin
        ready = 1'b1;
        if(!fifo_full)
        begin
          fifo_we = 1'b1;
          dout = hash_reg[127:64];
          state_next = WRITE_FIFO2;
        end
      end

      WRITE_FIFO2:
      begin
        ready = 1'b1;
        if(!fifo_full)
        begin
          fifo_we = 1'b1;
          dout = hash_reg[191:128];
          state_next = WRITE_FIFO3;
        end
      end

      WRITE_FIFO3:
      begin
        ready = 1'b1;
        if(!fifo_full)
        begin
          fifo_we = 1'b1;
          dout = hash_reg[255:192];
          state_next = READ_HASH0;
        end
      end

    endcase
  end


endmodule
