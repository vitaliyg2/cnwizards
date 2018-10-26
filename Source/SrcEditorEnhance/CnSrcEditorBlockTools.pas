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

unit CnSrcEditorBlockTools;
{ |<PRE>
================================================================================
* ������ƣ�CnPack IDE ר�Ұ�
* ��Ԫ���ƣ�����༭����չ�������ߵ�Ԫ
* ��Ԫ���ߣ��ܾ��� (zjy@cnpack.org)
* ��    ע��
* ����ƽ̨��PWin2000Pro + Delphi 5.01
* ���ݲ��ԣ�PWin9X/2000/XP + Delphi 5/6/7 + C++Builder 5/6
* �� �� �����õ�Ԫ�е��ַ���֧�ֱ��ػ�����ʽ
* ��Ԫ��ʶ��$Id$
* �޸ļ�¼��2018.07.30
*               ������ʾɫ��Ĺ���
*           2012.11.02 by liuxiao
*               �� OTA �� Bug������ D7 �µ�������������
*           2012.10.08 by shenloqi
*               ���� Ctrl+Shift+D ɾ����ǰ�л�ѡ���еĹ���
*           2012.10.01 by shenloqi
*               �����˽���ǰ����/�������ƶ��Ĺ��ܣ������˸��Ƶ�ǰ����/�еĹ���
*           2012.09.19 by shenloqi
*               ��ֲ�� Delphi XE3
*           2005.06.05
*               LiuXiao ���븴��ճ����ǰ��ʶ���Ĺ���
*           2004.12.25
*               ������Ԫ����ԭ CnEditorEnhancements �Ƴ�
================================================================================
|</PRE>}

interface

{$I CnWizards.inc}

{$IFDEF CNWIZARDS_CNSRCEDITORENHANCE}

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Dialogs, ToolsAPI,
  IniFiles, Forms, Menus, ActnList, Math,
  {$IFDEF DelphiXE3_UP}Actions,{$ENDIF}
  CnCommon, CnWizUtils, CnWizIdeUtils, CnWizConsts, CnEditControlWrapper,
  CnWizFlatButton, CnConsts, CnWizNotifier, CnWizShortCut, CnPopupMenu,
  CnSrcEditorCodeWrap, CnSrcEditorGroupReplace, CnSrcEditorWebSearch,
  CnWizManager, CnWizMenuAction, CnWizShareImages;

type
  TBlockToolKind = (
    btCopy, btCopyAppend, btDuplicate, btCut, btCutAppend, btDelete,
    btCopyHTML, btSaveToFile,
    btLowerCase, btUpperCase, btToggleCase,
    btIndent, btIndentEx, btUnindent, btUnindentEx,
    btCommentCode, btUnCommentCode, btToggleComment, btCommentCropper, btSortUsesList,
    btFormatCode, btCodeSwap, btCodeToString, btInsertColor, btInsertDateTime,
    btSortLines, btBlockMoveUp, btBlockMoveDown, btBlockDelLines, btShortCutConfig);

  TCnSrcEditorBlockTools = class(TObject)
  private
    FIcon: TIcon;
    FCodeWrap: TCnSrcEditorCodeWrapTool;
    FGroupReplace: TCnSrcEditorGroupReplaceTool;
    FWebSearch: TCnSrcEditorWebSearchTool;
    FDupShortCut: TCnWizShortCut;
    FLowerCaseShortCut: TCnWizShortCut;
    FUpperCaseShortCut: TCnWizShortCut;
    FToggleCaseShortCut: TCnWizShortCut;
    FBlockMoveUpShortCut: TCnWizShortCut;
    FBlockMoveDownShortCut: TCnWizShortCut;
    FBlockDelLinesShortCut: TCnWizShortCut;
    FActive: Boolean;
    FOnEnhConfig: TNotifyEvent;
    FShowBlockTools: Boolean;
    FPopupMenu: TPopupMenu;
    FEditMenu: TMenuItem;
    FCaseMenu: TMenuItem;
    FFormatMenu: TMenuItem;
    FCommentMenu: TMenuItem;
    FWrapMenu: TMenuItem;
    FReplaceMenu: TMenuItem;
    FWebSearchMenu: TMenuItem;
    FMiscMenu: TMenuItem;
    FTabIndent: Boolean;
    FShowColor: Boolean;
    procedure SetActive(const Value: Boolean);
    function ExecuteMenu(MenuItem: TMenuItem; Kind: TBlockToolKind): Boolean;
    procedure OnPopup(Sender: TObject);
    procedure OnItemClick(Sender: TObject);
    procedure OnEditDuplicate(Sender: TObject);
    procedure OnEditLowerCase(Sender: TObject);
    procedure OnEditUpperCase(Sender: TObject);
    procedure OnEditToggleCase(Sender: TObject);
    procedure OnEditBlockMoveUp(Sender: TObject);
    procedure OnEditBlockMoveDown(Sender: TObject);
    procedure OnEditBlockDelLines(Sender: TObject);
    procedure DoBlockExecute(Kind: TBlockToolKind);
    procedure DoBlockEdit(Kind: TBlockToolKind);
    procedure DoBlockCase(Kind: TBlockToolKind);
    procedure DoBlockFormat(Kind: TBlockToolKind);
    procedure DoBlockComment(Kind: TBlockToolKind);
    procedure DoBlockMisc(Kind: TBlockToolKind);
    procedure DoShortCutConfig;
    procedure ShowFlatButton(EditWindow: TCustomForm; EditControl: TControl;
      EditView: IOTAEditView);
    procedure SetShowBlockTools(Value: Boolean);
    procedure SetShowColor(const Value: Boolean);
  protected
    function CanShowButton: Boolean;
    procedure DoEnhConfig;
    procedure UpdateFlatButtons;
    procedure EditControlKeyDown(Editor: TEditorObject; Key, ScanCode: Word; Shift: TShiftState;
      var Handled: Boolean);
    procedure EditorChanged(Editor: TEditorObject; ChangeType: TEditorChangeTypes);
  public
    constructor Create;
    destructor Destroy; override;
    procedure LanguageChanged(Sender: TObject);
    procedure LoadSettings(Ini: TCustomIniFile);
    procedure SaveSettings(Ini: TCustomIniFile);
    procedure ResetSettings(Ini: TCustomIniFile);
    procedure UpdateMenu(Items: TMenuItem; NeedImage: Boolean = True);

    property Active: Boolean read FActive write SetActive;
    property ShowBlockTools: Boolean read FShowBlockTools write SetShowBlockTools;
    property ShowColor: Boolean read FShowColor write SetShowColor;
    property TabIndent: Boolean read FTabIndent write FTabIndent;
    property PopupMenu: TPopupMenu read FPopupMenu;
    property OnEnhConfig: TNotifyEvent read FOnEnhConfig write FOnEnhConfig;
  end;

