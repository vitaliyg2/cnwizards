{******************************************************************************}
{                       CnPack For Delphi/C++Builder                           }
{                     中国人自己的开放源码第三方开发包                         }
{                   (C)Copyright 2001-2018 CnPack 开发组                       }
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

unit CnProjectOpenFileFrm;
{ |<PRE>
================================================================================
* 软件名称：CnPack IDE 专家包
* 单元名称：工程组单元列表单元
* 单元作者：张伟（Alan） BeyondStudio@163.com
* 备    注：
* 开发平台：PWinXPPro + Delphi 5.01
* 兼容测试：PWin9X/2000/XP + Delphi 5/6/7 + C++Builder 5/6
* 本 地 化：该窗体中的字符串均符合本地化处理方式
* 单元标识：$Id$
* 修改记录：2018.3.28 V2.3
*               跟随基类重构以支持模糊匹配
*           2015.1.17 V2.2
*               允许显示工程中类型为 Unknown 的文件
*           2004.2.22 V2.1
*               重写所有代码
*           2004.2.18 V2.0 by Leeon
*               更改两个列表框架
*           2003.11.18 V1.9
*               修正打开单元后光标不出现的问题
*           2003.11.16 V1.8
*               新增打开多个文件时是否提示的功能
*           2003.10.30 V1.7 by yygw
*               修正排序后窗体显示时有时不能显示当前单元的问题
*           2003.10.16 V1.6
*               新增自动选择当前打开的单元并使之可见
*           2003.8.08 V1.5
*               删除显示代码行的功能
*           2003.6.28 V1.4
*               将 Record 类型改成了 class 类型，修复了一些错误
*           2003.6.26 V1.3
*               新增挂接 IDE 功能
*           2003.6.17 V1.2
*               新增显示文件属性、优化了大量代码
*           2003.6.6 V1.1
*               新增匹配输入功能
*           2003.5.28 V1.0
*               创建单元
================================================================================
|</PRE>}

interface

{$I CnWizards.inc}
{$DEFINE CNWIZARDS_CNPROJECTEXTWIZARD}
{$IFDEF CNWIZARDS_CNPROJECTEXTWIZARD}

uses
  Windows, Messages, SysUtils, Classes, Controls, Forms, Dialogs, Contnrs,
{$IFDEF COMPILER6_UP}
  StrUtils,
{$ENDIF}
  ComCtrls, StdCtrls, ExtCtrls, Math, ToolWin, Clipbrd, IniFiles, ToolsAPI,
  Graphics, ImgList, ActnList, CnStrings, CnCommon, CnConsts, CnWizConsts,
  CnWizOptions, CnWizUtils, CnIni, CnWizIdeUtils, CnWizMultiLang,
  CnProjectViewBaseFrm, CnWizEditFiler, System.Actions;

type

  TCnUnitType = (utUnknown, utProject, utPackage, utDataModule, utForm, utUnit,
    utAsm, utC, utH, utRC);

  TCnUnitInfo = class(TCnBaseElementInfo)
  private
    FIsOpened: Boolean;
    FSize: Integer;
    FImageIndex: Integer;
    FFileName: string;
    FProject: string;
    FUnitType: TCnUnitType;
    FRelPath: string;
  public
    property FileName: string read FFileName write FFileName;
    property RelPath: string read FRelPath write FRelPath;
    property Project: string read FProject write FProject;
    property Size: Integer read FSize write FSize;
    property UnitType: TCnUnitType read FUnitType write FUnitType;
    property IsOpened: Boolean read FIsOpened write FIsOpened;
    property ImageIndex: Integer read FImageIndex write FImageIndex;
  end;

//==============================================================================
// 工程组单元列表窗体
//==============================================================================

