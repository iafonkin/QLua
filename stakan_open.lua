

-- округдение до нужного после запятой
math.round = function(num, idp)
    local mult = 10^(idp or 0)
    return math.floor(num * mult + 0.5) / mult
  end


function OnQuote(class, sec ) 
	if class == a[3] and sec == a[7] then
	z = getQuoteLevel2 (class, sec)
    z1 = z.bid_count
    z3 = 0
    z4 = 0
    z6 = 0
    lag = 0
    lag1 = 0

		for i=z1, 1, -1 do
			if z.bid[i].quantity ~= nil then
				lag = lag + tonumber(z.bid[i].quantity)
                z3 = tonumber(z.bid[i].price)
                z4 = tonumber(z.bid[z.bid_count+0].price)
                z5 = (z4-z3) / z4 * 100
				if z5 > 0.15 and z6 == 0 then
                    z6 = i
                    lag1 = lag
				    --z4 = tonumber(z.bid[z.bid_count+0].price) - так для половинке стакана  Покупки
				    --message("Full close :  " .. z3 .. " prosadka po cene - ".. ( tonumber(z3-z4)))
				end
			end
			
			let = let .. "N-"..i.."  - price - ".. (z.bid[i].price)..";  "..(z.bid[i].quantity).." % ".. math.round(z5, 2) .."\n"
		end
								-- message (let)
    message(let .. "Full close :  " .. z6 .. " ob'em predlozh - ".. lag1 .. " - v % - " .. z5)
								let=""
                                lag = 0
                                lag1 = 0
	end
end

