#ifndef SERVICE_BI
#define SERVICE_BI

#define unicode
#include once "windows.bi"

Declare Sub ReportSvcStatus(ByVal dwCurrentState As DWORD, ByVal dwWin32ExitCode As DWORD, ByVal dwWaitHint As DWORD)
Declare Sub SvcMain(ByVal dwNumServicesArgs As DWORD, ByVal lpServiceArgVectors As LPWSTR Ptr)
Declare Function SvcCtrlHandlerEx(ByVal dwCtrl As DWORD, ByVal dwEventType As DWORD, ByVal lpEventData As LPVOID, ByVal lpContext As LPVOID)As DWORD
Declare Function ServiceProc(ByVal lpParam As LPVOID)As DWORD

' Имя службы
Const ServiceName = "IrcBot"

#endif
