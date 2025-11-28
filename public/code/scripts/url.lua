local url = getgenv().url

if type(url) == "string" and url ~= "" then
    local res = request({
        Url = url,
        Method = "GET"
    })

    if res and type(res.Body) == "string" then
        writefile("result.txt", res.Body)
    end
end
