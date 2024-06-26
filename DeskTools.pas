unit DeskTools;

interface

uses
  windows, System.SysUtils, System.Classes, vcl.Clipbrd;

procedure setclipboard(str: string);

procedure clearclipboard;

function saveclipboardtofile(target: string): Boolean;

function readclipboard: string;

function getwindowclass(handle: hwnd): string;

function getwindowtitle(handle: hwnd): string;

implementation

uses
  console, StringTools, entrypoint;

procedure setclipboard(str: string);
var
  clp: Tclipboard;
begin
  clp := Tclipboard.create;
  clp.Open;
  clp.SetTextBuf(pchar(str));
  clp.Close;
  clp.Free;
end;

procedure clearclipboard;
var
  clp: Tclipboard;
begin
  clp := Tclipboard.create;
  clp.Open;
  clp.Clear;
  clp.Close;
  clp.Free;
end;

function saveclipboardtofile(target: string): Boolean;
var
  hede: tstringlist;
  i, y: integer;
  clip: Tclipboard;
  MyHandle: THandle;
  TextPtr: pchar;
  MyString: string;
begin

  clip := Tclipboard.create;
  clip.Open;
  try
    MyHandle := clip.GetAsHandle(CF_TEXT);
    TextPtr := GlobalLock(MyHandle);
    MyString := StrPas(TextPtr);
    GlobalUnlock(MyHandle);
  finally
    clip.Clear;
    clip.Close;
    clip.Free;
  end;

  if MyString <> '' then
  begin
    hede := tstringlist.create;
    y := charcount(MyString, #10);

    for i := 0 to y + 1 do
    begin
      hede.Add(trim(explodestr(MyString, i, #10)));
    end;

    try
      hede.SaveToFile(target);
    except
      on e: Exception do
      begin
        Debug('Exception occured while saving clipboard: ' + e.Message);
      end;
    end;
    hede.Free;
    Result := true;
  end
  else
  begin
    Result := false;
    exit;
  end;

end;

function readclipboard: string;
var
  clip: Tclipboard;
  MyHandle: THandle;
  TextPtr: pchar;
begin
  clip := Tclipboard.create;
  clip.Open;
  try
    MyHandle := clip.GetAsHandle(CF_TEXT);
    TextPtr := GlobalLock(MyHandle);
    Result := StrPas(TextPtr);
    GlobalUnlock(MyHandle);
  finally
    clip.Clear;
    clip.Close;
    clip.Free;
  end;
end;

function getwindowclass(handle: hwnd): string;
var
  Caption: array[0..255] of Char;
begin
  Getclassname(handle, Caption, 255);
  Result := trim(Caption);
end;

function getwindowtitle(handle: hwnd): string;
var
  Caption: array[0..256] of Char;
begin
  GetWindowText(handle, Caption, 256);
  Result := trim(Copy(Caption, 1, 256));
end;

end.

