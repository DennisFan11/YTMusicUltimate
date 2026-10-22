#!/usr/bin/env bash
set -euo pipefail

REPO="DennisFan11/YTMusicUltimate"
TAG="ytmu-input"
ASSET="YouTubeMusic.ipa"
IPA_PATH="${1:-}"

if [[ -z "$IPA_PATH" || ! -f "$IPA_PATH" ]]; then
  echo "Usage: bash scripts/build-with-local-ipa.sh /path/to/decrypted.ipa" >&2
  exit 2
fi
if ! command -v gh >/dev/null 2>&1; then
  echo "GitHub CLI is required. On macOS, run: brew install gh" >&2
  exit 2
fi
if ! gh auth status >/dev/null 2>&1; then
  echo "Run 'gh auth login' to authenticate with GitHub." >&2
  exit 2
fi
if ! unzip -tq "$IPA_PATH" >/dev/null 2>&1; then
  echo "Invalid IPA archive: $IPA_PATH" >&2
  exit 2
fi
echo "IPA SHA-256:"
shasum -a 256 "$IPA_PATH"
echo "Using a draft release so the original IPA is not committed to the public repository."
if ! gh release view "$TAG" --repo "$REPO" >/dev/null 2>&1; then
  gh release create "$TAG" --repo "$REPO" --draft --title "Private YTMU build input" --notes "Temporary original IPA input for YTMusicUltimate GitHub Actions builds. Do not publish."
fi
TEMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TEMP_DIR"' EXIT
ln -s "$(cd "$(dirname "$IPA_PATH")" && pwd)/$(basename "$IPA_PATH")" "$TEMP_DIR/$ASSET"
gh release upload "$TAG" "$TEMP_DIR/$ASSET" --clobber --repo "$REPO"
echo "Uploaded to draft release $TAG."
gh workflow run main.yml --repo "$REPO" --ref main \
  -f input_source=release \
  -f display_name="YouTube Music" \
  -f bundle_id="com.google.ios.youtubemusic"
echo "Build requested. See: https://github.com/$REPO/actions/workflows/main.yml"
