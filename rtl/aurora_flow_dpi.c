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

void aurora_dpi_open(int instance, int pipe_id) {
    if (instance < 0 || instance >= MAX_INSTANCES) {
        printf("aurora_dpi: invalid instance %d\n", instance);
        fflush(stdout);
        return;
    }

    char path[256];
    const char *dir = getenv("AURORA_PIPE_DIR");
    if (!dir) dir = ".";

    printf("aurora_dpi[%d]: pipe_dir=%s pipe_id=%d\n", instance, dir, pipe_id);
    fflush(stdout);

    snprintf(path, sizeof(path), "%s/aurora_%d_rx", dir, pipe_id);
    rx_fds[instance] = open(path, O_RDONLY | O_NONBLOCK);
    printf("aurora_dpi[%d]: open RX %s = %d %s\n", instance, path,
           rx_fds[instance], rx_fds[instance] < 0 ? strerror(errno) : "ok");
    fflush(stdout);

    snprintf(path, sizeof(path), "%s/aurora_%d_tx", dir, pipe_id);
    int retries = 0;
    tx_fds[instance] = open(path, O_WRONLY | O_NONBLOCK);
    while (tx_fds[instance] < 0 && errno == ENXIO && retries < 5000) {
        usleep(1000);
        tx_fds[instance] = open(path, O_WRONLY | O_NONBLOCK);
        retries++;
    }
    printf("aurora_dpi[%d]: open TX %s = %d %s (retries=%d)\n", instance, path,
           tx_fds[instance], tx_fds[instance] < 0 ? strerror(errno) : "ok", retries);
    fflush(stdout);
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
