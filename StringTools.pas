unit StringTools;

interface

uses
  windows, sysutils;

type
  Texplodedstr = array of string;

function ParseBracket(Text: string; const _open: char = '('; const _close: char = ')'): string;

function replaceword(const s: string; NewWord: string; wordIndex: integer; karakter: char): string;

function explodestr(const s: string; wordIndex: integer; karakter: char): string;

function SearchAndReplace(sSrc, sLookFor, sReplaceWith: string): string;

function charcount(str: string; chr: string): integer;

function Removelastchar(s: string): string;

function Randomstring(strLen: integer): string;

function _explodestr(str: string; delim: char): Texplodedstr;

function SafeString(const Input: string): string;

implementation

const
  Alphabet = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ';

function SafeString(const Input: string): string;
var
  i: Integer;
  Output: string;
begin
  Output := '';
  for i := 1 to Length(Input) do
  begin
    case Input[i] of
      #8:
        Output := Output + '\b';   // Backspace
      #9:
        Output := Output + '\t';   // Horizontal Tab
      #10:
        Output := Output + '\n';  // Line Feed
      #12:
        Output := Output + '\f';  // Form Feed
      #13:
        Output := Output + '\r';  // Carriage Return
      #34:
        Output := Output + '\"';  // Double Quote
      #39:
        Output := Output + '\' + #39;  // Single Quote
      #92:
        Output := Output + '\\';  // Backslash
    else
      Output := Output + Input[i];
    end;
  end;
  Result := Output;
end;

function _explodestr(str: string; delim: char): Texplodedstr;
var
  i: integer;
  count: integer;
begin
  count := charcount(str, delim);
  setlength(result, count + 1);

  for i := 0 to count do
  begin
    result[i] := explodestr(str, i, delim);
  end;

end;

function charcount(str: string; chr: string): integer;
var
  say: integer;
  i: integer;
begin
  say := 0;
  for i := 1 to length(str) do
  begin
    if str[i] = chr then
      inc(say);
  end;
  result := say;
end;

function Randomstring(strLen: integer): string;
begin
  Randomize;
  Result := '';
  repeat
    Result := Result + Alphabet[Random(Length(Alphabet)) + 1];
  until (Length(Result) = strLen)
end;

function SearchAndReplace(sSrc, sLookFor, sReplaceWith: string): string;
var
  nPos, nLenLookFor: integer;
begin
  nPos := Pos(sLookFor, sSrc);
  nLenLookFor := Length(sLookFor);
  while (nPos > 0) do
  begin
    Delete(sSrc, nPos, nLenLookFor);
    Insert(sReplaceWith, sSrc, nPos);
    nPos := Pos(sLookFor, sSrc);
  end;
  Result := sSrc;
end;

function Removelastchar(s: string): string;
begin
  Result := copy(s, 1, Length(s) - 1);
end;

function replaceword(const s: string; NewWord: string; wordIndex: integer; karakter: char): string;
var
  tmp: string;
  i: integer;
begin
  for i := 0 to charcount(s, karakter) do
  begin
    if i = wordIndex then
      tmp := tmp + NewWord
    else
      tmp := tmp + explodestr(s, i, karakter) + karakter;
  end;

  if AnsiLastChar(tmp) = karakter then
    tmp := Removelastchar(tmp);
  Result := tmp;
end;

function explodestr(const s: string; wordIndex: integer; karakter: char): string;
var
  index, counter: integer;
begin
  Result := trim(s);
  counter := 0;
  index := Pos(karakter + karakter, Result);
  while index > 0 do
  begin
    Delete(Result, index, 1);
    index := Pos(karakter + karakter, Result);
  end;
  index := Pos(karakter, Result);
  while ((counter < wordIndex) and (index > 0)) do
  begin
    Delete(Result, 1, index);
    index := Pos(karakter, Result);

    counter := counter + 1;
  end;
  if (counter < wordIndex) then
    Result := '';
  index := Pos(karakter, Result);
  if index > 0 then
    Delete(Result, index, maxInt);
end;

function ParseBracket(Text: string; const _open: char = '('; const _close: char = ')'): string;
var
  pos1, pos2: integer;
begin
  Result := '';
  pos1 := Pos(_open, Text);
  pos2 := Pos(_close, Text);
  if (pos1 > 0) and (pos2 > pos1) then
    Result := copy(Text, pos1 + 1, pos2 - pos1 - 1);
end;

end.

