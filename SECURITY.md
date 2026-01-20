# Security Policy

## 🔒 Supported Versions

Security updates are provided for the following versions:

| Version | Supported          |
|---------|--------------------|
| 1.1.x   | ✅ Yes             |
| 1.0.x   | ✅ Yes             |
| < 1.0   | ❌ No              |

## 🐛 Reporting a Vulnerability

If you discover a security vulnerability in `server-scripts-cli`, please report it responsibly:

### Reporting Process

1. **DO NOT** open a public GitHub issue for security vulnerabilities
2. Email the maintainer directly: **marc.allgeier@proton.me**
3. Include the following information:
   - Description of the vulnerability
   - Steps to reproduce
   - Potential impact
   - Suggested fix (if any)

### Response Timeline

- **Initial Response**: Within 48 hours of report
- **Status Update**: Within 7 days
- **Fix Timeline**: Depends on severity
  - **Critical**: Hotfix within 7 days
  - **High**: Patch within 14 days
  - **Medium/Low**: Next minor release

### Disclosure Policy

- **Coordinated Disclosure**: We follow responsible disclosure practices
- **Credit**: Security researchers will be credited (if desired)
- **Public Disclosure**: After fix is released and users have time to update (typically 30 days)

## 🛡️ Security Considerations

### Script Execution

`server-scripts-cli` executes shell scripts defined in the manifest. Security best practices:

- **Review Scripts**: Always review scripts before adding to manifest
- **Root Privileges**: Use `requires_root: true` only when necessary
- **Input Validation**: Scripts should validate user input
- **Path Safety**: Use absolute paths in scripts

### YAML Manifest

- **Source Control**: Keep `manifest.yaml` in version control
- **Validation**: Run `ssc validate` regularly
- **Untrusted Sources**: Do not import manifests from untrusted sources

### Installation

- **Verify Source**: Only install from official repository or releases
- **HTTPS Only**: Use HTTPS URLs for installation (`https://github.com/fidpa/server-scripts-cli`)
- **Check Signatures**: Verify GPG signatures when available (future feature)

## 🔍 Known Security Considerations

### 1. Script Execution Context

`ssc run` executes scripts with the user's permissions. Scripts with `requires_root: true` will prompt for sudo.

**Mitigation**: Review scripts before execution, use `ssc info <name>` to inspect metadata.

### 2. Manifest Injection

Malicious YAML in `manifest.yaml` could cause unexpected behavior.

**Mitigation**: Only edit manifest via trusted sources, use `ssc validate` to check integrity.

### 3. Command Injection

`ssc run` uses safe execution patterns to prevent command injection.

**Current Status**: No known vulnerabilities (as of v1.1.1)

## 📋 Security Checklist for Users

- [ ] Review scripts before adding to manifest
- [ ] Use `requires_root` sparingly
- [ ] Keep `server-scripts-cli` updated
- [ ] Run `ssc validate` after manifest changes
- [ ] Use version control for manifest
- [ ] Audit logs via `ssc logs` regularly

## 🔐 Security Features

- **Input Validation**: All user input is validated
- **Safe Execution**: Uses Bash best practices (`set -uo pipefail`)
- **Root Detection**: Requires explicit `requires_root: true` flag
- **Manifest Validation**: Built-in integrity checks

## 📚 Resources

- [OWASP Shell Injection](https://owasp.org/www-community/attacks/Command_Injection)
- [Bash Security Best Practices](https://www.shellcheck.net/)
- [YAML Security](https://yaml.org/spec/1.2/spec.html#id2761803)

## 🙏 Acknowledgments

We thank the security community for responsible disclosure and collaboration.

---

**Last Updated**: 2026-01-20
**Contact**: marc.allgeier@proton.me
