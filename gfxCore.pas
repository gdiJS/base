unit gfxCore;

interface

uses
  windows, Classes, SysUtils, VCL.Imaging.JPeg, vcl.graphics;

function SaveScr(Quality: Integer; SavAs: string): Boolean;

procedure PrintInCoordinate(Text: string; x, y, boyut, renk, arka: Integer; merkez: string);

function pencerekap(Quality: Integer; pencere, SavAs: string): Boolean;

function BitmapDifference(BmpA, BmpB: TBitmap): integer;

procedure saveasjpeg(kaynak: TBitmap; yer: string; kalite: integer);

function ScrBmp: TBitmap;

function Bmp2Jpg(Bit: TBitmap; Quality: Integer): TJpegImage;

procedure CaptureFromScreen(Dest: TBitmap; x, y, w, h, screenx, screeny: integer);

function TakeScreenshot(var bmp: TBitmap; MonitorNumber: Integer): Boolean;

implementation

function BitmapDifference(BmpA, BmpB: TBitmap): integer;
var
  x, y: integer;
  P, Q: PByte;
  Diff: int64;
begin
  if not assigned(BmpA) or not assigned(BmpB) or (BmpA.PixelFormat <> pf24bit) or (BmpB.PixelFormat <> pf24bit) or (BmpA.Width <> BmpB.Width) or (BmpA.Height <> BmpB.Height) or (BmpA.Width * BmpA.Height = 0) then
  begin
    result := 100;
    exit;
  end;

  Diff := 0;
  for y := 0 to BmpA.Height - 1 do
  begin
    P := BmpA.Scanline[y];
    Q := BmpB.Scanline[y];
    for x := 0 to BmpA.Width - 1 do
    begin
      Diff := Diff + Sqr(P^ - Q^);
      inc(P);
      inc(Q);
      Diff := Diff + Sqr(P^ - Q^);
      inc(P);
      inc(Q);
      Diff := Diff + Sqr(P^ - Q^);
      inc(P);
      inc(Q);
    end;
  end;

  Result := Round(Sqrt(Diff / (BmpA.Width * BmpA.Height)));
end;

procedure saveasjpeg(kaynak: TBitmap; yer: string; kalite: integer);
var
  j: TJPEGImage;
begin
  j := TJpegImage.Create;
  j.Assign(kaynak);
  j.CompressionQuality := kalite;
  try
    j.SaveToFile(yer);
  finally
  end;
  j.Free;
end;

function Bmp2Jpg(Bit: TBitmap; Quality: Integer): TJpegImage;
var
  Jpg: TJpegImage;
begin
  try
    Jpg := TJpegImage.Create;
    Jpg.CompressionQuality := Quality;
    Jpg.ProgressiveEncoding := true;
    Jpg.ProgressiveDisplay := true;
    Jpg.Smoothing := false;
    Jpg.Performance := jpBestQuality;
    Jpg.Scale := jsFullSize;
    Jpg.PixelFormat := jf24Bit;
    Jpg.Compress;
    Jpg.Assign(Bit);
  finally
    Bit.Free;
  end;
  Result := Jpg;
end;

function GetDcAsBitmap(DC: HDC; W, H: Cardinal): TBitmap;
var
  Bitmap: TBitmap;
  hdcCompatible: HDC;
  hbmScreen: HBitmap;
begin
  Result := nil;
  try
    if DC = 0 then
      Exit;
    Bitmap := Tbitmap.create;
    hdcCompatible := CreateCompatibleDC(DC);
    hbmScreen := CreateCompatibleBitmap(DC, W, H);
    if (hbmScreen = 0) then
      Exit;
    if (SelectObject(hdcCompatible, hbmScreen) = 0) then
      Exit;
    if not (BitBlt(hdcCompatible, 0, 0, W, H, DC, 0, 0, SRCCOPY)) then
      Exit;
    Bitmap.Handle := hbmScreen;
    Bitmap.Dormant;
    Result := Bitmap;
  finally
    ;
  end;
end;

function GetWindowAsBitmap(const WindowName: string): Tbitmap;
var
  Wnd: HWnd;
  Rect: TRect;
begin
  result := nil;
  try
    Wnd := FindWindow(nil, PChar(WindowName));
    GetWindowRect(Wnd, Rect);
    Result := GetDCAsBitmap(GetWindowDC(Wnd), Rect.Right - Rect.Left, Rect.Bottom - Rect.Top);
  except
    on exception do
      exit;
  end;
end;

function pencerekap(Quality: Integer; pencere, SavAs: string): Boolean;
var
  jpg: TJPEGImage;
