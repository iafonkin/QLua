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


RANDOM_SEED = tonumber(os.date("%Y%m%d%H%M%S"))

function random_max()
	-- не принимает параметры и возвращает от 0 до 2147483647 (макс. полож. 32 битное число) подходит нам для транзакций
	local res = (16807*(RANDOM_SEED or 137137))%2147483647
	RANDOM_SEED = res
	return res
end

zx = random_max()

message(tostring(zx))


