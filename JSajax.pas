unit JSajax;

interface

uses
  msxml, classes, System.Net.HttpClient, Web.HTTPApp, Variants, SysUtils,
  windows, jsdownloader;

type
  TAjaxResponse = record
    mime: string;
    response: widestring;
    result: integer;
  end;

function httpGet(url: string): TAjaxResponse;

function httpPost(url, payload: string; const _type: string = 'application/x-www-form-urlencoded'): TAjaxResponse;

implementation

function httpPost(url, payload: string; const _type: string = 'application/x-www-form-urlencoded'): TAjaxResponse;
var
  XMLHTTPRequest: IServerXMLHTTPRequest;
begin
  XMLHTTPRequest := CoServerXMLHTTP.Create;
  XMLHTTPRequest._AddRef;
  XMLHTTPRequest.open('POST', url, false, EmptyParam, EmptyParam);
  XMLHTTPRequest.setRequestHeader('Cache-Control', 'no-cache');
  XMLHTTPRequest.setRequestHeader('Content-Type', _type);
  XMLHTTPRequest.setTimeouts(2 * 1000, 2 * 1000, 6 * 1000, 6 * 1000);
  XMLHTTPRequest.send(payload);
  result.response := XMLHTTPRequest.responseText;
  result.result := XMLHTTPRequest.status;
  result.mime := XMLHTTPRequest.getResponseHeader('Content-Type');

//  result.resultText := XMLHTTPRequest.statusText;
  XMLHTTPRequest._Release;
  XMLHTTPRequest := nil;
end;

function httpGet(url: string): TAjaxResponse;
var
  HttpClient: THTTPClient;
  Response: IHTTPResponse;
begin
  HttpClient := THTTPClient.Create;
  try
    Response := HttpClient.Get(url);
    if assigned(Response) then
    begin
      result.result := Response.StatusCode;
      result.response := Response.ContentAsString();
      result.mime := Response.MimeType;
    end;

  finally
    HttpClient.Free;
  end;
end;

end.

