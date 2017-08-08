#include once "Bot.bi"
#include once "IntegerToWString.bi"
#include once "win\tlhelp32.bi"
#include once "ProcessMemoryInfo.bi"

Const AsciiFileName = "ascii.txt"

Function ProcessUserCommand(ByVal eData As AdvancedData Ptr, ByVal User As WString Ptr, ByVal MessageText As WString Ptr)As Boolean
	' Разбить текст по пробелам
	Dim WordsCount As Long = Any
	Dim Lines As WString Ptr Ptr = CommandLineToArgvW(MessageText, @WordsCount)
	
	' Справка !справка
	If lstrcmp(Lines[0], @HelpCommand) = 0 Then
		eData->objClient.SendIrcMessage(User, @AllUserCommands)
	End If
	
	' Графика ASCII !ascii
	If lstrcmp(Lines[0], @AsciiCommand) = 0 Then
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
										eData->objClient.SendIrcMessage(User, wLine)
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
		ProcessUserCommand = True
	End If
	
	' Команда !процессы
	If lstrcmp(Lines[0], @ProcessesListCommand) = 0 Then
		' Показать список всех процессов
		Dim hProcessSnap As HANDLE = CreateToolhelp32Snapshot(TH32CS_SNAPPROCESS, 0)
		If hProcessSnap = INVALID_HANDLE_VALUE Then
			eData->objClient.SendIrcMessage(User, @"Не могу создать список процессов")
		Else
			Dim pe32 As PROCESSENTRY32 = Any
			pe32.dwSize = SizeOf(PROCESSENTRY32)
			If Process32First(hProcessSnap, @pe32) = 0 Then
				eData->objClient.SendIrcMessage(User, @"Ошибка в функции Process32First")
			Else
				Do
					' Идентификатор процесса
					Dim strProcessID As WString * 100 = Any
					itow(pe32.th32ProcessID, @strProcessID, 10)
					
					' Имя исполняемого файла
					Dim strProcessName As WString * (IrcClient.MaxBytesCount + 1) = Any
					lstrcpy(@strProcessName, @pe32.szExeFile)
					lstrcat(@strProcessName, @" ")
					lstrcat(@strProcessName, @strProcessID)
					
					eData->objClient.SendIrcMessage(User, @strProcessName)
					SleepEx(MessageTimeWait, 0)
				Loop While Process32Next(hProcessSnap, @pe32) <> 0
			End If
			CloseHandle(hProcessSnap)
		End If
		ProcessUserCommand = True
	End If
	
	' Команда !память ID процесса
	If lstrcmp(Lines[0], @ProcessInfoCommand) = 0 Then
		' Вывести информацию о процессе
		Dim ProcessData As ProcessMemoryInfo = Any
		If WordsCount = 1 Then
			Dim osMemory As MEMORYSTATUSEX = Any
			osMemory.dwLength = SizeOf(MEMORYSTATUSEX)
			
			If GlobalMemoryStatusEx(@osMemory) <> 0 Then
				Dim strCounter As WString * (IrcClient.MaxBytesCount + 1) = Any
				
				Scope
					Dim strNumber As WString * 256 = Any
					i64tow(osMemory.dwMemoryLoad, @strNumber, 10)
					lstrcpy(@strCounter, "% используется ")
					lstrcat(@strCounter, @strNumber)
					eData->objClient.SendIrcMessage(User, @strCounter)
					SleepEx(MessageTimeWait, 0)
				End Scope
				
				Scope
					Dim strNumber As WString * 256 = Any
					i64tow(osMemory.ullTotalPhys, @strNumber, 10)
					lstrcpy(@strCounter, "Физическая память всего ")
					lstrcat(@strCounter, @strNumber)
					eData->objClient.SendIrcMessage(User, @strCounter)
					SleepEx(MessageTimeWait, 0)
				End Scope
				
				Scope
					Dim strNumber As WString * 256 = Any
					i64tow(osMemory.ullAvailPhys, @strNumber, 10)
					lstrcpy(@strCounter, "Физическая память доступно ")
					lstrcat(@strCounter, @strNumber)
					eData->objClient.SendIrcMessage(User, @strCounter)
					SleepEx(MessageTimeWait, 0)
				End Scope
				
				Scope
					Dim strNumber As WString * 256 = Any
					i64tow(osMemory.ullTotalPageFile, @strNumber, 10)
					lstrcpy(@strCounter, "Файл подкачки всего ")
					lstrcat(@strCounter, @strNumber)
					eData->objClient.SendIrcMessage(User, @strCounter)
					SleepEx(MessageTimeWait, 0)
				End Scope
				Scope
					Dim strNumber As WString * 256 = Any
					i64tow(osMemory.ullAvailPageFile, @strNumber, 10)
					lstrcpy(@strCounter, "Файл подкачки доступно ")
					lstrcat(@strCounter, @strNumber)
					eData->objClient.SendIrcMessage(User, @strCounter)
					SleepEx(MessageTimeWait, 0)
				End Scope
				
				Scope
					Dim strNumber As WString * 256 = Any
					i64tow(osMemory.ullTotalVirtual, @strNumber, 10)
					lstrcpy(@strCounter, "Виртуальная память всего ")
					lstrcat(@strCounter, @strNumber)
					eData->objClient.SendIrcMessage(User, @strCounter)
					SleepEx(MessageTimeWait, 0)
				End Scope
				
				Scope
					Dim strNumber As WString * 256 = Any
					i64tow(osMemory.ullAvailVirtual, @strNumber, 10)
					lstrcpy(@strCounter, "Виртуальная память доступно ")
					lstrcat(@strCounter, @strNumber)
					eData->objClient.SendIrcMessage(User, @strCounter)
					SleepEx(MessageTimeWait, 0)
				End Scope
				
			End If
			
		Else
			
			If GetMemoryInfo(@ProcessData, wtoi(Lines[1])) Then
				Dim strCounter As WString * (IrcClient.MaxBytesCount + 1) = Any
				
				lstrcpy(@strCounter, "Ошибок страниц ")
				lstrcat(@strCounter, ProcessData.PageFaultCount)
				eData->objClient.SendIrcMessage(User, @strCounter)
				SleepEx(MessageTimeWait, 0)
				
				lstrcpy(@strCounter, "Рабочее множество ")
				lstrcat(@strCounter, ProcessData.WorkingSetSize)
				eData->objClient.SendIrcMessage(User, @strCounter)
				SleepEx(MessageTimeWait, 0)
				
				lstrcpy(@strCounter, "Пик рабочего множества ")
				lstrcat(@strCounter, ProcessData.PeakWorkingSetSize)
				eData->objClient.SendIrcMessage(User, @strCounter)
				SleepEx(MessageTimeWait, 0)
				
				lstrcpy(@strCounter, "Виртуальная память ")
				lstrcat(@strCounter, ProcessData.PagefileUsage)
				eData->objClient.SendIrcMessage(User, @strCounter)
				SleepEx(MessageTimeWait, 0)
				
				lstrcpy(@strCounter, "Пик виртуальной памяти ")
				lstrcat(@strCounter, ProcessData.PeakPagefileUsage)
				eData->objClient.SendIrcMessage(User, @strCounter)
				SleepEx(MessageTimeWait, 0)
				
				lstrcpy(@strCounter, "Собственные байты ")
				lstrcat(@strCounter, ProcessData.PrivateUsage)
				eData->objClient.SendIrcMessage(User, @strCounter)
				SleepEx(MessageTimeWait, 0)
			Else
				eData->objClient.SendIrcMessage(User, @"Не могу получить информацию о процессе")
			End If
		End If
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