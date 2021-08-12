#include "oBTCminer_fpga.h"

void heavy_hash_fpga_init(uint32_t *work_data, uint16_t matrix[64][64], uint32_t nonce_size, uint32_t *target, uint8_t blk)
{
    int rc;
    pci_bar_handle_t pci_bar_handle = PCI_BAR_HANDLE_INIT;
    uint32_t value;
#ifndef SV_TEST
    rc = fpga_pci_attach(0, FPGA_APP_PF, APP_PF_BAR0, 0, &pci_bar_handle);
    fail_on(rc, out, "Unable to write to the fpga !");
#endif
    printf("init begin\n");

    //send stop to all blocks
    rc = fpga_pci_poke(pci_bar_handle, STOP_REG_BASE + blk * FPGA_REG_OFFSET, 1);
    fail_on(rc, out, "Unable to write to the fpga !");

    //send start to all blocks
    rc = fpga_pci_poke(pci_bar_handle, START_REG_BASE + blk * FPGA_REG_OFFSET, 1);
    fail_on(rc, out, "Unable to write to the fpga !");

    //send nonce size to all blocks
    rc = fpga_pci_poke(pci_bar_handle, NONCE_SIZE_REG_BASE + blk * FPGA_REG_OFFSET, nonce_size);
    fail_on(rc, out, "Unable to write to the fpga !");

    printf("nonce_size : %08x\n", nonce_size);
    //send target to all blocks
    //printf("target : ");
    for (int i = 0; i < 8; i++)
    {
        rc = fpga_pci_poke(pci_bar_handle, TARGET_REG_BASE + blk * FPGA_REG_OFFSET, target[i]);
    //    printf("%08x\n", target[i]);
        fail_on(rc, out, "Unable to write to the fpga !");
    }
    //printf("\n");

    //send block header to all blocks
    for (int i = 19; i >= 0; i--)
    {
        rc = fpga_pci_poke(pci_bar_handle, BLOCK_HEADER_REG_BASE + blk * FPGA_REG_OFFSET, work_data[i]);
        fail_on(rc, out, "Unable to write to the fpga !");
    }

    //send matrix to all blocks
    for (int i = 0; i < 64; i++)
    {
        for (int j = 63; j > 0; j = j - 8)
        {
            value = ((uint32_t)matrix[i][j - 7] << 28) | ((uint32_t)matrix[i][j - 6] << 24) | ((uint32_t)matrix[i][j - 5] << 20) | ((uint32_t)matrix[i][j - 4] << 16) | ((uint32_t)matrix[i][j - 3] << 12) | ((uint32_t)matrix[i][j - 2] << 8) | ((uint32_t)matrix[i][j - 1] << 4) | (uint32_t)matrix[i][j];
            rc = fpga_pci_poke(pci_bar_handle, MATRIX_REG_BASE + blk * FPGA_REG_OFFSET, value);
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

void heavy_hash_fpga_deinit(uint8_t blk)
{
    int rc;
    pci_bar_handle_t pci_bar_handle = PCI_BAR_HANDLE_INIT;
    uint32_t value;
#ifndef SV_TEST
    rc = fpga_pci_attach(0, FPGA_APP_PF, APP_PF_BAR0, 0, &pci_bar_handle);
    fail_on(rc, out, "Unable to write to the fpga !");
#endif
    //send stop to all blocks
    rc = fpga_pci_poke(pci_bar_handle, STOP_REG_BASE + blk * FPGA_REG_OFFSET, 1);
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

uint32_t read_golden_nonce(pci_bar_handle_t *pci_bar_handle, uint8_t golden_blk)
{
    int rc;
    uint32_t value;
    // #ifndef SV_TEST
    //     rc = fpga_pci_attach(0, FPGA_APP_PF, APP_PF_BAR0, 0, &pci_bar_handle);
    //     fail_on(rc, out, "Unable to attach to the AFI on slot id %d", 0);
    // #endif
    rc = fpga_pci_peek(*pci_bar_handle, NONCE_REG_BASE + FPGA_REG_OFFSET * golden_blk, &value);
out:
    /* if there is an error code, exit with status 1 */
    return value;
}

uint32_t read_hashes_done(pci_bar_handle_t *pci_bar_handle, uint8_t blk)
{
    int rc;
    uint32_t value;
    // #ifndef SV_TEST
    //     rc = fpga_pci_attach(0, FPGA_APP_PF, APP_PF_BAR0, 0, &pci_bar_handle);
    //     fail_on(rc, out, "Unable to attach to the AFI on slot id %d", 0);
    // #endif
    rc = fpga_pci_peek(*pci_bar_handle, HASHES_DONE_BASE + FPGA_REG_OFFSET * blk, &value);
out:

    /* if there is an error code, exit with status 1 */
    return value;
}

uint32_t read_heavyhash(pci_bar_handle_t *pci_bar_handle, uint8_t golden_blk)
{
    int rc;
    uint32_t value;

    // #ifndef SV_TEST
    //     rc = fpga_pci_attach(0, FPGA_APP_PF, APP_PF_BAR0, 0, &pci_bar_handle);
    //     fail_on(rc, out, "Unable to attach to the AFI on slot id %d", 0);
    // #endif
    rc = fpga_pci_peek(*pci_bar_handle, HASH_REG_BASE + FPGA_REG_OFFSET * golden_blk, &value);
out:

    /* if there is an error code, exit with status 1 */
    return value;
}

void send_ack(pci_bar_handle_t *pci_bar_handle, uint8_t blk)
{
    int rc;

    rc = fpga_pci_poke(*pci_bar_handle, ACK_REG_BASE + blk * FPGA_REG_OFFSET, 1);
    fail_on(rc, out, "Unable to write to the fpga !");
out:
    return;
}

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

/*
 * An example to attach to an arbitrary slot, pf, and bar with register access.
 */
int peek_poke_example(uint32_t value)
{
    int rc;

    rc = fpga_mgmt_init();
    fail_on(rc, out, "Unable to initialize the fpga_mgmt library");
    /* pci_bar_handle_t is a handler for an address space exposed by one PCI BAR on one of the PCI PFs of the FPGA */

    pci_bar_handle_t pci_bar_handle = PCI_BAR_HANDLE_INIT;

    /* attach to the fpga, with a pci_bar_handle out param
     * To attach to multiple slots or BARs, call this function multiple times,
     * saving the pci_bar_handle to specify which address space to interact with in
     * other API calls.
     * This function accepts the slot_id, physical function, and bar number
     */
    rc = fpga_pci_attach(0, FPGA_APP_PF, APP_PF_BAR0, 0, &pci_bar_handle);
    fail_on(rc, out, "Unable to attach to the AFI on slot id %d", 0);

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
    return (rc != 0 ? 1 : 0);
}
