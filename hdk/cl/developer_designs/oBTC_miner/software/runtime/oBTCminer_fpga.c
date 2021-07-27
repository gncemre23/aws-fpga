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
#include <stdio.h>
#include <stdint.h>
#include <stdbool.h>
#include <stdarg.h>
#include <assert.h>
#include <string.h>
#include <unistd.h>
#include "heavyhash-gate.h"

//#define SV_TEST
#ifdef SV_TEST
#include "fpga_pci_sv.h"
#else
#include <fpga_pci.h>
#include <fpga_mgmt.h>
#include <utils/lcd.h>
#endif

#include <utils/sh_dpi_tasks.h>

/* Constants determined by the CL */
/* a set of register offsets; this CL has only one */
/* these register addresses should match the addresses in */
/* /aws-fpga/hdk/cl/examples/common/cl_common_defines.vh */
/* SV_TEST macro should be set if SW/HW co-simulation should be enabled */

/*`define HEAVYHASH_REG_ADDR      32'h0000_0508
`define STATUS_REG_ADDR         32'h0000_050C
`define NONCE_REG_ADDR          32'h0000_0510
`define BLOCKHEADER_REG_ADDR    32'h0000_0514
`define MATRIX_REG_ADDR         32'h0000_0518
`define TARGET_REG_ADDR         32'h0000_051C
`define NONCESIZE_REG_ADDR      32'h0000_0520
`define START_REG_ADDR          32'h0000_0524
`define STOP_REG_ADDR           32'h0000_0528
`define HEAVYHASH_SEL_REG_ADDR  32'h0000_052C*/

//This registers will exist for all blocks
//For each block, the address is obtained by base_address+ blk_cnt*36
//Example for block 2 start_reg_address will be
//0x524 + 36*2 = 0x56C
#define HELLO_WORLD_REG_ADDR UINT64_C(0x500)
#define VLED_REG_ADDR UINT64_C(0x504)
#define BLOCK_HEADER_REG UINT64_C(0x514)
#define MATRIX_REG UINT64_C(0x518)
#define TARGET_REG UINT64_C(0x51C)
#define START_REG UINT64_C(0x524)
#define STOP_REG UINT64_C(0x528)
#define STATUS_REG_BASE UINT64_C(0x50C)
#define HASH_REG_BASE UINT64_C(0x508)
#define NONCE_SIZE_REG UINT64_C(0x520)
#define NONCE_REG_BASE UINT64_C(0x510)

#define FPGA_REG_OFFSET 36
#define BLK_CNT 12
/* use the stdout logger for printing debug information  */
#ifndef SV_TEST
const struct logger *logger = &logger_stdout;
/*
 * pci_vendor_id and pci_device_id values below are Amazon's and avaliable to use for a given FPGA slot. 
 * Users may replace these with their own if allocated to them by PCI SIG
 */
static uint16_t pci_vendor_id = 0x1D0F; /* Amazon PCI Vendor ID */
static uint16_t pci_device_id = 0xF000; /* PCI Device ID preassigned by Amazon for F1 applications */

/*
 * check if the corresponding AFI for hello_world is loaded
 */
int check_afi_ready(int slot_id);

void usage(char *program_name)
{
    printf("usage: %s [--slot <slot-id>][<poke-value>]\n", program_name);
}

void fail_fpga(int rc, pci_bar_handle_t pci_bar_handle)
{
    if (rc < 0)
    {
        printf("PCIE write/attach error\n");
        fpga_pci_detach(pci_bar_handle);
    }
}

uint32_t byte_swap(uint32_t value);

#endif

/*
 * An example to attach to an arbitrary slot, pf, and bar with register access.
 */
int peek_poke_example(uint32_t value, int slot_id, int pf_id, int bar_id);
void heavy_hash_fpga_init(work_t *work, uint16_t matrix[64][64], int slot_id, int pf_id, int bar_id);
uint32_t read_golden_nonce(int slot_id, int pf_id, int bar_id, uint8_t golden_blk);
uint32_t read_heavyhash(int slot_id, int pf_id, int bar_id, uint8_t golden_blk);
void wait_status(int slot_id, int pf_id, int bar_id, uint32_t *status);
void heavy_hash_fpga_deinit(int slot_id, int pf_id, int bar_id);
//pci_bar_handle_t pci_bar_handle = PCI_BAR_HANDLE_INIT;

