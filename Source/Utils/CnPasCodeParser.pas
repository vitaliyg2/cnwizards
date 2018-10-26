{******************************************************************************}
{                       CnPack For Delphi/C++Builder                           }
{                     �й����Լ��Ŀ���Դ�������������                         }
{                   (C)Copyright 2001-2018 CnPack ������                       }
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

unit CnPasCodeParser;
{* |<PRE>
================================================================================
* ������ƣ�CnPack IDE ר�Ұ�
* ��Ԫ���ƣ�Pas Դ���������
* ��Ԫ���ߣ��ܾ��� zjy@cnpack.org
* ��    ע��
* ����ƽ̨��PWin2000Pro + Delphi 5.01
* ���ݲ��ԣ�
* �� �� �����õ�Ԫ�е��ַ��������ϱ��ػ�����ʽ
* ��Ԫ��ʶ��$Id: CnPasCodeParser.pas 1385 2013-12-31 15:39:02Z liuxiaoshanzhashu@gmail.com $
* �޸ļ�¼��2012.02.07
*               UTF8��λ��ת��ȥ�����������⣬�ָ�֮
*           2011.11.29
*               XE/XE2 ��λ�ý�������UTF8��λ��ת��
*           2011.11.03
*               �Ż��Դ�������õ�Ԫ����֧��
*           2011.05.29
*               ����BDS�¶Ժ���UTF8δ��������½������������
*           2004.11.07
*               ������Ԫ
================================================================================
|</PRE>}

interface

{$I CnWizards.inc}

uses
  Windows, SysUtils, Classes, mPasLex, mwBCBTokenList,
  Contnrs, CnCommon, CnFastList, CnContainers;

const
  CN_TOKEN_MAX_SIZE = 63;

type
  TCnCompDirectiveType = (ctNone, ctIf, ctIfDef, ctIfNDef, ctElse, ctEndIf, ctIfEnd);

  TCnUseToken = class(TObject)
  private
    FIsImpl: Boolean;
    FTokenPos: Integer;
    FToken: string;
    FTokenID: TTokenKind;
  public
    property Token: string read FToken write FToken;
    property IsImpl: Boolean read FIsImpl write FIsImpl;
    property TokenPos: Integer read FTokenPos write FTokenPos;
    property TokenID: TTokenKind read FTokenID write FTokenID;
  end;

  TCnPasToken = class(TPersistent)
  {* ����һ Token �Ľṹ������Ϣ}
  private
    FTag: Integer;
    FBracketLayer: Integer;
  protected
    FCppTokenKind: TCTokenKind;
    FCompDirectiveType: TCnCompDirectiveType;
    FCharIndex: Integer;
    FEditCol: Integer;
    FEditLine: Integer;
    FItemIndex: Integer;
    FItemLayer: Integer;
    FLineNumber: Integer;
    FMethodLayer: Integer;
    FToken: string;
    FTokenID: TTokenKind;
    FTokenPos: Integer;
    FIsMethodStart: Boolean;
    FIsMethodClose: Boolean;
    FMethodStartAfterParentBegin: Boolean;
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
    {* �ӱ��п�ʼ�����ַ�λ�ã����㿪ʼ���� ParseSource ������� }

    property EditCol: Integer read FEditCol write FEditCol;
    {* �����У���һ��ʼ�������ת��������һ���Ӧ EditPos }
    property EditLine: Integer read FEditLine write FEditLine;
    {* �����У���һ��ʼ�������ת��������һ���Ӧ EditPos }

    property ItemIndex: Integer read FItemIndex;
    {* ������ Parser �е���� }
    property ItemLayer: Integer read FItemLayer;
    {* ���ڸ����Ĳ�Σ��������̡������Լ�����飬��ֱ���������Ƹ�����Σ������κο���ʱ������㣩Ϊ 0 }
    property MethodLayer: Integer read FMethodLayer;
    {* ���ں����Ĳ�Σ������ĺ�����Ϊ 1���������������������κκ�����ʱ������㣩Ϊ 0 }
    property BracketLayer: Integer read FBracketLayer;
    {* ���ڵ�Բ���ŵĲ�Σ�������Ϊ 0��Բ���ű���Ӧ�����һ�㣨��δʵ�֣�}
    property Token: string read FToken;
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
    {* �Ƿ��Ǻ������̵Ŀ�ʼ������ function/procedure �� begin/asm ����� }
    property IsMethodClose: Boolean read FIsMethodClose;
    {* �Ƿ��Ǻ������̵Ľ�����ֻ���� end ���������˺� MethodStart �������� }
    property MethodStartAfterParentBegin: Boolean read FMethodStartAfterParentBegin;
    {* �� IsMethodStart �� True ���� function/procedure �� begin/asm ʱ��
       �Ƿ�λ����һ�� function/procedure �� begin ���ʵ�ֲ��֡�
       ����һ�㣬������һ��� begin ֮ǰʱΪ False����ʾ�Ƕ��壬
       ��������䲿���е��������������Դ�����Ϊ True ���Դ���������������}
    property CompDirectivtType: TCnCompDirectiveType read FCompDirectiveType write FCompDirectiveType;
    {* ���������� Pascal ����ָ��ʱ�������������ϸ���ͣ��������������ⲿ�������}
    property Tag: Integer read FTag write FTag;
    {* Tag ��ǣ���������ⳡ��ʹ��}
  end;

