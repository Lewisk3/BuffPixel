os.loadAPI("buffpixel")
write("Enter Window Width: ")
local win_width = tonumber(read())
write("Enter Window Height: ")
local win_height = tonumber(read())
write("Enter Window X: ")
local win_x = tonumber(read())
write("Enter Window Y: ")
local win_y = tonumber(read())
local w, h = term.getSize()
term.clear()
paintutils.drawBox(win_x, win_y, win_x+win_width+1, win_y+win_height+1, colors.gray)
buff = buffpixel.new( w*4, h*4 , 0, 0 , win_width, win_height )
local pix = buff.newPixel
buff:setRenderOffset(win_x,win_y)
local collide = true
local rw, rh = math.ceil(w/2), math.ceil(h/2)
buff:fillMap(pix("5D","*",false))
buff:setPixel(w-1,10,pix("87","@",true))
buff:newPlayer("BG","&",1,1,keys.w,keys.s,keys.a,keys.d,keys.e,1)
buff:setTPixel(1,5,"BG@")
buff:addEntityByName("testnpc",{x = 1, y = 5, interact = function() 
   buff:openDialog(colors.lightGray,colors.blue)
   buff:drawDialog("First dialogbox!",50,colors.white)
   if(buff:getDialogYesNo("Yea","Nope",2) == "yes")then
      buff:clearDialog(colors.lightGray,colors.white)
      buff:drawDialog("First yes and no result!",50,colors.black)
      buff:closeDialog()
   else
      buff:closeDialogRaw()
   end
end})
buff:setTPixelSolid(1,5,1)
buff:render()
buff:newHud("topbar",1,1,w,1,
   function()
      term.setTextColor(colors.white)
      term.setBackgroundColor(colors.gray)
      buff:setHudCursorPos("topbar",0,0)
      term.clearLine()
      write("Left click to place : Right click to break" .. " " .. buff:checkPlayerDistance(1,5))
   end, 
   function(e)
       term.current().setVisible(false)
       buff:drawHud("topbar")
       term.current().setVisible(true)
   end
)
function nocliptoggle(self)
   self.collide = not self.collide 
   buff:playerSolidCollision(self.collide) 
   if(not self.collide)then
      buff:setPlayerGraphic("0G","^")
   else
      buff:setPlayerGraphic("BG","&")
   end
end
buff:addPlayerEvent("noclip",{"key",keys.n},nocliptoggle)
buff.player.events['noclip'].collide = true
while true do
	local e = { os.pullEvent() }
   if(e[1] == "key")then
      local key = e[2]
      if(key == keys.left)then
         buff:updateView(1,0,0,0,true)
      end
      if(key == keys.right)then
         buff:updateView(-1,0,0,0,true)
      end
      if(key == keys.up)then
         buff:updateView(0,1,0,0,true)
      end
      if(key == keys.down)then
         buff:updateView(0,-1,0,0,true)
      end
   end
   buff:getMousePlaceBlock(e,pix("87","@",true),pix("5D","*",false))
	buff:updatePlayer(e,0)
   buff:updateHuds(e)
   buff:updateEntities(e)
	local px, py = buff:getPlayerPos()
	local pox, poy = buff:getOutsideViews(px,py,1,1)
   buff:lerpView(pox,poy,win_width/2,win_height/2)
end
