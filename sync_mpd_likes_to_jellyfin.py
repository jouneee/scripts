import subprocess
import requests
import os

JELLYFIN_URL     = "http://localhost:8096"
API_KEY          = "YOUR_API_KEY"
USER_ID          = "YOUR_USER_ID"
MPD_MUSIC_FOLDER = "/path/to/mpd/music"
MPD_LIKE         = "2"

HEADERS = {
        "Authorization": f'MediaBrowser Token="{API_KEY}"',
        "Content-Type": "application/json"
        }

def get_mpd_liked_paths():
    cmd = ['mpc', 'sticker', '', 'find', 'like']
    result = subprocess.run(cmd, capture_output=True, text=True)
    liked_songs = set()

    for line in result.stdout.splitlines():
        if f"like={MPD_LIKE}" in line:
            rel_uri = line.split(f': like=')[0].strip()
            full_path = os.path.normpath(os.path.join(MPD_MUSIC_FOLDER, rel_uri))
            liked_songs.add(full_path)
    return liked_songs

def get_jellyfin_library():
    url = f"{JELLYFIN_URL}/Users/{USER_ID}/Items"
    params = {
            "IncludeItemTypes": "Audio",
            "Recursive": "true",
            "Fields": "Path",
            "Limit": 50000     
            }

    try:
        response = requests.get(url, headers=HEADERS, params=params)
        response.raise_for_status()
        items = response.json().get("Items", [])

        library_map = {}
        for item in items:
            if 'Path' in item:
                path = os.path.normpath(item['Path'])
                is_fav = item.get('UserData', {}).get('IsFavorite', False)
                library_map[path] = {
                    'id': item['Id'],
                    'is_fav': is_fav,
                    'name': item.get('Name', 'Unknown')
                }
        return library_map

    except Exception as e:
        print(f"Error building Jellyfin index: {e}")
        return {}

def set_jellyfin_favourite(item_id, name, status=True):
    url = f"{JELLYFIN_URL}/Users/{USER_ID}/FavoriteItems/{item_id}"

    try:
        if status:
            res = requests.post(url, headers=HEADERS)
            action = "HEARTED"
        else:
            res= requests.delete(url, headers=HEADERS)
            action = "UN-HEARTED"

        if res.status_code == 200:
            print(f"    [{action}] {name}")
        else:
           print(f"    [ERROR] Failed to favorite {name}")
    except Exception as e:
        print(f"    [API ERROR] {e}")

mpd_liked_set = get_mpd_liked_paths()
jf_library = get_jellyfin_library()
for path, data in jf_library.items():
    is_liked_in_mpd = path in mpd_liked_set
    is_fav_in_jf = data['is_fav']
    item_id = data['id']
    name = data['name']

    if is_liked_in_mpd and not is_fav_in_jf:
        set_jellyfin_favourite(item_id, name, status=True)
    elif not is_liked_in_mpd and is_fav_in_jf:
        set_jellyfin_favourite(item_id, name, status=False)