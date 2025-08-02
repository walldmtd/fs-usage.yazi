# fs-usage.yazi

A [Yazi](https://github.com/sxyazi/yazi) plugin to show the used space in the current partition using `df`.

## Installation

> [!IMPORTANT]
> - This plugin is only supported on Linux
>   - It *might* work with WSL, but that is untested
> - Requires Yazi v25.5.31 or later

Install with `ya`:

```sh
ya pkg add walldmtd/fs-usage
```

## Usage

Add this somewhere in `~/.config/yazi/init.lua`, and adjust options as needed:

```lua
require("fs-usage"):setup({
    -- All values are optional
    -- WIP
})
```

> [!NOTE]
> The text only updates when changing directories or tabs in Yazi. When files are moved/deleted/modified, the new partition usage won't be shown until you change directories or switch tabs.

## Todo

- [ ] Usage bar + option to disable
- [ ] Colour + option to disable
- [ ] Options for colour thresholds
- [ ] Option to remove partition name or percentage
- [ ] Option to change module location (header/footer), and set position in order
