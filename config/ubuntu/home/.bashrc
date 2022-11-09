# ============================================================
# ~/.bashrc for alias / .aliasrc
# ============================================================




# ============================================================
# CONFIG
# ============================================================

alias prf="vim ~/.profile"
alias scfa="source ~/.profile"

# ============================================================
# SHORTCUTS
# ============================================================
alias v="nvim"
alias r="ranger"
alias tl="tree -L 3"
alias w="w3m https://www.google.com"

# ============================================================
# PRODUCTIVITY
# ============================================================
alias shell_bash="chsh -s /bin/bash"
alias shell_zsh="chsh -s /bin/zsh"

# count files
alias count='find . -type f | wc -l'

# dir size
alias sdir='sudo du -sh'

# copy with progressbar (cpv bigfile.flac /run/media/seth/audio/)
alias cpv='rsync -ah --info=progress2'


# ============================================================
# FOLDER NAVIGATION (REPOS)
# ============================================================
alias cd_etc='cd /etc/'
alias cd_nm='cd /etc/NetworkManager/system-connections'
alias cd

# ============================================================
# LIST FILES & FOLDER
# ============================================================
alias ll='ls -alF'
alias la='ls -A'
alias l='ls -CF'
alias lt='ls --human-readable --size -1 -S --classify'
alias lsa="ls -althF"
alias cls='clear'


# ============================================================
# EXPLORER
# ============================================================
alias o='thunar . &'


# ============================================================
# APT
# ============================================================



# ============================================================
# SYS-INFO
# ============================================================
alias unamex="uname -snrvm"

# ============================================================
# BLOCK DEVICES
# ============================================================
alias bootloader="sudo parted /dev/sda print"

# ============================================================
# TIME & DATE
# ============================================================
alias kw='cal -w -b'



















alias geshem="firefox https://www.geshem.cn/en/products/box_pc/CeleronSeries/51.html > /dev/null &"
alias askubuntu="firefox https://www.askubuntu.com > /dev/null &"
alias stackoverflow="firefox https://www.stackoverflow.com > /dev/null &"


# Clean Trash Bin
#alias trash="cd ~/.local/share/Trash/files && rm -rvf *"
#alias trashcan='mv --force -t ~/.local/share/Trash'
#alias trashdir="cd ~/.local/share/Trash/"







# ==========================================================
# HW INFO
# ==========================================================
alias hw_info="inxi -Fxxxz"
alias ssd="df -H"



# ==========================================================
# OpenSSH Server
# ==========================================================
alias sshd_status="sudo systemctl status sshd"
alias sshd_start="sudo systemctl start sshd"
alias sshd_stop="sudo systemctl stop sshd"
alias sshd_restart="sudo systemctl restart sshd"
alias sshd_deactivate="sudo systemctl disable sshd"
alias sshd_activate="sudo systemctl enable sshd"
alias sshd_config="sudo vim /etc/ssh/sshd_config"



# ==========================================================
# SITEMANAGER
# ==========================================================
alias sitemanager_login="ssh polar@gatemanager.intelli-knife.com -p"
alias gatemanager="firefox https://gatemanager.intelli-knife.com/lm"



# ==========================================================
# WIFI
# ==========================================================
alias wifi_connect="sudo nmcli dev wifi connect <mywifi> password <>"

