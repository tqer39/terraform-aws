#!/bin/bash

#
# This script is used to setup the repository for the first time.
#

# Install Homebrew
if [ "$(uname)" == 'Darwin' ]; then
  # macOS
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
elif [ "$(expr substr $(uname -s) 1 5)" == 'Linux' ]; then
  # Linux
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
fi

brew bundle

# Install anyenv
if ! command -v anyenv &> /dev/null; then
  git clone https://github.com/anyenv/anyenv ~/.anyenv
  export PATH="$HOME/.anyenv/bin:$PATH"
  eval "$(anyenv init -)"
  mkdir -p $(anyenv root)/plugins
  git clone https://github.com/znz/anyenv-update.git $(anyenv root)/plugins/anyenv-update
fi
