// ShlTanya, 10.02.2019

unit gdcFKManager;

interface

uses
  Classes, Windows, Messages, gdcBaseInterface, gdcBase;

const
  CMD_INIT       = 0;
  CMD_UPDATE     = 1;
  CMD_CLEAR      = 2;
  CMD_DONE       = 3;

type
  TCallBackProc = procedure (FTotalCount, FDone: Integer) of object;

  TgdcFKManagerThread = class(TThread)
  private
    FFinished: Boolean;
    FTotalCount, FDone: Integer;

  protected
    FWindowHandle: THandle;

    procedure InitScreen;
    procedure UpdateScreen;
    procedure ClearScreen;
    procedure DoneScreen;

  protected
    procedure Execute; override;

    property Finished: Boolean read FFinished;
  end;

  TgdcFKManager = class(TgdcBase)
  private
    FThread: TgdcFKManagerThread;

  public
    destructor Destroy; override;

    procedure DoAfterOpen; override;

    procedure SyncWithSystemMetadata;
    procedure CleanFKList;
    procedure UpdateStats(AHandle: THandle);
    function IsUpdateStatsRunning: Boolean;
    procedure CancelUpdateStats;
    function ConvertFK: Integer;

    class function GetListTable(const ASubType: TgdcSubType): String; override;
    class function GetListField(const ASubType: TgdcSubType): String; override;
    class function GetViewFormClassName(const ASubType: TgdcSubType): String; override;
    class function GetDialogFormClassName(const ASubType: TgdcSubType): String; override;
  end;

procedure Register;

implementation

uses
  gd_ClassList, gdc_dlgFKManager_unit, gdc_frmFKManager_unit,
  IBDatabase, IBSQL, SysUtils, Forms, Controls, gd_messages_const;

procedure Register;
begin
  RegisterComponents('gdc', [TgdcFKManager]);
end;

{ TgdcFKManager }

procedure TgdcFKManager.CancelUpdateStats;
begin
  if IsUpdateStatsRunning then
  begin
    FThread.Terminate;
    FThread.WaitFor;
  end;
end;

procedure TgdcFKManager.CleanFKList;
var
  Tr: TIBTransaction;
  q: TIBSQL;
begin
  Tr := TIBTransaction.Create(nil);
  q := TIBSQL.Create(nil);
  try
    Tr.DefaultDatabase := gdcBaseManager.Database;
    Tr.StartTransaction;

    q.Transaction := Tr;

    q.SQL.Text :=
      'DELETE FROM gd_ref_constraints WHERE ref_state = ref_next_state ' +
      '  AND ref_next_state = ''ORIGINAL'' ';
    q.ExecQuery;

    Tr.Commit;
  finally
    q.Free;
    Tr.Free;
  end;
end;

