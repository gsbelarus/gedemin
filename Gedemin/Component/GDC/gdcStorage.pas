// ShlTanya, 10.02.2019

{

  1. ��� ��������� -- ��� ��� ��� �������� �����.
  2. ������� ��������� ���������; �������������� ������������� ���������
     ��� �������� ����� -- GLOBAL, USER, COMPANY.
  3. ����� ����� �������� ���������, �������� ����� ����� ������� Changed=False
     � ID = -1.
  4. ��� �������� ��������� �� ����, ��� � ID �������� ����� �����������
     �� �������. ����� �������� ��������������� Changed=False.
  5. ����� ������� � �� ������������ � ������������� ��� �������� ����� �
     ������������ � ����� ���������.
}


unit gdcStorage;

{ DONE 5 -oandreik -cStorage : ��� �������� ������������, ��������, ��������, ������� ��������� }
{ DONE 5 -oandreik -cStorage : Assert �� IBLogin, � ���������� gdcBasemanager }
{ DONE 5 -oandreik -cStorage : ��������� ������ ������. ������������ �������� � ������������� }
{ DONE 5 -oandreik -cStorage : �������� ����������. ������� ��������� ��� ���������� � �������� �� ���� }
{ DONE 5 -oandreik -cStorage : � ����� ��������� ��������� ��������� ������ }
{ DONE 5 -oandreik -cStorage : ������ �� TdlgToSetting.Setup ���, ������� �������� � ���� �� �������}
{ DONE 5 -oandreik -cStorage : ������ InSett ������ ����������� �����������}
{ DONE 5 -oandreik -cStorage : BLOBs like QUADs! }
{ DONE 5 -oandreik -cStorage : ������������� ����� �� ������������ ��������� �������� }
{ DONE 5 -oandreik -cStorage : ������������ � ������������ ������ ����� � �������������� �� ��� �������� �������� }
{ DONE 5 -oandreik -cStorage : CheckTheSameStatement ��� �������� ����� ��������� ����� ��������� }
{ DONE 5 -oandreik -cStorage : ����� � �������� �� ������ }
{ DONE 5 -oandreik -cStorage : �������� �� ��� �������� ��� �������� �� �� ����� �� ������ }
{ DONE 5 -oandreik -cStorage : ��������� ��������� ��������� }
{ DONE 5 -oandreik -cStorage : ����� ���������� �� ������ ������� ������? property ID read only? }
{ DONE 5 -oandreik -cStorage : ������������� DFM ���� }
{ DONE 5 -oandreik -cStorage : ������������� DFM ����, ���� ��� ������������� ������ ���������� ������ }
{ DONE 5 -oandreik -cStorage : TwrpGsStorageFolder.DropFolder ������������� }
{ DONE 5 -oandreik -cStorage : ���� �� �������������� ��������� ��� �����? }
{ DONE 5 -oandreik -cStorage : � ��� ���� � ���������� ��� �����? }
{ DONE 5 -oandreik -cStorage : ������ � ���������� ��� ����� }
{ DONE 5 -oandreik -cStorage : ��� ������ � ����������� ���������� ��������� ������������? }

{ TODO 5 -oandreik -cStorage : ����� � gdcStreamSaver ����������� ���� IsModified ���������? }
{ TODO 5 -oandreik -cStorage : ����������� ������� � ����� TIBSQL ����� �������, � �� �� ����� }
{ TODO 5 -oandreik -cStorage : ����� ����� ��� ������� � ����� }
{ TODO 5 -oandreik -cStorage : ��������� � STorage ��� ������� �������� }
{ TODO 5 -oandreik -cStorage : ��� ����������� �� ����� �������������� ��� ��������� � ����������� }
{ TODO 5 -oandreik -cStorage : ���� �� ������������ �������� ����� ��������� ����� �� ����? }
{ TODO 5 -oandreik -cStorage : ����� �� � ���� ��������� ��������� ������������ �������� �����? }
{ TODO 5 -oandreik -cStorage : ����� ���������� ���������� ��������� ��������������? }
{ TODO 5 -oandreik -cStorage : �������� ������ ����� �������, � �� ����� ���������� ������ }
{ TODO 5 -oandreik -cStorage : TwrpGsStorageFolder.LoadFromDatabase ��������� �� ������� TgsIBStorage }
{ TODO 5 -oandreik -cStorage : Changed ����� �������� ������� � ����� �������� �� ������.
  �� ������: �������, �����������, �������� �����   }
{ TODO 5 -oandreik -cStorage : procedure TgdcUser.CopySettingsByUser(U: Integer; ibtr: TIBTransaction); }
{ TODO 5 -oandreik -cStorage : � ������������ �������� ���������� �� ���� � ���������� � ����� }
{ TODO 5 -oandreik -cStorage : ����������� � ��������������� �������� � ����� ��������� }
{ TODO 5 -oandreik -cStorage : ����������� �������� ��� �������� ������ ������������ ��������� }
{ TODO 5 -oandreik -cStorage : �� ����������� �� ������ ���������� ��������� ���� '. ID=', ������� ��� ��� ��� ���� }
{ TODO 5 -oandreik -cStorage : � ��������� ������������� ObjectKey ��� ��������� � XXXKey? }

