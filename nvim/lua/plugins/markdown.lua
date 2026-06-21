-- Point markdownlint-cli2 at a single global config regardless of nvim's cwd.
--
-- nvim-lint runs `markdownlint-cli2 -` over stdin, and markdownlint-cli2 only
-- discovers config files from the cwd downward (not parent directories), so
-- editing markdown anywhere outside the config's directory would otherwise fall
-- back to the strict defaults. Passing --config explicitly makes the relaxed
-- rules (see ~/.markdownlint-cli2.yaml) apply everywhere.
return {
  {
    "mfussenegger/nvim-lint",
    opts = {
      linters = {
        ["markdownlint-cli2"] = {
          args = { "--config", vim.fn.expand("~/.markdownlint-cli2.yaml"), "-" },
        },
      },
    },
  },
}
