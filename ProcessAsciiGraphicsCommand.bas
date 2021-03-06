#include once "ProcessAsciiGraphicsCommand.bi"
#include once "CharConstants.bi"

Const AsciiFileName = "ascii.txt"

Sub ProcessAsciiGraphicsCommand( _
		ByVal pBot As IrcBot Ptr, _
		ByVal User As WString Ptr, _
		ByVal Channel As WString Ptr, _
		ByVal MessageText As WString Ptr _
	)
	Dim wSpace1 As WString Ptr = StrChr(MessageText, WhiteSpaceChar)
	If wSpace1 = 0 Then
		Exit Sub
	End If
	
	Dim AsciiPictureName As WString Ptr = wSpace1 + 1
	If lstrlen(AsciiPictureName) = 0 Then
		Exit Sub
	End If
	
	Dim hFile As HANDLE = CreateFile(@AsciiFileName, GENERIC_READ, FILE_SHARE_READ, NULL, OPEN_EXISTING, FILE_ATTRIBUTE_NORMAL, NULL)
	If hFile = INVALID_HANDLE_VALUE Then
		Exit Sub
	End If
	
	Const MaxBufferLength As Integer = 635
	
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
						pBot->SayWithTimeOut(Channel, wLine)
					End If
					
					' Сравнить со строкой
					If lstrcmp(AsciiPictureName, wLine) = 0 Then
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
	CloseHandle(hFile)
End Sub
