-- fff.nvim — a Rust-backed, frecency-aware fuzzy file picker.
-- https://github.com/dmtrKovalenko/fff.nvim
--
-- `build` downloads a prebuilt binary (falls back to `cargo build` if a
-- Rust toolchain is present). `lazy = false` is recommended by the plugin so
-- it can index files in the background and stay fast on the first open.
return {
  {
    "dmtrKovalenko/fff.nvim",
    build = function()
      require("fff.download").download_or_build_binary()
    end,
    lazy = false,
    opts = {},
    keys = {
      -- Primary fuzzy file finder (replaces Telescope on <leader>ff;
      -- Telescope find_files stays available on <leader>fF).
      {
        "<leader>ff",
        function()
          require("fff").find_files()
        end,
        desc = "Find files (fff)",
      },
    },
  },
}
