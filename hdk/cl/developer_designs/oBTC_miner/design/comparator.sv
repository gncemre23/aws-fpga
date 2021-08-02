
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
    output logic nonce_fifo_re,
    output [31:0] hashes_done,
    output logic heavy_hash_rdy
  );

  logic [3:0] cnt_next, cnt_reg;
  logic [1:0] comp0_next, comp0_reg;
  logic [1:0] comp1_next, comp1_reg;
  logic [1:0] comp2_next, comp2_reg;
  logic [1:0] comp3_next, comp3_reg;
  logic result_next, result_reg;
  logic [255:0] target_reg, target_next;
  logic [255:0] heavy_hash_dout_next, heavy_hash_dout_reg;
  logic equal_next, equal_reg;
  logic [31:0] hashes_done_next, hashes_done_reg;
  logic heavy_hash_rdy_next, heavy_hash_rdy_reg;


  function [63:0] le2be(input logic [63:0] in);
    integer i;
    for (i = 0 ; i < 8 ; i= i + 1 )
    begin
      le2be[63 - i * 8 -: 8] = in[7 + i * 8 -: 8];
    end

  endfunction //automatic




  typedef enum { INIT,
                 READ_TARGET,
                 COMPARE_0,
                 COMPARE_1,
                 COMPARE_2,
                 COMPARE_3,
                 DETERMINE_RESULT
               } state_type;
  state_type state_next, state_reg;

  always_ff @(posedge clk)
  begin
    if(rst)
    begin
      state_reg <= INIT;
      cnt_reg <= 4'd0;
      target_reg <= 256'd0;
      result_reg <= 1'b0;
      heavy_hash_dout_reg <= 256'd0;
      equal_reg <= 1'b0;
      hashes_done_reg <= 32'd0;
      heavy_hash_rdy_reg <= 0;
      comp0_reg <= 0;
      comp1_reg <= 0;
      comp2_reg <= 0;
      comp3_reg <= 0;
    end
    else
    begin
      result_reg <= result_next;
      state_reg <= state_next;
      cnt_reg <= cnt_next;
      target_reg <= target_next;
      heavy_hash_dout_reg <= heavy_hash_dout_next;
      equal_reg <= equal_next;
      hashes_done_reg <= hashes_done_next;
      heavy_hash_rdy_reg <= heavy_hash_rdy_next;
      comp0_reg <= comp0_next;
      comp1_reg <= comp1_next;
      comp2_reg <= comp2_next;
      comp3_reg <= comp3_next;
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
    hashes_done_next = hashes_done_reg;
    heavy_hash_rdy_next = heavy_hash_rdy_reg;

    case (state_reg)
      INIT:
      begin
        result_next = 1'b0;
        cnt_next = 0;
        target_next = 0;
        state_next = READ_TARGET;
        hashes_done_next = 0;
      end

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
            heavy_hash_dout_next[63:0] = le2be(heavy_hash_din);
            heavy_hash_rdy_next = 0;
            state_next = COMPARE_1;
            if(le2be(heavy_hash_din) < target_reg[63:0])
            begin
              comp0_next = 1;
            end
            else if(le2be(heavy_hash_din) > target_reg[63:0])
            begin
              comp0_next = 0;
            end  
            else
            begin
              comp0_next = 2;
            end
          end
        end
        else
          state_next = INIT;
      end
      COMPARE_1:
      begin
        if(!stop)
        begin
          heavy_hash_re = 1'b1;
          if(heavy_hash_din_we)
          begin
            heavy_hash_dout_next[127:64] = le2be(heavy_hash_din);
            state_next = COMPARE_2;
            if(le2be(heavy_hash_din) < target_reg[127:64])
            begin
              comp1_next = 1;
            end
            else if(le2be(heavy_hash_din) > target_reg[127:64])
            begin
              comp1_next = 0;
            end  
            else
            begin
              comp1_next = 2;
            end
          end
        end
        else
          state_next = INIT;
      end
      COMPARE_2:
      begin
        if(!stop)
        begin
          heavy_hash_re = 1'b1;
          if(heavy_hash_din_we)
          begin
            heavy_hash_dout_next[191:128] = le2be(heavy_hash_din);
            state_next = COMPARE_3;
            if(le2be(heavy_hash_din) < target_reg[191:128])
            begin
              comp2_next = 1;
            end
            else if(le2be(heavy_hash_din) > target_reg[191:128])
            begin
              comp2_next = 0;
            end  
            else
            begin
              comp2_next = 2;
            end
          end
        end
        else
          state_next = INIT;
      end
      COMPARE_3:
      begin
        if(!stop)
        begin
          heavy_hash_re = 1'b1;
          if(heavy_hash_din_we)
          begin
            heavy_hash_dout_next[255:192] = le2be(heavy_hash_din);
            heavy_hash_rdy_next = 1;
            state_next = DETERMINE_RESULT;
            if(le2be(heavy_hash_din) < target_reg[255:192])
            begin
              comp3_next = 1;
            end
            else if(le2be(heavy_hash_din) > target_reg[255:192])
            begin
              comp3_next = 0;
            end  
            else
            begin
              comp3_next = 2;
            end
            hashes_done_next = hashes_done_reg + 1;
          end
        end
        else
          state_next = INIT;
      end
      DETERMINE_RESULT:
      begin
        if(!stop)
        begin
          state_next = COMPARE_0;
          nonce_fifo_re = 1;
          if(comp3_reg == 1)
            result_next = 1;
          else if(comp3_reg == 0)
            result_next = 0;
          else if(comp2_reg == 1)
            result_next = 1;
          else if(comp2_reg == 0)
            result_next = 0;
          else if(comp1_reg == 1)
            result_next = 1;
          else
            result_next = 0;   
        end
        else
          state_next = INIT;
      end


    endcase

  end

  assign result = result_reg;
  assign heavy_hash_dout = heavy_hash_dout_reg;
  assign hashes_done = hashes_done_reg;
  assign heavy_hash_rdy = heavy_hash_rdy_reg;
  

  endmodule
