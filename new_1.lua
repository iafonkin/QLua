-- Объявляем переменные
is_run = true

local FPath = getScriptPath().."/ini.txt"
local LogPath = getScriptPath().."/log.txt"
a ={}
m = "Data : \n"
z = 0
gi = ""
Q_sec = 0 -- колво общая позиция хеджирукемой бумаги
t_dat = {{}}
lag1 = 1
--переменные для МОМЕНТУМ
period = 200
res = 100
now_candle = 0


-- округдение до нужного после запятой
math.round = function(num, idp)
  local mult = 10^(idp or 0)
  return math.floor(num * mult + 0.5) / mult
end

-- Стандартная отработка остановки скрипта
function OnStop()
  is_run = false
  DestroyTable(t_id)
  AddLog("Script close")

  local file, err = io.open(FPath, "w") -- Открыть файл для чтения
	if file then                               -- Проверить, что он открылся

		a[11] = status
		for i=1,11 do
			file:write(a[i] .. '\n')                        -- Прочитать первую строку в переменную x (без преобразования в число)
		end
		file:flush()
		file:close()                           -- Закрыть файл
	end

  return 1000
end

local file, err = io.open(FPath, "r") -- Открыть файл для чтения
if file then                               -- Проверить, что он открылся

		for i=1,11 do
			a[i] = file:read()                        -- Прочитать первую строку в переменную x (без преобразования в число)
		end
		
		file:close()                           -- Закрыть файл
		status = a[11]
else
    message (err, 2)             -- Если не открылся, то вывести ошибку
    is_run = false
end



function GetData()
	-- Расчёт кол-ва акций
	z = getNumberOf("depo_limits")
	
	for k=0, z-1 do
		gi = getItem("depo_limits", k) 							-- берем данные k -ой строки (нумерация с 0) из таблицы fdepo_limits
		-- 
		if gi.sec_code == a[5] then
			Q_sec = gi.currentbal
			  
		end
	end

    FutInfo = getSecurityInfo(a[3], a[7]) -- запрос таблицы данных фьяча
	FutLot = FutInfo.lot_size  -- размер лота

	-- Даннвые по фьючерсу
	local request_result_go = ParamRequest( a[3], a[7], "BAYDEPO")   -- Подписываемся на получение ГО на продажу
	local request_result_price = ParamRequest ( a[3], a[7], "LAST")
	local request_result_life = ParamRequest ( a[3], a[7], "DAYS_TO_MAT_DATE")
	local request_result_vol_tr = ParamRequest ( a[3], a[7], "BIDDEPTHT")

	local go_buy = getParamEx2( a[3], a[7], "BUYDEPO").param_value    -- Получаем данные ГО продавца
	fut_price = getParamEx2( a[3], a[7], "LAST").param_value
	fut_life = getParamEx2( a[3], a[7], "DAYS_TO_MAT_DATE").param_value
	fut_vol_tr = getParamEx2( a[3], a[7], "BIDDEPTHT").param_value
	fut_vol_rec = lag1 * FutLot
	fut_vol_rec_1 = math.round( fut_vol_rec / Q_sec * 100, 2 )
	--STARTTIME
	-- futTIME 
	--VOLTODAY
	-- BIDDEPTHT
	go_buy_1 = math.round(go_buy, 2)
	
	

	-- Данные хеджируемой акции
	local request_result_sec_price = ParamRequest( a[4], a[5], "LAST")
	sec_price =getParamEx2( a[4], a[5], "LAST").param_value
	
	-- расчёт контанго/бэквордации
	CONTANGO = (fut_price - sec_price * FutLot) / (sec_price * FutLot + go_buy) *365 / fut_life * 100
	CONTANGO = math.round(CONTANGO, 2)

	-- переменные по количеству хеджируемых бумаг	
	Q_sec_h = Q_sec
	Q_sec_h_1 = math.round(Q_sec_h / Q_sec * 100, 2)
	Q_fut_rec = math.round(Q_sec / FutLot, 0)

	go_buy_2 = math.round(Q_sec_h / FutLot * go_buy_1, 1)
	
	-- message(    "request_result_depo_GO: " .. fut_vol_tr)
	--.. ";\n" ..
    --"request_result_depo_price: " .. fut_vol_rec .. ";\n" ..
	--"life: " .. fut_vol_rec_1.. ";\n" ..
	--"Q_sec:  ".. Q_sec
	--)


	-- текущие дата и врем
	T_date = getInfoParam("TRADEDATE")
	T_time = getInfoParam("LOCALTIME")

	
	
