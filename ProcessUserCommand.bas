#include once "Bot.bi"
#include once "IntegerToWString.bi"

Function ProcessUserCommand(ByVal eData As AdvancedData Ptr, ByVal User As WString Ptr, ByVal MessageText As WString Ptr)As Boolean
	' Разбить текст по пробелам
	Dim WordsCount As Long = Any
	Dim Lines As WString Ptr Ptr = CommandLineToArgvW(MessageText, @WordsCount)
	
	' Справка !справка
	If lstrcmp(Lines[0], @HelpCommand) = 0 Then
		eData->objClient.SendIrcMessage(User, @AllUserCommands)
	End If
	
	' Синий кит !кит
	If lstrcmp(Lines[0], @KitCommand) = 0 OrElse lstrcmp(Lines[0], @KitCommand2) = 0 Then
		eData->objClient.SendIrcMessage(User, @"                      I'M GAY GAY GAY ")
		SleepEx(MessageTimeWait, 0)
		eData->objClient.SendIrcMessage(User, @"             __   __  IN A SPECIAL WAY")
		SleepEx(MessageTimeWait, 0)
		eData->objClient.SendIrcMessage(User, @"            __ \ / __                 ")
		SleepEx(MessageTimeWait, 0)
		eData->objClient.SendIrcMessage(User, @"           /  \ | /  \     /          ")
		SleepEx(MessageTimeWait, 0)
		eData->objClient.SendIrcMessage(User, @"               \|/        /           ")
		SleepEx(MessageTimeWait, 0)
		eData->objClient.SendIrcMessage(User, @"          _,.---v---._   /            ")
		SleepEx(MessageTimeWait, 0)
		eData->objClient.SendIrcMessage(User, @" /\__/\  /            \ /             ")
		SleepEx(MessageTimeWait, 0)
		eData->objClient.SendIrcMessage(User, @" \_  _/ /              \              ")
		SleepEx(MessageTimeWait, 0)
		eData->objClient.SendIrcMessage(User, @"   \ \_|           @ __|              ")
		SleepEx(MessageTimeWait, 0)
		eData->objClient.SendIrcMessage(User, @"hjw \                \_               ")
		SleepEx(MessageTimeWait, 0)
		eData->objClient.SendIrcMessage(User, @"`97  \     ,__/       /               ")
		SleepEx(MessageTimeWait, 0)
		eData->objClient.SendIrcMessage(User, @"   ~~~`~~~~~~~~~~~~~~/~~~~	          ")
		
		ProcessUserCommand = True
	End If
	
	' Команда !символ текст
	If lstrcmp(Lines[0], @CharCommand) = 0 Then
		' Вывести в чат коды символов фразы
		' Число в строку
		' Dim strBuffer As WString * 100 = Any
		' itow(*eData->TimerCounter, @strBuffer, 10)
		ProcessUserCommand = True
	End If
	
	' Команда !пинг пользователь
	If lstrcmp(Lines[0], @PingCommand) = 0 Then
		' Засечь время
		' Отправить запрос
		' Получить ответ, получить время
		' Получить разницу времени
		' Вывести в чат
		ProcessUserCommand = True
	End If
	
	' Команда !жуйк текст
	If lstrcmp(Lines[0], @JuickCommand) = 0 Then
		eData->objClient.SendIrcMessage(User, @JuickCommandDone)
		ProcessUserCommand = True
	End If
	
	' Сказать реальное значение ника пользователя
	
	' Игра крестики‐нолики
	
	' Игра в карты
	
	' Проверка заголовков какого‐нибудь http‐сервера
	
	LocalFree(Lines)
End Function