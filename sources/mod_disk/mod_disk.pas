unit mod_disk;

interface

uses
  Windows,
  math,
  SysUtils;

type
  Tsystemdisk = packed record
    _label : string; // disk label
    _Char : char; // assigned drive char
    _type : integer; // drive type: 1:fixed, 2: removable
    active : Boolean; // disk ready to use
    disksize : Int64; // total capacity in mb
    diskfree : Int64; // total free in mb
    serial : string // added for mod_userdisk module compatibility
    end;

    type
      Tdisklist = array of Tsystemdisk;

    type
      Tdiskinfo = packed record
        _label : string;
        serial : string;
      end;

    function isdirectoryavailable( path : string ) : Boolean;

    function disklistfast : Tdisklist;

    function disklistobj : Tdisklist;

    function Disk_free( drive : char ) : Int64;

    function Disk_size( drive : char ) : Int64;

    function findavailabledrivechar : char;

    function DiskInDrive( drive : char ) : Boolean;

    function finddrivechar(
      lbl             : string;
      const drivetype : DWORD = 0 ) : char;

    function DisksAsJson( meta : Tdisklist ) : string;

implementation

uses
  xsuperobject;

function DisksAsJson( meta : Tdisklist ) : string;
  begin
    result := TJSON.Stringify< Tdisklist >( meta );
  end;

function findavailabledrivechar : char;
  var
    harf : char;
    ID : DWORD;
    list : array of char;
    i, z : integer;
    found : Boolean;
  begin
    ID := GetLogicalDrives;
    harf := 'A';
    SetLength( list, 30 );
    for i := 0 to 30 do
    begin
      if ( ID and ( 1 shl i ) ) <> 0
      then
      begin
        list[ i ] := char( ord( harf ) + i );
      end;
    end;

    for i := ord( 'Z' ) downto ord( 'A' ) do
    begin
      found := false;
      for z := 0 to 30 do
      begin
        if list[ z ] = chr( i )
        then
          found := true;
      end;
      if not found
      then
      begin
        result := chr( i );
        break;
      end;
    end;

  end;

