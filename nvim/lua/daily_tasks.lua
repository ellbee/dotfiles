local M = {}

-- Keep the heading hierarchy for each open task, without copying unrelated text.
function M.extract(lines)
  local result = {}
  local headings = {}
  local emitted = {}
  local count = 0

  for line_number, line in ipairs(lines) do
    local hashes = line:match("^(#+)%s+%S")
    if hashes and #hashes <= 6 then
      for level = #hashes, 6 do
        headings[level] = nil
      end
      headings[#hashes] = { line = line, number = line_number }
    elseif line:match("^%s*[-*+] %[[ >]%]%s+") then
      local common = 0
      for level = 1, 6 do
        if headings[level] and emitted[level] == headings[level].number then
          common = level
        elseif headings[level] then
          break
        end
      end

      local added_heading = false
      for level = 1, 6 do
        if headings[level] and level > common then
          if #result > 0 and result[#result] ~= "" then
            result[#result + 1] = ""
          end
          result[#result + 1] = headings[level].line
          emitted[level] = headings[level].number
          added_heading = true
        elseif not headings[level] then
          emitted[level] = nil
        end
      end

      if added_heading then
        result[#result + 1] = ""
      end
      result[#result + 1] = line
      count = count + 1
    end
  end

  return result, count
end

local function source_timestamp(input)
  if input == "" then
    local yesterday = os.date("*t")
    yesterday.day = yesterday.day - 1
    yesterday.hour = 12
    return os.time(yesterday)
  end

  local offset = tonumber(input)
  if offset and offset == math.floor(offset) then
    local day = os.date("*t")
    day.day = day.day + offset
    day.hour = 12
    return os.time(day)
  end

  local date = require("obsidian.date")
  local parsed = date.parse(input, Obsidian.opts.daily_notes.date_format)
  if not parsed then
    local first = tonumber(input:match("^(%d+)/"))
    if first and first > 12 then
      parsed = date.parse(input, input:match("^%d+/%d+/%d%d%d%d$") and "D/M/YYYY" or "D/M")
    end
  end
  parsed = parsed or date.parse(input)
  if parsed then
    return os.time(parsed)
  end
end

local function read_lines(path)
  local bufnr = vim.fn.bufnr(path)
  if bufnr ~= -1 and vim.api.nvim_buf_is_loaded(bufnr) then
    return vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
  end
  return vim.fn.readfile(path)
end

function M.copy(input)
  input = vim.trim(input or "")
  local timestamp = source_timestamp(input)
  if not timestamp then
    vim.notify("Invalid date: " .. input, vim.log.levels.ERROR)
    return
  end

  local daily = require("obsidian.daily")
  local source_path = tostring(daily.daily_note_path(timestamp))
  local today = daily.today()
  local destination_path = tostring(today.path)

  if source_path == destination_path then
    vim.notify("Source is today's daily note", vim.log.levels.WARN)
    return
  end
  if vim.fn.filereadable(source_path) == 0 then
    vim.notify("Daily note does not exist: " .. source_path, vim.log.levels.WARN)
    return
  end

  local lines, count = M.extract(read_lines(source_path))
  if count == 0 then
    vim.notify("No open tasks in " .. source_path, vim.log.levels.INFO)
    return
  end

  if not today:exists() then
    today:write()
  end
  today:open({
    sync = true,
    callback = function(bufnr)
      local existing = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
      if existing[#existing] ~= "" then
        table.insert(lines, 1, "")
      end
      vim.api.nvim_buf_set_lines(bufnr, -1, -1, false, lines)
      vim.api.nvim_buf_call(bufnr, function()
        vim.cmd.write()
      end)
      vim.notify(string.format("Copied %d open task%s into today's daily note", count, count == 1 and "" or "s"))
    end,
  })
end

return M
