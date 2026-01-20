#!/usr/bin/bash

wallpapersDir="$HOME/Pictures/Wallpapers"
wallpapers=("$wallpapersDir"/*)
history_file="$HOME/.cache/wallpaper_history"
history=()

[ -f $history_file ] && mapfile -t history < "$history_file"
if (( ${#history[@]} > 4 )); then
    history=("${history[@]: -4}")
fi

while true; do
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
    pal -m 0 -s 1.0 -nv $selectedWallpaper

    history+=("$selectedWallpaper")
    printf "%s\n" "${history[@]}" > "$history_file"
    if (( ${#history[@]} > 6 )); then
        history=("${history[@]:1}")
    fi

    KITTY_SOCKET=$(ls /tmp/ | grep mykitty)
    echo $KITTY_SOCKET
    if [ -n "$KITTY_SOCKET" ]; then
        kitten @ --to "unix:/tmp/$KITTY_SOCKET" set-colors -a "$HOME/.cache/pal/kitty-colors.conf"
    fi
    for pid in $(pgrep nvim); do
        nvim --server /run/user/1000/nvim.${pid}.0 --remote-expr "execute('ReloadWal')"
    done

    sleep 3600
done