function getdiskinfo( DriveLetter : char ) : Tdiskinfo;
  var
    NotUsed : DWORD;
    VolumeFlags : DWORD;
    res : string;
    VolumeSerialNumber : DWORD;
    Buf : array [ 0 .. MAX_PATH ] of char;
  begin
    GetVolumeInformation( PChar( DriveLetter + ':\' ), Buf, 260,
      @VolumeSerialNumber, NotUsed, VolumeFlags, nil, 0 );
    SetString( res, Buf, StrLen( Buf ) );
    result._label := res;
    result.serial := Format( '%8.8X', [ VolumeSerialNumber ] );
    zeromemory( @VolumeSerialNumber, sizeof( VolumeSerialNumber ) );
    zeromemory( @Buf, sizeof( Buf ) );
  end;

function GetHardDiskSerial( const DriveLetter : char ) : string;
  var
    NotUsed : DWORD;
    VolumeFlags : DWORD;
    VolumeSerialNumber : DWORD;
  begin
    GetVolumeInformation( PChar( DriveLetter + ':\' ), nil, 260,
      @VolumeSerialNumber, NotUsed, VolumeFlags, nil, 0 );
    result := Format( '%8.8X', [ VolumeSerialNumber ] );
    zeromemory( @VolumeSerialNumber, sizeof( VolumeSerialNumber ) );
  end;

function GetDriveLabel( DriveChar : char ) : string;
  var
    NotUsed : DWORD;
    VolumeFlags : DWORD;
    VolumeSerialNumber : DWORD;
    Buf : array [ 0 .. MAX_PATH ] of char;
  begin
    GetVolumeInformation( PChar( DriveChar + ':\' ), Buf, 260,
      @VolumeSerialNumber, NotUsed, VolumeFlags, nil, 0 );
    SetString( result, Buf, StrLen( Buf ) );
    zeromemory( @Buf, sizeof( Buf ) );
  end;

function Disk_size( drive : char ) : Int64;
  begin
    result := disksize( ord( drive ) - $40 );
  end;

function Disk_free( drive : char ) : Int64;
  begin
    result := diskfree( ord( drive ) - 64 );
  end;

function DiskInDrive( drive : char ) : Boolean;
  var
    errormode : WORD;
  begin
    if drive in [ 'a' .. 'z' ]
    then
      Dec( drive, $20 );
    { make sure it's a letter }
    errormode := SetErrorMode( SEM_FailCriticalErrors );
    try
      { drive 1 = a, 2 = b, 3 = c, etc. }
      if disksize( ord( drive ) - $40 ) = - 1
      then
        result := false
      else
        result := true;
    finally
      { restore old error mode }
      SetErrorMode( errormode );
    end;
  end;

function isdirectoryavailable( path : string ) : Boolean;
  var
    chr : char;
  begin
    result := false;

    if path <> ''
    then
    begin
      chr := path[ 1 ];
      result := ( ( DiskInDrive( chr ) ) and
        ( Disk_free( chr ) > ( 1024 * 10 ) ) );
    end;

  end;

function disklistobj : Tdisklist;
  var
    i : integer;
    harf : char;
    ID : DWORD;
    tmp : Tdisklist;
    info : Tdiskinfo;
    letter : char;
  begin
    ID := GetLogicalDrives;
    harf := 'A';
    SetLength( tmp, 26 );
    for i := 0 to 25 do
    begin
      if ( ID and ( 1 shl i ) ) <> 0
      then
      begin
        letter := char( ord( harf ) + i );
        info := getdiskinfo( letter );
        tmp[ i ]._Char := letter;
        tmp[ i ]._label := info._label;
        tmp[ i ]._type := GetDriveType( PChar( letter + ':\' ) );
        if tmp[ i ]._Char = 'A'
        then
          Continue;
        tmp[ i ].serial := info.serial;
        tmp[ i ].active := DiskInDrive( tmp[ i ]._Char );
        if tmp[ i ].active
        then
        begin

          tmp[ i ].disksize := Disk_size( tmp[ i ]._Char );
          if tmp[ i ].disksize < 0
          then
            tmp[ i ].disksize := 0;
          if ( tmp[ i ].disksize = low( tmp[ i ].disksize ) ) or
            ( tmp[ i ].disksize = high( tmp[ i ].disksize ) )
          then
            tmp[ i ].disksize := 0;
          if tmp[ i ].disksize > 1024
          then
            tmp[ i ].disksize := tmp[ i ].disksize div 1024 div 1024;

          tmp[ i ].diskfree := Disk_free( tmp[ i ]._Char );
          if tmp[ i ].diskfree < 0
          then
            tmp[ i ].diskfree := 0;
          if ( tmp[ i ].diskfree = low( tmp[ i ].diskfree ) ) or
            ( tmp[ i ].diskfree = high( tmp[ i ].diskfree ) )
          then
            tmp[ i ].diskfree := 0;
          if tmp[ i ].diskfree > 1024
          then
            tmp[ i ].diskfree := tmp[ i ].diskfree div 1024 div 1024;
        end;
      end;
    end;
    result := tmp;
    Finalize( tmp );
    FillChar( tmp, sizeof( tmp ), 0 );
    Finalize( info );
    FillChar( info, sizeof( info ), 0 );
  end;

function disklistfast : Tdisklist;
  var
    i : integer;
    harf : char;
    ID : DWORD;
    tmp : Tdisklist;
    info : Tdiskinfo;
    letter : char;
  begin
    ID := GetLogicalDrives;
    harf := 'A';
    SetLength( tmp, 26 );
    for i := 0 to 25 do
    begin
      if ( ID and ( 1 shl i ) ) <> 0
      then
      begin
        letter := char( ord( harf ) + i );
        info := getdiskinfo( letter );
        tmp[ i ]._Char := letter;
        if tmp[ i ]._Char = 'A'
        then
          Continue;
        tmp[ i ]._label := info._label;
        tmp[ i ]._type := GetDriveType( PChar( letter + ':\' ) );
        tmp[ i ].serial := info.serial;
        tmp[ i ].active := DiskInDrive( tmp[ i ]._Char );
      end;
    end;
    result := tmp;
  end;

function finddrivechar(
  lbl             : string;
  const drivetype : DWORD = 0 ) : char;
  var
    list : Tdisklist;
    i : integer;
  begin
    list := disklistobj;
    for i := Low( list ) to high( list ) do
    begin
      if drivetype > 0
      then
      begin
        if list[ i ]._type = drivetype
        then
        begin
          if Pos( UpperCase( lbl ), UpperCase( list[ i ]._label ) ) > 0
          then
          begin
            result := list[ i ]._Char;
            break;
          end;
        end;
      end
      else
      begin
        if Pos( UpperCase( lbl ), UpperCase( list[ i ]._label ) ) > 0
        then
        begin
          result := list[ i ]._Char;
          break;
        end;
      end;
    end;
  end;

end.