end

-- Обзор стакана фьючерса по стороне "покупка" для определения глубины с максимальной просадкой 0,15% от лучшей цены
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
				if z5 > tonumber( a[10] ) and z6 == 0 then
                    z6 = i
                    lag1 = lag
				    --z4 = tonumber(z.bid[z.bid_count+0].price) - так для половинке стакана  Покупки
				    --message("Full close :  " .. z3 .. " prosadka po cene - ".. ( tonumber(z3-z4)))
				end
			end
			
								--let = let .. "N-"..i.."  - price - ".. (z.bid[i].price)..";  "..(z.bid[i].quantity).." % ".. math.round(z5, 2) .."\n"
		end
								-- message (let)
    							--message(let .. "Full close :  " .. z6 .. " ob'em predlozh - ".. lag1 .. " - v % - " .. z5)
								
	end
	fut_vol_rec = lag1 * FutLot
	fut_vol_rec_1 = math.round( fut_vol_rec / Q_sec * 100, 2 )
	SetCell(t_id, 5 , 2 ,tostring(fut_vol_rec))
	SetCell(t_id, 5 , 3 ,tostring(fut_vol_rec_1))
end
	
function vuBildTable()

	-- образ таблицы как бы
	t_dat = {	{"Hedging a long stock position", a[4], "class code"},
				{" ", a[5], "sec code"},
				{" ", "quantity", " % "},
				{"whole long stock position", tostring(Q_sec), " "},
				{"part recommended for hedge", tostring(fut_vol_rec), tostring(fut_vol_rec_1), " ","step/lot"},
				{"your decision to hedge part", tostring(Q_sec_h), tostring(Q_sec_h_1), "< - >", tostring(FutLot), "< + >"},
				{"contango/backwardation", tostring(CONTANGO), "% Y      "},
				{"guarantee provision for 1 contract", tostring(go_buy_1) , tostring(go_buy_2)},
				{"State"},
				{"robot is OFF", "START"},
				{"----"},
				{"Hedge"},
				{"Open", "Date", "Time"},
				{" ", tostring(T_date), tostring(T_time)},
				{" ", "security", "futures"},
				{"quantity", 123, 456},
				{"price", 526, 865},
				{"sum", 12466, 46578},
				{"----"},
				{"actual quotes", 0.7, 7100},
				{" ", 216563, 365415},
				{"V", 45645, 55555},
				{"actual result", " ", 77777777}
				
				
			}
	
	-- Рисуем таблицу
		-- Получает доступный id для создания
		t_id = AllocTable()
		-- Добавляет 5 колонок
		AddColumn(t_id, 1, "", true, QTABLE_STRING_TYPE, 35)
		AddColumn(t_id, 2, "", true, QTABLE_INT_TYPE, 15)
		AddColumn(t_id, 3, "", true, QTABLE_INT_TYPE, 15)
		AddColumn(t_id, 4, "", true, QTABLE_INT_TYPE, 5)
		AddColumn(t_id, 5, "", true, QTABLE_INT_TYPE, 15)
		AddColumn(t_id, 6, "", true, QTABLE_STRING_TYPE, 5)
		
		 -- Подписываемся на события
		SetTableNotificationCallback(t_id, OnTableEvent)
		
		-- Создает таблицу
		t = CreateWindow(t_id)
		-- Устанавливает заголовок	
		SetWindowCaption(t_id, "First windows")
		-- Задает положение и размеры окна таблицы
		SetWindowPos(t_id, 200, 200, 520, 450)
		-- Добавляет строки
		InsertRow(t_id, -1)
		
		-- Заполняем строки из "образа"
			for i=1,23 do
				InsertRow(t_id, i)
				for j=1,6 do
				SetCell (t_id, i, j, t_dat[i][j])
				end
			end
			
			
			
			
	--
	SetColor(t_id, 1, QTABLE_NO_INDEX, RGB(0, 255, 255), RGB(0, 0, 0), RGB(0, 255, 255), RGB(0, 0, 0))
	SetColor(t_id, 2, QTABLE_NO_INDEX, RGB(0, 255, 255), RGB(0, 0, 0), RGB(0, 255, 255), RGB(0, 0, 0))
	
	SetColor(t_id, 3, 2, RGB(240, 255, 240), RGB(0, 0, 0), RGB(240, 255, 240), RGB(0, 0, 0))
	SetColor(t_id, 3, 3, RGB(240, 255, 240), RGB(0, 0, 0), RGB(240, 255, 240), RGB(0, 0, 0))
	
	SetColor(t_id, 4, 1, RGB(240, 255, 240), RGB(0, 0, 0), RGB(240, 255, 240), RGB(0, 0, 0))
	SetColor(t_id, 4, 2, RGB(224, 255, 224), RGB(0, 0, 0), RGB(224, 255, 224), RGB(0, 0, 0))
	SetColor(t_id, 4, 3, RGB(224, 255, 224), RGB(0, 0, 0), RGB(224, 255, 224), RGB(0, 0, 0))
				
	SetColor(t_id, 5, 1, RGB(240, 255, 240), RGB(0, 0, 0), RGB(240, 255, 240), RGB(0, 0, 0))
	SetColor(t_id, 5, 2, RGB(224, 255, 224), RGB(0, 0, 0), RGB(224, 255, 224), RGB(0, 0, 0))
	SetColor(t_id, 5, 3, RGB(224, 255, 224), RGB(0, 0, 0), RGB(224, 255, 224), RGB(0, 0, 0))	
		
	SetColor(t_id, 6, 1, RGB(240, 255, 240), RGB(0, 0, 0), RGB(240, 255, 240), RGB(0, 0, 0))	
	SetColor(t_id, 6, 2, RGB(224, 255, 224), RGB(0, 0, 0), RGB(224, 255, 224), RGB(0, 0, 0))
	SetColor(t_id, 6, 3, RGB(224, 255, 224), RGB(0, 0, 0), RGB(224, 255, 224), RGB(0, 0, 0))
	SetColor(t_id, 6, 4, RGB(255, 0, 0), RGB(0, 0, 0), RGB(255, 0, 0), RGB(0, 0, 0))
	SetColor(t_id, 6, 5, RGB(224, 255, 224), RGB(0, 0, 0), RGB(224, 255, 224), RGB(0, 0, 0))
	SetColor(t_id, 6, 6, RGB(0, 255, 0), RGB(0, 0, 0), RGB(0, 255, 0), RGB(0, 0, 0))

	SetColor(t_id, 10, 2, RGB(180, 180, 255), RGB(0, 0, 0), RGB(180, 180, 255), RGB(0, 0, 0))
	
	
	
