-- idops: (LÖVE) ImageData Operations
-- Version: 0.0.3 (Beta)
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
		error("bad type for argument #" .. arg_n .. ": expected " .. s1 .. " or " .. s2 .. ", got: " .. type(val))
	end
end

-- Maybe not a good idea at this level.
--[[
local function assertLoveObjectTypeOf(arg_n, val, str)
	if not val or type(val) ~= "userdata" or not val.typeOf or not val:typeOf(str) then
		error("bad type for argument #" .. arg_n .. ": expected 'typeOf' " .. str)
	end
end
--]]


local function compColor(r1, g1, b1, a1, r2, g2, b2, a2)
	return r1 == r2 and g1 == g2 and b1 == b2 and a1 == a2
end


local function pixInBounds(x, y, w, h)
	return x >= 0 and x < w and y >= 0 and y < h
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


local function provisionSpacerColor(src, sr, sg, sb, sa)
	if not sr then
		sr, sg, sb, sa = src:getPixel(0, 0)
	end

	return sr, sg, sb, sa
end


local function buildGlyphList(src, sr, sg, sb, sa)
	-- https://love2d.org/wiki/ImageFontFormat

	local glyphs = {}
	local on_separator = true

	local src_h = src:getHeight()

	for x = 0, src:getWidth() - 1 do
		local r, g, b, a = src:getPixel(x, 0)

		local sep_old = on_separator
		on_separator = compColor(r, g, b, a, sr, sg, sb, sa)

		if sep_old ~= on_separator then
			if not on_separator then
				local glyph = {}
				glyph.x = x
				glyph.y = 0
				glyph.w = 0
				glyph.h = src_h

				table.insert(glyphs, glyph)

			else
				local glyph = glyphs[#glyphs]
				glyph.w = x - glyph.x
			end
		end
	end

	return glyphs
end


-- ImageFont parsing: Count total width of all glyphs, not including spacer columns.
local function countGlyphWidth(glyphs)
	local width = 0
	for _, glyph in ipairs(glyphs) do
		width = width + glyph.w
	end

	return width
end


-- ImageFont parsing: Write a spacer column
local function writeSpacerColumn(src, x, sr, sg, sb, sa)
	for y = 0, src:getHeight() - 1 do
		src:setPixel(x, y, sr, sg, sb, sa)
	end
end


-- ImageFont parsing: Check if a pixel color matches the cut-out transparency key.
local function scanPixel(src, x, y, tr, tg, tb, ta)
	local rr, gg, bb, aa = src:getPixel(x, y)
	if not compColor(rr, gg, bb, aa, tr, tg, tb, ta) then
		return true
	end

	return false
end


-- ImageFont parsing: Strip empty columns from the right and left sides of a glyph rectangle.
local function scanGlyph(src, x, y, w, h, tr, tg, tb, ta)
	local ret_x, ret_y, ret_w, ret_h = x, y, w, h
	local stop

	-- Left-to-right
	stop = false
	for xx = ret_x, ret_x + ret_w - 1 do
		for yy = 0, ret_h - 1 do
			stop = scanPixel(src, xx, yy, tr, tg, tb, ta)
			if stop then
				break
			end
		end
		if stop then
			break
		else
			ret_x = ret_x + 1
			ret_w = ret_w - 1
		end
	end

	-- Right-to-left
	stop = false
	for xx = ret_x + ret_w - 1, ret_x, -1 do
		for yy = 0, ret_h - 1 do
			stop = scanPixel(src, xx, yy, tr, tg, tb, ta)
			if stop then
				break
			end
		end
		if stop then
			break
		else
			ret_w = ret_w - 1
		end
	end

	-- Assume 100% transparent glyphs are intended to be space, and undo the trimming.
	if ret_w <= 0 then
		ret_x, ret_y, ret_w, ret_h = x, y, w, h
	end

	return ret_x, ret_y, ret_w, ret_h
end


-- * / Internal *


-- * Public Functions *


function idops.pasteScaled(src, dst, scale_x, scale_y, src_x, src_y, src_w, src_h, dst_x, dst_y)

	scale_x = scale_x or 1
	assertArgType(3, scale_x, "number")

	scale_y = scale_y or scale_x
	assertArgType(4, scale_y, "number")

	src_x = src_x or 0
	assertArgType(5, src_x, "number")

	src_y = src_y or 0
	assertArgType(6, src_y, "number")

	src_w = src_w or src:getWidth()
	assertArgType(7, src_w, "number")

	src_h = src_h or src:getHeight()
	assertArgType(8, src_h, "number")

	dst_x = dst_x or 0
	assertArgType(9, dst_x, "number")

	dst_y = dst_y or 0
	assertArgType(10, dst_y, "number")

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

	assertArgType(2, sw, "number")

	sh = sh or sw
	assertArgType(3, sh, "number")

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

	assertArgType(2, ox, "number")
	assertArgType(3, oy, "number")
	assertArgType(4, tr, "number")
	assertArgType(5, tg, "number")
	assertArgType(6, tb, "number")
	assertArgType(7, ta, "number")
	assertArgType(8, sr, "number")
	assertArgType(9, sg, "number")
	assertArgType(10, sb, "number")
	assertArgType(11, sa, "number")
	assertArgType2(12, ignore_t, "nil", "table")

	local w, h = src:getDimensions()
	for y = 0, h - 1 do
		for x = 0, w - 1 do
			local r, g, b, a = src:getPixel(x, y)
			local is_tr = compColor(r, g, b, a, tr, tg, tb, ta)

			if pixInBounds(x - ox, y - oy, w, h) then
				if is_tr then
					local r2, g2, b2, a2 = src:getPixel(x - ox, y - oy)

					local do_set = true

					-- Don't cast shadows from fully transparent pixels or other shadows.
					if compColor(r2, g2, b2, a2, sr, sg, sb, sa) or compColor(r2, g2, b2, a2, tr, tg, tb, ta) then
						do_set = false

					elseif ignore_t then
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


function idops.glyphsAddSpacing(src, pad_left, pad_right, pad_top, pad_bottom, sr, sg, sb, sa)

	if type(pad_left) ~= "number" or pad_left < 0
	or type(pad_right) ~= "number" or pad_right < 0
	or type(pad_top) ~= "number" or pad_top < 0
	or type(pad_bottom) ~= "number" or pad_bottom < 0
	then
		error("all padding arguments must be 0 or greater.")
	end
	sr, sg, sb, sa = provisionSpacerColor(src, sr, sg, sb, sa)

	local leading_spacer_cols = 0
	local closing_spacer_cols = 0 -- NOTE: This is in addition to one spacer column written after the last glyph.

	local glyphs = buildGlyphList(src, sr, sg, sb, sa)

	--[[
	New width breakdown:
	+ Leading spacer columns
	+ Total width of all glyphs as they appear in the source
	+ Combined additional left+right padding of all glyphs
	+ Combined 1px spacer columns for all glyphs
	+ Additional closing spacer columns
	--]]
	local new_w = leading_spacer_cols + countGlyphWidth(glyphs) + ((pad_left + pad_right) * #glyphs) + (#glyphs + 1) + closing_spacer_cols
	local new_h = src:getHeight() + (pad_top + pad_bottom)

	local dst = love.image.newImageData(new_w, new_h)

	local dst_x = leading_spacer_cols

	-- Write leading spacer
	for xx = 0, leading_spacer_cols do
		writeSpacerColumn(dst, xx, sr, sg, sb, sa)
	end

	local src_h = src:getHeight()

	-- Write glyphs + spacers
	for i, glyph in ipairs(glyphs) do
		dst_x = dst_x + pad_left

		dst:paste(src, dst_x, pad_top, glyph.x, 0, glyph.w, src_h)

		dst_x = dst_x + glyph.w + pad_right

		writeSpacerColumn(dst, dst_x, sr, sg, sb, sa)

		dst_x = dst_x + 1
	end

	-- Write closing spacer
	for xx = 0, closing_spacer_cols - 1 do
		if dst_x + xx <= dst:getWidth() - 1 then
			writeSpacerColumn(dst, dst_x + xx, sr, sg, sb, sa)
		end
	end

	return dst
end


function idops.glyphsCropHorizontal(src, tr, tg, tb, ta, sr, sg, sb, sa)

	if not tr or not tg or not tb or not ta then
		error("for cropping, arguments 'tr', 'tg', 'tb' and 'ta' must be filled out to represent cut-out transparency.")
	end

	sr, sg, sb, sa = provisionSpacerColor(src, sr, sg, sb, sa)

	local glyphs = buildGlyphList(src, sr, sg, sb, sa)	

	-- Trim glyph boxes in source ImageData first.
	for i, glyph in ipairs(glyphs) do
		glyph.x, glyph.y, glyph.w, glyph.h = scanGlyph(src, glyph.x, glyph.y, glyph.w, glyph.h, tr, tg, tb, ta)
	end

	local leading_spacer_cols = 1
	local closing_spacer_cols = 0

	local new_w = leading_spacer_cols + countGlyphWidth(glyphs) + #glyphs
	local new_h = src:getHeight()

	local dst = love.image.newImageData(new_w, new_h)

	-- Write leading spacer
	writeSpacerColumn(dst, 0, sr, sg, sb, sa)

	local dst_x = 1

	local src_h = src:getHeight()

	-- Write glyphs + spacers
	for i, glyph in ipairs(glyphs) do
		dst:paste(src, dst_x, 0, glyph.x, 0, glyph.w, src_h)

		dst_x = dst_x + glyph.w

		writeSpacerColumn(dst, dst_x, sr, sg, sb, sa)

		dst_x = dst_x + 1
	end

	-- Write closing spacer
	writeSpacerColumn(dst, dst:getWidth() - 1, sr, sg, sb, sa)

	return dst
end


-- * / Public Functions *


return idops

