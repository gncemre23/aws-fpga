#ifndef HEAVYHASH_GATE_H__
#define HEAVYHASH_GATE_H__ 1

#include "algo-gate-api.h"
#include <stdint.h>
#include "build-fpga/oBTCminer_fpga.h"

#define MAX_BUF_LENGTH 5



void heavyhash(const uint16_t matrix[64][64], uint8_t* pdata, size_t pdata_len, uint8_t* output);
int scanhash_heavyhash( struct work *work, uint32_t max_nonce,
                    uint64_t *hashes_done, struct thr_info *mythr, uint32_t *  golden_i, uint32_t * circ_buffer,  uint32_t *found_nonce_count );


#endif