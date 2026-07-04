if status is-interactive
    # Starship custom prompt
    command -v starship &> /dev/null && starship init fish | source

    # Direnv + Zoxide
    command -v direnv &> /dev/null && direnv hook fish | source
    command -v zoxide &> /dev/null && zoxide init fish --cmd cd | source

    # Better ls
    command -v eza &> /dev/null && alias ls='eza --icons --group-directories-first -1'

    # Abbrs
    abbr lg 'lazygit'
    abbr gd 'git diff'
    abbr ga 'git add .'
    abbr gc 'git commit -am'
    abbr gl 'git log'
    abbr gs 'git status'
    abbr gst 'git stash'
    abbr gsp 'git stash pop'
    abbr gp 'git push'
    abbr gpl 'git pull'
    abbr gsw 'git switch'
    abbr gsm 'git switch main'
    abbr gb 'git branch'
    abbr gbd 'git branch -d'
    abbr gco 'git checkout'
    abbr gsh 'git show'

    abbr l 'ls'
    abbr ll 'ls -l'
    abbr la 'ls -a'
    abbr lla 'ls -la'

    abbr u 'sudo pacman -Syyu'
abbr upd 'sudo pacman -Syyu'
abbr up 'sudo pacman -Syyu'
abbr update 'sudo pacman -Syyu'
abbr udpate 'sudo pacman -Syyu'
abbr upate 'sudo pacman -Syyu'
abbr updte 'sudo pacman -Syyu'
abbr updqte 'sudo pacman -Syyu'

# --- Pacman abbreviations ---
abbr sps 'sudo pacman -S'
abbr spr 'sudo pacman -R'
abbr sprs 'sudo pacman -Rs'
abbr sprdd 'sudo pacman -Rdd'
abbr spqo 'sudo pacman -Qo'
abbr spsii 'sudo pacman -Sii'
abbr pac 'sudo pacman --color auto'

# --- Paru/AUR abbreviations ---
abbr upqll 'paru -Syu --noconfirm'
abbr upal 'paru -Syu --noconfirm'
abbr ua 'paru -Syu --noconfirm'
abbr pksyua 'paru -Syu --noconfirm'
abbr upall 'paru -Syu --noconfirm'
abbr upa 'paru -Syu --noconfirm'
abbr paruskip 'paru -S --mflags --skipinteg'
abbr yayskip 'yay -S --mflags --skipinteg'
abbr trizenskip 'trizen -S --skipinteg'

# --- System abbreviations ---
abbr cd.. 'cd ..'
abbr pdw 'pwd'
abbr upsh './up.sh'
abbr userlist 'cut -d: -f1 /etc/passwd | sort'
abbr merge 'xrdb -merge ~/.Xresources'
abbr psa 'ps auxf'
abbr psgrep 'ps aux | grep -v grep | grep -i -e VSZ -e'

# --- Keyboard layout abbreviations ---
abbr give-me-azerty-be 'sudo localectl set-x11-keymap be'
abbr give-me-qwerty-us 'sudo localectl set-x11-keymap us'
abbr setlocale 'sudo localectl set-locale LANG=en_US.UTF-8'
abbr setlocales 'sudo localectl set-x11-keymap be && sudo localectl set-locale LANG=en_US.UTF-8'

# --- Pacman locks abbreviations ---
abbr unlock 'sudo rm /var/lib/pacman/db.lck'
abbr rmpacmanlock 'sudo rm /var/lib/pacman/db.lck'

# --- GPU/System info abbreviations ---
abbr whichvga '/usr/local/bin/kiro-which-vga'
abbr hw 'hwinfo --short'
abbr audio 'pactl info | grep "Server Name"'
abbr microcode 'grep . /sys/devices/system/cpu/vulnerabilities/*'
abbr howold 'sudo lshw | grep -B 3 -A 8 BIOS'
abbr cpu 'cpuid -i | grep uarch | head -n 1'
abbr kernel 'ls /usr/lib/modules'
abbr kernels 'ls /usr/lib/modules'

