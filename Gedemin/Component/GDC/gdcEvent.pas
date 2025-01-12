// ShlTanya, 10.02.2019

unit gdcEvent;

interface

uses
  Classes, gdcBase, comctrls, gdcBaseInterface;

const
  cByObjectKey = 'ByObjectKey';
  cByLBRBObject = 'ByLBRBObject';

type
  TgdcEvent = class(TgdcBase)
  protected
    procedure _DoOnNewRecord; override;

    // ������������ �������
    function GetSelectClause: String; override;
    function GetFromClause(const ARefresh: Boolean = False): String; override;
    procedure GetWhereClauseConditions(S: TStrings); override;

  public
    class function GetListTable(const ASubType: TgdcSubType): String; override;
    class function GetKeyField(const ASubType: TgdcSubType): String; override;
    class function GetListField(const ASubType: TgdcSubType): String; override;
    class function GetSubSetList: String; override;
    class function GetViewFormClassName(const ASubType: TgdcSubType): String; override;
    class function NeedModifyFromStream(const SubType: String): Boolean; override;

    function CheckTheSameStatement: String; override;
    function SaveEvent(const AnObjectNode: TTreeNode;
     const AnEventNode: TTreeNode): Boolean;
  end;

  procedure Register;

implementation

uses
  DB, SysUtils, IBSQL, evt_Base, gdc_attr_frmEvent_unit,
  gd_ClassList, gd_directories_const, gdcFunction;

procedure Register;
begin
  RegisterComponents('gdc', [TgdcEvent]);
end;

{ TgdcEvent }

procedure TgdcEvent._DoOnNewRecord;
  {@UNFOLD MACRO INH_ORIG_PARAMS(VAR)}
  {M}VAR
  {M}  Params, LResult: Variant;
  {M}  tmpStrings: TStackStrings;
  {END MACRO}
begin
  {@UNFOLD MACRO INH_ORIG_WITHOUTPARAM('TGDCEVENT', '_DOONNEWRECORD', KEY_DOONNEWRECORD)}
  {M}  try
  {M}    if (not FDataTransfer) and Assigned(gdcBaseMethodControl) then
  {M}    begin
  {M}      SetFirstMethodAssoc('TGDCEVENT', KEY_DOONNEWRECORD);
  {M}      tmpStrings := TStackStrings(ClassMethodAssoc.IntByKey[KEY_DOONNEWRECORD]);
  {M}      if (tmpStrings = nil) or (tmpStrings.IndexOf('TGDCEVENT') = -1) then
  {M}      begin
  {M}        Params := VarArrayOf([GetGdcInterface(Self)]);
  {M}        if gdcBaseMethodControl.ExecuteMethodNew(ClassMethodAssoc, Self, 'TGDCEVENT',
  {M}          '_DOONNEWRECORD', KEY_DOONNEWRECORD, Params, LResult) then exit;
  {M}      end else
  {M}        if tmpStrings.LastClass.gdClassName <> 'TGDCEVENT' then
  {M}        begin
  {M}          Inherited;
  {M}          Exit;
  {M}        end;
  {M}    end;
  {END MACRO}
  inherited;

  FieldByName('afull').AsInteger := -1;
  if HasSubSet(cByObjectKey) then
    SetTID(FieldByName('objectkey'), ParamByName('objectkey'));
  {@UNFOLD MACRO INH_ORIG_FINALLY('TGDCEVENT', '_DOONNEWRECORD', KEY_DOONNEWRECORD)}
  {M}  finally
  {M}    if (not FDataTransfer) and Assigned(gdcBaseMethodControl) then
  {M}      ClearMacrosStack2('TGDCEVENT', '_DOONNEWRECORD', KEY_DOONNEWRECORD);
  {M}  end;
  {END MACRO}
end;

function TgdcEvent.GetFromClause(const ARefresh: Boolean = False): String;
  {@UNFOLD MACRO INH_ORIG_PARAMS(VAR)}
  {M}VAR
  {M}  Params, LResult: Variant;
  {M}  tmpStrings: TStackStrings;
  {END MACRO}
