{******************************************************************************}
{                       CnPack For Delphi/C++Builder                           }
{                     中国人自己的开放源码第三方开发包                         }
{                   (C)Copyright 2001-2017 CnPack 开发组                       }
{                   ------------------------------------                       }
{                                                                              }
{            本开发包是开源的自由软件，您可以遵照 CnPack 的发布协议来修        }
{        改和重新发布这一程序。                                                }
{                                                                              }
{            发布这一开发包的目的是希望它有用，但没有任何担保。甚至没有        }
{        适合特定目的而隐含的担保。更详细的情况请参阅 CnPack 发布协议。        }
{                                                                              }
{            您应该已经和开发包一起收到一份 CnPack 发布协议的副本。如果        }
{        还没有，可访问我们的网站：                                            }
{                                                                              }
{            网站地址：http://www.cnpack.org                                   }
{            电子邮件：master@cnpack.org                                       }
{                                                                              }
{******************************************************************************}

unit CnWidePasParser;
{* |<PRE>
================================================================================
* 软件名称：CnPack IDE 专家包
* 单元名称：Pas 源代码分析器的 Unicode 版本
* 单元作者：周劲羽 zjy@cnpack.org
* 备    注：改写自 CnPasCodeParser，去掉了一个无需改造的函数
* 开发平台：Win7 + Delphi 2009
* 兼容测试：
* 本 地 化：该单元中的字符串均符合本地化处理方式
* 单元标识：$Id: CnPasCodeParser.pas 1385 2013-12-31 15:39:02Z liuxiaoshanzhashu@gmail.com $
* 修改记录：2015.04.25 V1.1
*               增加 WideString 实现
*           2015.04.10
*               创建单元
================================================================================
|</PRE>}

interface

{$I CnWizards.inc}

uses
  Windows, SysUtils, Classes, mPasLex, CnPasWideLex, mwBCBTokenList,
  Contnrs, CnFastList, CnPasCodeParser, CnContainers;

type
{$IFDEF UNICODE}
  CnWideString = string;
{$ELSE}
  CnWideString = WideString;
{$ENDIF}

  TCnWidePasToken = class(TPersistent)
  {* 描述一 Token 的结构高亮信息}
  private
    FEditAnsiCol: Integer;
    FTag: Integer;
    function GetToken: PWideChar;
  protected
    FCppTokenKind: TCTokenKind;
    FCompDirectiveType: TCnCompDirectiveType;
    FCharIndex: Integer;
    FAnsiIndex: Integer;
    FEditCol: Integer;
    FEditLine: Integer;
    FItemIndex: Integer;
    FItemLayer: Integer;
    FLineNumber: Integer;
    FMethodLayer: Integer;
    FToken: array[0..CN_TOKEN_MAX_SIZE] of WideChar;
    FTokenID: TTokenKind;
    FTokenPos: Integer;
    FIsMethodStart: Boolean;
    FIsMethodClose: Boolean;
    FIsBlockStart: Boolean;
    FIsBlockClose: Boolean;
    FUseAsC: Boolean;
  public
    procedure Clear;

    property UseAsC: Boolean read FUseAsC;
    {* 是否是 C 方式的解析，默认不是}
    property LineNumber: Integer read FLineNumber; // Start 0
    {* 所在行号，从零开始，由 ParseSource 计算而来 }
    property CharIndex: Integer read FCharIndex;   // Start 0
    {* 从本行开始数的字符位置，从零开始，由 ParseSource 内据需展开 Tab 计算而来 }
    property AnsiIndex: Integer read FAnsiIndex;   // Start 0
    {* 从本行开始数的 Ansi 字符位置，从零开始，计算而来}

    property EditCol: Integer read FEditCol write FEditCol;
    {* 所在列，从一开始，由外界转换而来，一般对应 EditPos}
    property EditLine: Integer read FEditLine write FEditLine;
    {* 所在行，从一开始，由外界转换而来，一般对应 EditPos}
    property EditAnsiCol: Integer read FEditAnsiCol write FEditAnsiCol;
    {* 所在 Ansi 列，从一开始，由外界转换而来，用于绘制的场合}

    property ItemIndex: Integer read FItemIndex;
    {* 在整个 Parser 中的序号 }
    property ItemLayer: Integer read FItemLayer;
    {* 所在高亮的层次，包括过程、函数以及代码块，可直接用来绘制高亮层次，不在任何块内时（最外层）为 0 }
    property MethodLayer: Integer read FMethodLayer;
    {* 所在函数的嵌套层次，最外层的函数内为 1，包括匿名函数 }
    property Token: PWideChar read GetToken;
    {* 该 Token 的字符串内容 }
    property TokenID: TTokenKind read FTokenID;
    {* Token 的语法类型 }
    property CppTokenKind: TCTokenKind read FCppTokenKind;
    {* 作为 C 的 Token 使用时的 CToken 类型}
    property TokenPos: Integer read FTokenPos;
    {* Token 在整个文件中的线性位置 }
    property IsBlockStart: Boolean read FIsBlockStart;
    {* 是否是一块可匹配代码区域的开始 }
    property IsBlockClose: Boolean read FIsBlockClose;
    {* 是否是一块可匹配代码区域的结束 }
    property IsMethodStart: Boolean read FIsMethodStart;
    {* 是否是函数过程的开始，包括 function 和 begin/asm 的情况 }
    property IsMethodClose: Boolean read FIsMethodClose;
    {* 是否是函数过程的结束，只包括 end 的情况，因此和 MethodStart 数量不等 }
    property CompDirectivtType: TCnCompDirectiveType read FCompDirectiveType write FCompDirectiveType;
    {* 当其类型是 Pascal 编译指令时，此域代表其详细类型，但不解析，由外部按需解析}
    property Tag: Integer read FTag write FTag;
    {* Tag 标记，供外界特殊场合使用}
  end;

//==============================================================================
// Pascal Unicode 文件结构高亮解析器
//==============================================================================

  { TCnPasStructureParser }

  TCnWidePasStructParser = class(TObject)
  {* 利用 TCnPasWideLex 进行语法解析得到各个 Token 和位置信息}
  private
    FSupportUnicodeIdent: Boolean;
    FBlockCloseToken: TCnWidePasToken;
    FBlockStartToken: TCnWidePasToken;
    FChildMethodCloseToken: TCnWidePasToken;
    FChildMethodStartToken: TCnWidePasToken;
    FCurrentChildMethod: CnWideString;
    FCurrentMethod: CnWideString;
    FKeyOnly: Boolean;
    FList: TCnList;
    FMethodCloseToken: TCnWidePasToken;
    FMethodStartToken: TCnWidePasToken;
    FSource: CnWideString;
    FInnerBlockCloseToken: TCnWidePasToken;
    FInnerBlockStartToken: TCnWidePasToken;
    FTabWidth: Integer;
    FMethodStack: TCnObjectStack;
    FBlockStack: TCnObjectStack;
    FMidBlockStack: TCnObjectStack;
    FProcStack: TCnObjectStack;
    FIfStack: TCnObjectStack;
    function GetCount: Integer;
    function GetToken(Index: Integer): TCnWidePasToken;
  public
    constructor Create(SupportUnicodeIdent: Boolean = True);
    destructor Destroy; override;
    procedure Clear;
    procedure ParseSource(ASource: PWideChar; AIsDpr, AKeyOnly: Boolean);
    function FindCurrentDeclaration(LineNumber, WideCharIndex: Integer): CnWideString;
    {* 查找指定光标位置所在的声明，LineNumber 1 开始，WideCharIndex 0 开始，类似于 CharPos，
       但要求是 WideChar 偏移。D2005~2007 下，CursorPos.Col 经 ConverPos 后得到的是
       Utf8 的 CharPos 偏移，2009 或以上 ConverPos 得到混乱的 Ansi 偏移，都不能直接用。
       前者需要转成 WideChar 偏移，后者只能把 CursorPos.Col - 1 当作 Ansi 的 CharIndex，
       再转成 WideChar 的偏移}
    procedure FindCurrentBlock(LineNumber, WideCharIndex: Integer);
    {* 查找指定光标位置所在的块，LineNumber 1 开始，WideCharIndex 0 开始，类似于 CharPos，
       但要求是 WideChar 偏移。D2005~2007 下，CursorPos.Col 经 ConverPos 后得到的是
       Utf8 的 CharPos 偏移，2009 或以上 ConverPos 得到混乱的 Ansi 偏移，都不能直接用。
       前者需要转成 WideChar 偏移，后者只能把 CursorPos.Col - 1 当作 Ansi 的 CharIndex，
       再转成 WideChar 的偏移}
    function IndexOfToken(Token: TCnWidePasToken): Integer;
    property Count: Integer read GetCount;
    property Tokens[Index: Integer]: TCnWidePasToken read GetToken;
    property MethodStartToken: TCnWidePasToken read FMethodStartToken;
    {* 当前最外层的过程或函数}
    property MethodCloseToken: TCnWidePasToken read FMethodCloseToken;
    {* 当前最外层的过程或函数}
    property ChildMethodStartToken: TCnWidePasToken read FChildMethodStartToken;
    {* 当前最内层的过程或函数，用于有嵌套过程或函数定义的情况}
    property ChildMethodCloseToken: TCnWidePasToken read FChildMethodCloseToken;
    {* 当前最内层的过程或函数，用于有嵌套过程或函数定义的情况}
    property BlockStartToken: TCnWidePasToken read FBlockStartToken;
    {* 当前最外层块}
    property BlockCloseToken: TCnWidePasToken read FBlockCloseToken;
    {* 当前最外层块}
    property InnerBlockStartToken: TCnWidePasToken read FInnerBlockStartToken;
    {* 当前最内层块}
    property InnerBlockCloseToken: TCnWidePasToken read FInnerBlockCloseToken;
    {* 当前最内层块}
    property CurrentMethod: CnWideString read FCurrentMethod;
    {* 当前最外层的过程或函数名}
    property CurrentChildMethod: CnWideString read FCurrentChildMethod;
    {* 当前最内层的过程或函数名，用于有嵌套过程或函数定义的情况}
    property Source: CnWideString read FSource;
    property KeyOnly: Boolean read FKeyOnly;
    {* 是否只处理出关键字}

    {* 是否排版处理 Tab 键的宽度，如不处理，则将 Tab 键当作宽为 1 处理}
    property TabWidth: Integer read FTabWidth write FTabWidth;
    {* Tab 键的宽度}
  end;

procedure ParseUnitUsesW(const Source: CnWideString; UsesList: TStrings;
  SupportUnicodeIdent: Boolean = False);
{* 分析源代码中引用的单元}

implementation

type
  TCnProcObj = class
  {* 描述一个完整的 procedure/function 定义，包括匿名函数}
  private
    FToken: TCnWidePasToken;
    FBeginToken: TCnWidePasToken;
    FNestCount: Integer;
    function GetIsNested: Boolean;
    function GetBeginMatched: Boolean;
    function GetLayer: Integer;
  public
    property Token: TCnWidePasToken read FToken write FToken;
    {* procedure/function 所在的 Token}
    property Layer: Integer read GetLayer;
    {* procedure/function 所在的 Token 的层次数}
    property BeginMatched: Boolean read GetBeginMatched;
    {* 该 procedure/function 是否已与找到了实现体的 begin}
    property BeginToken: TCnWidePasToken read FBeginToken write FBeginToken;
    {* 该 procedure/function 实现体的 begin}
    property IsNested: Boolean read GetIsNested;
    {* 该 procedure/function 是否是被嵌套定义的，也即是否在外一层
       procedure/function 的声明部分（实现体 begin 之前}
    property NestCount: Integer read FNestCount write FNestCount;
    {* 该 procedure/function 的嵌套定义层数，也即离最近一个非嵌套 procedure/function 的层距离}
  end;

  TCnIfStatement = class
  {* 描述一个完整的 If 语句，可能带多个 else if 以及一个或 0 个 else，各块内还可能有 begin end}
  private
    FLevel: Integer;
    FIfStart: TCnWidePasToken;     // 存储主 if 引用
    FIfBegin: TCnWidePasToken;     // 存储 if 对应的同级 begin
    FIfEnded: Boolean;             // 该 if 主块是否结束（不是整个 if 语句）
    FElseToken: TCnWidePasToken;   // 存储 else 引用
    FElseBegin: TCnWidePasToken;   // 存储 else 对应的同级 begin
    FElseEnded: Boolean;           // 该 else 块是否结束
    FElseList: TObjectList;        // 存储多个 else if 中的 else 引用
    FIfList: TObjectList;          // 存储多个 else if 中的 if 引用
    FElseIfBeginList: TObjectList; // 存储多个 else if 的对应 begin，可能为空
    FElseIfEnded: TList;           // 存储多个 else if 是否结束的标记，1 或 0
    FIfAllEnded: Boolean;          // 整个 if 是否结束
    function GetElseIfCount: Integer;
    function GetElseIfElse(Index: Integer): TCnWidePasToken;
    function GetElseIfIf(Index: Integer): TCnWidePasToken;
    function GetLastElseIfElse: TCnWidePasToken;
    function GetLastElseIfIf: TCnWidePasToken;
    procedure SetIfStart(const Value: TCnWidePasToken);
    function GetLastElseIfBegin: TCnWidePasToken;
    procedure SetFIfBegin(const Value: TCnWidePasToken);
    procedure SetElseBegin(const Value: TCnWidePasToken);
  public
    constructor Create; virtual;
    destructor Destroy; override;

    function HasElse: Boolean;
    {* 该 if 块是否有单独的 else}

    procedure ChangeElseToElseIf(AIf: TCnWidePasToken);
    {* 将最后一个 else 改为一个 else if，用于 else 后接受到 if 时}
    procedure AddBegin(ABegin: TCnWidePasToken);
    {* 外界判断后，将 begin 挂入此 If，根据实际情况挂 else if 下或 if 头下}

    // 以下三个结束当前子块的条件是：
    // 1. 该子块有紧接的 begin，且有对应层次的 end，或者
    // 2. 该子块无紧接的 begin，有同层次的分号（层次判断不易，改用当前块的前后判断规则），或
    // 3. 该子块无紧接的 begin，但有上一层次的 end（前面无分号）；如 if then begin if then Close end; 中的 Close 语句
    procedure EndLastElseIfBlock;
    {* 令最后一个 else if 块结束，来源是 end 或分号}
    procedure EndElseBlock;
    {* 令 else 块结束，来源是 end 或分号}
    procedure EndIfBlock;
    {* 令 if 块结束（不是整个 if 语句），来源是 end 或分号}
    procedure EndIfAll;
    {* 令整个 if 语句结束，来源是 end 或分号}

    property Level: Integer read FLevel write FLevel;
    {* if 语句的层次，主要是 if 的层次}
    property IfStart: TCnWidePasToken read FIfStart write SetIfStart;
    {* 获取 if 起始 Token 以及将一个 Token 设为 if 起始 Token}
    property IfBegin: TCnWidePasToken read FIfBegin write SetFIfBegin;
    {* 获取 if 自身对应的 begin 的 Token 以及将一个 begin 设为 if 对应的 begin}
    property ElseToken: TCnWidePasToken read FElseToken write FElseToken;
    {* 获取 if 里的 else 的 Token 以及将一个 Token 设为 if 里的 else 的 Token}
    property ElseBegin: TCnWidePasToken read FElseBegin write SetElseBegin;
    {* 获取 if 里的 else 所对应的 begin 以及将一个 Token 设为此 else 对应的 begin 的 Token}
    property ElseIfCount: Integer read GetElseIfCount;
    {* 返回该 if 块的 else if 数量}
    property ElseIfElse[Index: Integer]: TCnWidePasToken read GetElseIfElse;
    {* 返回该 if 块的 else if 的 else 的 Token，索引从 0 到 ElseIfCount - 1}
    property ElseIfIf[Index: Integer]: TCnWidePasToken read GetElseIfIf;
    {* 返回该 if 块的 else if 的  的 Token，索引从 0 到 ElseIfCount - 1}
    property LastElseIfElse: TCnWidePasToken read GetLastElseIfElse;
    {* 返回该 if 块的最后一个 else if 的 else}
    property LastElseIfIf: TCnWidePasToken read GetLastElseIfIf;
    {* 返回该 if 块的最后一个 else if 的 if}
    property LastElseIfBegin: TCnWidePasToken read GetLastElseIfBegin;
    {* 返回该 if 块的最后一个 else if 的 begin，如果有的话}
    property IfAllEnded: Boolean read FIfAllEnded;
    {* 返回该 if 语句是否全部结束，供判断并从堆栈中弹出}
  end;

var
  TokenPool: TCnList;

function WideTrim(const S: CnWideString): CnWideString;
{$IFNDEF UNICODE}
var
  I, L: Integer;
{$ENDIF}
begin
{$IFDEF UNICODE}
  Result := Trim(S);
{$ELSE}
  L := Length(S);
  I := 1;
  while (I <= L) and (S[I] <= ' ') do Inc(I);
  if I > L then Result := '' else
  begin
    while S[L] <= ' ' do Dec(L);
    Result := Copy(S, I, L - I + 1);
  end;
{$ENDIF}
end;

// 用池方式来管理 PasTokens 以提高性能
function CreatePasToken: TCnWidePasToken;
begin
  if TokenPool.Count > 0 then
  begin
    Result := TCnWidePasToken(TokenPool.Last);
    TokenPool.Delete(TokenPool.Count - 1);
  end
  else
    Result := TCnWidePasToken.Create;
end;

procedure FreePasToken(Token: TCnWidePasToken);
begin
  if Token <> nil then
  begin
    Token.Clear;
    TokenPool.Add(Token);
  end;
end;

procedure ClearTokenPool;
var
  I: Integer;
begin
  for I := 0 to TokenPool.Count - 1 do
    TObject(TokenPool[I]).Free;
end;

// NextNoJunk仅仅只跳过注释，而没跳过编译指令的情况。加此函数可过编译指令
procedure LexNextNoJunkWithoutCompDirect(Lex: TCnPasWideLex);
begin
  repeat
    Lex.Next;
  until not (Lex.TokenID in [tkSlashesComment, tkAnsiComment, tkBorComment, tkCRLF,
    tkCRLFCo, tkSpace, tkCompDirect]);
end;

//==============================================================================
// 结构高亮解析器
//==============================================================================

{ TCnPasStructureParser }

constructor TCnWidePasStructParser.Create(SupportUnicodeIdent: Boolean);
begin
  inherited Create;
  FList := TCnList.Create;
  FTabWidth := 2;
  FSupportUnicodeIdent := SupportUnicodeIdent;

  FMethodStack := TCnObjectStack.Create;
  FBlockStack := TCnObjectStack.Create;
  FMidBlockStack := TCnObjectStack.Create;
  FProcStack := TCnObjectStack.Create;
  FIfStack := TCnObjectStack.Create;
end;

destructor TCnWidePasStructParser.Destroy;
begin
  Clear;
  FMethodStack.Free;
  FBlockStack.Free;
  FMidBlockStack.Free;
  FProcStack.Free;
  FIfStack.Free;
  FList.Free;
  inherited;
end;

procedure TCnWidePasStructParser.Clear;
var
  I: Integer;
begin
  for I := 0 to FList.Count - 1 do
    FreePasToken(TCnWidePasToken(FList[I]));
  FList.Clear;

  FMethodStartToken := nil;
  FMethodCloseToken := nil;
  FChildMethodStartToken := nil;
  FChildMethodCloseToken := nil;
  FBlockStartToken := nil;
  FBlockCloseToken := nil;
  FCurrentMethod := '';
  FCurrentChildMethod := '';
  FSource := '';
end;

function TCnWidePasStructParser.GetCount: Integer;
begin
  Result := FList.Count;
end;

function TCnWidePasStructParser.GetToken(Index: Integer): TCnWidePasToken;
begin
  Result := TCnWidePasToken(FList[Index]);
end;

procedure TCnWidePasStructParser.ParseSource(ASource: PWideChar; AIsDpr, AKeyOnly:
  Boolean);
var
  Lex: TCnPasWideLex;
  Token, CurrMethod, CurrBlock, CurrMidBlock, CurrIfStart: TCnWidePasToken;
  Bookmark: TCnPasWideBookmark;
  IsClassOpen, IsClassDef, IsImpl, IsHelper, IsElseIf, ExpectElse: Boolean;
  IsRecordHelper, IsSealed, IsAbstract, IsRecord, IsForFunc: Boolean;
  SameBlockMethod, CanEndBlock, CanEndMethod: Boolean;
  DeclareWithEndLevel: Integer;
  PrevTokenID: TTokenKind;
  PrevTokenStr: CnWideString;
  AProcObj, PrevProcObj: TCnProcObj;
  AIfObj: TCnIfStatement;

  procedure CalcCharIndexes(out ACharIndex: Integer; out AnAnsiIndex: Integer);
    function GetExtraSpaceForTabs: Integer;
    var
      i, LineLength: Integer;
    begin
      Result := 0;
      LineLength := Lex.TokenPos - Lex.LineStartOffset;
      for i := 0 to LineLength - 1 do
        if (ASource[Lex.LineStartOffset + i] = #09) then
          Inc(Result, FTabWidth - 1 - ((i + Result) mod FTabWidth));
    end;
  var
    ExtraSpaceForTabs: Integer;
  begin
    ACharIndex := Lex.TokenPos - Lex.LineStartOffset;
    AnAnsiIndex := Lex.ColumnNumber - 1;

    if (FTabWidth > 1) then
    begin
      ExtraSpaceForTabs := GetExtraSpaceForTabs;
      Inc(ACharIndex, ExtraSpaceForTabs);
      Inc(AnAnsiIndex, ExtraSpaceForTabs);
    end;
  end;

  procedure NewToken;
  var
    Len: Integer;
  begin
    Token := CreatePasToken;
    Token.FTokenPos := Lex.TokenPos;

    Len := Lex.TokenLength;
    if Len > CN_TOKEN_MAX_SIZE then
      Len := CN_TOKEN_MAX_SIZE;
    FillChar(Token.FToken[0], SizeOf(Token.FToken), 0);
    CopyMemory(@Token.FToken[0], Lex.TokenAddr, Len * SizeOf(WideChar));

    Token.FLineNumber := Lex.LineNumber - 1;              // 1 开始变成 0 开始
    CalcCharIndexes(Token.FCharIndex, Token.FAnsiIndex);
    // 不直接使用 Column 直观列号属性，而是据需 Tab 展开，俩也都会由 1 开始变成 0 开始

    Token.FTokenID := Lex.TokenID;
    Token.FItemIndex := FList.Count;
    if CurrBlock <> nil then
      Token.FItemLayer := CurrBlock.FItemLayer;

    // CurrBlock 的 ItemLayer 包含了 MethodLayer，但如果没有 CurrBlock，
    // 就得考虑用 CurrMethod 的 MethodLayer 来初始化 Token 的 ItemLayer。
    if CurrMethod <> nil then
    begin
      Token.FMethodLayer := CurrMethod.FMethodLayer;
      if CurrBlock = nil then
        Token.FItemLayer := CurrMethod.FMethodLayer;
    end;
    FList.Add(Token);
  end;

  procedure DiscardToken(Forced: Boolean = False);
  begin
    if (AKeyOnly or Forced) and (FList.Count > 0) then
    begin
      FreePasToken(FList[FList.Count - 1]);
      FList.Delete(FList.Count - 1);
    end;
  end;

  procedure ClearStackAndFreeObject(AStack: TCnObjectStack);
  begin
    if AStack = nil then
      Exit;

    while AStack.Count > 0 do
      AStack.Pop.Free;
  end;

begin
  Clear;
  Lex := nil;
  PrevTokenID := tkProgram;

  try
    FSource := ASource;
    FKeyOnly := AKeyOnly;

    FMethodStack.Clear;
    FBlockStack.Clear;
    FMidBlockStack.Clear;
    FProcStack.Clear;  // 存储 procedure/function 实现的关键字以及其嵌套层次
    FIfStack.Clear;    // 存储 if 的嵌套信息

    Lex := TCnPasWideLex.Create(FSupportUnicodeIdent);
    Lex.Origin := PWideChar(ASource);

    DeclareWithEndLevel := 0; // 嵌套的需要end的定义层数
    Token := nil;
    CurrMethod := nil;        // 当前 Token 所在的方法，包括匿名函数的 procedure/function
    CurrBlock := nil;         // 当前 Token 所在的块。
    CurrMidBlock := nil;
    IsImpl := AIsDpr;
    IsHelper := False;
    IsRecordHelper := False;
    ExpectElse := False;

    while Lex.TokenID <> tkNull do
    begin
      // 根据上一轮的结束条件判断是否能结束整个 if 语句
      if ExpectElse and (Lex.TokenID <> tkElse) and not FIfStack.IsEmpty then
        FIfStack.Pop.Free;
      ExpectElse := False;

      if {IsImpl and } (Lex.TokenID in [tkCompDirect, // Allow CompDirect
        tkProcedure, tkFunction, tkConstructor, tkDestructor,
        tkInitialization, tkFinalization,
        tkBegin, tkAsm,
        tkCase, tkTry, tkRepeat, tkIf, tkFor, tkWith, tkOn, tkWhile,
        tkRecord, tkObject, tkOf, tkEqual,
        tkClass, tkInterface, tkDispinterface,
        tkExcept, tkFinally, tkElse,
        tkEnd, tkUntil, tkThen, tkDo]) then
      begin
        NewToken;
        case Lex.TokenID of
          tkProcedure, tkFunction, tkConstructor, tkDestructor:
            begin
              // 不处理 procedure/function 类型定义，前面是 = 号
              // 也不处理 procedure/function 变量声明，前面是 : 号
              // 也不处理匿名方法声明，前面是 to
              // 但一定要处理匿名方法实现！前面是 := 赋值或 ( , 做参数，但可能不完全
              if IsImpl and ((not (Lex.TokenID in [tkProcedure, tkFunction]))
                or (not (PrevTokenID in [tkEqual, tkColon, tkTo{, tkAssign, tkRoundOpen, tkComma}])))
                and (DeclareWithEndLevel <= 0) then
              begin
                // DeclareWithEndLevel <= 0 表示只处理 class/record 外的声明，内部不管
//                while BlockStack.Count > 0 do
//                  BlockStack.Pop;
//                CurrBlock := nil;
                if CurrBlock = nil then
                  Token.FItemLayer := 0
                else
                  Token.FItemLayer := CurrBlock.ItemLayer;
                Token.FIsMethodStart := True;

                if CurrMethod <> nil then
                begin
                  Token.FMethodLayer := CurrMethod.FMethodLayer + 1;
                  FMethodStack.Push(CurrMethod);
                end
                else
                  Token.FMethodLayer := 1;
                CurrMethod := Token;

                // 碰到 procedure/function 实现时，推入堆栈并记录其层次，暂无 Layer 可记录。
                if FProcStack.IsEmpty then
                  PrevProcObj := nil
                else
                  PrevProcObj := TCnProcObj(FProcStack.Peek);

                AProcObj := TCnProcObj.Create;
                AProcObj.Token := Token;
                FProcStack.Push(AProcObj);

                // 如果当前 procedure 在外面的 procedure 的 begin 后，则算匿名函数，不加嵌套数
                // 如果外面没有 procedure，则更不算嵌套，默认是 0
                if (PrevProcObj <> nil) and not PrevProcObj.BeginMatched then
                  AProcObj.NestCount := PrevProcObj.NestCount + 1;
              end;
            end;
          tkInitialization, tkFinalization:
            begin
              while FBlockStack.Count > 0 do
                FBlockStack.Pop;
              CurrBlock := nil;
              while FMethodStack.Count > 0 do
                FMethodStack.Pop;
              CurrMethod := nil;
            end;
          tkBegin, tkAsm:
            begin
              Token.FIsBlockStart := True;
              // 匿名函数会导致 CurrBlock 与 CurrMethod 都存在且内外关系不确定，
              // 因此如 CurrBlock 存在，需要确定其远于 CurrMethod，这个 begin 才是 MethodStart。
              if (CurrMethod <> nil) and ((CurrBlock = nil) or
                (CurrBlock.ItemIndex < CurrMethod.ItemIndex)) then
                Token.FIsMethodStart := True;

              // 而且得 CurrBlock 比 CurrMethod 近，才能根据 CurrBlock 进一
              // 否则要根据下面的 Method 来进一
              if (CurrBlock <> nil) and ((CurrMethod = nil) or (CurrMethod.ItemIndex < CurrBlock.ItemIndex)) then
                Token.FItemLayer := CurrBlock.FItemLayer + 1
              else if CurrMethod <> nil then // 无 Block 或 Block 在 Method 外，是匿名函数，先进一层
                Token.FItemLayer := CurrMethod.FItemLayer + 1
              else // 下面会根据是否在函数过程内来进层
                Token.FItemLayer := 0;

              FBlockStack.Push(CurrBlock);
              CurrBlock := Token; // begin/asm 既可以是 CurrBlock，也可以是 CurrMethod 的对应 begin/asm

              // 处理本 begin/asm 和 procedure/function 同级时的进层
              if FProcStack.Count > 0 then
              begin
                AProcObj := TCnProcObj(FProcStack.Peek);
                if not AProcObj.BeginMatched then
                begin
                  // 当前 Proc 是嵌套函数时，begin 要进 procedure/function 的直接嵌套层数
                  if AProcObj.IsNested then
                    Inc(Token.FItemLayer, AProcObj.NestCount);

                  // 记录配套的 begin/asm 及其层次
                  AProcObj.BeginToken := Token;
                end;
              end;

              // 判断 begin 是否属于之前的 if 或 else if
              if (Lex.TokenID = tkBegin) and (PrevTokenID in [tkThen, tkElse]) and not FIfStack.IsEmpty then
              begin
                AIfObj := TCnIfStatement(FIfStack.Peek);
                if AIfObj.Level = Token.ItemLayer then
                  AIfObj.AddBegin(Token);
              end;
            end;
          tkCase:
            begin
              if (CurrBlock = nil) or (CurrBlock.TokenID <> tkRecord) then
              begin
                Token.FIsBlockStart := True;
                if CurrBlock <> nil then
                begin
                  Token.FItemLayer := CurrBlock.FItemLayer + 1;
                  FBlockStack.Push(CurrBlock);
                end
                else
                  Token.FItemLayer := 0;
                CurrBlock := Token;
              end
              else
                DiscardToken(True);
            end;
          tkTry, tkRepeat, tkIf, tkFor, tkWith, tkOn, tkWhile,
          tkRecord, tkObject:
            begin
              IsRecord := Lex.TokenID = tkRecord;
              IsForFunc := (PrevTokenID in [tkPoint]) or
                ((PrevTokenID = tkSymbol) and (PrevTokenStr = '&'));
              if IsRecord then
              begin
                // 处理 record helper for 的情形，但在implementation部分其end会被
                // record内部的function/procedure给干掉，暂无解决方案。
                IsRecordHelper := False;
                Lex.SaveToBookMark(Bookmark);

                LexNextNoJunkWithoutCompDirect(Lex);
                if Lex.TokenID in [tkSymbol, tkIdentifier] then
                begin
                  if LowerCase(Lex.Token) = 'helper' then
                    IsRecordHelper := True;
                end;

                Lex.LoadFromBookMark(Bookmark);
              end;

              // 不处理 of object 的字样；不处理前面是 @@ 型的label的情形
              // 额外用 IsRecord 变量因为 Lex.RunPos 恢复后，TokenID 可能会变
              if ((Lex.TokenID <> tkObject) or (PrevTokenID <> tkOf))
                and not (PrevTokenID in [tkAt, tkDoubleAddressOp])
                and not IsForFunc        // 不处理 TParalle.For 以及 .&For 这种函数
                and not ((Lex.TokenID = tkFor) and (IsHelper or IsRecordHelper)) then
                // 不处理 helper 中的 for
              begin
                Token.FIsBlockStart := True;
                if CurrBlock <> nil then
                begin
                  Token.FItemLayer := CurrBlock.FItemLayer + 1;
                  FBlockStack.Push(CurrBlock);
                  if (CurrBlock.TokenID = tkTry) and (Token.TokenID = tkTry)
                    and (CurrMidBlock <> nil) then
                  begin
                    FMidBlockStack.Push(CurrMidBlock);
                    CurrMidBlock := nil;
                  end;
                end
                else
                  Token.FItemLayer := 0;
                CurrBlock := Token;

                if IsRecord then
                begin
                  // 独立记录 record，因为 record 可以在函数体的 begin end 之外配 end
                  // IsInDeclareWithEnd := True;
                  Inc(DeclareWithEndLevel);
                end;
              end;

              if Lex.TokenID = tkFor then
              begin
                if IsHelper then
                  IsHelper := False;
                if IsRecordHelper then
                  IsRecordHelper := False;
              end;

              // 处理 if 或 else if 的情形
              if Lex.TokenID = tkIf then
              begin
                IsElseIf := False;
                if PrevTokenID = tkElse then
                begin
                  // 是 else if，找到最近的 AIfObj，把 else 改成 else if
                  if not FIfStack.IsEmpty then
                  begin
                    AIfObj := TCnIfStatement(FIfStack.Peek);
                    // 这个 if 和所在 if 块必须同级，以预防类似于 case else if then end 的情况
                    if AIfObj.Level = Token.ItemLayer then
                    begin
                      AIfObj.ChangeElseToElseIf(Token);
                      IsElseIf := True;
                    end;
                  end;
                end;

                if not IsElseIf then // 是单纯的 if，记录 if 块与其起始位置并推入堆栈
                begin
                  AIfObj := TCnIfStatement.Create;
                  AIfObj.IfStart := Token;
                  FIfStack.Push(AIfObj);
                end;
              end;
            end;
          tkClass, tkInterface, tkDispInterface:
            begin
              IsHelper := False;
              IsSealed := False;
              IsAbstract := False;
              IsClassDef := ((Lex.TokenID = tkClass) and Lex.IsClass)
                or ((Lex.TokenID = tkInterface) and Lex.IsInterface) or
                (Lex.TokenID = tkDispInterface);

              // 处理不是 classdef 但是 class helper for TObject 的情形
              if not IsClassDef and (Lex.TokenID = tkClass) and not Lex.IsClass then
              begin
                Lex.SaveToBookMark(Bookmark);

                LexNextNoJunkWithoutCompDirect(Lex);
                if Lex.TokenID in [tkSymbol, tkIdentifier, tkSealed, tkAbstract] then
                begin
                  if LowerCase(Lex.Token) = 'helper' then
                  begin
                    IsClassDef := True;
                    IsHelper := True;
                  end
                  else if Lex.TokenID = tkSealed then
                  begin
                    IsClassDef := True;
                    IsSealed := True;
                  end
                  else if Lex.TokenID = tkAbstract then
                  begin
                    IsClassDef := True;
                    IsAbstract := True;
                  end;
                end;

                Lex.LoadFromBookMark(Bookmark);
              end;

              IsClassOpen := False;
              if IsClassDef then
              begin
                IsClassOpen := True;
                Lex.SaveToBookMark(Bookmark);

                LexNextNoJunkWithoutCompDirect(Lex);
                if Lex.TokenID = tkSemiColon then // 是个 class; 不需要 end;
                  IsClassOpen := False
                else if IsHelper or IsSealed or IsAbstract then
                  LexNextNoJunkWithoutCompDirect(Lex);

                if Lex.TokenID = tkRoundOpen then // 有括号，看是不是();
                begin
                  while not (Lex.TokenID in [tkNull, tkRoundClose]) do
                    LexNextNoJunkWithoutCompDirect(Lex);
                  if Lex.TokenID = tkRoundClose then
                    LexNextNoJunkWithoutCompDirect(Lex);
                end;

                if Lex.TokenID = tkSemiColon then
                  IsClassOpen := False
                else if Lex.TokenID = tkFor then
                  IsClassOpen := True;

                Lex.LoadFromBookMark(Bookmark);
              end;

              if IsClassOpen then // 有后续内容，需要一个 end
              begin
                Token.FIsBlockStart := True;
                if CurrBlock <> nil then
                begin
                  Token.FItemLayer := CurrBlock.FItemLayer + 1;
                  FBlockStack.Push(CurrBlock);
                end
                else
                  Token.FItemLayer := 0;

                CurrBlock := Token;
                // 局部声明，需要 end 来结尾
                // IsInDeclareWithEnd := True;
                Inc(DeclareWithEndLevel);
              end
              else // 硬修补，免得 unit 的 interface 以及 class procedure 等被高亮
                DiscardToken(Token.TokenID in [tkClass, tkInterface, tkDispinterface]);
            end;
          tkExcept, tkFinally:
            begin
              if (CurrBlock = nil) or (CurrBlock.TokenID <> tkTry) then
                DiscardToken
              else if CurrMidBlock = nil then
              begin
                CurrMidBlock := Token;
              end
              else
                DiscardToken;
            end;
          tkElse:
            begin
              // 判断 else 是属于较近的 if 块还是较外层的 case 等块是个难题。
              // 遇到 else 时 if then 块已经结束，CurrBlock不会等于 if，所以得额外整一个 CurrIfStart
              CurrIfStart := nil;
              if not FIfStack.IsEmpty then
              begin
                AIfObj := TCnIfStatement(FIfStack.Peek);
                if AIfObj.IfStart <> nil then
                  CurrIfStart := AIfObj.IfStart;
              end;

              // else 前面可以不是分号，无须判断 PrevToken 是否分号
              if (CurrBlock = nil) or (PrevTokenID in [tkAt, tkDoubleAddressOp]) then
                DiscardToken
              else if (CurrBlock.TokenID = tkTry) and (CurrMidBlock <> nil) and
                (CurrMidBlock.TokenID = tkExcept) and
                ((CurrIfStart = nil) or (CurrIfStart.ItemIndex <= CurrBlock.ItemIndex)) then
                Token.FItemLayer := CurrBlock.FItemLayer    // try except else end 比最近的 if 块近，是一块的
              else if (CurrBlock.TokenID = tkCase) and
                ((CurrIfStart = nil) or (CurrIfStart.ItemIndex <= CurrBlock.ItemIndex))then
                Token.FItemLayer := CurrBlock.FItemLayer    // case of 中的 else 比最近的 if 块近，是一块的
              else if not FIfStack.IsEmpty then // 以上情况均不对，则 else 应该属于当前 if 块
              begin
                AIfObj := TCnIfStatement(FIfStack.Peek);
                Token.FItemLayer := AIfObj.Level;
                if not AIfObj.HasElse then
                  AIfObj.ElseToken := Token;
              end;
            end;
          tkEnd, tkUntil, tkThen, tkDo:
            begin
              if (CurrBlock <> nil) and not (PrevTokenID in [tkPoint, tkAt, tkDoubleAddressOp]) then
              begin
                if ((Lex.TokenID = tkUntil) and (CurrBlock.TokenID <> tkRepeat))
                  or ((Lex.TokenID = tkThen) and (CurrBlock.TokenID <> tkIf))
                  or ((Lex.TokenID = tkDo) and not (CurrBlock.TokenID in
                  [tkOn, tkWhile, tkWith, tkFor])) then
                begin
                  DiscardToken;
                end
                else
                begin
                  // 避免部分关键字做变量名的情形，但只是一个小 patch，处理并不完善
                  Token.FItemLayer := CurrBlock.FItemLayer;
                  Token.FIsBlockClose := True;
                  if (CurrBlock.TokenID = tkTry) and (CurrMidBlock <> nil) then
                  begin
                    if FMidBlockStack.Count > 0 then
                      CurrMidBlock := TCnWidePasToken(FMidBlockStack.Pop)
                    else
                      CurrMidBlock := nil;
                  end;

                  // End 既可以结束 Block 也可以结束 procedure，没有必然的先后顺序，要看哪个近
                  // 而且，倘若 CurrBlock 是 CurrMethod 的 begin/asm，则 End 要同时结束俩
                  CanEndBlock := False;
                  CanEndMethod := False;
                  if (CurrBlock = nil) and (CurrMethod = nil) then
                  begin
                    CanEndBlock := False;
                    CanEndMethod := False;
                  end
                  else if (CurrBlock = nil) and (CurrMethod <> nil) then
                  begin
                    CanEndBlock := False;
                    CanEndMethod := True;
                  end
                  else if (CurrBlock <> nil) and (CurrMethod = nil) then
                  begin
                    CanEndBlock := True;
                    CanEndMethod := False;
                  end
                  else if (CurrBlock <> nil) and (CurrMethod <> nil) then
                  begin
                    // 判断 CurrBlock 是不是 CurrMethod 对应的 begin，是则都能结束
                    SameBlockMethod := False;
                    if not FProcStack.IsEmpty then
                    begin
                      AProcObj := TCnProcObj(FProcStack.Peek);
                      if (AProcObj.Token = CurrMethod) and (AProcObj.BeginToken = CurrBlock) then
                        SameBlockMethod := True;
                    end;

                    if SameBlockMethod then
                    begin
                      CanEndMethod := True;
                      CanEndBlock := True;
                    end
                    else
                    begin
                      CanEndBlock := CurrBlock.ItemIndex >= CurrMethod.ItemIndex;
                      CanEndMethod := CurrMethod.ItemIndex >= CurrBlock.ItemIndex;
                    end;
                  end;

                  if CanEndBlock or (Lex.TokenID <> tkEnd) then // 其他直接结束 CurrBlock，End 要结束的也是 CurrBlock
                  begin
                  if FBlockStack.Count > 0 then
                  begin
                    CurrBlock := TCnWidePasToken(FBlockStack.Pop);
                  end
                  else
                  begin
                    CurrBlock := nil;
                    end;
                  end;

                  if CanEndMethod and (Lex.TokenID = tkEnd) then  // 是 End 且要结束的是 CurrMethod
                  begin
                    if (CurrMethod <> nil) and (DeclareWithEndLevel <= 0) then
                    begin
                      Token.FIsMethodClose := True;
                      if FMethodStack.Count > 0 then
                        CurrMethod := TCnWidePasToken(FMethodStack.Pop)
                      else
                        CurrMethod := nil;
                    end;
                  end;
                end;
              end
              else // 硬修补，免得 unit 的 End 也高亮
                DiscardToken(Token.TokenID = tkEnd);

              if (DeclareWithEndLevel > 0) and (Lex.TokenID = tkEnd) then // 跳出了局部声明
                Dec(DeclareWithEndLevel);

              if Lex.TokenID = tkEnd then
              begin
                // 如果 end 与 procedure/function 最新元素同级
                if FProcStack.Count > 0 then
                begin
                  AProcObj := TCnProcObj(FProcStack.Peek);
                  if AProcObj.BeginMatched and (AProcObj.Layer = Token.ItemLayer) then
                    FProcStack.Pop.Free;
                end;

                // 处理 if 对应的系列 begin end 的关系
                if not FIfStack.IsEmpty then
                begin
                  AIfObj := TCnIfStatement(FIfStack.Peek);
                  if (AIfObj.LastElseIfBegin <> nil) and
                    (AIfObj.LastElseIfBegin.ItemLayer = Token.ItemLayer) then
                  begin
                    // 此 end 与最近的 if 块中最后一个 else if 里的 begin 配对，表示此 else if 块结束
                    AIfObj.EndLastElseIfBlock;
                    ExpectElse := True;
                    // 下一个如果不是 else，则整个 if 结束
                  end
                  else if (AIfObj.ElseBegin <> nil) and (AIfObj.ElseBegin.ItemLayer = Token.ItemLayer) then
                  begin
                    // 此 end 与最近的 if 块中的独立 else 中的 begin 配对，表示此 else 块结束，同时整个 if 语句结束
                    AIfObj.EndElseBlock;
                    AIfObj.EndIfAll;
                  end
                  else if (AIfObj.IfBegin <> nil) and (AIfObj.IfBegin.ItemLayer = Token.ItemLayer) then
                  begin
                    // 此 end 与最近的 if 块中的 begin 配对，表示此 if 块结束（不是整个 if 语句）
                    AIfObj.EndIfBlock;
                    ExpectElse := True;
                    // 下一个如果不是 else，则整个 if 结束
                  end
                  else if (AIfObj.LastElseIfBegin = nil) and (AIfObj.LastElseIfIf <> nil) and
                    (AIfObj.LastElseIfIf.ItemLayer > Token.ItemLayer) then
                  begin
                    // 此 end 结束掉最近的 if 块中最后一个无 begin 的 else if （end之前允许无分号），同时结束整个 if
                    AIfObj.EndLastElseIfBlock;
                    AIfObj.EndIfAll;
                  end
                  else if (AIfObj.ElseBegin = nil) and (AIfObj.ElseToken <> nil) and
                    (AIfObj.ElseToken.ItemLayer > Token.ItemLayer) then
                  begin
                    // 此 end 结束掉最近的 if 块中无 begin 的 else （end之前允许无分号），同时结束整个 if
                    AIfObj.EndElseBlock;
                    AIfObj.EndIfAll;
                  end
                  else if (AIfObj.IfBegin = nil) and (AIfObj.IfStart.ItemLayer > Token.ItemLayer) then
                  begin
                    // 此 end 结束掉最近的 if 块中无 begin 的 if （end之前允许无分号），同时结束整个 if
                    AIfObj.EndIfBlock;
                    AIfObj.EndIfAll;
                  end;

                  if AIfObj.FIfAllEnded then
                    FIfStack.Pop.Free;
                end;
              end;
            end;
        end;
      end
      else
      begin
        if not IsImpl and (Lex.TokenID = tkImplementation) then
          IsImpl := True;

        if (Lex.TokenID = tkSemicolon) and not FIfStack.IsEmpty then
        begin
          AIfObj := TCnIfStatement(FIfStack.Peek);
          // 碰到分号，查查它结束了谁，注意不能用 Token，因为没针对分号创建 Token
          // 分号的 ItemLayer 目前没有靠谱值，因此不能依赖 ItemLayer 和 if 的 Level 比较。
          // FList.Count 为分号假想的 ItemIndex
          // 情况一，如果 CurrBlock 存在，且没有后于 if 的 else 且 else 无 begin，说明分号紧接 else 同级
          // 情况二，如果 CurrBlock 存在，且没有后于最后一个 else if 的 if，且无 begin，说明分号紧接最后一个 else if 同级
          // 情况三，如果 CurrBlock 存在，且没有后于 if，且 if 没 begin，说明分号紧接 if 同级
          if CurrBlock <> nil then
          begin
            if AIfObj.HasElse and (AIfObj.ElseBegin = nil) and
              (CurrBlock.ItemIndex <= AIfObj.ElseToken.ItemIndex) then  // 分号结束不带 begin 的 else
            begin
              AIfObj.EndElseBlock;
              AIfObj.EndIfAll;
            end
            else if (AIfObj.ElseIfCount > 0) and (AIfObj.LastElseIfBegin = nil)
              and (AIfObj.LastElseIfIf <> nil) and
              (CurrBlock.ItemIndex <= AIfObj.LastElseIfIf.ItemIndex) then
            begin
              AIfObj.EndLastElseIfBlock;       // 分号结束不带 begin 的最后一个 else if
              AIfObj.EndIfAll;
            end
            else if (AIfObj.IfBegin = nil) and
              (CurrBlock.ItemIndex <= AIfObj.IfStart.ItemIndex) then  // 分号结束不带 begin 的 if 本身
            begin
              AIfObj.EndIfBlock;
              AIfObj.EndIfAll;
            end;

            // 分号结束了整个 if 语句，可以从堆栈中弹出了
            if AIfObj.IfAllEnded then
              FIfStack.Pop.Free;
          end;
        end;

        if (CurrMethod <> nil) and // forward, external 无实现部分，前面必须是分号
          (Lex.TokenID in [tkForward, tkExternal]) and (PrevTokenID = tkSemicolon) then
        begin
          CurrMethod.FIsMethodStart := False;
          if AKeyOnly and (CurrMethod.FItemIndex = FList.Count - 1) then
          begin
            FreePasToken(FList[FList.Count - 1]);
            FList.Delete(FList.Count - 1);
          end;
          if FMethodStack.Count > 0 then
            CurrMethod := TCnWidePasToken(FMethodStack.Pop)
          else
            CurrMethod := nil;

          if FProcStack.Count > 0 then
          begin
            AProcObj := TCnProcObj(FProcStack.Pop);
            AProcObj.Free;
          end;
        end;

        // 需要时，普通标识符加，& 后的标识符也加
        if not AKeyOnly and ((PrevTokenID <> tkAmpersand) or (Lex.TokenID = tkIdentifier)) then
          NewToken;
      end;

      PrevTokenID := Lex.TokenID;
      PrevTokenStr := Lex.Token;
      //LexNextNoJunkWithoutCompDirect(Lex);
      Lex.NextNoJunk;
    end;
  finally
    Lex.Free;
    FMethodStack.Clear;
    FBlockStack.Clear;
    FMidBlockStack.Clear;
    ClearStackAndFreeObject(FProcStack);
    ClearStackAndFreeObject(FIfStack);
  end;
end;

procedure TCnWidePasStructParser.FindCurrentBlock(LineNumber, WideCharIndex:
  Integer);
var
  Token: TCnWidePasToken;
  CurrIndex: Integer;

  procedure _BackwardFindDeclarePos;
  var
    Level: Integer;
    I, NestedProcs: Integer;
    StartInner: Boolean;
  begin
    Level := 0;
    StartInner := True;
    NestedProcs := 1;
    for I := CurrIndex - 1 downto 0 do
    begin
      Token := Tokens[I];
      if Token.IsBlockStart then
      begin
        if StartInner and (Level = 0) then
        begin
          FInnerBlockStartToken := Token;
          StartInner := False;
        end;

        if Level = 0 then
          FBlockStartToken := Token
        else
          Dec(Level);
      end
      else if Token.IsBlockClose then
      begin
        Inc(Level);
      end;

      if Token.IsMethodStart then
      begin
        if Token.TokenID in [tkProcedure, tkFunction, tkConstructor, tkDestructor] then
        begin
          // 由于 procedure 与其对应的 begin 都可能是 MethodStart，因此需要这样处理
          Dec(NestedProcs);
          if (NestedProcs = 0) and (FChildMethodStartToken = nil) then
            FChildMethodStartToken := Token;
          if Token.MethodLayer = 1 then
          begin
            FMethodStartToken := Token;
            Exit;
          end;
        end
        else if Token.TokenID in [tkBegin, tkAsm] then
        begin
          // 在可嵌套声明函数过程的地区，暂时无需其他处理
        end;
      end
      else if Token.IsMethodClose then
        Inc(NestedProcs);

      if Token.TokenID in [tkImplementation] then
      begin
        Exit;
      end;
    end;
  end;

  procedure _ForwardFindDeclarePos;
  var
    Level: Integer;
    I, NestedProcs: Integer;
    EndInner: Boolean;
  begin
    Level := 0;
    EndInner := True;
    NestedProcs := 1;
    for I := CurrIndex to Count - 1 do
    begin
      Token := Tokens[I];
      if Token.IsBlockClose then
      begin
        if EndInner and (Level = 0) then
        begin
          FInnerBlockCloseToken := Token;
          EndInner := False;
        end;

        if Level = 0 then
          FBlockCloseToken := Token
        else
          Dec(Level);
      end
      else if Token.IsBlockStart then
      begin
        Inc(Level);
      end;

      if Token.IsMethodClose then
      begin
        Dec(NestedProcs);
        if Token.MethodLayer = 1 then // 碰到的最近的 Layer 为 1 的，必然是最外层
        begin
          FMethodCloseToken := Token;
          Exit;
        end
        else if (NestedProcs = 0) and (FChildMethodCloseToken = nil) then
          FChildMethodCloseToken := Token;
          // 最近的同层次的，才是 ChildMethodClose
      end
      else if Token.IsMethodStart and (Token.TokenID in [tkProcedure, tkFunction,
        tkConstructor, tkDestructor]) then
      begin
        Inc(NestedProcs);
      end;

      if Token.TokenID in [tkInitialization, tkFinalization] then
      begin
        Exit;
      end;
    end;
  end;

  procedure _FindInnerBlockPos;
  var
    I, Level: Integer;
  begin
    // 此函数在 _ForwardFindDeclarePos 和 _BackwardFindDeclarePos 后调用
    if (FInnerBlockStartToken <> nil) and (FInnerBlockCloseToken <> nil) then
    begin
      // 层次一样则退出
      if FInnerBlockStartToken.ItemLayer = FInnerBlockCloseToken.ItemLayer then
        Exit;
      // 上下方临近的 Block 可能层次不一样，需要找个一样层次的，以最外层为准

      if FInnerBlockStartToken.ItemLayer > FInnerBlockCloseToken.ItemLayer then
        Level := FInnerBlockCloseToken.ItemLayer
      else
        Level := FInnerBlockStartToken.ItemLayer;

      for I := CurrIndex - 1 downto 0 do
      begin
        Token := Tokens[I];
        if Token.IsBlockStart and (Token.ItemLayer = Level) then
          FInnerBlockStartToken := Token;
      end;
      for i := CurrIndex to Count - 1 do
      begin
        Token := Tokens[i];
        if Token.IsBlockClose and (Token.ItemLayer = Level) then
          FInnerBlockCloseToken := Token;
      end;
    end;
  end;

  function _GetMethodName(StartToken, CloseToken: TCnWidePasToken): CnWideString;
  var
    I: Integer;
  begin
    Result := '';
    if Assigned(StartToken) and Assigned(CloseToken) then
      for I := StartToken.ItemIndex + 1 to CloseToken.ItemIndex do
      begin
        Token := Tokens[I];
        if (Token.Token^ = '(') or (Token.Token^ = ':') or (Token.Token^ = ';') then
          Break;
        Result := Result + WideTrim(Token.Token);
      end;
  end;

begin
  FMethodStartToken := nil;
  FMethodCloseToken := nil;
  FChildMethodStartToken := nil;
  FChildMethodCloseToken := nil;
  FBlockStartToken := nil;
  FBlockCloseToken := nil;
  FInnerBlockCloseToken := nil;
  FInnerBlockStartToken := nil;
  FCurrentMethod := '';
  FCurrentChildMethod := '';

  CurrIndex := 0;
  while CurrIndex < Count do
  begin
    // 前者从 0 开始，后者从 1 开始，因此需要减 1
    if (Tokens[CurrIndex].LineNumber > LineNumber - 1) then
      Break;

    // 根据不同的起始 Token，判断条件也有所不同
    if Tokens[CurrIndex].LineNumber = LineNumber - 1 then
    begin
      if (Tokens[CurrIndex].TokenID in [tkBegin, tkAsm, tkTry, tkRepeat, tkIf,
        tkFor, tkWith, tkOn, tkWhile, tkCase, tkRecord, tkObject, tkClass,
        tkInterface, tkDispInterface]) and
        (Tokens[CurrIndex].CharIndex > WideCharIndex ) then // 起始的这样判断
        Break
      else if (Tokens[CurrIndex].TokenID in [tkEnd, tkUntil, tkThen, tkDo]) and
        (Tokens[CurrIndex].CharIndex + Length(Tokens[CurrIndex].Token) > WideCharIndex ) then
        Break;  //结束的这样判断
    end;

    Inc(CurrIndex);
  end;

  if (CurrIndex > 0) and (CurrIndex < Count) then
  begin
    _BackwardFindDeclarePos;
    _ForwardFindDeclarePos;

    _FindInnerBlockPos;
    if not FKeyOnly then
    begin
      FCurrentMethod := _GetMethodName(FMethodStartToken, FMethodCloseToken);
      FCurrentChildMethod := _GetMethodName(FChildMethodStartToken, FChildMethodCloseToken);
    end;
  end;
end;

function TCnWidePasStructParser.IndexOfToken(Token: TCnWidePasToken): Integer;
begin
  Result := FList.IndexOf(Token);
end;

function TCnWidePasStructParser.FindCurrentDeclaration(LineNumber,
  WideCharIndex: Integer): CnWideString;
var
  Idx: Integer;
begin
  Result := '';
  FindCurrentBlock(LineNumber, WideCharIndex);

  if InnerBlockStartToken <> nil then
  begin
    if InnerBlockStartToken.TokenID in [tkClass, tkInterface, tkRecord,
      tkDispInterface] then
    begin
      // 往前找等号以前的标识符
      Idx := IndexOfToken(InnerBlockStartToken);
      if Idx > 3 then
      begin
        if (InnerBlockStartToken.TokenID = tkRecord)
          and (Tokens[Idx - 1].TokenID = tkPacked) then
          Dec(Idx);
        if Tokens[Idx - 1].TokenID = tkEqual then
          Dec(Idx);
        if Tokens[Idx - 1].TokenID = tkIdentifier then
          Result := Tokens[Idx - 1].Token;
      end;
    end;
  end;
end;

// 分析源代码中引用的单元
procedure ParseUnitUsesW(const Source: CnWideString; UsesList: TStrings;
  SupportUnicodeIdent: Boolean);
var
  Lex: TCnPasWideLex;
  Flag: Integer;
  S: CnWideString;
begin
  UsesList.Clear;
  Lex := TCnPasWideLex.Create(SupportUnicodeIdent);

  Flag := 0;
  S := '';
  try
    Lex.Origin := PWideChar(Source);
    while Lex.TokenID <> tkNull do
    begin
      if Lex.TokenID = tkUses then
      begin
        while not (Lex.TokenID in [tkNull, tkSemiColon]) do
        begin
          Lex.Next;
          if Lex.TokenID = tkIdentifier then
          begin
            S := S + CnWideString(Lex.Token);
          end
          else if Lex.TokenID = tkPoint then
          begin
            S := S + '.';
          end
          else if Trim(S) <> '' then
          begin
            UsesList.AddObject(S, TObject(Flag));
            S := '';
          end;
        end;
      end
      else if Lex.TokenID = tkImplementation then
      begin
        Flag := 1;
        // 用 Flag 来表示 interface 还是 implementation
      end;
      Lex.Next;
    end;
  finally
    Lex.Free;
  end;
end;

{ TCnWidePasToken }

procedure TCnWidePasToken.Clear;
begin
  FCppTokenKind := TCTokenKind(0);
  FCharIndex := 0;
  FAnsiIndex := 0;
  FEditCol := 0;
  FEditLine := 0;
  FItemIndex := 0;
  FItemLayer := 0;
  FLineNumber := 0;
  FMethodLayer := 0;
  FillChar(FToken[0], SizeOf(FToken), 0);
  FTokenID := TTokenKind(0);
  FTokenPos := 0;
  FIsMethodStart := False;
  FIsMethodClose := False;
  FIsBlockStart := False;
  FIsBlockClose := False;
end;

function TCnWidePasToken.GetToken: PWideChar;
begin
  Result := @FToken[0];
end;

{ TCnIfStatement }

procedure TCnIfStatement.AddBegin(ABegin: TCnWidePasToken);
begin
  if ABegin = nil then
    Exit;

  if HasElse then                         // 有 else 说明是 else 对应的 begin
    FElseBegin := ABegin
  else if FElseIfBeginList.Count > 0 then // 有 else if 说明是最后一个 else if 对应的 begin
    FElseIfBeginList[FElseIfBeginList.Count - 1] := ABegin
  else
    FIfBegin := ABegin;                   // 否则是 if 对应的 begin
end;

procedure TCnIfStatement.ChangeElseToElseIf(AIf: TCnWidePasToken);
begin
  if (FElseToken = nil) or (AIf = nil) then
    Exit;

  FElseList.Add(FElseToken);
  FIfList.Add(AIf);
  FElseIfBeginList.Add(nil);
  FElseIfEnded.Add(nil);
  FElseToken := nil;
end;

constructor TCnIfStatement.Create;
begin
  inherited;
  FLevel := -1;
  FElseList := TObjectList.Create(False);
  FIfList := TObjectList.Create(False);
  FElseIfBeginList := TObjectList.Create(False);
  FElseIfEnded := TList.Create;
end;

destructor TCnIfStatement.Destroy;
begin
  FElseIfEnded.Free;
  FElseIfBeginList.Free;
  FIfList.Free;
  FElseList.Free;
  inherited;
end;

procedure TCnIfStatement.EndElseBlock;
begin
  if FElseToken <> nil then
    FElseEnded := True;
end;

procedure TCnIfStatement.EndIfAll;
begin
  if FIfStart <> nil then
    FIfAllEnded := True;
end;

procedure TCnIfStatement.EndIfBlock;
begin
  if FIfStart <> nil then
    FIfEnded := True;
end;

procedure TCnIfStatement.EndLastElseIfBlock;
begin
  if ElseIfCount > 0 then
    FElseIfEnded[FElseIfEnded.Count - 1] := Pointer(Ord(True));
end;

function TCnIfStatement.GetElseIfCount: Integer;
begin
  Result := FElseList.Count;
end;

function TCnIfStatement.GetElseIfElse(Index: Integer): TCnWidePasToken;
begin
  Result := TCnWidePasToken(FElseList[Index]);
end;

function TCnIfStatement.GetElseIfIf(Index: Integer): TCnWidePasToken;
begin
  Result := TCnWidePasToken(FIfList[Index]);
end;

function TCnIfStatement.GetLastElseIfBegin: TCnWidePasToken;
begin
  Result := nil;
  if FElseIfBeginList.Count > 0 then
    Result := TCnWidePasToken(FElseIfBeginList[FElseIfBeginList.Count - 1]);
end;

function TCnIfStatement.GetLastElseIfElse: TCnWidePasToken;
begin
  Result := nil;
  if FElseList.Count > 0 then
    Result := TCnWidePasToken(FElseList[FElseList.Count - 1]);
end;

function TCnIfStatement.GetLastElseIfIf: TCnWidePasToken;
begin
  Result := nil;
  if FIfList.Count > 0 then
    Result := TCnWidePasToken(FIfList[FIfList.Count - 1]);
end;

function TCnIfStatement.HasElse: Boolean;
begin
  Result := FElseToken <> nil;
end;

procedure TCnIfStatement.SetElseBegin(const Value: TCnWidePasToken);
begin
  FElseBegin := Value;
end;

procedure TCnIfStatement.SetFIfBegin(const Value: TCnWidePasToken);
begin
  FIfBegin := Value;
end;

procedure TCnIfStatement.SetIfStart(const Value: TCnWidePasToken);
begin
  FIfStart := Value;
  if Value <> nil then
    FLevel := Value.ItemLayer
  else
    FLevel := -1;
end;

{ TCnProcObj }

function TCnProcObj.GetIsNested: Boolean;
begin
  Result := FNestCount > 0;
end;

function TCnProcObj.GetBeginMatched: Boolean;
begin
  Result := FBeginToken <> nil;
end;

function TCnProcObj.GetLayer: Integer;
begin
  if FBeginToken <> nil then
    Result := FBeginToken.ItemLayer
  else
    Result := -1;
end;

initialization
  TokenPool := TCnList.Create;

finalization
  ClearTokenPool;
  FreeAndNil(TokenPool);

end.
