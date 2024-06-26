unit JSfilesystem;

interface

uses
  windows, System.IOUtils, System.strutils, System.types, System.SysUtils,
  classes;

procedure StringtoFileUTF8(Filename, Line: string; const Append: boolean = false);

function BrowseFolder(folder: string): widestring;

function appendText(fn, text: string): boolean;

function LoadFileToStr(const FileName: TFileName): string;

implementation

function appendText(fn, text: string): boolean;
begin
  if not FileExists(fn) then
    FileCreate(fn);
  TFile.AppendAllText(fn, text);
  result := True;
end;

function BrowseFolder(folder: string): widestring;
var
  LList: TStringDynArray;
  I: Integer;
  LSearchOption: TSearchOption;
begin
    { Select the search option }
    // if cbDoRecursive.Checked then
    // LSearchOption := TSearchOption.soAllDirectories
    // else
  LSearchOption := TSearchOption.soTopDirectoryOnly;

  try
    LList := TDirectory.GetFiles(folder, '*.*', LSearchOption);

      // LList := TDirectory.GetFileSystemEntries(edtPath.Text, LSearchOption, nil);
      // LList := TDirectory.GetDirectories(edtPath.Text, edtFileMask.Text, LSearchOption);
  except      { Catch the possible exceptions }
      // MessageDlg('Incorrect path or search mask', mtError, [mbOK], 0);
    Exit;
  end;
  Result := '[';
  for I := 0 to Length(LList) - 1 do
    Result := Result + '"' + ReplaceStr(LList[I], '\', '/') + '"' + ',';
  delete(Result, Length(Result), 1);
  Result := Result + ']';
end;

function LoadFileToStr(const FileName: TFileName): string;
var
  FileStream: TFileStream;
  Bytes: TBytes;
begin
  Result := '';
  FileStream := TFileStream.Create(FileName, fmOpenRead or fmShareDenyWrite);
  try
    if FileStream.Size > 0 then
    begin
      SetLength(Bytes, FileStream.Size);
      FileStream.Read(Bytes[0], FileStream.Size);
    end;
    Result := TEncoding.UTF8.GetString(Bytes);
  finally
    FileStream.Free;
  end;
end;

procedure StringtoFileUTF8(Filename, Line: string; const Append: boolean = false);
var
  fs: TFileStream;
  preamble: TBytes;
  outpututf8: RawByteString;
  amode: Integer;
begin
  if Append and FileExists(Filename) then
    amode := fmOpenReadWrite
  else
    amode := fmCreate;
  fs := TFileStream.Create(Filename, { mode } amode, fmShareDenyWrite);
    { sharing mode allows read during our writes }
  try

      { internal Char (UTF16) codepoint, to UTF8 encoding conversion: }
    outpututf8 := Utf8Encode(Line);
      // this converts UnicodeString to WideString, sadly.

    if (amode = fmCreate) then
    begin
        // preamble := TEncoding.UTF8.GetPreamble;
        // fs.WriteBuffer( PAnsiChar(preamble)^, Length(preamble));
    end
    else
    begin
      fs.Seek(fs.Size, 0); { go to the end, append }
    end;

      // outpututf8 := outpututf8 + AnsiChar(#13) + AnsiChar(#10);
    fs.WriteBuffer(PAnsiChar(outpututf8)^, Length(outpututf8));
  finally
    fs.Free;
  end;
end;

end.