{$ENDIF CNWIZARDS_CNSRCEDITORENHANCE}

implementation

{$IFDEF CNWIZARDS_CNSRCEDITORENHANCE}

uses
  CnWizSubActionShortCutFrm {$IFDEF DEBUG}, CnDebug{$ENDIF};

const
  csLeftKeep = 2;
  SCnSrcEditorBlockButton = 'CnSrcEditorBlockButton';

{ TCnSrcEditorBlockTools }

constructor TCnSrcEditorBlockTools.Create;
begin
  inherited;
  FActive := True;
  FShowBlockTools := True;
  FShowColor := True;

  FIcon := TIcon.Create;
  CnWizLoadIcon(nil, FIcon, 'CnSrcEditorBlockTools'); // ǿ�Ƽ��س�Сͼ��

  FCodeWrap := TCnSrcEditorCodeWrapTool.Create;
  FGroupReplace := TCnSrcEditorGroupReplaceTool.Create;
  FWebSearch := TCnSrcEditorWebSearchTool.Create;

  FDupShortCut := WizShortCutMgr.Add('CnEditDuplicate',
    ShortCut(Word('D'), [ssCtrl, ssAlt]), OnEditDuplicate);
  FLowerCaseShortCut := WizShortCutMgr.Add('CnEditLowerCase', 0, OnEditLowerCase);
  FUpperCaseShortCut := WizShortCutMgr.Add('CnEditUpperCase', 0, OnEditUpperCase);
  FToggleCaseShortCut := WizShortCutMgr.Add('CnEditToggleCase', 0, OnEditToggleCase);

  FBlockMoveUpShortCut := WizShortCutMgr.Add('CnEditBlockMoveUp',
    ShortCut(Word('U'), [ssCtrl, ssAlt, ssShift]), OnEditBlockMoveUp);
  FBlockMoveDownShortCut := WizShortCutMgr.Add('CnEditBlockMoveDown',
    ShortCut(Word('D'), [ssCtrl, ssAlt, ssShift]), OnEditBlockMoveDown);
  FBlockDelLinesShortCut := WizShortCutMgr.Add('CnEditBlockDeleteLines',
    ShortCut(Word('D'), [ssCtrl, ssShift]), OnEditBlockDelLines);

  FPopupMenu := TPopupMenu.Create(nil);
  FPopupMenu.AutoPopup := False;
  FPopupMenu.OnPopup := OnPopup;
  FPopupMenu.Images := dmCnSharedImages.GetMixedImageList;
  UpdateMenu(FPopupMenu.Items);

  EditControlWrapper.AddKeyDownNotifier(EditControlKeyDown);
  EditControlWrapper.AddEditorChangeNotifier(EditorChanged);
end;

destructor TCnSrcEditorBlockTools.Destroy;
begin
  EditControlWrapper.RemoveKeyDownNotifier(EditControlKeyDown);
  EditControlWrapper.RemoveEditorChangeNotifier(EditorChanged);

  // �ͷſؼ�
  FActive := False;
  UpdateFlatButtons;

  FCodeWrap.Free;
  FGroupReplace.Free;
  FWebSearch.Free;

  WizShortCutMgr.DeleteShortCut(FBlockDelLinesShortCut);
  WizShortCutMgr.DeleteShortCut(FBlockMoveDownShortCut);
  WizShortCutMgr.DeleteShortCut(FBlockMoveUpShortCut);
  WizShortCutMgr.DeleteShortCut(FToggleCaseShortCut);
  WizShortCutMgr.DeleteShortCut(FUpperCaseShortCut);
  WizShortCutMgr.DeleteShortCut(FLowerCaseShortCut);
  WizShortCutMgr.DeleteShortCut(FDupShortCut);
  FPopupMenu.Free;
  FIcon.Free;
  inherited;
end;

//------------------------------------------------------------------------------
// ��������
//------------------------------------------------------------------------------

procedure TCnSrcEditorBlockTools.OnItemClick(Sender: TObject);
begin
  if Sender is TMenuItem then
    DoBlockExecute(TBlockToolKind(TMenuItem(Sender).Tag));
end;

procedure TCnSrcEditorBlockTools.OnEditBlockDelLines(Sender: TObject);
var
  EditView: IOTAEditView;
  StartRow: Integer;
  EndRow: Integer;
  LineText: string;
  CharIndex: Integer;
begin
  EditView := CnOtaGetTopMostEditView;
  if IsEditControl(Screen.ActiveControl) and Assigned(EditView) then
  begin
    if EditView.Block.IsValid then
    begin
      StartRow := EditView.Block.StartingRow;
      EndRow := EditView.Block.EndingRow;
      EditView.CursorPos := CnOtaLinePosToEditPos(CnOtaEditPosToLinePos(
          OTAEditPos(1, StartRow), EditView));
      EditView.Block.BeginBlock;
      EditView.CursorPos := CnOtaLinePosToEditPos(CnOtaEditPosToLinePos(
          OTAEditPos(1, EndRow + 1), EditView));
      EditView.Block.EndBlock;
      CnOtaDeleteCurrentSelection();
      EditView.Position.Move(StartRow, 1);
      EditView.MoveViewToCursor();
    end
    else if CnOtaGetCurrLineText(LineText, StartRow, CharIndex) then
    begin
      EditView.CursorPos := CnOtaLinePosToEditPos(CnOtaEditPosToLinePos(
          OTAEditPos(1, StartRow), EditView));
      EditView.Block.BeginBlock;
      EditView.CursorPos := CnOtaLinePosToEditPos(CnOtaEditPosToLinePos(
          OTAEditPos(1, StartRow + 1), EditView));
      EditView.Block.EndBlock;
      CnOtaDeleteCurrentSelection();
      EditView.Position.Move(StartRow, 1);
      EditView.MoveViewToCursor();
    end;
  end;
