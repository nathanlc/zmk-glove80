local word_maps = {
	{"about ", "abou"},
	{"above ", "abov"},
	{"add ", "ad"},
	{"after ", "af"},
	{"again ", "agin"},
	{"all ", "al"},
	{"an ", "an"},
	{"and ", "and"},
	{"as ", "as"},
	{"at ", "at"},
	{"be ", "be"},
	{"because ", "bc"},
	{"for ", "for"},
	{"have ", "hav"},
	{"he ", "he"},
	{"if ", "if"},
	{"in ", "in"},
	{"is ", "is"},
	{"it ", "it"},
	{"me ", "me"},
	{"not ", "not"},
	{"of ", "of"},
	{"on ", "on"},
	{"or ", "or"},
	{"something ", "sth"},
	{"that ", "tha"},
	{"the ", "te"},
	{"there ", "thr"},
	{"this ", "this"},
	{"to ", "to"},
	{"what ", "wht"},
	{"who ", "who"},
	{"with ", "with"},
	{"without ", "witho"},
	{"yes ", "yes"},
}

local char_pos_map = {
	["T"] = "POS_LH_C1R3",
	["G"] = "POS_LH_C1R4",
	["B"] = "POS_LH_C1R5",
	["R"] = "POS_LH_C2R3",
	["F"] = "POS_LH_C2R4",
	["V"] = "POS_LH_C2R5",
	["E"] = "POS_LH_C3R3",
	["D"] = "POS_LH_C3R4",
	["C"] = "POS_LH_C3R5",
	["Z"] = "POS_LH_C4R3",
	["S"] = "POS_LH_C4R4",
	["X"] = "POS_LH_C4R5",
	["A"] = "POS_LH_C5R3",
	["Q"] = "POS_LH_C5R4",
	["W"] = "POS_LH_C5R5",
	["Y"] = "POS_RH_C1R3",
	["H"] = "POS_RH_C1R4",
	["N"] = "POS_RH_C1R5",
	["U"] = "POS_RH_C2R3",
	["J"] = "POS_RH_C2R4",
	-- [""] = "POS_RH_C2R5",
	["I"] = "POS_RH_C3R3",
	["K"] = "POS_RH_C3R4",
	-- [""] = "POS_RH_C3R5",
	["O"] = "POS_RH_C4R3",
	["L"] = "POS_RH_C4R4",
	-- [""] = "POS_RH_C4R5",
	["P"] = "POS_RH_C5R3",
	["M"] = "POS_RH_C5R4",
	-- [""] = "POS_RH_C5R5",
}

local default_layout = 0

local macro_tmpl = [[
        m_%s: m_%s {
            compatible = "zmk,behavior-macro";
            #binding-cells = <0>;
            wait-ms = <4>;
            bindings = <&macro_tap%s>;
        };
]]

local combo_tmpl = [[
        combo_%s {
            timeout-ms = <50>;
            key-positions = <%s>;
            bindings = <&m_%s>;
            layers = <%d>;
        };
]]


--- @param s string
--- @return string
local function trim(s)
	return (s:gsub("^%s*(.-)%s*$", "%1"))
end

--- @param chars string
--- @return string
local function chars_to_bindings(chars)
	local bindings = ""
	for i = 1, #chars do
		local char = chars:sub(i, i)
		local converted_char = char
		if char == "Q" then
			converted_char = "A"
		end
		if char == "A" then
			converted_char = "Q"
		end
		if char == "Z" then
			converted_char = "W"
		end
		if char == "W" then
			converted_char = "Z"
		end
		if char == "M" then
			converted_char = "SEMI"
		end
		if char == " " then
			converted_char = "SPACE"
		end
		bindings = bindings .. " &kp " .. converted_char
	end
	return bindings
end

local function chars_to_positions(chars)
	local positions = ""
	for i = 1, #chars do
		local char = chars:sub(i, i)
		local upper_char = string.upper(char)
		local pos = char_pos_map[upper_char]
		if positions == "" then
			positions = pos
		else
			positions = positions .. " " .. pos
		end
	end
	return positions
end

--- @param key string
--- @return string
local function word_to_macro(key)
	local trimmed_key = trim(key)
	local upper_key = string.upper(key)
	return macro_tmpl:format(trimmed_key, trimmed_key, chars_to_bindings(upper_key))
end

--- @param key string
--- @param value string
--- @return string
local function word_to_combo(key, value )
	local trimmed_key = trim(key)
	return combo_tmpl:format(trimmed_key, chars_to_positions(value), trimmed_key, default_layout)
end

--- @return table, table
local function generate_macros_and_combos()
	local macros = {}
	local combos = {}
	for _, word in ipairs(word_maps) do
		local key = word[1]
		local value = word[2]
		table.insert(macros, word_to_macro(key))
		table.insert(combos, word_to_combo(key, value))
	end
	return macros, combos
end

--- @return table, table
local function generate_macro_and_combo_lines()
	local macros, combos = generate_macros_and_combos()
	local macros_str = table.concat(macros, "\n")
	local combos_str = table.concat(combos, "\n")
	local macro_lines = vim.split(macros_str, "\n")
	local combo_lines = vim.split(combos_str, "\n")
	return macro_lines, combo_lines
end

--- @param file_path string
--- @return table
local function read_file_lines(file_path)
	local lines = {}
	local file = io.open(file_path, "r")
	assert(file, "Could not open file: " .. file_path)

	for line in file:lines() do
		table.insert(lines, line)
	end
	file:close()

	return lines
end

--- @param file_path string
--- @param lines table
--- @return boolean
local function write_file_lines(file_path, lines)
	local file = io.open(file_path, "w")
	assert(file, "Could not open file: " .. file_path)

	for _, line in ipairs(lines) do
		file:write(line .. "\n")
	end
	file:close()

	return true
end

--- @return table
local function generate_keymap_with_chords()
	local macro_lines, combo_lines = generate_macro_and_combo_lines()

	local is_before_macros = true
	local is_after_macros = false
	local is_before_combos = true
	local is_after_combos = false
	local final_lines = {}
	local keymap_lines = read_file_lines("./config/glove80.keymap")
	for _, line in ipairs(keymap_lines) do
		if is_before_macros or (is_after_macros and is_before_combos) or is_after_combos then
			table.insert(final_lines, line)
		end

		if string.find(line, "MACRO CHORDS START") then
			is_before_macros = false
			for _, macro_line in ipairs(macro_lines) do
				table.insert(final_lines, macro_line)
			end
		end
		if string.find(line, "MACRO CHORDS END") then
			is_after_macros = true
			table.insert(final_lines, line)
		end

		if string.find(line, "COMBO CHORDS START") then
			is_before_combos = false
			for _, combo_line in ipairs(combo_lines) do
				table.insert(final_lines, combo_line)
			end
		end
		if string.find(line, "COMBO CHORDS END") then
			is_after_combos = true
			table.insert(final_lines, line)
		end
	end

	return final_lines
end

--- @param lines table
local function lines_in_split(lines)
	vim.cmd("vsplit")
    local buf = vim.api.nvim_create_buf(false, true)
    vim.api.nvim_win_set_buf(0, buf)
	vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
end

local function generate_keymap()
	local keymap_with_chords_lines = generate_keymap_with_chords()

	lines_in_split(keymap_with_chords_lines)
end

generate_keymap()
