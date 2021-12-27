# Arkanoid for [MiSTer](https://github.com/MiSTer-devel/Main_MiSTer/wiki)
An FPGA implementation of Arkanoid by Ace, ElectronAsh, Enforcer, Sorgelig, Kitrinx and JimmyStones

## Credits
- Sorgelig: MiSTer project lead, spinner controls
- Ace: Core design
- ElectronAsh: Assistance with core design
- Enforcer: Mouse controls
- JimmyStones: High score saving support & pause feature
- Kitrinx: ROM loader

## Features
- Modelling done at the chip level to match PCB behavior and logic as closely as possible
- Spinner, joystick, mouse and keyboard controls
- High score saving (To save your scores, use the 'Save Settings' option in the OSD)
- T80s CPU by Daniel Wallner with fixes by MikeJ, Sorgelig, and others
- YM2149 core with volume table mixing by MikeJ for accurate mixing down to the PCB's audio distortion
- Accurate audio filtering based on original PCB spectrum analysis
- Option for normalized video timings to use with picky HDTVs and monitors (overclocks the game by ~1.4%)

## Installation
Place `*.rbf` into the "_Arcade/cores" folder on your SD card.  Then, place `*.mra` into the "_Arcade" folder and ROM files from MAME into "games/mame".

### ****ATTENTION****
ROMs are not included. In order to use this arcade core, you must provide the correct ROMs.

To simplify the process, .mra files are provided in the releases folder that specify the required ROMs along with their checksums.  The ROM's .zip filename refers to the corresponding file in the M.A.M.E. project.

Please refer to https://github.com/MiSTer-devel/Main_MiSTer/wiki/Arcade-Roms for information on how to setup and use the environment.

Quick reference for folders and file placement:

/_Arcade/<game name>.mra
/_Arcade/cores/<game rbf>.rbf
/games/mame/<mame rom>.zip
/games/hbmame/<hbmame rom>.zip

## Controls
### Keyboard
| Key | Function |
| --- | --- |
| 1 | 1-Player Start |
| 2 | 2-Player Start |
| 5 | Coin |
| 9 | Service Credit |
| Left/Right arrow keys | Movement |
| CTRL, Space | Fire |
| ALT | Fast |

### Mouse
| Mouse action | Function |
| --- | --- |
| Left/Right button | Fire |
| Left/Right | Movement |

## Known Issues
1) The game contains an MC68705 MCU which is currently not implemented
2) The required ROMs have a few bugs that the MRA files aim to correct, however, the Easy difficulty setting has inaccurate enemy spawns
3) Resolution is incorrectly reported as 256x225

## High Score Save/Load
Save and load of high scores is supported for this core.

- To save your high scores manually, press the 'Save Settings' option in the OSD.  High scores will be automatically loaded when the core is started.
- To enable automatic saving of high scores, turn on the 'Autosave Hiscores' option, press the 'Save Settings' option in the OSD, and reload the core.  High scores will then be automatically saved (if they have changed) any time the OSD is opened.

High score data is stored in /media/fat/config/nvram/ as ```<mra filename>.nvm```
