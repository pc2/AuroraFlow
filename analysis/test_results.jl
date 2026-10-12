using Test
include("results.jl")

function write_benchmark(path; framing_mismatches=nothing, append=false,
                         frame_errors=0, byte_errors=0, failed_transmissions=0)
    rows = [
        Any["node", "1", "commit", "2.16", "device", instance, 0, 0, 1, 4,
            1024, 10, 0, elapsed, 0, 0, zeros(Int, 22)...]
        for (instance, elapsed) in [(0, 1e-4), (1, 3e-4)]
    ]
    open(path, append ? "a" : "w") do io
        for row in rows
            row[17] = failed_transmissions
            row[23] = byte_errors
            row[38] = frame_errors
            isnothing(framing_mismatches) || push!(row, framing_mismatches)
            println(io, join(row, ','))
        end
    end
end

@testset "Benchmark analysis treats receiver framing mismatches as diagnostics" begin
    mktempdir() do directory
        path = joinpath(directory, "benchmark.csv")
        matrix = Dict("WIDTH" => "64", "AXI_CLOCK_HZ" => "300000000",
                      "XRT" => "2.16", "FRAME_SIZE" => "4")
        write_benchmark(path; framing_mismatches=0)
        @test benchmark_points(path, matrix).latency[1] ≈ 2e-5
        write_benchmark(path; append=true)
        @test benchmark_points(path, matrix).instances == [4]
        write_benchmark(path; framing_mismatches=255)
        @test benchmark_points(path, matrix).latency[1] ≈ 2e-5
        write_benchmark(path; framing_mismatches=255, frame_errors=1)
        @test_throws ErrorException benchmark_points(path, matrix)
        write_benchmark(path; framing_mismatches=255, byte_errors=1)
        @test_throws ErrorException benchmark_points(path, matrix)
        write_benchmark(path; framing_mismatches=255, failed_transmissions=1)
        @test_throws ErrorException benchmark_points(path, matrix)
    end
end

@testset "Throughput uses mean iteration latency and HLS frame bytes" begin
    mktempdir() do directory
        path = joinpath(directory, "benchmark.csv")
        write_benchmark(path)
        matrix = Dict("WIDTH" => "32", "HLS_WIDTH" => "64", "AXI_CLOCK_HZ" => "400000000",
                      "CLOCK_BRIDGE" => "1", "BUILD_SYS" => "make", "XRT" => "2.16", "FRAME_SIZE" => "4")
        data = benchmark_points(path, matrix)
        @test data.frame_bytes == [256]
        @test data.latency[1] ≈ 2e-5
        @test data.throughput[1] ≈ 0.4096
        matrix["FRAME_SIZE"] = "0"
        @test benchmark_points(path, matrix).frame_bytes == [0]
    end
end

@testset "Unavailable results do not contribute stale local data" begin
    mktempdir() do directory
        result = Dict("local" => Dict("kind" => "unavailable", "result_path" => "stale"))
        @test isnothing(result_directory(directory, result))
        result["local"] = Dict("kind" => "success", "result_path" => "..")
        @test_throws ErrorException result_directory(directory, result)
    end
end
