# Arch on USB

## Purpose
Swiss army knife mainly for cloning and flashing drives and partitions.
Simpler usage than CloneZilla.

The main application has is a simple tui. It needs an arch base system to run as
a LiveSystem from USB drive.

The tui menu is made with whiptail (libnewt on arch).

## Usage

This repo consists of two parts:

1. Linux Image Creator:
- Build the Arch Linux Live System directly on USB with `arch2usb` script.
- Usage: `arch2usb -h`

2. TUI Application:
- Service         - just allowed flash system partition (sdb2)
- Producution     - allowed to flash the whole system (sda)

### TUI Functions
- Clone             - clone functions using patclone
- Flash             - flash functions using partclone
- Tools             - additional tui tools 
- Installer         - Install Linux base systems i.e. with archtail script


## Structure 
- `config/`         - config files stolen from archiso releng
- `tui/`            - the tui menu
- `tui/bin`         - scripts for flashing, cloning, etc 
- `tuo/menu.sh`     - the main tui menu and its submenus


## Further Readings

### Archlinux Wiki
- Boot process - https://wiki.archlinux.org/title/Arch_boot_process

### Whiptail Docs:
- Manpage - https://linux.die.net/man/1/whiptail
- Wiki - https://en.wikibooks.org/wiki/Bash_Shell_Scripting/Whiptail
- Whiptail demo -https://github.com/simudream/Whiptail-demo
- Dialogbox - https://www.dev-insider.de/dialogboxen-mit-whiptail-erstellen-a-860990/
