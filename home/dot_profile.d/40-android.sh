# Android SDK (Flutter, adb). An ANDROID_HOME that is already set (by the user,
# an IDE or a parent shell) is kept. Otherwise the first complete SDK wins:
# the Homebrew android-commandlinetools cask (what `flutter config
# --android-sdk` points to on the Mac), Android Studio's default (macOS, then
# Linux), the old path. Nothing is changed when no SDK is found.
if [ -z "${ANDROID_HOME:-}" ] || [ ! -d "$ANDROID_HOME" ]; then
  _android_sdk=""
  for _android_dir in \
    ${HOMEBREW_PREFIX:+"$HOMEBREW_PREFIX/share/android-commandlinetools"} \
    "$HOME/Library/Android/sdk" \
    "$HOME/Android/Sdk" \
    "$HOME/lib/android-sdk"; do
    # An empty or half-downloaded SDK directory does not count.
    if [ -d "$_android_dir/platform-tools" ] || [ -d "$_android_dir/cmdline-tools" ]; then
      _android_sdk="$_android_dir"
      break
    fi
  done
  unset _android_dir
  [ -n "$_android_sdk" ] || { unset _android_sdk; return 0; }
  ANDROID_HOME="$_android_sdk"
  unset _android_sdk
fi

export ANDROID_HOME
export ANDROID_SDK_ROOT="$ANDROID_HOME" # Flutter
path_append "$ANDROID_HOME/cmdline-tools/latest/bin"
path_append "$ANDROID_HOME/platform-tools"
