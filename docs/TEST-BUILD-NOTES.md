## StatikFrame PC VR – test build

### How to update
1. Close the game if it is running.
2. Download the `StatikFrame-…-PC-VR-update.zip` file below and unzip it.
3. Copy its contents over your StatikFrame folder and say yes to replacing files. Your settings, saves and game files are kept.
4. Start **Play Statik VR.bat**.

### What's new
- **Steam Frame controllers:** every button works. A ✕, B ○, X □, Y △ (B + Y = blow), left D-pad, View/Menu = OPTIONS, bumpers/grips = L1/R1, triggers = L2/R2. Right stick = PS4 right stick; click it for R3.
- **Hold the box with both controllers**, like a real DualShock. Tilt and turn it like a steering wheel. Untick "Hold the box with both motion controllers" in the launcher to use one hand.
- **Sharper picture:** choose 200%–300% under Sharpness in the launcher. Higher needs a faster GPU; 260% is the default.
- **Wider view:** Field of view now goes to 120%.

### Tuning (optional)
Add these lines to `pc-vr\settings.local.txt`:
- `box_depth=8` – how far (cm) your hands sit inside the box. Higher = deeper; 0 = at the opening.
- `box_steady=10,30` – if the box twitches with your hands close together, raise these (for example `15,40`); if it feels sluggish, lower them (for example `6,20`).

### If SteamVR buttons are wrong
In SteamVR's controller bindings for **StatikQuest**, pick the default bindings.

### Thanks
StatikFrame is a fork of [Jerware/StatikQuest](https://github.com/Jerware/StatikQuest), built on [AstroQuest](https://github.com/bigmak94/AstroQuest), [shadPS4](https://github.com/shadps4-emu/shadPS4) and [shadps4-arm64](https://github.com/zenithblue-oss/shadps4-arm64). All the credit for Statik in VR goes to them; see the [README](https://github.com/emil253p/statikquest#thanks) for everyone involved.
