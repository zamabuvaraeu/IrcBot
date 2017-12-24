#include once "MainLoop.bi"
#include once "Bot.bi"

Function MainLoop(ByVal lpParam As LPVOID)As DWORD
	' Инициализация случайных чисел
	Dim dtNow As SYSTEMTIME = Any
	GetSystemTime(@dtNow)
	srand(dtNow.wMilliseconds - dtNow.wSecond + dtNow.wMinute + dtNow.wHour)
	
	Dim pBot As IrcBot Ptr = lpParam
	
	Do
		If pBot->Client.OpenIrc(pBot->IrcServer, pBot->Port, pBot->BotNick, pBot->UserString, pBot->Description) Then
			pBot->Client.Run()
			pBot->Client.CloseIrc()
			SleepEx(60 * 1000, 0)
		End If
	Loop
	Return 0
End Function