begin
  {@UNFOLD MACRO INH_ORIG_GETFROMCLAUSE('TGDCEVENT', 'GETFROMCLAUSE', KEYGETFROMCLAUSE)}
  {M}  try
  {M}    if (not FDataTransfer) and Assigned(gdcBaseMethodControl) then
  {M}    begin
  {M}      SetFirstMethodAssoc('TGDCEVENT', KEYGETFROMCLAUSE);
  {M}      tmpStrings := TStackStrings(ClassMethodAssoc.IntByKey[KEYGETFROMCLAUSE]);
  {M}      if (tmpStrings = nil) or (tmpStrings.IndexOf('TGDCEVENT') = -1) then
  {M}      begin
  {M}        Params := VarArrayOf([GetGdcInterface(Self), ARefresh]);
  {M}        if gdcBaseMethodControl.ExecuteMethodNew(ClassMethodAssoc, Self, 'TGDCEVENT',
  {M}          'GETFROMCLAUSE', KEYGETFROMCLAUSE, Params, LResult) then
  {M}          begin
  {M}            if (VarType(LResult) = varOleStr) or (VarType(LResult) = varString) then
  {M}              Result := String(LResult)
  {M}            else
  {M}              begin
  {M}                raise Exception.Create('��� ������ ''' + 'GETFROMCLAUSE' + ' ''' +
  {M}                  ' ������ ' + Self.ClassName + TgdcBase(Self).SubType + #10#13 +
  {M}                  '�� ������� ��������� �� ��������� ���');
  {M}              end;
  {M}            exit;
  {M}          end;
  {M}      end else
  {M}        if tmpStrings.LastClass.gdClassName <> 'TGDCEVENT' then
  {M}        begin
  {M}          Result := Inherited GetFromClause(ARefresh);
  {M}          Exit;
  {M}        end;
  {M}    end;
  {END MACRO}
  Result := 'FROM evt_objectevent z LEFT JOIN evt_object o ON z.objectkey = o.id ' +
    ' LEFT JOIN evt_object op ON op.id = o.parent ';
  {@UNFOLD MACRO INH_ORIG_FINALLY('TGDCEVENT', 'GETFROMCLAUSE', KEYGETFROMCLAUSE)}
  {M}  finally
  {M}    if (not FDataTransfer) and Assigned(gdcBaseMethodControl) then
  {M}      ClearMacrosStack2('TGDCEVENT', 'GETFROMCLAUSE', KEYGETFROMCLAUSE);
  {M}  end;
  {END MACRO}
end;

class function TgdcEvent.GetKeyField(const ASubType: TgdcSubType): String;
begin
  Result := 'ID'
end;

class function TgdcEvent.GetListField(const ASubType: TgdcSubType): String;
begin
  Result := 'EVENTNAME'
end;

class function TgdcEvent.GetListTable(const ASubType: TgdcSubType): String;
begin
  Result := 'EVT_OBJECTEVENT';
end;

function TgdcEvent.GetSelectClause: String;
  {@UNFOLD MACRO INH_ORIG_PARAMS(VAR)}
  {M}VAR
  {M}  Params, LResult: Variant;
  {M}  tmpStrings: TStackStrings;
  {END MACRO}
