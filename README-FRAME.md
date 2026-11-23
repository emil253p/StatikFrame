# StatikQuest on Steam Frame (standalone)

**Experimental and untested.** A native ARM64 Linux build of StatikQuest that runs on the
Steam Frame itself, without a PC: FEXCore runs the PS4 game's CPU code, Vulkan draws it on the
headset's GPU, and the headset's own SteamVR/OpenXR runtime shows it in stereo with head and
controller tracking. Whether Statik runs fast enough on the headset's chip has not been
verified yet.

The port follows [AstroQuest-Frame](https://github.com/mitch030504/AstroQuest-Frame) by
DieMitchell, which did the same for ASTRO BOT Rescue Mission: its build, launch and install
scripts and its Linux changes to the emulator are the basis of this one.

> Supply your own dumped game. No game files, PS4 firmware or keys are included.

## What you need

- A Steam Frame in **Developer Mode** (for a terminal or SSH, and the devkit shortcut). See
  [Valve's developer-mode setup](https://partner.steamgames.com/doc/steamhardware/steamframe/setup#developer-mode).
- **Steam Linux Runtime 4.0 - Arm64**, installed in Steam on the Frame (the installer opens its
  install page if it is missing).
- Your extracted **Statik: Institute of Retention, CUSA06929** (the folder with `eboot.bin`,
  `sce_sys` and `sce_module`). The PC launcher unpacks the `.pkg`; copy the resulting
  `games/cusa06929` folder from the PC to the Frame, e.g. to `~/Games/Statik/CUSA06929`.

## Build (on the Frame)

The build runs on the headset, inside Valve's Steam Runtime 4 ARM64 SDK container (podman). The
first build downloads the SDK, FEX and dependencies and takes a while; after a change, a rebuild
only recompiles what changed.

```sh
git clone https://github.com/emil253p/statikquest && cd statikquest
git checkout steam-frame-two-hands-res
git submodule update --init --recursive
bash tools/build-frame.sh
```

The result is `build/statikquest-frame/` and `build/StatikQuest-SteamFrame-ARM64.tar.gz`.

## Install and play

```sh
bash build/statikquest-frame/install.sh ~/Games/Statik/CUSA06929
```

The installer copies the app to `~/Applications/statikquest-frame`, remembers the game's folder
and adds **Devkit Game: StatikQuest_Frame** to **Library > Non-Steam**. Start it there in the
headset and close the Steam dashboard so the game gets the controllers. To update after a
rebuild, run the installer again (without the folder) and relaunch.

From a terminal: `~/Applications/statikquest-frame/launch.sh [game folder]`.

## Settings

`~/.local/share/statikquest/settings.txt` (made on the first start; it says what each one does).
The Frame starts with the lightest settings: 60 fps, the game's own sharpness, PS4 Pro mode off.
Raise them once the game runs well. Saves, logs and caches are in
`~/.local/share/statikquest/user`; the log is `user/log/shad_log.txt`.

Controls are as on the PC with Steam Frame controllers: right A ✕, B ○, X □, Y △ (B + Y
blow), left D-pad, View/Menu OPTIONS, bumpers and grips L1/R1, triggers L2/R2, both
controllers hold the box.