//==============================================================================
// Pascal �ļ��ṹ����������
//==============================================================================

  { TCnPasStructureParser }

  TCnPasStructureParser = class(TObject)
  {* ���� Lex �����﷨�����õ����� Token ��λ����Ϣ}
  private
    FSupportUnicodeIdent: Boolean;
    FBlockCloseToken: TCnPasToken;
    FBlockStartToken: TCnPasToken;
    FChildMethodCloseToken: TCnPasToken;
    FChildMethodStartToken: TCnPasToken;
    FCurrentChildMethod: String;
    FCurrentMethod: String;
    FKeyOnly: Boolean;
    FList: TCnList;
    FMethodCloseToken: TCnPasToken;
    FMethodStartToken: TCnPasToken;
    FSource: AnsiString;
    FInnerBlockCloseToken: TCnPasToken;
    FInnerBlockStartToken: TCnPasToken;
    FUseTabKey: Boolean;
    FTabWidth: Integer;
    FMethodStack: TCnObjectStack;
    FBlockStack: TCnObjectStack;
    FMidBlockStack: TCnObjectStack;
    FProcStack: TCnObjectStack;
    FIfStack: TCnObjectStack;
    function GetCount: Integer;
    function GetToken(Index: Integer): TCnPasToken; {$IFDEF SUPPORT_INLINE} inline; {$ENDIF}
  public
    constructor Create(SupportUnicodeIdent: Boolean = False);
    destructor Destroy; override;
    procedure Clear;
    procedure ParseSource(ASource: PAnsiChar; AIsDpr, AKeyOnly: Boolean);
    function FindCurrentDeclaration(LineNumber, CharIndex: Integer): String;
    {* ����ָ�����λ�����ڵ�������LineNumber 1 ��ʼ��CharIndex 0 ��ʼ�������� CharPos
       Ҫ���� Ansi ��ƫ������D567 �¿����� ConvertPos �õ��� CharPos ����}
    procedure FindCurrentBlock(LineNumber, CharIndex: Integer);
    {* ���ݵ�ǰ���λ�ò��ҵ�ǰ���뵱ǰǶ��/��㺯���ȡ�
       LineNumber 1 ��ʼ��CharIndex 0 ��ʼ�������� CharPos
       Ҫ���� Ansi ��ƫ������D567 �¿����� ConvertPos �õ��� CharPos ����}
    function IndexOfToken(Token: TCnPasToken): Integer;
    property Count: Integer read GetCount;
    property Tokens[Index: Integer]: TCnPasToken read GetToken;
    property MethodStartToken: TCnPasToken read FMethodStartToken;
    {* ��ǰ�����Ĺ��̻���}
    property MethodCloseToken: TCnPasToken read FMethodCloseToken;
    {* ��ǰ�����Ĺ��̻���}
    property ChildMethodStartToken: TCnPasToken read FChildMethodStartToken;
    {* ��ǰ���ڲ�Ĺ��̻�����������Ƕ�׹��̻�����������}
    property ChildMethodCloseToken: TCnPasToken read FChildMethodCloseToken;
    {* ��ǰ���ڲ�Ĺ��̻�����������Ƕ�׹��̻�����������}
    property BlockStartToken: TCnPasToken read FBlockStartToken;
    {* ��ǰ������}
    property BlockCloseToken: TCnPasToken read FBlockCloseToken;
    {* ��ǰ������}
    property InnerBlockStartToken: TCnPasToken read FInnerBlockStartToken;
    {* ��ǰ���ڲ��}
    property InnerBlockCloseToken: TCnPasToken read FInnerBlockCloseToken;
    {* ��ǰ���ڲ��}
    property CurrentMethod: String read FCurrentMethod;
    {* ��ǰ�����Ĺ��̻�����}
    property CurrentChildMethod: String read FCurrentChildMethod;
    {* ��ǰ���ڲ�Ĺ��̻�������������Ƕ�׹��̻�����������}
    property Source: AnsiString read FSource;
    property KeyOnly: Boolean read FKeyOnly;
    {* �Ƿ�ֻ������ؼ���}

    property UseTabKey: Boolean read FUseTabKey write FUseTabKey;
    {* �Ƿ��Ű洦�� Tab ���Ŀ�ȣ��粻������ Tab ��������Ϊ 1 ����
      ע�ⲻ�ܰ� IDE �༭��������� "Use Tab Character" ��ֵ��ֵ������
      IDE ����ֻ���ƴ������Ƿ��ڰ� Tab ʱ���� Tab �ַ������ÿո�ȫ��}
    property TabWidth: Integer read FTabWidth write FTabWidth;
    {* Tab ���Ŀ��}
  end;

