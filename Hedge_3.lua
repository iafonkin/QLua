Settings = {
Name = "Hedge_3", 
Period = 200, 

line = {{
		Name = "Horizontal line",
		Type = TYPE_LINE, 
		Color = RGB(0, 0, 255)
		},
		{
		Name = "MOMENTUM_2", 
		Type = TYPE_LINE, 
		Color = RGB(221, 44, 44)
		}
		},

Horizontal_line="100"
}

function Init()
	
	return #Settings.line
end

function OnCalculate(Index)
P = Settings.Period
	if CandleExist(Index - P) then
	
		if Index > P then
			 
			Res =  C(Index) / C(Index - P) * 100
		end
	
	return tonumber(Settings.Horizontal_line), Res
	end
	
end
