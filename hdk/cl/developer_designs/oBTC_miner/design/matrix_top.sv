//!Top module of the matrix multiplier
`timescale  1ns / 1ps
module matrix_top #(parameter WCOUNT = 4 )
  (
    //!global clk
    input logic clk,
    //!global reset
    input logic rst,
    //!empty flag from the M_fifo
    input logic m_empty,
    //!empty flag from the hashin_fifo
    input logic hashin_empty,
    //!fifo full input causing to stop giving heavyhash output
    input logic fifo_full,
    //!dataout of hashin fifo
    input logic [WCOUNT*4-1:0] hashin_dout,
    //!dataout of matrix fifo
    input logic [WCOUNT*4-1:0] m_dout,
    //!read enable signal for Matrix fifo
    output logic m_re,
    //!read enable signal for hashin fifo
    output logic hashin_re,
    //!write enable signal for hashout fifo
    output logic hashout_we,
    //! din of hashout fifo
    output logic [63:0] hashout_din
  );


  logic zi;
  logic zk;
  logic zj;
  logic zt;
  logic [6:0] counter_k;
  logic eni;
  logic ldi;
  logic enj;
  logic ldj;
  logic enk;
  logic ldk;
  logic ent;
  logic ldt;
  logic m_ram_we;
  logic [63:0] en_column;
  logic addr_sel;
  logic PE_en;
  logic PE_clr;

  matrix_controller
    matrix_controller_inst (
      .clk (clk ),
      .rst (rst ),
      .zi (zi ),
      .zk (zk ),
      .zj (zj ),
      .zt (zt),
      .counter_k (counter_k[5:0] ),
      .m_empty (m_empty ),
      .hashin_empty (hashin_empty ),
      .eni (eni ),
      .ldi (ldi ),
      .enj (enj ),
      .ldj (ldj ),
      .ent (ent ),
      .ldt (ldt ),
      .enk (enk ),
      .ldk (ldk ),
      .addr_sel(addr_sel),
      .PE_en(PE_en),
      .PE_clr(PE_clr),
      .m_ram_we (m_ram_we ),
      .en_column (en_column ),
      .m_re (m_re ),
      .hashin_re (hashin_re ),
      .hashout_we  ( hashout_we),
      .fifo_full (fifo_full)
    );

  matrix_data_path
    #(
      .WCOUNT (WCOUNT )
    )
    data_path_dut (
      .clk (clk ),
      .rst (rst ),
      .eni (eni ),
      .ldi (ldi ),
      .enj (enj ),
      .ldj (ldj ),
      .enk (enk ),
      .ldk (ldk ),
      .ent (ent ),
      .ldt (ldt ),
      .addr_sel(addr_sel),
      .PE_en(PE_en),
      .PE_clr(PE_clr),
      .hashin_dout (hashin_dout ),
      .m_ram_we (m_ram_we ),
      .en_column (en_column ),
      .m_dout (m_dout ),
      .hashout_din (hashout_din ),
      .zi (zi ),
      .zk (zk ),
      .zj (zj ),
      .zt (zt ),
      .counter_k  ( counter_k)
    );








endmodule