uint32_t byte_swap(uint32_t value)
{
    uint32_t swapped_value = 0;
    int b;
    for (b = 0; b < 4; b++)
    {
        swapped_value |= ((value >> (b * 8)) & 0xff) << (8 * (3 - b));
    }
    return swapped_value;
}

uint32_t heavy_hash_fpga[8];

#ifdef SV_TEST
//For cadence and questa simulators the main has to return some value
#ifdef INT_MAIN
int test_main(uint32_t *exit_code)
#else
void test_main(uint32_t *exit_code)
#endif
#else
int main(int argc, char **argv)
#endif
{
//The statements within SCOPE ifdef below are needed for HW/SW co-simulation with VCS
#ifdef SCOPE
    svScope scope;
    scope = svGetScopeFromName("tb");
    svSetScope(scope);
#endif

    uint32_t value = 0xefbeadde;
    int slot_id = 0;
    int rc;

#ifndef SV_TEST
    // Process command line args
    {
        int i;
        int value_set = 0;
        for (i = 1; i < argc; i++)
        {
            if (!strcmp(argv[i], "--slot"))
            {
                i++;
                if (i >= argc)
                {
                    printf("error: missing slot-id\n");
                    usage(argv[0]);
                    return 1;
                }
                sscanf(argv[i], "%d", &slot_id);
            }
            else if (!value_set)
            {
                sscanf(argv[i], "%x", &value);
                value_set = 1;
            }
            else
            {
                printf("error: Invalid arg: %s", argv[i]);
                usage(argv[0]);
                return 1;
            }
        }
    }
#endif

    /* initialize the fpga_mgmt library */
    rc = fpga_mgmt_init();
    fail_on(rc, out, "Unable to initialize the fpga_mgmt library");

#ifndef SV_TEST
    rc = check_afi_ready(slot_id);
    fail_on(rc, out, "AFI not ready");
#endif

    /* Accessing the CL registers via AppPF BAR0, which maps to sh_cl_ocl_ AXI-Lite bus between AWS FPGA Shell and the CL*/

    printf("===== Starting with peek_poke_example =====\n");
    rc = peek_poke_example(value, slot_id, FPGA_APP_PF, APP_PF_BAR0);
    fail_on(rc, out, "peek-poke example failed");

    printf("Developers are encouraged to modify the Virtual DIP Switch by calling the linux shell command to demonstrate how AWS FPGA Virtual DIP switches can be used to change a CustomLogic functionality:\n");
    printf("$ fpga-set-virtual-dip-switch -S (slot-id) -D (16 digit setting)\n\n");
    printf("In this example, setting a virtual DIP switch to zero clears the corresponding LED, even if the peek-poke example would set it to 1.\nFor instance:\n");

    printf(
        "# sudo fpga-set-virtual-dip-switch -S 0 -D 1111111111111111\n"
        "# sudo fpga-get-virtual-led  -S 0\n"
        "FPGA slot id 0 have the following Virtual LED:\n"
        "1010-1101-1101-1110\n"
        "# sudo fpga-set-virtual-dip-switch -S 0 -D 0000000000000000\n"
        "# sudo fpga-get-virtual-led  -S 0\n"
        "FPGA slot id 0 have the following Virtual LED:\n"
        "0000-0000-0000-0000\n");

    work_t g_work0, g_work1;
    uint16_t matrix[64][64];


    FILE *fp;
    fp = fopen("heavy_hash_out.txt","w");
    const char *line = "000000200c221d3dc065da14a1a6b6871eb489fbe94591053792425f3f170f0000000000a1fccbee670ba770ccced5fa1bb8014fd671d4dcfce1b7dd79bd633d244df90f870aba60d3ed131b00000000";
    uint8_t work_byte[100];
    uint32_t work_word[25];
    uint64_t hashes_done = 0;
    uint32_t golden_nonce = 0;

    for (int i = 0; i < 80; i++)
        sscanf(&line[i * 2], "%2x", &work_byte[i]);
    for (int i = 0; i < 80; i++)
        printf("%02x", work_byte[i]);
    printf("\n");

    mm128_bswap32_80(work_word, (uint32_t *)work_byte);
    printf("-------work--------\n");
    for (int i = 0; i < 20; i++)
    {
        g_work0.data[i] = work_word[i];
        g_work1.data[i] = work_word[i];
        printf("%08x\n", work_word[i]);
    }
    printf("\n");
    //fclose(fp);

    for (size_t i = 0; i < 64; i++)
    {
        for (size_t j = 0; j < 64; j++)
        {
            matrix[i][j] = 0;
        }
    }

    scanhash_heavyhash(&g_work0, 0xc8, &hashes_done, matrix,fp);
    fclose(fp);
    printf("=================Matrix============\n");
    for (size_t i = 0; i < 64; i++)
    {
        for (size_t j = 0; j < 64; j++)
        {
            printf("%x", matrix[i][j]);
        }
        printf("\n");
    }
    printf("===================================\n");
    printf("hashes_done = %d\n", hashes_done);
    heavy_hash_fpga_init(&g_work1, matrix, slot_id, FPGA_APP_PF, APP_PF_BAR0);

    uint32_t status[BLK_CNT] = {0};
    uint32_t hash = 0;
    uint32_t heavy_hash[8];
    uint32_t golden_blk = 255;

    sleep(1);

    //wait until status will be other than 2
    wait_status(slot_id, FPGA_APP_PF, APP_PF_BAR0, status);

    for (size_t i = 0; i < BLK_CNT; i++)
    {
        if (status[i] == 1)
        {
            golden_blk = i;
            golden_nonce = read_golden_nonce(slot_id, FPGA_APP_PF, APP_PF_BAR0, golden_blk) - 1;
            for (size_t j = 0; j < 8; j++)
            {
                heavy_hash[j] = read_heavyhash(slot_id, FPGA_APP_PF, APP_PF_BAR0, golden_blk);
            }

            printf("Golden nonce is = %08x\n", golden_nonce);
            printf("Golden hash is =");
            for (size_t j = 0; j < 8; j++)
            {
                printf("%08x", heavy_hash[j]);
            }
            printf("\n");
            break;
        }
    }
    if (golden_blk == 255)
        printf("all scanned, nothing found\n");
    heavy_hash_fpga_deinit(slot_id, FPGA_APP_PF, APP_PF_BAR0);

    //run for second time
    for (size_t i = 0; i < BLK_CNT; i++)
    {
        status[i] = 0;
    }
    hash = 0;

    heavy_hash_fpga_init(&g_work1, matrix, slot_id, FPGA_APP_PF, APP_PF_BAR0);
    //wait until status will be other than 2

   
    wait_status(slot_id, FPGA_APP_PF, APP_PF_BAR0, status);

    for (size_t i = 0; i < BLK_CNT; i++)
    {
        if (status[i] == 1)
        {
            golden_blk = i;
            golden_nonce = read_golden_nonce(slot_id, FPGA_APP_PF, APP_PF_BAR0, golden_blk) - 1;
            for (size_t j = 0; j < 8; j++)
            {
                heavy_hash[j] = read_heavyhash(slot_id, FPGA_APP_PF, APP_PF_BAR0, golden_blk);
            }

            printf("Golden nonce is = %08x\n", golden_nonce);
            printf("Golden hash is =");
            for (size_t j = 0; j < 8; j++)
            {
                printf("%08x", heavy_hash[j]);
            }
            printf("\n");
            break;
        }
    }
    if (golden_blk == 255)
        printf("all scanned, nothing found\n");
    heavy_hash_fpga_deinit(slot_id, FPGA_APP_PF, APP_PF_BAR0);

#ifndef SV_TEST
    return 0;

out:
    return 1;
#else

out:
#ifdef INT_MAIN
    *exit_code = 0;
    return 0;
#else
    *exit_code = 0;
#endif
#endif
}

