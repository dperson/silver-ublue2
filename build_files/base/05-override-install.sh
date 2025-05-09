#!/usr/bin/env -S bash

echo "::group:: ===$(basename "$0")==="
set -euxo pipefail

# Patched shells and Switcheroo Patch
# Enable Terra repo (Extras does not exist on F40)
# shellcheck disable=SC2016
for i in gnome-shell mesa-filesystem mesa-dri-drivers mesa-libEGL mesa-libGL \
      mesa-libgbm mesa-va-drivers mesa-vulkan-drivers switcheroo-control; do
  dnf5 -y swap --repo="terra, terra-extras, terra-mesa" "$i" "$i"
  dnf5 versionlock add "$i"
done

# Fix for ID in fwupd
dnf5 -y swap --repo=copr:copr.fedorainfracloud.org:ublue-os:staging fwupd fwupd

# Automatic wallpaper changing by month
HARDCODED_MONTH="01"
sed -i "/picture-uri/ s/${HARDCODED_MONTH}/$(date +%m)/" \
      "/etc/dconf/db/distro.d/03-bluefin-gnome"

echo "::endgroup::"
