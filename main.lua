--- @since 25.5.31

-- Default options
-- Can't reference Header.RIGHT etc. here (it hangs) so align is a string
-- 2000 puts it to the right of the indicator, and leaves some room between
local OPTION_POSITION = { parent = Header, align = "RIGHT", order = 2000 }

---Set new plugin state and redraw
local set_state = ya.sync(function(st, usage, source)
    st.usage = usage
    st.source = source

    -- Todo: Remove when ya.render is deprecated
    local render = ui.render or ya.render
    render()
end)

-- Called from init.lua 
---@param st State
---@param opts Options
local function setup(st, opts)
    -- Set default options first
    local position = OPTION_POSITION

    -- Set user options
    if opts then
        if opts.position then
            position.parent = opts.position.parent or position.parent
            position.order = opts.position.order or position.order

            if opts.position.align == "LEFT" or opts.position.align == "RIGHT" then
                position.align = opts.position.align
            end
        end
    end

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

    -- Add the entry to the header
    position.parent:children_add(function(self)
        return ui.Line {
            " ",
            ui.Span(st.source or ""),
            ": ",
            ui.Span(st.usage or ""),
            " "
        }
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
        local source, usage = output.stdout:match(".*%s(%S+)%s+(%S+)")
        set_state(usage, source)
    else
        set_state("", "")
    end
end

return { setup = setup, entry = entry }
