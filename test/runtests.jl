using KATCP
using Test
using Dates
using Sockets

@testset "KATCP.jl" begin
    @testset "Round trip protocol" begin
        for kind in [KATCP.Request, KATCP.Inform, KATCP.Reply],
            name in ["foo", "foo-bar", "foo123"],
            id in [nothing, 123],
            arguments in [
                [Vector{UInt8}("foo"), Vector{UInt8}("bar"), Vector{UInt8}("baz")],
                [Vector{UInt8}("foo"), Vector{UInt8}(raw"bar\_is\_silly")],
                []
            ]

            msg = RawMessage(kind, name, id, arguments)
            msg_roundtrip = RawMessage(Vector{UInt8}(msg))
            @test msg_roundtrip.kind == kind
            @test msg_roundtrip.name == name
            @test msg_roundtrip.id == id
            @test msg_roundtrip.arguments == arguments
        end
    end
    @testset "Round trip types" begin
        @testset "RetCode" begin
            for code in [KATCP.Ok, KATCP.Invalid, KATCP.Fail]
                code_roundtrip = KATCP.parse(KATCP.RetCode, Vector{UInt8}(code))
                @test code_roundtrip == code
            end
        end
        @testset "Int32" begin
            for val in rand(Int32, 100)
                @test val == KATCP.parse(Int32, Vector{UInt8}(val))
            end
        end
        @testset "Float32" begin
            for val in rand(Float32, 100)
                @test val == KATCP.parse(Float32, Vector{UInt8}(val))
            end
        end
        @testset "Bool" begin
            @test true == KATCP.parse(Bool, Vector{UInt8}(true))
            @test false == KATCP.parse(Bool, Vector{UInt8}(false))
        end
        @testset "DateTime" begin
            for timestamp in rand(100) .* 31536000
                dt = unix2datetime(timestamp)
                KATCP.parse(DateTime, Vector{UInt8}(dt))
            end
        end
        @testset "KatcpAddress" begin
            for host in [ip"192.168.4.10", ip"::1", ip"2001:0db8:85a3:0000:0000:8a2e:0370:7334"],
                port in [UInt16(8080), nothing]

                addr = KatcpAddress(host, port)
                @test addr == KATCP.parse(KatcpAddress, Vector{UInt8}(addr))
            end
        end
    end
    @testset "Round trip concrete message types" begin
        raw = RawMessage(KATCP.Reply, "foo", BareReply(KATCP.Ok)) |> Vector{UInt8}
        @test KATCP.read(BareReply, raw) === BareReply(KATCP.Ok)
    end
end
