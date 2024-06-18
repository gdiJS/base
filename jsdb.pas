unit jsdb;

interface

uses
  windows, classes, System.SysUtils, Generics.Collections, SQLiteTable3;

function ThreadedQuery(filename, query: string): string;

function query(id: Cardinal; query: string): string;

function opendb(filename: string): integer;

function closedb(id: Cardinal): boolean;

procedure killDb;

function exec(id: Cardinal; query: string): boolean;

implementation

uses
  entrypoint, XSuperObject,console;

var
  dbList: TDictionary<integer, TSQLiteDatabase>;
  ids: integer;

procedure killDb;
var
  Item: TPair<integer, TSQLiteDatabase>;
begin
  exit;
  for Item in dbList do
  begin
      // Item.Value.Close;
      // Item.Value.Free;
  end;
  dbList.Clear;
end;

function opendb(filename: string): integer;
var
  c: TSQLiteDatabase;
  i: integer;
begin
  if not FileExists(filename) then
  begin
    debug('db not found: ' + filename);
    result := 0;
    exit;
  end;

  c := TSQLiteDatabase.Create(filename);
  Inc(ids);
  i := ids;
  result := i;
  dbList.Add(i, c);
end;

function exec(id: Cardinal; query: string): boolean;
var
  c: TSQLiteDatabase;
begin
  result := false;
  if dbList.TryGetValue(id, c) then
  begin
    try
      c.ExecSQL(query);
    finally
      result := True;
    end;
  end;
end;

function ThreadedQuery(filename, query: string): string;
var
  f: integer;
  c: TSQLiteDatabase;
  q: TSQLiteUniTable;
  X: ISuperObject;
  A: ISuperArray;
begin
  if not FileExists(filename) then
  begin
    debug('db not found: ' + filename);
    result := '[]';
    exit;
  end;

  c := TSQLiteDatabase.Create(filename);
  q := TSQLiteUniTable.Create(c, query);
  A := SA();

  while not q.EOF do
  begin
    X := SO;
    for f := 0 to q.ColCount - 1 do
    begin
      X.S[q.Columns[f]] := q.FieldAsBlobText(q.FieldIndex[q.Columns[f]]);
    end;
    A.Add(X);
    q.Next;
  end;
  result := A.AsJSON();
  q.Free;
  c.Free;
end;

function query(id: Cardinal; query: string): string;
var
  f: integer;
  c: TSQLiteDatabase;
  q: TSQLiteUniTable;
  X: ISuperObject;
  A: ISuperArray;
begin
  if dbList.TryGetValue(id, c) then
  begin
    q := TSQLiteUniTable.Create(c, query);
    A := SA();

    while not q.EOF do
    begin
      X := SO;
      for f := 0 to q.ColCount - 1 do
      begin
        X.S[q.Columns[f]] := q.FieldAsBlobText(q.FieldIndex[q.Columns[f]]);
      end;
      A.Add(X);
      q.Next;
    end;
    result := A.AsJSON();
    q.Free;
  end;
end;

function closedb(id: Cardinal): boolean;
var
  c: TSQLiteDatabase;
begin
  exit;
  if dbList.TryGetValue(id, c) then
  begin

    c.Free;
    dbList.Remove(id);
    result := True;
  end
  else
    result := false;
end;

initialization
  dbList := TDictionary<integer, TSQLiteDatabase>.Create;

finalization
  killDb;
  dbList.Free;

end.

