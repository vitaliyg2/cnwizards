{******************************************************************************}
{                       CnPack For Delphi/C++Builder                           }
{                     �й����Լ��Ŀ���Դ�������������                         }
{                   (C)Copyright 2001-2014 CnPack ������                       }
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

unit CnEditorSortUsesList;
{* |<PRE>
================================================================================
* ������ƣ�CnPack IDE ר�Ұ�
* ��Ԫ���ƣ�����ѡ���й���
* ��Ԫ���ߣ��ܾ��� (zjy@cnpack.org)
* ��    ע��
* ����ƽ̨��PWinXP SP2 + Delphi 5.01
* ���ݲ��ԣ�PWin9X/2000/XP + Delphi 5/6/7 + C++Builder 5/6
* �� �� �����ô����е��ַ��������ϱ��ػ�����ʽ
* ��Ԫ��ʶ��$Id$
* �޸ļ�¼��2005.08.23 V1.0
*               ������Ԫ��ʵ�ֹ���
================================================================================
|</PRE>}

interface

{$I CnWizards.inc}
{$MESSAGE '-oVG TEST ONLY'}
{$DEFINE CNWIZARDS_CNEDITORWIZARD}
{$IFDEF CNWIZARDS_CNEDITORWIZARD}

uses
  Messages, SysUtils,
  Windows, Classes, Graphics, Controls, Forms, Dialogs,
  Variants, Contnrs, StdCtrls, IniFiles, ToolsAPI, CnWizUtils, CnConsts, CnCommon, CnEditorWizard,
  RegExpr, CnWizConsts, CnEditorCodeTool, CnWizXmlUtils, CnWizOptions;

type

{ TCnEditorSortUsesList }

  TCnEditorSortUsesList = class(TCnEditorCodeTool)
  protected
    function ProcessText(const Text: string): string; override;
    function GetStyle: TCnCodeToolStyle; override;
  public
    constructor Create(AOwner: TCnEditorToolsetWizard); override;
    function GetCaption: string; override;
    function GetHint: string; override;
    procedure GetEditorInfo(var Name, Author, Email: string); override;
  end;

{$ENDIF CNWIZARDS_CNEDITORWIZARD}

implementation

{$IFDEF CNWIZARDS_CNEDITORWIZARD}

type
  TUnitGroup = class
  private
    FAcceptAll: Boolean;
    FUnitNames: TStrings;
    FUnitScopeNames: TStrings;
    FFoundUnitNames: TStrings;
    FRegExp: TRegExpr;
  public
    constructor Create(aSettingsNode: IXMLNode);
    destructor Destroy; override;

    function ProcessUnitMatch(const aUnitName: string): Boolean;

    property FoundUnitNames: TStrings read FFoundUnitNames;
  end;

  TUsesUnitListSorter = class
  private
    FUnitGroups: TObjectList;

    procedure LoadSettings;
  public
    constructor Create;
    destructor Destroy; override;

    function Execute(const aUnitsList: string): string;
  end;

{ TCnEditorSortUsesList }

constructor TCnEditorSortUsesList.Create(AOwner: TCnEditorToolsetWizard);
begin
  inherited;
  ValidInSource := False;
  BlockMustNotEmpty := True;
end;

function TCnEditorSortUsesList.ProcessText(const Text: string): string;
var
  UnitGrouper: TUsesUnitListSorter;
begin
  try
    UnitGrouper := TUsesUnitListSorter.Create;
    try
        Result := UnitGrouper.Execute(Text);
    finally
      FreeAndNil(UnitGrouper);
    end;
  except
    on E: Exception do
      Result := E.Message;
  end;
end;

function TCnEditorSortUsesList.GetStyle: TCnCodeToolStyle;
begin
  Result := csLine;
end;

function TCnEditorSortUsesList.GetCaption: string;
begin
  Result := SCnEditorSortUsesListMenuCaption;
end;

function TCnEditorSortUsesList.GetHint: string;
begin
  Result := SCnEditorSortUsesListMenuHint;
end;

procedure TCnEditorSortUsesList.GetEditorInfo(var Name, Author, Email: string);
begin
  Name := SCnEditorSortUsesListName;
  Author := 'github.com/vitaliyg2';
  Email := 'vitaliygrabchuk@gmail.com';
end;

{ TUsesSort }

constructor TUsesUnitListSorter.Create;
begin
  inherited;
  FUnitGroups := TObjectList.Create;

  LoadSettings;
end;

destructor TUsesUnitListSorter.Destroy;
begin
  FreeAndNil(FUnitGroups);
  inherited;
end;

function TUsesUnitListSorter.Execute(const aUnitsList: string): string;
var
  ResultLine: string;

  procedure FlushResultLine(var aFormattedUnitList: string);
  begin
    if (ResultLine = '') then
      Exit;

    if (aFormattedUnitList <> '') then
      aFormattedUnitList := aFormattedUnitList + ',' + sLineBreak;

    aFormattedUnitList := aFormattedUnitList + '  ' + ResultLine;
    ResultLine := '';
  end;

var
  i, j, AvailableLength: Integer;
  Group: TUnitGroup;
  UnitNames: TStringList;
  Name: string;
