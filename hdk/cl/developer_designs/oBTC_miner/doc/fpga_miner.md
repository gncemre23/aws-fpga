# User manual of FPGA miner

## Table of Contents

1. [Overview](#overview)
2. [Functional Description](#description)
3. [Verification](#verification)
4. [Test software](#test_software)  
3. [Mining](#Mining)

<a name="overview"></a>
## Overview

<a name="description"></a>
## Functional Description

<a name="verification"></a>
## Verification

<a name="test_software"></a>
## Test Software

<a name="mining"></a>
## Mining

FPGA miner uses the FPGA hardware cores and the software controlling these cores named `oBTCminer_fpga`.  The software is used with `cpuminer` software. Therefore, the socket programming tecniques are used. The work is recevied by `cpuminer` and sent to the `oBTCminer_fpga` by `cpuminer`. To do that, the thread count is fixed to 1 at `cpuminer`. Also, the normally used `heavyhash function` is deactivated. Therefore, all the hash calculations are done by `oBTCminer_fpga`. Then, `oBTCminer_fpga` sends the golden nonce and hash (if they are exist) with `hashes_done` variable which is denoting the how many hash calculations are done by FPGA, to `cpuminer`.

To run the FPGA miner, follow the below steps:

- Open a terminal and connect to the instance with ssh protocol.
- At the instance, open home folder. Run the following command:
    - $ source fpga_init.sh
- After previous command, the current directory is oBTCminer. Go to the top folder of the repository (`aws-fpga`).
- Open `opowminer` folder.
- Open a second terminal and do the previous steps. After that you have two terminals connected to the instance.
- Run the following commands on one of the terminals. After these command, the FPGA will be programmed.
    - $ sudo fpga-clear-local-image -S 0
    - $ sudo fpga-load-local-image -S 0 -I agfi-0419d6ae69c6ddbfb -a 125 -b 370 -c 1
- At the first terminal, open `build-fpga` folder. Run `$ make` command. Therefore, `oBTCminer_fpga` is compiled.
- At the second terminal, run  `$ ./build.sh` command to compile cpuminer.
- After two ones are compiled, first, run `$ sudo ./oBTCminer_fpga` at build-fpga folder at one of the terminal. Then on the other terminal run the following command:
    - $ ./cpuminer -o stratum+tcp://pool.obtc.me:3390 -u [oBTC address] -p . -a heavyhash -D

After these steps, the mining is started.