#define IP_START 0x1
#define IP_DONE 0x2
#define IP_IDLE 0x4
#define USER_OFFSET 0x10

class SendKernel
{
public:
    SendKernel(uint32_t instance, xrt::device &device, xrt::uuid &xclbin_uuid, Configuration &config, std::vector<char> &data) : instance(instance), config(config)
    {
        char name[100];
        snprintf(name, 100, "send:{send_%u}", instance);
        ip = xrt::ip(device, xclbin_uuid, name);

        data_bo = xrt::bo(device, config.max_num_bytes, xrt::bo::flags::normal, 0x10);
        data_bo_addr = data_bo.address();

        data_bo.write(data.data());
        data_bo.sync(XCL_BO_SYNC_BO_TO_DEVICE);
    }

    SendKernel() {}

    void prepare_repetition(uint32_t repetition)
    {
        ip.write_register(0x10, data_bo_addr);
        ip.write_register(0x1c, config.message_sizes[repetition]);
        ip.write_register(0x24, config.frame_sizes[repetition]);
        ip.write_register(0x2c, config.iterations_per_message[repetition]);
        ip.write_register(0x34, config.test_mode);
    }

    void start()
    {
        uint32_t axi_ctrl = IP_START;
        ip.write_register(USER_OFFSET, axi_ctrl);
    }

    bool timeout()
    {
        uint32_t axi_ctrl = 0;
        double start = get_wtime();
        while (((get_wtime() - start) * 1000) < config.timeout_ms) {
            axi_ctrl = ip.read_register(USER_OFFSET);
            if ((axi_ctrl & IP_DONE) == IP_IDLE) {
                return false;
            }
        }
        return true;
    }

    std::vector<char> data;
private:
    xrt::bo data_bo;
    uint64_t data_bo_addr;
    xrt::ip ip;
    uint32_t instance;
    Configuration config;
};

class RecvKernel
{
public:

    RecvKernel(uint32_t instance, xrt::device &device, xrt::uuid &xclbin_uuid, Configuration &config) : instance(instance), config(config)
    {
        char name[100];
        snprintf(name, 100, "recv:{recv_%u}", instance);
        kernel = xrt::kernel(device, xclbin_uuid, name);

        data_bo = xrt::bo(device, config.max_num_bytes, xrt::bo::flags::normal, kernel.group_id(1));

        data.resize(config.max_num_bytes);
    }

    RecvKernel() {}

    void prepare_repetition(uint32_t repetition)
    {
        run = xrt::run(kernel);

        run.set_arg(1, data_bo);
        run.set_arg(2, config.message_sizes[repetition]);
        run.set_arg(3, config.iterations_per_message[repetition]);
        run.set_arg(4, config.test_mode);
    }

    void start()
    {
        run.start();
    }

    bool timeout()
    {
        return run.wait(std::chrono::milliseconds(config.timeout_ms)) == ERT_CMD_STATE_TIMEOUT;
    }

    void write_back()
    {
        data_bo.sync(XCL_BO_SYNC_BO_FROM_DEVICE);
        data_bo.read(data.data());
    }

    uint32_t compare_data(char *ref, uint32_t repetition)
    {
        uint32_t err_num = 0;
        for (uint32_t i = 0; i < config.message_sizes[repetition]; i++) {
            if (data[i] != ref[i]) {
                if (err_num < 16) {
                    printf("recv[%d] = %02x, send[%d] = %02x\n", i, (uint8_t)data[i], i, (uint8_t)ref[i]);
                }
                err_num++;
            }
        }
        if (err_num > 16) {
            std::cout << "only showing the first 16 byte errors" << std::endl;
        }
        return err_num;
    }

    std::vector<char> data;

private:
    xrt::bo data_bo;
    xrt::kernel kernel;
    xrt::run run;
    uint32_t instance;
    Configuration config;
};

class RecvSendKernel
{
public:
    RecvSendKernel(uint32_t instance, xrt::device &device, xrt::uuid &xclbin_uuid, Configuration &config) : instance(instance), config(config)
    {
        char name[100];
        snprintf(name, 100, "send_recv:{send_recv_%u}", instance);
        kernel = xrt::kernel(device, xclbin_uuid, name);
    }

    RecvSendKernel() {}

    void prepare_repetition(uint32_t repetition)
    {
        run = xrt::run(kernel);

        run.set_arg(2, config.message_sizes[repetition]);
        run.set_arg(3, config.iterations_per_message[repetition]);
    }

    void start()
    {
        run.start();
    }

    bool timeout()
    {
        return run.wait(std::chrono::milliseconds(config.timeout_ms)) == ERT_CMD_STATE_TIMEOUT;
    }

    std::vector<char> data;
private:
    xrt::bo data_bo;
    xrt::kernel kernel;
    xrt::run run;
    uint32_t instance;
    Configuration config;
};


