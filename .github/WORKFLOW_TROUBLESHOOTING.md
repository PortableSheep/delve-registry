# GitHub Actions Workflow Troubleshooting Guide

This guide helps you troubleshoot common issues with the Delve Plugin Registry GitHub Actions workflows.

## 🔍 Common Issues and Solutions

### 1. Deployment Failing - "Pages not enabled"

**Error**: `Error: GitHub Pages is not enabled for this repository`

**Solution**:
1. Go to repository Settings → Pages
2. Set Source to "Deploy from a branch"
3. Select branch: `main`
4. Select folder: `/ (root)`
5. Click "Save"

### 2. Workflow Permission Errors

**Error**: `Error: Resource not accessible by integration`

**Solution**:
1. Go to repository Settings → Actions → General
2. Under "Workflow permissions", select "Read and write permissions"
3. Check "Allow GitHub Actions to create and approve pull requests"
4. Click "Save"

### 3. YAML Validation Errors

**Error**: `registry.yml is invalid` or `Error loading registry`

**Solution**:
```bash
# Test locally first
sudo apt-get install yq  # or brew install yq on macOS

# Validate YAML syntax
yq eval registry.yml

# Common fixes:
# - Check indentation (use spaces, not tabs)
# - Ensure all strings with special chars are quoted
# - Verify YAML structure matches expected schema
```

### 4. JSON Validation Errors

**Error**: `Invalid JSON in api/plugins.json`

**Solution**:
```bash
# Test locally
jq . api/plugins.json

# Common JSON issues:
# - Trailing commas
# - Unescaped quotes in strings
# - Missing closing brackets/braces
```

### 5. Plugin Structure Warnings

**Error**: `Warning: plugin_name missing plugin.json`

**Solution**:
- Ensure each plugin directory has a `plugin.json` file
- Validate plugin.json structure:
```json
{
  "info": {
    "id": "plugin-name",
    "name": "Display Name",
    "version": "v1.0.0",
    "description": "Plugin description",
    "author": "Author Name"
  }
}
```

### 6. Deployment Succeeds but Site Shows 404

**Possible causes**:
1. **Repository name mismatch**: Check that URLs match your actual repository name
2. **Branch protection**: Ensure the main branch allows force pushes from Actions
3. **Custom domain issues**: Remove CNAME file temporarily to test

**Solution**:
```bash
# Check the actual deployment URL
# Should be: https://USERNAME.github.io/REPOSITORY-NAME/

# Test these URLs:
curl -I https://USERNAME.github.io/REPOSITORY-NAME/
curl -I https://USERNAME.github.io/REPOSITORY-NAME/registry.yml
curl -I https://USERNAME.github.io/REPOSITORY-NAME/api/plugins.json
```

### 7. Sitemap Generation Errors

**Error**: Issues with sitemap.xml creation

**Solution**:
- Check that repository variables are correctly set
- Ensure no special characters in repository name
- Test sitemap manually:
```xml
<?xml version="1.0" encoding="UTF-8"?>
<urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">
  <url>
    <loc>https://yourusername.github.io/delve-registry/</loc>
    <lastmod>2024-01-15T10:30:00Z</lastmod>
  </url>
</urlset>
```

## 🛠️ Debugging Workflow Issues

### Enable Debug Logging

Add this to your workflow for verbose output:
```yaml
- name: Debug Information
  run: |
    echo "Repository: ${{ github.repository }}"
    echo "Repository owner: ${{ github.repository_owner }}"
    echo "Repository name: ${{ github.event.repository.name }}"
    echo "Ref: ${{ github.ref }}"
    echo "SHA: ${{ github.sha }}"
    ls -la
    pwd
```

### Check File Structure

Add this step to verify your files:
```yaml
- name: Verify Structure
  run: |
    echo "Repository structure:"
    find . -type f -name "*.yml" -o -name "*.yaml" -o -name "*.json" | head -20
    
    echo "Required files check:"
    [ -f "registry.yml" ] && echo "✅ registry.yml" || echo "❌ registry.yml missing"
    [ -f "api/plugins.json" ] && echo "✅ api/plugins.json" || echo "❌ api/plugins.json missing"
    [ -f "README.md" ] && echo "✅ README.md" || echo "❌ README.md missing"
```

### Validate Before Deploy

