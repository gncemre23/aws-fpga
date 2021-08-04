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

// Definitions for socket
#define PortNumber      9876
#define MaxConnects        8
#define BuffSize         256
#define ConversationLen    3
#define Host            "localhost"

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
#define HASHES_DONE_BASE UINT64_C(0x53C)

#define FPGA_REG_OFFSET 40
#define BLK_CNT 40


uint32_t byte_swap(uint32_t value);
int peek_poke_example(uint32_t value);
void heavy_hash_fpga_init(uint32_t * work_data, uint16_t matrix[64][64], uint32_t nonce_size, uint32_t * target);
void heavy_hash_fpga_deinit();
uint32_t wait_status(uint32_t * status);
uint32_t read_golden_nonce(uint8_t golden_blk);
uint32_t read_heavyhash(uint8_t golden_blk);
uint32_t read_hashes_done(uint8_t blk);