begin
  {@UNFOLD MACRO INH_ORIG_GETSELECTCLAUSE('TGDCEVENT', 'GETSELECTCLAUSE', KEYGETSELECTCLAUSE)}
  {M}  try
  {M}    if (not FDataTransfer) and Assigned(gdcBaseMethodControl) then
  {M}    begin
  {M}      SetFirstMethodAssoc('TGDCEVENT', KEYGETSELECTCLAUSE);
  {M}      tmpStrings := TStackStrings(ClassMethodAssoc.IntByKey[KEYGETSELECTCLAUSE]);
  {M}      if (tmpStrings = nil) or (tmpStrings.IndexOf('TGDCEVENT') = -1) then
  {M}      begin
  {M}        Params := VarArrayOf([GetGdcInterface(Self)]);
  {M}        if gdcBaseMethodControl.ExecuteMethodNew(ClassMethodAssoc, Self, 'TGDCEVENT',
  {M}          'GETSELECTCLAUSE', KEYGETSELECTCLAUSE, Params, LResult) then
  {M}          begin
  {M}            if (VarType(LResult) = varOleStr) or (VarType(LResult) = varString) then
  {M}              Result := String(LResult)
  {M}            else
  {M}              begin
  {M}                raise Exception.Create('��� ������ ''' + 'GETSELECTCLAUSE' + ' ''' +
  {M}                  ' ������ ' + Self.ClassName + TgdcBase(Self).SubType + #10#13 +
  {M}                  '�� ������� ��������� �� ��������� ���');
  {M}              end;
  {M}            exit;
  {M}          end;
  {M}      end else
  {M}        if tmpStrings.LastClass.gdClassName <> 'TGDCEVENT' then
  {M}        begin
  {M}          Result := Inherited GetSelectClause;
  {M}          Exit;
  {M}        end;
  {M}    end;
  {END MACRO}
  Result := 'SELECT z.*, o.name as objectname, op.name as parentname ';
  {@UNFOLD MACRO INH_ORIG_FINALLY('TGDCEVENT', 'GETSELECTCLAUSE', KEYGETSELECTCLAUSE)}
  {M}  finally
  {M}    if (not FDataTransfer) and Assigned(gdcBaseMethodControl) then
  {M}      ClearMacrosStack2('TGDCEVENT', 'GETSELECTCLAUSE', KEYGETSELECTCLAUSE);
  {M}  end;
  {END MACRO}
end;

class function TgdcEvent.GetSubSetList: String;
begin
  Result := inherited GetSubSetList + cByObjectKey + ';' +
    cByLBRBObject + ';';
end;

procedure TgdcEvent.GetWhereClauseConditions(S: TStrings);
begin
  inherited;
  if HasSubSet(cByObjectKey) then
    S.Add('z.objectkey = :objectkey');
  if HasSubSet(cByLBRBObject) then
    S.Add('o.lb >= :LB AND o.rb <= :RB ');
end;

function TgdcEvent.SaveEvent(const AnObjectNode: TTreeNode;
  const AnEventNode: TTreeNode): Boolean;
var
  q: TIBSQL;
  DidActivate: Boolean;
  OK, FK: TID;
  EN: String;
begin
  Assert((AnObjectNode <> nil) and (AnObjectNode.Data <> nil));
  Assert((AnEventNode <> nil) and (AnEventNode.Data <> nil));

  OK := (TObject(AnObjectNode.Data) as TEventObject).ObjectKey;
  EN := AnsiUpperCase((TObject(AnEventNode.Data) as TEventItem).Name);
  FK := (TObject(AnEventNode.Data) as TEventItem).FunctionKey;

  DidActivate := False;
  q := TIBSQL.Create(nil);
  try
    DidActivate := ActivateTransaction;
    q.Transaction := Transaction;
    q.SQL.Text :=
      'SELECT functionkey FROM evt_objectevent ' +
      'WHERE objectkey = :OK AND eventname = :EN';
    SetTID(q.ParamByName('OK'), OK);
    q.ParamByName('EN').AsString := EN;
    q.ExecQuery;
    if not q.Eof then
    begin
      Result := GetTID(q.FieldByName('functionkey')) = FK;

      if Result then
        exit;

      q.Close;
      q.SQL.Text :=
        'DELETE FROM evt_objectevent WHERE objectkey = :OK AND eventname = :EN';
      SetTID(q.ParamByName('OK'), OK);
      q.ParamByName('EN').AsString := EN;
      q.ExecQuery;
    end;

    if FK <> 0 then
    begin
      q.Close;
      q.SQL.Text :=
        'INSERT INTO evt_objectevent(id, objectkey, functionkey, eventname) ' +
        'VALUES(:id, :objectkey, :functionkey, :eventname)';
      SetTID(q.ParamByName('id'), GetNextID);
      SetTID(q.ParamByName('objectkey'), OK);
      SetTID(q.ParamByName('functionkey'), FK);
      q.ParamByName('eventname').AsString := EN;
      q.ExecQuery;
    end;
  finally
    if DidActivate then
      Transaction.Commit;
    q.Free;
  end;

  Result := True;
