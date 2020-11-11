is_run = true
let =""
posicia = 50
lag = 0


sec_code = "HYZ0"
class_code = "SPBFUT"

-- request_result = Subscribe_Level_II_Quotes(class_code, sec_code)

z = getQuoteLevel2 (class_code, sec_code)
z1 = z.offer_count





function OnQuote(class, sec ) 
	if class == "SPBFUT" and sec == "HYZ0" then
	z = getQuoteLevel2 (class, sec)
    z1 = z.offer_count
    z3 = 0
    z4 = 0
    lag = 0
		for i=1, z1, 1 do
			if z.offer[i].quantity ~= nil then
				lag = lag + tonumber(z.offer[i].quantity)
			
				if lag > 50 and z3 == 0 then
                    z3 = tonumber(z.offer[i].price)
                    z4 = tonumber(z.offer[1].price)
				    --z4 = tonumber(z.offer[z.offer_count+0].price) - так для половинке стакана  Покупки
				    --message("Full close :  " .. z3 .. " prosadka po cene - ".. ( tonumber(z3-z4)))
				end
			end
			
								let = let .. "N-"..i.."  - price - ".. (z.offer[i].price)..";  "..(z.offer[i].quantity).."\n"
		end
								message (let)
    message("Full close :  " .. z3 .. " prosadka po cene - ".. ( tonumber(z4-z3)))
								let=""
								lag = 0
	end
end


function main()
while is_run do
sleep(5000)
    end
end

function OnStop()
  is_run = false
  
  return 1000
end