#!/bin/bash

# Delve Registry Management CLI
# A comprehensive tool for managing the Delve plugin registry

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REGISTRY_DIR="$(dirname "$SCRIPT_DIR")"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_header() {
    echo -e "${PURPLE}[REGISTRY]${NC} $1"
}

# Function to show usage
show_usage() {
    cat << 'EOF'
Delve Registry Management CLI

Usage: ./registry-cli.sh <command> [options]

Commands:
    init                Initialize a new registry
    validate            Validate registry files
    add <plugin>        Add a plugin to the registry
    remove <plugin>     Remove a plugin from the registry
    list                List all plugins in the registry
    stats               Show registry statistics
    build               Build API endpoints from registry data
    serve               Start local development server
    deploy              Deploy registry to hosting
    backup              Create registry backup
    restore <backup>    Restore from backup
    health              Check registry health

Plugin Commands:
    plugin list                     List all plugins
    plugin info <name>              Show plugin details
    plugin add <name> <repo> <ver>  Add new plugin
    plugin update <name> <ver>      Update plugin version
    plugin remove <name>            Remove plugin
    plugin validate <name>          Validate plugin

Validation Commands:
    validate all                    Validate entire registry
    validate metadata               Validate registry.yml
    validate api                    Validate API endpoints
    validate plugins                Validate all plugins

Development Commands:
    dev init                        Initialize development environment
    dev serve [port]                Start development server
    dev watch                       Watch for changes and rebuild
    dev test                        Run tests

Deployment Commands:
    deploy github                   Deploy to GitHub Pages
    deploy check                    Check deployment status
    deploy rollback                 Rollback deployment

Options:
    -h, --help                      Show this help message
    -v, --verbose                   Verbose output
    -q, --quiet                     Quiet mode
    -f, --force                     Force operation
    --dry-run                       Show what would be done

Examples:
    ./registry-cli.sh init
    ./registry-cli.sh plugin add json-formatter https://github.com/user/plugin v1.0.0
    ./registry-cli.sh validate all
    ./registry-cli.sh dev serve 8080
    ./registry-cli.sh deploy github

EOF
}

# Global variables
VERBOSE=false
QUIET=false
FORCE=false
DRY_RUN=false

# Parse global options
parse_global_options() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            -h|--help)
                show_usage
                exit 0
                ;;
            -v|--verbose)
                VERBOSE=true
                shift
                ;;
            -q|--quiet)
                QUIET=true
                shift
                ;;
            -f|--force)
                FORCE=true
                shift
                ;;
            --dry-run)
                DRY_RUN=true
                shift
                ;;
            -*)
                print_error "Unknown option: $1"
                exit 1
                ;;
            *)
                break
                ;;
        esac
    done

    # Export remaining arguments
    ARGS=("$@")
}

# Utility functions
log_verbose() {
    if [ "$VERBOSE" = true ]; then
        print_status "$1"
    fi
}

log_quiet() {
    if [ "$QUIET" = false ]; then
        echo "$1"
    fi
}

