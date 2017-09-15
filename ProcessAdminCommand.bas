#include once "Bot.bi"
#include once "DateTimeToString.bi"
#include once "IntegerToWString.bi"
#include once "CharConstants.bi"
#include once "Settings.bi"
#include once "win\tlhelp32.bi"
#include once "ProcessMemoryInfo.bi"

Type ProcessesThreadParam
	Dim eData As AdvancedData Ptr
	Dim UserName As WString * (IrcClient.MaxBytesCount + 1)
	
	Dim hMapFile As HANDLE
	Dim hThread As Handle
End Type

Function PrintProcesses(ByVal lpParam As LPVOID)As DWORD
	Dim ttp As ProcessesThreadParam Ptr = CPtr(ProcessesThreadParam Ptr, lpParam)
	
	Dim hProcessSnap As HANDLE = CreateToolhelp32Snapshot(TH32CS_SNAPPROCESS, 0)
	If hProcessSnap = INVALID_HANDLE_VALUE Then
		ttp->eData->objClient.SendIrcMessage(ttp->UserName, @"Не могу создать список процессов")
	Else
		Dim pe32 As PROCESSENTRY32 = Any
		pe32.dwSize = SizeOf(PROCESSENTRY32)
		If Process32First(hProcessSnap, @pe32) = 0 Then
			ttp->eData->objClient.SendIrcMessage(ttp->UserName, @"Ошибка в функции Process32First")
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
				
				ttp->eData->objClient.SendIrcMessage(ttp->UserName, @strProcessName)
				SleepEx(MessageTimeWait, 0)
			Loop While Process32Next(hProcessSnap, @pe32) <> 0
		End If
		CloseHandle(hProcessSnap)
	End If
	
	ttp->eData->objClient.SendIrcMessage(ttp->UserName, @CommandDone)
	
	Dim hMapFile As Handle = ttp->hMapFile
	UnmapViewOfFile(ttp)
	CloseHandle(hMapFile)
	Return 0
End Function

