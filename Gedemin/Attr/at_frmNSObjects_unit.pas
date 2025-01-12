// ShlTanya, 03.02.2019, #4135

unit at_frmNSObjects_unit;

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs,
  gd_createable_form, Db, IBCustomDataSet, IBDatabase, Grids, DBGrids,
  gsDBGrid, gsIBGrid, ComCtrls, ActnList, TB2Dock, TB2Toolbar, dmDatabase_unit,
  dmImages_unit, TB2Item, gdcBase, gdcBaseInterface, Menus, ExtCtrls,
  StdCtrls, gsPeriodEdit;

type
  Tat_frmNSObjects = class(TCreateableForm)
    TBDock: TTBDock;
    tb: TTBToolbar;
    ActionList: TActionList;
    sb: TStatusBar;
    gsIBGrid: TgsIBGrid;
    ibtr: TIBTransaction;
    ibds: TIBDataSet;
    ds: TDataSource;
    actOpenObject: TAction;
    TBItem1: TTBItem;
    actAddToNamespace: TAction;
    TBItem2: TTBItem;
    TBSeparatorItem1: TTBSeparatorItem;
    pm: TPopupMenu;
    pnlTopFilter: TPanel;
    pnlFilterButtons: TPanel;
    btnClearAll: TButton;
    pnlFilter: TPanel;
    actSetFilter: TAction;
    actClearAll: TAction;
    actSetAll: TAction;
    btnSetAll: TButton;
    btnSetFilter: TButton;
    chbxInNS: TCheckBox;
    gsPeriodEdit: TgsPeriodEdit;
    Label1: TLabel;
    procedure FormCreate(Sender: TObject);
    procedure actOpenObjectUpdate(Sender: TObject);
    procedure actOpenObjectExecute(Sender: TObject);
    procedure dsDataChange(Sender: TObject; Field: TField);
    procedure actAddToNamespaceUpdate(Sender: TObject);
    procedure actAddToNamespaceExecute(Sender: TObject);
    procedure actClearAllExecute(Sender: TObject);
    procedure actSetAllExecute(Sender: TObject);
    procedure actSetFilterExecute(Sender: TObject);

  private
    procedure DoOnClick(Sender: TObject);
    function GetObject: TgdcBase;

  public
    constructor Create(AnOwner: TComponent); override;
  end;

var
  at_frmNSObjects: Tat_frmNSObjects;

implementation

{$R *.DFM}

uses
  gd_classlist, gdcNamespace, gdcMetaData, IBSQL, at_AddToSetting;

const
  ArrayOfGDC: array[0..23] of String = (
    'TgdcBaseTable',
    'TgdcField',
    'TgdcStoredProc',
    'TgdcTrigger',
    'TgdcRelationField',
    'TgdcCheckConstraint',
    'TgdcException',
    'TgdcGenerator',
    'TgdcIndex',
    'TgdcConst',
    'TgdcFile',
    'TgdcStorage',
    'TgdcSavedFilter',
    'TgdcExplorer',
    'TgdcReportGroup',
    'TgdcReport',
    'TgdcMacros',
    'TgdcFunction',
    'TgdcEvent',
    'TgdcDelphiObject',
    'TgdcAcctAccount',
    'TgdcDocumentType',
    'TgdcBaseAcctTransactionEntry',
    'TgdcBaseAcctTransaction'
  );

procedure Tat_frmNSObjects.FormCreate(Sender: TObject);
var
  I: Integer;
  C: TCheckBox;
begin
  for I := Low(ArrayOfGDC) to High(ArrayOfGDC) do
  begin
    C := TCheckBox.Create(pnlFilter);
    C.Parent := pnlFilter;
    C.Width := 160;
    C.Height := 16;
    C.Left := 8 + (I mod 4) * C.Width;
    C.Top := 8 + (I div 4) * C.Height;
    C.Caption := ArrayOfGDC[I];
    C.Checked := False;
  end;

  ibtr.StartTransaction;
end;

procedure Tat_frmNSObjects.actOpenObjectUpdate(Sender: TObject);
begin
  actOpenObject.Enabled := not ibds.EOF;
