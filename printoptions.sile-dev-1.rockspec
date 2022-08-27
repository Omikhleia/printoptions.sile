package = "printoptions.sile"
version = "dev-1"
source = {
  url = "git://github.com/Omikhleia/printoptions.sile.git",
}
description = {
  summary = "Image tools for professional printers with the SILE typesetting system.",
  detailed = [[
    This package for the SILE typesetter helps tuning image resolution and vector rasterization,
    as often requested by professional printers and print-on-demand services.
  ]],
  homepage = "https://github.com/Omikhleia/printoptions.sile",
  license = "MIT",
}
dependencies = {
  "lua >= 5.1",
}
build = {
  type = "builtin",
  modules = {
    ["sile.packages.printoptions"] = "packages/printoptions/init.lua",
  }
}
