local word_maps = {
	{"because ", "bc"},
	{"there ", "thr"},
	{"the ", "te"},
	{"be ", "be"},
	{"to ", "to"},
	{"of ", "of"},
	{"and ", "and"},
	{"in ", "in"},
	{"is ", "is"},
	{"that ", "tha"},
	{"this ", "this"},
	{"have ", "hav"},
	{"it ", "it"},
	{"for ", "for"},
	{"not ", "not"},
	{"on ", "on"},
	{"with ", "with"},
	{"without ", "witho"},
	{"he ", "he"},
	{"as ", "as"}
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

local macro_tmpl = [[
	m_%s: m_%s {
		compatible = "zmk,behavior-macro";
		#binding-cells = <0>;
		wait-ms = <5>;
		bindings = <&macro_tap%s>;
	};
]]

local combo_tmpl = [[
	combo_%s {
		timeout-ms = <50>;
		key-positions = <%s>;
		bindings = <&m_%s>;
		layers = <DEFAULT>;
	};
]]


--- @param s string
--- @return string
local trim = function(s)
	return (s:gsub("^%s*(.-)%s*$", "%1"))
end

--- @param chars string
--- @return string
local chars_to_bindings = function(chars)
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
		if char == " " then
			converted_char = "SPACE"
		end
		bindings = bindings .. " &kp " .. converted_char
	end
	return bindings
end

local chars_to_positions = function(chars)
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
local word_to_macro = function(key)
	local trimmed_key = trim(key)
	local upper_key = string.upper(key)
	return macro_tmpl:format(trimmed_key, trimmed_key, chars_to_bindings(upper_key))
end

--- @param key string
--- @param value string
--- @return string
local word_to_combo = function(key, value)
	local trimmed_key = trim(key)
	return combo_tmpl:format(trimmed_key, chars_to_positions(value), trimmed_key)
end

--- @return table, table
local generate_macros_and_combos = function()
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

local generate_in_nvim_split = function()
	local macros, combos = generate_macros_and_combos()
	local macros_str = table.concat(macros, "\n")
	local combos_str = table.concat(combos, "\n")
	local macro_lines = vim.split(macros_str, "\n")
	local combo_lines = vim.split(combos_str, "\n")

	vim.cmd("vsplit")
    local buf = vim.api.nvim_create_buf(false, true)
    vim.api.nvim_win_set_buf(0, buf)
	vim.api.nvim_buf_set_lines(buf, -1, -1, false, macro_lines)
	vim.api.nvim_buf_set_lines(buf, -1, -1, false, combo_lines)
end

generate_in_nvim_split()