interface

uses
  Classes, IBCustomDataSet, gdcBase, Forms, gd_createable_form, Controls, DB,
  gdcBaseInterface, IBDataBase, gdcTree, gsStorage;

type
  TgdcStorage = class(TgdcTree)
  protected
    procedure _DoOnNewRecord; override;
    procedure DoAfterPost; override;
    procedure DoBeforeInsert; override;
    procedure DoBeforeEdit; override;
    procedure DoBeforeDelete; override;

    function GetTreeInsertMode: TgdcTreeInsertMode; override;

  public
    class function GetListTable(const ASubType: TgdcSubType): String; override;
    class function GetListField(const ASubType: TgdcSubType): String; override;
    class function GetViewFormClassName(const ASubType: TgdcSubType): String; override;
    class function NeedModifyFromStream(const SubType: String): Boolean; override;

    function CheckTheSameStatement: String; override;
    function GetCurrRecordClass: TgdcFullClass; override;

    function FindStorageItem(out SI: TgsStorageItem): Boolean; overload;
    function FindStorageItem(const AnID: TID; out SI: TgsStorageItem): Boolean; overload;
  end;

  TgdcStorageFolder = class(TgdcStorage)
  protected
    procedure GetWhereClauseConditions(S: TStrings); override;
    function GetCanDelete: Boolean; override;

  public
    class function GetDialogFormClassName(const ASubType: TgdcSubType): String; override;
    class function GetRestrictCondition(const ATableName, ASubType: String): String; override;
  end;

  TgdcStorageValue = class(TgdcStorage)
  protected
    procedure GetWhereClauseConditions(S: TStrings); override;

  public
    class function GetDialogFormClassName(const ASubType: TgdcSubType): String; override;
    class function GetRestrictCondition(const ATableName, ASubType: String): String; override;
  end;

  CgdcStorage = class of TgdcStorage;
  CgdcStorageFolder = class of TgdcStorageFolder;
  CgdcStorageValue = class of TgdcStorageValue;

procedure Register;
procedure ConvertStorageRecords(const ASettingKey: TID; AnDatabase: TIBDatabase);

implementation

uses
  Windows,
  Graphics,
  SysUtils,
  IBSQL,
  at_frmSQLProcess,
  gd_directories_const,
  gdcStorage_Types,
  gdc_dlgStorageValue_unit,
  gdc_dlgStorageFolder_unit,
  gdc_frmStorage_unit,
  gd_ClassList,
  gd_security,
  Storages,
  IB, IBErrorCodes;

procedure Register;
begin
  RegisterComponents('gdc', [TgdcStorage, TgdcStorageFolder, TgdcStorageValue]);
end;

procedure ConvertStorageRecords(const ASettingKey: TID; AnDatabase: TIBDatabase);

  function AdjustName(const SI: TgsStorageItem): String;
  const
    dname_length = 60;
  var
    LP, LN, D: Integer;
    SN: String;
  begin
    if SI.Storage is TgsUserStorage then
      SN := 'U'
    else if SI.Storage is TgsGlobalStorage then
      SN := 'G'
    else
      raise Exception.Create('Unsupported storage type');

    LP := Length(SI.Path);
    LN := Length(SN);
    D := dname_length - LN - LP; // 60 = length of dname domain
    if D >= 0 then
      Result := SN + SI.Path
    else begin
      D := D - 3;      // 3 = length of '...'
      Result := Copy(SN + '\...' + Copy(SI.Path, 2 - D, 256), 1, dname_length);
    end;
  end;

var
  q, qPos: TIBSQL;
  Tr: TIBTransaction;
  S: String;
  P: Integer;
  XID: TID;
  DBID: Integer;
  F: TgsStorageFolder;
  V: TgsStorageValue;

