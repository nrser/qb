echo "STARTING before_install.inc.bash"

QB_PYTHON_VERSION='2.7.14'
QB_TRAVIS_DIR="./test/ci/travis"

# Path to OS-specific "before install" script
# 
# Like `//test/ci/travis/bash/before_install/os/osx.inc.bash`
# 
QB_OS_SCRIPT_PATH="${QB_TRAVIS_DIR}/before_install/os/${TRAVIS_OS_NAME}.inc.bash"

./test/bin/git-submod-ssh-to-https.rb
git submodule update --init --recursive

if [ -f "${QB_OS_SCRIPT_PATH}" ]; then
  echo "Including OS-specific script '${QB_OS_SCRIPT_PATH}'..."
  source "${QB_OS_SCRIPT_PATH}"
  echo "DONE: OS-specific script '${QB_OS_SCRIPT_PATH}'"
else
  echo "No os-specific script found at '${QB_OS_SCRIPT_PATH}'."
fi

# Install the Python version
pyenv install --skip-existing "${QB_PYTHON_VERSION}"

# Set global python version
PYENV_VERSION="${QB_PYTHON_VERSION}"
pyenv global "$QB_PYTHON_VERSION"

# Install requirements (Ansible and QB Python module/filter deps)
pip install -r requirements.txt

# Install `//package.json` to get `semver`
yarn

# Install gem
gem update --system
gem install bundler

echo "DONE before_install.sh"
