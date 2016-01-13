local nick,chan,tCommand,message = ...
local mpdHost = "192.168.1.17"
if tCommand[2] == "current" then
 sendchan(chan,io.popen("mpc -h "..mpdHost.." current"):read("*a"))
elseif tCommand[2] == "playlist" then
 io.popen("mpc -h "..mpdHost.." playlist > ~/public_html/mpd-playlist.txt")
 sendchan(chan,"http://lain.shadowkat.science/~izaya/mpd-playlist.txt")
else
 sendchan(chan,":mpd subcommands: current, playlist")
end