end;

procedure Tat_frmNSObjects.actOpenObjectExecute(Sender: TObject);
var
  Obj: TgdcBase;
begin
  Obj := GetObject;
  if Obj <> nil then
  try
    Obj.EditDialog;
  finally
    Obj.Free;
  end;
end;

procedure Tat_frmNSObjects.dsDataChange(Sender: TObject; Field: TField);
var
  I: Integer;
  SL: TStringList;
  TBI: TTBItem;
begin
  for I := tb.Items.Count - 1 downto 0 do
  begin
    if tb.Items[I].Tag > 0 then
      tb.Items[I].Free;
  end;

  SL := TStringList.Create;
  try
    SL.Text := StringReplace(ibds.FieldByName('ns_list').AsString,
      ',', #13#10, [rfReplaceAll]);
    for I := 0 to Sl.Count - 1 do
    begin
      TBI := TTBItem.Create(nil);
      TBI.Tag := TID2Tag(GetTID(SL.Names[I]), Name);
      TBI.Caption := SL.Values[SL.Names[I]];
      TBI.OnClick := DoOnClick;
      tb.Items.Add(TBI);
    end;
  finally
    SL.Free;
  end;
end;

procedure Tat_frmNSObjects.DoOnClick(Sender: TObject);
var
  Obj: TgdcNamespace;
begin
  Obj := TgdcNamespace.Create(nil);
  try
    Obj.SubSet := 'ByID';
    Obj.ID := GetTID((Sender as TComponent).Tag, Name);
    Obj.Open;
    if not Obj.EOF then
      Obj.EditDialog;
  finally
    Obj.Free;
  end;
end;

constructor Tat_frmNSObjects.Create(AnOwner: TComponent);
begin
  inherited;
  ShowSpeedButton := True;
end;

procedure Tat_frmNSObjects.actAddToNamespaceUpdate(Sender: TObject);
begin
  actAddToNamespace.Enabled := ibds.Active
    and (not ibds.EOF);
end;

function Tat_frmNSObjects.GetObject: TgdcBase;
var
  CE: TgdClassEntry;
begin
  CE := gdClassList.Find(ibds.FieldByName('objectclass').AsString,
    ibds.FieldByName('subtype').AsString);
  if CE is TgdBaseEntry then
  begin
    Result := TgdBaseEntry(CE).gdcClass.Create(nil);
    Result.SubType := CE.SubType;
    Result.SubSet := 'ByID';
    Result.ID := gdcBaseManager.GetIDByRUID(GetTID(ibds.FieldByName('xid')),
      ibds.FieldByName('dbid').AsInteger);
    Result.Open;
    if Result.EOF then
    begin
      MessageBox(Self.Handle,
        '������ ��� ������ ����� �� ������ � ���� ������.',
        '��������',
        MB_OK or MB_ICONEXCLAMATION or MB_TASKMODAL);
      FreeAndNil(Result);
    end;
  end else
    Result := nil
end;

procedure Tat_frmNSObjects.actAddToNamespaceExecute(Sender: TObject);
var
  Obj: TgdcBase;
begin
  Obj := GetObject;
  if Obj <> nil then
  try
    AddToSetting(False, '', '', Obj, nil);
  finally
    Obj.Free;
  end;
end;

procedure Tat_frmNSObjects.actClearAllExecute(Sender: TObject);
var
  I: Integer;
begin
  for I := 0 to pnlFilter.ComponentCount - 1 do
    if pnlFilter.Components[I] is TCheckBox then
      (pnlFilter.Components[I] as TCheckBox).Checked := False;
end;

procedure Tat_frmNSObjects.actSetAllExecute(Sender: TObject);
var
  I: Integer;
begin
  for I := 0 to pnlFilter.ComponentCount - 1 do
    if pnlFilter.Components[I] is TCheckBox then
      (pnlFilter.Components[I] as TCheckBox).Checked := True;
end;

procedure Tat_frmNSObjects.actSetFilterExecute(Sender: TObject);
var
  S, USRCond: String;
  C: TPersistentClass;
  I: Integer;
begin
  S := '';
  for I := 0 to pnlFilter.ComponentCount - 1 do
    if (pnlFilter.Components[I] is TCheckBox)
      and (pnlFilter.Components[I] as TCheckBox).Checked then
    begin
      C := GetClass((pnlFilter.Components[I] as TCheckBox).Caption);
      if (C <> nil) and C.InheritsFrom(TgdcBase)
        and (CgdcBase(C).GetListTable('') > '') then
      begin
        if C.InheritsFrom(TgdcMetaBase) then
          USRCond := 
            '  (' + CgdcBase(C).GetListField('') + ' LIKE ''USR$%'')'#13#10 +
            '  AND (NOT r.' + CgdcBase(C).GetListField('') + ' LIKE ''USR$CROSS%'')'#13#10        
        else
          USRCond := '';

        if S > '' then
          S := S + #13#10#13#10 + 'UNION ALL'#13#10#13#10;
        if chbxInNS.Checked then
        begin
          S := S +
            'SELECT'#13#10 +
            '  CAST(''' + (pnlFilter.Components[I] as TCheckBox).Caption + ''' AS VARCHAR(60)) AS ObjectClass,'#13#10 +
            '  '''' AS SubType,'#13#10 +
            '  ruid.xid,'#13#10 +
            '  ruid.dbid,'#13#10 +
            '  r.' + CgdcBase(C).GetListField('') + ' AS ObjectName,'#13#10 +
            '  r.editiondate,'#13#10 +
            '  list(n.id || ''='' || n.name) AS ns_list'#13#10 +
            'FROM'#13#10 +
            '  ' +  CgdcBase(C).GetListTable('') + ' r'#13#10 +
            '  JOIN gd_ruid ruid ON ruid.id = r.id'#13#10 +
            '  JOIN at_object o ON o.xid = ruid.xid AND o.dbid = ruid.dbid'#13#10 +
            '  JOIN at_namespace n ON n.id = o.namespacekey'#13#10 +
            'WHERE '#13#10 +
            USRCond +
            '  AND (ruid.xid >= 147000000)'#13#10;
          if gsPeriodEdit.Text > '' then
            S := S +
            '  AND (r.editiondate IS NULL OR r.editiondate BETWEEN :DB AND :DE)'#13#10;
          S := S +
            'GROUP BY'#13#10 +
            '  1, 2, 3, 4, 5, 6';
        end else
        begin
          S := S +
            'SELECT'#13#10 +
            '  CAST(''' + (pnlFilter.Components[I] as TCheckBox).Caption + ''' AS VARCHAR(60)) AS ObjectClass,'#13#10 +
            '  '''' AS SubType,'#13#10 +
            '  ruid.xid,'#13#10 +
            '  ruid.dbid,'#13#10 +
            '  r.' + CgdcBase(C).GetListField('') + ' AS ObjectName,'#13#10 +
            '  r.editiondate,'#13#10 +
            '  '''' AS ns_list'#13#10 +
            'FROM'#13#10 +
            '  ' +  CgdcBase(C).GetListTable('') + ' r'#13#10 +
            '  JOIN gd_ruid ruid ON ruid.id = r.id'#13#10 +
            '  LEFT JOIN at_object o ON o.xid = ruid.xid AND o.dbid = ruid.dbid'#13#10 +
            'WHERE '#13#10 +
            USRCond +
            '  AND (o.id IS NULL)'#13#10 +
            '  AND (ruid.xid >= 147000000)'#13#10;
          if gsPeriodEdit.Text > '' then
            S := S +
            '  AND (r.editiondate IS NULL OR r.editiondate BETWEEN :DB AND :DE)';
        end;
      end;
    end;

  ibds.Close;
  ibds.SelectSQL.Text := S;
  if S > '' then
  begin
    if gsPeriodEdit.Text > '' then
    begin
      ibds.ParamByName('DB').AsDateTime := gsPeriodEdit.Date;
      ibds.ParamByName('DE').AsDateTime := gsPeriodEdit.EndDate + 1;
    end;  
    ibds.Open;
  end;
end;

end.
