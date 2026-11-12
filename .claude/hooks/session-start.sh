#!/bin/bash
# Installs the Flutter SDK (and the app's Dart packages, once pubspec.yaml
# exists) in Claude Code cloud sessions. Does nothing on local machines.
set -euo pipefail

if [ "${CLAUDE_CODE_REMOTE:-}" != "true" ]; then
  exit 0
fi

FLUTTER_VERSION="3.47.9"
FLUTTER_SHA256="25ed8c3c29d51a7353f2a944310b478af8214920639524b19c50a19e6c044c5a"
FLUTTER_URL="https://storage.googleapis.com/flutter_infra_release/releases/stable/linux/flutter_linux_${FLUTTER_VERSION}-stable.tar.xz"
SDK_PARENT="$HOME/.flutter-sdk/$FLUTTER_VERSION"
FLUTTER_HOME="$SDK_PARENT/flutter"

# 1. Flutter SDK (outside the repo; skipped when this version is already there)
if [ ! -x "$FLUTTER_HOME/bin/flutter" ]; then
  echo "Installing Flutter $FLUTTER_VERSION..." >&2
  tmp="$(mktemp -d)"
  trap 'rm -rf "$tmp"' EXIT
  curl -fsSL --retry 3 -o "$tmp/flutter.tar.xz" "$FLUTTER_URL"
  echo "$FLUTTER_SHA256  $tmp/flutter.tar.xz" | sha256sum --check --status
  rm -rf "$SDK_PARENT"
  mkdir -p "$SDK_PARENT"
  tar -xJf "$tmp/flutter.tar.xz" -C "$SDK_PARENT"
fi

git config --global --get-all safe.directory | grep -qxF "$FLUTTER_HOME" \
  || git config --global --add safe.directory "$FLUTTER_HOME"
export PATH="$FLUTTER_HOME/bin:$FLUTTER_HOME/bin/cache/dart-sdk/bin:$HOME/.pub-cache/bin:$PATH"
export FLUTTER_SUPPRESS_ANALYTICS=true

# First run downloads the Dart SDK and engine artifacts; later runs are fast.
if [ ! -d "$FLUTTER_HOME/bin/cache/dart-sdk" ]; then
  flutter --disable-analytics >/dev/null 2>&1 || true
  dart --disable-analytics >/dev/null 2>&1 || true
  flutter precache --universal >&2
fi

# 2. App packages (only once the Flutter project exists, and only when
#    pubspec changed since the last successful install)
cd "${CLAUDE_PROJECT_DIR:-.}"
if [ -f pubspec.yaml ]; then
  mkdir -p .dart_tool
  hashes=.dart_tool/.session-start.sha256
  if ! sha256sum --check --status "$hashes" 2>/dev/null; then
    rm -f "$hashes"
    flutter pub get >&2
    sha256sum .claude/hooks/session-start.sh pubspec.yaml pubspec.lock 2>/dev/null > "$hashes" || rm -f "$hashes"
  fi
fi

# 3. Make flutter and dart available to every command in the session
if [ -n "${CLAUDE_ENV_FILE:-}" ]; then
  {
    echo "export PATH=\"$FLUTTER_HOME/bin:$FLUTTER_HOME/bin/cache/dart-sdk/bin:\$HOME/.pub-cache/bin:\$PATH\""
    echo "export FLUTTER_SUPPRESS_ANALYTICS=true"
  } >> "$CLAUDE_ENV_FILE"
fi
