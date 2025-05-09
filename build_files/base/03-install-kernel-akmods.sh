#!/usr/bin/env -S bash

echo "::group:: ===$(basename "$0")==="
set -euxo pipefail

# Beta Updates Testing Repo...
if [[ "${UBLUE_IMAGE_TAG}" == "beta" ]]; then
  dnf5 config-manager setopt updates-testing.enabled=1
fi

# Remove Existing Kernel
for pkg in kernel kernel-core kernel-modules kernel-modules-core \
      kernel-modules-extra; do
  rpm --erase $pkg --nodeps
done

# Fetch Common AKMODS & Kernel RPMS
container="docker://ghcr.io/ublue-os/akmods:${AKMODS_FLAVOR}-$(rpm -E %fedora)"
skopeo copy --retry-times 3 "${container}-${KERNEL}" dir:/tmp/akmods
AKMODS_TARGZ=$(jq -r '.layers[].digest' </tmp/akmods/manifest.json |cut -d: -f2)
tar -xvzf /tmp/akmods/"$AKMODS_TARGZ" -C /tmp/
mv /tmp/rpms/* /tmp/akmods/
# NOTE: kernel-rpms should auto-extract into correct location

# Install Kernel
dnf5 -y install \
      /tmp/kernel-rpms/kernel-[0-9]*.rpm \
      /tmp/kernel-rpms/kernel-core-*.rpm \
      /tmp/kernel-rpms/kernel-modules-*.rpm

# TODO: Figure out why akmods cache is pulling in akmods/kernel-devel
dnf5 -y install /tmp/kernel-rpms/kernel-devel-*.rpm

dnf5 versionlock add kernel kernel-devel kernel-devel-matched kernel-core \
      kernel-modules kernel-modules-core kernel-modules-extra

# Everyone
# NOTE: we won't use dnf5 copr plugin for ublue-os/akmods until our upstream
# provides the COPR standard naming
sed -i 's@enabled=0@enabled=1@g' /etc/yum.repos.d/_copr_ublue-os-akmods.repo
if [[ "${UBLUE_IMAGE_TAG}" == "beta" ]]; then
  dnf5 -y install /tmp/akmods/kmods/*xone*.rpm || true
  dnf5 -y install /tmp/akmods/kmods/*openrazer*.rpm || true
  dnf5 -y install /tmp/akmods/kmods/*framework-laptop*.rpm || true
else
  dnf5 -y install \
        /tmp/akmods/kmods/*xone*.rpm \
        /tmp/akmods/kmods/*openrazer*.rpm \
        /tmp/akmods/kmods/*framework-laptop*.rpm
fi

# Nvidia AKMODS
if [[ "${IMAGE_NAME}" =~ nvidia ]]; then
  # Fetch Nvidia RPMs
  if [[ "${IMAGE_NAME}" =~ open ]]; then
    container="docker://ghcr.io/ublue-os/akmods-nvidia-open:${AKMODS_FLAVOR}"
    skopeo copy --retry-times 3 "${container}-$(rpm -E %fedora)-${KERNEL}" \
          dir:/tmp/akmods-rpms
  else
    container="docker://ghcr.io/ublue-os/akmods-nvidia:${AKMODS_FLAVOR}"
    skopeo copy --retry-times 3 "${container}-$(rpm -E %fedora)-${KERNEL}" \
          dir:/tmp/akmods-rpms
  fi
  NVIDIA_TARGZ=$(jq -r '.layers[].digest' </tmp/akmods-rpms/manifest.json |
        cut -d: -f2)
  tar -xvzf /tmp/akmods-rpms/"$NVIDIA_TARGZ" -C /tmp/
  mv /tmp/rpms/* /tmp/akmods-rpms/

  # Exclude the Golang Nvidia Container Toolkit in Fedora Repo
  dnf5 config-manager setopt excludepkgs=golang-github-nvidia-container-toolkit

  # Install Nvidia RPMs
  # Change when nvidia-install.sh updates
  url="https://raw.githubusercontent.com/ublue-os/main/main/build_files"
  curl -LSfso /tmp/nvidia-install.sh \
        "$url/nvidia-install.sh"
  chmod +x /tmp/nvidia-install.sh
  IMAGE_NAME="${BASE_IMAGE_NAME}" RPMFUSION_MIRROR="" /tmp/nvidia-install.sh
  rm -f /usr/share/vulkan/icd.d/nouveau_icd.*.json
  ln -sf libnvidia-ml.so.1 /usr/lib64/libnvidia-ml.so
  kargs='"rd.driver.blacklist=nouveau", "modprobe.blacklist=nouveau", '
  kargs+='"nvidia-drm.modeset=1", '
  kargs+='"initcall_blacklist=simpledrm_platform_driver_init"'
  tee /usr/lib/bootc/kargs.d/00-nvidia.toml <<-EOF
		kargs = [$kargs]
		EOF
fi

echo "::endgroup::"