end

-- Функция обрабатывает события в таблице
function OnTableEvent(t_id, msg, par1, par2)
    -- Если был клик левой кнопкой
	 -- message("msg= "..msg.." par1="..par1.." par2="..par2.. "status="..status)
    if msg == 11 then
        
		if par1 == 6 -- Номер строки
	    and par2 == 4 then -- Номер колонки
		
		   Q_sec_h = Q_sec_h - FutLot
		   Q_sec_h_1 = math.round(Q_sec_h / Q_sec * 100, 2)
		   go_buy_2 = math.round(Q_sec_h / FutLot * go_buy_1, 1)
		   SetCell (t_id, 6, 2, tostring(Q_sec_h))
		   SetCell (t_id, 6, 3, tostring(Q_sec_h_1))
		   SetCell (t_id, 8, 3, tostring(go_buy_2))
		end
		
		if par1 == 6 -- Номер строки
	    and par2 == 6 then -- Номер колонки
		
		   Q_sec_h = Q_sec_h + FutLot
		   Q_sec_h_1 = math.round(Q_sec_h / Q_sec * 100, 2)
		   go_buy_2 = math.round(Q_sec_h / FutLot * go_buy_1, 1)
		   SetCell (t_id, 6, 2, tostring(Q_sec_h))
		   SetCell (t_id, 6, 3, tostring(Q_sec_h_1))
		   SetCell (t_id, 8, 3, tostring(go_buy_2))
		end

		if par1 == 10 -- Номер строки
		and par2 == 2 then -- Номер колонки
						
			if status == "OFF" then -- если Статус = Выкл, то Статус = Вкл . Т.е включается скрипт отслеживания необходимости открытия хеджа
				status = "ON"
				AddLog ("new status = ".. status)
				SetCell (t_id, 10, 1, "robot is ON")
				SetCell (t_id, 10, 2, "STOP")

			elseif status == "ON" then -- если Статус = Вкл, то Статус = Выкл . Т.е. останавливантся скрипт льслеживания
				status = "OFF"
				AddLog ("new status = ".. status)
				SetCell (t_id, 10, 1, "robot is OFF")
				SetCell (t_id, 10, 2, "START")

			elseif status == "HEDGE" then -- если Статус = Хедж, то Статус = ВЫкл . принудительное закрытие Хеджа
				status = "OFF"
				AddLog ("new status = ".. status)
				SetCell (t_id, 10, 1, "robot is OFF")
				SetCell (t_id, 10, 2, "START")
			end
		
		end
		


	end	