/* As HW simulation test is not run on a AFI, the below function is not valid */
#ifndef SV_TEST

int check_afi_ready(int slot_id)
{
    struct fpga_mgmt_image_info info = {0};
    int rc;

    /* get local image description, contains status, vendor id, and device id. */
    rc = fpga_mgmt_describe_local_image(slot_id, &info, 0);
    fail_on(rc, out, "Unable to get AFI information from slot %d. Are you running as root?", slot_id);

    /* check to see if the slot is ready */
    if (info.status != FPGA_STATUS_LOADED)
    {
        rc = 1;
        fail_on(rc, out, "AFI in Slot %d is not in READY state !", slot_id);
    }

    printf("AFI PCI  Vendor ID: 0x%x, Device ID 0x%x\n",
           info.spec.map[FPGA_APP_PF].vendor_id,
           info.spec.map[FPGA_APP_PF].device_id);

    /* confirm that the AFI that we expect is in fact loaded */
    if (info.spec.map[FPGA_APP_PF].vendor_id != pci_vendor_id ||
        info.spec.map[FPGA_APP_PF].device_id != pci_device_id)
    {
        printf("AFI does not show expected PCI vendor id and device ID. If the AFI "
               "was just loaded, it might need a rescan. Rescanning now.\n");

        rc = fpga_pci_rescan_slot_app_pfs(slot_id);
        fail_on(rc, out, "Unable to update PF for slot %d", slot_id);
        /* get local image description, contains status, vendor id, and device id. */
        rc = fpga_mgmt_describe_local_image(slot_id, &info, 0);
        fail_on(rc, out, "Unable to get AFI information from slot %d", slot_id);

        printf("AFI PCI  Vendor ID: 0x%x, Device ID 0x%x\n",
               info.spec.map[FPGA_APP_PF].vendor_id,
               info.spec.map[FPGA_APP_PF].device_id);

        /* confirm that the AFI that we expect is in fact loaded after rescan */
        if (info.spec.map[FPGA_APP_PF].vendor_id != pci_vendor_id ||
            info.spec.map[FPGA_APP_PF].device_id != pci_device_id)
        {
            rc = 1;
            fail_on(rc, out, "The PCI vendor id and device of the loaded AFI are not "
                             "the expected values.");
        }
    }

    return rc;
out:
    return 1;
}