{ TCnProjectViewUnitsForm }

  TCnProjectOpenFileForm = class(TCnProjectViewBaseForm)
    tmrReadFiles: TTimer;
    procedure StatusBarDrawPanel(StatusBar: TStatusBar;
      Panel: TStatusPanel; const Rect: TRect);
    procedure lvListData(Sender: TObject; Item: TListItem);
    procedure tmrReadFilesTimer(Sender: TObject);
    procedure cbbProjectListChange(Sender: TObject);
    procedure FormCreate(Sender: TObject);
  private
    FSearchPaths: TStringList;
    FProjectInterfaceList: TInterfaceList;
    FCurrentFindFileProjectInfo: TCnProjectInfo;
    FCurrentFindFileProjectPath: string;

    procedure FillUnitInfo(AInfo: TCnUnitInfo);
    procedure DoFindFile(const aFileName: string; const Info: TSearchRec; var Abort: Boolean);
  protected
    function DoSelectOpenedItem: string; override;
    function GetSelectedFileName: string; override;
    procedure UpdateStatusBar; override;
    procedure OpenSelect; override;
    function GetHelpTopic: string; override;
    procedure CreateList; override;
    procedure UpdateComboBox; override;
    procedure DrawListPreParam(Item: TListItem; ListCanvas: TCanvas); override;
    
    function CanMatchDataByIndex(const AMatchStr: string; AMatchMode: TCnMatchMode;
      DataListIndex: Integer; MatchedIndexes: TList): Boolean; override;
    function SortItemCompare(ASortIndex: Integer; const AMatchStr: string;
      const S1, S2: string; Obj1, Obj2: TObject; SortDown: Boolean): Integer; override;
    procedure UpdateDataList;
  public
    destructor Destroy; override;
  end;

const
  SUnitTypes: array[TCnUnitType] of string =
    ('Unknown', 'Project', 'Package', 'DataModule', 'Unit(Form)', 'Unit',
     'Asm ','C', 'H', 'RC');
  SNotSaved = 'Not Saved';
  csVGOpenFile = 'VGOpenFile';

  csUnitImageIndexs: array[TCnUnitType] of Integer =
    (26, 76, 77, 73, 67, 78, 79, 80, 81, 89); // 26 means unknown

function ShowProjectOpenFile(Ini: TCustomIniFile; out Hooked: Boolean): Boolean;

{$ENDIF CNWIZARDS_CNPROJECTEXTWIZARD}

implementation

{$IFDEF CNWIZARDS_CNPROJECTEXTWIZARD}

{$R *.DFM}

{$IFDEF DEBUG}
uses
  CnDebug;
{$ENDIF}

{ TCnProjectViewUnitsForm }

function ShowProjectOpenFile(Ini: TCustomIniFile; out Hooked: Boolean): Boolean;
begin
  with TCnProjectOpenFileForm.Create(nil) do
  begin
    try
      ShowHint := WizOptions.ShowHint;
      LoadSettings(Ini, csVGOpenFile);
      Result := ShowModal = mrOk;
      Hooked := actHookIDE.Checked;
      SaveSettings(Ini, csVGOpenFile);
      if Result then
        BringIdeEditorFormToFront;
    finally
      Free;
    end;
  end;
end;

function FindProject(const aProjectList: TInterfaceList; const aProjectFileName: string; out aProject: IOTAProject): Boolean;
var
  i: Integer;
begin
  Assert(Assigned(aProjectList));
  for i := 0 to aProjectList.Count - 1 do
  begin
    aProject := IOTAProject(aProjectList[i]);
    Result := SameText(aProject.FileName, aProjectFileName);
    if Result then
      Exit;
  end;
  Result := False;
end;

//==============================================================================
// 工程组单元列表窗体
//==============================================================================

{ TCnProjectViewUnitsForm }

function TCnProjectOpenFileForm.SortItemCompare(ASortIndex: Integer;
  const AMatchStr, S1, S2: string; Obj1, Obj2: TObject; SortDown: Boolean): Integer;
var
  Info1, Info2: TCnUnitInfo;
begin
  Info1 := TCnUnitInfo(Obj1);
  Info2 := TCnUnitInfo(Obj2);

  case ASortIndex of // 因为搜索时只有名称一列参与匹配，因此排序时要考虑到把名称匹配时的全匹配提前
    0:
      begin
        Result := CompareTextWithPos(AMatchStr, Info1.Text, Info2.Text, SortDown);
      end;
    1:
      begin
        Result := CompareText(Info1.RelPath, Info2.RelPath);
        if SortDown then
          Result := -Result;
      end;
    2:
      begin
        Result := CompareValue(Info1.Size, Info2.Size);
        if SortDown then
          Result := -Result;
      end;
    3:
      begin
        Result := CompareText(SUnitTypes[Info1.UnitType], SUnitTypes[Info2.UnitType]);
        if SortDown then
          Result := -Result;
      end;
    4:
      begin
        Result := CompareText(Info1.Project, Info2.Project);
        if SortDown then
          Result := -Result;
      end;
  else
    Result := 0;
  end;
