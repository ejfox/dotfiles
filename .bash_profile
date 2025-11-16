# Twitter bot credentials moved to .env
# Source .env for secrets
[ -f ~/.env ] && source ~/.env

export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion
export JAVA_HOME=/Library/Java/JavaVirtualMachines/jdk1.8.0_202.jdk/Contents/Home
export ANDROID_HOME=/usr/local/share/android-sdk
export JAVA_HOME=/Library/Java/JavaVirtualMachines/adoptopenjdk-8.jdk/Contents/Home
export ANDROID_HOME=/usr/local/share/android-sdk

export PATH="/Users/ejf/bin:/usr/local/bin:/Library/Frameworks/Python.framework/Versions/3.7/bin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin:/usr/local/MacGPG2/bin:/Library/Frameworks/Mono.framework/Versions/Current/Commands:/Applications/Wireshark.app/Contents/MacOS:/Users/ejf/.nvm/versions/node/v8.11.1/bin:/Users/ejf/bin:/Library/Frameworks/Python.framework/Versions/3.7/bin:/Users/ejf/.vimpkg/bin"

[[ -s "$HOME/.rvm/scripts/rvm" ]] && source "$HOME/.rvm/scripts/rvm" # Load RVM into a shell session *as a function*
