#include "heavyhash-gate.h"
#include "keccak_tiny.h"

#include <inttypes.h>
#include <string.h>
#include <stdlib.h>
#include <math.h>

#include <stdint.h>
#include <stdbool.h>
#include <stdarg.h>
#include <assert.h>
#include <unistd.h>
#include <stdio.h>
#include <sys/types.h>
#include <sys/socket.h>
#include <arpa/inet.h>
#include <netinet/in.h>
#include <netinet/tcp.h>
#include <netdb.h>
#include <fcntl.h> /* Added for the nonblocking socket */

//definitions for socket
#define PortNumber 9876
#define MaxConnects 8
#define BuffSize 256
#define ConversationLen 3
#define Host "localhost"

#define EPS 1e-9

void report(const char *msg, int terminate)
{
    perror(msg);
    if (terminate)
        exit(-1); /* failure */
}

static inline uint64_t le64dec(const void *pp)
{
    const uint8_t *p = (uint8_t const *)pp;
    return ((uint64_t)(p[0]) | ((uint64_t)(p[1]) << 8) |
            ((uint64_t)(p[2]) << 16) | ((uint64_t)(p[3]) << 24)) |
           ((uint64_t)(p[4]) << 32) | ((uint64_t)(p[5]) << 40) |
           ((uint64_t)(p[6]) << 48) | ((uint64_t)(p[7]) << 56);
}

struct xoshiro_state
{
    uint64_t s[4];
};

static inline uint64_t rotl64(const uint64_t x, int k)
{
    return (x << k) | (x >> (64 - k));
}

static inline uint64_t xoshiro_gen(struct xoshiro_state *state)
{
    const uint64_t result = rotl64(state->s[0] + state->s[3], 23) + state->s[0];

    const uint64_t t = state->s[1] << 17;

    state->s[2] ^= state->s[0];
    state->s[3] ^= state->s[1];
    state->s[1] ^= state->s[2];
    state->s[0] ^= state->s[3];

    state->s[2] ^= t;

    state->s[3] = rotl64(state->s[3], 45);

    return result;
}

static int compute_rank(const uint_fast16_t A[64][64])
{
    double B[64][64];
    for (int i = 0; i < 64; ++i)
    {
        for (int j = 0; j < 64; ++j)
        {
            B[i][j] = A[i][j];
        }
    }

    int rank = 0;
    bool row_selected[64] = {};

    for (int i = 0; i < 64; ++i)
    {
        int j;
        for (j = 0; j < 64; ++j)
        {
            if (!row_selected[j] && fabs(B[j][i]) > EPS)
                break;
        }
        if (j != 64)
        {
            ++rank;
            row_selected[j] = true;
            for (int p = i + 1; p < 64; ++p)
                B[j][p] /= B[j][i];
            for (int k = 0; k < 64; ++k)
            {
                if (k != j && fabs(B[k][i]) > EPS)
                {
                    for (int p = i + 1; p < 64; ++p)
                        B[k][p] -= B[j][p] * B[k][i];
                }
            }
        }
    }
    return rank;
}

static inline bool is_full_rank(const uint_fast16_t matrix[64][64])
{
    return compute_rank(matrix) == 64;
}

static inline void generate_matrix(uint16_t matrix[64][64], struct xoshiro_state *state)
{
    do
    {
        for (int i = 0; i < 64; ++i)
        {
            for (int j = 0; j < 64; j += 16)
            {
                uint64_t value = xoshiro_gen(state);
                for (int shift = 0; shift < 16; ++shift)
                {
                    matrix[i][j + shift] = (value >> (4 * shift)) & 0xF;
                }
            }
        }
    } while (!is_full_rank(matrix));
}

