math.round = function(num, idp)
    local mult = 10^(idp or 0)
    return math.floor(num * mult + 0.5) / mult
end
  
  
  Q_sec_h = 25000
    FutLot = 10000

g = Q_sec_h % FutLot

pos_quantity = tostring(math.round(Q_sec_h / FutLot , 0))


r = tostring(pos_quantity:sub(1, string.len(pos_quantity) - 2))

message ( g .."   " .. pos_quantity.. " ----- " .. r)


