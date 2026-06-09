
# MOHAA EasyHost
<img width="791" height="960" alt="Github" src="https://github.com/user-attachments/assets/75b1fd8e-e5bf-476e-8204-f5942570046f" />

A simple one-click server launcher for **Medal of Honor: Allied Assault**.

This tool helps you host a private MOHAA server for your friends without typing long server commands or editing config files manually.

Perfect for:

* Playing with friends
* LAN parties
* VPN hosting
* Private public servers
* Quick testing

---

## What This Does

MOHAA EasyHost can:

* Start a MOHAA dedicated server
* Create the server config automatically
* Show the command your friends need to join
* Copy the friend command to your clipboard
* Change server name, password, maps, time limit, players, and port
* Change gameplay settings like speed, gravity, cheats, and weapon respawn
* Apply simple widescreen and video settings
* Restart or stop the server from the menu

---

## Important

This project does **not** include the game.

You must own a legal copy of **Medal of Honor: Allied Assault**.

Do not upload or share:

* `MOHAA.exe`
* `MOHAA_server.exe`
* `.pk3` files
* Game assets
* Cracks or serials

This repository only contains the launcher script.

---

## Requirements

You need:

* Windows 10 or Windows 11
* PowerShell
* A legal installed copy of Medal of Honor: Allied Assault
* `MOHAA.exe`
* `MOHAA_server.exe`

---

## Setup

### 1. Download the script

Download:

```txt
IMUSTAFSKI Server Runner.ps1
```

from the GitHub release page.

---

### 2. Put it inside your MOHAA folder

Place the script in the same folder as:

```txt
MOHAA.exe
MOHAA_server.exe
main/
```

Example:

```txt
Medal of Honor Allied Assault/
├── MOHAA.exe
├── MOHAA_server.exe
├── IMUSTAFSKI Server Runner.ps1
└── main/
```

---

### 3. Run the launcher

Right-click the script and choose:

```txt
Run with PowerShell
```

Or open PowerShell inside the MOHAA folder and run:

```powershell
.\IMUSTAFSKI Server Runner.ps1
```

---

## If PowerShell Blocks the Script

If Windows blocks the script, open PowerShell and run:

```powershell
Set-ExecutionPolicy -Scope CurrentUser RemoteSigned
```

Then run the launcher again.

---

## How to Host a Server

When you open the launcher, it will start the server automatically.

You will see a command like this:

```txt
connect YOUR-IP:12203
```

Send that command to your friends.

---

## How Friends Join

Your friends should:

1. Open MOHAA
2. Press the console key:

```txt
~
```

3. Type the connect command:

```txt
connect YOUR-IP:12203
```

4. Press Enter

Example:

```txt
connect 123.45.67.89:12203
```

---

## Playing on LAN or VPN

For LAN or VPN play, use the local/VPN command shown in the launcher.

Example:

```txt
connect 192.168.1.20:12203
```

This works well with:

* Same Wi-Fi
* Radmin VPN
* ZeroTier
* Hamachi
* Tailscale

---

## Playing Over the Internet

For public internet hosting, you usually need to open this port on your router:

```txt
UDP 12203
```

Forward UDP port `12203` to the PC that is hosting the server.

Also allow `MOHAA_server.exe` through Windows Firewall.

---

## Main Menu

Use the arrow keys and Enter.

You can also press the hotkeys:

```txt
[G] Open MOHAA
[C] Copy friend command
[E] Server settings
[V] Game settings
[R] Restart server
[B] Rebuild config
[S] Stop server
[Q] Quit launcher
```

---

## Server Settings

From the server settings menu, you can change:

* Server name
* Password
* Map rotation
* Time limit
* Max players
* Port
* Cheats
* Player speed
* Gravity
* Knockback
* Weapon respawn time

After changing settings, choose:

```txt
Apply and restart
```

The launcher will rebuild the config and restart the server.

---

## Map Rotation

To use one map, enter one map:

```txt
dm/mohdm6
```

To rotate multiple maps, separate them with commas:

```txt
dm/mohdm6, dm/mohdm7, dm/mohdm1
```

One map means the server stays on that map.

Multiple maps means the server rotates after the time limit.

---

## Game Settings

The game settings menu can apply:

* 1080p widescreen
* 1440p widescreen
* Custom resolution
* Fullscreen on/off
* Texture settings
* FOV setting
* Skybox cleanup preset

If the game is already open, restart MOHAA after applying video settings.

---

## Files Created by the Launcher

The launcher may create these files:

```txt
imustafski-runner-settings.json
main/imustafski-server.cfg
main/autoexec.cfg
main/configs/unnamedsoldier.cfg
```

It may also create a backup:

```txt
main/configs/unnamedsoldier.cfg.imustafski-backup
```

---

## Common Problems

### My friend cannot join

Check these:

1. The server is running.
2. Your friend used the correct connect command.
3. Windows Firewall allows `MOHAA_server.exe`.
4. UDP port `12203` is forwarded to your PC.
5. Your internet provider is not blocking hosting.

If public hosting does not work, try Radmin VPN, ZeroTier, Hamachi, or Tailscale.

---

### The launcher says the server executable is missing

Make sure this file exists in the same folder as the script:

```txt
MOHAA_server.exe
```

The script must be inside the MOHAA game folder.

---

### The game executable is missing

Make sure this file exists in the same folder as the script:

```txt
MOHAA.exe
```

---

### The server starts but the port is not detected

Try:

1. Restart the launcher
2. Allow the server in Windows Firewall
3. Make sure another server is not already using the same port
4. Change the port from the server settings menu

---

## Recommended GitHub Files

This repository should contain only:

```txt
README.md
LICENSE
IMUSTAFSKI Server Runner.ps1
```

Do not upload the full game folder.

---

## License

This project is released under the MIT License.

You can use it, modify it, and share it freely.

---

## Disclaimer

This is an unofficial community tool.

It is not affiliated with EA, GOG, 2015 Inc., or the official Medal of Honor franchise.

Medal of Honor: Allied Assault belongs to its original copyright owners.

You need a legal copy of the game to use this launcher.
