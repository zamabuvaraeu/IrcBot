#include once "Bot.bi"
#include once "BotConfig.bi"
#include once "IntegerToWString.bi"
#include once "CharConstants.bi"
#include once "StringFunctions.bi"

Const AsciiFileName = "ascii.txt"

Type TimerThreadParam
	Dim Interval As Integer
	Dim eData As AdvancedData Ptr
	' Кому отправить сообщение
	Dim User As WString * (IrcClient.MaxBytesCount + 1)
	' Текст сообщения
	Dim TextToSend As WString * (IrcClient.MaxBytesCount + 1)
	
	Dim hMapFile As HANDLE
	Dim b As Any Ptr
	Dim hThread As Handle
End Type

Function TimerAPCProc(ByVal lpParam As LPVOID)As DWORD
	Dim ttp As TimerThreadParam Ptr = CPtr(TimerThreadParam Ptr, lpParam)
	Sleep_(ttp->Interval)
	ttp->eData->objClient.SendIrcMessage(ttp->User, ttp->TextToSend)
	
	CloseHandle(ttp->hThread)
	Dim hMapFile As Handle = ttp->hMapFile
	UnmapViewOfFile(ttp)
	CloseHandle(hMapFile)
	Return 0
End Function

Function ProcessUserCommand(ByVal eData As AdvancedData Ptr, ByVal User As WString Ptr, ByVal Channel As WString Ptr, ByVal MessageText As WString Ptr)As Boolean
	
	' Команда пинг .
	If StartsWith(MessageText, @PingCommand) Then
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
	
	' Справка !справка
	If StartsWith(MessageText, @HelpCommand) Then
		eData->objClient.SendIrcMessage(Channel, @AllUserCommands1)
		eData->objClient.SendIrcMessage(Channel, @AllUserCommands2)
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
										eData->objClient.SendIrcMessage(Channel, wLine)
										SleepEx(MessageTimeWait, 0)
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
						ttp->b = ttp
						ttp->eData = eData
						lstrcpy(ttp->User, Channel)
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
						
						ttp->hThread = CreateThread(NULL, 0, @TimerAPCProc, ttp, 0, 0)
						If ttp->hThread <> NULL Then
							eData->objClient.SendIrcMessage(Channel, @CommandDone)
						Else
							UnmapViewOfFile(ttp)
							CloseHandle(hMapFile)
							eData->objClient.SendIrcMessage(Channel, @"Не могу создать поток ожидания таймера")
						End If
					Else
						CloseHandle(hMapFile)
						eData->objClient.SendIrcMessage(Channel, @"Не могу выделить память")
					End If
				Else
					CloseHandle(hMapFile)
					Dim ErrorMsg As WString * (IrcClient.MaxBytesCount + 1) = Any
					lstrcpy(@ErrorMsg, "Таймер с именем ")
					lstrcat(@ErrorMsg, @TimerName)
					lstrcat(@ErrorMsg, @" уже существует")
					
					eData->objClient.SendIrcMessage(Channel, @ErrorMsg)
				End If
			Else
				eData->objClient.SendIrcMessage(Channel, @"Не могу создать отображение файла")
			End If
		Else
			eData->objClient.SendIrcMessage(Channel, @"Интервал времени должен быть в диапазоне [1, 3600]")
		End If
		Return True
	End If
	
	' Статистика
	If StartsWith(MessageText, @StatsCommand) Then
		' If WordsCount > 2 Then
		' End If
	End If
	
	' Игра крестики‐нолики
	
	' Игра в карты
	
	' Проверка заголовков какого‐нибудь http‐сервера
	
End Function