# --- Font cache abbreviations ---
abbr update-fc 'sudo fc-cache -fv'

# --- Backup skel abbreviations ---
abbr bupskel 'cp -Rf /etc/skel ~/.skel-backup-(date +%Y.%m.%d-%H.%M.%S)'

# --- Shell switching abbreviations ---
abbr cb 'cp /etc/skel/.bashrc ~/.bashrc && exec bash'
abbr cz 'cp /etc/skel/.zshrc ~/.zshrc && echo "Copied."'
abbr cf 'cp /etc/skel/.config/fish/config.fish ~/.config/fish/config.fish && echo "Copied."'
abbr tobash 'sudo chsh $USER -s /bin/bash && echo "Now log out."'
abbr tozsh 'sudo chsh $USER -s /bin/zsh && echo "Now log out."'
abbr tofish 'sudo chsh $USER -s /bin/fish && echo "Now log out."'

# --- Display managers abbreviations ---
abbr tolightdm 'sudo pacman -S lightdm lightdm-gtk-greeter lightdm-gtk-greeter-settings --noconfirm --needed ; sudo systemctl enable lightdm.service -f ; echo "Lightm is active - reboot now"'
abbr tosddm 'sudo pacman -S sddm --noconfirm --needed ; sudo systemctl enable sddm.service -f ; echo "Sddm is active - reboot now"'
abbr toly 'sudo pacman -S ly --noconfirm --needed ; sudo systemctl enable ly.service -f ; echo "Ly is active - reboot now"'
abbr togdm 'sudo pacman -S gdm --noconfirm --needed ; sudo systemctl enable gdm.service -f ; echo "Gdm is active - reboot now"'
abbr tolxdm 'sudo pacman -S lxdm --noconfirm --needed ; sudo systemctl enable lxdm.service -f ; echo "Lxdm is active - reboot now"'
abbr toemptty 'sudo pacman -S emptty --noconfirm --needed ; sudo systemctl enable emptty.service -f ; echo "Emptty is active - reboot now"'

# --- Kill process abbreviations ---
abbr kc 'killall conky'
abbr kp 'killall polybar'
abbr kpi 'killall picom'

# --- Mirror abbreviations ---
abbr mirror 'sudo reflector -f 30 -l 30 --number 10 --verbose --save /etc/pacman.d/mirrorlist'
abbr mirrord 'sudo reflector --latest 30 --number 10 --sort delay --save /etc/pacman.d/mirrorlist'
abbr mirrors 'sudo reflector --latest 30 --number 10 --sort score --save /etc/pacman.d/mirrorlist'
abbr mirrora 'sudo reflector --latest 30 --number 10 --sort age --save /etc/pacman.d/mirrorlist'
abbr mirrorx 'sudo reflector --age 6 --latest 20  --fastest 20 --threads 5 --sort rate --protocol https --save /etc/pacman.d/mirrorlist'
abbr mirrorxx 'sudo reflector --age 6 --latest 20  --fastest 20 --threads 20 --sort rate --protocol https --save /etc/pacman.d/mirrorlist'
abbr ram 'rate-mirrors --allow-root --disable-comments arch | sudo tee /etc/pacman.d/mirrorlist'
abbr rams 'rate-mirrors --allow-root --disable-comments --protocol https arch  | sudo tee /etc/pacman.d/mirrorlist'

# --- VMware abbreviations ---
abbr start-vmware 'sudo systemctl enable --now vmtoolsd.service'
abbr vmware-start 'sudo systemctl enable --now vmtoolsd.service'
abbr sv 'sudo systemctl enable --now vmtoolsd.service'

# --- YouTube download abbreviations ---
abbr yta-aac 'yt-dlp --extract-audio --audio-format aac'
abbr yta-best 'yt-dlp --extract-audio --audio-format best'
abbr yta-flac 'yt-dlp --extract-audio --audio-format flac'
abbr yta-mp3 'yt-dlp --extract-audio --audio-format mp3'
abbr ytv-best 'yt-dlp -f "bestvideo[ext=mp4]+bestaudio[ext=m4a]/bestvideo+bestaudio" --merge-output-format mp4'