#endif

void heavy_hash_fpga_init(work_t *work, uint16_t matrix[64][64], int slot_id, int pf_id, int bar_id)
{
    int rc;
    pci_bar_handle_t pci_bar_handle = PCI_BAR_HANDLE_INIT;
    uint32_t value;
#ifndef SV_TEST
    rc = fpga_pci_attach(slot_id, pf_id, bar_id, 0, &pci_bar_handle);
    fail_on(rc, out, "Unable to write to the fpga !");
#endif
    printf("init begin\n");

    //send stop to all blocks
    rc = fpga_pci_poke(pci_bar_handle, STOP_REG, 1);
    fail_on(rc, out, "Unable to write to the fpga !");

    //send start to all blocks
    rc = fpga_pci_poke(pci_bar_handle, START_REG, 1);
    fail_on(rc, out, "Unable to write to the fpga !");

    //send nonce size to all blocks
    rc = fpga_pci_poke(pci_bar_handle, NONCE_SIZE_REG,  1000/BLK_CNT);
    fail_on(rc, out, "Unable to write to the fpga !");

    rc = fpga_pci_poke(pci_bar_handle, TARGET_REG, 1);
    fail_on(rc, out, "Unable to write to the fpga !");

    //send target to all blocks
    for (int i = 0; i < 7; i++)
    {
        rc = fpga_pci_poke(pci_bar_handle, TARGET_REG, 0);
        fail_on(rc, out, "Unable to write to the fpga !");
    }

    //send block header to all blocks
    for (int i = 19; i >= 0; i--)
    {
        rc = fpga_pci_poke(pci_bar_handle, BLOCK_HEADER_REG, work->data[i]);
        fail_on(rc, out, "Unable to write to the fpga !");
    }

    //send matrix to all blocks
    for (int i = 0; i < 64; i++)
    {
        for (int j = 63; j > 0; j = j - 8)
        {
            value = ((uint32_t)matrix[i][j - 7] << 28) | ((uint32_t)matrix[i][j - 6] << 24) | ((uint32_t)matrix[i][j - 5] << 20) | ((uint32_t)matrix[i][j - 4] << 16) | ((uint32_t)matrix[i][j - 3] << 12) | ((uint32_t)matrix[i][j - 2] << 8) | ((uint32_t)matrix[i][j - 1] << 4) | (uint32_t)matrix[i][j];
            rc = fpga_pci_poke(pci_bar_handle, MATRIX_REG, value);
            fail_on(rc, out, "Unable to write to the fpga !");
        }
    }

    printf("init done \n ...");

out:
    /* clean up */
    if (pci_bar_handle >= 0)
    {
        rc = fpga_pci_detach(pci_bar_handle);
        if (rc)
        {
            printf("Failure while detaching from the fpga.\n");
        }
    }
}

