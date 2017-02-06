---------------------------------------------------------------------------------|
--]] Copyright (C) Nova Corporations                                         [[--|
--]] Do not edit, Do not re-distrubute, Do not Copy                          [[--|
--]] All things under the Authority of the Owner(s) Lewisk3 (Gluuon, Redxone)[[--|
---------------------------------------------------------------------------------|

--]] Lua buffer map API ideas

--getMap(w, h) -- Returns map in table format
-------------]]
	--]] Map Functions -- "FF*", where FF is text color, then back color, and * is the graphic
--		changePixelGraphic(x,y,to) -- Changes a pixels graphic at an X and Y to a specific string "Text-Back-Str"
--		setSolid(x,y,tf) 	   -- Sets a pixel at X, Y to be solid or not (map[y][x].solid = tf)
--		getRegionMap(fx,fy,tx,ty)  -- Returns a map of pixels from a specific region
--		setPixelAttribute(x,y,att) -- Concatenates att table onto the Pixels table at X, Y
--		setPixelColor(x,y,cb)	   -- Sets pixel at x and y to color, cb (color byte)
--		getPixelAttribute(x,y,name)-- Returns Attribute by name
--		setPixel(x,y,g,s)	   -- sets pixel at x, y to graphic - g and solid - s
--		getPixel(x,y)		   -- returns entire pixel at x and y
--		drawPixel(x,y)             -- draws pixel from map x, y
--		drawPixelAt(x,y,sx,sy)     -- draws pixel from map x, y at screen sx, sy
---------------]]
--createCamera(fx,fy) -- Returns camera table with focal pointed offsets of - fx and fy		
	--]] Camera Functions -- store local buffer 	
--		render(map,mx,my,ox,oy) -- render map starting ox, oy and ending at mx+ox and my+oy, viewx = ox, viewy = oy, vieww = mx, viewh = my : checks buffer for smart rendering
--		updateView(map,cx,cy)   -- Updates cam view by adding cx and cy to it, renders 
--		clearBuffer()       -- Clears the buffer
--		isOutsideView(x,y)  -- Check view variables to see of coord is outside view
--		setBuffer(buff)     -- Sets buffer table to, buff    
---------------]]
--Transparent pixel utils -- render used to draw pixels unrelated to the table map
--]] Transparent pixel functions -- Returns renderer
--	setProjection(x,y) -- sets starting point for adding offsets too
--	addProjection(xo,yo) -- adds xo, yo to projection
--	drawTPixel(x,y,g) -- draws pixel at x, y with g as graphic
--	moveTPixel(map,xo,yo,g,a) -- takes map and draws map[y][x] at projection then draws g, at projection +xo, +yo boolean a is add offset to projection.
--	clearTPixel(map,x,y)      -- redraws x, y to map[y][x]
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--]] API: Start 
function checkUpdate(apiloc)
	if(http)then
		local upd = http.get("http://pastebin.com/raw/0smCR408")
		if(upd ~= nil)then
			local cont = upd.readAll()
			local f = fs.open(apiloc,"r")
			local pcont = f.readAll()
			f.close()
			if(cont ~= pcont)then
				local f = fs.open(apiloc,"w")
				f.write(cont)
				f.close()
				return "update"
			end
		else
			return "noconnection"
		end
	else
		return "nohttp"
	end
	return "noupdate"
end

if(not term.current().setVisible)then
	term.current().setVisible = function(noval)
		return false
	end
end

function new(mw,mh,nx,ny,nw,nh)
	local nmap = {}
	for y = 1, math.ceil(mh) do
		nmap[y] = {}
		for x = 1, math.ceil(mw) do
			nmap[y][x] = {}
		end
	end
	local ntmap = {}
	for y = 1, math.ceil(mh) do
		ntmap[y] = {}
		for x = 1, math.ceil(mw) do
			ntmap[y][x] = ""
		end
	end
	local w, h = term.getSize()
	local nbuffer = {}
	for y = 1, h do
		nbuffer[y] = {}
		for x = 1, w do
			nbuffer[y][x] = {}
		end
	end