begin
  result := false;
  try
    jpg := Bmp2Jpg(GetWindowAsBitmap(pencere), Quality);
    jpg.SaveToFile(SavAs);
    jpg.Free;
  except
    on exception do
      exit;
  end;
  result := true
end;

procedure PrintInCoordinate(Text: string; x, y, boyut, renk, arka: Integer; merkez: string);
var
  CrLf, cLine: string;
  c, LineH, p: LongInt;
  Dc: HDC;
  ortasi: integer;
begin
  try
    CrLf := #13#10;
    c := 0;
    Dc := GetWindowDc(GetDesktopWindow);
    with TCanvas.Create do
    begin
      Handle := Dc;
      Font.Size := boyut;
      Font.Color := renk;
      font.Name := 'Verdana';
      Brush.Color := arka;
      LineH := TextHeight('H');
      p := Pos(CrLf, Text);
      while p > 0 do
      begin
        cLine := Copy(Text, 1, p - 1);
        Text := Copy(Text, p + Length(CrLf), Length(Text));
        TextOut(x, y + (c * LineH), cLine);
        c := c + 1;
        p := Pos(CrLf, Text);
      end;

      if merkez = 'X' then
      begin
        ortasi := textwidth(Text) div 2;
        x := GetSystemMetrics(SM_CXSCREEN) div 2 - ortasi;
        y := GetSystemMetrics(SM_CYSCREEN) div 2 - TextHeight('H')
      end;

      TextOut(x, y + (c * LineH), Text);
      Free;
    end;
  except
    on Exception do
      exit
  end;
end;

procedure CaptureFromScreen(Dest: TBitmap; x, y, w, h, screenx, screeny: integer);
var
  DC: hWnd;
begin
  DC := GetDC(0);
  if DC = 0 then
    exit;
  bitblt(Dest.canvas.handle, -1600, 0, w, h, DC, -1600, 0, SRCCOPY);
  ReleaseDC(0, DC);
end;

function ScrBmp: TBitmap;
var
  Bit: TBitmap;
  Canv: TCanvas;
  Rec: TRect;
  X, Y: Integer;
begin
  Canv := TCanvas.Create;
  Canv.Handle := GetDC(GetDeskTopWindow);
  X := GetSystemMetrics(SM_CXSCREEN);
  Y := GetSystemMetrics(SM_CYSCREEN);
  try
    Bit := TBitmap.Create;
    Bit.Width := X;
    Bit.Height := Y;
    Rec := Rect(0, 0, X, Y);
    Bit.Canvas.CopyRect(Rec, Canv, Rec);
  finally
    ReleaseDC(0, Canv.Handle);
  end;
  Result := Bit;
  Canv.Free;
end;

function TakeScreenshot(var bmp: TBitmap; MonitorNumber: Integer): Boolean;
const
  CAPTUREBLT = $40000000;
//var
//  DesktopCanvas: TCanvas;
//  DC: HDC;
//  Left: Integer;
begin
  Result := False;
 {
  if (MonitorNumber > Screen.MonitorCount) then
    Exit;
  DC := GetDC(0);
  try
    if (DC = 0) then
      Exit;
    if (MonitorNumber = 0) then
    begin
      bmp.Width := Screen.DesktopWidth;
      bmp.Height := Screen.DesktopHeight;
      Left := Screen.DesktopLeft;
      Top := Screen.DesktopTop;
    end
    else
    begin
      bmp.Width := Screen.Monitors[MonitorNumber - 1].Width;
      bmp.Height := Screen.Monitors[MonitorNumber - 1].Height;
      Left := Screen.Monitors[MonitorNumber - 1].Left;
      Top := Screen.Monitors[MonitorNumber - 1].Top;
    end;
    DesktopCanvas := TCanvas.Create;
    try
      DesktopCanvas.Handle := DC;
      Result := BitBlt(bmp.Canvas.Handle, 0, 0, bmp.Width, bmp.Height, DesktopCanvas.Handle, Left, Top, SRCCOPY or CAPTUREBLT);
      Result := True;
    finally
      DesktopCanvas.Free;
    end;
  finally
    if (DC <> 0) then
      ReleaseDC(0, DC);
  end;
  }
end;

//************* End of JPG ***********************************

//*********** Function to call when saving *******************
function SaveScr(Quality: Integer; SavAs: string): Boolean;
var
  jpg: TJPEGImage;
begin
  result := false;
  try
    jpg := Bmp2Jpg(ScrBmp, Quality);
    jpg.SaveToFile(SavAs);
    jpg.Free;
  except
    on EFCreateError do
      exit;
  end;
  result := true
end;

end.

