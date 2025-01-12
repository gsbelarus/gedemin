// ShlTanya, 09.03.2019, #4135

unit gdv_frAcctQuantity_unit;

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs,
  ExtCtrls, gdvParamPanel, AcctUtils, contnrs, IBSQL, stdctrls, gdcBaseInterface,
  gd_security, gd_common_functions;

type
  TfrAcctQuantity = class(TFrame)
    ppMain: TgdvParamPanel;
    procedure ppMainResize(Sender: TObject);

  private
    { Private declarations }
    FCheckBoxList: TObjectList;
    FContext: String;
    procedure SetSelected(const Value: string);
    function GetSelected: string;
    function GetValueCount: Integer;

  public
    { Public declarations }
    procedure SaveToStream(const Stream: TStream);
    procedure LoadFromStream(const Stream: TStream);

    destructor Destroy; override;
    procedure UpdateQuantityList(AIdList: TList);

    function IDList: String;
    procedure ValueList(const ValueList: TStrings; const AccountList: TList; BeginDate,
      EndDate: TDateTime;
      const WithSubAccounts: Boolean = False);

    // ����� ����� �������������� ������� �� ����������
    property ValueCount: Integer read GetValueCount;
    property Selected: string read GetSelected write SetSelected;
    property Context: String write FContext;
  end;

implementation

uses
  Math;

{$R *.DFM}

{ TfrAcctQuantity }

destructor TfrAcctQuantity.Destroy;
begin
  FCheckBoxList.Free;
  
  inherited;
end;

function TfrAcctQuantity.GetSelected: string;
var
  I: Integer;
begin
  Result := '';
  if FCheckBoxList <> nil then
  begin
    for I := 0 to FCheckBoxList.Count - 1 do
    begin
      if TCheckBox(FCheckBoxList[I]).Checked then
      begin
        if Result > '' then Result := Result + #13#10;

        Result := Result + TID2S(GetTID(TCheckBox(FCheckBoxList[I]).Tag, FContext));
      end;  
    end;
  end;
end;

function TfrAcctQuantity.IDList: string;
var
  I: Integer;
begin
  Result := '';
  if FCheckBoxList <> nil then
  begin
    for i := 0 to FCheckBoxList.Count - 1 do
    begin
      if TCheckBox(FCheckBoxList[I]).Checked then
      begin
        if Result > '' then
          Result := Result + ', ';
        Result := Result + TID2S(GetTID(TCheckBox(FCheckBoxList[I]).Tag, FContext));
      end;  
    end;
  end;
end;

procedure TfrAcctQuantity.SetSelected(const Value: string);
var
  I: Integer;
  S: TStrings;
begin
  if FCheckBoxList <> nil then
  begin
    S := TStringList.Create;
    try
      S.Text := Value;
      for I := 0 to FCheckBoxList.Count - 1 do
      begin
        TCheckBox(FCheckBoxList[I]).Checked :=
          S.IndexOf(TID2S(GetTID(TCheckBox(FCheckBoxList[I]).Tag, FContext))) > - 1;
      end;
    finally
      S.Free;
    end;
  end;
end;

procedure TfrAcctQuantity.UpdateQuantityList(AIDList: TList);
var
  SQL: TIBSQL;
  I: Integer;
  CB: TCheckBox;
  H: Integer;
  Order: Integer;
  L: TList;
begin
  if FCheckBoxList = nil then
    FCheckBoxList := TObjectList.Create;

  L := TList.Create;
  try
    for I := 0 to FCheckBoxList.Count -1 do
    begin
      if TCheckBox(FCheckBoxList[I]).Checked then
        L.Add(Pointer(TCheckBox(FCheckBoxList[I]).Tag));
    end;
    FCheckBoxList.Clear;

    SQL := TIBSQL.Create(nil);
    try
      SQL.Transaction := gdcBaseManager.ReadTransaction;
      SQL.SQl.Text :=  'SELECT DISTINCT ' +
        'v.id, v.name, v.description ' +
        'FROM ' +
        '  ac_account a ' +
        '  JOIN ac_accvalue av ON av.accountkey = a.id ' +
        '  JOIN gd_value v ON av.valuekey = v.id ';
      if AIdList.Count > 0 then
      begin
        SQL.SQl.Add('WHERE ');
        SQL.SQl.Add('  a.id IN(' + AcctUtils.IDList(AIdList, FContext) + ') ');
      end;
      SQL.SQL.Add('ORDER BY v.name ');
      SQL.ExecQuery;
      H := ppMain.ClientRect.Top;
      Order := 0;

      while not SQl.Eof do
      begin
        Cb := TCheckBox.Create(Self);
        FCheckBoxList.Add(Cb);
        Cb.Left := 16;
        Cb.Top := H;
        Cb.Width := ppMain.ClientRect.Right - 16;
        Cb.ParentFont := False;
        Cb.ParentColor := False;
        Cb.Color := ppMain.FillColor;
        Cb.Parent := ppMain;
        Cb.TabOrder := Order;
        Cb.Anchors := [akLeft, akTop, akRight];

        if SQL.FieldByName('description').AsString > '' then
        begin
          Cb.Caption := Format('%s (%s)', [SQl.FieldByName('name').AsString,
            SQL.FieldByName('description').AsString]);
        end else
        begin
          Cb.Caption := SQL.FieldByName('name').AsString;
        end;
        Cb.Tag := TID2Tag(GetTID(SQL.FieldByName('id')), FContext);
        Cb.Checked := L.IndexOf(Pointer(Cb.Tag)) > - 1;

        H := H + Cb.Height;
        Inc(Order);

        SQL.Next;
      end;

      ppMain.UpdateHeight(Max(H + 4, cMinUnwrapedHeight));
    finally
      SQL.Free;
    end;
  finally
    L.Free;
  end;
  Realign;
