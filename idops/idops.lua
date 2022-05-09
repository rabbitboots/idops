-- idops: (LÖVE) ImageData Operations
-- Version: 0.0.2 (Beta)
-- Supported LÖVE Versions: 11.4
-- See 'README.md' for documentation and license info.

local idops = {}

-- * Internal *

local function assertArgType(arg_n, val, str)
	if type(val) ~= str then
		error("bad type for argument #" .. arg_n .. ": expected " .. str .. ", got: " .. type(val))
	end
end


local function assertArgType2(arg_n, val, s1, s2)
	local t_val = type(val)
	if t_val ~= s1 and t_val ~= s2 then
		error("bad type for argument #" .. arg_n .. ": expected " .. s1 .. " or " .. s2 ", got: " .. type(val))
	end
end


local function compColor(r1, g1, b1, a1, r2, g2, b2, a2)
	return r1 == r2 and g1 == g2 and b1 == b2 and a1 == a2
end


local function pixInBounds(x, y, w, h)
	return x > 0 and x < w-1 and y > 0 and y < h-1
end


-- scaleIntegral(): Holds a temp copy of the source ImageData pixel contents.
local temp = {}
local temp_i
local temp_w
local temp_sw
local temp_sh


-- scaleIntegral(): Copies source ImageData pixel values to a temporary array.
local function map_imageDataToTemp(x, y, r, g, b, a)
	temp[temp_i + 1] = r
	temp[temp_i + 2] = g
	temp[temp_i + 3] = b
	temp[temp_i + 4] = a
	
	temp_i = temp_i + 4
	
	return r, g, b, a
end


-- scaleIntegral(): Copies temp array values to the scaled destination ImageData.
local function map_tempToImageData(x, y, r, g, b, a)
	local i = 1 + (math.floor(y/temp_sh)*temp_w + math.floor(x/temp_sw)) * 4
	
	return temp[i], temp[i + 1], temp[i + 2], temp[i + 3]
end


-- replaceRGB(), replaceRGBA()
local temp_r1, temp_g1, temp_b1, temp_a1, temp_r2, temp_g2, temp_b2, temp_a2


local function map_replaceRGB(x, y, r, g, b, a)
	if r == temp_r1 and g == temp_g1 and b == temp_b1 then
		return temp_r2, temp_g2, temp_b2, a
	else
		return r, g, b, a
	end
end


local function map_replaceRGBA(x, y, r, g, b, a)
	if r == temp_r1 and g == temp_g1 and b == temp_b1 and a == temp_a1 then
		return temp_r2, temp_g2, temp_b2, temp_a2
	else
		return r, g, b, a
	end
end


local function map_invert(x, y, r, g, b, a)
	return 1 - r, 1 - g, 1 - b, 1 - a
end


-- * / Internal *


-- * Public Functions *


function idops.pasteScaled(src, dst, scale_x, scale_y, src_x, src_y, src_w, src_h, dst_x, dst_y)
	-- Defaults
	scale_x = scale_x or 1
	scale_y = scale_y or scale_x
	src_x = src_x or 0
	src_y = src_y or 0
	src_w = src_w or src:getWidth()
	src_h = src_h or src:getHeight()
	dst_x = dst_x or 0
	dst_y = dst_y or 0
	
	if scale_x <= 0 or scale_y <= 0 then
		error("scale_x and scale_y must be greater than zero.")
	end
	
	local dst_w = math.max(1, math.floor(src_w * scale_x))
	local dst_h = math.max(1, math.floor(src_h * scale_y))
	
	local w1, h1 = src:getDimensions()
	local w2, h2 = dst:getDimensions()
	
	local dx1 = math.floor(math.max(0, math.min(dst_x, w2 - 1)))
	local dx2 = math.floor(math.min(dx1 + dst_w, w2 - 1))
	
	local dy1 = math.floor(math.max(0, math.min(dst_y, h2 - 1)))
	local dy2 = math.floor(math.min(dy1 + dst_h, h2 - 1))
	
	for y = dy1, dy2 do
		for x = dx1, dx2 do
			local src_x = math.max(0, math.min(math.floor(x / scale_x), w1 - 1))
			local src_y = math.max(0, math.min(math.floor(y / scale_y), h1 - 1))
			
			local r, g, b, a = src:getPixel(src_x, src_y)
			dst:setPixel(x, y, r, g, b, a)
		end
	end
end


function idops.scaleIntegral(src, sw, sh)
	sh = sh or sw
	
	if sw < 1 or sh < 1 or math.floor(sw) ~= sw or math.floor(sh) ~= sh then
		error("input scale needs to be integers >= 1.")
	end
	
	local w, h = src:getDimensions()
	local n_w, n_h = w*sw, h*sh
	
	if n_w < 1 or n_h < 1 then
		error("the new scaled ImageData dimensions must be at least 1x1.")
	end
	
	-- Same dimensions as original: just return a copy
	if n_w == src:getWidth() and n_h == src:getHeight() then
		return src:clone()
	end
	
	local dst = love.image.newImageData(n_w, n_h)
	
	idops.pasteScaled(src, dst, sw, sh, 0, 0, src:getWidth(), src:getHeight(), 0, 0)
	
	return dst
