//!Datapath of the matrix multiplier
`timescale  1ns / 1ps
module matrix_controller
  (
    //!global clock signal
    input logic clk,
    //!global reset signal
    input logic rst,
    //!control signal detemining if the counter_i is achieved the specified limit
    input logic zi,
    //!control signal detemining if the counter_i is achieved the specified limit
    input logic zj,
    //!control signal detemining if the counter_i is achieved the specified limit
    input logic zt,
    //!control signal detemining if the counter_t is achieved the specified limit
    input logic zk,
    //!fifo full input causing to stop giving heavyhash output
    input logic fifo_full,
    //!counter k value
    input logic [5:0] counter_k,
    //!empty flag from the M_fifo
    input logic m_empty,
    //!empty flag from the hashin_fifo
    input logic hashin_empty,
    //!enable signal for counter_i
    output logic eni,
    //!load signal for counter_i
    output logic ldi,
    //!enable signal for counter_i
    output logic enj,
    //!load signal for counter_i
    output logic ldj,
    //!enable signal for counter_k
    output logic enk,
    //!enable signal for counter_t
    output logic ent,
    //!load signal for counter_k
    output logic ldk,
    //!load signal for counter_t
    output logic ldt,
    //!mux select bit for addr of matrix_ram
    output logic addr_sel,
    //!PE_enable
    output logic PE_en,
    //!PE_clear
    output logic PE_clr,
    //!write enable signal for matrix ram
    output logic m_ram_we,
    //!en signals to choose the block ram
    output logic [63:0] en_column,
    //!read enable signal for Matrix fifo
    output logic m_re,
    //!read enable signal for hashin fifo
    output logic hashin_re,
    //!write enable signal for hashout fifo
    output logic hashout_we
  );

  typedef enum { INIT, M_LOAD, MULT, WAIT_FOR_CLK_1, WAIT_FOR_CLK_2, DONE} state_type;
  state_type state_next, state_reg;
  logic h_re_next, h_re_reg;
  logic h_we_next, h_we_reg, h_we_reg_reg ;
  logic ent_next, ent_reg;
  logic addr_sel_next, addr_sel_reg;
  logic PE_en_next, PE_en_reg, PE_en_reg_reg, PE_en_reg_reg_reg, PE_en_reg_reg_reg_reg;


  assign hashin_re = h_re_reg;
  assign hashout_we = h_we_reg;
  assign ent = ent_reg;
  assign addr_sel = addr_sel_reg;
  assign PE_en = PE_en_next | PE_en_reg_reg_reg_reg;


  always_ff @( posedge clk )
  begin : seq_blk
    if(rst)
    begin
      state_reg <= INIT;
      h_re_reg <= 1'b0;
      h_we_reg <= 1'b0;
      h_we_reg_reg <= 1'b0;
      addr_sel_reg <= 1'b0;
      ent_reg <= 1'b0;
      PE_en_reg <= 1'b0;
      PE_en_reg_reg <= 1'b0;
      PE_en_reg_reg_reg <= 1'b0;
      PE_en_reg_reg_reg_reg <= 1'b0;

    end
    else
    begin
      h_re_reg <= h_re_next;
      h_we_reg <= h_we_next;
      h_we_reg_reg <= h_we_reg;
      ent_reg  <= ent_next;
      addr_sel_reg <= addr_sel_next;
      state_reg <= state_next;
      PE_en_reg <= PE_en_next;
      PE_en_reg_reg <= PE_en_reg;
      PE_en_reg_reg_reg <= PE_en_reg_reg;
      PE_en_reg_reg_reg_reg <= PE_en_reg_reg_reg;
    end
  end

  always_comb
  begin : comb_blk
    //! default assignments
    ldi = 1'b0;
    ldk = 1'b0;
    ldj = 1'b0;
    ldt = 1'b0;
    eni = 1'b0;
    enk = 1'b0;
    enj = 1'b0;
    m_re = 1'b0;
    PE_clr = 1'b0;
    en_column = 64'd0;
    state_next = state_reg;
    ent_next = ent_reg;
    PE_en_next = PE_en_reg;
    addr_sel_next = addr_sel_reg;
    //hashout_we = 1'b0;
    h_re_next = h_re_reg;
    h_we_next = h_we_reg;
    m_ram_we = 1'b0;
    case (state_reg)
      INIT :
      begin
        h_re_next = 1'b0;
        PE_clr = 1'b1;
        if(!m_empty)
        begin
          ldk = 1'b1;
          ldi = 1'b1;
          addr_sel_next = 1'b0;
          state_next = M_LOAD;
        end
        else if (!hashin_empty)
        begin
          ldj = 1'b1;
          enj = 1'b1;
          addr_sel_next = 1'b1;
          state_next = MULT;
          PE_en_next = 1'b1;
        end
      end
      M_LOAD :
      begin
        if(!m_empty)
        begin
          m_re = 1'b1;
          m_ram_we = 1'b1;
          en_column[counter_k] = 1'b1;
          if (zi)
          begin
            if(zk)
            begin
              state_next = INIT;
            end
            else
            begin
              ldi = 1'b1;
              enk = 1'b1;
            end
          end
          else
          begin
            eni = 1'b1;
          end
        end
      end
      MULT :
      begin
        if(!hashin_empty)
        begin
          en_column = 64'hFFFFFFFFFFFFFFFF;
          if(zj)
          begin
            state_next = WAIT_FOR_CLK_1;
            ldt = 1'b1;
            PE_en_next = 1'b0;
            h_re_next = 1'b0;
          end
          else
          begin
            enj = 1'b1;
            h_re_next = 1'b1;
          end
        end
      end
      WAIT_FOR_CLK_1:
        state_next = WAIT_FOR_CLK_2;
      WAIT_FOR_CLK_2:
        state_next = DONE;
      DONE:
      begin
        if(zt)
        begin
          state_next = INIT;
          h_we_next = 1'b0;
          ent_next = 1'b0;
        end
        else
        begin
          if(!fifo_full)
          begin
            ent_next = 1'b1;
            h_we_next = 1'b1;
          end
        end
      end

    endcase
  end


endmodule
