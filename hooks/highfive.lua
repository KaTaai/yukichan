tArgs = {...}
local nick, chan, message = tArgs[1],tArgs[2],tArgs[3]
if (message:find("o/") ~= nil or message:find("\\o") ~= nil) and message:find("\\o/") == nil then
 if nick ~= "Shocky" then
  if _G.leftHanging[2] == false then
   print (nick .." left hanging at "..os.time())
   local typeOfHighFive="o/"
   if message:find("o/") ~= nil then
    typeOfHighFive = "\\o"
   end
   _G.leftHanging = {os.time(),true,chan,typeOfHighFive}
  elseif _G.leftHanging[2] == true then
   _G.leftHanging = {0,false}
   print("No longer left hanging.")
  end
 else
  _G.leftHanging = {0,false}
 end
end
if message:find("o/ * \\o") ~= nil then _G.leftHanging = {0, false} end