//==============================================================================
// Դ��λ����Ϣ����
//==============================================================================

  // Դ������������
  TCodeAreaKind = (
    akUnknown,         // δ֪��Ч��
    akHead,            // ��Ԫ����֮ǰ
    akUnit,            // ��Ԫ������
    akProgram,         // ������������
    akInterface,       // interface ��
    akIntfUses,        // interface �� uses ��
    akImplementation,  // implementation ��
    akImplUses,        // implementation �� uses ��
    akInitialization,  // initialization ��
    akFinalization,    // finalization ��
    akEnd);            // end. ֮�������

  TCodeAreaKinds = set of TCodeAreaKind;

  // Դ����λ�����ͣ�ͬʱ֧�� Pascal �� C/C++
  TCodePosKind = (
    pkUnknown,         // δ֪��Ч����Pascal �� C/C++ ����Ч
    pkFlat,            // ��Ԫ�հ���
    pkComment,         // ע�Ϳ��ڲ���Pascal �� C/C++ ����Ч
    pkIntfUses,        // Pascal interface �� uses �ڲ�
    pkImplUses,        // Pascal implementation �� uses �ڲ�
    pkClass,           // Pascal class �����ڲ�
    pkInterface,       // Pascal interface �����ڲ�
    pkType,            // Pascal type ������
    pkConst,           // Pascal const ������
    pkResourceString,  // Pascal resourcestring ������
    pkVar,             // Pascal var ������
    pkCompDirect,      // ����ָ���ڲ�{$...}��C/C++ ����ָ #include ���ڲ�
    pkString,          // �ַ����ڲ���Pascal �� C/C++ ����Ч
    pkField,           // ��ʶ��. ��������ڲ������ԡ��������¼�����¼��ȣ�Pascal �� C/C++ ����Ч
    pkProcedure,       // �����ڲ�
    pkFunction,        // �����ڲ�
    pkConstructor,     // �������ڲ�
    pkDestructor,      // �������ڲ�
    pkFieldDot,        // ������ĵ㣬����C/C++��->

    pkDeclaration);    // C�еı�����������ָ����֮��ı��������֣�һ�����赯��

  TCodePosKinds = set of TCodePosKind;

  // ��ǰ����λ����Ϣ��ͬʱ֧�� Pascal �� C/C++
  PCodePosInfo = ^TCodePosInfo;
  TCodePosInfo = record
    IsPascal: Boolean;         // �Ƿ��� Pascal �ļ�
    LastIdentPos: Integer;     // ��һ����ʶ��λ��
    LastNoSpace: TTokenKind;   // ��һ���ǿռǺ�����
    LastNoSpacePos: Integer;   // ��һ�ηǿռǺ�λ��
    LineNumber: Integer;       // �к�
    LinePos: Integer;          // ��λ��
    TokenPos: Integer;         // ��ǰ�Ǻ�λ��
    Token: AnsiString;         // ��ǰ�Ǻ�����
    TokenID: TTokenKind;       // ��ǰPascal�Ǻ�����
    CTokenID: TCTokenKind;     // ��ǰC�Ǻ�����
    AreaKind: TCodeAreaKind;   // ��ǰ��������
    PosKind: TCodePosKind;     // ��ǰλ������
  end;

const
  // ���е�λ�ü���
  csAllPosKinds = [Low(TCodePosKind)..High(TCodePosKind)];
  // �Ǵ�������λ�ü���
  csNonCodePosKinds = [pkUnknown, pkComment, pkIntfUses, pkImplUses,
    pkCompDirect, pkString];
  // ������λ�ü���
  csFieldPosKinds = [pkField, pkFieldDot];
  // �����������
  csNormalPosKinds = csAllPosKinds - csNonCodePosKinds - csFieldPosKinds;

function ParsePasCodePosInfo(const Source: AnsiString; CurrPos: Integer;
  FullSource: Boolean = True; IsUtf8: Boolean = False): TCodePosInfo;
{* ����Դ�����е�ǰλ�õ���Ϣ}

procedure ParseUnitUses(const Source: AnsiString; UsesList: TStrings);
{* ����Դ���������õĵ�Ԫ}

implementation

type
  TCnProcObj = class
  {* ����һ�������� procedure/function ���壬������������}
  private
    FToken: TCnPasToken;
    FBeginToken: TCnPasToken;
    FNestCount: Integer;
    function GetIsNested: Boolean;
    function GetBeginMatched: Boolean;
    function GetLayer: Integer;
  public
    property Token: TCnPasToken read FToken write FToken;
    {* procedure/function ���ڵ� Token}
    property Layer: Integer read GetLayer;
    {* procedure/function ���ڵ� Token �Ĳ����}
    property BeginMatched: Boolean read GetBeginMatched;
    {* �� procedure/function �Ƿ������ҵ���ʵ����� begin}
    property BeginToken: TCnPasToken read FBeginToken write FBeginToken;
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
    FIfStart: TCnPasToken;         // �洢�� if ����
    FIfBegin: TCnPasToken;         // �洢 if ��Ӧ��ͬ�� begin
    FIfEnded: Boolean;             // �� if �����Ƿ�������������� if ��䣩
    FElseToken: TCnPasToken;       // �洢 else ����
    FElseBegin: TCnPasToken;       // �洢 else ��Ӧ��ͬ�� begin
    FElseEnded: Boolean;           // �� else ���Ƿ����
    FElseList: TObjectList;        // �洢��� else if �е� else ����
    FIfList: TObjectList;          // �洢��� else if �е� if ����
    FElseIfBeginList: TObjectList; // �洢��� else if �Ķ�Ӧ begin������Ϊ��
    FElseIfEnded: TList;           // �洢��� else if �Ƿ�����ı�ǣ�1 �� 0
    FIfAllEnded: Boolean;          // ���� if �Ƿ����
    function GetElseIfCount: Integer;
    function GetElseIfElse(Index: Integer): TCnPasToken;
    function GetElseIfIf(Index: Integer): TCnPasToken;
    function GetLastElseIfElse: TCnPasToken;
    function GetLastElseIfIf: TCnPasToken;
    procedure SetIfStart(const Value: TCnPasToken);
    function GetLastElseIfBegin: TCnPasToken;
    procedure SetFIfBegin(const Value: TCnPasToken);
    procedure SetElseBegin(const Value: TCnPasToken);
  public
    constructor Create; virtual;
    destructor Destroy; override;

    function HasElse: Boolean;
    {* �� if ���Ƿ��е����� else}

    procedure ChangeElseToElseIf(AIf: TCnPasToken);
    {* �����һ�� else ��Ϊһ�� else if������ else ����ܵ� if ʱ}
    procedure AddBegin(ABegin: TCnPasToken);
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
    property IfStart: TCnPasToken read FIfStart write SetIfStart;
    {* ��ȡ if ��ʼ Token �Լ���һ�� Token ��Ϊ if ��ʼ Token}
    property IfBegin: TCnPasToken read FIfBegin write SetFIfBegin;
    {* ��ȡ if �����Ӧ�� begin �� Token �Լ���һ�� begin ��Ϊ if ��Ӧ�� begin}
    property ElseToken: TCnPasToken read FElseToken write FElseToken;
    {* ��ȡ if ��� else �� Token �Լ���һ�� Token ��Ϊ if ��� else �� Token}
    property ElseBegin: TCnPasToken read FElseBegin write SetElseBegin;
    {* ��ȡ if ��� else ����Ӧ�� begin �Լ���һ�� Token ��Ϊ�� else ��Ӧ�� begin �� Token}
    property ElseIfCount: Integer read GetElseIfCount;
    {* ���ظ� if ��� else if ����}
    property ElseIfElse[Index: Integer]: TCnPasToken read GetElseIfElse;
    {* ���ظ� if ��� else if �� else �� Token�������� 0 �� ElseIfCount - 1}
    property ElseIfIf[Index: Integer]: TCnPasToken read GetElseIfIf;
    {* ���ظ� if ��� else if ��  �� Token�������� 0 �� ElseIfCount - 1}
    property LastElseIfElse: TCnPasToken read GetLastElseIfElse;
    {* ���ظ� if ������һ�� else if �� else}
    property LastElseIfIf: TCnPasToken read GetLastElseIfIf;
    {* ���ظ� if ������һ�� else if �� if}
    property LastElseIfBegin: TCnPasToken read GetLastElseIfBegin;
    {* ���ظ� if ������һ�� else if �� begin������еĻ�}
    property IfAllEnded: Boolean read FIfAllEnded;
    {* ���ظ� if ����Ƿ�ȫ�����������жϲ��Ӷ�ջ�е���}
  end;

