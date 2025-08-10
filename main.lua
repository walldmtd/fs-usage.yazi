--- @since 25.5.31

local DEFAULT_OPTIONS = {
    -- Can't reference Header.RIGHT etc. here (it hangs) so parent and align are strings
    -- 2000 puts it to the right of the indicator, and leaves some room between
    position = { parent = "Header", align = "RIGHT", order = 2000 },
    format = "both",
    bar = true,
    warning_threshold = 90,
    style_label = th.status.progress_label,
    style_normal = th.status.progress_normal,
    style_warning = th.status.progress_error
}

---Deep copy and merge two tables, overwriting values from one table into another
---@param from Table to take values from
---@param to Table to merge into
local function merge(into, from)
    -- Handle nil inputs
    into = into or {}
    from = from or {}

    local result = {}

    -- Deep copy 'into' first
    for k, v in pairs(into) do
        if type(v) == "table" then
            result[k] = merge({}, v)
        else
            result[k] = v
        end
    end

    -- Merge
    for k, v in pairs(from) do
        if type(v) == "table" then
            result[k] = merge(result[k], v)
        else
            result[k] = v
        end
    end

    return result
end

---Merge label and bar styles into left/right styles for the bar
---@param style_label Label style
---@param style_bar Usage bar style
local function build_styles(style_label, style_bar)
    local style_right = ui.Style()
            :fg(style_label.fg or style_bar.fg)
            :bg(style_bar.bg) -- Label bg is ignored
    if style_label.bold then style_right = style_right:bold() end
    if style_label.italic then style_right = style_right:italic() end
    
    -- Left style is the same as right, but with fg/bg reversed
    --  (this is overridden by the label colour if set)
    local style_left = ui.Style()
            :patch(style_right)
            :fg(style_label.fg or style_bar.bg)
            :bg(style_bar.fg) -- Label bg is ignored

    return style_left, style_right
end

---Format text based on options
---@param source Source
---@param usage Usage
---@param format Format
local function format_text(source, usage, format)
    local text = ""
    if format == "both" then
        text = string.format(" %s: %d%% ", source, usage)
    elseif format == "name" then
        text = string.format(" %s ", source)
    elseif format == "usage" then
        text = string.format(" %d%% ", usage)
    end
    return text
end

---Set new plugin state and redraw
local set_state = ya.sync(function(st, source, usage, text_left, text_right)
    st.source = source
    st.usage = usage
    st.text_left = text_left
    st.text_right = text_right

    -- Todo: Remove when ya.render is deprecated
    local render = ui.render or ya.render
    render()
end)

---Get plugin state needed by entry
local get_state = ya.sync(function(st)
    return {
        -- Persistent options
        format = st.format,
        bar = st.bar,

        -- Variables
        source = st.source,
        usage = st.usage
    }
end)

-- Called from init.lua 
---@param st State
---@param opts Options
local function setup(st, opts)
    opts = merge(DEFAULT_OPTIONS, opts)

    -- Allow unsetting some options
    if opts.style_label.fg == "" then opts.style_label.fg = nil end
    if opts.warning_threshold < 0 then opts.warning_threshold = nil end

    -- Translate opts.position.parent option into a component reference
    if opts.position.parent == "Header" then
        opts.position.parent = Header
    elseif opts.position.parent == "Status" then
        opts.position.parent = Status
    else
        -- Just set it to nil, it's gonna cause errors anyway
        opts.position.parent = nil
    end

    -- Set persistent options
    st.format = opts.format
    st.bar = opts.bar
    st.warning_threshold = opts.warning_threshold

    -- Build styles from options
    local style_normal_left, style_normal_right = build_styles(opts.style_label, opts.style_normal)
    local style_warning_left, style_warning_right = build_styles(opts.style_label, opts.style_warning)

    -- Add the component to the parent
    opts.position.parent:children_add(function(self)
        -- No point showing anything if usage is nil
        if not st.usage then
            return
        end

        if not st.warning_threshold or st.usage < st.warning_threshold then
            return ui.Line {
                ui.Span(st.text_left or ""):style(style_normal_left),
                ui.Span(st.text_right or ""):style(style_normal_right)
            }
        else
            return ui.Line {
                ui.Span(st.text_left or ""):style(style_warning_left),
                ui.Span(st.text_right or ""):style(style_warning_right)
            }
        end
    end, opts.position.order, opts.position.parent[opts.position.align])

    ---Pass cwd to the plugin for df
    local function callback()
        ya.emit("plugin", {
            st._id,
            ya.quote(tostring(cx.active.current.cwd), true)
        })
    end

    -- Subscribe to events
    ps.sub("cd", callback)
    ps.sub("tab", callback)
    ps.sub("delete", callback)
    -- These are the only relevant events that actually work
    -- Note: df might not immediately reflect usage changes
    --  when deleting files
end


-- Called from ya.emit in the callback
---@param job Job
local function entry(_, job)
    local cwd = job.args[1]

    -- Don't set cwd directly for Command() here, it hangs for dirs without read perms
    -- cwd is fine as an argument to df though
    local output = Command("df")
        :arg({ "--output=source,pcent", tostring(cwd) })
        :output()

    -- If df fails, hide the module
    if not output.status.success then
        set_state("", nil, "", "")
        return
    end

    -- Process df output
    local source, usage = output.stdout:match(".*%s(%S+)%s+(%d+)%%")
    usage = tonumber(usage)

    -- Get the plugin state here since now we know it's needed
    local st = get_state()

    -- If nothing has changed, don't bother updating
    if source == st.source and usage == st.usage then
        return
    end

    -- Start with text_right by default (used when no bar)
    local text_left = ""
    local text_right = format_text(source, usage, st.format)

    -- Only calculate bar length if the bar will be shown
    if st.bar then
        -- Using ceil so the bar is only empty at 0%
        -- Using len - 1 so the bar isn't full until 100%
        local text_len = string.len(text_right)
        local bar_len = usage < 100 and math.ceil((text_len - 1) / 100 * usage)
                or text_len

        text_left = string.sub(text_right, 1, bar_len)
        text_right = string.sub(text_right, bar_len + 1, text_len)
    end

    set_state(source, usage, text_left, text_right)
end

return { setup = setup, entry = entry }
