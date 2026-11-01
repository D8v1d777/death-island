DEATH ISLAND @VERSION@ - MANUAL TEST CANDIDATE
Source: @REVISION@

LINUX ARM64 PORTABLE BUILD
Requires a 64-bit ARM Linux desktop (for example Ubuntu 22.04+), X11/XWayland,
OpenGL 3.3-capable graphics, and the operating system's standard runtime libraries.
This executable does not run on Windows or x86 PCs. Godot is embedded; no editor,
source project, separate PCK, installer, or account is required.

1. Extract the ZIP to a writable directory.
2. Optional: run `sha256sum -c SHA256SUMS.txt` inside the extracted folder.
3. Run `chmod +x death-island.arm64` if your archive utility loses permissions.
4. Double-click death-island.arm64, or run `./death-island.arm64` in a terminal.
5. Choose Dave (the default) or Marie, then select New voyage.

CONTROLS
WASD: move. Shift: sprint. Mouse wheel: zoom. E: gather/talk/use.
Left/right mouse: light/heavy attack. Space: dodge.
Tab: inventory. C: crafting. J: journal. Escape: pause/resume.
1: eat. 2: drink. 3: heal. 4: equip weapon.
Touch: left joystick, right-side action buttons, top menu buttons.
Gamepad: left stick movement, right stick vertical zoom, A interact,
X/Y attacks, B dodge, Start pause, Back inventory.
Menus can scroll; use mouse wheel or touch drag to reach lower options.

TEST BOTH SURVIVORS
Start as Dave; verify the green outfit/brown hair, name and title preview.
Return to title and select Marie; verify blue outfit/dark hair and the MARIE HUD.
During a voyage, Pause -> Switch to Marie/Dave changes the controlled survivor.
Each retains their own inventory, equipment, health and survival values.
The inactive survivor remains in the world. Switch back to recover their pack.
Pause -> Save game -> choose a slot; reload and switch again to check persistence.

FIRST PLAY SESSION
Gather nearby driftwood and stones, open crafting and make a Stone Axe.
Equip it in the inventory. Talk to Mara for the opening quest and recruitment.
Explore, fight a boar, collect loot, cook food at a campfire, and build a shelter.
The farming/expanded-role prototype is unfinished; see RELEASE-NOTES.txt.

SAVES AND LOGS
Linux: ~/.local/share/godot/app_userdata/Death Island/
Saves are in save/ and logs in logs/godot.log. XDG_DATA_HOME overrides the prefix.
Keep a copy of saves before testing older/newer versions. Do not downgrade saves.
Close the window to exit; save from Pause first.

BUG REPORTS
https://github.com/D8v1d777/death-island/issues
Include version/source SHA, OS/CPU/GPU, chosen character, exact steps, expected
versus actual result, a screenshot, and relevant log lines. Never send credentials.

The character art is INTERIM, not final approved-reference artwork. This package
is for personal evaluation; it is not a production or Play Store release.
