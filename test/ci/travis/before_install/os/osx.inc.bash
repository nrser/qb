pyenv install "${QB_PYTHON_VERSION}"

echo 'eval "$(pyenv init -)"' > ~/.bash_profile

source ~/.bash_profile

echo "PATH: ${PATH}"
echo "which python: $(which python)"
echo "~/.bash_profile: $(cat ~/.bash_profile)"

# Install `yarn` via Homebrew. Way too noisy, so just toss the output
brew install yarn >/dev/null

# Set Git user and email because QB expects there to be one
# 
# TODO QB should handle it better if there isn't...
# 
git config --global user.name "Travis CI User (OSX)"
git config --global user.email "travis.osx@example.com"
