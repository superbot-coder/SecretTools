unit SecretTools;

interface

USES
  System.SysUtils, System.Classes, System.Math, System.IOUtils,
  DECCRC, DECBaseClass;

Type

  TSecretTools = record
  private
    FCRC: TCRCDef;
    FCharSet: AnsiString;
    FCharLen: UInt8;
    FBytesBuf: TBytes;
    procedure SetCharSet(const ACharSet: AnsiString);
  public
    constructor Crete(const CRCType: TCRCType; const ACharSet: AnsiString);
    property CharSet: AnsiString read FCharSet write SetCharSet;
    function CRCFile(const FileName: String): Uint32; inline;
    function CRCUint(const Value: Uint32; const Done: Boolean = true): Uint32; inline;
    function CRCUintToChars(const Value: Uint32): AnsiString; inline;
    function CRCString(const Value: String; const Done: Boolean = true): Uint32; inline;
    function CRCStringToChars(const Value: String): AnsiString; inline;
    procedure ReInit(const CRCType: TCRCType; const ASharSet: AnsiString); inline;
    function UInt64ToChars(const Value: UInt64): AnsiString; inline;
    function CharsToUint64(const Value: AnsiString): Uint64; inline;
    class function ShuffleString(const Input: string): string; static; inline;
    class function EncodeXor(const SourceValue: String; KeyValue: Uint32): String; overload; static; inline;
    class function EncodeXor(const SourceValue, KeyValue: String): String; overload; static; inline;
    class function DecodeXor(const HexString, KeyString: String): AnsiString; overload; static; inline;
    class function DecodeXor(const HexString: String; const KeyValue: Uint32): AnsiString; overload; static; inline;
  end;

implementation

function TSecretTools.CharsToUint64(const Value: AnsiString): Uint64;
var
  sl: integer;
  i, n: integer;
  ResEx: Extended;
begin
  ResEx := 0;
  Result := 0;
  sl := Length(Value);
  if (sl = 0) or (FCharLen = 0) then
    Exit;
  Dec(sl);
  for i := 0 to sl do
  begin
    n := AnsiPos(Value[i + 1], FCharSet);
    if n = 0 then
    begin
      Result := 0;
      Exit;
    end;
    ResEx := ResEx  + n * Power(FCharLen, sl - i);
  end;
  // Checking range result
  if (ResEx < 0) or (ResEx > High(UInt64)) or IsNan(ResEx) or IsInfinite(ResEx) then
    Exit;
  Result := Trunc(ResEx);
end;

function TSecretTools.CRCFile(const FileName: String): Uint32;
begin
  Result := 0;
  if FileName <> '' then
  begin
    FBytesBuf := TFile.ReadAllBytes(FileName);
    if  Length(FBytesBuf) <> 0 then
    begin
      Result := CRCCode(FCRC, FBytesBuf[0], Length(FBytesBuf));
      CRCDone(FCRC);
    end;
  end;
end;

function TSecretTools.CRCString(const Value: String; const Done: Boolean): Uint32;
begin
  FBytesBuf := BytesOf(AnsiString(Value));
  Result := CRCCode(FCRC, FBytesBuf[0], Length(FBytesBuf));
  if Done then
    CRCDone(FCRC);
end;

function TSecretTools.CRCStringToChars(const Value: String): AnsiString;
begin
  Result := UInt64ToChars(CRCString(Value, True));
end;

function TSecretTools.CRCUint(const Value: Uint32; const Done: Boolean): Uint32;
begin
  FBytesBuf := BytesOf(Pointer(@Value), 4);
  Result := CRCCode(FCRC, FBytesBuf[0], 4);
  if Done then
    CRCDone(FCRC);
end;

function TSecretTools.CRCUintToChars(const Value: Uint32): AnsiString;
begin
  Result := UInt64ToChars(CRCUint(Value, True));
end;

constructor TSecretTools.Crete(const CRCType: TCRCType; const ACharSet: AnsiString);
begin
  FCharSet :=  ACharSet;
  CRCInit(FCRC, CRCType);
  SetCharSet(ACharSet);
end;

class function TSecretTools.DecodeXor(const HexString, KeyString: String): AnsiString;
var
  SourceBuf, KeyBuf: TBytes;
  L: integer;
  bt: Byte;
