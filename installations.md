
# general installs
```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
brew update && brew upgrade
brew install --cask rectangle
brew install --cask latest
brew install --cask shottr
brew install --cask maccy
brew install wget
brew install rg
# https://www.bresink.com/osx/0TinkerTool/download.php # TinkerTool 
brew install --cask git-credential-manager
brew install --cask git
brew install kubernetes-cli
brew install helm
brew install kubecolor
```

# terminal
```bash
sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" # all my zsh
brew install --cask kitty
brew install powerlevel10k
echo "source $(brew --prefix)/share/powerlevel10k/powerlevel10k.zsh-theme" >>~/.zshrc
git clone --depth=1 https://github.com/romkatv/powerlevel10k.git "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/powerlevel10k"
# cp .p10k.zsh to ~/.p10k.zsh 
```

# pc shortcats

```bash
brew install --cask karabiner-elements
```
https://ke-complex-modifications.pqrs.org/#pc_shortcuts%20https://ke-complex-modifications.pqrs.org/#pc_shortcuts

# wallpaper 
https://windowswallpaper.miraheze.org/wiki/Img4_(Windows_10)#/media/File:Img4_(Windows_10).jpg

# git
```bash
git-credential-manager configure
git config --global credential.credentialStore cache
git-credential-manager github login
git config --global user.name "Bar Nuri"
git config --global user.email "barnuri@hotmail.com"
```