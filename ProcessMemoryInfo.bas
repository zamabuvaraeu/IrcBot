#include once "ProcessMemoryInfo.bi"
#include once "IntegerToWString.bi"

' Получение информации об использовании памяти процесса
Function GetMemoryInfo(ByVal ProcessData As ProcessMemoryInfo Ptr, ByVal processID As DWORD)As Boolean
	Dim hProcess As HANDLE = OpenProcess(PROCESS_QUERY_INFORMATION Or PROCESS_VM_READ, FALSE, processID)
	If hProcess <> NULL Then
		Dim pmc As PROCESS_MEMORY_COUNTERS_EX = Any
		If GetProcessMemoryInfo(hProcess, CPtr(PPROCESS_MEMORY_COUNTERS, @pmc), SizeOf(PROCESS_MEMORY_COUNTERS_EX)) <> 0 Then
			itow(pmc.PageFaultCount, ProcessData->PageFaultCount, 10)
			itow(pmc.PeakWorkingSetSize, ProcessData->PeakWorkingSetSize, 10)
			itow(pmc.WorkingSetSize, ProcessData->WorkingSetSize, 10)
			' itow(pmc.QuotaPeakPagedPoolUsage, ProcessData->QuotaPeakPagedPoolUsage, 10)
			' itow(pmc.QuotaPagedPoolUsage, ProcessData->QuotaPagedPoolUsage, 10)
			' itow(pmc.QuotaPeakNonPagedPoolUsage, ProcessData->QuotaPeakNonPagedPoolUsage, 10)
			' itow(pmc.QuotaNonPagedPoolUsage, ProcessData->QuotaNonPagedPoolUsage, 10)
			itow(pmc.PagefileUsage, ProcessData->PagefileUsage, 10)
			itow(pmc.PeakPagefileUsage, ProcessData->PeakPagefileUsage, 10)
			itow(pmc.PrivateUsage, ProcessData->PrivateUsage, 10)
			
			CloseHandle(hProcess)
			Return True
		End If
	End If
	Return False
End Function
