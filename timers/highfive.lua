local os = require "os"
if os.time() > _G.leftHanging[1]+3 and _G.leftHanging[2] then
 print ("Responding to a hanging high-five at ".._G.leftHanging[1])
 sendchan(_G.leftHanging[3],_G.leftHanging[4] or "\\o")
 _G.leftHanging={0,false}
end
