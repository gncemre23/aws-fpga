# This contains the CL specific constraints for Top level PNR

# False path between vled on CL clock and Shell asynchronous clock
set_false_path -from [get_cells WRAPPER_INST/CL/vled_q_reg*] 
set_false_path -from [get_pins WRAPPER_INST/CL/CL_HELLO_WORLD/TOP_INS/nonce_size_sync_reg0_reg*/C] -to [get_pins WRAPPER_INST/CL/CL_HELLO_WORLD/TOP_INS/nonce_size_sync_reg1_reg*/D]
set_false_path -from [get_pins WRAPPER_INST/CL/CL_HELLO_WORLD/TOP_INS/start_reg0_reg/C]            -to [get_pins WRAPPER_INST/CL/CL_HELLO_WORLD/TOP_INS/start_reg1_reg/D]
set_false_path -from [get_pins WRAPPER_INST/CL/CL_HELLO_WORLD/TOP_INS/stop_reg0_reg/C]             -to [get_pins WRAPPER_INST/CL/CL_HELLO_WORLD/TOP_INS/stop_reg1_reg/D]
set_false_path -from [get_pins WRAPPER_INST/CL/CL_HELLO_WORLD/TOP_INS/nonce_reg0_reg*/C]           -to [get_pins WRAPPER_INST/CL/CL_HELLO_WORLD/TOP_INS/nonce_sync_reg1_reg*/D]
set_false_path -from [get_pins WRAPPER_INST/CL/CL_HELLO_WORLD/TOP_INS/hash_sel_sync_reg0*/C]       -to [get_pins WRAPPER_INST/CL/CL_HELLO_WORLD/TOP_INS/hash_sel_sync_reg1*/D]
set_false_path -from [get_pins WRAPPER_INST/CL/CL_HELLO_WORLD/TOP_INS/hash_re_sync_reg0/C]         -to [get_pins WRAPPER_INST/CL/CL_HELLO_WORLD/TOP_INS/hhash_re_sync_reg1/D]
set_false_path -from [get_pins WRAPPER_INST/CL/CL_HELLO_WORLD/TOP_INS/status_sync_reg0*/C]         -to [get_pins WRAPPER_INST/CL/CL_HELLO_WORLD/TOP_INS/status_sync_reg1*/D]
set_false_path -from [get_pins WRAPPER_INST/CL/CL_HELLO_WORLD/TOP_INS/hash_out_sync_reg0*/C]       -to [get_pins WRAPPER_INST/CL/CL_HELLO_WORLD/TOP_INS/hash_out_sync_reg1*/D]

# False paths between main clock and tck
set_clock_groups -name TIG_SRAI_1 -asynchronous -group [get_clocks -of_objects [get_pins static_sh/SH_DEBUG_BRIDGE/inst/bsip/inst/USE_SOFTBSCAN.U_TAP_TCKBUFG/O]] -group [get_clocks -of_objects [get_pins WRAPPER_INST/SH/kernel_clks_i/clkwiz_sys_clk/inst/CLK_CORE_DRP_I/clk_inst/mmcme3_adv_inst/CLKOUT0]]
set_clock_groups -name TIG_SRAI_2 -asynchronous -group [get_clocks -of_objects [get_pins static_sh/SH_DEBUG_BRIDGE/inst/bsip/inst/USE_SOFTBSCAN.U_TAP_TCKBUFG/O]] -group [get_clocks drck]
set_clock_groups -name TIG_SRAI_3 -asynchronous -group [get_clocks -of_objects [get_pins static_sh/SH_DEBUG_BRIDGE/inst/bsip/inst/USE_SOFTBSCAN.U_TAP_TCKBUFG/O]] -group [get_clocks -of_objects [get_pins static_sh/pcie_inst/inst/gt_top_i/diablo_gt.diablo_gt_phy_wrapper/phy_clk_i/bufg_gt_userclk/O]]


create_pblock pblock_SLR0
add_cells_to_pblock [get_pblocks pblock_SLR0] [get_cells -quiet -hierarchical -filter {NAME =~ WRAPPER_INST/CL/top_ins/genblk1[0].heavy_hash_blk_dut}]
add_cells_to_pblock [get_pblocks pblock_SLR0] [get_cells -quiet -hierarchical -filter {NAME =~ WRAPPER_INST/CL/top_ins/genblk1[1].heavy_hash_blk_dut}]
add_cells_to_pblock [get_pblocks pblock_SLR0] [get_cells -quiet -hierarchical -filter {NAME =~ WRAPPER_INST/CL/top_ins/genblk1[2].heavy_hash_blk_dut}]
add_cells_to_pblock [get_pblocks pblock_SLR0] [get_cells -quiet -hierarchical -filter {NAME =~ WRAPPER_INST/CL/top_ins/genblk1[3].heavy_hash_blk_dut}]
add_cells_to_pblock [get_pblocks pblock_SLR0] [get_cells -quiet -hierarchical -filter {NAME =~ WRAPPER_INST/CL/top_ins/genblk1[4].heavy_hash_blk_dut}]
add_cells_to_pblock [get_pblocks pblock_SLR0] [get_cells -quiet -hierarchical -filter {NAME =~ WRAPPER_INST/CL/top_ins/genblk1[5].heavy_hash_blk_dut}]
add_cells_to_pblock [get_pblocks pblock_SLR0] [get_cells -quiet -hierarchical -filter {NAME =~ WRAPPER_INST/CL/top_ins/genblk1[6].heavy_hash_blk_dut}]
add_cells_to_pblock [get_pblocks pblock_SLR0] [get_cells -quiet -hierarchical -filter {NAME =~ WRAPPER_INST/CL/top_ins/genblk1[7].heavy_hash_blk_dut}]
resize_pblock [get_pblocks pblock_SLR0] -add {CLOCKREGION_X0Y0:CLOCKREGION_X3Y4}
set_property PARENT pblock_CL [get_pblocks pblock_SLR0]

