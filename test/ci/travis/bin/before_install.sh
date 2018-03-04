#!/usr/bin/env bash

echo "STARTING before_install.sh"

# Common / useful `set` commands
set -Ee # Exit on error
set -o pipefail # Check status of piped commands
set -u # Error on undefined vars
# set -v # Print everything
set -x # Print commands (with expanded vars)

PYTHON_VERSION='2.7.14'
TRAVIS_DIR="./test/ci/travis"
TRAVIS_BIN_DIR="${TRAVIS_DIR}/bin"

OS_SCRIPT_PATH="${TRAVIS_BIN_DIR}/before_install/os/${TRAVIS_OS_NAME}.inc.bash"

./test/bin/git-submod-ssh-to-https.rb
git submodule update --init --recursive

if [ -f "${OS_SCRIPT_PATH}" ]; then
  echo "Including OS-specific script '${OS_SCRIPT_PATH}'..."
  source "${OS_SCRIPT_PATH}"
  echo "DONE: OS-specific script '${OS_SCRIPT_PATH}'"
else
  echo "No os-specific script found at '${OS_SCRIPT_PATH}'."
fi

# Set global python version
pyenv global "$PYTHON_VERSION"

# Install requirements (Ansible and QB Python module/filter deps)
pip install -r requirements.txt

# Install `//package.json` to get `semver`
yarn

# Install gem
gem update --system
gem install bundler

echo "DONE before_install.sh"
