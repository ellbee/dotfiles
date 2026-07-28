-- ~/.config/nvim/lua/timestamp.lua
-- Toggle the thing under the cursor between a unix timestamp and an ISO 8601
-- UTC datetime.
--
--   1767225600            ->  2026-01-01T00:00:00Z
--   1767225600123         ->  2026-01-01T00:00:00.123Z   (13 digits = millis)
--   2026-01-01T00:00:00Z  ->  1767225600
--
-- Round-tripping is lossless: a value that came in as milliseconds goes back
-- out as milliseconds, and fractional seconds survive the trip.

local M = {}

-- Unix seconds -> UTC calendar fields. Done by hand rather than with
-- os.date("!*t") so this stays correct for pre-1970 (negative) timestamps,
-- which os.date rejects on some platforms.
local function civil_from_days(z)
  z = z + 719468
  local era = math.floor(z / 146097)
  local doe = z - era * 146097                                  -- [0, 146096]
  local yoe = math.floor((doe - math.floor(doe / 1460)
    + math.floor(doe / 36524) - math.floor(doe / 146096)) / 365) -- [0, 399]
  local y = yoe + era * 400
  local doy = doe - (365 * yoe + math.floor(yoe / 4) - math.floor(yoe / 100))
  local mp = math.floor((5 * doy + 2) / 153)                    -- [0, 11]
  local d = doy - math.floor((153 * mp + 2) / 5) + 1            -- [1, 31]
  local m = mp < 10 and mp + 3 or mp - 9                        -- [1, 12]
  return (m <= 2 and y + 1 or y), m, d
end

-- Inverse of civil_from_days: UTC calendar fields -> days since epoch.
local function days_from_civil(y, m, d)
  y = m <= 2 and y - 1 or y
  local era = math.floor(y / 400)
  local yoe = y - era * 400
  local mp = m > 2 and m - 3 or m + 9
  local doy = math.floor((153 * mp + 2) / 5) + d - 1
  local doe = yoe * 365 + math.floor(yoe / 4) - math.floor(yoe / 100) + doy
  return era * 146097 + doe - 719468
end

-- secs may be fractional; frac_digits controls the ".mmm" suffix (0 = none).
local function to_iso(secs, frac_digits)
  local whole = math.floor(secs)
  local days = math.floor(whole / 86400)
  local rem = whole - days * 86400
  local y, mo, d = civil_from_days(days)

  local iso = string.format("%04d-%02d-%02dT%02d:%02d:%02dZ",
    y, mo, d,
    math.floor(rem / 3600),
    math.floor(rem % 3600 / 60),
    rem % 60)

  if frac_digits and frac_digits > 0 then
    local frac = secs - whole
    -- Insert the fraction ahead of the trailing "Z".
    local digits = string.format("%." .. frac_digits .. "f", frac):sub(3)
    iso = iso:sub(1, -2) .. "." .. digits .. "Z"
  end

  return iso
end

-- Accepts "2026-01-01T00:00:00Z" and the common relaxations of it: a space
-- instead of "T", a missing "Z", fractional seconds, or a numeric ±HH:MM
-- offset. Returns fractional unix seconds, or nil if it isn't a datetime.
local function from_iso(s)
  local y, mo, d, rest = s:match("^(%d%d%d%d)%-(%d%d)%-(%d%d)[Tt ](.+)$")
  if not y then return nil end

  local hh, mi, ss, tail = rest:match("^(%d%d):(%d%d):(%d%d)(.*)$")
  if not hh then
    -- Seconds are optional: "2026-01-01T00:00Z".
    hh, mi, tail = rest:match("^(%d%d):(%d%d)(.*)$")
    if not hh then return nil end
    ss = "0"
  end

  local frac = 0
  local f, after = tail:match("^%.(%d+)(.*)$")
  if f then
    frac = tonumber("0." .. f)
    tail = after
  end

  -- Timezone: "Z", empty (assume UTC), or an explicit offset.
  local offset = 0
  if tail ~= "" and tail ~= "Z" and tail ~= "z" then
    local sign, oh, om = tail:match("^([+%-])(%d%d):?(%d%d)$")
    if not sign then return nil end
    offset = (tonumber(oh) * 3600 + tonumber(om) * 60) * (sign == "-" and -1 or 1)
  end

  local secs = days_from_civil(tonumber(y), tonumber(mo), tonumber(d)) * 86400
    + tonumber(hh) * 3600
    + tonumber(mi) * 60
    + tonumber(ss)
    + frac
    - offset

  return secs
