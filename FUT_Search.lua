  -- спецификация кодов фьюч контрактов
  -- https://www.moex.com/s205
  
  mask ="SR" -- список масок https://www.moex.com/a2087
  m_mask ={ "F",   "G",   "H",   "J",   "K",   "M",  "N",   "Q",   "U",   "V",   "X",   "Z"  }
  arg = ""
  k = 0  
  FUT = ""
  cont ={{}}
  z=""

  T_date = getInfoParam("TRADEDATE")
  T_year = tostring(T_date:sub(string.len(T_date)))
  T_next_Year = tostring(tonumber(T_date:sub(string.len(T_date)-3))+1)
  T_next_Year = T_next_Year:sub(4)
  T_month = tonumber(T_date:sub(4, 5))

year = {T_year, T_next_Year}
  
for a, v in ipairs(year) do

  for i = 1, 12 do
    FUT = tostring(mask .. m_mask[i]..v)
	  fut_life = getParamEx2( "SPBFUT", FUT, "DAYS_TO_MAT_DATE").param_value
    
    if tonumber(fut_life) > 0 then
  
      fut_vol_tr = getParamEx2( "SPBFUT", FUT, "MAT_DATE").param_value

      if k == 0 then
        k = i
        Y = v
      end
      
      table.insert(cont, {FUT, fut_life, fut_vol_tr})
    end
  end
end

 
for i = 2, table.maxn(cont) do
  
    z = z .. tostring(cont[i][1]) .." -- " .. tostring(cont[i][2]) .. " -- " .. tostring(cont[i][3]).. '\n'
 
end

z = z .. "now: " .. tostring(cont[2][1]) .. " next: " ..  tostring(cont[3][1])
    message(z)
 