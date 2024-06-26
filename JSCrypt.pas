unit JSCrypt;

interface

uses
  windows, sysutils, crc32, md5, System.Hash;

function _md5(str: string): string;

function _crc32(str: string): dword;

function GetStrHashSHA1(str: string): string;

function _md5file(filename: string): string;

implementation

function GetStrHashSHA1(str: string): string;
var
  HashSHA: THashSHA1;
begin
  HashSHA := THashSHA1.Create;
  HashSHA.GetHashString(str);
  result := HashSHA.GetHashString(str);
end;

function _md5(str: string): string;
begin
  result := THashMD5.GetHashString(str);
end;

function _crc32(str: string): dword;
begin
  result := CalcStringCRC32(str);
end;

function _md5file(filename: string): string;
var
  digest: Tmd5digest;
begin
  digest := MD5File(filename);
  result := MD5DigestToStr(digest);
end;

end.