end;

function TCnProjectOpenFileForm.CanMatchDataByIndex(
  const AMatchStr: string; AMatchMode: TCnMatchMode;
  DataListIndex: Integer; MatchedIndexes: TList): Boolean;
var
  Info: TCnUnitInfo;
begin
  Result := False;

  // 先限定工程，工程不符合条件的先剔除
  Info := TCnUnitInfo(DataList.Objects[DataListIndex]);
  if (ProjectInfoSearch <> nil) and (ProjectInfoSearch <> Info.ParentProject) then
    Exit;

  if AMatchStr = '' then
  begin
    Result := True;
    Exit;
  end;

  case AMatchMode of // 搜索时单元名参与匹配，不区分大小写
    mmStart:
      begin
        Result := (Pos(UpperCase(AMatchStr), UpperCase(DataList[DataListIndex])) = 1);
      end;
    mmAnywhere:
      begin
        Result := (Pos(UpperCase(AMatchStr), UpperCase(DataList[DataListIndex])) > 0);
      end;
    mmFuzzy:
      begin
        Result := FuzzyMatchStr(AMatchStr, DataList[DataListIndex], MatchedIndexes);
      end;
  end;
end;

procedure TCnProjectOpenFileForm.cbbProjectListChange(Sender: TObject);
begin
  inherited;
  UpdateDataList;
end;

procedure TCnProjectOpenFileForm.UpdateDataList;
  procedure ProcessProject(const aProjectInfo: TCnProjectInfo);
  var
    IProject: IOTAProject;
    LSearchPaths: TStringList;
    i: Integer;
  begin
    if not FindProject(FProjectInterfaceList, aProjectInfo.FileName, IProject) then
      Exit;

    LSearchPaths := TStringList.Create;
    try
      GetSearchPath(IProject, LSearchPaths);
      for I := 0 to LSearchPaths.Count - 1 do
        if FSearchPaths.IndexOf(LSearchPaths[i]) = -1 then
          FSearchPaths.AddObject(LSearchPaths[i], aProjectInfo);
    finally
      FreeAndNil(LSearchPaths);
    end;
  end;
var
  i: Integer;
begin
  ClearDataList;
  FSearchPaths.Clear;
  if Assigned(ProjectInfoSearch) then
    ProcessProject(ProjectInfoSearch)
  else
    for I := 0 to ProjectList.Count - 1 do
      ProcessProject(TCnProjectInfo(ProjectList[I]));

  tmrReadFiles.Enabled := True;

  inherited;
end;

function TCnProjectOpenFileForm.DoSelectOpenedItem: string;
var
  CurrentModule: IOTAModule;
begin
  CurrentModule := CnOtaGetCurrentModule;
  Result := _CnChangeFileExt(_CnExtractFileName(CurrentModule.FileName), '');
end;

function TCnProjectOpenFileForm.GetSelectedFileName: string;
begin
  if Assigned(lvList.ItemFocused) then
    Result := Trim(TCnUnitInfo(lvList.ItemFocused.Data).FileName);
end;

function TCnProjectOpenFileForm.GetHelpTopic: string;
begin
  Result := 'CnProjectExtViewUnits';
end;

procedure TCnProjectOpenFileForm.FillUnitInfo(AInfo: TCnUnitInfo);
var
  Reader: TCnEditFiler;
begin
  AInfo.IsOpened := CnOtaIsFileOpen(AInfo.FileName);

  Reader := nil;
  try
    try
      if not AInfo.IsOpened then
      begin
        AInfo.Size := GetFileSize(AInfo.FileName);
      end
      else
      begin
        Reader := TCnEditFiler.Create(AInfo.FileName);
        AInfo.Size := Reader.FileSize;
      end;
    except
      AInfo.Size := 0;
    end;
  finally
    Reader.Free;
  end;

  AInfo.ImageIndex := csUnitImageIndexs[AInfo.UnitType];
end;

procedure TCnProjectOpenFileForm.FormCreate(Sender: TObject);
begin
  FSearchPaths := TStringList.Create;
  FSearchPaths.Sorted := True;
  FSearchPaths.Duplicates := dupIgnore;
  FSearchPaths.CaseSensitive := False;

  FProjectInterfaceList := TInterfaceList.Create;

  inherited;
