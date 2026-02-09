return {
  {
    "mistricky/codesnap.nvim",
    build = "make",
    keys = {
      -- Map <leader>sc to our custom PNG copy function
      {
        "<leader>sc",
        function()
          require("codesnap-custom").copy_as_png()
        end,
        mode = "v",
        desc = "CodeSnap PNG to clipboard",
      },
      { "<leader>sC", ":CodeSnapSave<CR>", mode = "v", desc = "CodeSnap save to file" },
    },
    config = function()
      -- 1. DEFINE CUSTOM COPY FUNCTION
      -- This saves a temp PNG and copies it using AppleScript (macOS) to force PNG format.
      local custom_module = {}
      function custom_module.copy_as_png()
        local codesnap = require("codesnap")
        -- Create a temp path
        local path = os.tmpname() .. ".png"

        -- Save to that path (CodeSnap v2 generates PNG by default for .png extension)
        codesnap.save(path)

        -- Wait briefly for file to write, then copy to clipboard as PNG data
        vim.defer_fn(function()
          -- macOS command to read file as PNG data into clipboard
          vim.fn.system("osascript -e 'set the clipboard to (read (POSIX file \"" .. path .. "\") as «class PNGf»)'")

          -- [[ CLEANUP: Delete the temp file now that it is in the clipboard ]]
          os.remove(path)

          vim.notify("Snapshot copied as PNG!", vim.log.levels.INFO)
        end, 200) -- 200ms delay to ensure save completes
      end

      -- Expose for the keymap above
      package.loaded["codesnap-custom"] = custom_module

      -- 2. SETUP (Pure Code Settings)
      require("codesnap").setup({
        show_workspace = false,
        show_line_number = true, -- Set false if you want absolutely no text metadata

        snapshot_config = {
          -- Pure Code: No window controls, no shadow, no padding
          window = {
            mac_window_bar = false, -- Remove traffic lights
            shadow = { radius = 0 }, -- Remove shadow
            margin = { x = 0, y = 0 }, -- Remove background padding
            border = { width = 0 }, -- Ensure no border
          },

          -- Transparent Background
          background = "#00000000",

          -- Remove Watermark
          watermark = { content = "" },

          -- Remove Breadcrumbs header
          code_config = {
            breadcrumbs = { enable = false },
          },
        },
      })
    end,
  },
}