Add validation step:
```yaml
- name: Pre-deployment Validation
  run: |
    # Install dependencies
    sudo apt-get update && sudo apt-get install -y jq
    
    # Validate all JSON files
    find . -name "*.json" -exec echo "Validating {}" \; -exec jq empty {} \;
    
    # Check API structure
    if [ -f "api/plugins.json" ]; then
      echo "Checking API structure..."
      jq -e '.api_version' api/plugins.json
      jq -e '.plugins' api/plugins.json
    fi
```

## 🔧 Workflow Customization

### Using the Simplified Workflow

If the main workflow is problematic, switch to the simplified version:

1. Disable the complex workflow:
```yaml
# Add this to .github/workflows/pages.yml at the top
# name: Deploy Registry to Pages (DISABLED)
on:
  workflow_dispatch:  # Only manual trigger
```

2. Rename and use the simplified workflow:
```bash
mv .github/workflows/deploy-simple.yml .github/workflows/deploy.yml
```

### Custom Domain Setup

If using a custom domain:

1. Add CNAME file:
```bash
echo "plugins.yourdomain.com" > CNAME
```

2. Update workflow to use custom domain:
```yaml
- name: Set custom domain variables
  run: |
    echo "CUSTOM_DOMAIN=plugins.yourdomain.com" >> $GITHUB_ENV
    echo "BASE_URL=https://plugins.yourdomain.com" >> $GITHUB_ENV
```

### Local Testing

Test the workflow components locally:

```bash
# Clone your repository
git clone https://github.com/yourusername/delve-registry.git
cd delve-registry

# Install dependencies
sudo apt-get install jq yq

# Run validation checks
echo "Validating registry.yml..."
yq eval registry.yml > /dev/null && echo "✅ Valid" || echo "❌ Invalid"

echo "Validating api/plugins.json..."
jq . api/plugins.json > /dev/null && echo "✅ Valid" || echo "❌ Invalid"

# Test local server
python3 -m http.server 8080
# Test: http://localhost:8080
```

## 📊 Monitoring Deployment

### Check Deployment Status

1. **Actions Tab**: Monitor workflow execution
2. **Pages Settings**: Check deployment status
3. **Repository Insights**: View traffic and performance

### Useful Commands for Debugging

```bash
# Check if site is accessible
curl -I https://yourusername.github.io/delve-registry/

# Test API endpoints
curl https://yourusername.github.io/delve-registry/registry.yml
curl https://yourusername.github.io/delve-registry/api/plugins.json

# Check response headers
curl -v https://yourusername.github.io/delve-registry/ 2>&1 | grep -E '^< '

# Test from different locations
dig yourusername.github.io
nslookup yourusername.github.io
```

## 🚨 Emergency Recovery

### If Deployment Completely Breaks

1. **Revert to working commit**:
```bash
git log --oneline  # Find last working commit
git revert HEAD    # Revert latest changes
git push
```

2. **Reset to simple state**:
```bash
# Create minimal working registry
echo "registry:" > registry.yml
echo "  name: Test Registry" >> registry.yml
echo "plugins: {}" >> registry.yml

mkdir -p api
echo '{"api_version":"v1","total_plugins":0,"plugins":[]}' > api/plugins.json

git add .
git commit -m "Reset to minimal working state"
git push
```

3. **Disable workflows temporarily**:
```bash
# Rename workflow files to disable them
mv .github/workflows/pages.yml .github/workflows/pages.yml.disabled
git add .
git commit -m "Temporarily disable workflows"
git push
```

## 📞 Getting Help

### Information to Include in Issues

When reporting workflow issues, include:

1. **Repository URL**
2. **Error message** (full text from Actions log)
3. **Workflow run URL**
4. **Registry configuration** (sanitized registry.yml)
5. **Expected vs actual behavior**

### Useful Logs to Share

```yaml
# Add this step to capture debug info
- name: Debug Environment
  run: |
    echo "=== Environment ==="
    env | sort
    echo "=== File System ==="
    ls -la
    echo "=== Repository Info ==="
    git log --oneline -5
    echo "=== GitHub Context ==="
    echo '${{ toJSON(github) }}'
```

## ✅ Best Practices

1. **Test locally first** before pushing changes
2. **Use semantic commit messages** for easier debugging
3. **Keep workflows simple** - complex workflows are harder to debug
4. **Monitor deployment** after each change
5. **Backup working configurations** before major changes
6. **Use branch protection** to prevent broken deployments

Remember: GitHub Pages can take a few minutes to propagate changes globally. If your site works locally but not remotely, wait 5-10 minutes before troubleshooting further.