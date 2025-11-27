local password = {}
function generate(method, length) -- alg
    if method == "crypt" and crypt and crypt.generatekey and crypt.hash then
        table.insert(password, tostring(crypt.hash(crypt.generatekey(), "sha1")))
    elseif method == "random" then
        local chars = {"a","b","c","d","e","f","g","h","i","j","k","l","m","n","o","p","q","r","s","t","u","v","w","x","y","z","A","B","C","D","E","F","G","H","I","J","K","L","M","N","O","P","Q","R","S","T","U","V","W","X","Y","Z","0","1","2","3","4","5","6","7","8","9","!","@","#","$","%","^","&","*","(",")","-","_","=","+","[","]","{","}",";",":","'","\"",",",".","<",">","/","?","\\","|","~","`"}
        for i = 1, length do
            local char = chars[math.random(1, #chars)]
            table.insert(password, char)
        end
    end 
end

generate("crypt", 1)
print(table.concat(password)) -- setclipboard
