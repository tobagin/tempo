# Flatpak Automation Setup for Tempo

This document explains the automated Flatpak manifest update system for Tempo.

## 🚀 Overview

The automation system provides:
- **Tag-triggered updates**: Automatically update Flatpak manifests when creating release tags
- **Cross-repository PRs**: Create pull requests to Flathub repository automatically
- **External data checking**: Weekly checks for dependency updates
- **Zero-maintenance releases**: Just push a tag, everything else is automated

## 📁 Files Created

### GitHub Actions Workflows
- `.github/workflows/update-flatpak.yml` - Main automation workflow
- `.github/workflows/update-external-data.yml` - External data checker workflow

### Flatpak Configuration
- `packaging/io.github.tobagin.tempo.yml` - Production manifest with x-checker-data
- `flathub.json` - Flathub configuration

## 🔧 Setup Requirements

### 1. Repository Secrets
You need to add a `FLATHUB_TOKEN` secret to your GitHub repository:

1. Go to GitHub Settings → Developer settings → Personal access tokens → Tokens (classic)
2. Click "Generate new token (classic)"
3. Name it "Flathub Automation"
4. Select scopes:
   - `repo` (Full control of private repositories)
   - `workflow` (Update GitHub Action workflows)
5. Go to your repository → Settings → Secrets and variables → Actions
6. Click "New repository secret"
7. Name: `FLATHUB_TOKEN`
8. Value: Paste your personal access token

### 2. Token Permissions
Ensure your token has access to:
- Your main repository (`tobagin/Tempo`)
- Your Flathub repository (`flathub/io.github.tobagin.tempo`)

## 🔄 How It Works

### Automatic Release Updates
1. **Push a tag** matching `v*.*.*` pattern (e.g., `v1.2.1`)
2. **GitHub Action triggers** automatically
3. **Extracts version info** from the tag
4. **Updates manifest** with new tag and commit hash
5. **Commits changes** to your repository
6. **Creates PR** to Flathub repository
7. **Flathub CI** tests the build
8. **Maintainers merge** the PR to publish

### Weekly Dependency Checks
- **Every Monday at 14:00 UTC**, external data checker runs
- **Checks for updates** to Blueprint compiler and other dependencies
- **Creates PR** if updates are found
- **Manual review** before merging

## 🏷️ Usage

### Creating a Release
```bash
# Tag your release
git tag v1.2.1
git push origin v1.2.1

# The automation takes care of the rest!
```

### Manual Workflow Trigger
1. Go to Actions tab in your repository
2. Select "Update Flatpak Manifest on Tag"
3. Click "Run workflow"
4. Select your branch and run

### Testing External Data Checker
1. Go to Actions tab → "Update External Data"
2. Click "Run workflow"
3. Check "Only check for updates" for a dry run
4. Click "Run workflow"

## 📋 What Gets Updated

### Main Workflow Updates
- ✅ Tempo application tag and commit hash
- ✅ Manifest version references
- ✅ Local repository commits
- ✅ Flathub PR creation

### External Data Checker Updates
- ✅ Blueprint compiler versions
- ✅ Dependency source URLs
- ✅ Checksums and integrity hashes
- ✅ Version tracking

## 🔍 Monitoring

### Workflow Status
- Check Actions tab for workflow status
- Review GitHub step summaries
- Monitor Flathub PR status

### Flathub Repository
- Monitor: https://github.com/flathub/io.github.tobagin.tempo/pulls
- Check CI build status
- Verify merge completion

## 🐛 Troubleshooting

### Common Issues

**"Manifest file not found"**
- Check the manifest path in the workflow
- Ensure `packaging/io.github.tobagin.tempo.yml` exists

**"Pattern not found" during update**
- Verify the regex pattern matches your manifest structure
- Check module name is "tempo" and URL is correct

**"Authentication failed" for Flathub PR**
- Verify `FLATHUB_TOKEN` secret is set
- Check token has repository access
- Ensure token isn't expired

**External data checker fails**
- Check `x-checker-data` configuration
- Verify API endpoints are accessible
- Review Docker container logs

### Debugging Steps
1. Check workflow logs in Actions tab
2. Verify manifest syntax with `yamllint`
3. Test API endpoints manually:
   ```bash
   curl -s https://api.github.com/repos/tobagin/Tempo/releases/latest
   ```

## 📊 Benefits

- **Zero maintenance** releases
- **Consistent** Flathub updates
- **Automatic** commit hash verification for security
- **Integration** with Flathub's systems
- **Future-proof** automation that works with Flathub standards
- **Weekly** dependency updates
- **Comprehensive** error handling

## 🔒 Security

- Uses minimal token permissions
- Includes repository ownership checks
- Verifies commit hashes for integrity
- Regular dependency updates via external checker
- Automated PR creation with review requirements

---

## 🎯 Next Steps

1. **Set up the FLATHUB_TOKEN** secret
2. **Test with a sample tag** (e.g., `v1.2.0-test`)
3. **Monitor the first automated PR** to Flathub
4. **Enable weekly external data checking**

The automation is now ready! Just push tags and let GitHub Actions handle the rest.

---

*Based on the comprehensive Flatpak automation guide and configured specifically for Tempo.*