-- dofile (getScriptPath().."\\monitorStepNRTR.lua") --ste

-- Объявляем переменные
is_run = true

FUT_POS = 0
SEC_POS = 0

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
RANDOM_SEED = tonumber(os.date("%Y%m%d%H%M%S")) -- для рандомной нумерации
new_fut_name = ""


function random_max()
	-- не принимает параметры и возвращает от 0 до 2147483647 (макс. полож. 32 битное число) подходит нам для транзакций
	local res = (16807*(RANDOM_SEED or 137137))%2147483647
	RANDOM_SEED = res
	return res
end


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
  	--if order.balance ~= nil and order.balance ~= 0 then
	--	AddLog("QUIK is stop, but we have Order unexecute to " .. tostring(order.balance) .. "contract !!!")
	--	message("QUIK is stop, but we have Order unexecute to " .. tostring(order.balance) .. "contract !!!")
 	--end

  -- Перезапишим с новыми данными файл ini.txt
  local file, err = io.open(FPath, "w") -- Открыть файл для чтения
	if file then                               -- Проверить, что он открылся

		a[11] = status
		a[9] = FUT_POS
		a[8] = SEC_POS
		for i=1,13 do
			file:write(a[i] .. '\n')                        -- Прочитать первую строку в переменную x (без преобразования в число)
		end
		file:flush()
		file:close()                           -- Закрыть файл
	end

  return 1000
end

function futActual(fut_name)  
	--mask ="SR" -- список масок https://www.moex.com/a2087
	mask = fut_name:sub(1,2)
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
  
						  --z = z .. "now: " .. tostring(cont[2][1]) .. " next: " ..  tostring(cont[3][1])
						  -- message(z)
  
		  if tonumber(cont[2][2]) <= 11 then
			  res = tostring(cont[3][1])
		  else
			  res = tostring(cont[2][1])
		  end
  
	  return(res)
end 

local file, err = io.open(FPath, "r") -- Открыть файл для чтения
if file then                               -- Проверить, что он открылся

		for i=1,13 do
			a[i] = file:read()                        -- Прочитать первую строку в переменную x (без преобразования в число)
		end
		
		file:close()                           -- Закрыть файл
		status = a[11]
		FUT_POS = a[9]
		SEC_POS = a[8]
		
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


	-- слежение за сменой актуальных фьючерсов
	new_fut_name = futActual(a[7])
	if new_fut_name ~= a[7] then
	   
		message ("Importent !!! \n" .. 
		"There are 11 days left until the \n" .. 
		"expiration of the futures.\n" ..
		"The time has come to switch to \n" ..
		" a new contract - " .. new_fut_name .. "\n" ..
		"Modify the data in the ini.txt file. \n" ..
		"And, if necessary, change the open \n" ..
		"positions manually." )
	
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
	--анализ стакана
	stakan(a[3], a[7])
	
	
end

function stakan(class, sec)

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

-- Обзор стакана фьючерса по стороне "покупка" для определения глубины с максимальной просадкой 0,15% от лучшей цены
function OnQuote(class, sec ) 
	stakan(class, sec)
end
	
