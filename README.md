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

## CI Pipeline

This tap uses a multi-stage macOS CI gate (`.github/workflows/`) to validate PRs and releases:

- **lint.yml** (fast): Syntax, style, and audit checks on every PR/push to main
- **tests.yml** (build matrix): Full source builds on `macos-14` (ARM64) + `macos-13` (x86_64); includes co-installation testing for `wirelog` + `wyrelog` symlink conflicts
- **head-build.yml** (nightly): Tests upstream `HEAD` builds to detect dependency drift
- **release.yml** (on tag): Validates tagged formula releases before publication

### CI Design Notes

- **Dependent-rebuild**: `reverse_deps.yml` tracks tap-internal dependencies. When `libchronoid` or `wirelog` change, reverse-dependents are rebuilt to catch cross-formula breakage.
- **Co-installation testing**: `wyrelog` requires `wirelog`; CI explicitly tests both installation order and symlink conflict scenarios (commit 8df2384).
- **Caching**: Homebrew dependency installation is cached by runner to reduce build time.
- **Native runners**: Uses GitHub's native `macos-14` and `macos-13` runners; no cross-compilation or containers. Exercises macOS-specific code paths (`rpath`, dylib handling).

## Notes

- Formulae currently pin source snapshots until tagged releases are available
- Pre-built binaries are downloaded during installation where available
- All packages use Meson build system with offline wrap resolution

## CI Troubleshooting

### Lint job fails (`lint.yml`)
- **`brew style` violations**: Run `brew style --fix ./Formula` locally and commit the changes
- **`brew audit --strict` failures**: Review the audit warning and fix the formula or consider if the warning is a false positive
- **Ruby syntax errors (`ruby -wc`)**: Check for YAML indentation or Ruby syntax issues in `.rb` files

### Build job fails (`tests.yml`, `test-bot`)
- **Dependency resolution**: Check if `reverse_deps.yml` is accurate; if a formula's `depends_on` changed, update the reverse-dep map
- **Build timeout on `wyrelog`**: DuckDB download + Meson can take 15–20 min on the first build; cache hits should speed subsequent runs
- **Linker errors on `wyrelog`**: Verify `libduckdb.dylib` is present and executable. Check `lipo -info` output for architecture mismatch
- **Local reproduction**: Run `brew install --build-from-source ./Formula/<name>.rb && brew test <name>` to debug locally

### Co-install job fails (`tests.yml`, `coinstall`)
- **Symlink conflicts** (`wirelog` ↔ `wyrelog`): This is the expected failure mode. The fix usually involves:
  1. Check for overlapping files: `brew --prefix wirelog/lib` vs. `brew --prefix wyrelog/lib`
  2. Either remove the conflicting file from one formula or use `install_name_tool` to fix dylib references
  3. See commit 8df2384 for the current conflict resolution strategy
- **`brew test` failures**: Ensure both `brew test wirelog` and `brew test wyrelog` pass independently in the `test-bot` job first

### HEAD-build job fails (`head-build.yml`)
- **Advisory-only**: HEAD build failures do **not** block releases. They indicate upstream (`main` branch) changes may have broken the formula.
- **Check upstream**: Compare the HEAD build error to the upstream commit log for the dependency project. If the upstream is genuinely broken, ping the upstream maintainers.
- **Re-run manually**: Use GitHub Actions UI to trigger the job with `workflow_dispatch` after upstream fixes are available

### Release job fails (`release.yml`)
- **Tag format**: Tags must match `<formula>-<version>` (e.g., `libchronoid-1.0.3`, `wyrelog-2.5.1`)
- **Formula mismatch**: The formula file must exist at `Formula/<formula>.rb`
- **Version validation**: Ensure the version in the tag matches the `version` in the formula file
- **Co-install for wirelog/wyrelog**: If releasing `wirelog` or `wyrelog`, the release job runs co-installation tests to catch symlink conflicts before publication
