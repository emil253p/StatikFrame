#!/usr/bin/env bash
# Builds StatikQuest for Steam Frame standalone: a native ARM64 Linux shadPS4 with embedded
# FEXCore for the PS4's CPU code, Vulkan, and the headset's own SteamVR/OpenXR runtime.
# Run it ON the Frame (or another ARM64 Linux machine with podman), from a clone of this
# repository with its submodules:
#   git clone --recursive https://github.com/emil253p/statikquest && cd statikquest
#   git checkout steam-frame-two-hands-res && git submodule update --init --recursive
#   bash tools/build-frame.sh
# The build runs inside Valve's Steam Runtime 4 ARM64 SDK container, so the result runs under
# Steam Linux Runtime 4.0 - Arm64 on the headset. A rebuild after a change only recompiles
# what changed.
# Adapted from AstroQuest-Frame by DieMitchell (https://github.com/mitch030504/AstroQuest-Frame).
set -euo pipefail
root=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
cd "$root"
[[ $(uname -m) == aarch64 ]] || { echo "Run this build on an ARM64 Linux host (the Frame)." >&2; exit 1; }

sdk=registry.gitlab.steamos.cloud/steamrt/steamrt4/sdk/arm64:4.0.20260805.254769
container=statikquest-build
if [[ ${1:-} != --container ]]; then
  command -v podman >/dev/null || { echo "podman is required." >&2; exit 1; }
  # Over SSH there is no user systemd session for podman to put the container under
  # ("crun: sd-bus call: Process org.freedesktop.systemd1 exited"): podman manages its
  # cgroups itself and logs its events to a file instead.
  podman=(podman --cgroup-manager=cgroupfs --events-backend=file)
  create() {
    "${podman[@]}" create --name "$container" --network host -v "$root:$root" -w "$root" \
      "$sdk" sleep infinity >/dev/null
  }
  if ! "${podman[@]}" container exists "$container"; then
    create
  elif [[ $("${podman[@]}" inspect --format '{{.Config.Image}}' "$container") != "$sdk" ]] ||
       ! "${podman[@]}" start "$container" >/dev/null 2>&1; then
    # Another SDK, or made by an earlier try that could not start: made again (nothing of
    # the build is in it; the source and build folders are this clone's).
    "${podman[@]}" rm -f "$container" >/dev/null
    create
  fi
  "${podman[@]}" start "$container" >/dev/null
  exec "${podman[@]}" exec "$container" bash "$root/tools/build-frame.sh" --container
fi

export DEBIAN_FRONTEND=noninteractive
if [[ ! -e /var/lib/statikquest-deps ]]; then
  apt-get update
  apt-get install -y --no-install-recommends clang lld llvm cmake ninja-build git nodejs \
    pkg-config python3 libx11-dev libxext-dev libxrandr-dev libxcursor-dev libxi-dev \
    libwayland-dev libxkbcommon-dev wayland-protocols libasound2-dev libpulse-dev \
    libudev-dev libusb-1.0-0-dev libvulkan-dev libgl-dev
  touch /var/lib/statikquest-deps
fi
# (The Frame has 16 GB shared with everything else: more jobs than this runs out of memory.)
export CMAKE_BUILD_PARALLEL_LEVEL=${CMAKE_BUILD_PARALLEL_LEVEL:-3}
source_dir="$root/shadps4-arm64-main"
if [[ ! -e "$source_dir/runtime/build/fexcore-smoke-build/FEXCore/Source/libFEXCore.a" ]]; then
  bash "$source_dir/runtime/scripts/build-fexcore-smoke-aarch64.sh"
  "$source_dir/runtime/build/fexcore-smoke-stage/bin/fexcore-smoke"
  "$source_dir/runtime/build/fexcore-smoke-stage/bin/fexcore-guest-harness"
fi

if [[ ! -e "$root/build/frame/build.ninja" ]]; then
  cmake -S "$source_dir" -B "$root/build/frame" -G Ninja \
    -DCMAKE_C_COMPILER=clang -DCMAKE_CXX_COMPILER=clang++ \
    -DCMAKE_BUILD_TYPE=Release -DCMAKE_CXX_SCAN_FOR_MODULES=OFF \
    -DENABLE_FEX_GUEST_CPU=ON -DENABLE_OPENXR=ON -DENABLE_BACHATA_RUNTIME=OFF \
    -DENABLE_USERFAULTFD=OFF -DENABLE_DISCORD_RPC=OFF -DENABLE_UPDATER=OFF
fi
cmake --build "$root/build/frame" --target shadps4
readelf -h "$root/build/frame/shadps4" | grep -q 'Machine:.*AArch64'
strings "$root/build/frame/shadps4" | grep -F 'Steam Frame controller bindings suggested' >/dev/null

stage="$root/build/statikquest-frame"
rm -rf "$stage"
mkdir -p "$stage"
install -m755 "$root/build/frame/shadps4" "$stage/statikquest"
strip "$stage/statikquest"
install -m755 "$root/tools/launch-frame.sh" "$stage/launch.sh"
install -m755 "$root/tools/install-frame.sh" "$stage/install.sh"
install -m644 "$root/tools/frame-settings.txt" "$stage/settings.txt"
install -m644 "$root/pc-vr/default_config.json" "$stage/default_config.json"
cp "$root/LICENSE" "$root/THIRD-PARTY-NOTICES.md" "$root/README-FRAME.md" "$stage/"
while IFS= read -r -d '' notice; do
  destination="$stage/licenses/${notice#"$source_dir/"}"
  mkdir -p "$(dirname "$destination")"
  cp "$notice" "$destination"
done < <(find "$source_dir/externals" "$source_dir/runtime/sources/fex" -type f \
  \( -iname 'LICENSE*' -o -iname 'LICENCE*' -o -iname 'COPYING*' \
     -o -iname 'NOTICE*' -o -iname 'COPYRIGHT*' \) -print0 2>/dev/null)
ldd "$stage/statikquest" | tee "$stage/needed.txt"
if grep -q 'not found' "$stage/needed.txt"; then
  echo "Unresolved runtime libraries; package is incomplete." >&2; exit 1;
fi
tar -C "$root/build" -czf "$root/build/StatikQuest-SteamFrame-ARM64.tar.gz" statikquest-frame
echo "Built $root/build/StatikQuest-SteamFrame-ARM64.tar.gz"
echo "Install or update with: bash $stage/install.sh"
