# Delve Plugin Registry Setup Guide

This guide will walk you through setting up and hosting your own Delve Plugin Registry from scratch.

## 🚀 Quick Start

### 1. Clone or Fork This Repository

```bash
# Option 1: Fork this repository on GitHub (recommended)
# Click "Fork" on the GitHub repository page

# Option 2: Clone and create your own repository
git clone https://github.com/PortableSheep/delve-registry.git
cd delve-registry
git remote remove origin
git remote add origin https://github.com/yourusername/your-registry.git
```

### 2. Initialize Your Registry

```bash
# Make scripts executable
chmod +x scripts/*.sh

# Initialize a new registry (if starting fresh)
./scripts/registry-cli.sh init

# Or customize the existing registry
vim registry.yml
```

### 3. Configure GitHub Pages

1. **Go to Repository Settings**
   - Navigate to your repository on GitHub
   - Click "Settings" tab
   - Scroll down to "Pages" section

2. **Configure Pages Source**
   - Source: "Deploy from a branch"
   - Branch: `main`
   - Folder: `/ (root)`
   - Click "Save"

3. **Your registry will be available at:**
   ```
   https://yourusername.github.io/repository-name/
   ```

### 4. Test Your Registry

```bash
# Validate the registry
./scripts/registry-cli.sh validate all

# Check health
./scripts/registry-cli.sh health

# View statistics
./scripts/registry-cli.sh stats
```

## 📋 Prerequisites

### Required Tools

Install these tools on your system:

```bash
# macOS
brew install jq yq curl

# Ubuntu/Debian
sudo apt-get install jq curl
sudo wget -qO /usr/local/bin/yq https://github.com/mikefarah/yq/releases/latest/download/yq_linux_amd64
sudo chmod +x /usr/local/bin/yq

# Windows (using Chocolatey)
choco install jq yq curl
```

### GitHub Requirements

- GitHub account
- Repository with GitHub Pages enabled
- (Optional) Custom domain for professional setup

## 🏗️ Detailed Setup

### Step 1: Repository Configuration

1. **Update registry metadata in `registry.yml`:**

```yaml
registry:
  name: "Your Plugin Registry"
  description: "Registry for your Delve plugins"
  maintainer: "your-username"
  url: "https://github.com/yourusername/your-registry"
  api_version: "v1"

api:
  base_url: "https://yourusername.github.io/your-registry"
```

2. **Customize categories and channels:**

```yaml
categories:
  your-category:
    name: "Your Category"
    description: "Description of your plugin category"

channels:
  stable:
    description: "Production-ready releases"
    include_prerelease: false
    default: true
  beta:
    description: "Beta releases for testing"
    include_prerelease: true
```

### Step 2: GitHub Actions Setup

The repository includes automated workflows:

1. **`.github/workflows/pages.yml`** - Deploys registry to GitHub Pages
2. **`.github/workflows/publish-plugin.yml`** - Automates plugin publishing

**Enable GitHub Actions:**
1. Go to repository "Actions" tab
2. Click "I understand my workflows and want to enable them"
3. Workflows will run automatically on push to main branch

### Step 3: Add Your First Plugin

#### Method 1: Manual Addition

```bash
# Create plugin directory
mkdir my-plugin
cd my-plugin

# Create plugin.json
cat > plugin.json << 'EOF'
{
  "info": {
    "id": "my-plugin",
    "name": "My Awesome Plugin",
    "version": "v1.0.0",
    "description": "A sample plugin for demonstration",
    "author": "Your Name",
    "icon": "🔧"
  },
  "frontend": {
    "entry": "frontend/dist/index.html",
    "build_dir": "frontend/dist"
  },
  "permissions": [
    "storage.local"
  ],
  "config": {
    "api_key": {
      "type": "string",
      "required": false,
      "description": "Optional API key"
    }
  }
}
EOF

# Create releases directory
mkdir -p releases/v1.0.0

# Use the publishing script
cd ..
./scripts/publish-plugin.sh my-plugin v1.0.0
```

#### Method 2: Automated Publishing

Use the GitHub Actions workflow:

1. Go to "Actions" tab in your repository
2. Click "Publish Plugin to Registry"
3. Click "Run workflow"
4. Fill in:
   - Plugin name: `my-plugin`
   - Plugin version: `v1.0.0`
   - Plugin repository: `https://github.com/yourusername/my-plugin`
   - Channel: `stable`
5. Click "Run workflow"

### Step 4: Verify Setup

```bash
# Check registry health
./scripts/registry-cli.sh health

# List plugins
./scripts/registry-cli.sh plugin list

# Validate everything
./scripts/registry-cli.sh validate all

# Test the API endpoints
curl https://yourusername.github.io/your-registry/registry.yml
curl https://yourusername.github.io/your-registry/api/plugins.json
```

## 🔧 Configuration Options

### Custom Domain Setup

1. **Add CNAME file:**
```bash
echo "plugins.yourdomain.com" > CNAME
git add CNAME
git commit -m "Add custom domain"
git push
```

2. **Configure DNS:**
```
CNAME plugins.yourdomain.com yourusername.github.io
```

3. **Update registry URLs:**
```yaml
# registry.yml
api:
  base_url: "https://plugins.yourdomain.com"
```

### CDN Integration

For better performance, use a CDN:

```yaml
# Update host configurations to use CDN
registries:
  - name: your-registry
    url: https://cdn.jsdelivr.net/gh/yourusername/your-registry@main
    enabled: true
```

