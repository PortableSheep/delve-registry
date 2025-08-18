#!/bin/bash

# Delve Plugin Registry - Plugin Publishing Script
# This script automates the process of publishing a plugin to the registry

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REGISTRY_DIR="$(dirname "$SCRIPT_DIR")"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
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

# Function to show usage
show_usage() {
    echo "Usage: $0 <plugin_name> <version> [options]"
    echo ""
    echo "Options:"
    echo "  -p, --plugin-dir <dir>    Plugin source directory (default: ./<plugin_name>)"
    echo "  -c, --channel <channel>   Release channel (stable|beta|development, default: stable)"
    echo "  -f, --force              Force overwrite existing version"
    echo "  -h, --help               Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0 json-linter-formatter v1.0.0"
    echo "  $0 github-dashboard v2.1.0 --channel beta"
    echo "  $0 my-plugin v1.0.0 --plugin-dir /path/to/plugin"
}

# Function to validate version format
validate_version() {
    local version=$1
    if [[ ! $version =~ ^v[0-9]+\.[0-9]+\.[0-9]+(-[a-zA-Z0-9.-]+)?$ ]]; then
        print_error "Invalid version format: $version"
        print_error "Version must follow semantic versioning: vX.Y.Z or vX.Y.Z-prerelease"
        exit 1
    fi
}

# Function to calculate SHA256 checksum
calculate_checksum() {
    local file=$1
    if command -v sha256sum &> /dev/null; then
        sha256sum "$file" | cut -d' ' -f1
    elif command -v shasum &> /dev/null; then
        shasum -a 256 "$file" | cut -d' ' -f1
    else
        print_error "Neither sha256sum nor shasum found. Cannot calculate checksums."
        exit 1
    fi
}

# Function to get file size
get_file_size() {
    local file=$1
    if [[ "$OSTYPE" == "darwin"* ]]; then
        stat -f%z "$file"
    else
        stat -c%s "$file"
    fi
}

# Function to build plugin for all platforms
build_plugin() {
    local plugin_dir=$1
    local plugin_name=$2
    local version=$3
    local output_dir=$4

    print_status "Building plugin '$plugin_name' version '$version'..."

    if [[ ! -f "$plugin_dir/go.mod" ]]; then
        print_error "No go.mod found in plugin directory: $plugin_dir"
        exit 1
    fi

    cd "$plugin_dir"

    # Build for different platforms
    local platforms=("darwin/amd64" "darwin/arm64" "linux/amd64" "linux/arm64" "windows/amd64")

    for platform in "${platforms[@]}"; do
        local os=$(echo $platform | cut -d'/' -f1)
        local arch=$(echo $platform | cut -d'/' -f2)
        local binary_name="$plugin_name-$os-$arch"

        if [[ "$os" == "windows" ]]; then
            binary_name="$binary_name.exe"
        fi

        print_status "Building for $os/$arch..."

        GOOS=$os GOARCH=$arch go build -o "$output_dir/$binary_name" .

        if [[ $? -eq 0 ]]; then
            print_success "Built $binary_name"
        else
            print_error "Failed to build for $os/$arch"
            exit 1
        fi
    done

    cd - > /dev/null
}

# Function to copy frontend assets
copy_frontend() {
    local plugin_dir=$1
    local output_dir=$2

    if [[ -d "$plugin_dir/frontend" ]]; then
        print_status "Copying frontend assets..."
        cp -r "$plugin_dir/frontend" "$output_dir/"
        print_success "Frontend assets copied"
    fi
}

# Function to validate plugin.json
validate_plugin_json() {
    local plugin_json=$1

    if [[ ! -f "$plugin_json" ]]; then
        print_error "plugin.json not found: $plugin_json"
        exit 1
    fi

    # Basic JSON validation
    if ! python3 -m json.tool "$plugin_json" > /dev/null 2>&1; then
        print_error "Invalid JSON in plugin.json"
        exit 1
    fi

    print_success "plugin.json validated"
}

# Function to update registry metadata
update_registry() {
    local plugin_name=$1
    local version=$2
    local channel=$3
    local release_dir=$4

    print_status "Updating registry metadata..."

    # This is a simplified version - in practice, you'd want to use a proper
    # YAML/JSON parser to update the registry files programmatically
    print_warning "Registry metadata update needs to be implemented"
    print_warning "Please manually update registry.yml and API files"

    echo ""
    echo "Files created in: $release_dir"
    echo "Please update the following files manually:"
    echo "  - registry.yml"
    echo "  - api/plugins.json"
    echo "  - api/plugins/$plugin_name"
}

# Parse command line arguments
PLUGIN_NAME=""
VERSION=""
PLUGIN_DIR=""
CHANNEL="stable"
FORCE=false

