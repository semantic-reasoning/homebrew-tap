# semantic-reasoning Homebrew tap

Homebrew formulae for Semantic Reasoning projects.

## Install

```sh
brew tap semantic-reasoning/tap
brew install wyrelog
```

The `wyrelog` formula installs:

- `wyrelogd` — the daemon
- `wyctl` — the command-line client for a running daemon
- access-control templates and packaging support files

The formula currently pins a source snapshot until tagged `wyrelog` releases are
available.

## Development

```sh
brew install --build-from-source ./Formula/wyrelog.rb
brew test wyrelog
```
