## Quick Install / Update

To install or update `profileTools.sh` and automatically source it in your shell profile, run:

```sh
brew install fzf
git clone https://github.com/zsh-users/zsh-autosuggestions ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions
git clone https://github.com/zsh-users/zsh-syntax-highlighting.git ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting

curl -fsSL https://raw.githubusercontent.com/barnuri/dev-tools/refs/heads/master/mac-utils/profileTools.sh -o ~/profileTools.sh && source ~/profileTools.sh
curl -o ~/.oh-my-zsh/custom/themes/minimal-git.zsh-theme https://raw.githubusercontent.com/barnuri/dev-tools/refs/heads/master/mac-utils/minimal-git.zsh-theme
```

Or, from within a shell that already has the script, just run:

```sh
syncProfileTools
```

This will:

-   Download the latest `profileTools.sh` to `~/.profileTools.sh`
-   Add `source $HOME/.profileTools.sh` to your `~/.zshrc` (if not already present)
-   Source the updated script

## Usage

After installation, restart your terminal or run:

```sh
source ~/.zshrc
```

You will have access to many helpful aliases and functions, including:

-   Python venv helpers: `p3venv`, `venvActivate`, etc.
-   Git helpers: `gitc`, `gitmt`, `gitnb`, `gitp`, `gitMergeTo`, etc.
-   Utility aliases: `ll`, `k`, `reloadProfile`, etc.
-   Environment helpers: `readEnvFile`, `filesByGlob`, etc.

## Updating

To update to the latest version at any time, just run:

```sh
syncProfileTools
```

## Uninstall

To remove, delete the line `source $HOME/.profileTools.sh` from your `~/.zshrc` and remove the file `~/.profileTools.sh`.
