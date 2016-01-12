local socket = require "socket"
local serialization = require "serialization"

config = {}
cmds = {}
hooks = {}
timers = {}

function loadconfig()
 local f = io.open("./config.lua","rb")
 local content = f:read("*a")
 f:close()
 print(content)
 config = serialization.unserialize(content)
 hooks = {}
 for k,v in pairs(config.hooks) do
  print("Loading hook "..v)
  local fo=io.open("./hooks/" .. v)
  local c = fo:read("*a")
  local s,f = pcall(load,c)
  fo:close()
  if s then
   table.insert(hooks,#hooks+1,f)
   print("Hook "..v.." loaded")
  else
   print("Hook "..v.." failed to load:")
   print(f)
  end
 end
 cmds = {}
 for k,v in pairs(config.cmds) do
  local fo=io.open("./cmds/" .. v)
  local s,f = pcall(load,fo:read("*a"))
  fo:close()
  if s then
   table.insert(cmds,f)
   print("Command "..v.." loaded")
  else
   print("Command "..v.." failed to load:")
   print(f)
  end
 end
 timers = {}
 for k,v in pairs(config.timers) do
  local fo=io.open("./timers/" .. v)
  local s,f = pcall(load,fo:read("*a"))
  fo:close()
  if s then
   table.insert(timers,f)
   print("Timer "..v.." loaded")
  else
   print("Timer "..v.."Failed to load:")
   print(f)
  end
 end
end

function saveconfig()
 local newconfig = serialization.serialize(config)
 local f = io.open("config.lua","wb")
 f:write(newconfig)
 f:close()
end

function reply(chan,msg)

end

function os.sleep(n)
 os.execute("sleep ".. tostring(tonumber(n)))
end

function checkAdmin(nick)
 local pass=false
 writeln("WHOIS "..nick)
 repeat
  line = readln()
  print(line)
 until line:find("330") ~= nil or line == nil
 print ("Line: "..line)
 if line == nil then return false end -- wat
 local _,e = line:find(nick.." ")
 print("Start: "..tostring(e))
 local n,_ = line:find(" ",e+1)
 print("End: "..tostring(n))
 nick = line:sub(e+1,n-1)
 print("Logged in as "..nick)
 for k,v in pairs(config.admins) do
  if nick == v then
   print(v .. " = " .. nick)
   pass = true
   break
  else
   print(nick .. " != " .. v)
  end
 end
 return pass
end

function addcommand(fname,str)
 -- don't use this without pcall
 cmds[fname] = load(str)
end

leftHanging = {0,false}

function parsemsg(nick,chan,message)
 for k,v in pairs(hooks) do
  print("Running hook "..k)
  local fail,errors = pcall(v,nick,chan,message)
  if not fail then print(errors) end
 end
 if string.find(message,config.prefix) == 1 then
  local command = message:sub(2) .. " "
  if command == "" then return end
  local tCommand = {}
  for word in command:gmatch("%S+") do
   table.insert(tCommand,word)
  end
  if tCommand[1]:lower() == "echo" then
   local s = command:sub(6)
   sendchan(chan,s)
  elseif tCommand[1] == "echochan" then
   local s = command:sub(11 + tCommand[2]:len())
   sendchan(tCommand[2],s)
  elseif tCommand[1]:lower() == "action" then
   local s = command:sub(7)
   sendchan(chan,string.char(1).."ACTION"..s..string.char(1))
  elseif tCommand[1] == "actionchan" then
   local s = command:sub(string.len("actionchan")+2+ tCommand[2]:len())
   sendchan(tCommand[2],string.char(1).."ACTION"..s..string.char(1))
  elseif tCommand[1] == "rawecho" then
   if checkAdmin(nick) then
    writeln(command:sub(9))
   end
  elseif tCommand[1] == "drop" then
   leftHanging = {0, false}
  elseif tCommand[1] == "join" then
   writeln("JOIN "..tCommand[2])
  elseif tCommand[1] == "lua" then
   if checkAdmin(nick) then
    local s = command:sub(4)
    local worked,rval = pcall(load(s))
    sendchan(chan,tostring(worked).." "..tostring(rval))
   end
  elseif tCommand[1] == "whois" then
   writeln("WHOIS "..tCommand[2])
  elseif tCommand[1] == "addcmd" and checkAdmin(nick) then
   --I'll get back to this eventually
  elseif tCommand[1] == "quit" then
   if checkAdmin(nick) then
    sendchan(chan,"Bye! o/")
    writeln("QUIT :Blame telstra.")
    print("Killed by "..nick)
   end
  elseif cmds[tCommand[1]] ~= nil then
   local fail, errors = pcall(cmds[tCommand[1]],nick,chan,tCommand,message)
   if not fail then print(errors) end
  end
 end
end

function parse(line)
 if string.find(line, "PING :") == 1 then
  local _,pingid = string.match(line,"([^,]+):([^,]+)")
  writeln("PONG :"..pingid)
  print("Pinged: "..pingid)
 elseif string.find(line,":") == 1 and string.find(line,"PRIVMSG") ~= nil and string.find(line,"005") == nil then
  local s = string.sub(line,2) -- I
  local nick,s = string.match(s,"([^,]+)!([^,]+)") -- am
  local _,s = string.match(s,"([^,]+) PRIVMSG ([^,]+)") -- a
  local chan, msg = string.match(s,"([^,]+) :([^,]+)") -- terrible
  if chan == config.nick then chan = nick end
  print(nick .. " " .. chan .. " " .. msg) --person
  parsemsg(nick,chan,msg)
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
 function sendchan(chan,msg) writeln("PRIVMSG "..chan.." :"..msg) end
 function readln() return connection:receive() end
 connection:settimeout(1)
 print("Connected!")
 os.sleep(1)
 connection:receive() -- drop a line
 print("Logging in.")
 connection:send("NICK "..config.nick.."\n")
 connection:send("USER "..config.username.." "..config.hostname.." "..config.servername.." "..config.realname.."\n")
 repeat
  line = connection:receive() or ""
  if string.find(line, "PING :") == 1 then
   local _,pingid = string.match(line,"([^,]+):([^,]+)")
   writeln("PONG :"..pingid)
   print("Pinged: "..pingid)
  end 
  if line ~= "" then
   print(line)
  end
 until string.match(line or "","%+i") ~= nil
 os.sleep(2)
 print("Sent everything relevant. Joining channels.")
 if config.autojoin then
  for k,v in pairs(config.channels) do
   connection:send("JOIN " .. v.."\n")
  end
 end
 repeat
  line = connection:receive()
  if line ~= nil and line ~= "timeout" then
   print(line)
   pcall(parse,line)
  end
  for k,v in ipairs(timers) do
   local fail, errors = pcall(v,line)
   if not fail then print(errors) end
  end
  if line == nil then line = "" end
 until string.find(line,"ERROR :Closing link:") ~= nil
 print(connection:receive())
end

main()
