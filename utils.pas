unit utils;

interface

uses
  Windows, Winapi.TlHelp32, System.SysUtils, Registry, Classes, messages,
  ShellAPI;

type
  TProcess = packed record
    pid: longint;
    name: string;
    started: Int64;
    path: string;
  end;

  Tfile = packed record
    name: ansistring;
    size: Int64;
    created: Int64;
    modified: Int64;
  end;

  Tuser = packed record
    name: ansistring;
    isAdmin: boolean;
  end;

  Twindow = packed record
    caption: string;
    _class: ansistring;
    handle: integer;
    focused: boolean;
  end;

  Tscreen = packed record
    id: integer;
    width: integer;
    height: integer;
    default: boolean;
  end;

  Tdisk = packed record
    name: Ansistring;
    letter: string;
    devtype: integer;
    Size: Int64;
    free: Int64;
    fs: ansistring;
  end;

  Tscreens = array of Tscreen;

  Tdisks = array of Tdisk;

  Tproclist = array of Tprocess;

  Twindows = array of Twindow;

  Tfiles = array of Tfile;

  TSystem = packed record
    name: Ansistring;
    country: Ansistring;
    timezone: Ansistring;
    locale: AnsiString;
    memory: integer;
    cpu: integer;
    res: string;
    os: string;
    user: Tuser;
    bootAt: Int64;
  end;

  Tsession = packed record
    idle: Int64;
    window: ansistring;
    memload: Int64;
    uptime: Int64;
    updated: Int64;
  end;

type
  Tdatakesh = packed record
    system: Tsystem;
    session: Tsession;
    instance: TProcess;
    screens: Tscreens;
    disks: Tdisks;
    adres: ansistring;
    port: integer;
    key: ansistring;
    token: ansistring;
    ref: ansistring;
  end;

type
  MemoryStatusEx = record
    dwLength: DWORD;
    dwMemoryLoad: DWORD;
    ullTotalPhys: uint64;
    ullAvailPhys: uint64;
    ullTotalPageFile: uint64;
    ullAvailPageFile: uint64;
    ullTotalVirtual: uint64;
    ullAvailVirtual: uint64;
    ullAvailExtendedVirtual: uint64;
  end;

type
  TArg<T> = reference to procedure(const arg: T);

function ls(path: ansistring; const ext: string = '*'): Tfiles;

function explodestr(const s: ansistring; c: Char; wordIndex: integer): ansistring;

function UnixTime: Int64;

function GetUserName: string;

function LocaleInfoEx(Flag: integer): string;

function GetTimeZone: string;

function makine: string;

function getWindowsVersion: AnsiString;

function GetSystemMem: integer;

function IsWindowsAdmin: Boolean;

function ListDisks: Tdisks;

function IsPrime(N: Integer): Boolean;

function GenerateRandomPrime(min, max: Integer): Integer;

function idle: DWord;

function parseBool(b: boolean): string;

function readBuffer(fpath: string; var fbuffer: TBytes): boolean;

function CaseOfString(s: string; a: array of string): Integer;

function fixPath(path: string): string;

function makePath(path: string): string;

function TaskList: Twindows;

function StripNonAlphaNumeric(const AValue: string): string;

function ListProcesses: Tproclist;

function writeBuffer(fpath: string; fbuffer: TBytes): Boolean;

function DelTree(DirName: string): Boolean;

function readBufferLimit(fpath: string; limit: int64; var fbuffer: TBytes): boolean;

function GlobalMemoryStatusEx(var Buffer: MemoryStatusEx): BOOL; stdcall; external 'kernel32' name 'GlobalMemoryStatusEx';

function NtQuerySystemTime(var CurrentTime: LARGE_INTEGER): Integer; stdcall; external 'ntdll.dll';

procedure RtlGetNtVersionNumbers(out MajorVersion: DWORD; out MinorVersion: DWORD; out Build: DWORD); stdcall; external 'ntdll.dll';

function ExtractString(_id, _type: string): ansistring;

function WindowsPath: string;

function GetTempFolder: string;

function KillApp(hande: Thandle): boolean;

function getResolution: string;

function IsElevated: boolean;

function KillProcess(ExeFileName: string): integer;

function processExists(exeFileName: string): Boolean;

function IsAdministrator: boolean;

procedure firstBytes(const Filepath: string; limit: int64; CallBack: TArg<AnsiString>);

procedure CaptureConsoleOutput(const ACommand: string; CallBack: TArg<PAnsiChar>);

function getEnv(name: string): string;

function procTelemetry(line: string): string;

function percentage(part, whole: Int64): integer;

function SearchAndReplace(sSrc, sLookFor, sReplaceWith: string): string;

function FileSize(const fileName: string): int64;

function IsRemoteSession: Boolean;

function activate(WindowName: PChar; const cls: pchar = nil): boolean;

function maximize(WindowName: PChar; const cls: pchar = nil): boolean;

procedure _maximize(WindowHandle: Thandle);

function ramdurumu: integer;

function UnixTimeMillis: Int64;

procedure AddToPath(const Dir: string);

function RunFileWithParameters(const FileName, Parameters: string): Boolean;

