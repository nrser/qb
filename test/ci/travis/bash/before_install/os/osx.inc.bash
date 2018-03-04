pyenv install "${PYTHON_VERSION}"

echo 'eval "$(pyenv init -)"' > ~/.bash_profile

source ~/.bash_profile

brew install yarn

# Set Git user and email because QB expects there to be one
# 
# TODO QB should handle it better if there isn't...
# 
git config --global user.name "Travis CI User (OSX)"
git config --global user.email "travis.osx@example.com"
