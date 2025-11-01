-- gpt

-- dumper reconstruct tool (writes into folder "dumper")
local appendfile_cloned = clonefunction(appendfile)
local writefile_cloned = clonefunction(writefile)
local isfile_cloned = clonefunction(isfile)
local makefolder_cloned = clonefunction(makefolder)

-- ensure dumper folder exists
pcall(function() makefolder_cloned("dumper") end)

local out_raw = "dumper/Input"           -- raw concat -> Input
local out_dec_pieces = "dumper/decoded_pieces.txt"
local out_dec_whole = "dumper/output"    -- best-decoded whole -> output
local out_summary = "dumper/summary.txt"

-- reset/create files
writefile_cloned(out_raw, "")
writefile_cloned(out_dec_pieces, "")
writefile_cloned(out_dec_whole, "")
writefile_cloned(out_summary, "")

local function safe_append(name, text)
	if not isfile_cloned(name) then writefile_cloned(name, "") end
	appendfile_cloned(name, tostring(text))
end

-- robust base64 decoder
local b = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/'
local bmap = {}
for i = 1, #b do bmap[b:sub(i,i)] = i-1 end

local function b64decode(data)
	if type(data) ~= "string" then return "" end
	data = data:gsub("%s+", "")
	local out = {}
	local val = 0
	local bits = 0
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
	thresh = thresh or 0.90
	if type(s) ~= "string" or #s == 0 then return false end
	local printable = 0
	for i = 1, #s do
		local c = s:byte(i)
		if (c >= 32 and c <= 126) or c == 10 or c == 13 or c == 9 then printable = printable + 1 end
	end
	return (#s > 0) and ((printable / #s) >= thresh)
end

local lua_signatures = {"function","local","loadstring","load","return","end","for","while","do","require","print","--","if","then"}
local function score_lua_like(s)
	if type(s) ~= "string" then return 0 end
	local score = 0
	for _, kw in ipairs(lua_signatures) do
		if s:find(kw, 1, true) then score = score + 1 end
	end
	if #s > 200 and is_printable_ratio(s, 0.85) then score = score + 2 end
	return score
end

local function gather_table_from_args(...)
	local out = {}
	for i = 1, select("#", ...) do out[#out+1] = select(i, ...) end
	if #out == 1 and type(out[1]) == "table" then return out[1] end
	local t = {}
	for i = 1, #out do t[i] = out[i] end
	return t
end

local function filter_is_b64piece(s)
	if type(s) ~= "string" then return false end
	return s:match("^[A-Za-z0-9+/=]+$") ~= nil
end

local function build_candidates(tseq)
	local seq = {}
	for i = 1, #tseq do seq[#seq+1] = tseq[i] end

	local raw_concat = table.concat(seq)

	local decoded_pieces = {}
	for i = 1, #seq do
		local v = seq[i]
		if type(v) == "string" and filter_is_b64piece(v) then
			decoded_pieces[#decoded_pieces+1] = b64decode(v)
		else
			decoded_pieces[#decoded_pieces+1] = tostring(v)
		end
	end
	local join_decoded_pieces = table.concat(decoded_pieces)

	local whole_decoded = ""
	if type(raw_concat) == "string" and filter_is_b64piece(raw_concat) then
		whole_decoded = b64decode(raw_concat)
	else
		local cleaned = raw_concat:gsub("[^A-Za-z0-9+/=]", "")
		if #cleaned > 0 then whole_decoded = b64decode(cleaned) end
	end

	local only_b64 = {}
	for i = 1, #seq do
		local v = seq[i]
		if filter_is_b64piece(v) then only_b64[#only_b64+1] = v end
	end
	local only_b64_concat = table.concat(only_b64)
	local only_b64_decoded = ""
	if #only_b64_concat > 0 then only_b64_decoded = b64decode(only_b64_concat) end

	return {
		{ name = "raw_concat", text = raw_concat },
		{ name = "decoded_pieces", text = join_decoded_pieces },
		{ name = "whole_decoded", text = whole_decoded },
		{ name = "only_b64_decoded", text = only_b64_decoded }
	}
end

local function reconstruct(...)
	local t = gather_table_from_args(...)
	local seq = {}
	for i = 1, #t do seq[#seq+1] = t[i] end
	if #seq == 0 then
		local keys = {}
		for k in pairs(t) do keys[#keys+1] = k end
		table.sort(keys, function(a,b)
			if type(a) == "number" and type(b) == "number" then return a < b end
			return tostring(a) < tostring(b)
		end)
		for _,k in ipairs(keys) do seq[#seq+1] = t[k] end
	end

	local candidates = build_candidates(seq)

	-- write primary candidate outputs
	for _, c in ipairs(candidates) do
		if c.name == "raw_concat" then
			-- write raw concat to "dumper/Input"
			writefile_cloned(out_raw, c.text)
		elseif c.name == "decoded_pieces" then
			safe_append(out_dec_pieces, c.text)
		elseif c.name == "whole_decoded" or c.name == "only_b64_decoded" then
			safe_append(out_dec_whole, ("\n---- %s ----\n"):format(c.name))
			safe_append(out_dec_whole, c.text)
		end
	end

	-- score and summary
	local summary_lines = {}
	for _, c in ipairs(candidates) do
		local s = score_lua_like(c.text)
		local printable = is_printable_ratio(c.text) and "high_printable" or "low_printable"
		summary_lines[#summary_lines+1] = string.format("%s: score=%d, printable=%s, bytes=%d", c.name, s, printable, #c.text)
	end
	safe_append(out_summary, table.concat(summary_lines, "\n"))

	-- find best candidate and also write small snippet into output file (dumper/output)
	local best, bestscore = nil, -1
	for _, c in ipairs(candidates) do
		local sc = score_lua_like(c.text)
		if sc > bestscore then bestscore = sc; best = c end
	end
	if best then
		local header = ("Best guess: %s (score=%d, bytes=%d)\n\n"):format(best.name, bestscore, #best.text)
		-- overwrite output file with best guess (safe)
		writefile_cloned(out_dec_whole, header .. best.text)
		-- also write short snippet to summary
		local snippet = best.text:sub(1, 2000)
		safe_append(out_summary, ("\nBest guess snippet:\n%s\n"):format(snippet))
	end

	return true
end

return reconstruct
