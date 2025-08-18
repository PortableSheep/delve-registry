# Hosting the Delve Plugin Registry

This guide explains how to host your Delve Plugin Registry using various hosting options, with GitHub Pages being the recommended approach for most users.

## 🌐 Hosting Options Overview

| Option | Cost | Setup Complexity | Performance | Best For |
|--------|------|------------------|-------------|----------|
| **GitHub Pages** | Free | Easy | Good | Open source registries |
| **GitHub + CDN** | Low | Medium | Excellent | High-traffic registries |
| **Self-hosted** | Variable | High | Variable | Private/enterprise use |
| **Static Hosting** | Low-Medium | Medium | Good | Custom domains |

## 🚀 Option 1: GitHub Pages (Recommended)

GitHub Pages provides free static hosting perfect for plugin registries.

### Setup Steps

1. **Enable GitHub Pages**
   ```bash
   # In your repository settings
   Settings → Pages → Source: Deploy from a branch
   Branch: main / (root)
   ```

2. **Your registry will be available at:**
   ```
   https://yourusername.github.io/delve-registry/
   ```

3. **Update host configurations to use the new URL:**
   ```yaml
   # In host-config.yml
   registries:
     - name: official
       url: https://yourusername.github.io/delve-registry
       enabled: true
   ```

4. **Test the endpoints:**
   ```bash
   curl https://yourusername.github.io/delve-registry/registry.yml
   curl https://yourusername.github.io/delve-registry/api/plugins.json
   ```

### GitHub Pages Configuration

Create `.github/workflows/pages.yml`:
```yaml
name: Deploy Registry to Pages

on:
  push:
    branches: [ main ]
  workflow_dispatch:

permissions:
  contents: read
  pages: write
  id-token: write

concurrency:
  group: "pages"
  cancel-in-progress: false

jobs:
  deploy:
    environment:
      name: github-pages
      url: ${{ steps.deployment.outputs.page_url }}
    runs-on: ubuntu-latest
    steps:
      - name: Checkout
        uses: actions/checkout@v4

      - name: Setup Pages
        uses: actions/configure-pages@v4

      - name: Upload artifact
        uses: actions/upload-pages-artifact@v2
        with:
          path: '.'

      - name: Deploy to GitHub Pages
        id: deployment
        uses: actions/deploy-pages@v3
```

### Custom Domain (Optional)

1. **Add CNAME file:**
   ```bash
   echo "plugins.your-domain.com" > CNAME
   ```

2. **Configure DNS:**
   ```
   CNAME plugins.your-domain.com yourusername.github.io
   ```

3. **Update registry URLs:**
   ```yaml
   registries:
     - name: official
       url: https://plugins.your-domain.com
   ```

## 🔥 Option 2: GitHub + CDN (High Performance)

For better global performance, add a CDN layer.

### Using jsDelivr (Free)

jsDelivr automatically serves GitHub content via CDN:

```yaml
# host-config.yml
registries:
  - name: official
    url: https://cdn.jsdelivr.net/gh/yourusername/delve-registry@main
    enabled: true
```

**Benefits:**
- Global CDN with edge caching
- Automatic HTTPS
- Version pinning support
- No additional setup required

### Using Cloudflare (Free/Paid)

1. **Set up Cloudflare proxy:**
   ```
   plugins.your-domain.com → CNAME → yourusername.github.io
   ```

2. **Configure caching rules:**
   ```
   Cache Level: Standard
   Browser Cache TTL: 4 hours
   Edge Cache TTL: 2 hours
   ```

3. **Add cache headers (optional):**
   ```yaml
   # _headers file for Netlify-style hosting
   /api/*
     Cache-Control: public, max-age=3600
   /*.yml
     Cache-Control: public, max-age=7200
   /*/releases/*
     Cache-Control: public, max-age=86400
   ```

## 🏢 Option 3: Self-Hosted (Enterprise)

For private registries or custom requirements.

### Using Docker + Nginx

