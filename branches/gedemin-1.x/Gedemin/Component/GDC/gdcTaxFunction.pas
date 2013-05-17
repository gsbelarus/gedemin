
{++


  Copyright (c) 2001 by Golden Software of Belarus

  Module

    gdcTaxFunction.pas

  Abstract

    Business classes for calculation values of financial report.

  Author

    Dubrovnik Alexander (DAlex)

  Revisions history

    1.00    07.02.03    DAlex      Initial version.

--}

unit gdcTaxFunction;

interface

uses
  classes, gdcBase, gdcBaseInterface, gd_createable_form, menus, Controls,
  gdcClasses, graphics, dmImages_unit;

const
  tfVBF = 'VB';
  tfSFF = 'SF';
  tfCFF = 'CF';
  tfGSF = 'GS';

  stByTaxActual   = 'ByTaxActual';
  stByTax         = 'ByTax';
  stByDesignDate  = 'ByDesignDate';
  stByID          = 'ByID';
  stByType        = 'ByType';
  stByDocumentDate= 'ByDocumentDate';
  // ������������ ��� TgdcTaxReport, ���������� ������ ������ ���������� ����
  stByActualFirst = 'ByActualFirst';

type
  TTaxFunctionItem = record
    Name: String;
    TF: String;
    TFKey: Integer;
    Result: Variant;
    ActualKey: Integer;
    ReportDay: Byte;
    Calculated: Boolean;
  end;
  TArrayEstabl = array of Integer;

  {IgsSetTaxDate = interface
    procedure SetBPeriod(const ADate: TDate);
    procedure SetEPeriod(const ADate: TDate);
  end;}

type
  TgdcTaxName = class(TgdcBase)
  protected
    function CreateDialogForm: TCreateableForm; override;

    function CheckTheSameStatement: String; override;
//    function GetGroupID: Integer; override;
  public
    class function GetListTable(const ASubType: TgdcSubType): String; override;
    class function GetListField(const ASubType: TgdcSubType): String; override;

    class function GetViewFormClassName(const ASubType: TgdcSubType): String; override;

    class function GetDisplayName(const ASubType: TgdcSubType): String; override;
  end;

  TgdcTaxActual = class(TgdcBase)
  private
    FReportGroupKey: Integer;
    FTrRecordKey: Integer;
//    FpmActualReport: TPopupMenu;

//    procedure CreateActualReportMenu;
  protected
    function CreateDialogForm: TCreateableForm; override;

    function  GetSelectClause: String; override;
    function  GetFromClause(const ARefresh: Boolean = False): String; override;
    procedure GetWhereClauseConditions(S: TStrings); override;

    procedure DoAfterDelete; override;
    procedure DoBeforeDelete; override;

    function CheckTheSameStatement: String; override;
    function GetGroupID: Integer; override;
    function GetNotCopyField: String; override;
  public
{    procedure PopupActualReportMenu(const X, Y: Integer);}
    procedure Post; override;

    function Copy(const AFields: String; AValues: Variant; const ACopyDetail: Boolean = False;
      const APost: Boolean = True; const AnAppend: Boolean = False): Boolean; override;

    class function GetListTable(const ASubType: TgdcSubType): String; override;
    class function GetListField(const ASubType: TgdcSubType): String; override;

    class function GetSubSetList: String; override;
    class function GetViewFormClassName(const ASubType: TgdcSubType): String; override;
  end;

  TgdcTaxDesignDate = class(TgdcDocument)
  protected
    function GetSelectClause: String; override;
    function GetFromClause(const ARefresh: Boolean = False): String; override;

    procedure CustomInsert(Buff: Pointer); override;
    procedure CustomModify(Buff: Pointer); override;
    procedure GetWhereClauseConditions(S: TStrings); override;
    procedure _DoOnNewRecord; override;
    function GetGroupID: Integer; override;
  public
    function DocumentTypeKey: Integer; override;

    class function GetDocumentClassPart: TgdcDocumentClassPart; override;
    class function GetViewFormClassName(const ASubType: TgdcSubType): String; override;
    class function GetViewFormName: String;

    class procedure GetClassImage(const ASizeX, ASizeY: Integer; AGraphic: TGraphic); override;
    class function GetSubSetList: String; override;
  end;

  TgdcTaxResult = class(TgdcDocument)
  private
    function GetCorrectResult: OleVariant;
  protected
    function GetSelectClause: String; override;
    function GetFromClause(const ARefresh: Boolean = False): String; override;

    procedure CustomInsert(Buff: Pointer); override;
    procedure CustomModify(Buff: Pointer); override;
    procedure GetWhereClauseConditions(S: TStrings); override;
    procedure _DoOnNewRecord; override;
    function GetGroupID: Integer; override;
  public
    function DocumentTypeKey: Integer; override;

    class function GetDocumentClassPart: TgdcDocumentClassPart; override;
    class function GetViewFormClassName(const ASubType: TgdcSubType): String; override;

    class function GetSubSetList: String; override;

    property CorrectResult: OleVariant read GetCorrectResult;
  end;

{  procedure ConvertTFIntoScript(const FuncName: String; var Script: String;
    var ArrayEstabl: TArrayEstabl; out ContainIncFunc: Boolean);}
  procedure Register;

var
  gsFunction: IDispatch;
  //gsSetTaxFunction: IgsSetTaxDate;

implementation

uses
  gd_ClassList, sysutils, {gdc_frmTaxFunction_unit, gdc_dlgTaxFunction_unit,}
  gdc_dlgTaxActual_unit, Forms, gdcReport, gdcConstants, Db, IBSQL,
  scrReportGroup, Windows, gd_security_operationconst, gdc_dlgTaxName_unit,
  gdcCustomFunction, gd_directories_const, gdcAutoTransaction,
  gdcAcctTransaction;

const
  txNameChars =
    'qwertyuiopasdfghjklzxcvbnmQWERTYUIOPASDFGHJKLZXCVBNM1234567890_';

  txReportFolder = '%s (%s)';

  gdcTaxNameReportGroupKey          = 1020002;

type
  TtxFuncType = (txVB, txSF, txCF, txGS, txUnknown);

  TtxFuncDecl = record
    Name: String;
    FuncType: TtxFuncType;
    BPos, EPos: Integer;
  end;

type
  TCrackGdcBase = class(TgdcBase);


procedure Register;
begin
  RegisterComponents('gdc', [TgdcTaxActual]);
  RegisterComponents('gdc', [TgdcTaxDesignDate]);
  RegisterComponents('gdc', [TgdcTaxResult]);
  RegisterComponents('gdc', [TgdcTaxName]);
end;

