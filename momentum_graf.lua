is_run = true
period = 200
res = 0
now_candle = 0


function raschet()
    size = getNumCandles ("RusHidro")
    HydroPrice, s, name = getCandlesByIndex("RusHidro", 0, 0, size)


end

function main()

    while is_run do
        raschet()
        
        if size > period then
        res = HydroPrice[size-1].close / HydroPrice[size-1-period].close * 100

        end

        message("momentum - " .. res)
        
        
        
                
        sleep(10000)
    end

end

function OnStop()
    is_run = false
    
    return 1000
end

