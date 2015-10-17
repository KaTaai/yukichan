local socket = require "socket"
local serialization = require "serialization"

local config = {}

function loadconfig()
 local f = io.open("config.lua","rb")
 local content = f:read("*a")
 f:close()
 config = serialization.unserialize(dat)
end

function saveconfig()
 local newconfig = serialization.serialize(config)
 local f = io.open("config.lua","rb")
 f:write(newconfig)
 f:close()
end
