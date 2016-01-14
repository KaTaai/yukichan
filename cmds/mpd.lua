local nick,chan,tCommand,message = ...
local mpdHost = "192.168.1.17"
if tCommand[2] == "current" then
 sendchan(chan,io.popen("mpc -h "..mpdHost.." current"):read("*a"))
elseif tCommand[2] == "playlist" then
 io.popen("mpc -h "..mpdHost.." playlist > ~/public_html/mpd-playlist.txt")
 sendchan(chan,"http://lain.shadowkat.science/~izaya/mpd-playlist.txt")
elseif tCommand[2] == "raw" then
 if checkAdmin(nick) then
  local _,s = string.find(message,"raw")
  local restofcommand = message:sub(s+1)
  local data = io.popen("mpc " .. restofcommand .. " | head -n 1"):read("*a")
  sendchan(chan,data)
 else
  sendchan(chan,"Not authorized.")
 end
else
 sendchan(chan,":mpd subcommands: current, playlist, raw")
end
