# barcodes.sile

[![license](https://img.shields.io/github/license/Omikhleia/printoptions.sile)](LICENSE)
[![Luacheck](https://img.shields.io/github/workflow/status/Omikhleia/printoptions.sile/Luacheck?label=Luacheck&logo=Lua)](https://github.com/Omikhleia/printoptions.sile/actions?workflow=Luacheck)
[![Luarocks](https://img.shields.io/luarocks/v/Omikhleia/printoptions.sile?label=Luarocks&logo=Lua)](https://luarocks.org/modules/Omikhleia/printoptions.sile)

This package for the [SILE](https://github.com/sile-typesetter/sile) typesetting
system helps tuning image resolution and vector rasterization, as often requested by
professional printers and print-on-demand services.

The package requires Inkscape and GraphicMagick to be available on your system, and
uses them to convert vector files to rasters and to downsize, if need be, raster
images to the targeted resolution. If they are not available, everything goes as
usual, without conversion.

Most professional printers require the whole PDF to be flattened without transparency,
which is not addressed here. There are other tools, better suited to that task, which
may be used once you have a PDF document. This package aims at something simpler,
would you want to reduce the resolution (for proofreaders and reviewers) for a smaller
PDF, or to ensure, even for print quality, that images are not indecently oversized.

## Installation

These packages require SILE v0.14 or upper.

Installation relies on the **luarocks** package manager.

To install the latest development version, you may use the provided “rockspec”:

```
luarocks --lua-version 5.4 install --server=https://luarocks.org/dev printoptions.sile
```

(Adapt to your version of Lua, if need be, and refer to the SILE manual for more
detailed 3rd-party package installation information.)
