unit jstts;

interface

uses
  windows, messages, sysutils, classes, system.hash, mod_tts, ActiveX, wmipc;

procedure renderText(handle: dword; text, character, path, id: string);

implementation

const
  timeout = 9000;

var
  rendering: Boolean;
  gvoices: Tstringlist;

function _md5(str: string): string;
begin
  Result := THashMD5.GetHashString(str);
end;

function getvoice(vname: string): string;
var
  i: integer;
begin
  Result := '';
  vname := trim((vname));
  if gvoices.Count > 0 then
  begin
    for i := 0 to gvoices.Count - 1 do
    begin
      if ansipos(vname, trim(gvoices.Strings[i])) > 0 then
      begin
        Result := gvoices.Strings[i];
        break;
      end;
    end;
  end;
end;

function gethash(sp, text: string): string;
begin
  Result := lowercase(_md5(getvoice(sp) + text));
end;

function makePath(path: string): string;
begin
  Result := stringreplace(path, '\', '/', [rfReplaceAll, rfIgnoreCase]);
end;

procedure debug(str: string);
begin
  OutputDebugStringA(Pansichar(AnsiString(str)));
end;

procedure renderText(handle: dword; text, character, path, id: string);
var
  T: TThread;
  f: string;
  S: TRTLCriticalSection;
begin
//  debug('tts render');

  if gvoices.Count > 0 then
  begin
    f := path + gethash(character, text) + '.wav';
    if fileexists(f) then
    begin
    //  debug('tts cache hit: ' + text);
      wm_sendstringex(handle, handle, pwidechar('~eval=' + id + '(' + quotedstr(f) + ',0);' + id + '=undefined;'));
      exit;
    end;
  end;

  InitializeCriticalSection(S);
  T := TThread.CreateAnonymousThread(
    procedure
    var
      filename: string;
      tts: Tsapi;
      start: int64;
    begin
//      debug('tts thread start');
      start := gettickcount64;
      while rendering = true do
      begin
        if gettickcount64 - start > timeout then
        begin
          rendering := False;
          break;
        end;
        sleep(1);
      end;

      rendering := true;
      EnterCriticalSection(S);
      coInitialize(nil);
      tts := Tsapi.create;
      if gvoices.Count <= 0 then
        tts.enumvoices(gvoices);
      tts.SetVoice(character);
      OutputDebugString(pchar(character));
      filename := makePath(tts.render(text, path));
      wm_sendstringex(handle, handle, pwidechar('~eval=' + id + '(' + quotedstr(filename) + ',' + inttostr(gettickcount - start) + ');' + id + '=undefined;'));
      sleep(1);
      tts.free;
      LeaveCriticalSection(S);
      rendering := False;
    end);
  T.FreeOnTerminate := true;
  T.start;

end;

procedure speakFast(handle: dword; text, character, path, id: string);
var
  T: TThread;
  f: string;
  S: TRTLCriticalSection;
begin
  debug('tts start');
  InitializeCriticalSection(S);
  T := TThread.CreateAnonymousThread(
    procedure
    var
      filename: string;
      tts: Tsapi;
      start: int64;
    begin
      debug('tts thread start');
      start := gettickcount;
      EnterCriticalSection(S);
      coInitialize(nil);
      tts := Tsapi.create;
      if gvoices.Count <= 0 then
        tts.enumvoices(gvoices);
      tts.SetVoice(character);
      OutputDebugString(pchar(character));
      filename := makePath(tts.render(text, path));
      wm_sendstringex(handle, handle, pwidechar('~eval=' + id + '(' + quotedstr(filename) + ',' + inttostr(gettickcount - start) + ');' + id + '=undefined;'));
      sleep(1);
      tts.free;
      LeaveCriticalSection(S);
      rendering := False;
    end);
  T.FreeOnTerminate := true;
  T.start;

end;

initialization
  gvoices := Tstringlist.create;

end.

