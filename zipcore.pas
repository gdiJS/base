unit zipcore;

interface

uses
  sysutils, classes, x64, Zip, utils;

procedure viewZip(filename: string; CallBack: TArg<AnsiString>);

procedure createZip(directory: string; var fbuffer: Tbytes; CallBack: TArg<AnsiString>);

implementation

procedure viewZip(filename: string; CallBack: TArg<AnsiString>);
var
  i: integer;
  zip: TZipFile;
begin
  if not assigned(CallBack) then
    exit;

  zip := TZipFile.Create;

  if not zip.IsValid(filename) then
  begin
    CallBack('unsupported format');
    zip.free;
    exit;
  end;

  try
    zip.Open(filename, zmRead);

    for i := Low(zip.FileNames) to High(zip.FileNames) do
    begin
    if zip.FileInfo[i].UncompressedSize>0 then  
      CallBack(inttostr(i + 1) + ':' + zip.filenames[i] + ',' + inttostr(zip.FileInfo[i].UncompressedSize));
    end;

    zip.close;
    zip.Free;

  except
    on e: Exception do
    begin
      CallBack('zip error');
      zip.close;
      zip.Free;
    end;
  end;
end;

procedure createZip(directory: string; var fbuffer: Tbytes; CallBack: TArg<AnsiString>);
var
  MemoryStream: TMemoryStream;
  ZipFile: TZipFile;
  list: Tfiles;
  i: integer;
  t: integer;
  ext: string;
  comp: TZipCompression;
begin
  setlength(fbuffer, 0);
  MemoryStream := TMemoryStream.Create;
  ZipFile := TZipFile.Create;
  CallBack('0,0,read');
  list := ls(directory);
  t := length(list);
  if t <= 0 then
    exit;

  try
    ZipFile.Open(MemoryStream, zmWrite);
    for i := 0 to t-1 do
    begin
      if (list[i].size > 0) and (list[i].name <> '') then
      begin
        comp := zcDeflate64;
        ext := lowercase(extractfileext(list[i].name));
        if (ext = '.mp4') or (ext = '.mkv') or (ext = '.jpg') or (ext = '.gif') or (ext = '.zip') or (ext = '.rar') or (ext = '.iso') or (ext = '.7z') or (ext = '.mp3') or (ext = '.flac') or (ext = '.ogg') or (ext = '.ogv') or (ext = '.avi') then
        begin
          comp := zcStored;
        end
        else
          comp := zcDeflate;
        if fileexists(directory + list[i].name) then
        begin
          CallBack(inttostr(i) + ',' + inttostr(t) + ',' + list[i].name);
          ZipFile.Add(directory + list[i].name, list[i].name, comp);
        end;
      end;
    end;
    ZipFile.Comment := directory;
    ZipFile.Close;
    ZipFile.Free;

  finally
    CallBack('0,0,done');
    MemoryStream.Position := 0;
    SetLength(fbuffer, MemoryStream.Size);
    MoveFast(MemoryStream.memory^, fbuffer[0], MemoryStream.Size);
    MemoryStream.Free;
  end;
end;

end.

