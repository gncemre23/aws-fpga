//!Datapath of the matrix multiplier
`timescale  1ns / 1ps
module matrix_data_path #(parameter WCOUNT = 4 )
  (
    //!global clk
    input logic clk,
    //!global reset
    input logic rst,
    //!counter_i enable
    input logic eni,
    //!counter_i load
    input logic ldi,
    //!counter_j enable
    input logic enj,
    //!counter_j load
    input logic ldj,
    //!counter_k enable
    input logic enk,
    //!counter_k load
    input logic ldk,
    //!counter_t enable
    input logic ent,
    //!counter_t load
    input logic ldt,
    input logic addr_sel,
    input logic PE_en,
    input logic PE_clr,
    //!data from the hash_in fifo
    input logic [WCOUNT*4 -1 : 0] hashin_dout,
    //!we for all matrixrams
    input logic m_ram_we,
    //!en signals to choose the block ram
    input logic [63:0] en_column,
    //!matrix in
    input logic [WCOUNT*4 -1 : 0] m_dout,
    //!hash_out data
    output logic [63 : 0] hashout_din,
    //!control signal detemining if the counter_i is achieved the specified limit
    output logic zi,
    //!control signal detemining if the counter_i is achieved the specified limit
    output logic zj,
    //!control signal detemining if the counter_i is achieved the specified limit
    output logic zt,
    //!control signal detemining if the counter_k is achieved the specified limit
    output logic zk,
    //!counter_k out value
    output logic [6 : 0] counter_k
  );
  const int COUNTER_LIMIT = 64 / WCOUNT - 1;

  logic [13 : 0] PE_out [63:0];
  logic [6 : 0] counter_i, counter_j, counter_t;
  logic [WCOUNT*4 -1 : 0] dout [63:0];
  logic [63 : 0] htemp0, htemp1, htemp2, htemp3;
  logic enj0, enj1, enj2, enj3, enj4;
  logic [3:0] addr_m_ram;

  genvar i;

  assign addr_m_ram  = addr_sel ? counter_j[3:0] : counter_i[3:0];
  generate
    for (i = 0 ; i < 64 ; i++ )
    begin

      if(i < 45)
      begin
        xilinx_single_port_ram_block
          #(
            .RAM_WIDTH(16),                       // Specify RAM data width
            .RAM_DEPTH(16),                     // Specify RAM depth (number of entries)
            .RAM_PERFORMANCE("LOW_LATENCY"), // Select "HIGH_PERFORMANCE" or "LOW_LATENCY"
            .INIT_FILE("")                        // Specify name/location of RAM initialization file if using one (leave blank if not)
          ) your_instance_name (
            .addra(addr_m_ram),    // Address bus, width determined from RAM_DEPTH
            .dina(m_dout),      // RAM input data, width determined from RAM_WIDTH
            .clka(clk),      // Clock
            .wea(m_ram_we),        // Write enable
            .ena(en_column[i]),        // RAM Enable, for additional power savings, disable port when not in use
            .rsta(rst),      // Output reset (does not affect memory contents)
            .regcea(en_column[i]),  // Output register enable
            .douta(dout[i])     // RAM output data, width determined from RAM_WIDTH
          );
      end
      else
      begin
        xilinx_single_port_ram_dist
          #(
            .RAM_WIDTH(16),                       // Specify RAM data width
            .RAM_DEPTH(16),                     // Specify RAM depth (number of entries)
            .RAM_PERFORMANCE("LOW_LATENCY"), // Select "HIGH_PERFORMANCE" or "LOW_LATENCY"
            .INIT_FILE("")                        // Specify name/location of RAM initialization file if using one (leave blank if not)
          ) your_instance_name (
            .addra(addr_m_ram),    // Address bus, width determined from RAM_DEPTH
            .dina(m_dout),      // RAM input data, width determined from RAM_WIDTH
            .clka(clk),      // Clock
            .wea(m_ram_we),        // Write enable
            .ena(en_column[i]),        // RAM Enable, for additional power savings, disable port when not in use
            .rsta(rst),      // Output reset (does not affect memory contents)
            .regcea(en_column[i]),  // Output register enable
            .douta(dout[i])     // RAM output data, width determined from RAM_WIDTH
          );
      end


      PE #(.WCOUNT(WCOUNT))
         PE_inst
         (
           .rst (rst),
           .clk (clk),
           .en (PE_en),
           .clr(PE_clr),
           .M (dout[i]),
           .X(hashin_dout),
           .PE_out(PE_out[i])
         );
    end
  endgenerate

  counter counter_i_inst
          (
            .rst(rst),
            .clk(clk),
            .en(eni),
            .ld_data(7'd0),
            .ld(ldi),
            .counter_out(counter_i)
          );
  counter counter_j_inst
          (
            .rst(rst),
            .clk(clk),
            .en(enj),
            .ld_data(7'd0),
            .ld(ldj),
            .counter_out(counter_j)
          );

  counter counter_k_inst
          (
            .rst(rst),
            .clk(clk),
            .en(enk),
            .ld_data(7'd0),
            .ld(ldk),
            .counter_out(counter_k)
          );

  counter counter_t_inst
          (
            .rst(rst),
            .clk(clk),
            .en(ent),
            .ld_data(7'd0),
            .ld(ldt),
            .counter_out(counter_t)
          );

  generate
    for (i = 0 ; i < 64 ; i++ )
    begin
      if(i < 16)
        assign htemp0[64-i*4-1 : 64 - i*4 - 4 ] = PE_out[i][13:10];
      else if( i < 32)
        assign htemp1[128-i*4-1 : 128 - i*4 - 4 ] = PE_out[i][13:10];
      else if( i < 48)
        assign htemp2[192-i*4-1 : 192 - i*4 - 4 ] = PE_out[i][13:10];
      else
        assign htemp3[256-i*4-1 : 256 - i*4 - 4 ] = PE_out[i][13:10];
    end
  endgenerate


  always_ff @( posedge clk )
  begin : eni_ff
    if(rst)
    begin
      enj0 <= 1'b0;
      enj1 <= 1'b0;
      enj2 <= 1'b0;
      enj3 <= 1'b0;
      enj4 <= 1'b0;
    end
    else
    begin
      enj0 <= enj;
      enj1 <= enj0;
      enj2 <= enj1;
      enj3 <= enj2;
      enj4 <= enj3;
    end

  end



  always_comb
  begin : hashout_din_blk
    case (counter_t)
      0:
        hashout_din = htemp0;
      1:
        hashout_din = htemp1;
      2:
        hashout_din = htemp2;
      3:
        hashout_din = htemp3;
      default:
        hashout_din = 64'd0;

    endcase
  end


  assign zi = (counter_i == (COUNTER_LIMIT)) ? 1'b1 : 1'b0;
  assign zj = (counter_j == (COUNTER_LIMIT + 1)) ? 1'b1 : 1'b0;
  assign zk = (counter_k == (7'd63)) ? 1'b1 : 1'b0;
  assign zt = (counter_t == (7'd3)) ? 1'b1 : 1'b0;
endmodule
