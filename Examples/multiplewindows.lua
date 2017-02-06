-- Use this top line to make changes - 1
os.loadAPI("buffpixel")
local w, h = term.getSize()
term.clear()
game = {}
local win_width, win_height, win_x, win_y = 20,10,5,3
game[1] = buffpixel.new( w*4, h*4 , 0, 0 , win_width, win_height )
game[2] = buffpixel.new( w*4, h*4 , 0, 0 , win_width, win_height )
local pix = game[1].newPixel
selection = 2
function swapselect(s)
       selection = s
       game[getother(s)]:drawBorder(colors.lightGray)
       game[s]:drawBorder(colors.blue)
       game[s]:refreshRender() 
       game[s]:drawPlayer()
end
function getother(s) 
  if(s == 1)then 
      return tonumber(2) 
  elseif(s == 2)then
      return tonumber(1) 
  end 
end
game[1]:setRenderOffset(win_x,win_y)
game[2]:setRenderOffset(win_x+10,win_y)
local rw, rh = math.ceil(w/2), math.ceil(h/2)
game[1]:fillMap(pix("5D","*",false))
game[2]:fillMap(pix("5D"," ",false))
game[1]:setPixel(w-1,10,pix("87","@",true))
game[1]:newPlayer("BG","&",win_width/2,win_height/2,keys.w,keys.s,keys.a,keys.d,keys.e,1)
game[2]:newPlayer("BG","@",win_width/2,win_height/2,keys.w,keys.s,keys.a,keys.d,keys.e,1)
game[1]:setBorderText("Game: advanced graphics", colors.white)
game[2]:setBorderText("Game:  Basic graphics", colors.white)
game[getother(selection)]:refreshRender()
game[getother(selection)]:drawBorder(colors.blue)
game[selection]:refreshRender()
game[selection]:drawBorder(colors.lightGray)
local pmx, pmy = 0, 0
term.setBackgroundColor(colors.blue)
term.setTextColor(colors.white)
term.setCursorPos(1,1)
term.clearLine()
write("Click inside a window to focus, Drag to move")
while true do
   local gox, goy = game[selection]:getRenderOffsets()
   local gw, gh = game[selection]:getWidth(), game[selection]:getHeight()
   local e = { os.pullEvent() }
   if(e[1] == "mouse_click")then
         pmx = e[3]
         pmy = e[4]
      if(not game[2]:isOutsideView(e[3],e[4]) and selection == 1 and game[1]:isOutsideView(e[3],e[4]))then
         swapselect(2)
      end
      if(not game[1]:isOutsideView(e[3],e[4]) and selection == 2 and game[2]:isOutsideView(e[3],e[4]))then
          swapselect(1)
      end
   elseif(e[1] == "mouse_drag" and e[4]+gh < h and (e[3] - (gw/2)+gw) < w and e[4] > 1)then
      pmx = e[3]
      if(pmy == game[selection].roffy and pmx >= gox and pmx <= gox+gw)then
          game[selection]:setScreenPos(e[3] - (gw/2),e[4], colors.black)
          game[selection]:drawBorder(colors.blue)
          term.current().setVisible(false)
          game[getother(selection)]:refreshRender(1)
          game[getother(selection)]:drawBorder(colors.lightGray)
          game[selection]:refreshRender(1)
          game[selection]:drawBorder(colors.blue)
          term.current().setVisible(true)
          iscol = false
          pmy = e[4]
      end
   end
   if(selection == 1)then
      game[1]:getMousePlaceBlock(e,pix("87","@",true),pix("5D","*",false))
   else
      game[2]:getMousePlaceBlock(e,pix("87"," ",true),pix("5D"," ",false))
   end

   game[selection]:updatePlayer(e,0)
   local px, py = game[selection]:getPlayerPos()
   local pox, poy = game[selection]:getOutsideViews(px,py,1,1)
   game[selection]:lerpView(pox,poy,win_width/2,win_height/2,0)
end
