#!/usr/bin/bash

wallpapersDir="$HOME/Pictures/Wallpapers"
wallpapers=("$wallpapersDir"/*)
history_file="$HOME/.cache/wallpaper_history"
history=()
kitty_sockets=()

[ -f $history_file ] && mapfile -t history < "$history_file"
if (( ${#history[@]} > 6 )); then
    history=("${history[@]: -6}")
fi

#while true; do
    wallpaperId=$(( RANDOM % ${#wallpapers[@]}))
    selectedWallpaper="${wallpapers[$wallpaperId]}"

    in_history=false
    for h in "${history[@]}"; do
    if [[ "$h" == "$selectedWallpaper" ]]; then
        in_history=true
        break
    fi
    done

    swww img -t simple --transition-fps 144 --transition-step 2 $selectedWallpaper
    sd "/.*" $selectedWallpaper ~/.config/swaylock/config
    pal -m an -s 1.2 $selectedWallpaper

    history+=("$selectedWallpaper")
    printf "%s\n" "${history[@]}" > "$history_file"
    if (( ${#history[@]} > 6 )); then
        history=("${history[@]:1}")
    fi

    while IFS= read -r s; do
        kitty_sockets+=("$s")
    done < <(ls /tmp/ 2>/dev/null | grep mykitty)
    
    for s in "${kitty_sockets[@]}"; do
        kitten @ --to "unix:/tmp/$s" set-colors -a "$HOME/.cache/pal/kitty-colors.conf"
    done

    for pid in $(pgrep nvim); do
        nvim --server /run/user/1000/nvim.${pid}.0 --remote-expr "execute('ReloadPal')"
    done

    sleep 3600
#done

