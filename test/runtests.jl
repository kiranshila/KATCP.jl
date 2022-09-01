using KATCP
using Test
using Dates
using Sockets

function roundtrip_type(a::T) where {T}
    @test a == KATCP.parse(T, KATCP.unparse(a))
end

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
                roundtrip_type(code)
            end
        end
        @testset "Int32" begin
            for val in rand(Int32, 100)
                roundtrip_type(val)
            end
        end
        @testset "Float32" begin
            for val in rand(Float32, 100)
                roundtrip_type(val)
            end
        end
        @testset "Float64" begin
            for val in rand(Float32, 100)
                roundtrip_type(val)
            end
        end
        @testset "Bool" begin
            roundtrip_type(true)
            roundtrip_type(false)
        end
        @testset "DateTime" begin
            for timestamp in rand(100) .* 31536000
                roundtrip_type(unix2datetime(timestamp))
            end
        end
        @testset "Enums" begin
            @enum Foo Bar Baz Buzz
            for variant in [Bar, Baz, Buzz]
                roundtrip_type(variant)
            end
        end
        @testset "KatcpAddress" begin
            for host in [ip"192.168.4.10", ip"::1", ip"2001:0db8:85a3:0000:0000:8a2e:0370:7334"],
                port in [UInt16(8080), nothing]

                addr = KatcpAddress(host, port)
                @test addr == KATCP.parse(KatcpAddress, KATCP.unparse(addr))
            end
        end
        @testset "String" begin
            for s in ["foo", "foo bar baz", "\\@", "\eA\\_crazy\tstring\nwith\0lots\\of\rthings"]
                roundtrip_type(s)
            end
        end
        @testset "Arbitrary data" begin
            for data in eachcol(rand(UInt8, 100, 100))
                roundtrip_type(Vector(data))
            end
        end
    end
    @testset "Round trip concrete message types" begin
        raw = RawMessage(KATCP.Reply, "foo", BareReply(KATCP.Ok)) |> Vector{UInt8}
        @test KATCP.read(BareReply, raw) === BareReply(KATCP.Ok)
    end
end