type
  _SHELLEXECUTEINFOW = record
    cbSize: DWORD;
    fMask: ULONG;
    Wnd: HWND;
    lpVerb: LPCWSTR;
    lpFile: LPCWSTR;
    lpParameters: LPCWSTR;
    lpDirectory: LPCWSTR;
    nShow: Integer;
    hInstApp: HINST;
    { Optional fields }
    lpIDList: Pointer;
    lpClass: LPCWSTR;
    hkeyClass: HKEY;
    dwHotKey: DWORD;
    case Integer of
      0:
        (hIcon: THandle);
      1:
        (hMonitor: THandle;
        hProcess: THandle;);
  end;

  FILEOP_FLAGS = Word;

  _SHFILEOPSTRUCTW = record
    Wnd: HWND;
    wFunc: UINT;
    pFrom: LPCWSTR;
    pTo: LPCWSTR;
    fFlags: FILEOP_FLAGS;
    fAnyOperationsAborted: BOOL;
    hNameMappings: Pointer;
    lpszProgressTitle: LPCWSTR; { only used if FOF_SIMPLEPROGRESS }
  end;

  PShellExecuteInfoW = ^_SHELLEXECUTEINFOW;

  PShellExecuteInfo = PShellExecuteInfoW;

type
  HMONITOR = type THandle;

  TMonitorInfo = record
    cbSize: DWORD;
    rcMonitor: TRect;
    rcWork: TRect;
    dwFlags: DWORD;
  end;

  LPMONITORINFO = ^TMonitorInfo;

const
  MONITOR_DEFAULTTONEAREST = $00000002;
  WM_COMMAND = $0111;
  WM_SYSCOMMAND = $0112;

function GetMonitorInfo(hMonitor: HMONITOR; lpmi: LPMONITORINFO): BOOL; stdcall; external 'user32.dll' name 'GetMonitorInfoW';

function MonitorFromWindow(hwnd: HWND; dwFlags: DWORD): HMONITOR; stdcall; external 'user32.dll' name 'MonitorFromWindow';

function SHFileOperation(const lpFileOp: _SHFILEOPSTRUCTW): integer; stdcall; external 'shell32.dll' name 'SHFileOperationW';

function ShellExecuteEx(lpExecInfo: PShellExecuteInfo): BOOL; stdcall; external 'shell32.dll' name 'ShellExecuteExW'

function CheckTokenMembership(TokenHandle: THandle; SidToCheck: pointer; var IsMember: BOOL): BOOL; stdcall; external advapi32 name 'CheckTokenMembership';

const
  THREAD_SUSPEND_RESUME = $0002;

function OpenThread(dwDesiredAccess: DWORD; bInheritHandle: BOOL; dwThreadId: DWORD): THandle; stdcall; external 'kernel32.dll';

function SuspendProcess(PID: DWORD): Boolean;

function ResumeProcess(ProcessID: DWORD): Boolean;

type
  TenvVar = record
    key: string;
    value: string;
  end;

type
  TenvVars = array of Tenvvar;

function GetAllEnvVars: TenvVars;

implementation

function ResumeProcess(ProcessID: DWORD): Boolean;
var
  Snapshot, cThr: DWORD;
  ThrHandle: THandle;
  Thread: TThreadEntry32;
begin
  Result := False;
  cThr := GetCurrentThreadId;
  Snapshot := CreateToolhelp32Snapshot(TH32CS_SNAPTHREAD, 0);
  if Snapshot <> INVALID_HANDLE_VALUE then
  begin
    Thread.dwSize := SizeOf(TThreadEntry32);
    if Thread32First(Snapshot, Thread) then
      repeat
        if (Thread.th32ThreadID <> cThr) and (Thread.th32OwnerProcessID = ProcessID) then
        begin
          ThrHandle := OpenThread(THREAD_SUSPEND_RESUME, false, Thread.th32ThreadID);
          if ThrHandle = 0 then
            Exit;
          ResumeThread(ThrHandle);
          CloseHandle(ThrHandle);
        end;
      until not Thread32Next(Snapshot, Thread);
    Result := CloseHandle(Snapshot);
  end;
end;

function SuspendProcess(PID: DWORD): Boolean;
var
  hSnap: THandle;
  THR32: THREADENTRY32;
  hOpen: THandle;
begin
  Result := FALSE;
  hSnap := CreateToolhelp32Snapshot(TH32CS_SNAPTHREAD, 0);
  if hSnap <> INVALID_HANDLE_VALUE then
  begin
    THR32.dwSize := SizeOf(THR32);
    Thread32First(hSnap, THR32);
    repeat
      if THR32.th32OwnerProcessID = PID then
      begin
        hOpen := OpenThread($0002, FALSE, THR32.th32ThreadID);
        if hOpen <> INVALID_HANDLE_VALUE then
        begin
          Result := TRUE;
          SuspendThread(hOpen);
          CloseHandle(hOpen);
        end;
      end;
    until Thread32Next(hSnap, THR32) = FALSE;
    CloseHandle(hSnap);
  end;
end;

function GetAllEnvVars: TenvVars;
var
  i: integer;
  PEnvVars: PChar;    // pointer to start of environment block
  PEnvEntry: PChar;   // pointer to an env string in block
begin
  i := 0;
  setlength(result, i);
  PEnvVars := GetEnvironmentStrings;
  if PEnvVars <> nil then
  begin
    PEnvEntry := PEnvVars;
    try
      while PEnvEntry^ <> #0 do
      begin
        setlength(result, length(result) + 1);
        result[i].key := explodestr(PEnvEntry, '=', 0);
        result[i].value := explodestr(PEnvEntry, '=', 1);
        i := i + 1;
        Inc(PEnvEntry, StrLen(PEnvEntry) + 1);
      end;
    finally
      Windows.FreeEnvironmentStrings(PEnvVars);
    end;
  end
end;

function IsremoteSession: boolean;
const
  sm_RemoteSession = $1000;
begin
  Result := (GetSystemMetrics(sm_RemoteSession) <> 0);
