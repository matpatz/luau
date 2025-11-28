local url = getgenv().url or ""

if url ~= "" then
    local res = request({
        Url = url,
        Method = "GET"
    })

    if res and res.Body and writefile then
        writefile("result.txt", res.Body)
    end
end
