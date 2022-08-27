--
-- Print options for professional printers
-- 2022, Didier Willis
-- License: MIT
-- Requires: Inkscape and GraphicsMagick to be available on the host system.
-- Reminders: GraphicsMagick also needs Ghostscript for PDF images (it
-- delegates to it).
--
local base = require("packages.base")

local package = pl.class(base)
package._name = "printoptions"

function package.declareSettings (_)
  SILE.settings:declare({
    parameter = "printoptions.resolution",
    type = "integer or nil",
    default = nil,
    help = "If set, defines the target image resolution in dpi (dots per inch)"
  })

  SILE.settings:declare({
    parameter = "printoptions.vector.rasterize",
    type = "boolean",
    default = true,
    help = "When true and resolution is set, SVG vectors are rasterized."
  })

  SILE.settings:declare({
    parameter = "printoptions.image.flatten",
    type = "boolean",
    default = false,
    help = "When true and resolution is set, images are flattened (transparency removed)."
  })
end

local function handlePath (filename)
  local basename = pl.path.basename(filename):match("(.+)%..+$")
  local ext = pl.path.extension(filename)
  if not basename or not ext then
    SU.error("Cannot split path and extension in "..filename)
  end

  local dir = pl.path.join(pl.path.dirname(SILE.masterFilename), "converted")
  if not pl.path.exists(dir) then
    pl.path.mkdir(dir)
  end
  return pl.path.join(dir, basename), ext
end

local function imageResolutionConverter (filename, widthInPx, resolution, pageno)
  local sourceFilename = filename
  local basename, ext = handlePath(filename)
  local flatten = SILE.settings:get("printoptions.image.flatten")

  if pageno then
    -- Use specified page if provided (e.g. for PDF).
    sourceFilename = filename .. "[" .. (pageno - 1) .. "]" -- Graphicsmagick page numbers start at 0.
    basename = pageno and basename .. "-p" .. pageno
  end

  local targetFilename = basename .. "-".. widthInPx .. "-" .. resolution
  if flatten then
    targetFilename = targetFilename .. "-flat"
  end
  targetFilename = targetFilename .. ext

  local sourceTime = pl.path.getmtime(filename)
  if sourceTime == nil then
    SU.debug("printoptions", "Source file not found "..filename)
    return nil
  end

  local targetTime = pl.path.getmtime(targetFilename)
  if targetTime ~= nil and targetTime > sourceTime then
    SU.debug("printoptions", "Source file already converted "..filename)
    return targetFilename
  end

  local command
  if flatten then
    command = table.concat({
      "gm convert",
      sourceFilename ,
      "-units PixelsPerInch",
      -- disable antialiasing (best effort)
      "+antialias",
      "-filter point",
      -- resize
      "-resize "..widthInPx.."x\\>",
      "-density "..resolution,
      -- make grayscale + flattened
      "-background white",
      "-flatten",
      "-colorspace GRAY",
      targetFilename,
    }, " ")
  else
    command = table.concat({
      "gm convert",
      sourceFilename,
      "-units PixelsPerInch",
      -- disable antialiasing (best effort)
      "+antialias",
      "-filter point",
      -- resize
      "-resize "..widthInPx.."x\\>",
      "-density "..resolution,
      -- make grayscale
      "-colorspace GRAY",
      targetFilename,
    }, " ")
  end
  SU.debug("printoptions", "Command: "..command)
  local result = os.execute(command)
  if type(result) ~= "boolean" then result = (result == 0) end
  if result then
    SU.debug("printoptions", "Converted "..filename.." to "..targetFilename)
    return targetFilename
  else
    return nil
  end
end

local function svgRasterizer (filename, widthInPx, _)
  local basename, ext = handlePath(filename)
  if ext ~= ".svg" then SU.error("Expected SVG file for "..filename) end
  local wpx = widthInPx * 2 -- See further below
  local targetFilename = basename .. "-svg-"..wpx..".png"

  local sourceTime = pl.path.getmtime(filename)
  if sourceTime == nil then
    SU.debug("printoptions", "Source file not found "..filename)
    return nil
  end

  local targetTime = pl.path.getmtime(targetFilename)
  if targetTime ~= nil and targetTime > sourceTime then
    SU.debug("printoptions", "Source file already converted "..filename)
    return targetFilename
  end

  -- Inkscape is better than imagemagick's convert at converting a SVG...
  -- But it handles badly the resolution...
  -- Anyway, we'll just convert to PNG and let the outputter resize the image.
  local toSvg = table.concat({
    "inkscape",
    filename,
    "-w ".. wpx, -- FIXME. I could not find a proper way to disable antialiasing
                 -- So target twice the actual size, and the image conversion to
                 -- resolution will also downsize without antialiasing.
                 -- This is far from perfect, but minimizes the antialiasing a bit...
    "-o",
    targetFilename,
  }, " ")
  local result = os.execute(toSvg)
  if type(result) ~= "boolean" then result = (result == 0) end
  if result then
    SU.debug("printoptions", "Converted "..filename.." to "..targetFilename)
    return targetFilename
  else
    return nil
  end
