#include once "Bot.bi"
#include once "BotConfig.bi"
#include once "IntegerToWString.bi"
#include once "CharConstants.bi"
#include once "StringFunctions.bi"
#include once "Settings.bi"
#include once "windows.bi"

Const AsciiFileName = "ascii.txt"

Type TimerThreadParam
	Dim Interval As Integer
	Dim eData As AdvancedData Ptr
	' Кому отправить сообщение
	Dim UserName As WString * (IrcClient.MaxBytesCount + 1)
	' Текст сообщения
	Dim TextToSend As WString * (IrcClient.MaxBytesCount + 1)
	
	Dim hMapFile As HANDLE
End Type

Type StatisticWordCountParam
	Dim eData As AdvancedData Ptr
	' Кому отправить сообщение
	Dim UserName As WString * (IrcClient.MaxBytesCount + 1)
	' Канал
	Dim Channel As WString * (IrcClient.MaxBytesCount + 1)
	
	Dim hMapFile As HANDLE
End Type

Function TimerAPCProc(ByVal lpParam As LPVOID)As DWORD
	Dim ttp As TimerThreadParam Ptr = CPtr(TimerThreadParam Ptr, lpParam)
	Sleep_(ttp->Interval)
	ttp->eData->objClient.SendIrcMessage(ttp->UserName, ttp->TextToSend)
	
	Dim hMapFile As Handle = ttp->hMapFile
	UnmapViewOfFile(ttp)
	CloseHandle(hMapFile)
	Return 0
End Function

Function StatisticWordCount(ByVal lpParam As LPVOID)As DWORD
	Dim ttp As StatisticWordCountParam Ptr = CPtr(StatisticWordCountParam Ptr, lpParam)
	
#if __FB_DEBUG__ <> 0
	Const StatisticWordFileName = "c:\programming\freebasic projects\filelist.txt"
#else
	Const StatisticWordFileName = "c:\programming\www.freebasic.su\filelist.txt"
#endif
	
	ttp->eData->objClient.SendIrcMessage(ttp->Channel, @"Читаю статистику количества фраз пользователей из реестра Windows")
	
	Dim hHeap As Handle = HeapCreate(HEAP_NO_SERIALIZE, 0, 0)
	Dim ValuesCount As DWORD = 0
	Dim uw As UserWords Ptr = EnumerateUserWords(@ttp->Channel, hHeap, @ValuesCount)
	
	If uw = 0 Then
		ttp->eData->objClient.SendIrcMessage(ttp->Channel, @"Ошибка чтения реестра, лень разбираться какая")
	Else
		Dim hFile As HANDLE = CreateFile(@StatisticWordFileName, GENERIC_WRITE, FILE_SHARE_READ, NULL, CREATE_ALWAYS, FILE_ATTRIBUTE_NORMAL, NULL)
		If hFile <> INVALID_HANDLE_VALUE Then
			Dim bb As ZString * 2 = Any
			bb[0] = 255
			bb[1] = 254
			Dim WriteBytesCount As DWORD = Any
			WriteFile(hFile, @bb, 2, @WriteBytesCount, 0)
			
			For i As DWORD = 0 To ValuesCount - 1
				Dim strWordsCount As WString * 100 = Any
				itow(uw[i].WordsCount, @strWordsCount, 10)
				
				Dim strSendData As WString * (IrcClient.MaxBytesCount + 1) = Any
				lstrcpy(@strSendData, @uw[i].UserName)
				lstrcat(@strSendData, @" ")
				lstrcat(@strSendData, @strWordsCount)
				
				WriteFile(hFile, @strSendData, lstrlen(@strSendData) * SizeOf(WString), @WriteBytesCount, 0)
				WriteFile(hFile, @vbCrLf, 2 * SizeOf(WString), @WriteBytesCount, 0)
				
			Next
			CloseHandle(hFile)
			
			ttp->eData->objClient.SendIrcMessage(ttp->Channel, @"Смотри по этой ссылке http://www.freebasic.su/filelist.txt")
		End If
		
	End If
	
	HeapDestroy(hHeap)
	Dim hMapFile As Handle = ttp->hMapFile
	UnmapViewOfFile(ttp)
	CloseHandle(hMapFile)
	Return 0
End Function

