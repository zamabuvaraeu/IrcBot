#include once "Settings.bi"

Const RegSection = "Software\Пакетные файлы\FreeBasicIrcBot"

Function EnumerateUserWords( _
		ByVal Channel As WString Ptr, _
		ByVal hHeap As Handle, _
		ByVal ValuesCount As DWORD Ptr _
	)As UserWords Ptr
	Dim RegSectionChannels As WString * 512 = Any
	lstrcpy(RegSectionChannels, RegSection)
	lstrcat(RegSectionChannels, Channel)
	
	Dim reg As HKEY = Any
	Dim lpdwDisposition As DWORD = Any
	Dim hr As Long = RegCreateKeyEx(HKEY_CURRENT_USER, @RegSectionChannels, 0, 0, 0, KEY_QUERY_VALUE + KEY_ENUMERATE_SUB_KEYS, NULL, @reg, @lpdwDisposition)
	
	If hr <> ERROR_SUCCESS Then
		Return 0
	End If
	
	Dim SubKeysCount As DWORD = Any
	Dim MaxSubKeyLength As DWORD = Any
	Dim MaxClassNameLength As DWORD = Any
	
	Dim MaxValueDataLength As DWORD = Any
	Dim MaxValueNameLength As DWORD = Any
	
	' Информация о разделе реестра
	hr = RegQueryInfoKey(reg, NULL, 0, 0, @SubKeysCount, @MaxSubKeyLength, @MaxClassNameLength, ValuesCount, @MaxValueNameLength, @MaxValueDataLength, NULL, 0)
	If hr <> ERROR_SUCCESS Then
		RegCloseKey(reg)
		Return 0
	End If
	
	Dim pdwType As DWORD = REG_DWORD
	Dim Buffer As DWORD = Any
	Dim BufferLength As DWORD = SizeOf(DWORD)
	
	Dim hMem As UserWords Ptr = HeapAlloc(hHeap, HEAP_NO_SERIALIZE, (*ValuesCount) * SizeOf(UserWords))
	If hMem = 0 Then
		RegCloseKey(reg)
		Return 0
	End If
	
	For i As DWORD = 0 To *ValuesCount - 1
		
		Dim UserName As WString * (511 + 1) = Any
		Dim UserNameLength As DWORD = (511 + 1) * SizeOf(WString)
		
		hr = RegEnumValue(reg, i, @UserName, @UserNameLength, 0, @pdwType, CPtr(Byte Ptr, @Buffer), @BufferLength)
		If hr = ERROR_SUCCESS Then
			lstrcpy(@hMem[i].UserName[0], @UserName)
			hMem[i].WordsCount = Buffer
		Else
			RegCloseKey(reg)
			Return 0
		End If
		
	Next
	
	RegCloseKey(reg)
	Return hMem
End Function

Function IncrementUserWords( _
		ByVal Channel As WString Ptr, _
		ByVal User As WString Ptr _
	)As Boolean
	Dim RegSectionChannels As WString * 512 = Any
	lstrcpy(RegSectionChannels, RegSection)
	lstrcat(RegSectionChannels, Channel)
	
	Dim reg As HKEY = Any
	Dim lpdwDisposition As DWORD = Any
	Dim hr As Long = RegCreateKeyEx(HKEY_CURRENT_USER, @RegSectionChannels, 0, 0, 0, KEY_QUERY_VALUE + KEY_SET_VALUE, NULL, @reg, @lpdwDisposition)
	
	If hr <> ERROR_SUCCESS Then
		Return False
	End If
	
	Dim pdwType As DWORD = REG_DWORD
	Dim Buffer As DWORD = Any
	Dim BufferLength As DWORD = SizeOf(DWORD)
	hr = RegQueryValueEx(reg, User, 0, @pdwType, CPtr(Byte Ptr, @Buffer), @BufferLength)
	If hr <> ERROR_SUCCESS Then
		If hr = ERROR_FILE_NOT_FOUND  Then
			Buffer = 0
			BufferLength = SizeOf(DWORD)
		Else
			RegCloseKey(reg)
			Return -1
		End If
	End If
	
	Buffer += 1
	
	hr = RegSetValueEx(reg, User, 0, REG_DWORD, CPtr(Byte Ptr, @Buffer), SizeOf(DWORD))
	If hr <> ERROR_SUCCESS Then
		RegCloseKey(reg)
		Return False
	End If
	
	RegCloseKey(reg)
	Return True
End Function

Function GetSettingsValue( _
		ByVal Buffer As WString Ptr, _
		ByVal BufferLength As Integer, _
		ByVal Key As WString Ptr _
	)As Integer
	Dim reg As HKEY = Any
	Dim lpdwDisposition As DWORD = Any
	Dim hr As Long = RegCreateKeyEx(HKEY_CURRENT_USER, @RegSection, 0, 0, 0, KEY_QUERY_VALUE, NULL, @reg, @lpdwDisposition)

	If hr <> ERROR_SUCCESS Then
		Return -1
	End If
	
	Dim pdwType As DWORD = RRF_RT_REG_SZ
	Dim BufferLength2 As DWORD = (BufferLength + 1) * SizeOf(WString)
	hr = RegQueryValueEx(reg, Key, 0, @pdwType, CPtr(Byte Ptr, Buffer), @BufferLength2)
	If hr <> ERROR_SUCCESS Then
		RegCloseKey(reg)
		Return -1
	End If
	
	RegCloseKey(reg)
	
	Return BufferLength \ SizeOf(WString) - 1
End Function

Function SetSettingsValue( _
		ByVal Key As WString Ptr, _
		ByVal Value As WString Ptr _
	)As Boolean
	Dim reg As HKEY = Any
	Dim lpdwDisposition As DWORD = Any
	Dim hr As Long = RegCreateKeyEx(HKEY_CURRENT_USER, @RegSection, 0, 0, 0, KEY_SET_VALUE, NULL, @reg, @lpdwDisposition)
	
	If hr <> ERROR_SUCCESS Then
		Return False
	End If
	
	hr = RegSetValueEx(reg, Key, 0, REG_SZ, CPtr(Byte Ptr, Value), (lstrlen(Value) + 1) * SizeOf(WString))
	If hr <> ERROR_SUCCESS Then
		RegCloseKey(reg)
		Return False
	End If
	
	RegCloseKey(reg)
	Return True
End Function
