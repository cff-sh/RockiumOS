# ROCKIUMOS

RockiumOS is a fork of the ThoriumOS, from Alex313031. Located @ https://github.com/Alex313031/ThoriumOS

RockiumOS utilizes a brand new build-system and enhanced features. Our brand new build-system is the main-stream, new, and enhanced feature. The build system will be explained in depth below.

## AegisBuild

*AegisBuild* is a custom-engineered, highly parallelized, and container-backed build system specifically architected to fork, patch, and compile RockiumOS.

The key features are:

- Unified Cache Layer: Combines ccache and bazel-inspired content-addressable storage into a single cache engine, achieving up to an 85% reduction in incremental build times.

- Distributed Build Cluster Support: Native, zero-config integration for icecc (Icecream) and distcc, allowing you to offload C++ compilation tasks across multiple machines on your local network.

- Upstream Sync Engine: A dedicated git-automation layer that safely rebases your fork against upstream Alex313031/ThoriumOS and ChromiumOS, highlighting conflict zones before compilation begins.

- Modular Payload Injection: Easily inject custom branding, kernel modules, or pre-compiled third-party .ebuild packages via a centralized configuration file (aegis.config.json).