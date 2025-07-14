#!/bin/bash

VERSION="v0.1.6" 

declare -A config

# Packages Constants
config["ext_pkg_cpu_types"]="amd-ucode intel-ucode"
config["ext_pkg_gpu_types"]="vulkan-radeon vulkan-intel nvidia"
config["ext_pkg_dual_os"]="os-prober"
config["ext_pkg_uefi"]="efibootmgr"
config["base_packages"]="base linux linux-firmware sudo grub dosfstools mtools helix networkmanager git base-devel cliphist unrar 7zip noto-fonts-emoji ttf-jetbrains-mono-nerd zsh zsh-autosuggestions zsh-syntax-highlighting starship aria2 ssh-tools rustup power-profiles-daemon"
config["useful_packages"]="vlc telegram-desktop thunderbird rhythmbox libreoffice-fresh"
config["kde_desktop_environment_packages"]="sddm breeze breeze-gtk breeze-plymouth drkonqi kde-gtk-config kgamma kinfocenter kmenuedit kpipewire kscreen kscreenlocker ksystemstats kwin libkscreen libksysguard ocean-sound-theme plasma-desktop plasma-disks plasma-firewall plasma-nm plasma-pa plasma-systemmonitor plasma-workspace plasma-workspace-wallpapers plymouth-kcm polkit-kde-agent powerdevil print-manager sddm-kcm systemsettings ark dolphin elisa ffmpegthumbs gwenview kamera kcalc kclock kdeconnect konsole okular partitionmanager spectacle"
config["gnome_desktop_environment_packages"]=""
config["xfce_desktop_environment_packages"]=""
config["hyprland_desktop_environment_packages"]="hyprland uwsm greetd-regreet kitty  pipewire wireplumber dunst libnotify xdg-desktop-portal-hyprland xdg-desktop-portal-gtk hyprpolkitagent qt5-wayland qt6-wayland waybar hyprpaper rofi brightnessctl"

TOTAL_NUMBER_OF_QUESTIONS=18

READ_CONFIG_FROM_USER=1
# Configurations
config["disk_name"]="/dev/vda"
config["uefi_partition"]="null"
config["boot_partition"]="null"
config["root_partition"]="/dev/vda1"
config["home_partition"]="null"
config["swap_partition"]="null"
config["boot_partition_format"]="null"
config["root_partition_format"]="ext4"
config["home_partition_format"]="null"
config["mirror_country"]="Iran"
config["region_city"]="Asia/Tehran"
config["system_name"]=""
config["username"]=""
config["dual_boot"]="false"
config["desktop_environment"]="KDE"
config["partition_disk"]="false"
config["gpu_type"]="NVIDIA"

save_config() {
    cat > config.txt <<EOF
${config["disk_name"]}
${config["uefi_partition"]}
${config["boot_partition"]}
${config["root_partition"]}
${config["home_partition"]}
${config["swap_partition"]}
${config["boot_partition_format"]}
${config["root_partition_format"]}
${config["home_partition_format"]}
${config["mirror_country"]}
${config["region_city"]}
${config["system_name"]}
${config["username"]}
${config["dual_boot"]}
${config["desktop_environment"]}
${config["partition_disk"]}
${config["gpu_type"]}
EOF
}

load_config() {
    mapfile -t lines < config.txt
    config["disk_name"]="${lines[0]}"
    config["uefi_partition"]="${lines[1]}"
    config["boot_partition"]="${lines[2]}"
    config["root_partition"]="${lines[3]}"
    config["home_partition"]="${lines[4]}"
    config["swap_partition"]="${lines[5]}"
    config["boot_partition_format"]="${lines[6]}"
    config["root_partition_format"]="${lines[7]}"
    config["home_partition_format"]="${lines[8]}"
    config["mirror_country"]="${lines[9]}"
    config["region_city"]="${lines[10]}"
    config["system_name"]="${lines[11]}"
    config["username"]="${lines[12]}"
    config["dual_boot"]="${lines[13]}"
    config["desktop_environment"]="${lines[14]}"
    config["partition_disk"]="${lines[15]}"
    config["gpu_type"]="${lines[16]}"
}

save_checkpoint() {
    save_config
    step=$((step + 1))
    echo "$step" > step.txt
}

