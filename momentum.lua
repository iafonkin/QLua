-- https://quikluacsharp.ru/quik-qlua/poluchenie-v-qlua-lua-dannyh-iz-grafikov-i-indikatorov/

is_run = true
period = 200
res = 100
now_candle = 0
status = 2

function dannye()
    ds, err = CreateDataSource ("TQBR", "HYDR", INTERVAL_H1)
    ds:SetEmptyCallback()
    sleep(100)
    while (err == "" or err == nil) and ds:Size() == 0 do sleep(1) end
    if err ~= "" and err ~= nil then message("Ошибка подключения к графику: "..err) end
    now_candle = ds:Size()
end




function main()

    while is_run do
        
        dannye()
        
        if ds:Size() > period+2 then
        res = ds:L(ds:Size()) / ds:L(ds:Size() - period) * 100
        res1 = ds:L(ds:Size()-1) / ds:L(ds:Size() - period - 1) * 100
        res2 = ds:L(ds:Size()-2) / ds:L(ds:Size() - period - 2) * 100

        end

        message("momentum - " .. res)

        if status == 2 and res > 100 and res1 >= 100 and res2 >=100 then
            
            status = 2
            now_candle = ds:Size()
            -- Представляем дату в виде "ГГГГММДД"
            local date_pos = (tostring(ds:T(now_candle).year)..add_zero(tostring(ds:T(now_candle).month))..add_zero(tostring(ds:T(now_candle).day)))
            -- Представляем время в виде "ЧЧММСС"
            local time_pos = (add_zero(tostring(ds:T(now_candle).hour))..add_zero(tostring(ds:T(now_candle).min))..add_zero(tostring(ds:T(now_candle).sec)))
            -- Вызываем размещение метки с полученной датой и временем
            place_label(ds:C(now_candle), date_pos, time_pos)

            message(ds:C(now_candle).. " = " .. date_pos .. " = " .. time_pos)


        end
        
        
                
        sleep(10000)
    end

end

function OnStop()
    is_run = false
    
    return 1000
end

function place_label(price, date_pos, time_pos)
	-- Внимание, название всех параметров должны писаться большими буквами
	label_params = {
		-- Если подпись не требуется то оставить строку пустой ""
		TEXT = "Open Hedge",
		-- Если картинка не требуется оставить значение пустым ""
		IMAGE_PATH = getScriptPath() .. "\\arrow.jpeg",
		-- Расположение картинки относительно текста (возможно 4 варианта: LEFT, RIGHT, TOP, BOTTOM)
		ALIGNMENT = "LEFT",
		-- Значение параметра на оси Y, к которому будет привязана метка
		YVALUE = price,
		-- Дата в формате «ГГГГММДД», к которой привязана метка
		DATE = date_pos,
		-- Время в формате «ЧЧММСС», к которому будет привязана метка
		TIME = time_pos,
		-- Красная компонента цвета в формате RGB. Число в интервале [0;255]
		R = 100,
		-- Зеленая компонента цвета в формате RGB. Число в интервале [0;255]
		G = 200,
		-- Синяя компонента цвета в формате RGB. Число в интервале [0;255]
		B = 80,
		-- Прозрачность метки в процентах. Значение должно быть в промежутке [0; 100]
		TRANSPARENCY = 10,
		-- Прозрачность фона картинки. Возможные значения: «0» – прозрачность отключена, «1» – прозрачность включена
		TRANSPARENT_BACKGROUND = 1,
		-- Название шрифта (например «Arial»)
		FONT_FACE_NAME = "Arial",
		-- Размер шрифта
		FONT_HEIGHT = 12,
		-- Текст всплывающей подсказки
		HINT = "This moment hedge is Open"
	}
	-- Добавляем метку и запоминаем ее ID
	label_id = AddLabel("RusHidro", label_params)
end

-- Функция добавляет 0 к переданному значению, если количество переданных символов = 1, "1" -> "01"
function add_zero(number_str)
	if #number_str == 1 then
		return "0"..number_str
	else
		return number_str
	end
end

