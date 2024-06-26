﻿unit console;

interface

uses
  classes, sysutils, windows, messages, stringtools, StrUtils, tlhelp32, utils;

const
  BACKGROUND_BLACK = 0;
  BACKGROUND_BLUE = BACKGROUND_BLUE;
  BACKGROUND_GREEN = BACKGROUND_GREEN;
  BACKGROUND_RED = BACKGROUND_RED;
  BACKGROUND_INTENSITY = BACKGROUND_INTENSITY;
  FOREGROUND_BLACK = 0;
  FOREGROUND_ORANGE = FOREGROUND_RED or FOREGROUND_GREEN;
  BACKGROUND_ORANGE = BACKGROUND_RED or BACKGROUND_GREEN;
  FOREGROUND_LIGHT_RED = FOREGROUND_RED or FOREGROUND_INTENSITY;
  FOREGROUND_LIME = FOREGROUND_GREEN or FOREGROUND_INTENSITY;
  FOREGROUND_YELLOW = FOREGROUND_RED or FOREGROUND_GREEN or FOREGROUND_INTENSITY;
  BACKGROUND_YELLOW = BACKGROUND_RED or BACKGROUND_GREEN or BACKGROUND_INTENSITY;
  FOREGROUND_NORMAL = FOREGROUND_INTENSITY or FOREGROUND_RED or FOREGROUND_GREEN or FOREGROUND_BLUE;
  motd: array[0..7] of string = ('      ┏┓      ┏┓', '╋╋╋╋╋╋┃┃╋╋╋╋╋╋┃┃╋╋╋', '┏━━┓┏━┛┃┏┓╋╋╋╋┃┣━━┓', '┃┏┓┃┃┏┓┃┣┫╋╋┏┓┃┃━━┫', '┃┗┛┃┃┗┛┃┃┃┏┓┃┗┛┣━━┃', '┗━┓┃┗━━┛┗┛┗┛┗━━┻━━┛', '┏━┛┃╋╋╋╋╋╋╋╋╋╋╋╋╋╋╋', '┗━━┛');

type
  TConsoleReaderThread = class(TThread)
  protected
    procedure Execute; override;
  public
    constructor Create;
  end;

procedure WriteColoredText(const Text: string; color: word);

procedure SetConsoleColorEx(Color: Word);

procedure RedirectIOToConsole;

procedure CreateDebugConsole;

procedure debug(str: string);

procedure WriteMotd;

function FlushConsoleInputBuffer(hConsoleInput: THandle): BOOL; stdcall; external 'kernel32.dll';

implementation

uses
  entrypoint, psyapi, jsfilesystem, jsajax;

var
  memory: array of string;
  ConsoleOutput: THandle;
  InputHandle: THandle;

procedure initmem;
begin
  setlength(memory, 0);
end;

procedure savemem(filename: string);
var
  hFile: THandle;
  i: integer;
  Buffer: TBytes;
  dwWritten: DWORD;
