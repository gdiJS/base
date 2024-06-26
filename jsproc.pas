unit jsproc;

interface

uses
  windows, sysutils, xsuperobject, Winapi.TlHelp32,
  Winapi.PsAPI, System.Generics.Collections;

type
  Tprocmeta = packed record
    id: Int64;
    running: Boolean;
    pid: DWORD;
    handle: Thandle;
    thread: Thandle;
  end;

type
  Twinmeta = packed record
    hwnd: DWORD;
    objclass: string;
    ancestor: string;
    caption: string;
    pid: DWORD;
    path: string;
    fullscreen: Boolean;
  end;

  Tapp = packed record
    path: string;
    pid: DWORD;
  end;

type
  TQueryFullProcessImageName = function(hProcess: Thandle; dwFlags: DWORD; lpExeName: PChar; nSize: PDWORD): BOOL; stdcall;

function EnumProc: widestring;

function ProcmetaAsJson(meta: Tprocmeta): string;

function WinmetaAsJson(meta: Twinmeta): string;

function RunProcess(FileName: string; const param: string = ''; const hide: Boolean = false): Tprocmeta;

function getWinmeta(window: hwnd): Twinmeta;

function pingProcess(id: Int64): Boolean;

function releaseProcess(id: Int64): integer;

function GetAppExecutable(hwndFG: hwnd): Tapp;

function isfullscreen(h: DWORD): Boolean;

function GetDosOutput(CommandLine: string; Work: string = ''): string;