(*procedure ConvertTFIntoScript(const FuncName: String; var Script: String;
  var ArrayEstabl: TArrayEstabl; out ContainIncFunc: Boolean);
var
  IncludingStr: String;

const
  tfBFD     = '[';
  tfEFD     = ']';
  tfSpace   = ' ';
  tfColon   = ':';
  tfStrDecl = '"';
  tfPoint   = '.';
  tfComma   = ',';

  procedure ConvertProcess(var Script: String);
  var
    CI: Integer;
    CBCount, CSDCount: Integer;
    CtxFunc: TtxFuncDecl;
    CTypeStr: String;
    CBNamePos: Integer;
    CTmpStr: String;
    CPrevLength: Integer;
    CtxFuncParam: String;
    CCommaFound: Boolean;
  begin
    CCommaFound := False;
    CI := 1;
//    ArrayEstabl[CI - 1] := 1;
    CBCount := 0;
    CSDCount := 0;
    CBNamePos := 0;
    while CI <= Length(Script) do
    begin
      case Script[CI] of
        tfColon:
          if CSDCount mod 2 = 0 then
            raise Exception.Create('������ ����������.'#13#10 +
              '������������� ������� ":" ���������.');
        tfComma:
        begin
          if CCommaFound and (CSDCount mod 2 = 0) then
            raise Exception.Create('������ ���������� (��� ������� ������).'#13#10 +
              '��������, �������� ��������.');
          CCommaFound := True;
        end;
        tfBFD:
        begin
          if CBCount = 0 then
          begin
            CtxFunc.Name := '';
            CtxFunc.FuncType := txUnknown;
            CtxFunc.BPos := CI;
            CtxFunc.EPos := -1;
            CBNamePos := -1;
          end;
          Inc(CBCount);
        end;
        tfStrDecl: Inc(CSDCount);
        tfEFD:
        begin
          Dec(CBCount);
          if (CBCount = 0) and ((CSDCount mod 2) = 0) then
          begin
            CSDCount := 0;
            CtxFunc.EPos := CI;
//            ArrayEstabl[CI - 1] := CtxFunc.BPos + 1;
            CI := CtxFunc.BPos + 1;
//            CI := ArrayEstabl[CI -1];
            while CI <= CtxFunc.EPos do
            begin
              case Script[CI] of
                tfSpace: ;
                tfPoint:
                begin
                  if not (CtxFunc.FuncType = txUnknown) then
                    raise Exception.Create('������ ���������� (��� ����� ������).');

                  CTypeStr := AnsiUpperCase(Trim(copy(Script, CtxFunc.BPos + 1,
                    CI - CtxFunc.BPos - 1)));
                  if CTypeStr = tfVBF then
                  begin
                    CtxFunc.FuncType := txVB;
                  end else
                  if CTypeStr = tfSFF then
                  begin
                    CtxFunc.FuncType := txSF
                  end else
                  if CTypeStr = tfCFF then
                  begin
                    CtxFunc.FuncType := txCF
                  end else
                  if CTypeStr = tfGSF then
                  begin
                    CtxFunc.FuncType := txGS
                  end else
                    raise Exception.Create('��� ������� �� ���������.');
                end
                else
                  begin
                    if (not (CtxFunc.FuncType = txUnknown)) then
                    begin
                      if CBNamePos = -1 then
                      begin
                        if Pos(Script[CI], txNameChars) > 0  then
                          CBNamePos := CI
                        else
                          raise Exception.Create('������ ����������.');
                      end else
                        if Pos(Script[CI], txNameChars) = 0  then
                        begin
                          CPrevLength := Length(Script);

                          CtxFunc.Name := Copy(Script, CBNamePos, CI - CBNamePos);
                          if Length(CtxFunc.Name) > 0 then
                          begin
                            CtxFuncParam := Copy(Script, CI, CtxFunc.EPos - CI);
                            ConvertProcess(CtxFuncParam);
                            CTmpStr := CtxFunc.Name + CtxFuncParam +
                              Copy(Script, CtxFunc.EPos + 1, Length(Script));

                            case CtxFunc.FuncType of
                              txVB:
                                Script := Copy(Script, 1, CtxFunc.BPos - 1) + CTmpStr;
                              txSF:
                              begin
                                ContainIncFunc := True;
                                IncludingStr := IncludingStr +
                                  '''#include ' + CtxFunc.Name + ' :';
//                                IncludingStr := IncludingStr +
//                                  '''#include ' + CtxFunc.Name + #13#10;
                                Script := Copy(Script, 1, CtxFunc.BPos - 1) + CTmpStr;
                              end;
                              txCF:
                                Script := Copy(Script, 1, CtxFunc.BPos - 1) +
                                  'GS.GetValue("' + CtxFunc.Name + '")' +
                                  Copy(CTmpStr, 1 + Length(CtxFunc.Name), Length(CTmpStr));
                              txGS:
                                Script := Copy(Script, 1, CtxFunc.BPos - 1) +
                                  'GS.' + CTmpStr;
                              else
                                raise Exception.Create('��� ������� �� ���������.');
                            end;

//                            ArrayEstabl[CI - 1] := CtxFunc.EPos - (CPrevLength - Length(Script));
//                            CI := ArrayEstabl[CI - 1];//CtxFunc.EPos - (CPrevLength - Length(Script));
                            CI := CtxFunc.EPos - (CPrevLength - Length(Script));
                            Break;
                          end else
                            raise Exception.Create('������ � ����� �������.');
                        end;
                    end;
                  end;
              end;

              Inc(CI);
//              ArrayEstabl[CI - 1] := CI;
            end;
          end;
        end;
      end;
      if (Script[CI] <> tfSpace) and (Script[CI] <> tfComma)  then
        CCommaFound := False;
      Inc(CI);
    end;
    if (CSDCount mod 2) <> 0 then
      raise Exception.Create('������ ����������.'#13#10 +
        '���������� ������������� ������.');
  end;

begin
  IncludingStr := '';
  ContainIncFunc := False;
  Script := StringReplace(Script, ''#13#10, ' ', [rfReplaceAll, rfIgnoreCase]);
  ConvertProcess(Script);
  Script := 'function ' + FuncName + ' :' +
    '  ' + FuncName + ' = ' + Script + ' :' +
    'end function: ' + IncludingStr;
end;*)

{ TgdcTaxActual }

function TgdcTaxActual.CheckTheSameStatement: String;
  {@UNFOLD MACRO INH_ORIG_PARAMS(VAR)}
  {M}VAR
  {M}  Params, LResult: Variant;
  {M}  tmpStrings: TStackStrings;
  {END MACRO}
begin
  {@UNFOLD MACRO INH_ORIG_CHECKTHESAMESTATEMENT('TGDCTAXACTUAL', 'CHECKTHESAMESTATEMENT', KEYCHECKTHESAMESTATEMENT)}
  {M}  try
  {M}    if (not FDataTransfer) and Assigned(gdcBaseMethodControl) then
  {M}    begin
  {M}      SetFirstMethodAssoc('TGDCTAXACTUAL', KEYCHECKTHESAMESTATEMENT);
  {M}      tmpStrings := TStackStrings(ClassMethodAssoc.IntByKey[KEYCHECKTHESAMESTATEMENT]);
  {M}      if (tmpStrings = nil) or (tmpStrings.IndexOf('TGDCTAXACTUAL') = -1) then
  {M}      begin
  {M}        Params := VarArrayOf([GetGdcInterface(Self)]);
  {M}        if gdcBaseMethodControl.ExecuteMethodNew(ClassMethodAssoc, Self, 'TGDCTAXACTUAL',
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
  {M}        if tmpStrings.LastClass.gdClassName <> 'TGDCTAXACTUAL' then
  {M}        begin
  {M}          Result := Inherited CheckTheSameStatement;
  {M}          Exit;
  {M}        end;
  {M}    end;
  {END MACRO}
//����������� ������ ���� �� ��������������
  if FieldByName(GetKeyField(SubType)).AsInteger < cstUserIDStart then
    Result := inherited CheckTheSameStatement
  else
    Result := Format('SELECT %s FROM %s WHERE taxnamekey = %s AND actualdate = ''%s'' ',
      [GetKeyField(SubType), GetListTable(SubType),
        FieldByName('taxnamekey').AsString, FieldByName('actualdate').AsString]);
  {@UNFOLD MACRO INH_ORIG_FINALLY('TGDCTAXACTUAL', 'CHECKTHESAMESTATEMENT', KEYCHECKTHESAMESTATEMENT)}
  {M}  finally
  {M}    if (not FDataTransfer) and Assigned(gdcBaseMethodControl) then
  {M}      ClearMacrosStack2('TGDCTAXACTUAL', 'CHECKTHESAMESTATEMENT', KEYCHECKTHESAMESTATEMENT);
  {M}  end;
  {END MACRO}

end;

{procedure TgdcTaxActual.CreateActualReportMenu;
var
  MenuItem: TMenuItem;
  DidActivate: Boolean;
  ReportGroup: TscrReportGroup;
  IndexName: Integer;

  procedure FillMenu(const Parent: TObject);
  var
    I: Integer;
    M: TMenuItem;
    Index: Integer;
    AddCount: Integer;
  begin
    Assert((Parent is TMenuItem) or (Parent is TPopUpMenu));

    if (Parent is TMenuItem) then
    begin
      Index := (Parent as TMenuItem).Tag;
      (Parent as TMenuItem).Clear;
    end else
      Index := 0;

    AddCount := 0;
    if (ReportGroup.Count > 0) and (Index < ReportGroup.Count) then
    begin
      for I := Index to ReportGroup.Count - 1 do
      begin
        if ReportGroup.GroupItems[Index].Id = ReportGroup.GroupItems[I].Parent then
        begin
          M := TMenuItem.Create(Self);
          M.Tag := I;
//          M.Name := 'G' + IntToStr(ReportGroup.GroupItems[I].Id);
          M.Caption := ReportGroup.GroupItems[I].Name;
          if (Parent is TMenuItem) then
            (Parent as TMenuItem).Add(M)
          else
            (Parent as TPopUpMenu).Items.Add(M);
          FillMenu(M);
          Inc(AddCount);
        end;
      end;
      for I := 0 to ReportGroup.GroupItems[Index].ReportList.Count - 1 do
      begin
        M := TMenuItem.Create(Self);
        M.Tag := ReportGroup.GroupItems[Index].ReportList.Report[I].Id;
//        M.Name := 'M' + IntToStr(ReportGroup.GroupItems[Index].ReportList.Report[I].Id);
        M.Caption := ReportGroup.GroupItems[Index].ReportList.Report[I].Name;
        M.OnClick := DoOnReportClick;
        if (Parent is TMenuItem) then
          (Parent as TMenuItem).Add(M)
        else
          (Parent as TPopUpMenu).Items.Add(M);
        Inc(AddCount);
      end;
    end;
    if AddCount = 0 then
    begin
      M := TMenuItem.Create(Self);
//      M.Name := 'N' + IntToStr(IndexName);
      Inc(IndexName);
      M.Caption := '�����';
      M.Enabled := False;
      if (Parent is TMenuItem) then
        (Parent as TMenuItem).Add(M)
      else
        (Parent as TPopUpMenu).Items.Add(M);
    end;
  end;

  procedure ReportNotFound;
  begin
    MenuItem := TMenuItem.Create(FpmActualReport);
    MenuItem.Name := 'miNobody';
    MenuItem.Caption := '������ �����������';
    MenuItem.Enabled := False;
  end;

begin
  if FpmActualReport <> nil then
  begin
    FpmActualReport.Free;
    FpmActualReport := nil;
  end;

  IndexName := 0;
  
  if not Assigned(FpmActualReport) then
    FpmActualReport := TPopupMenu.Create(Self);
  FpmActualReport.AutoLineReduction := Menus.maAutomatic;

  if FieldByName('reportgroupkey').IsNull then
  begin
    ReportNotFound;
    Exit;
  end;

  DidActivate := False;
  try
    ReportGroup := TscrReportGroup.Create(UseScriptMethod);
    try
      ReportGroup.Transaction := ReadTransaction;
      ReportGroup.Load(FieldByName('reportgroupkey').AsInteger);

      if (ReportGroup.Count > 1) or ((ReportGroup.Count = 1) and (ReportGroup[0].ReportList.Count > 0)) then
      begin
        MenuItem := TMenuItem.Create(FpmActualReport);
        MenuItem.Caption := '-';
        FpmActualReport.Items.Add(MenuItem);

        FillMenu(FpmActualReport);
      end else
        begin
          ReportNotFound;
        end;
    finally
      ReportGroup.Free;
    end;

  finally
    if DidActivate then
      DeactivateReadTransaction;
  end;
end;}


function TgdcTaxActual.Copy(const AFields: String; AValues: Variant;
  const ACopyDetail, APost, AnAppend: Boolean): Boolean;
var
  TrKey: Integer;
  O: TgdcAutoTrRecord;
  B: Boolean;
begin
  TrKey := FieldByName('trrecordkey').AsInteger;
  B := APost;
  Result := inherited Copy(AFields, AValues, ACopyDetail, False, AnAppend);

  if Result then
  begin
    if TrKey <> 0 then
    begin
      O := TgdcAutoTrRecord.Create(nil);
      try
        O.Transaction := Transaction;
        O.ReadTransaction := ReadTransaction;
        O.SubSet := 'ByID';
        O.Id := TrKey;
        O.Open;
        if O.RecordCount > 0 then
        begin
          Result := O.Copy('', VarArrayOf([]), False, False, False);
          if Result then
          begin
            TrKey := O.FieldByName('id').AsInteger;
            if TrKey > 0 then
            begin
              O.Post;
              FieldByName('trrecordkey').AsInteger := TrKey;
            end;
          end;
        end;
      finally
        O.Free;
      end;
    end;

    if B then Post;
  end;
end;

function TgdcTaxActual.CreateDialogForm: TCreateableForm;
  {@UNFOLD MACRO INH_ORIG_PARAMS(VAR)}
  {M}VAR
  {M}  Params, LResult: Variant;
  {M}  tmpStrings: TStackStrings;
  {END MACRO}
begin
  {@UNFOLD MACRO INH_ORIG_FUNCCREATEDIALOGFORM('TGDCTAXACTUAL', 'CREATEDIALOGFORM', KEYCREATEDIALOGFORM)}
  {M}  try
  {M}    Result := nil;
  {M}    if (not FDataTransfer) and Assigned(gdcBaseMethodControl) then
  {M}    begin
  {M}      SetFirstMethodAssoc('TGDCTAXACTUAL', KEYCREATEDIALOGFORM);
  {M}      tmpStrings := TStackStrings(ClassMethodAssoc.IntByKey[KEYCREATEDIALOGFORM]);
  {M}      if (tmpStrings = nil) or (tmpStrings.IndexOf('TGDCTAXACTUAL') = -1) then
  {M}      begin
  {M}        Params := VarArrayOf([GetGdcInterface(Self)]);
  {M}        if gdcBaseMethodControl.ExecuteMethodNew(ClassMethodAssoc, Self, 'TGDCTAXACTUAL',
  {M}          'CREATEDIALOGFORM', KEYCREATEDIALOGFORM, Params, LResult) then
  {M}          begin
  {M}            Result := nil;
  {M}            if VarType(LResult) <> varDispatch then
  {M}              raise Exception.Create('������-�������: ' + Self.ClassName +
  {M}                TgdcBase(Self).SubType + 'CREATEDIALOGFORM' + #13#10 + '��� ������ ''' +
  {M}                'CREATEDIALOGFORM' + ' ''' + '������ ' + Self.ClassName +
  {M}                TgdcBase(Self).SubType + #10#13 + '�� ������� ��������� �� ������.')
  {M}            else
  {M}              if IDispatch(LResult) = nil then
  {M}                raise Exception.Create('������-�������: ' + Self.ClassName +
  {M}                  TgdcBase(Self).SubType + 'CREATEDIALOGFORM' + #13#10 + '��� ������ ''' +
  {M}                  'CREATEDIALOGFORM' + ' ''' + '������ ' + Self.ClassName +
  {M}                  TgdcBase(Self).SubType + #10#13 + '�� ������� ��������� ������ (null) ������.');
  {M}            Result := GetInterfaceToObject(LResult) as TCreateableForm;
  {M}            exit;
  {M}          end;
  {M}      end else
  {M}        if tmpStrings.LastClass.gdClassName <> 'TGDCTAXACTUAL' then
  {M}        begin
  {M}          Result := Inherited CreateDialogForm;
  {M}          Exit;
  {M}        end;
  {M}    end;
  {END MACRO}
//  Result := Tgdc_dlgTaxActual.CreateSubType(Application, '');
  Result := Tgdc_dlgTaxActual.Create(ParentForm);
  {@UNFOLD MACRO INH_ORIG_FINALLY('TGDCTAXACTUAL', 'CREATEDIALOGFORM', KEYCREATEDIALOGFORM)}
  {M}  finally
  {M}    if (not FDataTransfer) and Assigned(gdcBaseMethodControl) then
  {M}      ClearMacrosStack2('TGDCTAXACTUAL', 'CREATEDIALOGFORM', KEYCREATEDIALOGFORM);
  {M}  end;
  {END MACRO}
end;

procedure TgdcTaxActual.DoAfterDelete;
var
  {@UNFOLD MACRO INH_ORIG_PARAMS()}
  {M}
  {M}  Params, LResult: Variant;
  {M}  tmpStrings: TStackStrings;
  {END MACRO}
  gdcReportGroup: TgdcReportGroup;
  gdcAutoTrRecord: TgdcAutoTrRecord;
begin
  {@UNFOLD MACRO INH_ORIG_WITHOUTPARAM('TGDCTAXACTUAL', 'DOAFTERDELETE', KEYDOAFTERDELETE)}
  {M}  try
  {M}    if (not FDataTransfer) and Assigned(gdcBaseMethodControl) then
  {M}    begin
  {M}      SetFirstMethodAssoc('TGDCTAXACTUAL', KEYDOAFTERDELETE);
  {M}      tmpStrings := TStackStrings(ClassMethodAssoc.IntByKey[KEYDOAFTERDELETE]);
  {M}      if (tmpStrings = nil) or (tmpStrings.IndexOf('TGDCTAXACTUAL') = -1) then
  {M}      begin
  {M}        Params := VarArrayOf([GetGdcInterface(Self)]);
  {M}        if gdcBaseMethodControl.ExecuteMethodNew(ClassMethodAssoc, Self, 'TGDCTAXACTUAL',
  {M}          'DOAFTERDELETE', KEYDOAFTERDELETE, Params, LResult) then exit;
  {M}      end else
  {M}        if tmpStrings.LastClass.gdClassName <> 'TGDCTAXACTUAL' then
  {M}        begin
  {M}          Inherited;
  {M}          Exit;
  {M}        end;
  {M}    end;
  {END MACRO}

  inherited;

  try
    gdcReportGroup := TgdcReportGroup.Create(nil);
    try
      gdcReportGroup.Transaction := Self.Transaction;
      gdcReportGroup.SubSet := ssByID;
      gdcReportGroup.ParamByName('id').AsInteger := FReportGroupKey;
      gdcReportGroup.Open;
      try
        while not gdcReportGroup.Eof do
          gdcReportGroup.Delete;
      except
        if gdcReportGroup.Eof then
          raise Exception.Create(Format('������ �������� ����� � �� = %d.',
            [FReportGroupKey]))
        else
          raise Exception.Create(Format('������ �������� ����� ������� ''%s'' � �� = %d.',
            [gdcReportGroup.FieldByName('name').AsString, FReportGroupKey]));
      end;
    finally
      gdcReportGroup.Free;
    end;
  finally
    if not Eof then
      FReportGroupKey := Self.FieldByName('reportgroupkey').AsInteger;
  end;

  gdcAutoTrRecord := TgdcAutoTrRecord.Create(nil);
  try
    gdcAutoTrRecord.Transaction := Transaction;
    gdcAutoTrRecord.SubSet := 'ByID';
    gdcAutoTrrecord.ID := FTrRecordKey;
    gdcAutoTrRecord.Open;
    try
      gdcAutoTrRecord.Delete;
    except
    end;
  finally
    gdcAutoTrRecord.Free;
  end;

  {@UNFOLD MACRO INH_ORIG_FINALLY('TGDCTAXACTUAL', 'DOAFTERDELETE', KEYDOAFTERDELETE)}
  {M}  finally
  {M}    if (not FDataTransfer) and Assigned(gdcBaseMethodControl) then
  {M}      ClearMacrosStack2('TGDCTAXACTUAL', 'DOAFTERDELETE', KEYDOAFTERDELETE);
  {M}  end;
  {END MACRO}
end;

procedure TgdcTaxActual.DoBeforeDelete;
  {@UNFOLD MACRO INH_ORIG_PARAMS(VAR)}
  {M}VAR
  {M}  Params, LResult: Variant;
  {M}  tmpStrings: TStackStrings;
  {END MACRO}
begin
  {@UNFOLD MACRO INH_ORIG_WITHOUTPARAM('TGDCTAXACTUAL', 'DOBEFOREDELETE', KEYDOBEFOREDELETE)}
  {M}  try
  {M}    if (not FDataTransfer) and Assigned(gdcBaseMethodControl) then
  {M}    begin
  {M}      SetFirstMethodAssoc('TGDCTAXACTUAL', KEYDOBEFOREDELETE);
  {M}      tmpStrings := TStackStrings(ClassMethodAssoc.IntByKey[KEYDOBEFOREDELETE]);
  {M}      if (tmpStrings = nil) or (tmpStrings.IndexOf('TGDCTAXACTUAL') = -1) then
  {M}      begin
  {M}        Params := VarArrayOf([GetGdcInterface(Self)]);
  {M}        if gdcBaseMethodControl.ExecuteMethodNew(ClassMethodAssoc, Self, 'TGDCTAXACTUAL',
  {M}          'DOBEFOREDELETE', KEYDOBEFOREDELETE, Params, LResult) then exit;
  {M}      end else
  {M}        if tmpStrings.LastClass.gdClassName <> 'TGDCTAXACTUAL' then
  {M}        begin
  {M}          Inherited;
  {M}          Exit;
  {M}        end;
  {M}    end;
  {END MACRO}

  FReportGroupKey := Self.FieldByName('reportgroupkey').AsInteger;
  FTrRecordKey := Self.FieldByName('trrecordkey').AsInteger;
  inherited;

  {@UNFOLD MACRO INH_ORIG_FINALLY('TGDCTAXACTUAL', 'DOBEFOREDELETE', KEYDOBEFOREDELETE)}
  {M}  finally
  {M}    if (not FDataTransfer) and Assigned(gdcBaseMethodControl) then
  {M}      ClearMacrosStack2('TGDCTAXACTUAL', 'DOBEFOREDELETE', KEYDOBEFOREDELETE);
  {M}  end;
  {END MACRO}
end;

function TgdcTaxActual.GetFromClause(const ARefresh: Boolean): String;
  {@UNFOLD MACRO INH_ORIG_PARAMS(VAR)}
  {M}VAR
  {M}  Params, LResult: Variant;
  {M}  tmpStrings: TStackStrings;
  {END MACRO}
begin
  {@UNFOLD MACRO INH_ORIG_GETFROMCLAUSE('TGDCTAXACTUAL', 'GETFROMCLAUSE', KEYGETFROMCLAUSE)}
  {M}  try
  {M}    if (not FDataTransfer) and Assigned(gdcBaseMethodControl) then
  {M}    begin
  {M}      SetFirstMethodAssoc('TGDCTAXACTUAL', KEYGETFROMCLAUSE);
  {M}      tmpStrings := TStackStrings(ClassMethodAssoc.IntByKey[KEYGETFROMCLAUSE]);
  {M}      if (tmpStrings = nil) or (tmpStrings.IndexOf('TGDCTAXACTUAL') = -1) then
  {M}      begin
  {M}        Params := VarArrayOf([GetGdcInterface(Self), ARefresh]);
  {M}        if gdcBaseMethodControl.ExecuteMethodNew(ClassMethodAssoc, Self, 'TGDCTAXACTUAL',
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
  {M}        if tmpStrings.LastClass.gdClassName <> 'TGDCTAXACTUAL' then
  {M}        begin
  {M}          Result := Inherited GetFromClause(ARefresh);
  {M}          Exit;
  {M}        end;
  {M}    end;
  {END MACRO}
  Result :=
    'FROM gd_taxactual z ' +
    '  LEFT JOIN gd_taxname t ON z.taxnamekey = t.id ' +
    '  LEFT JOIN gd_taxtype tp ON z.typekey = tp.id ';
  {@UNFOLD MACRO INH_ORIG_FINALLY('TGDCTAXACTUAL', 'GETFROMCLAUSE', KEYGETFROMCLAUSE)}
  {M}  finally
  {M}    if (not FDataTransfer) and Assigned(gdcBaseMethodControl) then
  {M}      ClearMacrosStack2('TGDCTAXACTUAL', 'GETFROMCLAUSE', KEYGETFROMCLAUSE);
  {M}  end;
  {END MACRO}
end;

function TgdcTaxActual.GetGroupID: Integer;
begin
  Result := -1;
  if Active then
    Result := FieldByName('reportgroupkey').AsInteger;
end;

class function TgdcTaxActual.GetListField(
  const ASubType: TgdcSubType): String;
begin
  Result := 'actualdate';
end;

class function TgdcTaxActual.GetListTable(
  const ASubType: TgdcSubType): String;
begin
  Result := 'gd_taxactual';
end;

function TgdcTaxActual.GetNotCopyField: String;
  {@UNFOLD MACRO INH_ORIG_PARAMS(VAR)}
  {M}VAR
  {M}  Params, LResult: Variant;
  {M}  tmpStrings: TStackStrings;
  {END MACRO}
begin
  {@UNFOLD MACRO INH_ORIG_GETNOTCOPYFIELD('TGDCTAXACTUAL', 'GETNOTCOPYFIELD', KEYGETNOTCOPYFIELD)}
  {M}  try
  {M}    if (not FDataTransfer) and Assigned(gdcBaseMethodControl) then
  {M}    begin
  {M}      SetFirstMethodAssoc('TGDCTAXACTUAL', KEYGETNOTCOPYFIELD);
  {M}      tmpStrings := TStackStrings(ClassMethodAssoc.IntByKey[KEYGETNOTCOPYFIELD]);
  {M}      if (tmpStrings = nil) or (tmpStrings.IndexOf('TGDCTAXACTUAL') = -1) then
  {M}      begin
  {M}        Params := VarArrayOf([GetGdcInterface(Self)]);
  {M}        if gdcBaseMethodControl.ExecuteMethodNew(ClassMethodAssoc, Self, 'TGDCTAXACTUAL',
  {M}          'GETNOTCOPYFIELD', KEYGETNOTCOPYFIELD, Params, LResult) then
  {M}          begin
  {M}            if (VarType(LResult) = varOleStr) or (VarType(LResult) = varString) then
  {M}              Result := String(LResult)
  {M}            else
  {M}              begin
  {M}                raise Exception.Create('��� ������ ''' + 'GETNOTCOPYFIELD' + ' ''' +
  {M}                  ' ������ ' + Self.ClassName + TGDCTAXACTUAL(Self).SubType + #10#13 +
  {M}                  '�� ������� ��������� �� ��������� ���');
  {M}              end;
  {M}            exit;
  {M}          end;
  {M}      end else
  {M}        if tmpStrings.LastClass.gdClassName <> 'TGDCTAXACTUAL' then
  {M}        begin
  {M}          Result := Inherited GetNotCopyField;
  {M}          Exit;
  {M}        end;
  {M}    end;
  {END MACRO}

  Result := inherited GetNotCopyField + ',' + fnFunctionKey + ',' + fnReportGroupKey;

  {@UNFOLD MACRO INH_ORIG_FINALLY('TGDCTAXACTUAL', 'GETNOTCOPYFIELD', KEYGETNOTCOPYFIELD)}
  {M}  finally
  {M}    if (not FDataTransfer) and Assigned(gdcBaseMethodControl) then
  {M}      ClearMacrosStack2('TGDCTAXACTUAL', 'GETNOTCOPYFIELD', KEYGETNOTCOPYFIELD);
  {M}  end;
  {END MACRO}
end;

function TgdcTaxActual.GetSelectClause: String;
  {@UNFOLD MACRO INH_ORIG_PARAMS(VAR)}
  {M}VAR
  {M}  Params, LResult: Variant;
  {M}  tmpStrings: TStackStrings;
  {END MACRO}
begin
  {@UNFOLD MACRO INH_ORIG_GETSELECTCLAUSE('TGDCTAXACTUAL', 'GETSELECTCLAUSE', KEYGETSELECTCLAUSE)}
  {M}  try
  {M}    if (not FDataTransfer) and Assigned(gdcBaseMethodControl) then
  {M}    begin
  {M}      SetFirstMethodAssoc('TGDCTAXACTUAL', KEYGETSELECTCLAUSE);
  {M}      tmpStrings := TStackStrings(ClassMethodAssoc.IntByKey[KEYGETSELECTCLAUSE]);
  {M}      if (tmpStrings = nil) or (tmpStrings.IndexOf('TGDCTAXACTUAL') = -1) then
  {M}      begin
  {M}        Params := VarArrayOf([GetGdcInterface(Self)]);
  {M}        if gdcBaseMethodControl.ExecuteMethodNew(ClassMethodAssoc, Self, 'TGDCTAXACTUAL',
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
  {M}        if tmpStrings.LastClass.gdClassName <> 'TGDCTAXACTUAL' then
  {M}        begin
  {M}          Result := Inherited GetSelectClause;
  {M}          Exit;
  {M}        end;
  {M}    end;
  {END MACRO}
    Result := ' SELECT z.*, t.name as taxname, t.AccountKey, tp.name as typename ';
  {@UNFOLD MACRO INH_ORIG_FINALLY('TGDCTAXACTUAL', 'GETSELECTCLAUSE', KEYGETSELECTCLAUSE)}
  {M}  finally
  {M}    if (not FDataTransfer) and Assigned(gdcBaseMethodControl) then
  {M}      ClearMacrosStack2('TGDCTAXACTUAL', 'GETSELECTCLAUSE', KEYGETSELECTCLAUSE);
  {M}  end;
  {END MACRO}
end;

class function TgdcTaxActual.GetSubSetList: String;
begin
  Result := inherited GetSubSetList + 'ByTax;';
end;

class function TgdcTaxActual.GetViewFormClassName(
  const ASubType: TgdcSubType): String;
begin
  Result := inherited GetViewFormClassName(ASubType);
//  Result := 'Tgdc_frmTaxActual';
end;

procedure TgdcTaxActual.GetWhereClauseConditions(S: TStrings);
begin
  inherited;

  if HasSubSet('ByTax') then
    S.Add('taxnamekey = :taxnamekey');
end;

{procedure TgdcTaxActual.PopupActualReportMenu(const X, Y: Integer);
var
  Pt: TPoint;
begin
  CreateActualReportMenu;

  if (X = -1) and (Y = -1) then
    GetCursorPos(Pt)
  else
    Pt := Point(X, Y);

  FpmActualReport.Popup(Pt.X, Pt.Y);
end;}

procedure TgdcTaxActual.Post;
var
  FolderName: String;
  RepGrID: Integer;
  ParentFolder: Integer;
  D: TgdcBase;
begin
  FolderName := Format(txReportFolder,
    [Self.FieldByName(fntaxname).AsString, Self.FieldByName(fnactualdate).AsString]);

  D := TgdcTaxName.Create(nil);
  try
    D.ReadTransaction := Self.ReadTransaction;
    D.Transaction := Self.Transaction;
    ParentFolder := D.GroupID;
  finally
    D.Free;
  end;

  with TgdcReportGroup.Create(nil) do
  try
    ReadTransaction := Self.ReadTransaction;
    Transaction := Self.Transaction;

    if Self.FieldByName(fnREPORTGROUPKEY).IsNull then
    begin
      Open;
      Insert;
      FieldByName(fnname).AsString := FolderName;
      FieldByName(fnparent).AsInteger := ParentFolder;
      Post;

      RepGrID :=  FieldByName(fnid).AsInteger;
      Self.FieldByName(fnreportgroupkey).AsInteger := RepGrId;
    end else
    begin
      SubSet := 'ByID';
      ParamByName(fnid).AsInteger := Self.FieldByName(fnReportGroupKey).AsInteger;
      Open;
      Edit;
      FieldByName(fnname).AsString := FolderName;
      FieldByName(fnparent).AsInteger := ParentFolder;
      Post;
    end;
  finally
    Free;
  end;

  inherited;
end;

{ TgdcTaxResult }

procedure TgdcTaxResult.CustomInsert(Buff: Pointer);
  {@UNFOLD MACRO INH_ORIG_PARAMS(VAR)}
  {M}VAR
  {M}  Params, LResult: Variant;
  {M}  tmpStrings: TStackStrings;
  {END MACRO}
begin
  {@UNFOLD MACRO INH_ORIG_CUSTOMINSERT('TGDCTAXRESULT', 'CUSTOMINSERT', KEYCUSTOMINSERT)}
  {M}  try
  {M}    if (not FDataTransfer) and Assigned(gdcBaseMethodControl) then
  {M}    begin
  {M}      SetFirstMethodAssoc('TGDCTAXRESULT', KEYCUSTOMINSERT);
  {M}      tmpStrings := TStackStrings(ClassMethodAssoc.IntByKey[KEYCUSTOMINSERT]);
  {M}      if (tmpStrings = nil) or (tmpStrings.IndexOf('TGDCTAXRESULT') = -1) then
  {M}      begin
  {M}        Params := VarArrayOf([GetGdcInterface(Self), Integer(Buff)]);
  {M}        if gdcBaseMethodControl.ExecuteMethodNew(ClassMethodAssoc, Self, 'TGDCTAXRESULT',
  {M}          'CUSTOMINSERT', KEYCUSTOMINSERT, Params, LResult) then
  {M}          exit;
  {M}      end else
  {M}        if tmpStrings.LastClass.gdClassName <> 'TGDCTAXRESULT' then
  {M}        begin
  {M}          Inherited;
  {M}          Exit;
  {M}        end;
  {M}    end;
  {END MACRO}
  inherited CustomInsert(Buff);

  CustomExecQuery('INSERT INTO gd_taxresult ' +
  '  (documentkey, taxfunctionkey, taxdesigndatekey, result, resulttype, name, description) ' +
  'values ' +
  '  (:documentkey, :taxfunctionkey, :taxdesigndatekey, :result, :resulttype, :name, :description)', Buff);
  {@UNFOLD MACRO INH_ORIG_FINALLY('TGDCTAXRESULT', 'CUSTOMINSERT', KEYCUSTOMINSERT)}
  {M}  finally
  {M}    if (not FDataTransfer) and Assigned(gdcBaseMethodControl) then
  {M}      ClearMacrosStack2('TGDCTAXRESULT', 'CUSTOMINSERT', KEYCUSTOMINSERT);
  {M}  end;
  {END MACRO}
end;

procedure TgdcTaxResult.CustomModify(Buff: Pointer);
  {@UNFOLD MACRO INH_ORIG_PARAMS(VAR)}
  {M}VAR
  {M}  Params, LResult: Variant;
  {M}  tmpStrings: TStackStrings;
  {END MACRO}
begin
  {@UNFOLD MACRO INH_ORIG_CUSTOMINSERT('TGDCTAXRESULT', 'CUSTOMMODIFY', KEYCUSTOMMODIFY)}
  {M}  try
  {M}    if (not FDataTransfer) and Assigned(gdcBaseMethodControl) then
  {M}    begin
  {M}      SetFirstMethodAssoc('TGDCTAXRESULT', KEYCUSTOMMODIFY);
  {M}      tmpStrings := TStackStrings(ClassMethodAssoc.IntByKey[KEYCUSTOMMODIFY]);
  {M}      if (tmpStrings = nil) or (tmpStrings.IndexOf('TGDCTAXRESULT') = -1) then
  {M}      begin
  {M}        Params := VarArrayOf([GetGdcInterface(Self), Integer(Buff)]);
  {M}        if gdcBaseMethodControl.ExecuteMethodNew(ClassMethodAssoc, Self, 'TGDCTAXRESULT',
  {M}          'CUSTOMMODIFY', KEYCUSTOMMODIFY, Params, LResult) then
  {M}          exit;
  {M}      end else
  {M}        if tmpStrings.LastClass.gdClassName <> 'TGDCTAXRESULT' then
  {M}        begin
  {M}          Inherited;
  {M}          Exit;
  {M}        end;
  {M}    end;
  {END MACRO}
  inherited;

  CustomExecQuery('UPDATE gd_taxresult ' +
    'set ' +
    '  documentkey = :documentkey, ' +
    '  taxfunctionkey = :taxfunctionkey, ' +
    '  taxdesigndatekey = :taxdesigndatekey, ' +
    '  result = :result, ' +
    '  resulttype = :resulttype, ' +
    '  name = :name,' +
    '  description = :description' +
    'where ' +
    '  documentkey = :old_documentkey ', Buff);
  {@UNFOLD MACRO INH_ORIG_FINALLY('TGDCTAXRESULT', 'CUSTOMMODIFY', KEYCUSTOMMODIFY)}
  {M}  finally
  {M}    if (not FDataTransfer) and Assigned(gdcBaseMethodControl) then
  {M}      ClearMacrosStack2('TGDCTAXRESULT', 'CUSTOMMODIFY', KEYCUSTOMMODIFY);
  {M}  end;
  {END MACRO}
end;

function TgdcTaxResult.DocumentTypeKey: Integer;
begin
  Result := GD_DOC_TAXRESULT;
end;

function TgdcTaxResult.GetCorrectResult: OleVariant;
 function CommaToPoint(const S: string): string;
 var
   I, L: Integer;
 begin
   L := Length(S);
   Result := S;
   for I := 1 to L do
     if Result[I] = ',' then Result[i] := '.';
 end;
begin
  if (not Active) or Eof then
    Result := Unassigned;

  if  FieldByName('resulttype').IsNull then
    Result := FieldByName('resulttype').AsVariant;

  case FieldByName('resulttype').AsInteger of
    2, 3, 17:
      Result := FieldByName('result').AsInteger;
    6:
      Result := FieldByName('result').AsCurrency;
    4, 5, 14:
      Result := StrToFloat(CommaToPoint(FieldByName('result').AsString));
    7:
      Result := FieldByName('result').AsDateTime;
    8:
      Result := FieldByName('result').AsString;
    11:
      Result := FieldByName('result').AsBoolean;
    else
      Result := FieldByName('resulttype').AsVariant;
  end;
end;

class function TgdcTaxResult.GetDocumentClassPart: TgdcDocumentClassPart;
begin
  Result := dcpLine;
end;

function TgdcTaxResult.GetFromClause(const ARefresh: Boolean): String;
  {@UNFOLD MACRO INH_ORIG_PARAMS(VAR)}
  {M}VAR
  {M}  Params, LResult: Variant;
  {M}  tmpStrings: TStackStrings;
  {END MACRO}
begin
  {@UNFOLD MACRO INH_ORIG_GETFROMCLAUSE('TGDCTAXRESULT', 'GETFROMCLAUSE', KEYGETFROMCLAUSE)}
  {M}  try
  {M}    if (not FDataTransfer) and Assigned(gdcBaseMethodControl) then
  {M}    begin
  {M}      SetFirstMethodAssoc('TGDCTAXRESULT', KEYGETFROMCLAUSE);
  {M}      tmpStrings := TStackStrings(ClassMethodAssoc.IntByKey[KEYGETFROMCLAUSE]);
  {M}      if (tmpStrings = nil) or (tmpStrings.IndexOf('TGDCTAXRESULT') = -1) then
  {M}      begin
  {M}        Params := VarArrayOf([GetGdcInterface(Self), ARefresh]);
  {M}        if gdcBaseMethodControl.ExecuteMethodNew(ClassMethodAssoc, Self, 'TGDCTAXRESULT',
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
  {M}        if tmpStrings.LastClass.gdClassName <> 'TGDCTAXRESULT' then
  {M}        begin
  {M}          Result := Inherited GetFromClause(ARefresh);
  {M}          Exit;
  {M}        end;
  {M}    end;
  {END MACRO}
  Result := inherited GetFromClause(ARefresh) +
//    '   LEFT JOIN gd_taxdesigndate td ON td.documentkey = z.id ' +
    '   LEFT JOIN gd_taxresult tr ON tr.documentkey = z.id ' +
    '   LEFT JOIN gd_taxdesigndate td ON td.documentkey = tr.taxdesigndatekey ' +
//    '   LEFT JOIN gd_taxdesigndate td ON td.documentkey = tr.taxdesigndatekey ' +
    '   LEFT JOIN gd_taxactual ta ON ta.id = td.taxactualkey ' +
//    '   LEFT JOIN gd_taxfunction tf ON tf.id = tr.taxfunctionkey ' +
    '   LEFT JOIN gd_taxtype tp ON tp.id = ta.typekey ' +
    '   LEFT JOIN gd_taxname t ON t.id = ta.taxnamekey ';
  {@UNFOLD MACRO INH_ORIG_FINALLY('TGDCTAXRESULT', 'GETFROMCLAUSE', KEYGETFROMCLAUSE)}
  {M}  finally
  {M}    if (not FDataTransfer) and Assigned(gdcBaseMethodControl) then
  {M}      ClearMacrosStack2('TGDCTAXRESULT', 'GETFROMCLAUSE', KEYGETFROMCLAUSE);
  {M}  end;
  {END MACRO}
end;

function TgdcTaxResult.GetGroupID: Integer;
begin
  Result := - 1;
  if Active then
  begin
    Result := FieldByName('reportgroupkey').AsInteger;
  end;
end;

function TgdcTaxResult.GetSelectClause: String;
  {@UNFOLD MACRO INH_ORIG_PARAMS(VAR)}
  {M}VAR
  {M}  Params, LResult: Variant;
  {M}  tmpStrings: TStackStrings;
  {END MACRO}
begin
  {@UNFOLD MACRO INH_ORIG_GETSELECTCLAUSE('TGDCTAXRESULT', 'GETSELECTCLAUSE', KEYGETSELECTCLAUSE)}
  {M}  try
  {M}    if (not FDataTransfer) and Assigned(gdcBaseMethodControl) then
  {M}    begin
  {M}      SetFirstMethodAssoc('TGDCTAXRESULT', KEYGETSELECTCLAUSE);
  {M}      tmpStrings := TStackStrings(ClassMethodAssoc.IntByKey[KEYGETSELECTCLAUSE]);
  {M}      if (tmpStrings = nil) or (tmpStrings.IndexOf('TGDCTAXRESULT') = -1) then
  {M}      begin
  {M}        Params := VarArrayOf([GetGdcInterface(Self)]);
  {M}        if gdcBaseMethodControl.ExecuteMethodNew(ClassMethodAssoc, Self, 'TGDCTAXRESULT',
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
  {M}        if tmpStrings.LastClass.gdClassName <> 'TGDCTAXRESULT' then
  {M}        begin
  {M}          Result := Inherited GetSelectClause;
  {M}          Exit;
  {M}        end;
  {M}    end;
  {END MACRO}
  Result :=
    inherited GetSelectClause + ', tr.taxdesigndatekey, ' +
    '  tr.documentkey, tr.result, tr.name, tr.description, ' +
    '  ta.actualdate, t.name as taxname, t.id as idtax, ' +
    '  tp.name as typename, ta.reportgroupkey ';
  {@UNFOLD MACRO INH_ORIG_FINALLY('TGDCTAXRESULT', 'GETSELECTCLAUSE', KEYGETSELECTCLAUSE)}
  {M}  finally
  {M}    if (not FDataTransfer) and Assigned(gdcBaseMethodControl) then
  {M}      ClearMacrosStack2('TGDCTAXRESULT', 'GETSELECTCLAUSE', KEYGETSELECTCLAUSE);
  {M}  end;
  {END MACRO}
end;

class function TgdcTaxResult.GetSubSetList: String;
begin
  Result := inherited GetSubSetList + stByTax + ';' +
    stByDesignDate + ';' + stByActualFirst + ';';
end;

class function TgdcTaxResult.GetViewFormClassName(
  const ASubType: TgdcSubType): String;
begin
  Result := 'Tgdc_frmTaxResult';
end;

procedure TgdcTaxResult.GetWhereClauseConditions(S: TStrings);
begin
  inherited;
  if HasSubSet(stByTax) then
    S.Add('ta.taxnamekey = :taxnamekey')
  else
  if HasSubSet(stByDesignDate) then
    S.Add('z.parent = :taxdesigndatekey')
  else
  if HasSubSet(stByActualFirst) then
    S.Add('Z.parent = (SELECT MAX(doc.id) FROM GD_TAXDESIGNDATE TD1 LEFT JOIN ' +
          '  GD_DOCUMENT DOC ON TD1.DOCUMENTKEY = DOC.ID WHERE ' +
          '     TD1.taxactualkey = :taxactualkey AND doc.parent IS NULL) ');
end;

procedure TgdcTaxResult._DoOnNewRecord;
  {@UNFOLD MACRO INH_ORIG_PARAMS(VAR)}
  {M}VAR
  {M}  Params, LResult: Variant;
  {M}  tmpStrings: TStackStrings;
  {END MACRO}
begin
  {@UNFOLD MACRO INH_ORIG_WITHOUTPARAM('TGDCTAXRESULT', '_DOONNEWRECORD', KEY_DOONNEWRECORD)}
  {M}  try
  {M}    if (not FDataTransfer) and Assigned(gdcBaseMethodControl) then
  {M}    begin
  {M}      SetFirstMethodAssoc('TGDCTAXRESULT', KEY_DOONNEWRECORD);
  {M}      tmpStrings := TStackStrings(ClassMethodAssoc.IntByKey[KEY_DOONNEWRECORD]);
  {M}      if (tmpStrings = nil) or (tmpStrings.IndexOf('TGDCTAXRESULT') = -1) then
  {M}      begin
  {M}        Params := VarArrayOf([GetGdcInterface(Self)]);
  {M}        if gdcBaseMethodControl.ExecuteMethodNew(ClassMethodAssoc, Self, 'TGDCTAXRESULT',
  {M}          '_DOONNEWRECORD', KEY_DOONNEWRECORD, Params, LResult) then exit;
  {M}      end else
  {M}        if tmpStrings.LastClass.gdClassName <> 'TGDCTAXRESULT' then
  {M}        begin
  {M}          Inherited;
  {M}          Exit;
  {M}        end;
  {M}    end;
  {END MACRO}
  inherited;
  FieldByName('DocumentKey').AsInteger := ID;
  FieldByName('TaxDesignDateKey').AsInteger := FieldByName('Parent').AsInteger;
  {@UNFOLD MACRO INH_ORIG_FINALLY('TGDCTAXRESULT', '_DOONNEWRECORD', KEY_DOONNEWRECORD)}
  {M}  finally
  {M}    if (not FDataTransfer) and Assigned(gdcBaseMethodControl) then
  {M}      ClearMacrosStack2('TGDCTAXRESULT', '_DOONNEWRECORD', KEY_DOONNEWRECORD);
  {M}  end;
  {END MACRO}
end;

{ TgdcTaxDesignDate }

procedure TgdcTaxDesignDate.CustomInsert(Buff: Pointer);
  {@UNFOLD MACRO INH_ORIG_PARAMS(VAR)}
  {M}VAR
  {M}  Params, LResult: Variant;
  {M}  tmpStrings: TStackStrings;
  {END MACRO}
begin
  {@UNFOLD MACRO INH_ORIG_CUSTOMINSERT('TGDCTAXDESIGNDATE', 'CUSTOMINSERT', KEYCUSTOMINSERT)}
  {M}  try
  {M}    if (not FDataTransfer) and Assigned(gdcBaseMethodControl) then
  {M}    begin
  {M}      SetFirstMethodAssoc('TGDCTAXDESIGNDATE', KEYCUSTOMINSERT);
  {M}      tmpStrings := TStackStrings(ClassMethodAssoc.IntByKey[KEYCUSTOMINSERT]);
  {M}      if (tmpStrings = nil) or (tmpStrings.IndexOf('TGDCTAXDESIGNDATE') = -1) then
  {M}      begin
  {M}        Params := VarArrayOf([GetGdcInterface(Self), Integer(Buff)]);
  {M}        if gdcBaseMethodControl.ExecuteMethodNew(ClassMethodAssoc, Self, 'TGDCTAXDESIGNDATE',
  {M}          'CUSTOMINSERT', KEYCUSTOMINSERT, Params, LResult) then
  {M}          exit;
  {M}      end else
  {M}        if tmpStrings.LastClass.gdClassName <> 'TGDCTAXDESIGNDATE' then
  {M}        begin
  {M}          Inherited;
  {M}          Exit;
  {M}        end;
  {M}    end;
  {END MACRO}
  inherited CustomInsert(Buff);

  CustomExecQuery('INSERT INTO gd_taxdesigndate ' +
  '  (DOCUMENTKEY, taxnamekey, TAXACTUALKEY) ' +
  'values ' +
  '  (:DOCUMENTKEY, :taxnamekey, :TAXACTUALKEY)', Buff);
  {@UNFOLD MACRO INH_ORIG_FINALLY('TGDCTAXDESIGNDATE', 'CUSTOMINSERT', KEYCUSTOMINSERT)}
  {M}  finally
  {M}    if (not FDataTransfer) and Assigned(gdcBaseMethodControl) then
  {M}      ClearMacrosStack2('TGDCTAXDESIGNDATE', 'CUSTOMINSERT', KEYCUSTOMINSERT);
  {M}  end;
  {END MACRO}
end;

procedure TgdcTaxDesignDate.CustomModify(Buff: Pointer);
  {@UNFOLD MACRO INH_ORIG_PARAMS(VAR)}
  {M}VAR
  {M}  Params, LResult: Variant;
  {M}  tmpStrings: TStackStrings;
  {END MACRO}
begin
  {@UNFOLD MACRO INH_ORIG_CUSTOMINSERT('TGDCTAXDESIGNDATE', 'CUSTOMMODIFY', KEYCUSTOMMODIFY)}
  {M}  try
  {M}    if (not FDataTransfer) and Assigned(gdcBaseMethodControl) then
  {M}    begin
  {M}      SetFirstMethodAssoc('TGDCTAXDESIGNDATE', KEYCUSTOMMODIFY);
  {M}      tmpStrings := TStackStrings(ClassMethodAssoc.IntByKey[KEYCUSTOMMODIFY]);
  {M}      if (tmpStrings = nil) or (tmpStrings.IndexOf('TGDCTAXDESIGNDATE') = -1) then
  {M}      begin
  {M}        Params := VarArrayOf([GetGdcInterface(Self), Integer(Buff)]);
  {M}        if gdcBaseMethodControl.ExecuteMethodNew(ClassMethodAssoc, Self, 'TGDCTAXDESIGNDATE',
  {M}          'CUSTOMMODIFY', KEYCUSTOMMODIFY, Params, LResult) then
  {M}          exit;
  {M}      end else
  {M}        if tmpStrings.LastClass.gdClassName <> 'TGDCTAXDESIGNDATE' then
  {M}        begin
  {M}          Inherited;
  {M}          Exit;
  {M}        end;
  {M}    end;
  {END MACRO}
  inherited;

  CustomExecQuery('UPDATE gd_taxdesigndate ' +
    'set ' +
    '  taxnamekey = :taxnamekey, ' +
    '  taxactualkey = :taxactualkey, ' +
    'where ' +
    '  documentkey = :old_documentkey ', Buff);
  {@UNFOLD MACRO INH_ORIG_FINALLY('TGDCTAXDESIGNDATE', 'CUSTOMMODIFY', KEYCUSTOMMODIFY)}
  {M}  finally
  {M}    if (not FDataTransfer) and Assigned(gdcBaseMethodControl) then
  {M}      ClearMacrosStack2('TGDCTAXDESIGNDATE', 'CUSTOMMODIFY', KEYCUSTOMMODIFY);
  {M}  end;
  {END MACRO}
end;

function TgdcTaxDesignDate.DocumentTypeKey: Integer;
begin
  Result := GD_DOC_TAXRESULT;
end;

class procedure TgdcTaxDesignDate.GetClassImage(const ASizeX,
  ASizeY: Integer; AGraphic: TGraphic);
begin
  if (ASizeX = 16) and (ASizeY = 16) and (AGraphic is Graphics.TBitmap) then
    dmImages.il16x16.GetBitmap(212, Graphics.TBitmap(AGraphic));
end;

class function TgdcTaxDesignDate.GetDocumentClassPart: TgdcDocumentClassPart;
begin
  Result := dcpHeader;
end;

function TgdcTaxDesignDate.GetFromClause(const ARefresh: Boolean): String;
  {@UNFOLD MACRO INH_ORIG_PARAMS(VAR)}
  {M}VAR
  {M}  Params, LResult: Variant;
  {M}  tmpStrings: TStackStrings;
  {END MACRO}
begin
  {@UNFOLD MACRO INH_ORIG_GETFROMCLAUSE('TGDCTAXDESIGNDATE', 'GETFROMCLAUSE', KEYGETFROMCLAUSE)}
  {M}  try
  {M}    if (not FDataTransfer) and Assigned(gdcBaseMethodControl) then
  {M}    begin
  {M}      SetFirstMethodAssoc('TGDCTAXDESIGNDATE', KEYGETFROMCLAUSE);
  {M}      tmpStrings := TStackStrings(ClassMethodAssoc.IntByKey[KEYGETFROMCLAUSE]);
  {M}      if (tmpStrings = nil) or (tmpStrings.IndexOf('TGDCTAXDESIGNDATE') = -1) then
  {M}      begin
  {M}        Params := VarArrayOf([GetGdcInterface(Self), ARefresh]);
  {M}        if gdcBaseMethodControl.ExecuteMethodNew(ClassMethodAssoc, Self, 'TGDCTAXDESIGNDATE',
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
  {M}        if tmpStrings.LastClass.gdClassName <> 'TGDCTAXDESIGNDATE' then
  {M}        begin
  {M}          Result := Inherited GetFromClause(ARefresh);
  {M}          Exit;
  {M}        end;
  {M}    end;
  {END MACRO}
  Result := inherited GetFromClause(ARefresh) +
    '   LEFT JOIN gd_taxdesigndate td ON z.id = td.documentkey' +
    '   LEFT JOIN gd_taxactual ta ON ta.id = td.taxactualkey' +
    '   LEFT JOIN gd_taxname t ON ta.taxnamekey = t.id' +
    '   LEFT JOIN gd_taxtype tt ON tt.id = ta.typekey';
  {@UNFOLD MACRO INH_ORIG_FINALLY('TGDCTAXDESIGNDATE', 'GETFROMCLAUSE', KEYGETFROMCLAUSE)}
  {M}  finally
  {M}    if (not FDataTransfer) and Assigned(gdcBaseMethodControl) then
  {M}      ClearMacrosStack2('TGDCTAXDESIGNDATE', 'GETFROMCLAUSE', KEYGETFROMCLAUSE);
  {M}  end;
  {END MACRO}
end;

function TgdcTaxDesignDate.GetGroupID: Integer;
begin
  Result := -1;
  if Active then
  begin
    Result := FieldByName('reportgroupkey').AsInteger;
  end;
end;

function TgdcTaxDesignDate.GetSelectClause: String;
  {@UNFOLD MACRO INH_ORIG_PARAMS(VAR)}
  {M}VAR
  {M}  Params, LResult: Variant;
  {M}  tmpStrings: TStackStrings;
  {END MACRO}
begin
  {@UNFOLD MACRO INH_ORIG_GETSELECTCLAUSE('TGDCTAXDESIGNDATE', 'GETSELECTCLAUSE', KEYGETSELECTCLAUSE)}
  {M}  try
  {M}    if (not FDataTransfer) and Assigned(gdcBaseMethodControl) then
  {M}    begin
  {M}      SetFirstMethodAssoc('TGDCTAXDESIGNDATE', KEYGETSELECTCLAUSE);
  {M}      tmpStrings := TStackStrings(ClassMethodAssoc.IntByKey[KEYGETSELECTCLAUSE]);
  {M}      if (tmpStrings = nil) or (tmpStrings.IndexOf('TGDCTAXDESIGNDATE') = -1) then
  {M}      begin
  {M}        Params := VarArrayOf([GetGdcInterface(Self)]);
  {M}        if gdcBaseMethodControl.ExecuteMethodNew(ClassMethodAssoc, Self, 'TGDCTAXDESIGNDATE',
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
  {M}        if tmpStrings.LastClass.gdClassName <> 'TGDCTAXDESIGNDATE' then
  {M}        begin
  {M}          Result := Inherited GetSelectClause;
  {M}          Exit;
  {M}        end;
  {M}    end;
  {END MACRO}
  Result := inherited GetSelectClause +
    ', td.DOCUMENTKEY, td.taxnamekey, td.taxactualkey, t.name as taxname ' +
    ', ta.actualdate, ta.description as actualdescr, tt.name as typename, ta.reportgroupkey';
  {@UNFOLD MACRO INH_ORIG_FINALLY('TGDCTAXDESIGNDATE', 'GETSELECTCLAUSE', KEYGETSELECTCLAUSE)}
  {M}  finally
  {M}    if (not FDataTransfer) and Assigned(gdcBaseMethodControl) then
  {M}      ClearMacrosStack2('TGDCTAXDESIGNDATE', 'GETSELECTCLAUSE', KEYGETSELECTCLAUSE);
  {M}  end;
  {END MACRO}
end;

class function TgdcTaxDesignDate.GetSubSetList: String;
begin
  Result := inherited GetSubSetList + stByTax + ';' +
    stByType + ';' + stByTaxActual + ';' + stByDocumentDate + ';';
end;

class function TgdcTaxDesignDate.GetViewFormClassName(
  const ASubType: TgdcSubType): String;
begin
  Result := 'Tgdc_frmTaxDesignTime';
end;

class function TgdcTaxDesignDate.GetViewFormName: String;
begin
  Result := 'gdc_frmTaxDesignTime';
end;

procedure TgdcTaxDesignDate.GetWhereClauseConditions(S: TStrings);
begin
  inherited;
//  S.Add('parent IS NULL');
  if HasSubSet(stByTax) then
    S.Add('t.id = :taxnamekey');

  if HasSubSet(stByType) then
    S.Add('tt.id = :typekey');

  if HasSubSet(stByTaxActual) then
    S.Add('td.taxactualkey = :taxactualkey');

  if HasSubSet(stByDocumentDate) then
    S.Add('z.documentdate = :documentdate');
end;

procedure TgdcTaxDesignDate._DoOnNewRecord;
  {@UNFOLD MACRO INH_ORIG_PARAMS(VAR)}
  {M}VAR
  {M}  Params, LResult: Variant;
  {M}  tmpStrings: TStackStrings;
  {END MACRO}
begin
  {@UNFOLD MACRO INH_ORIG_WITHOUTPARAM('TGDCTAXDESIGNDATE', '_DOONNEWRECORD', KEY_DOONNEWRECORD)}
  {M}  try
  {M}    if (not FDataTransfer) and Assigned(gdcBaseMethodControl) then
  {M}    begin
  {M}      SetFirstMethodAssoc('TGDCTAXDESIGNDATE', KEY_DOONNEWRECORD);
  {M}      tmpStrings := TStackStrings(ClassMethodAssoc.IntByKey[KEY_DOONNEWRECORD]);
  {M}      if (tmpStrings = nil) or (tmpStrings.IndexOf('TGDCTAXDESIGNDATE') = -1) then
  {M}      begin
  {M}        Params := VarArrayOf([GetGdcInterface(Self)]);
  {M}        if gdcBaseMethodControl.ExecuteMethodNew(ClassMethodAssoc, Self, 'TGDCTAXDESIGNDATE',
  {M}          '_DOONNEWRECORD', KEY_DOONNEWRECORD, Params, LResult) then exit;
  {M}      end else
  {M}        if tmpStrings.LastClass.gdClassName <> 'TGDCTAXDESIGNDATE' then
  {M}        begin
  {M}          Inherited;
  {M}          Exit;
  {M}        end;
  {M}    end;
  {END MACRO}
  inherited;
  FieldByName('DocumentKey').AsInteger := ID;
  {@UNFOLD MACRO INH_ORIG_FINALLY('TGDCTAXDESIGNDATE', '_DOONNEWRECORD', KEY_DOONNEWRECORD)}
  {M}  finally
  {M}    if (not FDataTransfer) and Assigned(gdcBaseMethodControl) then
  {M}      ClearMacrosStack2('TGDCTAXDESIGNDATE', '_DOONNEWRECORD', KEY_DOONNEWRECORD);
  {M}  end;
  {END MACRO}
end;

{ TgdcTaxName }

function TgdcTaxName.CheckTheSameStatement: String;
  {@UNFOLD MACRO INH_ORIG_PARAMS(VAR)}
  {M}VAR
  {M}  Params, LResult: Variant;
  {M}  tmpStrings: TStackStrings;
  {END MACRO}
begin
  {@UNFOLD MACRO INH_ORIG_CHECKTHESAMESTATEMENT('TGDCTAXNAME', 'CHECKTHESAMESTATEMENT', KEYCHECKTHESAMESTATEMENT)}
  {M}  try
  {M}    if (not FDataTransfer) and Assigned(gdcBaseMethodControl) then
  {M}    begin
  {M}      SetFirstMethodAssoc('TGDCTAXNAME', KEYCHECKTHESAMESTATEMENT);
  {M}      tmpStrings := TStackStrings(ClassMethodAssoc.IntByKey[KEYCHECKTHESAMESTATEMENT]);
  {M}      if (tmpStrings = nil) or (tmpStrings.IndexOf('TGDCTAXNAME') = -1) then
  {M}      begin
  {M}        Params := VarArrayOf([GetGdcInterface(Self)]);
  {M}        if gdcBaseMethodControl.ExecuteMethodNew(ClassMethodAssoc, Self, 'TGDCTAXNAME',
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
  {M}        if tmpStrings.LastClass.gdClassName <> 'TGDCTAXNAME' then
  {M}        begin
  {M}          Result := Inherited CheckTheSameStatement;
  {M}          Exit;
  {M}        end;
  {M}    end;
  {END MACRO}
//����������� ������ ���� �� ��������������
  if FieldByName(GetKeyField(SubType)).AsInteger < cstUserIDStart then
    Result := inherited CheckTheSameStatement
  else
    Result := Format('SELECT %s FROM %s WHERE UPPER(name)=''%s'' ',
      [GetKeyField(SubType), GetListTable(SubType), AnsiUpperCase(FieldByName('name').AsString)]);
  {@UNFOLD MACRO INH_ORIG_FINALLY('TGDCTAXNAME', 'CHECKTHESAMESTATEMENT', KEYCHECKTHESAMESTATEMENT)}
  {M}  finally
  {M}    if (not FDataTransfer) and Assigned(gdcBaseMethodControl) then
  {M}      ClearMacrosStack2('TGDCTAXNAME', 'CHECKTHESAMESTATEMENT', KEYCHECKTHESAMESTATEMENT);
  {M}  end;
  {END MACRO}

end;

function TgdcTaxName.CreateDialogForm: TCreateableForm;
  {@UNFOLD MACRO INH_ORIG_PARAMS(VAR)}
  {M}VAR
  {M}  Params, LResult: Variant;
  {M}  tmpStrings: TStackStrings;
  {END MACRO}
begin
  {@UNFOLD MACRO INH_ORIG_FUNCCREATEDIALOGFORM('TGDCTAXNAME', 'CREATEDIALOGFORM', KEYCREATEDIALOGFORM)}
  {M}  try
  {M}    Result := nil;
  {M}    if (not FDataTransfer) and Assigned(gdcBaseMethodControl) then
  {M}    begin
  {M}      SetFirstMethodAssoc('TGDCTAXNAME', KEYCREATEDIALOGFORM);
  {M}      tmpStrings := TStackStrings(ClassMethodAssoc.IntByKey[KEYCREATEDIALOGFORM]);
  {M}      if (tmpStrings = nil) or (tmpStrings.IndexOf('TGDCTAXNAME') = -1) then
  {M}      begin
  {M}        Params := VarArrayOf([GetGdcInterface(Self)]);
  {M}        if gdcBaseMethodControl.ExecuteMethodNew(ClassMethodAssoc, Self, 'TGDCTAXNAME',
  {M}          'CREATEDIALOGFORM', KEYCREATEDIALOGFORM, Params, LResult) then
  {M}          begin
  {M}            Result := nil;
  {M}            if VarType(LResult) <> varDispatch then
  {M}              raise Exception.Create('������-�������: ' + Self.ClassName +
  {M}                TgdcBase(Self).SubType + 'CREATEDIALOGFORM' + #13#10 + '��� ������ ''' +
  {M}                'CREATEDIALOGFORM' + ' ''' + '������ ' + Self.ClassName +
  {M}                TgdcBase(Self).SubType + #10#13 + '�� ������� ��������� �� ������.')
  {M}            else
  {M}              if IDispatch(LResult) = nil then
  {M}                raise Exception.Create('������-�������: ' + Self.ClassName +
  {M}                  TgdcBase(Self).SubType + 'CREATEDIALOGFORM' + #13#10 + '��� ������ ''' +
  {M}                  'CREATEDIALOGFORM' + ' ''' + '������ ' + Self.ClassName +
  {M}                  TgdcBase(Self).SubType + #10#13 + '�� ������� ��������� ������ (null) ������.');
  {M}            Result := GetInterfaceToObject(LResult) as TCreateableForm;
  {M}            exit;
  {M}          end;
  {M}      end else
  {M}        if tmpStrings.LastClass.gdClassName <> 'TGDCTAXNAME' then
  {M}        begin
  {M}          Result := Inherited CreateDialogForm;
  {M}          Exit;
  {M}        end;
  {M}    end;
  {END MACRO}
  Result := Tgdc_dlgTaxName.CreateSubType(ParentForm, SubType);
  {@UNFOLD MACRO INH_ORIG_FINALLY('TGDCTAXNAME', 'CREATEDIALOGFORM', KEYCREATEDIALOGFORM)}
  {M}  finally
  {M}    if (not FDataTransfer) and Assigned(gdcBaseMethodControl) then
  {M}      ClearMacrosStack2('TGDCTAXNAME', 'CREATEDIALOGFORM', KEYCREATEDIALOGFORM);
  {M}  end;
  {END MACRO}
end;

class function TgdcTaxName.GetDisplayName(
  const ASubType: TgdcSubType): String;
begin
  Result := '������������� �����';
end;

class function TgdcTaxName.GetListField(
  const ASubType: TgdcSubType): String;
begin
  Result := 'name';
end;

class function TgdcTaxName.GetListTable(
  const ASubType: TgdcSubType): String;
begin
  Result := 'GD_TAXNAME';
end;

class function TgdcTaxName.GetViewFormClassName(
  const ASubType: TgdcSubType): String;
begin
  Result := 'Tgdc_frmTaxActual'//'Tgdc_frmTaxName';
end;

initialization
  RegisterGdcClass(TgdcTaxActual);
  RegisterGdcClass(TgdcTaxResult);
  RegisterGdcClass(TgdcTaxDesignDate);
  RegisterGdcClass(TgdcTaxName);

finalization
  UnRegisterGdcClass(TgdcTaxActual);
  UnRegisterGdcClass(TgdcTaxResult);
  UnRegisterGdcClass(TgdcTaxDesignDate);
  UnRegisterGdcClass(TgdcTaxName);

end.