# KATCP

[![Stable](https://img.shields.io/badge/docs-stable-blue.svg)](https://kiranshila.github.io/KATCP.jl/stable/)
[![Dev](https://img.shields.io/badge/docs-dev-blue.svg)](https://kiranshila.github.io/KATCP.jl/dev/)
[![Build Status](https://github.com/kiranshila/KATCP.jl/actions/workflows/CI.yml/badge.svg?branch=main)](https://github.com/kiranshila/KATCP.jl/actions/workflows/CI.yml?query=branch%3Amain)
[![Coverage](https://codecov.io/gh/kiranshila/KATCP.jl/branch/main/graph/badge.svg)](https://codecov.io/gh/kiranshila/KATCP.jl)

This library provides a pure Julia implementation of the [KATCP](https://katcp-python.readthedocs.io/en/latest/_downloads/361189acb383a294be20d6c10c257cb4/NRF-KAT7-6.0-IFCE-002-Rev5-1.pdf)
monitor and control protocol, as described by the Karoo Array Telescope (KAT) project from the Square Kilometer Array (SKA) South Africa group.

### Description

From the official specification:

> Broadly speaking, KATCP consists of newline-separated text messages sent asynchronously over a TCP/IP
> stream. There are three categories of messages: requests, replies and informs. Request messages expect some
> sort of acknowledgement. Reply messages acknowledge requests. Inform messages require no acknowledgement
> Inform messages are of two types: those sent synchronously as part of a reply and those sent asynchronously.

Unlike the rust implementation [here](https://github.com/kiranshila/katcp), this library forgoes some "correctness" for ease of use.
Specifically, we ignore the fact that lines are specified as "plaintext" and support serialization and deserialization of arbitrary (non-ASCII) bytes to allow "drop in" support as a CasperFPGA transport.
Additionally, as there are no switchable runtime backends like in rust, we will provide client and server implementations.

However, like rust, the interface is constructed such that the parser is type-stable and as fast as possible.

### Performance

Our parser is about a factor of 4 faster than the python solution (lots of room for improvement).

### License

KATCP.jl is distributed under the terms of the MIT license
See [LICENSE](LICENSE) for details.
