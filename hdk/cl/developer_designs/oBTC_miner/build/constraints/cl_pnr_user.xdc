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


# create_pblock pblock_SLR0
# add_cells_to_pblock [get_pblocks pblock_SLR0] [get_cells -quiet -hierarchical -filter {NAME =~ WRAPPER_INST/CL/top_ins/genblk1[0].heavy_hash_blk_dut}]
# add_cells_to_pblock [get_pblocks pblock_SLR0] [get_cells -quiet -hierarchical -filter {NAME =~ WRAPPER_INST/CL/top_ins/genblk1[1].heavy_hash_blk_dut}]
# add_cells_to_pblock [get_pblocks pblock_SLR0] [get_cells -quiet -hierarchical -filter {NAME =~ WRAPPER_INST/CL/top_ins/genblk1[2].heavy_hash_blk_dut}]
# add_cells_to_pblock [get_pblocks pblock_SLR0] [get_cells -quiet -hierarchical -filter {NAME =~ WRAPPER_INST/CL/top_ins/genblk1[3].heavy_hash_blk_dut}]
# add_cells_to_pblock [get_pblocks pblock_SLR0] [get_cells -quiet -hierarchical -filter {NAME =~ WRAPPER_INST/CL/top_ins/genblk1[4].heavy_hash_blk_dut}]
# add_cells_to_pblock [get_pblocks pblock_SLR0] [get_cells -quiet -hierarchical -filter {NAME =~ WRAPPER_INST/CL/top_ins/genblk1[5].heavy_hash_blk_dut}]
# add_cells_to_pblock [get_pblocks pblock_SLR0] [get_cells -quiet -hierarchical -filter {NAME =~ WRAPPER_INST/CL/top_ins/genblk1[6].heavy_hash_blk_dut}]
# add_cells_to_pblock [get_pblocks pblock_SLR0] [get_cells -quiet -hierarchical -filter {NAME =~ WRAPPER_INST/CL/top_ins/genblk1[7].heavy_hash_blk_dut}]
# add_cells_to_pblock [get_pblocks pblock_SLR0] [get_cells -quiet -hierarchical -filter {NAME =~ WRAPPER_INST/CL/top_ins/genblk1[8].heavy_hash_blk_dut}]
# add_cells_to_pblock [get_pblocks pblock_SLR0] [get_cells -quiet -hierarchical -filter {NAME =~ WRAPPER_INST/CL/top_ins/genblk1[9].heavy_hash_blk_dut}]
# #add_cells_to_pblock [get_pblocks pblock_SLR0] [get_cells -quiet -hierarchical -filter {NAME =~ WRAPPER_INST/CL/top_ins/genblk1[10].heavy_hash_blk_dut}]
# #add_cells_to_pblock [get_pblocks pblock_SLR0] [get_cells -quiet -hierarchical -filter {NAME =~ WRAPPER_INST/CL/top_ins/genblk1[11].heavy_hash_blk_dut}]
# resize_pblock [get_pblocks pblock_SLR0] -add {SLR0}
# set_property PARENT pblock_CL [get_pblocks pblock_SLR0]