end

local drawSVG = function (filename, svgdata, width, height, density)
  -- FIXME/CAVEAT: We are reimplementing the whole logic from _drawSVG in the
  -- "svg" package, but the latter might be wrong:
  -- See https://github.com/sile-typesetter/sile/pull/1517
  local svg = require("svg")
  local svgfigure, svgwidth, svgheight = svg.svg_to_ps(svgdata, density)
  SU.debug("svg", string.format("PS: %s\n", svgfigure))
  local scalefactor = 1
  if width and height then
    -- local aspect = svgwidth / svgheight
    SU.error("SILE cannot yet change SVG aspect ratios, specify either width or height but not both")
  elseif width then
    scalefactor = width:tonumber() / svgwidth
  elseif height then
    scalefactor = height:tonumber() / svgheight
  end
  width = SILE.measurement(svgwidth * scalefactor)
  height = SILE.measurement(svgheight * scalefactor)
  scalefactor = scalefactor * density / 72

  local resolution = SILE.settings:get("printoptions.resolution")
  local rasterize = SILE.settings:get("printoptions.vector.rasterize")
  if resolution and resolution > 0 and rasterize then
    local targetWidthInPx = math.ceil(SU.cast("number", width) * resolution / 72)
    local converted = svgRasterizer(filename, targetWidthInPx, resolution)
    if converted then
      SILE.call("img", { src = converted, width = width })
      return -- We are done replacing the SVG by a raster image
    end
    SU.warn("Resolution failure for "..filename..", using original image")
  end

  SILE.typesetter:pushHbox({
    value = nil,
    height = height,
    width = width,
    depth = 0,
    outputYourself = function (self, typesetter)
      SILE.outputter:drawSVG(svgfigure, typesetter.frame.state.cursorX, typesetter.frame.state.cursorY, self.width, self.height, scalefactor)
      typesetter.frame:advanceWritingDirection(self.width)
    end
  })
end

function package:_init (pkgoptions)
  base._init(self, pkgoptions)
  self.class:loadPackage("image")
  -- We do this to enforce loading the \svg command now.
  -- so our version here can override it.
  self.class:loadPackage("svg")
  self:registerCommand("svg", function (options, _)
    local src = SU.required(options, "src", "filename")
    local filename = SILE.resolveFile(src) or SU.error("Couldn't find file "..src)
    local width = options.width and SU.cast("measurement", options.width):absolute() or nil
    local height = options.height and SU.cast("measurement", options.height):absolute() or nil
    local density = options.density or 72
    local svgfile = io.open(filename)
    local svgdata = svgfile:read("*all")
    drawSVG(filename, svgdata, width, height, density)
  end)

  local outputter = SILE.outputter.drawImage -- for override
  SILE.outputter.drawImage = function (outputterSelf, filename, x, y, width, height, pageno)
    local resolution = SILE.settings:get("printoptions.resolution")
    if resolution and resolution > 0 then
      SU.debug("printoptions", "Conversion to "..resolution.. " DPI for "..filename)
      local targetWidthInPx = math.ceil(SU.cast("number", width) * resolution / 72)
      local converted = imageResolutionConverter(filename, targetWidthInPx, resolution, pageno)
      if converted then
        outputter(outputterSelf, converted, x, y, width, height)
        return -- We are done replacing the original image by its resampled version.
      end
      SU.warn("Resolution failure for "..filename..", using original image")
    end
    outputter(outputterSelf, filename, x, y, width, height, pageno)
  end
end

package.documentation = [[\begin{document}
The \autodoc:package{printoptions} package provides a few settings that allow tuning
image resolution and vector rasterization, as often requested by
professional printers and print-on-demand services.

The \autodoc:setting{printoptions.resolution} setting, when set to an integer
value, defines the expected image resolution in dpi (dots per inch).
It could be set to 300 or 600 for final offset print or, say, to 150
or lower for a low-resolution PDF for reviewers and proofreaders.
Images are resampled to the target resolution (if they have
a higher resolution) and are converted to grayscale.

The \autodoc:setting{printoptions.vector.rasterize} setting defaults to true.
If a target image resolution is defined and this setting is left enabled,
then vector images are rasterized. It currently applies to SVG files,
redefining the \autodoc:command[check=false]{\svg} command.

Converted images are all placed in a \code{converted} folder besides
the master file. Be cautious not having images with the same base filename
in different folders, to avoid conflicts!

The package requires Inkscape, GraphicMagick and Ghostscript to be available
on your system.

Moreover, if the \autodoc:setting{printoptions.image.flatten} setting is
turned to true (its default being false), not only images are resampled,
but they are also flattened with a white background. You probably do not
want to enable this setting for production, but it might be handy for
checking things before going to print.
(Most professional printers require the whole PDF to be flattened without
transparency, which is not addressed here; but the assumption is that you might
check what could happen if transparency is improperly managed by your printer
and/or you have layered contents incorrectly ordered.)
\end{document}]]

return package
