//! Taking the block header from block header fifo,
//! generating the block header just changing the nonce
`timescale  1ns / 1ps
//`define DBG_
module nonce_gen
  #(
     parameter NONCE_COEF = 1
   )
   (
     //!global clk
     input logic clk,
     //!global reset
     input logic rst,
     //!start signal stating new block header is ready
     input logic start,
     //!stop signal
     input logic stop,
     //!block header input from block_header fifo
     input logic [31:0] block_header,
     //!block_header write enable
     input block_header_we
     //!nonce size information calculated by software
     input logic [31:0] nonce_size,
     //!hashin fifo write enable
     output logic hashin_fifo_in_we,
     //!hashin fifo datain
     output logic [63:0] hashin_fifo_in_din,
     //!hashin fifo full flag
     input  logic hashin_fifo_in_full,
     //!nonce fifo full flag
     input logic nonce_fifo_full,
     //!nonce fifo data in
     output logic [31:0] nonce_fifo_din,
     //!nonce fifo write enable
     output logic nonce_fifo_we,
     //!signal stating ready to recieve start signal
     output logic stop_ack_nonce,

     //!debug ports if debug is defined
     `ifdef DBG_
     output logic state_nonce_dbg,
     `endif

     //!nonce end
     output logic [31:0] nonce_end
   );

  logic stop_ack_reg, stop_ack_next;
  logic [31:0] nonce_reg, nonce_next;
  logic [31:0] nonce_end_reg, nonce_end_next;
  //80-byte block header
  logic [639:0] block_header_reg, block_header_next;
  logic [639:0] block_header_reg_reg, block_header_reg_next;
  logic [4:0] cnt_reg, cnt_next;

  typedef enum { INIT, READ_BLOCK_HEADER, CHECK_NONCE_END, UPDATE_NONCE, WRITE_HASHIN} state_type;
  state_type state_reg, state_next;

  
  assign stop_ack_nonce = stop_ack_reg;
  assign nonce_end = nonce_end_reg;
  
  always_ff @( posedge clk )
  begin : seq
    if(rst)
    begin
      cnt_reg <= 5'd0;
      state_reg <= INIT;
      block_header_reg <= 640'd0;
      block_header_reg_reg <= 640'd0;
      nonce_reg <= 32'd0;
      nonce_end_reg <= 32'd0;
      stop_ack_reg <= 1'b0;
    end
    else
    begin
      cnt_reg <= cnt_next;
      state_reg <= state_next;
      block_header_reg <= block_header_next;
      block_header_reg_reg <= block_header_reg_next;
      nonce_reg <= nonce_next;
      nonce_end_reg <= nonce_end_next;
      stop_ack_reg <= stop_ack_next;
    end
  end


  always_comb
  begin : comb
    //default assingments
    cnt_next = cnt_reg;
    block_header_next = block_header_reg;
    block_header_reg_next = block_header_reg_reg;
    nonce_next = nonce_reg;
    nonce_end_next = nonce_end_reg; 
    hashin_fifo_in_we = 1'b0;
    hashin_fifo_in_din = 64'd0;
    nonce_fifo_we = 1'b0;
    nonce_fifo_din = 32'd0;
    stop_ack_next = stop_ack_reg;
    state_next = state_reg;
    case (state_reg)
      INIT:
      begin
        stop_ack_next = 1'b1;
        block_header_next = 640'd0;
        block_header_reg_next = 640'd0;
        nonce_next = 32'd0;
        cnt_next = 5'd0;
        if(start)
        begin
          state_next = READ_BLOCK_HEADER;
        end
      end

      READ_BLOCK_HEADER:
      begin
        stop_ack_next = 1'b0;
        if(cnt_reg < 20)
        begin
          if(block_header_we)
          begin
            block_header_next = {block_header,block_header_reg[639:32]};
            cnt_next = cnt_reg + 5'd1;
          end
        end
        else
        begin
          // $display("block_header_reg = %h",block_header_reg);
          nonce_end_next = block_header_reg[31:0] + nonce_size*NONCE_COEF;
          nonce_next = block_header_reg[31:0] + nonce_size*(NONCE_COEF-1);
          state_next = CHECK_NONCE_END;
        end
      end

      CHECK_NONCE_END:
      begin
        if(nonce_end_reg < block_header_reg[31:0])
          nonce_end_next = 32'hFFFFFFFF;
          state_next = UPDATE_NONCE;
      end

      UPDATE_NONCE:
      begin      
        if(!stop)
          if(nonce_reg < nonce_end_reg)
          begin
            if(!nonce_fifo_full & !hashin_fifo_in_full )
            begin
              // $display("block_header_reg = %h",{block_header_reg[639:32],nonce_reg[7:0],nonce_reg[15:8],nonce_reg[23:16],nonce_reg[31:24]});
              block_header_reg_next = {block_header_reg[639:32],nonce_reg[7:0],nonce_reg[15:8],nonce_reg[23:16],nonce_reg[31:24]} ;
              nonce_next = nonce_reg + 32'd1;
              hashin_fifo_in_din = 64'h8000000000000280;
              hashin_fifo_in_we = 1'b1;
              nonce_fifo_din = nonce_reg;
              nonce_fifo_we = 1'b1;
              cnt_next = 5'd0;
              state_next = WRITE_HASHIN;
            end
          end
          else
          begin
            state_next = INIT;
          end
        //stop
        else
        begin
          state_next = INIT;
        end
      end

      WRITE_HASHIN:
      begin
        if(cnt_reg < 10)
        begin
          if(!hashin_fifo_in_full)
          begin
            block_header_reg_next = block_header_reg_reg << 64;
            hashin_fifo_in_din = block_header_reg_reg[639:576];
            cnt_next = cnt_reg + 5'd1;
            hashin_fifo_in_we = 1'b1;
          end
        end
        else
        begin
          state_next = UPDATE_NONCE;
        end
      end

      default:
      begin
        state_next = INIT;
      end

    endcase
  end

  //debug assingments
  `ifdef DBG_
  assign state_nonce_dbg = state_reg;
  `endif



endmodule
