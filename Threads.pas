unit Threads;

interface

uses
  Windows;

type
  TThread2 = class;

  TThreadProcedure = procedure(Thread: TThread2);

  TSynchronizeProcedure = procedure;

  TThread2 = class
  private
    FThreadHandle: longword;
    FThreadID: longword;
    FExitCode: longword;
    FTerminated: boolean;
    FExecute: TThreadProcedure;
    FData: pointer;
  protected
  public
    constructor Create(ThreadProcedure: TThreadProcedure; CreationFlags: Cardinal);
    destructor Destroy; override;
    procedure Synchronize(Synchronize: TSynchronizeProcedure);
    procedure Lock;
    procedure Unlock;
    property Terminated: boolean read FTerminated write FTerminated;
    property ThreadHandle: longword read FThreadHandle;
    property ThreadID: longword read FThreadID;
    property ExitCode: longword read FExitCode;
    property Data: pointer read FData write FData;
  end;

implementation

var
  ThreadLock: TRTLCriticalSection;

procedure ThreadWrapper(Thread: TThread2);
var
  ExitCode: dword;
begin
  Thread.FTerminated := False;
  try
    Thread.FExecute(Thread);
  finally
    GetExitCodeThread(Thread.FThreadHandle, ExitCode);
    Thread.FExitCode := ExitCode;
    Thread.FTerminated := True;
    ExitThread(ExitCode);
  end;
end;

constructor TThread2.Create(ThreadProcedure: TThreadProcedure; CreationFlags: Cardinal);
begin
  inherited Create;
  FExitCode := 0;
  FExecute := ThreadProcedure;
  FThreadHandle := BeginThread(nil, 0, @ThreadWrapper, Pointer(Self), CreationFlags, FThreadID);
end;

destructor TThread2.Destroy;
begin
  inherited;
  CloseHandle(FThreadHandle);
end;

procedure TThread2.Synchronize(Synchronize: TSynchronizeProcedure);
begin
  EnterCriticalSection(ThreadLock);
  try
    Synchronize;
  finally
    LeaveCriticalSection(ThreadLock);
  end;
end;

procedure TThread2.Lock;
begin
  EnterCriticalSection(ThreadLock);
end;

procedure TThread2.Unlock;
begin
  LeaveCriticalSection(ThreadLock);
end;

initialization
  InitializeCriticalSection(ThreadLock);


finalization
  DeleteCriticalSection(ThreadLock);

end.

