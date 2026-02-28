#!/bin/bash

# Default values
FORCE=false
TARGET_PATH=""
DEST_PATH=""

# Parse flags (looking for -f)
while getopts "f" opt; do
  case $opt in
    f) FORCE=true ;;
    *) echo "Usage: $0 [-f] <binary_name_or_path> [destination]"; exit 1 ;;
  esac
done
shift $((OPTIND-1))

# Check for first argument
if [ -z "$1" ]; then
    echo "Error: No binary specified."
    echo "Usage: $0 [-f] <binary_name_or_path> [destination]"
    exit 1
fi

# 1. Resolve the Source Binary
if [[ "$1" == *"/"* ]]; then
    SOURCE_BIN="$1"
else
    SOURCE_BIN=$(command -v "$1")
fi

if [ ! -f "$SOURCE_BIN" ]; then
    echo "Error: Could not find binary at '$1'"
    exit 1
fi

# 2. Determine Destination Path
if [ -n "$2" ]; then
    DEST_PATH="$2"
    # If destination is a directory, append the basename
    if [ -d "$DEST_PATH" ]; then
        DEST_PATH="${DEST_PATH%/}/$(basename "$SOURCE_BIN")"
    fi
else
    # No destination given: create a temp directory
    TMP_DIR=$(mktemp -d -t "debug_unlock_XXXXXX")
    DEST_PATH="$TMP_DIR/$(basename "$SOURCE_BIN")"
    echo "Notice: No destination provided. Using temp path: $DEST_PATH"
fi

# 3. Check for Collision
if [ -f "$DEST_PATH" ] && [ "$FORCE" = false ]; then
    echo "Error: Destination '$DEST_PATH' already exists. Use -f to overwrite."
    exit 1
fi

# 4. Copy and Sign
cp -f "$SOURCE_BIN" "$DEST_PATH"
chmod +x "$DEST_PATH"

ENTITLEMENTS_FILE=$(mktemp)
cat <<EOF > "$ENTITLEMENTS_FILE"
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>com.apple.security.get-task-allow</key>
    <true/>
    <key>com.apple.security.cs.disable-library-validation</key>
    <true/>
</dict>
</plist>
EOF

echo "Unlocking: $SOURCE_BIN -> $DEST_PATH"
codesign -s - --entitlements "$ENTITLEMENTS_FILE" -f "$DEST_PATH" 2>/dev/null

if [ $? -eq 0 ]; then
    echo "✅ Success! You can now debug: $DEST_PATH"
else
    echo "❌ Error: Code signing failed."
fi

rm "$ENTITLEMENTS_FILE"