Create `docker-compose.yml`:
```yaml
version: '3.8'
services:
  registry:
    image: nginx:alpine
    ports:
      - "80:80"
      - "443:443"
    volumes:
      - ./:/usr/share/nginx/html:ro
      - ./nginx.conf:/etc/nginx/nginx.conf:ro
      - ./ssl:/etc/nginx/ssl:ro
    restart: unless-stopped

  # Optional: Add basic auth
  auth:
    image: nginx:alpine
    volumes:
      - ./auth/nginx.conf:/etc/nginx/nginx.conf:ro
      - ./auth/.htpasswd:/etc/nginx/.htpasswd:ro
```

Create `nginx.conf`:
```nginx
events {
    worker_connections 1024;
}

http {
    include /etc/nginx/mime.types;
    default_type application/octet-stream;

    # Enable gzip compression
    gzip on;
    gzip_types text/plain application/json application/yaml text/css application/javascript;

    # CORS headers for API endpoints
    add_header 'Access-Control-Allow-Origin' '*' always;
    add_header 'Access-Control-Allow-Methods' 'GET, OPTIONS' always;
    add_header 'Access-Control-Allow-Headers' 'Authorization, Content-Type' always;

    server {
        listen 80;
        server_name your-registry.com;
        root /usr/share/nginx/html;
        index index.html;

        # API endpoints
        location /api/ {
            add_header 'Content-Type' 'application/json' always;
            try_files $uri $uri.json =404;
        }

        # Registry metadata
        location ~ \.(yml|yaml)$ {
            add_header 'Content-Type' 'application/yaml' always;
        }

        # Plugin releases
        location /*/releases/ {
            add_header 'Content-Type' 'application/octet-stream' always;
            # Cache plugin binaries for longer
            expires 1d;
        }

        # Health check
        location /health {
            return 200 'OK';
            add_header Content-Type text/plain;
        }
    }
}
```

### Deployment Script

Create `deploy.sh`:
```bash
#!/bin/bash
set -e

echo "🚀 Deploying Delve Plugin Registry..."

# Build and validate registry
echo "📋 Validating registry metadata..."
if command -v yq &> /dev/null; then
    yq eval registry.yml > /dev/null
    echo "✅ Registry YAML is valid"
fi

if command -v jq &> /dev/null; then
    jq . api/plugins.json > /dev/null
    echo "✅ Plugin catalog JSON is valid"
fi

# Deploy via rsync or docker
if [ "$DEPLOY_METHOD" = "rsync" ]; then
    echo "📦 Deploying via rsync..."
    rsync -avz --delete ./ ${DEPLOY_USER}@${DEPLOY_HOST}:${DEPLOY_PATH}/
elif [ "$DEPLOY_METHOD" = "docker" ]; then
    echo "🐳 Deploying via Docker..."
    docker-compose down
    docker-compose up -d
    docker-compose ps
fi

echo "✅ Deployment complete!"
echo "🌐 Registry available at: ${REGISTRY_URL}"

# Test endpoints
echo "🧪 Testing endpoints..."
curl -s ${REGISTRY_URL}/health
curl -s ${REGISTRY_URL}/registry.yml > /dev/null
curl -s ${REGISTRY_URL}/api/plugins.json > /dev/null
echo "✅ All endpoints responding"
```

## ☁️ Option 4: Static Hosting Services

### Netlify
1. Connect your GitHub repository
2. Build command: (none needed)
3. Publish directory: `/`
4. Deploy automatically on push

### Vercel
1. Import GitHub repository
2. Framework preset: Other
3. Build command: (none)
4. Output directory: `./`

### AWS S3 + CloudFront
```bash
# Upload to S3
aws s3 sync . s3://your-registry-bucket/ --delete

# Invalidate CloudFront cache
aws cloudfront create-invalidation --distribution-id YOUR_DIST_ID --paths "/*"
```

## 🔐 Private Registry Setup

For enterprise or private use:

### GitHub with Personal Access Token
```yaml
# host-config.yml
registries:
  - name: private
    url: https://raw.githubusercontent.com/yourorg/private-registry/main
    enabled: true

auth:
  github_token_env: GITHUB_TOKEN
```

### Basic Authentication
```nginx
# nginx.conf
location / {
    auth_basic "Registry Access";
    auth_basic_user_file /etc/nginx/.htpasswd;
}
```

```bash
# Create password file
htpasswd -c .htpasswd username
```