end;

procedure TCnProjectOpenFileForm.OpenSelect;
var
  Item: TListItem;

  procedure OpenItem(const FilePath: string);
  begin
    // CnOtaMakeSourceVisible(FilePath);  // 这样打开可能会导致无 ctView 通知
    // CnOtaOpenFile(FilePath); // 但这样打开Project文件时会导致重新打开所有文件
                                // 并且 BCB 5/6 下会只打开窗体而不打开 CPP 文件

    // 所以必须加上这样的判断，也牺牲了打开Project Source与BCB 5/6 CPP打开时的通知
    if IsDpr(FilePath) or IsPackage(FilePath) or IsBdsProject(FilePath) or
      IsDProject(FilePath) or IsBpr(FilePath) or IsCbProject(FilePath) or IsBpg(FilePath)
      {$IFNDEF BDS} or IsCppSourceModule(FilePath) {$ENDIF} then
    begin
      CnOtaMakeSourceVisible(FilePath);
    end
    else
    begin
      CnOtaOpenFile(FilePath);
    end;
  end;

  procedure OpenSelectedItem;
  var
    I: Integer;
  begin
    BeginBatchOpenClose;
    try
      for I := 0 to Pred(lvList.Items.Count) do
        if lvList.Items.Item[I].Selected then
          OpenItem(TCnUnitInfo(lvList.Items.Item[I].Data).FileName);
    finally
      EndBatchOpenClose;
    end;
  end;

begin
  Item := lvList.Selected;

  if not Assigned(Item) then
    Exit;

  if lvList.SelCount <= 1 then
    OpenItem(TCnUnitInfo(Item.Data).FileName)
  else
  begin
    if actQuery.Checked then
      if not QueryDlg(SCnProjExtOpenUnitWarning, False, SCnInformation) then
        Exit;

    OpenSelectedItem;
  end;

  ModalResult := mrOK;
end;

procedure TCnProjectOpenFileForm.StatusBarDrawPanel(StatusBar: TStatusBar;
  Panel: TStatusPanel; const Rect: TRect);
var
  Item: TListItem;
begin
  Item := lvList.ItemFocused;
  if Assigned(Item) then
  begin
    if FileExists(TCnUnitInfo(Item.Data).FileName) then
      DrawCompactPath(StatusBar.Canvas.Handle, Rect, TCnUnitInfo(Item.Data).FileName)
    else
      DrawCompactPath(StatusBar.Canvas.Handle, Rect,
        TCnUnitInfo(Item.Data).FileName + SCnProjExtNotSave);

    StatusBar.Hint := TCnUnitInfo(Item.Data).FileName;
  end;
end;

procedure TCnProjectOpenFileForm.tmrReadFilesTimer(Sender: TObject);
begin
  if (FSearchPaths.Count = 0) then
  begin
    tmrReadFiles.Enabled := False;
    Exit;
  end;

  FCurrentFindFileProjectInfo := TCnProjectInfo(FSearchPaths.Objects[0]);
  FCurrentFindFileProjectPath := _CnExtractFilePath(FCurrentFindFileProjectInfo.FileName);
  FindFile(MakePath(FSearchPaths[0]), '*.*', DoFindFile, nil, False, False);
  FSearchPaths.Delete(0);
  UpdateListView;
end;

destructor TCnProjectOpenFileForm.Destroy;
begin
  FreeAndNil(FSearchPaths);
  FreeAndNil(FProjectInterfaceList);
  inherited;
end;

procedure TCnProjectOpenFileForm.DoFindFile(const aFileName: string; const Info: TSearchRec; var Abort: Boolean);
var
  UnitInfo: TCnUnitInfo;