create_pblock pblock_SLR1
add_cells_to_pblock [get_pblocks pblock_SLR1] [get_cells -quiet -hierarchical -filter {NAME =~ WRAPPER_INST/CL/genblk1[0].heavy_hash_blk_dut}]
add_cells_to_pblock [get_pblocks pblock_SLR1] [get_cells -quiet -hierarchical -filter {NAME =~ WRAPPER_INST/CL/genblk1[1].heavy_hash_blk_dut}]
add_cells_to_pblock [get_pblocks pblock_SLR1] [get_cells -quiet -hierarchical -filter {NAME =~ WRAPPER_INST/CL/genblk1[2].heavy_hash_blk_dut}]
add_cells_to_pblock [get_pblocks pblock_SLR1] [get_cells -quiet -hierarchical -filter {NAME =~ WRAPPER_INST/CL/genblk1[3].heavy_hash_blk_dut}]
add_cells_to_pblock [get_pblocks pblock_SLR1] [get_cells -quiet -hierarchical -filter {NAME =~ WRAPPER_INST/CL/genblk1[4].heavy_hash_blk_dut}]
add_cells_to_pblock [get_pblocks pblock_SLR1] [get_cells -quiet -hierarchical -filter {NAME =~ WRAPPER_INST/CL/genblk1[5].heavy_hash_blk_dut}]
add_cells_to_pblock [get_pblocks pblock_SLR1] [get_cells -quiet -hierarchical -filter {NAME =~ WRAPPER_INST/CL/genblk1[6].heavy_hash_blk_dut}]
add_cells_to_pblock [get_pblocks pblock_SLR1] [get_cells -quiet -hierarchical -filter {NAME =~ WRAPPER_INST/CL/genblk1[7].heavy_hash_blk_dut}]
#add_cells_to_pblock [get_pblocks pblock_SLR1] [get_cells -quiet -hierarchical -filter {NAME =~ WRAPPER_INST/CL/genblk1[8].heavy_hash_blk_dut}]
#add_cells_to_pblock [get_pblocks pblock_SLR1] [get_cells -quiet -hierarchical -filter {NAME =~ WRAPPER_INST/CL/genblk1[9].heavy_hash_blk_dut}]
#add_cells_to_pblock [get_pblocks pblock_SLR1] [get_cells -quiet -hierarchical -filter {NAME =~ WRAPPER_INST/CL/top_ins/genblk1[22].heavy_hash_blk_dut}]
#add_cells_to_pblock [get_pblocks pblock_SLR1] [get_cells -quiet -hierarchical -filter {NAME =~ WRAPPER_INST/CL/top_ins/genblk1[23].heavy_hash_blk_dut}]
resize_pblock [get_pblocks pblock_SLR1] -add {SLR1}
set_property PARENT pblock_CL [get_pblocks pblock_SLR1]

