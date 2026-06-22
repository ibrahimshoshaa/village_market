#!/usr/bin/env bash
set -e

# Install Flutter SDK (stable channel) into the Codespace
git clone https://github.com/flutter/flutter.git -b stable --depth 1 "$HOME/flutter"
echo 'export PATH="$PATH:$HOME/flutter/bin"' >> "$HOME/.bashrc"
export PATH="$PATH:$HOME/flutter/bin"

flutter precache
flutter config --no-analytics
flutter doctor

# Firebase CLI for `firebase deploy`, `flutterfire configure`
npm install -g firebase-tools

echo "✅ Codespace ready. Run 'flutter pub get' in the project root to begin."
