
//! comparator module to compare the hash output with the target value
//! if the hash output is less than the target value, golden nonce is obtained.

`timescale  1ns / 1ps
//`define DBG_
module comparator
  (
    //!global clk
    input logic clk,
    //!global rst
    input logic rst,
    //!32-bit target from asychronous fifo
    input logic [31:0] target,
    //!target write enable
    input logic target_we,
    //!start input to prepare the system
    input logic start,
    //!stop input
    input logic stop,

    //!read enable for hashout fifo
    output logic heavy_hash_re,
    input logic [63:0] heavy_hash_din,
    input logic heavy_hash_din_we,
    output logic [255:0] heavy_hash_dout,

    //! result stating if the output of heavy hash is less than the target
    //! 1 : less than target (objective)
    //! 0 : greater than target
    output logic result,
    output logic nonce_fifo_re
  );

  logic [3:0] cnt_next, cnt_reg;
  logic result_next, result_reg;
  logic [255:0] target_reg, target_next;
  logic [255:0] heavy_hash_dout_next, heavy_hash_dout_reg;
  logic equal_next, equal_reg;
  typedef enum { 
                 READ_TARGET,
                 COMPARE_0,
                 COMPARE_1,
                 COMPARE_2,
                 COMPARE_3
               } state_type;
  state_type state_next, state_reg;

  always_ff @(posedge clk)
  begin
    if(rst)
    begin
      state_reg <= READ_TARGET;
      cnt_reg <= 4'd0;
      target_reg <= 256'd0;
      result_reg <= 1'b0;
      heavy_hash_dout_reg <= 256'd0;
      equal_reg <= 1'b0;
    end
    else
    begin
      result_reg <= result_next;
      state_reg <= state_next;
      cnt_reg <= cnt_next;
      target_reg <= target_next;
      heavy_hash_dout_reg <= heavy_hash_dout_next;
      equal_reg <= equal_next;
    end
  end


  always_comb
  begin
  //default assingments
  heavy_hash_re = 1'b0;
  cnt_next = cnt_reg;
  target_next = target_reg;
  result_next = result_reg;
  state_next = state_reg; 
  heavy_hash_dout_next = heavy_hash_dout_reg;
  equal_next = equal_reg;
  nonce_fifo_re = 1'b0;
  case (state_reg)
    READ_TARGET:
    begin
      if(!stop)
      begin
        if(cnt_reg < 8)
        begin
          if(target_we)
          begin
          target_next = {target,target_reg[255:32]};
          cnt_next = cnt_reg + 4'd1;
          end
        end
        else
        begin
          state_next = COMPARE_0;
          heavy_hash_re = 1'b1;
        end
      end
    end
    COMPARE_0:
    begin
      if(!stop)
      begin
        heavy_hash_re = 1'b1;
        if(heavy_hash_din_we)
        begin
          heavy_hash_dout_next[255:192] = heavy_hash_din;
          state_next = COMPARE_1;
          if(target_reg[255:192] > heavy_hash_din)
          begin
            result_next = 1'b1;
          end
          else if(target_reg[255:192] == heavy_hash_din)
          begin
            equal_next = 1'b1;
          end
          else
            equal_next = 1'b0;
        end
      end
      else
        state_next = READ_TARGET;
    end
    COMPARE_1:
    begin
      if(!stop)
      begin
        heavy_hash_re = 1'b1;
        if(heavy_hash_din_we)
        begin
          heavy_hash_dout_next[191:128] = heavy_hash_din;
          state_next = COMPARE_2;
          if(equal_reg == 1'b1 && target_reg[191:128] > heavy_hash_din)
          begin
            result_next = 1'b1;
          end
          else if(target_reg[191:128] == heavy_hash_din)
          begin
            equal_next = 1'b1;
          end
          else 
          begin
            equal_next = 1'b0;
          end
        end
      end
      else
        state_next = READ_TARGET;
    end
    COMPARE_2:
    begin
      if(!stop)
      begin
        heavy_hash_re = 1'b1;
        if(heavy_hash_din_we)
        begin
          heavy_hash_dout_next[127:64] = heavy_hash_din;
          state_next = COMPARE_3;
          if(equal_reg == 1'b1 && target_reg[127:64] > heavy_hash_din)
          begin
            result_next = 1'b1;
          end
          else if(target_reg[127:64] == heavy_hash_din)
          begin
            equal_next = 1'b1;
          end
          else 
          begin
            equal_next = 1'b0;
          end
        end
      end
      else
        state_next = READ_TARGET;
    end
    COMPARE_3:
    begin
      if(!stop)
      begin
        heavy_hash_re = 1'b1;
        if(heavy_hash_din_we)
        begin
          heavy_hash_dout_next[63:0] = heavy_hash_din;
          state_next = COMPARE_0;
          equal_next = 1'b1;
          nonce_fifo_re = 1'b1;
          if(equal_reg == 1'b1 && target_reg[63:0] > heavy_hash_din)
          begin
            result_next = 1'b1;
          end
        end
      end
      else
        state_next = READ_TARGET;
    end

  endcase

  end

assign result = result_reg;
assign heavy_hash_dout = heavy_hash_dout_reg;

endmodule
