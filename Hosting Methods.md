## Hosting Methods

If you cannot forward ports on your router, use one of these two methods.

---

## Which Method Should You Use

| Situation | Best Method |
|---|---|
| Friends in nearby countries | ZeroTier VPN |
| Friends in Europe, US, or far away | Playit.gg Tunnel |
| Mixed players from everywhere | Run both at the same time |
| You have router access | Port forward UDP 12203 (see Playing Over the Internet) |

---

## Method 1 — ZeroTier VPN (Best for nearby players)

ZeroTier creates a private virtual network between you and your friends.
No router config needed. Free. Best ping for regional players.

Friends must install ZeroTier once. After that, joining is instant.

---

### Host Setup — Do This Once

*Step 1. Create your network*

Go to [my.zerotier.com](https://my.zerotier.com) and create a free account.

Click *Create A Network*.

Copy your *Network ID*. It looks like this:


a1b2c3d4e5f6g7h8


---

*Step 2. Install ZeroTier on your PC*

Download from [zerotier.com/download](https://www.zerotier.com/download) and install it.

ZeroTier appears in your system tray at the bottom right of your screen.

---

*Step 3. Join your own network*

Right-click the ZeroTier tray icon.

Click *Join Network*.

Paste your Network ID and confirm.

---

*Step 4. Authorize your PC*

Go back to [my.zerotier.com](https://my.zerotier.com).

Open your network and scroll to *Members*.

Your PC appears in the list. Tick the *Auth* checkbox next to it.

Your *ZeroTier IP* now appears. It looks like:


10.221.X.X


or


172.22.X.X


This is the IP your friends will use to connect.

---

*Step 5. Set network to Private*

In your network settings on [my.zerotier.com](https://my.zerotier.com), set *Access Control* to *Private*.

This means you manually approve every person who wants to join.
Nobody gets in without your click.

*Step 6. Run The Powershell Script*

The Script will start the server and detects the zerotire vpn like this

<img width="812" height="697" alt="ZeroTier Vpn2" src="https://github.com/user-attachments/assets/7201293b-3246-4dee-b8c2-c54ac089e1c4" />

---

### Friend Setup — Each Player Does This Once

*Step 1.* Download and install ZeroTier from [zerotier.com/download](https://www.zerotier.com/download).

*Step 2.* Right-click the ZeroTier tray icon and click *Join Network*.

*Step 3.* Enter the Network ID the host gave you and confirm.

*Step 4.* Tell the host you joined. Wait for them to authorize you.

*Step 5.* Once authorized, open MOHAA, press ~ and type:


connect HOST-ZEROTIER-IP:12203


Example:


connect 10.221.245.121:12203


Press Enter and you are in.

---

### How to Find Your ZeroTier IP Quickly

Either on The dashboard you will see the ipv4 

Open PowerShell and run:

powershell
Get-NetIPAddress -AddressFamily IPv4 | Where-Object { $_.IPAddress -like "10.2*" -or $_.IPAddress -like "172.2*" } | Select-Object IPAddress


Or check the ZeroTier tray icon. It shows your IP directly.

---

## Method 2 — Playit.gg Tunnel (Best for far away players)

Playit.gg gives you a permanent public address that anyone in the world can connect to.
No router config needed. Free. No VPN required on the friend side.

Best for players in Europe, US, or far away regions.
Ping may be higher for nearby players compared to ZeroTier.

---

### Host Setup

*Step 1. Create a Playit.gg account*

Go to [playit.gg](https://playit.gg) and create a free account.

---

*Step 2. Create a UDP tunnel*

In your Playit.gg dashboard, create a new tunnel.

Set the type to *UDP*.

Set the *Local Port* to 12203.

Save the tunnel. Your public tunnel address appears. It looks like:


something.at.ply.gg:XXXXX


Write down this address. This is what your friends will use.

---

*Step 3. Download the Playit agent*

Download the Playit agent from [playit.gg/download](https://playit.gg/download).

Place playit-windows-x86_64.exe inside your MOHAA folder. or run in the folder a cmd with "playit" it should launch

---

*Step 4. Run both together*

<img width="1917" height="1018" alt="playit gg" src="https://github.com/user-attachments/assets/1a51ffbe-a521-4b75-b214-72104d634ef6" />

Every time you host:

1. Run the IMUSTAFSKI Server Runner script first.
2. Then run the Playit agent separately.

The Playit agent connects to their servers and forwards traffic to your local MOHAA server on port 12203.

---

*Step 5. Give friends the tunnel address*

Send your friends the tunnel address from your Playit dashboard.

Example:


connect something.at.ply.gg:XXXXX


The port in the tunnel address is NOT 12203. Use the port Playit shows.

---

### Friend Setup for Playit

Friends do not need to install anything.

They just open MOHAA, press ~ and type the tunnel address you gave them.


connect something.at.ply.gg:XXXXX


Press Enter and they are in.

---

## Running Both Methods at the Same Time

You can run ZeroTier and Playit.gg at the same time.

Send both commands to your players and let them pick the one with better ping.

---

## Common Problems

### ZeroTier friend cannot connect

Check these:

1. You authorized them on [my.zerotier.com](https://my.zerotier.com) under Members.
2. They are using your ZeroTier IP, not your regular IP.
3. ZeroTier is running on both PCs. Check the system tray.
4. Windows Firewall allows MOHAA_server.exe.

### Playit.gg friend cannot connect

Check these:

1. The Playit agent is running on your PC.
2. Your friend is using the correct tunnel address from your Playit dashboard.
3. The tunnel type is set to UDP, not TCP.
4. The Local Port in your Playit tunnel settings is 12203.

### Ping is too high on Playit

Playit free tier routes through US or EU servers.
For nearby players, use ZeroTier instead. It is always faster for regional connections.

---
