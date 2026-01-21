# Changelog

All notable changes to server-scripts-cli will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [1.3.0] - 2026-01-21

### Added
- CI/CD pipeline with GitHub Actions
- ShellCheck linting workflow (severity: error)
- Bash syntax validation workflow
- Automated release workflow (tag-triggered)
- `.shellcheckrc` configuration (Best Practices 2025)
- CI status badge in README.md

### Changed
- All bash scripts now validated on every push to main branch
- Automated GitHub Releases on version tags

## [1.2.0] - 2026-01-20

### Added
- **Automated Installer** (`install.sh`): One-liner installation with 3 modes
  - `--local`: Add alias to ~/.bashrc (default)
  - `--user`: Symlink to ~/.local/bin
  - `--system`: Install to /usr/local/bin (requires sudo)
  - Prerequisites check (Bash 4.0+, yq, git)
  - Color-coded logging and idempotent execution
- **Contributing Guide** (`CONTRIBUTING.md`): Fork → Branch → PR workflow
- **Security Policy** (`SECURITY.md`): Vulnerability disclosure process
- **Code of Conduct** (`CODE_OF_CONDUCT.md`): Contributor Covenant v2.1
- **GitHub Issue Templates**: Bug Report and Feature Request templates
- **GitHub PR Template**: Standardized pull request format
- **Subdir Navigation**: `docs/README.md` and `examples/README.md` index files

### Changed
- **README.md**: Complete overhaul
  - Added 7 professional badges (Version, License, Bash, Platform, Maintenance, YAML, Contributions)
  - One-liner installation as primary method
  - Manual installation moved to collapsible `<details>` section
  - New "Contributing" section with links to community docs
  - Updated Documentation and Examples sections with index links

### Documentation
- Added `docs/README.md` - Documentation index with file descriptions
- Added `examples/README.md` - Demo scripts overview with usage guide

## [1.1.1] - 2026-01-17

### Fixed
- **HIGH**: Generator now supports `examples/demo-scripts/` directory as fallback when `scripts/` doesn't exist ([#codex-high](https://github.com/fidpa/server-scripts-cli/issues))
  - Enables testing generator in standalone demo repository without manual setup
  - Priority-based directory search: `scripts/` first, then `examples/demo-scripts/`
- **MEDIUM**: Fixed type taxonomy inconsistency - removed `cli-tool` default type, changed to `admin` ([#codex-medium](https://github.com/fidpa/server-scripts-cli/issues))
  - Default type changed from `cli-tool` to `admin` (Tier 1 type)
  - Updated CLI help text to show valid type examples
- **MEDIUM**: Added auto-migration for deprecated `cli-tool` type → `admin` with warnings ([#codex-medium](https://github.com/fidpa/server-scripts-cli/issues))
  - Non-breaking change: existing scripts with `type: cli-tool` auto-migrate
  - Warning messages guide users to update YAML frontmatter
- **LOW**: Synchronized version strings across all files to v1.1.1 ([#codex-low](https://github.com/fidpa/server-scripts-cli/issues))

### Changed
- Generator now scans directories in priority order: `scripts/` first, then `examples/demo-scripts/`
- Default type for scripts without frontmatter changed from `cli-tool` to `admin`
- Updated CLI help text (`ssc list --help`) to remove `cli-tool` references

### Deprecated
- Type `cli-tool` is now deprecated - use `deployment: cli-tool` field instead
- See [MANIFEST_SCHEMA.md](docs/MANIFEST_SCHEMA.md#deprecated-types) for migration guide

### Documentation
- Added "Deprecated Types" section to [MANIFEST_SCHEMA.md](docs/MANIFEST_SCHEMA.md)
- Added migration examples and behavior documentation

## [1.1.0] - 2026-01-16

### Added
- **4-Tier Type System**: Organize scripts by usage pattern
  - Tier 1 (Interactive): `report`, `admin`, `diagnostic`, `check`, `orchestrator`
  - Tier 2 (One-time): `deploy`, `setup`, `migration`, `generator`, `benchmark`
  - Tier 3 (Background): `daemon`, `scheduled`, `exporter`
  - Tier 4 (Internal): `library`, `helper`
- **Smart Default Filtering**: `ssc list` shows only Interactive types (Tier 1) by default
- **New `--all` flag**: Show complete script list including all tiers
- **Enhanced Help Text**: Detailed type hierarchy documentation in `ssc list --help`
- **Color-Coded Types**: Visual distinction between tiers (Green/Yellow/Cyan/Magenta)
- **New Type: `benchmark`**: Performance testing scripts (Tier 2)

### Changed
- **Demo Scripts Updated**: Migrated to new type system
  - `backup-example.sh`: `backup` → `admin`
  - `monitoring-example.sh`: `monitoring` → `check`
  - `health-check.sh`: `validation` → `check`
  - `deploy-example.sh`: `automation` → `deploy`
- **Manifest Schema**: Updated with complete type hierarchy documentation
- **README**: Enhanced feature list and examples

### Deprecated
- Legacy types (`automation`, `backup`, `monitoring`, `validation`) still supported but superseded by new types

## [1.0.0] - 2026-01-02

### Added
- Initial public release
- Core commands: `list`, `run`, `info`, `status`, `logs`, `validate`, `generate`
- YAML manifest-based script discovery
- systemd integration for status and logs
- Category and status filtering
- Search functionality
- Security: Input validation, safe execution, requires_root detection
- Demo scripts: 4 examples (backup, monitoring, health-check, deployment)
- Complete documentation suite
- MIT License

[Unreleased]: https://github.com/fidpa/server-scripts-cli/compare/v1.3.0...HEAD
[1.3.0]: https://github.com/fidpa/server-scripts-cli/compare/v1.2.0...v1.3.0
[1.2.0]: https://github.com/fidpa/server-scripts-cli/compare/v1.1.1...v1.2.0
[1.1.1]: https://github.com/fidpa/server-scripts-cli/compare/v1.1.0...v1.1.1
[1.1.0]: https://github.com/fidpa/server-scripts-cli/compare/v1.0.0...v1.1.0
[1.0.0]: https://github.com/fidpa/server-scripts-cli/releases/tag/v1.0.0
