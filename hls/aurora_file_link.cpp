/*
 * Copyright 2025 Gerrit Pape (papeg@mail.upb.de)
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

#include <hls_stream.h>
#include <ap_int.h>
#include <ap_axi_sdata.h>

#ifndef __SYNTHESIS__
#include <fcntl.h>
#include <unistd.h>
#include <poll.h>
#include <csignal>
#include <cstdio>
#include <cstdlib>
#include <cerrno>
#include <cstring>
#include <thread>
#endif

#ifndef DATA_WIDTH_BYTES
#define DATA_WIDTH_BYTES 64
#endif

#define DATA_WIDTH (DATA_WIDTH_BYTES * 8)

#ifndef __SYNTHESIS__
static bool write_full(int fd, const void *buf, size_t count) {
    size_t total = 0;
    while (total < count) {
        ssize_t n = write(fd, (const char *)buf + total, count - total);
        if (n <= 0) return false;
        total += n;
    }
    return true;
}

static bool read_full(int fd, void *buf, size_t count) {
    size_t total = 0;
    while (total < count) {
        ssize_t n = read(fd, (char *)buf + total, count - total);
        if (n <= 0) return false;
        total += n;
    }
    return true;
}
#endif

extern "C" {

void aurora_file_link(
    hls::stream<ap_axiu<DATA_WIDTH, 0, 0, 0>> &tx_axis,
    hls::stream<ap_axiu<DATA_WIDTH, 0, 0, 0>> &rx_axis,
    unsigned int pipe_id,
    volatile unsigned int *control
) {
#ifdef __SYNTHESIS__
    ap_axiu<DATA_WIDTH, 0, 0, 0> pkt = tx_axis.read();
    rx_axis.write(pkt);
    *control = 0;
#else
    signal(SIGPIPE, SIG_IGN);

    const char *pipe_dir = getenv("AURORA_PIPE_DIR");
    if (!pipe_dir) pipe_dir = "/tmp";

    char tx_path[256], rx_path[256];
    snprintf(tx_path, sizeof(tx_path), "%s/aurora_%u_tx", pipe_dir, pipe_id);
    snprintf(rx_path, sizeof(rx_path), "%s/aurora_%u_rx", pipe_dir, pipe_id);

    int tx_fd = -1, rx_fd = -1;
    std::thread tx_opener([&tx_fd, &tx_path]() {
        tx_fd = open(tx_path, O_WRONLY);
    });
    rx_fd = open(rx_path, O_RDONLY);
    tx_opener.join();

    if (tx_fd < 0 || rx_fd < 0) {
        fprintf(stderr, "aurora_file_link[%u]: pipe open failed: %s\n",
                pipe_id, strerror(errno));
        if (tx_fd >= 0) close(tx_fd);
        if (rx_fd >= 0) close(rx_fd);
        return;
    }

    fprintf(stderr, "aurora_file_link[%u]: pipes connected\n", pipe_id);

    std::thread tx_thread([&tx_axis, tx_fd, control]() {
        while (*control == 0) {
            if (tx_axis.empty()) {
                usleep(1000);
                continue;
            }
            ap_axiu<DATA_WIDTH, 0, 0, 0> pkt = tx_axis.read();
            if (!write_full(tx_fd, &pkt.data, DATA_WIDTH_BYTES)) break;
        }
        close(tx_fd);
    });

    struct pollfd pfd = {rx_fd, POLLIN, 0};
    while (*control == 0) {
        int ret = poll(&pfd, 1, 100);
        if (ret > 0 && (pfd.revents & POLLIN)) {
            ap_uint<DATA_WIDTH> data = 0;
            if (!read_full(rx_fd, &data, DATA_WIDTH_BYTES)) break;
            ap_axiu<DATA_WIDTH, 0, 0, 0> pkt;
            pkt.data = data;
            pkt.keep = -1;
            pkt.last = 0;
            rx_axis.write(pkt);
        } else if (ret > 0 && (pfd.revents & (POLLHUP | POLLERR))) {
            break;
        }
    }
    close(rx_fd);
    tx_thread.join();

    fprintf(stderr, "aurora_file_link[%u]: shutdown\n", pipe_id);
#endif
}

}
