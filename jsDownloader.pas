﻿unit JSDownloader;

interface

uses
  windows, System.Net.HttpClient, Web.HTTPApp, System.SysUtils, System.Classes,
  utils;

type
  Tdownload = record
    remote: string;
    local: string;
    mime: string;
    length: int64;
    downloaded: int64;
    response: integer;
    success: boolean;
  end;

type
  TDownloader = class
  private
    FHttpClient: THTTPClient;
    _onprogress: string;

    lastupdate: int64;
    lastsize: int64;

    CriticalSection: TRTLCriticalSection;

    procedure OnReceiveData(const Sender: TObject; AContentLength, AReadCount: Int64; var AAbort: Boolean);
  public
    constructor Create(const onprogress: string = '');
    destructor Destroy; override;
    function start(const URL, FileName: string): Tdownload;
  end;

implementation

uses
  entrypoint, wmipc;

constructor TDownloader.Create(const onprogress: string = '');
begin
  FHttpClient := THTTPClient.Create();
  _onprogress := onprogress;

  if _onprogress <> '' then
    FHttpClient.OnReceiveData := OnReceiveData;
end;

destructor TDownloader.Destroy;
begin
  FHttpClient.Free;
  inherited;
end;

function FormatDownloadSpeed(TimeInMs: Integer; BytesReceived: Int64): string;
var
  SpeedBps: Double;
begin
  if TimeInMs = 0 then
    Result := '0 bytes/s'
  else
  begin
    SpeedBps := (BytesReceived / TimeInMs) * 1000;  // Calculate bytes per second
    if SpeedBps < 1024 then
      Result := Format('%.2f bytes/s', [SpeedBps])  // Bytes per second
    else if SpeedBps < 1024 * 1024 then
      Result := Format('%.2f KB/s', [SpeedBps / 1024])  // Kilobytes per second
    else
      Result := Format('%.2f MB/s', [SpeedBps / (1024 * 1024)]);  // Megabytes per second
  end;
end;

function CalculatePercentage(TotalBytes, ReceivedBytes: Int64): Integer;
begin
  if TotalBytes = 0 then
    Result := 0  // Avoid division by zero if TotalBytes is zero
  else
    Result := Round((ReceivedBytes / TotalBytes) * 100);  // Calculate and round the percentage to the nearest integer
end;

procedure TDownloader.OnReceiveData(const Sender: TObject; AContentLength, AReadCount: Int64; var AAbort: Boolean);
var
  time: int64;
  took: integer;
  packet: int64;
begin
  took := (gettickcount64 - lastupdate);
  if ((took >= 100) and (AReadCount <> lastsize)) then
  begin
    lastupdate := gettickcount64;
    packet := AReadCount - lastsize;
    lastsize := AReadCount;

    wm_sendstringex(ahandle, ahandle, pwidechar('~eval=' + _onprogress + '({"read":' + inttostr(AReadCount) + ',"total":' + inttostr(AContentLength) + ',"speed":"' + FormatDownloadSpeed(took, packet) + '","progress":' + inttostr(CalculatePercentage(AContentLength, AReadCount)) + '});'));
  end;
end;

function TDownloader.start(const URL, FileName: string): Tdownload;
var
  FileStream: TFileStream;
  Response: IHTTPResponse;
begin
  result.success := false;
  FileStream := TFileStream.Create(FileName, fmCreate);
  try
    result.remote := URL;
    result.local := FileName;
    lastupdate := gettickcount64;
    Response := FHttpClient.Get(URL, FileStream);
  finally
    result.response := Response.StatusCode;
    result.downloaded := FileStream.Size;
    result.length := Response.ContentLength;
    if result.length = result.downloaded then
      result.success := True;
    result.mime := Response.MimeType;
    FileStream.Free;
  end;
end;

end.

