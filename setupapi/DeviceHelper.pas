unit DeviceHelper;

interface

uses
  windows,
  SetupApi,
  sysutils,
  Common;

type
  TDeviceHelper = class
    private
      FDeviceInfoData : SP_DEVINFO_DATA;
      FDeviceListHandle : HDEVINFO;
    protected
      function GetBinary(
        PropertyCode : Integer;
        pData        : Pointer;
        dwSize       : DWORD ) : Boolean; virtual;
      function GetDWORD( PropertyCode : Integer ) : DWORD; virtual;
      function GetGuid( PropertyCode : Integer ) : TGUID; virtual;
      function GetString( PropertyCode : Integer ) : string; virtual;
      function GetPolicy( PropertyCode : Integer ) : string; virtual;
    public
      function Capabilities : string;
      function Characteristics : string;
      function ConfigFlags : string;
      function DeviceClassDescription : string; overload;
      function DeviceClassDescription( DeviceTypeGUID : TGUID )
        : string; overload;
      function InstallState : string;
      function PowerData : string;
      function LegacyBusType : string;
    public
      property Address : DWORD
        index SPDRP_ADDRESS
        read GetDWORD;
      property BusTypeGUID : TGUID
        index SPDRP_BUSTYPEGUID
        read GetGuid;
      property BusNumber : DWORD
        index SPDRP_BUSNUMBER
        read GetDWORD;
      property ClassGUID : TGUID
        index SPDRP_CLASSGUID
        read GetGuid;
      property CompatibleIDS : string
        index SPDRP_COMPATIBLEIDS
        read GetString;
      property DeviceClassName : string
        index SPDRP_CLASS
        read GetString;
      // property DeviceType: xxx index SPDRP_DEVTYPE read xxx;
      property DriverName : string
        index SPDRP_DRIVER
        read GetString;
      property Description : string
        index SPDRP_DEVICEDESC
        read GetString;
      property Enumerator : string
        index SPDRP_ENUMERATOR_NAME
        read GetString;
      // property Exclusive: xxx index SPDRP_EXCLUSIVE read xxx;

      property FriendlyName : string
        index SPDRP_FRIENDLYNAME
        read GetString;
      property HardwareID : string
        index SPDRP_HARDWAREID
        read GetString;
      property Service : string
        index SPDRP_SERVICE
        read GetString;
      // property Security: xxx index SPDRP_SECURITY read xxx;
      // property SecuritySDS: xxx index SPDRP_SECURITY_SDS read xxx;

      property Location : string
        index SPDRP_LOCATION_INFORMATION
        read GetString;
      property LowerFilters : string
        index SPDRP_LOWERFILTERS
        read GetString;
      property Manufacturer : string
        index SPDRP_MFG
        read GetString;
      property PhisicalDriverName : string
        index SPDRP_PHYSICAL_DEVICE_OBJECT_NAME
        read GetString;
      property RemovalPolicy : string
        index SPDRP_REMOVAL_POLICY
        read GetPolicy;
      property RemovalPolicyHWDefault : string
        index SPDRP_REMOVAL_POLICY_HW_DEFAULT
        read GetPolicy;
      property RemovalPolicyOverride : string
        index SPDRP_REMOVAL_POLICY_OVERRIDE
        read GetPolicy;
      property UINumber : DWORD
        index SPDRP_UI_NUMBER
        read GetDWORD;
      property UINumberDecription : string
        index SPDRP_UI_NUMBER_DESC_FORMAT
        read GetString;
      property UpperFilters : string
        index SPDRP_UPPERFILTERS
        read GetString;
    public
      property DeviceInfoData : SP_DEVINFO_DATA
        read FDeviceInfoData
        write FDeviceInfoData;
      property DeviceListHandle : HDEVINFO
        read FDeviceListHandle
        write FDeviceListHandle;
  end;

implementation

{ TDeviceHelper }

function HasFlag( const Value, dwFlag : DWORD ) : Boolean;
  begin
    Result := ( Value and dwFlag ) = dwFlag;
  end;

procedure AddToResult(
  var AResult : string;
  const Value : string );
  begin
    if AResult = ''
    then
      AResult := Value
    else
      AResult := AResult + ', ' + Value;
  end;

function ExtractMultiString( const Value : string ) : string;
  var
    P : PChar;
  begin
    P := @Value[ 1 ];
    while P^ <> #0 do
    begin
      if Result <> ''
      then
        Result := Result + ', ';
      Result := Result + P;
      Inc( P, lstrlen( P ) + 1 );
    end;
  end;

