unit SecretTools;

interface

USES
  System.SysUtils, System.Classes, System.Math, System.IOUtils,
  DECCRC, DECBaseClass;

Type

  TSecretTool = record
  private
    FCRC: TCRCDef;
    FCharSet: AnsiString;
    FCharLen: UInt8;
    FBytesBuf: TBytes;
    procedure SetCharSet(const ACharSet: AnsiString);
  public
    constructor Crete(const CRCType: TCRCType; const ACharSet: AnsiString);
    property CharSet: AnsiString read FCharSet write SetCharSet;
    function ShuffleString(const Input: string): string; inline;
    function CRCUint(const Value: Uint32; const Done: Boolean = true): Uint32; inline;
    function CRCUintToChars(const Value: Uint32): AnsiString; inline;
    function CRCString(const Value: String; const Done: Boolean = true): Uint32; inline;
    function CRCStringToChars(const Value: String): AnsiString; inline;
    procedure ReInit(const CRCType: TCRCType; const ASharSet: AnsiString); inline;
    function UInt64ToChars(const Value: UInt64): AnsiString; inline;
    function CharsToUint64(const Value: AnsiString): Uint64; inline;
    function EncodeXor(const ValueA, ValueB: Uint32): Uint32; overload; inline;
    function EncodeXor(const SrcValue, KeyValue: AnsiString): String; overload; inline;
    function CRCFile(const FileName: String): Uint32; inline;
  end;

implementation

function TSecretTool.CharsToUint64(const Value: AnsiString): Uint64;
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

function TSecretTool.CRCFile(const FileName: String): Uint32;
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

function TSecretTool.CRCString(const Value: String; const Done: Boolean): Uint32;
begin
  FBytesBuf := BytesOf(AnsiString(Value));
  Result := CRCCode(FCRC, FBytesBuf[0], Length(FBytesBuf));
  if Done then
    CRCDone(FCRC);
end;

function TSecretTool.CRCStringToChars(const Value: String): AnsiString;
begin
  Result := UInt64ToChars(CRCString(Value, True));
end;

function TSecretTool.CRCUint(const Value: Uint32; const Done: Boolean): Uint32;
begin
  FBytesBuf := BytesOf(Pointer(@Value), 4);
  Result := CRCCode(FCRC, FBytesBuf[0], 4);
  if Done then
    CRCDone(FCRC);
end;

function TSecretTool.CRCUintToChars(const Value: Uint32): AnsiString;
begin
  Result := UInt64ToChars(CRCUint(Value, True));
end;

constructor TSecretTool.Crete(const CRCType: TCRCType; const ACharSet: AnsiString);
begin
  FCharSet :=  ACharSet;
  CRCInit(FCRC, CRCType);
  SetCharSet(ACharSet);
end;

function TSecretTool.EncodeXor(const SrcValue,
  KeyValue: AnsiString): String;
var
  Len: Uint32;
  i,j: Uint32;
  b: byte;
begin
  if (Length(SrcValue) <> 0) and (Length(KeyValue) <> 0) then
  begin
    for i := 0 to Pred(Length(SrcValue)) do
    begin
      b := Byte(SrcValue[i]);
      for j := 1 to Length(KeyValue) do
      begin
        b := b xor Byte(KeyValue[j]);
      end;
      Result := Result + b.ToHexString;
    end;
  end;
end;

function TSecretTool.EncodeXor(const ValueA, ValueB: Uint32): Uint32;
begin
  Result := ValueA xor ValueB;
end;

procedure TSecretTool.ReInit(const CRCType: TCRCType; const ASharSet: AnsiString);
begin
  CRCDone(FCRC);
  CRCInit(FCRC, CRCType);
  SetCharSet(ASharSet);
end;

procedure TSecretTool.SetCharSet(const ACharSet: AnsiString);
begin
  if Length(ACharSet) > High(Byte) then
    raise Exception.Create('Error: length ASharSet > 256 byte');
  FCharSet := ACharSet;
  FCharLen := Length(FCharSet);
end;

function TSecretTool.ShuffleString(const Input: string): string;
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

function TSecretTool.UInt64ToChars(const Value: UInt64): AnsiString;
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
