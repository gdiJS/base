unit logger;

interface

uses
  windows, messages, sysutils;

type
  Tlogger = class
    constructor create(filename: string);
    destructor free;
    procedure write(text: string);
  private
    hFile: THandle;
  end;

implementation

constructor Tlogger.create(filename: string);
begin
  hFile := CreateFile(PChar(filename), GENERIC_WRITE, FILE_SHARE_READ, nil, OPEN_ALWAYS, FILE_ATTRIBUTE_NORMAL, 0);

  if hFile = INVALID_HANDLE_VALUE then
  begin
    RaiseLastOSError;
  end
end;

procedure Tlogger.write(text: string);
var
  dwWritten: DWORD;
  Buffer: TBytes;
begin
  try
    SetFilePointer(hFile, 0, nil, FILE_END);
    Buffer := TEncoding.ANSI.GetBytes(text + #13#10);
    WriteFile(hFile, Buffer[0], Length(Buffer), dwWritten, nil);
  finally
  end;
end;

destructor Tlogger.free;
begin
  CloseHandle(hFile);
  inherited free;
end;

end.

