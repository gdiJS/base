unit psyapi;

interface

uses
  windows, System.SysUtils, System.Classes, tlhelp32, psapi;

function GetUserName: string;

procedure readdir(yol: string; liste: Tstringlist);

function isdirectoryavailable(path: string): boolean;

function DiskInDrive(Drive: Char): boolean;

function Disk_free(Drive: Char): Int64;

function StripTag(S: string; const delim1: Char = '['; const delim2: Char = ']'): string;

function explodestr(const S: string; wordIndex: integer; karakter: Char): string;

function makePath(path: string): string;

function fixPath(path: string): string;

function LocaleInfoEx(Flag: integer): string;

function GetTimeZone: string;

function makine: string;

function GetParentProcessName: string;

procedure KillParentProcess;
function GetParentProcessID: DWORD;

implementation

function GetParentProcessID: DWORD;
var
  Snapshot: THandle;
  ProcessEntry: TProcessEntry32;
begin
  Result := 0;
  Snapshot := CreateToolhelp32Snapshot(TH32CS_SNAPPROCESS, 0);
  if Snapshot <> INVALID_HANDLE_VALUE then
  try
    ProcessEntry.dwSize := SizeOf(ProcessEntry);
    if Process32First(Snapshot, ProcessEntry) then
      repeat
        if ProcessEntry.th32ProcessID = GetCurrentProcessId then
        begin
          Result := ProcessEntry.th32ParentProcessID;
          Break;
        end;
      until not Process32Next(Snapshot, ProcessEntry);
  finally
    CloseHandle(Snapshot);
  end;
end;

procedure KillParentProcess;
var
  ParentPID: DWORD;
  hParent: THandle;
begin
  ParentPID := GetParentProcessID;
  if ParentPID <> 0 then
  begin
    hParent := OpenProcess(PROCESS_TERMINATE, False, ParentPID);
    if hParent <> 0 then
    try
      if not TerminateProcess(hParent, 0) then
        RaiseLastOSError;
    finally
      CloseHandle(hParent);
    end
    else
      RaiseLastOSError;
  end
  else
    Writeln('Parent process not found or current process is the root.');
end;

function GetParentProcessName: string;
const
  BufferSize = 4096;
var
  HandleSnapShot: THandle;
  EntryParentProc: TProcessEntry32;
  CurrentProcessId: THandle;
  HandleParentProc: THandle;
  ParentProcessId: THandle;
  ParentProcessFound: Boolean;
  ParentProcPath: string;
begin
  ParentProcessFound := False;
  HandleSnapShot := CreateToolhelp32Snapshot(TH32CS_SNAPPROCESS, 0);
  if HandleSnapShot <> INVALID_HANDLE_VALUE then
  begin
    EntryParentProc.dwSize := SizeOf(EntryParentProc);
    if Process32First(HandleSnapShot, EntryParentProc) then
    begin
      CurrentProcessId := GetCurrentProcessId();
      repeat
        if EntryParentProc.th32ProcessID = CurrentProcessId then
        begin
          ParentProcessId := EntryParentProc.th32ParentProcessID;
          HandleParentProc := OpenProcess(PROCESS_QUERY_INFORMATION or PROCESS_VM_READ, False, ParentProcessId);
          if HandleParentProc <> 0 then
          begin
            ParentProcessFound := True;
            SetLength(ParentProcPath, BufferSize);
            GetModuleFileNameEx(HandleParentProc, 0, PChar(ParentProcPath), BufferSize);
            ParentProcPath := PChar(ParentProcPath);
            CloseHandle(HandleParentProc);
          end;
          Break;
        end;
      until not Process32Next(HandleSnapShot, EntryParentProc);
    end;
    CloseHandle(HandleSnapShot);
  end;
  if ParentProcessFound then
    Result := ParentProcPath
  else
    Result := '';
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
  result := IntToStr(TimeZone.Bias div  - 60);
end;

function LocaleInfoEx(Flag: integer): string;
var
  pcLCA: array[0..20] of Char;
begin
  if (windows.GetLocaleInfo(LOCALE_SYSTEM_DEFAULT, Flag, pcLCA, 19) <= 0) then
    pcLCA[0] := #0;
  result := trim(pcLCA);
end;

function fixPath(path: string): string;
begin
  result := stringreplace(path, '/', '\', [rfReplaceAll, rfIgnoreCase]);
end;

function makePath(path: string): string;
begin
  result := stringreplace(path, '\', '/', [rfReplaceAll, rfIgnoreCase]);
end;

function explodestr(const S: string; wordIndex: integer; karakter: Char): string;
var
  index, counter: integer;
begin
  result := trim(S);
  counter := 0;
  index := Pos(karakter + karakter, result);
  while index > 0 do
  begin
    Delete(result, index, 1);
    index := Pos(karakter + karakter, result);
  end;
  index := Pos(karakter, result);
  while ((counter < wordIndex) and (index > 0)) do
  begin
    Delete(result, 1, index);
    index := Pos(karakter, result);

    counter := counter + 1;
  end;
  if (counter < wordIndex) then
    result := '';
  index := Pos(karakter, result);
  if index > 0 then
    Delete(result, index, maxInt);
end;

function StripTag(S: string; const delim1: Char = '['; const delim2: Char = ']'): string;
var
  TagBegin, TagEnd, TagLength: integer;
begin
  TagBegin := Pos(delim1, S);
  while (TagBegin > 0) do
  begin
    TagEnd := Pos(delim2, S);
    TagLength := TagEnd - TagBegin + 1;
    Delete(S, TagBegin, TagLength);
    TagBegin := Pos(delim1, S);
  end;
  result := S;
end;

function DiskInDrive(Drive: Char): boolean;
var
  errormode: WORD;
begin
  if Drive in ['a'..'z'] then
    Dec(Drive, $20);
    { make sure it's a letter }
  errormode := SetErrorMode(SEM_FailCriticalErrors);
  try
      { drive 1 = a, 2 = b, 3 = c, etc. }
    if DiskSize(Ord(Drive) - $40) = -1 then
      result := False
    else
      result := True;
  finally
      { restore old error mode }
    SetErrorMode(errormode);
  end;
end;

function Disk_free(Drive: Char): Int64;
begin
  result := Diskfree(Ord(Drive) - 64);
end;

function isdirectoryavailable(path: string): boolean;
var
  chr: Char;
begin
  result := False;

  if path <> '' then
  begin
    chr := path[1];
    result := ((DiskInDrive(chr)) and (Disk_free(chr) > (1024 * 10)));
  end;

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

procedure readdir(yol: string; liste: Tstringlist);
var
  SR: TSearchRec;
  DirList: Tstringlist;
  IsFound: boolean;
  i: integer;
begin
  try
    if yol[length(yol)] <> '\' then
      yol := yol + '\';
    IsFound := FindFirst(yol + '*.*', faAnyFile - faDirectory, SR) = 0;

    while IsFound do
    begin
      liste.add(yol + SR.Name);
      IsFound := FindNext(SR) = 0;
    end;
    FindClose(SR);

    DirList := Tstringlist.Create;
    IsFound := FindFirst(yol + '*.*', faAnyFile, SR) = 0;
    while IsFound do
    begin
      if ((SR.Attr and faDirectory) <> 0) and (SR.Name[1] <> '.') then
        DirList.add(yol + SR.Name);
      IsFound := FindNext(SR) = 0;
    end;
    FindClose(SR);

    for i := 0 to DirList.Count - 1 do
      readdir(DirList[i], liste);
    DirList.Free;
  finally
    ZeroMemory(@SR, SizeOf(SR));
  end;
end;

end.

