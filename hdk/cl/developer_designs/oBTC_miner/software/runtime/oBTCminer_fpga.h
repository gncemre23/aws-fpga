#include <stdint.h>
#include <stdbool.h>
#include <stdarg.h>
#include <assert.h>
#include <string.h>
#include <unistd.h>

#include <fpga_pci.h>
#include <fpga_mgmt.h>
#include <utils/lcd.h>

#include <utils/sh_dpi_tasks.h>

#define HELLO_WORLD_REG_ADDR UINT64_C(0x500)
#define VLED_REG_ADDR UINT64_C(0x504)

uint32_t byte_swap(uint32_t value);
int peek_poke_example(uint32_t value);

