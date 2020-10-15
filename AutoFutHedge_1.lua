
-- Объявляем переменные
is_run = true

local FPath = getScriptPath().."/ini.txt"
a ={}
m = "Data : \n"
z = 0
gi = ""
Q_sec = 0 -- колво общая позиция хеджирукемой бумаги
t_dat = {{}}

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

--Чтение файла INI.tzt и присвоение прочитанного в переменные
local file, err = io.open(FPath, "r") -- Открыть файл для чтения
if file then                               -- Проверить, что он открылся

		for i=1,9 do
			a[i] = file:read()                        -- Прочитать первую строку в переменную x (без преобразования в число)
		end
		
		file:close()                           -- Закрыть файл
else
    message (err, 2)             -- Если не открылся, то вывести ошибку
    is_run = false
end

-- Функция обрабатывает события в таблице
function OnTableEvent(t_id, msg, par1, par2)
    -- Если был клик левой кнопкой
	-- message("msg= "..msg.." par1="..par1.." par2="..par2)
    if msg == 11 then
        -- Если это общий стоп
		if par1 == 6 -- Номер строки
	    and par2 == 4 then -- Номер колонки
		
	       message("I click !")
	
	
		end
	end	
end


--Основное тело скрипта
function main()

vuBildTable()
	 while is_run do
-- vuIniData()
vuCheckIniData()
vuGetDataToTable()


        
	sleep(10000)
    end
end

function vuCheckIniData()													-- функция проверки данных из ini.txt и данных открытого терминала Quik
	
	z = getNumberOf("futures_client_holding")								-- выясняем количество строк в таблице futures_client_holding
	
	for k=0, z-1 do
		gi = getItem("futures_client_holding", k) 							-- берем данные k -ой строки (нумерация с 0) из таблицы futures_client_holding
		-- 
		if gi.sec_code == a[7] then
			if gi.totalnet == tonumber(a[9]) then
				flag1 = 1													-- ксли в терминале есть позиция по тикеру фьюча как и в ini.txt и количество то же совпадает то flag1 присваем 1
			else
				message("ERROR !!! Data in ini.txt and Quik terminal are not equal !!!", 2)
			end
			  
		end
	
		
	end
end

function vuGetDataToTable()

-- Даннвые по фьючерсу
	local request_result_go = ParamRequest( a[3], a[7], "BAYDEPO")   -- Подписываемся на получение ГО на продажу
	local request_result_price = ParamRequest ( a[3], a[7], "LAST")
	local request_result_life = ParamRequest ( a[3], a[7], "DAYS_TO_MAT_DATE")
	

	local go_buy = getParamEx2( a[3], a[7], "BUYDEPO").param_value    -- Получаем данные ГО продавца
	fut_price = getParamEx2( a[3], a[7], "LAST").param_value
	fut_life = getParamEx2( a[3], a[7], "DAYS_TO_MAT_DATE").param_value
	
	FutInfo = getSecurityInfo(a[3], a[7]) -- запрос таблицы данных фьяча
	FutLot = FutInfo.lot_size  -- размер лота

-- Данные хеджируемой акции
	local request_result_sec_price = ParamRequest( a[4], a[5], "LAST")
	sec_price =getParamEx2( a[4], a[5], "LAST").param_value
	
-- расчёт контанго/бэквордации
	CONTANGO = (fut_price - sec_price * FutLot) / (sec_price * FutLot + go_buy) *365 / fut_life * 100
	CONTANGO = math.round(CONTANGO, 2)
	
-- Расчёт кол-ва акций
	

	
--	message(    "request_result_depo_GO: " .. go_buy.. ";\n" ..
--    "request_result_depo_price: " .. fut_price .. ";\n" ..
--	"life: " .. CONTANGO
--	)

end

function vuBildTable()

	-- образ таблицы как бы
	t_dat = {	{"Hedging a long stock position", a[4], "class code"},
				{" ", a[5], "sec code"},
				{" ", "quantity", " % "},
				{"whole long stock position", tostring(Q_sec), " "},
				{"part recommended for hedge", 456, 45.5, " ","step/lot"},
				{"your decision to hedge part", 789, 25.1, "< - >", tostring(FutLot), "< + >"},
				{"contango/backwardation", tostring(CONTANGO), "% Y      "},
				{"guarantee provision for 1 contract", " ", " "},
				{"State"},
				{"robot is OFF", "START"},
				{"----"},
				{"Hedge"},
				{"Open", "Date", "Time"},
				{" ", "11.09.2020", "15:45"},
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



function vuGetDataToTable_2()
	-- текущая дата
	DateNow = getInfoParam("TRADEDATE")
	datetime = {};
    datetime.day,datetime.month,datetime.year = string.match(DateNow,"(%d*).(%d*).(%d*)")
	
	-- данные фьюча
	FutInfo = getSecurityInfo(a[3], a[7]) -- запрос таблицы данных фьяча
	FutLot = FutInfo.lot_size  -- размер лота
	FutExp = FutInfo.mat_date  -- дата эксирации в формате 20200917
	dt = {};
	dt.year,dt.month,dt.day = string.match(FutExp,"(%d%d%d%d)(%d%d)(%d%d)"); -- дата эспирации в виде массива
	DayFutLife = (os.time(dt) - os.time(datetime))/86400 -- время до эспирации в днях
	
	
	
	-- message("Lot =" .. DateNow .. " data = " .. FutExp .. " nov dats = " .. DayFutLife)
	

	z = getNumberOf("depo_limits")
	
	for k=0, z-1 do
		gi = getItem("depo_limits", k) 							-- берем данные k -ой строки (нумерация с 0) из таблицы fdepo_limits
		-- 
		if gi.sec_code == a[5] then
			Q_sec = gi.currentbal
			  
		end
	end
	
end





function vuIniData() -- вывод сообщением содержимое переменных данные в которые занесены из ini.txt
	for i=1,9 do	

		m = m .. i .. " - " .. a[i] .. ";\n" 

	end
	message(m)
end