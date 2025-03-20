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

# Add Homebrew to PATH
if [ -d "/home/linuxbrew/.linuxbrew/bin" ]; then
  echo 'export PATH="/home/linuxbrew/.linuxbrew/bin:$PATH"' >> ~/.bashrc
  export PATH="/home/linuxbrew/.linuxbrew/bin:$PATH"
  source ~/.bashrc
elif [ -d "/opt/homebrew/bin" ]; then
  echo 'export PATH="/opt/homebrew/bin:$PATH"' >> ~/.bashrc
  export PATH="/opt/homebrew/bin:$PATH"
  source ~/.bashrc
fi

brew bundle

# Install anyenv
if ! command -v anyenv &> /dev/null; then
  git clone https://github.com/anyenv/anyenv ~/.anyenv
  export PATH="$HOME/.anyenv/bin:$PATH"
  eval "$(anyenv init -)"
  mkdir -p $(anyenv root)/plugins
  git clone https://github.com/znz/anyenv-update.git $(anyenv root)/plugins/anyenv-update

  echo 'eval "$(anyenv init -)"' >> ~/.bashrc
  exec bash -l
fi

# Install tfenv using anyenv
if command -v anyenv &> /dev/null; then
  if [ ! -d "$(anyenv root)/envs/tfenv" ]; then
    anyenv install tfenv
  fi
fi