void heavy_hash_fpga_deinit(int slot_id, int pf_id, int bar_id)
{
    int rc;
    pci_bar_handle_t pci_bar_handle = PCI_BAR_HANDLE_INIT;
    uint32_t value;
#ifndef SV_TEST
    rc = fpga_pci_attach(slot_id, pf_id, bar_id, 0, &pci_bar_handle);
    fail_on(rc, out, "Unable to write to the fpga !");
#endif
    //send stop to all blocks
    rc = fpga_pci_poke(pci_bar_handle, STOP_REG, 1);
    fail_on(rc, out, "Unable to write to the fpga !");
out:
    /* clean up */
    if (pci_bar_handle >= 0)
    {
        rc = fpga_pci_detach(pci_bar_handle);
        if (rc)
        {
            printf("Failure while detaching from the fpga.\n");
        }
    }
}

//wait for status to be 1 or 0
void wait_status(int slot_id, int pf_id, int bar_id, uint32_t *status)
{
    int rc;
    pci_bar_handle_t pci_bar_handle = PCI_BAR_HANDLE_INIT;
    uint8_t mine = 0;
#ifndef SV_TEST
    rc = fpga_pci_attach(slot_id, pf_id, bar_id, 0, &pci_bar_handle);
    fail_on(rc, out, "Unable to attach to the AFI on slot id %d", slot_id);
#endif
    //read status registers from all blocks
    uint32_t status_or = 0;
    uint32_t status_tmp = 0;
    int k = 0;
    do
    {
        if ((k % 100000) == 0)
            printf("status = ");
        for (size_t i = 0; i < BLK_CNT; i++)
        {
            rc = fpga_pci_peek(pci_bar_handle, STATUS_REG_BASE + i * FPGA_REG_OFFSET, &status[i]);
            fail_on(rc, out, "Unable to write to the fpga !");
            status_tmp |= status[i];
            status_or = status_tmp;
            if ((k % 100000) == 0)
                printf("%d", status[i]);

            if (status[i] == 1)
            {
                mine = 1;
                break;
            }
        }
        status_tmp = 0;
        if (mine)
        {
            break;
        }
        if ((k % 100000) == 0)
            printf("\n");
        k++;
    } while (status_or != 0);

out:
    /* clean up */
    if (pci_bar_handle >= 0)
    {
        rc = fpga_pci_detach(pci_bar_handle);
        if (rc)
        {
            printf("Failure while detaching from the fpga.\n");
        }
    }
}

uint32_t read_heavyhash(int slot_id, int pf_id, int bar_id, uint8_t golden_blk)
{
    int rc;
    uint32_t value;
    pci_bar_handle_t pci_bar_handle = PCI_BAR_HANDLE_INIT;
#ifndef SV_TEST
    rc = fpga_pci_attach(slot_id, pf_id, bar_id, 0, &pci_bar_handle);
    fail_on(rc, out, "Unable to attach to the AFI on slot id %d", slot_id);
#endif
    rc = fpga_pci_peek(pci_bar_handle, HASH_REG_BASE + FPGA_REG_OFFSET * golden_blk, &value);
out:
    /* clean up */
    if (pci_bar_handle >= 0)
    {
        rc = fpga_pci_detach(pci_bar_handle);
        if (rc)
        {
            printf("Failure while detaching from the fpga.\n");
        }
    }

    /* if there is an error code, exit with status 1 */
    return value;
}

