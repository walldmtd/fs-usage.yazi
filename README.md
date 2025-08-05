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

To use the default setup, add this somewhere in `~/.config/yazi/init.lua`:

```lua
require("fs-usage"):setup()
```

To customize it, add this instead and adjust the options as needed:

```lua
require("fs-usage"):setup({
    -- All values are optional

    -- Position of the component
    --  parent
    --      Parent component
    --      One of: Header | Status
    --      Default: Header
    --  align
    --      Anchor point within parent object
    --      One of: "LEFT" | "RIGHT"
    --      Default: "RIGHT"
    --  order
    --      Component order relative to others in the same parent
    --      Default: 2000
    position = { parent = Header, align = "RIGHT", order = 2000 },

    -- Option to enable or disable the usage bar
    -- Default: true
    bar = true
})
```

> [!NOTE]
> The text only updates when changing directories or tabs in Yazi. When files are moved/deleted/modified, the new partition usage won't be shown until you change directories or switch tabs.

## Todo

- [x] Usage bar + option to disable
- [ ] Colour + option to disable
- [ ] Options for colour thresholds
- [ ] Option to remove partition name or percentage
- [x] Option to change module location (header/footer), and set position in order