begin
  Result := '';
  L := length(HexString);
  if (L = 0) or ((L mod 2) <> 0) then
    exit;

  KeyBuf := BytesOf(KeyString);
  SetLength(SourceBuf, L div 2);
  HexToBin(PChar(HexString), SourceBuf, L div 2);

  for var i := 0 to High(SourceBuf) do
  begin
    bt := SourceBuf[i];
    for var j := high(KeyBuf) downto 0 do
      bt := bt xor KeyBuf[j];
    Result := Result + Char(Bt);
  end;
end;

class function TSecretTools.DecodeXor(const HexString: String; const KeyValue: Uint32): AnsiString;
var
  SourceBuf, KeyBuf: TBytes;
  L: integer;
  bt: Byte;
begin
  Result := '';
  L := length(HexString);
  if (L = 0) or ((L mod 2) <> 0) then
    exit;

  KeyBuf := BytesOf(Pointer(@KeyValue), 4);
  SetLength(SourceBuf, L div 2);
  HexToBin(PChar(HexString), SourceBuf, L div 2);

  for var i := 0 to High(SourceBuf) do
  begin
    bt := SourceBuf[i];
    for var j := high(KeyBuf) downto 0 do
      bt := bt xor KeyBuf[j];
    Result := Result + Char(Bt);
  end;
end;

class function TSecretTools.EncodeXor(const SourceValue, KeyValue: String): String;
var
  bt: byte;
  SourceBuf, KeyBuf: TBytes;
begin
  if (Length(SourceValue) <> 0) and (Length(KeyValue) <> 0) then
  begin
    SourceBuf := BytesOf(SourceValue);
    KeyBuf    := BytesOf(KeyValue);
    for var i := 0 to High(SourceBuf) do
    begin
      bt := SourceBuf[i];
      for var j := 0 to High(KeyBuf) do
        bt := bt xor KeyBuf[j];
      Result := Result + bt.ToHexString;
    end;
  end;
end;

class function TSecretTools.EncodeXor(const SourceValue: String; KeyValue: Uint32): String;
var
  SourceBuf: TBytes;
  KeyBuf: TBytes;
  bt: Byte;
begin
  if Length(SourceValue) <> 0 then
  begin
    SourceBuf := BytesOf(SourceValue);
    KeyBuf := BytesOf(Pointer(@KeyValue), SizeOf(KeyValue));
    for var i := 0 to High(SourceBuf) do
    begin
      bt := SourceBuf[i];
      for var j := 0 to High(KeyBuf) do
        bt := bt xor KeyBuf[j];
      Result := Result + bt.ToHexString;
    end;
  end;
end;

procedure TSecretTools.ReInit(const CRCType: TCRCType; const ASharSet: AnsiString);
begin
  CRCDone(FCRC);
  CRCInit(FCRC, CRCType);
  SetCharSet(ASharSet);
end;

procedure TSecretTools.SetCharSet(const ACharSet: AnsiString);
begin
  if Length(ACharSet) > High(Byte) then
    raise Exception.Create('Error: length ASharSet > 256 byte');
  FCharSet := ACharSet;
  FCharLen := Length(FCharSet);
end;

class function TSecretTools.ShuffleString(const Input: string): string;
var
  CharArray: TArray<Char>;
  i, j: Integer;
  Temp: Char;
begin
  // Преобразуем строку в массив символов
  CharArray := Input.ToCharArray;

  // Реализация перемешивания символов методом Фишера-Йетса
  Randomize;
  for i := High(CharArray) downto 1 do
  begin
    j := Random(i + 1); // Случайный индекс от 0 до i
    // Меняем местами символы
    Temp := CharArray[i];
    CharArray[i] := CharArray[j];
    CharArray[j] := Temp;
  end;

  // Преобразуем массив символов обратно в строку
  Result := String.Create(CharArray);
end;

function TSecretTools.UInt64ToChars(const Value: UInt64): AnsiString;
var
  sale, N, D: UInt64;
begin
  Result := '';
  if FCharSet = '' then
    Exit;
  D := Value;
  while D > 0 do
  begin
    if D > FCharLen then
    begin
      N    := D div FCharLen;
      sale := D mod FCharLen;
      if sale = 0 then
      begin
        Result := FCharSet[FCharLen] + Result;
        D := N - 1;
      end
      else
      begin
        Result := FCharSet[sale] + Result;
        D := N;
      end;
    end
    else
    begin
      Result := FCharSet[D] + Result;
      Break;
    end;
  end;
end;

end.