var
  TokenPool: TCnList;

// �óط�ʽ������ PasTokens ���������
function CreatePasToken: TCnPasToken;
begin
  if TokenPool.Count > 0 then
  begin
    Result := TCnPasToken(TokenPool.Last);
    TokenPool.Delete(TokenPool.Count - 1);
  end
  else
    Result := TCnPasToken.Create;
end;

procedure FreePasToken(Token: TCnPasToken);
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
procedure LexNextNoJunkWithoutCompDirect(Lex: TmwPasLex);
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

constructor TCnPasStructureParser.Create(SupportUnicodeIdent: Boolean);
begin
  FList := TCnList.Create;
  FTabWidth := 2;
  FSupportUnicodeIdent := SupportUnicodeIdent;

  FMethodStack := TCnObjectStack.Create;
  FBlockStack := TCnObjectStack.Create;
  FMidBlockStack := TCnObjectStack.Create;
  FProcStack := TCnObjectStack.Create;
  FIfStack := TCnObjectStack.Create;
end;

destructor TCnPasStructureParser.Destroy;
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

procedure TCnPasStructureParser.Clear;
var
  I: Integer;
begin
  for I := 0 to FList.Count - 1 do
    FreePasToken(TCnPasToken(FList[I]));
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

function TCnPasStructureParser.GetCount: Integer;
begin
  Result := FList.Count;
end;

function TCnPasStructureParser.GetToken(Index: Integer): TCnPasToken;
begin
  Result := TCnPasToken(FList[Index]);
end;

procedure TCnPasStructureParser.ParseSource(ASource: PAnsiChar; AIsDpr, AKeyOnly:
  Boolean);