while [[ $# -gt 0 ]]; do
    case $1 in
        -p|--plugin-dir)
            PLUGIN_DIR="$2"
            shift 2
            ;;
        -c|--channel)
            CHANNEL="$2"
            shift 2
            ;;
        -f|--force)
            FORCE=true
            shift
            ;;
        -h|--help)
            show_usage
            exit 0
            ;;
        -*)
            print_error "Unknown option: $1"
            show_usage
            exit 1
            ;;
        *)
            if [[ -z "$PLUGIN_NAME" ]]; then
                PLUGIN_NAME="$1"
            elif [[ -z "$VERSION" ]]; then
                VERSION="$1"
            else
                print_error "Too many arguments"
                show_usage
                exit 1
            fi
            shift
            ;;
    esac
done

# Validate required arguments
if [[ -z "$PLUGIN_NAME" || -z "$VERSION" ]]; then
    print_error "Plugin name and version are required"
    show_usage
    exit 1
fi

# Set default plugin directory
if [[ -z "$PLUGIN_DIR" ]]; then
    PLUGIN_DIR="$REGISTRY_DIR/$PLUGIN_NAME"
fi

# Validate inputs
validate_version "$VERSION"

if [[ ! -d "$PLUGIN_DIR" ]]; then
    print_error "Plugin directory not found: $PLUGIN_DIR"
    exit 1
fi

# Validate channel
if [[ ! "$CHANNEL" =~ ^(stable|beta|development)$ ]]; then
    print_error "Invalid channel: $CHANNEL. Must be stable, beta, or development"
    exit 1
fi

# Create release directory
RELEASE_DIR="$REGISTRY_DIR/$PLUGIN_NAME/releases/$VERSION"

if [[ -d "$RELEASE_DIR" && "$FORCE" == false ]]; then
    print_error "Release directory already exists: $RELEASE_DIR"
    print_error "Use --force to overwrite"
    exit 1
fi

mkdir -p "$RELEASE_DIR"

print_status "Publishing plugin '$PLUGIN_NAME' version '$VERSION' to channel '$CHANNEL'..."

# Validate plugin.json
validate_plugin_json "$PLUGIN_DIR/plugin.json"

# Copy plugin.json to plugin root (for API access)
cp "$PLUGIN_DIR/plugin.json" "$REGISTRY_DIR/$PLUGIN_NAME/"

# Build plugin binaries
build_plugin "$PLUGIN_DIR" "$PLUGIN_NAME" "$VERSION" "$RELEASE_DIR"

# Copy frontend assets
copy_frontend "$PLUGIN_DIR" "$RELEASE_DIR"

# Generate checksums and metadata
print_status "Generating checksums and metadata..."

CHECKSUM_FILE="$RELEASE_DIR/checksums.txt"
METADATA_FILE="$RELEASE_DIR/metadata.json"

echo "# Checksums for $PLUGIN_NAME $VERSION" > "$CHECKSUM_FILE"
echo "# Generated on $(date -u '+%Y-%m-%d %H:%M:%S UTC')" >> "$CHECKSUM_FILE"
echo "" >> "$CHECKSUM_FILE"

# Generate metadata JSON
cat > "$METADATA_FILE" << EOF
{
  "plugin_name": "$PLUGIN_NAME",
  "version": "$VERSION",
  "channel": "$CHANNEL",
  "released": "$(date -u '+%Y-%m-%dT%H:%M:%SZ')",
  "assets": {
EOF

FIRST_ASSET=true
for file in "$RELEASE_DIR"/*; do
    if [[ -f "$file" && "$(basename "$file")" != "checksums.txt" && "$(basename "$file")" != "metadata.json" ]]; then
        filename=$(basename "$file")
        checksum=$(calculate_checksum "$file")
        size=$(get_file_size "$file")

        echo "$checksum  $filename" >> "$CHECKSUM_FILE"

        if [[ "$FIRST_ASSET" == false ]]; then
            echo "," >> "$METADATA_FILE"
        fi
        FIRST_ASSET=false

        cat >> "$METADATA_FILE" << EOF
    "$filename": {
      "checksum": "sha256:$checksum",
      "size": $size
    }EOF
    fi
done

cat >> "$METADATA_FILE" << EOF

  }
}
EOF

print_success "Plugin published successfully!"
print_success "Release directory: $RELEASE_DIR"

# Update registry
update_registry "$PLUGIN_NAME" "$VERSION" "$CHANNEL" "$RELEASE_DIR"

print_status "Don't forget to:"
print_status "1. Update registry.yml with the new version"
print_status "2. Update API endpoint files"
print_status "3. Commit and push changes to the registry repository"
print_status "4. Tag the release in the plugin's source repository"
