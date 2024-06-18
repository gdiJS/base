unit exceptions;

interface

uses
  windows, sysutils;

type
  REArguments = array[0..100] of DWORD;

  PREArguments = ^REArguments;

  TExceptionProc = procedure(dwExceptionCode, dwExceptionFlags, nNumberOfArguments: DWORD; lpArguments: PREArguments); stdcall;

procedure HandleFatalException(dwExceptionCode, dwExceptionFlags, nNumberOfArguments: DWORD; lpArguments: PREArguments); stdcall;

implementation

procedure HandleFatalException(dwExceptionCode, dwExceptionFlags, nNumberOfArguments: DWORD; lpArguments: PREArguments); stdcall;
var
  msg: string;
begin
  msg := 'Brutal Error: ' + inttostr(dwExceptionCode) + ' - ' + IntToStr(dwExceptionFlags);
end;


end.