var
  Lex: TmwPasLex;
  Token, CurrMethod, CurrBlock, CurrMidBlock, CurrIfStart: TCnPasToken;
  SavePos, SaveLineNumber, SaveLinePos: Integer;
  IsClassOpen, IsClassDef, IsImpl, IsHelper, IsElseIf, ExpectElse: Boolean;
  IsRecordHelper, IsSealed, IsAbstract, IsRecord, IsObjectRecord, IsForFunc: Boolean;
  SameBlockMethod, CanEndBlock, CanEndMethod: Boolean;
  DeclareWithEndLevel, CurrBracketLevel: Integer;
  PrevTokenID: TTokenKind;
  PrevTokenStr: AnsiString;
  AProcObj, PrevProcObj: TCnProcObj;
  AIfObj: TCnIfStatement;

  function CalcCharIndex(): Integer;
{$IFDEF BDS2009_UP}
  var
    I, Len: Integer;
{$ENDIF}
  begin
{$IFDEF BDS2009_UP}
    if FUseTabKey and (FTabWidth >= 2) then
    begin
      // ������ǰ�����ݽ��� Tab ��չ��
      I := Lex.LinePos;
      Len := 0;
      while ( I < Lex.TokenPos ) do
      begin
        if (ASource[I] = #09) then
          Len := ((Len div FTabWidth) + 1) * FTabWidth
        else
          Inc(Len);
        Inc(I);
      end;
      Result := Len;
    end
    else
{$ENDIF}
      Result := Lex.TokenPos - Lex.LinePos;
  end;

  procedure NewToken;
  begin
    Token := CreatePasToken;
    Token.FTokenPos := Lex.TokenPos;

    Token.FToken := Lex.Token;

    Token.FLineNumber := Lex.LineNumber;
    Token.FCharIndex := CalcCharIndex();
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
    Token.FBracketLayer := CurrBracketLevel;
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

    Lex := TmwPasLex.Create(FSupportUnicodeIdent);
    Lex.Origin := PAnsiChar(ASource);

    DeclareWithEndLevel := 0; // Ƕ�׵���Ҫend�Ķ������
    Token := nil;
    CurrMethod := nil;        // ��ǰ Token ���ڵķ��� procedure/function�������������������� 
    CurrBlock := nil;         // ��ǰ Token ���ڵĿ顣
    CurrMidBlock := nil;
    CurrBracketLevel := 0;
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

      if (Lex.TokenID in [tkCompDirect]) // Allow CompDirect
        or ((PrevTokenID <> tkAmpersand) and (Lex.TokenID in
        [tkProcedure, tkFunction, tkConstructor, tkDestructor,
        tkInitialization, tkFinalization,
        tkBegin, tkAsm,
        tkCase, tkTry, tkRepeat, tkIf, tkFor, tkWith, tkOn, tkWhile,
        tkRecord, tkObject, tkOf, tkEqual,
        tkClass, tkInterface, tkDispinterface,
        tkExcept, tkFinally, tkElse,
        tkEnd, tkUntil, tkThen, tkDo])) then
      begin
        NewToken;
        case Lex.TokenID of
          tkProcedure, tkFunction, tkConstructor, tkDestructor:
            begin
              // IsAnonFunc := IsImpl and (Lex.TokenID in [tkProcedure, tkFunction])
              //   and (PrevTokenID in [tkTo, tkAssign, tkRoundOpen, tkComma]);

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
                if PrevProcObj <> nil then
                begin
                  if PrevProcObj.BeginMatched then
                    Token.FMethodStartAfterParentBegin := True
                  else
                    AProcObj.NestCount := PrevProcObj.NestCount + 1;
                end;
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
                if (AProcObj.Token <> nil) and Token.FIsMethodStart then
                begin
                  // ����� Proc ������������������ begin �󣩣��� begin ҲҪ��¼
                  Token.FMethodStartAfterParentBegin := AProcObj.Token.FMethodStartAfterParentBegin;
                end;

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
              IsObjectRecord := Lex.TokenID = tkObject;
              IsForFunc := (PrevTokenID in [tkPoint]) or
                ((PrevTokenID = tkSymbol) and (PrevTokenStr = '&'));
              if IsRecord then
              begin
                // ���� record helper for �����Σ�����implementation������end�ᱻ
                // record�ڲ���function/procedure���ɵ������޽��������
                IsRecordHelper := False;
                SavePos := Lex.RunPos;
                SaveLineNumber := Lex.LineNumber;
                SaveLinePos := Lex.LinePos;

                LexNextNoJunkWithoutCompDirect(Lex);
                if Lex.TokenID in [tkSymbol, tkIdentifier] then
                begin
                  if LowerCase(string(Lex.Token)) = 'helper' then
                    IsRecordHelper := True;
                end;

                // TODO: �ָ���Lex.TokenID ����
                Lex.LineNumber := SaveLineNumber;
                Lex.LinePos := SaveLinePos;
                Lex.RunPos := SavePos;
              end;

              // of object �� object ��Ӧ�ø����������ڴ˴��޳�

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

                if IsRecord or IsObjectRecord then
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
                SavePos := Lex.RunPos;
                SaveLineNumber := Lex.LineNumber;
                SaveLinePos := Lex.LinePos;

                LexNextNoJunkWithoutCompDirect(Lex);
                if Lex.TokenID in [tkSymbol, tkIdentifier, tkSealed, tkAbstract] then
                begin
                  if LowerCase(string(Lex.Token)) = 'helper' then
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
                Lex.LineNumber := SaveLineNumber;
                Lex.LinePos := SaveLinePos;
                Lex.RunPos := SavePos;
              end;

              IsClassOpen := False;
              if IsClassDef then
              begin
                IsClassOpen := True;
                SavePos := Lex.RunPos;
                SaveLineNumber := Lex.LineNumber;
                SaveLinePos := Lex.LinePos;

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

                // RunPos ���¸�ֵ���ᵼ���Ѿ����Ƶ� LineNumber �ع飬�Ǹ� Bug
                // ����� Lex �� LineNumber �Լ� LinePos ֱ�Ӹ�ֵ���ֲ�֪������ɶ����
                Lex.LineNumber := SaveLineNumber;
                Lex.LinePos := SaveLinePos;
                Lex.RunPos := SavePos;
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
                      CurrMidBlock := TCnPasToken(FMidBlockStack.Pop)
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
                      CurrBlock := TCnPasToken(FBlockStack.Pop);
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
                      Token.FMethodStartAfterParentBegin := CurrMethod.MethodStartAfterParentBegin;
                      if FMethodStack.Count > 0 then
                        CurrMethod := TCnPasToken(FMethodStack.Pop)
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
          // �ֺ�����ڶ����Բ������ͷ��˵��������Ϊ�����ã���˼����� CurrBracketLevel ���ж�
          // FList.Count Ϊ�ֺż���� ItemIndex
          // ���һ����� CurrBlock ���ڣ���û�к��� if �� else �� else �� begin��˵���ֺŽ��� else ͬ��
          // ���������� CurrBlock ���ڣ���û�к������һ�� else if �� if������ begin��˵���ֺŽ������һ�� else if ͬ��
          // ���������� CurrBlock ���ڣ���û�к��� if���� if û begin��˵���ֺŽ��� if ͬ��
          if CurrBlock <> nil then
          begin
            if AIfObj.HasElse and (AIfObj.ElseBegin = nil) and
              (CurrBlock.ItemIndex <= AIfObj.ElseToken.ItemIndex) and
              (CurrBracketLevel = AIfObj.ElseToken.BracketLayer) then  // �ֺŽ������� begin �� else
            begin
              AIfObj.EndElseBlock;
              AIfObj.EndIfAll;
            end
            else if (AIfObj.ElseIfCount > 0) and (AIfObj.LastElseIfBegin = nil)
              and (AIfObj.LastElseIfIf <> nil) and
              (CurrBlock.ItemIndex <= AIfObj.LastElseIfIf.ItemIndex) and
              (CurrBracketLevel = AIfObj.LastElseIfIf.BracketLayer) then
            begin
              AIfObj.EndLastElseIfBlock;       // �ֺŽ������� begin �����һ�� else if
              AIfObj.EndIfAll;
            end
            else if (AIfObj.IfBegin = nil) and
              (CurrBlock.ItemIndex <= AIfObj.IfStart.ItemIndex) and
              (CurrBracketLevel = AIfObj.IfStart.BracketLayer) then  // �ֺŽ������� begin �� if ����
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
            CurrMethod := TCnPasToken(FMethodStack.Pop)
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

      if Lex.TokenID = tkRoundOpen then
        Inc(CurrBracketLevel)
      else if Lex.TokenID = tkRoundClose then
        Dec(CurrBracketLevel);

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

procedure TCnPasStructureParser.FindCurrentBlock(LineNumber, CharIndex:
  Integer);
var
  Token: TCnPasToken;
  CurrIndex: Integer;

  procedure _BackwardFindDeclarePos;
  var
    Level: Integer;
    i, NestedProcs: Integer;
    StartInner: Boolean;
  begin
    Level := 0;
    StartInner := True;
    NestedProcs := 1;
    for i := CurrIndex - 1 downto 0 do
    begin
      Token := Tokens[i];
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
    i, NestedProcs: Integer;
    EndInner: Boolean;
  begin
    Level := 0;
    EndInner := True;
    NestedProcs := 1;
    for i := CurrIndex to Count - 1 do
    begin
      Token := Tokens[i];
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

  function _GetMethodName(StartToken, CloseToken: TCnPasToken): String;
  var
    i: Integer;
  begin
    Result := '';
    if Assigned(StartToken) and Assigned(CloseToken) then
      for i := StartToken.ItemIndex + 1 to CloseToken.ItemIndex do
      begin
        Token := Tokens[i];
        if (Token.Token = '(') or (Token.Token = ':') or (Token.Token = ';') then
          Break;
        Result := Result + Trim(Token.Token);
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
        (Tokens[CurrIndex].CharIndex > CharIndex ) then // ��ʼ�������ж�
        Break
      else if (Tokens[CurrIndex].TokenID in [tkEnd, tkUntil, tkThen, tkDo]) and
        (Tokens[CurrIndex].CharIndex + Length(Tokens[CurrIndex].Token) > CharIndex ) then
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

function TCnPasStructureParser.IndexOfToken(Token: TCnPasToken): Integer;
begin
  Result := FList.IndexOf(Token);
end;

function TCnPasStructureParser.FindCurrentDeclaration(LineNumber, CharIndex: Integer): String;
var
  Idx: Integer;
begin
  Result := '';
  FindCurrentBlock(LineNumber, CharIndex);
  
  if InnerBlockStartToken <> nil then
  begin
    if InnerBlockStartToken.TokenID in [tkClass, tkInterface, tkRecord,
      tkDispInterface, tkObject] then
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

//==============================================================================
// Pascal Դ��λ����Ϣ����
//==============================================================================

function ParsePasCodePosInfo(const Source: AnsiString; CurrPos: Integer;
  FullSource: Boolean = True; IsUtf8: Boolean = False): TCodePosInfo;
var
  IsProgram: Boolean;
  InClass: Boolean;
  ProcStack: TStack;
  ProcIndent: Integer;
  SavePos: TCodePosKind;
  Lex: TmwPasLex;
  Text: AnsiString;

  procedure DoNext(NoJunk: Boolean = False);
  begin
    Result.LastIdentPos := Lex.LastIdentPos;
    Result.LastNoSpace := Lex.LastNoSpace;
    Result.LastNoSpacePos := Lex.LastNoSpacePos;
    Result.LineNumber := Lex.LineNumber;
    Result.LinePos := Lex.LinePos;
    Result.TokenPos := Lex.TokenPos;
    Result.Token := Lex.Token;
    Result.TokenID := Lex.TokenID;
    if NoJunk then
      Lex.NextNoJunk
    else
      Lex.Next;
  end;

begin
  if CurrPos <= 0 then
    CurrPos := MaxInt;
  Lex := nil;
  ProcStack := nil;
  Result.IsPascal := True;

  try
    Lex := TmwPasLex.Create;
    ProcStack := TStack.Create;
{$IFDEF BDS}
    if IsUtf8 then
    begin
      Text := CnUtf8ToAnsi(PAnsiChar(Source));
//{$IFNDEF BDS2009_UP}
      // XE/XE2 �µ�CurrPos �Ѿ��� UTF8 ��λ�ã������ٴ�ת�����������2009 δ֪��
      CurrPos := Length(CnUtf8ToAnsi(Copy(Source, 1, CurrPos)));
      // ��ת���ᵼ�������������ַ����ﵯ���������֣����ǵ�ת��
//{$ENDIF}
    end
    else
      Text := Source;
{$ELSE}
    Text := Source;
{$ENDIF}
    Lex.Origin := PAnsiChar(Text);

    if FullSource then
    begin
      Result.AreaKind := akHead;
      Result.PosKind := pkUnknown;
    end
    else
    begin
      Result.AreaKind := akImplementation;
      Result.PosKind := pkUnknown;
    end;
    SavePos := pkUnknown;
    IsProgram := False;
    InClass := False;
    ProcIndent := 0;
    while (Lex.TokenPos < CurrPos) and (Lex.TokenID <> tkNull) do
    begin
      // CnDebugger.LogFmt('Token ID %d, Pos %d, %s',[Integer(Lex.TokenID), Lex.TokenPos, Lex.Token]);
      case Lex.TokenID of
        tkUnit:
          begin
            IsProgram := False;
            Result.AreaKind := akUnit;
            Result.PosKind := pkFlat;
          end;
        tkProgram, tkLibrary:
          begin
            IsProgram := True;
            Result.AreaKind := akProgram;
            Result.PosKind := pkFlat;
          end;
        tkInterface:
          begin
            if (Result.AreaKind in [akUnit, akProgram]) and not IsProgram then
            begin
              Result.AreaKind := akInterface;
              Result.PosKind := pkFlat;
            end
            else if Lex.IsInterface then
            begin
              Result.PosKind := pkInterface;
              DoNext(True);
              if (Lex.TokenPos < CurrPos) and (Lex.TokenID = tkSemiColon) then
                Result.PosKind := pkType
              else if (Lex.TokenPos < CurrPos) and (Lex.TokenID = tkRoundOpen) then
              begin
                while (Lex.TokenPos < CurrPos) and not (Lex.TokenID in
                  [tkNull, tkRoundClose]) do
                  DoNext;
                if (Lex.TokenPos < CurrPos) and (Lex.TokenID = tkRoundClose) then
                begin
                  DoNext(True);
                  if (Lex.TokenPos < CurrPos) and (Lex.TokenID = tkSemiColon) then
                    Result.PosKind := pkType;
                end;
              end;
              if Result.PosKind = pkInterface then
                InClass := True;
            end;
          end;
        tkUses:
          begin
            if Result.AreaKind in [akProgram, akInterface] then
            begin
              Result.AreaKind := akIntfUses;
              Result.PosKind := pkIntfUses;
            end
            else if Result.AreaKind = akImplementation then
            begin
              Result.AreaKind := akImplUses;
              Result.PosKind := pkIntfUses;
            end;
            if Result.AreaKind in [akIntfUses, akImplUses] then
            begin
              while (Lex.TokenPos < CurrPos) and not (Lex.TokenID in [tkNull, tkSemiColon]) do
                DoNext;
              if (Lex.TokenPos < CurrPos) and (Lex.TokenID = tkSemiColon) then
              begin
                if Result.AreaKind = akIntfUses then
                  Result.AreaKind := akInterface
                else
                  Result.AreaKind := akImplementation;
                Result.PosKind := pkFlat;
              end;
            end;
          end;
        tkImplementation:
          if not IsProgram then
          begin
            Result.AreaKind := akImplementation;
            Result.PosKind := pkFlat;
          end;
        tkInitialization:
          begin
            Result.AreaKind := akInitialization;
            Result.PosKind := pkFlat;
          end;
        tkFinalization:
          begin
            Result.AreaKind := akFinalization;
            Result.PosKind := pkFlat;
          end;
        tkSquareClose:
          if (Lex.Token = '.)') and (Lex.LastNoSpace in [tkIdentifier,
            tkPointerSymbol, tkSquareClose, tkRoundClose]) then
          begin
            if not (Result.PosKind in [pkFieldDot, pkField]) then
              SavePos := Result.PosKind;
            Result.PosKind := pkFieldDot;
          end;
        tkPoint:
          if Lex.LastNoSpace = tkEnd then
          begin
            Result.AreaKind := akEnd;
            Result.PosKind := pkUnknown;
          end
          else if Lex.LastNoSpace in [tkIdentifier, tkPointerSymbol, {$IFDEF DelphiXE3_UP} tkString, {$ENDIF} // Delphi XE3 Supports function invoke on string
            tkSquareClose, tkRoundClose] then
          begin
            if not (Result.PosKind in [pkFieldDot, pkField]) then
              SavePos := Result.PosKind;
            Result.PosKind := pkFieldDot;
          end;
        tkAnsiComment, tkBorComment, tkSlashesComment:
          begin
            if Result.PosKind <> pkComment then
            begin
              SavePos := Result.PosKind;
              Result.PosKind := pkComment;
            end;
          end;
        tkClass:
          begin
            if Lex.IsClass then
            begin
              Result.PosKind := pkClass;
              DoNext(True);
              if (Lex.TokenPos < CurrPos) and (Lex.TokenID = tkSemiColon) then
                Result.PosKind := pkType
              else if (Lex.TokenPos < CurrPos) and (Lex.TokenID = tkRoundOpen) then
              begin
                while (Lex.TokenPos < CurrPos) and not (Lex.TokenID in
                  [tkNull, tkRoundClose]) do
                  DoNext;
                if (Lex.TokenPos < CurrPos) and (Lex.TokenID = tkRoundClose) then
                begin
                  DoNext(True);
                  if (Lex.TokenPos < CurrPos) and (Lex.TokenID = tkSemiColon) then
                    Result.PosKind := pkType
                  else
                  begin
                    InClass := True;
                    Continue;
                  end;
                end;
              end
              else
              begin
                InClass := True;
                Continue;
              end;
            end;
          end;
        tkType:
          Result.PosKind := pkType;
        tkConst:
          if not InClass then
            Result.PosKind := pkConst;
        tkResourceString:
          Result.PosKind := pkResourceString;
        tkVar:
          if not InClass then
            Result.PosKind := pkVar;
        tkCompDirect:
          begin
            if Result.PosKind <> pkCompDirect then
            begin
              SavePos := Result.PosKind;
              Result.PosKind := pkCompDirect;
            end;
          end;
        tkString:
          begin
            if not SameText(string(Lex.Token), 'String') and (Result.PosKind <> pkString) then
            begin
              SavePos := Result.PosKind;
              Result.PosKind := pkString;
            end;
          end;
        tkIdentifier, tkMessage, tkRead, tkWrite, tkDefault, tkIndex:
          if (Lex.LastNoSpace = tkPoint) and (Result.PosKind = pkFieldDot) then
          begin
            Result.PosKind := pkField;
          end;
        tkProcedure, tkFunction, tkConstructor, tkDestructor:
          begin
            if not InClass and (Result.AreaKind in [akProgram, akImplementation]) then
            begin
              ProcIndent := 0;
              if Lex.TokenID = tkProcedure then
                Result.PosKind := pkProcedure
              else if Lex.TokenID = tkFunction then
                Result.PosKind := pkFunction
              else if Lex.TokenID = tkConstructor then
                Result.PosKind := pkConstructor
              else
                Result.PosKind := pkDestructor;
              ProcStack.Push(Pointer(Result.PosKind));
            end;
            // todo: �����������ĺ���
          end;
        tkBegin, tkTry, tkCase, tkAsm, tkRecord:
          begin
            if ProcStack.Count > 0 then
            begin
              Inc(ProcIndent);
              Result.PosKind := TCodePosKind(ProcStack.Peek);
            end;
          end;
        tkEnd:
          begin
            if InClass then
            begin
              Result.PosKind := pkType;
              InClass := False;
            end
            else if ProcStack.Count > 0 then
            begin
              Dec(ProcIndent);
              if ProcIndent <= 0 then
              begin
                ProcStack.Pop;
                Result.PosKind := pkFlat;
              end;
            end;
          end;
      else
        if Result.PosKind in [pkCompDirect, pkComment, pkString, pkField,
          pkFieldDot] then
          Result.PosKind := SavePos;
      end;

      DoNext;
    end;
  finally
    if Lex <> nil then
      Lex.Free;
    if ProcStack <> nil then
      ProcStack.Free;
  end;
end;

// ����Դ���������õĵ�Ԫ
procedure ParseUnitUses(const Source: AnsiString; UsesList: TStrings);
var
  Lex: TmwPasLex;
  Flag: Integer;
  S: string;
begin
  UsesList.Clear;
  Lex := TmwPasLex.Create;

  Flag := 0;
  S := '';
  try
    Lex.Origin := PAnsiChar(Source);
    while Lex.TokenID <> tkNull do
    begin
      if Lex.TokenID = tkUses then
      begin
        while not (Lex.TokenID in [tkNull, tkSemiColon]) do
        begin
          Lex.Next;
          if Lex.TokenID = tkIdentifier then
          begin
            S := S + string(Lex.Token);
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

{ TCnPasToken }

procedure TCnPasToken.Clear;
begin
  FCppTokenKind := TCTokenKind(0);
  FCharIndex := 0;
  FEditCol := 0;
  FEditLine := 0;
  FItemIndex := 0;
  FItemLayer := 0;
  FLineNumber := 0;
  FMethodLayer := 0;
  FToken := '';
  FTokenID := TTokenKind(0);
  FTokenPos := 0;
  FIsMethodStart := False;
  FIsMethodClose := False;
  FIsBlockStart := False;
  FIsBlockClose := False;
end;

{ TCnIfStatement }

procedure TCnIfStatement.AddBegin(ABegin: TCnPasToken);
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

procedure TCnIfStatement.ChangeElseToElseIf(AIf: TCnPasToken);
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

function TCnIfStatement.GetElseIfElse(Index: Integer): TCnPasToken;
begin
  Result := TCnPasToken(FElseList[Index]);
end;

function TCnIfStatement.GetElseIfIf(Index: Integer): TCnPasToken;
begin
  Result := TCnPasToken(FIfList[Index]);
end;

function TCnIfStatement.GetLastElseIfBegin: TCnPasToken;
begin
  Result := nil;
  if FElseIfBeginList.Count > 0 then
    Result := TCnPasToken(FElseIfBeginList[FElseIfBeginList.Count - 1]);
end;

function TCnIfStatement.GetLastElseIfElse: TCnPasToken;
begin
  Result := nil;
  if FElseList.Count > 0 then
    Result := TCnPasToken(FElseList[FElseList.Count - 1]);
end;

function TCnIfStatement.GetLastElseIfIf: TCnPasToken;
begin
  Result := nil;
  if FIfList.Count > 0 then
    Result := TCnPasToken(FIfList[FIfList.Count - 1]);
end;

function TCnIfStatement.HasElse: Boolean;
begin
  Result := FElseToken <> nil;
end;

procedure TCnIfStatement.SetElseBegin(const Value: TCnPasToken);
begin
  FElseBegin := Value;
end;

procedure TCnIfStatement.SetFIfBegin(const Value: TCnPasToken);
begin
  FIfBegin := Value;
end;

procedure TCnIfStatement.SetIfStart(const Value: TCnPasToken);
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
