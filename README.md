# Net Speed

Download and upload speed in the menu bar (every 2 s), and a desktop card with the last two minutes as a small graph.
Click the bar item for each connection (Wi-Fi, Ethernet, VPN) and how much it has moved since the computer started.

- **Asks for:** `run` (Run commands as you): one command, `cat /proc/uptime /proc/net/dev`, the counters the kernel
  already keeps. Nothing is sent anywhere.
- **Counts** every real link; loopback and the virtual links of containers and virtual machines (`veth`, `docker`,
  `br-`, `virbr`, `podman`, ...) are left out, so traffic is not counted twice.
- **Files:** `plugin.toml`, `bar.lua` (menu bar), `card.lua` (desktop card, small or medium), `icon.png`, `preview.webp`.

## Install

From the Store: **Plugins**, then **Get** on Net Speed. From a release: `wol plugin add wonderlandos.netspeed-1.0.wolplug --yes` (a file the index did not sign is marked
unreviewed), then `wol plugin enable wonderlandos.netspeed`.

## Tests

`.tests/case-*.json` are runs of the scripts in the WolOS plugin runtime (wol-lua, the shell's sandbox and Lua API) with
fixture answers for `wol.run`: nothing on the machine runs. Each case lists the steps (render, popover, click, change,
query) and the text the result must and must not contain; the runner (`plugtest`, wol-lua with fixture services) is
not published yet. `wol plugin check` on a copy of the folder named after the id is the lint.

## Release

`.github/workflows/hub-release.yml` turns a pushed tag `v<plugin.toml version>` (`v1.0`) into a GitHub release with
`wonderlandos.netspeed-<version>.wolplug`, checked by the hub's own hubcheck first (wonderlandos/hub `wol-release.yml`, pinned).

Licence: GPL-2.0-or-later.
