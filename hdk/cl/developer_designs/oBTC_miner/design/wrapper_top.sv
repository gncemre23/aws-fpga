// Amazon FPGA Hardware Development Kit
//
// Copyright 2016 Amazon.com, Inc. or its affiliates. All Rights Reserved.
//
// Licensed under the Amazon Software License (the "License"). You may not use
// this file except in compliance with the License. A copy of the License is
// located at
//
//    http://aws.amazon.com/asl/
//
// or in the "license" file accompanying this file. This file is distributed on
// an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, express or
// implied. See the License for the specific language governing permissions and
// limitations under the License.

module cl_hello_world

  (
`include "cl_ports.vh" // Fixed port definition

  );

  // export "DPI-C" function slave_write;

`include "cl_common_defines.vh"      // CL Defines for all examples
`include "cl_id_defines.vh"          // Defines for ID0 and ID1 (PCI ID's)
`include "cl_hello_world_defines.vh" // CL Defines for cl_hello_world

  logic rst_main_n_sync;


  //--------------------------------------------0
  // Start with Tie-Off of Unused Interfaces
  //---------------------------------------------
  // the developer should use the next set of `include
  // to properly tie-off any unused interface
  // The list is put in the top of the module
  // to avoid cases where developer may forget to
  // remove it from the end of the file

`include "unused_flr_template.inc"
`include "unused_ddr_a_b_d_template.inc"
`include "unused_ddr_c_template.inc"
`include "unused_pcim_template.inc"
`include "unused_dma_pcis_template.inc"
`include "unused_cl_sda_template.inc"
`include "unused_sh_bar1_template.inc"
`include "unused_apppf_irq_template.inc"


  parameter  BLK_CNT = 8;
  //-------------------------------------------------
  // Wires
  //-------------------------------------------------
  logic        arvalid_q;
  logic [31:0] araddr_q;
  logic [31:0] hello_world_q_byte_swapped;
  logic [15:0] vled_q;
  logic [15:0] pre_cl_sh_status_vled;
  logic [15:0] sh_cl_status_vdip_q;
  logic [15:0] sh_cl_status_vdip_q2;
  logic [31:0] hello_world_q;




  genvar k;





  //-------------------------------------------------
  // ID Values (cl_hello_world_defines.vh)
  //-------------------------------------------------
  assign cl_sh_id0[31:0] = `CL_SH_ID0;
  assign cl_sh_id1[31:0] = `CL_SH_ID1;

  //-------------------------------------------------
  // Reset Synchronization
  //-------------------------------------------------
  logic pre_sync_rst_n;

  always_ff @(negedge rst_main_n or posedge clk_main_a0)
    if (!rst_main_n)
    begin
      pre_sync_rst_n  <= 0;
      rst_main_n_sync <= 0;
    end
    else
    begin
      pre_sync_rst_n  <= 1;
      rst_main_n_sync <= pre_sync_rst_n;
    end

  //-------------------------------------------------
  // PCIe OCL AXI-L (SH to CL) Timing Flops
  //-------------------------------------------------

  // Write address
  logic        sh_ocl_awvalid_q;
  logic [31:0] sh_ocl_awaddr_q;
  logic        ocl_sh_awready_q;

  // Write data
  logic        sh_ocl_wvalid_q;
  logic [31:0] sh_ocl_wdata_q;
  logic [ 3:0] sh_ocl_wstrb_q;
  logic        ocl_sh_wready_q;

  // Write response
  logic        ocl_sh_bvalid_q;
  logic [ 1:0] ocl_sh_bresp_q;
  logic        sh_ocl_bready_q;

  // Read address
  logic        sh_ocl_arvalid_q;
  logic [31:0] sh_ocl_araddr_q;
  logic        ocl_sh_arready_q;

  // Read data/response
  logic        ocl_sh_rvalid_q;
  logic [31:0] ocl_sh_rdata_q;
  logic [ 1:0] ocl_sh_rresp_q;
  logic        sh_ocl_rready_q;

  axi_register_slice_light
    AXIL_OCL_REG_SLC (
      .aclk          (clk_main_a0),
      .aresetn       (rst_main_n_sync),
      .s_axi_awaddr  (sh_ocl_awaddr),
      .s_axi_awprot   (2'h0),
      .s_axi_awvalid (sh_ocl_awvalid),
      .s_axi_awready (ocl_sh_awready),
      .s_axi_wdata   (sh_ocl_wdata),
      .s_axi_wstrb   (sh_ocl_wstrb),
      .s_axi_wvalid  (sh_ocl_wvalid),
      .s_axi_wready  (ocl_sh_wready),
      .s_axi_bresp   (ocl_sh_bresp),
      .s_axi_bvalid  (ocl_sh_bvalid),
      .s_axi_bready  (sh_ocl_bready),
      .s_axi_araddr  (sh_ocl_araddr),
      .s_axi_arvalid (sh_ocl_arvalid),
      .s_axi_arready (ocl_sh_arready),
      .s_axi_rdata   (ocl_sh_rdata),
      .s_axi_rresp   (ocl_sh_rresp),
      .s_axi_rvalid  (ocl_sh_rvalid),
      .s_axi_rready  (sh_ocl_rready),
      .m_axi_awaddr  (sh_ocl_awaddr_q),
      .m_axi_awprot  (),
      .m_axi_awvalid (sh_ocl_awvalid_q),
      .m_axi_awready (ocl_sh_awready_q),
      .m_axi_wdata   (sh_ocl_wdata_q),
      .m_axi_wstrb   (sh_ocl_wstrb_q),
      .m_axi_wvalid  (sh_ocl_wvalid_q),
      .m_axi_wready  (ocl_sh_wready_q),
      .m_axi_bresp   (ocl_sh_bresp_q),
      .m_axi_bvalid  (ocl_sh_bvalid_q),
      .m_axi_bready  (sh_ocl_bready_q),
      .m_axi_araddr  (sh_ocl_araddr_q),
      .m_axi_arvalid (sh_ocl_arvalid_q),
      .m_axi_arready (ocl_sh_arready_q),
      .m_axi_rdata   (ocl_sh_rdata_q),
      .m_axi_rresp   (ocl_sh_rresp_q),
      .m_axi_rvalid  (ocl_sh_rvalid_q),
      .m_axi_rready  (sh_ocl_rready_q)
    );

  //-------------------------------------------------
  // Wires for oBTCMiner_design
  //-------------------------------------------------
  logic rst_oBTC_sync;
  logic block_header_we;
  logic matrix_fifo_we;
  logic target_we;
  logic start;
  logic stop;
  logic [31:0] block_header;
  logic [31:0] matrix_in;
  logic [31:0] target;
  logic [31:0] nonce_size;
  logic [31:0] nonce;
  logic [1:0] status;
  logic [31:0] heavyhash;
  logic hash_re;
  logic [$clog2(BLK_CNT)-1:0] hash_select;


`ifdef DBG_
  logic [255:0] hash_out_dbg;
  logic hash_out_we_dbg;
  logic stop_ack_dbg;
  logic [2:0] state_nonce_dbg;
  logic [2:0] state_comparator_dbg;
  logic hashin_fifo_in_we;
  logic [63:0] hashin_fifo_in_din;
  logic sha3in_dst_write_dbg;
  logic [63:0] sha3in_dout_dbg;
  logic sha3out_dst_write_dbg;
  logic [63:0] sha3out_dout_dbg;
  logic [1:0] state_top_dbg;
  logic start_dbg;
  logic stop_dbg;
  logic [255:0] target_dbg;
  logic [31:0] nonce_end_dbg;
`endif


  //-------------------------------------------------
  // Reset Synchronization for oBTC
  //------------------------- ------------------------
  logic pre_sync_rst;

  always_ff @(negedge rst_main_n or posedge clk_extra_a3)
    if (!rst_main_n)
    begin
      pre_sync_rst  <= 1;
      rst_oBTC_sync <= 1;
    end
    else
    begin
      pre_sync_rst  <= 0;
      rst_oBTC_sync <= pre_sync_rst;
    end

  logic dummy_reg_a1;
  logic dummy_reg_a2;
  logic dummy_reg_a3;
  logic dummy_reg_b0;
  logic dummy_reg_b1;
  logic dummy_reg_c0;
  logic dummy_reg_c1;
  //This registers are added to work around for the error given below
  //ERROR: [Place 30-838] The following clock nets need to use the same
  //clock routing resource, as their clock buffer sources are locked to
  //sites that use the same routing track. One or more loads of these
  //clocks are locked to clock region(s) X2Y11 X2Y12 which causes the
  //clock partitions for these clocks to overlap. This creates
  //unresolvable contention on the clock routing resources.
  //If the clock buffers need to be locked, we recommend users constrain
  //them to a clock region and not to specific BUFGCE/BUFG_GT sites so
  //they can use different routing resources. If clock sources should be
  //locked to specific BUFGCE/BUFG_GT sites that share the same routing resources,
  //make sure loads of such clocks are not constrained to the same region(s). Clock nets sharing routing resources:
  //ERROR:[Place 30-678] Failed to do clock region partitioning: failed to resolve clock partition contention for locked clock sources.

  always_ff @(posedge clk_extra_a1)
    dummy_reg_a1 <= 1'b0;

  always_ff @(posedge clk_extra_a2)
    dummy_reg_a2 <= 1'b0;

  always_ff @(posedge clk_extra_a3)
    dummy_reg_a3 <= 1'b0;

  always_ff @(posedge clk_extra_b0)
    dummy_reg_b0 <= 1'b0;

  always_ff @(posedge clk_extra_b1)
    dummy_reg_b1 <= 1'b0;

  always_ff @(posedge clk_extra_c0)
    dummy_reg_c0 <= 1'b0;

  always_ff @(posedge clk_extra_c1)
    dummy_reg_c1 <= 1'b0;



  


  






  //--------------------------------------------------------------
  // PCIe OCL AXI-L Slave Accesses (accesses from PCIe AppPF BAR0)
  //--------------------------------------------------------------
  // Only supports single-beat accesses.

  logic        awvalid;
  logic [31:0] awaddr;
  logic        wvalid;
  logic [31:0] wdata;
  logic [3:0]  wstrb;
  logic        bready;
  logic        arvalid;
  logic [31:0] araddr;
  logic        rready;

  logic        awready;
  logic        wready;
  logic        bvalid;
  logic [1:0]  bresp;
  logic        arready;
  logic        rvalid;
  logic [31:0] rdata;
  logic [1:0]  rresp;

  // Inputs
  assign awvalid         = sh_ocl_awvalid_q;
  assign awaddr[31:0]    = sh_ocl_awaddr_q;
  assign wvalid          = sh_ocl_wvalid_q;
  assign wdata[31:0]     = sh_ocl_wdata_q;
  assign wstrb[3:0]      = sh_ocl_wstrb_q;
  assign bready          = sh_ocl_bready_q;
  assign arvalid         = sh_ocl_arvalid_q;
  assign araddr[31:0]    = sh_ocl_araddr_q;
  assign rready          = sh_ocl_rready_q;

  // Outputs
  assign ocl_sh_awready_q = awready;
  assign ocl_sh_wready_q  = wready;
  assign ocl_sh_bvalid_q  = bvalid;
  assign ocl_sh_bresp_q   = bresp[1:0];
  assign ocl_sh_arready_q = arready;
  assign ocl_sh_rvalid_q  = rvalid;
  assign ocl_sh_rdata_q   = rdata;
  assign ocl_sh_rresp_q   = rresp[1:0];




  //--------------------------------------------------------------
  // Heavy hash blocks instantiation
  //--------------------------------------------------------------
  logic [31:0] rdata_blk[BLK_CNT-1 : 0];
  logic rvalid_heavy_hash[BLK_CNT-1:0];
  logic [31:0] rdata_blk_or[BLK_CNT : 0];
  logic [31:0] rvalid_or[BLK_CNT : 0];
  
  generate
    for (k=0;k<BLK_CNT;k++ )
    begin
      heavy_hash_blk
        #(
          .NONCE_COEF(k+1),
          .WCOUNT ( 4 )
        )
        heavy_hash_blk_dut (
          .clk_axi (clk_main_a0 ),
          .clk_int (clk_extra_b0), //B5 = 400MHz
          .rst_n (rst_main_n_sync ),
          //axi input interfaces
          .awvalid(awvalid),
          .awaddr(awaddr),
          .wvalid(wvalid),
          .wdata(wdata),
          .arvalid(arvalid),
          .araddr(araddr),
          .rready(rready),
          .bvalid(bvalid),
          .bready(bready),
          //axi output interfaces
          .rdata(rdata_blk[k]),
          .rvalid_heavy_hash(rvalid_heavy_hash[k])
        );
    end
  endgenerate


  //--------------------------------------------------------------
  // OR operations for rdata_blk signals
  // only one of the blocks output is different than zero.
  //--------------------------------------------------------------
  assign rdata_blk_or[0] = 1'b0;
  assign rvalid_or[0] = 1'b0;
  generate
    for (k = 0 ; k < BLK_CNT ; k ++ )
    begin
      assign rdata_blk_or[k+1] = rdata_blk[k] | rdata_blk_or[k];
      assign rvalid_or[k+1] = rvalid_heavy_hash[k] | rvalid_or[k];
    end
  endgenerate

  // Write Request
  logic        wr_active;
  logic [31:0] wr_addr;

  always_ff @(posedge clk_main_a0)
    if (!rst_main_n_sync)
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

  // Write Response
  always_ff @(posedge clk_main_a0)
    if (!rst_main_n_sync)
      bvalid <= 0;
    else
      bvalid <=  bvalid &&  bready           ? 1'b0  :
             ~bvalid && wready ? 1'b1  :
             bvalid;
  assign bresp = 0;

  // Read Request
  always_ff @(posedge clk_main_a0)
    if (!rst_main_n_sync)
    begin
      arvalid_q <= 0;
      araddr_q  <= 0;
    end
    else
    begin
      arvalid_q <= arvalid;
      araddr_q  <= arvalid ? araddr : araddr_q;
    end

  assign arready = !arvalid_q && !rvalid;

  // Read Response
  always_ff @(posedge clk_main_a0)
    if (!rst_main_n_sync)
    begin
      rvalid <= 0;
      rdata  <= 0;
      rresp  <= 0;
      hash_re <= 0;
    end
    else if (rvalid && rready)
    begin
      rvalid <= 0;
      rdata  <= 0;
      rresp  <= 0;
      hash_re <= 0;
    end
    else if (arvalid_q && (araddr_q == `HELLO_WORLD_REG_ADDR || araddr_q == `VLED_REG_ADDR))
    begin
      rvalid <= 1;
      rdata  <= (araddr_q == `HELLO_WORLD_REG_ADDR  ) ? hello_world_q_byte_swapped[31:0]:
             (araddr_q == `VLED_REG_ADDR         ) ? {16'b0,vled_q[15:0]            }:
             0;
      rresp  <= 0;
    end
    else if (rvalid_or[BLK_CNT])
    begin
      rvalid <= 1;
      rdata <= rdata_blk_or[BLK_CNT];
      rresp  <= 0;
    end



  //-------------------------------------------------
  // Hello World Register
  //-------------------------------------------------
  // When read it, returns the byte-flipped value.

  always_ff @(posedge clk_main_a0)
    if (!rst_main_n_sync)
    begin                    // Reset
      hello_world_q[31:0] <= 32'h0000_0000;
    end
    else if (wready & (wr_addr == `HELLO_WORLD_REG_ADDR))
    begin
      hello_world_q[31:0] <= wdata[31:0];
    end
    else
    begin                                // Hold Value
      hello_world_q[31:0] <= hello_world_q[31:0];
    end

  assign hello_world_q_byte_swapped[31:0] = {hello_world_q[7:0],   hello_world_q[15:8],
         hello_world_q[23:16], hello_world_q[31:24]};





  // always@(top_ins.hash_out)
  // begin
  //   $display("hash_out: %h",top_ins.hash_out);
  // end



  //-------------------------------------------------
  // Virtual LED Register
  //-------------------------------------------------
  // Flop/synchronize interface signals
  always_ff @(posedge clk_main_a0)
    if (!rst_main_n_sync)
    begin                    // Reset
      sh_cl_status_vdip_q[15:0]  <= 16'h0000;
      sh_cl_status_vdip_q2[15:0] <= 16'h0000;
      cl_sh_status_vled[15:0]    <= 16'h0000;
    end
    else
    begin
      sh_cl_status_vdip_q[15:0]  <= sh_cl_status_vdip[15:0];
      sh_cl_status_vdip_q2[15:0] <= sh_cl_status_vdip_q[15:0];
      cl_sh_status_vled[15:0]    <= pre_cl_sh_status_vled[15:0];
    end

  // The register contains 16 read-only bits corresponding to 16 LED's.
  // For this example, the virtual LED register shadows the hello_world
  // register.
  // The same LED values can be read from the CL to Shell interface
  // by using the linux FPGA tool: $ fpga-get-virtual-led -S 0

  always_ff @(posedge clk_main_a0)
    if (!rst_main_n_sync)
    begin                    // Reset
      vled_q[15:0] <= 16'h0000;
    end
    else
    begin
      vled_q[15:0] <= hello_world_q[15:0];
    end

  // The Virtual LED outputs will be masked with the Virtual DIP switches.
  assign pre_cl_sh_status_vled[15:0] = vled_q[15:0] & sh_cl_status_vdip_q2[15:0];

  //-------------------------------------------
  // Tie-Off Unused Global Signals
  //-------------------------------------------
  // The functionality for these signals is TBD so they can can be tied-off.
  assign cl_sh_status0[31:0] = 32'h0;
  assign cl_sh_status1[31:0] = 32'h0;

  //-----------------------------------------------
  // Debug bridge, used if need Virtual JTAG
  //-----------------------------------------------
  `ifndef DISABLE_VJTAG_DEBUG

          // Flop for timing global clock counter
          logic[63:0] sh_cl_glcount0_q;

  always_ff @(posedge clk_main_a0)
    if (!rst_main_n_sync)
      sh_cl_glcount0_q <= 0;
    else
      sh_cl_glcount0_q <= sh_cl_glcount0;


  // Integrated Logic Analyzers (ILA)
  ila_0 CL_ILA_0 (
          .clk    (clk_main_a0),
          .probe0 (sh_ocl_awvalid_q),
          .probe1 (sh_ocl_awaddr_q ),
          .probe2 (ocl_sh_awready_q),
          .probe3 (sh_ocl_arvalid_q),
          .probe4 (sh_ocl_araddr_q ),
          .probe5 (ocl_sh_arready_q)
        );

  ila_0 CL_ILA_1 (
          .clk    (clk_main_a0),
          .probe0 (ocl_sh_bvalid_q),
          .probe1 (sh_cl_glcount0_q),
          .probe2 (sh_ocl_bready_q),
          .probe3 (ocl_sh_rvalid_q),
          .probe4 ({32'b0,ocl_sh_rdata_q[31:0]}),
          .probe5 (sh_ocl_rready_q)
        );


`ifdef DBG_

  ila_0 CL_ILA_2 (
          .clk    (clk_main_a0),
          .probe0 (hash_out_we_dbg),
          .probe1 (hash_out_dbg[63:0]),
          .probe2 (hashin_fifo_in_we),
          .probe3 (state_top_dbg[0]),
          .probe4 (hashin_fifo_in_din),
          .probe5 (state_top_dbg[1])
        );

  ila_0 CL_ILA_3 (
          .clk    (clk_main_a0),
          .probe0 (sha3in_dst_write_dbg),
          .probe1 (sha3in_dout_dbg),
          .probe2 (sha3out_dst_write_dbg),
          .probe3 (start_dbg),
          .probe4 (sha3out_dout_dbg),
          .probe5 (stop_dbg)
        );

  ila_0 CL_ILA_4 (
          .clk    (clk_main_a0),
          .probe0 (status[0]),
          .probe1 ({61'd0,state_nonce_dbg}),
          .probe2 (status[1]),
          .probe3 (stop_ack_dbg),
          .probe4 ({32'd0,nonce_end_dbg}),
          .probe5 (start_dbg)
        );
  ila_0 CL_ILA_5 (
          .clk    (clk_main_a0),
          .probe0 (start_dbg),
          .probe1 (target_dbg[63:0]),
          .probe4 ({61'd0,state_comparator_dbg})
        );
`endif

  // Debug Bridge
  cl_debug_bridge CL_DEBUG_BRIDGE (
                    .clk(clk_main_a0),
                    .S_BSCAN_drck(drck),
                    .S_BSCAN_shift(shift),
                    .S_BSCAN_tdi(tdi),
                    .S_BSCAN_update(update),
                    .S_BSCAN_sel(sel),
                    .S_BSCAN_tdo(tdo),
                    .S_BSCAN_tms(tms),
                    .S_BSCAN_tck(tck),
                    .S_BSCAN_runtest(runtest),
                    .S_BSCAN_reset(reset),
                    .S_BSCAN_capture(capture),
                    .S_BSCAN_bscanid_en(bscanid_en)
                  );

  //-----------------------------------------------
  // VIO Example - Needs Virtual JTAG
  //-----------------------------------------------
  // Counter running at 125MHz

  logic      vo_cnt_enable;
  logic      vo_cnt_load;
  logic      vo_cnt_clear;
  logic      vo_cnt_oneshot;
  logic [7:0]  vo_tick_value;
  logic [15:0] vo_cnt_load_value;
  logic [15:0] vo_cnt_watermark;

  logic      vo_cnt_enable_q = 0;
  logic      vo_cnt_load_q = 0;
  logic      vo_cnt_clear_q = 0;
  logic      vo_cnt_oneshot_q = 0;
  logic [7:0]  vo_tick_value_q = 0;
  logic [15:0] vo_cnt_load_value_q = 0;
  logic [15:0] vo_cnt_watermark_q = 0;

  logic        vi_tick;
  logic        vi_cnt_ge_watermark;
  logic [7:0]  vi_tick_cnt = 0;
  logic [15:0] vi_cnt = 0;

  // Tick counter and main counter
  always @(posedge clk_main_a0)
  begin

    vo_cnt_enable_q     <= vo_cnt_enable    ;
    vo_cnt_load_q       <= vo_cnt_load      ;
    vo_cnt_clear_q      <= vo_cnt_clear     ;
    vo_cnt_oneshot_q    <= vo_cnt_oneshot   ;
    vo_tick_value_q     <= vo_tick_value    ;
    vo_cnt_load_value_q <= vo_cnt_load_value;
    vo_cnt_watermark_q  <= vo_cnt_watermark ;

    vi_tick_cnt = vo_cnt_clear_q ? 0 :
                ~vo_cnt_enable_q ? vi_tick_cnt :
                (vi_tick_cnt >= vo_tick_value_q) ? 0 :
                vi_tick_cnt + 1;

    vi_cnt = vo_cnt_clear_q ? 0 :
           vo_cnt_load_q ? vo_cnt_load_value_q :
           ~vo_cnt_enable_q ? vi_cnt :
           (vi_tick_cnt >= vo_tick_value_q) && (~vo_cnt_oneshot_q || (vi_cnt <= 16'hFFFF)) ? vi_cnt + 1 :
           vi_cnt;

    vi_tick = (vi_tick_cnt >= vo_tick_value_q);

    vi_cnt_ge_watermark = (vi_cnt >= vo_cnt_watermark_q);

  end // always @ (posedge clk_main_a0)


  vio_0 CL_VIO_0 (
          .clk    (clk_main_a0),
          .probe_in0  (vi_tick),
          .probe_in1  (vi_cnt_ge_watermark),
          .probe_in2  (vi_tick_cnt),
          .probe_in3  (vi_cnt),
          .probe_out0 (vo_cnt_enable),
          .probe_out1 (vo_cnt_load),
          .probe_out2 (vo_cnt_clear),
          .probe_out3 (vo_cnt_oneshot),
          .probe_out4 (vo_tick_value),
          .probe_out5 (vo_cnt_load_value),
          .probe_out6 (vo_cnt_watermark)
        );

  ila_vio_counter CL_VIO_ILA (
                    .clk     (clk_main_a0),
                    .probe0  (vi_tick),
                    .probe1  (vi_cnt_ge_watermark),
                    .probe2  (vi_tick_cnt),
                    .probe3  (vi_cnt),
                    .probe4  (vo_cnt_enable_q),
                    .probe5  (vo_cnt_load_q),
                    .probe6  (vo_cnt_clear_q),
                    .probe7  (vo_cnt_oneshot_q),
                    .probe8  (vo_tick_value_q),
                    .probe9  (vo_cnt_load_value_q),
                    .probe10 (vo_cnt_watermark_q)
                  );

`endif //  `ifndef DISABLE_VJTAG_DEBUG

endmodule





