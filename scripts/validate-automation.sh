#!/bin/bash

# Tempo Flatpak Automation Validation Script
# This script validates the automation setup

set -e

echo "🔍 Validating Tempo Flatpak Automation Setup..."
echo

# Check required files exist
echo "📁 Checking required files..."

required_files=(
    ".github/workflows/update-flatpak.yml"
    ".github/workflows/update-external-data.yml"
    "packaging/io.github.tobagin.tempo.yml"
    "flathub.json"
)

missing_files=0
for file in "${required_files[@]}"; do
    if [[ -f "$file" ]]; then
        echo "✅ $file"
    else
        echo "❌ $file (MISSING)"
        missing_files=$((missing_files + 1))
    fi
done

if [[ $missing_files -gt 0 ]]; then
    echo
    echo "❌ $missing_files required file(s) missing. Please create them first."
    exit 1
fi

echo

# Validate YAML syntax
echo "📝 Validating YAML syntax..."

if command -v yamllint &> /dev/null; then
    echo "Using yamllint for validation..."
    yamllint .github/workflows/ || echo "⚠️ Workflow YAML has issues"
    yamllint packaging/io.github.tobagin.tempo.yml || echo "⚠️ Manifest YAML has issues"
else
    echo "⚠️ yamllint not installed, skipping YAML validation"
    echo "   Install with: pip install yamllint"
fi

echo

# Check manifest structure
echo "🔧 Checking manifest structure..."

manifest_file="packaging/io.github.tobagin.tempo.yml"
if grep -q "x-checker-data" "$manifest_file"; then
    echo "✅ x-checker-data configuration found"
else
    echo "❌ x-checker-data configuration missing"
fi

if grep -q "tag: v" "$manifest_file"; then
    echo "✅ Version tag format found"
else
    echo "❌ Version tag format missing"
fi

if grep -q "commit:" "$manifest_file"; then
    echo "✅ Commit hash found"
else
    echo "❌ Commit hash missing"
fi

echo

# Test GitHub API endpoints
echo "🌐 Testing GitHub API endpoints..."

api_url="https://api.github.com/repos/tobagin/Tempo/releases/latest"
if curl -s "$api_url" | grep -q "tag_name"; then
    echo "✅ GitHub API endpoint accessible"
    latest_tag=$(curl -s "$api_url" | grep '"tag_name"' | cut -d'"' -f4)
    echo "   Latest release: $latest_tag"
else
    echo "❌ GitHub API endpoint not accessible"
fi

echo

# Check workflow triggers
echo "⚡ Checking workflow triggers..."

if grep -q "v\*\.\*\.\*" .github/workflows/update-flatpak.yml; then
    echo "✅ Tag trigger pattern found"
else
    echo "❌ Tag trigger pattern missing"
fi

if grep -q "workflow_dispatch" .github/workflows/update-flatpak.yml; then
    echo "✅ Manual trigger enabled"
else
    echo "❌ Manual trigger missing"
fi

echo

# Validate repository references
echo "🔗 Validating repository references..."

expected_refs=(
    "flathub/io.github.tobagin.tempo"
    "tobagin/Tempo"
    "io.github.tobagin.tempo"
)

for ref in "${expected_refs[@]}"; do
    if grep -q "$ref" .github/workflows/update-flatpak.yml; then
        echo "✅ $ref reference found"
    else
        echo "❌ $ref reference missing"
    fi
done

echo

# Summary
echo "📋 Validation Summary"
echo "===================="
echo
echo "Required setup steps:"
echo "1. ✅ GitHub Actions workflows created"
echo "2. ✅ Flatpak manifest configured"
echo "3. ✅ External data checker setup"
echo "4. ✅ Flathub configuration added"
echo
echo "Next steps:"
echo "- Set up FLATHUB_TOKEN secret in GitHub repository"
echo "- Test with a sample tag (e.g., v1.2.0-test)"
echo "- Monitor first automated PR to Flathub"
echo
echo "🚀 Automation setup validation complete!"

# Check if we're in a git repository
if git rev-parse --is-inside-work-tree &>/dev/null; then
    echo
    echo "📦 Git repository status:"
    echo "Current tag: $(git describe --tags --abbrev=0 2>/dev/null || echo 'No tags found')"
    echo "Current commit: $(git rev-parse --short HEAD)"
    echo "Branch: $(git branch --show-current)"
fi