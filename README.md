<div align="center">

SnowflakeOS ISO
===
[![Built with Nix][builtwithnix badge]][builtwithnix]
[![License: MIT][MIT badge]][MIT]
[![Chat on Matrix][matrix badge]][matrix]
[![Chat on Discord][discord badge]][discord]

SnowflakeOS is a NixOS based Linux distribution focused on beginner friendliness and ease of use. This repository contains the configuration used to build the SnowflakeOS ISO files.

</div>

## Where to download?

Latest ISO files are currently being hosted on [Sourceforge](https://sourceforge.net/projects/snowflakeos/files/latest/download)

Previous builds can be found in this repositories [GitHub Actions](https://github.com/snowflakelinux/snowflake-iso/actions)

## How to build

1) Clone this repository and navigate to the project directory
2) `nix build .#install-isoConfigurations.snowflakeos`
3) The resulting ISO file will be linked in `result/iso/snowflakeos-<version>.iso`

[builtwithnix badge]: https://img.shields.io/badge/Built%20With-Nix-41439A?style=for-the-badge&logo=nixos&logoColor=white
[builtwithnix]: https://builtwithnix.org/
[MIT badge]: https://img.shields.io/badge/License-MIT-blue.svg?style=for-the-badge
[MIT]: https://opensource.org/licenses/MIT
[matrix badge]: https://img.shields.io/badge/matrix-join%20chat-0cbc8c?style=for-the-badge&logo=matrix&logoColor=white
[matrix]: https://matrix.to/#/#snowflakeos:matrix.org
[discord badge]: https://img.shields.io/discord/1021080090676842506?color=7289da&label=Discord&logo=discord&logoColor=ffffff&style=for-the-badge
[discord]: https://discord.gg/6rWNMmdkgT