end;

procedure TCnSrcEditorBlockTools.OnEditBlockMoveDown(Sender: TObject);
var
  EditView: IOTAEditView;
  StartRow: Integer;
  EndRow: Integer;
  StartCol: Integer;
  EndCol: Integer;
  TotalLine: Integer;
  InsertingText: string;
begin
  EditView := CnOtaGetTopMostEditView;
  if IsEditControl(Screen.ActiveControl) and Assigned(EditView) then
  begin
    TotalLine := EditView.Buffer.GetLinesInBuffer;
    if EditView.Block.IsValid then
    begin
      EndRow := EditView.Block.EndingRow;
      if EndRow >= TotalLine then Exit;

      StartRow := EditView.Block.StartingRow;
      StartCol := EditView.Block.StartingColumn;
      EndCol := EditView.Block.EndingColumn;
      if EndRow + 1 < TotalLine then
      begin
        EditView.CursorPos := CnOtaLinePosToEditPos(CnOtaEditPosToLinePos(
            OTAEditPos(1, StartRow), EditView));
        EditView.Block.BeginBlock;
        EditView.CursorPos := CnOtaLinePosToEditPos(CnOtaEditPosToLinePos(
            OTAEditPos(1, EndRow + 1), EditView));
      end
      else
      begin
        EditView.CursorPos := CnOtaLinePosToEditPos(CnOtaEditPosToLinePos(
            OTAEditPos(1, StartRow - 1), EditView));
        EditView.Position.MoveEOL;
        EditView.Block.BeginBlock;
        EditView.CursorPos := CnOtaLinePosToEditPos(CnOtaEditPosToLinePos(
            OTAEditPos(1, EndRow), EditView));
        EditView.Position.MoveEOL;
      end;
      EditView.Block.EndBlock;
      InsertingText := EditView.Block.Text;
      CnOtaDeleteCurrentSelection();
      if EndRow + 1 < TotalLine then
      begin
        EditView.Position.Move(StartRow + 1, 1);
      end
      else
      begin
        EditView.Position.Move(StartRow, 1);
        EditView.Position.MoveEOL;
      end;
      {$IFDEF UNICODE}
      CnOtaInsertTextIntoEditorAtPosW(InsertingText,
        CnOtaEditPosToLinePos(EditView.CursorPos, EditView) , EditView.Buffer);
      {$ELSE}
      CnOtaInsertTextIntoEditorAtPos(ConvertEditorTextToText(InsertingText),
        CnOtaEditPosToLinePos(EditView.CursorPos, EditView) , EditView.Buffer);
      {$ENDIF}
      EditView.CursorPos := CnOtaLinePosToEditPos(CnOtaEditPosToLinePos(
          OTAEditPos(StartCol, StartRow + 1), EditView));
      EditView.Block.BeginBlock;
      EditView.CursorPos := CnOtaLinePosToEditPos(CnOtaEditPosToLinePos(
          OTAEditPos(EndCol, EndRow + 1), EditView));
      EditView.Block.EndBlock;

      //EditView.MoveViewToCursor();
    end
    else if CnOtaGetCurrLineText(InsertingText, StartRow, StartCol) then
    begin
      if StartRow >= TotalLine then Exit;

      EditView.CursorPos := CnOtaLinePosToEditPos(CnOtaEditPosToLinePos(
          OTAEditPos(1, StartRow), EditView));
      EditView.Block.BeginBlock;
      EditView.CursorPos := CnOtaLinePosToEditPos(CnOtaEditPosToLinePos(
          OTAEditPos(1, StartRow + 1), EditView));
      EditView.Block.EndBlock;
      CnOtaDeleteCurrentSelection();
      Inc(StartRow);
      CnOtaInsertSingleLine(StartRow, InsertingText, EditView);
    end;
  end;
end;

procedure TCnSrcEditorBlockTools.OnEditBlockMoveUp(Sender: TObject);
var
  EditView: IOTAEditView;
  StartRow: Integer;
  EndRow: Integer;
  StartCol: Integer;
  EndCol: Integer;
  TotalLine: Integer;
  InsertingText: string;