end

-- Patterns for the values we recognise, longest/most specific first so that an
-- ISO datetime wins over the bare year at its start. Anchored scanning (rather
-- than expanding outwards from the cursor) keeps surrounding punctuation like
-- a JSON `": "` or a trailing `--` comment out of the match.
local PATTERNS = {
  "%d%d%d%d%-%d%d%-%d%d[Tt ]%d%d:%d%d:%d%d%.%d+[+%-]%d%d:?%d%d", -- frac + offset
  "%d%d%d%d%-%d%d%-%d%d[Tt ]%d%d:%d%d:%d%d[+%-]%d%d:?%d%d",      -- offset
  "%d%d%d%d%-%d%d%-%d%d[Tt ]%d%d:%d%d:%d%d%.%d+[Zz]?",           -- frac
  "%d%d%d%d%-%d%d%-%d%d[Tt ]%d%d:%d%d:%d%d[Zz]?",
  "%d%d%d%d%-%d%d%-%d%d[Tt ]%d%d:%d%d[Zz]?",
  "%d+",                                                          -- bare number
}

-- Find the value under the cursor: the first pattern with a match whose byte
-- range covers the cursor. Returns text, start, end (1-indexed, inclusive).
local function token_under_cursor()
  local line = vim.api.nvim_get_current_line()
  local col = vim.api.nvim_win_get_cursor(0)[2] + 1 -- 1-indexed byte position

  for _, pat in ipairs(PATTERNS) do
    local init = 1
    while true do
      local s, e = line:find(pat, init)
      if not s then break end
      if col >= s and col <= e then
        -- A bare number directly preceded by "-" is a negative timestamp.
        if pat == "%d+" and s > 1 and line:sub(s - 1, s - 1) == "-" then
          s = s - 1
        end
        return line:sub(s, e), s, e, line
      end
      init = e + 1
    end
  end

  return nil
end

local function replace_range(line, s, e, replacement)
  local lnum = vim.api.nvim_win_get_cursor(0)[1]
  local updated = line:sub(1, s - 1) .. replacement .. line:sub(e + 1)
  vim.api.nvim_buf_set_lines(0, lnum - 1, lnum, false, { updated })
  -- Leave the cursor on the start of what we just wrote.
  vim.api.nvim_win_set_cursor(0, { lnum, s - 1 })
end

--- Toggle the timestamp or ISO datetime under the cursor.
function M.toggle()
  local token, s, e, line = token_under_cursor()
  if not token then
    vim.notify("timestamp: nothing under the cursor", vim.log.levels.WARN)
    return
  end

  -- ISO -> unix. Try this first: an ISO string also contains digits, so
  -- testing for a bare number first would misread the leading year.
  local secs = from_iso(token)
  if secs then
    local out
    if secs % 1 == 0 then
      out = string.format("%d", secs)
    else
      -- Fractional input round-trips as milliseconds.
      out = string.format("%d", math.floor(secs * 1000 + 0.5))
    end
    replace_range(line, s, e, out)
    return
  end

  -- Unix -> ISO. Unit is inferred from magnitude, which is unambiguous for
  -- any date this side of 1970: seconds top out at 10 digits until 2286.
  local num = token:match("^%-?%d+$")
  if num then
    local n = tonumber(num)
    local digits = #(num:match("%d+"))
    local out
    if digits >= 16 then       -- microseconds
      out = to_iso(n / 1000000, 6)
    elseif digits >= 12 then   -- milliseconds
      out = to_iso(n / 1000, 3)
    else                       -- seconds
      out = to_iso(n, 0)
    end
    replace_range(line, s, e, out)
    return
  end

  vim.notify("timestamp: not a unix timestamp or ISO datetime: " .. token,
    vim.log.levels.WARN)
end

return M
