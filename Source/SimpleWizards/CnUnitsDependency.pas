{******************************************************************************}
{                       CnPack For Delphi/C++Builder                           }
{                     �й����Լ��Ŀ���Դ�������������                         }
{                   (C)Copyright 2001-2015 CnPack ������                       }
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
  CnWizOptions, mPasLex, Math, TypInfo,
  System.IOUtils, System.Types;

type
  TCnUnitsDependency = class(TCnMenuWizard)
  private
    FIgnoreInit: Boolean;
    FIgnoreReg: Boolean;
    FIgnoreNoSrc: Boolean;
    FIgnoreCompRef: Boolean;
    FIgnoreList: TStringList;
    FCleanList: TStringList;
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
  FIgnoreInit := True;
  FIgnoreReg := True;
  FIgnoreNoSrc := False;
  FIgnoreCompRef := True;
  FIgnoreList := TStringList.Create;
  FCleanList := TStringList.Create;
end;

destructor TCnUnitsDependency.Destroy;
begin
  FCleanList.Free;
  FIgnoreList.Free;
  inherited;
end;

procedure TCnUnitsDependency.Execute;
var
  List: TObjectList;
begin
  if CnOtaGetProjectGroup <> nil then
  begin
    if not CompileUnits() then
    begin      {$MESSAGE '-oVG TEST ONLY SCnUsesCleanerCompileFail'}
      ErrorDlg(SCnUsesCleanerCompileFail);
      Exit;
    end;

    // ���з���
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
  DcuPath: string;
  DcuName: string;

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
    i, j: Integer;
    UsesInfo: TCnUnitUsesInfo;
    TextFile: TFileStream;
    Writer: TStreamWriter;
    DcuFLPs: TStringDynArray;
  begin
    DcuPath := GetProjectDcuPath(Project);
    DcuFLPs := TDirectory.GetFiles(DcuPath, '*.dcu');
    TextFile := TFileStream.Create(TPath.Combine(DcuPath, 'Dependency.txt'), fmCreate);
    Writer := TStreamWriter.Create(TextFile);
    try
      for i := 0 to Length(DcuFLPs) - 1 do
      begin
        DcuName := DcuFLPs[i];
        if not FileExists(DcuName) then
          Continue;
        UsesInfo := TCnUnitUsesInfo.Create(DcuName);
        try
          UsesInfo.Sort;
          Writer.WriteLine(DcuName);
          Writer.WriteLine('|Interface');
          for j := 0 to UsesInfo.IntfUsesCount - 1 do
          begin
            Writer.WriteLine('||'+UsesInfo.IntfUses[j]);
          end;
          Writer.WriteLine('|Implementation');
          for j := 0 to UsesInfo.ImplUsesCount - 1 do
          begin
            Writer.WriteLine('||'+UsesInfo.ImplUses[j]);
          end;
          Writer.WriteLine('');
          //WriteUsesInfoXML()
        finally
          FreeAndNil(UsesInfo);
        end;
      end;
    finally
      FreeAndNil(Writer);
      FreeAndNil(TextFile);
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