function TgdcFKManager.ConvertFK: Integer;
const
  c_e_message = '��������� ��������� ����������� �� ���� <constraint_field> � ������� <constraint_rel>.';

  c_check =
    '  IF (NEW.<constraint_field> IS NOT NULL) THEN '#13#10 +
    '  BEGIN '#13#10 +
    '    IF (NOT EXISTS (SELECT * FROM gd_ref_constraint_data WHERE value_data = NEW.<constraint_field> '#13#10 +
    '      AND constraintkey = <constraint_key>)) THEN '#13#10 +
    '    BEGIN'#13#10 +
    '      IF (NOT EXISTS (SELECT <ref_field> FROM <ref_rel> WHERE <ref_field> = NEW.<constraint_field>)) THEN'#13#10 +
    '        EXCEPTION gd_e_fkmanager ''<except_message>'' || '' ��������: '' || NEW.<constraint_field>;'#13#10 +
    '      RDB$SET_CONTEXT(''USER_TRANSACTION'', ''REF_CONSTRAINT_UNLOCK'', ''1'');'#13#10 +
    '      INSERT INTO gd_ref_constraint_data (constraintkey, value_data)'#13#10 +
    '        VALUES (<constraint_key>, NEW.<constraint_field>);'#13#10 +
    '      RDB$SET_CONTEXT(''USER_TRANSACTION'', ''REF_CONSTRAINT_UNLOCK'', ''0'');'#13#10 +
    '    END'#13#10 +
    '  END';

  c_ai_constraint_rel_name = 'gd_ai_constraint_rel_<constraint_key>';

  c_ai_constraint_rel =
    'CREATE OR ALTER TRIGGER <trigger_name> FOR <constraint_rel> '#13#10 +
    '  AFTER INSERT '#13#10 +
    '  POSITION 32000 '#13#10 +
    'AS '#13#10 +
    'BEGIN '#13#10 +
    '<check>'#13#10 +
    'END';

  c_au_constraint_rel_name = 'gd_au_constraint_rel_<constraint_key>';

  c_au_constraint_rel =
    'CREATE OR ALTER TRIGGER <trigger_name> FOR <constraint_rel> '#13#10 +
    '  AFTER UPDATE '#13#10 +
    '  POSITION 32000 '#13#10 +
    'AS '#13#10 +
    'BEGIN '#13#10 +
    '  IF (NEW.<constraint_field> IS NOT DISTINCT FROM OLD.<constraint_field>) THEN'#13#10 +
    '    EXIT;'#13#10 +
    '<check>'#13#10 +
    'END';

  c_update_no_action =
    'IF (EXISTS (SELECT * FROM <constraint_rel> WHERE <constraint_field> = OLD.<ref_field>)) THEN '#13#10 +
    '  EXCEPTION gd_e_fkmanager ''<except_message>'';';

  c_update_set_null =
    'UPDATE <constraint_rel> SET <constraint_field> = NULL WHERE <constraint_field> = OLD.<ref_field>;';

  c_update_set_default =
    'UPDATE <constraint_rel> SET <constraint_field> = <default_value> WHERE <constraint_field> = OLD.<ref_field>;';

  c_update_cascade =
    'UPDATE <constraint_rel> SET <constraint_field> = NEW.<ref_field> WHERE <constraint_field> = OLD.<ref_field>;';

  c_delete_no_action = c_update_no_action;

  c_delete_set_null = c_update_set_null;

  c_delete_set_default = c_update_set_default;

  c_delete_cascade =
    'DELETE FROM <constraint_rel> WHERE <constraint_field> = OLD.<ref_field>;';

  c_au_ref_rel_name = 'gd_au_ref_rel_<constraint_key>';

  c_au_ref_rel =
    'CREATE OR ALTER TRIGGER <trigger_name> FOR <ref_rel>'#13#10 +
    '  AFTER UPDATE'#13#10 +
    '  POSITION 32000'#13#10 +
    'AS'#13#10 +
    'BEGIN'#13#10 +
    '  IF (NEW.<ref_field> = OLD.<ref_field>) THEN'#13#10 +
    '    EXIT;'#13#10 +
    ''#13#10 +
    '  <update_rule_code>'#13#10 +
    ''#13#10 +
    '  RDB$SET_CONTEXT(''USER_TRANSACTION'', ''REF_CONSTRAINT_UNLOCK'', ''1'');'#13#10 +
    '  UPDATE gd_ref_constraint_data SET value_data = NEW.<ref_field> WHERE value_data = OLD.<ref_field>'#13#10 +
    '    AND constraintkey = <constraint_key>;'#13#10 +
    '  RDB$SET_CONTEXT(''USER_TRANSACTION'', ''REF_CONSTRAINT_UNLOCK'', ''0'');'#13#10 +
    'END';

  c_ad_ref_rel_name = 'gd_ad_ref_rel_<constraint_key>';

  c_ad_ref_rel =
    'CREATE OR ALTER TRIGGER <trigger_name> FOR <ref_rel>'#13#10 +
    '  AFTER DELETE'#13#10 +
    '  POSITION 32000'#13#10 +
    'AS'#13#10 +
    'BEGIN'#13#10 +
    '  <delete_rule_code>'#13#10 +
    ''#13#10 +
    '  RDB$SET_CONTEXT(''USER_TRANSACTION'', ''REF_CONSTRAINT_UNLOCK'', ''1'');'#13#10 +
    '  DELETE FROM gd_ref_constraint_data WHERE value_data = OLD.<ref_field>'#13#10 +
    '    AND constraintkey = <constraint_key>;'#13#10 +
    '  RDB$SET_CONTEXT(''USER_TRANSACTION'', ''REF_CONSTRAINT_UNLOCK'', ''0'');'#13#10 +
    'END';

  //c_bi_ref_rel_name = 'gd_bi_ref_rel_<constraint_key>';

  //c_bi_ref_rel =
  //  'CREATE OR ALTER TRIGGER <trigger_name> FOR <ref_rel>'#13#10 +
  //  '  BEFORE INSERT'#13#10 +
  //  '  POSITION 32000'#13#10 +
  //  'AS'#13#10 +
  //  'BEGIN'#13#10 +
  //  '  RDB$SET_CONTEXT(''USER_TRANSACTION'', ''REF_CONSTRAINT_UNLOCK'', ''1'');'#13#10 +
  //  '  INSERT INTO gd_ref_constraint_data (constraintkey, value_data) '#13#10 +
  //  '    VALUES (<constraint_key>, NEW.<ref_field>);'#13#10 +
  //  '  RDB$SET_CONTEXT(''USER_TRANSACTION'', ''REF_CONSTRAINT_UNLOCK'', ''0'');'#13#10 +
  //  'END';

  c_drop_constraint =
    'ALTER TABLE <constraint_rel> DROP CONSTRAINT <constraint_name>';

  c_update_trigger =
    'UPDATE gd_ref_constraints SET ref_state = ''TRIGGER'' WHERE constraint_name = ''<constraint_name>'' ';

  c_create_constraint =
    'ALTER TABLE <constraint_rel> ADD CONSTRAINT <constraint_name> ' +
    'FOREIGN KEY (<constraint_field>) REFERENCES <ref_rel> (<ref_field>) ';

  c_update_original =
    'UPDATE gd_ref_constraints SET ref_state = ''ORIGINAL'' WHERE constraint_name = ''<constraint_name>'' ';

  c_create_check =
    'ALTER TABLE <constraint_rel> ADD CONSTRAINT <check_constraint_name> CHECK ( <constraint_field> IN (<id_list>))';

  c_drop_constraint_check =
    'ALTER TABLE <constraint_rel> DROP CONSTRAINT <check_constraint_name>';

  c_update_check =
    'UPDATE gd_ref_constraints SET ref_state = ''CHECK'' WHERE constraint_name = ''<constraint_name>'' ';

  c_update_checkid =
    'UPDATE gd_ref_constraints SET check_id = null where Id = <ID>';

