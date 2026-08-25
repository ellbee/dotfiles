-- ~/.config/nvim/lua/incremental_selection.lua
-- Expand and shrink the visual selection along the treesitter tree.
--
--   <CR>   start from the node under the cursor, then grow to its parent
--   <BS>   step back to the previously selected node
--
-- The `main` branch of nvim-treesitter dropped the `incremental_selection`
-- module that used to provide this, so it is reimplemented here on top of the
-- built-in `vim.treesitter` API.

local M = {}

-- One node stack per buffer. Keyed weakly so the entry disappears with the
-- buffer rather than being left behind on every wipeout.
local stacks = setmetatable({}, { __mode = "k" })

local function stack_for(buf)
  stacks[buf] = stacks[buf] or {}
  return stacks[buf]
end

-- Node ranges are (row, col) 0-indexed with an exclusive end column; marks are
-- 1-indexed with an inclusive end. `setpos` on '< and '> then `gv` is used
-- instead of driving `v` motions so the selection lands exactly on the node
-- regardless of where the cursor happens to be sitting.
local function select_node(node)
  local sr, sc, er, ec = node:range()

  -- A node ending at column 0 spans up to but not including that line; pull
  -- the end back onto the last character of the previous line so the trailing
  -- newline is not swallowed into the selection.
  if ec == 0 and er > sr then
    er = er - 1
    ec = #vim.fn.getline(er + 1)
  end

  vim.fn.setpos("'<", { 0, sr + 1, sc + 1, 0 })
  vim.fn.setpos("'>", { 0, er + 1, ec, 0 })
  vim.cmd("normal! gv")
end

-- Walk up until a node that actually covers more text than `node`. Wrappers
-- that share their child's exact range (common around expressions) would
-- otherwise make <CR> look like it did nothing.
local function larger_parent(node)
  local sr, sc, er, ec = node:range()
  local parent = node:parent()
  while parent do
    local psr, psc, per, pec = parent:range()
    if psr ~= sr or psc ~= sc or per ~= er or pec ~= ec then
      return parent
    end
    parent = parent:parent()
  end
  return nil
end

--- Select the node under the cursor, seeding a fresh stack.
function M.init()
  local ok, node = pcall(vim.treesitter.get_node)
  if not ok or not node then
    vim.notify("incremental_selection: no treesitter node under the cursor",
      vim.log.levels.WARN)
    return
  end

  local stack = stack_for(vim.api.nvim_get_current_buf())
  -- Replace rather than append: a new <CR> from normal mode starts over.
  for i = #stack, 1, -1 do stack[i] = nil end
  stack[1] = node
  select_node(node)
end

--- Grow the selection to the nearest enclosing node.
function M.expand()
  local stack = stack_for(vim.api.nvim_get_current_buf())
  local node = stack[#stack]

  -- Entering from a selection this module did not make (a plain `v` motion,
  -- say) leaves the stack empty, so fall back to the cursor node.
  if not node then
    local ok, cursor_node = pcall(vim.treesitter.get_node)
    if not ok or not cursor_node then return end
    node = cursor_node
    stack[1] = node
  end

  local parent = larger_parent(node)
  if not parent then
    -- Already at the root: keep the current selection instead of collapsing.
    select_node(node)
    return
  end

  stack[#stack + 1] = parent
  select_node(parent)
end

--- Shrink back to the previously selected node.
function M.shrink()
  local stack = stack_for(vim.api.nvim_get_current_buf())
  if #stack == 0 then return end
  if #stack > 1 then
    stack[#stack] = nil
  end
  select_node(stack[#stack])
end

--- Map <CR>/<BS> in the current buffer. Called from a FileType autocmd so the
--- mappings only exist where a parser is attached, leaving <CR> alone in
--- quickfix, netrw, and other list-like buffers.
function M.attach(buf)
  buf = buf or vim.api.nvim_get_current_buf()

  vim.keymap.set("n", "<CR>", M.init,
    { buffer = buf, desc = "Init treesitter selection" })
  vim.keymap.set("x", "<CR>", M.expand,
    { buffer = buf, desc = "Expand treesitter selection" })
  vim.keymap.set("x", "<BS>", M.shrink,
    { buffer = buf, desc = "Shrink treesitter selection" })
end

--- Attach to every buffer that has a treesitter parser running.
function M.setup()
  local group = vim.api.nvim_create_augroup("MyIncrementalSelection",
    { clear = true })

  -- FileType fires after the parser has been started by the treesitter
  -- config, and re-fires on every new buffer of that type.
  vim.api.nvim_create_autocmd("FileType", {
    group = group,
    callback = function(args)
      -- Only where a parser actually exists; vim.treesitter.get_parser
      -- throws for unsupported filetypes, hence the pcall.
      local ok, parser = pcall(vim.treesitter.get_parser, args.buf, nil,
        { error = false })
      if ok and parser then
        M.attach(args.buf)
      end
    end,
  })
end

return M
