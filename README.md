# semantic-reasoning Homebrew tap

Homebrew formulae for Semantic Reasoning projects.

## Installation

### Tap setup

```sh
brew tap semantic-reasoning/tap
```

### Install packages

```sh
# Install from tap
brew install semantic-reasoning/tap/<package-name>
```

Available packages can be discovered with:

```sh
brew search semantic-reasoning
```

## Build from source

```sh
brew install --build-from-source ./Formula/<formula-name>.rb
```

## Requirements

- macOS 10.13+ or Linux (Ubuntu 20.04+, Debian 11+)
- Meson ≥ 0.62.0
- Ninja
- pkg-config
- GCC or Clang

## Notes

- Formulae currently pin source snapshots until tagged releases are available
- Pre-built binaries are downloaded during installation where available
- All packages use Meson build system with offline wrap resolution