var
  Tr: TIBTransaction;
  qList, qScript: TIBSQL;
  I: Integer;

  function ExpandMetaVariables(const S: String): String;
  begin
    Result := StringReplace(S, '<except_message>',
      c_e_message, [rfIgnoreCase, rfReplaceAll]);
    Result := StringReplace(Result, '<constraint_field>',
      qList.FieldByName('constraint_field').AsTrimString, [rfIgnoreCase, rfReplaceAll]);
    Result := StringReplace(Result, '<constraint_rel>',
      qList.FieldByName('constraint_rel').AsTrimString, [rfIgnoreCase, rfReplaceAll]);
    Result := StringReplace(Result, '<constraint_key>',
      qList.FieldByName('id').AsTrimString, [rfIgnoreCase, rfReplaceAll]);
    Result := StringReplace(Result, '<ref_field>',
      qList.FieldByName('ref_field').AsTrimString, [rfIgnoreCase, rfReplaceAll]);
    Result := StringReplace(Result, '<ref_rel>',
      qList.FieldByName('ref_rel').AsTrimString, [rfIgnoreCase, rfReplaceAll]);
    Result := StringReplace(Result, '<constraint_name>',
      qList.FieldByName('constraint_name').AsTrimString, [rfIgnoreCase, rfReplaceAll]);
    Result := StringReplace(Result, '<update_rule>',
      qList.FieldByName('update_rule').AsTrimString, [rfIgnoreCase, rfReplaceAll]);
    Result := StringReplace(Result, '<delete_rule>',
      qList.FieldByName('delete_rule').AsTrimString, [rfIgnoreCase, rfReplaceAll]);
    Result := StringReplace(Result, '<id_list>',
      qList.FieldByName('check_id').AsTrimString, [rfIgnoreCase, rfReplaceAll]);
    if (qList.FieldByName('ref_next_state').AsTrimString = 'CHECK') or
      (qList.FieldByName('ref_state').AsTrimString = 'CHECK') then
    begin
      Result := StringReplace(Result, '<check_constraint_name>',
        'gd_ref_' + gdcBaseManager.GetRUIDStringByID(GetTID(qList.FieldByName('id'))), [rfIgnoreCase, rfReplaceAll]);
    end;
    Result := StringReplace(Result, '<ID>', TID2S(qList.FieldByName('ID')), [rfIgnoreCase, rfReplaceAll]);

  end;

  procedure InsertScript(const S: String);
  begin
    qScript.ParamByName('numorder').AsInteger := I;
    qScript.ParamByName('script').AsTrimString := S;
    qScript.ExecQuery;
    Inc(I);
  end;

  procedure ConvertToTrigger;
  var
    ExceptMessage, CheckCode, TriggerCode, UpdateRuleCode, DeleteRuleCode: String;
  begin
    ExceptMessage := ExpandMetaVariables(c_e_message);
    CheckCode := StringReplace(ExpandMetaVariables(c_check), '<except_message>',
      ExceptMessage, [rfReplaceAll, rfIgnoreCase]);

    TriggerCode := StringReplace(ExpandMetaVariables(c_ai_constraint_rel), '<check>',
      CheckCode, [rfReplaceAll, rfIgnoreCase]);
    TriggerCode := StringReplace(TriggerCode, '<trigger_name>',
      ExpandMetaVariables(c_ai_constraint_rel_name), [rfReplaceAll, rfIgnoreCase]);
    InsertScript(TriggerCode);

    TriggerCode := StringReplace(ExpandMetaVariables(c_au_constraint_rel), '<check>',
      CheckCode, [rfReplaceAll, rfIgnoreCase]);
    TriggerCode := StringReplace(TriggerCode, '<trigger_name>',
      ExpandMetaVariables(c_au_constraint_rel_name), [rfReplaceAll, rfIgnoreCase]);
    InsertScript(TriggerCode);

    if qList.FieldByName('update_rule').AsTrimString = 'CASCADE' then
    begin
      UpdateRuleCode := ExpandMetaVariables(c_update_cascade);
    end
    else if qList.FieldByName('update_rule').AsTrimString = 'NO ACTION' then
    begin
      UpdateRuleCode := ExpandMetaVariables(c_update_no_action);
    end
    else if qList.FieldByName('update_rule').AsTrimString = 'RESTRICT' then
    begin
      UpdateRuleCode := ExpandMetaVariables(c_update_no_action);
    end
    else if qList.FieldByName('update_rule').AsTrimString = 'SET NULL' then
    begin
      UpdateRuleCode := ExpandMetaVariables(c_update_set_null);
    end else
      raise Exception.Create('Update rule SET DEFAULT is not supported.');
    TriggerCode := StringReplace(ExpandMetaVariables(c_au_ref_rel), '<update_rule_code>',
      UpdateRuleCode, [rfReplaceAll, rfIgnoreCase]);
    TriggerCode := StringReplace(TriggerCode, '<trigger_name>',
      ExpandMetaVariables(c_au_ref_rel_name), [rfReplaceAll, rfIgnoreCase]);
    InsertScript(TriggerCode);

    if qList.FieldByName('delete_rule').AsTrimString = 'CASCADE' then
    begin
      DeleteRuleCode := ExpandMetaVariables(c_delete_cascade);
    end
    else if qList.FieldByName('delete_rule').AsTrimString = 'NO ACTION' then
    begin
      DeleteRuleCode := ExpandMetaVariables(c_delete_no_action);
    end
    else if qList.FieldByName('delete_rule').AsTrimString = 'RESTRICT' then
    begin
      DeleteRuleCode := ExpandMetaVariables(c_delete_no_action);
    end
    else if qList.FieldByName('delete_rule').AsTrimString = 'SET NULL' then
    begin
      DeleteRuleCode := ExpandMetaVariables(c_delete_set_null);
    end else
      raise Exception.Create('Delete rule SET DEFAULT is not supported.');
    TriggerCode := StringReplace(ExpandMetaVariables(c_ad_ref_rel), '<delete_rule_code>',
      DeleteRuleCode, [rfReplaceAll, rfIgnoreCase]);
    TriggerCode := StringReplace(TriggerCode, '<trigger_name>',
      ExpandMetaVariables(c_ad_ref_rel_name), [rfReplaceAll, rfIgnoreCase]);
    InsertScript(TriggerCode);

    //TriggerCode := StringReplace(ExpandMetaVariables(c_bi_ref_rel), '<trigger_name>',
    //  ExpandMetaVariables(c_bi_ref_rel_name), [rfReplaceAll, rfIgnoreCase]);
    //InsertScript(TriggerCode);

    InsertScript(ExpandMetaVariables(c_drop_constraint));
    InsertScript(ExpandMetaVariables(c_update_trigger));
    InsertScript(ExpandMetaVariables(c_update_checkid));
  end;

  procedure ConvertToCheck;
  begin
    if qList.FieldByName('check_id').AsTrimString <> '' then
      InsertScript(ExpandMetaVariables(c_create_check));

    InsertScript(ExpandMetaVariables(c_drop_constraint));
    InsertScript(ExpandMetaVariables(c_update_check));
  end;

  procedure ConvertToFKFromTrigger;
  var
    UpdateRule, DeleteRule: String;
  begin
    //InsertScript('DROP TRIGGER ' + ExpandMetaVariables(c_bi_ref_rel_name));
    InsertScript('DROP TRIGGER ' + ExpandMetaVariables(c_ad_ref_rel_name));
    InsertScript('DROP TRIGGER ' + ExpandMetaVariables(c_au_ref_rel_name));
    InsertScript('DROP TRIGGER ' + ExpandMetaVariables(c_au_constraint_rel_name));
    InsertScript('DROP TRIGGER ' + ExpandMetaVariables(c_ai_constraint_rel_name));

    if qList.FieldByName('update_rule').AsTrimString = 'RESTRICT' then
      UpdateRule := ''
    else
      UpdateRule := ExpandMetaVariables('ON UPDATE <update_rule> ');

    if qList.FieldByName('delete_rule').AsTrimString = 'RESTRICT' then
      DeleteRule := ''
    else
      DeleteRule := ExpandMetaVariables('ON DELETE <delete_rule> ');

    InsertScript(ExpandMetaVariables(c_create_constraint) + UpdateRule + DeleteRule);
    InsertScript(ExpandMetaVariables(c_update_original));
  end;

  procedure ConvertToFKFromCheck;
  var
    UpdateRule, DeleteRule: String;
  begin
    if qList.FieldByName('check_id').AsTrimString <> '' then
      InsertScript(ExpandMetaVariables(c_drop_constraint_check));
    InsertScript(ExpandMetaVariables(c_update_checkid));

    if qList.FieldByName('update_rule').AsTrimString = 'RESTRICT' then
      UpdateRule := ''
    else
      UpdateRule := ExpandMetaVariables('ON UPDATE <update_rule> ');

    if qList.FieldByName('delete_rule').AsTrimString = 'RESTRICT' then
      DeleteRule := ''
    else
      DeleteRule := ExpandMetaVariables('ON DELETE <delete_rule> ');

    InsertScript(ExpandMetaVariables(c_create_constraint) + UpdateRule + DeleteRule);
    InsertScript(ExpandMetaVariables(c_update_original));
  end;

