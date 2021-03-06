#include once "ProcessChannelStatisticsCommand.bi"
#ifndef unicode
#define unicode
#endif
#include once "windows.bi"
#include once "Settings.bi"
#include once "IntegerToWString.bi"

#if __FB_DEBUG__ <> 0
Const StatisticWordFileName = "c:\programming\freebasic projects\channelstats.xml"
#else
Const StatisticWordFileName = "c:\programming\www.freebasic.su\channelstats.xml"
#endif

Type StatisticWordCountParam
	Dim pBot As IrcBot Ptr
	' Кому отправить сообщение
	Dim UserName As WString * (IrcClient.MaxBytesCount + 1)
	' Канал
	Dim Channel As WString * (IrcClient.MaxBytesCount + 1)
	
	Dim hMapFile As HANDLE
End Type

Function StatisticWordCount(ByVal lpParam As LPVOID)As DWORD
	Dim ttp As StatisticWordCountParam Ptr = CPtr(StatisticWordCountParam Ptr, lpParam)
	
	ttp->pBot->Say(ttp->Channel, @"Читаю статистику количества фраз пользователей из реестра Windows.")
	
	Dim hHeap As Handle = HeapCreate(HEAP_NO_SERIALIZE, 0, 0)
	Dim ValuesCount As DWORD = 0
	Dim uw As UserWords Ptr = EnumerateUserWords(@ttp->Channel, hHeap, @ValuesCount)
	
	If uw = 0 Then
		ttp->pBot->Say(ttp->Channel, @"Ошибка чтения реестра, лень разбираться какая.")
	Else
		Dim hFile As HANDLE = CreateFile(@StatisticWordFileName, GENERIC_WRITE, FILE_SHARE_READ, NULL, CREATE_ALWAYS, FILE_ATTRIBUTE_NORMAL, NULL)
		If hFile <> INVALID_HANDLE_VALUE Then
			Dim bb As ZString * 2 = Any
			bb[0] = 255
			bb[1] = 254
			Dim WriteBytesCount As DWORD = Any
			WriteFile(hFile, @bb, 2, @WriteBytesCount, 0)
			
			Const xmlDeclaration = "<?xml version=""1.0"" encoding=""utf-16"" ?>"
			WriteFile(hFile, @xmlDeclaration, lstrlen(xmlDeclaration) * SizeOf(WString), @WriteBytesCount, 0)
			
			Const xmlStartRoot = "<channelstats>"
			Const xmlEndRoot = "</channelstats>"
			
			WriteFile(hFile, @xmlStartRoot, lstrlen(@xmlStartRoot) * SizeOf(WString), @WriteBytesCount, 0)
			
			For i As DWORD = 0 To ValuesCount - 1
				Const xmlStartUserMessagesTable = "<statistics>"
				Const xmlEndUserMessagesTable = "</statistics>"
				
				WriteFile(hFile, @xmlStartUserMessagesTable, lstrlen(@xmlStartUserMessagesTable) * SizeOf(WString), @WriteBytesCount, 0)
				
				Scope
					Const xmlStartUserName = "<nick>"
					Const xmlEndUserName = "</nick>"
					
					WriteFile(hFile, @xmlStartUserName, lstrlen(@xmlStartUserName) * SizeOf(WString), @WriteBytesCount, 0)
					WriteFile(hFile, @uw[i].UserName, lstrlen(@uw[i].UserName) * SizeOf(WString), @WriteBytesCount, 0)
					WriteFile(hFile, @xmlEndUserName, lstrlen(@xmlEndUserName) * SizeOf(WString), @WriteBytesCount, 0)
				End Scope
				
				Scope
					Const xmlStartMessagesCount = "<messages-count>"
					Const xmlEndMessagesCount = "</messages-count>"
					
					Dim strWordsCount As WString * 100 = Any
					itow(uw[i].WordsCount, @strWordsCount, 10)
					
					WriteFile(hFile, @xmlStartMessagesCount, lstrlen(@xmlStartMessagesCount) * SizeOf(WString), @WriteBytesCount, 0)
					WriteFile(hFile, @strWordsCount, lstrlen(@strWordsCount) * SizeOf(WString), @WriteBytesCount, 0)
					WriteFile(hFile, @xmlEndMessagesCount, lstrlen(@xmlEndMessagesCount) * SizeOf(WString), @WriteBytesCount, 0)
				End Scope
				
				WriteFile(hFile, @xmlEndUserMessagesTable, lstrlen(xmlEndUserMessagesTable) * SizeOf(WString), @WriteBytesCount, 0)
			Next
			
			WriteFile(hFile, @xmlEndRoot, lstrlen(xmlEndRoot) * SizeOf(WString), @WriteBytesCount, 0)
			
			CloseHandle(hFile)
			
			ttp->pBot->Say(ttp->Channel, @"Смотри по этой ссылке http://www.freebasic.su/channelstats.xml")
		End If
		
	End If
	
	HeapDestroy(hHeap)
	Dim hMapFile As Handle = ttp->hMapFile
	UnmapViewOfFile(ttp)
	CloseHandle(hMapFile)
	Return 0
End Function

Sub ProcessChannelStatisticsCommand( _
		ByVal pBot As IrcBot Ptr, _
		ByVal User As WString Ptr, _
		ByVal Channel As WString Ptr _
	)
	Dim TimerName As WString * (IrcClient.MaxBytesCount + 1) = Any
	lstrcpy(@TimerName, "IrcBotStatistic")
	lstrcat(@TimerName, User)
	
	' Выделить память
	Dim hMapFile As Handle = CreateFileMapping(INVALID_HANDLE_VALUE, 0, PAGE_READWRITE, 0, SizeOf(StatisticWordCountParam), @TimerName)
	If hMapFile <> NULL Then
		
		If GetLastError() <> ERROR_ALREADY_EXISTS Then
			
			Dim ttp As StatisticWordCountParam Ptr = CPtr(StatisticWordCountParam Ptr, MapViewOfFile(hMapFile, FILE_MAP_ALL_ACCESS, 0, 0, SizeOf(StatisticWordCountParam)))
			If ttp <> 0 Then
				ttp->hMapFile = hMapFile
				ttp->pBot = pBot
				lstrcpy(ttp->UserName, User)
				lstrcpy(ttp->Channel, Channel)
				
				Dim hThread As Handle = CreateThread(NULL, 0, @StatisticWordCount, ttp, 0, 0)
				If hThread <> NULL Then
					CloseHandle(hThread)
				Else
					UnmapViewOfFile(ttp)
					CloseHandle(hMapFile)
					pBot->Say(Channel, @"Не могу создать поток получения статистики")
				End If
			Else
				CloseHandle(hMapFile)
				pBot->Say(Channel, @"Не могу выделить память")
			End If
		Else
			CloseHandle(hMapFile)
		End If
	Else
		pBot->Say(Channel, @"Не могу создать отображение файла")
	End If
End Sub
