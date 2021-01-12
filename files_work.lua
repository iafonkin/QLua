
local FPath = getScriptPath().."/1txt.txt"
a ={}

arg = os.date()
arg2 = os.date("*t").year


function main()
SaveData()
end

function SaveData()
    local f = io.open(FPath, 'a')   
    
          f:write(arg .. "Hedge ON" .."\n")
          f:flush() 
    
       f:close()
end   