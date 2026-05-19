-- ~/.config/nvim/lua/agenda.lua
-- Agenda picker: scrapes tasks from epic notes in ~/notes
--
-- Frontmatter (per note):
--   epic: Profile/DNP3
--   tags: [rust, protocol]        (optional)
--
-- Task syntax (in note body):
--   - [ ] Task title | due: 2026-05-10 | priority: high
--   - [x] Done task | due: 2026-05-08 | priority: low
--
-- Keymaps in picker:
--   <CR>      open note at task line
--   <C-d>     mark task done ([ ] → [x]), refresh picker
--   <C-t>     toggle display of done tasks

local pickers       = require("telescope.pickers")
local finders       = require("telescope.finders")
local conf          = require("telescope.config").values
local actions       = require("telescope.actions")
local action_state  = require("telescope.actions.state")
local entry_display = require("telescope.pickers.entry_display")

local M = {}

local NOTES_DIR = vim.fn.expand("~/notes")

local function setup_highlights()
  vim.api.nvim_set_hl(0, "AgendaOverdue",  { fg = "#E24B4A", bold = true })
  vim.api.nvim_set_hl(0, "AgendaToday",    { fg = "#EF9F27", bold = true })
  vim.api.nvim_set_hl(0, "AgendaUpcoming", { fg = "#1D9E75" })
  vim.api.nvim_set_hl(0, "AgendaDone",     { fg = "#888780", italic = true })
  vim.api.nvim_set_hl(0, "AgendaLabel",    { fg = "#888780" })
  vim.api.nvim_set_hl(0, "AgendaPriority", { fg = "#7F77DD", bold = true })
end

local function parse_date(s)
  if not s or s == "" then return nil end
  local y, mo, d = s:match("^(%d%d%d%d)-(%d%d)-(%d%d)$")
  if not y then return nil end
  return { year = tonumber(y), month = tonumber(mo), day = tonumber(d), raw = s }
end

local function today()
  local t = os.date("*t")
  return { year = t.year, month = t.month, day = t.day }
end

local function classify(due, done)
  if done then return "done" end
  if not due then return "unknown" end
  local t = today()
  if due.year < t.year
    or (due.year == t.year and due.month < t.month)
    or (due.year == t.year and due.month == t.month and due.day < t.day)
  then
    return "overdue"
  elseif due.year == t.year and due.month == t.month and due.day == t.day then
    return "today"
  else
    return "upcoming"
  end
end

local function read_frontmatter(path)
  local f = io.open(path, "r")
  if not f then return nil end
  local first = f:read("*l")
  if first ~= "---" then f:close(); return nil end
  local fm = {}
  for line in f:lines() do
    if line == "---" then break end
    local k, v = line:match("^(%w+):%s*(.-)%s*$")
    if k then
      fm[k] = v:match('^"(.*)"$') or v:match("^'(.*)'$") or v
    end
  end
  f:close()
  return fm
end

local function epic_from_path(path)
  local name = path:match("([^/]+)%.md$") or path
  return name:gsub("[-_]", " ")
end

local function parse_task_line(line, lnum)
  local done_marker, rest = line:match("^%s*%- %[([x ])%] (.+)$")
  if not done_marker then return nil end

  local done  = (done_marker == "x")
  local parts = vim.split(rest, "|", { plain = true, trimempty = false })

  local title    = vim.trim(parts[1] or "")
  local due_raw  = ""
  local priority = ""

  for i = 2, #parts do
    local seg = vim.trim(parts[i])
    local v = seg:match("^due:%s*(.+)$")
    if v then due_raw = vim.trim(v) end
    v = seg:match("^priority:%s*(.+)$")
    if v then priority = vim.trim(v) end
  end

  local due = parse_date(due_raw)
  local cls = classify(due, done)

  return {
    title    = title,
    due      = due,
    due_raw  = due_raw,
    priority = priority,
    done     = done,
    cls      = cls,
    lnum     = lnum,
  }
end

-- ---------------------------------------------------------------------------
-- Collection: scan all notes, extract tasks
-- ---------------------------------------------------------------------------

local function collect_entries()
  local cmd = {
    "rg", "--files-with-matches", "--glob", "*.md",
    "^\\s*- \\[[ x]\\]",
    NOTES_DIR,
  }
  local result = vim.system(cmd, { text = true }):wait()

  if result.code ~= 0 or not result.stdout or result.stdout == "" then
    return {}
  end

  local entries = {}

  for path in result.stdout:gmatch("[^\n]+") do
    local fm   = read_frontmatter(path) or {}
    local epic = fm.epic or epic_from_path(path)

    local f = io.open(path, "r")
    if f then
      local lnum = 0
      for line in f:lines() do
        lnum = lnum + 1
        local task = parse_task_line(line, lnum)
        if task then
          table.insert(entries, {
            path     = path,
            epic     = epic,
            title    = task.title,
            due      = task.due,
            due_raw  = task.due_raw,
            priority = task.priority,
            done     = task.done,
            cls      = task.cls,
            lnum     = task.lnum,
          })
        end
      end
      f:close()
    end
  end

  -- Sort: overdue → today → upcoming → unknown → done; then by date
  local order = { overdue = 1, today = 2, upcoming = 3, unknown = 4, done = 5 }
  table.sort(entries, function(a, b)
    local oa = order[a.cls] or 9
    local ob = order[b.cls] or 9
    if oa ~= ob then return oa < ob end
    return (a.due_raw or "") < (b.due_raw or "")
  end)

  return entries
end

-- ---------------------------------------------------------------------------
-- Mark done: rewrite [ ] → [x] on the task's line
-- ---------------------------------------------------------------------------

