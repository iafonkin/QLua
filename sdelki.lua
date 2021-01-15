-- вычисление руальной цены исполнения заявки
avg_price = 0
avg_qty = 0
avg_sum = 0
trt ={}	
for i=1, getNumberOf("trades")-1 do
trt = getItem("trades", i)
--if trt.trans_id == trans_id then
    avg_qty = avg_qty + trt.qty
    avg_sum = avg_sum + (trt.qty * trt.price)
--end

end
    avg_price = avg_sum / avg_qty
    avg_price_sec = getParamEx2( "TQBR", "HYDR", "LAST").param_value
    message (tostring(avg_price) .. " --- " .. tostring(avg_price_sec) .. "/n" ..
     tostring(trt.trans_id))
-- окончание вычисления цены исполнения