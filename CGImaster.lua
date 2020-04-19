---------------------------------
--    CGImaster by Geniusz1    --
--            v1.0             --
---------------------------------


-- BITMAP SCRIPT

local Bitmap = {}

local function read_word(data, offset)
	return data:byte(offset+1)*256 + data:byte(offset)
end

local function read_dword(data, offset)
	return read_word(data, offset+2)*65536 + read_word(data, offset)
end

local function pack(...)
	return {...}
end

function Bitmap.from_string(data)
	if not read_dword(data, 1) == 0x4D42 then -- Bitmap "magic" header
		return nil, "Bitmap magic not found"
	elseif read_word(data, 29) ~= 24 then -- Bits per pixel
		return nil, "Only 24bpp bitmaps supported"
	elseif read_dword(data, 31) ~= 0 then -- Compression
		return nil, "Only uncompressed bitmaps supported"
	end

	local bmp = {} -- We'll return this to the user

	bmp.data = data
	bmp.pixel_offset = read_word(data, 11);
	bmp.width = read_dword(data, 19);
	bmp.height = read_dword(data, 23);

	function bmp:get_pixel(x,y)
		if (x < 0) or (x > self.width) or (y < 0) or (y > self.height) then
			return nil, "Out of bounds"
		end
		local index = self.pixel_offset + (self.height - y - 1)*3*self.width + x*3
		local b = self.data:byte(index+1)
		local g = self.data:byte(index+2)
		local r = self.data:byte(index+3)
		return r,g,b
	end

	function bmp:write_to_file(path)
		local file io.open(path, "wb")
		if not file then
			return nil, "Can't open file"
		end
		file:write(bmp.data)
		file:close()
		return #bmp.data
	end

	function bmp:to_string()
		return data
	end

	function bmp:set_pixel(x,y,r,g,b)
		if (x < 0) or (x > self.width) or
		   (y < 0) or (y > self.height) or
			 (r<0) or (r>255) or
			 (g<0) or (g>255) or
			 (b<0) or (b>255) then
			return nil, "Out of bounds"
		end
		local index = self.pixel_offset + (self.width*3)*y + x
		local r = self.data:byte(index)
		local g = self.data:byte(index+1)
		local b = self.data:byte(index+2)
		local start = self.data:sub(1,index-1)
		local mid = string.char(r,g,b)
		local stop = self.data:sub(index+1, index+3)
		self.data = start .. mid .. stop
		return true
	end

	function bmp:get_rect(data, x, y, w, h)
		local data = assert(bitmap.data)
		local rect = {}
		for cy=y, y+h do
			local line = {}
			local empty = true
			for cx=x,x+w do
				if not ((x < 0) or (x > self.width) or (y < 0) or (y > self.height)) then
					local index = pixel_offset + (self.width*3)*y + x
					local r,g,b = self.data:byte(index, index+2)
					if r and g and b then
						line[#line + 1] = {r,g,b}
						empty = false
					end
				end
			end
			if empty then
				setmetatable(line, {__index = function(t, k) if k == "empty" then return true end end})
			end
			rect[#rect+1] = line
		end
		return rect
	end

	return bmp

end

function Bitmap.from_file(path)
	local file = io.open(path, "rb")
	if not file then
		return nil, "Can't open file!"
	end
	local content = file:read("*a")
	file:close()
	return Bitmap.from_string(content)
end

-- END BITMAP SCRIPT


local bitmap = Bitmap
local bmp = bitmap.from_file('./scripts/CGImaster/image.bmp')
local mode = 'only deco'

local mousex, mousey = 0, 0
local cx, cy = 0, 0

local window = Window:new(-1, -1, 350, 225)

local exitButt = Button:new(296,5,50,20)
exitButt:text('EXIT')
exitButt:action(function()
    interface.closeWindow(window)
end)

local header = Label:new(10,4,tpt.textwidth('CGImaster by Geniusz1 (v1.0)'),20, 'CGImaster by Geniusz1 (v1.0)')

local labelIMGname = Label:new(10,28,tpt.textwidth('IMAGE NAME:'),20, 'IMAGE NAME:')

local textBox = Textbox:new(tpt.textwidth('IMAGE NAME:')+20,28,200,20)

local labelWRONG = Label:new(0,50,350,20, 'WRONG IMAGE', 255,0,0)
local labelLOADED = Label:new(0,50,350,20, 'IMAGE LOADED', 255,0,0)
local disclaimer1 = Label:new(10,90,tpt.textwidth('REMEMBER:'),15, 'REMEMBER:')
local disclaimer2 = Label:new(10, 105,tpt.textwidth('- The image name is a name of an image (without .bmp extension)'),12, '- The image name is a name of an image (without .bmp extension)')
local disclaimer3 = Label:new(10, 117,tpt.textwidth('located in CGImaster folder, next to CGImaster.lua script.'),12, 'located in CGImaster folder, next to CGImaster.lua script.')
local disclaimer4 = Label:new(-9, 129,tpt.textwidth('- 1 pixel of the image equals 1 pixel in the game.'),12, '- 1 pixel of image equals 1 pixel in game.')
local disclaimer5 = Label:new(10,142,tpt.textwidth('- The file format has to be 24 bit BMP.'),12, '- The file format has to be 24 bit BMP.')
local disclaimer6 = Label:new(10,154,tpt.textwidth('- You can convert JPG, PNG and other formats to 24 bit BMP using:'),12, '- You can convert JPG, PNG and other formats to 24 bit BMP using:')
local disclaimer7 = Label:new(10,167,tpt.textwidth('online-converting.com/image/convert2bmp'),12, 'online-converting.com/image/convert2bmp')
local disclaimer8 = Label:new(10,179,tpt.textwidth('AND THE MOST IMPORTANT:'),15, 'AND THE MOST IMPORTANT:')
local disclaimer9 = Label:new(10,194,tpt.textwidth('DO NOT post any saves containing deco generated by this script,'),12, 'DO NOT post any saves containing deco generated by this script,')
local disclaimer10 = Label:new(10,206,tpt.textwidth('because it is against TPT rules.'),12, 'because it is against TPT rules.')
local copyButt = Button:new(tpt.textwidth('online-converting.com/image/convert2bmp')+15,167,30,11)
copyButt:text('COPY')
copyButt:action(function()
    tpt.set_clipboard('online-converting.com/image/convert2bmp')
end)

local function captfunc()
    gfx.drawRect(mousex, mousey, bmp.width, bmp.height, 255,0,0)
    gfx.drawRect(mousex+1, mousey+1, bmp.width-2, bmp.height-2, 0,0,0,70)
    gfx.drawRect(mousex+2, mousey+2, bmp.width-4, bmp.height-4, 0,0,0,70)
    gfx.drawRect(mousex+3, mousey+3, bmp.width-6, bmp.height-6, 0,0,0,70)
    gfx.drawRect(mousex+4, mousey+4, bmp.width-8, bmp.height-8, 0,0,0,70)
    gfx.fillRect(mousex, mousey-41, bmp.width, 40, 0,0,0,70)
    gfx.drawText(mousex+1, mousey-20, 'Press V to paste')
    gfx.drawText(mousex+1, mousey-10, 'Press SHIFT + V to exit')
    gfx.drawText(mousex+1, mousey-40, 'Mode: '..mode, 0,255,0)
    gfx.drawText(mousex+1, mousey-30, 'Press M to change mode')
end

local function oncapture(key, scan, rep, shift, ctrl, alt)
    if scan == 25 and not shift then
        if mode == 'only deco' then 
            for x = 0, bmp.width-1, 1 do
                for y = 0, bmp.height-1, 1 do
                    local r,g,b = bmp:get_pixel(x,y)
                    sim.decoBox(mousex+x,mousey+y,mousex+x,mousey+y,r,g,b)
                end
            end
        elseif mode == 'fill rectangle' then
            sim.createBox(mousex, mousey, mousex+bmp.width-1, mousey+bmp.height-1)
            for x = 0, bmp.width-1, 1 do
                for y = 0, bmp.height-1, 1 do
                    local r,g,b = bmp:get_pixel(x,y)
                    sim.decoBox(mousex+x,mousey+y,mousex+x,mousey+y,r,g,b)
                end
            end
        end
    elseif scan == 25 and shift then  
        tpt.unregister_step(captfunc)
        event.unregister(event.keypress, oncapture)
    elseif scan == 16 then
        if mode == 'fill rectangle' then mode = 'only deco'
        elseif mode == 'only deco' then mode = 'fill rectangle' end
    end
end

local captureButt = Button:new(150,70,50,20)
captureButt:text('START')
captureButt:action(function()
    interface.closeWindow(window)
    tpt.register_step(captfunc)
    event.register(event.keypress, oncapture)
end)
captureButt:enabled(false)

local loadButt = Button:new(296,28,50,20)
loadButt:text('LOAD')
loadButt:action(function()
    bmp = bitmap.from_file('./scripts/CGImaster/'..textBox:text()..'.bmp')
    if bmp == nil then 
        window:addComponent(labelWRONG) 
        window:removeComponent(labelLOADED)
        captureButt:enabled(false)
    else 
        window:addComponent(labelLOADED)
        window:removeComponent(labelWRONG)
        captureButt:enabled(true)
    end
end)

window:addComponent(exitButt)
window:addComponent(header)
window:addComponent(labelIMGname)
window:addComponent(textBox)
window:addComponent(loadButt)
window:addComponent(captureButt)
window:addComponent(disclaimer1)
window:addComponent(disclaimer2)
window:addComponent(disclaimer3)
window:addComponent(disclaimer4)
window:addComponent(disclaimer5)
window:addComponent(disclaimer6)
window:addComponent(disclaimer7)
window:addComponent(disclaimer8)
window:addComponent(disclaimer9)
window:addComponent(disclaimer10)
window:addComponent(copyButt)

local function mouse(x, y, dx, dy)
    mousex, mousey = x, y
end

local function quit(key, scan, rep, shift, ctrl, alt) 
    if scan == 18 and ctrl then
        interface.showWindow(window)
    end
end

event.register(event.keypress, quit)
event.register(event.mousemove, mouse)