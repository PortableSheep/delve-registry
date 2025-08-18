# Delve Plugin Registry

A centralized registry for Delve plugins that provides plugin discovery and distribution. This registry follows the separation of concerns principle - it handles **plugin metadata and distribution only**, while host applications manage user preferences and local configuration.

## 🎯 Core Concept

**Registry Responsibility**: "Here are the available plugins and how to get them"  
**Host Responsibility**: "Here are my preferences and what I have installed"

```
┌─────────────────┐    Queries     ┌─────────────────┐
│   Delve Host    │ ─────────────> │ Plugin Registry │
│                 │                │                 │
│ • User prefs    │                │ • Plugin catalog│
│ • Installed     │                │ • Versions      │
│ • Enabled/      │                │ • Download URLs │
│   Disabled      │                │ • Checksums     │
│ • Auto-update   │                │ • Metadata      │
└─────────────────┘                └─────────────────┘
```

## 📁 Structure

```
delve-registry/
├── registry.yml                    # 📋 Main plugin catalog (source of truth)
├── api/
│   ├── plugins.json                # 🔍 Generated plugin list for discovery
│   └── plugins/{id}                # 📊 Individual plugin details
├── {plugin-name}/                  # 📦 Plugin assets and metadata
│   ├── plugin.json                 # Plugin metadata
│   ├── releases/v1.0.0/           # Version-specific assets
│   │   ├── plugin-darwin-amd64     # Platform binaries
│   │   ├── plugin-linux-amd64
│   │   └── checksums.txt           # Asset verification
│   └── frontend/                   # UI components (if any)
└── scripts/
    └── publish-plugin.sh           # 🚀 Plugin publishing automation
```

## 🔍 What's In This Registry

### ✅ Registry Contains (Plugin Distribution)
- Plugin metadata (name, description, author, license)
- Available versions and compatibility info
- Download URLs and checksums
- Platform-specific binaries
- Plugin categorization and tags

### ❌ Registry Does NOT Contain (Host Configuration)
- User's installed plugins list
- Enabled/disabled state per user
- User's auto-update preferences
- User's authentication tokens
- Host-specific cache settings

## 🏠 Host Configuration

Host configuration belongs in the **main Delve project**, not this registry. Example:

```yaml
# In your Delve installation: host-config.yml
installed_plugins:
  json-linter-formatter:
    version: "v1.0.0"
    enabled: true
    auto_update: true

settings:
  auto_check_updates: true
  cache_directory: "./plugin_cache"
  
registries:
  - name: "official"
    url: "https://raw.githubusercontent.com/PortableSheep/delve-registry/main"
```

## 🔌 Adding a Plugin

### 1. Prepare Your Plugin
```bash
my-plugin/
├── main.go              # Plugin implementation
├── plugin.json          # Plugin metadata
├── frontend/            # UI files (optional)
└── go.mod              # Go dependencies
```

### 2. Plugin Metadata Example
```json
{
  "info": {
    "id": "my-plugin",
    "name": "My Awesome Plugin",
    "version": "1.0.0",
    "description": "Does amazing things",
    "author": "Your Name",
    "license": "MIT",
    "icon": "🚀"
  },
  "frontend": {
    "entry": "frontend/dist/index.html"
  },
  "permissions": ["network.http"]
}
```

### 3. Publish Using Script
```bash
./scripts/publish-plugin.sh my-plugin v1.0.0
```

### 4. Update Registry
The script automatically:
- Builds binaries for all platforms
- Generates checksums
- Updates `registry.yml`
- Updates API files

## 📡 API Endpoints

| Endpoint | Purpose | Example |
|----------|---------|---------|
| `/registry.yml` | Registry metadata | Categories, channels, API info |
| `/api/plugins.json` | Plugin discovery | List all available plugins |
| `/api/plugins/{id}` | Plugin details | Specific plugin information |
| `/{plugin}/plugin.json` | Plugin metadata | Original plugin metadata |
| `/{plugin}/releases/{version}/{asset}` | Asset download | Binaries, frontend files |

### Discovery Flow
```bash
# 1. Get plugin list
curl .../api/plugins.json

# 2. Get plugin details  
curl .../api/plugins/json-linter-formatter

# 3. Download plugin binary
curl .../json-linter-formatter/releases/v1.0.0/plugin-darwin-amd64
```

## 🏷️ Plugin Organization

### Categories
- **data-tools**: Data manipulation and formatting
- **development-tools**: Software development utilities  
- **monitoring**: System and application monitoring
- **utilities**: General purpose tools

### Channels
- **stable**: Production-ready releases (default)
- **beta**: Testing releases with new features
- **development**: Latest development builds

## 🔐 Security

- **Checksums**: SHA256 verification for all assets
- **Trusted Publishers**: Registry maintains list of verified authors
- **Host Verification**: Host apps verify checksums before installation

## 🚀 Publishing Workflow

```bash
# Build and publish
./scripts/publish-plugin.sh my-plugin v1.2.0

# With options
./scripts/publish-plugin.sh my-plugin v1.2.0 \
  --channel beta \
  --plugin-dir /path/to/plugin \
  --force
```

## 📊 Versioning

All plugins use semantic versioning:
- `v1.0.0` - Stable release
- `v1.1.0-beta.1` - Beta release
- `v1.2.0-dev.20240115` - Development build

Each version declares Delve compatibility:
```yaml
compatibility: ["v0.1.0", "v0.2.0", "v0.3.0"]
```

## 🤝 Contributing

1. **Fork** this repository
2. **Add** your plugin directory with proper structure
3. **Test** using the publish script
4. **Submit** a pull request

## 📚 Examples

See existing plugins:
- `json-linter-formatter/` - Data formatting tool
- `github-dashboard/` - Development monitoring
- `sample_plugin/` - Basic plugin template

## 🔗 Related

- **[Delve](../delve/)** - Main application
- **[Delve SDK](../delve_sdk/)** - Plugin development framework

## 📄 License

MIT License - see individual plugins for their specific licenses.

---

**Remember**: This registry only handles plugin discovery and distribution. User preferences and local configuration are managed by the host application (Delve).