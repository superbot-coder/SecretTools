# Модуль **SecretTools.pas**
Полезный модуль, который я использую для генерации серийных номеров программ
Это всего скорее на подобие такого мини ящика с инструментами где собраны полезные функции. Сперва я хотел оформить виде интерфейса но выяснилось, что нет ни одного объекта, время жизни которого нужно было бы контролировать и поэтому оформил все в виде TSecretTools = record. 

### Зависимости 
 1. Библиотека [DelphiEncryptionCompendium](https://github.com/MHumm/DelphiEncryptionCompendium)

### Описание методов

```pascal
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
```

Параметр const **Done**: Boolean который встречается в функциях означает финализацию  расчет контрольной суммы. 
Параметр имеет значение по умолчанию "True" для вычисления одной операции или блока данных,  если же нужно вычислить контрольную сумму в потоке данных, например, нескольких строк идущих строка за строкой, то этот параметр необходимо перевести в состояние "false".
Например, у нас есть две строки **'String_first'** и **'String_two'** нужно посчитать общую контрольную сумму обеих строк, то код будет такой:

```pascal
// Создадим экземпляр с инициализацией
  var SE := TSecretTools.Crete(CRC_32, '');

  // значения строк
  var S1 := 'String_first';
  var S2 := 'String_two';

  (* Подсчитываем сумму первой строки параметр Done = false
     это значить, что контрольная сумма будет сохранена
     для сложения её с последующей строкой *)
  Show('CRC32 S1: ' + SE.CRCString(S1, false).ToString);

  (* Подсчитываем контрольную сумму второй строки к сумме второй строки
    будет сложена с сумма первой строки как будто они единое целое.
    Done = "true" - это значит, что после вычисления контрольной суммы
    подсчет будет финализирован и можно делать новый подсчет,
    который не будет суммарно складываться с предудущими данными *)
  Show('CRC32 S2: ' + SE.CRCString(S2, true).ToString);

  (* Альтернативный ввод данных: параметр Done можно пропустить
    в этом случае компилятр применит параметр по у молчинию который равен "true" *)
  // Show('CRC32 S2: ' + SE.CRCString(S2).ToString);

  (* Контрольная сумма разделенного вычисления будет эквивалетнона
    сумме сложенных строк вместе  S1 + S2 *)
  show('CRC32 S1 + S2: ' + SE.CRCString(S1 + S2).ToString);
``` 

Результат вывода: 
```
CRC32 S1: 3487669340
CRC32 S2: 2820161786
CRC32 S1 + S2: 2820161786
```

**ShuffleString** - функция смешивает строку случайным образом

**CRCUint**  - функция получения контрольной суммы для числа целого типа.

**CRCUintToChars** - функция получения контрольной суммы для числа целого типа,
вывод конвертируется в строковый формат и состоит из символов Chars, см. **UInt64ToChars**

**CRCString** - функция для получения контрольной суммы строки

**CRCStringToChars** - функция для получения контрольной суммы строки c выводом результата в  формате строки из символов Chars, см. выше как у  **UInt64ToChars**
**ReInit** - процедура которая позволяет сделать новую инициализацию аналогично Create()

**UInt64ToChars** - Функция, которая преобразует число или строку в строку из символов Chars (AnsiString), для этого нужно в конструкторе Crete() задать строку символов const ACharSet или задать позже через свойство (property) **CharSet := 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';**  или задать такую строку через **ReInit()** Символы должны быть уникальными без повторов, иначе будет не правильно работать или может привести к ошибкам в вычислении. 

**CharsToUint64** - Функция обратная функции **UInt64ToChars** конвертирует строку из Chars в Uint64 (Cardinal)

**EncodeXor** - Две перегруженные Функции одна для чисел другая для строк, функции выполняют простою операцию XOR простая 

**CRCFile** - функция для подсчета контрольной суммы файлов

### Еще один пример:

```pascal
  var SE := TSecretTools.Crete(CRC_32, '');
  var S1 := 'String_first';
  var S2 := 'String_two';
  var Chars := 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
  SE.CharSet := Chars;
  var crcOut := SE.CRCString(S1 + S2);
  show('CRC to Chars: ' + SE.UInt64ToChars(crcOut));

  // Смешиваем строку Chars случайным порядком
  SE.CharSet := SE.ShuffleString(Chars);
  show('CRC to ShuffleString Chars: ' + SE.CRCStringToChars(S1 + S2));
```

Результат: 
```
CRC to Chars: AJWA30N 
CRC to ShuffleString Chars: CMOC9WZ
```
#### Telegram channel: https://t.me/delphi_solutions
#### Telegram chat: https://t.me/delphi_solutions_chat
#### Telegram video: https://t.me/delphi_solutions_video