# --- Package management abbreviations ---
abbr rip 'expac --timefmt="%Y-%m-%d %T" "%l\t%n %v" | sort | tail -200 | nl'
abbr riplong 'expac --timefmt="%Y-%m-%d %T" "%l\t%n %v" | sort | tail -3000 | nl'
abbr cleanup 'sudo pacman -Rns (pacman -Qtdq)'
abbr list 'sudo pacman -Qqe'
abbr listt 'sudo pacman -Qqet'
abbr listaur 'sudo pacman -Qqem'
abbr big 'expac -H M "%m\t%n" | sort -h | nl'

# --- Clean screen abbreviations ---
abbr clean 'clear; seq 1 (tput cols) | sort -R | sparklines | lolcat'
abbr cls 'clear; seq 1 (tput cols) | sort -R | sparklines | lolcat'

# --- Search abbreviations ---
abbr rg 'rg --sort path'

# --- Journalctl abbreviations ---
abbr jctl 'journalctl -p 3 -xb'
abbr jclean 'sudo journalctl --rotate && sudo journalctl --vacuum-time=1s'

# --- Edit configs abbreviations ---
abbr nlxdm 'sudo $EDITOR /etc/lxdm/lxdm.conf'
abbr nlightdm 'sudo $EDITOR /etc/lightdm/lightdm.conf'
abbr npacman 'sudo $EDITOR /etc/pacman.conf'
abbr ncalamareslog 'sudo $EDITOR /var/log/Calamares.log'
abbr nmakepkg 'sudo $EDITOR /etc/makepkg.conf'
abbr nmkinitcpio 'sudo $EDITOR /etc/mkinitcpio.conf'
abbr nmirrorlist 'sudo $EDITOR /etc/pacman.d/mirrorlist'
abbr nchaoticmirrorlist 'sudo $EDITOR /etc/pacman.d/chaotic-mirrorlist'
abbr nsddm 'sudo $EDITOR /etc/sddm.conf'
abbr nsddmk 'sudo $EDITOR /etc/sddm.conf.d/kde_settings.conf'
abbr nsddmd 'sudo $EDITOR /usr/lib/sddm/sddm.conf.d/default.conf'
abbr nfstab 'sudo $EDITOR /etc/fstab'
abbr nnsswitch 'sudo $EDITOR /etc/nsswitch.conf'
abbr nsamba 'sudo $EDITOR /etc/samba/smb.conf'
abbr ngnupgconf 'sudo $EDITOR /etc/pacman.d/gnupg/gpg.conf'
abbr nhosts 'sudo $EDITOR /etc/hosts'
abbr nhostname 'sudo $EDITOR /etc/hostname'
abbr nresolv 'sudo $EDITOR /etc/resolv.conf'
abbr nb '$EDITOR ~/.bashrc'
abbr nz '$EDITOR ~/.zshrc'
abbr nf '$EDITOR ~/.config/fish/config.fish'
abbr nneofetch '$EDITOR ~/.config/neofetch/config.conf'
abbr nfastfetch '$EDITOR ~/.config/fastfetch/config.jsonc'
abbr nplymouth 'sudo $EDITOR /etc/plymouth/plymouthd.conf'
abbr nvconsole 'sudo $EDITOR /etc/vconsole.conf'
abbr nenvironment 'sudo $EDITOR /etc/environment'
abbr nloader 'sudo $EDITOR /boot/efi/loader/loader.conf'
abbr nrefind 'sudo $EDITOR /boot/refind_linux.conf'
abbr nalacritty 'nano /home/$USER/.config/alacritty/alacritty.toml'
abbr nemptty 'sudo $EDITOR /etc/emptty/conf'
abbr nkitty '$EDITOR ~/.config/kitty/kitty.conf'

# --- View logs abbreviations ---
abbr lcalamares 'bat /var/log/Calamares.log'
abbr lpacman 'bat /var/log/pacman.log'
abbr lxorg 'bat /var/log/Xorg.0.log'
abbr lxorgo 'bat /var/log/Xorg.0.log.old'

