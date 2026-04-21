if [ "$(uname)" = "Darwin" ]; then
  ANDROID_HOME=$HOME/Library/Android/sdk
else
  ANDROID_HOME=$HOME/Android/Sdk
fi

if test -d "${ANDROID_HOME}" ; then
  export ANDROID_HOME
  PATH="${PATH}:${ANDROID_HOME}/emulator:${ANDROID_HOME}/platform-tools"
else
  unset ANDROID_HOME
fi