end;

function activate(WindowName: PChar; const cls: pchar = nil): boolean;
var
  WindowHandle: HWND;
begin
  try
    Result := true;
    WindowHandle := FindWindow(cls, WindowName);
    if (WindowHandle <> 0) then
    begin
      SendMessage(WindowHandle, WM_SYSCOMMAND, SC_RESTORE, WindowHandle);
      SetForegroundWindow(WindowHandle);
    end
    else
      Result := false;
  except
    on Exception do
      Result := false;
  end;
end;

function maximize(WindowName: PChar; const cls: pchar = nil): boolean;
var
  WindowHandle: HWND;
begin
  try
    Result := true;
    WindowHandle := FindWindow(cls, WindowName);
    if (WindowHandle <> 0) then
    begin
      SendMessage(WindowHandle, WM_SYSCOMMAND, SC_MAXIMIZE, WindowHandle);
      SetForegroundWindow(WindowHandle);
    end
    else
      Result := false;
  except
    on Exception do
      Result := false;
  end;
end;

procedure _maximize(WindowHandle: Thandle);
begin
  SendMessage(WindowHandle, WM_SYSCOMMAND, SC_MAXIMIZE, WindowHandle);
  SetForegroundWindow(WindowHandle);
end;

function percentage(part, whole: Int64): integer;
begin
  result := round((part / whole) * 100);
end;

function getEnv(name: string): string;
var
  Buffer: array[0..255] of char;
begin
  GetEnvironmentVariable(pchar(name), @Buffer, SizeOf(Buffer));
  result := string(Buffer);
end;

function procTelemetry(line: string): string;
begin
  line := stringreplace(line, '*', '?', [rfReplaceAll, rfIgnoreCase]);
  line := stringreplace(line, '$', '?', [rfReplaceAll, rfIgnoreCase]);
  line := stringreplace(line, ';', '?', [rfReplaceAll, rfIgnoreCase]);
  line := stringreplace(line, ',', '?', [rfReplaceAll, rfIgnoreCase]);
  result := trim(line);
end;

procedure firstBytes(const Filepath: string; limit: int64; CallBack: TArg<AnsiString>);
var
  abuf: TBytes;
  cbuf: TBytes;
  i: integer;
  a: integer;
  T: int64;
  r: int64;
  parts: integer;
  payload: string;
const
  chunk = 1024;
label
  skip;
begin
  SetLength(abuf, 0);
  readBufferLimit(Filepath, limit, abuf);
  T := Length(abuf);

  if T < chunk then
  begin
    SetString(payload, PAnsiChar(@abuf[0]), Length(abuf));
    zeromemory(@abuf[0], Length(abuf));
    CallBack(payload);
    exit;
  end;

  parts := T div chunk;
  if ((T mod parts) > 0) then
    inc(parts);

  for a := 0 to parts - 1 do
  begin
    r := chunk * a;
    if r > limit then
      exit;

    SetLength(cbuf, chunk);
    for i := 0 to chunk do
    begin
      if (i + r) > limit then
        break;

      cbuf[i] := abuf[i + r];
    end;

    SetString(payload, PAnsiChar(@cbuf[0]), Length(cbuf));
    zeromemory(@cbuf[0], Length(cbuf));
    payload := procTelemetry(payload);
    if payload <> '' then
      CallBack(payload);
  end;
  zeromemory(@abuf[0], Length(abuf));
  SetLength(abuf, 0);
end;

procedure CaptureConsoleOutput(const ACommand: string; CallBack: TArg<PAnsiChar>);
const
  CReadBuffer = 2400;
var
  saSecurity: TSecurityAttributes;
  hRead: THandle;
  hWrite: THandle;
  suiStartup: TStartupInfo;
  piProcess: TProcessInformation;
  pBuffer: array[0..CReadBuffer] of AnsiChar;
  dBuffer: array[0..CReadBuffer] of AnsiChar;
  dRead: DWORD;
  dRunning: DWORD;
  dAvailable: DWORD;