begin
  hFile := CreateFile(PChar(filename), GENERIC_WRITE, FILE_SHARE_READ, nil, OPEN_ALWAYS, FILE_ATTRIBUTE_NORMAL, 0);
  if hFile = INVALID_HANDLE_VALUE then
  begin
    RaiseLastOSError;
    exit;
  end;

  for i := Low(memory) to High(memory) do
  begin
    SetFilePointer(hFile, 0, nil, FILE_END);
    Buffer := TEncoding.ANSI.GetBytes(memory[i] + #13#10);
    WriteFile(hFile, Buffer[0], Length(Buffer), dwWritten, nil);
  end;
  CloseHandle(hFile);
end;

procedure addmem(str: string);
begin
  setlength(memory, length(memory) + 1);
  memory[length(memory) - 1] := str;
end;

function ReadUnicodeString: string;
var
  Buffer: array[0..255] of WideChar;
  CharsRead: Cardinal;
begin
  FillChar(Buffer, SizeOf(Buffer), 0);
  ReadConsoleW(InputHandle, @Buffer, Length(Buffer), CharsRead, nil);
  SetLength(Result, CharsRead);
  if CharsRead > 0 then
    Move(Buffer, Result[1], CharsRead * SizeOf(WideChar));
end;

procedure WriteToConsole(const S: string);
var
  Written: Cardinal;
begin
  WriteConsoleW(ConsoleOutput, PChar(S), Length(S), Written, nil);
  addmem(S);
  Written := 0;
  writeln('');
end;

procedure micromotd;
begin
  writeln('GDI.js | ' + version_info_long);
end;

procedure minimotd;
begin
  SetConsoleColorEx(FOREGROUND_BLACK or BACKGROUND_RED or BACKGROUND_GREEN or BACKGROUND_BLUE);
  write(' GDI.js ');
  SetConsoleColorEx(FOREGROUND_RED);
  write('█');
  SetConsoleColorEx(FOREGROUND_YELLOW);
  write('▓');
  SetConsoleColorEx(FOREGROUND_LIME);
  write('▓');
  SetConsoleColorEx(FOREGROUND_GREEN);
  write('▒');
  SetConsoleColorEx(FOREGROUND_BLUE or FOREGROUND_INTENSITY);
  write('░');
  SetConsoleColorEx(FOREGROUND_BLUE);
  write('░');
  SetConsoleColorEx(FOREGROUND_NORMAL);
  writeln('');
  SetConsoleColorEx(FOREGROUND_BLACK or BACKGROUND_RED or BACKGROUND_GREEN or BACKGROUND_BLUE);
  writeln(' ' + version_info_long);
end;

procedure debug(str: string);
begin
  WriteToConsole(str);
end;

procedure SetConsoleTitleEx(const Title: string);
begin
  SetConsoleTitle(PChar(Title));
end;

procedure SetConsoleIcon(Icon: HICON);
var
  ConsoleHandle: HWND;
begin
  ConsoleHandle := GetConsoleWindow();
  SendMessage(ConsoleHandle, WM_SETICON, ICON_BIG, Icon);
end;

procedure ClrScr;
var
  I: Integer;
  _Pos: TCoord;
  Info: TConsoleScreenBufferInfo;
  Output: DWORD;
begin
  GetConsoleScreenBufferInfo(ConsoleOutput, Info);
  _Pos.X := 0;
  _Pos.Y := 0;
  SetConsoleCursorPosition(ConsoleOutput, _Pos);
  for I := 0 to 255 do
  begin
    _Pos.X := 0;
    _Pos.Y := I;
    FillConsoleOutputCharacter(ConsoleOutput, #32, 255, _Pos, Output);
    FillConsoleOutputAttribute(ConsoleOutput, Info.wAttributes, 255, _Pos, Output);
  end;
end;

procedure AdjustConsoleMode;
var
  Mode: DWORD;
begin
  if GetConsoleMode(InputHandle, Mode) then
  begin
    Mode := Mode and not (ENABLE_LINE_INPUT or ENABLE_ECHO_INPUT);
    SetConsoleMode(InputHandle, Mode);
  end
  else
    WriteLn('Error getting console mode');
end;

procedure SetConsoleModeEx;
var
  InputHandle, OutputHandle: THandle;
  Mode: DWORD;
begin
  InputHandle := GetStdHandle(STD_INPUT_HANDLE);
  OutputHandle := GetStdHandle(STD_OUTPUT_HANDLE);

  // Get current mode and add or remove flags as needed
  if GetConsoleMode(InputHandle, Mode) then
  begin
    Mode := Mode or ENABLE_ECHO_INPUT or ENABLE_LINE_INPUT; // Ensure echo and line input
    SetConsoleMode(InputHandle, Mode);
  end
  else
    WriteLn('Error getting input console mode');

  if GetConsoleMode(OutputHandle, Mode) then
  begin
    Mode := Mode or ENABLE_PROCESSED_OUTPUT or ENABLE_WRAP_AT_EOL_OUTPUT; // Proper output processing
    SetConsoleMode(OutputHandle, Mode);
  end
  else
    WriteLn('Error getting output console mode');
end;

procedure CreateDebugConsole;
var
  MyIcon: HICON;
  attached: boolean;
begin

  if (incel = false) and (AttachConsole(ATTACH_PARENT_PROCESS)) then
  begin
    attached := True;

    ConsoleOutput := GetStdHandle(STD_OUTPUT_HANDLE);
    InputHandle := GetStdHandle(STD_INPUT_HANDLE);

    AdjustConsoleMode;
    SetConsoleModeEx;
    SetConsoleCP(CP_UTF8);
    SetConsoleOutputCP(CP_UTF8);
    Mode := 2;
  end
  else
  begin
    AllocConsole;
    ConsoleOutput := GetStdHandle(STD_OUTPUT_HANDLE);
    InputHandle := GetStdHandle(STD_INPUT_HANDLE);

    SetConsoleCP(CP_UTF8);
    SetConsoleOutputCP(CP_UTF8);
  end;

  if printver = true then
  begin
    write('GDI.js ' + version_info_long + #13#10);
    FreeConsole;
    terminateprocess(getcurrentprocess, 0);
  end;

  MyIcon := LoadIcon(hInstance, 'MAINICON');
  SetConsoleIcon(MyIcon);

  if Mode = 0 then
    WriteMotd;
  if Mode = 1 then
    minimotd;

  if Mode = 2 then
    micromotd;

  if (Mode = 2) or (Mode = 0) then
  begin
    repl := true;
    initmem;
  end;

  if attached = True and repl = true then
  begin
    KillParentProcess;
    ClrScr;
  end;

  Setconsolecolorex(FOREGROUND_INTENSITY);
  write('>> ');
  SetConsoleColorEx(FOREGROUND_NORMAL);
  RedirectIOToConsole;

  SetConsoleTitleEx('GDI.js - v' + version_info);
  TConsoleReaderThread.Create;
end;

constructor TConsoleReaderThread.Create;
begin
  FreeOnTerminate := True;
  inherited Create(False);
end;

procedure TConsoleReaderThread.Execute;
var
  res: string;
  InputHandle: THandle;
  Buffer: array[0..255] of WideChar;
  CharsRead: Cardinal;
  uinput, ubuffer: string;
  param: string;
//  response: TAjaxResponse;
begin
  InputHandle := GetStdHandle(STD_INPUT_HANDLE);
  FillChar(Buffer, SizeOf(Buffer), 0);

  while not Terminated do
  begin
    ReadConsoleW(InputHandle, @Buffer, Length(Buffer), CharsRead, nil);
    if CharsRead > 0 then
    begin
      SetLength(ubuffer, CharsRead);
      move(Buffer, ubuffer[1], CharsRead * SizeOf(WideChar));
      for var i := 1 to length(ubuffer) do
      begin
        if Ord(ubuffer[i]) = 13 then
        begin
          uinput := trim(uinput);
          if length(uinput) > 0 then
          begin

            case CaseOfString(explodestr(uinput, 0, ' '), ['exit', 'save', 'load', 'clear', 'help', 'update']) of
              0:
                begin
                  FreeConsole;
                  terminateprocess(Getcurrentprocess, 0);
                end;
              1:
                begin
                  param := explodestr(uinput, 1, ' ');
                  if param = '' then
                    param := 'REPL.log';
                  savemem(param);
                  writeln('-- session saved to file: ' + param);
                end;
              2:
                begin
                  param := explodestr(uinput, 1, ' ');
                  if param = '' then
                  begin
                    writeln('-- usage: load filename.js');
                  end
                  else
                  begin
                    if fileexists(param) then
                    begin
                      Synchronize(
                        procedure
                        begin
                          judith.engine.FEngine.eval(LoadFileToStr(param));
                        end);
                    end
                    else
                      writeln('-- file not found: ' + param);
                  end;

                end;
              3:
                begin
                  ClrScr;
                  initmem;
                end;
              4:
                begin
                  writeln('-- REPL commands');
                  writeln('save     save screen buffer to file');
                  writeln('load     load script from file');
                  writeln('clear    clear screen');
                  writeln('help     this list');
                  writeln('update   update runtime from server');
                  writeln('exit     terminate session');
                end;
              5:
                begin
                  writeln('-- checking for updates..');
                  Synchronize(
                    procedure
                    begin
                      judith.engine.EvalFromRes('update');
                    end);
                end;
            else
              Synchronize(
                procedure
                begin
                  addmem('>> ' + uinput);
                  if (pos(' ', uinput) = 0) and (pos('(', uinput) = 0) and (pos(';', uinput) = 0) then
                  begin
                    res := judith.engine.FEngine.eval('typeof ' + uinput, true);
                    if res = 'object' then
                      judith.engine.FEngine.eval('console.log(' + uinput + ');')
                    else if res = 'function' then
                      WriteColoredText('[function]', FOREGROUND_INTENSITY)
                    else
                      judith.engine.FEngine.eval(uinput);
                  end
                  else
                    judith.engine.FEngine.eval(uinput);
                end);
            end;
          end
          else
          begin
            Setconsolecolorex(FOREGROUND_INTENSITY);
            write('>> ');
            Setconsolecolorex(FOREGROUND_NORMAL);
          end;

          FlushConsoleInputBuffer(InputHandle);
          ubuffer := '';
          uinput := '';
          break;
        end
        else
          uinput := uinput + ubuffer[i];
      end;
    end;
  end;
end;

procedure RedirectIOToConsole;
var
  hOut: THandle;
  hIn: THandle;
begin
  hOut := CreateFile('CONOUT$', GENERIC_WRITE, FILE_SHARE_WRITE, nil, OPEN_EXISTING, FILE_ATTRIBUTE_NORMAL, 0);
  SetStdHandle(STD_OUTPUT_HANDLE, hOut);
  hIn := CreateFile('CONIN$', GENERIC_READ, FILE_SHARE_READ, nil, OPEN_EXISTING, FILE_ATTRIBUTE_NORMAL, 0);
  SetStdHandle(STD_INPUT_HANDLE, hIn);

  System.Assign(Output, 'CONOUT$');
  System.Rewrite(Output);
  System.Assign(input, 'CONIN$');
  System.Reset(input);
end;

procedure SetConsoleColorEx(Color: Word);
begin
  SetConsoleTextAttribute(ConsoleOutput, Color);
end;

procedure WriteColoredText(const Text: string; color: Word);
begin
  if Mode = 3 then
    exit;

  if Mode = 2 then
  begin
    addmem(Text);
    writeln(Text);
    exit;
  end;

  if ConsoleOutput <> INVALID_HANDLE_VALUE then
  begin
    SetConsoleColorEx(color);
    WriteToConsole(Text);
    SetConsoleColorEx(FOREGROUND_NORMAL);
  end;

  Setconsolecolorex(FOREGROUND_INTENSITY);
  write('>> ');
  SetConsoleColorEx(FOREGROUND_NORMAL);

end;

procedure SetConsoleFontSize(const Width, Height: Short);
var
  ConsoleHandle: THandle;
  ConsoleFontInfo: CONSOLE_FONT_INFOEX;
begin
  ConsoleHandle := GetStdHandle(STD_OUTPUT_HANDLE);
  FillChar(ConsoleFontInfo, SizeOf(CONSOLE_FONT_INFOEX), 0);
  ConsoleFontInfo.cbSize := SizeOf(CONSOLE_FONT_INFOEX);
  GetCurrentConsoleFontEx(ConsoleHandle, False, ConsoleFontInfo);

  ConsoleFontInfo.dwFontSize.X := Width; // Width of each character in pixels
  ConsoleFontInfo.dwFontSize.Y := Height; // Height

  SetCurrentConsoleFontEx(ConsoleHandle, False, ConsoleFontInfo);
end;

procedure WriteMotd;
var
  I, c: Integer;
begin
  SetConsoleFontSize(6, 18);

  for I := Low(motd) to High(motd) do
  begin

    for c := 0 to length(motd[I]) do
    begin

      if (c < 26) and (motd[I][c] = '╋') then
        setConsolecolorex(FOREGROUND_BLUE)
      else
      begin
        if c in [0..4] then
          SetConsoleColorEx(FOREGROUND_GREEN);

        if c in [5..8] then
          SetConsoleColorEx(FOREGROUND_GREEN or FOREGROUND_INTENSITY);

        if c in [9..10] then
          SetConsoleColorEx(FOREGROUND_GREEN);

        if c in [11..12] then
          SetConsoleColorEx(FOREGROUND_INTENSITY);

        if c in [13..17] then
          SetConsoleColorEx(FOREGROUND_GREEN or FOREGROUND_INTENSITY);

        if c in [16..20] then
          SetConsoleColorEx(FOREGROUND_GREEN);

      end;
      write(motd[I][c]);

    end;

    writeln('');

  //  writeln(' ' + motd[I] + ' ');
  end;
  writeln(version_info_long);

end;

end.