begin
  Tr := TIBTransaction.Create(nil);
  q := TIBSQL.Create(nil);
  qPos := TIBSQL.Create(nil);
  try
    Tr.DefaultDatabase := AnDatabase;
    Tr.StartTransaction;

    q.Transaction := Tr;
    q.SQL.Text :=
      'SELECT * FROM at_setting_storage WHERE settingkey = :settingkey AND (NOT branchname LIKE ''#%'')';
    SetTID(q.ParamByName('settingkey'), ASettingKey);
    q.ExecQuery;

    qPos.Transaction := Tr;
    qPos.SQL.Text := 'INSERT INTO at_settingpos (settingkey, objectclass, ' +
      'category, objectname, dbid, xid, withdetail, needmodify, autoadded) ' +
      'VALUES (:SK, :OC, :CAT, :ON, :DBID, :XID, :WD, :NM, :AA)';

    while not q.EOF do
    begin
      S := q.FieldByName('branchname').AsString;
      P := Pos('\', S);
      if P = 0 then
        continue;

      if Pos('GLOBAL', S) = 1 then
        F := GlobalStorage.OpenFolder(System.Copy(S, P + 1, 1024), False, False)
      else
        F := UserStorage.OpenFolder(System.Copy(S, P + 1, 1024), False, False);

      if F = nil then
      begin
        if MessageBox(0,
          PChar('����� ��������� "' + S + '" ����������� � ���� ������.'#13#10#13#10 +
          '������� �� �� ���������?'),
          '��������',
          MB_YESNO or MB_ICONQUESTION or MB_TASKMODAL) = ID_NO then
        begin
          raise Exception.Create('Can not find storage folder "' + S + '"');
        end;
      end else
        try
          if q.FieldByName('valuename').IsNull then
          begin
            qPos.ParamByName('ON').AsString := AdjustName(F);
            qPos.ParamByName('OC').AsString := CgdcStorageFolder.ClassName;
            gdcBaseManager.GetRUIDByID(F.ID, XID, DBID);
            AddText('����������� � �� ����� ' + S);
          end else
          begin
            V := F.ValueByName(q.FieldByName('valuename').AsString);

            if V = nil then
            begin
              if MessageBox(0,
                PChar('�������� ��������� "' + S + '\' + q.FieldByName('valuename').AsString +
                '" ����������� � ���� ������.'#13#10#13#10 +
                '������� ��� �� ���������?'),
                '��������',
                MB_YESNO or MB_ICONQUESTION or MB_TASKMODAL) = ID_NO then
              begin
                raise Exception.Create('Can not find storage value "' +
                  S + '\' + q.FieldByName('valuename').AsString + '"');
              end else
              begin
                q.Next;
                continue;
              end;
            end;

            qPos.ParamByName('ON').AsString := AdjustName(V);
            qPos.ParamByName('OC').AsString := CgdcStorageValue.ClassName;
            gdcBaseManager.GetRUIDByID(V.ID, XID, DBID);
            AddText('����������� � �� �������� ' + S + '\' + V.Name);
          end;

          SetTID(qPos.ParamByName('SK'), ASettingKey);
          qPos.ParamByName('WD').AsInteger := 1;
          qPos.ParamByName('NM').AsInteger := 1;
          qPos.ParamByName('AA').AsInteger := 0;
          SetTID(qPos.ParamByName('XID'), XID);
          qPos.ParamByName('DBID').AsInteger := DBID;
          qPos.ParamByName('CAT').AsString := TgdcStorage.GetListTable('');

          try
            qPos.ExecQuery;
          except
            on E: EIBInterbaseError do
            begin
              if E.IBErrorCode = isc_unique_key_violation then
                AddWarning('��� ����������� ��������� �������� ������������� �������.', clBlack)
              else
                raise;
            end
            else
              raise;
          end;
        finally
          F.Storage.CloseFolder(F, False);
        end;

      q.Next;
    end;

    q.Close;
    q.SQL.Text :=
      'UPDATE at_setting_storage SET branchname = ''#'' || branchname ' +
      '  WHERE settingkey = :settingkey AND (NOT branchname LIKE ''#%'')';
    SetTID(q.ParamByName('settingkey'), ASettingKey);
    q.ExecQuery;

    Tr.Commit;
  finally
    qPos.Free;
    q.Free;
    Tr.Free;
  end;
end;

{ TgdcStorage ------------------------------------------------}

class function TgdcStorage.GetListField(const ASubType: TgdcSubType): String;
begin
  Result := 'NAME';
end;

class function TgdcStorage.GetListTable(const ASubType: TgdcSubType): String;
begin
  Result := 'GD_STORAGE_DATA';
end;

class function TgdcStorage.GetViewFormClassName(
  const ASubType: TgdcSubType): String;
begin
  Result := 'Tgdc_frmStorage';
end;

function TgdcStorage.FindStorageItem(out SI: TgsStorageItem): Boolean;
begin
  Result := FindStorageItem(ID, SI);
end;

{ TgdcStorageValue }

class function TgdcStorageValue.GetDialogFormClassName(
  const ASubType: TgdcSubType): String;
begin
  Result := 'Tgdc_dlgStorageValue';
end;

class function TgdcStorageValue.GetRestrictCondition(const ATableName,
  ASubType: String): String;
begin
  if AnsiCompareText(ATableName, GetListTable(ASubType)) = 0 then
    Result := Format('%s.data_type IN (''S'', ''I'', ''C'', ''D'', ''L'', ''B'')', [GetListTableAlias])
  else
    Result := inherited GetRestrictCondition(ATableName, ASubType);
end;

procedure TgdcStorageValue.GetWhereClauseConditions(S: TStrings);
begin
  inherited;
  S.Add(GetRestrictCondition(GetListTable(SubType), SubType));
end;

{ TgdcStorageFolder }

function TgdcStorageFolder.GetCanDelete: Boolean;
begin
  Result := inherited GetCanDelete and (not FieldByName('parent').IsNull);
end;

class function TgdcStorageFolder.GetDialogFormClassName(
  const ASubType: TgdcSubType): String;
begin
  Result := 'Tgdc_dlgStorageFolder';
end;

class function TgdcStorageFolder.GetRestrictCondition(const ATableName,
  ASubType: String): String;
begin
  if AnsiCompareText(ATableName, GetListTable(ASubType)) = 0 then
    Result := Format('%s.data_type IN (''F'', ''G'', ''U'', ''O'', ''T'')', [GetListTableAlias])
  else
    Result := inherited GetRestrictCondition(ATableName, ASubType);
end;

procedure TgdcStorageFolder.GetWhereClauseConditions(S: TStrings);
begin
  inherited;
  S.Add(GetRestrictCondition(GetListTable(SubType), SubType));
end;

function TgdcStorage.GetCurrRecordClass: TgdcFullClass;
begin
  Result.gdClass := CgdcBase(Self.ClassType);
  Result.SubType := SubType;

  if (not IsEmpty) and (Length(FieldByName('data_type').AsString) = 1) then
  begin
    case FieldByName('data_type').AsString[1] of
      cStorageGlobal, cStorageUser, cStorageCompany,
      cStorageDesktop, cStorageFolder:
        Result.gdClass := TgdcStorageFolder;

      cStorageInteger, cStorageString, cStorageBoolean,
      cStorageDateTime, cStorageCurrency, cStorageBLOB:
        Result.gdClass := TgdcStorageValue;
    end;
  end;

  FindInheritedSubType(Result);
end;

procedure TgdcStorage._DoOnNewRecord;
var
  {@UNFOLD MACRO INH_ORIG_PARAMS()}
  {M}
  {M}  Params, LResult: Variant;
  {M}  tmpStrings: TStackStrings;
  {END MACRO}
begin
  {@UNFOLD MACRO INH_ORIG_WITHOUTPARAM('TGDCSTORAGE', '_DOONNEWRECORD', KEY_DOONNEWRECORD)}
  {M}  try
  {M}    if (not FDataTransfer) and Assigned(gdcBaseMethodControl) then
  {M}    begin
  {M}      SetFirstMethodAssoc('TGDCSTORAGE', KEY_DOONNEWRECORD);
  {M}      tmpStrings := TStackStrings(ClassMethodAssoc.IntByKey[KEY_DOONNEWRECORD]);
  {M}      if (tmpStrings = nil) or (tmpStrings.IndexOf('TGDCSTORAGE') = -1) then
  {M}      begin
  {M}        Params := VarArrayOf([GetGdcInterface(Self)]);
  {M}        if gdcBaseMethodControl.ExecuteMethodNew(ClassMethodAssoc, Self, 'TGDCSTORAGE',
  {M}          '_DOONNEWRECORD', KEY_DOONNEWRECORD, Params, LResult) then exit;
  {M}      end else
  {M}        if tmpStrings.LastClass.gdClassName <> 'TGDCSTORAGE' then
  {M}        begin
  {M}          Inherited;
  {M}          Exit;
  {M}        end;
  {M}    end;
  {END MACRO}

  if Self.InheritsFrom(TgdcStorageValue) then
    FieldByName('data_type').AsString := cStorageInteger
  else
    FieldByName('data_type').AsString := cStorageFolder;

  inherited;

  {@UNFOLD MACRO INH_ORIG_FINALLY('TGDCSTORAGE', '_DOONNEWRECORD', KEY_DOONNEWRECORD)}
  {M}  finally
  {M}    if (not FDataTransfer) and Assigned(gdcBaseMethodControl) then
  {M}      ClearMacrosStack2('TGDCSTORAGE', '_DOONNEWRECORD', KEY_DOONNEWRECORD);
  {M}  end;
  {END MACRO}
end;

procedure TgdcStorage.DoBeforeEdit;
  {@UNFOLD MACRO INH_ORIG_PARAMS(VAR)}
  {M}VAR
  {M}  Params, LResult: Variant;
  {M}  tmpStrings: TStackStrings;
  {END MACRO}
  SI: TgsStorageItem;
begin
  {@UNFOLD MACRO INH_ORIG_WITHOUTPARAM('TGDCSTORAGE', 'DOBEFOREEDIT', KEYDOBEFOREEDIT)}
  {M}  try
  {M}    if (not FDataTransfer) and Assigned(gdcBaseMethodControl) then
  {M}    begin
  {M}      SetFirstMethodAssoc('TGDCSTORAGE', KEYDOBEFOREEDIT);
  {M}      tmpStrings := TStackStrings(ClassMethodAssoc.IntByKey[KEYDOBEFOREEDIT]);
  {M}      if (tmpStrings = nil) or (tmpStrings.IndexOf('TGDCSTORAGE') = -1) then
  {M}      begin
  {M}        Params := VarArrayOf([GetGdcInterface(Self)]);
  {M}        if gdcBaseMethodControl.ExecuteMethodNew(ClassMethodAssoc, Self, 'TGDCSTORAGE',
  {M}          'DOBEFOREEDIT', KEYDOBEFOREEDIT, Params, LResult) then exit;
  {M}      end else
  {M}        if tmpStrings.LastClass.gdClassName <> 'TGDCSTORAGE' then
  {M}        begin
  {M}          Inherited;
  {M}          Exit;
  {M}        end;
  {M}    end;
  {END MACRO}

  if FindStorageItem(SI) and SI.Changed and (SI.Storage is TgsIBStorage) then
  begin
    (SI.Storage as TgsIBStorage).SaveToDatabase;
    Refresh;
  end;

  inherited;

  if IsEmpty or (not FieldByName('parent').IsNull) or (FieldByName('name').AsString = '') then
    FieldByName('name').ReadOnly := False
  else
    FieldByName('name').ReadOnly := True;

  {@UNFOLD MACRO INH_ORIG_FINALLY('TGDCSTORAGE', 'DOBEFOREEDIT', KEYDOBEFOREEDIT)}
  {M}  finally
  {M}    if (not FDataTransfer) and Assigned(gdcBaseMethodControl) then
  {M}      ClearMacrosStack2('TGDCSTORAGE', 'DOBEFOREEDIT', KEYDOBEFOREEDIT);
  {M}  end;
  {END MACRO}
end;

procedure TgdcStorage.DoAfterPost;
var
  {@UNFOLD MACRO INH_ORIG_PARAMS()}
  {M}
  {M}  Params, LResult: Variant;
  {M}  tmpStrings: TStackStrings;
  {END MACRO}
  SI, SIParent: TgsStorageItem;
  S: TStream;
  T1: Char;
  T2, ExMsg: String;
begin
  {@UNFOLD MACRO INH_ORIG_WITHOUTPARAM('TGDCSTORAGE', 'DOAFTERPOST', KEYDOAFTERPOST)}
  {M}  try
  {M}    if (not FDataTransfer) and Assigned(gdcBaseMethodControl) then
  {M}    begin
  {M}      SetFirstMethodAssoc('TGDCSTORAGE', KEYDOAFTERPOST);
  {M}      tmpStrings := TStackStrings(ClassMethodAssoc.IntByKey[KEYDOAFTERPOST]);
  {M}      if (tmpStrings = nil) or (tmpStrings.IndexOf('TGDCSTORAGE') = -1) then
  {M}      begin
  {M}        Params := VarArrayOf([GetGdcInterface(Self)]);
  {M}        if gdcBaseMethodControl.ExecuteMethodNew(ClassMethodAssoc, Self, 'TGDCSTORAGE',
  {M}          'DOAFTERPOST', KEYDOAFTERPOST, Params, LResult) then exit;
  {M}      end else
  {M}        if tmpStrings.LastClass.gdClassName <> 'TGDCSTORAGE' then
  {M}        begin
  {M}          Inherited;
  {M}          Exit;
  {M}        end;
  {M}    end;
  {END MACRO}

  if FDataTransfer then
  begin
    FieldByName('name').ReadOnly := False;
    exit;
  end;

  inherited;

  {
    ����� ����������: 1) ��������; 2) ������������; 3) ��������.
  }

  Assert(Length(FieldByName('data_type').AsString) = 1);

  LockStorage(True);
  try
    if FieldByName('parent').IsNull or (not FindStorageItem(GetTID(FieldByName('parent')), SIParent)) then
      SIParent := nil;

    if FindStorageItem(SI) then
    begin
      if SI.Name <> FieldByName('name').AsString then
        SI.Name := FieldByName('name').AsString;

      if (SIParent <> nil) and (SIParent <> SI.Parent) then
      begin
        (SI.Parent as TgsStorageFolder).RemoveChildren(SI);
        (SIParent as TgsStorageFolder).AddChildren(SI);
      end;

      T1 := SI.GetTypeName;
      T2 := FieldByName('data_type').AsString;
      if SI is TgsStorageValue then
      try
        case T1 of
          cStorageInteger:  TgsStorageValue(SI).AsInteger   := GetTID(FieldByName('int_data'));
          cStorageBoolean:  TgsStorageValue(SI).AsBoolean   := GetTID(FieldByName('int_data')) <> 0;
          cStorageCurrency: TgsStorageValue(SI).AsCurrency  := FieldByName('curr_data').AsCurrency;
          cStorageDateTime: TgsStorageValue(SI).AsDateTime  := FieldByName('datetime_data').AsDateTime;
          cStorageString:   TgsStorageValue(SI).AsString    := FieldByName('str_data').AsString;
          cStorageBLOB:     TgsStorageValue(SI).AsString    := FieldByName('blob_data').AsString;
        end;
      except
        on E: EgsStorageTypeCastError do
        begin
          ExMsg :=
            '������������ �������� ��������� ' + SI.Storage.Name + SI.Path + ' ����� ��� ' + T1 + '.'#13#10 +
            '��������, ����������� �� ������, ����� ��� ' + T2 + '.'#13#10#13#10 +
            '�������������� ��� ������������� �������� ��� ������� ���, ����� ��������� ����������� ���������.';

          raise EgsStorageTypeCastError.Create(ExMsg);
        end;
      end;
    end else
    begin
      if SIParent is TgsStorageFolder then
      begin
        case FieldByName('data_type').AsString[1] of
          cStorageFolder:
            TgsStorageFolder.Create(SIParent, FieldByName('name').AsString, ID);
          cStorageInteger:
            TgsIntegerValue.Create(SIParent, FieldByName('name').AsString, ID).AsInteger :=
              GetTID(FieldByName('int_data'));
          cStorageBoolean:
            TgsBooleanValue.Create(SIParent, FieldByName('name').AsString, ID).AsBoolean :=
              GetTID(FieldByName('int_data')) <> 0;
          cStorageCurrency:
            TgsCurrencyValue.Create(SIParent, FieldByName('name').AsString, ID).AsCurrency :=
              FieldByName('curr_data').AsCurrency;
          cStorageDateTime:
            TgsDateTimeValue.Create(SIParent, FieldByName('name').AsString, ID).AsDateTime :=
              FieldByName('datetime_data').AsDateTime;
          cStorageString:
            TgsStringValue.Create(SIParent, FieldByName('name').AsString, ID).AsString :=
              FieldByName('str_data').AsString;
          cStorageBLOB:
          begin
            S := CreateBlobStream(FieldByName('blob_data'), DB.bmRead);
            try
              TgsStreamValue.Create(SIParent, FieldByName('name').AsString, ID).LoadDataFromStream(S);
            finally
              S.Free;
            end;
          end;
        end;
      end else
        raise Exception.Create('Invalid parent! Storage item: ' + FieldByName('name').AsString);
    end;
  finally
    LockStorage(False);
  end;

  FieldByName('name').ReadOnly := False;

  {@UNFOLD MACRO INH_ORIG_FINALLY('TGDCSTORAGE', 'DOAFTERPOST', KEYDOAFTERPOST)}
  {M}  finally
  {M}    if (not FDataTransfer) and Assigned(gdcBaseMethodControl) then
  {M}      ClearMacrosStack2('TGDCSTORAGE', 'DOAFTERPOST', KEYDOAFTERPOST);
  {M}  end;
  {END MACRO}