local function mark_done(path, lnum)
  local lines = {}
  local f = io.open(path, "r")
  if not f then
    vim.notify("agenda: cannot open " .. path, vim.log.levels.ERROR)
    return false
  end
  for line in f:lines() do table.insert(lines, line) end
  f:close()

  local target = lines[lnum]
  if not target then
    vim.notify("agenda: line " .. lnum .. " not found in " .. path, vim.log.levels.ERROR)
    return false
  end

  local updated, n = target:gsub("%- %[ %]", "- [x]", 1)
  if n == 0 then
    vim.notify("agenda: task already done or pattern mismatch", vim.log.levels.WARN)
    return false
  end

  lines[lnum] = updated
  local out = io.open(path, "w")
  if not out then
    vim.notify("agenda: cannot write " .. path, vim.log.levels.ERROR)
    return false
  end
  out:write(table.concat(lines, "\n") .. "\n")
  out:close()
  return true
end

-- ---------------------------------------------------------------------------
-- Mark done at cursor (normal mode, outside picker)
-- ---------------------------------------------------------------------------

function M.mark_done_at_cursor()
  local lnum = vim.api.nvim_win_get_cursor(0)[1]
  local line = vim.api.nvim_buf_get_lines(0, lnum - 1, lnum, false)[1] or ""

  local updated
  if line:match("^%s*%- %[ %]") then
    local ts = os.date("%Y-%m-%d %H:%M:%S")
    updated = line:gsub("%- %[ %]", "- [x]", 1) .. " | completed: " .. ts
    vim.notify("Done", vim.log.levels.INFO)
  elseif line:match("^%s*%- %[x%]") then
    updated = line:gsub("%- %[x%]", "- [ ]", 1)
    updated = updated:gsub("%s*| completed: %d%d%d%d%-%d%d%-%d%d %d%d:%d%d:%d%d%s*$", "")
    vim.notify("Marked incomplete", vim.log.levels.INFO)
  else
    vim.notify("agenda: cursor is not on a task line", vim.log.levels.WARN)
    return
  end

  vim.api.nvim_buf_set_lines(0, lnum - 1, lnum, false, { updated })
  vim.cmd("write")
end

-- ---------------------------------------------------------------------------
-- Telescope picker
-- ---------------------------------------------------------------------------

local ICON = {
  overdue  = "! ",
  today    = "▶ ",
  upcoming = "  ",
  done     = "✓ ",
  unknown  = "  ",
}

local CLS_HL = {
  overdue  = "AgendaOverdue",
  today    = "AgendaToday",
  upcoming = "AgendaUpcoming",
  done     = "AgendaDone",
  unknown  = "AgendaLabel",
}

function M.open(opts)
  setup_highlights()
  opts = opts or {}

  local all_entries = collect_entries()
  if #all_entries == 0 then
    vim.notify("agenda: no tasks found in " .. NOTES_DIR, vim.log.levels.WARN)
    return
  end

  local show_done = false

  local displayer = entry_display.create({
    separator = " ",
    items = {
      { width = 2  },       -- status icon
      { width = 11 },       -- due date
      { width = 8  },       -- priority
      { width = 20 },       -- epic
      { remaining = true }, -- task title
    },
  })

  local function make_display(entry)
    local e  = entry.value
    local hl = CLS_HL[e.cls] or "AgendaLabel"
    return displayer({
      { ICON[e.cls] or "  ", hl               },
      { e.due_raw,            hl               },
      { e.priority,           "AgendaPriority" },
      { e.epic,               "AgendaLabel"    },
      { e.title,              "Normal"         },
    })
  end

  local function filtered(entries)
    if show_done then return entries end
    return vim.tbl_filter(function(e) return e.cls ~= "done" end, entries)
  end

  local function make_finder(entries)
    return finders.new_table({
      results = filtered(entries),
      entry_maker = function(e)
        return {
          value   = e,
          display = make_display,
          ordinal = (e.due_raw or "") .. " " .. e.epic .. " " .. e.title,
          path    = e.path,
          lnum    = e.lnum,
        }
      end,
    })
  end

  local function prompt_title()
    return show_done and "Agenda [+done]" or "Agenda"
  end

  pickers.new(opts, {
    prompt_title = prompt_title(),
    finder       = make_finder(all_entries),
    sorter       = conf.generic_sorter(opts),
    previewer    = conf.file_previewer(opts),
    attach_mappings = function(prompt_bufnr, map)

      -- <CR> → open note at task line
      actions.select_default:replace(function()
        actions.close(prompt_bufnr)
        local sel = action_state.get_selected_entry()
        if sel then
          vim.cmd("edit " .. vim.fn.fnameescape(sel.path))
          vim.api.nvim_win_set_cursor(0, { sel.lnum, 0 })
          vim.cmd("normal! zz")
        end
      end)

      -- <C-d> → mark done, refresh in place
      map({ "i", "n" }, "<C-d>", function()
        local sel = action_state.get_selected_entry()
        if not sel then return end
        local e = sel.value
        if e.done then
          vim.notify("agenda: already done", vim.log.levels.INFO)
          return
        end
        local ok = mark_done(e.path, e.lnum)
        if ok then
          e.done = true
          e.cls  = "done"
          vim.notify("Done: " .. e.title, vim.log.levels.INFO)
          all_entries = collect_entries()
          local p = action_state.get_current_picker(prompt_bufnr)
          p:refresh(make_finder(all_entries), { reset_prompt = false })
          p.prompt_border:change_title(prompt_title())
        end
      end)

      -- <C-t> → toggle done visibility
      map({ "i", "n" }, "<C-t>", function()
        show_done = not show_done
        local p = action_state.get_current_picker(prompt_bufnr)
        p:refresh(make_finder(all_entries), { reset_prompt = false })
        p.prompt_border:change_title(prompt_title())
      end)

      return true
    end,
  }):find()
end

return M