Function ProcessAdminCommand(ByVal eData As AdvancedData Ptr, ByVal User As WString Ptr, ByVal Channel As WString Ptr, ByVal MessageText As WString Ptr)As Boolean
	' Разбить текст по пробелам
	Dim WordsCount As Long = Any
	Dim Lines As WString Ptr Ptr = CommandLineToArgvW(MessageText, @WordsCount)
	
	' Справка !справка
	If lstrcmp(MessageText, @HelpCommand) = 0 Then
		eData->objClient.SendIrcMessage(Channel, @AllAdminCommands)
		ProcessAdminCommand = True
	End If
	
	' Команда !процессы
	If lstrcmp(MessageText, @ProcessesListCommand) = 0 Then
		Dim TimerName As WString * (IrcClient.MaxBytesCount + 1) = Any
		lstrcpy(@TimerName, "IrcBotProcessesList")
		lstrcat(@TimerName, User)
		
		Dim hMapFile As Handle = CreateFileMapping(INVALID_HANDLE_VALUE, 0, PAGE_READWRITE, 0, SizeOf(ProcessesThreadParam), @TimerName)
		If hMapFile <> NULL Then
			If GetLastError() <> ERROR_ALREADY_EXISTS Then
				Dim ttp As ProcessesThreadParam Ptr = CPtr(ProcessesThreadParam Ptr, MapViewOfFile(hMapFile, FILE_MAP_ALL_ACCESS, 0, 0, SizeOf(ProcessesThreadParam)))
				If ttp <> 0 Then
					ttp->hMapFile = hMapFile
					ttp->eData = eData
					lstrcpy(ttp->UserName, Channel)
					
					Dim hThread As Handle = CreateThread(NULL, 0, @PrintProcesses, ttp, 0, 0)
					If hThread <> NULL Then
						CloseHandle(hThread)
					Else
						UnmapViewOfFile(ttp)
						CloseHandle(hMapFile)
						eData->objClient.SendIrcMessage(Channel, @"Не могу создать поток получения процессов")
					End If
				Else
					CloseHandle(hMapFile)
					eData->objClient.SendIrcMessage(Channel, @"Не могу выделить память")
				End If
			Else
				CloseHandle(hMapFile)
				Dim ErrorMsg As WString * (IrcClient.MaxBytesCount + 1) = Any
				lstrcpy(@ErrorMsg, "Список процессов с именем ")
				lstrcat(@ErrorMsg, @TimerName)
				lstrcat(@ErrorMsg, @" уже существует")
				
				eData->objClient.SendIrcMessage(Channel, @ErrorMsg)
			End If
		Else
			eData->objClient.SendIrcMessage(Channel, @"Не могу создать отображение файла")
		End If
		ProcessAdminCommand = True
	End If
	
	' Команда !память ID процесса
	If lstrcmp(Lines[0], @ProcessInfoCommand) = 0 Then
		' Вывести информацию о процессе
		If WordsCount = 1 Then
			Dim osMemory As MEMORYSTATUSEX = Any
			osMemory.dwLength = SizeOf(MEMORYSTATUSEX)
			
			eData->objClient.SendIrcMessage(Channel, @"Память операционной системы")
			
			Dim strCounter As WString * (IrcClient.MaxBytesCount + 1) = Any

			If GlobalMemoryStatusEx(@osMemory) <> 0 Then
				
				Scope
					Dim strNumber As WString * 256 = Any
					i64tow(osMemory.dwMemoryLoad, @strNumber, 10)
					lstrcpy(@strCounter, @strNumber)
					lstrcat(@strCounter, "% используется ")
					eData->objClient.SendIrcMessage(Channel, @strCounter)
					SleepEx(MessageTimeWait, 0)
				End Scope
				
				Scope
					Dim strNumber As WString * 256 = Any
					i64tow(osMemory.ullTotalPhys, @strNumber, 10)
					lstrcpy(@strCounter, "Физическая память всего ")
					lstrcat(@strCounter, @strNumber)
					eData->objClient.SendIrcMessage(Channel, @strCounter)
					SleepEx(MessageTimeWait, 0)
				End Scope
				
				Scope
					Dim strNumber As WString * 256 = Any
					i64tow(osMemory.ullAvailPhys, @strNumber, 10)
					lstrcpy(@strCounter, "Физическая память свободно ")
					lstrcat(@strCounter, @strNumber)
					eData->objClient.SendIrcMessage(Channel, @strCounter)
					SleepEx(MessageTimeWait, 0)
				End Scope
				
				Scope
					Dim strNumber As WString * 256 = Any
					i64tow(osMemory.ullTotalPageFile, @strNumber, 10)
					lstrcpy(@strCounter, "Файл подкачки всего ")
					lstrcat(@strCounter, @strNumber)
					eData->objClient.SendIrcMessage(Channel, @strCounter)
					SleepEx(MessageTimeWait, 0)
				End Scope
				Scope
					Dim strNumber As WString * 256 = Any
					i64tow(osMemory.ullAvailPageFile, @strNumber, 10)
					lstrcpy(@strCounter, "Файл подкачки свободно ")
					lstrcat(@strCounter, @strNumber)
					eData->objClient.SendIrcMessage(Channel, @strCounter)
					SleepEx(MessageTimeWait, 0)
				End Scope
				
				Scope
					Dim strNumber As WString * 256 = Any
					i64tow(osMemory.ullTotalVirtual, @strNumber, 10)
					lstrcpy(@strCounter, "Виртуальная память всего ")
					lstrcat(@strCounter, @strNumber)
					eData->objClient.SendIrcMessage(Channel, @strCounter)
					SleepEx(MessageTimeWait, 0)
				End Scope
				
				Scope
					Dim strNumber As WString * 256 = Any
					i64tow(osMemory.ullAvailVirtual, @strNumber, 10)
					lstrcpy(@strCounter, "Виртуальная память доступно ")
					lstrcat(@strCounter, @strNumber)
					eData->objClient.SendIrcMessage(Channel, @strCounter)
					SleepEx(MessageTimeWait, 0)
				End Scope
				
			Else
				eData->objClient.SendIrcMessage(Channel, @"Не могу получить информацию о памяти системы через GlobalMemoryStatusEx")
			End If
			
			Dim pf As PERFORMANCE_INFORMATION
			pf.cb = SizeOf(PPERFORMANCE_INFORMATION)
			If GetPerformanceInfo(@pf, SizeOf(PPERFORMANCE_INFORMATION)) <> 0 Then
			
				Scope
					Dim strNumber As WString * 256 = Any
					i64tow(pf.CommitTotal, @strNumber, 10)
					lstrcpy(@strCounter, "CommitTotal ")
					lstrcat(@strCounter, @strNumber)
					eData->objClient.SendIrcMessage(Channel, @strCounter)
					SleepEx(MessageTimeWait, 0)
				End Scope
				
				Scope
					Dim strNumber As WString * 256 = Any
					i64tow(pf.CommitLimit, @strNumber, 10)
					lstrcpy(@strCounter, "CommitLimit ")
					lstrcat(@strCounter, @strNumber)
					eData->objClient.SendIrcMessage(Channel, @strCounter)
					SleepEx(MessageTimeWait, 0)
				End Scope
				
				Scope
					Dim strNumber As WString * 256 = Any
					i64tow(pf.CommitPeak, @strNumber, 10)
					lstrcpy(@strCounter, "CommitPeak ")
					lstrcat(@strCounter, @strNumber)
					eData->objClient.SendIrcMessage(Channel, @strCounter)
					SleepEx(MessageTimeWait, 0)
				End Scope
				
				Scope
					Dim strNumber As WString * 256 = Any
					i64tow(pf.PhysicalTotal, @strNumber, 10)
					lstrcpy(@strCounter, "PhysicalTotal ")
					lstrcat(@strCounter, @strNumber)
					eData->objClient.SendIrcMessage(Channel, @strCounter)
					SleepEx(MessageTimeWait, 0)
				End Scope
				
				Scope
					Dim strNumber As WString * 256 = Any
					i64tow(pf.PhysicalAvailable, @strNumber, 10)
					lstrcpy(@strCounter, "PhysicalAvailable ")
					lstrcat(@strCounter, @strNumber)
					eData->objClient.SendIrcMessage(Channel, @strCounter)
					SleepEx(MessageTimeWait, 0)
				End Scope
				
				Scope
					Dim strNumber As WString * 256 = Any
					i64tow(pf.SystemCache, @strNumber, 10)
					lstrcpy(@strCounter, "SystemCache ")
					lstrcat(@strCounter, @strNumber)
					eData->objClient.SendIrcMessage(Channel, @strCounter)
					SleepEx(MessageTimeWait, 0)
				End Scope
				
				Scope
					Dim strNumber As WString * 256 = Any
					i64tow(pf.KernelPaged, @strNumber, 10)
					lstrcpy(@strCounter, "KernelPaged ")
					lstrcat(@strCounter, @strNumber)
					eData->objClient.SendIrcMessage(Channel, @strCounter)
					SleepEx(MessageTimeWait, 0)
				End Scope
				
				Scope
					Dim strNumber As WString * 256 = Any
					i64tow(pf.KernelNonpaged, @strNumber, 10)
					lstrcpy(@strCounter, "KernelNonpaged ")
					lstrcat(@strCounter, @strNumber)
					eData->objClient.SendIrcMessage(Channel, @strCounter)
					SleepEx(MessageTimeWait, 0)
				End Scope
				
				Scope
					Dim strNumber As WString * 256 = Any
					i64tow(pf.KernelNonpaged, @strNumber, 10)
					lstrcpy(@strCounter, "KernelNonpaged ")
					lstrcat(@strCounter, @strNumber)
					eData->objClient.SendIrcMessage(Channel, @strCounter)
					SleepEx(MessageTimeWait, 0)
				End Scope
				
				Scope
					Dim strNumber As WString * 256 = Any
					i64tow(pf.PageSize, @strNumber, 10)
					lstrcpy(@strCounter, "PageSize ")
					lstrcat(@strCounter, @strNumber)
					eData->objClient.SendIrcMessage(Channel, @strCounter)
					SleepEx(MessageTimeWait, 0)
				End Scope
				
				Scope
					Dim strNumber As WString * 256 = Any
					i64tow(pf.HandleCount, @strNumber, 10)
					lstrcpy(@strCounter, "Манипуляторов ")
					lstrcat(@strCounter, @strNumber)
					eData->objClient.SendIrcMessage(Channel, @strCounter)
					SleepEx(MessageTimeWait, 0)
				End Scope
				
				Scope
					Dim strNumber As WString * 256 = Any
					i64tow(pf.ProcessCount, @strNumber, 10)
					lstrcpy(@strCounter, "Процессов ")
					lstrcat(@strCounter, @strNumber)
					eData->objClient.SendIrcMessage(Channel, @strCounter)
					SleepEx(MessageTimeWait, 0)
				End Scope
				
				Scope
					Dim strNumber As WString * 256 = Any
					i64tow(pf.ThreadCount, @strNumber, 10)
					lstrcpy(@strCounter, "Потоков ")
					lstrcat(@strCounter, @strNumber)
					eData->objClient.SendIrcMessage(Channel, @strCounter)
					SleepEx(MessageTimeWait, 0)
				End Scope
				
			Else
				Dim dwError As DWORD = GetLastError()
				Dim strNumber As WString * 256 = Any
				i64tow(pf.ThreadCount, @strNumber, 10)
				eData->objClient.SendIrcMessage(Channel, @"Не могу получить информацию о памяти системы через GetPerformanceInfo")
				eData->objClient.SendIrcMessage(Channel, @strNumber)
			End If
			
		Else
			
			Dim ProcessData As ProcessMemoryInfo = Any
			If GetMemoryInfo(@ProcessData, wtoi(Lines[1])) Then
				Dim strCounter As WString * (IrcClient.MaxBytesCount + 1) = Any
				
				lstrcpy(@strCounter, "Ошибок страниц ")
				lstrcat(@strCounter, ProcessData.PageFaultCount)
				eData->objClient.SendIrcMessage(Channel, @strCounter)
				SleepEx(MessageTimeWait, 0)
				
				lstrcpy(@strCounter, "Рабочее множество ")
				lstrcat(@strCounter, ProcessData.WorkingSetSize)
				eData->objClient.SendIrcMessage(Channel, @strCounter)
				SleepEx(MessageTimeWait, 0)
				
				lstrcpy(@strCounter, "Пик рабочего множества ")
				lstrcat(@strCounter, ProcessData.PeakWorkingSetSize)
				eData->objClient.SendIrcMessage(Channel, @strCounter)
				SleepEx(MessageTimeWait, 0)
				
				lstrcpy(@strCounter, "Виртуальная память ")
				lstrcat(@strCounter, ProcessData.PagefileUsage)
				eData->objClient.SendIrcMessage(Channel, @strCounter)
				SleepEx(MessageTimeWait, 0)
				
				lstrcpy(@strCounter, "Пик виртуальной памяти ")
				lstrcat(@strCounter, ProcessData.PeakPagefileUsage)
				eData->objClient.SendIrcMessage(Channel, @strCounter)
				SleepEx(MessageTimeWait, 0)
				
				lstrcpy(@strCounter, "Собственные байты ")
				lstrcat(@strCounter, ProcessData.PrivateUsage)
				eData->objClient.SendIrcMessage(Channel, @strCounter)
				SleepEx(MessageTimeWait, 0)
			Else
				eData->objClient.SendIrcMessage(Channel, @"Не могу получить информацию о процессе")
			End If
		End If
		ProcessAdminCommand = True
	End If
	
	' Выход из сети !сгинь причина выхода из сети
	If lstrcmp(Lines[0], @QuitCommand) = 0 Then
		If WordsCount > 1 Then
			Dim w As WString Ptr = StrChr(MessageText, WhiteSpaceChar)
			eData->objClient.QuitFromServer(@w[1])
		Else
			Dim strQuitString As WString * SizeOf(WString)
			eData->objClient.QuitFromServer(@strQuitString)
		End If
		ExitProcess(0)
		' ProcessAdminCommand = True
	End If
	
	' Смена ника !ник новый ник
	If lstrcmp(Lines[0], @NickCommand) = 0 Then
		eData->objClient.ChangeNick(Lines[1])
		eData->objClient.SendIrcMessage(Channel, @CommandDone)
		ProcessAdminCommand = True
	End If
	
	' Присоединение к каналу !зайди channel
	If lstrcmp(Lines[0], @JoinCommand) = 0 Then
		eData->objClient.JoinChannel(Lines[1])
		eData->objClient.SendIrcMessage(Channel, @CommandDone)
		ProcessAdminCommand = True
	End If
	
	' Отключение от канала !выйди channel причина выхода
	If lstrcmp(Lines[0], @PartCommand) = 0 Then
		If WordsCount > 2 Then
			Dim w As WString Ptr = StrChr((StrChr(MessageText, WhiteSpaceChar))[1], WhiteSpaceChar)
			eData->objClient.PartChannel(Lines[1], @w[1])
		Else
			Dim strQuitString As WString * SizeOf(WString)
			eData->objClient.PartChannel(Lines[1], @strQuitString)
		End If
		eData->objClient.SendIrcMessage(Channel, @CommandDone)
		ProcessAdminCommand = True
	End If
	
	' Смена темы канала !тема канал новая тема канала
	If lstrcmp(Lines[0], @TopicCommand) = 0 Then
		If WordsCount > 2 Then
			Dim w As WString Ptr = StrChr((StrChr(MessageText, WhiteSpaceChar))[1], WhiteSpaceChar)
			eData->objClient.ChangeTopic(Lines[1], @w[1])
		Else
			' Очистить тему
		End If
		eData->objClient.SendIrcMessage(Channel, @CommandDone)
		ProcessAdminCommand = True
	End If
	
	' Сырое сообщение !ну текст
	If lstrcmp(Lines[0], @RawCommand) = 0 Then
		If WordsCount > 1 Then
			Dim w As WString Ptr = StrChr(MessageText, WhiteSpaceChar)
			eData->objClient.SendRawMessage(@w[1])
			eData->objClient.SendIrcMessage(Channel, @CommandDone)
		End If
		ProcessAdminCommand = True
	End If
	
	' Установить пароль на никсерв !пароль текст
	If lstrcmp(Lines[0], @PasswordCommand) = 0 Then
		If WordsCount > 1 Then
			Dim w As WString Ptr = StrChr(MessageText, WhiteSpaceChar)
			If SetSettingsValue(@PasswordKey, w) Then
				eData->objClient.SendIrcMessage(Channel, @CommandDone)
			End If
		End If
		ProcessAdminCommand = True
	End If
	
	' Сказать в чат !скажи канал текст сообщения
	If lstrcmp(Lines[0], @SayCommand) = 0 Then
		If WordsCount > 2 Then
			Dim w As WString Ptr = StrChr((StrChr(MessageText, WhiteSpaceChar))[1], WhiteSpaceChar)
			eData->objClient.SendIrcMessage(Lines[1], @w[1])
			eData->objClient.SendIrcMessage(Channel, @CommandDone)
		End If
		ProcessAdminCommand = True
	End If
	
	' Выполнить программу !делай "команда" "параметры"
	If lstrcmp(Lines[0], @ExecuteCommand) = 0 Then
		REM ShellExecute(0, command, filename, param, dir, show_cmd)
		If WordsCount > 2 Then
			ShellExecute(0, 0, Lines[1], Lines[2], 0, 0)
		Else
			eData->objClient.SendIrcMessage(Channel, @"Недостаточно параметров для запуска приложения")
		End If
		ProcessAdminCommand = True
	End If
	
	' Команда !считай текст
	If lstrcmp(Lines[0], @CalculateCommand) = 0 Then
		If WordsCount > 1 Then
			Dim wCalc As WString Ptr = @(StrChr(MessageText, WhiteSpaceChar))[1]
			' Создать файл, записать в него текст
			' Print 
			' Скомпилировать
			' Создать процесс, перенаправить вывод к себе
			' Отправить вывод в чат
		Else
			Dim strQuitString As WString * SizeOf(WString)
			' eData->objClient.QuitFromServer(@strQuitString)
		End If
		ProcessAdminCommand = True
	End If
	
	' Показать список ключевых фраз !вопросы
	If lstrcmp(Lines[0], @QuestionListCommand) = 0 Then
		GetQuestionList(eData, Channel)
		ProcessAdminCommand = True
	End If
	
	' Добавить ключевую фразу !вопрос фраза
	If lstrcmp(Lines[0], @AddQuestionCommand) = 0 Then
		If WordsCount > 1 Then
			Dim w As WString Ptr = StrChr(MessageText, WhiteSpaceChar)
			AddQuestion(eData, Channel, @w[1])
		End If
		eData->objClient.SendIrcMessage(Channel, @CommandDone)
		ProcessAdminCommand = True
	End If
	
	' Добавить ответ !ответ номер‐вопроса фраза
	If lstrcmp(Lines[0], @AddAnswerCommand) = 0 Then
		If WordsCount > 2 Then
			Dim w As WString Ptr = StrChr((StrChr(MessageText, WhiteSpaceChar))[1], WhiteSpaceChar)
			AddAnswer(eData, Channel, wtoi(Lines[1]), @w[1])
		End If
		eData->objClient.SendIrcMessage(Channel, @CommandDone)
		ProcessAdminCommand = True
	End If
	
	' Показать список ключевых фраз
	If lstrcmp(Lines[0], @QuestionListCommand) = 0 Then
		GetQuestionList(eData, Channel)
		ProcessAdminCommand = True
	End If
	
	' Показать список ответов
	' Const  = "!ответы"
	If lstrcmp(Lines[0], @AnswerListCommand) = 0 Then
		If WordsCount > 1 Then
			GetAnswerList(eData, Channel, wtoi(Lines[1]))
		End If
		ProcessAdminCommand = True
	End If
	
	LocalFree(Lines)
End Function