check_dependencies() {
    local deps=("jq" "yq" "curl")
    local missing=()

    for dep in "${deps[@]}"; do
        if ! command -v "$dep" &> /dev/null; then
            missing+=("$dep")
        fi
    done

    if [ ${#missing[@]} -gt 0 ]; then
        print_error "Missing dependencies: ${missing[*]}"
        print_status "Please install: ${missing[*]}"
        exit 1
    fi
}

# Registry initialization
cmd_init() {
    print_header "Initializing new registry..."

    if [ -f "$REGISTRY_DIR/registry.yml" ] && [ "$FORCE" != true ]; then
        print_error "Registry already exists. Use --force to overwrite."
        exit 1
    fi

    if [ "$DRY_RUN" = true ]; then
        print_status "DRY RUN: Would create registry structure"
        return 0
    fi

    # Create directory structure
    mkdir -p "$REGISTRY_DIR"/{api/plugins,scripts,examples}
    log_verbose "Created directory structure"

    # Create registry.yml
    cat > "$REGISTRY_DIR/registry.yml" << 'EOF'
registry:
  name: "Delve Plugin Registry"
  description: "Central registry for Delve plugins"
  maintainer: "registry-maintainer"
  url: "https://github.com/user/delve-registry"
  api_version: "v1"
  last_updated: ""

plugins: {}

channels:
  stable:
    description: "Stable, production-ready releases"
    include_prerelease: false
    default: true
  beta:
    description: "Beta releases for testing"
    include_prerelease: true
  development:
    description: "Latest development builds"
    include_prerelease: true

categories:
  data-tools:
    name: "Data Tools"
    description: "Plugins for data manipulation, formatting, and analysis"
  development-tools:
    name: "Development Tools"
    description: "Plugins for software development workflows"
  monitoring:
    name: "Monitoring & Analytics"
    description: "Plugins for monitoring systems and analyzing metrics"
  utilities:
    name: "Utilities"
    description: "General purpose utility plugins"

api:
  base_url: "https://user.github.io/delve-registry"
  endpoints:
    registry_metadata: "/registry.yml"
    plugin_list: "/api/plugins.json"
    plugin_details: "/api/plugins/{plugin_id}"
    download_asset: "/{plugin_id}/releases/{version}/{asset_name}"

stats:
  total_plugins: 0
  total_versions: 0
  total_downloads: 0
  most_popular: []
EOF

    # Update timestamp
    current_time=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
    yq eval ".registry.last_updated = \"$current_time\"" -i "$REGISTRY_DIR/registry.yml"

    # Create initial API endpoint
    cat > "$REGISTRY_DIR/api/plugins.json" << EOF
{
  "api_version": "v1",
  "generated_at": "$current_time",
  "total_plugins": 0,
  "plugins": [],
  "categories": [
    {
      "id": "data-tools",
      "name": "Data Tools",
      "description": "Plugins for data manipulation, formatting, and analysis",
      "plugin_count": 0
    },
    {
      "id": "development-tools",
      "name": "Development Tools",
      "description": "Plugins for software development workflows",
      "plugin_count": 0
    },
    {
      "id": "monitoring",
      "name": "Monitoring & Analytics",
      "description": "Plugins for monitoring systems and analyzing metrics",
      "plugin_count": 0
    },
    {
      "id": "utilities",
      "name": "Utilities",
      "description": "General purpose utility plugins",
      "plugin_count": 0
    }
  ],
  "filters": {
    "categories": ["data-tools", "development-tools", "monitoring", "utilities"],
    "licenses": ["MIT", "Apache-2.0", "GPL-3.0"],
    "platforms": ["darwin-amd64", "darwin-arm64", "linux-amd64", "linux-arm64", "windows-amd64"],
    "channels": ["stable", "beta", "development"]
  }
}
EOF

    # Create README
    cat > "$REGISTRY_DIR/README.md" << 'EOF'
# Delve Plugin Registry

This registry contains plugins for the Delve application.

## Usage

Add this registry to your Delve configuration:

```yaml
registries:
  - name: my-registry
    url: https://your-username.github.io/delve-registry
    enabled: true
```

## API Endpoints

- `/registry.yml` - Registry metadata
- `/api/plugins.json` - Plugin catalog
- `/api/plugins/{id}` - Plugin details

## Contributing

See CONTRIBUTING.md for guidelines on adding plugins.
EOF

    print_success "Registry initialized successfully!"
    print_status "Next steps:"
    print_status "1. Update registry.yml with your information"
    print_status "2. Add plugins with: ./registry-cli.sh plugin add"
    print_status "3. Deploy with: ./registry-cli.sh deploy github"
}

# Validation functions
cmd_validate() {
    local target="${1:-all}"

    case "$target" in
        all)
            validate_metadata
            validate_api
            validate_plugins
            ;;
        metadata)
            validate_metadata
            ;;
        api)
            validate_api
            ;;
        plugins)
            validate_plugins
            ;;
        *)
            print_error "Unknown validation target: $target"
            print_status "Valid targets: all, metadata, api, plugins"
            exit 1
            ;;
    esac
}

