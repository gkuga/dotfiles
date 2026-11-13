[ -d "$HOME/lib/android-sdk" ] || return 0

export ANDROID_HOME="$HOME/lib/android-sdk"
export ANDROID_SDK_ROOT="$ANDROID_HOME" # Flutter
PATH="$PATH:$ANDROID_HOME/cmdline-tools/latest/bin:$ANDROID_HOME/platform-tools"
