#include "oBTCminer_fpga.h"

const char *books[] = {"War and Peace",
                       "Pride and Prejudice",
                       "The Sound and the Fury"};
void report(const char *msg, int terminate)
{
    perror(msg);
    if (terminate)
        exit(-1); /* failure */
}

int main(int argc, char **argv)
{

    char buffer[256];

    //socket server
    int fd = socket(AF_INET,     /* network versus AF_LOCAL */
                    SOCK_STREAM, /* reliable, bidirectional, arbitrary payload size */
                    0);          /* system picks underlying protocol (TCP) */
    if (fd < 0)
        report("socket", 1); /* terminate */

    /* bind the server's local address in memory */
    struct sockaddr_in saddr;
    memset(&saddr, 0, sizeof(saddr));          /* clear the bytes */
    saddr.sin_family = AF_INET;                /* versus AF_LOCAL */
    saddr.sin_addr.s_addr = htonl(INADDR_ANY); /* host-to-network endian */
    saddr.sin_port = htons(PortNumber);        /* for listening */

    if (bind(fd, (struct sockaddr *)&saddr, sizeof(saddr)) < 0)
        report("bind", 1); /* terminate */

    /* listen to the socket */
    if (listen(fd, MaxConnects) < 0) /* listen for clients, up to MaxConnects */
        report("listen", 1);         /* terminate */

    fprintf(stderr, "Listening on port %i for clients...\n", PortNumber);

    struct sockaddr_in caddr; /* client address */
    int len = sizeof(caddr);  /* address length could change */

    int client_fd = accept(fd, (struct sockaddr *)&caddr, &len); /* accept blocks */

    if (client_fd < 0)
    {
        report("accept", 0); /* don't terminate, though there's a problem */
    }

    while (1)
    {
        int count = 0;
        uint32_t work_data[20];
        uint16_t matrix_in[64][64] = {0};
        uint32_t target[8] = {0};
        uint32_t max_nonce = 0;
        while (count == 0)
            count = read(client_fd, work_data, 80);

        printf("===== received work =====\n");
        for (size_t i = 0; i < 20; i++)
        {
            printf("%08x", work_data[i]);
        }
        printf("\n=======================\n");

        count = 0;

        while (count == 0)
            count = read(client_fd, matrix_in, sizeof(matrix_in));

        printf("=== Matrix(matrix form) ====\n");
        for (int i = 0; i < 64; i++)
        {
            for (int j = 0; j < 64; j++)
            {
                printf("%1x", matrix_in[i][j]);
            }
            printf("\n");
        }

        count = 0;
        while (count == 0)
            count = read(client_fd, target, 32);

        count = 0;
        while (count == 0)
            count = read(client_fd, &max_nonce, 4);

        printf("max_nonce = %08x", max_nonce);

        uint32_t first_nonce = work_data[19];
        uint32_t nonce_size = (max_nonce - first_nonce) / BLK_CNT;

        uint32_t status[BLK_CNT] = {0};
        uint32_t hash = 0;
        uint32_t heavy_hash[8];
        uint32_t golden_blk;
        uint32_t golden_nonce;
        uint32_t last_status;

        heavy_hash_fpga_init(work_data, matrix_in, nonce_size, target);
        wait_status(status, &golden_blk);
        for (size_t i = 0; i < BLK_CNT; i++)
        {
            if (status[i] == 1)
            {
                golden_blk = i;
                golden_nonce = read_golden_nonce(golden_blk);
                for (size_t j = 0; j < 8; j++)
                {
                    heavy_hash[j] = read_heavyhash(golden_blk);
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
        last_status = status[golden_blk];
        heavy_hash_fpga_deinit();

        //send the last status (0 or 1)
        write(client_fd, &last_status, 4);
        if (last_status)
        {
            write(client_fd, golden_nonce, 4);
            write(client_fd, heavy_hash, 32);
        }
    }

    return 0;
}

void heavy_hash_fpga_init(uint32_t *work_data, uint16_t matrix[64][64], uint32_t nonce_size, uint32_t *target)
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
    rc = fpga_pci_poke(pci_bar_handle, STOP_REG, 1);
    fail_on(rc, out, "Unable to write to the fpga !");

    //send start to all blocks
    rc = fpga_pci_poke(pci_bar_handle, START_REG, 1);
    fail_on(rc, out, "Unable to write to the fpga !");

    //send nonce size to all blocks
    rc = fpga_pci_poke(pci_bar_handle, NONCE_SIZE_REG, nonce_size);
    fail_on(rc, out, "Unable to write to the fpga !");

    //send target to all blocks
    for (int i = 0; i < 8; i++)
    {
        rc = fpga_pci_poke(pci_bar_handle, TARGET_REG, target[i]);
        fail_on(rc, out, "Unable to write to the fpga !");
    }

    //send block header to all blocks
    for (int i = 19; i >= 0; i--)
    {
        rc = fpga_pci_poke(pci_bar_handle, BLOCK_HEADER_REG, work_data[i]);
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

void heavy_hash_fpga_deinit()
{
    int rc;
    pci_bar_handle_t pci_bar_handle = PCI_BAR_HANDLE_INIT;
    uint32_t value;
#ifndef SV_TEST
    rc = fpga_pci_attach(0, FPGA_APP_PF, APP_PF_BAR0, 0, &pci_bar_handle);
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

void wait_status(uint32_t *status, uint32_t *golden_blk)
{
    int rc;
    pci_bar_handle_t pci_bar_handle = PCI_BAR_HANDLE_INIT;
    *golden_blk = 0;
#ifndef SV_TEST
    rc = fpga_pci_attach(0, FPGA_APP_PF, APP_PF_BAR0, 0, &pci_bar_handle);
    fail_on(rc, out, "Unable to attach to the AFI on slot id %d", 0);
#endif
    //read status registers from all blocks
    uint32_t status_and = 2;
    while (status_and == 2)
    {
        for (size_t i = 0; i < BLK_CNT; i++)
        {
            rc = fpga_pci_peek(pci_bar_handle, STATUS_REG_BASE + i * FPGA_REG_OFFSET, &status[i]);
            fail_on(rc, out, "Unable to write to the fpga !");
            status_and &= status[i];
        }
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
}

uint32_t read_golden_nonce(uint8_t golden_blk)
{
    int rc;
    uint32_t value;
    pci_bar_handle_t pci_bar_handle = PCI_BAR_HANDLE_INIT;
#ifndef SV_TEST
    rc = fpga_pci_attach(0, FPGA_APP_PF, APP_PF_BAR0, 0, &pci_bar_handle);
    fail_on(rc, out, "Unable to attach to the AFI on slot id %d", 0);
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

uint32_t read_heavyhash(uint8_t golden_blk)
{
    int rc;
    uint32_t value;
    pci_bar_handle_t pci_bar_handle = PCI_BAR_HANDLE_INIT;
#ifndef SV_TEST
    rc = fpga_pci_attach(0, FPGA_APP_PF, APP_PF_BAR0, 0, &pci_bar_handle);
    fail_on(rc, out, "Unable to attach to the AFI on slot id %d", 0);
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