function vuBildTable()
	if a[11] == "ON" then
		state1, state2 = "robot is ON", "STOP"
		elseif a[11] == "OFF" then
			state1, state2 = "robot is OFF", "START"
			else
				state1, state2 = "robot is HEDGE", "STOP"
		
	end

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
				{state1, state2},
				{"----"},
				{"Hedge"},
				{"Open", "Date", "Time"},
				{" ", tostring(T_date), tostring(T_time)},
				{" ", "security", "futures"},
				{"quantity", tostring(FUT_POS * FutLot), tostring(FUT_POS)},
				{"price", a[12], a[13]},
				{"sum", tostring(FUT_POS * FutLot * a[12]), tostring(FUT_POS * a[13])},
				{"----"},
				{"actual quotes", 0.7, 7100},
				{" ", 216563, 365415},
				{"V", 45645, 55555},
				{"actual result", " ", (FUT_POS * FutLot * (a[12] - sec_price) - ( FUT_POS * (a[13] - fut_price ) )) }
				
				
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

		if par1 == 5 -- Номер строки
		and par2 == 2 then -- Номер колонки
			
			Q_sec_h = fut_vol_rec
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

	if status == "ON" and res < 100 and res1 >= 100 and res2 >=100 then
		
		status = "HEDGE"
		AddLog ("new status = ".. status)
		SetCell (t_id, 10, 1, "robot is HEDGE")
		now_candle = ds:Size()
		-- Представляем дату в виде "ГГГГММДД"
		local date_pos = (tostring(ds:T(now_candle).year)..add_zero(tostring(ds:T(now_candle).month))..add_zero(tostring(ds:T(now_candle).day)))
		-- Представляем время в виде "ЧЧММСС"
		local time_pos = (add_zero(tostring(ds:T(now_candle).hour))..add_zero(tostring(ds:T(now_candle).min))..add_zero(tostring(ds:T(now_candle).sec)))
		-- Вызываем размещение метки с полученной датой и временем
		place_label(ds:C(now_candle), date_pos, time_pos, "Open Hedge")

		message(ds:C(now_candle).. " = " .. date_pos .. " = " .. time_pos)

		OpenPosition()



	end

	if status == "HEDGE" and res > 103 and res1 <= 103 and res2 <=103 then
		status = "ON"
		AddLog ("new status = ".. status)
		SetCell (t_id, 10, 1, "robot is ON")
		now_candle = ds:Size()
		-- Представляем дату в виде "ГГГГММДД"
		local date_pos = (tostring(ds:T(now_candle).year)..add_zero(tostring(ds:T(now_candle).month))..add_zero(tostring(ds:T(now_candle).day)))
		-- Представляем время в виде "ЧЧММСС"
		local time_pos = (add_zero(tostring(ds:T(now_candle).hour))..add_zero(tostring(ds:T(now_candle).min))..add_zero(tostring(ds:T(now_candle).sec)))
		-- Вызываем размещение метки с полученной датой и временем
		place_label(ds:C(now_candle), date_pos, time_pos, "Close Hedge")

		message(ds:C(now_candle).. " = " .. date_pos .. " = " .. time_pos)

		ClosePosition()
	
	
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
function place_label(price, date_pos, time_pos, tekst)
	-- Внимание, название всех параметров должны писаться большими буквами
	label_params = {
		-- Если подпись не требуется то оставить строку пустой ""
		TEXT = tekst,
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

function OpenPosition()

	trans_id = random_max()
	pos_quantity = tostring(math.round(Q_sec_h / FutLot , 0))
	SEC_POS = Q_sec_h
	
	local Transaction={
		["TRANS_ID"]   = tostring(trans_id),
		["ACTION"]     = "NEW_ORDER",
		["CLASSCODE"]  = a[3],
		["SECCODE"]    = a[7],
		["OPERATION"]  = "S", -- (SELL)
		["TYPE"]       = "M", -- по рынку (MARKET)
		["QUANTITY"]   = tostring(pos_quantity:sub(1, string.len(pos_quantity) - 2)), -- количество
		["ACCOUNT"]    = a[1],
		["PRICE"]      = tostring(z.bid[z6].price),
		["COMMENT"]    = "hedge"
	 }

	local Result = sendTransaction(Transaction)
   	AddLog("Order #"..tostring(trans_id) .. " to sell " .. tostring(pos_quantity) ..  " futures by price: " .. tostring(z.bid[z6].price) .. " send") -- Записывает в лог-файл
   
   -- ЕСЛИ функция вернула строку диагностики ошибки, ТО значит транзакция не прошла
    if Result ~= "" then
      -- Выводит сообщение с ошибкой
	  message("Hedging by selling futures has failed\nERROR: "..Result)
	  AddLog("Hedging by selling futures has failed. ERROR: "..Result)
	else
		FUT_POS = pos_quantity
			
   	end   
end

function ClosePosition()
	
	trans_id = random_max()
	pos_quantity = tostring(math.round(FUT_POS+0, 0))
	fut_price = getParamEx2( a[3], a[7], "LAST").param_value
	fut_price = tostring(math.round(fut_price * 1.01, 0))
	
	local Transaction={
		["TRANS_ID"]   = tostring(trans_id),
		["ACTION"]     = "NEW_ORDER",
		["CLASSCODE"]  = a[3],
		["SECCODE"]    = a[7],
		["OPERATION"]  = "B", -- (Buy)
		["TYPE"]       = "M", -- по рынку (MARKET)
		["QUANTITY"]   = tostring(pos_quantity:sub(1, string.len(pos_quantity) - 2)), -- количество, -- количество
		["ACCOUNT"]    = a[1],
		["PRICE"]      = tostring(fut_price:sub(1, string.len(fut_price) - 2)),
		["COMMENT"]    = "stop hedge"
	 }

	local Result = sendTransaction(Transaction)
   	AddLog("Order #"..tostring(trans_id) .. " to Buy " .. tostring(pos_quantity) ..  " futures by price: " .. tostring(fut_price:sub(1, string.len(fut_price) - 2)) .. " send") -- Записывает в лог-файл
   
   -- ЕСЛИ функция вернула строку диагностики ошибки, ТО значит транзакция не прошла
    if Result ~= "" then
      -- Выводит сообщение с ошибкой
	  message("Stop Hedging by Buying futures has failed\nERROR: "..Result)
	  AddLog("Stop Hedging by Buying futures has failed. ERROR: "..Result)
	  else 
		
		FUT_POS = 0
		SEC_POS = 0
      
   	end   
end

function OnOrder(order)

	if order.trans_id == trans_id and order.balance == 0 then
		if bit.test(order.flags, 2) then
			a[8] = 0
			a[9] = 0
			else
				a[9] = pos_quantity
				a[8] = Q_sec_h
		end
		AddLog("Order #" .. tostring(trans_id) .. " full execute")
		message("bit - " .. tostring(bit.test(order.flags, 2)))
	end	

end


--Основное тело скрипта
function main()
AddLog("Script open")
GetData()
vuBildTable()
	 while is_run do


		momentum()

		SetCell (t_id, 16, 2, tostring(a[8]))
		SetCell (t_id, 16, 3, tostring(a[9]))
		
		fut_price = getParamEx2( a[3], a[7], "LAST").param_value
		sec_price =getParamEx2( a[4], a[5], "LAST").param_value
		SetCell (t_id, 20, 3, tostring(fut_price))
		SetCell (t_id, 20, 2, tostring(sec_price))
		SetCell (t_id, 23, 3, tostring(FUT_POS * FutLot * (a[12] - sec_price) - ( FUT_POS * (a[13] - fut_price ) )) )




 
        
	sleep(10000)
    end
end