begin
  UnitNames := TStringList.Create;
  try
    UnitNames.CommaText := StringReplace(aUnitsList, ';', ',', [rfReplaceAll]);
    for i := 0 to UnitNames.Count - 1 do
    begin
      Name := Trim(UnitNames[i]);
      if (Name = '') then
        Continue;

      for j := 0 to FUnitGroups.Count - 1 do
      begin
        Group := TUnitGroup(FUnitGroups[j]);
        if Group.ProcessUnitMatch(Name) then
        begin
          Break;
        end;
      end;
    end;

    Result := '';
    for j := 0 to FUnitGroups.Count - 1 do
    begin
      Group := TUnitGroup(FUnitGroups[j]);

      ResultLine := '';
      for i := 0 to Group.FoundUnitNames.Count - 1 do
      begin
        Name := Group.FoundUnitNames[i];

        AvailableLength := 80 - 2 - Length(ResultLine);
        if (AvailableLength - Length(Name) >= -8) and
          (AvailableLength >= Round(Length(Name)*0.65))
        then
        begin
          if (ResultLine <> '') then
            ResultLine := ResultLine + ', ';

          ResultLine := ResultLine + Name;
        end
        else
        begin
          FlushResultLine(Result);
          ResultLine := Name;
        end;
      end;

      FlushResultLine(Result);
    end;

    if (Result <> '') then
      Result := Result + ';' + sLineBreak;
  finally
    FreeAndNil(UnitNames);
  end;
end;

procedure TUsesUnitListSorter.LoadSettings;
var
  XmlDoc: IXMLDocument;
  GroupNodes: IXMLNodeList;
  i: Integer;
  Settings: TStringList;
begin
  XmlDoc := CreateXMLDoc;
  if not Assigned(XmlDoc) then
    raise ECnWizardException.Create('Failed to create XML document');

  Settings := TStringList.Create;
  try
    if not WizOptions.LoadUserFile(Settings, 'UsesSortSettings.xml') or
      not XmlDoc.loadXML(Settings.Text)
    then
      raise ECnWizardException.Create('Failed to load uses sorter settings');
  finally
    FreeAndNil(Settings);
  end;

  GroupNodes := XmlDoc.selectNodes('settings/group');
  for i := 0 to GroupNodes.length - 1 do
    FUnitGroups.Add(TUnitGroup.Create(GroupNodes.item[i]));

  FUnitGroups.Add(TUnitGroup.Create(nil)); // accept all group
end;

{ TUnitGroup }

constructor TUnitGroup.Create(aSettingsNode: IXMLNode);
var
  RegExpExpr: WideString;
begin
  inherited Create;

  FUnitNames := TStringList.Create;
  TStringList(FUnitNames).CaseSensitive := False;

  FUnitScopeNames := TStringList.Create;
  TStringList(FUnitScopeNames).CaseSensitive := False;

  FFoundUnitNames := TStringList.Create;

  // Load
  if Assigned(aSettingsNode) then
  begin
    FUnitNames.Text := StringReplace(VarToStr(aSettingsNode.text),
      ',', sLineBreak, [rfReplaceAll]);
    TrimStrings(FUnitNames);

    RegExpExpr := GetNodeAttrStr(aSettingsNode, 'pattern', '');
    FUnitScopeNames.Text := StringReplace(
      GetNodeAttrStr(aSettingsNode, 'scope', ''),
      ';', sLineBreak, [rfReplaceAll]);
    TrimStrings(FUnitScopeNames);

    if (RegExpExpr <> '') then
    begin
      FRegExp := TRegExpr.Create;
      FRegExp.Expression := RegExpExpr;
    end;
  end
  else
    FAcceptAll := True;
end;

destructor TUnitGroup.Destroy;
begin
  FreeAndNil(FUnitNames);
  FreeAndNil(FUnitScopeNames);
  FreeAndNil(FFoundUnitNames);
  FreeAndNil(FRegExp);

  inherited;
end;

function TUnitGroup.ProcessUnitMatch(const aUnitName: string): Boolean;
var
  UnitOrderIndex, i, FoundUnitIndex: Integer;
  GroupUnitName: string;
begin
  UnitOrderIndex := -1;

  Result := FAcceptAll;

  if (not Result) then
  begin
    UnitOrderIndex := FUnitNames.IndexOf(aUnitName);
    Result := (UnitOrderIndex <> -1);
    if Result then
      Exit;

    if (FUnitScopeNames.Count = 1) and (FUnitScopeNames[0]= '*') then
    begin
      for i := 0 to FUnitNames.Count - 1 do
      begin
        GroupUnitName := FUnitNames[i];
        Result := SameText(StrRight(GroupUnitName, Length(aUnitName) + 1),
          '.' + aUnitName);

        if Result then
        begin
          UnitOrderIndex := i;
          Break;
        end;
      end;
    end
    else
    begin
      for i := 0 to FUnitScopeNames.Count - 1 do
      begin
        UnitOrderIndex := FUnitNames.IndexOf(FUnitScopeNames[i] + '.' + aUnitName);
        Result := (UnitOrderIndex <> -1);
        if Result then
          Break;
      end;
    end;
  end;

  if (not Result) then
  begin
    Result := (Assigned(FRegExp) and FRegExp.Exec(aUnitName));
  end;

  if Result then
  begin
    if (UnitOrderIndex <> -1) then
      for i := 0 to FFoundUnitNames.Count - 1 do
      begin
        FoundUnitIndex := Integer(FFoundUnitNames.Objects[i]);
        if (FoundUnitIndex = -1) or ((FoundUnitIndex > UnitOrderIndex)) then
        begin
          FFoundUnitNames.InsertObject(i, aUnitName, TObject(UnitOrderIndex));
          Exit;
        end;
      end;

    FFoundUnitNames.AddObject(aUnitName, TObject(UnitOrderIndex));
  end;
end;

initialization
  RegisterCnCodingToolset(TCnEditorSortUsesList);

{$ENDIF CNWIZARDS_CNEDITORWIZARD}
end.
