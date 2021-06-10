
`timescale  1ns / 1ps
module top
  #(
     parameter WCOUNT = 4,
     parameter BLK_CNT = 48
   )
   (
     //!axi domain clk
     input logic clk_axi,
     //!global clock
     input logic clk_top,
     //!global reset
     input logic rst,
     //!blockheader fifo write enable
     input logic block_header_we,
     //!Matrix fifo write enable
     input logic matrix_fifo_we,
     //!Target fifo write enable
     input logic target_we,

     //! start signal for new block operations
     input logic start,

     //! stop signal
     input logic stop,

     //! hash_select
     input logic [$clog2(BLK_CNT) -1 : 0] hash_select,

     //! 32-bit block header input (dout data from block_header fifo)
     input logic [31:0] block_header,

     //! 32-bit matrix_in input from matrix_fifo
     input logic [31:0] matrix_in,

     //! 32-bit target input
     input logic [31:0] target,

     //! 32-bit size calculated by software
     input logic [31:0] nonce_size,

     //! heavy hash out read enable
     input logic hash_re,

     //! heavy hash out (consecutive reads to obtaion complete (256-bit) out)
     output logic [31:0] heavyhash,


     //! nonce output generated by nonce_gen
     output logic [31:0] nonce,

     //! result stating if the output of heavy hash is less than the target
     //! 1 : less than target (objective)
     //! 0 : greater than target

     output logic [1:0] status
   );
  logic matrix_we;
  logic [31:0] block_header_dout;
  logic block_header_re;
  logic block_header_full;
  logic block_header_empty;

  logic matrix_fifo_re;
  logic [31:0] matrix_dout;
  logic matrix_full;
  logic matrix_empty;

  logic target_re;
  logic [31:0] target_dout;
  logic target_full;
  logic target_empty;

  logic [31:0] nonce_size_sync_reg0=32'd0;
  logic [31:0] nonce_size_sync_reg1=32'd0;
  logic [31:0] nonce_size_sync_reg2=32'd0;
  //logic [31:0] none_size_sync_reg3=32'd0;

  logic start_reg0, start_reg1, start_reg2;
  logic stop_reg0, stop_reg1, stop_reg2;

  logic start_heavy_hash;

  logic [31:0] nonce_reg0=0, nonce_sync_reg1=0, nonce_sync_reg2=0;
  logic result_sync_reg0, result_sync_reg1, result_sync_reg2;

  logic result;
  logic [9:0] cnt = 10'd0;
  logic [31:0] golden_nonce [BLK_CNT-1:0];
  logic [BLK_CNT:0] stop_ack_reg;
  logic [$clog2(BLK_CNT)-1:0] mux_sel;
  logic stop_ack;
  logic [BLK_CNT-1:0] result_blk;
  logic [BLK_CNT-1:0] stop_ack_blk;
  logic [BLK_CNT:0] result_reg;
  logic stop_blk;
  logic [1:0] status_blk_reg [BLK_CNT:0];
  logic [1:0] status_blk [BLK_CNT-1:0];
  logic [1:0] status_reg;
  logic [1:0] status_sync_reg0;
  logic [1:0] status_sync_reg1;
  logic [1:0] status_sync_reg2;

  logic [255:0] hash_blk_out [BLK_CNT-1: 0];
  logic [255:0] hash_out;
  logic [31:0] hash_fifo_out;
  logic [BLK_CNT-1: 0] hash_out_we;
  logic hash_we;


  logic [31:0] hash_out_sync_reg0;
  logic [31:0] hash_out_sync_reg1;
  logic [31:0] hash_out_sync_reg2;
  
  logic hash_re_sync_reg0, hash_re_sync_reg1, hash_re_sync_reg2;
  logic [$clog2(BLK_CNT)-1:0] hash_sel_sync_reg0, hash_sel_sync_reg1, hash_sel_sync_reg2;

  //PIPE_STAGEs
  logic [BLK_CNT-1:0] pipe_stage0_start_heavy_hash;
  logic [BLK_CNT-1:0] pipe_stage1_start_heavy_hash;
  logic [BLK_CNT-1:0] pipe_stage2_start_heavy_hash;
  logic [BLK_CNT-1:0] pipe_stage3_start_heavy_hash;
  logic [BLK_CNT-1:0] pipe_stage4_start_heavy_hash;

  logic [BLK_CNT-1:0] pipe_stage0_stop_blk;
  logic [BLK_CNT-1:0] pipe_stage1_stop_blk;
  logic [BLK_CNT-1:0] pipe_stage2_stop_blk;
  logic [BLK_CNT-1:0] pipe_stage3_stop_blk;
  logic [BLK_CNT-1:0] pipe_stage4_stop_blk;

  logic [BLK_CNT-1:0] pipe_stage0_matrix_we;
  logic [BLK_CNT-1:0] pipe_stage1_matrix_we;
  logic [BLK_CNT-1:0] pipe_stage2_matrix_we;
  logic [BLK_CNT-1:0] pipe_stage3_matrix_we;
  logic [BLK_CNT-1:0] pipe_stage4_matrix_we;

  logic [BLK_CNT-1:0] pipe_stage0_stop_ack;
  logic [BLK_CNT-1:0] pipe_stage1_stop_ack;
  logic [BLK_CNT-1:0] pipe_stage2_stop_ack;
  logic [BLK_CNT-1:0] pipe_stage3_stop_ack;
  logic [BLK_CNT-1:0] pipe_stage4_stop_ack;

  logic [BLK_CNT-1:0] pipe_stage0_result;
  logic [BLK_CNT-1:0] pipe_stage1_result;
  logic [BLK_CNT-1:0] pipe_stage2_result;
  logic [BLK_CNT-1:0] pipe_stage3_result;
  logic [BLK_CNT-1:0] pipe_stage4_result;


  logic [31:0] pipe_stage0_block_header [BLK_CNT-1:0];
  logic [31:0] pipe_stage1_block_header [BLK_CNT-1:0];
  logic [31:0] pipe_stage2_block_header [BLK_CNT-1:0];
  logic [31:0] pipe_stage3_block_header [BLK_CNT-1:0];
  logic [31:0] pipe_stage4_block_header [BLK_CNT-1:0];

  logic [31:0] pipe_stage0_target [BLK_CNT-1:0];
  logic [31:0] pipe_stage1_target [BLK_CNT-1:0];
  logic [31:0] pipe_stage2_target [BLK_CNT-1:0];
  logic [31:0] pipe_stage3_target [BLK_CNT-1:0];
  logic [31:0] pipe_stage4_target [BLK_CNT-1:0];

  logic [31:0] pipe_stage0_matrix [BLK_CNT-1:0];
  logic [31:0] pipe_stage1_matrix [BLK_CNT-1:0];
  logic [31:0] pipe_stage2_matrix [BLK_CNT-1:0];
  logic [31:0] pipe_stage3_matrix [BLK_CNT-1:0];
  logic [31:0] pipe_stage4_matrix [BLK_CNT-1:0];

  logic [31:0] pipe_stage0_nonce_size [BLK_CNT-1:0];
  logic [31:0] pipe_stage1_nonce_size [BLK_CNT-1:0];
  logic [31:0] pipe_stage2_nonce_size [BLK_CNT-1:0];
  logic [31:0] pipe_stage3_nonce_size [BLK_CNT-1:0];
  logic [31:0] pipe_stage4_nonce_size [BLK_CNT-1:0];

  logic [31:0] pipe_stage0_nonce [BLK_CNT-1:0];
  logic [31:0] pipe_stage1_nonce [BLK_CNT-1:0];
  logic [31:0] pipe_stage2_nonce [BLK_CNT-1:0];
  logic [31:0] pipe_stage3_nonce [BLK_CNT-1:0];
  logic [31:0] pipe_stage4_nonce [BLK_CNT-1:0];

  logic [1:0] pipe_stage0_status [BLK_CNT-1:0];
  logic [1:0] pipe_stage1_status [BLK_CNT-1:0];
  logic [1:0] pipe_stage2_status [BLK_CNT-1:0];
  logic [1:0] pipe_stage3_status [BLK_CNT-1:0];
  logic [1:0] pipe_stage4_status [BLK_CNT-1:0];






  typedef enum { INIT,
                 WAIT_FOR_STOP_ACK,
                 OPERATE
               } state_type;
  state_type state;

  genvar i;
  generate
    for (i=0;i<BLK_CNT;i++ )
    begin
      heavy_hash_blk
        #(
          .NONCE_COEF(i+1),
          .WCOUNT ( WCOUNT )
        )
        heavy_hash_blk_dut (
          .clk (clk_top ),
          .rst (rst ),
          .start ( pipe_stage4_start_heavy_hash[i]),
          .stop (pipe_stage4_stop_blk[i] ),
          .block_header (pipe_stage4_block_header[i] ),
          .matrix_in (pipe_stage4_matrix[i] ),
          .target (pipe_stage4_target[i] ),
          .nonce_size (nonce_size_sync_reg2 ),
          .matrix_we (pipe_stage4_matrix_we[i]),
          .nonce (golden_nonce[i] ),
          .result (result_blk[i] ),
          .stop_ack  ( stop_ack_blk[i]),
          .status(status_blk[i]),
          .hash_out(hash_blk_out[i]),
          .hash_out_we(hash_out_we[i])
        );
    end
  endgenerate

  always_ff @( posedge clk_top )
  begin : pipe_stages
    
    for (int i = 0 ; i < BLK_CNT ; i ++ )
    begin
      //pipe_stages for start_heavy_hash
      pipe_stage0_start_heavy_hash[i] <= start_heavy_hash;
      pipe_stage1_start_heavy_hash[i] <= pipe_stage0_start_heavy_hash[i];
      pipe_stage2_start_heavy_hash[i] <= pipe_stage1_start_heavy_hash[i];
      pipe_stage3_start_heavy_hash[i] <= pipe_stage2_start_heavy_hash[i];
      pipe_stage4_start_heavy_hash[i] <= pipe_stage3_start_heavy_hash[i];

      //pipe_stages for stop_blk
      pipe_stage0_stop_blk[i] <= stop_blk;
      pipe_stage1_stop_blk[i] <= pipe_stage0_stop_blk[i];
      pipe_stage2_stop_blk[i] <= pipe_stage1_stop_blk[i];
      pipe_stage3_stop_blk[i] <= pipe_stage2_stop_blk[i];
      pipe_stage4_stop_blk[i] <= pipe_stage3_stop_blk[i];

      //pipe_stages for block header
      pipe_stage0_block_header[i] <= block_header_dout;
      pipe_stage1_block_header[i] <= pipe_stage0_block_header[i];
      pipe_stage2_block_header[i] <= pipe_stage1_block_header[i];
      pipe_stage3_block_header[i] <= pipe_stage2_block_header[i];
      pipe_stage4_block_header[i] <= pipe_stage3_block_header[i];

      //pipe_stages for matrix in
      pipe_stage0_matrix[i] <= matrix_dout;
      pipe_stage1_matrix[i] <= pipe_stage0_matrix[i];
      pipe_stage2_matrix[i] <= pipe_stage1_matrix[i];
      pipe_stage3_matrix[i] <= pipe_stage2_matrix[i];
      pipe_stage4_matrix[i] <= pipe_stage3_matrix[i];

      //pipe_stages for matrix in
      pipe_stage0_matrix_we[i] <= matrix_we;
      pipe_stage1_matrix_we[i] <= pipe_stage0_matrix_we[i];
      pipe_stage2_matrix_we[i] <= pipe_stage1_matrix_we[i];
      pipe_stage3_matrix_we[i] <= pipe_stage2_matrix_we[i];
      pipe_stage4_matrix_we[i] <= pipe_stage3_matrix_we[i];

      //pipe_stages for target
      pipe_stage0_target[i] <= target_dout;
      pipe_stage1_target[i] <= pipe_stage0_target[i];
      pipe_stage2_target[i] <= pipe_stage1_target[i];
      pipe_stage3_target[i] <= pipe_stage2_target[i];
      pipe_stage4_target[i] <= pipe_stage3_target[i];

      
      //pipe_stages for nonce size
      pipe_stage0_nonce_size[i] <= nonce_size_sync_reg2;
      pipe_stage1_nonce_size[i] <= pipe_stage0_nonce_size[i];
      pipe_stage2_nonce_size[i] <= pipe_stage1_nonce_size[i];
      pipe_stage3_nonce_size[i] <= pipe_stage2_nonce_size[i];
      pipe_stage4_nonce_size[i] <= pipe_stage3_nonce_size[i];

      //pipe_stages for nonce
      pipe_stage0_nonce[i] <= golden_nonce[i];
      pipe_stage1_nonce[i] <= pipe_stage0_nonce[i];
      pipe_stage2_nonce[i] <= pipe_stage1_nonce[i];
      pipe_stage3_nonce[i] <= pipe_stage2_nonce[i];
      pipe_stage4_nonce[i] <= pipe_stage3_nonce[i];

      
      //pipe_stages for result
      pipe_stage0_result[i] <= result_blk[i];
      pipe_stage1_result[i] <= pipe_stage0_result[i];
      pipe_stage2_result[i] <= pipe_stage1_result[i];
      pipe_stage3_result[i] <= pipe_stage2_result[i];
      pipe_stage4_result[i] <= pipe_stage3_result[i];

      //pipe_stages for status
      pipe_stage0_status[i] <= status_blk[i];
      pipe_stage1_status[i] <= pipe_stage0_status[i];
      pipe_stage2_status[i] <= pipe_stage1_status[i];
      pipe_stage3_status[i] <= pipe_stage2_status[i];
      pipe_stage4_status[i] <= pipe_stage3_status[i];
    end
  end





  assign stop_ack_reg[0] = 1'b0;
  assign result_reg[0] = 1'b0;
  assign stop_ack_reg[0] = 1'b1;
   
  generate
    for (i = 0 ; i < BLK_CNT ; i ++ )
    begin
      assign result_reg[i+1] = pipe_stage4_result[i] | result_reg[i];
      assign status_blk_reg[i+1] = status_blk[i] | status_blk_reg[i];
      assign stop_ack_reg[i+1] = stop_ack_blk[i] & stop_ack_reg[i];
    end
  endgenerate

  assign stop_ack = stop_ack_reg[BLK_CNT];
  assign result_sync_reg0 = result_reg[BLK_CNT];
  assign status_reg = status_blk_reg[BLK_CNT];

  

  fifo_async
    #(.DEPTH(64),
      .WRITE_WIDTH(256),
      .READ_WIDTH(32))
    heavyhash_fifo (
      .wr_clk (clk_top ),
      .rd_clk (clk_axi ),
      .rst (rst ),
      .wr_en ( hash_we ),
      .rd_en ( hash_re_sync_reg2 ),
      .din (hash_out ),
      .dout (hash_fifo_out ),
      .full (hash_fifo_full ),
      .empty  ( hash_fifo_empty)
    );


  fifo_async
    #(.DEPTH(64))
    block_header_fifo (
      .wr_clk (clk_axi ),
      .rd_clk (clk_top ),
      .rst (rst ),
      .wr_en ( block_header_we),
      .rd_en (block_header_re ),
      .din (block_header ),
      .dout (block_header_dout ),
      .full (block_header_full ),
      .empty  ( block_header_empty)
    );

  fifo_async
    #(.DEPTH(512))
    matrix_fifo (
      .wr_clk (clk_axi ),
      .rd_clk (clk_top ),
      .rst (rst ),
      .wr_en ( matrix_fifo_we),
      .rd_en (matrix_fifo_re ),
      .din (matrix_in ),
      .dout (matrix_dout ),
      .full (matrix_full ),
      .empty  (matrix_empty )
    );

  fifo_async
    #(.DEPTH(16))
    target_fifo (
      .wr_clk (clk_axi ),
      .rd_clk (clk_top ),
      .rst (rst ),
      .wr_en (target_we ),
      .rd_en (target_re ),
      .din (target ),
      .dout (target_dout ),
      .full (target_full ),
      .empty  (target_empty)
    );


  always_comb
  begin : encoder
    mux_sel = 0;
    for (int i = 0; i < BLK_CNT; i++)
    begin
      if (pipe_stage4_result[i])
        mux_sel = i[5:0];
    end
  end

  assign hash_out = hash_blk_out[hash_sel_sync_reg2];
  assign hash_we = hash_out_we[hash_sel_sync_reg2];
  


  always_ff @( posedge clk_axi )
  begin : clk_domain_axi
    nonce_size_sync_reg0 <= nonce_size;
    start_reg0 <= start;
    stop_reg0 <= stop;
    hash_sel_sync_reg0 <= hash_select;
    hash_re_sync_reg0 <= hash_re;
  end
  //Two flip-flop synchronizer
  always_ff @( posedge clk_top )
  begin : synchronizer1
    nonce_size_sync_reg1 <= nonce_size_sync_reg0;
    nonce_size_sync_reg2 <= nonce_size_sync_reg1;

    start_reg1 <= start_reg0;
    start_reg2 <= start_reg1;

    stop_reg1 <= stop_reg0;
    stop_reg2 <= stop_reg1;

    hash_sel_sync_reg1 <=  hash_sel_sync_reg0;
    hash_sel_sync_reg2 <=  hash_sel_sync_reg1;

    hash_re_sync_reg1 <= hash_re_sync_reg0;
    hash_re_sync_reg2 <= hash_re_sync_reg1;
  end

  always_ff @( posedge clk_top )
  begin : clk_domain_top
    if(result_sync_reg0)
      nonce_reg0 <= pipe_stage4_nonce[mux_sel];

    status_sync_reg0 <= status_reg;
    hash_out_sync_reg0 <= hash_fifo_out;
  end
  //Two flip-flop synchronizer
  always_ff @( posedge clk_axi)
  begin : synchronizer2
    nonce_sync_reg1 <= nonce_reg0;
    nonce_sync_reg2 <= nonce_sync_reg1;

    result_sync_reg1 <= result_sync_reg0;
    result_sync_reg2 <= result_sync_reg1;
    
    status_sync_reg1 <= status_sync_reg0;
    status_sync_reg2 <= status_sync_reg1;

    hash_out_sync_reg1 <= hash_out_sync_reg0;
    hash_out_sync_reg2 <= hash_out_sync_reg1;
  end


  //TODO: seperate comb and seq
  always_ff @( posedge clk_top )
  begin : fsm_top
    if(rst)
    begin
      target_re <= 1'b0;
      block_header_re <= 1'b0;
      matrix_fifo_re <= 1'b0;
      stop_blk <= 1'b0;
      start_heavy_hash <= 1'b0;
    end
    else
    begin
      case (state)
        INIT:
        begin
          start_heavy_hash <= 1'b0;
          if(stop_reg2)
            stop_blk <= 1'b1;
          else if(start_reg2)
          begin
            state <= WAIT_FOR_STOP_ACK;
          end
        end
        WAIT_FOR_STOP_ACK:
        begin
          if(stop_ack)
          begin
            stop_blk <= 1'b0;
            start_heavy_hash <= 1'b1;
            state <= OPERATE;
            //block_header_re <= 1'b1;
            //target_re <= 1'b1;
          end
        end
        OPERATE:
        begin
          if(!block_header_empty)
            block_header_re <= 1'b1;
          else
            block_header_re <= 1'b0;

          if(!matrix_empty)
          begin
            matrix_fifo_re <= 1'b1;
            if(cnt < 512)
            begin
              matrix_we <= 1'b1;
              cnt <= cnt + 10'd1;
            end
            else
              matrix_we <= 1'b0;
          end
          else
          begin
            matrix_fifo_re <= 1'b0;
            matrix_we <= 1'b0;
          end

          if(!target_empty)
            target_re <= 1'b1;
          else
            target_re <= 1'b0;

          if(stop_reg2)
            state <= INIT;
        end
      endcase
    end
  end


  assign nonce = nonce_sync_reg2;
  assign result = result_sync_reg2;
  //assign start_heavy_hash = stop_ack & start_reg2;
  assign status = status_sync_reg2;
  assign heavyhash = hash_out_sync_reg2;


endmodule
