#!/bin/bash
set -e

# Script to import KnightOS packages into the registry

# Show help message
if [ "$1" = "-h" ] || [ "$1" = "--help" ]; then
    echo "Usage: $0 <package-path>"
    echo ""
    echo "Import a KnightOS package from a directory containing package.config."
    echo ""
    echo "Arguments:"
    echo "  package-path    Path to the package directory"
    echo ""
    echo "Examples:"
    echo "  $0 /path/to/fileman"
    echo "  $0 ~/Documents/knightos-textview"
    exit 0
fi

# Require package path argument
if [ -z "$1" ]; then
    echo "Error: Package path is required"
    echo "Usage: $0 <package-path>"
    exit 1
fi

PKG_DIR="$1"
PACKAGES_DIR="$(dirname "$0")/../packages"

# Validate that the package directory exists
if [ ! -d "$PKG_DIR" ]; then
    echo "Error: Directory not found: $PKG_DIR"
    exit 1
fi

echo "Importing KnightOS package from: $PKG_DIR"

# Function to parse package.config and create manifest.json
import_package() {
    local pkg_dir="$1"
    local pkg_name=$(basename "$pkg_dir")

    if [ ! -f "$pkg_dir/package.config" ]; then
        echo "Warning: No package.config found in $pkg_dir"
        return
    fi

    # Parse package.config
    local name=$(grep "^name=" "$pkg_dir/package.config" | cut -d= -f2)
    local repo=$(grep "^repo=" "$pkg_dir/package.config" | cut -d= -f2)
    local version=$(grep "^version=" "$pkg_dir/package.config" | cut -d= -f2)
    local description=$(grep "^description=" "$pkg_dir/package.config" | cut -d= -f2)
    local copyright=$(grep "^copyright=" "$pkg_dir/package.config" | cut -d= -f2)
    local dependencies=$(grep "^dependencies=" "$pkg_dir/package.config" | cut -d= -f2)

    if [ -z "$name" ] || [ -z "$repo" ] || [ -z "$version" ]; then
        echo "Warning: Missing required fields in $pkg_dir/package.config"
        return
    fi

    # Find the .pkg file
    local pkg_file=$(find "$pkg_dir" -maxdepth 1 -name "*.pkg" -type f ! -name "*1.6.2*" | head -1)

    if [ -z "$pkg_file" ]; then
        echo "Warning: No .pkg file found in $pkg_dir"
        return
    fi

    # Create target directory
    local target_dir="$PACKAGES_DIR/$repo/$name"
    mkdir -p "$target_dir"

    # Copy .pkg file
    cp "$pkg_file" "$target_dir/"
    echo "  Copied: $(basename "$pkg_file")"

    # Convert dependencies to JSON array
    local deps_json="[]"
    if [ -n "$dependencies" ]; then
        # Split by space and create JSON array
        deps_json="["
        first=true
        for dep in $dependencies; do
            if [ "$first" = true ]; then
                deps_json="${deps_json}\"$dep\""
                first=false
            else
                deps_json="${deps_json}, \"$dep\""
            fi
        done
        deps_json="${deps_json}]"
    fi

    # Create manifest.json
    cat > "$target_dir/manifest.json" <<EOF
{
  "name": "$name",
  "repo": "$repo",
  "full_name": "$repo/$name",
  "version": "$version",
  "description": "$description",
  "copyright": "$copyright",
  "dependencies": $deps_json
}
EOF

    echo "  Created: $repo/$name manifest.json"
    echo ""
}

# Import the package
import_package "$PKG_DIR"

echo "Package import complete!"
echo ""
echo "Packages directory structure:"
tree -L 3 "$PACKAGES_DIR" 2>/dev/null || find "$PACKAGES_DIR" -type f | sort
