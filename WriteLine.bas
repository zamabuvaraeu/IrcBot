#include once "WriteLine.bi"
#include once "CharConstants.bi"

Const MaxConsoleCharsCount As Integer = 32000

Function WriteLine(ByVal hOut As Handle, ByVal s As WString Ptr)As Integer
	Dim StringWithNewLine As WString * (MaxConsoleCharsCount + 1) = Any
	
	Dim intLength As DWORD = Cast(DWORD, lstrlen(lstrcat(lstrcpy(@StringWithNewLine, s), vbCrLf)))
	
	Dim CharsCount As DWORD = Any
	
	If WriteConsole(hOut, @StringWithNewLine, intLength, @CharsCount, 0) = 0 Then
		Dim Buffer As ZString * (MaxConsoleCharsCount) = Any
		
		Dim BytesCount As Integer = WideCharToMultiByte(GetConsoleOutputCP(), 0, @StringWithNewLine, -1, @Buffer, MaxConsoleCharsCount - 1, 0, NULL)
		
		WriteFile(hOut, @Buffer, BytesCount - 1, @CharsCount, 0)
	End If
	
	Return CharsCount
	
End Function