# create_pblock pblock_SLR2
# add_cells_to_pblock [get_pblocks pblock_SLR2] [get_cells -quiet -hierarchical -filter {NAME =~ WRAPPER_INST/CL/top_ins/genblk1[20].heavy_hash_blk_dut}]
# add_cells_to_pblock [get_pblocks pblock_SLR2] [get_cells -quiet -hierarchical -filter {NAME =~ WRAPPER_INST/CL/top_ins/genblk1[21].heavy_hash_blk_dut}]
# add_cells_to_pblock [get_pblocks pblock_SLR2] [get_cells -quiet -hierarchical -filter {NAME =~ WRAPPER_INST/CL/top_ins/genblk1[22].heavy_hash_blk_dut}]
# add_cells_to_pblock [get_pblocks pblock_SLR2] [get_cells -quiet -hierarchical -filter {NAME =~ WRAPPER_INST/CL/top_ins/genblk1[23].heavy_hash_blk_dut}]
# add_cells_to_pblock [get_pblocks pblock_SLR2] [get_cells -quiet -hierarchical -filter {NAME =~ WRAPPER_INST/CL/top_ins/genblk1[24].heavy_hash_blk_dut}]
# add_cells_to_pblock [get_pblocks pblock_SLR2] [get_cells -quiet -hierarchical -filter {NAME =~ WRAPPER_INST/CL/top_ins/genblk1[25].heavy_hash_blk_dut}]
# add_cells_to_pblock [get_pblocks pblock_SLR2] [get_cells -quiet -hierarchical -filter {NAME =~ WRAPPER_INST/CL/top_ins/genblk1[26].heavy_hash_blk_dut}]
# add_cells_to_pblock [get_pblocks pblock_SLR2] [get_cells -quiet -hierarchical -filter {NAME =~ WRAPPER_INST/CL/top_ins/genblk1[27].heavy_hash_blk_dut}]
# add_cells_to_pblock [get_pblocks pblock_SLR2] [get_cells -quiet -hierarchical -filter {NAME =~ WRAPPER_INST/CL/top_ins/genblk1[28].heavy_hash_blk_dut}]
# add_cells_to_pblock [get_pblocks pblock_SLR2] [get_cells -quiet -hierarchical -filter {NAME =~ WRAPPER_INST/CL/top_ins/genblk1[29].heavy_hash_blk_dut}]
# add_cells_to_pblock [get_pblocks pblock_SLR2] [get_cells -quiet -hierarchical -filter {NAME =~ WRAPPER_INST/CL/top_ins/genblk1[30].heavy_hash_blk_dut}]
# add_cells_to_pblock [get_pblocks pblock_SLR2] [get_cells -quiet -hierarchical -filter {NAME =~ WRAPPER_INST/CL/top_ins/genblk1[31].heavy_hash_blk_dut}]
# add_cells_to_pblock [get_pblocks pblock_SLR2] [get_cells -quiet -hierarchical -filter {NAME =~ WRAPPER_INST/CL/top_ins/genblk1[32].heavy_hash_blk_dut}]
# add_cells_to_pblock [get_pblocks pblock_SLR2] [get_cells -quiet -hierarchical -filter {NAME =~ WRAPPER_INST/CL/top_ins/genblk1[33].heavy_hash_blk_dut}]
# add_cells_to_pblock [get_pblocks pblock_SLR2] [get_cells -quiet -hierarchical -filter {NAME =~ WRAPPER_INST/CL/top_ins/genblk1[34].heavy_hash_blk_dut}]
# add_cells_to_pblock [get_pblocks pblock_SLR2] [get_cells -quiet -hierarchical -filter {NAME =~ WRAPPER_INST/CL/top_ins/genblk1[35].heavy_hash_blk_dut}]
# resize_pblock [get_pblocks pblock_SLR2] -add {SLICE_X0Y600:SLICE_X168Y899}
# resize_pblock [get_pblocks pblock_SLR2] -add {DSP48E2_X0Y240:DSP48E2_X18Y359}
# resize_pblock [get_pblocks pblock_SLR2] -add {LAGUNA_X0Y480:LAGUNA_X23Y719}
# resize_pblock [get_pblocks pblock_SLR2] -add {RAMB18_X0Y240:RAMB18_X11Y359}
# resize_pblock [get_pblocks pblock_SLR2] -add {RAMB36_X0Y120:RAMB36_X11Y179}
# resize_pblock [get_pblocks pblock_SLR2] -add {URAM288_X0Y160:URAM288_X3Y239}
# set_property PARENT pblock_CL [get_pblocks pblock_SLR2]

# create_pblock pblock_SLR3
# add_cells_to_pblock [get_pblocks pblock_SLR3] [get_cells -quiet -hierarchical -filter {NAME =~ WRAPPER_INST/CL/top_ins/genblk1[12].heavy_hash_blk_dut}]
# add_cells_to_pblock [get_pblocks pblock_SLR3] [get_cells -quiet -hierarchical -filter {NAME =~ WRAPPER_INST/CL/top_ins/genblk1[13].heavy_hash_blk_dut}]
# add_cells_to_pblock [get_pblocks pblock_SLR3] [get_cells -quiet -hierarchical -filter {NAME =~ WRAPPER_INST/CL/top_ins/genblk1[14].heavy_hash_blk_dut}]
# add_cells_to_pblock [get_pblocks pblock_SLR3] [get_cells -quiet -hierarchical -filter {NAME =~ WRAPPER_INST/CL/top_ins/genblk1[15].heavy_hash_blk_dut}]
# resize_pblock [get_pblocks pblock_SLR3] -add {CLOCKREGION_X3Y10:CLOCKREGION_X5Y14}
# set_property PARENT pblock_CL [get_pblocks pblock_SLR3]

set_property CLOCK_LOW_FANOUT TRUE [get nets WRAPPER_INST/SH/kernel_clks_i/clkwiz_sys_clk/inst/CLK_CORE_DRP_I/clk_inst/clk_out2]