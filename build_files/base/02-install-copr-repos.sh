#!/usr/bin/env -S bash
# shellcheck disable=SC2016

echo "::group:: ===$(basename "$0")==="
set -euxo pipefail

# Add Packages repo
dnf5 -y copr enable ublue-os/packages

# Add Staging repo
dnf5 -y copr enable ublue-os/staging

# Add bazzite repo
dnf5 -y copr enable kylegospo/bazzite

# Add cosmic repo
#dnf5 -y copr enable ryanabx/cosmic-epoch

# Add kcli repo
dnf5 -y copr enable karmab/kcli

# Add niri repo
#dnf5 -y copr enable yalter/niri

# Add Tailscale repo
dnf5 -y config-manager --add-repo \
      https://pkgs.tailscale.com/stable/fedora/tailscale.repo

# Add Terra repo
dnf5 -y install --nogpgcheck --repofrompath \
      'terra,https://repos.fyralabs.com/terra$releasever' terra-release
dnf5 -y install terra-release-extras || true
# dnf5 config-manager setopt "terra*".enabled=0

echo "::endgroup::"