uint32_t read_golden_nonce(int slot_id, int pf_id, int bar_id, uint8_t golden_blk)
{
    int rc;
    uint32_t value;
    pci_bar_handle_t pci_bar_handle = PCI_BAR_HANDLE_INIT;
#ifndef SV_TEST
    rc = fpga_pci_attach(slot_id, pf_id, bar_id, 0, &pci_bar_handle);
    fail_on(rc, out, "Unable to attach to the AFI on slot id %d", slot_id);
#endif
    rc = fpga_pci_peek(pci_bar_handle, NONCE_REG_BASE + FPGA_REG_OFFSET * golden_blk, &value);
out:
    /* clean up */
    if (pci_bar_handle >= 0)
    {
        rc = fpga_pci_detach(pci_bar_handle);
        if (rc)
        {
            printf("Failure while detaching from the fpga.\n");
        }
    }

    /* if there is an error code, exit with status 1 */
    return value;
}

/*
 * An example to attach to an arbitrary slot, pf, and bar with register access.
 */
int peek_poke_example(uint32_t value, int slot_id, int pf_id, int bar_id)
{
    int rc;
    /* pci_bar_handle_t is a handler for an address space exposed by one PCI BAR on one of the PCI PFs of the FPGA */

    pci_bar_handle_t pci_bar_handle = PCI_BAR_HANDLE_INIT;

    /* attach to the fpga, with a pci_bar_handle out param
     * To attach to multiple slots or BARs, call this function multiple times,
     * saving the pci_bar_handle to specify which address space to interact with in
     * other API calls.
     * This function accepts the slot_id, physical function, and bar number
     */
#ifndef SV_TEST
    rc = fpga_pci_attach(slot_id, pf_id, bar_id, 0, &pci_bar_handle);
    fail_on(rc, out, "Unable to attach to the AFI on slot id %d", slot_id);
#endif

    /* write a value into the mapped address space */
    uint32_t expected = byte_swap(value);
    printf("Writing 0x%08x to HELLO_WORLD register (0x%016lx)\n", value, HELLO_WORLD_REG_ADDR);
    rc = fpga_pci_poke(pci_bar_handle, HELLO_WORLD_REG_ADDR, value);

    fail_on(rc, out, "Unable to write to the fpga !");

    /* read it back and print it out; you should expect the byte order to be
     * reversed (That's what this CL does) */
    rc = fpga_pci_peek(pci_bar_handle, HELLO_WORLD_REG_ADDR, &value);
    fail_on(rc, out, "Unable to read read from the fpga !");

    printf("=====  Entering peek_poke_example =====\n");
    printf("register: 0x%x\n", value);
    if (value == expected)
    {
        printf("TEST PASSED");
        printf("Resulting value matched expected value 0x%x. It worked!\n", expected);
    }
    else
    {
        printf("TEST FAILED");
        printf("Resulting value did not match expected value 0x%x. Something didn't work.\n", expected);
    }

    rc = fpga_pci_poke(pci_bar_handle, HELLO_WORLD_REG_ADDR, 11);

    rc = fpga_pci_peek(pci_bar_handle, HELLO_WORLD_REG_ADDR, &value);
    fail_on(rc, out, "Unable to read read from the fpga !");
    printf("=====  Entering peek_poke_example =====\n");
    printf("register: 0x%x\n", value);
out:
    /* clean up */
    if (pci_bar_handle >= 0)
    {
        rc = fpga_pci_detach(pci_bar_handle);
        if (rc)
        {
            // printf("Failure while detaching from the fpga.\n");
        }
    }

    /* if there is an error code, exit with status 1 */
    return (rc != 0 ? 1 : 0);
}

#ifdef SV_TEST
/*This function is used transfer string buffer from SV to C.
  This function currently returns 0 but can be used to update a buffer on the 'C' side.*/
int send_rdbuf_to_c(char *rd_buf)
{
    return 0;
}

#endif