begin
  EditView := CnOtaGetTopMostEditView;
  if IsEditControl(Screen.ActiveControl) and Assigned(EditView) then
  begin
    TotalLine := EditView.Buffer.GetLinesInBuffer;
    if EditView.Block.IsValid then
    begin
      StartRow := EditView.Block.StartingRow;
      if StartRow <= 1 then Exit;

      EndRow := EditView.Block.EndingRow;
      StartCol := EditView.Block.StartingColumn;
      EndCol := EditView.Block.EndingColumn;
      if (EndRow >= TotalLine) then
      begin
        EditView.CursorPos := CnOtaLinePosToEditPos(CnOtaEditPosToLinePos(
            OTAEditPos(1, StartRow - 1), EditView));
        EditView.Position.MoveEOL;
        EditView.Block.BeginBlock;
        EditView.Position.MoveEOF;
        EditView.Block.EndBlock;
        InsertingText := Copy(EditView.Block.Text, 3,
          Length(EditView.Block.Text)) + CRLF;
      end
      else
      begin
        EditView.CursorPos := CnOtaLinePosToEditPos(CnOtaEditPosToLinePos(
            OTAEditPos(1, StartRow), EditView));
        EditView.Block.BeginBlock;
        EditView.CursorPos := CnOtaLinePosToEditPos(CnOtaEditPosToLinePos(
          OTAEditPos(1, EndRow + 1), EditView));
        EditView.Block.EndBlock;
        InsertingText := EditView.Block.Text;
      end;
      CnOtaDeleteCurrentSelection();
      {$IFDEF UNICODE}
      CnOtaInsertTextIntoEditorAtPosW(InsertingText,
        CnOtaEditPosToLinePos(OTAEditPos(1, StartRow - 1), EditView),
        EditView.Buffer);
      {$ELSE}
      CnOtaInsertTextIntoEditorAtPos(ConvertEditorTextToText(InsertingText),
        CnOtaEditPosToLinePos(OTAEditPos(1, StartRow - 1), EditView),
        EditView.Buffer);
      {$ENDIF}
      EditView.CursorPos := CnOtaLinePosToEditPos(CnOtaEditPosToLinePos(
          OTAEditPos(StartCol, StartRow - 1), EditView));
      EditView.Block.BeginBlock;
      EditView.CursorPos := CnOtaLinePosToEditPos(CnOtaEditPosToLinePos(
          OTAEditPos(EndCol, EndRow - 1), EditView));
      EditView.Block.EndBlock;

      EditView.MoveViewToCursor();
    end
    else if CnOtaGetCurrLineText(InsertingText, StartRow, StartCol) then
    begin
      if StartRow <= 1 then Exit;

      if (StartRow >= TotalLine) then
      begin
        EditView.CursorPos := CnOtaLinePosToEditPos(CnOtaEditPosToLinePos(
            OTAEditPos(1, StartRow - 1), EditView));
        EditView.Position.MoveEOL;
        EditView.Block.BeginBlock;
        EditView.Position.MoveEOF;
      end
      else
      begin
        EditView.CursorPos := CnOtaLinePosToEditPos(CnOtaEditPosToLinePos(
            OTAEditPos(1, StartRow), EditView));
        EditView.Block.BeginBlock;
        EditView.CursorPos := CnOtaLinePosToEditPos(CnOtaEditPosToLinePos(
          OTAEditPos(1, StartRow + 1), EditView));
      end;
      EditView.Block.EndBlock;
      CnOtaDeleteCurrentSelection();
      Dec(StartRow);
      CnOtaInsertSingleLine(StartRow, InsertingText, EditView);
    end;
  end;
end;

procedure TCnSrcEditorBlockTools.OnEditDuplicate(Sender: TObject);
var
  EditView: IOTAEditView;
  TextLen: Integer;
  StartPos: Integer;
  EndPos: Integer;
  LineNo: Integer;
  CharIndex: Integer;
  LineText: String;
begin
  EditView := CnOtaGetTopMostEditView;
  if IsEditControl(Screen.ActiveControl) and Assigned(EditView) then
  begin
    if EditView.Block.IsValid then
    begin
      StartPos := CnOtaEditPosToLinePos(OTAEditPos(EditView.Block.StartingColumn,
        EditView.Block.StartingRow), EditView);
      EndPos := CnOtaEditPosToLinePos(OTAEditPos(EditView.Block.EndingColumn,
        EditView.Block.EndingRow), EditView);
      TextLen := EditView.Block.Size;

    {$IFDEF UNICODE}
      CnOtaInsertTextIntoEditorAtPosW(EditView.Block.Text, StartPos, EditView.Buffer);
    {$ELSE}
      CnOtaInsertTextIntoEditorAtPos(ConvertEditorTextToText(EditView.Block.Text), StartPos, EditView.Buffer);
    {$ENDIF}
      EditView.CursorPos := CnOtaLinePosToEditPos(StartPos + TextLen);
      EditView.Block.BeginBlock;
      EditView.CursorPos := CnOtaLinePosToEditPos(EndPos + TextLen);
      EditView.Block.EndBlock;

      EditView.Paint;
    end
    else
    begin
      CnOtaGetCurrLineText(LineText, LineNo, CharIndex);
      Inc(LineNo);
      CnOtaInsertSingleLine(LineNo, LineText, EditView);
    end;
  end;
end;

procedure TCnSrcEditorBlockTools.OnEditLowerCase(Sender: TObject);
var
  EditView: IOTAEditView;
begin
  EditView := CnOtaGetTopMostEditView;
  if Assigned(EditView) then
  begin
    EditView.Block.LowerCase;
    EditView.Paint;
  end;
end;

procedure TCnSrcEditorBlockTools.OnEditUpperCase(Sender: TObject);
var
  EditView: IOTAEditView;
begin
  EditView := CnOtaGetTopMostEditView;
  if Assigned(EditView) then
  begin
    EditView.Block.UpperCase;
    EditView.Paint;
  end;
end;

procedure TCnSrcEditorBlockTools.OnEditToggleCase(Sender: TObject);
var
  EditView: IOTAEditView;
begin
  EditView := CnOtaGetTopMostEditView;
  if Assigned(EditView) then
  begin
    EditView.Block.ToggleCase;
    EditView.Paint;
  end;
end;

procedure TCnSrcEditorBlockTools.DoBlockExecute(Kind: TBlockToolKind);
begin
  case Kind of
    btCopy..btSaveToFile: DoBlockEdit(Kind);
    btLowerCase..btToggleCase: DoBlockCase(Kind);
    btIndent..btUnindentEx: DoBlockFormat(Kind);
    btCommentCode..btCommentCropper: DoBlockComment(Kind);
    btFormatCode..btBlockDelLines: DoBlockMisc(Kind);
    btShortCutConfig: DoShortCutConfig;
  end;
end;

function TCnSrcEditorBlockTools.ExecuteMenu(MenuItem: TMenuItem; Kind:
  TBlockToolKind): Boolean;
var
  i: Integer;
begin
  for i := 0 to MenuItem.Count - 1 do
    if (MenuItem.Items[i].Tag = Ord(Kind)) and Assigned(MenuItem.Items[i].Action) then
    begin
      Result := MenuItem.Items[i].Action.Execute;
      Exit;
    end;
  Result := False;
