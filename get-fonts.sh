#!/bin/sh
# Download the Titan One font from Google Fonts if not already present.
# Run this before installing caelestia-greeter.

FONT_DIR="$(dirname "$0")/assets/fonts"
FONT_FILE="$FONT_DIR/TitanOne-Regular.ttf"

if [ -f "$FONT_FILE" ] && [ "$(stat -c%s "$FONT_FILE" 2>/dev/null || stat -f%z "$FONT_FILE" 2>/dev/null)" -gt 10000 ]; then
    echo "Titan One font already present."
    exit 0
fi

mkdir -p "$FONT_DIR"

echo "Downloading Titan One from Google Fonts..."
if command -v curl >/dev/null 2>&1; then
    curl -L "https://fonts.gstatic.com/s/titanone/v17/mFTzWbsGxbbS_J5cQcjykw.ttf" \
         -o "$FONT_FILE" --fail --silent --show-error
elif command -v wget >/dev/null 2>&1; then
    wget -q "https://fonts.gstatic.com/s/titanone/v17/mFTzWbsGxbbS_J5cQcjykw.ttf" \
         -O "$FONT_FILE"
else
    echo "Error: curl or wget is required to download the font."
    exit 1
fi

if [ -f "$FONT_FILE" ] && [ "$(stat -c%s "$FONT_FILE" 2>/dev/null || stat -f%z "$FONT_FILE" 2>/dev/null)" -gt 10000 ]; then
    echo "Font downloaded successfully."
else
    echo "Warning: font download may have failed. The greeter will use a fallback font."
fi
