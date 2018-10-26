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

unit CnUnitsDependencyFrm;
{ |<PRE>
================================================================================
* ������ƣ�CnPack IDE ר�Ұ�
* ��Ԫ���ƣ����õ�Ԫ����������
* ��Ԫ���ߣ��ܾ��� (zjy@cnpack.org)
* ��    ע��
* ����ƽ̨��PWinXP SP2 + Delphi 5.01
* ���ݲ��ԣ�PWin9X/2000/XP + Delphi 5/6/7 + C++Builder 5/6
* �� �� �����ô����е��ַ���֧�ֱ��ػ�����ʽ
* ��Ԫ��ʶ��$Id$
* �޸ļ�¼��2005.08.11 V1.0
*               ������Ԫ
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

