-- Объявляем переменные
is_run = true

local FPath = getScriptPath().."/ini.txt"
a ={}
m = "Data : \n"
z = 0
gi = ""
Q_sec = 0 -- колво общая позиция хеджирукемой бумаги
t_dat = {{}}
lag1 = 1

-- округдение до нужного после запятой
math.round = function(num, idp)
  local mult = 10^(idp or 0)
  return math.floor(num * mult + 0.5) / mult
end

-- Стандартная отработка остановки скрипта
function OnStop()
  is_run = false
  DestroyTable(t_id)
  return 1000
end

local file, err = io.open(FPath, "r") -- Открыть файл для чтения
if file then                               -- Проверить, что он открылся

		for i=1,10 do
			a[i] = file:read()                        -- Прочитать первую строку в переменную x (без преобразования в число)
		end
		
		file:close()                           -- Закрыть файл
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
	
	
	
end

-- Функция обрабатывает события в таблице
function OnTableEvent(t_id, msg, par1, par2)
    -- Если был клик левой кнопкой
	-- message("msg= "..msg.." par1="..par1.." par2="..par2)
    if msg == 11 then
        -- Если это общий стоп
		if par1 == 6 -- Номер строки
	    and par2 == 4 then -- Номер колонки
		
		   Q_sec_h = Q_sec_h - FutLot
		   Q_sec_h_1 = math.round(Q_sec_h / Q_sec * 100, 2)
		   go_buy_2 = math.round(Q_sec_h / FutLot * go_buy_1, 1)
		   DestroyTable(t_id)
		   vuBildTable()
		end
		
		if par1 == 6 -- Номер строки
	    and par2 == 6 then -- Номер колонки
		
		   Q_sec_h = Q_sec_h + FutLot
		   Q_sec_h_1 = math.round(Q_sec_h / Q_sec * 100, 2)
		   go_buy_2 = math.round(Q_sec_h / FutLot * go_buy_1, 1)
		   DestroyTable(t_id)
		   vuBildTable()
		end
	end	
end


--Основное тело скрипта
function main()

GetData()
vuBildTable()
	 while is_run do
-- vuIniData()



        
	sleep(10000)
    end
end


