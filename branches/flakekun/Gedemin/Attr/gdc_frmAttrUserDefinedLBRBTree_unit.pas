
{++


  Copyright (c) 2001 by Golden Software of Belarus

  Module

    gdc_frmAttrUserDefinedTree_unit.pas

  Abstract

    Part of gedemin project.
    View form for user defined tables with tree structure.

  Author

    Denis Romanovski

  Revisions history

    1.0    30.10.2001    Dennis    Initial version.


--}

unit gdc_frmAttrUserDefinedLBRBTree_unit;

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs,
  gdc_frmMDVTree_unit, IBDatabase, Db, Menus, ActnList, Grids, DBGrids,
  gsDBGrid, gsIBGrid, ComCtrls, gsDBTreeView, ToolWin, ExtCtrls, TB2Item,
  TB2Dock, TB2Toolbar, IBCustomDataSet, gdcBase, gdcAttrUserDefined,
  gd_MacrosMenu, StdCtrls, gdcTree;

type
  Tgdc_frmAttrUserDefinedLBRBTree = class(Tgdc_frmMDVTree)
    Master: TgdcAttrUserDefinedLBRBTree;
    Detail: TgdcAttrUserDefinedLBRBTree;

    procedure FormCreate(Sender: TObject);

  private

  public
    constructor Create(AnOwner: TComponent); override;
    class function CreateAndAssign(AnOwner: TComponent): TForm; override;
    class function GetSubTypeList(SubTypeList: TStrings): Boolean; override;

  end;

var
  gdc_frmAttrUserDefinedLBRBTree: Tgdc_frmAttrUserDefinedLBRBTree;

implementation

{$R *.DFM}

uses at_classes,  gd_ClassList;

{ Tgdc_frmAttrUserDefinedTree }

constructor Tgdc_frmAttrUserDefinedLBRBTree.Create(AnOwner: TComponent);
begin
  inherited;
end;

class function Tgdc_frmAttrUserDefinedLBRBTree.CreateAndAssign(
  AnOwner: TComponent): TForm;
begin
  Result := nil;
end;

procedure Tgdc_frmAttrUserDefinedLBRBTree.FormCreate(Sender: TObject);
var
  R: TatRelation;
begin
  gdcObject := Master;
  //gdcObject.SubType := FSubType;

  R := atDatabase.Relations.ByRelationName(FSubType);
  Assert(R <> nil);

  if tvGroup.DisplayField = '' then
    tvGroup.DisplayField := R.ListField.FieldName;

  gdcDetailObject := Detail;
  gdcDetailObject.SubType := FSubType;
  //gdcDetailObject.SubSet := 'ByLBRB';

  inherited;

  with atDatabase.Relations do
  begin
    if ByRelationName(FSubType) <> nil then
      Self.Caption := ByRelationName(FSubType).LName
    else
      Self.Caption := '������ �� ���������!';
  end;
end;

class function Tgdc_frmAttrUserDefinedLBRBTree.GetSubTypeList(
  SubTypeList: TStrings): Boolean;
begin
  Result := TgdcAttrUserDefinedLBRBTree.GetSubTypeList(SubTypeList);
end;

initialization
  RegisterFrmClass(Tgdc_frmAttrUserDefinedLBRBTree);

finalization
  UnRegisterFrmClass(Tgdc_frmAttrUserDefinedLBRBTree);

end.
