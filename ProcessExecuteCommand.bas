#include once "ProcessExecuteCommand.bi"

Sub ProcessExecuteCommand( _
		ByVal pBot As IrcBot Ptr, _
		ByVal User As WString Ptr, _
		ByVal Channel As WString Ptr, _
		ByVal MessageText As WString Ptr _
	)
	Dim WordsCount As Long = Any
	Dim Lines As WString Ptr Ptr = CommandLineToArgvW(MessageText, @WordsCount)
	
	If WordsCount <= 2 Then
		pBot->Say(Channel, @"Недостаточно параметров для запуска приложения")
	Else
		ShellExecute(0, 0, Lines[1], Lines[2], 0, 0)
	End If
	
	LocalFree(Lines)
End Sub