load_checkpoint() {
    if [[ -s "step.txt" ]]; then
        step=$(<step.txt)
        if [[ $step > 1 ]]; then
            load_config
        fi
    else
        if [[ $READ_CONFIG_FROM_USER = 1 ]]; then
            step=1
        else
            step=2
        fi
    fi
}

print_title() {
    local title="$1"
    printf "\n<===== $title =====>\n"
}

question_boolean() {
    local question="$1"
    while true; do
        printf "\n" >&2
        read -p "$question" answer
        case "$answer" in
        [yY]) echo "$answer"; break ;;
        [nN]) echo "$answer"; break ;;
        *) ;;
        esac
    done
}

question_options() {
    local max_number="$1"
    local question="$2"
    while true; do
        printf "\n" >&2
        read -p "$question" answer
        case "$answer" in
            [1-${max_number}]) echo "$answer"; break ;;
            *) ;;
        esac
    done
}

question_string() {
    local repeat_if_empty=$1
    local question="$2"
    while true; do
        printf "\n" >&2
        read -p "$question" answer
        if [[ $repeat_if_empty = 0 || "$answer" != "" ]]; then
            echo "$answer"
            break
        fi
    done
}

question_password() {
    local question1="$1"
    local question2="$2"
    while true; do
        printf "\n" >&2
        read -s -p "$question1" answer1
        if [[ "$answer1" != "" ]]; then
            printf "\n\n" >&2
            read -s -p "$question2" answer2
            if [[ "$answer1" == "$answer2" ]]; then
                echo "$answer1"
                break
            fi
        fi
    done
}

not_null() {
    local config="$1"
    if [[ -n "$config" && "$config" != "null" ]]; then
        echo 1
    else
        echo 0
    fi
}

find_and_save_good_mirrors() {
    local mirror_country="$1"
    local saving_path="$2"

    if [[ "$(not_null "$mirror_country")" == "1" ]]; then
        reflector --latest 10 --country "$mirror_country" --protocol https --sort rate --save "$saving_path"
    else
        reflector --latest 10 --protocol https --sort rate --save "$saving_path"
    fi
}

config_pacman() {
    local saving_path="$1"
    sed -i -e "s/#Color/Color/" "$saving_path" -e "s/#VerbosePkgLists/VerbosePkgLists\nILoveCandy/" "$saving_path"
}

printf "\nArch Linux Setup - $VERSION\n"

load_checkpoint

