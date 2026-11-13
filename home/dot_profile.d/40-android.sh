# Android SDK (Flutter, adb). The first location that exists wins: Android
# Studio's default (macOS, then Linux), the Homebrew android-commandlinetools
# cask (what `flutter config --android-sdk` points to on the Mac), the old path.
for ANDROID_HOME in \
  "$HOME/Library/Android/sdk" \
  "$HOME/Android/Sdk" \
  "${HOMEBREW_PREFIX:-/opt/homebrew}/share/android-commandlinetools" \
  "$HOME/lib/android-sdk"; do
  [ -d "$ANDROID_HOME" ] && break
done
[ -d "$ANDROID_HOME" ] || { unset ANDROID_HOME; return 0; }

export ANDROID_HOME
export ANDROID_SDK_ROOT="$ANDROID_HOME" # Flutter
path_append "$ANDROID_HOME/cmdline-tools/latest/bin"
path_append "$ANDROID_HOME/platform-tools"