begin
  I := 0;

  Tr := TIBTransaction.Create(nil);
  qList := TIBSQL.Create(nil);
  qScript := TIBSQL.Create(nil);
  try
    Tr.DefaultDatabase := gdcBaseManager.Database;
    Tr.StartTransaction;

    qList.Transaction := Tr;
    qList.SQL.Text := 'SELECT * FROM at_transaction';
    qList.ExecQuery;

    if not qList.EOF then
    begin
      MessageBox(ParentHandle,
        '���������� ��������� ��������� �� �� ���� ���������. ������������� �������.',
        '��������',
        MB_OK or MB_ICONEXCLAMATION or MB_TASKMODAL);
      Result := -1;
      exit;
    end;

    qList.Close;
    qList.SQL.Text := 'SELECT * FROM gd_ref_constraints WHERE ref_state <> ref_next_state ';
    qList.ExecQuery;

    qScript.Transaction := Tr;
    qScript.SQL.Text :=
      'INSERT INTO at_transaction (trkey, numorder, script, successfull) ' +
      'VALUES (:trkey, :numorder, :script, 1)';
    SetTID(qScript.ParamByName('trkey'), GetNextID);

    while not qList.EOF do
    begin
      if qList.FieldByName('ref_next_state').AsTrimString = 'TRIGGER' then
        ConvertToTrigger;
      if qList.FieldByName('ref_next_state').AsTrimString = 'CHECK' then
        ConvertToCheck;
      if (qList.FieldByName('ref_next_state').AsTrimString = 'ORIGINAL')
        and (qList.FieldByName('ref_state').AsTrimString = 'TRIGGER')  then
        ConvertToFKFromTrigger;
      if (qList.FieldByName('ref_next_state').AsTrimString = 'ORIGINAL')
        and (qList.FieldByName('ref_state').AsTrimString = 'CHECK')  then
        ConvertToFKFromCheck;

      qList.Next;
    end;

    if qList.RecordCount > 0 then
      InsertScript('DELETE FROM gd_ref_constraints WHERE ref_state = ref_next_state ' +
        '  AND ref_next_state = ''ORIGINAL'' ');

    Result := qList.RecordCount;
    Tr.Commit;
  finally
    qScript.Free;
    qList.Free;
    Tr.Free;
  end;
