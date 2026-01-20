# Contributing to Server Scripts CLI

Thank you for considering contributing to `server-scripts-cli`! This document outlines the process for contributing to this project.

## 🚀 Quick Start

```bash
# 1. Fork the repository on GitHub
# 2. Clone your fork
git clone https://github.com/YOUR_USERNAME/server-scripts-cli
cd server-scripts-cli

# 3. Create a feature branch
git checkout -b feature/your-feature-name

# 4. Make your changes
# 5. Test your changes
./ssc.sh list
./ssc.sh validate

# 6. Commit with semantic versioning in mind
git add .
git commit -m "Add: Feature description"

# 7. Push to your fork
git push origin feature/your-feature-name

# 8. Open a Pull Request on GitHub
```

## 📋 Contribution Guidelines

### Code Style

- **Bash Scripts**: Follow existing patterns (`set -uo pipefail`, error handling, readonly variables)
- **Indentation**: 4 spaces (no tabs)
- **Functions**: Use `snake_case` naming
- **Variables**: Use `SCREAMING_SNAKE_CASE` for constants, `snake_case` for locals
- **Comments**: Document complex logic, use `# =====` section separators

### Testing

Before submitting a PR, ensure:
- [ ] `./ssc.sh list` works correctly
- [ ] `./ssc.sh validate` passes
- [ ] Script follows shellcheck recommendations
- [ ] Documentation is updated (if adding features)

### Documentation

- Update `README.md` if adding user-facing features
- Update `docs/MANIFEST_SCHEMA.md` if changing YAML schema
- Add entries to `CHANGELOG.md` (Keep a Changelog format)

### Commit Messages

Use clear, descriptive commit messages:

```
Add: New feature description
Fix: Bug fix description
Docs: Documentation update
Refactor: Code improvement without behavior change
Test: Add or update tests
```

## 🐛 Reporting Bugs

Use the [Bug Report template](.github/ISSUE_TEMPLATE/bug_report.md) and include:
- Steps to reproduce
- Expected vs. actual behavior
- Environment (Bash version, OS, yq version)
- Relevant logs or error messages

## 💡 Feature Requests

Use the [Feature Request template](.github/ISSUE_TEMPLATE/feature_request.md) and describe:
- Use case and motivation
- Proposed solution
- Alternative solutions considered

## 📜 Code of Conduct

This project adheres to the [Contributor Covenant Code of Conduct](CODE_OF_CONDUCT.md). By participating, you are expected to uphold this code.

## 🔄 Pull Request Process

1. **Fork & Branch**: Create a feature branch from `main`
2. **Develop**: Make your changes with clear commits
3. **Test**: Ensure all tests pass and functionality works
4. **Document**: Update relevant documentation
5. **Submit**: Open a PR with a clear description
6. **Review**: Address feedback from maintainers
7. **Merge**: Once approved, your PR will be merged

## 📝 License

By contributing, you agree that your contributions will be licensed under the MIT License.

## 🙏 Thank You!

Your contributions help make `server-scripts-cli` better for everyone. We appreciate your time and effort!

---

**Questions?** Open an issue or reach out to [@fidpa](https://github.com/fidpa).