end;

procedure TCnSrcEditorBlockTools.DoBlockEdit(Kind: TBlockToolKind);
var
  EditView: IOTAEditView;
begin
  EditView := CnOtaGetTopMostEditView;
  if Assigned(EditView) then
  begin
    case Kind of
      btCopy: EditView.Block.Copy(False);
      btCopyAppend: EditView.Block.Copy(True);
      btDuplicate: OnEditDuplicate(nil);
      btCut: EditView.Block.Cut(False);
      btCutAppend: EditView.Block.Cut(True);
      btDelete: EditView.Block.Delete;
      btSaveToFile:
        begin
          with TSaveDialog.Create(nil) do
          try
            Filter := SCnSaveDlgTxtFilter;
            Title := SCnSaveDlgTitle;
            Options := [ofOverwritePrompt, ofHideReadOnly, ofEnableSizing];
            if Execute then
              EditView.Block.SaveToFile(FileName);
          finally
            Free;
          end;
        end;
    else
      ExecuteMenu(FEditMenu, Kind);
    end;
    EditView.Paint;
  end;
end;

procedure TCnSrcEditorBlockTools.DoBlockCase(Kind: TBlockToolKind);
var
  EditView: IOTAEditView;
begin
  EditView := CnOtaGetTopMostEditView;
  if Assigned(EditView) then
  begin
    case Kind of
      btLowerCase: EditView.Block.LowerCase;
      btUpperCase: EditView.Block.UpperCase;
      btToggleCase: EditView.Block.ToggleCase;
    end;
    EditView.Paint;
  end;
end;

procedure TCnSrcEditorBlockTools.DoBlockFormat(Kind: TBlockToolKind);
var
  EditView: IOTAEditView;
  Indent: Integer;

  function QueryIndent(const ACaption, APrompt: string; var Value: Integer;
    DefValue: Integer): Boolean;
  var
    S: string;
  begin
    S := IntToStr(DefValue);
    if CnInputQuery(ACaption, APrompt, S) then
      Value := StrToIntDef(S, 0)
    else
      Value := 0;
    Result := Value <> 0;
  end;
begin
  EditView := CnOtaGetTopMostEditView;
  if Assigned(EditView) then
  begin
    case Kind of
      btIndent:
        EditView.Block.Indent(CnOtaGetBlockIndent);
      btIndentEx:
        if QueryIndent(SCnSrcBlockIndentCaption, SCnSrcBlockIndentPrompt,
          Indent, CnOtaGetBlockIndent) then
          EditView.Block.Indent(Indent);
      btUnindent:
        EditView.Block.Indent(-CnOtaGetBlockIndent);
      btUnindentEx:
        if QueryIndent(SCnSrcBlockUnindentCaption, SCnSrcBlockUnindentPrompt,
          Indent, CnOtaGetBlockIndent) then
          EditView.Block.Indent(-Indent);
    end;
    EditView.Paint;
  end;
end;

procedure TCnSrcEditorBlockTools.DoBlockComment(Kind: TBlockToolKind);
begin
  ExecuteMenu(FCommentMenu, Kind);
end;

procedure TCnSrcEditorBlockTools.DoBlockMisc(Kind: TBlockToolKind);
var
  EditView: IOTAEditView;
begin
  EditView := CnOtaGetTopMostEditView;
  if Assigned(EditView) then
  begin
    case Kind of
      btBlockMoveUp: OnEditBlockMoveUp(nil);
      btBlockMoveDown: OnEditBlockMoveDown(nil);
      btBlockDelLines: OnEditBlockDelLines(nil);
    else
      ExecuteMenu(FMiscMenu, Kind);
    end;
  end;
end;

//------------------------------------------------------------------------------
// ��ݼ�����
//------------------------------------------------------------------------------

procedure TCnSrcEditorBlockTools.EditControlKeyDown(Editor: TEditorObject; Key, ScanCode: Word;
  Shift: TShiftState; var Handled: Boolean);
var
  EditView: IOTAEditView;
begin
  if FTabIndent and (Key = VK_TAB) and (Shift - [ssShift] = [])
    and not CnOtaIsPersistentBlocks then
  begin
    EditView := CnOtaGetTopMostEditView;
    if Assigned(EditView) and EditView.Block.IsValid then
    begin
{$IFDEF DELPHI10_UP}
      if EditView.Block.SyncMode <> ToolsAPI.smNone then
        Exit;
{$ENDIF}
      if Shift = [ssShift] then
        DoBlockExecute(btUnindent)
      else
        DoBlockExecute(btIndent);
      Handled := True;
    end;
  end;
end;

//------------------------------------------------------------------------------
// �ؼ�����
//------------------------------------------------------------------------------

procedure TCnSrcEditorBlockTools.UpdateMenu(Items: TMenuItem; NeedImage: Boolean);
var
  Item: TMenuItem;

  function DoAddMenuItem(AItem: TMenuItem; const ACaption: string;
    Kind: TBlockToolKind; const ShortCut: TShortCut = 0;
    const ImageActionName: string = ''): TMenuItem;
  var
    Action: TContainedAction;
  begin
    Result := AddMenuItem(AItem, ACaption, OnItemClick, nil, ShortCut,
      StripHotkey(ACaption), Ord(Kind));
    if NeedImage and (ImageActionName <> '') then
    begin
      Action := FindIDEAction(ImageActionName);
      if Assigned(Action) and (Action is TCustomAction) then
        Result.ImageIndex := TCustomAction(Action).ImageIndex;
    end;
  end;

  function AddMenuItemWithAction(AItem: TMenuItem; const ActionName: string;
    Kind: TBlockToolKind): TMenuItem;
  var
    Action: TContainedAction;
  begin
    Action := FindIDEAction(ActionName);
    if Assigned(Action) then
    begin
      Result := TMenuItem.Create(AItem);
      Result.Action := Action;
      if not NeedImage then
        Result.ImageIndex := -1;
      Result.Tag := Ord(Kind);
      AItem.Add(Result);
    end
    else
      Result := nil;
  end;

