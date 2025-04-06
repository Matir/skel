ANDROID_HOME=$HOME/Library/Android/sdk

if test -d $ANDROID_HOME ; then
  PATH=$PATH:$ANDROID_HOME/emulator:$ANDROID_HOME/platform-tools
else
  unset ANDROID_HOME
fi