void heavyhash(const uint16_t matrix[64][64], uint8_t *pdata, size_t pdata_len, uint8_t *output)
{
    uint8_t hash_first[32] __attribute__((aligned(64)));
    uint8_t hash_first_eg[32] __attribute__((aligned(64)));
    uint8_t hash_second[32] __attribute__((aligned(64)));
    uint8_t hash_xored[32] __attribute__((aligned(64)));

    uint16_t vector[64] __attribute__((aligned(64)));
    uint16_t product[64] __attribute__((aligned(64)));
    uint32_t nonce = *((uint32_t *)pdata + 19);
    sha3_256((uint8_t *)hash_first, 32, pdata, pdata_len);

    printf("nonce:%08x\n", nonce);
    printf("=== hash input %d ===\n", pdata_len);
    for (int i = 0; i < 88; i++)
    {
        printf("%02x", *((uint8_t *)pdata + i));
    }
    printf("\n");

    // /*===== Added by egoncu to see block header ======*/
    // printf("=== First hash ===\n");
    // for (int i = 0; i < 32; i++)
    // {
    //     printf("%02x", *((uint8_t *)hash_first_eg + i));
    // }
    // printf("\n");
    // for (int i = 0; i < 32; i++)
    // {
    //     printf("%02x", hash_first[i]);
    // }
    // printf("\n");
    // printf("==================\n");

    /*=================================================*/

    for (int i = 0; i < 32; ++i)
    {
        vector[2 * i] = (hash_first[i] >> 4);
        vector[2 * i + 1] = hash_first[i] & 0xF;
    }

    for (int i = 0; i < 64; ++i)
    {
        uint16_t sum = 0;
        for (int j = 0; j < 64; ++j)
        {
            sum += matrix[i][j] * vector[j];
        }
        //printf("sum[%d]=%04x\n",i,sum);
        product[i] = (sum >> 10);
    }

    for (int i = 0; i < 32; ++i)
    {
        hash_second[i] = (product[2 * i] << 4) | (product[2 * i + 1]);
    }

    //printf("=== Hash XORed ===\n");
    for (int i = 0; i < 32; ++i)
    {
        hash_xored[i] = hash_first[i] ^ hash_second[i];
        //printf("%02x", hash_xored[i]);
    }
    //printf("\n================\n");
    sha3_256(output, 32, hash_xored, 32);

    printf("=== First heavyhash ===\n");
    for (int i = 31; i >= 0; i--)
    {
        printf("%02x", *(output + i));
    }
    printf("\n");
}

