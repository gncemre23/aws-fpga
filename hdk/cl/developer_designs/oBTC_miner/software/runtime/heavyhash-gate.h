#ifndef HEAVYHASH_GATE_H__
#define HEAVYHASH_GATE_H__

//#include "algo-gate-api.h"
#include <stdint.h>
#include <stdbool.h>
#include <stddef.h>
typedef unsigned __int128 uint128_t;

// inline bool valid_hash( uint32_t *hash, const void *target )
// {
//    const uint128_t *h = (const uint128_t*)hash;
//    const uint128_t *t = (const uint128_t*)target;
//    if ( h[1] > t[1] ) return false;
//    if ( h[1] < t[1] ) return true;
//    if ( h[0] > t[0] ) return false;
//    return true;
// }

static inline uint32_t b_swap_32(uint32_t s)
{
   uint8_t temp[4]={0};
   temp[0] = s >> 24;
   temp[1] = s >> 16;
   temp[2] = s >> 8;
   temp[3] = s;
   return  *((uint32_t*) temp) ;
}

static inline void mm128_bswap32_80( void *d, void *s )
{
  ( (uint32_t*)d )[ 0] = b_swap_32( ( (uint32_t*)s )[ 0] );
  ( (uint32_t*)d )[ 1] = b_swap_32( ( (uint32_t*)s )[ 1] );
  ( (uint32_t*)d )[ 2] = b_swap_32( ( (uint32_t*)s )[ 2] );
  ( (uint32_t*)d )[ 3] = b_swap_32( ( (uint32_t*)s )[ 3] );
  ( (uint32_t*)d )[ 4] = b_swap_32( ( (uint32_t*)s )[ 4] );
  ( (uint32_t*)d )[ 5] = b_swap_32( ( (uint32_t*)s )[ 5] );
  ( (uint32_t*)d )[ 6] = b_swap_32( ( (uint32_t*)s )[ 6] );
  ( (uint32_t*)d )[ 7] = b_swap_32( ( (uint32_t*)s )[ 7] );
  ( (uint32_t*)d )[ 8] = b_swap_32( ( (uint32_t*)s )[ 8] );
  ( (uint32_t*)d )[ 9] = b_swap_32( ( (uint32_t*)s )[ 9] );
  ( (uint32_t*)d )[10] = b_swap_32( ( (uint32_t*)s )[10] );
  ( (uint32_t*)d )[11] = b_swap_32( ( (uint32_t*)s )[11] );
  ( (uint32_t*)d )[12] = b_swap_32( ( (uint32_t*)s )[12] );
  ( (uint32_t*)d )[13] = b_swap_32( ( (uint32_t*)s )[13] );
  ( (uint32_t*)d )[14] = b_swap_32( ( (uint32_t*)s )[14] );
  ( (uint32_t*)d )[15] = b_swap_32( ( (uint32_t*)s )[15] );
  ( (uint32_t*)d )[16] = b_swap_32( ( (uint32_t*)s )[16] );
  ( (uint32_t*)d )[17] = b_swap_32( ( (uint32_t*)s )[17] );
  ( (uint32_t*)d )[18] = b_swap_32( ( (uint32_t*)s )[18] );
  ( (uint32_t*)d )[19] = b_swap_32( ( (uint32_t*)s )[19] );
}

typedef struct work
{
        uint32_t target[8] __attribute__((aligned(64)));
        uint32_t data[48] __attribute__((aligned(64)));
        double targetdiff;
        double sharediff;
        double stratum_diff;
        int height;
        char *txs;
        char *workid;
        char *job_id;
        size_t xnonce2_len;
        unsigned char *xnonce2;
        bool sapling;
        bool stale;
} work_t __attribute__((aligned(64)));




void heavyhash(const uint16_t matrix[64][64], uint8_t* pdata, size_t pdata_len, uint8_t* output, FILE *file_ptr);
int scanhash_heavyhash(work_t *work, uint32_t max_nonce, uint64_t *hashes_done, uint16_t matrix[64][64], FILE *file_ptr);


#endif