-- SPDX-License-Identifier: GPL-2.0-or-later
-- Menu bar item: "↓ 1.2 MB/s  ↑ 36 kB/s", every 2 s. The popover lists each connection with what
-- it has moved since the computer started.
-- One command, two files: the clock (/proc/uptime, seconds since boot) and the counters
-- (/proc/net/dev). Taking both at once gives the exact interval between two samples, also when the
-- shell hands back an answer that is a little older than this render.
local SKIP = { "lo", "veth", "docker", "br-", "virbr", "vnet", "podman", "cni", "flannel", "tap" }

local function counted(name)
  for _, p in ipairs(SKIP) do
    if name:sub(1, #p) == p then return false end
  end
  return true
end

-- Parses the command's output: uptime, then { name = { rx = bytes, tx = bytes } } of counted links.
local function parse(out)
  local up = tonumber(out:match("^%s*([%d%.]+)"))
  if not up then return nil end
  local links = {}
  for line in out:gmatch("[^\n]+") do
    local name, rest = line:match("^%s*([^%s:]+):%s*(.*)$")
    if name and counted(name) then
      local f = {}
      for n in rest:gmatch("%d+") do f[#f + 1] = tonumber(n) end
      if #f >= 9 then links[name] = { rx = f[1], tx = f[9] } end
    end
  end
  return up, links
end

local s = { up = nil, rx = nil, tx = nil, down_rate = nil, up_rate = nil, links = {}, err = nil }

local function sample()
  local ok, out = wol.run { "cat", "/proc/uptime", "/proc/net/dev", timeout = 2 }
  if not ok then s.err = out; return end
  local up, links = parse(out)
  if not up then s.err = "No network counters on this computer."; return end
  s.err = nil
  local rx, tx = 0, 0
  for _, l in pairs(links) do rx = rx + l.rx; tx = tx + l.tx end
  if s.up and up > s.up then
    local dt = up - s.up
    -- A counter that went down is a link that came and went: no rate for this step.
    if rx >= s.rx and tx >= s.tx then
      s.down_rate = (rx - s.rx) / dt
      s.up_rate = (tx - s.tx) / dt
    end
  end
  if not s.up or up > s.up then s.up, s.rx, s.tx, s.links = up, rx, tx, links end
  return true
end

-- 1234567 -> "1.2 MB/s": decimal units, as network speeds are given.
local function speed(b)
  if not b then return "-" end
  if b < 1000 then return string.format("%d B/s", math.floor(b + 0.5)) end
  if b < 1e6 then return string.format("%.0f kB/s", b / 1e3) end
  if b < 1e9 then return string.format("%.1f MB/s", b / 1e6) end
  return string.format("%.2f GB/s", b / 1e9)
end

local function amount(b)
  if b < 1e6 then return string.format("%.0f kB", b / 1e3) end
  if b < 1e9 then return string.format("%.1f MB", b / 1e6) end
  return string.format("%.2f GB", b / 1e9)
end

local function kind(name)
  if name:match("^wl") or name:match("^wlan") then return "Wi-Fi", "network-wireless-symbolic" end
  if name:match("^en") or name:match("^eth") then return "Ethernet", "network-wired-symbolic" end
  if name:match("^wg") or name:match("^tun") or name:match("^tailscale") then return "VPN", "network-vpn-symbolic" end
  if name:match("^ww") or name:match("^usb") then return "Mobile", "network-cellular-symbolic" end
  return "Network", "network-transmit-receive-symbolic"
end

return wol.menubar {
  refresh = 2,
  render = function()
    sample()
    if s.err then return wol.label { "Net: -" } end
    return wol.row { spacing = 8,
      wol.label { "↓ " .. speed(s.down_rate) },
      wol.label { "↑ " .. speed(s.up_rate) },
    }
  end,
  popover = function()
    if s.err then
      return wol.stack { spacing = 8,
        wol.label { "Net Speed", role = "title" },
        wol.label { s.err, role = "secondary" },
      }
    end
    local names = {}
    for n in pairs(s.links) do names[#names + 1] = n end
    table.sort(names)
    local rows = {}
    for _, n in ipairs(names) do
      local l = s.links[n]
      local what, icon = kind(n)
      rows[#rows + 1] = wol.item { title = what .. " (" .. n .. ")",
        subtitle = "↓ " .. amount(l.rx) .. "  ↑ " .. amount(l.tx) .. " since start", icon = icon }
    end
    if #rows == 0 then
      rows[1] = wol.item { title = "No connection", subtitle = "Nothing is connected right now.",
        icon = "network-offline-symbolic" }
    end
    return wol.stack { spacing = 8,
      wol.label { "Net Speed", role = "title" },
      wol.label { "Download " .. speed(s.down_rate) .. ", upload " .. speed(s.up_rate), role = "secondary" },
      wol.list(rows),
    }
  end,
}