begin
  Items.Clear;

  // �༭�˵�
  FEditMenu := AddMenuItem(Items, SCnSrcBlockEdit, nil);
  DoAddMenuItem(FEditMenu, SCnSrcBlockCopy, btCopy,
    ShortCut(Word('C'), [ssCtrl]), 'EditCopyCommand');
  DoAddMenuItem(FEditMenu, SCnSrcBlockCopyAppend, btCopyAppend);
  DoAddMenuItem(FEditMenu, SCnSrcBlockCut, btCut,
    ShortCut(Word('X'), [ssCtrl]), 'EditCutCommand');
  DoAddMenuItem(FEditMenu, SCnSrcBlockCutAppend, btCutAppend);
  AddSepMenuItem(FEditMenu);
  DoAddMenuItem(FEditMenu, SCnSrcBlockDuplicate, btDuplicate, FDupShortCut.ShortCut);
  DoAddMenuItem(FEditMenu, SCnSrcBlockDelete, btDelete,
    ShortCut(VK_DELETE, []), 'EditDeleteCommand');
  AddSepMenuItem(FEditMenu);
  AddMenuItemWithAction(FEditMenu, SCnActionPrefix + SCnPas2HtmlWizardCopySelected, btCopyHTML);
  DoAddMenuItem(FEditMenu, SCnSrcBlockSaveToFile, btSaveToFile, 0, 'FileSaveCommand');

  // ��Сдת���˵�
  FCaseMenu := AddMenuItem(Items, SCnSrcBlockCase, nil);
  DoAddMenuItem(FCaseMenu, SCnSrcBlockLowerCase, btLowerCase, FLowerCaseShortCut.ShortCut);
  DoAddMenuItem(FCaseMenu, SCnSrcBlockUpperCase, btUpperCase, FUpperCaseShortCut.ShortCut);
  DoAddMenuItem(FCaseMenu, SCnSrcBlockToggleCase, btToggleCase, FToggleCaseShortCut.ShortCut);

  // ��ʽ�˵�
  FFormatMenu := AddMenuItem(Items, SCnSrcBlockFormat, nil);
  DoAddMenuItem(FFormatMenu, SCnSrcBlockIndent, btIndent, ShortCut(VK_TAB, []), 'actCnEditorCodeIndent');
  DoAddMenuItem(FFormatMenu, SCnSrcBlockIndentEx, btIndentEx);
  DoAddMenuItem(FFormatMenu, SCnSrcBlockUnindent, btUnindent, ShortCut(VK_TAB, [ssShift]), 'actCnEditorCodeUnIndent');
  DoAddMenuItem(FFormatMenu, SCnSrcBlockUnindentEx, btUnindentEx);

  // ע�Ͳ˵�
  FCommentMenu := AddMenuItem(Items, SCnSrcBlockComment, nil);
  AddMenuItemWithAction(FCommentMenu, 'actCnEditorCodeComment', btCommentCode);
  AddMenuItemWithAction(FCommentMenu, 'actCnEditorCodeUnComment', btUnCommentCode);
  AddMenuItemWithAction(FCommentMenu, 'actCnEditorCodeToggleComment', btToggleComment);
  if FindIDEAction('actCnCommentCropperWizard') <> nil then
  begin
    AddSepMenuItem(FCommentMenu);
    AddMenuItemWithAction(FCommentMenu, 'actCnCommentCropperWizard', btCommentCropper);
  end;

  // ����Ƕ��˵�
  FWrapMenu := AddMenuItem(Items, SCnSrcBlockWrap, nil);
  FCodeWrap.InitMenuItems(FWrapMenu);

  // ���滻�˵�
  FReplaceMenu := AddMenuItem(Items, SCnSrcBlockReplace, nil);
  FGroupReplace.InitMenuItems(FReplaceMenu);

  // Web �����˵�
  FWebSearchMenu := AddMenuItem(Items, SCnSrcBlockSearch, nil);
  FWebSearch.InitMenuItems(FWebSearchMenu);

  // �����˵�
  FMiscMenu := AddMenuItem(Items, SCnSrcBlockMisc, nil);
  AddMenuItemWithAction(FMiscMenu, 'actCnCodeFormatterWizardFormatCurrent', btFormatCode);
  AddMenuItemWithAction(FMiscMenu, 'actCnEditorCodeSwap', btCodeSwap);
  AddMenuItemWithAction(FMiscMenu, 'actCnEditorCodeToString', btCodeToString);
  AddMenuItemWithAction(FMiscMenu, 'actCnEditorInsertColor', btInsertColor);
  AddMenuItemWithAction(FMiscMenu, 'actCnEditorInsertTime', btInsertDateTime);
  AddMenuItemWithAction(FMiscMenu, 'actCnEditorSortLines', btSortLines);
  AddMenuItemWithAction(FMiscMenu, 'actCnEditorSortUsesList', btSortUsesList);

{$IFDEF BDS} // Only for BDS because of bug. ;-(
  DoAddMenuItem(FMiscMenu, SCnSrcBlockMoveUp, btBlockMoveUp, FBlockMoveUpShortCut.ShortCut);
  DoAddMenuItem(FMiscMenu, SCnSrcBlockMoveDown, btBlockMoveDown, FBlockMoveDownShortCut.ShortCut);
  DoAddMenuItem(FMiscMenu, SCnSrcBlockDeleteLines, btBlockDelLines, FBlockDelLinesShortCut.ShortCut);
{$ENDIF}

  AddSepMenuItem(FMiscMenu);
  DoAddMenuItem(FMiscMenu, SCnWizConfigCaption, btShortCutConfig);

  // ���ò˵�
  AddSepMenuItem(Items);
  Item := AddMenuItem(Items, SCnEditorEnhanceConfig, OnEnhConfig);
  Item.ImageIndex := CnWizardMgr.ImageIndexByWizardClassNameAndCommand('TCnIdeEnhanceMenuWizard',
    SCnIdeEnhanceMenuCommand + 'TCnSrcEditorEnhance');