### API Key Authentication
```yaml
# host-config.yml
auth:
  registry_tokens:
    private: "${PRIVATE_REGISTRY_TOKEN}"
```

## 📊 Monitoring and Analytics

### GitHub Repository Insights
- Traffic analytics in repository insights
- Release download statistics
- API request patterns

### Custom Analytics
```html
<!-- Add to index.html -->
<script async src="https://www.googletagmanager.com/gtag/js?id=GA_MEASUREMENT_ID"></script>
<script>
  window.dataLayer = window.dataLayer || [];
  function gtag(){dataLayer.push(arguments);}
  gtag('js', new Date());
  gtag('config', 'GA_MEASUREMENT_ID');
</script>
```

### Monitoring Script
```bash
#!/bin/bash
# monitor.sh - Check registry health

REGISTRY_URL="https://your-registry.com"

# Test endpoints
endpoints=(
    "/health"
    "/registry.yml"
    "/api/plugins.json"
)

for endpoint in "${endpoints[@]}"; do
    if curl -sf "${REGISTRY_URL}${endpoint}" > /dev/null; then
        echo "✅ ${endpoint} - OK"
    else
        echo "❌ ${endpoint} - FAILED"
        # Send alert (Slack, email, etc.)
    fi
done
```

## 🚀 CI/CD Integration

### GitHub Actions for Plugin Publishing
```yaml
# .github/workflows/publish-plugin.yml
name: Publish Plugin
on:
  release:
    types: [published]

jobs:
  publish:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Extract plugin info
        id: plugin
        run: |
          echo "name=${GITHUB_REPOSITORY##*/}" >> $GITHUB_OUTPUT
          echo "version=${GITHUB_REF#refs/tags/}" >> $GITHUB_OUTPUT

      - name: Build plugin
        run: |
          chmod +x scripts/publish-plugin.sh
          ./scripts/publish-plugin.sh ${{ steps.plugin.outputs.name }} ${{ steps.plugin.outputs.version }}

      - name: Update registry
        run: |
          # Auto-update registry metadata
          python scripts/update-registry.py ${{ steps.plugin.outputs.name }} ${{ steps.plugin.outputs.version }}

      - name: Commit changes
        run: |
          git config --local user.email "action@github.com"
          git config --local user.name "GitHub Action"
          git add .
          git commit -m "Add ${{ steps.plugin.outputs.name }} ${{ steps.plugin.outputs.version }}" || exit 0
          git push
```

## 📈 Performance Optimization

### Content Delivery
1. **Enable compression** for YAML/JSON files
2. **Set proper cache headers** for different content types
3. **Use CDN** for global distribution
4. **Optimize file sizes** by minifying JSON where possible

### Caching Strategy
```
Registry metadata (registry.yml): 2 hours
Plugin catalog (api/plugins.json): 1 hour
Plugin details: 6 hours
Plugin binaries: 24 hours
```

### Load Testing
```bash
# Test registry performance
ab -n 1000 -c 10 https://your-registry.com/api/plugins.json
wrk -t12 -c400 -d30s https://your-registry.com/registry.yml
```

## 🔧 Maintenance

### Regular Tasks
1. **Update plugin metadata** when new versions are released
2. **Validate YAML/JSON** files in CI/CD
3. **Monitor download statistics** and usage patterns
4. **Clean up old releases** if storage becomes an issue
5. **Update documentation** and examples

### Backup Strategy
```bash
# Backup script
#!/bin/bash
DATE=$(date +%Y%m%d)
tar -czf "registry-backup-${DATE}.tar.gz" \
    registry.yml \
    api/ \
    */plugin.json \
    */releases/

# Upload to backup location
aws s3 cp "registry-backup-${DATE}.tar.gz" s3://your-backup-bucket/
```

## 🎯 Recommended Setup

For most users, we recommend:

1. **Start with GitHub Pages** (free, simple)
2. **Add jsDelivr CDN** for better performance
3. **Set up custom domain** for branding
4. **Implement CI/CD** for automated publishing
5. **Add monitoring** for health checks

This provides a robust, scalable, and cost-effective registry hosting solution that can grow with your plugin ecosystem.