end;

destructor TgdcFKManager.Destroy;
begin
  if IsUpdateStatsRunning then
    CancelUpdateStats;
  FThread.Free;
  inherited;
end;

procedure TgdcFKManager.DoAfterOpen;
var
  {@UNFOLD MACRO INH_ORIG_PARAMS()}
  {M}
  {M}  Params, LResult: Variant;
  {M}  tmpStrings: TStackStrings;
  {END MACRO}
begin
  {@UNFOLD MACRO INH_ORIG_WITHOUTPARAM('TGDCFKMANAGER', 'DOAFTEROPEN', KEYDOAFTEROPEN)}
  {M}  try
  {M}    if (not FDataTransfer) and Assigned(gdcBaseMethodControl) then
  {M}    begin
  {M}      SetFirstMethodAssoc('TGDCFKMANAGER', KEYDOAFTEROPEN);
  {M}      tmpStrings := TStackStrings(ClassMethodAssoc.IntByKey[KEYDOAFTEROPEN]);
  {M}      if (tmpStrings = nil) or (tmpStrings.IndexOf('TGDCFKMANAGER') = -1) then
  {M}      begin
  {M}        Params := VarArrayOf([GetGdcInterface(Self)]);
  {M}        if gdcBaseMethodControl.ExecuteMethodNew(ClassMethodAssoc, Self, 'TGDCFKMANAGER',
  {M}          'DOAFTEROPEN', KEYDOAFTEROPEN, Params, LResult) then exit;
  {M}      end else
  {M}        if tmpStrings.LastClass.gdClassName <> 'TGDCFKMANAGER' then
  {M}        begin
  {M}          Inherited;
  {M}          Exit;
  {M}        end;
  {M}    end;
  {END MACRO}

  inherited;

  FieldByName('constraint_name').ReadOnly := True;
  FieldByName('const_name_uq').ReadOnly := True;
  FieldByName('match_option').ReadOnly := True;
  FieldByName('update_rule').ReadOnly := True;
  FieldByName('delete_rule').ReadOnly := True;
  FieldByName('constraint_rel').ReadOnly := True;
  FieldByName('constraint_field').ReadOnly := True;
  FieldByName('ref_rel').ReadOnly := True;
  FieldByName('ref_field').ReadOnly := True;
  FieldByName('ref_state').ReadOnly := True;

  {@UNFOLD MACRO INH_ORIG_FINALLY('TGDCFKMANAGER', 'DOAFTEROPEN', KEYDOAFTEROPEN)}
  {M}  finally
  {M}    if (not FDataTransfer) and Assigned(gdcBaseMethodControl) then
  {M}      ClearMacrosStack2('TGDCFKMANAGER', 'DOAFTEROPEN', KEYDOAFTEROPEN);
  {M}  end;
  {END MACRO}
