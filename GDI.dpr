﻿program GDI;

{$SetPEFlags 1}
{$IF compilerversion >= 21.0}
{$WEAKLINKRTTI on}
{$RTTI EXPLICIT METHODS ([]) PROPERTIES ([]) fields ([])}
{$IFEND}

uses
  winapi.windows,
  System.SysUtils,
  classes,
  PsAPI,
  SpeechLib_TLB in 'SpeechLib_TLB.pas',
  jsTTS in 'jsTTS.pas',
  JSfilesystem in 'JSfilesystem.pas',
  JSajax in 'JSajax.pas',
  JSNatives in 'JSNatives.pas',
  jsdb in 'jsdb.pas',
  JSCrypt in 'JSCrypt.pas',
  jsRuntime in 'jsRuntime.pas',
  StringTools in 'StringTools.pas',
  jsproc in 'jsproc.pas',
  SetupApi in 'setupapi\SetupApi.pas',
  ModuleLoader in 'setupapi\ModuleLoader.pas',
  DeviceHelper in 'setupapi\DeviceHelper.pas',
  Common in 'setupapi\Common.pas',
  jshwinfo in 'jshwinfo.pas',
  JudithKernel in 'JudithKernel.pas',
  mod_keyhook in 'sources\natives\mod_keyhook.pas',
  keyhook in 'keyhook.pas',
  sndkey32tr in 'sndkey32tr.pas',
  psyapi in 'psyapi.pas',
  jstcp in 'jstcp.pas',
  entrypoint in 'entrypoint.pas',
  DeskTools in 'DeskTools.pas',
  mod_disk in 'sources\mod_disk\mod_disk.pas',
  udputils in 'udputils.pas',
  exceptions in 'exceptions.pas',
  utils in 'utils.pas',
  socket in 'socket.pas',
  threads in 'threads.pas',
  x64 in 'x64.pas',
  console in 'console.pas',
  logger in 'logger.pas',
  jsdownloader in 'jsdownloader.pas';

var
  Mutex: Thandle;

  {$R 'resources.RES'}

const
  MUTEXstr = 'JudithCore';
  apptitle = 'Judith';

procedure duplicatecheck;
begin
  Mutex := CreateMutex(NIL, False, pchar(MUTEXstr));
  if WaitForSingleObject(Mutex, 3000) = WAIT_TIMEOUT then
    TerminateProcess(GetCurrentProcess, 0);
end;

var
  msg: Tmsg;
  bRet: Boolean;
  err: RawByteString;
  i: integer;

type
  TTickThread = class(TThread)
  protected
    procedure Execute; override;
  public
    constructor Create;
  end;

constructor TTickThread.Create;
begin
  FreeOnTerminate := True;
  inherited Create(False);
end;

procedure TTickThread.Execute;
var
  start: int64;
begin
  start := gettickcount64;
  sleep(1000);
  while not Terminated do
  begin
    Synchronize(
      procedure
      begin
        err := judith.engine.FEngine.eval('vm._tick(' + inttostr(gettickcount64 - start) + ');', true);
      end);
    sleep(1);
  end;
end;

begin
{
mode 0: REPL session
mode 1: read only script execution, no input
mode 2: attach to existing console (cmd, conhost, powershell, terminal)
mode 3: hidden mode, no console
}

  root := extractfilepath(ParamStr(0));
  chdir(root);
  mode := 0;

  setlength(scripts, 0);

  if paramcount > 0 then
  begin
    mode := 1;
    for i := 1 to paramcount do
    begin
      if paramstr(i) = '--log' then
      begin
        log := Tlogger.create('engine.log');
        log.write('-- app start ' + datetimetostr(now));
        log.write('-- GDI.js v' + version_info);
        continue;
      end;
      if paramstr(i) = '--zombie' then
      begin
        nokill := true;
        continue;
      end;
      if paramstr(i) = '--hide' then
      begin
        mode := 2;
        continue;
      end;

      if paramstr(i) = '--new' then
      begin
        mode := 0;
        incel := true;
      end;

      if paramstr(i) = '--update' then
      begin
        update := true;
      end;

      if paramstr(i) = '--version' then
      begin
        printver := true;
      end;

      if paramstr(i) = '-v' then
      begin
        printver := true;
      end;

      if length(paramstr(i)) > 0 then
      begin
        if paramstr(i)[1] <> '-' then
        begin
          setlength(scripts, length(scripts) + 1);
          scripts[length(scripts) - 1] := paramstr(i);
        end;
      end;
    end;
  end;

  if mode < 2 then
  begin
    CreateDebugConsole;
  end;

  for I := Low(scripts) to High(scripts) do
  begin
    if not fileexists(scripts[i]) then
    begin
      debug('-- file not found: ' + scripts[i]);
      exit;
    end;
  end;

  judith := TJudith.create;
  ahandle := judith.window.handle;
  boot := True;

  //TTickThread.Create;

  repeat
    bRet := winapi.windows.GetMessage(msg, 0, 0, 0);
    if Int32(bRet) = -1 then
    begin
   //   OutputDebugString(PChar('Error in GetMessage: ' + IntToStr(GetLastError)));
      Break;
    end
    else
    begin
      TranslateMessage(msg);
      DispatchMessage(msg);
    end;
  until not bRet;

  __shutdown := True;
  judith.free;

  if Mutex > 0 then
  begin
    ReleaseMutex(Mutex);
    closehandle(Mutex);
  end;

end.