int scanhash_heavyhash(struct work *work, uint32_t max_nonce,
                       uint64_t *hashes_done, struct thr_info *mythr)
{
    uint32_t edata[20] __attribute__((aligned(64)));
    uint32_t hash[8] __attribute__((aligned(64)));
    uint32_t golden_hash[8] __attribute__((aligned(64)));
    uint32_t seed[8] __attribute__((aligned(64)));

    uint32_t *pdata = work->data;
    uint32_t *ptarget = work->target;
    const uint32_t first_nonce = pdata[19];
    const uint32_t last_nonce = max_nonce - 1;
    uint32_t n = first_nonce;
    const int thr_id = mythr->id;
    const bool bench = opt_benchmark;

    uint16_t matrix[64][64];
    struct xoshiro_state state;

    // socket client
    int sockfd = socket(AF_INET,     /* versus AF_LOCAL */
                        SOCK_STREAM, /* reliable, bidirectional */
                        0);          /* system picks protocol (TCP) */
    if (sockfd < 0)
        report("socket", 1); /* terminate */

    /* get the address of the host */
    struct hostent *hptr = gethostbyname(Host); /* localhost: 127.0.0.1 */
    if (!hptr)
        report("gethostbyname", 1);  /* is hptr NULL? */
    if (hptr->h_addrtype != AF_INET) /* versus AF_LOCAL */
        report("bad address family", 1);

    /* connect to the server: configure server's address 1st */
    struct sockaddr_in saddr;
    memset(&saddr, 0, sizeof(saddr));
    saddr.sin_family = AF_INET;
    saddr.sin_addr.s_addr =
        ((struct in_addr *)hptr->h_addr_list[0])->s_addr;
    saddr.sin_port = htons(PortNumber); /* port number in big-endian */

    if (connect(sockfd, (struct sockaddr *)&saddr, sizeof(saddr)) < 0)
        report("connect", 1);

    fcntl(sockfd, F_SETFL, O_NONBLOCK);

    mm128_bswap32_80(edata, pdata);

    sha3_256(seed, 32, edata + 1, 32);

    for (int i = 0; i < 4; ++i)
    {
        state.s[i] = le64dec(seed + 2 * i);
    }

    generate_matrix(matrix, &state);

    write(sockfd, work->data, 80);

    write(sockfd, matrix, sizeof(matrix));

    write(sockfd, ptarget, 32);

    write(sockfd, &max_nonce, 4);

    uint32_t golden_nonce = 0;

    printf("Thread id = %d \n", thr_id);

    int count = -1;
    uint32_t status = 0;

    count = -1;
    uint32_t hh = 0;

    do
    {
        count = -1;
        while (count == -1)
        {
            count = read(sockfd, &status, 4);

            //printf("hashes_done = %d\n", count);
            if (work_restart[thr_id].restart)
            {
                printf("Restart threads!\n");
                // socket client
                FILE *fp;
                int ret;
                char filename[] = "interProcessFile";
                fp = fopen(filename, "a+");

                while (count == -1)
                    count = read(sockfd, &status, 4);

                //printf("Socket is closed\n");
                fclose(fp);

                ret = remove(filename);

                if (ret == 0)
                {
                    printf("File deleted successfully");
                }
                else
                {
                    printf("Error: unable to delete the file");
                }
                status = 0;
                return 0;
            }
        }
        if (status == 1)
        {
            count = -1;
            while (count == -1)
                count = read(sockfd, &golden_nonce, 4);

            count = -1;
            while (count == -1)
                count = read(sockfd, hash, 32);

            printf("hash:");
            for (size_t i = 0; i < 8; i++)
            {
                printf("%08x", hash[i]);
            }
            printf("\n");
            pdata[19] = golden_nonce;
            count = -1;
            while (count == -1)
                count = read(sockfd, &hh, 4);
            *hashes_done = hh;
            submit_solution(work, hash, mythr);
        }
    } while (status != 0);

    count = -1;
    while (count == -1)
        count = read(sockfd, &hh, 4);

    *hashes_done = hh;
    //printf("hashes_done = %+d\n", *hashes_done);

    close(sockfd);
    return 0;
}

int scanhash_generic_exampletest(struct work *work, uint32_t max_nonce,
                                 uint64_t *hashes_done, struct thr_info *mythr)
{
    uint32_t edata[20] __attribute__((aligned(64)));
    uint32_t hash[8] __attribute__((aligned(64)));
    uint32_t *pdata = work->data;
    uint32_t *ptarget = work->target;
    const uint32_t first_nonce = pdata[19];
    const uint32_t last_nonce = max_nonce - 1;
    uint32_t n = first_nonce;
    const int thr_id = mythr->id;
    const bool bench = opt_benchmark;

    mm128_bswap32_80(edata, pdata);
    do
    {
        edata[19] = n;
        if (likely(algo_gate.hash(hash, edata, thr_id)))
            if (unlikely(valid_hash(hash, ptarget) && !bench))
            {
                pdata[19] = bswap_32(n);
                submit_solution(work, hash, mythr);
            }
        n++;
    } while (n != (first_nonce + 2)); //(n < last_nonce && !work_restart[thr_id].restart);
    *hashes_done = n - first_nonce;
    pdata[19] = n;
    return 0;
}

bool register_heavyhash_algo(algo_gate_t *gate)
{
    gate->optimizations = SSE42_OPT;
    gate->scanhash = (void *)&scanhash_heavyhash;
    gate->hash = (void *)&heavyhash;

    return true;
};
