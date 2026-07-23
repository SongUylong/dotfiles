local M = {}

local function window_geometry(win)
  return {
    x = 0,
    y = 1,
    width = math.max(vim.api.nvim_win_get_width(win) - 2, 1),
    height = math.max(vim.api.nvim_win_get_height(win) - 3, 1),
  }
end

function M.open()
  if vim.fn.executable("pango-view") ~= 1 then
    vim.notify("KhmerView needs pango-view", vim.log.levels.ERROR)
    return
  end

  local source_lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
  local work_dir = vim.fn.tempname() .. "-khmer-view"
  local input_file = work_dir .. "/buffer.txt"
  local output_file = work_dir .. "/buffer.png"
  vim.fn.mkdir(work_dir, "p")
  vim.fn.writefile(source_lines, input_file)

  local render = vim.system({
    "pango-view",
    "--no-display",
    "--pixels",
    "--language=km",
    "--font=Noto Sans Khmer ExtraCondensed 28",
    "--foreground=#E8E2C1",
    "--background=#111318",
    "--margin=36",
    "--width=1500",
    "--wrap=word-char",
    "--line-spacing=1.25",
    "--output=" .. output_file,
    input_file,
  }, { text = true }):wait()

  if render.code ~= 0 then
    vim.fn.delete(work_dir, "rf")
    vim.notify(render.stderr or "KhmerView render failed", vim.log.levels.ERROR)
    return
  end

  require("lazy").load({ plugins = { "image.nvim" } })
  local image_api = require("image")

  vim.cmd("tabnew")
  local buffer = vim.api.nvim_get_current_buf()
  local window = vim.api.nvim_get_current_win()
  vim.api.nvim_buf_set_name(buffer, "Khmer Read View")
  vim.api.nvim_buf_set_lines(buffer, 0, -1, false, {
    "Khmer Read View — press q to close",
    "",
  })
  vim.bo[buffer].buftype = "nofile"
  vim.bo[buffer].bufhidden = "wipe"
  vim.bo[buffer].swapfile = false
  vim.bo[buffer].modifiable = false

  local image = image_api.from_file(output_file, vim.tbl_extend("force", {
    id = "khmer-read-view-" .. buffer,
    window = window,
    buffer = buffer,
  }, window_geometry(window)))
  image:render()

  local closed = false
  local resize_autocmd
  local function cleanup()
    if closed then
      return
    end
    closed = true
    if resize_autocmd then
      pcall(vim.api.nvim_del_autocmd, resize_autocmd)
    end
    pcall(function()
      image:clear()
    end)
    vim.fn.delete(work_dir, "rf")
  end

  vim.keymap.set("n", "q", function()
    cleanup()
    vim.cmd("tabclose")
  end, { buffer = buffer, silent = true, desc = "Close Khmer read view" })

  vim.api.nvim_create_autocmd("BufWipeout", {
    buffer = buffer,
    once = true,
    callback = cleanup,
  })

  resize_autocmd = vim.api.nvim_create_autocmd("WinResized", {
    callback = function()
      if not closed and vim.api.nvim_win_is_valid(window) then
        image:render(window_geometry(window))
      end
    end,
  })
end

function M.setup()
  vim.api.nvim_create_user_command("KhmerView", M.open, {
    desc = "Render current buffer as readable Khmer",
  })
end

return M
