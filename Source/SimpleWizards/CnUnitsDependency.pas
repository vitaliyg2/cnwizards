{******************************************************************************}
{                       CnPack For Delphi/C++Builder                           }
{                     中国人自己的开放源码第三方开发包                         }
{                   (C)Copyright 2001-2015 CnPack 开发组                       }
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

unit CnUnitsDependency;

interface

{$I CnWizards.inc}

{$MESSAGE '-oVG TEST ONLY'}
{$DEFINE CNWIZARDS_CNUNITSDEPENDENCY}
{$IFDEF CNWIZARDS_CNUNITSDEPENDENCY}

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs,
  StdCtrls, ToolsAPI, IniFiles, Contnrs, CnWizMultiLang, CnWizClasses, CnWizConsts,
  CnCommon, CnConsts, CnWizUtils, CnDCU32, CnWizIdeUtils, CnWizEditFiler,
  CnWizOptions, mPasLex, Math, TypInfo, ComCtrls,
  System.IOUtils, System.Types, CnUnitsDependencyFrm, System.Generics.Collections;

type
  TCnUnitsDependency = class(TCnMenuWizard)
  private
    FResultsForm: TCnUnitsDependecyForm;

    function CompileUnits(): Boolean;
    function ProcessUnits(List: TObjectList): Boolean;
  public
    constructor Create; override;
    destructor Destroy; override;

    procedure LoadSettings(Ini: TCustomIniFile); override;
    procedure SaveSettings(Ini: TCustomIniFile); override;
    function GetState: TWizardState; override;
    class procedure GetWizardInfo(var Name, Author, Email, Comment: string); override;
    function GetCaption: string; override;
    function GetHint: string; override;
    function GetDefShortCut: TShortCut; override;
    procedure Execute; override;
  end;

{$ENDIF}

implementation

{$IFDEF CNWIZARDS_CNUNITSDEPENDENCY}

{$IFDEF DEBUG}
uses
  CnDebug;
{$ENDIF}

const
  csDcuExt = '.dcu';

{ TCnUnitsDependency }

constructor TCnUnitsDependency.Create;
begin
  inherited;
  FResultsForm := TCnUnitsDependecyForm.Create(nil);
end;

destructor TCnUnitsDependency.Destroy;
begin
  FreeAndNil(FResultsForm);
  inherited;
end;

procedure TCnUnitsDependency.Execute;
var
  List: TObjectList;
begin
  if CnOtaGetProjectGroup <> nil then
  begin
    if not CompileUnits() then
    begin
      ErrorDlg(SCnUnitsDependencyCompileFail);
      Exit;
    end;

    // 进行分析
    List := TObjectList.Create;
    try
      if ProcessUnits(List) then  {$MESSAGE '-oVG build uses graph'}
      begin

      end;
    finally
      List.Free;
    end;
  end;
end;

function TCnUnitsDependency.CompileUnits(): Boolean;
var
  Project: IOTAProject;

  function DoCompileProject(AProject: IOTAProject): Boolean;
  begin
    Result := not AProject.ProjectBuilder.ShouldBuild or
      AProject.ProjectBuilder.BuildProject(cmOTAMake, False);
  end;
begin
  Result := False;
  try
    Project := CnOtaGetCurrentProject;
    Assert(Assigned(Project));
    Result := DoCompileProject(Project);
  except
    on E: Exception do
      DoHandleException(E.Message);
  end;
end;

function TCnUnitsDependency.ProcessUnits(List: TObjectList): Boolean;
var
  Module: IOTAModule;
  Project: IOTAProject;

  function GetProjectDcuPath(AProject: IOTAProject): string;
  begin
    if (AProject <> nil) and (AProject.ProjectOptions <> nil) then
    begin
      Result := ReplaceToActualPath(AProject.ProjectOptions.Values['UnitOutputDir'], AProject);
      if Result <> '' then
        Result := MakePath(LinkPath(_CnExtractFilePath(AProject.FileName), Result));
    {$IFDEF DEBUG}
      CnDebugger.LogMsg('GetProjectDcuPath: ' + Result);
    {$ENDIF}
    end
    else
      Result := '';
  end;

  function GetDcuName(const ADcuPath: string; AModule: IOTAModule): string;
  begin
    if ADcuPath = '' then
      Result := _CnChangeFileExt(Module.FileName, csDcuExt)
    else
      Result := _CnChangeFileExt(ADcuPath + _CnExtractFileName(Module.FileName), csDcuExt);
  end;

  function ProcessAProject(AProject: IOTAProject; OpenedOnly: Boolean): Boolean;
  var
    UsesInfos: TObjectList<TCnUnitUsesInfo>;
    ProcessedUnitNames: TStringList;

