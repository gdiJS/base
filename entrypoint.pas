unit entrypoint;

interface

uses
  windows, System.SysUtils, jsruntime, judithkernel, classes, logger;

const
  version_info = '0.2';
  version_arch = 'x64';
  version_date = 'May 2024';
  version_info_long = version_arch + ' | ' + 'v' + version_info + ' | ' + version_date;
  logfilename = 'engine.log';
  libpath = '';

var
  __shutdown: Boolean;
  __done: Boolean;
  boot: Boolean;
  root: string;
  ahandle: THandle;
  index: string;
  WM_JUDITH: DWORD;
  judith: Tjudith;
  mode: integer;
  nokill: boolean;
  scripts: array of string;
  log: Tlogger;
  killedparent: boolean;
  parentid: cardinal;
  repl: boolean;
  incel: boolean;
  printver:boolean;
  update:boolean;


implementation

uses
  console;

procedure debug(text: string);
begin
  if assigned(log) then
    log.write(text);
  if mode = 3 then
    MessageBox(GetForegroundWindow, pchar(text), pchar('GDI.js'), MB_ICONWARNING or MB_OK)
  else
    WriteColoredText(text, FOREGROUND_NORMAL);
end;

end.

