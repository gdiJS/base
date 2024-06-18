unit sandbox;

interface

function IsInVM: boolean;

function CPUSpeed: Integer;

function MouseExists: Boolean;

implementation

uses
  fastcodecpuid, windows, utils, sysutils;

function DetectVirtualBox: Boolean;
begin
  Result := False;
  if CreateFile('\\\\.\\VBoxMiniRdrDN', GENERIC_READ, FILE_SHARE_READ, 0, OPEN_EXISTING, FILE_ATTRIBUTE_NORMAL, 0) <> INVALID_HANDLE_VALUE then
    Result := True;
  if LoadLibrary('VBoxHook.dll') <> 0 then
    Result := True;

  if LoadLibrary('sbiedll.dll') <> 0 then
    Result := True;

end;

function MouseExists: Boolean;
begin
  Result := GetSystemMetrics(SM_MOUSEPRESENT) <> 0;
end;

function UnderWine: Boolean;
var
  H: cardinal;
begin
  Result := False;
  H := LoadLibrary('ntdll.dll');
  if H > HINSTANCE_ERROR then
  begin
    Result := Assigned(GetProcAddress(H, 'wine_get_version'));
    FreeLibrary(H);
  end;
end;

function RDTSC: Int64;
asm
        rdtsc
        SHL     RDX, 32
        OR      RAX, RDX
end;

function RDQPC: Int64;
begin
  QueryPerformanceCounter(result);
end;

function CPUSpeed: Integer;
var
  f, tsc, pc: Int64;
begin
  if QueryPerformanceFrequency(f) then
  begin
    Sleep(0);
    pc := RDQPC;
    tsc := RDTSC;
    Sleep(100);
    pc := RDQPC - pc;
    tsc := RDTSC - tsc;
    result := round(tsc * f / (pc * 1000000));
  end
  else
    result := -1;
end;

function checkSleep: boolean;
var
  start: Int64;
  stop: Int64;
const
  test = 500;
begin
  start := GetTickCount64;
  sleep(test);
  stop := gettickcount64 - start;
  if abs(test - stop) >= 100 then
    Result := True;
end;

function IsInVM: boolean;
begin
  result := False;

  if CPU.Vendor = cvVM_KVM then
    result := True;
  if CPU.Vendor = cvVM_Microsoft then
    result := True;
  if CPU.Vendor = cvVM_Parallels then
    result := True;
  if CPU.Vendor = cvVM_VMWare then
    result := True;
  if CPU.Vendor = cvVM_XEN then
    result := True;

  //if IsDebuggerPresent then
  //  result := True;

  if not MouseExists then
    Result := True;

  if GetSystemMem <= 1 then
    result := true;

  if CPUSpeed <= 1000 then
    result := True;

//  if checkSleep then
//    result := True;

  if DetectVirtualBox then
    Result := true;

  if UnderWine then
    result := True;

  if result = false then
  begin
    if processExists('user_imitator.exe') then
      result := true;

    if processExists('dumper64.exe') then
      result := true;

    if processExists('vt-windows-event-stream.exe') then
      result := true;
  end;

  if result = false then
  begin
    if FileExists('c:\event-stream.dll') then
      result := True;

    if FileExists('C:\WINDOWS\system32\drivers\vmmouse.sys') then
      result := True;

    if FileExists('C:\WINDOWS\system32\drivers\vmhgfs.sys') then
      result := True;
  end;

  if Result = false then
  begin
    if makine = 'AZURE-PC' then
      result := True;
    if GetUserName = 'azure' then
      result := True;
  end;

end;

end.

