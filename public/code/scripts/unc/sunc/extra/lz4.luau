--!strict
-- metatablecat 2022 - buffer rewrite

local lz4 = {}

local function plainFind(str, pat)
	return string.find(str, pat, 0, true)
end

-- Buffer-backed stream
type Streamer = {
	Offset: number,
	Source: buffer,
	Length: number,
	IsFinished: boolean,
	LastUnreadBytes: number,

	read: (Streamer, len: number?, shiftOffset: boolean?) -> string,
	seek: (Streamer, len: number) -> (),
	append: (Streamer, newData: string) -> (),
	toEnd: (Streamer) -> ()
}

local function streamer(str: string): Streamer
	local Stream = {} :: Streamer
	Stream.Source = buffer.fromstring(str)
	Stream.Length = buffer.len(Stream.Source)
	Stream.Offset = 0
	Stream.IsFinished = Stream.Length == 0
	Stream.LastUnreadBytes = 0

	function Stream.read(self: Streamer, len: number?, shift: boolean?): string
		len = len or 1
		shift = if shift ~= nil then shift else true

		local available = math.min(len, self.Length - self.Offset)
		local dat = buffer.readstring(self.Source, self.Offset, available)

		self.LastUnreadBytes = len - available

		if shift then
			self:seek(len)
		end

		return dat
	end

	function Stream.seek(self: Streamer, len: number)
		self.Offset = math.clamp(self.Offset + len, 0, self.Length)
		self.IsFinished = self.Offset >= self.Length
	end

	function Stream.append(self: Streamer, newData: string)
		local newLen = self.Length + #newData
		local newBuf = buffer.create(newLen)
		buffer.copy(newBuf, 0, self.Source, 0, self.Length)
		buffer.writestring(newBuf, self.Length, newData)
		self.Source = newBuf
		self.Length = newLen
		self:seek(0)
	end

	function Stream.toEnd(self: Streamer)
		self.Offset = self.Length
		self.IsFinished = true
	end

	return Stream
end

function lz4.compress(str: string): string
	type BlockData = {
		[number]: {
			Literal: string,
			LiteralLength: number,
			MatchOffset: number?,
			MatchLength: number?
		}
	}

	local blocks: BlockData = {}
	local iostream = streamer(str)

	if iostream.Length > 12 then
		local firstFour = iostream:read(4)
		local processed = firstFour
		local lit = firstFour
		local match = ""
		local LiteralPushValue = ""
		local pushToLiteral = true

		repeat
			pushToLiteral = true
			local nextByte = iostream:read()

			if plainFind(processed, nextByte) then
				local next3 = iostream:read(3, false)

				if #next3 < 3 then
					LiteralPushValue = nextByte .. next3
					iostream:seek(3)
				else
					match = nextByte .. next3
					local matchPos = plainFind(processed, match)

					if matchPos then
						iostream:seek(3)
						repeat
							local nextMatchByte = iostream:read(1, false)
							local newResult = match .. nextMatchByte
							local repos = plainFind(processed, newResult)
							if repos then
								match = newResult
								matchPos = repos
								iostream:seek(1)
							end
						until not plainFind(processed, match .. iostream:read(1, false)) or iostream.IsFinished

						local matchLen = #match
						local pushMatch = true

						if iostream.Length - iostream.Offset <= 5 then
							LiteralPushValue = match
							pushMatch = false
						end

						if pushMatch then
							pushToLiteral = false
							local realPosition = #processed - matchPos
							processed = processed .. match

							table.insert(blocks, {
								Literal = lit,
								LiteralLength = #lit,
								MatchOffset = realPosition + 1,
								MatchLength = matchLen,
							})
							lit = ""
						end
					else
						LiteralPushValue = nextByte
					end
				end
			else
				LiteralPushValue = nextByte
			end

			if pushToLiteral then
				lit = lit .. LiteralPushValue
				processed = processed .. nextByte
			end
		until iostream.IsFinished

		table.insert(blocks, {
			Literal = lit,
			LiteralLength = #lit
		})
	else
		blocks[1] = {
			Literal = str,
			LiteralLength = #str
		}
	end

	-- Estimate output size and write to buffer
	local parts = {}
	local function write(s: string)
		parts[#parts + 1] = s
	end

	write(string.rep("\x00", 4))

	for chunkNum, chunk in blocks do
		local litLen = chunk.LiteralLength
		local matLen = (chunk.MatchLength or 4) - 4

		local tokenLit = math.clamp(litLen, 0, 15)
		local tokenMat = math.clamp(matLen, 0, 15)
		local token = bit32.lshift(tokenLit, 4) + tokenMat
		write(string.pack("<I1", token))

		if litLen >= 15 then
			local rem = litLen - 15
			repeat
				local nextToken = math.clamp(rem, 0, 0xFF)
				write(string.pack("<I1", nextToken))
				if nextToken == 0xFF then rem -= 255 end
			until nextToken < 0xFF
		end

		write(chunk.Literal)

		if chunkNum ~= #blocks then
			write(string.pack("<I2", chunk.MatchOffset))

			if matLen >= 15 then
				local rem = matLen - 15
				repeat
					local nextToken = math.clamp(rem, 0, 0xFF)
					write(string.pack("<I1", nextToken))
					if nextToken == 0xFF then rem -= 255 end
				until nextToken < 0xFF
			end
		end
	end

	local output = table.concat(parts)
	local compLen = #output - 4

	return string.pack("<I4", compLen) .. string.pack("<I4", iostream.Length) .. output
end

function lz4.decompress(lz4data: string): string
	local inputStream = streamer(lz4data)

	local compressedLen = string.unpack("<I4", inputStream:read(4))
	local decompressedLen = string.unpack("<I4", inputStream:read(4))
	local _reserved = string.unpack("<I4", inputStream:read(4))

	if compressedLen == 0 then
		return inputStream:read(decompressedLen)
	end

	-- Pre-allocate output buffer
	local outBuf = buffer.create(decompressedLen)
	local outOffset = 0

	local function writeOut(s: string)
		buffer.writestring(outBuf, outOffset, s)
		outOffset += #s
	end

	local function readOut(offset: number, len: number): string
		local available = math.min(len, outOffset - offset)
		local result = buffer.readstring(outBuf, offset, available)

		-- Handle overlapping copies (run-length style)
		if available < len then
			local extra = len - available
			local repeated = ""
			local pos = offset
			while #repeated < extra do
				local chunk = buffer.readstring(outBuf, pos, math.min(available, extra - #repeated))
				repeated ..= chunk
			end
			result ..= repeated
		end

		return result
	end

	repeat
		local token = string.byte(inputStream:read())
		local litLen = bit32.rshift(token, 4)
		local matLen = bit32.band(token, 15) + 4

		if litLen >= 15 then
			repeat
				local nextByte = string.byte(inputStream:read())
				litLen += nextByte
			until nextByte ~= 0xFF
		end

		local literal = inputStream:read(litLen)
		writeOut(literal)

		if outOffset < decompressedLen then
			local offset = string.unpack("<I2", inputStream:read(2))

			if matLen >= 19 then
				repeat
					local nextByte = string.byte(inputStream:read())
					matLen += nextByte
				until nextByte ~= 0xFF
			end

			local matchStart = outOffset - offset
			local match = readOut(matchStart, matLen)
			writeOut(match)
		end

	until outOffset >= decompressedLen

	return buffer.readstring(outBuf, 0, decompressedLen)
end

return lz4
