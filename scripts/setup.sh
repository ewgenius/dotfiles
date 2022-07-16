# install brew
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# Utilities
brew install --cask raycast
brew install --cask cleanshot # https://licenses.maketheweb.io/
brew install --cask google-drive
brew install --cask surfshark
brew install --cask bitwarden
brew install --cask brave-browser
brew install --cask notion
brew install --cask telegram

# Dev Tools
brew tap homebrew/cask-fonts && brew install --cask font-jetbrains-mono
brew install --cask iterm2
brew install --cask visual-studio-code
brew install --cask gh
brew install nvm
