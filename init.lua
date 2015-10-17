local socket = require "socket"
local serialization = require "serialization"

local config = {}

function loadconfig()
 local f = io.open("./config.lua","rb")
 local content = f:read("*a")
 f:close()
 print(content)
 config = serialization.unserialize(content)
end

function saveconfig()
 local newconfig = serialization.serialize(config)
 local f = io.open("config.lua","rb")
 f:write(newconfig)
 f:close()
end

function reply(chan,msg)

end

function os.sleep(n)
 os.execute("sleep ".. tostring(tonumber(n)))
end

function parse(line)
 if string.find(line, "PING :") == 1 then
  local _,pingid = string.match(line,"([^,]+):([^,]+)")
  writeln("PONG :"..pingid)
  print("Pinged: "..pingid)
 end
end

function main()
 print("Loading config.")
 loadconfig()
 print("Config loaded, resolving "..config.server)
 local ip = socket.dns.toip(config.server)
 print("Opening connection to "..ip)
 local connection = socket.connect(ip,config.port)
 function writeln(l) connection:send(l.."\n") end
 connection:settimeout(10)
 print("Connected!")
 os.sleep(1)
 connection:receive() -- drop a line
 print("Logging in.")
 connection:send("NICK "..config.nick.."\n")
 connection:send("USER "..config.username.." "..config.hostname.." "..config.servername.." "..config.realname.."\n")
 repeat
  line = connection:receive()
  print(line)
 until line == nil
 print("Sent everything relevant. Joining channels.")
 for k,v in pairs(config.channels) do
  connection:send("JOIN " .. v.."\n")
 end
 repeat
  line = connection:receive()
  if line ~= nil and line ~= "timeout" then
   print(line)
   parse(line)
  end
  if line == nil then line = "" end
 until string.find(line,"ERROR :Closing link:") ~= nil
 print(connection:receive())
end

main()