end;

procedure TfrAcctQuantity.ValueList(const ValueList: TStrings;
  const AccountList: TList; BeginDate, EndDate: TDateTime;
  const WithSubAccounts: Boolean = False);

  function GetIDList: String;
  var
    ibsql: TIBSQL;
    L: TList;
  begin
    Result := '-1';
    if AccountList.Count > 0 then
    begin
      if WithSubAccounts then
      begin
        L := TList.Create;
        ibsql := TIBSQL.Create(nil);
        try
          ibsql.Transaction := gdcBaseManager.ReadTransaction;
          ibsql.SQL.Text := Format(
            ' SELECT a2.id FROM ac_account a1, ac_account a2 WHERE a1.id in(%s) and ' +
            ' a2.lb >= a1.lb and a2.rb <= a1.rb and a2.ACCOUNTTYPE in (''A'', ''S'')',
            [AcctUtils.IDList(AccountList, FContext)]);
          ibsql.ExecQuery;
          while not ibsql.Eof do
          begin
            if L.IndexOf(TID2Pointer(GetTID(ibsql.Fields[0]), FContext)) = -1 then
              L.Add(TID2Pointer(GetTID(ibsql.Fields[0]), FContext));
            ibsql.Next;
          end;
          Result := AcctUtils.IDList(L, FContext);
        finally
          ibsql.Free;
          L.Free;
        end;
      end else
        Result := AcctUtils.IDList(AccountList, FContext);
    end;
  end;

var
  SQL: TIBSQL;
begin
  ValueList.Clear;
  if IdList > '' then
  begin
    SQL := TIBSQL.Create(nil);
    try
      SQL.Transaction := gdcBaseManager.ReadTransaction;
      SQL.SQl.Text :=
        'SELECT DISTINCT ' +
        '  q.valuekey, v.name ' +
        'FROM ' +
        '  ac_entry e ' +
        '  LEFT JOIN ac_record r ON r.id = e.recordkey ' +
        '  LEFT JOIN ac_entry e1 ON e.id = e1.id AND e1.entrydate < :begindate ' +
        '  LEFT JOIN ac_entry e2 ON e.id = e2.id AND e2.entrydate  >= :begindate AND ' +
        '    e2.entrydate <=:enddate ' +
        '  JOIN ac_quantity q ON q.entrykey = e.id ' +
        '  JOIN gd_value v ON v.id = q.valuekey ' +
        'WHERE ';
      if AccountList.Count > 0 then
        SQL.SQL.Add('  e.accountkey IN(' + GetIDList + ') AND ');

      SQL.SQL.Text := SQL.SQL.Text +
        '  e.entrydate <= :enddate AND ' +
        '  r.companykey IN(' + IBLogin.HoldingList + ') AND ' +
        '  BIN_AND(BIN_OR(r.aview, 1), ' + IntToStr(IBLogin.InGroup) + ') <> 0 AND ' +
        '  v.id IN (' + IDList + ') ' +
        'GROUP BY q.valuekey, v.name ' +
        'HAVING SUM(e2.debitncu) <> 0 OR SUM(e2.creditncu) <> 0 '#13#10 +
        '  OR SUM(e1.debitncu - e1.creditncu) <> 0 OR SUM(e1.debitcurr - e1.creditcurr) <> 0 '#13#10 +
        '  OR SUM(e2.debitcurr) <> 0 OR SUM(e2.creditcurr) <> 0 '#13#10 +
        '  OR SUM(q.quantity) <> 0';
      SQL.ParamByName('enddate').AsDateTime := EndDate;
      SQL.ExecQuery;
      while not SQL.Eof do
      begin
        ValueList.Add(SQL.FieldByName('valuekey').AsString + '=' +
          SQL.FieldByName('name').AsString);
        SQL.Next;
      end;
    finally
      SQL.Free;
    end;
  end;
end;

procedure TfrAcctQuantity.ppMainResize(Sender: TObject);
begin
  SetBounds(Left, Top, ppMain.Width, ppMain.Height);
end;

procedure TfrAcctQuantity.LoadFromStream(const Stream: TStream);
begin
  Selected := ReadStringFromStream(Stream);
end;

procedure TfrAcctQuantity.SaveToStream(const Stream: TStream);
begin
  SaveStringToStream(Selected, Stream);
end;

function TfrAcctQuantity.GetValueCount: Integer;
begin
  Result := 0;
  if Assigned(FCheckBoxList) then
    Result := FCheckBoxList.Count;
end;

end.