function TDeviceHelper.Capabilities : string;
  var
    I : Integer;
    dwCapabilities : DWORD;
  begin
    Result := '';
    dwCapabilities := GetDWORD( SPDRP_CAPABILITIES );
    for I := 0 to 9 do
      if HasFlag( dwCapabilities, CapabilitiesRelationships[ I ].Flag )
      then
        AddToResult( Result, CapabilitiesRelationships[ I ].Desc );
  end;

function TDeviceHelper.Characteristics : string;
  var
    dwCharacteristics : DWORD;
  begin
    dwCharacteristics := GetDWORD( SPDRP_CHARACTERISTICS );
    // if dwCharacteristics <> 0 then p;
  end;

function TDeviceHelper.ConfigFlags : string;
  var
    I : Integer;
    dwConfigFlags : DWORD;
  begin
    Result := '';
    dwConfigFlags := GetDWORD( SPDRP_CONFIGFLAGS );
    for I := 0 to 15 do
      if HasFlag( dwConfigFlags, ConfigFlagRelationships[ I ].Flag )
      then
        AddToResult( Result, ConfigFlagRelationships[ I ].Desc );
  end;

function TDeviceHelper.DeviceClassDescription( DeviceTypeGUID : TGUID )
  : string;
  var
    dwRequiredSize : DWORD;
  begin
    Result := '';
    dwRequiredSize := 0;
    SetupDiGetClassDescriptionA( DeviceTypeGUID, nil, 0, @dwRequiredSize );
    if GetLastError = ERROR_INSUFFICIENT_BUFFER
    then
    begin
      SetLength( Result, dwRequiredSize );
      SetupDiGetClassDescriptionA( DeviceTypeGUID, @Result[ 1 ], dwRequiredSize,
        @dwRequiredSize );
    end;
    Result := PChar( Result );
  end;

function TDeviceHelper.DeviceClassDescription : string;
  var
    AGUID : TGUID;
  begin
    AGUID := ClassGUID;
    Result := DeviceClassDescription( AGUID );
  end;

function TDeviceHelper.GetBinary(
  PropertyCode : Integer;
  pData        : Pointer;
  dwSize       : DWORD ) : Boolean;
  var
    dwPropertyRegDataType, dwRequiredSize : DWORD;
  begin
    dwRequiredSize := 0;
    dwPropertyRegDataType := REG_BINARY;
    Result := SetupDiGetDeviceRegistryPropertyA( DeviceListHandle,
      DeviceInfoData, PropertyCode, dwPropertyRegDataType, pData, dwSize,
      dwRequiredSize );
  end;

function TDeviceHelper.GetDWORD( PropertyCode : Integer ) : DWORD;
  var
    dwPropertyRegDataType, dwRequiredSize : DWORD;
  begin
    Result := 0;
    dwRequiredSize := 4;
    dwPropertyRegDataType := REG_DWORD;
    SetupDiGetDeviceRegistryPropertyA( DeviceListHandle, DeviceInfoData,
      PropertyCode, dwPropertyRegDataType, pbyte( Result ), dwRequiredSize,
      dwRequiredSize );
  end;

function TDeviceHelper.GetGuid( PropertyCode : Integer ) : TGUID;
  var
    dwPropertyRegDataType, dwRequiredSize : DWORD;
    StringGUID : string;
  begin
    ZeroMemory( @Result, SizeOf( TGUID ) );
    StringGUID := GetString( PropertyCode );
    {
      if StringGUID = '' then begin
      dwRequiredSize := 0;
      dwPropertyRegDataType := REG_BINARY;
      SetupDiGetDeviceRegistryPropertyW(DeviceListHandle, DeviceInfoData, PropertyCode, dwPropertyRegDataType, nil, 0, dwRequiredSize);
      if GetLastError = ERROR_INSUFFICIENT_BUFFER then
      begin
      SetupDiGetDeviceRegistryPropertyW(DeviceListHandle, DeviceInfoData, PropertyCode, dwPropertyRegDataType, Result, dwRequiredSize, dwRequiredSize);
      end;
      end
      else
    }
    Result := StringToGUID( StringGUID );
  end;

