#!/usr/bin/env -S bash

echo "::group:: ===$(basename "$0")==="
set -euxo pipefail

# Add Mutter experimental-features
if [[ "${IMAGE_NAME}" =~ nvidia ]]; then
  sed -i "/experimental-features/ s|\\[|['kms-modifiers',|" \
        /etc/dconf/db/distro.d/03-bluefin-gnome
fi

# k8s tools
for i in dive helm ko kubectl; do #minio:mc
  podman pull "cgr.dev/chainguard/${i%:*}:latest"
  mnt=$(podman image mount "cgr.dev/chainguard/${i%:*}:latest")
  cp "$mnt/usr/bin/$i" "/usr/bin/${i#*:}"
  podman image umount "cgr.dev/chainguard/${i#*:}:latest"
  podman image rm "cgr.dev/chainguard/${i#*:}:latest"
done

echo "::endgroup::"
