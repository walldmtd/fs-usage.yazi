--- @since 25.5.31

-- Default options
-- Can't reference Header.RIGHT etc. here (it hangs) so align is a string
-- 2000 puts it to the right of the indicator, and leaves some room between
local OPTION_POSITION = { parent = Header, align = "RIGHT", order = 2000 }
local OPTION_BAR = true
local OPTION_STYLE_LABEL = {} -- No bold here cause the bold in the Yazi default doesn't show
local OPTION_STYLE_NORMAL = { fg = "blue", bg = "black" }
local OPTION_STYLE_WARNING = { fg = "red", bg = "black" }

-- Merge and overwrite values from one table into another
---@param from Table to take values from
---@param to Table to merge into
local function merge(into, from)
    local result = {}

    if into then
        for k, v in pairs(into) do
            result[k] = v
        end
    end

    if from then
        for k, v in pairs(from) do
            result[k] = v
        end
    end
    return result
end

-- Merge label and bar styles into left/right styles for the bar
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

-- Set persistent options
local set_state_initial = ya.sync(function(st, bar)
    st.bar = bar
end)

---Set new plugin state and redraw
local set_state = ya.sync(function(st, source, usage)
    -- Todo: move like everything out of here, this function shouldn't do work

    -- Skip if nothing has changed
    if source == st.source and usage == st.usage then
        return
    end

    st.source = source
    st.usage = usage

    -- Todo: move to its own function
    if st.source and st.usage ~= nil then
        st.text = string.format(" %s: %d%% ", st.source, st.usage)
    elseif st.source then
        st.text = string.format(" %s ", st.source)
    elseif st.usage ~= nil then
        st.text = string.format(" %d%% ", st.usage)
    else
        st.text = ""
    end

    -- Don't bother calculating left/right text if bar is disabled
    -- Also don't bother if source or usage are empty/nil (bar won't be shown)
    if st.bar and st.source and st.usage ~= nil then
        -- Todo: maybe make this stuff its own function?

        -- Using ceil so the bar is only empty at 0%
        -- Using len - 1 so the bar isn't full until 100%
        local text_len = string.len(st.text)
        local bar_len = st.usage < 100 and math.ceil((text_len - 1) / 100 * st.usage)
                or text_len

        st.text_left = string.sub(st.text, 1, bar_len)
        st.text_right = string.sub(st.text, bar_len + 1, text_len)
    end

    -- Todo: Remove when ya.render is deprecated
    local render = ui.render or ya.render
    render()
end)

-- Called from init.lua 
---@param st State
---@param opts Options
local function setup(st, opts)
    -- Set default options first
    -- Todo: move to the options function
    local position = OPTION_POSITION
    local bar = OPTION_BAR
    -- Inherit from flavor if possible
    local style_label = merge(OPTION_STYLE_LABEL, th.status.progress_label)
    local style_normal = merge(OPTION_STYLE_NORMAL, th.status.progress_normal)
    local style_warning = merge(OPTION_STYLE_WARNING, th.status.progress_warning)

    -- Set user options
    -- Todo: move this to its own function (edit opts in-place to replace nil with defaults)
    if opts then
        position = merge(position, opts.position)

        if opts.bar ~= nil then bar = opts.bar end

        style_label = merge(style_label, opts.style_label)
        style_normal = merge(style_normal, opts.style_normal)
        style_warning = merge(style_normal, opts.style_normal)

        -- Allow unsetting label fg with ""
        if style_label.fg == "" then style_label.fg = nil end
    end

    -- Set persistent options
    set_state_initial(bar)

    ---Callback on cwd change to pass the new path to the plugin entry
    local function callback()
        local cwd = cx.active.current.cwd
        if st.cwd ~= cwd then
            st.cwd = cwd

            ya.emit("plugin", {
                st._id,
                ya.quote(tostring(cwd), true)
            })
        end
    end

    -- Subscribe to events
    ps.sub("cd", callback)
    ps.sub("tab", callback)
    -- Ideally this would subscribe to stuff like file moving/deleting,
    --  but the callback is triggered before the operation completes
    --  so the usage doesn't update properly
    --  (also file writing/copying doesn't have an event anyway so it would still get out of date)

    local style_left, style_right = build_styles(style_label, style_normal)

    position.parent:children_add(function(self)
        if st.usage == nil then
            -- No point showing anything if usage == nil
            return ui.Line("")
        elseif st.bar and st.source then
            -- Only show bar if source isn't empty (otherwise it's too short)
            return ui.Line {
                ui.Span(st.text_left or ""):style(style_left),
                ui.Span(st.text_right or ""):style(style_right)
            }
        else
            return ui.Line {
                ui.Span(st.text or ""):style(style_right)
            }
        end
    end, position.order, position.parent[position.align])
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
    
    if output.status.success then
        local source, usage = output.stdout:match(".*%s(%S+)%s+(%d+)%%")
        set_state(source, tonumber(usage))
    else
        set_state("", nil)
    end
end

return { setup = setup, entry = entry }