end


function idops.replaceRGB(src, r1, g1, b1, r2, g2, b2, px, py, pw, ph)

	assertArgType(2, r1, "number")
	assertArgType(3, g1, "number")
	assertArgType(4, b1, "number")
	assertArgType(5, r2, "number")
	assertArgType(6, g2, "number")
	assertArgType(7, b2, "number")
	
	px = px or 0
	assertArgType(8, px, "number")
	
	py = py or 0
	assertArgType(9, py, "number")
	
	pw = pw or src:getWidth()
	assertArgType(10, pw, "number")
	
	ph = ph or src:getHeight()
	assertArgType(11, ph, "number")
	
	
	temp_r1, temp_g1, temp_b1, temp_r2, temp_g2, temp_b2 = r1, g1, b1, r2, g2, b2
	src:mapPixel(map_replaceRGB, px, py, pw, ph)
end


function idops.replaceRGBA(src, r1, g1, b1, a1, r2, g2, b2, a2, px, py, pw, ph)
	
	assertArgType(2, r1, "number")
	assertArgType(3, g1, "number")
	assertArgType(4, b1, "number")
	assertArgType(5, a1, "number")
	assertArgType(6, r2, "number")
	assertArgType(7, g2, "number")
	assertArgType(8, b2, "number")
	assertArgType(9, a2, "number")
	
	px = px or 0
	assertArgType(10, px, "number")
	
	py = py or 0
	assertArgType(11, py, "number")
	
	pw = pw or src:getWidth()
	assertArgType(12, pw, "number")
	
	ph = ph or src:getHeight()
	assertArgType(13, ph, "number")
	
	
	temp_r1, temp_g1, temp_b1, temp_a1, temp_r2, temp_g2, temp_b2, temp_a2 = r1, g1, b1, a1, r2, g2, b2, a2
	src:mapPixel(map_replaceRGBA, px, py, pw, ph)
end


function idops.addDropShadow(src, ox, oy, tr, tg, tb, ta, sr, sg, sb, sa, ignore_t)
	local w, h = src:getDimensions()
	for y = 0, h - 1 do
		for x = 0, w - 1 do
			local r, g, b, a = src:getPixel(x, y)
			local is_tr = compColor(r, g, b, a, tr, tg, tb, ta)
			
			if is_tr then
				if pixInBounds(x - ox, y - oy, w, h) then
					local r2, g2, b2, a2 = src:getPixel(x - ox, y - oy)
					
					local do_set = true
					
					if ignore_t then
						for i = 1, #ignore_t do
							local ig_c = ignore_t[i]
							if compColor(r2, g2, b2, a2, ig_c[1], ig_c[2], ig_c[3], ig_c[4]) then
								do_set = false
								break
							end
						end
					end
					if do_set then
						src:setPixel(x, y, sr, sg, sb, sa)
					end
				end
			end
		end
	end
end


function idops.addOutline4(src, tr, tg, tb, ta, sr, sg, sb, sa, ignore_t)
	idops.addDropShadow(src,  1,  0, tr, tg, tb, ta, sr, sg, sb, sa, ignore_t)
	idops.addDropShadow(src, -1,  0, tr, tg, tb, ta, sr, sg, sb, sa, ignore_t)
	idops.addDropShadow(src,  0,  1, tr, tg, tb, ta, sr, sg, sb, sa, ignore_t)
	idops.addDropShadow(src,  0, -1, tr, tg, tb, ta, sr, sg, sb, sa, ignore_t)
end


function idops.addOutline8(src, tr, tg, tb, ta, sr, sg, sb, sa, ignore_t)
	idops.addDropShadow(src,  1,  0, tr, tg, tb, ta, sr, sg, sb, sa, ignore_t)
	idops.addDropShadow(src,  1,  1, tr, tg, tb, ta, sr, sg, sb, sa, ignore_t)
	idops.addDropShadow(src,  0,  1, tr, tg, tb, ta, sr, sg, sb, sa, ignore_t)
	idops.addDropShadow(src, -1,  1, tr, tg, tb, ta, sr, sg, sb, sa, ignore_t)
	idops.addDropShadow(src, -1,  0, tr, tg, tb, ta, sr, sg, sb, sa, ignore_t)
	idops.addDropShadow(src, -1, -1, tr, tg, tb, ta, sr, sg, sb, sa, ignore_t)
	idops.addDropShadow(src,  0, -1, tr, tg, tb, ta, sr, sg, sb, sa, ignore_t)
	idops.addDropShadow(src,  1, -1, tr, tg, tb, ta, sr, sg, sb, sa, ignore_t)
end


-- * / Public Functions *


return idops