end;

class function TgdcEvent.GetViewFormClassName(const ASubType: TgdcSubType): String;
begin
  Result := 'Tgdc_frmEvent';
end;

function TgdcEvent.CheckTheSameStatement: String;
  {@UNFOLD MACRO INH_ORIG_PARAMS(VAR)}
  {M}VAR
  {M}  Params, LResult: Variant;
  {M}  tmpStrings: TStackStrings;
  {END MACRO}
begin
  {@UNFOLD MACRO INH_ORIG_CHECKTHESAMESTATEMENT('TGDCEVENT', 'CHECKTHESAMESTATEMENT', KEYCHECKTHESAMESTATEMENT)}
  {M}  try
  {M}    if (not FDataTransfer) and Assigned(gdcBaseMethodControl) then
  {M}    begin
  {M}      SetFirstMethodAssoc('TGDCEVENT', KEYCHECKTHESAMESTATEMENT);
  {M}      tmpStrings := TStackStrings(ClassMethodAssoc.IntByKey[KEYCHECKTHESAMESTATEMENT]);
  {M}      if (tmpStrings = nil) or (tmpStrings.IndexOf('TGDCEVENT') = -1) then
  {M}      begin
  {M}        Params := VarArrayOf([GetGdcInterface(Self)]);
  {M}        if gdcBaseMethodControl.ExecuteMethodNew(ClassMethodAssoc, Self, 'TGDCEVENT',
  {M}          'CHECKTHESAMESTATEMENT', KEYCHECKTHESAMESTATEMENT, Params, LResult) then
  {M}          begin
  {M}            if (VarType(LResult) = varOleStr) or (VarType(LResult) = varString) then
  {M}              Result := String(LResult)
  {M}            else
  {M}              begin
  {M}                raise Exception.Create('��� ������ ''' + 'CHECKTHESAMESTATEMENT' + ' ''' +
  {M}                  ' ������ ' + Self.ClassName + TgdcBase(Self).SubType + #10#13 +
  {M}                  '�� ������� ��������� �� ��������� ���');
  {M}              end;
  {M}            exit;
  {M}          end;
  {M}      end else
  {M}        if tmpStrings.LastClass.gdClassName <> 'TGDCEVENT' then
  {M}        begin
  {M}          Result := Inherited CheckTheSameStatement;
  {M}          Exit;
  {M}        end;
  {M}    end;
  {END MACRO}

  if State = dsInactive then
    Result := 'SELECT id FROM evt_objectevent WHERE objectkey = :objectkey AND ' +
      'eventname = :eventname'
  else if ID < cstUserIDStart then
    Result := inherited CheckTheSameStatement
  else
    Result := Format('SELECT id FROM evt_objectevent WHERE objectkey = %d AND ' +
      'eventname = ''%s''',
      [TID264(FieldByName('objectkey')), FieldByName('eventname').AsString]);

  {@UNFOLD MACRO INH_ORIG_FINALLY('TGDCEVENT', 'CHECKTHESAMESTATEMENT', KEYCHECKTHESAMESTATEMENT)}
  {M}  finally
  {M}    if (not FDataTransfer) and Assigned(gdcBaseMethodControl) then
  {M}      ClearMacrosStack2('TGDCEVENT', 'CHECKTHESAMESTATEMENT', KEYCHECKTHESAMESTATEMENT);
  {M}  end;
  {END MACRO}
end;

class function TgdcEvent.NeedModifyFromStream(
  const SubType: String): Boolean;
begin
  Result := True;
end;

initialization
  RegisterGdcClass(TgdcEvent, '�������');

finalization
  UnregisterGdcClass(TgdcEvent);
end.
