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

`ifndef CL_HELLO_WORLD_DEFINES
`define CL_HELLO_WORLD_DEFINES
`define CL_COMMON_DEFAULTS

//Put module name of the CL design here.  This is used to instantiate in top.sv
`define CL_NAME cl_hello_world

//Highly recommeneded.  For lib FIFO block, uses less async reset (take advantage of
// FPGA flop init capability).  This will help with routing resources.
`define FPGA_LESS_RST


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

// Value to return for PCIS access to unimplemented register address
`define UNIMPLEMENTED_REG_VALUE 32'hdeaddead

// CL Register Addresses
`define HELLO_WORLD_REG_ADDR    32'h0000_0500
`define VLED_REG_ADDR           32'h0000_0504

//for ila debugs
//`define DBG_

// Uncomment to disable Virtual JTAG
//`define DISABLE_VJTAG_DEBUG

`endif
