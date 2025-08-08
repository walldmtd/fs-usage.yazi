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

To customize it, add this instead and adjust/remove the options as needed:

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

    -- Label text style
    -- Unset options use the progress bar style from the Yazi flavor if available,
    -- otherwise falls back to the default style
    --  fg
    --      Text colour
    --      Can be a terminal colour string (e.g. "white"),
    --          or a hex colour (e.g. "#ffffff"),
    --          or it can be "" to use the reverse of the bar colour
    --      Default: (unset, inherits from Yazi)
    --  bold
    --      One of: true | false
    --      Default: (unset, inherits from Yazi)
    --  italic
    --      One of: true | false
    --      Default: (unset, inherits from Yazi)
    -- Example: style_label = { fg = "white", bold = true, italic = false },
    style_label = {},

    -- Usage bar style
    -- Unset options use the progress bar style from the Yazi flavor if available,
    -- otherwise falls back to the default style
    --  fg
    --      Bar color
    --      Can be a terminal colour string (e.g. "blue"),
    --          or a hex colour (e.g. "#0000ff")
    --      Default (unset, inherits from Yazi)
    --  bg
    --      Bar background color
    --      Can be a terminal colour string (e.g. "black"),
    --          or a hex colour (e.g. "#000000")
    --      Default (unset, inherits from Yazi)
    -- Example: style_normal = { fg = "blue", bg = "black" },
    style_normal = {},

    -- Usage bar style when the used space is above the warning threshold
    -- Unset options use the progress bar error style from the Yazi flavor if available,
    -- otherwise falls back to the default style
    -- Options are the same as style_normal
    -- Example: style_warning = { fg = "red", bg = "black" },
    style_warning = {},
})
```

> [!NOTE]
> The text only updates when changing directories or tabs in Yazi. When files are moved/deleted/modified, the new partition usage won't be shown until you change directories or switch tabs.

## Todo

- [x] Usage bar + option to disable
- [x] Style options
- [ ] Options for colour thresholds
- [ ] Option to remove partition name or percentage
- [x] Option to change module location (header/footer), and set position in order
