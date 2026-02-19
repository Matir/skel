#!/usr/bin/env bash

# --- 1. Identity Resolution ---
# Finds the physical location of this script, regardless of symlinks
REAL_PATH=$(realpath "$0")
REAL_NAME=$(basename "$REAL_PATH")
HOOKS_DIR=$(dirname "$REAL_PATH")
CALLED_AS=$(basename "$0")

# --- 2. Self-Installation / Sync Logic ---
if [ "$CALLED_AS" == "$REAL_NAME" ]; then
    echo "🔧 Synchronizing Git Hook Dispatcher..."

    # Point Git to this directory
    git config core.hooksPath "$HOOKS_DIR"

    # Create symlinks for any [hook-name].d directories found
    for d in "$HOOKS_DIR"/*.d/; do
        [ -d "$d" ] || continue
        HOOK_NAME=$(basename "$d" .d)
        TARGET="$HOOKS_DIR/$HOOK_NAME"

        if [ ! -L "$TARGET" ]; then
            ln -sf "$REAL_NAME" "$TARGET"
            chmod +x "$TARGET"
            echo "   ✨ Linked: $HOOK_NAME"
        fi
    done

    # Cleanup: Remove symlinks that no longer have a matching .d directory
    for link in "$HOOKS_DIR"/*; do
        if [ -L "$link" ] && [ "$(basename "$link")" != "$REAL_NAME" ]; then
            if [ ! -d "${link}.d" ]; then
                rm "$link"
                echo "   🗑️ Removed: $(basename "$link")"
            fi
        fi
    done
    echo "✅ Done."
    exit 0
fi

# --- 3. Selective Stdin Buffering ---
# Buffer stdin only for hooks that expect it to prevent hanging/performance hits
STDIN_DATA=""
case "$CALLED_AS" in
    pre-push|post-rewrite|pre-receive|post-receive|reference-transaction)
        # Check if stdin has data (is not a terminal)
        if [ ! -t 0 ]; then
            STDIN_DATA=$(cat)
        fi
        ;;
esac

# --- 4. Dispatch Logic ---
SUB_HOOK_DIR="${HOOKS_DIR}/${CALLED_AS}.d"

if [ -d "$SUB_HOOK_DIR" ]; then
    # Sort files naturally so 01- runs before 02-
    for script in $(ls "$SUB_HOOK_DIR" | sort); do
        FULL_PATH="$SUB_HOOK_DIR/$script"
        [ -x "$FULL_PATH" ] || continue

        # Replay stdin if we captured it, otherwise execute normally
        if [ -n "$STDIN_DATA" ]; then
            echo "$STDIN_DATA" | "$FULL_PATH" "$@"
        else
            "$FULL_PATH" "$@"
        fi

        # Exit immediately if any sub-script fails
        EXIT_CODE=$?
        if [ $EXIT_CODE -ne 0 ]; then
            echo "❌ Hook '$CALLED_AS' failed at: $script"
            exit $EXIT_CODE
        fi
    done
fi

exit 0
