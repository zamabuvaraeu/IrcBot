#include once "Bot.bi"
#include once "IntegerToWString.bi"

Const AnswersDatabaseFileName = "Ответы.txt"

' Таблица ключевых фраз и ответов
Type QuestionAnswer
	' Ключевая фраза
	Dim Question As WString * 512
	' Количество ответов
	Dim AnswersCount As Integer
	' Список из 50 ответов
	Dim Answers(49) As WString * 512
End Type

' Ответить на сообщение
Sub AnswerToChat(ByVal eData As AdvancedData Ptr, ByVal User As WString Ptr, ByVal MessageText As WString Ptr)
	' Открыть файл, прочитать
	Dim hFile As HANDLE = CreateFile(@AnswersDatabaseFileName, GENERIC_READ, FILE_SHARE_READ, NULL, OPEN_EXISTING, FILE_ATTRIBUTE_NORMAL, NULL)
	If hFile <> INVALID_HANDLE_VALUE Then
		' Вопрос‐ответ
		Dim qa As QuestionAnswer = Any
		Dim BytesCount As DWORD = Any
		Dim result As Integer = ReadFile(hFile, @qa, SizeOf(QuestionAnswer), @BytesCount, 0)
		
		' Читать до тех пор, пока не будет ошибки
		Do While result <> 0
			If BytesCount <> SizeOf(QuestionAnswer) Then
				Exit Do
			End If
			' Найти ключевую фразу
			If StrStr(MessageText, qa.Question) <> 0 Then
				' Получить ответ
				If qa.AnswersCount > 0 Then
					' Отправить пользователю случайную
					Dim AnswerIndex As Integer = rand() Mod qa.AnswersCount
					eData->objClient.SendIrcMessage(User, @qa.Answers(AnswerIndex))
				End If
				Exit Do
			End If
			result = ReadFile(hFile, @qa, SizeOf(QuestionAnswer), @BytesCount, 0)
		Loop
		
		' Закрытие
		CloseHandle(hFile)
	End If
End Sub

' Получить список ключевых фраз
Sub GetQuestionList(ByVal eData As AdvancedData Ptr, ByVal User As WString Ptr)
	' Открыть файл, прочитать
	Dim hFile As HANDLE = CreateFile(@AnswersDatabaseFileName, GENERIC_READ, FILE_SHARE_READ, NULL, OPEN_EXISTING, FILE_ATTRIBUTE_NORMAL, NULL)
	If hFile <> INVALID_HANDLE_VALUE Then
		' Вопрос‐ответ
		Dim qa As QuestionAnswer = Any
		Dim BytesCount As DWORD = Any
		Dim result As Integer = ReadFile(hFile, @qa, SizeOf(QuestionAnswer), @BytesCount, 0)
		Dim QuestionCount As Integer = 0
		
		' Читать до тех пор, пока не будет ошибки
		Do While result <> 0
			If BytesCount <> SizeOf(QuestionAnswer) Then
				Exit Do
			End If
			' Найти ключевую фразу
			If lstrlen(qa.Question) = 0 Then
				Exit Do
			End If
			
			' Номер фразы в строку
			Dim buf As WString * 100 = Any
			lstrcpy(@buf, @"Фраза ")
			itow(QuestionCount, @buf + lstrlen(@buf), 10)
			
			eData->objClient.SendIrcMessage(User, @buf)
			eData->objClient.SendIrcMessage(User, @qa.Question)
			
			' Задержка
			SleepEx(MessageTimeWait, 0)
			
			QuestionCount += 1
			result = ReadFile(hFile, @qa, SizeOf(QuestionAnswer), @BytesCount, 0)
		Loop
		
		' Закрытие
		CloseHandle(hFile)
	End If
End Sub

