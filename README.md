# printoptions.sile

[![license](https://img.shields.io/github/license/Omikhleia/printoptions.sile?label=License)](LICENSE)
[![Luacheck](https://img.shields.io/github/actions/workflow/status/Omikhleia/printoptions.sile/luacheck.yml?branch=main&label=Luacheck&logo=Lua)](https://github.com/Omikhleia/printoptions.sile/actions?workflow=Luacheck)
[![Luarocks](https://img.shields.io/luarocks/v/Omikhleia/printoptions.sile?label=Luarocks&logo=Lua)](https://luarocks.org/modules/Omikhleia/printoptions.sile)

This package for the [SILE](https://github.com/sile-typesetter/sile) typesetting
system helps tuning image resolution and vector rasterization, as often requested by
professional printers and print-on-demand services.

The package requires Inkscape, GraphicMagick and Ghostscript to be available
on your system, and uses them to convert vector files to rasters and to downsize,
if need be, raster images to the targeted resolution.
If they are not available, everything goes as usual, without conversion.

Some professional printers require the whole PDF to be flattened without transparency,
which is not addressed here. There are other tools, better suited to that task, which
may be used once you have a final PDF document. Most of the time, it results, however,
in a much heavier PDF (in terms of size), as pages may have to be fully rasterized
to remove any layering and compute flattened transparencies.

This package aims at something simpler, would you want to reduce the resolution
(for proofreaders and reviewers) for a smaller PDF; or to ensure, even for print quality,
that images are not indecently oversized and the rasterized vectors still look good
and properly ordered on the page.

## Installation

These packages require SILE v0.14 or upper.

Installation relies on the **luarocks** package manager.

To install the latest development version, you may use the provided “rockspec”:

```
luarocks --lua-version 5.4 install --server=https://luarocks.org/dev printoptions.sile
```

(Adapt to your version of Lua, if need be, and refer to the SILE manual for more
detailed 3rd-party package installation information.)

## Usage

The in-code package documentation may be useful.
A readable version of the documentation is included in the User Manual for
the [resilient.sile](https://github.com/Omikhleia/resilient.sile) collection
of classes and packages.

## License

All SILE-related code and samples in this repository are released under the MIT License, (c) 2022 Omikhleia.
