-- dumper reconstruct tool (writes into folder "dumper")
local appendfile_cloned = clonefunction(appendfile)
local writefile_cloned = clonefunction(writefile)
local isfile_cloned = clonefunction(isfile)
local makefolder_cloned = clonefunction(makefolder)
local old_loadstring = clonefunction(loadstring)

pcall(function() makefolder_cloned("dumper") end)

local out_raw = "dumper/Input"
local out_dec_pieces = "dumper/decoded_pieces.txt"
local out_dec_whole = "dumper/output"
local out_summary = "dumper/summary.txt"

writefile_cloned(out_raw, "")
writefile_cloned(out_dec_pieces, "")
writefile_cloned(out_dec_whole, "")
writefile_cloned(out_summary, "")

local function safe_append(name, text)
	if not isfile_cloned(name) then writefile_cloned(name, "") end
	appendfile_cloned(name, tostring(text))
end

-- base64 decoder
local b = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/'
local bmap = {} for i = 1, #b do bmap[b:sub(i,i)] = i-1 end
local function b64decode(data)
	if type(data) ~= "string" then return "" end
	data = data:gsub("%s+", "")
	local out, val, bits = {}, 0, 0
	for i = 1, #data do
		local c = data:sub(i,i)
		if c == "=" then break end
		local v = bmap[c]
		if v then
			val = val * 64 + v
			bits = bits + 6
			if bits >= 8 then
				bits = bits - 8
				local byte = math.floor(val / (2^bits)) % 256
				out[#out+1] = string.char(byte)
			end
		end
	end
	return table.concat(out)
end

local function is_printable_ratio(s, thresh)
	thresh = thresh or 0.9
	if type(s) ~= "string" or #s == 0 then return false end
	local printable = 0
	for i = 1, #s do
		local c = s:byte(i)
		if (c >= 32 and c <= 126) or c == 10 or c == 13 or c == 9 then printable += 1 end
	end
	return (#s > 0) and ((printable / #s) >= thresh)
end

local lua_signatures = {"function","local","loadstring","load","return","end","for","while","do","require","print","--","if","then"}
local function score_lua_like(s)
	if type(s) ~= "string" then return 0 end
	local score = 0
	for _, kw in ipairs(lua_signatures) do
		if s:find(kw, 1, true) then score += 1 end
	end
	if #s > 200 and is_printable_ratio(s, 0.85) then score += 2 end
	return score
end

local function filter_is_b64piece(s)
	return type(s) == "string" and s:match("^[A-Za-z0-9+/=]+$") ~= nil
end

local function build_candidates(str)
	local raw = tostring(str)
	local decoded = b64decode(raw)
	local cleaned = raw:gsub("[^A-Za-z0-9+/=]", "")
	local cleaned_decoded = b64decode(cleaned)
	return {
		{ name = "raw_concat", text = raw },
		{ name = "whole_decoded", text = decoded },
		{ name = "cleaned_decoded", text = cleaned_decoded }
	}
end

local function reconstruct(data)
	local candidates = build_candidates(data)
	for _, c in ipairs(candidates) do
		if c.name == "raw_concat" then
			writefile_cloned(out_raw, c.text)
		elseif c.name == "whole_decoded" then
			safe_append(out_dec_whole, "\n---- WHOLE ----\n" .. c.text)
		elseif c.name == "cleaned_decoded" then
			safe_append(out_dec_whole, "\n---- CLEANED ----\n" .. c.text)
		end
	end

	local summary_lines = {}
	for _, c in ipairs(candidates) do
		local s = score_lua_like(c.text)
		local printable = is_printable_ratio(c.text) and "high" or "low"
		summary_lines[#summary_lines+1] = string.format("%s: score=%d, printable=%s, bytes=%d", c.name, s, printable, #c.text)
	end
	safe_append(out_summary, table.concat(summary_lines, "\n"))

	local best, bestscore = nil, -1
	for _, c in ipairs(candidates) do
		local sc = score_lua_like(c.text)
		if sc > bestscore then bestscore = sc; best = c end
	end
	if best then
		writefile_cloned(out_dec_whole, ("Best guess: %s (score=%d, bytes=%d)\n\n%s"):format(best.name, bestscore, #best.text, best.text))
	end
end

-- 🔥 Hook loadstring
getgenv().loadstring = function(code, chunkname)
	task.spawn(function()
		reconstruct(code)
	end)
	return old_loadstring(code, chunkname)
end

print("[Dumper] loadstring hooked. Any loadstring() calls will be logged in dumper/")