end;

class function TgdcFKManager.GetDialogFormClassName(
  const ASubType: TgdcSubType): String;
begin
  Result := 'Tgdc_dlgFKManager';
end;

class function TgdcFKManager.GetListField(
  const ASubType: TgdcSubType): String;
begin
  Result := 'constraint_name';
end;

class function TgdcFKManager.GetListTable(
  const ASubType: TgdcSubType): String;
begin
  Result := 'gd_ref_constraints';
end;

class function TgdcFKManager.GetViewFormClassName(
  const ASubType: TgdcSubType): String;
begin
  Result := 'Tgdc_frmFKManager';
end;

function TgdcFKManager.IsUpdateStatsRunning: Boolean;
begin
  Result := (FThread <> nil) and (not FThread.Finished);
end;

procedure TgdcFKManager.SyncWithSystemMetadata;
var
  Tr, Tr_ins: TIBTransaction;
  q, q_ins: TIBSQL;
begin
  Tr := TIBTransaction.Create(nil);
  Tr_ins := TIBTransaction.Create(nil);
  q := TIBSQL.Create(nil);
  q_ins := TIBSQL.Create(nil);
  try
    Tr.Params.Text := 'concurrency'#13#10'nowait';
    Tr.DefaultDatabase := gdcBaseManager.Database;

    Tr_ins.Params.Text := 'concurrency'#13#10'nowait';
    Tr_ins.DefaultDatabase := gdcBaseManager.Database;

    Tr.StartTransaction;

    q.Transaction := Tr;
    q.SQL.Text :=
      'DELETE FROM gd_ref_constraints WHERE constraint_rel NOT IN ' +
      '  (SELECT rdb$relation_name FROM rdb$relations) ';
    q.ExecQuery;

    q.Close;
    q.SQL.Text :=
      'DELETE FROM gd_ref_constraints WHERE ref_rel NOT IN ' +
      '  (SELECT rdb$relation_name FROM rdb$relations) ';
    q.ExecQuery;

    q.Close;
    q.SQL.Text :=
      'DELETE FROM gd_ref_constraints WHERE constraint_name NOT IN ' +
      '  (SELECT rdb$constraint_name FROM rdb$ref_constraints) AND ref_state = ''ORIGINAL'' ';
    q.ExecQuery;

    Tr.Commit;
    Tr.StartTransaction;

    q.Close;
    q.SQL.Text :=
      '    SELECT '#13#10 +
      '      r.rdb$constraint_name CONSTRAINT_NAME, '#13#10 +
      '      r.rdb$const_name_uq CONST_NAME_UQ, '#13#10 +
      '      r.rdb$match_option MATCH_OPTION, '#13#10 +
      '      r.rdb$update_rule UPDATE_RULE, '#13#10 +
      '      r.rdb$delete_rule DELETE_RULE, '#13#10 +
      '      fk_i.rdb$relation_name CONSTRAINT_REL, '#13#10 +
      '      fk_is.rdb$field_name CONSTRAINT_FIELD, '#13#10 +
      '      pk_i.rdb$relation_name REF_REL, '#13#10 +
      '      pk_is.rdb$field_name REF_FIELD, '#13#10 +
      '      ''ORIGINAL'' REF_STATE,'#13#10 +
      '      ''ORIGINAL'' REF_NEXT_STATE'#13#10 +
      '    FROM '#13#10 +
      '      rdb$ref_constraints r '#13#10 +
      '    JOIN rdb$relation_constraints fk ON r.rdb$constraint_name = fk.rdb$constraint_name '#13#10 +
      '    JOIN rdb$relation_constraints pk ON r.rdb$const_name_uq = pk.rdb$constraint_name '#13#10 +
      '    JOIN rdb$indices pk_i ON pk_i.rdb$index_name = pk.rdb$index_name '#13#10 +
      '    JOIN rdb$indices fk_i ON fk_i.rdb$index_name = fk.rdb$index_name '#13#10 +
      '    JOIN rdb$index_segments pk_is ON pk_is.rdb$index_name = pk_i.rdb$index_name '#13#10 +
      '    JOIN rdb$index_segments fk_is ON fk_is.rdb$index_name = fk_i.rdb$index_name '#13#10 +
      '    JOIN rdb$relation_fields pk_rf ON pk_rf.rdb$relation_name = pk_i.rdb$relation_name '#13#10 +
      '          AND pk_rf.rdb$field_name = pk_is.rdb$field_name '#13#10 +
      '    JOIN rdb$fields pk_f ON pk_f.rdb$field_name = pk_rf.rdb$field_source '#13#10 +
      '    JOIN rdb$relations fk_r ON fk_r.rdb$relation_name = fk_i.rdb$relation_name '#13#10 +
      '    JOIN rdb$relations pk_r ON pk_r.rdb$relation_name = pk_i.rdb$relation_name '#13#10 +
      '    WHERE '#13#10 +
      '      pk_i.rdb$segment_count = 1 AND '#13#10 +
      '      fk_i.rdb$segment_count = 1 AND '#13#10 +
      '      pk_f.rdb$field_type = 8 AND '#13#10 +
      '      fk_r.rdb$relation_name <> ''GD_REF_CONSTRAINT_DATA'' AND '#13#10 +
      '      COALESCE(fk_r.rdb$system_flag, 0) <> 1 AND '#13#10 +
      '      COALESCE(pk_r.rdb$system_flag, 0) <> 1 AND '#13#10 +
      '      r.rdb$update_rule <> ''SET DEFAULT'' AND '#13#10 +
      '      r.rdb$delete_rule <> ''SET DEFAULT'' AND '#13#10 +
      '  r.rdb$constraint_name NOT IN (SELECT constraint_name FROM gd_ref_constraints) ';
    q.ExecQuery;

    q_ins.Transaction := Tr_ins;
    q_ins.SQL.Text :=
      'INSERT INTO GD_REF_CONSTRAINTS ( '#13#10 +
      ' ID, CONSTRAINT_NAME, CONST_NAME_UQ, MATCH_OPTION, '#13#10 +
      ' UPDATE_RULE, DELETE_RULE, CONSTRAINT_REL, CONSTRAINT_FIELD, '#13#10 +
      ' REF_REL, REF_FIELD, REF_STATE, REF_NEXT_STATE ) '#13#10 +
      'VALUES ( '#13#10 +
      ' :ID, :CONSTRAINT_NAME, :CONST_NAME_UQ, :MATCH_OPTION, '#13#10 +
      ' :UPDATE_RULE, :DELETE_RULE, :CONSTRAINT_REL, :CONSTRAINT_FIELD, '#13#10 +
      ' :REF_REL, :REF_FIELD, :REF_STATE, :REF_NEXT_STATE )';

    while not q.eof do
    begin
      Tr_ins.StartTransaction;
      SetTID(q_ins.ParamByName('ID'), GetNextID);
      q_ins.ParamByName('CONSTRAINT_NAME').Value := q.FieldByName('CONSTRAINT_NAME').Value;
      q_ins.ParamByName('CONST_NAME_UQ').Value := q.FieldByName('CONST_NAME_UQ').Value;
      q_ins.ParamByName('MATCH_OPTION').Value := q.FieldByName('MATCH_OPTION').Value;
      q_ins.ParamByName('UPDATE_RULE').Value := q.FieldByName('UPDATE_RULE').Value;
      q_ins.ParamByName('DELETE_RULE').Value := q.FieldByName('DELETE_RULE').Value;
      q_ins.ParamByName('CONSTRAINT_REL').Value := q.FieldByName('CONSTRAINT_REL').Value;
      q_ins.ParamByName('CONSTRAINT_FIELD').Value := q.FieldByName('CONSTRAINT_FIELD').Value;
      q_ins.ParamByName('REF_REL').Value := q.FieldByName('REF_REL').Value;
      q_ins.ParamByName('REF_FIELD').Value := q.FieldByName('REF_FIELD').Value;
      q_ins.ParamByName('REF_STATE').Value := q.FieldByName('REF_STATE').Value;
      q_ins.ParamByName('REF_NEXT_STATE').Value := q.FieldByName('REF_NEXT_STATE').Value;
      q_ins.ExecQuery;
      Tr_ins.Commit;

      q.Next;
    end;

    Tr.Commit;
  finally
    q_ins.Free;
    q.Free;
    Tr_ins.Free;
    Tr.Free;
  end;
