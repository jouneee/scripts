#!/usr/bin/lua

local lfs = require("lfs")

local program = arg[0]
if #arg < 3 then
    print("Usage: " .. program .. " <string_to_match> <replacement> <filepath>")
    print("Reads lines from file and applies string.gsub per line")
    print("Be mindful when using regex")
    os.exit(1)
end

local init_string = arg[1]
local repl_string = arg[2]
local filepath = arg[3]

local attr, err = lfs.attributes(filepath)
if not attr or attr.mode ~= "file" then
    if attr.mode == "directory" then
        print("Directories unsupported")
        os.exit(1)
    else
        error("Invalid file")
        os.exit(1)
    end
end

local buf = ""
for line in io.lines(filepath) do
    if line:find(init_string) then
        line = string.gsub(line, init_string, repl_string)
    end
    buf = buf .. line .. "\n"
end

local file = io.open(filepath, "w")
file:write(buf)
file:close()