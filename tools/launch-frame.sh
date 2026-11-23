#!/usr/bin/env bash
# Starts Statik on Steam Frame standalone (the Linux counterpart of pc-vr/launch.ps1).
#   launch.sh [extracted game folder] [emulator arguments]
# Settings: ~/.local/share/statikquest/settings.txt (made from the app's settings.txt the first
# time). Saves, logs and caches: ~/.local/share/statikquest/user.
# Adapted from AstroQuest-Frame by DieMitchell (https://github.com/mitch030504/AstroQuest-Frame).
set -euo pipefail
app_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
data="${XDG_DATA_HOME:-$HOME/.local/share}/statikquest"
mkdir -p "$data/user/log"
[[ -f "$data/settings.txt" ]] || cp "$app_dir/settings.txt" "$data/settings.txt"
[[ -f "$data/user/config.json" ]] || cp "$app_dir/default_config.json" "$data/user/config.json"
for name in savedata trophy inputs; do mkdir -p "$data/user/home/1000/$name"; done

# setting <key> <default>: the last key=value line for that key in the settings file.
setting() {
  local value
  value=$(sed -n "s/^[[:space:]]*$1[[:space:]]*=[[:space:]]*//p" "$data/settings.txt" | tail -n 1 | tr -d '\r')
  printf '%s' "${value:-$2}"
}

game=${1:-$(setting game "$HOME/Games/Statik/CUSA06929")}
if [[ $# -gt 0 ]]; then shift; fi
game=${game/#\~/$HOME}
[[ -f "$game/eboot.bin" && -f "$game/sce_sys/param.sfo" ]] || {
  echo "Statik is not at $game: give the extracted game folder (with eboot.bin and sce_sys)," >&2
  echo "or set game= in $data/settings.txt." >&2
  exit 1
}
[[ -f "$game/sce_module/libc.prx" ]] || {
  echo "$game is not a complete copy of the game (sce_module/libc.prx is missing)." >&2; exit 1;
}
game=$(realpath "$game")
runtime="$HOME/.local/share/Steam/steamapps/common/SteamLinuxRuntime_4-arm64/run"
[[ -x "$runtime" ]] || { echo "Install Steam Linux Runtime 4.0 - Arm64 in Steam." >&2; exit 1; }

frame_rate=$(setting frame_rate 60)
case $frame_rate in 60|90|120) ;; *) frame_rate=60 ;; esac
resolution=$(setting resolution game)
case $resolution in game|180|220|260) ;; *) resolution=game ;; esac
pro=$(setting pro 0)

# The game's engine settings, as the PC launcher writes them (see Set-EngineSettings there):
# frame rate and per-eye sharpness. Only a file this launcher wrote is replaced or removed.
mark="; Written by the StatikQuest launcher"
ini_dir="$game/deadlock/saved/config/ps4"
ini="$ini_dir/engine.ini"
if [[ -f "$ini" ]] && ! head -n 1 "$ini" | grep -qF "$mark"; then
  echo "The game's folder has engine settings of its own ($ini); they are left as they are." >&2
else
  morpheus=()
  case $frame_rate in
    90) morpheus+=("PSVRFrameSequence=Render90Scanout90") ;;
    120) morpheus+=("PSVRFrameSequence=Render120Scanout120") ;;
  esac
  if [[ $resolution != game ]]; then
    morpheus+=("bOverrideScreenPercentage=True")
    if [[ $pro != 0 ]]; then
      morpheus+=("ScreenPercentage=145" "ScreenPercentageNeo=$resolution")
    else
      morpheus+=("ScreenPercentage=$resolution" "ScreenPercentageNeo=180")
    fi
  fi
  if [[ ${#morpheus[@]} -eq 0 ]]; then
    rm -f "$ini"
  else
    mkdir -p "$ini_dir"
    {
      echo "$mark for $frame_rate fps, sharpness $resolution."
      echo "[/Script/MorpheusEditor.MorpheusRuntimeSettings]"
      printf '%s\n' "${morpheus[@]}"
      if [[ $frame_rate != 60 ]]; then
        printf '%s\n' "" "[/Script/Engine.Engine]" "bSmoothFrameRate=False" \
          "SmoothedFrameRateRange=(LowerBound=(Type=Inclusive,Value=22),UpperBound=(Type=Exclusive,Value=250))" \
          "" "[SystemSettings]" "t.MaxFPS=0"
      fi
    } >"$ini"
  fi
fi

# What the settings mean to the emulator (as pc-vr/launch.ps1 sets them).
unset $(compgen -e | grep '^SHADPS4_' || true)
export SHADPS4_VR=1 SHADPS4_OPENXR=1 SHADPS4_VR_DEMO=0
export SHADPS4_XR_HEAD=1 SHADPS4_XR_HANDS=1 SHADPS4_XR_GRIPS=1 SHADPS4_XR_CONTROLLERS=1
export SHADPS4_XR_PAUSE=$([[ $(setting pause 1) == 0 ]] && echo 0 || echo 1)
export SHADPS4_VR_SHARPEN=$(setting sharpen 0.3)
export SHADPS4_XR_WAIT=$(setting wait 30)
export SHADPS4_NEO_MODE=$([[ $pro == 0 ]] && echo 0 || echo 1)
export SHADPS4_XR_TWO_HANDS=$([[ $(setting two_hands 1) == 0 ]] && echo 0 || echo 1)
export SHADPS4_XR_RIGHT_STICK=$(setting right_stick both)
[[ $(setting controller_hand right) == left ]] && export SHADPS4_XR_PAD_HAND=left
fov=$(setting fov 110)
[[ $fov != 100 ]] && export SHADPS4_VR_FOV=$fov
[[ $(setting fov_of psvr) != psvr ]] && export SHADPS4_VR_FOV_OF=headset
[[ -n $(setting turn "") ]] && export SHADPS4_VR_TURN=$(setting turn "")
# A phone-class GPU: hand recorded work to the GPU in smaller pieces, and no MSAA.
export SHADPS4_FLUSH_DRAWS=$(setting flush_draws 64)
export SHADPS4_MAX_MSAA=$(setting msaa 1)
# The console's language: settings, else the system's (en_US.UTF-8 -> en-US).
language=$(setting language system)
if [[ $language == system || -z $language ]]; then
  language=${LC_ALL:-${LC_MESSAGES:-${LANG:-en_US}}}
  language=${language%%.*}
  language=${language/_/-}
fi
export SHADPS4_CONSOLE_LANGUAGE=$language
export DISPLAY=${DISPLAY:-:0}

echo "Statik: $game"
echo "Frame rate $frame_rate fps, sharpness $resolution, PS4 Pro mode $([[ $pro == 0 ]] && echo off || echo on), field of view $fov%."
log="$data/user/log/shad_log.txt"
[[ -f "$log" ]] && cp "$log" "$data/user/log/shad_log.prev.txt"
cd "$data"
exec "$runtime" -- "$app_dir/statikquest" -g "$game/eboot.bin" "$@" \
  >"$data/user/log/console.txt" 2>&1
