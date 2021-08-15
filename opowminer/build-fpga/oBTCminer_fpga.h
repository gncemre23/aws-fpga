#ifndef OBTC_MINER_FPGA_H__
#define OBTC_MINER_FPGA_H__ 
#include <stdint.h>
#include <stdbool.h>
#include <stdarg.h>
#include <assert.h>
#include <string.h>
#include <unistd.h>
#include <stdio.h>
#include <stdlib.h>
#include <sys/types.h>
#include <sys/socket.h>
#include <arpa/inet.h>
#include <netinet/in.h>
#include <netinet/tcp.h>
#include <netdb.h>


#include <fpga_pci.h>
#include <fpga_mgmt.h>
#include <utils/lcd.h>

#include <utils/sh_dpi_tasks.h>


#define HELLO_WORLD_REG_ADDR UINT64_C(0x500)
#define VLED_REG_ADDR UINT64_C(0x504)
#define HASH_REG_BASE UINT64_C(0x508)
#define STATUS_REG_BASE UINT64_C(0x50C)
#define NONCE_REG_BASE UINT64_C(0x510)
#define BLOCK_HEADER_REG_BASE UINT64_C(0x514)
#define MATRIX_REG_BASE UINT64_C(0x518)
#define TARGET_REG_BASE UINT64_C(0x51C)
#define NONCE_SIZE_REG_BASE UINT64_C(0x520)
#define START_REG_BASE UINT64_C(0x524)
#define STOP_REG_BASE UINT64_C(0x528)
#define HASHES_DONE_BASE UINT64_C(0x530)
#define ACK_REG_BASE UINT64_C(0x534)


#define FPGA_REG_OFFSET 44
#define CORE_CNT 40
#define FPGA_SCAN_TIME 7





uint32_t byte_swap(uint32_t value);
int peek_poke_example(pci_bar_handle_t *pci_bar_handle, uint32_t value);
void heavy_hash_fpga_init(uint32_t *work_data, uint16_t matrix[64][64], uint32_t nonce_size, uint32_t *target, uint8_t blk, pci_bar_handle_t *pci_bar_handle);
void heavy_hash_fpga_deinit(uint8_t blk, pci_bar_handle_t *pci_bar_handle);
//uint32_t wait_status();
uint32_t read_golden_nonce(pci_bar_handle_t *pci_bar_handle, uint8_t golden_blk);
uint32_t read_heavyhash(pci_bar_handle_t *pci_bar_handle, uint8_t golden_blk);
uint32_t read_hashes_done(pci_bar_handle_t *pci_bar_handle, uint8_t golden_blk);
void send_ack(pci_bar_handle_t *pci_bar_handle, uint8_t blk);
#endif