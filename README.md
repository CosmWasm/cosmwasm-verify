# CosmWasm Verify

A tool to verify a CosmWasm build result against its source.

When uploading a smart contract to a blockchain, storage is very expensive.
For this reason we only want to store the absolute minimum of data required for execution
on chain. However, a Wasm bytecode does not allow for reviewing the functionality that
is executed in a smart contract.
For auditing we need to look into the original source, which we can
link on chain. In order to verify that the build result indeed matches the linked source code,
we use CosmWasm Verify.

## From source to Wasm bytecode

A source code is compiled into Wasm bytecode using a "builder", i.e. a compiler toolchain
that typically optimizes the code for small size or low execution cost. Builders are identified
by docker images in CosmWasm, which is a convenient way to represent a whole suite of tools and
scripts in a short identifier.

The same source code can be compiled using different builders, e.g. when the tooling improves over
time or to do custom optimization priorities (some user prefers smaller code, another user prefers cheaper execution).

## The inputs and outputs

CosmWasm Verify has 3 input parameters:

- **Source** is an URL to an optinally compressed tar archive. Currently supported protocols are: https.
- **Builder** is a docker image, including version.
- **Checksum** is the expeced SHA256 hash of the compiled wasm bytecode.

The script `cosmwasm-verify` takes those 3 inputs as positional arguments. It outputs all kind
of stuff during the build process, which is meant for your entertainment and debugging.
**The only guaranteed interface for verification is result code `0` in case of a successful verification and a different code if anything goes wrong.**

## Getting started

Setup the script in your session with

```
git clone https://github.com/confio/cosmwasm-verify
export PATH="$PWD/cosmwasm-verify/bin:$PATH"
```

An example call would be

```sh
cosmwasm-verify \
  https://crates.io/api/v1/crates/cw-nameservice/0.1.0/download \
  confio/cosmwasm-opt:0.6.2 \
  66128c5c0cd38e6b908b03d41eba8c9e9befb79b34683e334d7a8bbe74d5df41

# Shows the return code of the last script
echo $?
```

## Language support

CosmWasm Verify is CosmWasm specific but generic enough to support multiple languages.
The primary smart contract language at the moment is Rust and the primary Rust builder is
[cosmwasm-opt](https://github.com/confio/cosmwasm-opt).
The [upcoming AssemblyScript support](https://github.com/confio/cosmwasm/pull/118) will require a
different builder but should be handles equally by CosmWasm Verify.

## Conventions

In order to make our lifes easier, we need a trade-off between flexibility and
pre-defined rules. Here are a set of conventions required for CosmWasm Verify
to work.

1. The builder is a docker image that works out of the box with `docker run <builder>`
2. The builder must create a `contract.wasm` in the current directory
3. The source URL points to an optionally compressed tar archive that includes a single top directory which.
4. All checksums are lower hex encoded SHA-256 hashes

## Requirements

CosmWasm Verify aims to run in every UNIX-like environment. It requires the
following tools to work:

- `bash`
- `wget`
- `docker`
- `sha256sum` or `shasum`