validate_metadata() {
    print_header "Validating registry metadata..."

    if [ ! -f "$REGISTRY_DIR/registry.yml" ]; then
        print_error "registry.yml not found"
        return 1
    fi

    if ! yq eval . "$REGISTRY_DIR/registry.yml" > /dev/null; then
        print_error "Invalid YAML in registry.yml"
        return 1
    fi

    # Check required fields
    local required_fields=(
        ".registry.name"
        ".registry.api_version"
        ".plugins"
        ".channels"
    )

    for field in "${required_fields[@]}"; do
        if ! yq eval "$field" "$REGISTRY_DIR/registry.yml" > /dev/null 2>&1; then
            print_error "Missing required field: $field"
            return 1
        fi
    done

    print_success "Registry metadata is valid"
}

validate_api() {
    print_header "Validating API endpoints..."

    if [ ! -f "$REGISTRY_DIR/api/plugins.json" ]; then
        print_error "api/plugins.json not found"
        return 1
    fi

    if ! jq . "$REGISTRY_DIR/api/plugins.json" > /dev/null; then
        print_error "Invalid JSON in api/plugins.json"
        return 1
    fi

    # Validate individual plugin API files
    local errors=0
    if [ -d "$REGISTRY_DIR/api/plugins" ]; then
        for plugin_file in "$REGISTRY_DIR/api/plugins"/*; do
            if [ -f "$plugin_file" ]; then
                if ! jq . "$plugin_file" > /dev/null 2>&1; then
                    print_error "Invalid JSON in $(basename "$plugin_file")"
                    ((errors++))
                fi
            fi
        done
    fi

    if [ $errors -eq 0 ]; then
        print_success "API endpoints are valid"
    else
        print_error "$errors API files have errors"
        return 1
    fi
}

validate_plugins() {
    print_header "Validating plugins..."

    local errors=0
    local plugin_count=0

    for plugin_dir in "$REGISTRY_DIR"/*/; do
        if [[ "$(basename "$plugin_dir")" == "api" ]] || [[ "$(basename "$plugin_dir")" == "scripts" ]] || [[ "$(basename "$plugin_dir")" == "examples" ]]; then
            continue
        fi

        if [ -d "$plugin_dir" ]; then
            plugin_name=$(basename "$plugin_dir")
            log_verbose "Validating plugin: $plugin_name"

            # Check for plugin.json
            if [ ! -f "$plugin_dir/plugin.json" ]; then
                print_warning "Plugin $plugin_name missing plugin.json"
                ((errors++))
                continue
            fi

            # Validate plugin.json
            if ! jq . "$plugin_dir/plugin.json" > /dev/null 2>&1; then
                print_error "Invalid JSON in $plugin_name/plugin.json"
                ((errors++))
                continue
            fi

            # Check required fields in plugin.json
            local required=(".info.id" ".info.name" ".info.version")
            for field in "${required[@]}"; do
                if ! jq -e "$field" "$plugin_dir/plugin.json" > /dev/null 2>&1; then
                    print_error "Plugin $plugin_name missing required field: $field"
                    ((errors++))
                fi
            done

            ((plugin_count++))
        fi
    done

    if [ $errors -eq 0 ]; then
        print_success "All $plugin_count plugins are valid"
    else
        print_error "$errors validation errors found"
        return 1
    fi
}

# Plugin management
cmd_plugin() {
    local subcmd="$1"
    shift

    case "$subcmd" in
        list)
            plugin_list
            ;;
        info)
            plugin_info "$1"
            ;;
        add)
            plugin_add "$1" "$2" "$3"
            ;;
        update)
            plugin_update "$1" "$2"
            ;;
        remove)
            plugin_remove "$1"
            ;;
        validate)
            plugin_validate "$1"
            ;;
        *)
            print_error "Unknown plugin command: $subcmd"
            print_status "Valid commands: list, info, add, update, remove, validate"
            exit 1
            ;;
    esac
}