end;

function TgdcStorage.FindStorageItem(const AnID: TID;
  out SI: TgsStorageItem): Boolean;
begin
  Result :=
    GlobalStorage.FindID(AnID, SI) or
    UserStorage.FindID(AnID, SI) or
    CompanyStorage.FindID(AnID, SI) or
    ((AdminStorage <> nil) and AdminStorage.FindID(AnID, SI));
end;

function TgdcStorage.CheckTheSameStatement: String;
  {@UNFOLD MACRO INH_ORIG_PARAMS(VAR)}
  {M}VAR
  {M}  Params, LResult: Variant;
  {M}  tmpStrings: TStackStrings;
  {END MACRO}
  S: String;
begin
  {@UNFOLD MACRO INH_ORIG_CHECKTHESAMESTATEMENT('TGDCSTORAGE', 'CHECKTHESAMESTATEMENT', KEYCHECKTHESAMESTATEMENT)}
  {M}  try
  {M}    if (not FDataTransfer) and Assigned(gdcBaseMethodControl) then
  {M}    begin
  {M}      SetFirstMethodAssoc('TGDCSTORAGE', KEYCHECKTHESAMESTATEMENT);
  {M}      tmpStrings := TStackStrings(ClassMethodAssoc.IntByKey[KEYCHECKTHESAMESTATEMENT]);
  {M}      if (tmpStrings = nil) or (tmpStrings.IndexOf('TGDCSTORAGE') = -1) then
  {M}      begin
  {M}        Params := VarArrayOf([GetGdcInterface(Self)]);
  {M}        if gdcBaseMethodControl.ExecuteMethodNew(ClassMethodAssoc, Self, 'TGDCSTORAGE',
  {M}          'CHECKTHESAMESTATEMENT', KEYCHECKTHESAMESTATEMENT, Params, LResult) then
  {M}          begin
  {M}            if (VarType(LResult) = varOleStr) or (VarType(LResult) = varString) then
  {M}              Result := String(LResult)
  {M}            else
  {M}              begin
  {M}                raise Exception.Create('��� ������ ''' + 'CHECKTHESAMESTATEMENT' + ' ''' +
  {M}                  ' ������ ' + Self.ClassName + TGDCSTORAGE(Self).SubType + #10#13 +
  {M}                  '�� ������� ��������� �� ��������� ���');
  {M}              end;
  {M}            exit;
  {M}          end;
  {M}      end else
  {M}        if tmpStrings.LastClass.gdClassName <> 'TGDCSTORAGE' then
  {M}        begin
  {M}          Result := '';//Inherited CheckTheSameStatement;
  {M}          Exit;
  {M}        end;
  {M}    end;
  {END MACRO}

  if State = dsInactive then
    Result :=
      'SELECT '#13#10 +
      '  id '#13#10 +
      'FROM '#13#10 +
      '  gd_storage_data '#13#10 +
      'WHERE '#13#10 +
      '  ( '#13#10 +
      '    parent IS NOT NULL '#13#10 +
      '    AND '#13#10 +
      '    parent = :Parent '#13#10 +
      '    AND '#13#10 +
      '    UPPER(name) = UPPER(:Name) '#13#10 +
      '  ) '#13#10 +
      '  OR '#13#10 +
      '  ( '#13#10 +
      '    parent IS NULL '#13#10 +
      '    AND '#13#10 +
      '    data_type = :data_type '#13#10 +
      '    AND '#13#10 +
      '    ( '#13#10 +
      '      ( '#13#10 +
      '        :data_type = ''U'' '#13#10 +
      '        AND '#13#10 +
      '        int_data = :int_data '#13#10 +
      '      ) '#13#10 +
      '      OR '#13#10 +
      '      ( '#13#10 +
      '        :data_type = ''O'' '#13#10 +
      '        AND '#13#10 +
      '        int_data = :int_data '#13#10 +
      '      ) '#13#10 +
      '      OR '#13#10 +
      '      ( '#13#10 +
      '        :data_type = ''T'' '#13#10 +
      '        AND '#13#10 +
      '        name = :Name '#13#10 +
      '      ) '#13#10 +
      '      OR '#13#10 +
      '      ( '#13#10 +
      '        :data_type = ''G'' '#13#10 +
      '      ) '#13#10 +
      '    ) '#13#10 +
      '  )'
  else if ID < cstUserIDStart then
    Result := inherited CheckTheSameStatement
  else begin
    if not FieldByName('parent').IsNull then
      Result := Format(
        'SELECT id FROM gd_storage_data WHERE UPPER(name)=UPPER(''%0:s'') AND parent=%1:d',
        [StringReplace(FieldByName('name').AsString, '''', '''''', [rfReplaceAll]),
         TID264(FieldByName('parent'))])
    else begin
      if FieldByName('data_type').AsString = cStorageUser then
        S := 'AND int_data=' + TID2S(IBLogin.UserKey)
      else if FieldByName('data_type').AsString = cStorageCompany then
        S := 'AND int_data=' + TID2S(IBLogin.CompanyKey)
      else if FieldByName('data_type').AsString = cStorageDesktop then
        S := 'AND name=''' + FieldByName('name').AsString + ''''
      else if FieldByName('data_type').AsString = cStorageGlobal then
        S := ''
      else
        raise EgdcException.Create('Invalid storage data type');

      Result := Format('SELECT id FROM gd_storage_data WHERE parent IS NULL AND data_type=''%0:s'' %1:s',
        [FieldByName('data_type').AsString, S])
    end;
  end;

  {@UNFOLD MACRO INH_ORIG_FINALLY('TGDCSTORAGE', 'CHECKTHESAMESTATEMENT', KEYCHECKTHESAMESTATEMENT)}
  {M}  finally
  {M}    if (not FDataTransfer) and Assigned(gdcBaseMethodControl) then
  {M}      ClearMacrosStack2('TGDCSTORAGE', 'CHECKTHESAMESTATEMENT', KEYCHECKTHESAMESTATEMENT);
  {M}  end;
  {END MACRO}
end;

function TgdcStorage.GetTreeInsertMode: TgdcTreeInsertMode;
begin
  Result := timChildren;
end;

procedure TgdcStorage.DoBeforeDelete;
  {@UNFOLD MACRO INH_ORIG_PARAMS(VAR)}
  {M}VAR
  {M}  Params, LResult: Variant;
  {M}  tmpStrings: TStackStrings;
  {END MACRO}
  SI: TgsStorageItem;
begin
  {@UNFOLD MACRO INH_ORIG_WITHOUTPARAM('TGDCSTORAGE', 'DOBEFOREDELETE', KEYDOBEFOREDELETE)}
  {M}  try
  {M}    if (not FDataTransfer) and Assigned(gdcBaseMethodControl) then
  {M}    begin
  {M}      SetFirstMethodAssoc('TGDCSTORAGE', KEYDOBEFOREDELETE);
  {M}      tmpStrings := TStackStrings(ClassMethodAssoc.IntByKey[KEYDOBEFOREDELETE]);
  {M}      if (tmpStrings = nil) or (tmpStrings.IndexOf('TGDCSTORAGE') = -1) then
  {M}      begin
  {M}        Params := VarArrayOf([GetGdcInterface(Self)]);
  {M}        if gdcBaseMethodControl.ExecuteMethodNew(ClassMethodAssoc, Self, 'TGDCSTORAGE',
  {M}          'DOBEFOREDELETE', KEYDOBEFOREDELETE, Params, LResult) then exit;
  {M}      end else
  {M}        if tmpStrings.LastClass.gdClassName <> 'TGDCSTORAGE' then
  {M}        begin
  {M}          Inherited;
  {M}          Exit;
  {M}        end;
  {M}    end;
  {END MACRO}

  if FDataTransfer then
    exit;

  inherited;

  if FindStorageItem(SI) then
    SI.Drop;
    
  {@UNFOLD MACRO INH_ORIG_FINALLY('TGDCSTORAGE', 'DOBEFOREDELETE', KEYDOBEFOREDELETE)}
  {M}  finally
  {M}    if (not FDataTransfer) and Assigned(gdcBaseMethodControl) then
  {M}      ClearMacrosStack2('TGDCSTORAGE', 'DOBEFOREDELETE', KEYDOBEFOREDELETE);
  {M}  end;
  {END MACRO}
end;

class function TgdcStorage.NeedModifyFromStream(
  const SubType: String): Boolean;
begin
  // �� ��������� ���������� ���� "�������������� �� ������"
  Result := True;
end;

procedure TgdcStorage.DoBeforeInsert;
  {@UNFOLD MACRO INH_ORIG_PARAMS(VAR)}
  {M}VAR
  {M}  Params, LResult: Variant;
  {M}  tmpStrings: TStackStrings;
  {END MACRO}
begin
  {@UNFOLD MACRO INH_ORIG_WITHOUTPARAM('TGDCSTORAGE', 'DOBEFOREINSERT', KEYDOBEFOREINSERT)}
  {M}  try
  {M}    if (not FDataTransfer) and Assigned(gdcBaseMethodControl) then
  {M}    begin
  {M}      SetFirstMethodAssoc('TGDCSTORAGE', KEYDOBEFOREINSERT);
  {M}      tmpStrings := TStackStrings(ClassMethodAssoc.IntByKey[KEYDOBEFOREINSERT]);
  {M}      if (tmpStrings = nil) or (tmpStrings.IndexOf('TGDCSTORAGE') = -1) then
  {M}      begin
  {M}        Params := VarArrayOf([GetGdcInterface(Self)]);
  {M}        if gdcBaseMethodControl.ExecuteMethodNew(ClassMethodAssoc, Self, 'TGDCSTORAGE',
  {M}          'DOBEFOREINSERT', KEYDOBEFOREINSERT, Params, LResult) then exit;
  {M}      end else
  {M}        if tmpStrings.LastClass.gdClassName <> 'TGDCSTORAGE' then
  {M}        begin
  {M}          Inherited;
  {M}          Exit;
  {M}        end;
  {M}    end;
  {END MACRO}

  FieldByName('name').ReadOnly := False;
  inherited;

  {@UNFOLD MACRO INH_ORIG_FINALLY('TGDCSTORAGE', 'DOBEFOREINSERT', KEYDOBEFOREINSERT)}
  {M}  finally
  {M}    if (not FDataTransfer) and Assigned(gdcBaseMethodControl) then
  {M}      ClearMacrosStack2('TGDCSTORAGE', 'DOBEFOREINSERT', KEYDOBEFOREINSERT);
  {M}  end;
  {END MACRO}
end;

initialization
  RegisterGdcClass(TgdcStorage);
  RegisterGdcClass(TgdcStorageFolder);
  RegisterGdcClass(TgdcStorageValue);

finalization
  UnregisterGdcClass(TgdcStorage);
  UnregisterGdcClass(TgdcStorageFolder);
  UnregisterGdcClass(TgdcStorageValue);
end.
