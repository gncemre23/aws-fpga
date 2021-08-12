
//TODO draw new diagram regarding the new code
/* ================== Heavy hash block ================================= */
/*           Block_header            Matrix               Target         */
/*                |                     |                    |           */
/*                |                     |                    |           */
/*                |                     |                    |           */
/*       +--------+---------------------+--------------------+---------+ */
/*       |        |                     v                    |         | */
/*       |        v                +----------+              v         | */
/* start |   +----------+          |          |        +-----------+   | */
/* ------+-->| nonce_gen+--------->|heavy_hash+------->|comparator |   | */
/*       |   +----+-----+          |          |        +-----+-----+   | */
/*       |                         +----------+              |         | */
/*       |                               |                   |         | */
/*       +--------+----------------------|-------------------+---------+ */
/*                                       |                   |           */
/*                                       |                   |           */
/*                                       v                   v           */
/*                                     nonce               result        */
/* ================== Heavy hash block ================================= */
`timescale  1ns / 1ps
//`define DBG_

//`define VERIF_
`define HEAVYHASH_REG_ADDR      32'h0000_0508
`define STATUS_REG_ADDR         32'h0000_050C
`define NONCE_REG_ADDR          32'h0000_0510
`define BLOCKHEADER_REG_ADDR    32'h0000_0514
`define MATRIX_REG_ADDR         32'h0000_0518
`define TARGET_REG_ADDR         32'h0000_051C
`define NONCESIZE_REG_ADDR      32'h0000_0520
`define START_REG_ADDR          32'h0000_0524
`define STOP_REG_ADDR           32'h0000_0528
`define HASHES_DONE_BASE        32'h0000_053C
`define ACK_REG_ADDR            32'h0000_0540
module heavy_hash_blk
  #(
     parameter NONCE_COEF = 1,
     parameter WCOUNT = 4
   )
   (
     //!AXI clk
     input logic clk_axi,

     //!Internal Fast clock
     input logic clk_int,

     //!global reset (active low)
     input logic rst_n,

     //!AXI write address valid signal
     input logic awvalid,

     //!AXI write address
     input logic [31:0] awaddr,

     //!AXI write data valid signal
     input logic wvalid,

     //!AXI bvalid
     input logic bvalid,

     //!AXI bready,
     input logic bready,

     //!AXI write data
     input logic [31:0] wdata,

     //!AXI read address valid
     input logic arvalid,

     //!AXI read address
     input logic [31:0] araddr,

     //!AXI read rready
     input logic rready,

     //!AXI read data
     output logic [31:0] rdata,

     //!AXI rvalid output
     output logic rvalid_heavy_hash

   );

  //! reset signal for internal logic (active high)
  logic rst;

  //! start signal for new block operations
  logic start_axi, start_int;

  //! ack signal to inform core that nonce is read
  logic ack_axi, ack_int;

  //! stop signal
  logic stop_axi, stop_int;

  //! 32-bit block header input (dout data from block_header fifo)
  logic [31:0] block_header_axi, block_header_int;

  //! write enable for block_header
  logic block_header_we_axi, block_header_we_int;

  //! 32-bit matrix_in input from matrix_fifo
  logic [31:0] matrix_in_axi, matrix_in_int;
  //! write enable for matrix input
  logic matrix_we_axi, matrix_we_int;

  //! 32-bit target input
  logic [31:0] target_axi, target_int;
  //! write enable for target input
  logic target_we_axi, target_we_int;

  //! 32-bit size calculated by software
  logic [31:0] nonce_size_axi, nonce_size_int;



  //! nonce output generated by nonce_gen
  logic [31:0] nonce;

  //! result stating if the output of heavy hash is less than the target
  //! 1 : less than target (objective)
  //! 0 : greater than target
  logic result;

  //! acknowledge signal stating ready to recieve start signal
  logic stop_ack;

  //! status
  logic [1:0] status;

  logic [255:0] hash_out;

  logic hash_out_we;


  //internal signals

  logic hashin_fifo_in_full;
  logic matrix_fifo_in_full;
  logic hashout_fifo_re;
  logic [255:0] hashout_fifo_out_dout;
  logic hash_out_empty;
  logic nonce_fifo_we;
  logic nonce_fifo_full;
  logic stop_ack_comp;
  logic stop_ack_nonce;
  logic [31:0] nonce_fifo_din;
  logic [255:0] zero_reg  = 256'd0;
  logic heavy_hash_all_empty;
  logic [31:0] nonce_end_1;







  //-------------------------------------------------
  // AXI Write Interface logic
  //-------------------------------------------------
  logic wr_active;
  logic [31:0] wr_addr;
  logic awready;
  logic wready;
  logic [31:0]  golden_nonce = 32'd0;
  logic [255:0] golden_hash = 256'd0;

  const int BLOCKHEADER_REG_ADDR_BLK = `BLOCKHEADER_REG_ADDR + (NONCE_COEF-1)*44;
  const int MATRIX_REG_ADDR_BLK = `MATRIX_REG_ADDR + (NONCE_COEF-1)*44;
  const int TARGET_REG_ADDR_BLK = `TARGET_REG_ADDR + (NONCE_COEF-1)*44;
  const int NONCESIZE_REG_ADDR_BLK = `NONCESIZE_REG_ADDR + (NONCE_COEF-1)*44;
  const int START_REG_ADDR_BLK = `START_REG_ADDR + (NONCE_COEF-1)*44;
  const int STOP_REG_ADDR_BLK = `STOP_REG_ADDR + (NONCE_COEF-1)*44;
  const int ACK_REG_ADDR_BLK = `ACK_REG_ADDR + (NONCE_COEF-1)*44;


  always_ff @(posedge clk_axi)
    if (!rst_n)
    begin
      wr_active <= 0;
      wr_addr   <= 0;
    end
    else
    begin
      wr_active <=  wr_active && bvalid  && bready ? 1'b0     :
                ~wr_active && awvalid           ? 1'b1     :
                wr_active;
      wr_addr <= awvalid && ~wr_active ? awaddr : wr_addr     ;
    end

  assign awready = ~wr_active;
  assign wready  =  wr_active && wvalid;


  always_ff @(posedge clk_axi)
    if (!rst_n)
    begin                    // Reset
      block_header_axi <= 32'h0000_0000;
      matrix_in_axi <= 32'h0000_0000;
      target_axi <= 32'h0000_0000;
      nonce_size_axi <= 32'h0000_0000;
      start_axi <= 1'b0;
      stop_axi <= 1'b0;
      target_we_axi <= 1'b0;
      block_header_we_axi <= 1'b0;
      matrix_we_axi <= 1'b0;
      ack_axi <= 1'b0;
    end
    else if (wready & (wr_addr == BLOCKHEADER_REG_ADDR_BLK))
    begin
      block_header_axi <= wdata[31:0];
      block_header_we_axi <= 1'b1;
    end
    else if (wready & (wr_addr == MATRIX_REG_ADDR_BLK))
    begin
      matrix_in_axi <= wdata[31:0];
      matrix_we_axi <= 1'b1;
    end
    else if (wready & (wr_addr == TARGET_REG_ADDR_BLK))
    begin
      target_axi <= wdata[31:0];
      target_we_axi <= 1'b1;
    end
    else if (wready & (wr_addr == NONCESIZE_REG_ADDR_BLK))
    begin
      nonce_size_axi <= wdata[31:0];
    end
    else if (wready & (wr_addr == START_REG_ADDR_BLK))
    begin
      start_axi <= 1'b1;
    end
    else if (wready & (wr_addr == STOP_REG_ADDR_BLK))
    begin
      stop_axi <= 1'b1;
    end
    else if (wready & (wr_addr == ACK_REG_ADDR_BLK))
    begin
      ack_axi <= 1'b1;
    end
    else
    begin
      target_we_axi <= 1'b0;
      block_header_we_axi <= 1'b0;
      matrix_we_axi <= 1'b0;
      block_header_axi <= 32'd0;
      target_axi <= 32'd0;
      matrix_in_axi <= 32'd0;
      nonce_size_axi <= nonce_size_axi;
      start_axi <= 1'b0;
      stop_axi <= 1'b0;
      ack_axi <= 1'b0;
    end

  //-------------------------------------------------
  // AXI Read Interface logic
  //-------------------------------------------------
  // araddr_q, arvalid_q, counter i
  logic [31:0] araddr_q;
  logic arvalid_q;
  logic [2:0] counter_i;
  logic [31:0] rdata_int;
  logic rvalid_heavy_hash_int;
  logic arvalid_int;
  logic arvalid_int_old;
  logic [31:0] araddr_int;
  logic rvalid_heavy_hash_int_q = 1'b0;
  logic [31:0] rdata_int_q = 32'd0;
  logic [2:0] hold_cnt = 3'd0;
  logic [31:0] hashes_done;

  const int NONCE_REG_ADDR_BLK = `NONCE_REG_ADDR + (NONCE_COEF-1)*40;
  const int HEAVYHASH_REG_ADDR_BLK = `HEAVYHASH_REG_ADDR + (NONCE_COEF-1)*40;
  const int STATUS_REG_ADDR_BLK = `STATUS_REG_ADDR + (NONCE_COEF-1)*40;
  const int HASHES_DONE_ADDR_BLK = `HASHES_DONE_BASE + (NONCE_COEF-1)*40;
  always_ff @(posedge clk_int)
  begin
    arvalid_int_old <= arvalid_int;
  end


  always_ff @(posedge clk_int)
    if (rst)
    begin
      araddr_q <= 0;
      arvalid_q  <= 0;
      counter_i  <= 0;
    end
    else if (arvalid_int & ~arvalid_int_old)
    begin
      araddr_q <= araddr_int;
      arvalid_q  <= 1'b1;
      counter_i  <= counter_i;
    end
    else if(araddr_q == HEAVYHASH_REG_ADDR_BLK)
    begin
      counter_i <= counter_i + 1;
      araddr_q <= 0;
      arvalid_q  <= 0;
    end
    else
    begin
      araddr_q <= 0;
      arvalid_q  <= 0;
      counter_i  <= counter_i;
    end

  always_comb
  begin
    //default assignments
    rdata_int = 32'd0;
    rvalid_heavy_hash_int = 1'b0;
    if (araddr_q == NONCE_REG_ADDR_BLK)
    begin
      rvalid_heavy_hash_int = 1'b1;
      rdata_int = golden_nonce;
    end
    else if( araddr_q == HEAVYHASH_REG_ADDR_BLK)
    begin
      rvalid_heavy_hash_int = 1'b1;
      rdata_int = heavy_hash_32;
    end
    else if( araddr_q == STATUS_REG_ADDR_BLK)
    begin
      rvalid_heavy_hash_int = 1'b1;
      rdata_int = {30'd0, status};
    end
    else if( araddr_q == HASHES_DONE_ADDR_BLK)
    begin
      rvalid_heavy_hash_int = 1'b1;
      rdata_int = hashes_done;
    end
  end

  always_ff @( posedge clk_int )
  begin
    if(rvalid_heavy_hash_int)
    begin
      hold_cnt <= hold_cnt + 1;
      rvalid_heavy_hash_int_q <= 1'b1;
      rdata_int_q <= rdata_int;
    end
    else if(rvalid_heavy_hash_int_q == 1 && hold_cnt < 4)
    begin
      hold_cnt <= hold_cnt + 1;
      rvalid_heavy_hash_int_q <= rvalid_heavy_hash_int_q;
      rdata_int_q <= rdata_int_q;
    end
    else
    begin
      hold_cnt <= 0;
      rvalid_heavy_hash_int_q <= 0;
      rdata_int_q <= 0;
    end
  end



  
  //-------------------------------------------------
  // Synchronizations for bus (multi-bit) signals
  //-------------------------------------------------
  xpm_cdc_gray #(
                 .DEST_SYNC_FF(4),          // DECIMAL; range: 2-10
                 .INIT_SYNC_FF(0),          // DECIMAL; 0=disable simulation init values, 1=enable simulation init values
                 .REG_OUTPUT(0),            // DECIMAL; 0=disable registered output, 1=enable registered output
                 .SIM_ASSERT_CHK(0),        // DECIMAL; 0=disable simulation messages, 1=enable simulation messages
                 .SIM_LOSSLESS_GRAY_CHK(0), // DECIMAL; 0=disable lossless check, 1=enable lossless check
                 .WIDTH(32)                 // DECIMAL; range: 2-32
               )
               sync_block_header (
                 .dest_out_bin(block_header_int), // WIDTH-bit output: Binary input bus (src_in_bin) synchronized to
                 // destination clock domain. This output is combinatorial unless REG_OUTPUT
                 // is set to 1.

                 .dest_clk(clk_int),         // 1-bit input: Destination clock.
                 .src_clk(clk_axi),           // 1-bit input: Source clock.
                 .src_in_bin(block_header_axi)      // WIDTH-bit input: Binary input bus that will be synchronized to the
                 // destination clock domain.

               );

  xpm_cdc_gray #(
                 .DEST_SYNC_FF(4),          // DECIMAL; range: 2-10
                 .INIT_SYNC_FF(0),          // DECIMAL; 0=disable simulation init values, 1=enable simulation init values
                 .REG_OUTPUT(0),            // DECIMAL; 0=disable registered output, 1=enable registered output
                 .SIM_ASSERT_CHK(0),        // DECIMAL; 0=disable simulation messages, 1=enable simulation messages
                 .SIM_LOSSLESS_GRAY_CHK(0), // DECIMAL; 0=disable lossless check, 1=enable lossless check
                 .WIDTH(32)                  // DECIMAL; range: 2-32
               )
               sync_matrix (
                 .dest_out_bin(matrix_in_int), // WIDTH-bit output: Binary input bus (src_in_bin) synchronized to
                 // destination clock domain. This output is combinatorial unless REG_OUTPUT
                 // is set to 1.

                 .dest_clk(clk_int),         // 1-bit input: Destination clock.
                 .src_clk(clk_axi),           // 1-bit input: Source clock.
                 .src_in_bin(matrix_in_axi)      // WIDTH-bit input: Binary input bus that will be synchronized to the
                 // destination clock domain.

               );

  xpm_cdc_gray #(
                 .DEST_SYNC_FF(4),          // DECIMAL; range: 2-10
                 .INIT_SYNC_FF(0),          // DECIMAL; 0=disable simulation init values, 1=enable simulation init values
                 .REG_OUTPUT(0),            // DECIMAL; 0=disable registered output, 1=enable registered output
                 .SIM_ASSERT_CHK(0),        // DECIMAL; 0=disable simulation messages, 1=enable simulation messages
                 .SIM_LOSSLESS_GRAY_CHK(0), // DECIMAL; 0=disable lossless check, 1=enable lossless check
                 .WIDTH(32)                  // DECIMAL; range: 2-32
               )
               sync_target (
                 .dest_out_bin(target_int), // WIDTH-bit output: Binary input bus (src_in_bin) synchronized to
                 // destination clock domain. This output is combinatorial unless REG_OUTPUT
                 // is set to 1.

                 .dest_clk(clk_int),         // 1-bit input: Destination clock.
                 .src_clk(clk_axi),           // 1-bit input: Source clock.
                 .src_in_bin(target_axi)      // WIDTH-bit input: Binary input bus that will be synchronized to the
                 // destination clock domain.

               );

  xpm_cdc_gray #(
                 .DEST_SYNC_FF(4),          // DECIMAL; range: 2-10
                 .INIT_SYNC_FF(0),          // DECIMAL; 0=disable simulation init values, 1=enable simulation init values
                 .REG_OUTPUT(1),            // DECIMAL; 0=disable registered output, 1=enable registered output
                 .SIM_ASSERT_CHK(0),        // DECIMAL; 0=disable simulation messages, 1=enable simulation messages
                 .SIM_LOSSLESS_GRAY_CHK(0), // DECIMAL; 0=disable lossless check, 1=enable lossless check
                 .WIDTH(32)                  // DECIMAL; range: 2-32
               )
               sync_nonce_size (
                 .dest_out_bin(nonce_size_int), // WIDTH-bit output: Binary input bus (src_in_bin) synchronized to
                 // destination clock domain. This output is combinatorial unless REG_OUTPUT
                 // is set to 1.

                 .dest_clk(clk_int),         // 1-bit input: Destination clock.
                 .src_clk(clk_axi),           // 1-bit input: Source clock.
                 .src_in_bin(nonce_size_axi)      // WIDTH-bit input: Binary input bus that will be synchronized to the
                 // destination clock domain.

               );

  xpm_cdc_gray #(
                 .DEST_SYNC_FF(4),          // DECIMAL; range: 2-10
                 .INIT_SYNC_FF(0),          // DECIMAL; 0=disable simulation init values, 1=enable simulation init values
                 .REG_OUTPUT(0),            // DECIMAL; 0=disable registered output, 1=enable registered output
                 .SIM_ASSERT_CHK(0),        // DECIMAL; 0=disable simulation messages, 1=enable simulation messages
                 .SIM_LOSSLESS_GRAY_CHK(0), // DECIMAL; 0=disable lossless check, 1=enable lossless check
                 .WIDTH(32)                  // DECIMAL; range: 2-32
               )
               sync_rdata(
                 .dest_out_bin(rdata), // WIDTH-bit output: Binary input bus (src_in_bin) synchronized to
                 // destination clock domain. This output is combinatorial unless REG_OUTPUT
                 // is set to 1.

                 .dest_clk(clk_axi),         // 1-bit input: Destination clock.
                 .src_clk(clk_int),           // 1-bit input: Source clock.
                 .src_in_bin(rdata_int_q)      // WIDTH-bit input: Binary input bus that will be synchronized to the
                 // destination clock domain.

               );

  xpm_cdc_gray #(
                 .DEST_SYNC_FF(4),          // DECIMAL; range: 2-10
                 .INIT_SYNC_FF(0),          // DECIMAL; 0=disable simulation init values, 1=enable simulation init values
                 .REG_OUTPUT(0),            // DECIMAL; 0=disable registered output, 1=enable registered output
                 .SIM_ASSERT_CHK(0),        // DECIMAL; 0=disable simulation messages, 1=enable simulation messages
                 .SIM_LOSSLESS_GRAY_CHK(0), // DECIMAL; 0=disable lossless check, 1=enable lossless check
                 .WIDTH(32)                  // DECIMAL; range: 2-32
               )
               sync_araddr(
                 .dest_out_bin(araddr_int), // WIDTH-bit output: Binary input bus (src_in_bin) synchronized to
                 // destination clock domain. This output is combinatorial unless REG_OUTPUT
                 // is set to 1.

                 .dest_clk(clk_int),         // 1-bit input: Destination clock.
                 .src_clk(clk_axi),           // 1-bit input: Source clock.
                 .src_in_bin(araddr)      // WIDTH-bit input: Binary input bus that will be synchronized to the
                 // destination clock domain.

               );

  //-------------------------------------------------
  // Synchronizations for 1-bit signals
  //-------------------------------------------------
  xpm_cdc_single #(
                   .DEST_SYNC_FF(4),   // DECIMAL; range: 2-10
                   .INIT_SYNC_FF(0),   // DECIMAL; 0=disable simulation init values, 1=enable simulation init values
                   .SIM_ASSERT_CHK(0), // DECIMAL; 0=disable simulation messages, 1=enable simulation messages
                   .SRC_INPUT_REG(1)   // DECIMAL; 0=do not register input, 1=register input
                 )
                 sync_block_header_we (
                   .dest_out(block_header_we_int), // 1-bit output: src_in synchronized to the destination clock domain. This output is
                   // registered.
                   .dest_clk(clk_int), // 1-bit input: Clock signal for the destination clock domain.
                   .src_clk(clk_axi),   // 1-bit input: optional; required when SRC_INPUT_REG = 1
                   .src_in(block_header_we_axi)      // 1-bit input: Input signal to be synchronized to dest_clk domain.
                 );

  xpm_cdc_single #(
                   .DEST_SYNC_FF(4),   // DECIMAL; range: 2-10
                   .INIT_SYNC_FF(0),   // DECIMAL; 0=disable simulation init values, 1=enable simulation init values
                   .SIM_ASSERT_CHK(0), // DECIMAL; 0=disable simulation messages, 1=enable simulation messages
                   .SRC_INPUT_REG(1)   // DECIMAL; 0=do not register input, 1=register input
                 )
                 sync_matrix_we (
                   .dest_out(matrix_we_int), // 1-bit output: src_in synchronized to the destination clock domain. This output is
                   // registered.
                   .dest_clk(clk_int), // 1-bit input: Clock signal for the destination clock domain.
                   .src_clk(clk_axi),   // 1-bit input: optional; required when SRC_INPUT_REG = 1
                   .src_in(matrix_we_axi)      // 1-bit input: Input signal to be synchronized to dest_clk domain.
                 );

  xpm_cdc_single #(
                   .DEST_SYNC_FF(4),   // DECIMAL; range: 2-10
                   .INIT_SYNC_FF(0),   // DECIMAL; 0=disable simulation init values, 1=enable simulation init values
                   .SIM_ASSERT_CHK(0), // DECIMAL; 0=disable simulation messages, 1=enable simulation messages
                   .SRC_INPUT_REG(1)   // DECIMAL; 0=do not register input, 1=register input
                 )
                 sync_target_we (
                   .dest_out(target_we_int), // 1-bit output: src_in synchronized to the destination clock domain. This output is
                   // registered.
                   .dest_clk(clk_int), // 1-bit input: Clock signal for the destination clock domain.
                   .src_clk(clk_axi),   // 1-bit input: optional; required when SRC_INPUT_REG = 1
                   .src_in(target_we_axi)      // 1-bit input: Input signal to be synchronized to dest_clk domain.
                 );


  xpm_cdc_single #(
                   .DEST_SYNC_FF(4),   // DECIMAL; range: 2-10
                   .INIT_SYNC_FF(0),   // DECIMAL; 0=disable simulation init values, 1=enable simulation init values
                   .SIM_ASSERT_CHK(0), // DECIMAL; 0=disable simulation messages, 1=enable simulation messages
                   .SRC_INPUT_REG(0)   // DECIMAL; 0=do not register input, 1=register input
                 )
                 sync_start (
                   .dest_out(start_int), // 1-bit output: src_in synchronized to the destination clock domain. This output is
                   // registered.
                   .dest_clk(clk_int), // 1-bit input: Clock signal for the destination clock domain.
                   .src_clk(clk_axi),   // 1-bit input: optional; required when SRC_INPUT_REG = 1
                   .src_in(start_axi)      // 1-bit input: Input signal to be synchronized to dest_clk domain.
                 );

  xpm_cdc_single #(
                   .DEST_SYNC_FF(4),   // DECIMAL; range: 2-10
                   .INIT_SYNC_FF(0),   // DECIMAL; 0=disable simulation init values, 1=enable simulation init values
                   .SIM_ASSERT_CHK(0), // DECIMAL; 0=disable simulation messages, 1=enable simulation messages
                   .SRC_INPUT_REG(0)   // DECIMAL; 0=do not register input, 1=register input
                 )
                 sync_stop (
                   .dest_out(stop_int), // 1-bit output: src_in synchronized to the destination clock domain. This output is
                   // registered.
                   .dest_clk(clk_int), // 1-bit input: Clock signal for the destination clock domain.
                   .src_clk(clk_axi),   // 1-bit input: optional; required when SRC_INPUT_REG = 1
                   .src_in(stop_axi)      // 1-bit input: Input signal to be synchronized to dest_clk domain.
                 );

  xpm_cdc_single #(
                   .DEST_SYNC_FF(4),   // DECIMAL; range: 2-10
                   .INIT_SYNC_FF(0),   // DECIMAL; 0=disable simulation init values, 1=enable simulation init values
                   .SIM_ASSERT_CHK(0), // DECIMAL; 0=disable simulation messages, 1=enable simulation messages
                   .SRC_INPUT_REG(0)   // DECIMAL; 0=do not register input, 1=register input
                 )
                 sync_ack (
                   .dest_out(ack_int), // 1-bit output: src_in synchronized to the destination clock domain. This output is
                   // registered.
                   .dest_clk(clk_int), // 1-bit input: Clock signal for the destination clock domain.
                   .src_clk(clk_axi),   // 1-bit input: optional; required when SRC_INPUT_REG = 1
                   .src_in(ack_axi)      // 1-bit input: Input signal to be synchronized to dest_clk domain.
                 );

  xpm_cdc_single #(
                   .DEST_SYNC_FF(4),   // DECIMAL; range: 2-10
                   .INIT_SYNC_FF(0),   // DECIMAL; 0=disable simulation init values, 1=enable simulation init values
                   .SIM_ASSERT_CHK(0), // DECIMAL; 0=disable simulation messages, 1=enable simulation messages
                   .SRC_INPUT_REG(1)   // DECIMAL; 0=do not register input, 1=register input
                 )
                 sync_rdata_valid_heavyhash_int (
                   .dest_out(rvalid_heavy_hash), // 1-bit output: src_in synchronized to the destination clock domain. This output is
                   // registered.
                   .dest_clk(clk_axi), // 1-bit input: Clock signal for the destination clock domain.
                   .src_clk(clk_int),   // 1-bit input: optional; required when SRC_INPUT_REG = 1
                   .src_in(rvalid_heavy_hash_int_q)      // 1-bit input: Input signal to be synchronized to dest_clk domain.
                 );

  xpm_cdc_single #(
                   .DEST_SYNC_FF(4),   // DECIMAL; range: 2-10
                   .INIT_SYNC_FF(0),   // DECIMAL; 0=disable simulation init values, 1=enable simulation init values
                   .SIM_ASSERT_CHK(0), // DECIMAL; 0=disable simulation messages, 1=enable simulation messages
                   .SRC_INPUT_REG(1)   // DECIMAL; 0=do not register input, 1=register input
                 )
                 sync_arvalid (
                   .dest_out(arvalid_int), // 1-bit output: src_in synchronized to the destination clock domain. This output is
                   // registered.
                   .dest_clk(clk_int), // 1-bit input: Clock signal for the destination clock domain.
                   .src_clk(clk_axi),   // 1-bit input: optional; required when SRC_INPUT_REG = 1
                   .src_in(arvalid)      // 1-bit input: Input signal to be synchronized to dest_clk domain.
                 );
  logic matrix_we;
  logic matrix_we_int_old;
  logic block_header_we_int_old;
  logic target_we_int_old;
  logic block_header_we;
  logic target_we;
  always @(posedge clk_int)
  begin
    matrix_we_int_old <= matrix_we_int;
    block_header_we_int_old <= block_header_we_int;
    target_we_int_old <= target_we_int;
  end

  always @(posedge clk_int)
  begin
    if(matrix_we_int & ~matrix_we_int_old)
      matrix_we <= 1'b1;
    else
      matrix_we <= 1'b0;

    if(block_header_we_int & ~block_header_we_int_old)
      block_header_we <= 1'b1;
    else
      block_header_we <= 1'b0;

    if(target_we_int & ~target_we_int_old)
      target_we <= 1'b1;
    else
      target_we <= 1'b0;

  end

  //-------------------------------------------------
  // Synchronizations for reset
  //-------------------------------------------------
  xpm_cdc_sync_rst #(
                     .DEST_SYNC_FF(4),   // DECIMAL; range: 2-10
                     .INIT(1),           // DECIMAL; 0=initialize synchronization registers to 0, 1=initialize synchronization
                     // registers to 1
                     .INIT_SYNC_FF(0),   // DECIMAL; 0=disable simulation init values, 1=enable simulation init values
                     .SIM_ASSERT_CHK(0)  // DECIMAL; 0=disable simulation messages, 1=enable simulation messages
                   )
                   sync_rst (
                     .dest_rst(rst), // 1-bit output: src_rst synchronized to the destination clock domain. This output
                     // is registered.

                     .dest_clk(clk_int), // 1-bit input: Destination clock.
                     .src_rst(~rst_n)    // 1-bit input: Source reset signal.
                   );


  //-------------------------------------------------
  // Synchronizations for reset
  //-------------------------------------------------
  logic [63:0] hashin_fifo_in_din;
  logic [31:0] nonce_end;


  nonce_gen
    #(
      .NONCE_COEF ( NONCE_COEF )
    )
    nonce_gen_dut (
      .clk (clk_int ),
      .rst (rst ),
      .start (start_int ),
      .stop (stop_int),
      .block_header (block_header_int ),
      .block_header_we(block_header_we),
      .nonce_size (nonce_size_int ),
      .hashin_fifo_in_we (hashin_fifo_in_we ),
      .hashin_fifo_in_din (hashin_fifo_in_din ),
      .hashin_fifo_in_full (hashin_fifo_in_full ),
      .nonce_fifo_full (nonce_fifo_full ),
      .nonce_fifo_din (nonce_fifo_din ),
      .nonce_fifo_we (nonce_fifo_we ),
      .stop_ack_nonce  ( stop_ack_nonce),
`ifdef DBG_
      .state_nonce_dbg(state_nonce_dbg),
`endif
      .nonce_end(nonce_end)
    );


  logic heavy_hash_out_re;
  logic [63:0] heavy_hash_out_data;
  logic heavy_hash_out_we;

  heavy_hash
    #(
      .WCOUNT (WCOUNT )
    )
    heavy_hash_dut (
      .clk (clk_int ),
      .rst (rst | stop_int),
      .hashin_fifo_in_we (hashin_fifo_in_we ),
      .hashin_fifo_in_din (hashin_fifo_in_din ),
      .hashin_fifo_in_full (hashin_fifo_in_full ),
      .matrix_fifo_in_we (matrix_we ),
      .matrix_fifo_in_din (matrix_in_int ),
      .matrix_fifo_in_full (matrix_fifo_in_full ),
      .heavy_hash_out_re (heavy_hash_out_re ),
      .nonce_fifo_full (nonce_fifo_full ),
      .nonce_fifo_din (nonce_fifo_din ),
      .nonce_fifo_we (nonce_fifo_we ),
      .nonce (nonce ),
      .heavy_hash_out_data (heavy_hash_out_data ),
      .heavy_hash_out_we  ( heavy_hash_out_we),
      .nonce_fifo_re (nonce_fifo_re)
    );


  logic [255:0] heavy_hash_dout;
  logic nonce_fifo_re;
  logic heavy_hash_rdy;
  comparator
    comparator_inst (
      .clk (clk_int ),
      .rst (rst),
      .target (target_int ),
      .target_we (target_we ),
      .start (start_int ),
      .stop (stop_int ),
      .heavy_hash_re (heavy_hash_out_re ),
      .heavy_hash_din (heavy_hash_out_data ),
      .heavy_hash_din_we (heavy_hash_out_we ),
      .heavy_hash_dout (heavy_hash_dout ),
      .result  ( result),
      .nonce_fifo_re (nonce_fifo_re),
      .hashes_done(hashes_done),
      .heavy_hash_rdy(heavy_hash_rdy)
    );


  //-------------------------------------------------
  // Status logic
  //-------------------------------------------------

  assign nonce_end_1 = nonce_end -1 ;

  
  //-------------------------------------------------
  // Golden nonce and Golden hash
  //-------------------------------------------------
  
  logic golden_state  = 0;
  logic [1:0] status_old;
  logic state_status;

  always_ff @(posedge clk_int )
  begin
    if(rst | stop_int)
    begin
      status <= 0;
      state_status <= 0;
      status_old <= 0;
    end
    else
    begin
      status_old <= status;
      case (state_status)
        0:
        begin
          if(result)
          begin
            status <= 1;
            state_status <= 1;
          end
          else
          begin
            state_status <= 0;
            if(nonce < nonce_end_1)
            begin
              status <= 2;
            end
            else
              status <= 0;
          end
        end
        1:
        begin
          if(ack_int)
          begin
            status <= 0;
            state_status <= 0;
          end
          else
          begin
            status <= 1;
            state_status <= 1;
          end
        end
      endcase
    end
  end

  always_ff @(posedge clk_int )
  begin
    if(stop_int)
      golden_state <= 0;
    else if(status == 1 && status_old == 2)
    begin
      golden_state <= 1;   
    end
    else if (heavy_hash_rdy)
    begin
      golden_state <= 0;   
    end
    else
    begin
      golden_state <= golden_state;
    end

    if(stop_int)
    begin
      golden_hash  <= 0;
      golden_nonce <= 0;
    end
    if (heavy_hash_rdy & golden_state)
    begin
      golden_hash  <= heavy_hash_dout;
      golden_nonce <= nonce;
    end
    else
    begin
      golden_hash  <= golden_hash;
      golden_nonce <= golden_nonce;
    end
  end


  //-------------------------------------------------
  // MUX for Heavyhash 32-bit output
  //-------------------------------------------------
  logic [31:0] heavy_hash_32;
  always_comb
  begin
    case (counter_i)
      0:
        heavy_hash_32 = golden_hash[255:224];
      1:
        heavy_hash_32 = golden_hash[223:192];
      2:
        heavy_hash_32 = golden_hash[191:160];
      3:
        heavy_hash_32 = golden_hash[159:128];
      4:
        heavy_hash_32 = golden_hash[127: 96];
      5:
        heavy_hash_32 = golden_hash[ 95: 64];
      6:
        heavy_hash_32 = golden_hash[ 63: 32];
      7:
        heavy_hash_32 = golden_hash[ 31:  0];
    endcase
  end