Function ProcessUserCommand(ByVal eData As AdvancedData Ptr, ByVal User As WString Ptr, ByVal Channel As WString Ptr, ByVal MessageText As WString Ptr)As Boolean
	
	' Команда пинг .
	If lstrcmp(MessageText, @PingCommand) = 0 Then
		lstrcpy(eData->SavedChannel, Channel)
		lstrcpy(eData->SavedUser, User)
		
		' Засечь время
		Dim dt As SYSTEMTIME = Any
		GetSystemTime(@dt)
		Dim ft As FILETIME = Any
		SystemTimeToFileTime(@dt, @ft)
		
		Dim ul As ULARGE_INTEGER = Any
		ul.LowPart = ft.dwLowDateTime
		ul.HighPart = ft.dwHighDateTime
		
		Dim strNumber As WString * 256 = Any
		i64tow(ul.QuadPart, @strNumber, 10)
		
		' Отправить запрос
		eData->objClient.SendCtcpPingRequest(User, @strNumber)
		Return True
	End If
	
	' Забор
	If StartsWith(MessageText, @"!з") Then
		Dim wParam As WString Ptr = StrChr(MessageText, WhiteSpaceChar)
		wParam += 1
		If wParam <> 0 Then
			Dim ParamLength As Integer = lstrlen(wParam)
			If ParamLength > 0 Then
				For i As Integer = 0 To ParamLength - 1
					Dim wChar As Integer = wParam[i]
					If i Mod 2 = 0 Then
						Select Case wChar
							Case &h401 ' Ё
								wChar = &h451
							Case &h410 ' А
								wChar = &h430
							Case &h411
								wChar = &h431
							Case &h412
								wChar = &h432
							Case &h413
								wChar = &h433
							Case &h414
								wChar = &h434
							Case &h415
								wChar = &h435
							Case &h416
								wChar = &h436
							Case &h417
								wChar = &h437
							Case &h418
								wChar = &h438
							Case &h419
								wChar = &h439
							Case &h41A
								wChar = &h43A
							Case &h41B
								wChar = &h43B
							Case &h41C
								wChar = &h43C
							Case &h41D
								wChar = &h43D
							Case &h41E
								wChar = &h43E
							Case &h41F
								wChar = &h43F
							Case &h420
								wChar = &h440
							Case &h421
								wChar = &h441
							Case &h422
								wChar = &h442
							Case &h423
								wChar = &h443
							Case &h424
								wChar = &h444
							Case &h425
								wChar = &h445
							Case &h426
								wChar = &h446
							Case &h427
								wChar = &h447
							Case &h428
								wChar = &h448
							Case &h429
								wChar = &h449
							Case &h42A
								wChar = &h44A
							Case &h42B
								wChar = &h44B
							Case &h42C
								wChar = &h44C
							Case &h42D
								wChar = &h44D
							Case &h42E
								wChar = &h44E
							Case &h42F
								wChar = &h44F
						End Select
					Else
						Select Case wChar
							Case &h451 ' Ё
								wChar = &h401
							Case &h430 ' А
								wChar = &h410
							Case &h431
								wChar = &h411
							Case &h432
								wChar = &h412
							Case &h433
								wChar = &h413
							Case &h434
								wChar = &h414
							Case &h435
								wChar = &h415
							Case &h436
								wChar = &h416
							Case &h437
								wChar = &h417
							Case &h438
								wChar = &h418
							Case &h439
								wChar = &h419
							Case &h43A
								wChar = &h41A
							Case &h43B
								wChar = &h41B
							Case &h43C
								wChar = &h41C
							Case &h43D
								wChar = &h41D
							Case &h43E
								wChar = &h41E
							Case &h43F
								wChar = &h41F
							Case &h440
								wChar = &h420
							Case &h441
								wChar = &h421
							Case &h442
								wChar = &h422
							Case &h443
								wChar = &h423
							Case &h444
								wChar = &h424
							Case &h445
								wChar = &h425
							Case &h446
								wChar = &h426
							Case &h447
								wChar = &h427
							Case &h448
								wChar = &h428
							Case &h449
								wChar = &h429
							Case &h44A
								wChar = &h42A
							Case &h44B
								wChar = &h42B
							Case &h44C
								wChar = &h42C
							Case &h44D
								wChar = &h42D
							Case &h44E
								wChar = &h42E
							Case &h44F
								wChar = &h42F
						End Select
					End If
					wParam[i] = wChar
				Next
				SleepEx(MessageTimeWait, 0)
				eData->objClient.SendIrcMessage(Channel, wParam)
			End If
		End If
		Return True
	End If
	
	' Справка !справка
	If lstrcmp(MessageText, @HelpCommand) = 0 Then
		SleepEx(MessageTimeWait, 0)
		eData->objClient.SendIrcMessage(Channel, @AllUserCommands1)
		eData->objClient.SendIrcMessage(Channel, @AllUserCommands2)
		Return True
	End If
	
	' Графика ASCII !ascii
	If StartsWith(MessageText, @AsciiCommand) Then
		Dim wParam As WString Ptr = StrChr(MessageText, WhiteSpaceChar)
		If wParam <> 0 Then
			Dim hFile As HANDLE = CreateFile(@AsciiFileName, GENERIC_READ, FILE_SHARE_READ, NULL, OPEN_EXISTING, FILE_ATTRIBUTE_NORMAL, NULL)
			If hFile <> INVALID_HANDLE_VALUE Then
				
				wParam += 1
				If lstrlen(wParam) <> 0 Then
					
					Const MaxBufferLength As Integer = 65535
					
					' Буфер для хранения данных чтения
					Dim Buffer As ZString * (MaxBufferLength + SizeOf(WString)) = Any
					
					' Читаем данные файла
					Dim ReadBytesCount As DWORD = Any
					If ReadFile(hFile, @Buffer, MaxBufferLength, @ReadBytesCount, 0) <> 0 Then
						' Ставим нулевой символ, чтобы строка была валидной
						Buffer[ReadBytesCount] = 0
						Buffer[ReadBytesCount + 1] = 0
						
						' Будем считать, что кодировка текста UTF-16 с меткой BOM
						If ReadBytesCount > 2 Then
							If Buffer[0] = 255 AndAlso Buffer[1] = 254 Then
								
								Dim wLine As WString Ptr = CPtr(WString Ptr, @Buffer[2])
								Dim ReadedBytesCount As Integer = 0
								Dim Result2 As Integer = 1
								
								' Флаг того, что фразу нашли
								Dim FindFlag As Boolean = False
								
								Do
									
									' Найти в буфере CrLf
									Dim wCrLf As WString Ptr = StrStr(wLine, @vbCrLf)
									Do While wCrLf = NULL
										' Проверить буфер на переполнение
										If ReadedBytesCount >= MaxBufferLength Then
											' Буфер заполнен, будем читать данные в следующий раз
											Buffer[MaxBufferLength] = 0
											Buffer[MaxBufferLength + 1] = 0
											Exit Do
										End If
										
										' Если CrLf в буфере нет, то читать данные с файла
										Result2 = ReadFile(hFile, @Buffer + ReadedBytesCount, MaxBufferLength - ReadedBytesCount, @ReadBytesCount, 0)
										If Result2 = 0 OrElse ReadBytesCount = 0 Then
											' Ошибка или данные прочитаны, выйти
											Exit Do
										End If
										
										' Прочитанный байт всего
										ReadedBytesCount += ReadBytesCount
										' Ставим нулевой символ, чтобы строка была валидной
										Buffer[ReadBytesCount] = 0
										Buffer[ReadBytesCount + 1] = 0
										' Искать CrLf заново
										wCrLf = StrStr(wLine, @vbCrLf)
									Loop
									' CrLf найдено
									If wCrLf <> 0 Then
										wCrLf[0] = 0
									End If
									
									If FindFlag Then
										' Если пустая строка, то выйти из цикла
										If lstrlen(wLine) = 0 Then
											Exit Do
										End If
										
										' Отправить строку в чат
										SleepEx(MessageTimeWait, 0)
										eData->objClient.SendIrcMessage(Channel, wLine)
									End If
									
									' Сравнить со строкой
									If lstrcmp(wParam, wLine) = 0 Then
										' Найдено, теперь нужно отобразить в чат
										FindFlag = True
									End If
									
									' Переместить правее CrLf
									If wCrLf <> 0 Then
										wLine = wCrLf + 2
										' Передвинуть данные в буфере влево
										Dim tmpBuffer As ZString * (MaxBufferLength + SizeOf(WString)) = Any
										lstrcpy(CPtr(WString Ptr, @tmpBuffer), wLine)
										lstrcpy(CPtr(WString Ptr, @Buffer), CPtr(WString Ptr, @tmpBuffer))
										wLine = CPtr(WString Ptr, @Buffer)
									End If
									
									ReadedBytesCount = 0
								Loop While Result2 <> 0 And ReadBytesCount <> 0						
								
							End If
						End If
					End If
				End If
			End If
			' Закрытие
			CloseHandle(hFile)
		End If
		Return True
	End If
	
	' Команда !жуйк текст
	If StartsWith(MessageText, @JuickCommand) Then
		SleepEx(MessageTimeWait, 0)
		eData->objClient.SendIrcMessage(Channel, @JuickCommandDone)
		Return True
	End If
	
	' Команда «чат, скажи:»
	Scope
		Dim ChatSayTextCommandLength As Integer = Any
		If StartsWith(MessageText, ChatSayTextCommand1) Then
			ChatSayTextCommandLength = 12
		Else
			If StartsWith(MessageText, ChatSayTextCommand2) Then
				ChatSayTextCommandLength = 5
			Else
				ChatSayTextCommandLength = 0
			End If
		End If
		
		If ChatSayTextCommandLength > 0 Then
			' Чат, скажи: ааа или ввв
			' Найти « или »
			Dim wOrString As WString Ptr = StrStrI(MessageText + ChatSayTextCommandLength, " или ")
			If wOrString <> 0 Then
				' Удалить пробел перед «или»
				wOrString[0] = 0
				
				Dim Buffer As WString * (IrcClient.MaxBytesCount + 1) = Any
				
				' Фраза «сделай»
				Scope
					Dim Number As Integer = rand() Mod 10
					Select Case Number
						Case 0
							lstrcpy(@Buffer, "Конечно же ")
						Case 1
							lstrcpy(@Buffer, "Обязательно ")
						Case 2
							lstrcpy(@Buffer, "Наверное ")
						Case 3
							lstrcpy(@Buffer, "Не знаю насчёт ")
						Case 4
							lstrcpy(@Buffer, "Ни в коем случае не ")
						Case 5
							lstrcpy(@Buffer, "Было бы странным ")
						Case 6
							lstrcpy(@Buffer, "Тебя засмеют, если ")
						Case 7
							lstrcpy(@Buffer, "Ящитаю, что ")
						Case 8
							lstrcpy(@Buffer, "Мне нравится ")
						Case 9
							lstrcpy(@Buffer, "Ты зашкваришься, если ")
					End Select
				End Scope
				
				' Фраза из вопроса пользователя
				Scope
					Dim Number As Integer = rand() Mod 2
					
					Select Case Number
						Case 0
							lstrcat(@Buffer, MessageText + ChatSayTextCommandLength)
							
						Case 1
							' Удалить знак вопроса
							Dim wQuestionMark As WString Ptr = StrChr(wOrString + 5, QuestionMarkChar)
							If wQuestionMark <> 0 Then
								wQuestionMark[0] = 0
							End If
							lstrcat(@Buffer, wOrString + 5)
							
					End Select
					
					lstrcat(@Buffer, ".")
				End Scope
				
				SleepEx(MessageTimeWait, 0)
				eData->objClient.SendIrcMessage(Channel, @Buffer)
				Return True
			End If
		End If
	End Scope
	
	' Команда !таймер время сообщение
	If StartsWith(MessageText, @TimerCommand) Then
		Dim wSpace1 As WString Ptr = StrChr(MessageText, WhiteSpaceChar)
		If wSpace1 = 0 Then
			Return True
		End If
		wSpace1[0] = 0
		wSpace1 += 1
		
		Dim wSpace2 As WString Ptr = StrChr(wSpace1, WhiteSpaceChar)
		If wSpace2 = 0 Then
			Return True
		End If
		wSpace2[0] = 0
		wSpace2 += 1
		
		' Проверить параметры
		Dim Seconds As LongInt = wtoi(wSpace1)
		If Seconds > 0 AndAlso Seconds <= 3600 Then
			Dim TimerName As WString * (IrcClient.MaxBytesCount + 1) = Any
			lstrcpy(@TimerName, "IrcBotTimers")
			lstrcat(@TimerName, User)
			
			' Выделить память
			Dim hMapFile As Handle = CreateFileMapping(INVALID_HANDLE_VALUE, 0, PAGE_READWRITE, 0, SizeOf(TimerThreadParam), @TimerName)
			If hMapFile <> NULL Then
				
				If GetLastError() <> ERROR_ALREADY_EXISTS Then
					
					Dim ttp As TimerThreadParam Ptr = CPtr(TimerThreadParam Ptr, MapViewOfFile(hMapFile, FILE_MAP_ALL_ACCESS, 0, 0, SizeOf(TimerThreadParam)))
					If ttp <> 0 Then
						ttp->Interval = 1000 * Seconds
						ttp->hMapFile = hMapFile
						ttp->eData = eData
						lstrcpy(ttp->UserName, Channel)
						lstrcpy(ttp->TextToSend, User)
						lstrcat(ttp->TextToSend, ":")
						
						If StrStrI(wSpace2, "http") <> 0 Then
							lstrcat(ttp->TextToSend, " Таймер сработал")
						Else
							If StrStrI(wSpace2, "www.") <> 0 Then
								lstrcat(ttp->TextToSend, " Таймер сработал")
							Else
								lstrcat(ttp->TextToSend, wSpace2)
							End If
						End If
						
						Dim hThread As Handle = CreateThread(NULL, 0, @TimerAPCProc, ttp, 0, 0)
						If hThread <> NULL Then
							CloseHandle(hThread)
							eData->objClient.SendIrcMessage(Channel, @CommandDone)
						Else
							UnmapViewOfFile(ttp)
							CloseHandle(hMapFile)
							SleepEx(MessageTimeWait, 0)
							eData->objClient.SendIrcMessage(Channel, @"Не могу создать поток ожидания таймера")
						End If
					Else
						CloseHandle(hMapFile)
						SleepEx(MessageTimeWait, 0)
						eData->objClient.SendIrcMessage(Channel, @"Не могу выделить память")
					End If
				Else
					CloseHandle(hMapFile)
				End If
			Else
				SleepEx(MessageTimeWait, 0)
				eData->objClient.SendIrcMessage(Channel, @"Не могу создать отображение файла")
			End If
		Else
			SleepEx(MessageTimeWait, 0)
			eData->objClient.SendIrcMessage(Channel, @"Интервал времени должен быть в диапазоне [1, 3600]")
		End If
		Return True
	End If
	
	' Статистика
	If lstrcmp(MessageText, @StatsCommand) = 0 Then
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
					ttp->eData = eData
					lstrcpy(ttp->UserName, User)
					lstrcpy(ttp->Channel, Channel)
					
					Dim hThread As Handle = CreateThread(NULL, 0, @StatisticWordCount, ttp, 0, 0)
					If hThread <> NULL Then
						CloseHandle(hThread)
					Else
						UnmapViewOfFile(ttp)
						CloseHandle(hMapFile)
						SleepEx(MessageTimeWait, 0)
						eData->objClient.SendIrcMessage(Channel, @"Не могу создать поток получения статистики")
					End If
				Else
					CloseHandle(hMapFile)
					SleepEx(MessageTimeWait, 0)
					eData->objClient.SendIrcMessage(Channel, @"Не могу выделить память")
				End If
			Else
				CloseHandle(hMapFile)
			End If
		Else
			SleepEx(MessageTimeWait, 0)
			eData->objClient.SendIrcMessage(Channel, @"Не могу создать отображение файла")
		End If
		Return True
	End If
	
	' Добавление админа в список
	If lstrcmp(MessageText, @UserWhoIsCommand) = 0 Then
		Dim Buffer As WString * (IrcClient.MaxBytesCount + 1) = Any
		lstrcpy(@Buffer, "WHOIS ")
		lstrcat(@Buffer, User)
		eData->objClient.SendRawMessage(@Buffer)
		Return True
	End If
	
	' Игра крестики‐нолики
	
	' Игра в карты
	
	' Проверка заголовков какого‐нибудь http‐сервера
	
End Function