end;

procedure TgdcFKManager.UpdateStats(AHandle: THandle);
begin
  if IsUpdateStatsRunning then
    exit;

  if FThread <> nil then
    FThread.Free;

  FThread := TgdcFKManagerThread.Create(False);
  FThread.FWindowHandle := AHandle;
end;

{ TgdcFKManagerThread }

procedure TgdcFKManagerThread.ClearScreen;
begin
  if FWindowHandle <> 0 then
    PostMessage(FWindowHandle, WM_UPDATESTATS, CMD_CLEAR, 0);
end;

procedure TgdcFKManagerThread.DoneScreen;
begin
  if FWindowHandle <> 0 then
    PostMessage(FWindowHandle, WM_UPDATESTATS, CMD_DONE, 0);
end;

procedure TgdcFKManagerThread.Execute;
var
  FDB: TIBDatabase;
  Tr, TrStat: TIBTransaction;
  qList, qCalc: TIBSQL;
begin
  FDB := TIBDatabase.Create(nil);
  Tr := TIBTransaction.Create(nil);
  TrStat := TIBTransaction.Create(nil);
  qList := TIBSQL.Create(nil);
  qCalc := TIBSQL.Create(nil);
  try
    FDB.DatabaseName := gdcBaseManager.Database.DatabaseName;
    FDB.Params.Assign(gdcBaseManager.Database.Params);
    FDB.LoginPrompt := False;
    FDB.Connected := True;

    Tr.DefaultDatabase := FDB;
    Tr.StartTransaction;

    TrStat.DefaultDatabase := FDB;
    qCalc.Transaction := TrStat;

    qList.Transaction := Tr;
    qList.SQL.Text := 'SELECT COUNT(rdb$index_name) FROM rdb$indices';
    qList.ExecQuery;
    FTotalCount := qList.Fields[0].AsInteger;
    FDone := 0;
    Synchronize(InitScreen);

    qList.Close;
    qList.SQL.Text := 'SELECT rdb$index_name FROM rdb$indices';
    qList.ExecQuery;

    while (not Terminated) and (not qList.EOF) do
    begin
      TrStat.StartTransaction;
      qCalc.SQL.Text := 'SET STATISTICS INDEX "' + qList.Fields[0].AsTrimString + '"';
      qCalc.ExecQuery;
      qCalc.Close;
      TrStat.Commit;

      Inc(FDone);
      Synchronize(UpdateScreen);

      qList.Next;
    end;

    qList.Close;

    Synchronize(DoneScreen);
    Tr.Commit;
  finally
    qCalc.Free;
    qList.Free;
    Tr.Free;
    TrStat.Free;
    FDB.Free;
    FFinished := True;
  end;
end;

procedure TgdcFKManagerThread.InitScreen;
begin
  if FWindowHandle <> 0 then
    PostMessage(FWindowHandle, WM_UPDATESTATS, CMD_INIT, FTotalCount);
end;

procedure TgdcFKManagerThread.UpdateScreen;
begin
  if FWindowHandle <> 0 then
    PostMessage(FWindowHandle, WM_UPDATESTATS, CMD_UPDATE, FDone);
end;

initialization
  RegisterGdcClass(TgdcFKManager, '������� ����');

finalization
  UnregisterGdcClass(TgdcFKManager);
end.
