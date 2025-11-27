local url = getgenv().url or ""

if url ~= "" then
    local res = request({
        Url = url,
        Method = "GET"
    })

    if res and res.Body and not isfile("result.txt") then
        writefile("result.txt", res.Body)
    elseif isfile("result.txt") then
        delfile("result.txt")
        writefile("result.txt", res.Body)
    end
end