# create_pblock pblock_SLR1
# add_cells_to_pblock [get_pblocks pblock_SLR1] [get_cells -quiet -hierarchical -filter {NAME =~ WRAPPER_INST/CL/top_ins/genblk1[8].heavy_hash_blk_dut}]
# add_cells_to_pblock [get_pblocks pblock_SLR1] [get_cells -quiet -hierarchical -filter {NAME =~ WRAPPER_INST/CL/top_ins/genblk1[9].heavy_hash_blk_dut}]
# add_cells_to_pblock [get_pblocks pblock_SLR1] [get_cells -quiet -hierarchical -filter {NAME =~ WRAPPER_INST/CL/top_ins/genblk1[10].heavy_hash_blk_dut}]
# add_cells_to_pblock [get_pblocks pblock_SLR1] [get_cells -quiet -hierarchical -filter {NAME =~ WRAPPER_INST/CL/top_ins/genblk1[11].heavy_hash_blk_dut}]
# add_cells_to_pblock [get_pblocks pblock_SLR1] [get_cells -quiet -hierarchical -filter {NAME =~ WRAPPER_INST/CL/top_ins/genblk1[12].heavy_hash_blk_dut}]
# add_cells_to_pblock [get_pblocks pblock_SLR1] [get_cells -quiet -hierarchical -filter {NAME =~ WRAPPER_INST/CL/top_ins/genblk1[13].heavy_hash_blk_dut}]
# add_cells_to_pblock [get_pblocks pblock_SLR1] [get_cells -quiet -hierarchical -filter {NAME =~ WRAPPER_INST/CL/top_ins/genblk1[14].heavy_hash_blk_dut}]
# add_cells_to_pblock [get_pblocks pblock_SLR1] [get_cells -quiet -hierarchical -filter {NAME =~ WRAPPER_INST/CL/top_ins/genblk1[15].heavy_hash_blk_dut}]
# resize_pblock [get_pblocks pblock_SLR1] -add {CLOCKREGION_X0Y5:CLOCKREGION_X5Y9}
# set_property PARENT pblock_CL [get_pblocks pblock_SLR1]

# create_pblock pblock_SLR2
# add_cells_to_pblock [get_pblocks pblock_SLR2] [get_cells -quiet -hierarchical -filter {NAME =~ WRAPPER_INST/CL/top_ins/genblk1[16].heavy_hash_blk_dut}]
# add_cells_to_pblock [get_pblocks pblock_SLR2] [get_cells -quiet -hierarchical -filter {NAME =~ WRAPPER_INST/CL/top_ins/genblk1[17].heavy_hash_blk_dut}]
# add_cells_to_pblock [get_pblocks pblock_SLR2] [get_cells -quiet -hierarchical -filter {NAME =~ WRAPPER_INST/CL/top_ins/genblk1[18].heavy_hash_blk_dut}]
# add_cells_to_pblock [get_pblocks pblock_SLR2] [get_cells -quiet -hierarchical -filter {NAME =~ WRAPPER_INST/CL/top_ins/genblk1[19].heavy_hash_blk_dut}]
# add_cells_to_pblock [get_pblocks pblock_SLR2] [get_cells -quiet -hierarchical -filter {NAME =~ WRAPPER_INST/CL/top_ins/genblk1[20].heavy_hash_blk_dut}]
# add_cells_to_pblock [get_pblocks pblock_SLR2] [get_cells -quiet -hierarchical -filter {NAME =~ WRAPPER_INST/CL/top_ins/genblk1[21].heavy_hash_blk_dut}]
# add_cells_to_pblock [get_pblocks pblock_SLR2] [get_cells -quiet -hierarchical -filter {NAME =~ WRAPPER_INST/CL/top_ins/genblk1[22].heavy_hash_blk_dut}]
# add_cells_to_pblock [get_pblocks pblock_SLR2] [get_cells -quiet -hierarchical -filter {NAME =~ WRAPPER_INST/CL/top_ins/genblk1[23].heavy_hash_blk_dut}]
# resize_pblock [get_pblocks pblock_SLR2] -add {CLOCKREGION_X0Y10:CLOCKREGION_X5Y14}
# set_property PARENT pblock_CL [get_pblocks pblock_SLR2]

#create_pblock pblock_SLR2
#add_cells_to_pblock [get_pblocks pblock_SLR2] [get_cells -quiet [list {GENBLK*[8].heavy_hash_blk_dut} {GENBLK*[9].heavy_hash_blk_dut} {GENBLK*[10].heavy_hash_blk_dut} {GENBLK*[11].heavy_hash_blk_dut} ]]
#resize_pblock [get_pblocks pblock_SLR2] -add {CLOCKREGION_X0Y10:CLOCKREGION_X5Y14}
