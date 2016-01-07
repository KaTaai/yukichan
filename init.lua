local socket = require "socket"
local serialization = require "serialization"

local config = {}
local cmds={}

function loadconfig()
 local f = io.open("./config.lua","rb")
 local content = f:read("*a")
 f:close()
 print(content)
 config = serialization.unserialize(content)
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
 if message:find("o/") ~= nil or message:find("\\o") ~= nil and nick ~= "Shocky" and nick ~= "yukichan" then
  if leftHanging[2] == false then
   print (nick .." left hanging at "..os.time())
   local typeOfHighFive="o/"
   if message:find("o/") ~= nil then
    typeOfHighFive = "\\o"
   end
   leftHanging = {os.time(),true,chan,typeOfHighFive}
  elseif leftHanging[2] == true then
   leftHanging = {0,false}
   print("No longer left hanging.")
  end
 end
 if message:find("o/ * \\o") ~= nil and nick == "Shocky" then leftHanging = {0, false} end
 if string.find(message,":") == 1 then
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
   pcall(cmds[tCommand[1]],nick,chan,tCommand,message)
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
 connection:settimeout(2)
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
  print(line)
 until string.match(line or "","%+i") ~= nil
 os.sleep(2)
 print("Sent everything relevant. Joining channels.")
 for k,v in pairs(config.channels) do
  connection:send("JOIN " .. v.."\n")
 end
 repeat
  line = connection:receive()
  if line ~= nil and line ~= "timeout" then
   print(line)
   pcall(parse,line)
  end
  if os.time() > leftHanging[1]+3 and leftHanging[2] then
   print ("Responding to a hanging high-five at "..leftHanging[1])
   sendchan(leftHanging[3],leftHanging[4] or "\\o")
   leftHanging={0,false}
  end
  if line == nil then line = "" end
 until string.find(line,"ERROR :Closing link:") ~= nil
 print(connection:receive())
end

main()