' Получить список ответов
Sub GetAnswerList(ByVal eData As AdvancedData Ptr, ByVal User As WString Ptr, ByVal QuestionIndex As Integer)
	' Открыть файл, прочитать
	Dim hFile As HANDLE = CreateFile(@AnswersDatabaseFileName, GENERIC_READ, FILE_SHARE_READ, NULL, OPEN_EXISTING, FILE_ATTRIBUTE_NORMAL, NULL)
	If hFile <> INVALID_HANDLE_VALUE Then
		' Вопрос‐ответ
		Dim qa As QuestionAnswer = Any
		Dim BytesCount As DWORD = Any
		Dim result As Integer = ReadFile(hFile, @qa, SizeOf(QuestionAnswer), @BytesCount, 0)
		Dim QuestionCount As Integer = 0
		
		' Читать до тех пор, пока не будет ошибки
		Do While result <> 0
			If BytesCount <> SizeOf(QuestionAnswer) Then
				Exit Do
			End If
			' Найти ключевую фразу
			If lstrlen(qa.Question) = 0 Then
				Exit Do
			End If
			If QuestionIndex = QuestionCount Then
				' Номер фразы в строку
				Dim buf As WString * 100 = Any
				lstrcpy(@buf, @"Фраза ")
				itow(QuestionCount, @buf + lstrlen(@buf), 10)
				
				eData->objClient.SendIrcMessage(User, @buf)
				eData->objClient.SendIrcMessage(User, @qa.Question)
				
				' Задержка
				SleepEx(MessageTimeWait, 0)
				
				For i As Integer = 0 To qa.AnswersCount - 1
					lstrcpy(@buf, @"Ответ ")
					itow(QuestionCount, @buf + lstrlen(@buf), 10)
					
					eData->objClient.SendIrcMessage(User, @buf)
					eData->objClient.SendIrcMessage(User, @qa.Answers(i))
					
					' Задержка
					SleepEx(MessageTimeWait, 0)
				Next
				
				Exit Do
			End If
			QuestionCount += 1
			result = ReadFile(hFile, @qa, SizeOf(QuestionAnswer), @BytesCount, 0)
		Loop
		
		' Закрытие
		CloseHandle(hFile)
	End If
End Sub

' Добавить ключевую фразу
Sub AddQuestion(ByVal eData As AdvancedData Ptr, ByVal User As WString Ptr, ByVal Question As WString Ptr)
	' Открыть файл, прочитать
	Dim hFile As HANDLE = CreateFile(@AnswersDatabaseFileName, GENERIC_WRITE, FILE_SHARE_READ, NULL, OPEN_ALWAYS, FILE_ATTRIBUTE_NORMAL, NULL)
	If hFile <> INVALID_HANDLE_VALUE Then
		SetFilePointer(hFile, 0, NULL, FILE_END)
		' Вопрос‐ответ
		Dim qa As QuestionAnswer = Any
		memset(@qa, 0, SizeOf(QuestionAnswer))
		
		lstrcpy(@qa.Question, Question)
		
		Dim BytesCount As DWORD = Any
		Dim result As Integer = WriteFile(hFile, @qa, SizeOf(QuestionAnswer), @BytesCount, 0)
		
		' Закрытие
		CloseHandle(hFile)
	End If
End Sub

Sub AddAnswer(ByVal eData As AdvancedData Ptr, ByVal User As WString Ptr, ByVal QuestionIndex As Integer, ByVal Answer As WString Ptr)
	' Открыть файл, прочитать
	Dim hFile As HANDLE = CreateFile(@AnswersDatabaseFileName, GENERIC_READ + GENERIC_WRITE, FILE_SHARE_READ, NULL, OPEN_ALWAYS, FILE_ATTRIBUTE_NORMAL, NULL)
	If hFile <> INVALID_HANDLE_VALUE Then
		Dim qa As QuestionAnswer = Any
		Dim BytesCount As DWORD = Any
		Dim result As Integer = ReadFile(hFile, @qa, SizeOf(QuestionAnswer), @BytesCount, 0)
		Dim QuestionCount As Integer = 0
		
		' Читать до тех пор, пока не будет ошибки
		Do While result <> 0
			If BytesCount <> SizeOf(QuestionAnswer) Then
				Exit Do
			End If
			' Найти ключевую фразу
			If lstrlen(qa.Question) = 0 Then
				Exit Do
			End If
			If QuestionIndex = QuestionCount Then
				lstrcpy(@qa.Answers(qa.AnswersCount), Answer)
				qa.AnswersCount += 1
				
				SetFilePointer(hFile, -SizeOf(QuestionAnswer), NULL, FILE_CURRENT)
				result = WriteFile(hFile, @qa, SizeOf(QuestionAnswer), @BytesCount, 0)
				
				Exit Do
			End If
			QuestionCount += 1
			result = ReadFile(hFile, @qa, SizeOf(QuestionAnswer), @BytesCount, 0)
		Loop
		
		' Закрытие
		CloseHandle(hFile)
	End If
End Sub