while [[ true ]]; do
    case $step in
        1)
            print_title "Getting Info"

            printf "\n" >&2

            lsblk
            
            config["disk_name"]="$(question_string 1 "Enter Disk Name [01/$TOTAL_NUMBER_OF_QUESTIONS]: ")"
            config["uefi_partition"]="$(question_string 0 "Enter UEFI Partition Name [02/$TOTAL_NUMBER_OF_QUESTIONS]: ")"
            config["boot_partition"]="$(question_string 0 "Enter Boot Partition Name [03/$TOTAL_NUMBER_OF_QUESTIONS]: ")"
            config["root_partition"]="$(question_string 1 "Enter Root Partition Name [04/$TOTAL_NUMBER_OF_QUESTIONS]: ")"
            config["home_partition"]="$(question_string 0 "Enter Home Partition Name [05/$TOTAL_NUMBER_OF_QUESTIONS]: ")"
            config["swap_partition"]="$(question_string 0 "Enter Swap Partition Name [06/$TOTAL_NUMBER_OF_QUESTIONS]: ")"
            config["boot_partition_format"]="$(question_string 0 "Enter Boot Partition Format [07/$TOTAL_NUMBER_OF_QUESTIONS]: ")"
            config["root_partition_format"]="$(question_string 0 "Enter Root Partition Format [08/$TOTAL_NUMBER_OF_QUESTIONS]: ")"
            config["home_partition_format"]="$(question_string 0 "Enter Home Partition Format [09/$TOTAL_NUMBER_OF_QUESTIONS]: ")"
            config["mirror_country"]="$(question_string 0 "Enter Mirror Country [10/$TOTAL_NUMBER_OF_QUESTIONS]: ")"
            config["region_city"]="$(question_string 1 "Enter Region City [11/$TOTAL_NUMBER_OF_QUESTIONS]: ")"
            config["system_name"]="$(question_string 1 "Enter System Name [12/$TOTAL_NUMBER_OF_QUESTIONS]: ")"
            config["username"]="$(question_string 1 "Enter Username [13/$TOTAL_NUMBER_OF_QUESTIONS]: ")"
            answer="$(question_boolean "Do You Want To Dual Boot? (y/n) [14/$TOTAL_NUMBER_OF_QUESTIONS]: ")"
            if [[ "$answer" == "y" || "$answer" == "Y" ]]; then
                config["dual_boot"]="true"
            else
                config["dual_boot"]="false"
            fi

            answer="$(question_options 4 "Select Your Desktop Environment (KDE[1] GNOME[2] XFCE[3] Hyprland[4] NONE[5]) [15/$TOTAL_NUMBER_OF_QUESTIONS]: ")"
            case "$answer" in
                1) config["desktop_environment"]="KDE" ;;
                2) config["desktop_environment"]="GNOME" ;;
                3) config["desktop_environment"]="XFCE" ;;
                4) config["desktop_environment"]="HYPRLAND" ;;
                5) config["desktop_environment"]="NONE" ;;
                *) ;;
            esac

            cpu_type=""
            answer="$(question_options 2 "Do You Have An AMD[1] Or Intel[2] CPU? [16/$TOTAL_NUMBER_OF_QUESTIONS]: ")"
            set -- ${config["ext_pkg_cpu_types"]}
            if [[ "$answer" == "1" ]]; then
                cpu_type="$1"
            elif [[ "$answer" == "2" ]]; then
                cpu_type="$2"
            fi
            config["base_packages"]="${config["base_packages"]} ${cpu_type}"

            gpu_package=""
            answer=$(question_options 7 "Select Your GPU: AMD[1] Intel[2] Nvidia[4] (You Can Select Multiple Options. Example: All => 7 = 1 + 2 + 3) [17/$TOTAL_NUMBER_OF_QUESTIONS]: ")
            set -- ${config["ext_pkg_gpu_types"]}
            case "$answer" in
                [1]) gpu_package=$1; config["gpu_type"]="AMD" ;;
                [2]) gpu_package=$2; config["gpu_type"]="INTEL" ;;
                [4]) gpu_package=$3; config["gpu_type"]="NVIDIA" ;;
                [3]) gpu_package="$1 $2"; config["gpu_type"]="AMD|INTEL" ;;
                [5]) gpu_package="$1 $3"; config["gpu_type"]="AMD|NVIDIA" ;;
                [6]) gpu_package="$2 $3"; config["gpu_type"]="INTEL|NVIDIA" ;;
                [7]) gpu_package="$1 $2 $3"; config["gpu_type"]="AMD|INTEL|NVIDIA" ;;
                *)  ;;
            esac
            config["base_packages"]="${config["base_packages"]} ${gpu_package}"
            
            answer="$(question_boolean "Do You Want To Partition Your Disk? (y/n) [18/$TOTAL_NUMBER_OF_QUESTIONS]: ")"
            if [[ "$answer" == "y" || "$answer" == "Y" ]]; then
                config["partition_disk"]="true"
            else
                config["partition_disk"]="false"
            fi
            ;;
        2)
            if [[ "${config["partition_disk"]}" == "true" ]]; then
                fdisk "${config["disk_name"]}"
            fi

            timedatectl
            ;;
        3)
            print_title "Formatting Selected Partitions"

            if [[ "$(not_null "${config["uefi_partition"]}")" == "1" ]]; then
                mkfs.fat -F32 "${config["uefi_partition"]}"
            fi

            if [[ "$(not_null "${config["boot_partition"]}")" == "1" && "$(not_null "${config["boot_partition_format"]}")" == "1" ]]; then
                mkfs."${config["boot_partition_format"]}" "${config["boot_partition"]}"
            fi

            if [[ "$(not_null "${config["root_partition"]}")" == "1" && "$(not_null "${config["root_partition_format"]}")" == "1" ]]; then
                mkfs."${config["root_partition_format"]}" "${config["root_partition"]}"
            fi

            if [[ "$(not_null "${config["home_partition"]}")" == "1" && "$(not_null "${config["home_partition_format"]}")" == "1" ]]; then
                mkfs."${config["home_partition_format"]}" "${config["home_partition"]}"
            fi

            if [[ "$(not_null "${config["swap_partition"]}")" == "1" ]]; then
                mkswap "${config["swap_partition"]}"
                swapon "${config["swap_partition"]}"
            fi
            ;;
        4)
            print_title "Mounting Available Partitions"

            if [[ "$(not_null "${config["root_partition"]}")" == "1" ]]; then
                mount "${config["root_partition"]}" /mnt
                printf "\nMounted [Root] (${config["root_partition"]}) At [/mnt]\n"
            fi

            if [[ "$(not_null "${config["boot_partition"]}")" == "1" ]]; then
                mkdir /mnt/boot
                mount "${config["boot_partition"]}" /mnt/boot
                printf "\nMounted [Boot] (${config["boot_partition"]}) At [/mnt/boot]\n"
            fi

            if [[ "$(not_null "${config["uefi_partition"]}")" == "1" ]]; then
                mkdir /mnt/boot/EFI
                mount "${config["uefi_partition"]}" /mnt/boot/EFI
                printf "\nMounted [UEFI] (${config["uefi_partition"]}) At [/mnt/boot/EFI]\n"
            fi

            if [[ "$(not_null "${config["home_partition"]}")" == "1" ]]; then
                mkdir /mnt/home
                mount "${config["home_partition"]}" /mnt/home
                printf "\nMounted [Home] (${config["home_partition"]}) At [/mnt/home]\n"
            fi
            ;;
        5)
            print_title "Finding Some Good Mirrors"

            find_and_save_good_mirrors "${config["mirror_country"]}" "/etc/pacman.d/mirrorlist"
            ;;
        6)
            print_title "Beutifying And Enabling Parallel Downloads For Pacman"

            config_pacman "/etc/pacman.conf"
            ;;
        7)
            print_title "Installing Base Packages"

            if [[ "${config["dual_boot"]}" == "true" ]]; then
                config["base_packages"]="${config["base_packages"]} ${config["ext_pkg_dual_os"]}"
            fi

            if [[ "$(not_null "${config["uefi_partition"]}")" == "1" ]]; then
                config["base_packages"]="${config["base_packages"]} ${config["ext_pkg_uefi"]}"
            fi

            pacstrap -K /mnt ${config["base_packages"]}
            ;;
        8)
            print_title "Finding Some Good Mirrors (On Local Machine's Disk)"
            
            find_and_save_good_mirrors "${config["mirror_country"]}" "/mnt/etc/pacman.d/mirrorlist"
            ;;
        9)
            print_title "Beutifying And Enabling Parallel Downloads For Pacman (On Local Machine's Disk)"

            config_pacman "/mnt/etc/pacman.conf"
            ;;
        10)
            print_title "Installing Desktop Environment And Related Packages"

            case "${config["desktop_environment"]}" in
                KDE) arch-chroot /mnt pacman -Sy ${config["kde_desktop_environment_packages"]} ;;
                GNOME) arch-chroot /mnt pacman -Sy ${config["gnome_desktop_environment_packages"]} ;;
                XFCE) arch-chroot /mnt pacman -Sy ${config["xfce_desktop_environment_packages"]} ;;
                HYPRLAND) arch-chroot /mnt pacman -Sy ${config["hyprland_desktop_environment_packages"]} ;;
            esac
            ;;
        11)
            print_title "Configuring Desktop Environment"

            case "${config["desktop_environment"]}" in
                KDE)
                    arch-chroot /mnt systemctl enable sddm
                    ;;
                GNOME)
                    ;;
                XFCE)
                    ;;
                HYPRLAND)
                    ;;
            esac
            ;;
        12)
            print_title "Generating File System Table"

            genfstab -U /mnt > /mnt/etc/fstab
            ;;
        13)
            print_title "Setting Time Zone"

            arch-chroot /mnt ln -sf "/usr/share/zoneinfo/${config["region_city"]}" /etc/localtime
            ;;
        14)
            print_title "Setting Hardware Clock"

            arch-chroot /mnt hwclock --systohc
            ;;
        15)
            print_title "Generating Locales"

            sed -i "s/#en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/g" /mnt/etc/locale.gen
            arch-chroot /mnt locale-gen
            echo "LANG=en_US.UTF-8" > /etc/locale.conf
            ;;
        16)
            print_title "Setting System Name In Config Files"

            echo "${config["system_name"]}" > "/mnt/etc/hostname"
            echo "127.0.0.1    localhost\n::1          localhost\n127.0.1.1    ${config["system_name"]}.localdomain    ${config["system_name"]}" > "/mnt/etc/hosts"
            ;;
        17)
            print_title "Creating User And Setting It's Configs"

            arch-chroot /mnt useradd -m "${config["username"]}"
            arch-chroot /mnt usermod -aG wheel "${config["username"]}"
            sed -i "s/# %wheel ALL=(ALL:ALL) ALL/%wheel ALL=(ALL:ALL) ALL/g" /mnt/etc/sudoers
            ;;
        18)
            print_title "Setting Root & User Password"

            printf "<Root Password>\n"
            arch-chroot /mnt passwd

            printf "<User Password>\n"
            arch-chroot /mnt passwd "${config["username"]}"
            ;;
        19)
            print_title "Installing GRUB"

            if [[ "$(not_null "${config["uefi_partition"]}")" == "1" ]]; then
                arch-chroot /mnt grub-install --target=x86_64-efi --bootloader-id=grub_uefi --recheck
            else
                arch-chroot /mnt grub-install --target=i386-pc "${config["disk_name"]}"
            fi

            sed -i -e "s/GRUB_TIMEOUT=5/GRUB_TIMEOUT=0/" /mnt/etc/default/grub -e "s/GRUB_CMDLINE_LINUX_DEFAULT=\"loglevel=3 quiet\"/GRUB_CMDLINE_LINUX_DEFAULT=\"loglevel=3\"/" /mnt/etc/default/grub

            if [[ "$(not_null "${config["dual_boot"]}")" == "1" ]]; then
                sed -i "s/#GRUB_DISABLE_OS_PROBER=false/GRUB_DISABLE_OS_PROBER=false/" /mnt/etc/default/grub
            fi

            arch-chroot /mnt grub-mkconfig -o /boot/grub/grub.cfg
            ;;
        20)
            print_title "Enabling NetworkManager Service"

            arch-chroot /mnt systemctl enable NetworkManager
            ;;
        21)
            print_title "Installing Paru AUR Helper"

            arch-chroot -u "${config["username"]}" /mnt git clone https://aur.archlinux.org/paru-bin.git /home/"${config["username"]}"/paru-bin

            if [[ $? -ne 0 ]]; then
                break
            fi

            arch-chroot -u "${config["username"]}" /mnt bash -c "cd /home/"${config["username"]}"/paru-bin && makepkg -si"

            if [[ $? -ne 0 ]]; then
                break
            fi

            rm -r /mnt/home/"${config["username"]}"/paru-bin
            ;;

        22)
            print_title "Configuring Some Nvidia GPU Settings"

            if [[ "${config["gpu_type"]}" == *NVIDIA* ]]; then
                echo "options nvidia_drm modeset=1" > /mnt/etc/modprobe.d/nvidia.conf

                if [[ "${config["gpu_type"]}" == *INTEL* ]]; then
                    sed -i "s/MODULES=()/MODULES=(i915 nvidia nvidia_modeset nvidia_uvm nvidia_drm)/" /etc/mkinitcpio.conf
                else
                    sed -i "s/MODULES=()/MODULES=(nvidia nvidia_modeset nvidia_uvm nvidia_drm)/" /etc/mkinitcpio.conf
                fi

                arch-chroot /mnt mkinitcpio -P

                # This is for Hyprland, put it in a good place for hyprland later.
                # echo "env = LIBVA_DRIVER_NAME,nvidia\nenv = __GLX_VENDOR_LIBRARY_NAME,nvidia"
            fi
            ;;
        23)
            print_title "Installing Some Fonts"

            mkdir -p /mnt/usr/local/share/fonts/v/
            cp ./backup/vazirmatn-v33.003/* /mnt/usr/local/share/fonts/v/
            ;;
        24)
            print_title "Changing The Shell & Restoring Configurations (ZSH, KDE Settings)"

            arch-chroot -u "${config["username"]}" /mnt chsh -s $(which zsh)
            arch-chroot /mnt chsh -s $(which zsh)

            cp -r ./backup/dot_files/. /mnt/home/"${config["username"]}"/
            cp -r ./backup/dot_files/. /mnt/root/
	    chown -R 1000:1000 "/mnt/home/${config["username"]}"
            ;;
        25)
            print_title "Optional Step (Printer & Wifi Driver Installation)"

            answer="$(question_boolean "Do You Want To Install RTL8821CE Driver? (y/n): ")"
            if [[ "$answer" == "y" || "$answer" == "Y" ]]; then
                arch-chroot /mnt sudo pacman -Syu linux-headers dkms bc --needed

                if [[ $? -ne 0 ]]; then
                    break
                fi

                arch-chroot -u "${config["username"]}" /mnt git clone https://github.com/tomaspinho/rtl8821ce.git /home/"${config["username"]}"/Desktop/rtl8821ce

                if [[ $? -ne 0 ]]; then
                    break
                fi

                cat << EOF > /mnt/home/"${config["username"]}"/Desktop/post_installation_script.sh
#!/bin/bash
cd /home/"${config["username"]}"/Desktop/rtl8821ce
./dkms-remove.sh
./dkms-install.sh
sudo rm -r /home/"${config["username"]}"/Desktop/rtl8821ce                
echo "blacklist rtw88_8821ce" | sudo tee /etc/modprobe.d/blacklist.conf
EOF

                chmod +x /mnt/home/"${config["username"]}"/Desktop/post_installation_script.sh                
            fi

            answer="$(question_boolean "Do You Want To Install Canon Printer Driver (cnrdrvcups-lb)? (y/n): ")"
            if [[ "$answer" == "y" || "$answer" == "Y" ]]; then
                cat << EOF >> /mnt/home/"${config["username"]}"/Desktop/post_installation_script.sh
paru -Syu cups cnrdrvcups-lb
systemctl enable cups
EOF
            fi
            ;;
        26)
            answer="$(question_boolean "Do You Want To Install Optimus Manager? (y/n): ")"
            if [[ "$answer" == "y" || "$answer" == "Y" ]]; then
                cat << EOF >> /mnt/home/"${config["username"]}"/Desktop/post_installation_script.sh
paru -Syu optimus-manager
EOF

                case "${config["desktop_environment"]}" in
                KDE)
                    cat << EOF >> /mnt/home/"${config["username"]}"/Desktop/post_installation_script.sh
paru -Syu optimus-manager-qt
EOF
                    ;;
                GNOME)
                    ;;
                XFCE)
                    ;;
                HYPRLAND)
                    ;;
                esac
            fi
            ;;
        27)
            print_title "Installing Some Useful Applications"
            
            arch-chroot /mnt pacman -Syu ${config["useful_packages"]} --needed

            if [[ $? -ne 0 ]]; then
                break
            fi

            cat << EOF >> /mnt/home/"${config["username"]}"/Desktop/post_installation_script.sh
paru -Syu visual-studio-code-bin --needed
EOF
	    chown -R 1000:1000 "/mnt/home/${config["username"]}/Desktop/post_installation_script.sh"

            arch-chroot -u "${config["username"]}" /mnt mkdir -p /home/"${config["username"]}"/Applications/
            
            if [[ $? -ne 0 ]]; then
                break
            fi

            arch-chroot -u "${config["username"]}" /mnt aria2c --continue=true "https://github.com/zen-browser/desktop/releases/latest/download/zen-x86_64.AppImage" -d "/home/"${config["username"]}"/Applications"

            if [[ $? -ne 0 ]]; then
                break
            fi

            arch-chroot -u "${config["username"]}" /mnt aria2c --continue=true "https://github.com/johannesjo/super-productivity/releases/latest/download/superProductivity-x86_64.AppImage" -d "/home/"${config["username"]}"/Applications"

            if [[ $? -ne 0 ]]; then
                break
            fi

            arch-chroot -u "${config["username"]}" /mnt aria2c --continue=true "https://github.com/mattermost-community/focalboard/releases/download/v7.10.6/focalboard-linux.tar.gz" -d "/home/"${config["username"]}"/Applications"

            if [[ $? -ne 0 ]]; then
                break
            fi

            arch-chroot -u "${config["username"]}" /mnt aria2c --continue=true "https://github.com/hiddify/hiddify-app/releases/latest/download/Hiddify-Linux-x64.AppImage" -d "/home/"${config["username"]}"/Applications"

            if [[ $? -ne 0 ]]; then
                break
            fi

            arch-chroot -u "${config["username"]}" /mnt aria2c --continue=true "https://github.com/bepass-org/oblivion-desktop/releases/latest/download/oblivion-desktop-linux-x86_64.AppImage" -d "/home/"${config["username"]}"/Applications"
            ;;
        28)
            print_title "Installation Finished!"

            umount -R /mnt

            break
            ;;
        
    esac
    if [[ $? -ne 0 ]]; then
        break
    fi
    save_checkpoint
    sleep 1
done