{$MESSAGE '-oVG TEST ONLY'}
//    function FindUsesInfo(const aUnitName: string; out aUsesInfo: TCnUnitUsesInfo): Boolean;
//    var
//      i: Integer;
//    begin
//      for i := 0 to UsesInfos.Count - 1 do
//      begin
//        aUsesInfo := UsesInfos[i];
//        Result := (aUsesInfo.UnitName = aUnitName);
//        if Result then
//          Exit;
//      end;
//      Result := False;
//    end;

    procedure ProcessUnitInfo(const aUnitName: string; aParentNode: TTreeNode);
      function UsesUnit(aUsesInfo: TCnUnitUsesInfo; const aUnitName: string): Boolean;
      var
        i: Integer;
      begin
        for i := 0 to aUsesInfo.IntfUsesCount - 1 do
        begin
          Result := (aUnitName = aUsesInfo.IntfUses[i]);
          if Result then
            Exit;
        end;

        for i := 0 to aUsesInfo.ImplUsesCount - 1 do
        begin
          Result := (aUnitName = aUsesInfo.ImplUses[i]);
          if Result then
            Exit;
        end;

        Result := False;
      end;
    var
      Node: TTreeNode;
      UsesInfo: TCnUnitUsesInfo;
    begin
      if ProcessedUnitNames.IndexOf(aUnitName) = -1 then
      begin
        ProcessedUnitNames.Add(aUnitName);

        if Assigned(aParentNode) then
          Node := FResultsForm.chktvResult.Items.AddChild(aParentNode, aUnitName)
        else
        begin
          Node := FResultsForm.chktvResult.Items.Add(nil, aUnitName);
          Node.Expanded := True;
        end;
        Node.ImageIndex := 78;
        Node.SelectedIndex := 78;

        for UsesInfo in UsesInfos do
        begin
          if UsesUnit(UsesInfo, aUnitName) then
          begin
            ProcessUnitInfo(UsesInfo.UnitName, Node);
          end;
        end;
      end
      else
      begin
        Node := FResultsForm.chktvResult.Items.AddChild(aParentNode, aUnitName + ' (Duplicate)');
        Node.ImageIndex := 26;
        Node.SelectedIndex := 26;
      end;
    end;

  var
    DcuPath: string;

    procedure AddUsesInfoForUnit(const aUnitName: string; aParentNode: TTreeNode);
      function UnitInfoExists(const aUnitName: string): Boolean;
      var
        UsesInfo: TCnUnitUsesInfo;
      begin
        for UsesInfo in UsesInfos do
        begin
          Result := (UsesInfo.UnitName = aUnitName);
          if Result then
            Exit;
        end;
        Result := False;
      end;
    var
      DcuFLP: string;
      UsesInfo: TCnUnitUsesInfo;
      i: Integer;
      Node: TTreeNode;
    begin
      DcuFLP := TPath.Combine(DcuPath, aUnitName + csDcuExt);
      if not FileExists(DcuFLP) or UnitInfoExists(aUnitName) then
        Exit;

      Node := FResultsForm.chktvResult.Items.AddChild(aParentNode, aUnitName);
      UsesInfo := TCnUnitUsesInfo.Create(DcuFLP);
      try
        UsesInfo.Sort;
      except
        FreeAndNil(UsesInfo);
        raise;
      end;
      UsesInfos.Add(UsesInfo);

      for i := 0 to UsesInfo.IntfUsesCount - 1 do
        AddUsesInfoForUnit(UsesInfo.IntfUses[i], Node);

      for i := 0 to UsesInfo.ImplUsesCount - 1 do
        AddUsesInfoForUnit(UsesInfo.ImplUses[i], Node);
    end;

  var
    i: Integer;
    Module: IOTAModule;
    ModuleInfo: IOTAModuleInfo;
    CurrentUnitName: string;
  begin
    Module := CnOtaGetCurrentModule;
    Result := Assigned(Module);
    if not Result then
      Exit;

    CurrentUnitName := TPath.GetFileNameWithoutExtension(Module.FileName);

    DcuPath := GetProjectDcuPath(Project);

    UsesInfos := TObjectList<TCnUnitUsesInfo>.Create;
    try
      for i := 0 to AProject.GetModuleCount - 1 do
      begin
        ModuleInfo := AProject.GetModule(i);
        if not Assigned(ModuleInfo) then
         Continue;
        AddUsesInfoForUnit(TPath.GetFileNameWithoutExtension(ModuleInfo.FileName), nil);
      end;

      ProcessedUnitNames := TStringList.Create;
      try
        FResultsForm.chktvResult.Items.Clear;
        ProcessUnitInfo(CurrentUnitName, nil);
        if FResultsForm.chktvResult.Items.Count > 0 then
          FResultsForm.chktvResult.Items.GetFirstNode.Expand(False);
        FResultsForm.Show;
      finally
        FreeAndNil(ProcessedUnitNames);
      end;
    finally
      FreeAndNil(UsesInfos);
    end;
    Result := True;
  end;
begin
  Result := False;
  try
    List.Clear;
    Project := CnOtaGetCurrentProject;
    Assert(Assigned(Project));
    Result := ProcessAProject(Project, False);
  except
    on E: Exception do
      DoHandleException(E.Message);
  end;
end;

procedure TCnUnitsDependency.LoadSettings(Ini: TCustomIniFile);
begin
  inherited;
end;

procedure TCnUnitsDependency.SaveSettings(Ini: TCustomIniFile);
begin
  inherited;
end;

function TCnUnitsDependency.GetCaption: string;
begin
  Result := SCnUnitsDependencyMenuCaption;
end;

function TCnUnitsDependency.GetDefShortCut: TShortCut;
begin
  Result := 0;
end;

function TCnUnitsDependency.GetHint: string;
begin
  Result := SCnUnitsDependencyMenuHint;
end;

function TCnUnitsDependency.GetState: TWizardState;
begin
  if CnOtaGetProjectGroup <> nil then
    Result := [wsEnabled]
  else
    Result := [];
end;

class procedure TCnUnitsDependency.GetWizardInfo(var Name, Author, Email,
  Comment: string);
begin
  Name := SCnUnitsDependencyName;
  Author := 'Vitaliy Grabchuk';
  Email := 'vitaliygrabchuk@gmail.com';
  Comment := SCnUnitsDependencyComment;
end;

initialization
  RegisterCnWizard(TCnUnitsDependency);

{$ENDIF CNWIZARDS_CNUNITSDEPENDENCY}
end.
