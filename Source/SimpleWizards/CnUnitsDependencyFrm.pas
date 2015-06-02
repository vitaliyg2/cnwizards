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

unit CnUnitsDependencyFrm;
{ |<PRE>
================================================================================
* 软件名称：CnPack IDE 专家包
* 单元名称：引用单元清理结果窗体
* 单元作者：周劲羽 (zjy@cnpack.org)
* 备    注：
* 开发平台：PWinXP SP2 + Delphi 5.01
* 兼容测试：PWin9X/2000/XP + Delphi 5/6/7 + C++Builder 5/6
* 本 地 化：该窗体中的字符串支持本地化处理方式
* 单元标识：$Id$
* 修改记录：2005.08.11 V1.0
*               创建单元
================================================================================
|</PRE>}

interface

{$I CnWizards.inc}

{$MESSAGE '-oVG TEST ONLY'}
{$DEFINE CNWIZARDS_CNUNITSDEPENDENCY}
{$IFDEF CNWIZARDS_CNUNITSDEPENDENCY}

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs,
  StdCtrls, ComCtrls, Contnrs, ToolsAPI, CnCommon, CnWizMultiLang,
  CnDCU32, CnWizShareImages, CnWizConsts, Menus, Clipbrd, CnPopupMenu;

type
  TCnUnitsDependecyForm = class(TCnTranslateForm)
    chktvResult: TTreeView;
    lbl1: TLabel;
    btnClean: TButton;
    btnCancel: TButton;
    btnHelp: TButton;
    pmList: TPopupMenu;
    mniSelAll: TMenuItem;
    mniSelNone: TMenuItem;
    mniSelInvert: TMenuItem;
    N2: TMenuItem;
    mniCopyName: TMenuItem;
    mniDefault: TMenuItem;
    N3: TMenuItem;
    N4: TMenuItem;
    mniSameSel: TMenuItem;
    mniSameNone: TMenuItem;
    procedure pmListPopup(Sender: TObject);
    procedure btnHelpClick(Sender: TObject);
  private
    { Private declarations }
    List: TObjectList;
    FSelection: TTreeNode;
  protected
    function GetHelpTopic: string; override;
  public
    { Public declarations }
  end;

{$ENDIF CNWIZARDS_CNUNITSDEPENDENCY}

implementation

{$IFDEF CNWIZARDS_CNUNITSDEPENDENCY}

{$R *.DFM}

const
  IdxProject = 76;
  IdxUnit = 78;
  IdxUses = 73;
  IdxIntf = 73;
  IdxImpl = 73;

  SCnIntfCaption = 'Interface';
  SCnImplCaption = 'Implementation';

{ TCnUsesCleanResultForm }

procedure TCnUnitsDependecyForm.pmListPopup(Sender: TObject);
var
  Bl: Boolean;
begin
  FSelection := chktvResult.Selected;
  Bl := FSelection <> nil;
  mniCopyName.Enabled := Bl;
  Bl := Bl and (FSelection.Data <> nil) and (TObject(FSelection.Data) is TCnUsesItem);
  mniSameSel.Enabled := Bl;
  mniSameNone.Enabled := Bl;
end;


function TCnUnitsDependecyForm.GetHelpTopic: string;
begin
  Result := 'CnUnitsDependency';
end;

procedure TCnUnitsDependecyForm.btnHelpClick(Sender: TObject);
begin
  ShowFormHelp;
end;

{$ENDIF CNWIZARDS_CNUNITSDEPENDENCY}
end.

