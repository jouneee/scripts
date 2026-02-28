#!/usr/bin/luajit

local socket = require("posix.sys.socket")
local unistd = require("posix.unistd")
local json   = require("dkjson")

local function niri_request(command)
    local sock = assert(socket.socket(socket.AF_UNIX, socket.SOCK_STREAM, 0))
    assert(socket.connect(sock, {family = socket.AF_UNIX, path = os.getenv("NIRI_SOCKET")}))
    assert(socket.send(sock, command .. "\n"))

    local buf = ""
    repeat
        local ch = socket.recv(sock, 4096)
        if not ch or ch == "" then break end
        buf = buf .. ch
    until ch:find("\n", 1, true)

    unistd.close(sock)
    return json.decode(buf)
end

local function get_windows()
    local event, _, _ = niri_request('"FocusedWindow"')
    local focused_id = nil
    if event.Ok then
        focused_id = event.Ok.FocusedWindow.id
    end
    
    event, _, _ = niri_request('"Windows"')
    local window_ids = {}
    if event.Ok then
        local event_windows = event.Ok.Windows
        for i = 1, #event_windows do
            if event_windows[i].id ~= focused_id then
                table.insert(window_ids, {
                    id = event_windows[i].id,
                    wid = event_windows[i].workspace_id
                })
            end
        end
        return window_ids
    else
        return nil
    end
end

local function get_workspace_map()
    local event, _, _ = niri_request('"Workspaces"')
    local workspace_map = {}
    local active_idx = nil
    if event.Ok then
        local workspace_event = event.Ok.Workspaces
        if workspace_event ~= nil then
            for i = 1, #workspace_event do
                local ws = workspace_event[i]
                workspace_map[ws.id] = ws.idx
                if ws.is_active then
                    active_idx = ws.idx
                end
            end
        end
        return workspace_map, active_idx
    else
        return nil
    end
end

local workspace_map, active_idx = get_workspace_map()
local window_ids = get_windows()

for i = 1, #window_ids do
    window_ids[i].wid = workspace_map[window_ids[i].wid]
end

-- reverse sorting workspace indexes 
table.sort(window_ids, function(a,b)
    if a.wid == nil then return false end
    if b.wid == nil then return true end
    return a.wid > b.wid
end)

for i = 1, #window_ids do
    if window_ids[i].id ~= nil and active_idx ~= nil then
        local action = string.format('{"Action": {"MoveWindowToWorkspace": {"window_id":%d, "reference": {"Index": %d}, "focus": false}}}\n', window_ids[i].id, active_idx)
        niri_request(action)
    end
end