# --- Sublime text logs abbreviations ---
abbr scal 'subl /var/log/Calamares.log'
abbr spac 'subl /etc/pacman.conf'

# --- GPG fixes abbreviations ---
abbr gpg-check 'gpg2 --keyserver-options auto-key-retrieve --verify'
abbr fix-gpg-check 'gpg2 --keyserver-options auto-key-retrieve --verify'
abbr gpg-retrieve 'gpg2 --keyserver-options auto-key-retrieve --receive-keys'
abbr fix-gpg-retrieve 'gpg2 --keyserver-options auto-key-retrieve --receive-keys'
abbr fix-keyserver '[ -d ~/.gnupg ] || mkdir ~/.gnupg ; cp /etc/pacman.d/gnupg/gpg.conf ~/.gnupg/ ; echo "done"'
abbr fix-permissions 'sudo chown -R $USER:$USER ~/.config ~/.local'

# --- Kiro fix scripts abbreviations ---
abbr keyfix '/usr/local/bin/kiro-fix-pacman-keys'
abbr key-fix '/usr/local/bin/kiro-fix-pacman-keys'
abbr keys-fix '/usr/local/bin/kiro-fix-pacman-keys'
abbr fixkey '/usr/local/bin/kiro-fix-pacman-keys'
abbr fixkeys '/usr/local/bin/kiro-fix-pacman-keys'
abbr fix-key '/usr/local/bin/kiro-fix-pacman-keys'
abbr fix-keys '/usr/local/bin/kiro-fix-pacman-keys'
abbr fix-pacman-conf '/usr/local/bin/kiro-fix-pacman-conf'
abbr fix-pacman-keyserver '/usr/local/bin/kiro-fix-gpg-conf'
abbr fix-archlinux-mirrors '/usr/local/bin/kiro-fix-mirrors'

# --- Other abbreviations ---
abbr unhblock 'hblock -S none -D none'
abbr probe 'sudo kiro-probe'
abbr sysfailed 'systemctl list-units --failed'
abbr ssn 'sudo shutdown now'
abbr sr 'reboot'
abbr xd 'ls /usr/share/xsessions'
abbr xdw 'ls /usr/share/wayland-sessions'
abbr rmgitcache 'rm -r ~/.cache/git'
abbr grh 'git reset --hard'
abbr pamac-unlock 'sudo rm /var/tmp/pamac/dbs/db.lock'

# --- Quick navigation abbreviations ---
abbr .. 'cd ..'
abbr ... 'cd ../..'
abbr .... 'cd ../../..'
abbr ~ 'cd ~'
abbr - 'cd -'

# --- Common command abbreviations ---
abbr ff 'fastfetch'
abbr neo 'fastfetch'
abbr vim 'nvim'
abbr vi 'nvim'
abbr nv 'nvim'
abbr bat 'bat'
abbr cat 'bat'
abbr s 'sudo'
abbr se 'sudo -e'
abbr c 'claude'
abbr claude 'claude'
abbr grep 'grep --color=auto'
abbr egrep 'egrep --color=auto'
abbr fgrep 'fgrep --color=auto'
abbr df 'df -h'
abbr free 'free -mt'
abbr wget 'wget -c'
abbr ls 'eza --icons --group-directories-first -1'
abbr l 'ls'
abbr ll 'ls -l'
abbr la 'ls -a'
abbr lla 'ls -la'

    # Custom colours
    if isatty stdout
        cat ~/.local/state/caelestia/sequences.txt 2> /dev/null
    end

    # For jumping between prompts in foot terminal
    function mark_prompt_start --on-event fish_prompt
        echo -en "\e]133;A\e\\"
    end

    # Custom fish config
    source ~/.config/caelestia/user-config.fish 2> /dev/null
end
set -gx QML2_IMPORT_PATH "$HOME/.local/lib/qt6/qml"
set -gx CAELESTIA_LIB_DIR "$HOME/.local/lib/caelestia"
