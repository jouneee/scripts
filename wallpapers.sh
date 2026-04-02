#!/usr/bin/bash

wallpapersDir="$HOME/Pictures/Wallpapers"
wallpapers=("$wallpapersDir"/*)
history_file="$HOME/.cache/wallpaper_history"
wallpaper_history=()
kitty_sockets=()

[ -f $history_file ] && mapfile -t wallpaper_history < "$history_file"

if (( ${#wallpaper_history[@]} > 6 )); then
    wallpaper_history=("${wallpaper_history[@]: -6}")
fi

while true; do
    wallpaperId=$(( RANDOM % ${#wallpapers[@]}))
    selectedWallpaper="${wallpapers[$wallpaperId]}"

    is_recent=0
    for h in "${wallpaper_history[@]}"; do
        if [[ "$h" == "$selectedWallpaper" ]]; then
            is_recent=1
            break
        fi
    done

    if ((is_recent == 1)); then
        continue
    fi

    awww img -t simple --transition-fps 144 --transition-step 2 $selectedWallpaper
    $HOME/Documents/code/scripts/replace.lua "/.*" $selectedWallpaper ~/.config/swaylock/config
    pal -m an -s 1.2 $selectedWallpaper

    wallpaper_history+=("$selectedWallpaper")
    if (( ${#wallpaper_history[@]} > 6 )); then
        wallpaper_history=("${wallpaper_history[@]:1}")
    fi
    printf "%s\n" "${wallpaper_history[@]}" > "$history_file"

    # while IFS= read -r s; do
    #     kitty_sockets+=("$s")
    # done < <(ls /tmp/ 2>/dev/null | grep mykitty)
    #
    # for s in "${kitty_sockets[@]}"; do
    #     kitten @ --to "unix:/tmp/$s" set-colors -a "$HOME/.cache/pal/kitty-colors.conf"
    # done

    # for pid in $(pgrep nvim); do
    #     nvim --server /run/user/1000/nvim.${pid}.0 --remote-expr "execute('ReloadPal')"
    # done
    
    sleep 7200
done
