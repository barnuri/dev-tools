# general installs

```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
brew update && brew upgrade
brew install --cask rectangle
brew install --cask latest
brew install --cask shottr
brew install --cask maccy
brew install wget
brew install ripgrep
# https://www.bresink.com/osx/0TinkerTool/download.php # TinkerTool
brew install --cask git-credential-manager
brew install --cask git
brew install kubernetes-cli
brew install helm
brew install kubecolor
brew install python
brew install awscli
brew install uv
brew install node
```

# terminal

```bash
sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" # all my zsh
brew install --cask kitty
brew install powerlevel10k
echo "source $(brew --prefix)/share/powerlevel10k/powerlevel10k.zsh-theme" >>~/.zshrc
git clone --depth=1 https://github.com/romkatv/powerlevel10k.git "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/powerlevel10k"
curl -fsSL https://raw.githubusercontent.com/barnuri/dev-tools/master/mac-utils/.p10k.zsh -o ~/.p10k.zsh
```

# pc shortcats

```bash
brew install --cask karabiner-elements
curl -fsSL https://raw.githubusercontent.com/barnuri/dev-tools/master/mac-utils/karabiner.json -o ~/.config/karabiner/karabiner.json
```

# wallpaper

https://windowswallpaper.miraheze.org/wiki/Img4_(Windows_10)#/media/File:Img4_(Windows_10).jpg

# git

```bash
git-credential-manager configure
git config --global credential.credentialStore keychain
git-credential-manager github login
git config --global user.name "Bar Nuri"
git config --global user.email "barnuri@hotmail.com"
```

# no password on sudo

```bash
echo '<username> ALL=(ALL) NOPASSWD: ALL' | sudo tee -a /etc/sudoers
```
