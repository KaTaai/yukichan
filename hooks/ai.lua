nick,chan,message = ...
local serialization = require "serialization"
lnick = "yukichan"
print(lnick,nick,chan,message)
if string.find(message,lnick) ~= nil and nick ~= "Shocky" then
 print("Message addressed to AI!")
 local f = io.open("./ai.lua","rb")
 if f ~= nil then
  local content = f:read("*a")
  f:close()
  print(content)
  print("Loaded AI file.")
  print(type(serialization.unserialize))
  w,aitab = pcall(serialization.unserialize,content)
  print(w,aitab)
  print("Decoded AI file.")
  local selection = 0
  local hscore = 0
  print("Starting interpretation.")
  for k,v in ipairs(aitab) do
   local count = 0
   for l,w in ipairs(v[2]) do
    if message:find(w) then count = count + 1 print ("yes") end
   end
   if count > hscore then
    selection = k
    hscore = count
    print(selection,hscore)
   end
  end
  if hscore == 0 then
   print("No high score, selecting a random response.")
   selection = math.random(1,#aitab)
  end
  print(selection)
  selstring = aitab[selection][1][1]
  if type(selstring) == "table" then
   for k,v in pairs(selstring) do
    print(k.."="..v)
   end
  end
  print(selstring)
  sendchan(chan,selstring)
 end
end