local mutils = {
	map = nmap,
	tmap = ntmap,
	player = {},
	buffer = nbuffer,
	huds = {},
	viewx = 0,
	viewy = 0,
	vieww = 0,
	viewh = 0,
	roffx = 0,
	roffy = 0,
	btext = {"", colors.white},
	dialogln = 0,
	entities = {},
	-- Misc map utils
	importMap = function(self,file)
		if(fs.exists(file))then
			local f = fs.open(file,"r")
			local gmap = textutils.unserialize(f.readAll())
			if(type(gmap) == "table")then self.map = gmap else error("importMap: Map invalid or corrupt. ") end
			f.close()
			self:resetTMap()
			self:initBuffer()
		else
			error("importMap: File doesnt exist: " .. file)		
		end
	end,

	setRenderOffset = function(self,x,y)
		-- Make sure x and y is a number and that the number is an Integer
		self.roffx = math.ceil(tonumber(x))
		self.roffy = math.ceil(tonumber(y))
	end,

	getWidth = function(self)
		return self.vieww
	end,

	getHeight = function(self)
		return self.viewh
	end,

	getViews = function(self)
		return self.viewx, self.viewy
	end,

	getRenderOffsets = function(self)
		return self.roffx, self.roffy
	end,

	-- Misc camera buffer utils
	initBuffer = function(self)
		self.buffer = {}
		for y = 0, self.viewh do
				self.buffer[y] = {}
			for x = 0, self.vieww do
				self.buffer[y][x] = {}
			end 
		end
	end,
	fillBuffer = function(self,pix)
		for y = 1, #self.map do
			for x = 1, #self.map[y] do
				self:setBuffer(x,y,pix)
			end
		end
	end,
	setBufferPixel = function(self,x,y,pix)
		self.buffer[y][x] = pix
	end,
	isBuffsize = function(self,x,y)
		if(self.buffer[y] ~= nil)then
			if(self.buffer[y][x] ~= nil)then
				return true
			end
		end
		return false
	end,
	checkViews = function(self)
		local nocap = true
		if( self.viewy-self.viewh > #self.map   )then self.viewy = #self.map-self.viewh nocap = false  end 
		if( self.viewx-self.vieww > #self.map[1] )then self.viewx = #self.map[1]-self.vieww nocap = false  end
		if( self.viewx < 0 )then self.viewx = 0 nocap = false end
		if( self.viewy < 0 )then self.viewy = 0 nocap = false end
		return nocap
	end,
	setBuffer = function(self,buff)
		self.buffer = buff
	end,
	clearBuffer = function(self)
		self.buffer = {}
	end,
	getOutsideViews = function(self,x,y,xd,yd)
		local vox, voy = 0, 0
		if( x-xd <= self.viewx			     ) then vox = -1 end
		if( x+xd >  self.vieww +  self.viewx ) then vox = 1  end
		if( y-yd <= self.viewy 			     ) then voy = -1 end 
		if( y+yd >  self.viewh +  self.viewy ) then voy = 1  end
		if(x-xd < 1 or x+xd > #self.map[1])then
			vox = 0
		end
		if(y-yd < 1 or y+yd > #self.map)then
			voy = 0
		end
		return tonumber(vox), tonumber(voy)
	end,
	isOutsideView = function(self,x,y)
		return (x <= self.roffx) or ( x > self.vieww+self.roffx ) or (y <= self.roffy) or (y > self.viewh+self.roffy)
	end,
	isOutsideViewRelative = function(self,x,y)
		return (x < self.viewx+1) or ( x > self.vieww+self.viewx ) or (y < self.viewy+1) or (y > self.viewh + self.viewy)
	end,

	-- Misc pixel utils
	newPixel = function(col,g,s)
		return {col .. g, s}
	end,
	-- Color utils
	getColoredByte = function(byte)
		return 2^tonumber(byte:sub(1,1),16), 2^tonumber(byte:sub(2,2),16)
	end,
	setColors = function(tcol, bcol)
		term.setTextColor(tcol)
		term.setBackgroundColor(bcol)
	end,

	-- Map utils
	fillMap = function(self,pix)
		for y = 1, #self.map do
			for x = 1, #self.map[y] do
				self:setPixel(x,y,pix,s)
			end
		end
	end,
	clearMap = function(self)
		for y = 1, #self.map do
			for x = 1, #self.map[y] do
				self.map[y][x] = {}
			end
		end
	end,
	setMapRegion = function(self,sx,sy,regiontable)
		for y = sy, #regiontable+sy do
			for x = sx, #regiontable[y-sy]+sx do
				self.map[y][x] = regiontable[y-sy][x-sx]
			end
		end
	end,
	setMap = function(self, map)
		self.map = map
		if(#map > #self.tmap or #map[1] > #self.tmap)then
	       for y = 1, #self.map do
	       		    self.tmap[y] = {}
			    for x = 1, #self.map[y] do
					self.tmap[y][x] = {}
				end
		   end
		end
	end,
	getMap = function(self)
		return self.map
	end,
	getRegion = function(self,x,y,xx,yy)
		local retmap = {}
		for yr = y, yy do
			for xr = x, xx do
				retmap[yr-y][xr-x] = self.map[yr][xr] 
			end
		end
		return retmap
	end,

	-- Pixel utils
	setSolid = function(self,x,y,s)
		self.map[y][x].solid = s
	end,
	getSolid = function(self,x,y)
		return self.map[y][x].solid
	end,
	getPixel = function(self,x,y)
		if(self.map[y] == nil)then return {"END", solid=true} end
		if(self.map[y][x] == nil)then return {"END", solid=true} end
		return self.map[y][x][1]
	end,
	drawPixel = function(self,x,y,cpix)
		if(cpix:sub(1,1) == "G")then
			term.setTextColor(2^tonumber( self.map[y+self.viewy][x+self.viewx][1]:sub(1,1), 16 ) )
			term.setBackgroundColor(2^tonumber( cpix:sub(2,2), 16) )
		elseif(cpix:sub(2,2) == "G")then
			term.setTextColor(2^tonumber( cpix:sub(1,1), 16) )
			term.setBackgroundColor( 2^tonumber( self.map[y+self.viewy][x+self.viewx][1]:sub(2,2),16 ) )
		else
			self.setColors(self.getColoredByte(cpix))
		end
		if(self:isBuffsize(x, y))then
			self:setBufferPixel(x, y, cpix)
		end
		term.setCursorPos(x + self.roffx, y + self.roffy)
		write(cpix:sub(3,3))
		self:checkHudRedraw(x + self.roffx,y + self.roffy)
	end,
	getPixelRaw = function(self,x,y)
		if(self.map[y] == nil)then return {"END", solid=true} end
		if(self.map[y][x] == nil)then return {"END", solid=true} end
		return self.map[y][x]
	end,
	getPixelAttribute = function(self,x,y,attrib)
		return self.map[y][x][attrib]
	end,
	setPixelAttribute = function(self,x,y,attrib,eq)
		self.map[y][x][attrib] = eq
	end,
	drawMapPixel = function(self,x,y)
		self.setColors(self.getColoredByte(self.map[y][x][1]))
		term.setCursorPos( (x-self.viewx) + self.roffx, (y-self.viewy) + self.roffy)
		write(self.map[y][x][1]:sub(3,3))
		self:drawTPixel(x,y)
		self:checkHudRedraw( (x-self.viewx) + self.roffx, (y-self.viewy) + self.roffy)
	end,
	drawMapPixelAt = function(self,x,y,dx,dy)
		self.setColors(self.getColoredByte(self.map[y][x][1]))
		term.setCursorPos(dx, dy)
		write(self.map[y][x][1]:sub(3,3))
	end,
	setPixel = function(self,x,y,pix)
		self.map[y][x] = {pix[1],solid=pix[2]}
		if(self:isBuffsize(x-self.viewx, y-self.viewy))then
			self:setBufferPixel(x-self.viewx, y-self.viewy, pix[1])
		end
		if(self.player ~= {})then
			if(x == self.player.x and y == self.player.y)then
				self:drawPlayer()
			elseif(not self:isOutsideViewRelative(x,y))then
				self:drawMapPixel(x,y)
			end
		elseif(not self:isOutsideViewRelative(x,y))then
			self:drawMapPixel(x,y)
		end
		self:checkHudRedraw((x - self.viewx) + self.roffx,(y - self.viewy) + self.roffy)
	end,

	checkPixelDistance = function(self, fx, fy, tx, ty)
		-- Again, thanks math teacher xD
		local dist = math.sqrt( (tx - fx)^2 + (ty - fy)^2 )
		return math.floor(dist)
	end,

	setPixelRelative = function(self,x,y,pix)
		self:setPixel(x + self.viewx - self.roffx, y + self.viewy - self.roffy, pix)
	end,

	-- Transparent Pixel utils
	resetTMap = function(self)
		for y = 1, #map do
			ntmap[y] = {}
			for x = 1, #map[y] do
				ntmap[y][x] = ""
			end
		end
	end,
	getTPixel = function(self,x,y)
		return self.tmap[y][x]
	end,
	isTPixelSolid = function(self,x,y)
		return self.tmap[y][x]:sub(4,4) == "1"
	end,
	setTPixelSolid = function(self,x,y,s)
		if(s == true )then s = 1 elseif(s == false)then s = 0 end
		if(s == nil)then s = 0 end
		self.tmap[y][x] = self.tmap[y][x]:sub(1,3) .. tostring(s)
	end,
	setTPixel = function(self,x,y,pix,s)
		if(s == true )then s = 1 elseif(s == false)then s = 0 end
		if(s == nil)then s = 0 end
		self.tmap[y][x] = pix .. tostring(s)
		if(self:isBuffsize(x-self.viewx, y-self.viewy))then
			self:setBufferPixel(x-self.viewx, y-self.viewy, pix)
		end
		if(not self:isOutsideViewRelative(x,y))then
			self:drawTPixel(x,y)
		end
		self:checkHudRedraw((x - self.viewx) + self.roffx,(y - self.viewy) + self.roffy)
	end,

	setTPixelRelative = function(self,x,y,pix,s)
		self:setTPixel(x + self.viewx - self.roffx, y + self.viewy - self.roffy, pix,s)
	end,
	drawTPixel = function(self,x,y)
		local cpix = self:getTPixel(x,y)
		if(cpix ~= "")then
			if(cpix:sub(1,1) == "G")then
				term.setTextColor(2^tonumber( self.map[y+self.viewy][x+self.viewx][1]:sub(1,1), 16 ) )
				term.setBackgroundColor(2^tonumber( cpix:sub(2,2), 16) )
			elseif(cpix:sub(2,2) == "G")then
				term.setTextColor(2^tonumber( cpix:sub(1,1), 16) )
				term.setBackgroundColor( 2^tonumber( self.map[y+self.viewy][x+self.viewx][1]:sub(2,2),16 ) )
			else
				self.setColors(self.getColoredByte(cpix))
			end
			if(not self:isOutsideViewRelative(x,y))then
				term.setCursorPos( (x-self.viewx) + self.roffx, (y-self.viewy) + self.roffy)
				write(cpix:sub(3,3))
				self:checkHudRedraw(x + self.roffx,y + self.roffy)
			end
		end
	end,
	clearTPixel = function(self,x,y)
		self:setTPixel(x,y,"")
		self:drawMapPixel(x,y)
	end,
	moveTPixel = function(self,fx,fy,ax,ay)
		local cpix = self:getTPixel(fx,fy)
		self:clearTPixel(fx,fy)
		self:setTPixel(fx+ax,fy+ay,cpix)
	end,
	setTPixelPos = function(self,fx,fy,tx,ty)
		local cpix = self:getTPixel(fx,fy)
		self:clearTPixel(fx,fy)
		self:setTPixel(tx,ty,cpix)
	end,
	---- Player utils
	drawPlayer = function(self)
		if(self.player == {})then return false end
		local xd = self.player.x-self.viewx 
		local yd = self.player.y-self.viewy
		if(xd <= 0)then xd = 1 end
		if(yd <= 0)then yd = 1 end
		if(self.player.x > 0 and self.player.y > 0)then
			self:drawPixel( xd, yd ,self.player.pix)
		end
	end,
	
	setPlayerGraphic = function(self,col,g)
		self.player.pix = col .. g
		self:drawPlayer()
	end,

	undrawPlayer = function(self)
		if(self.player == {})then return false end
		self:drawMapPixel(self.player.x,self.player.y)
	end,
	drawPlayerAt = function(self,x,y)
		if(self.player == {})then return false end
		self:drawPixel(x,y,self.player.pix)
	end,
	movePlayer = function(self,ox,oy,r)
		if(self.player == {})then return false end
		if(r)then
			self:undrawPlayer()
		end
		if( ( ( self:getPixelRaw( self.player.x + ox, self.player.y + oy ).solid == false and not self:isTPixelSolid( self.player.x + ox, self.player.y + oy ) ) or self.player.scollide == false ) and self.player.mcollide and
			self.player.x+ox >= 1 and self.player.y+oy >= 1 and self.player.y+oy <= #self.map and self.player.x+ox <= #self.map[1] )then
			self.player.x = self.player.x + ox
			self.player.y = self.player.y + oy
		else
			if(r)then
				self:drawPlayer()
			end			
			return false
		end
		if(r)then
			self:drawPlayer()
		end
	end,
	setPlayerPos = function(self,x,y)
		self.player.x = x
		self.player.y = y
	end,
	getPlayerPos = function(self)
		return self.player.x, self.player.y
	end,
	newPlayer = function(self,pcol,pg,px,py,aup,adown,aleft,aright,aact,aspd)
		if(aup == nil or adown == nil or aleft == nil or aright == nil or aact == nil)then
			error("BuffPixel: newPlayer -> missing control!")
		end
		self.player = {scollide=true,mcollide=true,pix=pcol..pg,x=math.ceil(px),y=math.ceil(py),events={},up=aup,down=adown,left=aleft,right=aright,interact=aact,spd=aspd,canmove=true}
		self:drawPlayer()
	end,
	setPlayerControls = function(self,aup,adown,aleft,aright,aact)
		self.player.up = aup
		self.player.down = adown
		self.player.left = aleft
		self.player.right = aright
		self.player.interact = aact
	end,
	setPlayerCollisionType = function(self,colw)
		self.player.mcollide = colw
	end,
	playerSolidCollision = function(self,tf)
		self.player.scollide = tf
	end,
	clearPlayerEvents = function(self)
		self.player.events = {}
	end,
	addPlayerEvent = function(self,name,evtbl,call)
		self.player.events[name] = {evs = evtbl,func = call}
	end,
	removePlayerEvent = function(self,name)
		if(self.player.events[name] ~= nil)then
		   self.player.events[name] = nil
		end
	end,
	updatePlayer = function(self,ev,spd)
		-- Compare user specific player events
		for k, v in pairs(self.player.events) do
			if(ev[1] == v.evs[1] and ev[2] == v.evs[2])then
			 v:func()
			end
		end
		-- Player Input and movement
		if(ev[1] == "key")then
			local key = ev[2]
			if(self.player.canmove)then
					if(key == self.player.up   )then
						self:movePlayer(0,-self.player.spd,true)
				elseif(key == self.player.down )then
						self:movePlayer(0,self.player.spd,true)
				elseif(key == self.player.left )then
						self:movePlayer(-self.player.spd,0,true)
				elseif(key == self.player.right)then
						self:movePlayer(self.player.spd,0,true)
				end
			end
			if(spd ~= nil)then
				sleep(spd)
			end
		end
	end,
	checkPlayerDistance = function(self,x,y)
		-- checks players distance to block
		-- Thanks math teacher :)
		local dist = math.sqrt( (x - self.player.x)^2 + (y - self.player.y)^2 )
		return math.floor(dist)
	end,
	-- Entity utils
	addEntity = function(self,entity)
		self.entities[#self.entities] = entity
	end,
	addEntityByName = function(self, name, entity)
		if(self.entities[name] == nil)then
			self.entities[name] = entity
			return true
		end
		return false
	end,
	removeEntity = function(self, name)
		if(self.entities[name] ~= nil)then
			table.remove(self.entities,name)
			return true
		end
		return false
	end,
	updateEntities = function(self, e)
		for k, v in pairs(self.entities) do
			if(v.alive ~= nil)then
				if(v.alive == false)then
					table.remove(self.entities,k)
					return false
				end
			end
			if(v.draw ~= nil)then
				v:draw(e)
			end
			if(v.update ~= nil)then
				v:update(e)
			end
			if(e[1] == "key" and self.player ~= {})then
				if(e[2] == self.player.interact and v.interact ~= nil)then
					if(self:checkPlayerDistance(v.x,v.y) <= 1)then
						v:interact(e)
					end
				end
			end
		end
	end,

	-- Hud utils
	renderHuds = function(self)
		for k, v in pairs(self.huds) do
			term.setCursorPos(v.offx, v.offy)
			v.draw()
		end
	end,

	updateHuds = function(self,e)
		for k, v in pairs(self.huds) do
			term.setCursorPos(v.offx, v.offy)
			v.update(e)
		end
	end,
	
	drawHud = function(self,name)
		if(self.huds[name] ~= nil)then
			self.huds[name].draw()
		end
	end,

	checkHudRedraw = function(self,x,y)
		for k, v in pairs(self.huds) do
			--term.setCursorPos(1,2)
			--write(x .. ">= " .. v.offx .. " " .. x .. "<= " .. v.width + v.offx-1)
			--term.setCursorPos(1,3)
			--write(y .. ">= " .. v.offy .. " " .. y .. "<= " .. v.height + v.offy-1)
			if( x >= v.offx and x <= v.width + v.offx-1 and y >= v.offy and y <= v.height + v.offy -1 )then
				self:drawHud(k)
			end
		end
	end,

	newHud = function(self,name,xo,yo,w,h,drawf,updatef)
		self.huds[name] = {offx=xo,offy=yo,width=w,height=h,draw=drawf,update=updatef}
		self:drawHud(name)
	end,

	removeHud = function(self, name)
		if(self.huds[name] ~= nil)then
			self.huds[name] = nil
		end
	end,

	setHudCursorPos = function(self,name,x,y)
		if(self.huds[name] ~= nil)then
			term.setCursorPos(self.huds[name].offx + x, self.huds[name].offy + y)
		end
	end,

	-- Special event handlers
	getMousePlaceBlock = function(self,e,blockone,blocktwo)
		if(e[1] == "mouse_click" or e[1] == "mouse_drag")then
	      if(not self:isOutsideView(e[3],e[4]))then
	         if(e[2] == 1 and blockone ~= nil)then
	             self:setPixelRelative(e[3],e[4],blockone)
	         elseif(blocktwo ~= nil)then
	             self:setPixelRelative(e[3],e[4],blocktwo)
	         end
	      end
	   end
	end,

	-- Render utils 

	renderSection = function(self,fx,fy,tx,ty)
		term.current().setVisible(false)
		if(#self.buffer ~= self.viewh or #self.buffer[1] ~= self.vieww)then
		    self:initBuffer()
		end
		self.buffer[(self.player.y-self.viewy)][(self.player.x-self.viewx)] = {self.player.pix, solid=false}
		for y=fy, ty do
				for x=fx, tx do
					
						-- Draw the pixel
						self:drawMapPixel(x,y)
						if(opt == true)then
							self.setColors(self.getColoredByte(self.map[y][x][1]))
							term.setCursorPos( (x-self.viewx) + self.roffx, (y-self.viewy) + self.roffy)
							write("R")
						end
						-- Add the pixel to the buffer
						self:setBufferPixel(x-self.viewx, y-self.viewy, self.map[y][x][1])
						self:checkHudRedraw( (x-self.viewx) + self.roffx, (y-self.viewy) + self.roffy)
					if( self.tmap[y][x] ~= "")then
							-- Draw the player
							self:drawTPixel(x,y)
							if(opt == true)then
								self.setColors(self.getColoredByte(self.tmap[y][x]))
								term.setCursorPos( (x-self.viewx) + self.roffx, (y-self.viewy) + self.roffy)
								write("R")
							end
							-- Add the pixel to the buffer
							self:setBufferPixel(x-self.viewx, y-self.viewy, self.tmap[y][x])
							self:checkHudRedraw( (x-self.viewx) + self.roffx, (y-self.viewy) + self.roffy)	
					end
					if(self.player ~= {})then
							-- Draw the player
							self:drawPlayer()
							-- Add the pixel to the buffer
							self.buffer[(self.player.y-self.viewy)][(self.player.x-self.viewx)] = {self.player.pix}
							self:checkHudRedraw( (x-self.viewx) + self.roffx, (y-self.viewy) + self.roffy)	
					end
				end
			end
		local success, err = pcall(self.renderHuds,self)
		if( not success )then
			term.current().setVisible(true)
			print("Hud renderer errored with: " .. err)
		end
		term.current().setVisible(true)
	end,
	refreshRender = function(self, vis)
		if( not vis )then term.current().setVisible(false) end
		if(#self.buffer ~= self.viewh or #self.buffer[1] ~= self.vieww)then
		    self:initBuffer()
		end
		for y=self.viewy+1, self.viewy + self.viewh do
				for x=self.viewx+1, self.viewx + self.vieww do
					-- If we have a new pixel in view
						-- Draw the pixel
						self:drawMapPixel(x,y)
						-- Add the pixel to the buffer
						self:setBufferPixel(x-self.viewx, y-self.viewy, self.map[y][x][1])
						self:checkHudRedraw( (x-self.viewx) + self.roffx, (y-self.viewy) + self.roffy)

					if( (self.buffer[(y-self.viewy)][(x-self.viewx)] ~= self.tmap[y][x]) and self.tmap[y][x] ~= "")then
							-- Draw the player
							self:drawTPixel(x,y)
							-- Add the pixel to the buffer
							self:setBufferPixel(x-self.viewx, y-self.viewy, self.tmap[y][x])
							self:checkHudRedraw( (x-self.viewx) + self.roffx, (y-self.viewy) + self.roffy)	
					end
					if(self.buffer[(self.player.y-self.viewy)][(self.player.x-self.viewx)] ~= {self.player.pix})then
							-- Draw the player
							self:drawPlayer()
							-- Add the pixel to the buffer
							self.buffer[(self.player.y-self.viewy)][(self.player.x-self.viewx)] = {self.player.pix}
							self:checkHudRedraw( (x-self.viewx) + self.roffx, (y-self.viewy) + self.roffy)	
					end
			end
		end
		local success, err = pcall(self.renderHuds,self)
		if( not success )then
			term.current().setVisible(true)
			print("Hud renderer errored with: " .. err)
		end
		if( not vis )then term.current().setVisible(true) end
		if(self.player ~= {})then self:drawPlayer() end
	end,

	render = function(self,opt)
		term.current().setVisible(false)
		if(#self.buffer ~= self.viewh or #self.buffer[1] ~= self.vieww)then
		    self:initBuffer()
		end
		for y=self.viewy+1, self.viewy + self.viewh do
				for x=self.viewx+1, self.viewx + self.vieww do
					-- If we have a new pixel in view
					if(self.buffer[(y-self.viewy)][(x-self.viewx)] ~= self.map[y][x][1])then
						-- Draw the pixel
						self:drawMapPixel(x,y)
						if(opt == true)then
							self.setColors(self.getColoredByte(self.map[y][x][1]))
							term.setCursorPos( (x-self.viewx) + self.roffx, (y-self.viewy) + self.roffy)
							write("R")
						end
						-- Add the pixel to the buffer
						self:setBufferPixel(x-self.viewx, y-self.viewy, self.map[y][x][1])
						self:checkHudRedraw( (x-self.viewx) + self.roffx, (y-self.viewy) + self.roffy)
					end
					if( (self.buffer[(y-self.viewy)][(x-self.viewx)] ~= self.tmap[y][x]) and self.tmap[y][x] ~= "")then
							-- Draw the player
							self:drawTPixel(x,y)
							if(opt == true)then
								self.setColors(self.getColoredByte(self.tmap[y][x]))
								term.setCursorPos( (x-self.viewx) + self.roffx, (y-self.viewy) + self.roffy)
								write("R")
							end
							-- Add the pixel to the buffer
							self:setBufferPixel(x-self.viewx, y-self.viewy, self.tmap[y][x])
							self:checkHudRedraw( (x-self.viewx) + self.roffx, (y-self.viewy) + self.roffy)	
					end
					if(self.buffer[(self.player.y-self.viewy)][(self.player.x-self.viewx)] ~= {self.player.pix})then
							-- Draw the player
							self:drawPlayer()
							-- Add the pixel to the buffer
							self.buffer[(self.player.y-self.viewy)][(self.player.x-self.viewx)] = {self.player.pix}
							self:checkHudRedraw( (x-self.viewx) + self.roffx, (y-self.viewy) + self.roffy)	
					end
				end
		end
		local success, err = pcall(self.renderHuds,self)
		if( not success )then
			term.current().setVisible(true)
			print("Hud renderer errored with: " .. err)
		end
		term.current().setVisible(true)
	end,
	setView = function(self,nx,ny,nw,nh)
		local oh, ow = self.viewh, self.vieww
		self.viewx = nx
		self.viewy = ny
		self.vieww = nw
		self.viewh = nh
		if(nw ~= ow or nh ~= oh)then self:initBuffer() end
		if( self:checkViews() )then return self:render() end
	end,

	updateView = function(self,ox,oy,ow,oh)
		local ovx = self.viewx
		local ovy = self.viewy
		local ovh = self.viewh
		local ovw = self.vieww
		self.viewx = self.viewx + ox
		self.viewy = self.viewy + oy
		self.vieww = self.vieww + ow
		self.viewh = self.viewh + oh
		if(ow ~= 0 or oh ~= 0)then self:initBuffer() end
		if( self:checkViews() )then return self:render() end
	end,

	lerpView = function(self,ox,oy,ax,ay,time)
		-- ox, and oy are directional variables
		-- ax, and ay are the amount to move the view
		-- time is how long to wait before moving the view again
		self.player.canmove = false
		if(ox ~= 0 )then
			 term.current().setVisible(false)
			 self:undrawPlayer()
		   	 for x = 1, ax do
		   	 	self:updateView(ox,0,0,0,true)
		   	 	if(time ~= nil)then
		   	 		sleep(time)
		  	 	end
		  	 end
	   	end
	   if(oy ~= 0 )then
	   	  term.current().setVisible(false)
	   	  self:undrawPlayer() 
	   	  for y = 1, ay do
	   	 	 self:updateView(0,oy,0,0,true)
		   	 if(time ~= nil)then
		   	 	sleep(time)
		  	 end
	   	  end
	   end
	   self.player.canmove = true
	end,


	-- Screen utils
	checkScreenCollision = function(self, x, y, w, h)
		return (x >= self.roffx-1 and x <= self.vieww + self.roffx + 1 and y >= self.roffy-1 and y <= self.viewh + self.roffy + 1)
	end,
	setBorderText = function(self, txt, color)
		self.btext = {txt, color}
	end,
	drawBorder = function(self, color)
		paintutils.drawBox(self.roffx, self.roffy, self.vieww+self.roffx+1, self.viewh+self.roffy+1, color)
		term.setCursorPos(self.roffx , self.roffy)
		--+ (self.vieww /2) - (#self.btext[1] /2) centered text
		term.setTextColor(self.btext[2])
		write(self.btext[1]:sub(1,self.vieww))
	end,
	clearScreen = function(self,color)
		paintutils.drawFilledBox(self.roffx, self.roffy, self.vieww+self.roffx+1, self.viewh+self.roffy+1, color)
	end,
	setScreenPos = function(self,tox,toy, color)
		term.current().setVisible(false)
		self:clearScreen(color)
		self.roffx = tox
		self.roffy = toy
		self:refreshRender()
		term.current().setVisible(true)
	end,
	moveScreen = function(self,tox,toy, color)
		term.current().setVisible(false)
		self:clearScreen(color)
		self.roffx = self.roffx + tox
		self.roffy = self.roffy + toy
		self:refreshRender()
		term.current().setVisible(true)
	end,

	-- Dialog utils
	openDialog = function(self,bcol,tcol)
			self.dialogln = 0
	        paintutils.drawBox(self.roffx+1,self.viewh + self.roffy-5,self.vieww+self.roffx,self.viewh + self.roffy,bcol)
	        paintutils.drawFilledBox(self.roffx+2,self.viewh + self.roffy-4,self.vieww+self.roffx-1,self.viewh + self.roffy-1,tcol)
	end,
	 
	clearDialog = function(self,tc,bc) 
		self.dialogln = 0
		self:openDialog(tc,bc)
	end,
	 
	drawDialog = function(self,text,speed,txcol)
	        term.setCursorPos(self.roffx+2,self.roffy+self.viewh- ( 4 - ( self.dialogln ) ) )
	        term.setTextColor(txcol)
			local x,y = term.getCursorPos()
			local st = 0
			for i = 1, #text do
				if(i-st > self.vieww-4)then
					text = text:sub(1,i) .. "\n" .. text:sub(i+1,-1)
					st = i
				end
			end
			local ln = 0
			for line in text:gmatch("[^\n]+") do
				term.setCursorPos(x,y+ln)
				textutils.slowPrint(line,speed)
				ln = ln + 1
			end
	end,
	 
	getDialogYesNo = function(self,YText,NText,ln)
	        local sel = 1
	        local waiting = true
	        local opt = {
	                {name=YText};
	                {name=NText};
	        }
	 
	        function waitResult()
	                while waiting do
	                        for i = 1, #opt do
	                                term.setCursorPos(self.roffx+(self.vieww/2) - #opt[i].name/2,self.roffy + self.viewh- ( 4 - ( (ln+i)-1 ) ) )
	                                if(sel == i )then
	                                        write("["..opt[i].name.."]")
	                                else
	                                        write(" "..opt[i].name.." ")
	                                end
	                        end
	 
	                        a = {os.pullEvent("key")}
	 
	                        if(a[2] == keys.w and sel > 1)then
	                                sel = sel - 1
	                        end
	                        if(a[2] == keys.s and sel < #opt)then
	                                sel = sel + 1
	                        end
	                        if(a[2] == keys.space)then
	                                if(sel == 1)then  waiting = false return "yes" end
	                                if(sel == 2)then  waiting = false return  "no" end
	                        end
	                end
	        end
	        return waitResult()
	end,
	 
	closeDialog = function(self)
	    os.pullEvent("key")
	    self.dialogln = 0
	    self:renderSection(1,self.viewh-5,self.vieww,self.viewh)
	end,
	 
	closeDialogRaw = function(self)
		self.dialogln = 0
	    self:renderSection(1,self.viewh-5,self.vieww,self.viewh)
	end

}
	mutils.viewx = nx
	mutils.viewy = ny
	mutils.vieww = nw
	mutils.viewh = nh
	return mutils
end

function exportMap(map, file)
	if(fs.exists(file))then
		error("exportMap: File already exists: " .. file)
	else
		local f = fs.open(file,"w")
		map = textutils.serialize(map)
		map = map:gsub("n", "") 
		map = map:gsub("%s+", "")
		f.write(map)
		f.close()
	end
end