begin
  if not (IsSourceModule(aFileName) or IsRC(aFileName) or
    IsInc(aFileName))
  then
    Exit;

  UnitInfo := TCnUnitInfo.Create;
  with UnitInfo do
  begin
    Text := _CnChangeFileExt(_CnExtractFileName(aFileName), '');
    FileName := aFileName;
    RelPath := GetRelativePath(_CnExtractFilePath(aFileName),
      FCurrentFindFileProjectPath);
    UnitInfo.Project := FCurrentFindFileProjectInfo.Name;

  {$IFDEF SUPPORT_MODULETYPE}
    // todo: Check ModuleInfo.ModuleType
  {$ELSE}
    if IsRC(aFileName) then
      UnitType := utRC
    else if (FileExists(ChangeFileExt(aFileName,'.dfm'))) then
      UnitType := utForm
    else if IsPas(aFileName) or IsCpp(aFileName) then
      UnitType := utUnit
    else if IsAsm(aFileName) then
      UnitType := utAsm
    else if IsC(aFileName) then
      UnitType := utC
    else if IsH(aFileName) then
      UnitType := utH
    else
      UnitType := utUnknown;
  {$ENDIF}

    // 未知类型文件不隐藏扩展名
    if UnitType = utUnknown then
      Text := _CnExtractFileName(aFileName);
  end;

  FillUnitInfo(UnitInfo);
  UnitInfo.ParentProject := FCurrentFindFileProjectInfo;
  DataList.AddObject(UnitInfo.Text, UnitInfo);
end;

procedure TCnProjectOpenFileForm.CreateList;
var
  ProjectInfo: TCnProjectInfo;
  UnitInfo: TCnUnitInfo;
  I, J: Integer;
  UnitFileName: string;
  IProject: IOTAProject;
  IModuleInfo: IOTAModuleInfo;
{$IFDEF BDS}
  ProjectGroup: IOTAProjectGroup;
{$ENDIF}
begin
  FProjectInterfaceList.Clear;
  CnOtaGetProjectList(FProjectInterfaceList);
    for I := 0 to FProjectInterfaceList.Count - 1 do
    begin
      IProject := IOTAProject(FProjectInterfaceList[I]);

      if IProject.FileName = '' then
        Continue;

{$IFDEF BDS}
      // BDS 后，ProjectGroup 也支持 Project 接口，因此需要去掉
      if Supports(IProject, IOTAProjectGroup, ProjectGroup) then
        Continue;
{$ENDIF}

      ProjectInfo := TCnProjectInfo.Create;
      ProjectInfo.Name := _CnExtractFileName(IProject.FileName);
      ProjectInfo.FileName := IProject.FileName;

      ProjectList.Add(ProjectInfo);  // ProjectList 中只包含工程信息
    end;

    UpdateDataList;
end;

procedure TCnProjectOpenFileForm.UpdateComboBox;
var
  i: Integer;
  ProjectInfo: TCnProjectInfo;
begin
  with cbbProjectList do
  begin
    Clear;
    Items.Add(SCnProjExtProjectAll);
    Items.Add(SCnProjExtCurrentProject);
    if Assigned(ProjectList) then
    begin
      for i := 0 to ProjectList.Count - 1 do
      begin
        ProjectInfo := TCnProjectInfo(ProjectList[i]);
        Items.AddObject(_CnExtractFileName(ProjectInfo.Name), ProjectInfo);
      end;
    end;
  end;
end;


procedure TCnProjectOpenFileForm.UpdateStatusBar;
begin
  with StatusBar do
  begin
    Panels[1].Text := Format(SCnProjExtProjectCount, [ProjectList.Count]);
    Panels[2].Text := Format(SCnProjExtUnitsFileCount, [lvList.Items.Count]);
  end;
end;

procedure TCnProjectOpenFileForm.DrawListPreParam(Item: TListItem;
  ListCanvas: TCanvas);
begin
  if Assigned(Item) and (Item.Data <> nil) and TCnUnitInfo(Item.Data).IsOpened then
    ListCanvas.Font.Color := clGreen;
end;

procedure TCnProjectOpenFileForm.lvListData(Sender: TObject;
  Item: TListItem);
var
  Info: TCnUnitInfo;
begin
  if (Item.Index >= 0) and (Item.Index < DisplayList.Count) then
  begin
    Info := TCnUnitInfo(DisplayList.Objects[Item.Index]);
    Item.Caption := Info.Text;
    Item.ImageIndex := Info.ImageIndex;
    Item.Data := Info;

    with Item.SubItems do
    begin
      Add(Info.RelPath);
      Add(IntToStrSp(Info.Size));
      Add(SUnitTypes[Info.UnitType]);
      Add(Info.Project);
    end;
  end;
end;

{$ENDIF CNWIZARDS_CNPROJECTEXTWIZARD}
end.