end;

procedure TCnSrcEditorBlockTools.OnPopup(Sender: TObject);
begin
  if FCommentMenu <> nil then
    FCommentMenu.Visible := (FCommentMenu.Count > 0) and CurrentIsSource;
  if FWrapMenu <> nil then
    FWrapMenu.Visible := (FWrapMenu.Count > 0) and CurrentIsSource;
  if FReplaceMenu <> nil then
    FReplaceMenu.Visible := FReplaceMenu.Count > 0;
  if FMiscMenu <> nil then
    FMiscMenu.Visible := FMiscMenu.Count > 0;
end;

procedure TCnSrcEditorBlockTools.ShowFlatButton(EditWindow: TCustomForm; 
  EditControl: TControl; EditView: IOTAEditView);
var
  IsColor: Boolean;
  AColor: TColor;
  Button: TCnWizFlatButton;
  X, Y, E: Integer;
  StartingRow, EndingRow: Integer;
  S: string;
{$IFDEF BDS}
  ElidedStartingRows, ElidedEndingRows, I, RowEnd: Integer;
{$ENDIF}
{$IFDEF IDE_SYNC_EDIT_BLOCK}
  SyncBtn: TControl;
{$ENDIF}
begin
  Button := TCnWizFlatButton(FindComponentByClass(EditWindow, TCnWizFlatButton,
    SCnSrcEditorBlockButton));
  if Assigned(EditView) and EditView.Block.IsValid then
  begin
    if Button = nil then
    begin
      Button := TCnWizFlatButton.Create(EditWindow);
      Button.Name := SCnSrcEditorBlockButton;
      Button.Image := FIcon;
      Button.DropdownMenu := FPopupMenu;
      Button.AutoDropdown := False;
      Button.Hint := SCnSrcBlockToolsHint;
      // BDS �� Parent �� EditControl.Parent �Ͽ��ܵ��� ModelMaker Explorer
      // �������Զ������жϴ���
      // D5 �� Parent �� EditControl �Ͽ��ܵ��°�ťˢ�²���ȷ
      // �������߷ֿ�����
    {$IFDEF BDS}
      Button.Parent := TWinControl(EditControl);
    {$ELSE}
      Button.Parent := EditControl.Parent;
    {$ENDIF}
    end;

    // ֻ���ұ���Ļ��ѡ�еĿ����
    StartingRow := EditView.Block.StartingRow;
    EndingRow := EditView.Block.EndingRow;
{$IFDEF DEBUG}
    CnDebugger.LogFmt('EditorBlock Tool EditView: Start %d, End %d.', [EditView.TopRow, EditView.BottomRow]);
    CnDebugger.LogFmt('EditorBlock Tool Selection: Start %d, End %d.', [StartingRow, EndingRow]);
{$ENDIF}

{$IFDEF BDS} // ֻ�� BDS ���д����۵�����ʱ�����¼���
    ElidedStartingRows := 0;
    ElidedEndingRows := 0;
    RowEnd := Max(EditView.BottomRow, EndingRow);
    for I := EditView.TopRow to RowEnd do
    begin
      if EditControlWrapper.GetLineIsElided(EditControl, I) then
      begin
        // ����Ļ����ʼ�����Ƿ��������أ��о͵�����Ӱ���������е�λ��
        if I < StartingRow then Inc(ElidedStartingRows);
        if I < EndingRow then Inc(ElidedEndingRows);
      end;
    end;
    
    // ����õ�ʵ����ʼ����
    Dec(StartingRow, ElidedStartingRows);
    Dec(EndingRow, ElidedEndingRows);
{$IFDEF DEBUG}
    CnDebugger.LogFmt('EditorBlock Tool Remove Elided: Start %d, End %d.', [StartingRow, EndingRow]);
{$ENDIF}
{$ENDIF}

    // Parent ��ͬ��Ҫ�ֿ�����
{$IFDEF BDS}
    Y := ((StartingRow + EndingRow) div 2 -
      EditView.TopRow) * EditControlWrapper.GetCharHeight;
    Y := TrimInt(Y, 0, EditControl.ClientHeight - Button.Height);
    X := csLeftKeep;

  {$IFDEF IDE_SYNC_EDIT_BLOCK}
    // ������﷨�༭��ť����λ�ó�ͻ�����������ťλ��
    SyncBtn := GetCurrentSyncButton;
    if (SyncBtn <> nil) and SyncBtn.Visible then
    begin
      if (Y >= SyncBtn.Top) and (Y - SyncBtn.Top < Button.Height + 2) then
      begin
        // ������ť���﷨��ť֮���Ҿ���Ͻ��������ƶ��㹻����
        Y := SyncBtn.Top + SyncBtn.Height + 2;
      end
      else if (Y <= SyncBtn.Top) and (SyncBtn.Top - Y < Button.Height + 2) then
      begin
        // ������ť���﷨��ť֮���Ҿ���Ͻ��������ƶ��㹻����
        Y := SyncBtn.Top - Button.Height - 2;
        if Y < 1 then  // ���̫�����ˣ��򻻳���һ�ֵ����취
          Y := SyncBtn.Top + SyncBtn.Height + 2;
      end;
    end;
  {$ENDIF}
{$ELSE}
    Y := ((StartingRow + EndingRow) div 2 -
      EditView.TopRow) * EditControlWrapper.GetCharHeight + EditControl.Top;
    Y := TrimInt(Y, EditControl.Top, EditControl.Top +
      EditControl.ClientHeight - Button.Height);
    X := EditControl.Left + csLeftKeep;
{$ENDIF}
    if Y <> Button.Top then
      Button.Top := Y;
    if X <> Button.Left then
      Button.Left := X;

    // �ж�ѡ�����Ƿ�����ɫ����������Ԥ��
    if FShowColor then
    begin
      IsColor := False;
      S := Trim(EditView.Block.Text);
      if IdentToColor(S, Longint(AColor)) then
        IsColor := True
      else
      begin
        if (Length(S) = 6) or (Length(S) = 8) then
        begin
          Val('$' + S, Integer(AColor), E);
          if E = 0 then
            IsColor := True;
        end
        else if (Length(S) = 7) or (Length(S) = 9) and (S[1] = '$') then
        begin
          Val(S, Integer(AColor), E);
          if E = 0 then
            IsColor := True;
        end;
      end;

      if IsColor then
        Button.DisplayColor := AColor;
      Button.ShowColor := IsColor;
    end
    else
      Button.ShowColor := False;

    if not Button.Visible then
    begin
      Button.Visible := True;
      Button.Enabled := True;
      Button.IsDropdown := False;
      Button.IsMouseEnter := False;
      Button.BringToFront;
    end;
  end
  else if (Button <> nil) and Button.Visible then
  begin
    Button.Visible := False;
  end;
