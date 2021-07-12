#include "oBTCminer_fpga.h"


const char* books[] = {"War and Peace",
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

    

    int client_fd = accept(fd, (struct sockaddr*) &caddr, &len);  /* accept blocks */

    if (client_fd < 0) {
      report("accept", 0); /* don't terminate, though there's a problem */
    }

    int count = 0;
    while(count == 0)
        count = read(client_fd,buffer,4);

   
    uint32_t value = *((uint32_t *) buffer);
    peek_poke_example(value);

    close(client_fd);

    return 0;
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
