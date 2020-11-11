is_run = true
let =""
posicia = 200
lag = 0


sec_code = "HYZ0"
class_code = "SPBFUT"

-- request_result = Subscribe_Level_II_Quotes(class_code, sec_code)

z = getQuoteLevel2 (class_code, sec_code)
z1 = z.bid_count





function OnQuote(class, sec ) 
	if class == "SPBFUT" and sec == "HYZ0" then
	z = getQuoteLevel2 (class, sec)
	z1 = z.bid_count
		for i=z1, 1, -1 do
			if z.bid[i].quantity ~= nil then
				lag = lag + tonumber(z.bid[i].quantity)
			
				if lag > posicia then
				z3 = tonumber(z.bid[i].price)
				z4 = tonumber(z.bid[z.bid_count+0].price)
				message("Full close :  " .. z3 .. " lag - ".. ( tonumber(z3-z4)))
			
				end
			end
			
								let = let .. "N-"..i.."  - price - ".. (z.bid[i].price)..";  "..(z.bid[i].quantity).."\n"
		end
								message (let)
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