function GetOutputStdIn(app, command: string; const dir: string = ''; const delimiter: char = #10): string;

var
  ProcList: TDictionary<integer, Tprocmeta>;
  QueryFullProcessImageName: TQueryFullProcessImageName;
  pc: Int64;

implementation

uses
  desktools, psyapi;

function isfullscreen(h: DWORD): Boolean;
var
  rect: Trect;
  height: integer;
  width: integer;
begin
  if h <= 0 then
  begin
    Result := false;
    exit;
  end;

  GetWindowRect(h, rect);
  height := rect.Bottom - rect.Top;
  width := rect.Right - rect.Left;

  Result := false;
  if (IsWindowVisible(h) and not IsIconic(h)) then
  begin
//    if (rect.Left <= 0) and (rect.Top <= 0) and (width >= screen.width) and (height >= screen.height) and (h <> GetDesktopWindow) then
      Result := True;
  end;

end;

function EnumProc: widestring;
var
  MyHandle: Thandle;
  Struct: TProcessEntry32;
  e: string;
begin
  Result := '[';
  try
    MyHandle := CreateToolHelp32SnapShot(TH32CS_SNAPPROCESS, 0);
    Struct.dwSize := Sizeof(TProcessEntry32);
    if Process32First(MyHandle, Struct) then
      e := Struct.szExeFile;
      // if e <> '[System Process]' then
    Result := Result + quotedstr(makePath(e)) + ',';
    while Process32Next(MyHandle, Struct) do
    begin
      e := Struct.szExeFile;
        // if e <> '[System Process]' then
      Result := Result + quotedstr(makePath(e)) + ',';
    end;
    delete(Result, length(Result), 1);
    Result := Result + ']';
  except
    on exception do
        // Sleep(1);




  end
end;

function GetDosOutput(CommandLine: string; Work: string = ''): string;
var
  SA: TSecurityAttributes;
  SI: TStartupInfo;
  PI: TProcessInformation;
  StdOutPipeRead, StdOutPipeWrite: THandle;
  WasOK: Boolean;
  Buffer: array[0..255] of AnsiChar;
  BytesRead: Cardinal;
  WorkDir: string;
  Handle: Boolean;
begin
  Result := '';
  with SA do
  begin
    nLength := SizeOf(SA);
    bInheritHandle := True;
    lpSecurityDescriptor := nil;
  end;
  CreatePipe(StdOutPipeRead, StdOutPipeWrite, @SA, 0);
  try
    with SI do
    begin
      FillChar(SI, SizeOf(SI), 0);
      cb := SizeOf(SI);
      dwFlags := STARTF_USESHOWWINDOW or STARTF_USESTDHANDLES;
      wShowWindow := SW_HIDE;
      hStdInput := GetStdHandle(STD_INPUT_HANDLE); // don't redirect stdin
      hStdOutput := StdOutPipeWrite;
      hStdError := StdOutPipeWrite;
    end;
    WorkDir := Work;
    if WorkDir = '' then
      WorkDir := GetCurrentDir;

    Handle := CreateProcess(nil, PChar('cmd.exe /C ' + CommandLine), nil, nil, True, 0, nil, PChar(WorkDir), SI, PI);
    CloseHandle(StdOutPipeWrite);
    if Handle then
    try
      repeat
        WasOK := ReadFile(StdOutPipeRead, Buffer, 255, BytesRead, nil);
        if BytesRead > 0 then
        begin
          Buffer[BytesRead] := #0;
          Result := Result + Buffer;
        end;
      until not WasOK or (BytesRead = 0);
      WaitForSingleObject(PI.hProcess, INFINITE);
    finally
      CloseHandle(PI.hThread);
      CloseHandle(PI.hProcess);
    end;
  finally
    CloseHandle(StdOutPipeRead);
  end;
end;

function GetChildProcess(CurrentProcessId: dword): DWORD;
var
  HandleSnapShot: THandle;
  EntryParentProc: TProcessEntry32;
  HandleParentProc: THandle;
  ParentProcessFound: Boolean;
  ParentProcPath: string;
begin
  result := 0;
  ParentProcessFound := False;
  HandleSnapShot := CreateToolhelp32Snapshot(TH32CS_SNAPPROCESS, 0);   //enumerate the process
  if HandleSnapShot <> INVALID_HANDLE_VALUE then
  begin
    EntryParentProc.dwSize := SizeOf(EntryParentProc);
    if Process32First(HandleSnapShot, EntryParentProc) then    //find the first process
    begin
      repeat
        if EntryParentProc.th32ParentProcessID = CurrentProcessId then
        begin
          if EntryParentProc.szExeFile <> 'conhost.exe' then
          begin
            Result := EntryParentProc.th32ProcessID;
            break;
          end;
        end;
      until not Process32Next(HandleSnapShot, EntryParentProc);
    end;
    CloseHandle(HandleSnapShot);
  end;
end;

function GetOutputStdIn(app, command: string; const dir: string = ''; const delimiter: char = #10): string;
//launches an app, writes something to stdin and terminates application on delimiter received
var
  SA: TSecurityAttributes;
  SI: TStartupInfo;
  PI: TProcessInformation;
  StdOutPipeRead, StdOutPipeWrite: THandle;
  InputPipeRead, InputPipeWrite: THandle;
  WasOK: Boolean;
  Buffer: array[0..255] of AnsiChar;
  BytesRead: Cardinal;
  WorkDir: string;
  Handle: Boolean;
  dos: string;
  DosSize: Integer;
  cWritten: Cardinal;
  child: dword;
  cmd: ansistring;
  r: char;
  i: integer;
begin
  Result := '';
  with SA do
  begin
    nLength := SizeOf(SA);
    bInheritHandle := True;
    lpSecurityDescriptor := nil;
  end;
  CreatePipe(InputPipeRead, InputPipeWrite, @SA, 0);
  CreatePipe(StdOutPipeRead, StdOutPipeWrite, @SA, 0);
  try
    with SI do
    begin
      FillChar(SI, SizeOf(SI), 0);
      cb := SizeOf(SI);
      dwFlags := STARTF_USESHOWWINDOW or STARTF_USESTDHANDLES;
      wShowWindow := SW_HIDE;
      hStdInput := InputPipeRead;
      hStdOutput := StdOutPipeWrite;
      hStdError := StdOutPipeWrite;
    end;
    if dir = '' then
      WorkDir := GetCurrentDir
    else
      WorkDir := dir;
    SetLength(dos, 255);
    DosSize := GetEnvironmentVariable('COMSPEC', @dos[1], 255);
    SetLength(dos, DosSize);
    Handle := CreateProcess(nil, PChar(dos + ' /C ' + app), @SA, @SA, true, SYNCHRONIZE, nil, PChar(WorkDir), SI, PI);
    cmd := command + #13#10;
    WriteFile(InputPipeWrite, cmd[1], Length(cmd), cWritten, nil);
    CloseHandle(StdOutPipeWrite);
    if Handle then
    try
      repeat
        WasOK := ReadFile(StdOutPipeRead, Buffer, 255, BytesRead, nil);
        if BytesRead > 0 then
        begin
          Buffer[BytesRead] := #0;
          Result := Result + Buffer;
          for i := 0 to Length(Result) do
          begin
            if result[i] = delimiter then
            begin
              child := GetChildProcess(PI.dwProcessId);
              terminateprocess(OpenProcess(PROCESS_TERMINATE, false, child), 0);
             // GenerateConsoleCtrlEvent(CTRL_C_EVENT, child);
             // SetConsoleCtrlHandler(nil, true);

            end;
          end;
        end;
        Sleep(1);
      until not WasOK or (BytesRead = 0);
      WaitForSingleObject(PI.hProcess, INFINITE);
    finally
      CloseHandle(PI.hThread);
      CloseHandle(PI.hProcess);
    end;
  finally
    CloseHandle(StdOutPipeRead);
    CloseHandle(InputPipeWrite);
    CloseHandle(InputPipeRead);
  end;
  result := trim(Result);
end;

function getWinmeta(window: hwnd): Twinmeta;
var
  anc: Thandle;
  app: Tapp;
begin
  anc := GetAncestor(window, 3);
  app := (GetAppExecutable(anc));
  Result.hwnd := window;
  Result.objclass := getwindowclass(window);
  Result.caption := getwindowtitle(window);
  Result.ancestor := getwindowclass(anc);
  Result.fullscreen := isfullscreen(window);
  Result.path := makePath(app.path);
  Result.pid := app.pid;
end;

function GetAppExecutable(hwndFG: hwnd): Tapp;
var
  hProc: Thandle;
  hMod: array[0..0] of HMODULE;
  dwPID: DWORD;
  dwSize: DWORD;
  dwCount: DWORD;
  nSize: cardinal;
  sciezka: array[0..MAX_PATH - 1] of Char;
begin
  Result.path := '';
    // SetLength(result.exe, 0);
  if (hwndFG <> 0) then
  begin
    if (GetWindowThreadProcessID(hwndFG, @dwPID) <> 0) then
    begin
      Result.pid := dwPID;
      hProc := OpenProcess(PROCESS_QUERY_INFORMATION or PROCESS_VM_READ, True, dwPID);
      if (hProc <> 0) then
      begin
        try
          dwCount := 0;
          if EnumProcessModules(hProc, @hMod, Sizeof(HMODULE), dwCount) then
          begin
            SetLength(Result.path, Succ(MAX_PATH));
            dwSize := GetModuleFileNameEx(hProc, hMod[0], Pointer(Result.path), MAX_PATH);
            SetLength(Result.path, dwSize);
          end
          else
          begin
            nSize := MAX_PATH;
            ZeroMemory(@sciezka, MAX_PATH);
            if QueryFullProcessImageName(hProc, 0, sciezka, @nSize) then
              Result.path := trim(sciezka);
            if Result.path = '' then
              Result.path := '<unknown>';
          end;
        finally
          CloseHandle(hProc);
        end;
      end;
    end;
  end;
end;

function releaseProcess(id: Int64): integer;
var
  Proc: Tprocmeta;
begin
  if ProcList.TryGetValue(id, Proc) then
  begin
    OutputDebugString(PChar('Releasing handle: ' + inttostr(id) + '/' + inttostr(Proc.handle)));
    CloseHandle(Proc.handle);
    CloseHandle(Proc.thread);
    ProcList.Remove(id);
  end;
end;

function WinmetaAsJson(meta: Twinmeta): string;
begin
  Result := TJSON.Stringify<Twinmeta>(meta);
end;

function ProcmetaAsJson(meta: Tprocmeta): string;
begin
  Result := TJSON.Stringify<Tprocmeta>(meta);
end;

function pingProcess(id: Int64): Boolean;
var
  Proc: Tprocmeta;
begin
  if ProcList.TryGetValue(id, Proc) then
  begin
    if WaitForSingleObject(Proc.handle, 1) = WAIT_TIMEOUT then
      Result := True
    else
      Result := false;
  end;
end;

function RunProcess(FileName: string; const param: string = ''; const hide: Boolean = false): Tprocmeta;
var
  StartupInfo: TStartupInfo;
  ProcessInfo: TProcessInformation;
begin
  FillChar(StartupInfo, Sizeof(StartupInfo), #0);
  StartupInfo.cb := Sizeof(StartupInfo);
  StartupInfo.dwFlags := STARTF_USESHOWWINDOW or STARTF_FORCEONFEEDBACK;
  if hide then
    StartupInfo.wShowWindow := SW_HIDE
  else
    StartupInfo.wShowWindow := SW_SHOWNORMAL;
  if CreateProcess(nil, @FileName[1], nil, nil, false, CREATE_NEW_CONSOLE or NORMAL_PRIORITY_CLASS, nil, nil, StartupInfo, ProcessInfo) then
  begin
    Result.running := True;
    Result.pid := ProcessInfo.dwProcessId;
    Result.handle := ProcessInfo.hProcess;
    Result.thread := ProcessInfo.hThread;
    Result.id := pc;
    ProcList.Add(Result.id, Result);
    Inc(pc);

  end
  else
    Result.running := false;
end;

initialization
  ProcList := TDictionary<integer, Tprocmeta>.Create;
  @QueryFullProcessImageName := GetProcAddress(GetModuleHandle('kernel32'), 'QueryFullProcessImageNameW');

finalization
  ProcList.Free;

end.

