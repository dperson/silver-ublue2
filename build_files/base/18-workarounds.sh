#!/usr/bin/env -S bash

echo "::group:: ===$(basename "$0")==="
set -euxo pipefail

get_git_pkg() { local prj="$1" pat="$2" out="$3" cmd="${4:-${1##*/}}" url \
      i="$([[ ${5:-} ]] && echo "[]|select(.name|test(\"$5\"))" || echo "[0]")"
  local filter=".$i.assets[]|select(.name|test(\"$pat\")).browser_download_url"
  PATH=/bin:/usr/bin:/usr/local/bin type -p "$cmd" >/dev/null && return 1 || :
  url=$(curl -LSfs "https://api.github.com/repos/$prj/releases"|jq -r "$filter")
  curl -LSfso "$out" "$url"
}

## Pins and Overrides
## Use this section to pin packages in order to avoid regressions
# Remember to leave a note with rationale/link to issue for each pin!

# Workaround atheros-firmware regression
# see https://bugzilla.redhat.com/show_bug.cgi?id=2365882
dnf -y swap atheros-firmware atheros-firmware-20250311-1$(rpm -E %{dist})

# Current bluefin systems have the bling.sh and bling.fish in default locations
mkdir -p /usr/share/ublue-os/bluefin-cli
cp /usr/share/ublue-os/bling/* /usr/share/ublue-os/bluefin-cli

# Try removing just docs (is it actually promblematic?)
rm -rf /usr/share/doc/just/README.*.md

# Install chezmoi
get_git_pkg "twpayne/chezmoi" "linux-amd64$" /usr/bin/chezmoi
url="https://github.com/twpayne/chezmoi/raw/master/completions"
p="/usr/share/bash-completion/completions"
curl -LSfso "${p}/chezmoi" "${url}/chezmoi-completion.bash"
p="/usr/share/zsh/site-functions"
curl -LSfso "${p}/_chezmoi" "${url}/chezmoi.zsh"
chmod +x /usr/bin/chezmoi

# Install eza
get_git_pkg "eza-community/eza" "x86_64-unknown-linux-gnu.tar.gz" /tmp/eza.tgz
get_git_pkg "eza-community/eza" "completions" /tmp/eza_completions.tgz
tar -C /tmp -xf /tmp/eza.tgz
tar -C /tmp -xf /tmp/eza_completions.tgz
cp /tmp/eza /usr/bin
cp /tmp/target/completions-*/eza /usr/share/bash-completion/completions
cp /tmp/target/completions-*/_eza /usr/share/zsh/site-functions
chmod +x /usr/bin/eza
rm -rf /tmp/eza*

# Install kanata
get_git_pkg "jtroo/kanata" "^kanata$" /usr/bin/kanata
chgrp input /usr/bin/kanata
chmod 2755 /usr/bin/kanata

# Install k9s, kind, kubectx, & kubens
get_git_pkg "derailed/k9s" "linux_amd64.rpm$" /tmp/k9s.rpm
dnf5 install -y /tmp/k9s.rpm
rm /tmp/k9s.rpm
get_git_pkg "kubernetes-sigs/kind" "^kind-linux-amd64$" /usr/bin/kind
get_git_pkg "ahmetb/kubectx" "^kubens$" /usr/bin/kubens
get_git_pkg "ahmetb/kubectx" "^kubectx$" /usr/bin/kubectx
chmod +x /usr/bin/kind /usr/bin/kubectx /usr/bin/kubens

# Install mdcat
get_git_pkg "swsnr/mdcat" "linux" /tmp/mdcat.tgz
tar -C /tmp -xf /tmp/mdcat.tgz
cp /tmp/mdcat*/mdcat /usr/bin
cp /tmp/mdcat*/mdcat.1/mdcat.1 /usr/share/man/man1
rm -rf /tmp/mdcat*
chmod +x /usr/bin/mdcat

# Install oh-my-posh
get_git_pkg "JanDeDobbeleer/oh-my-posh" "linux-amd64$" /usr/bin/oh-my-posh
chmod +x /usr/bin/oh-my-posh

# Install rust-parallel
get_git_pkg "aaronriekenberg/rust-parallel" "x86_64.*linux" /tmp/parallel.tgz
tar -C /tmp -xf /tmp/parallel.tgz
cp /tmp/rust-parallel /usr/bin/parallel
rm -rf /tmp/*parallel*
chmod +x /usr/bin/parallel

# Fix justfile syntax highlighting
url="https://github.com/NoahTheDuke/vim-just/raw/main/syntax"
curl -LSfso /usr/share/nvim/runtime/syntax/just.vim "${url}/just.vim"
cp /usr/share/nvim/runtime/syntax/just.vim /usr/share/vim/vim91/syntax/

# Fix power button
sed -i 's/#HandlePowerKey=poweroff/HandlePowerKey=suspend/g' \
      /usr/lib/systemd/logind.conf

# Enable faillock in PAM authentication profile
authselect enable-feature with-faillock -q

# Fix waydroid
sed -Ei 's/=.\$\(command -v (nft|ip6?tables-legacy).*/=/g' \
      /usr/lib/waydroid/data/scripts/waydroid-net.sh
sed -i 's@=waydroid first-launch@=/usr/bin/waydroid-launcher first-launch\
X-Steam-Library-Capsule=/usr/share/applications/Waydroid/capsule.png\
X-Steam-Library-Hero=/usr/share/applications/Waydroid/hero.png\
X-Steam-Library-Logo=/usr/share/applications/Waydroid/logo.png\
X-Steam-Library-StoreCapsule=/usr/share/applications/Waydroid/store-capsule.png\
X-Steam-Controller-Template=Desktop@g' /usr/share/applications/Waydroid.desktop
url='https://raw.githubusercontent.com/Quackdoc/waydroid-scripts/main'
curl -LSfso /usr/bin/waydroid-choose-gpu "${url}/waydroid-choose-gpu.sh"
chmod +x /usr/bin/waydroid-choose-gpu

# Make needed directory
mkdir -pv /etc/containers/registries.d/ghcr.io

# Make group needed by kanata
groupadd -r uinput

# Fix some broken apps libdrm links
cp -d /usr/lib64/libdrm.so.2 /usr/lib64/libdrm.so

# Install topgrade
pip install --prefix=/usr topgrade

# Install Gnome Extensions
pip install --prefix=/usr gnome-extensions-cli
gext install 615  # appindicatorsupport@rgcjonas.gmail.com
gext install 16   # auto-move-windows@gnome-shell-extensions.gcampax.github.com
gext install 6670 # Bluetooth-Battery-Meter@maniacx.github.com
gext install 3193 # blur-my-shell@aunetx
gext install 517  # caffeine@patapon.info
gext install 4839 # clipboard-history@alexsaveau.dev
gext install 307  # dash-to-dock@micxgx.gmail.com
gext install 3843 # just-perfection-desktop@just-perfection
gext install 7048 # rounded-window-corners@fxgn
gext install 6139 # tailscale@joaophi.github.com
gext install 7065 # tilingshell@ferrarodomenico.com
gext install 6784 # wiggle@mechtifs

echo "::endgroup::"