function TDeviceHelper.GetPolicy( PropertyCode : Integer ) : string;
  var
    dwPolicy : DWORD;
  begin
    dwPolicy := GetDWORD( PropertyCode );
    if dwPolicy > 0
    then
      case dwPolicy of
        CM_REMOVAL_POLICY_EXPECT_NO_REMOVAL :
          Result := 'CM_REMOVAL_POLICY_EXPECT_NO_REMOVAL';
        CM_REMOVAL_POLICY_EXPECT_ORDERLY_REMOVAL :
          Result := 'CM_REMOVAL_POLICY_EXPECT_ORDERLY_REMOVAL';
        CM_REMOVAL_POLICY_EXPECT_SURPRISE_REMOVAL :
          Result := 'CM_REMOVAL_POLICY_EXPECT_SURPRISE_REMOVAL';
        else
          Result := 'unknown 0x' + IntToHex( dwPolicy, 8 );
      end;
  end;

function TDeviceHelper.GetString( PropertyCode : Integer ) : string;
  var
    dwPropertyRegDataType, dwRequiredSize : DWORD;
  begin
    Result := '';
    dwRequiredSize := 0;
    dwPropertyRegDataType := REG_SZ;
    SetupDiGetDeviceRegistryPropertyW( DeviceListHandle, DeviceInfoData,
      PropertyCode, dwPropertyRegDataType, nil, 0, dwRequiredSize );
    if not ( dwPropertyRegDataType in [ REG_SZ, REG_MULTI_SZ ] )
    then
      Exit;
    if GetLastError = ERROR_INSUFFICIENT_BUFFER
    then
    begin
      SetLength( Result, dwRequiredSize );
      SetupDiGetDeviceRegistryPropertyW( DeviceListHandle, DeviceInfoData,
        PropertyCode, dwPropertyRegDataType, @Result[ 1 ], dwRequiredSize,
        dwRequiredSize );
    end;
    case dwPropertyRegDataType of
      REG_SZ :
        Result := PChar( Result );
      REG_MULTI_SZ :
        Result := ExtractMultiString( Result );
    end;
  end;

function TDeviceHelper.InstallState : string;
  var
    dwInstallState : DWORD;
  begin
    dwInstallState := GetDWORD( SDRP_INSTALL_STATE );
    case dwInstallState of
      CM_INSTALL_STATE_INSTALLED :
        Result := 'CM_INSTALL_STATE_INSTALLED';
      CM_INSTALL_STATE_NEEDS_REINSTALL :
        Result := 'CM_INSTALL_STATE_NEEDS_REINSTALL';
      CM_INSTALL_STATE_FAILED_INSTALL :
        Result := 'CM_INSTALL_STATE_FAILED_INSTALL';
      CM_INSTALL_STATE_FINISH_INSTALL :
        Result := 'CM_INSTALL_STATE_FINISH_INSTALL';
      else
        Result := 'unknown 0x' + IntToHex( dwInstallState, 8 );
    end;
  end;

function TDeviceHelper.LegacyBusType : string;
  var
    BusType : Integer;
  begin
    BusType := Integer( GetDWORD( SPDRP_LEGACYBUSTYPE ) );
    case BusType of
      - 1 :
        Result := 'InterfaceTypeUndefined';
      00 :
        Result := 'Internal';
      01 :
        Result := 'Isa';
      02 :
        Result := 'Eisa';
      03 :
        Result := 'MicroChannel';
      04 :
        Result := 'TurboChannel';
      05 :
        Result := 'PCIBus';
      06 :
        Result := 'VMEBus';
      07 :
        Result := 'NuBus';
      08 :
        Result := 'PCMCIABus';
      09 :
        Result := 'CBus';
      10 :
        Result := 'MPIBus';
      11 :
        Result := 'MPSABus';
      12 :
        Result := 'ProcessorInternal';
      13 :
        Result := 'InternalPowerBus';
      14 :
        Result := 'PNPISABus';
      15 :
        Result := 'PNPBus';
      16 :
        Result := 'MaximumInterfaceType';
      else
        Result := 'unknown 0x' + IntToHex( BusType, 8 );
    end;
  end;

function TDeviceHelper.PowerData : string;
  var
    I : Integer;
    pPowerData : TCM_Power_Data;
  begin
    Result := '';
    if GetBinary( SPDRP_DEVICE_POWER_DATA, @pPowerData,
      SizeOf( TCM_Power_Data ) )
    then
    begin
      for I := 0 to 8 do
        if HasFlag( pPowerData.PD_Capabilities, PDCAPRelationships[ I ].Flag )
        then
          AddToResult( Result, PDCAPRelationships[ I ].Desc );
    end;
  end;

end.
