using KATCP
using Test
using Dates
using Sockets
using Aqua

function roundtrip_type(a::T) where {T}
    @test a == KATCP.parse(T, KATCP.unparse(a))
end

function roundtrip_msg(a::T) where {T<:KATCP.AbstractKatcpMessage}
    @test a == KATCP.read(T, KATCP.serialize(KatcpMessage(a)))
end

function roundtrip_msg(msg::KatcpMessage)
    msg_roundtrip = KatcpMessage(KATCP.serialize(msg))
    @test msg_roundtrip.kind == msg.kind
    @test msg_roundtrip.name == msg.name
    @test msg_roundtrip.id == msg.id
    @test msg_roundtrip.arguments == msg.arguments
end

@testset "Aqua" begin
    Aqua.test_ambiguities(KATCP)
    # I don't think this is actually an error
    # Aqua.test_ubnound_args(KATCP)
    Aqua.test_undefined_exports(KATCP)
    Aqua.test_project_extras(KATCP)
    Aqua.test_stale_deps(KATCP)
    Aqua.test_deps_compat(KATCP)
    Aqua.test_project_toml_formatting(KATCP)
end

@testset "KATCP.jl" begin
    @testset "Round trip protocol" begin
        for kind in [KATCP.Request, KATCP.Inform, KATCP.Reply],
            name in ["foo", "foo-bar", "foo123"],
            id in [nothing, Some(123)],
            arguments in [
                [b"foo", b"bar", b"baz"],
                [b"foo", Vector{UInt8}(raw"bar\_is\_silly")],
                Vector{UInt8}[]
            ]

            roundtrip_msg(KatcpMessage(kind, name, id, arguments))
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
        @testset "Maybe" begin
            @test Some("Foo") == KATCP.parse(KATCP.Maybe{String}, KATCP.unparse("Foo"))
            @test nothing === KATCP.parse(KATCP.Maybe{String}, KATCP.unparse(nothing))
        end
    end
    @testset "Roundtrip messages" begin
        @testset "Replies" begin
            for code in [KATCP.Ok, KATCP.Fail, KATCP.Invalid], id in [nothing, 123]
                roundtrip_msg(reply(code, "a-command-name"; id=id))
            end
        end
        @testset "Halt" begin
            roundtrip_msg(HaltRequest())
        end
        @testset "Help" begin
            for name in [nothing, Some("a-command-name")]
                roundtrip_msg(HelpRequest(name))
            end
            roundtrip_msg(HelpRequest())
            roundtrip_msg(HelpInform("a-command-name", raw"This is how this command works"))
            roundtrip_msg(reply(KATCP.Ok, HelpReply(123)))
        end
        @testset "Restart" begin
            roundtrip_msg(RestartRequest())
        end
        @testset "Watchdog" begin
            roundtrip_msg(WatchdogRequest())
        end
        @testset "VersionList" begin
            roundtrip_msg(VersionListRequest())
            for identifier = [Some("abc123nd"), nothing]
                roundtrip_msg(VersionListInform("foo", "v1.2.3", identifier))
            end
            roundtrip_msg(reply(KATCP.Ok, VersionListReply(123)))
        end
        @testset "Disconnect" begin
            roundtrip_msg(DisconnectInform("New client connected from 192.168.1.100:24500"))
        end
        @testset "VersionConnect" begin
            roundtrip_msg(VersionConnectInform("katcp-protocol", "5.0-MITB"))
            roundtrip_msg(VersionConnectInform("katcp-library", "KATCP.jl-0.1.0", "Julia 1.8 - x86_64-linux-gnu"))
        end
        @testset "InterfaceChanged" begin
            roundtrip_msg(InterfaceChangedInform("sensor-list"))
            roundtrip_msg(InterfaceChangedInform("request-list"))
            roundtrip_msg(InterfaceChangedInform("sensor", "az", KATCP.Added))
            roundtrip_msg(InterfaceChangedInform("request", "el", KATCP.Modified))
            roundtrip_msg(InterfaceChangedInform("request", "el", KATCP.Removed))
        end
    end
end