plugin_list() {
    print_header "Registry plugins:"
    echo ""

    if [ ! -f "$REGISTRY_DIR/registry.yml" ]; then
        print_error "Registry not found. Run 'init' first."
        return 1
    fi

    # Read plugins from registry.yml
    local plugin_count=0
    printf "%-25s %-15s %-50s %-15s\n" "NAME" "VERSION" "DESCRIPTION" "AUTHOR"
    printf "%-25s %-15s %-50s %-15s\n" "----" "-------" "-----------" "------"

    yq eval '.plugins | keys | .[]' "$REGISTRY_DIR/registry.yml" | while read -r plugin_id; do
        if [ "$plugin_id" != "null" ]; then
            name=$(yq eval ".plugins.\"$plugin_id\".name" "$REGISTRY_DIR/registry.yml")
            description=$(yq eval ".plugins.\"$plugin_id\".description" "$REGISTRY_DIR/registry.yml")
            author=$(yq eval ".plugins.\"$plugin_id\".author" "$REGISTRY_DIR/registry.yml")

            # Get latest version
            version=$(yq eval ".plugins.\"$plugin_id\".versions[0].version" "$REGISTRY_DIR/registry.yml" 2>/dev/null || echo "unknown")

            printf "%-25s %-15s %-50s %-15s\n" "$name" "$version" "$description" "$author"
            ((plugin_count++))
        fi
    done

    echo ""
    print_status "Total plugins: $plugin_count"
}

plugin_info() {
    local plugin_name="$1"

    if [ -z "$plugin_name" ]; then
        print_error "Plugin name required"
        return 1
    fi

    print_header "Plugin information: $plugin_name"

    if [ ! -f "$REGISTRY_DIR/$plugin_name/plugin.json" ]; then
        print_error "Plugin $plugin_name not found"
        return 1
    fi

    # Display plugin information
    echo "ID:          $(jq -r '.info.id' "$REGISTRY_DIR/$plugin_name/plugin.json")"
    echo "Name:        $(jq -r '.info.name' "$REGISTRY_DIR/$plugin_name/plugin.json")"
    echo "Version:     $(jq -r '.info.version' "$REGISTRY_DIR/$plugin_name/plugin.json")"
    echo "Description: $(jq -r '.info.description' "$REGISTRY_DIR/$plugin_name/plugin.json")"
    echo "Author:      $(jq -r '.info.author' "$REGISTRY_DIR/$plugin_name/plugin.json")"

    # Show versions from registry
    if yq eval ".plugins.\"$plugin_name\"" "$REGISTRY_DIR/registry.yml" > /dev/null 2>&1; then
        echo ""
        echo "Available versions:"
        yq eval ".plugins.\"$plugin_name\".versions[].version" "$REGISTRY_DIR/registry.yml" | while read -r version; do
            echo "  - $version"
        done
    fi

    # Show releases
    if [ -d "$REGISTRY_DIR/$plugin_name/releases" ]; then
        echo ""
        echo "Releases:"
        ls -1 "$REGISTRY_DIR/$plugin_name/releases" | while read -r release; do
            echo "  - $release"
        done
    fi
}