end


-- ЛОГИКА ОТСЛЕЖИВАНИЯ НА ОСНОВЕ ИНДИКАТОРА МОМЕНТУМ
function momentum()

	dannye()
        
	if ds:Size() > period+2 then
	res = ds:L(ds:Size()) / ds:L(ds:Size() - period) * 100
	res1 = ds:L(ds:Size()-1) / ds:L(ds:Size() - period - 1) * 100
	res2 = ds:L(ds:Size()-2) / ds:L(ds:Size() - period - 2) * 100

	end

	--message("momentum - " .. res)

	if status == "ON" and res > 100 and res1 >= 100 and res2 >=100 then
		
		status = "HEDGE"
		now_candle = ds:Size()
		-- Представляем дату в виде "ГГГГММДД"
		local date_pos = (tostring(ds:T(now_candle).year)..add_zero(tostring(ds:T(now_candle).month))..add_zero(tostring(ds:T(now_candle).day)))
		-- Представляем время в виде "ЧЧММСС"
		local time_pos = (add_zero(tostring(ds:T(now_candle).hour))..add_zero(tostring(ds:T(now_candle).min))..add_zero(tostring(ds:T(now_candle).sec)))
		-- Вызываем размещение метки с полученной датой и временем
		place_label(ds:C(now_candle), date_pos, time_pos)

		message(ds:C(now_candle).. " = " .. date_pos .. " = " .. time_pos)



	end

end

-- вспомогательная функция для МОМЕНТУМ
function dannye() 
    ds, err = CreateDataSource (a[4], a[5], INTERVAL_H1)
    ds:SetEmptyCallback()
    sleep(100)
    while (err == "" or err == nil) and ds:Size() == 0 do sleep(1) end
    if err ~= "" and err ~= nil then message("Ошибка подключения к графику: "..err) end
    now_candle = ds:Size()
end

-- вспомогательная функция для МОМЕНТУМ
-- Функция добавляет 0 к переданному значению, если количество переданных символов = 1, "1" -> "01"
function add_zero(number_str)
	if #number_str == 1 then
		return "0"..number_str
	else
		return number_str
	end
end

-- вспомогательная функция для МОМЕНТУМ
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

function AddLog(log_txt)
	local l = io.open(LogPath, 'a')   
    arg = tostring( os.date() .. " --- ".. log_txt)
	l:write(arg .. '\n') 
	l:flush() 

 	l:close()
end


--Основное тело скрипта
function main()
AddLog("Script open")
GetData()
vuBildTable()
	 while is_run do
-- vuIniData()

		momentum()

        
	sleep(10000)
    end
end


