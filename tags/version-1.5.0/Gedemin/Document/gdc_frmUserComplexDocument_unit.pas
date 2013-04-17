
unit gdc_frmUserComplexDocument_unit;

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs,
  gdc_frmMDHGR_unit, Db, Menus, ActnList, Grids, DBGrids, gsDBGrid,
  gsIBGrid, ToolWin, ComCtrls, ExtCtrls, TB2Item, TB2Dock, TB2Toolbar,
  IBCustomDataSet, gdcBase, gdcClasses, IBDatabase, gdcTree, gd_MacrosMenu,
  StdCtrls;

type
  Tgdc_frmUserComplexDocument = class(Tgdc_frmMDHGR)
    gdcUserDocumentLine: TgdcUserDocumentLine;
    gdcUserDocument: TgdcUserDocument;
    actCreateEntry: TAction;
    TBItem1: TTBItem;
    actGotoEntry: TAction;
    TBItem2: TTBItem;
    actMainGotoEntry: TAction;
    TBItem3: TTBItem;
    procedure FormCreate(Sender: TObject);
    procedure actCreateEntryExecute(Sender: TObject);
    procedure actGotoEntryExecute(Sender: TObject);
    procedure actMainGotoEntryExecute(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
    class function CreateAndAssign(AnOwner: TComponent): TForm; override;
    class function GetSubTypeList(SubTypeList: TStrings): Boolean; override;
  end;

var
  gdc_frmUserComplexDocument: Tgdc_frmUserComplexDocument;

implementation

{$R *.DFM}

uses
  dmDatabase_unit,
  gd_ClassList,
  gdc_frmTransaction_unit
  {must be placed after Windows unit!}
  {$IFDEF LOCALIZATION}
    , gd_localization_stub
  {$ENDIF}
  ;

{ Tgdc_frmUserComplexDocument }

class function Tgdc_frmUserComplexDocument.CreateAndAssign(
  AnOwner: TComponent): TForm;
begin
  Result := nil;
end;

procedure Tgdc_frmUserComplexDocument.FormCreate(Sender: TObject);
begin
//  gdcUserDocument.SubType := FSubType;
//  gdcUserDocumentLine.SubType := FSubType;

  gdcObject := gdcUserDocument;
  //gdcObject.SubType := FSubType;

  gdcDetailObject := gdcUserDocumentLine;
  gdcDetailObject.SubType := FSubType;
  gdcDetailObject.SubSet := 'ByParent';

  inherited;

  gdcDetailObject.Open;

  Caption := gdcUserDocument.DocumentName[True];
end;

class function Tgdc_frmUserComplexDocument.GetSubTypeList(
  SubTypeList: TStrings): Boolean;
begin
  Result := TgdcUserDocument.GetSubTypeList(SubTypeList);
end;

procedure Tgdc_frmUserComplexDocument.actCreateEntryExecute(
  Sender: TObject);
var
  DidActivate: Boolean;
begin
  inherited;
  if MessageBox(HANDLE, '�������� �������� �� ������ ����������?', '��������',
       mb_YesNo or mb_IconQuestion or mb_TaskModal) = idNo then
    exit;
  DidActivate := not gdcObject.Transaction.InTransaction;
  if DidActivate then
    gdcObject.Transaction.StartTransaction;
  try
    try
      if gdcObject.EOF then
        gdcObject.Prior;
      while not gdcObject.EOF do
      begin
        (gdcObject as TgdcDocument).CreateEntry;
        gdcObject.Next;
      end;
    except
      if DidActivate and gdcObject.Transaction.InTransaction then
        gdcObject.Transaction.Rollback;
      raise;
    end;
  finally
    if DidActivate and gdcObject.Transaction.InTransaction then
      gdcObject.Transaction.Commit;
  end;
end;

procedure Tgdc_frmUserComplexDocument.actGotoEntryExecute(Sender: TObject);
begin

  if Self.gdcDetailObject.FieldByName('transactionkey').AsInteger > 0 then
  begin
    with Tgdc_frmTransaction.CreateAndAssign(Application) as Tgdc_frmTransaction do
    begin
      cbGroupByDocument.Checked := False;
      tvGroup.GoToID(Self.gdcDetailObject.FieldByName('transactionkey').AsInteger);
      gdcAcctViewEntryRegister.Locate('DOCUMENTKEY', Self.gdcDetailObject.FieldByName('id').AsInteger, []);
      Show;
    end;
  end
  else
  begin
    MessageBox(HANDLE, '�� ������ ������� �� ����������� ��������.', '��������',
      mb_OK or mb_IconInformation);
  end;
end;

procedure Tgdc_frmUserComplexDocument.actMainGotoEntryExecute(
  Sender: TObject);
begin
  if Self.gdcObject.FieldByName('transactionkey').AsInteger > 0 then
  begin
    with Tgdc_frmTransaction.CreateAndAssign(Application) as Tgdc_frmTransaction do
    begin
      cbGroupByDocument.Checked := False;
      tvGroup.GoToID(Self.gdcObject.FieldByName('transactionkey').AsInteger);
      gdcAcctViewEntryRegister.Locate('DOCUMENTKEY', Self.gdcObject.FieldByName('id').AsInteger, []);
      Show;
    end;
  end
  else
  begin
    MessageBox(HANDLE, '�� ������ ������� �� ����������� ��������.', '��������',
      mb_OK or mb_IconInformation);
  end;
end;

initialization
  RegisterFrmClass(Tgdc_frmUserComplexDocument);

finalization
  UnRegisterFrmClass(Tgdc_frmUserComplexDocument);

end.