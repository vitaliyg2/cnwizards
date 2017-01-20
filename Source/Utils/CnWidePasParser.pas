{******************************************************************************}
{                       CnPack For Delphi/C++Builder                           }
{                     �й����Լ��Ŀ���Դ�������������                         }
{                   (C)Copyright 2001-2017 CnPack ������                       }
{                   ------------------------------------                       }
{                                                                              }
{            ���������ǿ�Դ��������������������� CnPack �ķ���Э������        }
{        �ĺ����·�����һ����                                                }
{                                                                              }
{            ������һ��������Ŀ����ϣ�������ã���û���κε���������û��        }
{        �ʺ��ض�Ŀ�Ķ������ĵ���������ϸ���������� CnPack ����Э�顣        }
{                                                                              }
{            ��Ӧ���Ѿ��Ϳ�����һ���յ�һ�� CnPack ����Э��ĸ��������        }
{        ��û�У��ɷ������ǵ���վ��                                            }
{                                                                              }
{            ��վ��ַ��http://www.cnpack.org                                   }
{            �����ʼ���master@cnpack.org                                       }
{                                                                              }
{******************************************************************************}

unit CnWidePasParser;
{* |<PRE>
================================================================================
* ������ƣ�CnPack IDE ר�Ұ�
* ��Ԫ���ƣ�Pas Դ����������� Unicode �汾
* ��Ԫ���ߣ��ܾ��� zjy@cnpack.org
* ��    ע����д�� CnPasCodeParser��ȥ����һ���������ĺ���
* ����ƽ̨��Win7 + Delphi 2009
* ���ݲ��ԣ�
* �� �� �����õ�Ԫ�е��ַ��������ϱ��ػ�����ʽ
* ��Ԫ��ʶ��$Id: CnPasCodeParser.pas 1385 2013-12-31 15:39:02Z liuxiaoshanzhashu@gmail.com $
* �޸ļ�¼��2015.04.25 V1.1
*               ���� WideString ʵ��
*           2015.04.10
*               ������Ԫ
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
  {* ����һ Token �Ľṹ������Ϣ}
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
    {* �Ƿ��� C ��ʽ�Ľ�����Ĭ�ϲ���}
    property LineNumber: Integer read FLineNumber; // Start 0
    {* �����кţ����㿪ʼ���� ParseSource ������� }
    property CharIndex: Integer read FCharIndex;   // Start 0
    {* �ӱ��п�ʼ�����ַ�λ�ã����㿪ʼ���� ParseSource �ھ���չ�� Tab ������� }
    property AnsiIndex: Integer read FAnsiIndex;   // Start 0
    {* �ӱ��п�ʼ���� Ansi �ַ�λ�ã����㿪ʼ���������}

    property EditCol: Integer read FEditCol write FEditCol;
    {* �����У���һ��ʼ�������ת��������һ���Ӧ EditPos}
    property EditLine: Integer read FEditLine write FEditLine;
    {* �����У���һ��ʼ�������ת��������һ���Ӧ EditPos}
    property EditAnsiCol: Integer read FEditAnsiCol write FEditAnsiCol;
    {* ���� Ansi �У���һ��ʼ�������ת�����������ڻ��Ƶĳ���}

    property ItemIndex: Integer read FItemIndex;
    {* ������ Parser �е���� }
    property ItemLayer: Integer read FItemLayer;
    {* ���ڸ����Ĳ�Σ��������̡������Լ�����飬��ֱ���������Ƹ�����Σ������κο���ʱ������㣩Ϊ 0 }
    property MethodLayer: Integer read FMethodLayer;
    {* ���ں�����Ƕ�ײ�Σ������ĺ�����Ϊ 1�������������� }
    property Token: PWideChar read GetToken;
    {* �� Token ���ַ������� }
    property TokenID: TTokenKind read FTokenID;
    {* Token ���﷨���� }
    property CppTokenKind: TCTokenKind read FCppTokenKind;
    {* ��Ϊ C �� Token ʹ��ʱ�� CToken ����}
    property TokenPos: Integer read FTokenPos;
    {* Token �������ļ��е�����λ�� }
    property IsBlockStart: Boolean read FIsBlockStart;
    {* �Ƿ���һ���ƥ���������Ŀ�ʼ }
    property IsBlockClose: Boolean read FIsBlockClose;
    {* �Ƿ���һ���ƥ���������Ľ��� }
    property IsMethodStart: Boolean read FIsMethodStart;
    {* �Ƿ��Ǻ������̵Ŀ�ʼ������ function �� begin/asm ����� }
    property IsMethodClose: Boolean read FIsMethodClose;
    {* �Ƿ��Ǻ������̵Ľ�����ֻ���� end ���������˺� MethodStart �������� }
    property CompDirectivtType: TCnCompDirectiveType read FCompDirectiveType write FCompDirectiveType;
    {* ���������� Pascal ����ָ��ʱ�������������ϸ���ͣ��������������ⲿ�������}
    property Tag: Integer read FTag write FTag;
    {* Tag ��ǣ���������ⳡ��ʹ��}
  end;

//==============================================================================
// Pascal Unicode �ļ��ṹ����������
//==============================================================================

  { TCnPasStructureParser }

  TCnWidePasStructParser = class(TObject)
  {* ���� TCnPasWideLex �����﷨�����õ����� Token ��λ����Ϣ}
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
    {* ����ָ�����λ�����ڵ�������LineNumber 1 ��ʼ��WideCharIndex 0 ��ʼ�������� CharPos��
       ��Ҫ���� WideChar ƫ�ơ�D2005~2007 �£�CursorPos.Col �� ConverPos ��õ�����
       Utf8 �� CharPos ƫ�ƣ�2009 ������ ConverPos �õ����ҵ� Ansi ƫ�ƣ�������ֱ���á�
       ǰ����Ҫת�� WideChar ƫ�ƣ�����ֻ�ܰ� CursorPos.Col - 1 ���� Ansi �� CharIndex��
       ��ת�� WideChar ��ƫ��}
    procedure FindCurrentBlock(LineNumber, WideCharIndex: Integer);
    {* ����ָ�����λ�����ڵĿ飬LineNumber 1 ��ʼ��WideCharIndex 0 ��ʼ�������� CharPos��
       ��Ҫ���� WideChar ƫ�ơ�D2005~2007 �£�CursorPos.Col �� ConverPos ��õ�����
       Utf8 �� CharPos ƫ�ƣ�2009 ������ ConverPos �õ����ҵ� Ansi ƫ�ƣ�������ֱ���á�
       ǰ����Ҫת�� WideChar ƫ�ƣ�����ֻ�ܰ� CursorPos.Col - 1 ���� Ansi �� CharIndex��
       ��ת�� WideChar ��ƫ��}
    function IndexOfToken(Token: TCnWidePasToken): Integer;
    property Count: Integer read GetCount;
    property Tokens[Index: Integer]: TCnWidePasToken read GetToken;
    property MethodStartToken: TCnWidePasToken read FMethodStartToken;
    {* ��ǰ�����Ĺ��̻���}
    property MethodCloseToken: TCnWidePasToken read FMethodCloseToken;
    {* ��ǰ�����Ĺ��̻���}
    property ChildMethodStartToken: TCnWidePasToken read FChildMethodStartToken;
    {* ��ǰ���ڲ�Ĺ��̻�����������Ƕ�׹��̻�����������}
    property ChildMethodCloseToken: TCnWidePasToken read FChildMethodCloseToken;
    {* ��ǰ���ڲ�Ĺ��̻�����������Ƕ�׹��̻�����������}
    property BlockStartToken: TCnWidePasToken read FBlockStartToken;
    {* ��ǰ������}
    property BlockCloseToken: TCnWidePasToken read FBlockCloseToken;
    {* ��ǰ������}
    property InnerBlockStartToken: TCnWidePasToken read FInnerBlockStartToken;
    {* ��ǰ���ڲ��}
    property InnerBlockCloseToken: TCnWidePasToken read FInnerBlockCloseToken;
    {* ��ǰ���ڲ��}
    property CurrentMethod: CnWideString read FCurrentMethod;
    {* ��ǰ�����Ĺ��̻�����}
    property CurrentChildMethod: CnWideString read FCurrentChildMethod;
    {* ��ǰ���ڲ�Ĺ��̻�������������Ƕ�׹��̻�����������}
    property Source: CnWideString read FSource;
    property KeyOnly: Boolean read FKeyOnly;
    {* �Ƿ�ֻ������ؼ���}

    {* �Ƿ��Ű洦�� Tab ���Ŀ�ȣ��粻������ Tab ��������Ϊ 1 ����}
    property TabWidth: Integer read FTabWidth write FTabWidth;
    {* Tab ���Ŀ��}
  end;

procedure ParseUnitUsesW(const Source: CnWideString; UsesList: TStrings;
  SupportUnicodeIdent: Boolean = False);
{* ����Դ���������õĵ�Ԫ}

implementation

type
  TCnProcObj = class
  {* ����һ�������� procedure/function ���壬������������}
  private
    FToken: TCnWidePasToken;
    FBeginToken: TCnWidePasToken;
    FNestCount: Integer;
    function GetIsNested: Boolean;
    function GetBeginMatched: Boolean;
    function GetLayer: Integer;
  public
    property Token: TCnWidePasToken read FToken write FToken;
    {* procedure/function ���ڵ� Token}
    property Layer: Integer read GetLayer;
    {* procedure/function ���ڵ� Token �Ĳ����}
    property BeginMatched: Boolean read GetBeginMatched;
    {* �� procedure/function �Ƿ������ҵ���ʵ����� begin}
    property BeginToken: TCnWidePasToken read FBeginToken write FBeginToken;
    {* �� procedure/function ʵ����� begin}
    property IsNested: Boolean read GetIsNested;
    {* �� procedure/function �Ƿ��Ǳ�Ƕ�׶���ģ�Ҳ���Ƿ�����һ��
       procedure/function ���������֣�ʵ���� begin ֮ǰ}
    property NestCount: Integer read FNestCount write FNestCount;
    {* �� procedure/function ��Ƕ�׶��������Ҳ�������һ����Ƕ�� procedure/function �Ĳ����}
  end;

  TCnIfStatement = class
  {* ����һ�������� If ��䣬���ܴ���� else if �Լ�һ���� 0 �� else�������ڻ������� begin end}
  private
    FLevel: Integer;
    FIfStart: TCnWidePasToken;     // �洢�� if ����
    FIfBegin: TCnWidePasToken;     // �洢 if ��Ӧ��ͬ�� begin
    FIfEnded: Boolean;             // �� if �����Ƿ�������������� if ��䣩
    FElseToken: TCnWidePasToken;   // �洢 else ����
    FElseBegin: TCnWidePasToken;   // �洢 else ��Ӧ��ͬ�� begin
    FElseEnded: Boolean;           // �� else ���Ƿ����
    FElseList: TObjectList;        // �洢��� else if �е� else ����
    FIfList: TObjectList;          // �洢��� else if �е� if ����
    FElseIfBeginList: TObjectList; // �洢��� else if �Ķ�Ӧ begin������Ϊ��
    FElseIfEnded: TList;           // �洢��� else if �Ƿ�����ı�ǣ�1 �� 0
    FIfAllEnded: Boolean;          // ���� if �Ƿ����
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
    {* �� if ���Ƿ��е����� else}

    procedure ChangeElseToElseIf(AIf: TCnWidePasToken);
    {* �����һ�� else ��Ϊһ�� else if������ else ����ܵ� if ʱ}
    procedure AddBegin(ABegin: TCnWidePasToken);
    {* ����жϺ󣬽� begin ����� If������ʵ������� else if �»� if ͷ��}

    // ��������������ǰ�ӿ�������ǣ�
    // 1. ���ӿ��н��ӵ� begin�����ж�Ӧ��ε� end������
    // 2. ���ӿ��޽��ӵ� begin����ͬ��εķֺţ�����жϲ��ף����õ�ǰ���ǰ���жϹ��򣩣���
    // 3. ���ӿ��޽��ӵ� begin��������һ��ε� end��ǰ���޷ֺţ����� if then begin if then Close end; �е� Close ���
    procedure EndLastElseIfBlock;
    {* �����һ�� else if ���������Դ�� end ��ֺ�}
    procedure EndElseBlock;
    {* �� else ���������Դ�� end ��ֺ�}
    procedure EndIfBlock;
    {* �� if ��������������� if ��䣩����Դ�� end ��ֺ�}
    procedure EndIfAll;
    {* ������ if ����������Դ�� end ��ֺ�}

    property Level: Integer read FLevel write FLevel;
    {* if ���Ĳ�Σ���Ҫ�� if �Ĳ��}
    property IfStart: TCnWidePasToken read FIfStart write SetIfStart;
    {* ��ȡ if ��ʼ Token �Լ���һ�� Token ��Ϊ if ��ʼ Token}
    property IfBegin: TCnWidePasToken read FIfBegin write SetFIfBegin;
    {* ��ȡ if �����Ӧ�� begin �� Token �Լ���һ�� begin ��Ϊ if ��Ӧ�� begin}
    property ElseToken: TCnWidePasToken read FElseToken write FElseToken;
    {* ��ȡ if ��� else �� Token �Լ���һ�� Token ��Ϊ if ��� else �� Token}
    property ElseBegin: TCnWidePasToken read FElseBegin write SetElseBegin;
    {* ��ȡ if ��� else ����Ӧ�� begin �Լ���һ�� Token ��Ϊ�� else ��Ӧ�� begin �� Token}
    property ElseIfCount: Integer read GetElseIfCount;
    {* ���ظ� if ��� else if ����}
    property ElseIfElse[Index: Integer]: TCnWidePasToken read GetElseIfElse;
    {* ���ظ� if ��� else if �� else �� Token�������� 0 �� ElseIfCount - 1}
    property ElseIfIf[Index: Integer]: TCnWidePasToken read GetElseIfIf;
    {* ���ظ� if ��� else if ��  �� Token�������� 0 �� ElseIfCount - 1}
    property LastElseIfElse: TCnWidePasToken read GetLastElseIfElse;
    {* ���ظ� if ������һ�� else if �� else}
    property LastElseIfIf: TCnWidePasToken read GetLastElseIfIf;
    {* ���ظ� if ������һ�� else if �� if}
    property LastElseIfBegin: TCnWidePasToken read GetLastElseIfBegin;
    {* ���ظ� if ������һ�� else if �� begin������еĻ�}
    property IfAllEnded: Boolean read FIfAllEnded;
    {* ���ظ� if ����Ƿ�ȫ�����������жϲ��Ӷ�ջ�е���}
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

// �óط�ʽ������ PasTokens ���������
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

// NextNoJunk����ֻ����ע�ͣ���û��������ָ���������Ӵ˺����ɹ�����ָ��
procedure LexNextNoJunkWithoutCompDirect(Lex: TCnPasWideLex);
begin
  repeat
    Lex.Next;
  until not (Lex.TokenID in [tkSlashesComment, tkAnsiComment, tkBorComment, tkCRLF,
    tkCRLFCo, tkSpace, tkCompDirect]);
end;

//==============================================================================
// �ṹ����������
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

    Token.FLineNumber := Lex.LineNumber - 1;              // 1 ��ʼ��� 0 ��ʼ
    CalcCharIndexes(Token.FCharIndex, Token.FAnsiIndex);
    // ��ֱ��ʹ�� Column ֱ���к����ԣ����Ǿ��� Tab չ������Ҳ������ 1 ��ʼ��� 0 ��ʼ

    Token.FTokenID := Lex.TokenID;
    Token.FItemIndex := FList.Count;
    if CurrBlock <> nil then
      Token.FItemLayer := CurrBlock.FItemLayer;

    // CurrBlock �� ItemLayer ������ MethodLayer�������û�� CurrBlock��
    // �͵ÿ����� CurrMethod �� MethodLayer ����ʼ�� Token �� ItemLayer��
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
    FProcStack.Clear;  // �洢 procedure/function ʵ�ֵĹؼ����Լ���Ƕ�ײ��
    FIfStack.Clear;    // �洢 if ��Ƕ����Ϣ

    Lex := TCnPasWideLex.Create(FSupportUnicodeIdent);
    Lex.Origin := PWideChar(ASource);

    DeclareWithEndLevel := 0; // Ƕ�׵���Ҫend�Ķ������
    Token := nil;
    CurrMethod := nil;        // ��ǰ Token ���ڵķ������������������� procedure/function
    CurrBlock := nil;         // ��ǰ Token ���ڵĿ顣
    CurrMidBlock := nil;
    IsImpl := AIsDpr;
    IsHelper := False;
    IsRecordHelper := False;
    ExpectElse := False;

    while Lex.TokenID <> tkNull do
    begin
      // ������һ�ֵĽ��������ж��Ƿ��ܽ������� if ���
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
              // ������ procedure/function ���Ͷ��壬ǰ���� = ��
              // Ҳ������ procedure/function ����������ǰ���� : ��
              // Ҳ��������������������ǰ���� to
              // ��һ��Ҫ������������ʵ�֣�ǰ���� := ��ֵ�� ( , �������������ܲ���ȫ
              if IsImpl and ((not (Lex.TokenID in [tkProcedure, tkFunction]))
                or (not (PrevTokenID in [tkEqual, tkColon, tkTo{, tkAssign, tkRoundOpen, tkComma}])))
                and (DeclareWithEndLevel <= 0) then
              begin
                // DeclareWithEndLevel <= 0 ��ʾֻ���� class/record ����������ڲ�����
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

                // ���� procedure/function ʵ��ʱ�������ջ����¼���Σ����� Layer �ɼ�¼��
                if FProcStack.IsEmpty then
                  PrevProcObj := nil
                else
                  PrevProcObj := TCnProcObj(FProcStack.Peek);

                AProcObj := TCnProcObj.Create;
                AProcObj.Token := Token;
                FProcStack.Push(AProcObj);

                // �����ǰ procedure ������� procedure �� begin ��������������������Ƕ����
                // �������û�� procedure���������Ƕ�ף�Ĭ���� 0
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
              // ���������ᵼ�� CurrBlock �� CurrMethod �������������ϵ��ȷ����
              // ����� CurrBlock ���ڣ���Ҫȷ����Զ�� CurrMethod����� begin ���� MethodStart��
              if (CurrMethod <> nil) and ((CurrBlock = nil) or
                (CurrBlock.ItemIndex < CurrMethod.ItemIndex)) then
                Token.FIsMethodStart := True;

              // ���ҵ� CurrBlock �� CurrMethod �������ܸ��� CurrBlock ��һ
              // ����Ҫ��������� Method ����һ
              if (CurrBlock <> nil) and ((CurrMethod = nil) or (CurrMethod.ItemIndex < CurrBlock.ItemIndex)) then
                Token.FItemLayer := CurrBlock.FItemLayer + 1
              else if CurrMethod <> nil then // �� Block �� Block �� Method �⣬�������������Ƚ�һ��
                Token.FItemLayer := CurrMethod.FItemLayer + 1
              else // ���������Ƿ��ں���������������
                Token.FItemLayer := 0;

              FBlockStack.Push(CurrBlock);
              CurrBlock := Token; // begin/asm �ȿ����� CurrBlock��Ҳ������ CurrMethod �Ķ�Ӧ begin/asm

              // ���� begin/asm �� procedure/function ͬ��ʱ�Ľ���
              if FProcStack.Count > 0 then
              begin
                AProcObj := TCnProcObj(FProcStack.Peek);
                if not AProcObj.BeginMatched then
                begin
                  // ��ǰ Proc ��Ƕ�׺���ʱ��begin Ҫ�� procedure/function ��ֱ��Ƕ�ײ���
                  if AProcObj.IsNested then
                    Inc(Token.FItemLayer, AProcObj.NestCount);

                  // ��¼���׵� begin/asm ������
                  AProcObj.BeginToken := Token;
                end;
              end;

              // �ж� begin �Ƿ�����֮ǰ�� if �� else if
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
                // ���� record helper for �����Σ�����implementation������end�ᱻ
                // record�ڲ���function/procedure���ɵ������޽��������
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

              // ������ of object ��������������ǰ���� @@ �͵�label������
              // ������ IsRecord ������Ϊ Lex.RunPos �ָ���TokenID ���ܻ��
              if ((Lex.TokenID <> tkObject) or (PrevTokenID <> tkOf))
                and not (PrevTokenID in [tkAt, tkDoubleAddressOp])
                and not IsForFunc        // ������ TParalle.For �Լ� .&For ���ֺ���
                and not ((Lex.TokenID = tkFor) and (IsHelper or IsRecordHelper)) then
                // ������ helper �е� for
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
                  // ������¼ record����Ϊ record �����ں������ begin end ֮���� end
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

              // ���� if �� else if ������
              if Lex.TokenID = tkIf then
              begin
                IsElseIf := False;
                if PrevTokenID = tkElse then
                begin
                  // �� else if���ҵ������ AIfObj���� else �ĳ� else if
                  if not FIfStack.IsEmpty then
                  begin
                    AIfObj := TCnIfStatement(FIfStack.Peek);
                    // ��� if ������ if �����ͬ������Ԥ�������� case else if then end �����
                    if AIfObj.Level = Token.ItemLayer then
                    begin
                      AIfObj.ChangeElseToElseIf(Token);
                      IsElseIf := True;
                    end;
                  end;
                end;

                if not IsElseIf then // �ǵ����� if����¼ if ��������ʼλ�ò������ջ
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

              // ������ classdef ���� class helper for TObject ������
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
                if Lex.TokenID = tkSemiColon then // �Ǹ� class; ����Ҫ end;
                  IsClassOpen := False
                else if IsHelper or IsSealed or IsAbstract then
                  LexNextNoJunkWithoutCompDirect(Lex);

                if Lex.TokenID = tkRoundOpen then // �����ţ����ǲ���();
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

              if IsClassOpen then // �к������ݣ���Ҫһ�� end
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
                // �ֲ���������Ҫ end ����β
                // IsInDeclareWithEnd := True;
                Inc(DeclareWithEndLevel);
              end
              else // Ӳ�޲������ unit �� interface �Լ� class procedure �ȱ�����
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
              // �ж� else �����ڽϽ��� if �黹�ǽ����� case �ȿ��Ǹ����⡣
              // ���� else ʱ if then ���Ѿ�������CurrBlock������� if�����Եö�����һ�� CurrIfStart
              CurrIfStart := nil;
              if not FIfStack.IsEmpty then
              begin
                AIfObj := TCnIfStatement(FIfStack.Peek);
                if AIfObj.IfStart <> nil then
                  CurrIfStart := AIfObj.IfStart;
              end;

              // else ǰ����Բ��Ƿֺţ������ж� PrevToken �Ƿ�ֺ�
              if (CurrBlock = nil) or (PrevTokenID in [tkAt, tkDoubleAddressOp]) then
                DiscardToken
              else if (CurrBlock.TokenID = tkTry) and (CurrMidBlock <> nil) and
                (CurrMidBlock.TokenID = tkExcept) and
                ((CurrIfStart = nil) or (CurrIfStart.ItemIndex <= CurrBlock.ItemIndex)) then
                Token.FItemLayer := CurrBlock.FItemLayer    // try except else end ������� if �������һ���
              else if (CurrBlock.TokenID = tkCase) and
                ((CurrIfStart = nil) or (CurrIfStart.ItemIndex <= CurrBlock.ItemIndex))then
                Token.FItemLayer := CurrBlock.FItemLayer    // case of �е� else ������� if �������һ���
              else if not FIfStack.IsEmpty then // ������������ԣ��� else Ӧ�����ڵ�ǰ if ��
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
                  // ���ⲿ�ֹؼ����������������Σ���ֻ��һ��С patch������������
                  Token.FItemLayer := CurrBlock.FItemLayer;
                  Token.FIsBlockClose := True;
                  if (CurrBlock.TokenID = tkTry) and (CurrMidBlock <> nil) then
                  begin
                    if FMidBlockStack.Count > 0 then
                      CurrMidBlock := TCnWidePasToken(FMidBlockStack.Pop)
                    else
                      CurrMidBlock := nil;
                  end;

                  // End �ȿ��Խ��� Block Ҳ���Խ��� procedure��û�б�Ȼ���Ⱥ�˳��Ҫ���ĸ���
                  // ���ң����� CurrBlock �� CurrMethod �� begin/asm���� End Ҫͬʱ������
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
                    // �ж� CurrBlock �ǲ��� CurrMethod ��Ӧ�� begin�������ܽ���
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

                  if CanEndBlock or (Lex.TokenID <> tkEnd) then // ����ֱ�ӽ��� CurrBlock��End Ҫ������Ҳ�� CurrBlock
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

                  if CanEndMethod and (Lex.TokenID = tkEnd) then  // �� End ��Ҫ�������� CurrMethod
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
              else // Ӳ�޲������ unit �� End Ҳ����
                DiscardToken(Token.TokenID = tkEnd);

              if (DeclareWithEndLevel > 0) and (Lex.TokenID = tkEnd) then // �����˾ֲ�����
                Dec(DeclareWithEndLevel);

              if Lex.TokenID = tkEnd then
              begin
                // ��� end �� procedure/function ����Ԫ��ͬ��
                if FProcStack.Count > 0 then
                begin
                  AProcObj := TCnProcObj(FProcStack.Peek);
                  if AProcObj.BeginMatched and (AProcObj.Layer = Token.ItemLayer) then
                    FProcStack.Pop.Free;
                end;

                // ���� if ��Ӧ��ϵ�� begin end �Ĺ�ϵ
                if not FIfStack.IsEmpty then
                begin
                  AIfObj := TCnIfStatement(FIfStack.Peek);
                  if (AIfObj.LastElseIfBegin <> nil) and
                    (AIfObj.LastElseIfBegin.ItemLayer = Token.ItemLayer) then
                  begin
                    // �� end ������� if �������һ�� else if ��� begin ��ԣ���ʾ�� else if �����
                    AIfObj.EndLastElseIfBlock;
                    ExpectElse := True;
                    // ��һ��������� else�������� if ����
                  end
                  else if (AIfObj.ElseBegin <> nil) and (AIfObj.ElseBegin.ItemLayer = Token.ItemLayer) then
                  begin
                    // �� end ������� if ���еĶ��� else �е� begin ��ԣ���ʾ�� else �������ͬʱ���� if ������
                    AIfObj.EndElseBlock;
                    AIfObj.EndIfAll;
                  end
                  else if (AIfObj.IfBegin <> nil) and (AIfObj.IfBegin.ItemLayer = Token.ItemLayer) then
                  begin
                    // �� end ������� if ���е� begin ��ԣ���ʾ�� if ��������������� if ��䣩
                    AIfObj.EndIfBlock;
                    ExpectElse := True;
                    // ��һ��������� else�������� if ����
                  end
                  else if (AIfObj.LastElseIfBegin = nil) and (AIfObj.LastElseIfIf <> nil) and
                    (AIfObj.LastElseIfIf.ItemLayer > Token.ItemLayer) then
                  begin
                    // �� end ����������� if �������һ���� begin �� else if ��end֮ǰ�����޷ֺţ���ͬʱ�������� if
                    AIfObj.EndLastElseIfBlock;
                    AIfObj.EndIfAll;
                  end
                  else if (AIfObj.ElseBegin = nil) and (AIfObj.ElseToken <> nil) and
                    (AIfObj.ElseToken.ItemLayer > Token.ItemLayer) then
                  begin
                    // �� end ����������� if ������ begin �� else ��end֮ǰ�����޷ֺţ���ͬʱ�������� if
                    AIfObj.EndElseBlock;
                    AIfObj.EndIfAll;
                  end
                  else if (AIfObj.IfBegin = nil) and (AIfObj.IfStart.ItemLayer > Token.ItemLayer) then
                  begin
                    // �� end ����������� if ������ begin �� if ��end֮ǰ�����޷ֺţ���ͬʱ�������� if
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
          // �����ֺţ������������˭��ע�ⲻ���� Token����Ϊû��ԷֺŴ��� Token
          // �ֺŵ� ItemLayer Ŀǰû�п���ֵ����˲������� ItemLayer �� if �� Level �Ƚϡ�
          // FList.Count Ϊ�ֺż���� ItemIndex
          // ���һ����� CurrBlock ���ڣ���û�к��� if �� else �� else �� begin��˵���ֺŽ��� else ͬ��
          // ���������� CurrBlock ���ڣ���û�к������һ�� else if �� if������ begin��˵���ֺŽ������һ�� else if ͬ��
          // ���������� CurrBlock ���ڣ���û�к��� if���� if û begin��˵���ֺŽ��� if ͬ��
          if CurrBlock <> nil then
          begin
            if AIfObj.HasElse and (AIfObj.ElseBegin = nil) and
              (CurrBlock.ItemIndex <= AIfObj.ElseToken.ItemIndex) then  // �ֺŽ������� begin �� else
            begin
              AIfObj.EndElseBlock;
              AIfObj.EndIfAll;
            end
            else if (AIfObj.ElseIfCount > 0) and (AIfObj.LastElseIfBegin = nil)
              and (AIfObj.LastElseIfIf <> nil) and
              (CurrBlock.ItemIndex <= AIfObj.LastElseIfIf.ItemIndex) then
            begin
              AIfObj.EndLastElseIfBlock;       // �ֺŽ������� begin �����һ�� else if
              AIfObj.EndIfAll;
            end
            else if (AIfObj.IfBegin = nil) and
              (CurrBlock.ItemIndex <= AIfObj.IfStart.ItemIndex) then  // �ֺŽ������� begin �� if ����
            begin
              AIfObj.EndIfBlock;
              AIfObj.EndIfAll;
            end;

            // �ֺŽ��������� if ��䣬���ԴӶ�ջ�е�����
            if AIfObj.IfAllEnded then
              FIfStack.Pop.Free;
          end;
        end;

        if (CurrMethod <> nil) and // forward, external ��ʵ�ֲ��֣�ǰ������Ƿֺ�
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

        // ��Ҫʱ����ͨ��ʶ���ӣ�& ��ı�ʶ��Ҳ��
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
          // ���� procedure �����Ӧ�� begin �������� MethodStart�������Ҫ��������
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
          // �ڿ�Ƕ�������������̵ĵ�������ʱ������������
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
        if Token.MethodLayer = 1 then // ����������� Layer Ϊ 1 �ģ���Ȼ�������
        begin
          FMethodCloseToken := Token;
          Exit;
        end
        else if (NestedProcs = 0) and (FChildMethodCloseToken = nil) then
          FChildMethodCloseToken := Token;
          // �����ͬ��εģ����� ChildMethodClose
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
    // �˺����� _ForwardFindDeclarePos �� _BackwardFindDeclarePos �����
    if (FInnerBlockStartToken <> nil) and (FInnerBlockCloseToken <> nil) then
    begin
      // ���һ�����˳�
      if FInnerBlockStartToken.ItemLayer = FInnerBlockCloseToken.ItemLayer then
        Exit;
      // ���·��ٽ��� Block ���ܲ�β�һ������Ҫ�Ҹ�һ����εģ��������Ϊ׼

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
    // ǰ�ߴ� 0 ��ʼ�����ߴ� 1 ��ʼ�������Ҫ�� 1
    if (Tokens[CurrIndex].LineNumber > LineNumber - 1) then
      Break;

    // ���ݲ�ͬ����ʼ Token���ж�����Ҳ������ͬ
    if Tokens[CurrIndex].LineNumber = LineNumber - 1 then
    begin
      if (Tokens[CurrIndex].TokenID in [tkBegin, tkAsm, tkTry, tkRepeat, tkIf,
        tkFor, tkWith, tkOn, tkWhile, tkCase, tkRecord, tkObject, tkClass,
        tkInterface, tkDispInterface]) and
        (Tokens[CurrIndex].CharIndex > WideCharIndex ) then // ��ʼ�������ж�
        Break
      else if (Tokens[CurrIndex].TokenID in [tkEnd, tkUntil, tkThen, tkDo]) and
        (Tokens[CurrIndex].CharIndex + Length(Tokens[CurrIndex].Token) > WideCharIndex ) then
        Break;  //�����������ж�
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
      // ��ǰ�ҵȺ���ǰ�ı�ʶ��
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

// ����Դ���������õĵ�Ԫ
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
        // �� Flag ����ʾ interface ���� implementation
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

  if HasElse then                         // �� else ˵���� else ��Ӧ�� begin
    FElseBegin := ABegin
  else if FElseIfBeginList.Count > 0 then // �� else if ˵�������һ�� else if ��Ӧ�� begin
    FElseIfBeginList[FElseIfBeginList.Count - 1] := ABegin
  else
    FIfBegin := ABegin;                   // ������ if ��Ӧ�� begin
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
