-- Arduino / ESP32 dev — wire the official arduino-language-server into the
-- existing nvim-lspconfig so `.ino` tabs get real autocomplete + diagnostics.
-- It's the only LSP that handles Arduino's multi-tab preprocessing (implicit
-- Arduino.h + auto-generated prototypes) that plain clangd chokes on; it spawns
-- its own clangd under the hood.
--
-- Binary: ~/bin/arduino-language-server (v0.7.7, installed manually -> mason=false).
-- The -fqbn MUST stay in sync with firmware/pixel_canvas/sketch.yaml (`box` profile).
-- Absolute paths so it works regardless of how nvim's PATH is set.
return {
  {
    "neovim/nvim-lspconfig",

    opts = {
      servers = {
        arduino_language_server = {
          mason = false,
          cmd = {
            vim.fn.expand("~/bin/arduino-language-server"),
            "-cli", "/opt/homebrew/bin/arduino-cli",
            "-cli-config", vim.fn.expand("~/Library/Arduino15/arduino-cli.yaml"),
            "-clangd", "/usr/bin/clangd",
            "-fqbn", "esp32:esp32:esp32s3:CDCOnBoot=cdc,FlashSize=16M,PSRAM=opi",
          },
        },
      },
    },
  },

  -- Optional (research win #4, left off by default): full C++ highlighting on
  -- .ino tabs instead of the weak `arduino` parser. Uncomment to enable.
  -- {
  --   "neovim/nvim-lspconfig",
  --   init = function()
  --     vim.treesitter.language.register("cpp", "arduino")
  --   end,
  -- },
}
