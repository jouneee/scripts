set directory "$HOME/Pictures/Wallpapers/"
set wallpapers "$directory"/*
set history_file "$HOME/.cache/wallpaper_history"
set wp_history "$(cat $history_file)"

if test (count $wp_history) -gt 6
    set wp_history $wp_history[-6..-1]
end

while true
    set sel_wallpaper $(random choice $wallpapers)
    for h in $wp_history
        if string match $sel_wallpaper $h
            break
        end
    end

    swww img -t simple --transition-fps 144 --transition-step 2 $sel_wallpaper
    $HOME/Documents/code/scripts/replace.lua "/.*" $sel_wallpaper ~/.config/swaylock/config
    pal -m an -s 1.2 $sel_wallpaper

    set wp_history $wp_history $sel_wallpaper
    printf '%s\n' $wp_history > $history_file
    if test $(count $wp_history) > 6
        echo true
        set wp_history $wp_history[2..-1]
    end

    sleep 7200
end
