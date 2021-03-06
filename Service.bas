#include once "Service.bi"

Const ServiceName = "IrcBot"
Const SCMGoodByeMessage = "I am shutting down because Windows Service Controller sent a SERVICE_CONTROL_STOP message."
Const SCMInterrogateNotice = "Windows Service Controller sent a SERVICE_CONTROL_INTERROGATE message."
Const SCMNotImplementedNotice = "Windows Service Controller sent a not implemented message."

Function EntryPoint Alias "EntryPoint"()As Integer
	Dim DispatchTable(1) As SERVICE_TABLE_ENTRY = Any
	DispatchTable(0).lpServiceName = @ServiceName
	DispatchTable(0).lpServiceProc = @SvcMain
	DispatchTable(1).lpServiceName = 0
	DispatchTable(1).lpServiceProc = 0

	StartServiceCtrlDispatcher(@DispatchTable(0))
	Return 0
End Function

Sub SvcMain( _
		ByVal dwNumServicesArgs As DWORD, _
		ByVal lpServiceArgVectors As LPWSTR Ptr _
	)
	Dim Context As ServiceContext
	
	Context.ServiceStatusHandle = RegisterServiceCtrlHandlerEx(@ServiceName, @SvcCtrlHandlerEx, @Context)
	If Context.ServiceStatusHandle = 0 Then
		Exit Sub
	End If
	
	Context.ServiceStatus.dwServiceType = SERVICE_WIN32_OWN_PROCESS
	Context.ServiceStatus.dwServiceSpecificExitCode = 0
	
	ReportSvcStatus(@Context, SERVICE_START_PENDING, NO_ERROR, 3000)
	
	InitializeIrcBot(@Context.Bot, @Context.RealBotVersion)
	
	Context.ServiceStopEvent = CreateEvent(NULL, TRUE, FALSE, NULL)
	If Context.ServiceStopEvent = NULL Then
		ReportSvcStatus(@Context, SERVICE_STOPPED, NO_ERROR, 0)
		Exit Sub
	End If
	
	ReportSvcStatus(@Context, SERVICE_START_PENDING, NO_ERROR, 3000)
	
	Dim ThreadId As DWord = Any
	Dim hThreadLoop As HANDLE = CreateThread(NULL, 0, @MainLoop, @Context.Bot, 0, @ThreadId)
	If hThreadLoop = NULL Then
		ReportSvcStatus(@Context, SERVICE_STOPPED, NO_ERROR, 0)
		Exit Sub
	End If
	CloseHandle(hThreadLoop)
	
	ReportSvcStatus(@Context, SERVICE_RUNNING, NO_ERROR, 0)
	
	WaitForSingleObject(Context.ServiceStopEvent, INFINITE)
	
	ReportSvcStatus(@Context, SERVICE_STOPPED, NO_ERROR, 0)
End Sub

Function SvcCtrlHandlerEx( _
		ByVal dwCtrl As DWORD, _
		ByVal dwEventType As DWORD, _
		ByVal lpEventData As LPVOID, _
		ByVal lpContext As LPVOID _
	)As DWORD
	
	Dim lpContext2 As ServiceContext Ptr = lpContext
	
	Select Case dwCtrl
		Case SERVICE_CONTROL_INTERROGATE
			lpContext2->Bot.Say(@MainChannel, @SCMInterrogateNotice)
			ReportSvcStatus(lpContext2, lpContext2->ServiceStatus.dwCurrentState, NO_ERROR, 0)
			
		Case SERVICE_CONTROL_STOP
			ReportSvcStatus(lpContext2, SERVICE_STOP_PENDING, NO_ERROR, 0)
			lpContext2->Bot.Client.QuitFromServer(@SCMGoodByeMessage)
			SetEvent(lpContext2->ServiceStopEvent)
			
		Case Else
			lpContext2->Bot.Say(@MainChannel, @SCMNotImplementedNotice)
			Return ERROR_CALL_NOT_IMPLEMENTED
			
	End Select
	
	Return NO_ERROR
	
End Function

Sub ReportSvcStatus( _
		ByVal lpContext As ServiceContext Ptr, _
		ByVal dwCurrentState As DWORD, _
		ByVal dwWin32ExitCode As DWORD, _
		ByVal dwWaitHint As DWORD _
	)
	lpContext->ServiceStatus.dwCurrentState = dwCurrentState
	lpContext->ServiceStatus.dwWin32ExitCode = dwWin32ExitCode
	lpContext->ServiceStatus.dwWaitHint = dwWaitHint
	
	If dwCurrentState = SERVICE_START_PENDING Then
		lpContext->ServiceStatus.dwControlsAccepted = 0
	Else
		lpContext->ServiceStatus.dwControlsAccepted = SERVICE_ACCEPT_STOP
	End If
	
	If dwCurrentState = SERVICE_RUNNING Or dwCurrentState = SERVICE_STOPPED Then
		lpContext->ServiceStatus.dwCheckPoint = 0
	Else
		lpContext->ServiceCheckPoint += 1
		lpContext->ServiceStatus.dwCheckPoint = lpContext->ServiceCheckPoint
	End If
	
	SetServiceStatus(lpContext->ServiceStatusHandle, @lpContext->ServiceStatus)
End Sub

#if __FB_DEBUG__ <> 0
End(EntryPoint())
#endif