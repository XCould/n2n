# n2n on macOS

In order to use n2n on macOS, you first need to install support for TUN/TAP interfaces:

```bash
brew tap homebrew/cask
brew cask install tuntap
```

If you are on a modern version of macOS (i.e. Catalina), the commands above will ask you to enable the TUN/TAP kernel extension in System Preferences → Security & Privacy → General.

For more information refer to vendor documentation or the [Apple Technical Note](https://developer.apple.com/library/content/technotes/tn2459/_index.html).


# Build on Windows (Visual Studio)

## Requirements

In order to build on Windows the following tools should be installed:

- Visual Studio. For a minimal install, the command line only build tools can be
  downloaded and installed from https://visualstudio.microsoft.com/downloads/#build-tools-for-visual-studio-2017.

- CMake (From https://cmake.org/download/)

  NOTE: You should always use the official cmake stable release as otherwise
  you may have issues finding libraries (e.g: the installed OpenSSL library).
  If you still have problems, you can try invoking it with `C:\Program Files\CMake\bin\cmake`.

- (optional) The OpenSSL library. Pre-built binaries can be downloaded from
  https://slproweb.com/products/Win32OpenSSL.html.
  The full version is required, i.e. not the "Light" version. The Win32
  version of it is usually required for a standard build.

  NOTE: In order to enable OpenSSL compilation, add the option
  `-DN2N_OPTION_USE_OPENSSL=ON` to the `cmake ..` command below.

  NOTE: To statically link OpenSSL, add the option
  `-DOPENSSL_USE_STATIC_LIBS=true` to the `cmake ..` command below.

NOTE: Sticking to this tool chain has historically meant that resulting
executables are more likely to be able to communicate with Linux or other
OS builds, however efforts are being made to address this concern.

## Build (CLI)

In order to build from the command line, open a terminal window change to
the directory where the git checkout of this repository is and run the
following commands:

The `libnatpmp` and `libminiupnp` have been moved to separated repositories.
So the very first time, you should run this command in the n2n directory to
install them:

```bash
git submodule update --init --recursive
```

Building using `cmake` works as follows:

```batch
cmake -E make_directory build
cd build

rem Append any options to the next line
cmake ..

cmake --build . --config Release
```

The compiled `.exe` files should now be available in the `build\Release` directory.

## Run

In order to run n2n, you will need the following:

- The TAP drivers should be installed into the system. They can be installed from
  http://build.openvpn.net/downloads/releases, search for "tap-windows".

- If OpenSSL has been linked dynamically, the corresponding `.dll` file should be available
  onto the target computer.

The `edge.exe` program reads the `edge.conf` file located into the current directory if no option is provided.

The `supernode.exe` program reads the `supernode.conf` file located into the current directory if no option is provided.

Example [edge.conf](../packages/etc/n2n/edge.conf.sample)
and [supernode.conf](../packages/etc/n2n/supernode.conf.sample) are available.

See `edge.exe --help` and `supernode.exe --help` for a full list of supported options.

# Build on Windows (MinGW)

These steps were tested on a fresh install of Windows 10 Pro with all patches
applied as of 2021-09-29.

- Install Chocolatey (Following instructions on https://chocolatey.org/install)
- from an admin cmd prompt
    - choco install git mingw make
- All the remaining commands must be run from inside a bash shell ("C:\Program Files\Git\usr\bin\bash.exe")
    - git clone $THIS_REPO
    - cd n2n
    - ./scripts/hack_fakeautoconf.sh
    - make
    - make test

Due to the hack used to replace autotools on windows, any build created this
way will currently have inaccurate build version numbers.

Note: MinGW builds have a history of incompatibility reports with other OS
builds, please see [#617](https://github.com/ntop/n2n/issues/617) and [#642](https://github.com/ntop/n2n/issues/642).
However, if the tests pass, you should have a high confidence that your build
will be compatible.

# General Building Options

## Compiler Optimizations

The easiest way to boosting speed is by allowing the compiler to apply optimization to the code. To let the compiler know, the configuration process can take in the optionally specified compiler flag `-O3`:

`./configure CFLAGS="-O3"`

The `tools/n2n-benchmark` tool reports speed-ups of 200% or more! There is no known risk in terms of instable code or so.

## Hardware Features

Some parts of the code significantly benefit from compiler optimizations (`-O3`) and platform features
such as NEON, SSE and AVX. It needs to be decided at compile-time. Hence if compiling for a specific
platform with known features (maybe the local one), it should be specified to the compiler – for
example through the `-march=sandybridge` (you name it) or just `-march=native` for local use.

So far, the following portions of n2n's code benefit from hardware features:

```
AES:               AES-NI
ChaCha20:          SSE2, SSSE3
SPECK:             SSE2, SSSE3, AVX2, AVX512, (NEON)
Random Numbers:    RDSEED, RDRND (not faster but more random seed)
```

The compilations flags could easily be combined:

`./configure CFLAGS="-O3 -march=native"`.

There are reports of compile errors showing `n2n_seed': random_numbers.c:(.text+0x214): undefined reference to _rdseed64_step'` even though the CPU should support it, see #696. In this case, best solution found so far is to disable `RDSEED` support by adding `-U__RDSEED__` to the `CFLAGS`.

## OpenSSL Support

Some ciphers' speed can take advantage of OpenSSL support which is disabled by default as the built-in ciphers already prove reasonably fast in most cases. OpenSSL support can be configured using

`./configure --with-openssl`

which then will include OpenSSL 1.1 if found on the system. This can be combined with the hardware support and compiler optimizations such as

`./configure --with-openssl CFLAGS="-O3 -march=native"`

Please do no forget to `make clean` after (re-)configuration and before building (again) using `make`.

## ZSTD Compression Support

In addition to the built-in LZO1x for payload compression (`-z1` at the edge's commandline), n2n optionally supports [ZSTD](https://github.com/facebook/zstd). As of 2020, it is considered cutting edge and [praised](https://en.wikipedia.org/wiki/Zstandard) for reaching the currently technologically possible Pareto frontier in terms of CPU power versus compression ratio. ZSTD support can be configured using

`./configure --with-zstd`

which then will include ZSTD if found on the system. It will be available via `-z2` at the edges. Of course, it can be combined with the other features mentioned above:

`./configure --with-zstd --with-openssl CFLAGS="-O3 -march=native"`

Again, and this needs to be reiterated sufficiently often, please do no forget to `make clean` after (re-)configuration and before building (again) using `make`.

## SPECK – ARM NEON Hardware Acceleration

By default, SPECK does not take advantage of ARM NEON hardware acceleration even if compiled with `-march=native`. The reason is that the NEON implementation proved to be slower than the 64-bit scalar code on Raspberry Pi 3B+, see [here](https://github.com/ntop/n2n/issues/563).

Your specific ARM mileage may vary, so it can be enabled by configuring the definition of the `SPECK_ARM_NEON` macro:

`./configure CFLAGS="-DSPECK_ARM_NEON"`

Just make sure that the correct architecture is set, too. `-march=native` usually works quite well.

## Disable Multicast Local Peer Detection

For better local peer detection, the edges try to detect local peers by sending REGISTER
packets to a certain multicast address. Also, edges listen to this address to eventually
fetch such packets.

If these packets disturb network's peace or even get forwarded by (other) edges through the
n2n network, this behavior can be disabled, just add

`-DSKIP_MULTICAST_PEERS_DISCOVERY`

to your `CFLAGS` when configuring, e.g.

`./configure --with-zstd CFLAGS="-O3 -march=native -DSKIP_MULTICAST_PEERS_DISCOVERY"`

# Cross compiling on Linux

## Using the Makefiles and Autoconf

The Makefiles are all setup to allow cross compiling of this code.  You
will need to have the cross compiler, binutils and any additional libraries
desired installed for the target architecture.  Then you can run the `./configure`
with the appropriate CC and AR environment and the right `--host` option.

If compiling on Debian or Ubuntu, this can be as simple as the following example:

```
HOST_TRIPLET=arm-linux-gnueabi
sudo apt-get install binutils-$HOST_TRIPLET gcc-$HOST_TRIPLET
./autogen.sh
export CC=$HOST_TRIPLET-gcc
export AR=$HOST_TRIPLET-ar
./configure --host $HOST_TRIPLET
make
```

A good starting point to determine the host triplet for your destination platform
can be found by copying the `./config.guess` script to it and running it on the
destination.

This is not a good way to produce binaries for embedded environments (like OpenWRT)
as they will often use a different libc environment.
