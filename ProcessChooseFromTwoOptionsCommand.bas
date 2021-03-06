#include once "ProcessChooseFromTwoOptionsCommand.bi"
#include once "CharConstants.bi"

Sub ProcessChooseFromTwoOptionsCommand( _
		ByVal pBot As IrcBot Ptr, _
		ByVal User As WString Ptr, _
		ByVal Channel As WString Ptr, _
		ByVal MessageText As WString Ptr _
	)
	Dim ChatSayTextCommandLength As Integer = 5
	If StrStrI(MessageText, "http") <> 0 Then
		Exit Sub
	End If
	
	' Чат, скажи: ааа или ввв
	' Найти « или »
	Dim wOrString As WString Ptr = StrStrI(MessageText + ChatSayTextCommandLength, " или ")
	If wOrString = 0 Then
		Exit Sub
	End If
	
	' Удалить пробел перед «или»
	wOrString[0] = 0
	
	Dim Buffer As WString * (IrcClient.MaxBytesCount + 1) = Any
	
	' Фраза «сделай»
	Select Case pBot->ReceivedRawMessagesCounter Mod 10
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
	
	' Фраза из вопроса пользователя
	Select Case pBot->ReceivedRawMessagesCounter Mod 2
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
	
	pBot->Say(Channel, @Buffer)
End Sub