### Private Registry

For private plugins:

1. **Make repository private**
2. **Use GitHub tokens for access:**

```yaml
# In Delve host-config.yml
auth:
  github_token_env: GITHUB_TOKEN
  registry_tokens:
    private: "${PRIVATE_REGISTRY_TOKEN}"
```

## 🛠️ Development Workflow

### Local Development

```bash
# Start development server
./scripts/registry-cli.sh serve 8080

# Your registry will be available at:
# http://localhost:8080

# Test API endpoints:
# http://localhost:8080/registry.yml
# http://localhost:8080/api/plugins.json
```

### Adding Plugins

```bash
# Method 1: Use CLI tool
./scripts/registry-cli.sh plugin add my-plugin https://github.com/user/plugin v1.0.0

# Method 2: Use publishing script
./scripts/publish-plugin.sh my-plugin v1.0.0 --plugin-dir /path/to/plugin

# Method 3: Use GitHub Actions workflow (see above)
```

### Validation and Testing

```bash
# Validate all components
./scripts/registry-cli.sh validate all

# Specific validations
./scripts/registry-cli.sh validate metadata
./scripts/registry-cli.sh validate api
./scripts/registry-cli.sh validate plugins

# Build API endpoints
./scripts/registry-cli.sh build

# Check health
./scripts/registry-cli.sh health
```

## 📊 Monitoring and Maintenance

### Registry Statistics

```bash
# View registry stats
./scripts/registry-cli.sh stats

# List all plugins
./scripts/registry-cli.sh plugin list

# Get plugin info
./scripts/registry-cli.sh plugin info my-plugin
```

### Automated Maintenance

The GitHub Actions workflows handle:
- ✅ Automatic validation on every push
- ✅ API endpoint generation
- ✅ GitHub Pages deployment
- ✅ Plugin publishing automation

### Manual Maintenance Tasks

1. **Update plugin metadata** when new versions are released
2. **Clean up old releases** if storage becomes an issue
3. **Update documentation** and examples
4. **Review and approve** plugin submissions

## 🔒 Security Best Practices

### Repository Security

1. **Enable branch protection:**
   - Require pull request reviews
   - Require status checks to pass
   - Require branches to be up to date

2. **Use secrets for sensitive data:**
   - GitHub tokens
   - API keys
   - Deployment credentials

3. **Regular security audits:**
   - Review plugin submissions
   - Check for malicious content
   - Validate checksums

### Content Security

1. **Plugin validation:**
   - Verify plugin.json schema
   - Check for required fields
   - Validate version formats

2. **Checksum verification:**
   - All plugin assets include SHA256 checksums
   - Automatic verification during download

3. **Trusted publishers:**
   - Maintain list of verified plugin authors
   - Review new publisher requests

## 🎯 Production Deployment

### Performance Optimization

1. **Enable compression** in GitHub Pages
2. **Use CDN** for global distribution
3. **Optimize file sizes** by minifying JSON
4. **Set proper cache headers**

### Scalability Considerations

1. **Plugin organization:**
   - Use categories and tags effectively
   - Maintain clear naming conventions
   - Archive old versions when appropriate

2. **API design:**
   - Keep plugin catalog lightweight
   - Use detailed endpoints for full information
   - Implement pagination if needed

3. **Storage management:**
   - Monitor repository size
   - Use Git LFS for large binaries if needed
   - Consider external asset hosting for very large files

## 🆘 Troubleshooting

### Common Issues

**1. GitHub Pages not updating:**
```bash
# Check Actions tab for deployment status
# Force rebuild by making a small commit
echo "# Updated $(date)" >> README.md
git add README.md
git commit -m "Force rebuild"
git push
```

**2. API endpoints not working:**
```bash
# Rebuild API endpoints
./scripts/registry-cli.sh build
git add api/
git commit -m "Rebuild API endpoints"
git push
```

**3. Plugin validation errors:**
```bash
# Validate specific plugin
./scripts/registry-cli.sh plugin validate my-plugin

# Check plugin.json format
jq . my-plugin/plugin.json
```

**4. Registry health check fails:**
```bash
# Run comprehensive health check
./scripts/registry-cli.sh health

# Validate all components
./scripts/registry-cli.sh validate all
```

### Getting Help

1. **Check the logs** in GitHub Actions
2. **Validate your configuration** using the CLI tools
3. **Review the documentation** in this repository
4. **Open an issue** if you find bugs or need features

## 🎉 Next Steps

After setup is complete:

1. **Add your registry to Delve:**
   ```yaml
   # host-config.yml
   registries:
     - name: my-registry
       url: https://yourusername.github.io/your-registry
       enabled: true
   ```

2. **Test plugin installation:**
   ```bash
   delve plugin discover
   delve plugin install my-plugin
   ```

3. **Share your registry:**
   - Document the registry URL
   - Create submission guidelines
   - Promote to the community

4. **Monitor and maintain:**
   - Watch GitHub repository for issues
   - Update plugins as needed
   - Add new features and categories

## 📚 Additional Resources

- [HOSTING.md](HOSTING.md) - Detailed hosting options
- [README.md](README.md) - Registry overview and usage
- [MIGRATION.md](../delve/MIGRATION.md) - Migration from old system
- [API Documentation](api/) - Registry API reference
- [Example Plugins](examples/) - Sample plugin structures

---

Your Delve Plugin Registry is now ready for production use! 🚀