`ifdef VERIF_
  //checker part
  logic [31:0] count_m = 0;
  always_ff @( posedge clk_int )
  begin
    if (comparator_inst.state_reg == 5)
    begin
      count_m <= count_m + 1;
    end
    if(stop_int)
    begin
      count_m <= 0;
    end
  end

  always @(comparator_inst.state_reg)
  begin
    // if(heavy_hash_dout != heavy_hash_ref[/*(NONCE_COEF - 1) * nonce_size_int +*/ i])
    //   $display("Error -- blk[%d]-- heavy_hash : %h", NONCE_COEF - 1, heavy_hash_dout);
    if(comparator_inst.state_reg == 2 && count_m > 0)
    begin
      
      if(NONCE_COEF == 1)
      begin
        //$display(cl_hello_world.heavy_hash_ref0[count_m - 1]);
        if(heavy_hash_dout != cl_hello_world.heavy_hash_ref0[count_m - 1]) begin
          $display("%d --- %h -- %h", count_m - 1, heavy_hash_dout, cl_hello_world.heavy_hash_ref0[count_m - 1]);
        end
      end
      else
      begin
        if(heavy_hash_dout != cl_hello_world.heavy_hash_ref1[count_m - 1])
          $display("%d --- %h -- %h", count_m - 1, heavy_hash_dout, cl_hello_world.heavy_hash_ref1[count_m - 1]);
      end
    end
  end
`endif



endmodule