end;

procedure TCnSrcEditorBlockTools.EditorChanged(Editor: TEditorObject;
  ChangeType: TEditorChangeTypes);
begin
  if CanShowButton and (ChangeType * [ctView, ctWindow, ctCurrLine, ctFont,
    ctVScroll, ctBlock] <> []) then
  begin
    ShowFlatButton(Editor.EditWindow, Editor.EditControl,
      Editor.EditView);
  end;
end;

procedure TCnSrcEditorBlockTools.UpdateFlatButtons;
var
  I: Integer;
  Button: TCnWizFlatButton;
begin
  with EditControlWrapper do
  begin
    for I := 0 to EditorCount - 1 do
    begin
      Button := TCnWizFlatButton(FindComponentByClass(Editors[i].EditWindow,
        TCnWizFlatButton, SCnSrcEditorBlockButton));
      if Button <> nil then
      begin
        if not CanShowButton then
          Button.Free
        else
        begin
          Button.Hint := SCnSrcBlockToolsHint;
        end;
      end;
    end;
  end;
end;

//------------------------------------------------------------------------------
// �������
//------------------------------------------------------------------------------

procedure TCnSrcEditorBlockTools.DoEnhConfig;
begin
  if Assigned(FOnEnhConfig) then
    FOnEnhConfig(Self);
end;

procedure TCnSrcEditorBlockTools.LanguageChanged(Sender: TObject);
begin
  UpdateMenu(FPopupMenu.Items);
  UpdateFlatButtons;
  FWebSearch.LanguageChanged(Sender);
end;

const
  csBlockTools = 'BlockTools';
  csShowBlockTools = 'ShowBlockTools';
  csShowColor = 'ShowColor';
  csTabIndent = 'TabIndent';

procedure TCnSrcEditorBlockTools.LoadSettings(Ini: TCustomIniFile);
begin
  FShowBlockTools := Ini.ReadBool(csBlockTools, csShowBlockTools, FShowBlockTools);
  FShowColor := Ini.ReadBool(csBlockTools, csShowColor, FShowColor);
  FTabIndent := Ini.ReadBool(csBlockTools, csTabIndent, True);
end;

procedure TCnSrcEditorBlockTools.SaveSettings(Ini: TCustomIniFile);
begin
  Ini.WriteBool(csBlockTools, csShowBlockTools, FShowBlockTools);
  Ini.WriteBool(csBlockTools, csShowColor, FShowColor);
  Ini.WriteBool(csBlockTools, csTabIndent, FTabIndent);  
end;

procedure TCnSrcEditorBlockTools.ResetSettings(Ini: TCustomIniFile);
begin

end;

//------------------------------------------------------------------------------
// ���Զ�д
//------------------------------------------------------------------------------

function TCnSrcEditorBlockTools.CanShowButton: Boolean;
begin
  Result := Active and ShowBlockTools;
end;

procedure TCnSrcEditorBlockTools.SetActive(const Value: Boolean);
begin
  if FActive <> Value then
  begin
    FActive := Value;
    UpdateFlatButtons;
  end;
end;

procedure TCnSrcEditorBlockTools.SetShowBlockTools(Value: Boolean);
begin
  if FShowBlockTools <> Value then
  begin
    FShowBlockTools := Value;
    UpdateFlatButtons;
  end;
end;

procedure TCnSrcEditorBlockTools.DoShortCutConfig;
var
  I: Integer;
  List: TList;
  Holder: TCnShortCutHolder;
begin
  List := TList.Create;
  try
    Holder := TCnShortCutHolder.Create(SCnSrcBlockDuplicate, FDupShortCut);
    List.Add(Holder);
    Holder := TCnShortCutHolder.Create(SCnSrcBlockLowerCase, FLowerCaseShortCut);
    List.Add(Holder);
    Holder := TCnShortCutHolder.Create(SCnSrcBlockUpperCase, FUpperCaseShortCut);
    List.Add(Holder);
    Holder := TCnShortCutHolder.Create(SCnSrcBlockToggleCase, FToggleCaseShortCut);
    List.Add(Holder);

{$IFDEF BDS}
    Holder := TCnShortCutHolder.Create(SCnSrcBlockMoveUp, FBlockMoveUpShortCut);
    List.Add(Holder);
    Holder := TCnShortCutHolder.Create(SCnSrcBlockMoveDown, FBlockMoveDownShortCut);
    List.Add(Holder);
    Holder := TCnShortCutHolder.Create(SCnSrcBlockDeleteLines, FBlockDelLinesShortCut);
    List.Add(Holder);
{$ENDIF}

    if ShowShortCutConfigForHolders(List, SCnSrcBlockToolsHint, 'CnSrcEditorEnhance') then
      UpdateMenu(FPopupMenu.Items);;
  finally
    for I := List.Count - 1 downto 0 do
      TCnShortCutHolder(List[I]).Free;
    List.Free;
  end;
end;

procedure TCnSrcEditorBlockTools.SetShowColor(const Value: Boolean);
begin
  if FShowColor <> Value then
  begin
    FShowColor := Value;
    UpdateFlatButtons;
  end;
end;

{$ENDIF CNWIZARDS_CNSRCEDITORENHANCE}
end.

