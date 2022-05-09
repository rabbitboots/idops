# idops.lua

Idops (ImageData Operations) contains some utility functions for working with LÖVE ImageData objects, particularly those intended to be used as ImageFonts.

Idops (IDOps?) is not complete and hasn't been thoroughly tested. I'm putting it online because I'm using it in a few different projects, and want to keep track of the most recently updated copy. It's MIT-licensed, so you can do almost anything you want with it. Just be aware that the functions in this repo aren't totally settled yet.


## Functions

* `idops.pasteScaled(src, dst, scale_x, scale_y, src_x, src_y, src_w, src_h, dst_x, dst_y)`

Pastes the contents of one ImageData into another, with some basic scaling support (nearest neighbor only). The paste region is always at least 1x1 in size.

`src` The source ImageData.
`dst` The destination ImageData.
`scale_x` *(1)* The pasted X scale.
`scale_y` *(1)* The pasted Y scale.
`src_x` *(0)* Top-left X position in the source ImageData.
`src_y` *(0)* Top-left Y position in the source ImageData.
`src_w` *(src:getWidth())* How many pixels to copy from src_x.
`src_h` *(src:getHeight())* How many pixels to copy from src_y.
`dst_x` *(0)* Top-left X position in the destination ImageData.
`dst_y` *(0)* Top-left Y position in the destination ImageData.

Returns: Nothing. Destination ImageData is modified in-place.


* `idops.scaleIntegral(src, sw, sh)`

Returns a scaled copy of ImageData `src` by integral amounts (2x, 3x, etc.)

`src` The source ImageData to use.
`sw` The new horizontal scale. Must be an integer >= 1.
`sh` The new vertical scale. Must be an integer >= 1.

Returns: The scaled ImageData.


* `idops.replaceRGBA(src, r1, g1, b1, a1, r2, g2, b2, a2)`

Replaces pixels matching one set of RGBA values with a the second RGBA set.

`src` The ImageData to modify.
`r1` The target red value to check, in the range of 0-1.
`g1` The target green value.
`b1` The target blue value.
`a1` The target alpha value.
`r2` The replacement red value, in the range of 0-1.
`g2` The replacement green value.
`b2` The replacement blue value.
`a2` The replacement alpha value.

Returns: Nothing. ImageData is modified in-place.


* `idops.replaceRGB(src, r1, g1, b1, r2, g2, b2)`

Like `idops.replaceRGBA()`, but doesn't check or modify the alpha channel.

`src` The ImageData to modify.
`r1` The target red value to check, in the range of 0-1.
`g1` The target green value.
`b1` The target blue value.
`r2` The replacement red value, in the range of 0-1.
`g2` The replacement green value.
`b2` The replacement blue value.

Returns: Nothing. ImageData is modified in-place.


* `idops.addDropShadow(i_data, ox, oy, tr, tg, tb, ta, sr, sg, sb, sa, ignore_t)`

Adds a basic drop shadow to an ImageData. Intended for ImageFonts.

`src` The ImageData to modify.
`ox` Shadow X pixel offset.
`oy` Shadow Y pixel offset.
`tr` Transparency color key: red. Shadows will be applied to these pixels only.
`tg` Transparency color key: green.
`tb` Transparency color key: blue.
`ta` Transparency color key: alpha.
`sr` Shadow color: red.
`sg` Shadow color: green.
`sb` Shadow color: blue.
`sa` Shadow color: alpha.
`ignore_t` *(Optional)* Table of tables (ie `{{1, 0, 0, 1}, {0, 1, 0, 1}, [etc.]}`), specifying colors which should not be treated as casting shadows. In an ImageFont graphic, you'd pass the separator color here. Note that it's a linear search, so adding several color tables could have performance implications.

Returns: Nothing. ImageData is modified in-place.


* `idops.addOutline4(src, tr, tg, tb, ta, sr, sg, sb, sa, ignore_t)`

Adds a basic outline by running `idops.addDropShadow()` to the top, bottom, left, and right neighbors of each eligible pixel.

`src` The ImageData to modify.
`tr` Transparency color key: red. The outline will be applied to these pixels only.
`tg` Transparency color key: green.
`tb` Transparency color key: blue.
`ta` Transparency color key: alpha.
`sr` Outline color: red.
`sg` Outline color: green.
`sb` Outline color: blue.
`sa` Outline color: alpha.
`ignore_t` *(Optional)* Table of tables (ie `{{1, 0, 0, 1}, {0, 1, 0, 1}, [etc.]}`), specifying colors which should not be treated as possible outline contours. Note that it's a linear search, so adding several color tables could have performance implications.

Returns: Nothing. The ImageData is modified in-place.


* `idops.addOutline8(src, tr, tg, tb, ta, sr, sg, sb, sa, ignore_t)`

Like `idops.addOutline4()`, but applies the drop-shadow function to all eight neighbors of every eligible pixel.

`src` The ImageData to modify.
`tr` Transparency color key: red. The outline will be applied to these pixels only.
`tg` Transparency color key: green.
`tb` Transparency color key: blue.
`ta` Transparency color key: alpha.
`sr` Outline color: red.
`sg` Outline color: green.
`sb` Outline color: blue.
`sa` Outline color: alpha.
`ignore_t` *(Optional)* Table of tables (ie `{{1, 0, 0, 1}, {0, 1, 0, 1}, [etc.]}`), specifying colors which should not be treated as possible outline contours. Note that it's a linear search, so adding several color tables could have performance implications.

Returns: Nothing. The ImageData is modified in-place.


## License

Copyright (c) 2022 RBTS

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.


