#!/usr/bin/luajit -joff

local lfs = require("lfs")

args = {...}
types = nil

if #args > 0 then
    path = args[1]
    if not path then
        os.exit(1)
    end
    if #args > 1 then
        types = {}
        for i=2, #args do
            local suffix = args[i]
            types[suffix] = true
        end
    end
else
    print("\tProvide path to file or directory. Optionally provide file types to rename.")
    print("\tUsage randomize_filenames <path> <type1> <type2> ...")
    os.exit(0)
end

math.randomseed(os.time())
sets = {{97, 122}, {65, 90}, {48, 57}} -- a-z A-Z 0-9
local function random_string(length)
    local str = ""
    for i = 1, length do
        local charset = sets[math.random(1, #sets)]
        str = str .. string.char(math.random(charset[1], charset[2]))
    end
    return str
end

local function name_suffix(filepath)
    local dir, file = filepath:match("^(.+)/([^/]*)$")
    if file:match("^%.%.?[^%.]") then
        return filepath
    end
    local basename = file:gsub("%.([^%.\\/]+)$", "")
    local suffix = file:match("%.([^%.\\/]+)$")
    return dir, basename, suffix
end

attr = lfs.attributes(path) 
if not attr or attr.mode ~= "file" then
    for filename in lfs.dir(path) do
        local fpath = path:gsub("/$", "")
        local filepath = fpath .. "/" .. filename
        attr = lfs.attributes(filepath)
        if not attr or attr.mode ~= "directory" then
            local dir, basename, suffix = name_suffix(filepath)
            if basename then
                if types then
                    if suffix and types[suffix] then
                        local nn = dir .. "/" .. random_string(10) .. "." .. suffix
                        local fullpath = path .. basename .. "." .. suffix
                        os.rename(fullpath, nn)
                        print("Renamed " .. fullpath .. " to " .. nn)
                    end
                else
                    if suffix then
                        local nn = dir .. "/" .. random_string(10) .. "." .. suffix
                        local fullpath = path .. basename .. "." .. suffix
                        os.rename(fullpath, nn)
                        print("Renamed " .. fullpath .. " to " .. nn)
                    else
                        local nn = dir .. "/" .. random_string(10)
                        local fullpath = path .. basename
                        os.rename(fullpath, nn)
                        print("Renamed " .. fullpath .. " to " .. nn)
                    end
                end
            end
        end
    end
else
    local dir, basename, suffix = name_suffix(path)
    if basename then
        if suffix then
            local nn = dir .. "/" .. random_string(10) .. "." .. suffix
            os.rename(path, nn)
            print("Renamed " .. path .. " to " .. nn)
        else
            local nn = dir .. "/" .. random_string(10)
            os.rename(path, nn)
            print("Renamed " .. path .. " to " .. nn)
        end
    end
end
