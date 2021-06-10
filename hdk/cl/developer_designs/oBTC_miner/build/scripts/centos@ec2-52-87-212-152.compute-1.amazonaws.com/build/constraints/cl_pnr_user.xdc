# This contains the CL specific constraints for Top level PNR

# False path between vled on CL clock and Shell asynchronous clock
set_false_path -from [get_cells WRAPPER_INST/CL/vled_q_reg*] 

# False paths between main clock and tck
set_clock_groups -name TIG_SRAI_1 -asynchronous -group [get_clocks -of_objects [get_pins static_sh/SH_DEBUG_BRIDGE/inst/bsip/inst/USE_SOFTBSCAN.U_TAP_TCKBUFG/O]] -group [get_clocks -of_objects [get_pins WRAPPER_INST/SH/kernel_clks_i/clkwiz_sys_clk/inst/CLK_CORE_DRP_I/clk_inst/mmcme3_adv_inst/CLKOUT0]]
set_clock_groups -name TIG_SRAI_2 -asynchronous -group [get_clocks -of_objects [get_pins static_sh/SH_DEBUG_BRIDGE/inst/bsip/inst/USE_SOFTBSCAN.U_TAP_TCKBUFG/O]] -group [get_clocks drck]
set_clock_groups -name TIG_SRAI_3 -asynchronous -group [get_clocks -of_objects [get_pins static_sh/SH_DEBUG_BRIDGE/inst/bsip/inst/USE_SOFTBSCAN.U_TAP_TCKBUFG/O]] -group [get_clocks -of_objects [get_pins static_sh/pcie_inst/inst/gt_top_i/diablo_gt.diablo_gt_phy_wrapper/phy_clk_i/bufg_gt_userclk/O]]


create_pblock pblock_SLR0
add_cells_to_pblock [get_pblocks pblock_SLR0] [get_cells -quiet [list {top_ins.genblk1[0].heavy_hash_blk_dut} {top_ins.genblk1[1].heavy_hash_blk_dut{top_ins.genblk1[2].heavy_hash_blk_dut} {top_ins.genblk1[3].heavy_hash_blk_dut}]]

resize_pblock [get_pblocks pblock_SLR0] -add {CLOCKREGION_X0Y0:CLOCKREGION_X5Y4}

create_pblock pblock_SLR1
add_cells_to_pblock [get_pblocks pblock_SLR1] [get_cells -quiet [list {top_ins.block_header_fifo} {top_ins.target_fifo} {top_ins.heavyhash_fifo} {top_ins.matrix_fifo}   {top_ins.genblk1[4].heavy_hash_blk_dut} {top_ins.genblk1[5].heavy_hash_blk_dut} {top_ins.genblk1[6].heavy_hash_blk_dut} {top_ins.genblk1[7].heavy_hash_blk_dut} ]]
resize_pblock [get_pblocks pblock_SLR1] -add {CLOCKREGION_X0Y5:CLOCKREGION_X5Y9}

create_pblock pblock_SLR2
add_cells_to_pblock [get_pblocks pblock_SLR2] [get_cells -quiet [list {genblk1[8].heavy_hash_blk_dut} {genblk1[9].heavy_hash_blk_dut} {genblk1[10].heavy_hash_blk_dut} {genblk1[11].heavy_hash_blk_dut} ]]
resize_pblock [get_pblocks pblock_SLR2] -add {CLOCKREGION_X0Y10:CLOCKREGION_X5Y14}