begin
  saSecurity.nLength := SizeOf(TSecurityAttributes);
  saSecurity.bInheritHandle := True;
  saSecurity.lpSecurityDescriptor := nil;
  if CreatePipe(hRead, hWrite, @saSecurity, 0) then
  try
    FillChar(suiStartup, SizeOf(TStartupInfo), #0);
    suiStartup.cb := SizeOf(TStartupInfo);
    suiStartup.hStdInput := hRead;
    suiStartup.hStdOutput := hWrite;
    suiStartup.hStdError := hWrite;
    suiStartup.dwFlags := STARTF_USESTDHANDLES or STARTF_USESHOWWINDOW;
    suiStartup.wShowWindow := SW_HIDE;
    if CreateProcess(nil, pchar(getEnv('COMSPEC') + ' /C ' + ACommand), @saSecurity, @saSecurity, True, NORMAL_PRIORITY_CLASS, nil, nil, suiStartup, piProcess) then
    try
      repeat
        dRunning := WaitForSingleObject(piProcess.hProcess, 100);
        PeekNamedPipe(hRead, nil, 0, nil, @dAvailable, nil);
        if (dAvailable > 0) then
          repeat
            dRead := 0;
            ReadFile(hRead, pBuffer[0], CReadBuffer, dRead, nil);
            pBuffer[dRead] := #0;
            OemToCharA(pBuffer, dBuffer);
            if assigned(CallBack) then
              CallBack(dBuffer);
          until (dRead < CReadBuffer);
        sleep(1);
      until (dRunning <> WAIT_TIMEOUT);
    finally
      CloseHandle(piProcess.hProcess);
      CloseHandle(piProcess.hThread);
    end;
  finally
    CloseHandle(hRead);
    CloseHandle(hWrite);
  end;

end;

function IsAdministrator: boolean;
var
  psidAdmin: pointer;
  B: BOOL;
const
  SECURITY_NT_AUTHORITY: TSidIdentifierAuthority = (
    Value: (0, 0, 0, 0, 0, 5)
  );
  SECURITY_BUILTIN_DOMAIN_RID = $00000020;
  DOMAIN_ALIAS_RID_ADMINS = $00000220;
  SE_GROUP_USE_FOR_DENY_ONLY = $00000010;
begin
  psidAdmin := nil;
  try
    Win32Check(AllocateAndInitializeSid(SECURITY_NT_AUTHORITY, 2, SECURITY_BUILTIN_DOMAIN_RID, DOMAIN_ALIAS_RID_ADMINS, 0, 0, 0, 0, 0, 0, psidAdmin));
    if CheckTokenMembership(0, psidAdmin, B) then
      result := B
    else
      result := False;
  finally
    if psidAdmin <> nil then
      FreeSid(psidAdmin);
  end;
end;

function IsElevated: boolean;
const
  TokenElevation = TTokenInformationClass(20);
type
  TOKEN_ELEVATION = record
    TokenIsElevated: DWORD;
  end;
var
  TokenHandle: THandle;
  ResultLength: cardinal;
  ATokenElevation: TOKEN_ELEVATION;
  HaveToken: boolean;
begin
  if CheckWin32Version(6, 0) then
  begin
    TokenHandle := 0;
    HaveToken := OpenThreadToken(GetCurrentThread, TOKEN_QUERY, True, TokenHandle);
    if (not HaveToken) and (GetLastError = ERROR_NO_TOKEN) then
      HaveToken := OpenProcessToken(GetCurrentProcess, TOKEN_QUERY, TokenHandle);
    if HaveToken then
    begin
      try
        ResultLength := 0;
        if GetTokenInformation(TokenHandle, TokenElevation, @ATokenElevation, SizeOf(ATokenElevation), ResultLength) then
          result := ATokenElevation.TokenIsElevated <> 0
        else
          result := False;
      finally
        CloseHandle(TokenHandle);
      end;
    end
    else
      result := False;
  end
  else
    result := IsAdministrator;
end;

function SearchAndReplace(sSrc, sLookFor, sReplaceWith: string): string;
var
  nPos, nLenLookFor: integer;
begin
  nPos := Pos(sLookFor, sSrc);
  nLenLookFor := Length(sLookFor);
  while (nPos > 0) do
  begin
    Delete(sSrc, nPos, nLenLookFor);
    Insert(sReplaceWith, sSrc, nPos);
    nPos := Pos(sLookFor, sSrc);
  end;
  result := sSrc;
end;

function processExists(exeFileName: string): Boolean;
var
  ContinueLoop: BOOL;
  FSnapshotHandle: THandle;
  FProcessEntry32: TProcessEntry32;
begin
  FSnapshotHandle := CreateToolhelp32Snapshot(TH32CS_SNAPPROCESS, 0);
  FProcessEntry32.dwSize := SizeOf(FProcessEntry32);
  ContinueLoop := Process32First(FSnapshotHandle, FProcessEntry32);
  result := False;
  while Integer(ContinueLoop) <> 0 do
  begin
    if ((UpperCase(ExtractFileName(FProcessEntry32.szExeFile)) = UpperCase(exeFileName)) or (UpperCase(FProcessEntry32.szExeFile) = UpperCase(exeFileName))) then
    begin
      result := True;
    end;
    ContinueLoop := Process32Next(FSnapshotHandle, FProcessEntry32);
  end;
  CloseHandle(FSnapshotHandle);
end;

function KillProcess(ExeFileName: string): integer;
const
  PROCESS_TERMINATE = $0001;
var
  ContinueLoop: BOOL;
  FSnapshotHandle: THandle;
  FProcessEntry32: TProcessEntry32;
begin
  result := 0;
  FSnapshotHandle := CreateToolhelp32Snapshot(TH32CS_SNAPPROCESS, 0);
  FProcessEntry32.dwSize := Sizeof(FProcessEntry32);
  ContinueLoop := Process32First(FSnapshotHandle, FProcessEntry32);
  while integer(ContinueLoop) <> 0 do
  begin
    if ((UpperCase(ExtractFileName(FProcessEntry32.szExeFile)) = UpperCase(ExeFileName)) or (UpperCase(FProcessEntry32.szExeFile) = UpperCase(ExeFileName))) then
      result := Integer(TerminateProcess(OpenProcess(PROCESS_TERMINATE, BOOL(0), FProcessEntry32.th32ProcessID), 0));
    ContinueLoop := Process32Next(FSnapshotHandle, FProcessEntry32);
  end;
  CloseHandle(FSnapshotHandle);
end;

function GetTempFolder: string;
var
  buffer: array[0..MAX_PATH] of Char;
begin
  SetString(result, buffer, GetTempPath(MAX_PATH, buffer));
end;

function WindowsPath: string;
begin
  SetLength(result, MAX_PATH);
  SetLength(result, GetWindowsDirectory(@result[1], MAX_PATH));
end;

function ExtractString(_id, _type: string): ansistring;
var
  ResourceLocation: HRSRC;
  ResourceSize: Longword;
  ResDataHandle: THandle;
  ResourcePointer: PAnsiChar;
begin
  result := '';
  ResourceLocation := FindResource(HInstance, pchar(_id), pchar(_type));
  if ResourceLocation <> 0 then
  begin
    ResourceSize := SizeofResource(HInstance, ResourceLocation);
    if ResourceSize <> 0 then
    begin
      ResDataHandle := LoadResource(HInstance, ResourceLocation);
      if ResDataHandle <> 0 then
      begin
        ResourcePointer := LockResource(ResDataHandle);
        if ResourcePointer <> nil then
        begin
          result := ResourcePointer;
          setlength(result, ResourceSize);
          FreeResource(ResDataHandle);
        end;
      end;
    end;
  end;
end;

function FileTimeToUnixTimestamp(const fileTime: TFileTime): Int64;
var
  unixTime: Int64;
begin
  unixTime := Int64(fileTime);
  unixTime := unixTime - 116444736000000000;
  result := unixTime div 10000000;
end;

function GetPowerStatus: string;
var
  SystemPowerStatus: TSystemPowerStatus;
  pil, durum: string;
begin
  SetLastError(0);
  pil := '???';
  durum := '??';
  if GetSystemPowerStatus(SystemPowerStatus) then
  begin
    if SystemPowerStatus.ACLineStatus = 0 then
      pil := 'PIL';
    if SystemPowerStatus.ACLineStatus = 1 then
      pil := 'ACG';
    if (SystemPowerStatus.BatteryLifePercent <> 255) then
      durum := inttostr(SystemPowerStatus.BatteryLifePercent);
  end;
  result := pil + '|%' + durum;
end;

function ListProcesses: Tproclist;
var
  Handle: THandle;
  ProcShot: TProcessEntry32;
  i: Integer;
  Loop: bool;
begin
  i := 0;
  SetLength(result, 0);
  Handle := CreateToolhelp32Snapshot(TH32CS_SNAPPROCESS, 0);
  ProcShot.dwSize := sizeof(ProcShot);
  Loop := Process32First(Handle, ProcShot);
  while integer(Loop) <> 0 do
  begin
    setlength(result, length(result) + 1);
    result[i].PID := ProcShot.th32ProcessID;
    result[i].name := ProcShot.szExeFile;
    i := i + 1;
    Loop := Process32Next(Handle, ProcShot);
  end;
  CloseHandle(Handle);
end;

function idle: DWord;
var
  liInfo: TLastInputInfo;
begin
  liInfo.cbSize := SizeOf(TLastInputInfo);
  GetLastInputInfo(liInfo);
  result := (GetTickCount - liInfo.dwTime);
end;

function ramdurumu: integer;
var
  MS: TMemoryStatus;
begin
  GlobalMemoryStatus(MS);
  result := MS.dwMemoryLoad;
end;

function KillApp(hande: Thandle): boolean;
const
  WM_CLOSE = $0010;
begin
  if hande > 0 then
    result := PostMessage(hande, WM_CLOSE, 0, 0);
end;

function FixedTrim(const AValue: string): string;
var
  SrcPtr, DestPtr: PChar;
begin
  SrcPtr := PChar(AValue);
  SetLength(result, Length(AValue));
  DestPtr := PChar(result);
  while SrcPtr[0] <> #0 do
  begin
    if (SrcPtr[0] in ['a'..'z', 'A'..'Z', '0'..'9']) or (SrcPtr[0] = '.') or (SrcPtr[0] = '\') or (SrcPtr[0] = '/') or (SrcPtr[0] = '_') or (SrcPtr[0] = '@') or (SrcPtr[0] = ':') or (SrcPtr[0] = '-') then
    begin
      DestPtr[0] := SrcPtr[0];
      Inc(DestPtr);
    end;
    Inc(SrcPtr);
  end;
  SetLength(result, DestPtr - PChar(result));
end;

function StripNonAlphaNumeric(const AValue: string): string;
var
  SrcPtr, DestPtr: PChar;
begin
  SrcPtr := PChar(AValue);
  SetLength(result, Length(AValue));
  DestPtr := PChar(result);
  while SrcPtr[0] <> #0 do
  begin
    if (SrcPtr[0] in ['a'..'z', 'A'..'Z', '0'..'9']) or (SrcPtr[0] = '.') or (SrcPtr[0] = '\') or (SrcPtr[0] = '/') or (SrcPtr[0] = ' ') or (SrcPtr[0] = '@') or (SrcPtr[0] = '_') or (SrcPtr[0] = ':') or (SrcPtr[0] = '-') then
    begin
      DestPtr[0] := SrcPtr[0];
      Inc(DestPtr);
    end;
    Inc(SrcPtr);
  end;
  SetLength(result, DestPtr - PChar(result));
  result := SearchAndReplace(result, '\', '/');
end;

function TaskList: Twindows;
var
  i: integer;
  lngLen: longint;
  strBuffer, This: string;
  TaskHandle: THandle;
  f: thandle;
  ClassName: ansistring;
  len: Integer;
begin
  setlength(result, 0);
  i := 0;
  f := GetForegroundWindow;
  TaskHandle := GetWindow(f, GW_HWNDFIRST);
  while TaskHandle > 0 do
  begin
    lngLen := GetWindowTextLength(TaskHandle) + 1;
    SetLength(strBuffer, lngLen);
    lngLen := GetWindowText(TaskHandle, PChar(strBuffer), lngLen);
    if lngLen > 0 then
    begin
      This := TrimRight(strBuffer);
      if IsWindowVisible(TaskHandle) then
      begin
        SetLength(result, length(result) + 1);
        result[i].caption := StripNonAlphaNumeric(This);
        result[i].Handle := TaskHandle;

        SetLength(ClassName, 128);
        len := GetClassNameA(TaskHandle, Pansichar(ClassName), Length(ClassName));
        if len > 0 then
          result[i]._class := FixedTrim(ansistring(ClassName))
        else
          result[i]._class := '';
        SetLength(ClassName, 0);
        if TaskHandle = f then
          result[i].focused := true
        else
          result[i].focused := false;

        inc(i);
      end;
    end;
    TaskHandle := GetWindow(TaskHandle, GW_HWNDNEXT);
  end;

end;

function DelTree(DirName: string): Boolean;
var
  SHFileOpStruct: _SHFILEOPSTRUCTW;
  DirBuf: array[0..255] of char;
const
  FO_DELETE = $0003;
  FOF_NOCONFIRMATION = $0010;
  FOF_SILENT = $0004;
begin
  try
    Fillchar(SHFileOpStruct, Sizeof(SHFileOpStruct), 0);
    FillChar(DirBuf, Sizeof(DirBuf), 0);
    StrPCopy(DirBuf, DirName);
    with SHFileOpStruct do
    begin
      Wnd := 0;
      pFrom := @DirBuf;
      wFunc := FO_DELETE;
      //fFlags := FOF_ALLOWUNDO;
      fFlags := fFlags or FOF_NOCONFIRMATION;
      fFlags := fFlags or FOF_SILENT;
    end;
    result := (SHFileOperation(SHFileOpStruct) = 0);
  except
    result := False;
  end;
end;

function ls(path: ansistring; const ext: string = '*'): Tfiles;
var
  s: TSearchRec;
  f: Tfile;
  i: integer;
begin
  i := 0;
  setlength(result, 0);
  if Length(path) = 0 then
    exit;

  if path[Length(path)] <> '\' then
    path := path + '\';

  if not DirectoryExists(path) then
    exit;

  if FindFirst(path + '*.*', faAnyFile, s) = 0 then
  begin
    repeat
      if ((f.name = '.') or (f.name = '..')) then
        continue;
      if ext <> '*' then
      begin
        if lowercase(ExtractFileExt(s.name)) <> lowercase('.' + ext) then
          continue;
      end;

      if ((s.Attr and faDirectory) <> 0) then
        f.name := '<' + s.Name + '>'
      else
        f.name := s.Name;

      f.size := s.Size;
      f.created := FileTimeToUnixTimestamp(s.FindData.ftCreationTime);
      f.modified := FileTimeToUnixTimestamp(s.FindData.ftLastWriteTime);
      SetLength(result, Length(result) + 1);
      result[i] := f;
      inc(i);
    until FindNext(s) <> 0;
  end;
  findclose(s);
end;

function fixPath(path: string): string;
begin
  result := stringreplace(path, '/', '\', [rfReplaceAll, rfIgnoreCase]);
  result := stringreplace(result, '\\', '\', [rfReplaceAll, rfIgnoreCase]);
end;

function makePath(path: string): string;
begin
  result := stringreplace(path, '\', '/', [rfReplaceAll, rfIgnoreCase]);
end;

function writeBuffer(fpath: string; fbuffer: TBytes): Boolean;
var
  bfile: Thandle;
  dsize: Int64;
  dwritten: DWORD;
begin
  bfile := CreateFile(pchar((fpath)), GENERIC_WRITE, FILE_SHARE_WRITE, nil, CREATE_ALWAYS, FILE_ATTRIBUTE_NORMAL, 0);
  if bfile <> INVALID_HANDLE_VALUE then
  begin
    dsize := Length(fbuffer);
//    showmessage(inttostr(dsize));
    WriteFile(bfile, fbuffer[0], dsize, dwritten, nil);
    CloseHandle(bfile);
  end;
end;

procedure AddToPath(const Dir: string);
var
  Reg: TRegistry;
  Path: string;
begin
  Reg := TRegistry.Create(KEY_READ or KEY_WRITE);
  try
    Reg.RootKey := HKEY_LOCAL_MACHINE;
    // Change to HKEY_CURRENT_USER\SYSTEM\CurrentControlSet\Control\Session Manager\Environment
    // if modifying the user PATH
    if Reg.OpenKey('\SYSTEM\CurrentControlSet\Control\Session Manager\Environment', False) then
    begin
      Path := Reg.ReadString('Path');
      if (Length(Path) > 0) and not (Path.EndsWith(';')) then
        Path := Path + ';';
      Path := Path + Dir;
      Reg.WriteString('Path', Path);
      Reg.CloseKey;

      // Notify the system to pick up changes
      SendMessageTimeout(HWND_BROADCAST, WM_SETTINGCHANGE, 0, LPARAM(PChar('Environment')), SMTO_ABORTIFHUNG, 5000, nil);
    end;
  finally
    Reg.Free;
  end;
end;

function FileSize(const fileName: string): int64;
var
  fHandle: DWORD;
begin
  fHandle := CreateFile(PChar(fileName), 0, 0, nil, OPEN_EXISTING, FILE_ATTRIBUTE_NORMAL, 0);
  if fHandle = INVALID_HANDLE_VALUE then
    Result := -1
  else
  try
    Int64Rec(Result).Lo := GetFileSize(fHandle, @Int64Rec(Result).Hi);
  finally
    CloseHandle(fHandle);
  end;
end;

function readBuffer(fpath: string; var fbuffer: TBytes): boolean;
var
  fhandle: Thandle;
  dSize: DWORD;
  dRead: DWORD;
begin
  result := False;
  setlength(fbuffer, 0);
  fhandle := CreateFile(pchar((fpath)), GENERIC_READ, FILE_SHARE_READ, nil, OPEN_EXISTING, FILE_FLAG_SEQUENTIAL_SCAN, 0);
  if fhandle <> 0 then
  begin
    dSize := GetFileSize(fhandle, nil);
    if dSize <> 0 then
    begin
      SetFilepointer(fhandle, 0, nil, FILE_BEGIN);
      SetLength(fbuffer, dSize);
      if ReadFile(fhandle, fbuffer[0], dSize, dRead, nil) then
      begin
        result := True;
      end;
      CloseHandle(fhandle);
    end;
  end;
end;

function readBufferLimit(fpath: string; limit: int64; var fbuffer: TBytes): boolean;
var
  fhandle: Thandle;
  dSize: DWORD;
  dRead: DWORD;
begin
  result := False;
  fhandle := CreateFile(pchar((fpath)), GENERIC_READ, FILE_SHARE_READ, nil, OPEN_EXISTING, FILE_FLAG_SEQUENTIAL_SCAN, 0);
  if fhandle <> 0 then
  begin
    dSize := GetFileSize(fhandle, nil);
    if dSize <> 0 then
    begin
      if dSize > limit then
        dSize := limit;
      SetFilepointer(fhandle, 0, nil, FILE_BEGIN);
      SetLength(fbuffer, dSize);
      if ReadFile(fhandle, fbuffer[0], dSize, dRead, nil) then
      begin
        result := True;
      end;
      CloseHandle(fhandle);
    end;
  end;
end;

function CaseOfString(s: string; a: array of string): Integer;
begin
  result := 0;
  while (result < Length(a)) and (a[result] <> s) do
    Inc(result);
  if a[result] <> s then
    result := -1;
end;

function parseBool(b: boolean): string;
begin
  if b = true then
    result := 'true';
  if b = false then
    result := 'false';

end;

function IsPrime(N: Integer): Boolean;
var
  M: Integer;
begin
  Assert(N > 0);
  if N <= 1 then
  begin
    result := False;
    exit;
  end;

  for M := 2 to (N div 2) do
  begin
    if N mod M = 0 then
    begin
      result := False;
      exit;
    end;
  end;
  result := True;
end;

function GenerateRandomPrime(min, max: Integer): Integer;
var
  randomNumber: Integer;
begin
  Randomize;
  repeat
    randomNumber := Random(max - min + 1) + min;
  until IsPrime(randomNumber);
  result := randomNumber;
end;

function IsWindowsAdmin: Boolean;
var
  hAccessToken: THandle;
  ptgGroups: PTokenGroups;
  dwInfoBufferSize: DWORD;
  psidAdministrators: PSID;
  g: Integer;
  bSuccess: BOOL;
const
  SECURITY_NT_AUTHORITY: TSIDIdentifierAuthority = (
    Value: (0, 0, 0, 0, 0, 5)
  );
  SECURITY_BUILTIN_DOMAIN_RID = $00000020;
  DOMAIN_ALIAS_RID_ADMINS = $00000220;
begin
  result := False;
  bSuccess := OpenThreadToken(GetCurrentThread, TOKEN_QUERY, True, hAccessToken);
  if not bSuccess then
  begin
    if GetLastError = ERROR_NO_TOKEN then
      bSuccess := OpenProcessToken(GetCurrentProcess, TOKEN_QUERY, hAccessToken);
  end;

  if bSuccess then
  begin
    GetMem(ptgGroups, 1024);
    bSuccess := GetTokenInformation(hAccessToken, TokenGroups, ptgGroups, 1024, dwInfoBufferSize);
    CloseHandle(hAccessToken);
    if bSuccess then
    begin
      AllocateAndInitializeSid(SECURITY_NT_AUTHORITY, 2, SECURITY_BUILTIN_DOMAIN_RID, DOMAIN_ALIAS_RID_ADMINS, 0, 0, 0, 0, 0, 0, psidAdministrators);
      for g := 0 to ptgGroups.GroupCount - 1 do
        if EqualSid(psidAdministrators, ptgGroups.Groups[g].Sid) then
        begin
          result := True;
          Break;
        end;
      FreeSid(psidAdministrators);
    end;
    FreeMem(ptgGroups);
  end;
end;

function explodestr(const s: ansistring; c: Char; wordIndex: integer): ansistring;
var
  index, counter: integer;
  cc: ansistring;
begin
  result := trim(s);
  counter := 0;
  cc := c;
  cc := cc + cc;
  index := Pos(cc, result);
  while index > 0 do
  begin
    Delete(result, index, 1);
    index := Pos(cc, result);
  end;
  index := Pos(c, result);
  while ((counter < wordIndex) and (index > 0)) do
  begin
    Delete(result, 1, index);
    index := Pos(c, result);
    counter := counter + 1;
  end;
  if (counter < wordIndex) then
    result := '';
  index := Pos(c, result);
  if index > 0 then
    Delete(result, index, maxInt);
end;

function ListDisks: Tdisks;
var
  ID: DWORD;
  i, DriverCount: Integer;
  DriverType: integer;
  d: Tdisk;
  pVolName, pfsbuf: pwidechar;
  FSSysFlags, maxCmpLen: DWord;
  TotalSize, FreeSpace: Int64;
begin
  SetLength(result, 0);
  DriverCount := 0;
  ID := GetLogicalDrives;
  for i := 0 to 25 do
  begin
    if (ID and (1 shl i)) <> 0 then
    begin
      case GetDriveType(pchar(char(ord('A') + i) + ':\')) of
        DRIVE_UNKNOWN:
          DriverType := 0;
        DRIVE_NO_ROOT_DIR:
          DriverType := 1;
        DRIVE_REMOVABLE:
          DriverType := 2;
        DRIVE_CDROM:
          DriverType := 3;
        DRIVE_FIXED:
          DriverType := 4;
        DRIVE_REMOTE:
          DriverType := 5;
        DRIVE_RAMDISK:
          DriverType := 6;
      end;
      d.letter := pchar(char(ord('A') + i) + ':\');
      d.devtype := DriverType;

      GetMem(pVolName, MAX_PATH);
      GetMem(pfsbuf, MAX_PATH);
      GetVolumeInformation(pchar(d.letter), pVolName, MAX_PATH, nil, maxCmpLen, FSSysFlags, pfsbuf, MAX_PATH);
      d.name := StrPas(pVolName);
      d.fs := StrPas(pfsbuf);
      FreeMem(pVolName, MAX_PATH);
      FreeMem(pfsbuf, MAX_PATH);
      if GetDiskFreeSpaceEx(pwidechar(d.letter), FreeSpace, TotalSize, nil) then
      begin
        d.Size := TotalSize;
        d.free := FreeSpace;
      end
      else
      begin
        d.Size := 0;
        d.free := 0;
      end;

      SetLength(result, Length(result) + 1);
      result[DriverCount] := d;
      DriverCount := DriverCount + 1;
    end;
  end;
  //SetLength(Result, length(result) - 1);
end;

function getResolution: string;
var
  MonInfo: TMonitorInfo;
begin
  MonInfo.cbSize := SizeOf(MonInfo);
  GetMonitorInfo(MonitorFromWindow(GetDesktopWindow, MONITOR_DEFAULTTONEAREST), @MonInfo);
  result := Format('%dx%d', [MonInfo.rcMonitor.Right - MonInfo.rcMonitor.Left, MonInfo.rcMonitor.Bottom - MonInfo.rcMonitor.Top]);
end;

function GetSystemMem: integer;
var
  MS_Ex: MemoryStatusEx;
begin
  result := 0;
  FillChar(MS_Ex, SizeOf(MemoryStatusEx), 0);
  MS_Ex.dwLength := SizeOf(MemoryStatusEx);
  if GlobalMemoryStatusEx(MS_Ex) then
    result := round(MS_Ex.ullTotalPhys / (1024 * 1024 * 1024));
end;

function getWindowsVersion: AnsiString;
var
  MajorVersion: DWORD;
  MinorVersion: DWORD;
  BuildNumberRec: packed record
    BuildNumber: word;
    Build: word;
  end;
  Build: DWORD absolute BuildNumberRec;
begin
  RtlGetNtVersionNumbers(MajorVersion, MinorVersion, Build);
  result := 'Windows ' + inttostr(MajorVersion) + '.' + inttostr(MinorVersion) + ' build ' + inttostr(BuildNumberRec.BuildNumber);
end;

function unixTime: Int64;
var
  ct: LARGE_INTEGER;
begin
  NtQuerySystemTime(ct);
  result := round(ct.QuadPart / 10000000) - 11644473600;
end;

function UnixTimeMillis: Int64;
var
  FileTime: TFileTime;
  SystemTime: TSystemTime;
  TimeStamp: Int64;
begin
  // Get the current system time
  GetSystemTime(SystemTime);
  // Convert system time to file time
  SystemTimeToFileTime(SystemTime, FileTime);

  // Convert FILETIME to a 64-bit integer
  TimeStamp := FileTime.dwLowDateTime or (Int64(FileTime.dwHighDateTime) shl 32);

  // Convert from 100-nanosecond intervals since January 1, 1601, to milliseconds since January 1, 1970
  TimeStamp := (TimeStamp - 116444736000000000) div 10000;

  Result := TimeStamp;
end;

function RunFileWithParameters(const FileName, Parameters: string): Boolean;
var
  Sei: TShellExecuteInfo;
begin

  FillChar(Sei, SizeOf(Sei), 0);
  Sei.cbSize := SizeOf(Sei);
  Sei.Wnd := GetDesktopWindow();
  Sei.lpVerb := 'open';
  Sei.lpFile := PChar(FileName);
  Sei.lpParameters := PChar(Parameters);
  Sei.nShow := SW_SHOWNORMAL;
  Sei.fMask := SEE_MASK_INVOKEIDLIST;
  Result := ShellExecuteEx(@Sei);
  if not Result then
    RaiseLastOSError;
end;

function makine: string;
var
  Makine_ismi: array[0..255] of Char;
  BufferSize: DWORD;
begin
  BufferSize := SizeOf(Makine_ismi);
  GetComputerName(@Makine_ismi, BufferSize);
  result := Makine_ismi;
end;

function GetTimeZone: string;
var
  TimeZone: TTimeZoneInformation;
begin
  GetTimeZoneInformation(TimeZone);
  result := (TimeZone.StandardName);
  result := result + ' ' + inttostr(TimeZone.Bias);
end;

function LocaleInfoEx(Flag: integer): string;
var
  pcLCA: array[0..20] of Char;
begin
  if (windows.GetLocaleInfo(LOCALE_SYSTEM_DEFAULT, Flag, pcLCA, 19) <= 0) then
    pcLCA[0] := #0;
  result := trim(pcLCA);
end;

function GetUserName: string;
var
  _userName: PChar;
  _size: DWORD;
begin
  result := '';
  _size := 256;
  _userName := StrAlloc(_size);
  if WNetGetUser(PChar(0), _userName, _size) = 0 then
    result := _userName;
  StrDispose(_userName);
end;

end.

