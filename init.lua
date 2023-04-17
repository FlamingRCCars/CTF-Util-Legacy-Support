time_left = 0
timer = 0
modstorage = core.get_mod_storage()
d_c = modstorage:get_string("donate_counter")
s_o_c_u_u = modstorage:get_string("show_other_ctf_util_users")
c_m = modstorage:get_string("custom_message")
i_l = modstorage:get_string("ignore_list")

function format_time(seconds)
    local minutes = math.floor(seconds / 60)
    local remaining_seconds = seconds % 60
    return string.format("%02d:%02d", minutes, remaining_seconds)
end


function say(message)
    minetest.send_chat_message(message)
    if minetest.get_server_info().protocol_version < 29 then
        local name = minetest.localplayer:get_name()
        minetest.display_chat_message("<"..name.."> " .. message)
    end
end

function check_ignorelist(message)
    local ignorelist = (i_l):split(",")
    for i = 1, #ignorelist do
        search_string = "<" .. ignorelist[i] .. ">"
        if string.find(message, search_string) then
            return true
        end
    end
    return false
end

function donate_counter(dtime)
    local hudpos = {x = 0.9, y = 0.3}
    timer = timer + dtime
    if timer >= 1 then
        if time_left > 0 then
            time_left = time_left - 1
        end
        timer = timer - 1
    end
    if minetest.localplayer then
        formatted_time = format_time(time_left)
        
        if is_declared then
            minetest.localplayer:hud_change(donate_number, "text", formatted_time)
        else
            donate_text = minetest.localplayer:hud_add({hud_elem_type = "text", position = hudpos, offset = {x = 0, y = 0}, text = "Donate: ", alignment = {x = 1, y = 1}, scale = {x = 1, y = 1}, number = 0xFFFFFF})
            donate_number = minetest.localplayer:hud_add({hud_elem_type = "text", position = hudpos, offset = {x = 70, y = 0}, text = formatted_time, alignment = {x = 1, y = 1}, scale = {x = 1, y = 1}, number = 0xFFFFFF})
            is_declared = true
        end
    end
end

minetest.register_chatcommand("block", {
    params = "<player_name>",
    description = "Add players to your ignore list.",
    func = function(message)
        if message then
            local found_name = false
            local str = i_l
            local str_table = str:split(",")
            for i, name in ipairs(str_table) do
                if name == message then
                    found_name = true
                    break
                end
            end
            if found_name then
                print(message .. " is already ignored!")
                return
            end
            local temp_data = modstorage:get_string("ignore_list")
            local temp_data = temp_data .. "," .. message
            modstorage:set_string("ignore_list", temp_data)
            i_l = modstorage:get_string("ignore_list")
            print("Added " .. message .. " to your ignore list.")
            return
        end
        print("Please enter a name.")
    end
})

minetest.register_chatcommand("unblock", {
    params = "<player_name>",
    description = "Remove players from your ignore list.",
    func = function(message)
        if message then
            local found_name = false
            local str = i_l
            local str_table = str:split(",")
            for i, name in ipairs(str_table) do
                if name == message then
                    table.remove(str_table, i)
                    found_name = true
                    break
                end
            end
            if found_name then
                local new_str = table.concat(str_table, ",")
                modstorage:set_string("ignore_list", new_str)
                i_l = modstorage:get_string("ignore_list")
                print("Removed " .. message .. " from your ignore list.")
            else
                print(message .. " isn't ignored!")
            end
            return
        end
        print("Please enter a name.")
    end
})

minetest.register_chatcommand("list_blocked", {
    params = "",
    description = "List all blocked players.",
    func = function(message)
        local str = i_l
        local str_table = str:split(",")
        local output_string = ""
        for i, name in ipairs(str_table) do
            if output_string == "" then
                output_string = str_table[i]
            else
                output_string = output_string .. ", " .. str_table[i]
            end
        end
        print(output_string)
    end
})

minetest.register_chatcommand("toggle_donate_counter", {
    params = "",
    description = "Toggle the donate counter.",
    func = function(message)
        current = d_c
        if current == "true" then
            modstorage:set_string("donate_counter", "false")
            minetest.localplayer:hud_remove(donate_number)
            minetest.localplayer:hud_remove(donate_text)
            is_declared = false
        else
            modstorage:set_string("donate_counter", "true")
        end
        if current == "true" then
            msg = "disabled."
        else
            msg = "enabled."
        end
        print("The donate counter is now " .. msg)
        d_c = modstorage:get_string("donate_counter")
    end
})

minetest.register_chatcommand("toggle_show_ctf_util", {
    params = "",
    description = "Toggle showing other CTF util users",
    func = function(message)
        current = s_o_c_u_u
        if current == "true" then
            modstorage:set_string("show_other_ctf_util_users", "false")
        else
            modstorage:set_string("show_other_ctf_util_users", "true")
        end
        if current == "true" then
            msg = "Other players using CTF Util will no longer be highlighted."
        else
            msg = "Other players using CTF Util will now be highlighted."
        end
        print(msg)
        s_o_c_u_u = modstorage:get_string("show_other_ctf_util_users")
    end
})

minetest.register_chatcommand("set_message", {
    params = "",
    description = "Set the custom message shown next to other CTF_Util users",
    func = function(message)
        modstorage:set_string("custom_message", message)
        print("Players will now have " .. message .. " added to the beginning of their name.")
        c_m = modstorage:get_string("custom_message")
    end
})

minetest.register_on_sending_chat_message(function(message)
    if string.sub(message, 1, 1) == "/" then
        return false
    else
        say(message .. string.char(127))
        return true
    end
end)

minetest.register_on_receiving_chat_message(function(message)
    if minetest.localplayer then
        local player_name = minetest.localplayer:get_name()
        local search_string = player_name .. " donated"
        local handled = check_ignorelist(message)
        if string.find(message, search_string) then
            time_left = 600
        end
        if handled == false then
            if s_o_c_u_u == "true" then
                if string.find(message, string.char(127)) then
                    custom = d_c
                    print(minetest.colorize("#FF5000", custom .. " ") .. message)
                    return true
                end
            end
        end
        
        return(handled)
    end
end)

minetest.register_on_mods_loaded(function()
    if modstorage:get_string("donate_counter") ~= "true" and modstorage:get_string("donate_counter") ~= "false" then
        modstorage:set_string("donate_counter", "true")
    end
    if modstorage:get_string("show_other_ctf_util_users") ~= "true" and modstorage:get_string("show_other_ctf_util_users") ~= "false" then
        modstorage:set_string("show_other_ctf_util_users", "true")
    end
    if modstorage:get_string("custom_message") == "" then
        modstorage:set_string("custom_message", "CTF_Util")
    end
    if modstorage:get_string("initialized") ~= "true" then
        modstorage:set_string("initialized", "true")
        modstorage:set_string("custom_message", "CTF_Util")
    end

    d_c = modstorage:get_string("donate_counter")
    s_o_c_u_u = modstorage:get_string("show_other_ctf_util_users")
    c_m = modstorage:get_string("custom_message")
    i_l = modstorage:get_string("ignore_list")

    minetest.after(2, function()
        print(minetest.colorize("#00FFFF", "The available commands are: .help all .set_message .block, .unblock .toggle_donate_counter .toggle_show_ctf_util .list_blocked"))
    end)
end)

minetest.register_globalstep(function(dtime)
    if d_c == "true" then
        donate_counter(dtime)
    end
end)