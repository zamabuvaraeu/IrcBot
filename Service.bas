#include once "Service.bi"

Dim Shared ServiceStatusHandle As SERVICE_STATUS_HANDLE
Dim Shared ServiceStatus As SERVICE_STATUS
Dim Shared ServiceStopEvent As HANDLE
Dim Shared ServiceCheckPoint As DWORD

Function EntryPoint Alias "EntryPoint"()As Integer
	Dim DispatchTable(1) As SERVICE_TABLE_ENTRY = Any
	DispatchTable(0).lpServiceName = @ServiceName
	DispatchTable(0).lpServiceProc = @SvcMain
	DispatchTable(1).lpServiceName = 0
	DispatchTable(1).lpServiceProc = 0

	StartServiceCtrlDispatcher(@DispatchTable(0))
	Return 0
End Function

Sub SvcMain(ByVal dwNumServicesArgs As DWORD, ByVal lpServiceArgVectors As LPWSTR Ptr)
	ServiceStatusHandle = RegisterServiceCtrlHandlerEx(@ServiceName, @SvcCtrlHandlerEx, NULL)
	If ServiceStatusHandle = 0 Then
		Exit Sub
	End If
	
	ServiceStatus.dwServiceType = SERVICE_WIN32_OWN_PROCESS
	ServiceStatus.dwServiceSpecificExitCode = 0
	
	ReportSvcStatus(SERVICE_START_PENDING, NO_ERROR, 3000)
	
	' TODO Добавить необходимых инициализаций
	
	ServiceStopEvent = CreateEvent(NULL, TRUE, FALSE, NULL)
	
	If ServiceStopEvent = NULL Then
		ReportSvcStatus(SERVICE_STOPPED, NO_ERROR, 0)
		Exit Sub
	End If
	
	ReportSvcStatus(SERVICE_START_PENDING, NO_ERROR, 3000)
	
	' TODO Поток рабочего процесса
	
	Dim ThreadId As DWord = Any
	Dim hThreadLoop As HANDLE = CreateThread(NULL, 0, @ServiceProc, 0, 0, @ThreadId)
	If hThreadLoop = NULL Then
		ReportSvcStatus(SERVICE_STOPPED, NO_ERROR, 0)
		Exit Sub
	End If
	CloseHandle(hThreadLoop)
	
	ReportSvcStatus(SERVICE_RUNNING, NO_ERROR, 0)
	
	WaitForSingleObject(ServiceStopEvent, INFINITE)
	
	ReportSvcStatus(SERVICE_STOPPED, NO_ERROR, 0)
End Sub

Function SvcCtrlHandlerEx(ByVal dwCtrl As DWORD, ByVal dwEventType As DWORD, ByVal lpEventData As LPVOID, ByVal lpContext As LPVOID)As DWORD
	
	Select Case dwCtrl
		'Case SERVICE_CONTROL_CONTINUE
				
		Case SERVICE_CONTROL_INTERROGATE
			ReportSvcStatus(ServiceStatus.dwCurrentState, NO_ERROR, 0)
			Return NO_ERROR
			
		'Case SERVICE_CONTROL_PARAMCHANGE
		
		'Case SERVICE_CONTROL_PAUSE
		
		'Case SERVICE_CONTROL_SHUTDOWN
			
		Case SERVICE_CONTROL_STOP
			ReportSvcStatus(SERVICE_STOP_PENDING, NO_ERROR, 0)
			SetEvent(ServiceStopEvent)
			Return NO_ERROR
			
		' TODO Обработка собственных кодов
		
		Case Else
			Return ERROR_CALL_NOT_IMPLEMENTED
			
	End Select
	
End Function

Sub ReportSvcStatus(ByVal dwCurrentState As DWORD, ByVal dwWin32ExitCode As DWORD, ByVal dwWaitHint As DWORD)
	ServiceStatus.dwCurrentState = dwCurrentState
	ServiceStatus.dwWin32ExitCode = dwWin32ExitCode
	ServiceStatus.dwWaitHint = dwWaitHint
	
	If dwCurrentState = SERVICE_START_PENDING Then
		ServiceStatus.dwControlsAccepted = 0
	Else
		ServiceStatus.dwControlsAccepted = SERVICE_ACCEPT_STOP
	End If
	
	If dwCurrentState = SERVICE_RUNNING Or dwCurrentState = SERVICE_STOPPED Then
		ServiceStatus.dwCheckPoint = 0
	Else
		ServiceCheckPoint += 1
		ServiceStatus.dwCheckPoint = ServiceCheckPoint
	End If
	
	SetServiceStatus(ServiceStatusHandle, @ServiceStatus)
End Sub