# Statistics
cmd_stats() {
    print_header "Registry statistics:"
    echo ""

    if [ ! -f "$REGISTRY_DIR/registry.yml" ]; then
        print_error "Registry not found"
        return 1
    fi

    # Count plugins
    local plugin_count=$(yq eval '.plugins | length' "$REGISTRY_DIR/registry.yml")
    echo "Total plugins: $plugin_count"

    # Count versions
    local version_count=0
    yq eval '.plugins | keys | .[]' "$REGISTRY_DIR/registry.yml" | while read -r plugin_id; do
        if [ "$plugin_id" != "null" ]; then
            versions=$(yq eval ".plugins.\"$plugin_id\".versions | length" "$REGISTRY_DIR/registry.yml" 2>/dev/null || echo "0")
            version_count=$((version_count + versions))
        fi
    done

    echo "Total versions: $version_count"

    # Show categories
    echo ""
    echo "Categories:"
    yq eval '.categories | keys | .[]' "$REGISTRY_DIR/registry.yml" | while read -r category; do
        if [ "$category" != "null" ]; then
            name=$(yq eval ".categories.\"$category\".name" "$REGISTRY_DIR/registry.yml")
            echo "  - $category: $name"
        fi
    done

    # Show channels
    echo ""
    echo "Channels:"
    yq eval '.channels | keys | .[]' "$REGISTRY_DIR/registry.yml" | while read -r channel; do
        if [ "$channel" != "null" ]; then
            description=$(yq eval ".channels.\"$channel\".description" "$REGISTRY_DIR/registry.yml")
            echo "  - $channel: $description"
        fi
    done
}

# Build API endpoints
cmd_build() {
    print_header "Building API endpoints..."

    if [ ! -f "$REGISTRY_DIR/registry.yml" ]; then
        print_error "Registry not found"
        return 1
    fi

    if [ "$DRY_RUN" = true ]; then
        print_status "DRY RUN: Would rebuild API endpoints"
        return 0
    fi

    # Rebuild plugins.json
    python3 << 'EOF'
import yaml
import json
from datetime import datetime
import sys
import os

registry_dir = os.environ.get('REGISTRY_DIR', '.')
registry_file = os.path.join(registry_dir, 'registry.yml')

try:
    with open(registry_file, 'r') as f:
        registry = yaml.safe_load(f)
except Exception as e:
    print(f"Error loading registry: {e}")
    sys.exit(1)

# Build plugins catalog
catalog = {
    'api_version': 'v1',
    'generated_at': datetime.utcnow().isoformat() + 'Z',
    'total_plugins': len(registry.get('plugins', {})),
    'plugins': [],
    'categories': [],
    'filters': {
        'categories': list(registry.get('categories', {}).keys()),
        'licenses': ['MIT', 'Apache-2.0', 'GPL-3.0'],
        'platforms': ['darwin-amd64', 'darwin-arm64', 'linux-amd64', 'linux-arm64', 'windows-amd64'],
        'channels': list(registry.get('channels', {}).keys())
    }
}

# Add categories
for cat_id, cat_data in registry.get('categories', {}).items():
    catalog['categories'].append({
        'id': cat_id,
        'name': cat_data.get('name', cat_id),
        'description': cat_data.get('description', ''),
        'plugin_count': 0  # Will be updated later
    })

# Add plugins
for plugin_id, plugin_data in registry.get('plugins', {}).items():
    latest_version = plugin_data.get('versions', [{}])[0] if plugin_data.get('versions') else {}

    catalog_plugin = {
        'id': plugin_id,
        'name': plugin_data.get('name', plugin_id),
        'description': plugin_data.get('description', ''),
        'author': plugin_data.get('author', ''),
        'license': plugin_data.get('license', 'MIT'),
        'category': plugin_data.get('category', 'utilities'),
        'tags': plugin_data.get('tags', []),
        'latest_version': latest_version.get('version', 'unknown'),
        'min_delve_version': plugin_data.get('min_delve_version', 'v0.1.0'),
        'repository': plugin_data.get('repository', ''),
        'homepage': plugin_data.get('homepage', plugin_data.get('repository', '')),
        'download_count': 0,
        'last_updated': latest_version.get('released', ''),
        'status': 'stable',
        'supported_platforms': list(latest_version.get('assets', {}).keys()),
        'icon': plugin_data.get('icon', '🔧'),
        'api_urls': {
            'details': f'/api/plugins/{plugin_id}',
            'versions': f'/api/plugins/{plugin_id}/versions',
            'metadata': f'/{plugin_id}/plugin.json'
        }
    }

    catalog['plugins'].append(catalog_plugin)

# Update category plugin counts
for category in catalog['categories']:
    category['plugin_count'] = len([p for p in catalog['plugins'] if p['category'] == category['id']])

# Save catalog
api_dir = os.path.join(registry_dir, 'api')
os.makedirs(api_dir, exist_ok=True)

with open(os.path.join(api_dir, 'plugins.json'), 'w') as f:
    json.dump(catalog, f, indent=2)

print("✅ API endpoints built successfully")
EOF

    print_success "API endpoints built successfully"
}

