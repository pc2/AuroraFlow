/*
 * Copyright 2026 Gerrit Pape (gerrit.pape@uni-paderborn.de)
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <fcntl.h>
#include <unistd.h>
#include <errno.h>
#include <svdpi.h>

#define MAX_INSTANCES 2
#define DATA_BYTES 32

static int tx_fds[MAX_INSTANCES] = {-1, -1};
static int rx_fds[MAX_INSTANCES] = {-1, -1};

static int get_rank() {
    const char *rank_str = getenv("OMPI_COMM_WORLD_RANK");
    if (!rank_str) rank_str = getenv("PMIX_RANK");
    return rank_str ? atoi(rank_str) : 0;
}

void aurora_dpi_open_all() {
    char path[256];
    const char *dir = getenv("AURORA_PIPE_DIR");
    if (!dir) dir = ".";
    int rank = get_rank();

    // Phase 1: open all RX fds (O_RDONLY|O_NONBLOCK succeeds immediately)
    for (int i = 0; i < MAX_INSTANCES; i++) {
        snprintf(path, sizeof(path), "%s/aurora_r%d_i%d_rx", dir, rank, i);
        rx_fds[i] = open(path, O_RDONLY | O_NONBLOCK);
        printf("aurora_dpi[r%d_i%d]: open RX %s = %d %s\n", rank, i, path,
               rx_fds[i], rx_fds[i] < 0 ? strerror(errno) : "ok");
        fflush(stdout);
    }

    // Phase 2: open all TX fds (readers now exist from phase 1)
    for (int i = 0; i < MAX_INSTANCES; i++) {
        snprintf(path, sizeof(path), "%s/aurora_r%d_i%d_tx", dir, rank, i);
        int retries = 0;
        tx_fds[i] = open(path, O_WRONLY | O_NONBLOCK);
        while (tx_fds[i] < 0 && errno == ENXIO && retries < 10000) {
            usleep(1000);
            tx_fds[i] = open(path, O_WRONLY | O_NONBLOCK);
            retries++;
        }
        printf("aurora_dpi[r%d_i%d]: open TX %s = %d %s (retries=%d)\n", rank, i, path,
               tx_fds[i], tx_fds[i] < 0 ? strerror(errno) : "ok", retries);
        fflush(stdout);
    }
}

int aurora_dpi_write(int instance, const svBitVecVal *data) {
    if (instance < 0 || instance >= MAX_INSTANCES || tx_fds[instance] < 0) return 0;
    ssize_t n = write(tx_fds[instance], data, DATA_BYTES);
    if (n == DATA_BYTES) return 1;
    return 0;
}

int aurora_dpi_read(int instance, svBitVecVal *data) {
    if (instance < 0 || instance >= MAX_INSTANCES || rx_fds[instance] < 0) return 0;
    ssize_t total = 0;
    while (total < DATA_BYTES) {
        ssize_t n = read(rx_fds[instance], (char *)data + total, DATA_BYTES - total);
        if (n > 0) {
            total += n;
        } else if (n == 0) {
            return 0;
        } else if (errno == EAGAIN || errno == EWOULDBLOCK) {
            if (total == 0) return 0;
            usleep(1);
        } else {
            return 0;
        }
    }
    return 1;
}

void aurora_dpi_close(int instance) {
    if (instance < 0 || instance >= MAX_INSTANCES) return;
    if (tx_fds[instance] >= 0) { close(tx_fds[instance]); tx_fds[instance] = -1; }
    if (rx_fds[instance] >= 0) { close(rx_fds[instance]); rx_fds[instance] = -1; }
    printf("aurora_dpi[%d]: closed\n", instance);
    fflush(stdout);
}
