unit wmipc;

interface

uses
  Windows, classes, SysUtils, Messages;
  {
type
  TCopyDataStruct = record
    dwData: DWORD;
    cbData: DWORD;
    lpData: Pointer;
  end;
 {
  TCopyDataStruct = packed record
    dwData: DWORD_PTR;
    cbData: DWORD_PTR;
    lpData: Pointer;
  end;
  }

procedure wm_sendstringex(sender: HWND; target: hwnd; strtosend: string);

procedure wm_sendstring(sender: HWND; title: string; strtosend: string);

procedure wm_sendcommand(window: string; _message, command: Cardinal; const param: Cardinal = 0);

implementation

procedure wm_sendcommand(window: string; _message, command: Cardinal; const param: Cardinal = 0);
var
  receiverHandle: THandle;
begin
  try
    receiverHandle := FindWindow(nil, PChar(window));
    if receiverHandle <> 0 then
        SendMessage(receiverHandle, _message, command, param);
  except
    on e: exception do
    begin

    end;
  end;
end;

procedure wm_sendstring(sender: HWND; title: string; strtosend: string);
var
  copyDataStruct: TCopyDataStruct;
  receiverHandle: THandle;
begin
  try
    copyDataStruct.dwData := sender;
    CopyDataStruct.cbData := (Length(strtosend) + 1) * SizeOf(Char);
    copyDataStruct.lpData := PChar(strtosend);

    receiverHandle := FindWindow(nil, PChar(title));

    if receiverHandle <> 0 then
    begin
       SendMessage(receiverHandle, WM_COPYDATA, sender, LPARAM(@CopyDataStruct));
    end;

  except
    on e: exception do
    begin

    end;
  end;
end;


function GetWindowTitle(HWND: THandle): string;
var
  Buffer: array[0..255] of Char;
begin
  SetString(Result, Buffer, GetWindowText(HWND, Buffer, Length(Buffer)));
end;

function GetWindowClassName(HWND: THandle): string;
var
  Buffer: array[0..255] of Char;
begin
  SetString(Result, Buffer, GetClassName(HWND, Buffer, Length(Buffer)));
end;


procedure wm_sendstringex(sender: HWND; target: hwnd; strtosend: string);
var
  copyDataStruct: TCopyDataStruct;
begin

  if not iswindow(sender) then begin
     outputdebugstring(pchar('sendstring: sender hwnd is invalid'));
    exit;
  end;

  if not iswindow(target) then begin
     outputdebugstring(pchar('sendstring: target hwnd is invalid'));
    exit;
  end;

    outputdebugstring(pchar(GetWindowClassName(target)));
    outputdebugstring(pchar(GetWindowTitle(target)));

    outputdebugstring(pchar(strtosend));

    CopyDataStruct.dwData := sender;
    CopyDataStruct.cbData := (Length(strtosend) + 1) * SizeOf(Char);
    CopyDataStruct.lpData := PChar(strtosend);
    SendMessage(target, WM_COPYDATA, sender, LPARAM(@CopyDataStruct));
end;

end.

