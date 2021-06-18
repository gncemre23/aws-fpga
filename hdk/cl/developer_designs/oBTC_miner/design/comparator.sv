
//! comparator module to compare the hash output with the target value
//! if the hash output is less than the target value, golden nonce is obtained.

`timescale  1ns / 1ps
`define DBG_
module comparator
  (
    //!global clk
    input logic clk,
    //!global rst
    input logic rst,
    //!32-bit target from asychronous fifo
    input logic [31:0] target,
    //!start input to prepare the system
    input logic start,
    //!stop input
    input logic stop,
    //!target ready
    output logic stop_ack_comp,

    //!obtained by or operation of empty signals from all fifos in heavy_hash
    input logic heavy_hash_all_empty,
    //!read enable for hashout fifo
    output logic hashout_fifo_re,
    input logic [255:0] hash_out,
    input logic hash_out_empty,

    `ifdef DBG_
    output logic [2:0] state_comparator_dbg,
    output logic [255:0] target_dbg,
    `endif

    //! result stating if the output of heavy hash is less than the target
    //! 1 : less than target (objective)
    //! 0 : greater than target
    output logic result
  );

  logic [3:0] cnt;
  logic [255:0] target_reg;
  typedef enum { DRAIN_FIFOS,
                 READ_TARGET,
                 COMPARE_0,
                 COMPARE_1,
                 COMPARE_2,
                 COMPARE_3
               } state_type;
  state_type state;

  //TODO: seperate comb and seq
  always_ff @( posedge clk )
  begin : comp_fsm
    if(rst)
    begin
      hashout_fifo_re <= 1'b0;
      cnt <= 4'd0;
      target_reg <= 256'd0;
      stop_ack_comp <= 1'b1;
      result <= 1'b0;
      state <= DRAIN_FIFOS;
    end

    else
    begin
      case (state)
        DRAIN_FIFOS:
        begin   
          result <= 1'b0;      
          if(!heavy_hash_all_empty)begin
            hashout_fifo_re <= 1'b1;
            stop_ack_comp <= 1'b0;
          end
          else
          begin
            stop_ack_comp <= 1'b1;
            hashout_fifo_re <= 1'b0;
            if(start)
            begin
              state <= READ_TARGET;
            end
          end
        end
        READ_TARGET:
        begin
          if(!stop)
          begin
            stop_ack_comp <= 1'b0;
            if(cnt < 8)
            begin
              target_reg <= {target,target_reg[255:32]};
              cnt <= cnt + 4'd1;
            end
            else if(!hash_out_empty)
              state <= COMPARE_0;
          end
          else
            state <= DRAIN_FIFOS;
        end
        COMPARE_0:
        begin
          if(!stop)
          begin
            if(!hash_out_empty)
            begin
              if(target_reg[255:192] > hash_out[255:192])
              begin
                hashout_fifo_re <= 1'b0;
                result <= 1'b1;
                state <= DRAIN_FIFOS;
              end
              else if(target_reg[255:192] == hash_out[255:192])
              begin
                hashout_fifo_re <= 1'b0;
                state <= COMPARE_1;
              end
              else if(!hash_out_empty)
                hashout_fifo_re <= 1'b1;
              else
                hashout_fifo_re <= 1'b0;
            end
            else
              hashout_fifo_re <= 1'b0;
          end
          else
            state <= DRAIN_FIFOS;
        end
        COMPARE_1:
        begin
          if(!stop)
          begin
            if(target_reg[191:128] > hash_out[191:128])
            begin
              result <= 1'b1;
              state <= DRAIN_FIFOS;
            end
            else if(target_reg[191:128] == hash_out[191:128])
            begin
              hashout_fifo_re <= 1'b0;
              state <= COMPARE_2;
            end
            else if(!hash_out_empty)
            begin
              hashout_fifo_re <= 1'b1;
              state <= COMPARE_0;
            end
            else
              hashout_fifo_re <= 1'b0;
          end
          else
            state <= DRAIN_FIFOS;
        end
        COMPARE_2:
        begin
          if(!stop)
          begin
            if(target_reg[127:64] > hash_out[127:64])
            begin
              result <= 1'b1;
              state <= DRAIN_FIFOS;
            end
            else if(target_reg[127:64] == hash_out[127:64])
            begin
              hashout_fifo_re <= 1'b0;
              state <= COMPARE_3;
            end
            else if(!hash_out_empty)
            begin
              hashout_fifo_re <= 1'b1;
              state <= COMPARE_0;
            end
            else
              hashout_fifo_re <= 1'b0;
          end
          else
            state <= DRAIN_FIFOS;
        end
        COMPARE_3:
        begin
          if(!stop)
          begin
            if(target_reg[63:0] > hash_out[63:0])
            begin
              result <= 1'b1;
              state <= DRAIN_FIFOS;
            end
            else if(!hash_out_empty)
            begin
              hashout_fifo_re <= 1'b1;
              state <= COMPARE_0;
            end
            else
              hashout_fifo_re <= 1'b0;
          end
          else
            state <= DRAIN_FIFOS;
        end
        default:
        begin
          hashout_fifo_re <= 1'b0;
          cnt <= 4'd0;
          target_reg <= 256'd0;
          stop_ack_comp <= 1'b1;
          result <= 1'b0;
          state <= DRAIN_FIFOS;
        end

      endcase
    end

  end


`ifdef DBG_
assign state_compator_dbg = state;
assign target_dbg = target_reg;
`endif

endmodule