# Development server
cmd_serve() {
    local port="${1:-8080}"

    print_header "Starting development server on port $port..."

    if [ ! -f "$REGISTRY_DIR/registry.yml" ]; then
        print_error "Registry not found. Run 'init' first."
        return 1
    fi

    # Build API endpoints first
    cmd_build

    print_status "Registry available at: http://localhost:$port"
    print_status "API endpoints:"
    print_status "  - http://localhost:$port/registry.yml"
    print_status "  - http://localhost:$port/api/plugins.json"
    print_status ""
    print_status "Press Ctrl+C to stop server"

    # Start simple HTTP server
    cd "$REGISTRY_DIR"
    python3 -m http.server "$port" 2>/dev/null || python -m SimpleHTTPServer "$port"
}

# Health check
cmd_health() {
    print_header "Registry health check..."

    local errors=0

    # Check registry.yml exists and is valid
    if [ ! -f "$REGISTRY_DIR/registry.yml" ]; then
        print_error "registry.yml not found"
        ((errors++))
    elif ! yq eval . "$REGISTRY_DIR/registry.yml" > /dev/null 2>&1; then
        print_error "registry.yml is invalid"
        ((errors++))
    else
        print_success "registry.yml is valid"
    fi

    # Check API endpoints
    if [ ! -f "$REGISTRY_DIR/api/plugins.json" ]; then
        print_error "api/plugins.json not found"
        ((errors++))
    elif ! jq . "$REGISTRY_DIR/api/plugins.json" > /dev/null 2>&1; then
        print_error "api/plugins.json is invalid"
        ((errors++))
    else
        print_success "api/plugins.json is valid"
    fi

    # Check plugin directories
    local plugin_dirs=0
    for plugin_dir in "$REGISTRY_DIR"/*/; do
        if [[ "$(basename "$plugin_dir")" != "api" ]] && [[ "$(basename "$plugin_dir")" != "scripts" ]] && [[ "$(basename "$plugin_dir")" != "examples" ]]; then
            if [ -d "$plugin_dir" ]; then
                ((plugin_dirs++))
            fi
        fi
    done

    print_status "Found $plugin_dirs plugin directories"

    if [ $errors -eq 0 ]; then
        print_success "Registry health check passed"
        return 0
    else
        print_error "Health check failed with $errors errors"
        return 1
    fi
}

# Main function
main() {
    parse_global_options "$@"
    set -- "${ARGS[@]}"

    if [ $# -eq 0 ]; then
        show_usage
        exit 1
    fi

    # Check dependencies
    check_dependencies

    local command="$1"
    shift

    case "$command" in
        init)
            cmd_init "$@"
            ;;
        validate)
            cmd_validate "$@"
            ;;
        plugin)
            cmd_plugin "$@"
            ;;
        list)
            plugin_list
            ;;
        stats)
            cmd_stats
            ;;
        build)
            cmd_build
            ;;
        serve)
            cmd_serve "$@"
            ;;
        health)
            cmd_health
            ;;
        help|--help|-h)
            show_usage
            ;;
        *)
            print_error "Unknown command: $command"
            print_status "Run './registry-cli.sh help' for usage information"
            exit 1
            ;;
    esac
}

# Run main function
main "$@"
