// ShlTanya, 07.10.2019
{++

  Copyright (c) 2001-2022 by Golden Software of Belarus, Ltd

  Module

    gdcInvDocument_unit.pas

  Abstract

    Business class. Inventory base document.

  Author

    Romanovski Denis (17-09-2001)

  Revisions history

    Initial  17-09-2001  Dennis  Initial version.
    Changed  09-11-2001  Michael Minor changes

--}

unit gdcInvDocument_unit;

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs,
  ComCtrls, gdcBase, gd_createable_form, gdcClasses_interface, gdcClasses,
  at_Classes, gdcInvMovement, IBDatabase, DB, IBSQL, IB, IBErrorCodes,
  gdcInvConsts_unit, gdcBaseInterface, ComObj, gd_resourcestring, gd_KeyAssoc,
  gd_ClassList;

{$IFDEF DEBUGMOVE}
const
  TimeCustomInsertUSR: LongWord = 0;
  TimeCustomInsertDoc: LongWord = 0;
  TimeDoOnNewRecord: LongWord = 0;
  TimeGetRemains: LongWord = 0;
  TimeMakeMovement: LongWord = 0;
  TimeMakePos: LongWord = 0;
  TimeMakeInsert: LongWord = 0;
  TimeQueryList: LongWord = 0;
  TimeFillPosition: LongWord = 0;

  TimePostInPosition: LongWord = 0;
{$ENDIF}

type
  TgdcInvRelationAlias = record
    RelationName: String[31];
    AliasName: String[31];
  end;

  TgdcInvRelationAliases = array of TgdcInvRelationAlias;

  TgdcInvDocumentType = class;
  TgdcInvBaseDocument = class;
  TgdcInvBaseDocumentClass = class of TgdcInvBaseDocument;

  TgdcInvBaseDocument = class(TgdcDocument)
  private
    FRelationName, FRelationLineName: String; // ������������ ���������� �������
    FMovementSource, FMovementTarget: TgdcInvMovementContactOption; // �������� � ���������� ��������
    FRelationType: TgdcInvRelationType;
    FCurrentStreamVersion: String; // ������ ��������, ��������� �� ������

    FContact: TIBSQL;

    function EnumRelationFields(const Alias: String; SkipList: String;
      const UseDot: Boolean = True): String;
    function EnumModificationList(const ExcludeField: String = ''): String;

    function EnumRelationJoins(Relations: TgdcInvRelationAliases): String;
    function EnumJoinedListFields(Relations: TgdcInvRelationAliases): String;

    function GetRelation: TatRelation;
    function GetRelationLine: TatRelation;

    function GetRelationType: TgdcInvRelationType;

    procedure CreateContactSQL;
    procedure UpdatePredefinedFields;

  protected
    FStreamOptions: TStream;

    procedure CreateFields; override;
    procedure ReadOptions(DE: TgdDocumentEntry); override;

    //procedure WriteOptions(Stream: TStream); virtual;

    function GetJoins: TStringList; virtual; abstract;
    procedure SetJoins(const Value: TStringList); virtual; abstract;

    function GetNotCopyField: String; override;
    procedure DoBeforePost; override;

    property Joins: TStringList read GetJoins write SetJoins;

  public
    constructor Create(AnOwner: TComponent); override;
    constructor CreateSubType(AnOwner: TComponent; const ASubType: TgdcSubType;
      const ASubSet: TgdcSubSet = 'All'); override;

    destructor Destroy; override;

    function CheckTheSameStatement: String; override;
    function JoinListFieldByFieldName(const AFieldName, AAliasName, AJoinFieldName: String): String;
    procedure GetProperties(ASL: TStrings); override;

    class function IsAbstractClass: Boolean; override;
    class function GetViewFormClassName(const ASubType: TgdcSubType): String; override;

    property MovementSource: TgdcInvMovementContactOption read FMovementSource; // �������� ��������
    property MovementTarget: TgdcInvMovementContactOption read FMovementTarget; // ���������� ��������
    property RelationName: String read FRelationName;
    property RelationLineName: String read FRelationLineName;
    property Relation: TatRelation read GetRelation;
    property RelationLine: TatRelation read GetRelationLine;
    property RelationType: TgdcInvRelationType read GetRelationType;
    property CurrentStreamVersion: String read FCurrentStreamVersion;
    property BranchKey: TID read FBranchKey;
  end;


  TgdcInvDocument = class(TgdcInvBaseDocument)
  private
    FJoins: TStringList;
    FisLocalChange: Boolean;

  protected
    function GetSelectClause: String; override;
    function GetFromClause(const ARefresh: Boolean = False): String; override;
    function GetGroupClause: String; override;
    function GetOrderClause: String; override;
    procedure GetWhereClauseConditions(S: TStrings); override;

    procedure CustomInsert(Buff: Pointer); override;
    procedure CustomModify(Buff: Pointer); override;

    procedure _DoOnNewRecord; override;

    function GetJoins: TStringList; override;
    procedure SetJoins(const Value: TStringList); override;
    function GetDetailObject: TgdcDocument; override;

  public
    constructor Create(AnOwner: TComponent); override;
    destructor Destroy; override;

    //class function GetViewFormClassName(const ASubType: TgdcSubType): String; override;
    class function GetDialogFormClassName(const ASubType: TgdcSubType): String; override;
    class function GetDocumentClassPart: TgdcDocumentClassPart; override;

    procedure InternalSetFieldData(Field: TField; Buffer: Pointer); override;
  end;

  TgdcInvDocumentLine = class(TgdcInvBaseDocument)
  private
    FSourceFeatures, FDestFeatures, FMinusFeatures: TgdcInvFeatures; // ������ �������� ���������
    FDirection: TgdcInvMovementDirection; // ����������� �������� (FIFO, LIFO)
    FRestrictRemainsBy: string; // ���������� ����� �������� ��� �� ���������

    FMovement: TgdcInvMovement; // ������ ������ � ��������� ���

    FLineJoins: TStringList; // ������ ���������� � ������� ���������
    FSources: TgdcInvReferenceSources; // ��������� ���������� ����������

    FGoodSQL: TIBSQL; // ������ � ����������� �������
    FViewMovementPart: TgdcInvMovementPart; // ������� ����������� �������������

    FControlRemains: Boolean; // ����� �� �������������� �������
    FLiveTimeRemains: Boolean; // ������ ������ � �������� ���������
    FEndMonthRemains: Boolean; // �������� �� ����� ������

    FUseCachedUpdates: Boolean; // ����� �� ������������ CachedUpdates
    FCanBeDelayed: Boolean; // ������������ ���������
    FisErrorUpdate: Boolean; //
    FisErrorInsert: Boolean;
    FIsMinusRemains: Boolean;
    FisSetFeaturesFromRemains: Boolean;
    FisChangeCardValue: Boolean;
    FisAppendCardValue: Boolean;
    FSavePoint: String;
    FisCheckDestFeatures: Boolean;
    FisChooseRemains: Boolean;
    FUseGoodKeyForMakeMovement: Boolean;
    FIsMakeMovementOnFromCardKeyOnly: Boolean;
    FIsUseCompanyKey: Boolean;
    FSaveRestWindowOption: Boolean;
    FWithoutSearchRemains: Boolean;

    function EnumCardFields(const Alias: String; Kind: TgdcInvFeatureKind;
      const AsName: String = ''): String;
    function IsFeatureUsed(const FieldName: String; Features: TgdcInvFeatures): Boolean;

    procedure SetViewMovementPart(const Value: TgdcInvMovementPart);
    procedure SetIsMakeMovementOnFromCardKeyOnly(const Value: Boolean);
{$IFDEF NEWDEPOT}
    procedure NewCreateMovement;
{$ENDIF}
  protected
    //procedure WriteOptions(Stream: TStream); override;
    procedure ReadOptions(DE: TgdDocumentEntry); override;
    function GetSelectClause: String; override;
    function GetFromClause(const ARefresh: Boolean = False): String; override;
    function GetGroupClause: String; override;
    function GetOrderClause: String; override;

    function GetNotCopyField: String; override;

    procedure CustomInsert(Buff: Pointer); override;
    procedure CustomModify(Buff: Pointer); override;
    procedure CustomDelete(Buff: Pointer); override;

    procedure CreateFields; override;

    procedure _DoOnNewRecord; override;
    procedure DoBeforeInsert; override;
    procedure DoBeforeEdit; override;
    procedure DoAfterCancel; override;
    procedure DoBeforePost; override;
    procedure DoOnCalcFields; override;

    function GetJoins: TStringList; override;
    procedure SetJoins(const Value: TStringList); override;

    procedure GetWhereClauseConditions(S: TStrings); override;

    procedure SetSubType(const Value: TgdcSubType); override;
    function GetMasterObject: TgdcDocument; override;
    procedure SaveHeader;

  public
    constructor Create(AnOwner: TComponent); override;
    destructor Destroy; override;

    function ChooseRemains: Boolean;
    function SelectGoodFeatures: Boolean;

    procedure UpdateGoodNames;
    procedure SetFeatures(isFrom, isTo: Boolean);
    procedure GetProperties(ASL: TStrings); override;

    class function GetDocumentClassPart: TgdcDocumentClassPart; override;
    class function GetDialogFormClassName(const ASubType: TgdcSubType): String; override;

    property Sources: TgdcInvReferenceSources read FSources;
    property Direction: TgdcInvMovementDirection read FDirection;
    property RestrictRemainsBy: string read FRestrictRemainsBy;

    property SourceFeatures: TgdcInvFeatures read FSourceFeatures;
    property DestFeatures: TgdcInvFeatures read FDestFeatures;
    property MinusFeatures : TgdcInvFeatures read FMinusFeatures;

    property ViewMovementPart: TgdcInvMovementPart read FViewMovementPart write SetViewMovementPart;
    property ControlRemains: Boolean read FControlRemains write FControlRemains;
    property Movement: TgdcInvMovement read FMovement;
    property UseCachedUpdates: Boolean read FUseCachedUpdates;
    property CanBeDelayed: Boolean read FCanBeDelayed;
    property LiveTimeRemains: Boolean read FLiveTimeRemains write FLiveTimeRemains;
    property EndMonthRemains: Boolean read FEndMonthRemains write FEndMonthRemains;
    property WithoutSearchRemains: Boolean read FWithoutSearchRemains write FWithoutSearchRemains;
    property isMinusRemains: Boolean read FIsMinusRemains write FIsMinusRemains;
    property isSetFeaturesFromRemains: Boolean read FisSetFeaturesFromRemains
      write FisSetFeaturesFromRemains;
    property isChooseRemains: Boolean read FisChooseRemains
      write FisChooseRemains;

    property isChangeCardValue: Boolean read FisChangeCardValue write FisChangeCardValue;
    property isAppendCardValue: Boolean read FisAppendCardValue write FisAppendCardValue;
    property isUseCompanyKey: Boolean read FIsUseCompanyKey write FIsUseCompanyKey;
    property SaveRestWindowOption: Boolean read FSaveRestWindowOption write FSaveRestWindowOption;
    property SavePoint: String read FSavePoint;

    property isCheckDestFeatures: Boolean read FisCheckDestFeatures write FisCheckDestFeatures default True;
    property UseGoodKeyForMakeMovement: Boolean read FUseGoodKeyForMakeMovement write FUseGoodKeyForMakeMovement default False;
    property IsMakeMovementOnFromCardKeyOnly: Boolean read FIsMakeMovementOnFromCardKeyOnly write SetIsMakeMovementOnFromCardKeyOnly default False;

    procedure _SaveToStream(Stream: TStream; ObjectSet: TgdcObjectSet;
      PropertyList: TgdcPropertySets; BindedList: TgdcObjectSet;
      WithDetailList: TgdKeyArray; const SaveDetailObjects: Boolean = True); override;
  end;

  TgdcInvDocumentType = class(TgdcDocumentType)
  private
    {$IFDEF NEWDEPOT}
    procedure CreateTriggers;
    procedure CreateTempTable;
    {$ENDIF}

  protected
    FIE: TgdInvDocumentEntry;

    procedure CreateFields; override;
    procedure DoBeforePost; override;
    procedure DoAfterCustomProcess(Buff: Pointer; Process: TgsCustomProcess); override;

  public
    constructor Create(AnOwner: TComponent); override;
    destructor Destroy; override;

    procedure InitOpt; override;
    procedure DoneOpt; override;
    procedure UpdateFlag(const AFlag: TgdInvDocumentEntryFlag; const AValue: Boolean;
      const ACheckValue: Boolean = True);
    procedure UpdateContactTypeOption(const AValue: TgdcInvMovementContactType;
      const APrefix: String);
    procedure UpdateRF(const ARF: TatRelationField; const AName: String);
    procedure UpdateContactList(lv: TListView; const AName: String; V: TgdcMCOPredefined);
    procedure UpdateFeatures(const AFeature: TgdInvDocumentEntryFeature; SL: TStrings);

    class function InvDocumentTypeBranchKey: TID;
    class function GetHeaderDocumentClass: CgdcBase; override;
    class function GetViewFormClassName(const ASubType: TgdcSubType): String; override;
    class function GetDialogFormClassName(const ASubType: TgdcSubType): String; override;
  end;

  EgdcInvBaseDocument = class(EgdcException);
  EgdcInvDocument = class(EgdcException);
  EgdcInvDocumentLine = class(EgdcException);
  EgdcInvDocumentType = class(EgdcException);

procedure Register;

function RelationTypeByRelation(Relation: TatRelation): TgdcInvRelationType;

implementation

uses
  gd_security_OperationConst, gdc_dlgSetupInvDocument_unit, gdc_dlgG_unit,
  gdc_dlgInvDocument_unit, gdc_dlgInvDocumentLine_unit, gd_security,
  at_sql_setup, gdc_frmInvDocument_unit, gdc_frmInvDocumentType_unit,
  gdc_dlgViewMovement_unit, gdcMetaData,
  gd_common_functions
  {must be placed after Windows unit!}
  {$IFDEF LOCALIZATION}
    , gd_localization_stub
  {$ENDIF}
  ;

type
  TgdcInvShortField = record
    FieldName: String;
    AliasName: String;
  end;

  TgdcInvShortFieldArray = array of TgdcInvShortField;

procedure Register;
begin
  RegisterComponents('GDC', [TgdcInvDocumentType, TgdcInvDocument, TgdcInvDocumentLine]);
end;

function RelationTypeByRelation(Relation: TatRelation): TgdcInvRelationType;
begin
  if not Assigned(Relation) then
    Result := irtInvalid else

  with Relation.RelationFields do
  begin
    if
      (ByFieldName('MASTERKEY') <> nil) and
      (ByFieldName('DOCUMENTKEY') <> nil) and
      (ByFieldName('FROMCARDKEY') <> nil) and
      (ByFieldName('TOCARDKEY') <> nil) and
      (ByFieldName('QUANTITY') <> nil)
    then
      Result := irtFeatureChange else

    if
      (ByFieldName('MASTERKEY') <> nil) and
      (ByFieldName('DOCUMENTKEY') <> nil) and
      (ByFieldName('FROMCARDKEY') <> nil) and
      (ByFieldName('FROMQUANTITY') <> nil) and
      (ByFieldName('TOQUANTITY') <> nil)
    then
      Result := irtInventorization else

    if
      (ByFieldName('MASTERKEY') <> nil) and
      (ByFieldName('DOCUMENTKEY') <> nil) and
      (ByFieldName('FROMCARDKEY') <> nil) and
      (ByFieldName('INQUANTITY') <> nil) and
      (ByFieldName('OUTQUANTITY') <> nil)
    then
      Result := irtTransformation else

    if
      (ByFieldName('MASTERKEY') <> nil) and
      (ByFieldName('DOCUMENTKEY') <> nil) and
      (ByFieldName('FROMCARDKEY') <> nil) and
      (ByFieldName('QUANTITY') <> nil)
    then
      Result := irtSimple
    else
      Result := irtInvalid;
  end;
end;


{ TgdcInvBaseDocument }

constructor TgdcInvBaseDocument.Create(AnOwner: TComponent);
begin
  inherited;

  FMovementSource := TgdcInvMovementContactOption.Create;
  FMovementTarget := TgdcInvMovementContactOption.Create;

  FRelationName := '';
  FRelationLineName := '';
  FContact := nil;
  FRelationType := irtInvalid;

  FCurrentStreamVersion := gdcInv_Document_Undone;
end;

procedure TgdcInvBaseDocument.CreateContactSQL;
begin
  if not Assigned(FContact) then
  begin
    FContact := TIBSQL.Create(nil);
    FContact.SQL.Text := 'SELECT id, name FROM gd_contact WHERE id = :id';
  end;

  if FContact.Transaction = nil then
    FContact.Transaction := ReadTransaction;

  if FContact.Database = nil then
    FContact.Database := Database;
end;

procedure TgdcInvBaseDocument.CreateFields;
var
  {@UNFOLD MACRO INH_ORIG_PARAMS()}
  {M}
  {M}  Params, LResult: Variant;
  {M}  tmpStrings: TStackStrings;
  {END MACRO}
  I: Integer;
begin
  {@UNFOLD MACRO INH_ORIG_WITHOUTPARAM('TGDCINVBASEDOCUMENT', 'CREATEFIELDS', KEYCREATEFIELDS)}
  {M}  try
  {M}    if (not FDataTransfer) and Assigned(gdcBaseMethodControl) then
  {M}    begin
  {M}      SetFirstMethodAssoc('TGDCINVBASEDOCUMENT', KEYCREATEFIELDS);
  {M}      tmpStrings := TStackStrings(ClassMethodAssoc.IntByKey[KEYCREATEFIELDS]);
  {M}      if (tmpStrings = nil) or (tmpStrings.IndexOf('TGDCINVBASEDOCUMENT') = -1) then
  {M}      begin
  {M}        Params := VarArrayOf([GetGdcInterface(Self)]);
  {M}        if gdcBaseMethodControl.ExecuteMethodNew(ClassMethodAssoc, Self, 'TGDCINVBASEDOCUMENT',
  {M}          'CREATEFIELDS', KEYCREATEFIELDS, Params, LResult) then exit;
  {M}      end else
  {M}        if tmpStrings.LastClass.gdClassName <> 'TGDCINVBASEDOCUMENT' then
  {M}        begin
  {M}          Inherited;
  {M}          Exit;
  {M}        end;
  {M}    end;
  {END MACRO}
  inherited;

  if (csDesigning in ComponentState) or (FDocumentTypeKey = -1) then
    Exit;

  FieldByName('documentkey').Required := False;

  for I := 0 to Joins.Count - 1 do
    FieldByName(Joins.Values[Joins.Names[I]]).Required := False;
  {@UNFOLD MACRO INH_ORIG_FINALLY('TGDCINVBASEDOCUMENT', 'CREATEFIELDS', KEYCREATEFIELDS)}
  {M}  finally
  {M}    if (not FDataTransfer) and Assigned(gdcBaseMethodControl) then
  {M}      ClearMacrosStack2('TGDCINVBASEDOCUMENT', 'CREATEFIELDS', KEYCREATEFIELDS);
  {M}  end;
  {END MACRO}
end;

constructor TgdcInvBaseDocument.CreateSubType(AnOwner: TComponent;
  const ASubType: TgdcSubType; const ASubSet: TgdcSubSet = 'All');
begin
  inherited;

end;

destructor TgdcInvBaseDocument.Destroy;
begin
  FContact.Free;
  FMovementSource.Free;
  FMovementTarget.Free;
  inherited;
end;

function TgdcInvBaseDocument.EnumModificationList(const ExcludeField: String = ''): String;
var
  I: Integer;
  R: TatRelation;
begin
  if Self is TgdcInvDocument then
    R := Relation
  else
    R := RelationLine;

  Assert(R <> nil, 'Relation not assigned!');

  Result := '';

  for I := 0 to R.RelationFields.Count - 1 do
  begin
    if AnsiPos(R.RelationFields[I].FieldName + ';', ExcludeField) <> 0 then Continue;
    Result := Result +
      R.RelationFields[I].FieldName +
      ' = :' +
      R.RelationFields[I].FieldName;

    if I < R.RelationFields.Count - 1 then
      Result := Result + ', ';
  end;
end;

function TgdcInvBaseDocument.EnumRelationFields(const Alias: String;
  SkipList: String; const UseDot: Boolean = True): String;
var
  I: Integer;
  R: TatRelation;
  CE: TgdClassEntry;
begin
  CE := gdClassList.Get(TgdDocumentEntry, Self.ClassName, Self.SubType).GetRootSubType;

  Assert(atDatabase <> nil, 'Relation not assigned!');

  R := atDatabase.Relations.ByRelationName(TgdDocumentEntry(CE).DistinctRelation);

  Assert(R <> nil, 'Relation not assigned!');

  Result := '';

  for I := 0 to R.RelationFields.Count - 1 do
  begin
    if AnsiPos(R.RelationFields[I].FieldName + ';', SkipList) <> 0 then Continue;

    Result := Result + Alias;

    if UseDot then
      Result := Result + '.';

    Result := Result +
      R.RelationFields[I].FieldName;

    if I < R.RelationFields.Count - 1 then
      Result := Result + ', ';
  end;
end;

function TgdcInvBaseDocument.EnumRelationJoins(Relations: TgdcInvRelationAliases): String;
var
  R: TatRelation;
  I, K: Integer;
  InnerJoins, LeftJoins: TStringList;
  Line: String;
begin
  Result := '';
  InnerJoins := TStringList.Create;
  LeftJoins := TStringList.Create;

  try
    for I := 1 to Length(Relations) do
    begin
      R := atDatabase.Relations.ByRelationName(Relations[I - 1].RelationName);

      Assert(R <> nil, 'Relation not found!');

      for K := 1 to R.RelationFields.Count do
      with R.RelationFields[K - 1] do
      begin
        if not IsUserDefined or not Visible or (References = nil) then
          Continue;

        // ���� ������� �� ������������ � �������� �������,
        // �� ���������� ���

        Line := '';
        if (Self is TgdcInvDocumentLine) then
        with (Self as TgdcInvDocumentLine) do
          if (AnsiCompareText(R.RelationName, 'INV_CARD') = 0) then
          begin
            if (RelationType <> irtFeatureChange) and
              not IsFeatureUsed(FieldName, SourceFeatures) and
              not IsFeatureUsed(FieldName, DestFeatures)
            then
              Continue
            else
              if (RelationType = irtFeatureChange) and
                 (
                 ((Relations[I - 1].AliasName = 'CARD') and not IsFeatureUsed(FieldName, SourceFeatures)) or
                 ((Relations[I - 1].AliasName = 'TOCARD') and not IsFeatureUsed(FieldName, DestFeatures))
                 )
              then
                Continue;
          end;

        if Field.IsNullable then
          Line := 'LEFT JOIN '
        else
          Line := 'JOIN ';

        Line := Line +
          Format(
            '%0:s %1:s_%2:s ON (%1:s.%2:s = %1:s_%2:s.%3:s) ',
            [
              References.RelationName,
              Relations[I - 1].AliasName,
              FieldName,
              References.PrimaryKey.ConstraintFields[0].FieldName
            ]
          );

        FSQLSetup.Ignores.AddAliasName(
          Relations[I - 1].AliasName + '_' + FieldName);

        if Field.IsNullable then
          LeftJoins.Add(Line)
        else
          InnerJoins.Add(Line);
      end;
    end;

    for I := 0 to InnerJoins.Count - 1 do
      Result := Result + InnerJoins[I];

    for I := 0 to LeftJoins.Count - 1 do
      Result := Result + LeftJoins[I];
  finally
    InnerJoins.Free;
    LeftJoins.Free;
  end;
end;

function TgdcInvBaseDocument.EnumJoinedListFields(Relations: TgdcInvRelationAliases): String;
var
  R: TatRelation;
  I, K: Integer;
  ListFieldName: String;
begin
  Joins.Clear;
  Result := '';

  for I := 1 to Length(Relations) do
  begin
    R := atDatabase.Relations.ByRelationName(Relations[I - 1].RelationName);

    Assert(R <> nil, 'Relation not found!');

    for K := 1 to R.RelationFields.Count do
    with R.RelationFields[K - 1] do
    begin
      if not IsUserDefined or not Visible or (References = nil) then
        Continue;

      // ���� ������� �� ������������ � �������� �������,
      // �� ���������� ���

      if (Self is TgdcInvDocumentLine) then
        with (Self as TgdcInvDocumentLine) do
          if (AnsiCompareText(R.RelationName, 'INV_CARD') = 0) then
          begin
            if (RelationType <> irtFeatureChange) and
              not IsFeatureUsed(FieldName, SourceFeatures) and
              not IsFeatureUsed(FieldName, DestFeatures)
            then
              Continue
            else
              if (RelationType = irtFeatureChange) and
                 (
                 ((Relations[I - 1].AliasName = 'CARD') and not IsFeatureUsed(FieldName, SourceFeatures)) or
                 ((Relations[I - 1].AliasName = 'TOCARD') and not IsFeatureUsed(FieldName, DestFeatures))
                 )
              then
                Continue;
          end;

      if Assigned(Field.RefListField) then
        ListFieldName := Field.RefListField.FieldName
      else
        ListFieldName := References.ListField.FieldName;

      Result := Result + ', ' +
        Relations[I - 1].AliasName + '_' + FieldName + '.' +
          ListFieldName +
        ' as ' +
        Relations[I - 1].AliasName + '_' + FieldName + '_' + ListFieldName;
    end;
  end;
end;

function TgdcInvBaseDocument.GetRelation: TatRelation;
begin
  Assert(atDatabase <> nil, 'Attributes database not assigned!');
  Result := atDatabase.Relations.ByRelationName(FRelationName);
end;

function TgdcInvBaseDocument.GetRelationLine: TatRelation;
begin
  Assert(atDatabase <> nil, 'Attributes database not assigned!');
  Result := atDatabase.Relations.ByRelationName(FRelationLineName);
end;

function TgdcInvBaseDocument.GetRelationType: TgdcInvRelationType;
begin
  Result := FRelationType;
end;

function TgdcInvBaseDocument.JoinListFieldByFieldName(
  const AFieldName, AAliasName, AJoinFieldName: String): String;
begin
  Result := AAliasName + '_' + AFieldName + '_' + AJoinFieldName;
end;

procedure TgdcInvBaseDocument.ReadOptions(DE: TgdDocumentEntry);
var
  AnIDE: TgdInvDocumentEntry;
  R: TatRelation;
  LDE: TgdInvDocumentEntry;
begin
  Assert(not Active);

  inherited;

  if DE <> nil then
  begin
    AnIDE := DE as TgdInvDocumentEntry;

    FRelationName := AnIDE.HeaderRelName;
    FRelationLineName := AnIDE.LineRelName;

    LDE := gdClassList.Get(TgdInvDocumentEntry, 'TgdcInvDocumentLine', Self.SubType).GetRootSubType as TgdInvDocumentEntry;
    R := atDatabase.Relations.ByRelationName(LDE.DistinctRelation);
    if R <> nil then
      FRelationType := RelationTypeByRelation(R)
    else
      raise EgdcInvBaseDocument.Create('Unknown document line table: ' + LDE.DistinctRelation);

    FMovementTarget.RelationName := AnIDE.GetMCORelationName(emDebit);
    FMovementTarget.SourceFieldName := AnIDE.GetMCOSourceFieldName(emDebit);
    FMovementTarget.SubRelationName := AnIDE.GetMCOSubRelationName(emDebit);
    FMovementTarget.SubSourceFieldName := AnIDE.GetMCOSubSourceFieldName(emDebit);
    FMovementTarget.ContactType := AnIDE.GetMCOContactType(emDebit);
    AnIDE.GetMCOPredefined(emDebit, FMovementTarget.Predefined);
    AnIDE.GetMCOSubPredefined(emDebit, FMovementTarget.SubPredefined);

    FMovementSource.RelationName := AnIDE.GetMCORelationName(emCredit);
    FMovementSource.SourceFieldName := AnIDE.GetMCOSourceFieldName(emCredit);
    FMovementSource.SubRelationName := AnIDE.GetMCOSubRelationName(emCredit);
    FMovementSource.SubSourceFieldName := AnIDE.GetMCOSubSourceFieldName(emCredit);
    FMovementSource.ContactType := AnIDE.GetMCOContactType(emCredit);
    AnIDE.GetMCOPredefined(emCredit, FMovementSource.Predefined);
    AnIDE.GetMCOSubPredefined(emCredit, FMovementSource.SubPredefined);
  end else
  begin
    FMovementSource.Clear;
    FMovementTarget.Clear;
    FRelationName := '';
    FRelationLineName := '';
    FRelationType := irtInvalid;
  end;
end;

procedure TgdcInvBaseDocument.UpdatePredefinedFields;
var
  RelName: String;
  CE: TgdClassEntry;

  procedure CheckMovement(M: TgdcInvMovementContactOption);
  begin
    if
      (AnsiCompareText(M.SubRelationName, RelName) = 0)
        and
      (Length(M.SubPredefined) > 0)
    then begin
      CreateContactSQL;
      SetTID(FieldByName(M.SubSourceFieldName), M.SubPredefined[0]);

      FContact.Close;
      SetTID(FContact.ParamByName('id'), M.SubPredefined[0]);
      FContact.ExecQuery;

      if (FContact.RecordCount > 0) and
        (FindField(JoinListFieldByFieldName(M.SubSourceFieldName, 'INVDOC', 'NAME')) <> nil)
      then
        FieldByName(JoinListFieldByFieldName(M.SubSourceFieldName, 'INVDOC', 'NAME')).AsString :=
          FContact.FieldByName('name').AsString;

      FContact.Close;
    end;

    if
      (AnsiCompareText(M.RelationName, RelName) = 0)
        and
      (Length(M.Predefined) > 0)
        and
      (Length(M.SubPredefined) = 0)
    then begin
      CreateContactSQL;
      SetTID(FieldByName(M.SourceFieldName), M.Predefined[0]);

      FContact.Close;
      SetTID(FContact.ParamByName('id'), M.Predefined[0]);
      FContact.ExecQuery;

      if FContact.RecordCount > 0 then
      begin
        if GetDocumentClassPart = dcpHeader then
          FieldByName(JoinListFieldByFieldName(M.SourceFieldName, 'INVDOC', 'NAME')).AsString :=
            FContact.FieldByName('name').AsString
        else
          FieldByName(JoinListFieldByFieldName(M.SourceFieldName, 'INVLINE', 'NAME')).AsString :=
            FContact.FieldByName('name').AsString;
      end;
      FContact.Close;
    end;
  end;

begin
  if State <> dsInsert then Exit;

  CE := gdClassList.Get(TgdDocumentEntry, Self.ClassName, Self.SubType).GetRootSubType;
  RelName := TgdDocumentEntry(CE).DistinctRelation;

  CheckMovement(MovementSource);
  CheckMovement(MovementTarget);
end;

{procedure TgdcInvBaseDocument.WriteOptions(Stream: TStream);
var
  I: Integer;
begin
  with TWriter.Create(Stream, 1024) do
  try
    WriteString(gdcInvDocument_Version3_0);
    WriteString(FRelationName);
    WriteString(FRelationLineName);

    WriteInteger(FReportGroupKey);

    WriteString(FMovementTarget.RelationName);
    WriteString(FMovementTarget.SourceFieldName);
    WriteString(FMovementTarget.SubRelationName);
    WriteString(FMovementTarget.SubSourceFieldName);
    Write(FMovementTarget.ContactType, SizeOf(TgdcInvMovementContactType));

    WriteListBegin;
      for I := 0 to Length(FMovementTarget.Predefined) - 1 do
        WriteInteger(FMovementTarget.Predefined[I]);
    WriteListEnd;

    WriteListBegin;
      for I := 0 to Length(FMovementTarget.SubPredefined) - 1 do
        WriteInteger(FMovementTarget.SubPredefined[I]);
    WriteListEnd;

    WriteString(FMovementSource.RelationName);
    WriteString(FMovementSource.SourceFieldName);
    WriteString(FMovementSource.SubRelationName);
    WriteString(FMovementSource.SubSourceFieldName);
    Write(FMovementSource.ContactType, SizeOf(TgdcInvMovementContactType));

    WriteListBegin;
      for I := 0 to Length(FMovementSource.Predefined) - 1 do
        WriteInteger(FMovementSource.Predefined[I]);
    WriteListEnd;

    WriteListBegin;
      for I := 0 to Length(FMovementSource.SubPredefined) - 1 do
        WriteInteger(FMovementSource.SubPredefined[I]);
    WriteListEnd;
  finally
    Free;
  end;
end;}

function TgdcInvBaseDocument.GetNotCopyField: String;
  {@UNFOLD MACRO INH_ORIG_PARAMS(VAR)}
  {M}VAR
  {M}  Params, LResult: Variant;
  {M}  tmpStrings: TStackStrings;
  {END MACRO}
begin
  {@UNFOLD MACRO INH_ORIG_GETNOTCOPYFIELD('TGDCINVBASEDOCUMENT', 'GETNOTCOPYFIELD', KEYGETNOTCOPYFIELD)}
  {M}  try
  {M}    if (not FDataTransfer) and Assigned(gdcBaseMethodControl) then
  {M}    begin
  {M}      SetFirstMethodAssoc('TGDCINVBASEDOCUMENT', KEYGETNOTCOPYFIELD);
  {M}      tmpStrings := TStackStrings(ClassMethodAssoc.IntByKey[KEYGETNOTCOPYFIELD]);
  {M}      if (tmpStrings = nil) or (tmpStrings.IndexOf('TGDCINVBASEDOCUMENT') = -1) then
  {M}      begin
  {M}        Params := VarArrayOf([GetGdcInterface(Self)]);
  {M}        if gdcBaseMethodControl.ExecuteMethodNew(ClassMethodAssoc, Self, 'TGDCINVBASEDOCUMENT',
  {M}          'GETNOTCOPYFIELD', KEYGETNOTCOPYFIELD, Params, LResult) then
  {M}          begin
  {M}            if (VarType(LResult) = varOleStr) or (VarType(LResult) = varString) then
  {M}              Result := String(LResult)
  {M}            else
  {M}              begin
  {M}                raise Exception.Create('��� ������ ''' + 'GETNOTCOPYFIELD' + ' ''' +
  {M}                  ' ������ ' + Self.ClassName + TgdcBase(Self).SubType + #10#13 +
  {M}                  '�� ������� ��������� �� ��������� ���');
  {M}              end;
  {M}            exit;
  {M}          end;
  {M}      end else
  {M}        if tmpStrings.LastClass.gdClassName <> 'TGDCINVBASEDOCUMENT' then
  {M}        begin
  {M}          Result := Inherited GetNotCopyField;
  {M}          Exit;
  {M}        end;
  {M}    end;
  {END MACRO}

  Result := inherited GetNotCopyField + ',DOCUMENTKEY';

  if GetDocumentClassPart <> dcpHeader then
    Result := Result + ',MASTERKEY';

  {@UNFOLD MACRO INH_ORIG_FINALLY('TGDCINVBASEDOCUMENT', 'GETNOTCOPYFIELD', KEYGETNOTCOPYFIELD)}
  {M}  finally
  {M}    if (not FDataTransfer) and Assigned(gdcBaseMethodControl) then
  {M}      ClearMacrosStack2('TGDCINVBASEDOCUMENT', 'GETNOTCOPYFIELD', KEYGETNOTCOPYFIELD);
  {M}  end;
  {END MACRO}
end;

class function TgdcInvBaseDocument.GetViewFormClassName(
  const ASubType: TgdcSubType): String;
begin
  Result := 'Tgdc_frmInvDocument';
end;

function TgdcInvBaseDocument.CheckTheSameStatement: String;
  {@UNFOLD MACRO INH_ORIG_PARAMS(VAR)}
  {M}VAR
  {M}  Params, LResult: Variant;
  {M}  tmpStrings: TStackStrings;
  {END MACRO}
begin
  {@UNFOLD MACRO INH_ORIG_CHECKTHESAMESTATEMENT('TGDCINVBASEDOCUMENT', 'CHECKTHESAMESTATEMENT', KEYCHECKTHESAMESTATEMENT)}
  {M}  try
  {M}    if (not FDataTransfer) and Assigned(gdcBaseMethodControl) then
  {M}    begin
  {M}      SetFirstMethodAssoc('TGDCINVBASEDOCUMENT', KEYCHECKTHESAMESTATEMENT);
  {M}      tmpStrings := TStackStrings(ClassMethodAssoc.IntByKey[KEYCHECKTHESAMESTATEMENT]);
  {M}      if (tmpStrings = nil) or (tmpStrings.IndexOf('TGDCINVBASEDOCUMENT') = -1) then
  {M}      begin
  {M}        Params := VarArrayOf([GetGdcInterface(Self)]);
  {M}        if gdcBaseMethodControl.ExecuteMethodNew(ClassMethodAssoc, Self, 'TGDCINVBASEDOCUMENT',
  {M}          'CHECKTHESAMESTATEMENT', KEYCHECKTHESAMESTATEMENT, Params, LResult) then
  {M}          begin
  {M}            if (VarType(LResult) = varOleStr) or (VarType(LResult) = varString) then
  {M}              Result := String(LResult)
  {M}            else
  {M}              begin
  {M}                raise Exception.Create('��� ������ ''' + 'CHECKTHESAMESTATEMENT' + ' ''' +
  {M}                  ' ������ ' + Self.ClassName + TGDCINVBASEDOCUMENT(Self).SubType + #10#13 +
  {M}                  '�� ������� ��������� �� ��������� ���');
  {M}              end;
  {M}            exit;
  {M}          end;
  {M}      end else
  {M}        if tmpStrings.LastClass.gdClassName <> 'TGDCINVBASEDOCUMENT' then
  {M}        begin
  {M}          Result := Inherited CheckTheSameStatement;
  {M}          Exit;
  {M}        end;
  {M}    end;
  {END MACRO}
  Result := '';
  {@UNFOLD MACRO INH_ORIG_FINALLY('TGDCINVBASEDOCUMENT', 'CHECKTHESAMESTATEMENT', KEYCHECKTHESAMESTATEMENT)}
  {M}  finally
  {M}    if (not FDataTransfer) and Assigned(gdcBaseMethodControl) then
  {M}      ClearMacrosStack2('TGDCINVBASEDOCUMENT', 'CHECKTHESAMESTATEMENT', KEYCHECKTHESAMESTATEMENT);
  {M}  end;
  {END MACRO}
end;

class function TgdcInvBaseDocument.IsAbstractClass: Boolean;
begin
  Result := Self.ClassNameIs('TgdcInvBaseDocument');
end;

procedure TgdcInvBaseDocument.DoBeforePost;
  {@UNFOLD MACRO INH_ORIG_PARAMS(VAR)}
  {M}VAR
  {M}  Params, LResult: Variant;
  {M}  tmpStrings: TStackStrings;
  {END MACRO}
begin
  {@UNFOLD MACRO INH_ORIG_WITHOUTPARAM('TGDCINVBASEDOCUMENT', 'DOBEFOREPOST', KEYDOBEFOREPOST)}
  {M}  try
  {M}    if (not FDataTransfer) and Assigned(gdcBaseMethodControl) then
  {M}    begin
  {M}      SetFirstMethodAssoc('TGDCINVBASEDOCUMENT', KEYDOBEFOREPOST);
  {M}      tmpStrings := TStackStrings(ClassMethodAssoc.IntByKey[KEYDOBEFOREPOST]);
  {M}      if (tmpStrings = nil) or (tmpStrings.IndexOf('TGDCINVBASEDOCUMENT') = -1) then
  {M}      begin
  {M}        Params := VarArrayOf([GetGdcInterface(Self)]);
  {M}        if gdcBaseMethodControl.ExecuteMethodNew(ClassMethodAssoc, Self, 'TGDCINVBASEDOCUMENT',
  {M}          'DOBEFOREPOST', KEYDOBEFOREPOST, Params, LResult) then exit;
  {M}      end else
  {M}        if tmpStrings.LastClass.gdClassName <> 'TGDCINVBASEDOCUMENT' then
  {M}        begin
  {M}          Inherited;
  {M}          Exit;
  {M}        end;
  {M}    end;
  {END MACRO}

  if sMultiple in BaseState then
    raise EgdcInvDocument.Create('������������� �������������� ��������� ���������� �� �����������.');

  inherited;

  {@UNFOLD MACRO INH_ORIG_FINALLY('TGDCINVBASEDOCUMENT', 'DOBEFOREPOST', KEYDOBEFOREPOST)}
  {M}  finally
  {M}    if (not FDataTransfer) and Assigned(gdcBaseMethodControl) then
  {M}      ClearMacrosStack2('TGDCINVBASEDOCUMENT', 'DOBEFOREPOST', KEYDOBEFOREPOST);
  {M}  end;
  {END MACRO}
end;

procedure TgdcInvBaseDocument.GetProperties(ASL: TStrings);
begin
  inherited;

  ASL.Add('');
  ASL.Add('[��������� ��������]');
  ASL.Add(AddSpaces('������� �����') + FRelationName);
  ASL.Add(AddSpaces('������� �������') + FRelationLineName);
  ASL.Add(AddSpaces('��� ������� �������') + InvRelationTypeNames[RelationType]);

  ASL.Add('');
  ASL.Add('[MovementSource]');
  FMovementSource.GetProperties(ASL);
  ASL.Add('');
  ASL.Add('[MovementTarget]');
  FMovementTarget.GetProperties(ASL);

  ASL.Add(AddSpaces('�� ���� ���������') + IntToStr(FDocumentTypeKey));
  ASL.Add(AddSpaces('�� ����� ����.') + IntToStr(FBranchKey));
end;

{ TgdcInvDocument }

constructor TgdcInvDocument.Create(AnOwner: TComponent);
begin
  inherited;
  FJoins := TStringList.Create;
  FisLocalChange := False;
end;

procedure TgdcInvDocument.CustomInsert(Buff: Pointer);
  {@UNFOLD MACRO INH_ORIG_PARAMS(VAR)}
  {M}VAR
  {M}  Params, LResult: Variant;
  {M}  tmpStrings: TStackStrings;
  {END MACRO}
  CE: TgdClassEntry;
begin
  {@UNFOLD MACRO INH_ORIG_CUSTOMINSERT('TGDCINVDOCUMENT', 'CUSTOMINSERT', KEYCUSTOMINSERT)}
  {M}  try
  {M}    if (not FDataTransfer) and Assigned(gdcBaseMethodControl) then
  {M}    begin
  {M}      SetFirstMethodAssoc('TGDCINVDOCUMENT', KEYCUSTOMINSERT);
  {M}      tmpStrings := TStackStrings(ClassMethodAssoc.IntByKey[KEYCUSTOMINSERT]);
  {M}      if (tmpStrings = nil) or (tmpStrings.IndexOf('TGDCINVDOCUMENT') = -1) then
  {M}      begin
  {M}        Params := VarArrayOf([GetGdcInterface(Self), Integer(Buff)]);
  {M}        if gdcBaseMethodControl.ExecuteMethodNew(ClassMethodAssoc, Self, 'TGDCINVDOCUMENT',
  {M}          'CUSTOMINSERT', KEYCUSTOMINSERT, Params, LResult) then
  {M}          exit;
  {M}      end else
  {M}        if tmpStrings.LastClass.gdClassName <> 'TGDCINVDOCUMENT' then
  {M}        begin
  {M}          Inherited;
  {M}          Exit;
  {M}        end;
  {M}    end;
  {END MACRO}

  inherited;

  if SubType > '' then
  begin
    if GetTID(FieldByName('id')) <> GetTID(FieldByName('documentkey')) then
      SetTID(FieldByName('documentkey'), GetTID(FieldByName('id')));
      
    CE := gdClassList.Get(TgdDocumentEntry, Self.ClassName, Self.SubType).GetRootSubType;
    CustomExecQuery(
      Format(
        'INSERT INTO %s ' +
        '  (%s) ' +
        'VALUES ' +
        '  (%s) ',
        [TgdDocumentEntry(CE).DistinctRelation, EnumRelationFields('', '', False), EnumRelationFields(':', '', False)]
      ),
      Buff
    );
  end;
  {@UNFOLD MACRO INH_ORIG_FINALLY('TGDCINVDOCUMENT', 'CUSTOMINSERT', KEYCUSTOMINSERT)}
  {M}  finally
  {M}    if (not FDataTransfer) and Assigned(gdcBaseMethodControl) then
  {M}      ClearMacrosStack2('TGDCINVDOCUMENT', 'CUSTOMINSERT', KEYCUSTOMINSERT);
  {M}  end;
  {END MACRO}
end;

procedure TgdcInvDocument.CustomModify(Buff: Pointer);
  {@UNFOLD MACRO INH_ORIG_PARAMS(VAR)}
  {M}VAR
  {M}  Params, LResult: Variant;
  {M}  tmpStrings: TStackStrings;
  {END MACRO}
  CE: TgdClassEntry;
begin
  {@UNFOLD MACRO INH_ORIG_CUSTOMINSERT('TGDCINVDOCUMENT', 'CUSTOMMODIFY', KEYCUSTOMMODIFY)}
  {M}  try
  {M}    if (not FDataTransfer) and Assigned(gdcBaseMethodControl) then
  {M}    begin
  {M}      SetFirstMethodAssoc('TGDCINVDOCUMENT', KEYCUSTOMMODIFY);
  {M}      tmpStrings := TStackStrings(ClassMethodAssoc.IntByKey[KEYCUSTOMMODIFY]);
  {M}      if (tmpStrings = nil) or (tmpStrings.IndexOf('TGDCINVDOCUMENT') = -1) then
  {M}      begin
  {M}        Params := VarArrayOf([GetGdcInterface(Self), Integer(Buff)]);
  {M}        if gdcBaseMethodControl.ExecuteMethodNew(ClassMethodAssoc, Self, 'TGDCINVDOCUMENT',
  {M}          'CUSTOMMODIFY', KEYCUSTOMMODIFY, Params, LResult) then
  {M}          exit;
  {M}      end else
  {M}        if tmpStrings.LastClass.gdClassName <> 'TGDCINVDOCUMENT' then
  {M}        begin
  {M}          Inherited;
  {M}          Exit;
  {M}        end;
  {M}    end;
  {END MACRO}

  inherited;

  if SubType > '' then
  begin
    CE := gdClassList.Get(TgdDocumentEntry, Self.ClassName, Self.SubType).GetRootSubType;
    CustomExecQuery(
      Format(
        'UPDATE %s ' +
        'SET ' +
        '  %s ' +
        'WHERE ' +
        '  (DOCUMENTKEY = :NEW_DOCUMENTKEY) ',
        [TgdDocumentEntry(CE).DistinctRelation, EnumModificationList]
      ),
      Buff
    );
  end;
  {@UNFOLD MACRO INH_ORIG_FINALLY('TGDCINVDOCUMENT', 'CUSTOMMODIFY', KEYCUSTOMMODIFY)}
  {M}  finally
  {M}    if (not FDataTransfer) and Assigned(gdcBaseMethodControl) then
  {M}      ClearMacrosStack2('TGDCINVDOCUMENT', 'CUSTOMMODIFY', KEYCUSTOMMODIFY);
  {M}  end;
  {END MACRO}
end;

destructor TgdcInvDocument.Destroy;
begin
  FJoins.Free;
  inherited;
end;

procedure TgdcInvDocument._DoOnNewRecord;
  {@UNFOLD MACRO INH_ORIG_PARAMS(VAR)}
  {M}VAR
  {M}  Params, LResult: Variant;
  {M}  tmpStrings: TStackStrings;
  {END MACRO}
begin
  {@UNFOLD MACRO INH_ORIG_WITHOUTPARAM('TGDCINVDOCUMENT', '_DOONNEWRECORD', KEY_DOONNEWRECORD)}
  {M}  try
  {M}    if (not FDataTransfer) and Assigned(gdcBaseMethodControl) then
  {M}    begin
  {M}      SetFirstMethodAssoc('TGDCINVDOCUMENT', KEY_DOONNEWRECORD);
  {M}      tmpStrings := TStackStrings(ClassMethodAssoc.IntByKey[KEY_DOONNEWRECORD]);
  {M}      if (tmpStrings = nil) or (tmpStrings.IndexOf('TGDCINVDOCUMENT') = -1) then
  {M}      begin
  {M}        Params := VarArrayOf([GetGdcInterface(Self)]);
  {M}        if gdcBaseMethodControl.ExecuteMethodNew(ClassMethodAssoc, Self, 'TGDCINVDOCUMENT',
  {M}          '_DOONNEWRECORD', KEY_DOONNEWRECORD, Params, LResult) then exit;
  {M}      end else
  {M}        if tmpStrings.LastClass.gdClassName <> 'TGDCINVDOCUMENT' then
  {M}        begin
  {M}          Inherited;
  {M}          Exit;
  {M}        end;
  {M}    end;
  {END MACRO}
  inherited;

  SetTID(FieldByName('DOCUMENTKEY'), GetTID(FieldByName('ID')));
  FieldByName('DELAYED').AsInteger := 0;

  UpdatePredefinedFields;
  {@UNFOLD MACRO INH_ORIG_FINALLY('TGDCINVDOCUMENT', '_DOONNEWRECORD', KEY_DOONNEWRECORD)}
  {M}  finally
  {M}    if (not FDataTransfer) and Assigned(gdcBaseMethodControl) then
  {M}      ClearMacrosStack2('TGDCINVDOCUMENT', '_DOONNEWRECORD', KEY_DOONNEWRECORD);
  {M}  end;
  {END MACRO}
end;

class function TgdcInvDocument.GetDocumentClassPart: TgdcDocumentClassPart;
begin
  Result := dcpHeader;
end;

function TgdcInvDocument.GetFromClause(const ARefresh: Boolean = False): String;
var
  {@UNFOLD MACRO INH_ORIG_PARAMS()}
  {M}
  {M}  Params, LResult: Variant;
  {M}  tmpStrings: TStackStrings;
  {END MACRO}
  Relations: TgdcInvRelationAliases;
  CE: TgdClassEntry;
begin
  {@UNFOLD MACRO INH_ORIG_GETFROMCLAUSE('TGDCINVDOCUMENT', 'GETFROMCLAUSE', KEYGETFROMCLAUSE)}
  {M}  try
  {M}    if (not FDataTransfer) and Assigned(gdcBaseMethodControl) then
  {M}    begin
  {M}      SetFirstMethodAssoc('TGDCINVDOCUMENT', KEYGETFROMCLAUSE);
  {M}      tmpStrings := TStackStrings(ClassMethodAssoc.IntByKey[KEYGETFROMCLAUSE]);
  {M}      if (tmpStrings = nil) or (tmpStrings.IndexOf('TGDCINVDOCUMENT') = -1) then
  {M}      begin
  {M}        Params := VarArrayOf([GetGdcInterface(Self), ARefresh]);
  {M}        if gdcBaseMethodControl.ExecuteMethodNew(ClassMethodAssoc, Self, 'TGDCINVDOCUMENT',
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
  {M}        if tmpStrings.LastClass.gdClassName <> 'TGDCINVDOCUMENT' then
  {M}        begin
  {M}          Result := Inherited GetFromClause(ARefresh);
  {M}          Exit;
  {M}        end;
  {M}    end;
  {END MACRO}

  if (csDesigning in ComponentState) or (FDocumentTypeKey = -1) or (SubType = '') then
  begin
    Result := inherited GetFromClause(ARefresh) +
      ' JOIN gd_documenttype thisdoctype ON thisdoctype.id = z.documenttypekey ' +
      ' JOIN gd_documenttype invdoctyperoot ON thisdoctype.lb > invdoctyperoot.lb AND thisdoctype.rb <= invdoctyperoot.rb ' +
      '  AND invdoctyperoot.id = 804000 AND invdoctyperoot.parent IS NULL ';
    exit;
  end;

  if SubType > '' then
  begin
    CE := gdClassList.Get(TgdDocumentEntry, Self.ClassName, Self.SubType).GetRootSubType;

    SetLength(Relations, 1);
    Relations[0].RelationName := TgdDocumentEntry(CE).DistinctRelation;
    Relations[0].AliasName := 'INVDOC';

    Result := Format(
      inherited GetFromClause(ARefresh) +
      '  JOIN %s INVDOC ON (Z.ID = INVDOC.DOCUMENTKEY) ',
      [TgdDocumentEntry(CE).DistinctRelation]
    );
  end;

  {@UNFOLD MACRO INH_ORIG_FINALLY('TGDCINVDOCUMENT', 'GETFROMCLAUSE', KEYGETFROMCLAUSE)}
  {M}  finally
  {M}    if (not FDataTransfer) and Assigned(gdcBaseMethodControl) then
  {M}      ClearMacrosStack2('TGDCINVDOCUMENT', 'GETFROMCLAUSE', KEYGETFROMCLAUSE);
  {M}  end;
  {END MACRO}
end;

function TgdcInvDocument.GetGroupClause: String;
  {@UNFOLD MACRO INH_ORIG_PARAMS(VAR)}
  {M}VAR
  {M}  Params, LResult: Variant;
  {M}  tmpStrings: TStackStrings;
  {END MACRO}
begin
  {@UNFOLD MACRO INH_ORIG_GETGROUPCLAUSE('TGDCINVDOCUMENT', 'GETGROUPCLAUSE', KEYGETGROUPCLAUSE)}
  {M}  try
  {M}    if (not FDataTransfer) and Assigned(gdcBaseMethodControl) then
  {M}    begin
  {M}      SetFirstMethodAssoc('TGDCINVDOCUMENT', KEYGETGROUPCLAUSE);
  {M}      tmpStrings := TStackStrings(ClassMethodAssoc.IntByKey[KEYGETGROUPCLAUSE]);
  {M}      if (tmpStrings = nil) or (tmpStrings.IndexOf('TGDCINVDOCUMENT') = -1) then
  {M}      begin
  {M}        Params := VarArrayOf([GetGdcInterface(Self)]);
  {M}        if gdcBaseMethodControl.ExecuteMethodNew(ClassMethodAssoc, Self, 'TGDCINVDOCUMENT',
  {M}          'GETGROUPCLAUSE', KEYGETGROUPCLAUSE, Params, LResult) then
  {M}          begin
  {M}            if (VarType(LResult) = varOleStr) or (VarType(LResult) = varString) then
  {M}              Result := String(LResult)
  {M}            else
  {M}              begin
  {M}                raise Exception.Create('��� ������ ''' + 'GETGROUPCLAUSE' + ' ''' +
  {M}                  ' ������ ' + Self.ClassName + TgdcBase(Self).SubType + #10#13 +
  {M}                  '�� ������� ��������� �� ��������� ���');
  {M}              end;
  {M}            exit;
  {M}          end;
  {M}      end else
  {M}        if tmpStrings.LastClass.gdClassName <> 'TGDCINVDOCUMENT' then
  {M}        begin
  {M}          Result := Inherited GetGroupClause;
  {M}          Exit;
  {M}        end;
  {M}    end;
  {END MACRO}
  Result := '';
  {@UNFOLD MACRO INH_ORIG_FINALLY('TGDCINVDOCUMENT', 'GETGROUPCLAUSE', KEYGETGROUPCLAUSE)}
  {M}  finally
  {M}    if (not FDataTransfer) and Assigned(gdcBaseMethodControl) then
  {M}      ClearMacrosStack2('TGDCINVDOCUMENT', 'GETGROUPCLAUSE', KEYGETGROUPCLAUSE);
  {M}  end;
  {END MACRO}
end;

function TgdcInvDocument.GetJoins: TStringList;
begin
  Result := FJoins;
end;

function TgdcInvDocument.GetOrderClause: String;
  {@UNFOLD MACRO INH_ORIG_PARAMS(VAR)}
  {M}VAR
  {M}  Params, LResult: Variant;
  {M}  tmpStrings: TStackStrings;
  {END MACRO}
begin
  {@UNFOLD MACRO INH_ORIG_GETORDERCLAUSE('TGDCINVDOCUMENT', 'GETORDERCLAUSE', KEYGETORDERCLAUSE)}
  {M}  try
  {M}    if (not FDataTransfer) and Assigned(gdcBaseMethodControl) then
  {M}    begin
  {M}      SetFirstMethodAssoc('TGDCINVDOCUMENT', KEYGETORDERCLAUSE);
  {M}      tmpStrings := TStackStrings(ClassMethodAssoc.IntByKey[KEYGETORDERCLAUSE]);
  {M}      if (tmpStrings = nil) or (tmpStrings.IndexOf('TGDCINVDOCUMENT') = -1) then
  {M}      begin
  {M}        Params := VarArrayOf([GetGdcInterface(Self)]);
  {M}        if gdcBaseMethodControl.ExecuteMethodNew(ClassMethodAssoc, Self, 'TGDCINVDOCUMENT',
  {M}          'GETORDERCLAUSE', KEYGETORDERCLAUSE, Params, LResult) then
  {M}          begin
  {M}            if (VarType(LResult) = varOleStr) or (VarType(LResult) = varString) then
  {M}              Result := String(LResult)
  {M}            else
  {M}              begin
  {M}                raise Exception.Create('��� ������ ''' + 'GETORDERCLAUSE' + ' ''' +
  {M}                  ' ������ ' + Self.ClassName + TgdcBase(Self).SubType + #10#13 +
  {M}                  '�� ������� ��������� �� ��������� ���');
  {M}              end;
  {M}            exit;
  {M}          end;
  {M}      end else
  {M}        if tmpStrings.LastClass.gdClassName <> 'TGDCINVDOCUMENT' then
  {M}        begin
  {M}          Result := Inherited GetOrderClause;
  {M}          Exit;
  {M}        end;
  {M}    end;
  {END MACRO}
  Result := '';
  {@UNFOLD MACRO INH_ORIG_FINALLY('TGDCINVDOCUMENT', 'GETORDERCLAUSE', KEYGETORDERCLAUSE)}
  {M}  finally
  {M}    if (not FDataTransfer) and Assigned(gdcBaseMethodControl) then
  {M}      ClearMacrosStack2('TGDCINVDOCUMENT', 'GETORDERCLAUSE', KEYGETORDERCLAUSE);
  {M}  end;
  {END MACRO}
end;

function TgdcInvDocument.GetSelectClause: String;
var
  {@UNFOLD MACRO INH_ORIG_PARAMS()}
  {M}
  {M}  Params, LResult: Variant;
  {M}  tmpStrings: TStackStrings;
  {END MACRO}
  Relations: TgdcInvRelationAliases;
  CE: TgdClassEntry;
begin
  {@UNFOLD MACRO INH_ORIG_GETSELECTCLAUSE('TGDCINVDOCUMENT', 'GETSELECTCLAUSE', KEYGETSELECTCLAUSE)}
  {M}  try
  {M}    if (not FDataTransfer) and Assigned(gdcBaseMethodControl) then
  {M}    begin
  {M}      SetFirstMethodAssoc('TGDCINVDOCUMENT', KEYGETSELECTCLAUSE);
  {M}      tmpStrings := TStackStrings(ClassMethodAssoc.IntByKey[KEYGETSELECTCLAUSE]);
  {M}      if (tmpStrings = nil) or (tmpStrings.IndexOf('TGDCINVDOCUMENT') = -1) then
  {M}      begin
  {M}        Params := VarArrayOf([GetGdcInterface(Self)]);
  {M}        if gdcBaseMethodControl.ExecuteMethodNew(ClassMethodAssoc, Self, 'TGDCINVDOCUMENT',
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
  {M}        if tmpStrings.LastClass.gdClassName <> 'TGDCINVDOCUMENT' then
  {M}        begin
  {M}          Result := Inherited GetSelectClause;
  {M}          Exit;
  {M}        end;
  {M}    end;
  {END MACRO}
  
  if (csDesigning in ComponentState) or (FDocumentTypeKey = -1) then
  begin
    Result := inherited GetSelectClause;
    Exit;
  end;

  if SubType > '' then
  begin
    CE := gdClassList.Get(TgdDocumentEntry, Self.ClassName, Self.SubType).GetRootSubType;
    SetLength(Relations, 1);
    Relations[0].RelationName := TgdDocumentEntry(CE).DistinctRelation;
    Relations[0].AliasName := 'INVDOC';

    Result := Format(
      inherited GetSelectClause +
      ', %s ',
      [EnumRelationFields('INVDOC', '')]
    );
  end;
  
  {@UNFOLD MACRO INH_ORIG_FINALLY('TGDCINVDOCUMENT', 'GETSELECTCLAUSE', KEYGETSELECTCLAUSE)}
  {M}  finally
  {M}    if (not FDataTransfer) and Assigned(gdcBaseMethodControl) then
  {M}      ClearMacrosStack2('TGDCINVDOCUMENT', 'GETSELECTCLAUSE', KEYGETSELECTCLAUSE);
  {M}  end;
  {END MACRO}
end;

procedure TgdcInvDocument.SetJoins(const Value: TStringList);
begin
  if Value <> nil then
    FJoins.Assign(Value);
end;

//class function TgdcInvDocument.GetViewFormClassName(
//  const ASubType: TgdcSubType): String;
//begin
//  Result := 'Tgdc_frmInvDocument';
//end;

procedure TgdcInvDocument.GetWhereClauseConditions(S: TStrings);
var
  Str: String;
  i: Integer;
begin
  inherited;
  if HasSubSet('OnlySelected') then
  begin
    Str := '';
    for I := 0 to SelectedID.Count - 1 do
    begin
      if Length(Str) >= 8192 then break;
      Str := Str + IntToStr(SelectedID[I]) + ',';
    end;
    if Str = '' then
      Str := '-1'
    else
      SetLength(Str, Length(Str) - 1);
    S.Add(Format('%s.%s IN (%s)', ['INVDOC', 'documentkey', Str]));
  end;

end;

procedure TgdcInvDocument.InternalSetFieldData(Field: TField;
  Buffer: Pointer);
var
  DocumentLine: TgdcInvDocumentLine;
{$IFNDEF NEWDEPOT}
  dsMain: TDataSource;
  i: Integer;
  IsNullOld: Boolean;
  OldValue: String;
  
{$ENDIF}
  DidActivate: Boolean;

  function MakeMovementOnLine: boolean;
  var
    FLSavePoint: String;
  begin
    MakeMovementOnLine := True;
    if GetTID(DocumentLine.FieldByName('masterkey')) =  GetTID(FieldByName('id')) then
    begin
      FLSavePoint := '';
      if not Transaction.Active then
      begin
        DidActivate := True;
        Transaction.StartTransaction;
      end
      else
      begin
        FLSavePoint := 'S' + System.Copy(StringReplace(
          StringReplace(
            StringReplace(CreateClassID, '{', '', [rfReplaceAll]), '}', '', [rfReplaceAll]),
            '-', '', [rfReplaceAll]), 1, 30);
        try
          Transaction.SetSavePoint(FLSavePoint);
        except
          FLSavePoint := '';
        end;

      end;

      try

        try
          DocumentLine.Movement.gdcDocumentLine := DocumentLine;
          DocumentLine.Movement.Database := DocumentLine.Database;
          DocumentLine.Movement.ReadTransaction := DocumentLine.Transaction;
          DocumentLine.Movement.Transaction := DocumentLine.Transaction;
          DocumentLine.Movement.CreateAllMovement(ipsmPosition);
          
        except

          on E: Exception do
          begin
            if (DocumentLine.Movement.CountPositionChanged >= 0) and (not (sLoadFromStream in DocumentLine.BaseState) and not (sLoadFromStream in BaseState) ) then
            begin

              MakeMovementOnLine := False;

              MessageBox(ParentHandle,
                PChar(E.Message),
                PChar(sAttention),
                MB_OK or MB_ICONINFORMATION or MB_TASKMODAL);

              if DidActivate then
                Transaction.Rollback
              else
              begin
                Transaction.RollBackToSavePoint(FLSavePoint);
                Transaction.ReleaseSavePoint(FLSavePoint);
                FLSavePoint := '';
                if sDialog in BaseState then
                  Field.FocusControl;
              end;
              if not DidActivate and not Transaction.InTransaction  then
                Transaction.StartTransaction;
//              abort;
            end
            else begin
              raise;
            end;
          end;
        end;
      finally
        if FLSavePoint <> '' then
          Transaction.ReleaseSavePoint(FLSavePoint);
        if Transaction.InTransaction and DidActivate then
          Transaction.Commit;
      end;
    end;
  end;

begin

{$IFNDEF NEWDEPOT}

  if Field.IsNull then
  begin
    OldValue := '';
    IsNullOld := True;
  end
  else
  begin
    OldValue := Field.AsString;
    IsNullOld := False;
  end;
{$ENDIF}

  inherited;

  if FIsLocalChange or FDataTransfer then
    exit;

{$IFNDEF NEWDEPOT}

  if (UpperCase(Field.FieldName) = 'DELAYED')
       or (UpperCase(Field.FieldName) = 'DOCUMENTDATE')
       or
     (
     (UpperCase(Field.FieldName) = MovementSource.SourceFieldName) AND
     (ANSICompareText(MovementSource.RelationName, RelationName) = 0)
     ) or
     (
     (UpperCase(Field.FieldName) = MovementTarget.SourceFieldName) AND
     (ANSICompareText(MovementTarget.RelationName, RelationName) = 0)
     )
  then
  begin
    if (Field.Dataset.State = dsInsert) or (Field.Dataset.State = dsEdit)
    then
    begin
      if UpperCase(Field.FieldName) = 'DOCUMENTDATE' then
      begin
        if FieldByName('documentdate').IsNull  and
           (not (sLoadFromStream in BaseState)) then
        begin
          MessageBox(ParentHandle,
            PChar(sSetDocumentDate),
            PChar(sAttention),
            mb_Ok or mb_IconInformation or MB_TASKMODAL);
          FieldByName('documentdate').FocusControl;
          abort;
        end
        else
        begin
          if FieldByName('documentdate').IsNull then
            exit;
        end;
      end;

      DidActivate := False;
      try
        if DetailLinksCount > 0 then
        begin
          for i:= 0 to DetailLinksCount - 1 do
            if DetailLinks[i] is TgdcInvDocumentLine then
            begin
              DocumentLine := DetailLinks[i] as TgdcInvDocumentLine;
              if DocumentLine.Active then
                if not MakeMovementOnLine then
                begin
                  FIsLocalChange := True;
                  if not isNullOld then
                    Field.AsString := OldValue
                  else
                    Field.Clear;
                end;
            end;
        end
        else
        begin
          DidActivate := ActivateTransaction;
          dsMain := TDataSource.Create(Owner);
          DocumentLine := GetDetailObject as TgdcInvDocumentLine;
          try
            dsMain.DataSet := Self;
            DocumentLine.SubSet := 'ByParent';
            DocumentLine.MasterField := 'id';
            DocumentLine.DetailField := 'parent';
            DocumentLine.MasterSource := dsMain;
            DocumentLine.Open;
            if not MakeMovementOnLine then
            begin
              FIsLocalChange := True;
              if not isNullOld then
                Field.AsString := OldValue
              else
                Field.Clear;
            end;
          finally
            DocumentLine.Free;
            dsMain.Free;
          end;
        end;
      finally
        if DidActivate and Transaction.InTransaction then
          Transaction.Commit;
        FIsLocalChange := False;  
      end;
    end;
  end;

{$ENDIF}  
end;

function TgdcInvDocument.GetDetailObject: TgdcDocument;
begin
  Result := TgdcInvDocumentLine.CreateSubType(Owner, SubType);
  if sLoadFromStream in BaseState then
    Result.BaseState := Result.BaseState + [sLoadFromStream];
end;

class function TgdcInvDocument.GetDialogFormClassName(
  const ASubType: TgdcSubType): String;
begin
  Result := 'TdlgInvDocument';
end;

{ TgdcInvDocumentLine }

function TgdcInvDocumentLine.ChooseRemains: Boolean;
var
  FLocalSavePoint: String;
  F: TComponent;
begin
  F := Self.FindComponent('gdc_frmInvSelectRemains' + Self.SubType);
  if Assigned(F) then
  begin
    (F as TForm).BringToFront;
    Result := True;
    exit;
  end;
  SaveHeader;
  if Transaction.InTransaction then
  begin
    FLocalSavePoint := 'S' + System.Copy(StringReplace(
      StringReplace(
        StringReplace(CreateClassID, '{', '', [rfReplaceAll]), '}', '', [rfReplaceAll]),
        '-', '', [rfReplaceAll]), 1, 30);
    try
      Transaction.SetSavePoint(FLocalSavePoint);
    except
      FLocalSavePoint := '';
    end;
  end else
    FLocalSavePoint := '';

  try
    FMovement.gdcDocumentLine := Self;
    FMovement.Database := Database;
    if Transaction.InTransaction then
      FMovement.ReadTransaction := Transaction
    else
      FMovement.ReadTransaction := ReadTransaction;
    FMovement.Transaction := Transaction;
    Result := FMovement.ChooseRemains;

    if not Result then
    begin
      if FLocalSavePoint > '' then
      begin
        try
          if Transaction.InTransaction then
          begin
            Transaction.RollBackToSavePoint(FLocalSavePoint);
            Transaction.ReleaseSavePoint(FLocalSavePoint);
            FLocalSavePoint := '';
          end;
          Close;
          Open;
        except
          FLocalSavePoint := '';
        end;
      end;
    end
  finally
    if FLocalSavePoint > '' then
    begin
      try
        if Transaction.InTransaction then
          Transaction.ReleaseSavePoint(FLocalSavePoint);
        FLocalSavePoint := '';
      except
        FLocalSavePoint := '';
      end;
    end;
  end;
end;

constructor TgdcInvDocumentLine.Create(AnOwner: TComponent);
begin
  inherited;

  FisSetFeaturesFromRemains := False;
  FisChooseRemains := False;
  FisErrorUpdate := False;
  FisErrorInsert := False;

  FUseGoodKeyForMakeMovement := False;
  FIsMakeMovementOnFromCardKeyOnly := False;

  FisCheckDestFeatures := True;

  CustomProcess := [cpInsert, cpModify, cpDelete];

  FLineJoins := TStringList.Create;
  if not (csDesigning in ComponentState) then
    FMovement := TgdcInvMovement.CreateSubType(Self, SubType);

  SetLength(FSourceFeatures, 0);
  SetLength(FDestFeatures, 0);
  SetLength(FMinusFeatures, 0);  

  FSources := [];
  FDirection := imdFIFO;

  FGoodSQL := nil;
  FControlRemains := False;
  FIsMinusRemains := False;

  FViewMovementPart := impAll;

  FLiveTimeRemains := False;
  FEndMonthRemains := False;
  FWithoutSearchRemains := False;
  FUseCachedUpdates := False;
  FCanBeDelayed := False;
end;

procedure TgdcInvDocumentLine.CreateFields;
var
  {@UNFOLD MACRO INH_ORIG_PARAMS()}
  {M}
  {M}  Params, LResult: Variant;
  {M}  tmpStrings: TStackStrings;
  {END MACRO}
  F: TField;
begin
  {@UNFOLD MACRO INH_ORIG_WITHOUTPARAM('TGDCINVDOCUMENTLINE', 'CREATEFIELDS', KEYCREATEFIELDS)}
  {M}  try
  {M}    if (not FDataTransfer) and Assigned(gdcBaseMethodControl) then
  {M}    begin
  {M}      SetFirstMethodAssoc('TGDCINVDOCUMENTLINE', KEYCREATEFIELDS);
  {M}      tmpStrings := TStackStrings(ClassMethodAssoc.IntByKey[KEYCREATEFIELDS]);
  {M}      if (tmpStrings = nil) or (tmpStrings.IndexOf('TGDCINVDOCUMENTLINE') = -1) then
  {M}      begin
  {M}        Params := VarArrayOf([GetGdcInterface(Self)]);
  {M}        if gdcBaseMethodControl.ExecuteMethodNew(ClassMethodAssoc, Self, 'TGDCINVDOCUMENTLINE',
  {M}          'CREATEFIELDS', KEYCREATEFIELDS, Params, LResult) then exit;
  {M}      end else
  {M}        if tmpStrings.LastClass.gdClassName <> 'TGDCINVDOCUMENTLINE' then
  {M}        begin
  {M}          Inherited;
  {M}          Exit;
  {M}        end;
  {M}    end;
  {END MACRO}
  inherited;

  if (csDesigning in ComponentState) or (FDocumentTypeKey = -1) then
    Exit;

  FieldByName('GOODNAME').Required := False;
  FieldByName('GOODALIAS').Required := False;

  if FindField('REMAINS') <> nil then
    FieldByName('REMAINS').ReadOnly := True;

  if RelationType in [irtTransformation, irtInventorization] then
  begin
    F := TFloatField.Create(Self);
    F.Calculated := True;
    F.FieldName := 'QUANTITY';
    F.DataSet := Self;
  end;
  {@UNFOLD MACRO INH_ORIG_FINALLY('TGDCINVDOCUMENTLINE', 'CREATEFIELDS', KEYCREATEFIELDS)}
  {M}  finally
  {M}    if (not FDataTransfer) and Assigned(gdcBaseMethodControl) then
  {M}      ClearMacrosStack2('TGDCINVDOCUMENTLINE', 'CREATEFIELDS', KEYCREATEFIELDS);
  {M}  end;
  {END MACRO}
end;

procedure TgdcInvDocumentLine.CustomDelete(Buff: Pointer);
  {@UNFOLD MACRO INH_ORIG_PARAMS(VAR)}
  {M}VAR
  {M}  Params, LResult: Variant;
  {M}  tmpStrings: TStackStrings;
  {END MACRO}
  S: String;
  CE: TgdClassEntry;
begin
  {@UNFOLD MACRO INH_ORIG_CUSTOMINSERT('TGDCINVDOCUMENTLINE', 'CUSTOMDELETE', KEYCUSTOMDELETE)}
  {M}  try
  {M}    if (not FDataTransfer) and Assigned(gdcBaseMethodControl) then
  {M}    begin
  {M}      SetFirstMethodAssoc('TGDCINVDOCUMENTLINE', KEYCUSTOMDELETE);
  {M}      tmpStrings := TStackStrings(ClassMethodAssoc.IntByKey[KEYCUSTOMDELETE]);
  {M}      if (tmpStrings = nil) or (tmpStrings.IndexOf('TGDCINVDOCUMENTLINE') = -1) then
  {M}      begin
  {M}        Params := VarArrayOf([GetGdcInterface(Self), Integer(Buff)]);
  {M}        if gdcBaseMethodControl.ExecuteMethodNew(ClassMethodAssoc, Self, 'TGDCINVDOCUMENTLINE',
  {M}          'CUSTOMDELETE', KEYCUSTOMDELETE, Params, LResult) then
  {M}          exit;
  {M}      end else
  {M}        if tmpStrings.LastClass.gdClassName <> 'TGDCINVDOCUMENTLINE' then
  {M}        begin
  {M}          Inherited;
  {M}          Exit;
  {M}        end;
  {M}    end;
  {END MACRO}
  
  try
    try
      FSavePoint := '';

      if Transaction.InTransaction then
      begin
        FSavepoint := 'S' + System.Copy(StringReplace(
          StringReplace(
            StringReplace(CreateClassID, '{', '', [rfReplaceAll]), '}', '', [rfReplaceAll]),
            '-', '', [rfReplaceAll]), 1, 30);
        try
          Transaction.SetSavePoint(FSavepoint);
          //ExecSingleQuery('SAVEPOINT ' + FSavepoint);
        except
          FSavepoint := '';
        end;
      end;

      try
        CE := gdClassList.Get(TgdDocumentEntry, Self.ClassName, Self.SubType).GetRootSubType;
        CustomExecQuery(
          Format(
            'DELETE FROM %s WHERE documentkey = :old_documentkey',
            [TgdDocumentEntry(CE).DistinctRelation]),
          Buff
        );
      except
        on E: EIBError do
        begin
          if E.IBErrorCode = isc_except then
          begin
            S := String(PChar(StatusVectorArray[7]));
            if (S = 'GD_E_BLOCK') then
            begin
              MessageBox(ParentHandle,
                '������ ������������ ��� ���������.'#13#10 +
                '�� ������ ������ ������������� ������ � �� ������ �� ��������.'#13#10 +
                '�������� ���������� ����� � ���� �����, ���� ������.',
                '������ ������������',
                MB_OK or MB_ICONEXCLAMATION);
              abort;
            end
            else if (Pos('USR', S) > 0) then
              //���������������� ����������
              raise
            else
            begin
              with Tgdc_dlgViewMovement.Create(ParentForm) do
                try
                  DocumentKey := GetTID(FieldByName('documentkey'));
                  if CompareText(FMovementTarget.RelationName, RelationLineName) = 0 then
                    ContactKey := GetTID(FieldByName(FMovementTarget.SourceFieldName))
                  else
                    ContactKey := GetTID(MasterSource.DataSet.FieldByName(FMovementTarget.SourceFieldName));
                  GoodName := FieldByName('goodname').AsString;
                  Transaction := Self.ReadTransaction;
                  ShowModal;
                finally
                  Free;
                end;
              abort;
            end
          end else
            raise;
        end;

      end;

      inherited;
    except
      if FSavePoint > '' then
      begin
        try
          if Transaction.InTransaction then
          begin
            Transaction.RollBackToSavePoint(FSavepoint);
            Transaction.ReleaseSavePoint(FSavepoint);
            //ExecSingleQuery('ROLLBACK TO ' + FSavepoint);
            //ExecSingleQuery('RELEASE SAVEPOINT ' + FSavepoint);
          end;
          FSavepoint := '';
        except
          FSavepoint := '';
        end;
      end;
      raise;
    end;
  finally
    if FSavePoint > '' then
      Transaction.ReleaseSavePoint(FSavepoint);
      //ExecSingleQuery('RELEASE SAVEPOINT ' + FSavepoint);
  end;
  {@UNFOLD MACRO INH_ORIG_FINALLY('TGDCINVDOCUMENTLINE', 'CUSTOMDELETE', KEYCUSTOMDELETE)}
  {M}  finally
  {M}    if (not FDataTransfer) and Assigned(gdcBaseMethodControl) then
  {M}      ClearMacrosStack2('TGDCINVDOCUMENTLINE', 'CUSTOMDELETE', KEYCUSTOMDELETE);
  {M}  end;
  {END MACRO}
end;

procedure TgdcInvDocumentLine.CustomInsert(Buff: Pointer);
var
  {@UNFOLD MACRO INH_ORIG_PARAMS()}
  {M}
  {M}  Params, LResult: Variant;
  {M}  tmpStrings: TStackStrings;
  {END MACRO}
  DataSet: TgdcBase;
  ADataSource: TDataSource;
  isCreate: Boolean;
{$IFDEF DEBUGMOVE}
  TimeTmp: LongWord;
{$ENDIF}
  CE: TgdClassEntry;
begin
  {@UNFOLD MACRO INH_ORIG_CUSTOMINSERT('TGDCINVDOCUMENTLINE', 'CUSTOMINSERT', KEYCUSTOMINSERT)}
  {M}  try
  {M}    if (not FDataTransfer) and Assigned(gdcBaseMethodControl) then
  {M}    begin
  {M}      SetFirstMethodAssoc('TGDCINVDOCUMENTLINE', KEYCUSTOMINSERT);
  {M}      tmpStrings := TStackStrings(ClassMethodAssoc.IntByKey[KEYCUSTOMINSERT]);
  {M}      if (tmpStrings = nil) or (tmpStrings.IndexOf('TGDCINVDOCUMENTLINE') = -1) then
  {M}      begin
  {M}        Params := VarArrayOf([GetGdcInterface(Self), Integer(Buff)]);
  {M}        if gdcBaseMethodControl.ExecuteMethodNew(ClassMethodAssoc, Self, 'TGDCINVDOCUMENTLINE',
  {M}          'CUSTOMINSERT', KEYCUSTOMINSERT, Params, LResult) then
  {M}          exit;
  {M}      end else
  {M}        if tmpStrings.LastClass.gdClassName <> 'TGDCINVDOCUMENTLINE' then
  {M}        begin
  {M}          Inherited;
  {M}          Exit;
  {M}        end;
  {M}    end;
  {END MACRO}
  {$IFDEF DEBUGMOVE}
  TimeTmp := GetTickCount;
  TimePostInPosition := GetTickCount;
  TimeMakeMovement := 0;
  {$ENDIF}
  FSavePoint := '';
  DataSet := nil;
  aDataSource := nil;
  isCreate := False;

  if Transaction.InTransaction then
  begin
(*    FSavepoint := 'S' + System.Copy(StringReplace(
      StringReplace(
        StringReplace(CreateClassID, '{', '', [rfReplaceAll]), '}', '', [rfReplaceAll]),
        '-', '', [rfReplaceAll]), 1, 30);
    try
      ExecSingleQuery('SAVEPOINT ' + FSavepoint);
    except
      FSavepoint := '';
    end;*)
    FSavepoint := '';
  end;

  try

    inherited;

    if GetTID(FieldByName('id')) <> GetTID(FieldByName('documentkey')) then
      SetTID(FieldByName('documentkey'), GetTID(FieldByName('id')));
    {$IFDEF DEBUGMOVE}
    TimeCustomInsertDoc := GetTickCount - TimeTmp;
    {$ENDIF}

    try

      FMovement.gdcDocumentLine := Self;
      FMovement.Database := Database;
      FMovement.Transaction := Transaction;
      FMovement.ReadTransaction := Transaction;
      if Assigned(MasterSource) and Assigned(MasterSource.DataSet) then
        DataSet := MasterSource.DataSet as TgdcBase
      else
        DataSet := nil;


      {$IFNDEF NEWDEPOT}
      //��� ������������ �� ������ ������� ����������� ������ ���� ������!!!
      if (sLoadFromStream in BaseState) and (not Assigned(DataSet)) then
      begin
        ADataSource := TDataSource.Create(Self);
        DataSet := TgdcInvDocument.CreateWithID(Self, Database, Transaction,
          GetTID(FieldByName('parent')), SubType);
        DataSet.ReadTransaction := ReadTransaction;
        DataSet.Open;
        ADataSource.DataSet := DataSet;
        Self.MasterSource := ADataSource;
        isCreate := True;
      end;

      if FControlRemains then
        ExecSingleQuery('select rdb$set_context(''USER_TRANSACTION'', ''CONTROLREMAINS'', 1) from rdb$database')
      else
        ExecSingleQuery('select rdb$set_context(''USER_TRANSACTION'', ''CONTROLREMAINS'', 0) from rdb$database');

      if Assigned(DataSet) and (sDialog in DataSet.BaseState) and not CachedUpdates
      then
        FMovement.CreateMovement(ipsmPosition)
      else
        FMovement.CreateMovement(ipsmDocument);
      {$ELSE}
        NewCreateMovement;
      {$ENDIF}

      {$IFDEF DEBUGMOVE}
      TimeTmp := GetTickCount;
      {$ENDIF}
      CE := gdClassList.Get(TgdDocumentEntry, Self.ClassName, Self.SubType).GetRootSubType;
      CustomExecQuery(
        Format(
          'INSERT INTO %s ' +
          '  (%s, disabled) ' +
          'VALUES ' +
          '  (%s, %d) ',
          [TgdDocumentEntry(CE).DistinctRelation,
            EnumRelationFields('', 'DISABLED;', False), EnumRelationFields(':', 'DISABLED;', False),
            FieldByName('linedisabled').AsInteger]
        ),
        Buff
      );
      {$IFDEF DEBUGMOVE}
      TimeCustomInsertUSR := GetTickCount - TimeTmp;
      {$ENDIF}
    except
{      if FSavePoint > '' then
      begin
        try
          if Transaction.InTransaction then
          begin
            ExecSingleQuery('ROLLBACK TO ' + FSavepoint);
            ExecSingleQuery('RELEASE SAVEPOINT ' + FSavepoint);
          end;
          FSavepoint := '';
        except
          FSavepoint := '';
        end;
      end
      else
      begin
        FisErrorInsert := True;
        try
          inherited CustomDelete(Buff);
        finally
          FisErrorInsert := False;
        end;
      end;}
      raise;
    end;
  finally
    if isCreate then
    begin
      Self.MasterSource := nil;
      aDataSource.Free;
      DataSet.Free;
    end;
    if FSavePoint > '' then
    begin
      try
        if Transaction.InTransaction then
          Transaction.ReleaseSavePoint(FSavepoint);
          //ExecSingleQuery('RELEASE SAVEPOINT ' + FSavepoint);
        FSavepoint := '';
      except
        FSavepoint := '';
      end;
    end;
  end;

{$IFDEF DEBUGMOVE}
  if not IsChooseRemains then
  begin
    TimePostInPosition := GetTickCount - TimePostInPosition;
    ShowMessage('����� ���������� ' + IntToStr(TimePostInPosition) +
    ' ����� �������� ' + IntToStr(TimeGetRemains) +
    ' ������������ �������� ' + IntToStr(TimeMakeMovement));
  end;
{$ENDIF}

  {@UNFOLD MACRO INH_ORIG_FINALLY('TGDCINVDOCUMENTLINE', 'CUSTOMINSERT', KEYCUSTOMINSERT)}
  {M}  finally
  {M}    if (not FDataTransfer) and Assigned(gdcBaseMethodControl) then
  {M}      ClearMacrosStack2('TGDCINVDOCUMENTLINE', 'CUSTOMINSERT', KEYCUSTOMINSERT);
  {M}  end;
  {END MACRO}
end;

procedure TgdcInvDocumentLine.CustomModify(Buff: Pointer);
var
  {@UNFOLD MACRO INH_ORIG_PARAMS()}
  {M}
  {M}  Params, LResult: Variant;
  {M}  tmpStrings: TStackStrings;
  {END MACRO}
  DataSet: TgdcBase;
  ADataSource: TDataSource;
  isCreate: Boolean;
  CE: TgdClassEntry;
begin
  {@UNFOLD MACRO INH_ORIG_CUSTOMINSERT('TGDCINVDOCUMENTLINE', 'CUSTOMMODIFY', KEYCUSTOMMODIFY)}
  {M}  try
  {M}    if (not FDataTransfer) and Assigned(gdcBaseMethodControl) then
  {M}    begin
  {M}      SetFirstMethodAssoc('TGDCINVDOCUMENTLINE', KEYCUSTOMMODIFY);
  {M}      tmpStrings := TStackStrings(ClassMethodAssoc.IntByKey[KEYCUSTOMMODIFY]);
  {M}      if (tmpStrings = nil) or (tmpStrings.IndexOf('TGDCINVDOCUMENTLINE') = -1) then
  {M}      begin
  {M}        Params := VarArrayOf([GetGdcInterface(Self), Integer(Buff)]);
  {M}        if gdcBaseMethodControl.ExecuteMethodNew(ClassMethodAssoc, Self, 'TGDCINVDOCUMENTLINE',
  {M}          'CUSTOMMODIFY', KEYCUSTOMMODIFY, Params, LResult) then
  {M}          exit;
  {M}      end else
  {M}        if tmpStrings.LastClass.gdClassName <> 'TGDCINVDOCUMENTLINE' then
  {M}        begin
  {M}          Inherited;
  {M}          Exit;
  {M}        end;
  {M}    end;
  {END MACRO}
  inherited;
  FSavePoint := '';

  if Transaction.InTransaction then
  begin
    FSavepoint := 'S' + System.Copy(StringReplace(
      StringReplace(
        StringReplace(CreateClassID, '{', '', [rfReplaceAll]), '}', '', [rfReplaceAll]),
        '-', '', [rfReplaceAll]), 1, 30);
    try
      Transaction.SetSavePoint(FSavepoint);
      //ExecSingleQuery('SAVEPOINT ' + FSavepoint);
    except
      FSavepoint := '';
    end;
  end;

  ADataSource := nil;

  if Assigned(MasterSource) and Assigned(MasterSource.DataSet) then
    DataSet := MasterSource.DataSet as TgdcBase
  else
    DataSet := nil;
  isCreate := False;

  try
    try

      FMovement.gdcDocumentLine := Self;
      FMovement.Database := Database;
      FMovement.ReadTransaction := Transaction;
      FMovement.Transaction := Transaction;

      //��� ������������ �� ������ ������� ����������� ������ ���� ������!!!
      if {(sLoadFromStream in BaseState) and }(not Assigned(DataSet)) then
      begin
        ADataSource := TDataSource.Create(Self);
        DataSet := TgdcInvDocument.CreateWithID(Self, Database, Transaction,
          GetTID(FieldByName('parent')), SubType);
        DataSet.ReadTransaction := ReadTransaction;
        DataSet.Open;
        ADataSource.DataSet := DataSet;
        Self.MasterSource := ADataSource;
        isCreate := True;
      end;

      {$IFNDEF NEWDEPOT}
      if FControlRemains then
        ExecSingleQuery('select rdb$set_context(''USER_TRANSACTION'', ''CONTROLREMAINS'', 1) from rdb$database')
      else
        ExecSingleQuery('select rdb$set_context(''USER_TRANSACTION'', ''CONTROLREMAINS'', 0) from rdb$database');

      if Assigned(DataSet) and (sDialog in DataSet.BaseState) and not CachedUpdates
      then
        FMovement.CreateMovement(ipsmPosition)
      else
        FMovement.CreateMovement(ipsmDocument);
      {$ELSE}
      NewCreateMovement;
      {$ENDIF}
       CE := gdClassList.Get(TgdDocumentEntry, Self.ClassName, Self.SubType).GetRootSubType;
       CustomExecQuery(
        Format(
          'UPDATE %s ' +
          'SET ' +
          '  %s, disabled = %d ' +
          'WHERE ' +
          '  (documentkey = :new_documentkey) ',
          [TgdDocumentEntry(CE).DistinctRelation, EnumModificationList('DISABLED;'), FieldByName('linedisabled').AsInteger]
        ),
        Buff
      );

    except
      FisErrorUpdate := True;

      if FSavePoint > '' then
      begin
        try
          if Transaction.InTransaction then
          begin
            Transaction.RollBackToSavePoint(FSavepoint);
            Transaction.ReleaseSavePoint(FSavepoint);
            //ExecSingleQuery('ROLLBACK TO ' + FSavepoint);
            //ExecSingleQuery('RELEASE SAVEPOINT ' + FSavepoint);
          end;
          FSavepoint := '';
          FisErrorUpdate := False;
        except
          FSavepoint := '';
        end;
      end;

      raise;
    end;
  finally
    if isCreate then
    begin
      Self.MasterSource := nil;
      aDataSource.Free;
      DataSet.Free;
    end;

    if FSavePoint > '' then
    begin
      try
        if Transaction.InTransaction then
          Transaction.ReleaseSavePoint(FSavepoint);
          //ExecSingleQuery('RELEASE SAVEPOINT ' + FSavepoint);
        FSavepoint := '';
      except
        FSavepoint := '';
      end;
    end;
  end;
  {@UNFOLD MACRO INH_ORIG_FINALLY('TGDCINVDOCUMENTLINE', 'CUSTOMMODIFY', KEYCUSTOMMODIFY)}
  {M}  finally
  {M}    if (not FDataTransfer) and Assigned(gdcBaseMethodControl) then
  {M}      ClearMacrosStack2('TGDCINVDOCUMENTLINE', 'CUSTOMMODIFY', KEYCUSTOMMODIFY);
  {M}  end;
  {END MACRO}
end;

destructor TgdcInvDocumentLine.Destroy;
begin
  FreeAndNil(FLineJoins);

  if Assigned(FGoodSQL) then
    FreeAndNil(FGoodSQL);

  inherited;
end;

procedure TgdcInvDocumentLine.DoBeforePost;
VAR
  F: TField;
  {@UNFOLD MACRO INH_ORIG_PARAMS()}
  {M}
  {M}  Params, LResult: Variant;
  {M}  tmpStrings: TStackStrings;
  {END MACRO}
begin
  {@UNFOLD MACRO INH_ORIG_WITHOUTPARAM('TGDCINVDOCUMENTLINE', 'DOBEFOREPOST', KEYDOBEFOREPOST)}
  {M}  try
  {M}    if (not FDataTransfer) and Assigned(gdcBaseMethodControl) then
  {M}    begin
  {M}      SetFirstMethodAssoc('TGDCINVDOCUMENTLINE', KEYDOBEFOREPOST);
  {M}      tmpStrings := TStackStrings(ClassMethodAssoc.IntByKey[KEYDOBEFOREPOST]);
  {M}      if (tmpStrings = nil) or (tmpStrings.IndexOf('TGDCINVDOCUMENTLINE') = -1) then
  {M}      begin
  {M}        Params := VarArrayOf([GetGdcInterface(Self)]);
  {M}        if gdcBaseMethodControl.ExecuteMethodNew(ClassMethodAssoc, Self, 'TGDCINVDOCUMENTLINE',
  {M}          'DOBEFOREPOST', KEYDOBEFOREPOST, Params, LResult) then exit;
  {M}      end else
  {M}        if tmpStrings.LastClass.gdClassName <> 'TGDCINVDOCUMENTLINE' then
  {M}        begin
  {M}          Inherited;
  {M}          Exit;
  {M}        end;
  {M}    end;
  {END MACRO}

{$IFDEF DEBUGMOVE}
  TimePostInPosition := GetTickCount;
{$ENDIF}

  if sLoadFromStream in BaseState then
    isCheckDestFeatures := False;

  if FieldByName('GOODKEY').IsNull or (GetTID(FieldByName('GOODKEY')) = 0) then
  begin
    if not (sLoadFromStream in BaseState) then
      MessageBox(ParentHandle, PChar(s_InvChooseGood), PChar(sAttention),
        mb_Ok or mb_IconInformation or mb_SystemModal);
    abort;
  end;

  if (RelationType = irtTransformation) then
  begin
    F := FindField('INQUANTITY');
    if Assigned(F) and (FieldByName('INQUANTITY').AsCurrency > 0) then
      FieldByName('VIEWMOVEMENTPART').AsString := 'I'
    else
    begin
      F := FindField('OUTQUANTITY');
      if Assigned(F) and (FieldByName('OUTQUANTITY').AsCurrency > 0) then
        FieldByName('VIEWMOVEMENTPART').AsString := 'E';
    end;    
  end;

  inherited;

  if FControlRemains then
    FieldByName('checkremains').AsInteger := 1
  else
    FieldByName('checkremains').AsInteger := 0;
    
  if not (sMultiple in BaseState) then
  begin
    if
      ((irsRemainsRef in FSources) and
      (not (irsGoodRef in FSources) or (sLoadFromStream in BaseState))  and
      (RelationType <> irtTransformation))
        or
      ((RelationType = irtTransformation) and (FindField('OUTQUANTITY') <> nil) AND
      (FieldByName('OUTQUANTITY').AsCurrency > 0))
    then begin
      FMovement.gdcDocumentLine := Self;                                                                                          
      FMovement.Database := Database;
      if Transaction.InTransaction then
      begin
        FMovement.ReadTransaction := Transaction;
        FMovement.Transaction := Transaction;
      end
      else
        FMovement.ReadTransaction := ReadTransaction;
      FMovement.GetRemains;
    end;
  end;

{$IFDEF DEBUGMOVE}
  TimePostInPosition := GetTickCount - TimePostInPosition;
{$ENDIF}

  {@UNFOLD MACRO INH_ORIG_FINALLY('TGDCINVDOCUMENTLINE', 'DOBEFOREPOST', KEYDOBEFOREPOST)}
  {M}  finally
  {M}    if (not FDataTransfer) and Assigned(gdcBaseMethodControl) then
  {M}      ClearMacrosStack2('TGDCINVDOCUMENTLINE', 'DOBEFOREPOST', KEYDOBEFOREPOST);
  {M}  end;
  {END MACRO}
end;

procedure TgdcInvDocumentLine.DoOnCalcFields;
begin
  inherited;

  if (csDesigning in ComponentState) or (FDocumentTypeKey = -1) then
    Exit;

  case RelationType of
    irtTransformation:
    begin
      if ViewMovementPart = impIncome then
        FieldByName('QUANTITY').AsCurrency := FieldByName('INQUANTITY').AsCurrency
      else
        if ViewMovementPart = impExpense then
           FieldByName('QUANTITY').AsCurrency := - FieldByName('OUTQUANTITY').AsCurrency
         else
           FieldByName('QUANTITY').AsCurrency := FieldByName('INQUANTITY').AsCurrency
             - FieldByName('OUTQUANTITY').AsCurrency;
    end;
    irtInventorization:
    begin
      FieldByName('QUANTITY').AsCurrency :=
        FieldByName('TOQUANTITY').AsCurrency - FieldByName('FROMQUANTITY').AsCurrency;
    end;
  end;
end;

procedure TgdcInvDocumentLine._DoOnNewRecord;
var
  {@UNFOLD MACRO INH_ORIG_PARAMS()}
  {M}
  {M}  Params, LResult: Variant;
  {M}  tmpStrings: TStackStrings;
  {END MACRO}
{$IFDEF DEBUGMOVE}
  TempTime: LongWord;
{$ENDIF}
begin
  {@UNFOLD MACRO INH_ORIG_WITHOUTPARAM('TGDCINVDOCUMENTLINE', '_DOONNEWRECORD', KEY_DOONNEWRECORD)}
  {M}  try
  {M}    if (not FDataTransfer) and Assigned(gdcBaseMethodControl) then
  {M}    begin
  {M}      SetFirstMethodAssoc('TGDCINVDOCUMENTLINE', KEY_DOONNEWRECORD);
  {M}      tmpStrings := TStackStrings(ClassMethodAssoc.IntByKey[KEY_DOONNEWRECORD]);
  {M}      if (tmpStrings = nil) or (tmpStrings.IndexOf('TGDCINVDOCUMENTLINE') = -1) then
  {M}      begin
  {M}        Params := VarArrayOf([GetGdcInterface(Self)]);
  {M}        if gdcBaseMethodControl.ExecuteMethodNew(ClassMethodAssoc, Self, 'TGDCINVDOCUMENTLINE',
  {M}          '_DOONNEWRECORD', KEY_DOONNEWRECORD, Params, LResult) then exit;
  {M}      end else
  {M}        if tmpStrings.LastClass.gdClassName <> 'TGDCINVDOCUMENTLINE' then
  {M}        begin
  {M}          Inherited;
  {M}          Exit;
  {M}        end;
  {M}    end;
  {END MACRO}

  {$IFDEF DEBUGMOVE}
  TempTime := GetTickCount;
  {$ENDIF}

  inherited;

  SetTID(FieldByName('MASTERKEY'), GetTID(FieldByName('Parent')));
  SetTID(FieldByName('DOCUMENTKEY'), GetTID(FieldByName('ID')));

  case RelationType of
    irtFeatureChange:
    begin
      FieldByName('FROMCARDKEY').Required := False;
      FieldByName('TOCARDKEY').Required := False;
    end;
    irtSimple, irtInventorization:
    begin
      FieldByName('FROMCARDKEY').Required := False;
    end;
    irtTransformation:
    begin
      FieldByName('FROMCARDKEY').Required := False;

      if (ViewMovementPart = impIncome) then
      begin
        FieldByName('INQUANTITY').AsCurrency := 0;
        FieldByName('VIEWMOVEMENTPART').AsString := 'I';
      end
      else
      begin
        FieldByName('OUTQUANTITY').AsCurrency := 0;
        FieldByName('VIEWMOVEMENTPART').AsString := 'E';
    end;
  end;
  end;

  UpdatePredefinedFields;

  {$IFDEF DEBUGMOVE}
  TimeDoOnNewRecord := TimeDoOnNewRecord + GetTickCount - TempTime;
  {$ENDIF}

  {@UNFOLD MACRO INH_ORIG_FINALLY('TGDCINVDOCUMENTLINE', '_DOONNEWRECORD', KEY_DOONNEWRECORD)}
  {M}  finally
  {M}    if (not FDataTransfer) and Assigned(gdcBaseMethodControl) then
  {M}      ClearMacrosStack2('TGDCINVDOCUMENTLINE', '_DOONNEWRECORD', KEY_DOONNEWRECORD);
  {M}  end;
  {END MACRO}
end;

function TgdcInvDocumentLine.EnumCardFields(const Alias: String; Kind: TgdcInvFeatureKind;
  const AsName: String = ''): String;
var
  I: Integer;
  Relation: TatRelation;
  Features: TgdcInvFeatures;
begin
  Assert(atDatabase <> nil, 'Attributes database not assigned!');

  Relation := atDatabase.Relations.ByRelationName('INV_CARD');
  Assert(Relation <> nil, 'Relation not assigned!');

  Result := '';

  SetLength(Features, 0);

  if RelationType <> irtTransformation then
  begin
    if (Kind = ifkDest) and (Length(FDestFeatures) > 0) then
      Features := FDestFeatures
    else
      if (Kind = ifkSource) and (Length(FSourceFeatures) > 0) then
        Features := FSourceFeatures;
  end else begin
    if Kind = ifkDest then
       Features := FDestFeatures
    else
       Features := FSourceFeatures;
  end;

  if (Kind = ifkSource) or (RelationType = irtTransformation) then
    Result := Result + ', ' + Alias + '.GOODKEY';

  for I := 0 to Relation.RelationFields.Count - 1 do
  begin
    if not IsFeatureUsed(Relation.RelationFields[I].FieldName, Features) then Continue;

    Result := Result + ', ' + Alias + '.' +
      Relation.RelationFields[I].FieldName;

    if AsName > '' then
      Result := Result + ' AS ' + AsName + Relation.RelationFields[I].FieldName;
  end;
end;

class function TgdcInvDocumentLine.GetDocumentClassPart: TgdcDocumentClassPart;
begin
  Result := dcpLine;
end;

function TgdcInvDocumentLine.GetFromClause(const ARefresh: Boolean = False): String;
var
  {@UNFOLD MACRO INH_ORIG_PARAMS()}
  {M}
  {M}  Params, LResult: Variant;
  {M}  tmpStrings: TStackStrings;
  {END MACRO}
  Ignore: TatIgnore;
  Relations: TgdcInvRelationAliases;
  CE: TgdClassEntry;
begin
  {@UNFOLD MACRO INH_ORIG_GETFROMCLAUSE('TGDCINVDOCUMENTLINE', 'GETFROMCLAUSE', KEYGETFROMCLAUSE)}
  {M}  try
  {M}    if (not FDataTransfer) and Assigned(gdcBaseMethodControl) then
  {M}    begin
  {M}      SetFirstMethodAssoc('TGDCINVDOCUMENTLINE', KEYGETFROMCLAUSE);
  {M}      tmpStrings := TStackStrings(ClassMethodAssoc.IntByKey[KEYGETFROMCLAUSE]);
  {M}      if (tmpStrings = nil) or (tmpStrings.IndexOf('TGDCINVDOCUMENTLINE') = -1) then
  {M}      begin
  {M}        Params := VarArrayOf([GetGdcInterface(Self), ARefresh]);
  {M}        if gdcBaseMethodControl.ExecuteMethodNew(ClassMethodAssoc, Self, 'TGDCINVDOCUMENTLINE',
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
  {M}        if tmpStrings.LastClass.gdClassName <> 'TGDCINVDOCUMENTLINE' then
  {M}        begin
  {M}          Result := Inherited GetFromClause(ARefresh);
  {M}          Exit;
  {M}        end;
  {M}    end;
  {END MACRO}
  if (csDesigning in ComponentState) or (FDocumentTypeKey = -1) then
  begin
    Result := inherited GetFromClause(ARefresh);
    Exit;
  end;

  CE := gdClassList.Get(TgdDocumentEntry, Self.ClassName, Self.SubType).GetRootSubType;
  Result := Format(
    inherited GetFromClause(ARefresh) +
    '  LEFT JOIN %s INVLINE ON (Z.ID = INVLINE.DOCUMENTKEY) ' +

    '  LEFT JOIN INV_CARD CARD ON (CARD.ID = INVLINE.FROMCARDKEY) ' +

    '  LEFT JOIN GD_GOOD G ON (G.ID = CARD.GOODKEY) ' +
    '  LEFT JOIN GD_VALUE V ON (G.VALUEKEY = V.ID) ',
    [TgdDocumentEntry(CE).DistinctRelation]
  );

  FSQLSetup.Ignores.AddAliasName('CARD');

  SetLength(Relations, 1);
  Relations[0].RelationName := 'INV_CARD';
  Relations[0].AliasName := 'CARD';

  if RelationType = irtFeatureChange then
  begin
    Result := Result +
      '  LEFT JOIN INV_CARD TOCARD ON (TOCARD.ID = INVLINE.TOCARDKEY) ';

    Ignore := FSQLSetup.Ignores.Add;
    Ignore.AliasName := 'TOCARD';

    SetLength(Relations, 2);
    Relations[1].RelationName := 'INV_CARD';
    Relations[1].AliasName := 'TOCARD';
  end;

  Result := Result + ' ' + EnumRelationJoins(Relations);
  
  {@UNFOLD MACRO INH_ORIG_FINALLY('TGDCINVDOCUMENTLINE', 'GETFROMCLAUSE', KEYGETFROMCLAUSE)}
  {M}  finally
  {M}    if (not FDataTransfer) and Assigned(gdcBaseMethodControl) then
  {M}      ClearMacrosStack2('TGDCINVDOCUMENTLINE', 'GETFROMCLAUSE', KEYGETFROMCLAUSE);
  {M}  end;
  {END MACRO}
end;

function TgdcInvDocumentLine.GetGroupClause: String;
  {@UNFOLD MACRO INH_ORIG_PARAMS(VAR)}
  {M}VAR
  {M}  Params, LResult: Variant;
  {M}  tmpStrings: TStackStrings;
  {END MACRO}
begin
  {@UNFOLD MACRO INH_ORIG_GETGROUPCLAUSE('TGDCINVDOCUMENTLINE', 'GETGROUPCLAUSE', KEYGETGROUPCLAUSE)}
  {M}  try
  {M}    if (not FDataTransfer) and Assigned(gdcBaseMethodControl) then
  {M}    begin
  {M}      SetFirstMethodAssoc('TGDCINVDOCUMENTLINE', KEYGETGROUPCLAUSE);
  {M}      tmpStrings := TStackStrings(ClassMethodAssoc.IntByKey[KEYGETGROUPCLAUSE]);
  {M}      if (tmpStrings = nil) or (tmpStrings.IndexOf('TGDCINVDOCUMENTLINE') = -1) then
  {M}      begin
  {M}        Params := VarArrayOf([GetGdcInterface(Self)]);
  {M}        if gdcBaseMethodControl.ExecuteMethodNew(ClassMethodAssoc, Self, 'TGDCINVDOCUMENTLINE',
  {M}          'GETGROUPCLAUSE', KEYGETGROUPCLAUSE, Params, LResult) then
  {M}          begin
  {M}            if (VarType(LResult) = varOleStr) or (VarType(LResult) = varString) then
  {M}              Result := String(LResult)
  {M}            else
  {M}              begin
  {M}                raise Exception.Create('��� ������ ''' + 'GETGROUPCLAUSE' + ' ''' +
  {M}                  ' ������ ' + Self.ClassName + TgdcBase(Self).SubType + #10#13 +
  {M}                  '�� ������� ��������� �� ��������� ���');
  {M}              end;
  {M}            exit;
  {M}          end;
  {M}      end else
  {M}        if tmpStrings.LastClass.gdClassName <> 'TGDCINVDOCUMENTLINE' then
  {M}        begin
  {M}          Result := Inherited GetGroupClause;
  {M}          Exit;
  {M}        end;
  {M}    end;
  {END MACRO}
  Result := '';
  {@UNFOLD MACRO INH_ORIG_FINALLY('TGDCINVDOCUMENTLINE', 'GETGROUPCLAUSE', KEYGETGROUPCLAUSE)}
  {M}  finally
  {M}    if (not FDataTransfer) and Assigned(gdcBaseMethodControl) then
  {M}      ClearMacrosStack2('TGDCINVDOCUMENTLINE', 'GETGROUPCLAUSE', KEYGETGROUPCLAUSE);
  {M}  end;
  {END MACRO}
end;

function TgdcInvDocumentLine.GetJoins: TStringList;
begin
  Result := FLineJoins;
end;

function TgdcInvDocumentLine.GetOrderClause: String;
  {@UNFOLD MACRO INH_ORIG_PARAMS(VAR)}
  {M}VAR
  {M}  Params, LResult: Variant;
  {M}  tmpStrings: TStackStrings;
  {END MACRO}
begin
  {@UNFOLD MACRO INH_ORIG_GETORDERCLAUSE('TGDCINVDOCUMENTLINE', 'GETORDERCLAUSE', KEYGETORDERCLAUSE)}
  {M}  try
  {M}    if (not FDataTransfer) and Assigned(gdcBaseMethodControl) then
  {M}    begin
  {M}      SetFirstMethodAssoc('TGDCINVDOCUMENTLINE', KEYGETORDERCLAUSE);
  {M}      tmpStrings := TStackStrings(ClassMethodAssoc.IntByKey[KEYGETORDERCLAUSE]);
  {M}      if (tmpStrings = nil) or (tmpStrings.IndexOf('TGDCINVDOCUMENTLINE') = -1) then
  {M}      begin
  {M}        Params := VarArrayOf([GetGdcInterface(Self)]);
  {M}        if gdcBaseMethodControl.ExecuteMethodNew(ClassMethodAssoc, Self, 'TGDCINVDOCUMENTLINE',
  {M}          'GETORDERCLAUSE', KEYGETORDERCLAUSE, Params, LResult) then
  {M}          begin
  {M}            if (VarType(LResult) = varOleStr) or (VarType(LResult) = varString) then
  {M}              Result := String(LResult)
  {M}            else
  {M}              begin
  {M}                raise Exception.Create('��� ������ ''' + 'GETORDERCLAUSE' + ' ''' +
  {M}                  ' ������ ' + Self.ClassName + TgdcBase(Self).SubType + #10#13 +
  {M}                  '�� ������� ��������� �� ��������� ���');
  {M}              end;
  {M}            exit;
  {M}          end;
  {M}      end else
  {M}        if tmpStrings.LastClass.gdClassName <> 'TGDCINVDOCUMENTLINE' then
  {M}        begin
  {M}          Result := Inherited GetOrderClause;
  {M}          Exit;
  {M}        end;
  {M}    end;
  {END MACRO}
  Result := '';
  {@UNFOLD MACRO INH_ORIG_FINALLY('TGDCINVDOCUMENTLINE', 'GETORDERCLAUSE', KEYGETORDERCLAUSE)}
  {M}  finally
  {M}    if (not FDataTransfer) and Assigned(gdcBaseMethodControl) then
  {M}      ClearMacrosStack2('TGDCINVDOCUMENTLINE', 'GETORDERCLAUSE', KEYGETORDERCLAUSE);
  {M}  end;
  {END MACRO}
end;

function TgdcInvDocumentLine.GetSelectClause: String;
var
  {@UNFOLD MACRO INH_ORIG_PARAMS()}
  {M}
  {M}  Params, LResult: Variant;
  {M}  tmpStrings: TStackStrings;
  {END MACRO}
  SkipList, Prefix: String;
  Relations: TgdcInvRelationAliases;
  FeaturesText: String;
begin
  {@UNFOLD MACRO INH_ORIG_GETSELECTCLAUSE('TGDCINVDOCUMENTLINE', 'GETSELECTCLAUSE', KEYGETSELECTCLAUSE)}
  {M}  try
  {M}    if (not FDataTransfer) and Assigned(gdcBaseMethodControl) then
  {M}    begin
  {M}      SetFirstMethodAssoc('TGDCINVDOCUMENTLINE', KEYGETSELECTCLAUSE);
  {M}      tmpStrings := TStackStrings(ClassMethodAssoc.IntByKey[KEYGETSELECTCLAUSE]);
  {M}      if (tmpStrings = nil) or (tmpStrings.IndexOf('TGDCINVDOCUMENTLINE') = -1) then
  {M}      begin
  {M}        Params := VarArrayOf([GetGdcInterface(Self)]);
  {M}        if gdcBaseMethodControl.ExecuteMethodNew(ClassMethodAssoc, Self, 'TGDCINVDOCUMENTLINE',
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
  {M}        if tmpStrings.LastClass.gdClassName <> 'TGDCINVDOCUMENTLINE' then
  {M}        begin
  {M}          Result := Inherited GetSelectClause;
  {M}          Exit;
  {M}        end;
  {M}    end;
  {END MACRO}

  if (csDesigning in ComponentState) or (FDocumentTypeKey = -1) then
  begin
    Result := inherited GetSelectClause;
    Exit;
  end;

  if (RelationType = irtTransformation) then
  begin
    if (ViewMovementPart = impIncome) then
      SkipList := 'OUTQUANTITY;'
    else
      if ViewMovementPart = impExpense then
        SkipList := 'INQUANTITY;';
  end else begin
    SkipList := '';
  end;

  if RelationType = irtTransformation then
  begin
    if ViewMovementPart in [impIncome, impAll] then
      Prefix := INV_DESTFEATURE_PREFIX
    else
      Prefix := INV_SOURCEFEATURE_PREFIX;
  end else

  if (Length(SourceFeatures) > 0) or (RelationType = irtFeatureChange) then
    Prefix := INV_SOURCEFEATURE_PREFIX else

  if (Length(DestFeatures) > 0) then
    Prefix := INV_DESTFEATURE_PREFIX;

  SetLength(Relations, 1);
  Relations[0].RelationName := 'INV_CARD';
  Relations[0].AliasName := 'CARD';

  if RelationType = irtFeatureChange then
  begin
    SetLength(Relations, 2);
    Relations[1].RelationName := 'INV_CARD';
    Relations[1].AliasName := 'TOCARD';
  end;

  if RelationType = irtTransformation then
  begin
    if FViewMovementPart = impIncome then
      FeaturesText := EnumCardFields('CARD', ifkDest, Prefix) else
    if FViewMovementPart = impExpense then
      FeaturesText := EnumCardFields('CARD', ifkSource, Prefix)
    else
      FeaturesText := EnumCardFields('CARD', ifkDest, INV_DESTFEATURE_PREFIX) +
        EnumCardFields('CARD', ifkSource, INV_SOURCEFEATURE_PREFIX);
  end else
    FeaturesText := EnumCardFields('CARD', ifkSource, Prefix);

  Result := Format(
    inherited GetSelectClause +
    ', G.NAME AS GOODNAME, G.ALIAS AS GOODALIAS, G.VALUEKEY, G.GROUPKEY, V.NAME, INVLINE.disabled AS LINEDISABLED ' +
    '%s%s%s',
    [
      EnumRelationFields('INVLINE', SkipList),
      EnumJoinedListFields(Relations),
      FeaturesText
    ]
  );

  if (RelationType = irtFeatureChange) or (Length(FDestFeatures) > 0) then
  begin
    if (RelationType = irtFeatureChange) then
      Result := Result + EnumCardFields('TOCARD', ifkDest, INV_DESTFEATURE_PREFIX)
    else
      Result := Result + EnumCardFields('CARD', ifkDest, INV_DESTFEATURE_PREFIX);
  end;

  Result := Result + ' ';
  {@UNFOLD MACRO INH_ORIG_FINALLY('TGDCINVDOCUMENTLINE', 'GETSELECTCLAUSE', KEYGETSELECTCLAUSE)}
  {M}  finally
  {M}    if (not FDataTransfer) and Assigned(gdcBaseMethodControl) then
  {M}      ClearMacrosStack2('TGDCINVDOCUMENTLINE', 'GETSELECTCLAUSE', KEYGETSELECTCLAUSE);
  {M}  end;
  {END MACRO}
end;

procedure TgdcInvDocumentLine.GetWhereClauseConditions(S: TStrings);
begin
  inherited;

  if (csDesigning in ComponentState) or (FDocumentTypeKey = -1) then
    Exit;

  if RelationType = irtTransformation then
  begin
    if ViewMovementPart = impIncome then
      S.Add(' INVLINE.VIEWMOVEMENTPART = ''I'' ')

    else if ViewMovementPart = impExpense then
      S.Add(' INVLINE.VIEWMOVEMENTPART = ''E'' ');
  end;

  S.Add('INVLINE.documentkey IS NOT NULL');
end;

function TgdcInvDocumentLine.IsFeatureUsed(const FieldName: String;
  Features: TgdcInvFeatures): Boolean;
var
  I: Integer;
begin
  for I := 0 to Length(Features) - 1 do
    if AnsiCompareText(Features[I], FieldName) = 0 then
    begin
      Result := True;
      Exit;
    end;

  Result := False;
end;

procedure TgdcInvDocumentLine.ReadOptions(DE: TgdDocumentEntry);
var
  AnIDE: TgdInvDocumentEntry;
  
  procedure SLToAS(const AFeature: TgdInvDocumentEntryFeature; var AnAS: TgdcInvFeatures);
  var
    I: Integer;
  begin
    SetLength(AnAS, AnIDE.GetFeaturesCount(AFeature));
    for I := 0 to High(AnAS) do
      AnAS[I] := AnIDE.GetFeature(AFeature, I);
  end;

begin
  inherited;

  if DE <> nil then
  begin
    AnIDE := DE as TgdInvDocumentEntry;

    SLToAS(ftSource, FSourceFeatures);
    SLToAS(ftDest, FDestFeatures);
    SLToAS(ftMinus, FMinusFeatures);

    FSources := AnIDE.GetSources;
    FDirection := AnIDE.GetDirection;

    if AnIDE.GetFeaturesCount(ftRestrRemainsBy) > 0 then
      FRestrictRemainsBy := AnIDE.GetFeature(ftRestrRemainsBy, 0);

    if not (irsRemainsRef in FSources) then
    begin
      FControlRemains := False;
      FLiveTimeRemains := False;
    end else
    begin
      FControlRemains := AnIDE.GetFlag(efControlRemains);
      FLiveTimeRemains := AnIDE.GetFlag(efLiveTimeRemains);
    end;

    FCanBeDelayed := AnIDE.GetFlag(efDelayedDocument);
    FUseCachedUpdates := AnIDE.GetFlag(efUseCachedUpdates);
    FIsMinusRemains := AnIDE.GetFlag(efMinusRemains);
    FIsChangeCardValue := AnIDE.GetFlag(efIsChangeCardValue);
    FIsAppendCardValue := AnIDE.GetFlag(efIsAppendCardValue);
    FIsUseCompanyKey := AnIDE.GetFlag(efIsUseCompanyKey);
    FSaveRestWindowOption := AnIDE.GetFlag(efSaveRestWindowOption);
    FEndMonthRemains := AnIDE.GetFlag(efEndMonthRemains);
    FWithoutSearchRemains := AnIDE.GetFlag(efWithoutSearchRemains);
  end else
  begin
    SetLength(FSourceFeatures, 0);
    SetLength(FDestFeatures, 0);
    SetLength(FMinusFeatures, 0);

    FSources := [];
    FDirection := imdFIFO;

    FControlRemains := False;
    FLiveTimeRemains := False;
    FCanBeDelayed := False;
    FUseCachedUpdates := False;
    FIsMinusRemains := False;
    FIsChangeCardValue := False;
    FIsAppendCardValue := False;
    FIsUseCompanyKey := False;
    FSaveRestWindowOption := False;
    FEndMonthRemains := False;
    FWithoutSearchRemains := False;
  end;
end;

function TgdcInvDocumentLine.SelectGoodFeatures: Boolean;
begin
  SaveHeader;
  FSavepoint := '';
  if Transaction.InTransaction then
  begin
    FSavepoint := 'S' + System.Copy(StringReplace(
      StringReplace(
        StringReplace(CreateClassID, '{', '', [rfReplaceAll]), '}', '', [rfReplaceAll]),
        '-', '', [rfReplaceAll]), 1, 30);
    try
      Transaction.SetSavePoint(FSavepoint);
    except
      FSavepoint := '';
    end;
  end;

  try
    FMovement.gdcDocumentLine := Self;
    FMovement.Database := Database;
    if Transaction.InTransaction then
      FMovement.ReadTransaction := Transaction
    else
      FMovement.ReadTransaction := ReadTransaction;
    FMovement.Transaction := Transaction;
    Result := FMovement.SelectGoodFeatures;

    if not Result then
    begin
      if FSavePoint > '' then
      begin
        try
          if Transaction.InTransaction then
          begin
            Transaction.RollBackToSavePoint(FSavepoint);
            Transaction.ReleaseSavePoint(FSavepoint);
          end;
          FSavepoint := '';
          Close;
          Open;
        except
          FSavepoint := '';
        end;
      end;
    end
  finally
    if FSavePoint > '' then
    begin
      try
        if Transaction.InTransaction then
          Transaction.ReleaseSavePoint(FSavepoint);
        FSavepoint := '';
      except
        FSavepoint := '';
      end;
    end;
  end;
end;

procedure TgdcInvDocumentLine.SetJoins(const Value: TStringList);
begin
  if Value <> nil then
    FLineJoins.Assign(Value);
end;

procedure TgdcInvDocumentLine.SetViewMovementPart(
  const Value: TgdcInvMovementPart);
begin
  if FViewMovementPart <> Value then
  begin
    Close;
    FViewMovementPart := Value;
    FSQLInitialized := False;
  end;
end;

procedure TgdcInvDocumentLine.UpdateGoodNames;
begin
  if not (State in dsEditModes) then
    Edit;

  if not Assigned(FGoodSQL) then
  begin
    FGoodSQL := TIBSQL.Create(nil);
    FGoodSQL.Database := Database;
    FGoodSQL.Transaction := ReadTransaction;
    FGoodSQL.SQL.Text := 'SELECT name, alias FROM gd_good WHERE id = :id';
  end;

  FGoodSQL.Transaction := ReadTransaction;

  SetTID(FGoodSQL.ParamByName('ID'), GetTID(FieldByName('GoodKey')));
  FGoodSQL.ExecQuery;

  if FGoodSQL.RecordCount > 0 then
  begin
    FieldByName('GOODNAME').AsString := FGoodSQL.FieldByName('NAME').AsString;
    FieldByName('GOODALIAS').AsString := FGoodSQL.FieldByName('ALIAS').AsString;
  end;

  FGoodSQL.Close;
end;

{procedure TgdcInvDocumentLine.WriteOptions(Stream: TStream);
var
  I: Integer;
begin
  inherited;

  with TWriter.Create(Stream, 1024) do
  try
    WriteListBegin;
    for I := 0 to Length(FSourceFeatures) - 1 do
      WriteString(FSourceFeatures[I]);
    WriteListEnd;

    WriteListBegin;
    for I := 0 to Length(FDestFeatures) - 1 do
      WriteString(FDestFeatures[I]);
    WriteListEnd;

    Write(FSources, SizeOf(TgdcInvReferenceSources));
    Write(FDirection, SizeOf(TgdcInvMovementDirection));

    WriteBoolean(FControlRemains);
    WriteBoolean(FLiveTimeRemains);
    WriteBoolean(FCanBeDelayed);
    WriteBoolean(FUseCachedUpdates);
    WriteBoolean(FisMinusRemains);
    WriteListBegin;
    for I := 0 to Length(FMinusFeatures) - 1 do
      WriteString(FMinusFeatures[I]);
    WriteListEnd;
    WriteBoolean(FIsChangeCardValue);
    WriteBoolean(FIsAppendCardValue);
    WriteBoolean(FIsUseCompanyKey);
    WriteBoolean(FSaveRestWindowOption);
    WriteBoolean(FEndMonthRemains);
    WriteBoolean(FWithoutSearchRemains);

  finally
    Free;
  end;
end;}

procedure TgdcInvDocumentLine.SetSubType(const Value: TgdcSubType);
begin
  inherited;
  if Assigned(FMovement) then
    FMovement.SubType := Value;
end;

procedure TgdcInvDocumentLine.DoAfterCancel;
var
  DataSet: TgdcBase;
begin
  inherited;
  if FisErrorUpdate then
  begin
    try
      FMovement.gdcDocumentLine := Self;
      FMovement.Database := Database;
      FMovement.ReadTransaction := Transaction;
      FMovement.Transaction := Transaction;

      if Assigned(MasterSource) and Assigned(MasterSource.DataSet) then
        DataSet := MasterSource.DataSet as TgdcBase
      else
        DataSet := nil;

      if Assigned(DataSet) and (sDialog in DataSet.BaseState) and not CachedUpdates
      then
        FMovement.CreateMovement(ipsmPosition)
      else
        FMovement.CreateMovement(ipsmDocument);
    except
      on E:Exception do
      begin
        if not (sLoadFromStream in BaseState) then
          MessageBox(ParentHandle, PChar(Format(s_InvErrorSaveHeadDocument,
            [E.Message])), PChar(sAttention), mb_OK or mb_IconInformation);
        Transaction.RollbackRetaining;
        Close;
        Open;
      end;
    end;
    FisErrorUpdate := False;
  end;
end;

procedure TgdcInvDocumentLine.SetFeatures(isFrom, isTo: Boolean);
var
  ibsql: TIBSQL;
  i: Integer;
begin
  try
    FisSetFeaturesFromRemains := True;
    if isFrom and not FieldByName('FROMCARDKEY').IsNull then
    begin
      ibsql := TIBSQL.Create(nil);
      try
        ibsql.Transaction := ReadTransaction;
        ibsql.SQL.Text := 'SELECT * FROM inv_card WHERE id = :id';
        SetTID(ibsql.ParamByName('id'), GetTID(FieldByName('fromcardkey')));
        ibsql.ExecQuery;
        if ibsql.RecordCount > 0 then
        begin
          for i:= Low(FSourceFeatures) to High(FSourceFeatures) do
            SetVar2Field(FieldByName('FROM_' + FSourceFeatures[i]),
              GetFieldAsVar(ibsql.FieldByName(FSourceFeatures[i])));
        end;
      finally
        ibsql.Free;
      end;
    end;
    if isTo then
    begin
      for i:= Low(FSourceFeatures) to High(FSourceFeatures) do
        if Assigned(FindField('TO_' + FSourceFeatures[i])) then
          SetVar2Field(FieldByName('TO_' + FSourceFeatures[i]),
             GetFieldAsVar(FieldByName('FROM_' + FSourceFeatures[i])));
    end;
  finally
    FisSetFeaturesFromRemains := False;
  end;
end;

procedure TgdcInvDocumentLine._SaveToStream(Stream: TStream;
  ObjectSet: TgdcObjectSet; PropertyList: TgdcPropertySets;
  BindedList: TgdcObjectSet; WithDetailList: TgdKeyArray;
  const SaveDetailObjects: Boolean);
var
  I: Integer;
  fld: TatRelationField;
  Obj: TgdcBase;
  FC: TgdcFullClass;
begin
 if ((ObjectSet <> nil) and (ObjectSet.Find(ID) > -1)) then
   Exit;
{����� ����������� ��������� ���������� ��������� ������ �� ��������}
  for I := 0 to FieldCount - 1 do
  begin
    if (AnsiPos('"INV_CARD".', Fields[I].Origin) = 1) {and (Fields[I].DataType = ftInteger)}
      and not Fields[I].IsNull then
    begin
      fld := atDatabase.FindRelationField('INV_CARD',
        System.Copy(Fields[I].Origin, 13, Length(Fields[I].Origin) - 13));
      if Assigned(fld) and Assigned(fld.References) and (GetTID(Fields[I]) <> ID) then
      begin
        FC := GetBaseClassForRelationByID(fld.References.RelationName, GetTID(Fields[I]), Transaction);
        if Assigned(FC.gdClass) then
        begin
          Obj := FC.gdClass.CreateWithID(nil, Database, Transaction,
            GetTID(Fields[I]), FC.SubType);
          try
            if Transaction.InTransaction then
              Obj.ReadTransaction := Transaction
            else
              Obj.ReadTransaction := ReadTransaction;
            Obj.FReadUserFromStream := Self.FReadUserFromStream;  
            Obj.Open;
            if Obj.RecordCount = 1 then
            begin
              Obj._SaveToStream(Stream, ObjectSet, PropertyList, BindedList,
                WithDetailList, SaveDetailObjects);
            end;
          finally
            Obj.Free;
          end;
        end;
      end;
    end;
  end;
  inherited;
end;

function TgdcInvDocumentLine.GetMasterObject: TgdcDocument;
begin
  Result := TgdcInvDocument.CreateSubType(Owner, SubType);
end;

function TgdcInvDocumentLine.GetNotCopyField: String;
  {@UNFOLD MACRO INH_ORIG_PARAMS(VAR)}
  {M}VAR
  {M}  Params, LResult: Variant;
  {M}  tmpStrings: TStackStrings;
  {END MACRO}
begin
  {@UNFOLD MACRO INH_ORIG_GETNOTCOPYFIELD('TGDCINVDOCUMENTLINE', 'GETNOTCOPYFIELD', KEYGETNOTCOPYFIELD)}
  {M}  try
  {M}    if (not FDataTransfer) and Assigned(gdcBaseMethodControl) then
  {M}    begin
  {M}      SetFirstMethodAssoc('TGDCINVDOCUMENTLINE', KEYGETNOTCOPYFIELD);
  {M}      tmpStrings := TStackStrings(ClassMethodAssoc.IntByKey[KEYGETNOTCOPYFIELD]);
  {M}      if (tmpStrings = nil) or (tmpStrings.IndexOf('TGDCINVDOCUMENTLINE') = -1) then
  {M}      begin
  {M}        Params := VarArrayOf([GetGdcInterface(Self)]);
  {M}        if gdcBaseMethodControl.ExecuteMethodNew(ClassMethodAssoc, Self, 'TGDCINVDOCUMENTLINE',
  {M}          'GETNOTCOPYFIELD', KEYGETNOTCOPYFIELD, Params, LResult) then
  {M}          begin
  {M}            if (VarType(LResult) = varOleStr) or (VarType(LResult) = varString) then
  {M}              Result := String(LResult)
  {M}            else
  {M}              begin
  {M}                raise Exception.Create('��� ������ ''' + 'GETNOTCOPYFIELD' + ' ''' +
  {M}                  ' ������ ' + Self.ClassName + TGDCINVDOCUMENTLINE(Self).SubType + #10#13 +
  {M}                  '�� ������� ��������� �� ��������� ���');
  {M}              end;
  {M}            exit;
  {M}          end;
  {M}      end else
  {M}        if tmpStrings.LastClass.gdClassName <> 'TGDCINVDOCUMENTLINE' then
  {M}        begin
  {M}          Result := Inherited GetNotCopyField;
  {M}          Exit;
  {M}        end;
  {M}    end;
  {END MACRO}

  Result := inherited GetNotCopyField + ',FROMCARDKEY,TOCARDKEY';
  
  {@UNFOLD MACRO INH_ORIG_FINALLY('TGDCINVDOCUMENTLINE', 'GETNOTCOPYFIELD', KEYGETNOTCOPYFIELD)}
  {M}  finally
  {M}    if (not FDataTransfer) and Assigned(gdcBaseMethodControl) then
  {M}      ClearMacrosStack2('TGDCINVDOCUMENTLINE', 'GETNOTCOPYFIELD', KEYGETNOTCOPYFIELD);
  {M}  end;
  {END MACRO}
end;

procedure TgdcInvDocumentLine.DoBeforeInsert;

  {@UNFOLD MACRO INH_ORIG_PARAMS(VAR)}
  {M}VAR
  {M}  Params, LResult: Variant;
  {M}  tmpStrings: TStackStrings;
  {END MACRO}

begin
  {@UNFOLD MACRO INH_ORIG_WITHOUTPARAM('TGDCINVDOCUMENTLINE', 'DOBEFOREINSERT', KEYDOBEFOREINSERT)}
  {M}  try
  {M}    if (not FDataTransfer) and Assigned(gdcBaseMethodControl) then
  {M}    begin
  {M}      SetFirstMethodAssoc('TGDCINVDOCUMENTLINE', KEYDOBEFOREINSERT);
  {M}      tmpStrings := TStackStrings(ClassMethodAssoc.IntByKey[KEYDOBEFOREINSERT]);
  {M}      if (tmpStrings = nil) or (tmpStrings.IndexOf('TGDCINVDOCUMENTLINE') = -1) then
  {M}      begin
  {M}        Params := VarArrayOf([GetGdcInterface(Self)]);
  {M}        if gdcBaseMethodControl.ExecuteMethodNew(ClassMethodAssoc, Self, 'TGDCINVDOCUMENTLINE',
  {M}          'DOBEFOREINSERT', KEYDOBEFOREINSERT, Params, LResult) then exit;
  {M}      end else
  {M}        if tmpStrings.LastClass.gdClassName <> 'TGDCINVDOCUMENTLINE' then
  {M}        begin
  {M}          Inherited;
  {M}          Exit;
  {M}        end;
  {M}    end;
  {END MACRO}
  SaveHeader;
  inherited;
  {@UNFOLD MACRO INH_ORIG_FINALLY('TGDCINVDOCUMENTLINE', 'DOBEFOREINSERT', KEYDOBEFOREINSERT)}
  {M}  finally
  {M}    if (not FDataTransfer) and Assigned(gdcBaseMethodControl) then
  {M}      ClearMacrosStack2('TGDCINVDOCUMENTLINE', 'DOBEFOREINSERT', KEYDOBEFOREINSERT);
  {M}  end;
  {END MACRO}
end;


procedure TgdcInvDocumentLine.SaveHeader;
var
  R: TatRelation;
  F: TatRelationField;
begin
  if Assigned(MasterSource) and Assigned(MasterSource.DataSet) and
     (MasterSource.DataSet.State in [dsInsert, dsEdit]) and
     (MasterSource.DataSet is TgdcInvBaseDocument)
  then
  begin
    if ((AnsiCompareText(MovementSource.RelationName,
         (MasterSource.DataSet as TgdcInvBaseDocument).RelationName) = 0) and
       MasterSource.DataSet.FieldByName(MovementSource.SourceFieldName).IsNull)
    then
    begin
      R := atDatabase.Relations.ByRelationName(MovementSource.RelationName);
      if Assigned(R) then
      begin
        F := R.RelationFields.ByFieldName(MovementSource.SourceFieldName);
        if Assigned(F) then
          MessageBox(ParentHandle, PChar(s_InvEmptyField + F.LName), PChar(sAttention),
            mb_Ok or mb_IconInformation)
        else
          MessageBox(ParentHandle, PChar(s_InvEmptyField), PChar(sAttention),
            mb_Ok or mb_IconInformation);
        abort;
      end;
    end;

    if ((AnsiCompareText(MovementTarget.RelationName,
         (MasterSource.DataSet as TgdcInvBaseDocument).RelationName) = 0) and
       MasterSource.DataSet.FieldByName(MovementTarget.SourceFieldName).IsNull)
    then
    begin
      R := atDatabase.Relations.ByRelationName(MovementTarget.RelationName);
      if Assigned(R) then
      begin
        F := R.RelationFields.ByFieldName(MovementTarget.SourceFieldName);
        if Assigned(F) then
          MessageBox(ParentHandle, PChar(s_InvEmptyField + F.LName), PChar(sAttention),
            mb_Ok or mb_IconInformation)
        else
          MessageBox(ParentHandle, PChar(s_InvEmptyField), PChar(sAttention),
            mb_Ok or mb_IconInformation);
        abort;
      end;
    end;

    try
      MasterSource.DataSet.Post;
    except
      on E: Exception do
      begin
        MessageBox(ParentHandle, PChar(Format(s_InvErrorSaveHeadDocument, [E.Message])),
          PChar(sAttention), mb_ok or mb_IconInformation);
        abort;
      end;
    end;
  end;

end;

procedure TgdcInvDocumentLine.SetIsMakeMovementOnFromCardKeyOnly(
  const Value: Boolean);
begin
  if Value <> FIsMakeMovementOnFromCardKeyOnly then
  begin
    FIsMakeMovementOnFromCardKeyOnly := Value;
    Movement.ClearCardQuery;
  end;
end;

class function TgdcInvDocumentLine.GetDialogFormClassName(
  const ASubType: TgdcSubType): String;
begin
  Result := 'TdlgInvDocumentLine';
end;

{$IFDEF NEWDEPOT}
procedure TgdcInvDocumentLine.NewCreateMovement;
var
  i: Integer;
  ibsql: TIBSQL;
  FieldList, ValueList: String;

begin
  ibsql := TIBSQL.Create(nil);
  try

    ibsql.Transaction := Transaction;
    ibsql.SQL.Text := 'DELETE FROM usr$' + SubType + ' WHERE documentkey = :documentkey';
    SetTID(ibsql.ParamByName('documentkey'), GetTID(FieldByName('id')));
    ibsql.ExecQuery;

    if (Length(FSourceFeatures) > 0) and ((RelationType <> irtTransformation) or
      (ViewMovementPart = impExpense) or
       ((ViewMovementPart = impAll) and (FieldByName('OUTQUANTITY').AsCurrency <> 0))) then
    begin
      FieldList := '';
      ValueList := '';
      for i := 0 to Length(FSourceFeatures) - 1 do
      begin
        if FieldList <> '' then FieldList := FieldList + ',';
        FieldList := FieldList + FSourceFeatures[i];
        if ValueList <> '' then ValueList := ValueList + ',';
        ValueList := ValueList + ':' + FSourceFeatures[i];
      end;
      ibsql.SQL.Text :=
        ' INSERT INTO usr$' + SubType + ' (documentkey, goodkey, typevalue, minusremains, ischeckdestfeatures, ' + FieldList + ') ' +
        ' VALUES (:documentkey, :goodkey, ''F'', :minusremains, :ischeckdestfeatures, ' + ValueList + ') ';
      ibsql.Prepare;
      SetTID(ibsql.ParamByName('documentkey'), GetTID(FieldByName('id')));
      SetTID(ibsql.ParamByName('goodkey'), GetTID(FieldByName('goodkey')));
//      ibsql.ParamByName('checkremains').AsInteger := Integer(ControlRemains);
      ibsql.ParamByName('ischeckdestfeatures').AsInteger := Integer(IsCheckDestFeatures);
      if isMinusRemains and isChooseRemains then
        ibsql.ParamByName('minusremains').AsInteger := 1
      else
        ibsql.ParamByName('minusremains').AsInteger :=  0;
      for i := 0 to Length(FSourceFeatures) - 1 do
        SetVar2Param(ibsql.ParamByName(FSourceFeatures[i]), GetFieldAsVar(FieldByName('FROM_' + FSourceFeatures[i])));
      ibsql.ExecQuery
    end;

    if (Length(FDestFeatures) > 0) and ((RelationType <> irtTransformation) or
      (ViewMovementPart = impIncome) or
       ((ViewMovementPart = impAll) and (FieldByName('INQUANTITY').AsCurrency <> 0))) then
    begin
      FieldList := '';
      ValueList := '';
      for i := 0 to Length(FDestFeatures) - 1 do
      begin
        if FieldList <> '' then FieldList := FieldList + ',';
        FieldList := FieldList + FDestFeatures[i];
        if ValueList <> '' then ValueList := ValueList + ',';
        ValueList := ValueList + ':' + FDestFeatures[i];
      end;
      ibsql.SQL.Text :=
        ' INSERT INTO usr$' + SubType + ' (documentkey, goodkey, typevalue, minusremains, ischeckdestfeatures, ' + FieldList + ') ' +
        ' VALUES (:documentkey, :goodkey, ''T'', :minusremains, :ischeckdestfeatures, ' + ValueList + ') ';
      ibsql.Prepare;
      SetTID(ibsql.ParamByName('documentkey'), GetTID(FieldByName('id')));
      SetTID(ibsql.ParamByName('goodkey'), GetTID(FieldByName('goodkey')));
//      ibsql.ParamByName('checkremains').AsInteger := Integer(ControlRemains);
      ibsql.ParamByName('ischeckdestfeatures').AsInteger := Integer(ischeckdestfeatures);
      if isMinusRemains and isChooseRemains then
        ibsql.ParamByName('minusremains').AsInteger := 1
      else
        ibsql.ParamByName('minusremains').AsInteger :=  0;
      for i := 0 to Length(FDestFeatures) - 1 do
        SetVar2Param(ibsql.ParamByName(FDestFeatures[i]), GetFieldAsVar(FieldByName('TO_' + FDestFeatures[i])));
      ibsql.ExecQuery

    end;

  finally
    ibsql.Free;
  end;
end;
{$ENDIF}

procedure TgdcInvDocumentLine.DoBeforeEdit;
  {@UNFOLD MACRO INH_ORIG_PARAMS(VAR)}
  {M}VAR
  {M}  Params, LResult: Variant;
  {M}  tmpStrings: TStackStrings;
  {END MACRO}

begin
  {@UNFOLD MACRO INH_ORIG_WITHOUTPARAM('TGDCINVDOCUMENTLINE', 'DOBEFOREEDIT', KEYDOBEFOREEDIT)}
  {M}  try
  {M}    if (not FDataTransfer) and Assigned(gdcBaseMethodControl) then
  {M}    begin
  {M}      SetFirstMethodAssoc('TGDCINVDOCUMENTLINE', KEYDOBEFOREEDIT);
  {M}      tmpStrings := TStackStrings(ClassMethodAssoc.IntByKey[KEYDOBEFOREEDIT]);
  {M}      if (tmpStrings = nil) or (tmpStrings.IndexOf('TGDCINVDOCUMENTLINE') = -1) then
  {M}      begin
  {M}        Params := VarArrayOf([GetGdcInterface(Self)]);
  {M}        if gdcBaseMethodControl.ExecuteMethodNew(ClassMethodAssoc, Self, 'TGDCINVDOCUMENTLINE',
  {M}          'DOBEFOREEDIT', KEYDOBEFOREEDIT, Params, LResult) then exit;
  {M}      end else
  {M}        if tmpStrings.LastClass.gdClassName <> 'TGDCINVDOCUMENTLINE' then
  {M}        begin
  {M}          Inherited;
  {M}          Exit;
  {M}        end;
  {M}    end;
  {END MACRO}
//  SaveHeader;
  inherited;
  {@UNFOLD MACRO INH_ORIG_FINALLY('TGDCINVDOCUMENTLINE', 'DOBEFOREEDIT', KEYDOBEFOREEDIT)}
  {M}  finally
  {M}    if (not FDataTransfer) and Assigned(gdcBaseMethodControl) then
  {M}      ClearMacrosStack2('TGDCINVDOCUMENTLINE', 'DOBEFOREEDIT', KEYDOBEFOREEDIT);
  {M}  end;
  {END MACRO}
end;

procedure TgdcInvDocumentLine.GetProperties(ASL: TStrings);
var
  S: String;
  I: Integer;
begin
  inherited;

  ASL.Add('');
  ASL.Add('[������� ���������]');

  for I := 0 to High(FSourceFeatures) do
    if I = 0 then
      ASL.Add(AddSpaces('SourceFeatures') + FSourceFeatures[0])
    else
      ASL.Add(AddSpaces('') + FSourceFeatures[I]);

  for I := 0 to High(FDestFeatures) do
    if I = 0 then
      ASL.Add(AddSpaces('FIE.GetFeatures(ftDest)') + FDestFeatures[0])
    else
      ASL.Add(AddSpaces('') + FDestFeatures[I]);

  for I := 0 to High(FMinusFeatures) do
    if I = 0 then
      ASL.Add(AddSpaces('MinusFeatures') + FMinusFeatures[0])
    else
      ASL.Add(AddSpaces('') + FMinusFeatures[I]);

  if FDirection = imdFIFO then
    S := 'FIFO'
  else if FDirection = imdLIFO then
    S := 'LIFO'
  else
    S := 'default';

  ASL.Add(AddSpaces('Direction') + S);
  ASL.Add(AddSpaces('ControlRemains') + BooleanToString(FControlRemains));
  ASL.Add(AddSpaces('LiveTimeRemains') + BooleanToString(FLiveTimeRemains));
  ASL.Add(AddSpaces('EndMonthRemains') + BooleanToString(FEndMonthRemains));
  ASL.Add(AddSpaces('UseCachedUpdates') + BooleanToString(FUseCachedUpdates));
  ASL.Add(AddSpaces('CanBeDelayed') + BooleanToString(FCanBeDelayed));
  ASL.Add(AddSpaces('IsMinusRemains') + BooleanToString(FIsMinusRemains));
  ASL.Add(AddSpaces('IsSetFeaturesFromRemains') + BooleanToString(FisSetFeaturesFromRemains));
  ASL.Add(AddSpaces('IsChangeCardValue') + BooleanToString(FisChangeCardValue));
  ASL.Add(AddSpaces('IsAppendCardValue') + BooleanToString(FisAppendCardValue));
  ASL.Add(AddSpaces('IsCheckDestFeatures') + BooleanToString(FisCheckDestFeatures));
  ASL.Add(AddSpaces('IsChooseRemains') + BooleanToString(FisChooseRemains));
  ASL.Add(AddSpaces('IsUseCompanyKey') + BooleanToString(FIsUseCompanyKey));
  ASL.Add(AddSpaces('SaveRestWindowOption') + BooleanToString(FSaveRestWindowOption));
  ASL.Add(AddSpaces('WithoutSearchRemains') + BooleanToString(FWithoutSearchRemains));
  ASL.Add(AddSpaces('UseGoodKeyMakeMovement') + BooleanToString(FUseGoodKeyForMakeMovement));
  ASL.Add(AddSpaces('IsMakeMovemeOnFromCardKeyOnly') + BooleanToString(FIsMakeMovementOnFromCardKeyOnly));
end;

{ TgdcInvDocumentType }

constructor TgdcInvDocumentType.Create(AnOwner: TComponent);
begin
  inherited;
  CustomProcess := [cpInsert, cpModify];
end;

procedure TgdcInvDocumentType.CreateFields;
  {@UNFOLD MACRO INH_ORIG_PARAMS(VAR)}
  {M}VAR
  {M}  Params, LResult: Variant;
  {M}  tmpStrings: TStackStrings;
  {END MACRO}
begin
  {@UNFOLD MACRO INH_ORIG_WITHOUTPARAM('TGDCINVDOCUMENTTYPE', 'CREATEFIELDS', KEYCREATEFIELDS)}
  {M}  try
  {M}    if (not FDataTransfer) and Assigned(gdcBaseMethodControl) then
  {M}    begin
  {M}      SetFirstMethodAssoc('TGDCINVDOCUMENTTYPE', KEYCREATEFIELDS);
  {M}      tmpStrings := TStackStrings(ClassMethodAssoc.IntByKey[KEYCREATEFIELDS]);
  {M}      if (tmpStrings = nil) or (tmpStrings.IndexOf('TGDCINVDOCUMENTTYPE') = -1) then
  {M}      begin
  {M}        Params := VarArrayOf([GetGdcInterface(Self)]);
  {M}        if gdcBaseMethodControl.ExecuteMethodNew(ClassMethodAssoc, Self, 'TGDCINVDOCUMENTTYPE',
  {M}          'CREATEFIELDS', KEYCREATEFIELDS, Params, LResult) then exit;
  {M}      end else
  {M}        if tmpStrings.LastClass.gdClassName <> 'TGDCINVDOCUMENTTYPE' then
  {M}        begin
  {M}          Inherited;
  {M}          Exit;
  {M}        end;
  {M}    end;
  {END MACRO}

  inherited;
  FieldByName('headerrelkey').Required := True;
  FieldByName('linerelkey').Required := True;

  {@UNFOLD MACRO INH_ORIG_FINALLY('TGDCINVDOCUMENTTYPE', 'CREATEFIELDS', KEYCREATEFIELDS)}
  {M}  finally
  {M}    if (not FDataTransfer) and Assigned(gdcBaseMethodControl) then
  {M}      ClearMacrosStack2('TGDCINVDOCUMENTTYPE', 'CREATEFIELDS', KEYCREATEFIELDS);
  {M}  end;
  {END MACRO}
end;

{$IFDEF NEWDEPOT}
procedure TgdcInvDocumentType.CreateTempTable;
var
  s, head: String;
  i: Integer;
  F: TatRelationField;
  ibsql: TIBSQL;
  NameTable: String;
begin

  NameTable := 'usr$' + FieldByName('ruid').AsString;
  head := 'CREATE global TEMPORARY TABLE ' + NameTable + '(' + #13#10 +
    '  documentkey DINTKEY,' + #13#10 +
    '  goodkey DINTKEY,' + #13#10 +
    '  typevalue CHAR(1),' + #13#10 +
    '  ischeckdestfeatures DBOOLEAN, ' + #13#10 +
    '  minusremains DBOOLEAN ' + #13#10;

  s := '';
  for i := 0 to FIE.GetFeaturesCount(ftSource) - 1 do
  begin
    F := atDatabase.FindRelationField('INV_CARD', FIE.GetFeature(ftSource, i));
    if Assigned(F) then
    begin
      if s <> '' then s := s + ',';
      s := s + '  ' + FIE.GetFeature(ftSource, i) + ' ' + F.Field.FieldName;
    end;
  end;

  for i := 0 to FIE.GetFeaturesCount(ftDest) - 1 do
  begin
    if not FIE.IsExistsFeature(ftSource, FIE.GetFeature(ftDest, i)) then
    begin
      F := atDatabase.FindRelationField('INV_CARD', FIE.GetFeature(ftDest, i));
      if Assigned(F) then
      begin
        if s <> '' then s := s + ',';
        s := s + '  ' + FIE.GetFeature(ftDest, i) + ' ' + F.Field.FieldName;
      end;
    end;
  end;

  if s <> '' then
    s := ', ' + s;

  s := head + s + #13#10 + ') ' + #13#10 +
    ' ON commit delete ROWS ' + #13#10;

  ibsql := TIBSQL.Create(nil);
  try

    ibsql.Transaction := Transaction;
    ibsql.Close;
    ibsql.SQL.Text := 'DROP TRIGGER USR$BI_' + FieldByName('ruid').AsString;
    try
      ibsql.ExecQuery;
    except
    end;

    ibsql.Close;
    ibsql.SQL.Text := 'DROP TRIGGER USR$BU_' + FieldByName('ruid').AsString;
    try
      ibsql.ExecQuery;
    except
    end;


    ibsql.Close;
    ibsql.SQL.Text := 'DROP TABLE ' + NameTable;
    try
      ibsql.ExecQuery;
    except
    end;

    ibsql.Close;
    ibsql.SQL.Text := s;
    ibsql.ExecQuery;

    ibsql.Close;
    ibsql.SQL.Text := 'GRANT ALL ON ' + NameTable + ' TO administrator';
    ibsql.ExecQuery;

  finally
    ibsql.Free;
  end;


end;

procedure TgdcInvDocumentType.CreateTriggers;
var
  gdcTrigger: TgdcTrigger;
  NameTrigger: String;
  R: TatRelation;
  RelType: TgdcInvRelationType;
  srcFieldArray: TgdcInvShortFieldArray;

const
  FixedVariableList =
    'AS ' + #13#10 +
    '  declare variable ruid druid; ' + #13#10 +
    '  declare variable documentdate date; ' + #13#10 +
    '  declare variable id DFOREIGNKEY; ' + #13#10 +
    '  declare variable cardkey dforeignkey; ' + #13#10 +
    '  declare variable newcardkey dforeignkey; ' + #13#10 +
    '  declare variable companykey dforeignkey; ' + #13#10 +
    '  declare variable goodkey dforeignkey; ' + #13#10 +
    '  declare variable fromcontactkey dforeignkey; ' + #13#10 +
    '  declare variable tocontactkey dforeignkey; ' + #13#10 +
    '  declare variable movementkey dforeignkey; ' + #13#10 +
    '  declare variable delayed DBOOLEAN; ' + #13#10 +
    '  declare variable checkremains DBOOLEAN; ' + #13#10 +
    '  declare variable minusremains DBOOLEAN; ' + #13#10 +
    '  declare variable ischeckdestfeatures DBOOLEAN; ' + #13#10 +
    '  declare variable remains numeric(15, 4); ' + #13#10 +
    '  declare variable tmpquantity numeric(15, 4); ' + #13#10 +
    '  declare variable quant numeric(15, 4); ' + #13#10 +
    '  declare variable ondate DATE; ' + #13#10 +
    '  declare variable firstdate DATE; ' + #13#10 +
    '  declare variable movementquantity numeric(15, 4); ' + #13#10 +
    '  declare variable olddocumentdate date; ' + #13#10 +
    '  declare variable isdeletemovement DBOOLEAN; ' + #13#10 +
    '  declare variable firstdocumentkey DFOREIGNKEY; ' + #13#10;


  ConstTriggerText =
    'BEGIN ' + #13#10 +
    '  /* �������� ��� ��������, ������� �������� � ����, ������ � gd_document ��� ��������� */ ' + #13#10 +
    '  select dt.ruid, d.companykey, d.documentdate, d.delayed from  ' + #13#10 +
    '     gd_document d join gd_documenttype dt ON d.documenttypekey = dt.id ' + #13#10 +
    '  where d.id = NEW.masterkey ' + #13#10 +
    '  into :ruid, :companykey, :documentdate, :delayed; ' + #13#10 +
    '  isdeletemovement = 0; ' + #13#10;

procedure InitFieldArray;
var
  i: Integer;
  CountFields: Integer;
  R: TatRelation;
begin

  R := atDatabase.Relations.ByRelationName('INV_CARD');
  CountFields := R.RelationFields.Count;
  SetLength(srcFieldArray, CountFields);
  for i := 0 to CountFields - 1 do
  begin
    srcFieldArray[i].FieldName := R.RelationFields[i].FieldName;
    srcFieldArray[i].AliasName := 'F' + IntToStr(i);
  end;

end;

function GetFieldAlias(FieldName: String): String;
var
  i: Integer;
begin
  for i:= 1 to Length(srcFieldArray) do
    if srcFieldArray[i].FieldName = FieldName then
    begin
      Result := srcFieldArray[i].AliasName;
      exit;
    end;
end;


function MakeFieldList(ftType: TgdInvDocumentEntryFeature; Prefix: String): String;
var
  i: Integer;
  CountFields: Integer;
  F: TatRelationField;
begin
  Result := '';
  CountFields := FIE.GetFeaturesCount(ftType);

  for i := 0 to CountFields - 1 do
  begin
    F := atDatabase.FindRelationField('INV_CARD', FIE.GetFeature(ftType, i));
    if Assigned(F) then
      Result := Result + '  declare variable ' + Prefix + GetFieldAlias(FIE.GetFeature(ftType, i)) + ' ' + F.Field.FieldName + ';' + #13#10;
  end;
end;

function GetIntoFieldList(ftType: TgdInvDocumentEntryFeature; Prefix: String): String;
var
  i: Integer;
begin
  Result := '';
  for i := 0 to FIE.GetFeaturesCount(ftType) - 1 do
  begin
    if Result <> '' then Result := Result + ',';
    Result := Result + ':' + Prefix + GetFieldAlias(FIE.GetFeature(ftType, i));
  end;
end;

function GetMovementContactSQL(Movement: TgdcInvMovementContactOption; IsFrom: Boolean): String;
var
  s: String;
begin
  if isFrom then
    s:= 'fromcontactkey'
  else
    s:= 'tocontactkey';

  if AnsiCompareText(Movement.RelationName, DocRelationName) = 0 then
    Result := Format(
      '      select %s from %s where documentkey = NEW.masterkey ' + #13#10 +
      '      into :%s; ' + #13#10, [Movement.SourceFieldName, Movement.RelationName, s])
  else
    Result := Format('      %s = NEW.%s;' + #13#10, [s, Movement.SourceFieldName]);
end;

function GetOldMovementContactSQL(Movement: TgdcInvMovementContactOption; IsFrom: Boolean): String;
begin
  if isFrom then
    Result := '      select DISTINCT contactkey from inv_movement ' + #13#10 +
              '      where documentkey = NEW.documentkey AND credit <> 0 ' + #13#10 +
              '      into :oldfromcontactkey; '  + #13#10
  else
    Result := '      select DISTINCT contactkey from inv_movement ' + #13#10 +
              '      where documentkey = NEW.documentkey AND debit <> 0 ' + #13#10 +
              '      into :oldtocontactkey; '  + #13#10 ;
end;

function GetOldDocumentDateSQL: String;
begin
  Result :=
    ' select FIRST(1) movementdate from inv_movement where documentkey = NEW.documentkey ' + #13#10 +
    ' into :olddocumentdate; ' + #13#10;
end;


function GetChooseRemainsSQL(ftType: TgdInvDocumentEntryFeature): String;
var
  i: Integer;
  s: String;
begin
  s := '';
  for i:= 0 to FIE.GetFeaturesCount(ftType) - 1 do
  begin
    if s <> '' then s := s + ' AND ';
    s := s + ' (c.' + FIE.GetFeature(ftType, i) + ' = :' + GetFieldAlias(FIE.GetFeature(ftType, i)) + ' or (c.' + FIE.GetFeature(ftType, i) + ' is NULL and :' +
       GetFieldAlias(FIE.GetFeature(ftType, i)) + ' is NULL)) ' + #13#10;
  end;

  if s <> '' then s := ' where ' + #13#10 + s + #13#10;

  if not FIE.GetFlag(efEndMonthRemains) then
    Result := '      ondate = :documentdate;' + #13#10
  else
    Result := '      ondate = CAST(CAST(EXTRACT(DAY FROM :documentdate - EXTRACT(DAY FROM :documentdate) + ' + #13#10 +
              '        32 - EXTRACT(DAY FROM :documentdate - EXTRACT(DAY FROM :documentdate) + 32)) as VARCHAR(2)) || ''.'' || ' + #13#10 +
              '        CAST(EXTRACT(MONTH FROM :documentdate) as VARCHAR(2)) || ''.'' || CAST(EXTRACT(YEAR FROM :documentdate) as VARCHAR(4)) as DATE); ' + #13#10;
  Result := Result +
    '      for ' + #13#10 +
    '        select m.cardkey, c.firstdate, c.firstdocumentkey, SUM(m.remains) as remains ' + #13#10 +
    '        from ' + #13#10 +
    '          (select m.cardkey, m.balance as remains from ' + #13#10 +
    '            inv_balance  m ' + #13#10 +
    '           where ' + #13#10 +
    '             m.contactkey = :fromcontactkey and m.goodkey = :goodkey and balance <> 0 ' + #13#10 +
    '/* ���� ����������� ������� �� ���� ��������� ��� ����� ������ �� ��������� �����c*/ ' + #13#10;

  if not FIE.GetFlag(efLiveTimeRemains) then
    Result := Result +
    '           union all ' + #13#10 +
    '           select m.cardkey, SUM(m.credit - m.debit) from ' + #13#10 +
    '             inv_movement m ' + #13#10 +
    '           where ' + #13#10 +
    '             m.contactkey = :fromcontactkey and m.goodkey = :goodkey and ' + #13#10 +
    '             m.movementdate > :ondate ' + #13#10 +
    '           group by m.cardkey  ' + #13#10 +
    '           having SUM(m.credit - m.debit) <> 0 ';

  Result := Result +
    ') m ' + #13#10 +
    '           join inv_card c ON m.cardkey = c.id ' + #13#10 +
    s +
    '         group by 1, 2, 3 ' + #13#10;
  if not FIE.GetFlag(efMinusRemains) then
    Result := Result +
      '         having SUM(m.remains) > 0 ' + #13#10
  else
    Result := Result +
      '         having SUM(m.remains) < 0 ' + #13#10;
  Result := Result +
    '         order by 2 ' + #13#10 +
    '         into :id, :firstdate, :firstdocumentkey, :remains ' + #13#10 +
    '       do ' + #13#10;
end;

function GetUpdateCardSQL(ftType: TgdInvDocumentEntryFeature; Prefix: String): String;
var
  i: Integer;
begin

  Result := '';
  for i:= 0 to FIE.GetFeaturesCount(ftType) - 1 do
    Result := Result + '            , ' + FIE.GetFeature(ftType, i) + ' = :' + Prefix + GetFieldAlias(FIE.GetFeature(ftType, i)) + #13#10;

  Result :=
    '          update inv_card set ' + #13#10 +
    '            goodkey = :goodkey ' + Result + #13#10 +
    '          where id = :id; ' + #13#10;

end;


function GetMakeUpdateCardSQL(ftType: TgdInvDocumentEntryFeature; Prefix: String): String;
begin

  Result :=
    '        for ' + #13#10 +
    '          select DISTINCT cardkey from ' + #13#10 +
    '            inv_movement ' + #13#10 +
    '          where documentkey = NEW.documentkey ' + #13#10;
  if (RelType = irtFeatureChange) then
    Result := Result + ' and debit > 0 ';
  Result := Result +
    '          into :id ' + #13#10 +
    '        do ' + #13#10 + GetUpdateCardSQL(ftType, Prefix);

end;

function GetNewCardSQL(ftType: TgdInvDocumentEntryFeature;  Prefix: String): String;
var
  s, s1, s2: String;
begin

  s := '';
  s1 := '';
  s2 := 'NEW.documentkey';
  if (Prefix = 'n') and (RelType <> irtTransformation) then
  begin
    s := 'parent, ';
    s1 := ':cardkey, ';
    s2 := ':firstdocumentkey';
  end;

  if (s = '') then
  begin
    if FIE.GetFeaturesCount(ftType) > 0 then
      Result :=
        Format('/* ������� ����� �������� */ ' + #13#10 +
               ' ' + #13#10 +
               '    EXECUTE PROCEDURE gd_p_getnextid_ex RETURNING_VALUES :id; ' + #13#10 +
               '    insert into inv_card (id, firstdate, ' + s + 'companykey, goodkey, documentkey, firstdocumentkey, %0:s) ' + #13#10 +
               '    values (:id, :documentdate, ' + s1 + ':companykey, :goodkey, NEW.documentkey, %2:s, %1:s); ' + #13#10,
               [FIE.GetFeaturesText(ftType), GetIntoFieldList(ftType, Prefix), s2])
    else
      Result :=
        Format('/* ������� ����� �������� */ ' + #13#10 +
               ' ' + #13#10 +
               '    EXECUTE PROCEDURE gd_p_getnextid_ex RETURNING_VALUES :id; ' + #13#10 +
               '    insert into inv_card (id, firstdate, ' + s + 'companykey, goodkey, documentkey, firstdocumentkey) ' + #13#10 +
               '    values (:id, :documentdate, ' + s1 + ':companykey, :goodkey, NEW.documentkey, %0:s); ' + #13#10,
               [s2]);
  end
  else
    Result :=  ' ' + #13#10 +
               '    EXECUTE PROCEDURE gd_p_getnextid_ex RETURNING_VALUES :id; ' + #13#10 +
               '    EXECUTE PROCEDURE INV_INSERT_CARD (:ID, :CARDKEY); ' + #13#10 +
               GetUpdateCardSQL(ftType, Prefix);


end;

function GetCheckFeaturesSQL(ftType: TgdInvDocumentEntryFeature; NewPrefix, OldPrefix: String): String;
var
  i: Integer;
  s: String;
begin

  if NewPrefix = 'n' then
    s:= 'istochange'
  else
    s:= 'ischange';

  Result := '';
  if ftType = ftSource then
  begin
    for i:= 0 to FIE.GetFeaturesCount(ftType) - 1 do
    begin
      if Result <> '' then Result := Result + ' OR ';
      Result := Result + '(' + NewPrefix + GetFieldAlias(FIE.GetFeature(ftType, i))  + ' <> ' +
          OldPrefix + GetFieldAlias(FIE.GetFeature(ftType, i)) + #13#10 +
        ' or (' + NewPrefix + GetFieldAlias(FIE.GetFeature(ftType, i)) + ' is null and '  +
          OldPrefix + GetFieldAlias(FIE.GetFeature(ftType, i)) + ' is not null) ' + #13#10 +
        ' or (' + NewPrefix + GetFieldAlias(FIE.GetFeature(ftType, i)) + ' is not null and '  +
          OldPrefix + GetFieldAlias(FIE.GetFeature(ftType, i)) + ' is null)) ' + #13#10;
    end;
    if Result <> '' then Result := Result + ' or ';
    Result :=
      '  ' + s + ' = 0;' + #13#10 +
      ' if (' + Result + ' (coalesce(goodkey, 0) <> coalesce(oldgoodkey, 0)) ) then ' + #13#10 +
      '    ' + s + ' = 1;' + #13#10;
  end
  else
  begin
    Result := '  changefields = ''''; ' + #13#10;
    for i := 0 to FIE.GetFeaturesCount(ftType) - 1 do
    begin
      Result := Result + ' if (' +
          NewPrefix + GetFieldAlias(FIE.GetFeature(ftType, i)) + ' <> ' +
          OldPrefix + GetFieldAlias(FIE.GetFeature(ftType, i)) + #13#10 +
        ' or (' + NewPrefix + GetFieldAlias(FIE.GetFeature(ftType, i)) + ' is null and '  +
          OldPrefix + GetFieldAlias(FIE.GetFeature(ftType, i)) + ' is not null) ' + #13#10 +
        ' or (' + NewPrefix + GetFieldAlias(FIE.GetFeature(ftType, i)) + ' is not null and '  +
          OldPrefix + GetFieldAlias(FIE.GetFeature(ftType, i)) + ' is null)) then ' + #13#10 +
        '    begin ' + #13#10 +
        '      select id from AT_RELATION_FIELDS where FIELDNAME = ''' + FIE.GetFeature(ftType, i) + ''' and RelationName = ''INV_CARD''' + #13#10 +
        '      into :fieldkey; ' + #13#10 +
        '      if (changefields <> '''') then ' + #13#10 +
        '       changefields = changefields || '','';' + #13#10 +
        '      changefields = changefields || CAST(fieldkey as VARCHAR(20)); ' + #13#10 +
        '      ' + s + ' = 1; ' + #13#10 +
        '    end ' + #13#10;

    end;
    Result := Result +
      '    if ( coalesce(goodkey, 0) <> coalesce(oldgoodkey, 0) ) then ' + #13#10 +
      '    begin ' + #13#10 +
      '      select LIST(DISTINCT cardkey) from inv_movement ' + #13#10 +
      '      WHERE documentkey = NEW.DOCUMENTKEY ' + #13#10 +
      '      INTO :cardstring; ' + #13#10 +
      '      if (cardstring is not null) then ' + #13#10 +
      '      begin ' + #13#10 +
      '        sqlstatement = ''select FIRST(1) m.documentkey from inv_movement m ' + #13#10 +
      '      where m.cardkey in ('' || cardstring || '') and m.documentkey <> '' || CAST(NEW.documentkey as VARCHAR(20)); ' + #13#10 +
      '      EXECUTE STATEMENT sqlstatement INTO :dockey; ' + #13#10 +
      '      if (dockey is not null) then ' + #13#10 +
      '        EXCEPTION INV_E_CANNTCHANGEGOODKEY; ' + #13#10 +
      '    end ' + #13#10 +
      '    end ' + #13#10 +
      '    if (changefields <> '''') then ' + #13#10 +
      '    begin ' + #13#10 +
      '      sqlstatement = ''select LIST(DISTINCT o.DTKEY) from gd_documenttype_option o where o.RELATIONFIELDKEY in ('' || changefields || '') and o.OPTION_NAME = ''''SF'''' '';' + #13#10 +
      '      EXECUTE STATEMENT sqlstatement INTO :dtstring; ' + #13#10 +
      '      with recursive tree ' + #13#10 +
      '      as ' + #13#10  +
      '        (select t.id, t.parent ' + #13#10 +
      '         from inv_movement m join inv_card t ON m.cardkey = t.id and m.debit > 0 ' + #13#10 +
      '         where m.documentkey = NEW.documentkey ' + #13#10 +
      '         union all ' + #13#10 +
      '         select c.id, c.parent ' + #13#10 +
      '         from inv_card c ' + #13#10 +
      '         inner join tree prior ON prior.id = c.parent) ' + #13#10 +
      '      select LIST(tr.id) from tree tr ' + #13#10 +
      '      INTO :cardstring; ' + #13#10 +
      '      if (dtstring is not null and cardstring is not null ) then ' + #13#10 +
      '      begin ' + #13#10 +
      '      if (ischeckdestfeatures = 1) then ' + #13#10 +
      '      begin ' + #13#10 +
      '          sqlstatement = ''select FIRST(1) m.documentkey, m1.id from inv_movement m join gd_document doc ON ' +
      'm.documentkey = doc.id  LEFT JOIN inv_movement m1 ON m.documentkey = m1.documentkey and ' +
      'm1.credit <> 0 and    not (m1.CARDKEY in ('' || cardstring || '')) where  m.cardkey in ('' || cardstring || '') ' +
      'and doc.documenttypekey in ('' || dtstring || '') and  m.credit <> 0 and m.documentkey <> '' || CAST(NEW.documentkey as VARCHAR(20)); ' + #13#10 +
      '          EXECUTE STATEMENT sqlstatement INTO :dockey, :badmovekey; ' + #13#10 +
      '          if (badmovekey is not null) then ' + #13#10 +
      '            EXCEPTION INV_E_CANNTCHANGEFEATURE; ' + #13#10 +
      '        end ' + #13#10 +
      '        sqlstatement = ''INSERT INTO GD_CHANGEDDOC (changedfields, sourcedockey, destdockey, editiondate, editorkey) select DISTINCT '''''' || changefields || '''''''' || '','' ' + #13#10 +
      '                       || CAST(NEW.documentkey as VARCHAR(20)) || '', m.documentkey, doc.editiondate, doc.editorkey from inv_movement m join gd_document doc ON m.documentkey = doc.id  ' + #13#10 +
      '                       where  m.cardkey in ('' || cardstring || '') ' + #13#10 +
      '                       and doc.documenttypekey in ('' || dtstring || '') and  m.credit <> 0 and m.documentkey <> '' || CAST(NEW.documentkey as VARCHAR(20)) || '' ' + #13#10 +
      'and (NOT EXISTS (SELECT * FROM gd_changeddoc WHERE destdockey = m.documentkey AND sourcedockey = '' || CAST(NEW.documentkey as VARCHAR(20)) || ''))''; ' + #13#10 +
      '      EXECUTE STATEMENT sqlstatement; ' + #13#10 +
      '      end ' + #13#10 +
      '    end ' + #13#10



  end;
end;

function GetReadFeatureSQL(ftType: TgdInvDocumentEntryFeature; IsFrom: Char; IsNew, OnlyFeatures: Boolean; Prefix: String): String;
var
  s, s1, FieldName: String;
begin
  if (isFrom = 'F') or (RelType <> irtFeatureChange) then
    FieldName := 'fromcardkey'
  else
    FieldName := 'tocardkey';

  if isNew then
  begin
    if isFrom <> #0 then
      Result := ' and typevalue = ''' + IsFrom + '''';

    s := '';
    s1 := '';
    if FIE.GetFeaturesCount(ftType) > 0 then
    begin
      s := FIE.GetFeaturesText(ftType);
      s1 := GetIntoFieldList(ftType, Prefix);
    end;
    if not OnlyFeatures then
    begin
      if s <> '' then s := s + ',';
      s:= s + 'goodkey, minusremains, ischeckdestfeatures';
      if s1 <> '' then s1 := s1 + ',';
      s1 := s1 + ':goodkey, :minusremains, :ischeckdestfeatures';
    end;
    if s <> '' then
      Result :=
          '    select ' + s + ' from ' + #13#10 +
          '    usr$' + FieldByName('ruid').AsString + #13#10 +
          '    where documentkey = NEW.documentkey  ' + Result + #13#10 +
          '    into ' + s1 + '; ' + #13#10 +
          '    if (ROW_COUNT = 0) then '  + #13#10 +
          '      select ' + StringReplace(StringReplace(s,
               'minusremains', 'CAST(0 as INTEGER) as minusremains', [rfIgnoreCase]), 'ischeckdestfeatures', 'CAST(1 as INTEGER) as ischeckdestfeatures', [rfIgnoreCase])  + ' from ' + #13#10 +
          '      inv_card ' + #13#10 +
          '      where id = NEW.' + FieldName + #13#10 +
          '      into ' + s1 + ';' + #13#10 +
          '     checkremains = NEW.checkremains; '

    else
      Result := '';
  end
  else
  begin
    s := '';
    s1 := '';
    if FIE.GetFeaturesCount(ftType) > 0 then
    begin
      s := FIE.GetFeaturesText(ftType);
      s1 := GetIntoFieldList(ftType, Prefix);
    end;
    if not OnlyFeatures then
    begin
      if s <> '' then s := s + ',';
      s:= s + 'goodkey';
      if s1 <> '' then s1 := s1 + ',';
      s1 := s1 + ':oldgoodkey';
    end;
    if isFrom = 'N' then
      FieldName := 'NEW.' + FieldName
    else
      FieldName := 'OLD.' + FieldName;
    if s <> '' then
      Result :=
          '    select ' + s + ' from ' + #13#10 +
          '    inv_card ' + #13#10 +
          '    where id = ' + FieldName + #13#10 +
          '    into ' + s1 + ';' + #13#10
    else
      Result := '';

  end;
end;

function GetCheckRemainsOnDateSQL(IsFrom: Boolean): String;
begin
  if isFrom then
    Result :=
       '  /* ������������ �������� �������� �� ����� ���� ��������� */ ' + #13#10 +
       '            for ' + #13#10 +
       '              select cardkey, SUM(credit) from inv_movement ' + #13#10 +
       '              where documentkey = NEW.documentkey and credit <> 0 ' + #13#10 +
       '              group by cardkey ' + #13#10 +
       '              into :id, :movementquantity ' + #13#10 +
       '            do ' + #13#10 +
       '            begin ' + #13#10 +
       '              select SUM(m.balance)  from ' + #13#10 +
       '                (select balance from inv_balance where ' + #13#10 +
       '                 cardkey = :id and contactkey = :fromcontactkey ' + #13#10 +
       '                 union all ' + #13#10 +
       '                 select credit - debit from inv_movement where ' + #13#10 +
       '                 cardkey = :id and contactkey = :fromcontactkey and movementdate > :documentdate) m ' + #13#10 +
       '              into :oldquantity; ' + #13#10 +
       '              if (oldquantity < movementquantity) then ' + #13#10 +
       '                EXCEPTION INV_E_NOPRODUCT; ' + #13#10 +
       '            end ' + #13#10
  else
    Result :=
       '  /* ������������ �������� �������� �� ����� ���� ��������� */ ' + #13#10 +
       '            for ' + #13#10 +
       '              select cardkey, debit from inv_movement ' + #13#10 +
       '              where documentkey = NEW.documentkey and debit <> 0 ' + #13#10 +
       '              into :id, :movementquantity ' + #13#10 +
       '            do ' + #13#10 +
       '            begin ' + #13#10 +
       '              select SUM(m.balance)  from ' + #13#10 +
       '                (select balance from inv_balance where ' + #13#10 +
       '                 cardkey = :id and contactkey = :tocontactkey ' + #13#10 +
       '                 union all ' + #13#10 +
       '                 select credit - debit from inv_movement where ' + #13#10 +
       '                 cardkey = :id and contactkey = :tocontactkey and movementdate >= :documentdate) m ' + #13#10 +
       '              into :oldquantity; ' + #13#10 +
       '              if (oldquantity < movementquantity) then ' + #13#10 +
       '                EXCEPTION INV_E_EARLIERMOVEMENT; ' + #13#10 +
       '            end ' + #13#10;
end;

function GetUpdateDateSQL: String;
begin
  Result :=
       '            /* �������� ���� �������� �� ���� ��������� */ ' + #13#10 +
       '            update inv_movement set movementdate = :documentdate ' + #13#10 +
       '            where documentkey = NEW.documentkey; ' + #13#10 + #13#10;

end;


// �������� �������� BeforeInsert ��� �������� ���������� ���������
function CreateInsertTrigger_SimpleDoc: String;
var
  ftWhat: TgdInvDocumentEntryFeature;
begin

  if FIE.GetFeaturesCount(ftDest) > 0 then
    ftWhat := ftDest
  else
    ftWhat := ftSource;

  Result :=
    FixedVariableList + #13#10 + MakeFieldList(ftWhat, '') + ConstTriggerText +
    Format(
          '  if (ruid = ''%0:s'') then ' + #13#10 +
          '  begin ' + #13#10 + GetReadFeatureSQL(ftWhat, #0, True, False, ''),
          [FieldByName('ruid').AsString]) +
          GetMovementContactSQL(FIE.GetMovement(emCredit), True) +
          GetMovementContactSQL(FIE.GetMovement(emDebit), False);

  if FIE.GetFeaturesCount(ftSource) > 0 then
    Result := Result +
        '    if (delayed = 0 and coalesce(NEW.quantity, 0) <> 0) then ' + #13#10 +
        '    begin ' + #13#10 +
        '      tmpquantity = NEW.quantity; ' + #13#10 +
        GetChooseRemainsSQL(ftSource) +
        '       begin ' + #13#10 +
        '         if (tmpquantity > remains) then ' + #13#10 +
        '           quant = remains; ' + #13#10 +
        '         else ' + #13#10 +
        '           quant = tmpquantity; ' + #13#10 +
        '         NEW.fromcardkey = :id; ' + #13#10 +
        '         EXECUTE PROCEDURE gd_p_getnextid_ex RETURNING_VALUES :movementkey; ' + #13#10 +
        ' ' + #13#10 +
        '         INSERT INTO inv_movement (movementkey, documentkey, goodkey, cardkey, contactkey, movementdate, credit) ' + #13#10 +
        '         VALUES (:movementkey, NEW.documentkey, :goodkey, :id, :fromcontactkey, :documentdate, :quant); ' + #13#10 +
        ' ' + #13#10 +
        '         INSERT INTO inv_movement (movementkey, documentkey, goodkey, cardkey, contactkey, movementdate, debit) ' + #13#10 +
        '         VALUES (:movementkey, NEW.documentkey, :goodkey, :id, :tocontactkey, :documentdate, :quant); ' + #13#10 +
        ' ' + #13#10 +
        '         tmpquantity = tmpquantity - quant; ' + #13#10 +
        '       end ' + #13#10 +
        '       if (tmpquantity > 0 and NEW.checkremains = 0) then ' + #13#10 +
        '       begin ' + #13#10 +
        GetNewCardSQL(ftSource, '') +
        '         EXECUTE PROCEDURE gd_p_getnextid_ex RETURNING_VALUES :movementkey; ' + #13#10 +
        ' ' + #13#10 +
        '         INSERT INTO inv_movement (movementkey, documentkey, goodkey, cardkey, contactkey, movementdate, credit) ' + #13#10 +
        '         VALUES (:movementkey, NEW.documentkey, :goodkey, :id, :fromcontactkey, :documentdate, :tmpquantity); ' + #13#10 +
        ' ' + #13#10 +
        '         INSERT INTO inv_movement (movementkey, documentkey, goodkey, cardkey, contactkey, movementdate, debit) ' + #13#10 +
        '         VALUES (:movementkey, NEW.documentkey, :goodkey, :id, :tocontactkey, :documentdate, :tmpquantity); ' + #13#10 +
        '       end' + #13#10 +
        '       else ' + #13#10 +
        '       if (tmpquantity > 0) then '  + #13#10 +
        '         EXCEPTION INV_E_INSUFFICIENTBALANCE; ' + #13#10 +
        '    end ' + #13#10 +
        '    else ' + #13#10 +
        '    begin ' + #13#10 +
        GetNewCardSQL(ftSource, '') +
        '      NEW.fromcardkey = :id; ' + #13#10 +
        '    end ' + #13#10 +
        '  end ' + #13#10
   else
     Result := Result +
          '                                         ' + #13#10 +
          ' ' + #13#10 + GetNewCardSQL(ftWhat, '') +
          '/* ����������� �� � fromcardkey ��������� */ ' + #13#10 +
          '    NEW.fromcardkey = :id; ' + #13#10 +
          ' ' + #13#10 +
          '    if (delayed = 0 and coalesce(NEW.quantity, 0) <> 0) then ' + #13#10 +
          '    begin ' + #13#10 +
          '/* ���� �������� �� ���������� ������� �������� */ ' + #13#10 +
          '/* �� ����� ��������� ������� �������� ������ � ���� */ ' + #13#10 +
          '      if (minusremains = 0) then ' + #13#10 +
          '      begin ' + #13#10 +
          '        EXECUTE PROCEDURE gd_p_getnextid_ex RETURNING_VALUES :movementkey; ' + #13#10 +
          ' ' + #13#10 +
          '  /* ��������� �������� � inv_movememt */ ' + #13#10 +
          ' ' + #13#10 +
          '        INSERT INTO inv_movement (movementkey, documentkey, goodkey, cardkey, contactkey, movementdate, credit) ' + #13#10 +
          '        VALUES (:movementkey, NEW.documentkey, :goodkey, :id, :fromcontactkey, :documentdate, NEW.quantity); ' + #13#10 +
          ' ' + #13#10 +
          '        INSERT INTO inv_movement (movementkey, documentkey, goodkey, cardkey, contactkey, movementdate, debit) ' + #13#10 +
          '        VALUES (:movementkey, NEW.documentkey, :goodkey, :id, :tocontactkey, :documentdate, NEW.quantity); ' + #13#10 +
          '      end ' + #13#10 +
          '      else ' + #13#10 +
          '      begin ' + #13#10 +
          '        tmpquantity = NEW.quantity; ' + #13#10 +
          GetChooseRemainsSQL(ftWhat) +
          '       begin ' + #13#10 +
          '         if (tmpquantity > ABS(remains)) then ' + #13#10 +
          '           quant = ABS(remains); ' + #13#10 +
          '         else ' + #13#10 +
          '           quant = tmpquantity; ' + #13#10 +
          '         NEW.fromcardkey = :id; ' + #13#10 +
          '         EXECUTE PROCEDURE gd_p_getnextid_ex RETURNING_VALUES :movementkey; ' + #13#10 +
          ' ' + #13#10 +
          '         INSERT INTO inv_movement (movementkey, documentkey, goodkey, cardkey, contactkey, movementdate, credit) ' + #13#10 +
          '         VALUES (:movementkey, NEW.documentkey, :goodkey, :id, :fromcontactkey, :documentdate, :quant); ' + #13#10 +
          ' ' + #13#10 +
          '         INSERT INTO inv_movement (movementkey, documentkey, goodkey, cardkey, contactkey, movementdate, debit) ' + #13#10 +
          '         VALUES (:movementkey, NEW.documentkey, :goodkey, :id, :tocontactkey, :documentdate, :quant); ' + #13#10 +
          ' ' + #13#10 +
          '         tmpquantity = tmpquantity - quant; ' + #13#10 +
          '       end ' + #13#10 +
          '       if (tmpquantity > 0) then ' + #13#10 +
          '         EXCEPTION INV_E_INSUFFICIENTBALANCE; ' + #13#10 +
          '      end ' + #13#10 +
          '    end ' + #13#10 +
          '  end ' + #13#10;
   Result := Result + 'end ';
end;

// �������� �������� BeforeUpdate ��� �������� ���������� ���������
function CreateUpdateTrigger_SimpleDoc: String;
var
  Features: TgdInvDocumentEntryFeature;
  s: String;
begin

  if FIE.GetFeaturesCount(ftDest) > 0 then
    Features := ftDest
  else
    Features := ftSource;

  Result :=
    FixedVariableList + #13#10 +
    '  declare variable oldgoodkey DFOREIGNKEY; ' + #13#10 +
    '  declare variable oldfromcontactkey DFOREIGNKEY; ' + #13#10 +
    '  declare variable oldtocontactkey DFOREIGNKEY; ' + #13#10 +
    '  declare variable oldquantity numeric(15, 4); ' + #13#10 +
    '  declare variable ischange dboolean; ' + #13#10 +
    '  declare variable sqlstatement VARCHAR(4096); ' + #13#10 +
    '  declare variable changefields VARCHAR(4096); ' + #13#10 +
    '  declare variable dtstring VARCHAR(1024); ' + #13#10 +
    '  declare variable cardstring VARCHAR(1024); ' + #13#10 +
    '  declare variable fieldkey DFOREIGNKEY; ' + #13#10 +
    '  declare variable dockey DFOREIGNKEY; ' + #13#10 +
    '  declare variable badmovekey DFOREIGNKEY; ' + #13#10 +
    MakeFieldList(Features, '') + MakeFieldList(Features, 'o') + ConstTriggerText +
    Format(
          '  if (ruid = ''%0:s'') then ' + #13#10 +
          '  begin ' + #13#10 + GetReadFeatureSQL(Features, #0, True, False, ''),
          [FieldByName('ruid').AsString]) + GetReadFeatureSQL(Features, #0, False, False, 'o') +
        GetMovementContactSQL(FIE.GetMovement(emCredit), True) +
        GetMovementContactSQL(FIE.GetMovement(emDebit), False) +
        GetOldMovementContactSQL(FIE.GetMovement(emCredit), True) +
        GetOldMovementContactSQL(FIE.GetMovement(emDebit), False) +
        GetCheckFeaturesSQL(Features, '', 'o') +
        GetOldDocumentDateSQL;

    if FIE.GetFlag(efLiveTimeRemains) then
      s := '        if (isdeletemovement = 0) then ' + #13#10 +
           '        begin ' + #13#10 +
           '          if (olddocumentdate > documentdate) then ' + #13#10 +
           '' + GetUpdateDateSQL +
           '          else ' + #13#10 +
           '          begin ' + #13#10 + GetCheckRemainsOnDateSQL(False) +  GetUpdateDateSQL +
           '          end ' + #13#10 +
           '        end ' + #13#10

    else
      s := '        if (isdeletemovement = 0) then ' + #13#10 +
           '        begin ' + #13#10 +
           '        if (olddocumentdate <> documentdate) then ' + #13#10 +
           '        begin ' + #13#10 +
           '          if (NEW.checkremains = 1 and olddocumentdate > documentdate) then ' + #13#10 +
           '          begin ' + #13#10 +  GetCheckRemainsOnDateSQL(True) +
           '          end ' + #13#10 +
           '          if (olddocumentdate < documentdate) then ' + #13#10 +
           '          begin ' + #13#10 + GetCheckRemainsOnDateSQL(False) +
           '          end ' + #13#10 + GetUpdateDateSQL +
           '        end ' + #13#10 +
           '        end ' + #13#10;

  if FIE.GetFeaturesCount(ftSource) > 0 then
    Result := Result +
        '    if (delayed = 1) then ' + #13#10 +
        '      DELETE FROM inv_movement WHERE documentkey = NEW.documentkey; ' + #13#10 +
        '    else ' + #13#10 +
        '    begin ' + #13#10 +
        '      rdb$set_context(''USER_TRANSACTION'', ''CONTROLREMAINS'', NEW.checkremains); ' + #13#10 +
        '      if ((ischange = 1) or (oldfromcontactkey <> fromcontactkey) or (olddocumentdate IS NULL) or (NOT EXISTS (select id from inv_movement where documentkey = NEW.documentkey))) then ' + #13#10 +
        '      begin ' + #13#10 +
        '        DELETE FROM inv_movement WHERE documentkey = NEW.documentkey; ' + #13#10 +
        '        isdeletemovement = 1; ' + #13#10 +
        '        tmpquantity = NEW.quantity; ' + #13#10 +
        GetChooseRemainsSQL(Features) +
        '         begin ' + #13#10 +
        '           if (tmpquantity > remains) then ' + #13#10 +
        '             quant = remains; ' + #13#10 +
        '           else ' + #13#10 +
        '             quant = tmpquantity; ' + #13#10 +
        '           NEW.fromcardkey = :id; ' + #13#10 +
        '           EXECUTE PROCEDURE gd_p_getnextid_ex RETURNING_VALUES :movementkey; ' + #13#10 +
        ' ' + #13#10 +
        '           INSERT INTO inv_movement (movementkey, documentkey, goodkey, cardkey, contactkey, movementdate, credit) ' + #13#10 +
        '           VALUES (:movementkey, NEW.documentkey, :goodkey, :id, :fromcontactkey, :documentdate, :quant); ' + #13#10 +
        ' ' + #13#10 +
        '           INSERT INTO inv_movement (movementkey, documentkey, goodkey, cardkey, contactkey, movementdate, debit) ' + #13#10 +
        '           VALUES (:movementkey, NEW.documentkey, :goodkey, :id, :tocontactkey, :documentdate, :quant); ' + #13#10 +
        ' ' + #13#10 +
        '           tmpquantity = tmpquantity - quant; ' + #13#10 +
        '         end ' + #13#10 +
        '         if (tmpquantity > 0 and NEW.checkremains = 0) then ' + #13#10 +
        '         begin ' + #13#10 +
        GetNewCardSQL(Features, '') +
        '           EXECUTE PROCEDURE gd_p_getnextid_ex RETURNING_VALUES :movementkey; ' + #13#10 +
        ' ' + #13#10 +
        '           INSERT INTO inv_movement (movementkey, documentkey, goodkey, cardkey, contactkey, movementdate, credit) ' + #13#10 +
        '           VALUES (:movementkey, NEW.documentkey, :goodkey, :id, :fromcontactkey, :documentdate, :tmpquantity); ' + #13#10 +
        ' ' + #13#10 +
        '           INSERT INTO inv_movement (movementkey, documentkey, goodkey, cardkey, contactkey, movementdate, debit) ' + #13#10 +
        '           VALUES (:movementkey, NEW.documentkey, :goodkey, :id, :tocontactkey, :documentdate, :tmpquantity); ' + #13#10 +
        '         end' + #13#10 +
        '         else ' + #13#10 +
        '         if (tmpquantity > 0) then '  + #13#10 +
        '           EXCEPTION INV_E_INSUFFICIENTBALANCE; ' + #13#10 +
        '      end ' + #13#10 +
        '      else ' + #13#10 +
        '      begin '  + #13#10 +
        '        if (coalesce(oldtocontactkey, 0) <> coalesce(tocontactkey, 0)) then ' + #13#10 +
        '        begin ' + #13#10 +
        '          UPDATE inv_movement SET contactkey = :tocontactkey ' + #13#10 +
        '          WHERE documentkey = NEW.documentkey and debit <> 0; ' + #13#10 +
        '          when EXCEPTION INV_E_INVALIDMOVEMENT do ' + #13#10 +
        '            EXCEPTION INV_E_DONTCHANGEBENEFICIARY; ' + #13#10 +
        '        end ' + #13#10 + S +
        '        if (coalesce(OLD.quantity, 0) < coalesce(NEW.quantity, 0)) then ' + #13#10 +
        '        begin ' + #13#10 +
        '         tmpquantity = coalesce(NEW.quantity, 0) - coalesce(OLD.quantity, 0); ' + #13#10 +
        GetChooseRemainsSQL(Features) +
        '         begin ' + #13#10 +
        '           if (tmpquantity > remains) then ' + #13#10 +
        '             quant = remains; ' + #13#10 +
        '           else ' + #13#10 +
        '             quant = tmpquantity; ' + #13#10 +
        '           EXECUTE PROCEDURE gd_p_getnextid_ex RETURNING_VALUES :movementkey; ' + #13#10 +
        ' ' + #13#10 +
        '           INSERT INTO inv_movement (movementkey, documentkey, goodkey, cardkey, contactkey, movementdate, credit) ' + #13#10 +
        '           VALUES (:movementkey, NEW.documentkey, :goodkey, :id, :fromcontactkey, :documentdate, :quant); ' + #13#10 +
        ' ' + #13#10 +
        '           INSERT INTO inv_movement (movementkey, documentkey, goodkey, cardkey, contactkey, movementdate, debit) ' + #13#10 +
        '           VALUES (:movementkey, NEW.documentkey, :goodkey, :id, :tocontactkey, :documentdate, :quant); ' + #13#10 +
        ' ' + #13#10 +
        '           tmpquantity = tmpquantity - quant; ' + #13#10 +
        '         end ' + #13#10 +
        '         if (tmpquantity > 0 and NEW.checkremains = 0) then ' + #13#10 +
        '         begin ' + #13#10 +
        GetNewCardSQL(Features, '') +
        '           EXECUTE PROCEDURE gd_p_getnextid_ex RETURNING_VALUES :movementkey; ' + #13#10 +
        ' ' + #13#10 +
        '           INSERT INTO inv_movement (movementkey, documentkey, goodkey, cardkey, contactkey, movementdate, credit) ' + #13#10 +
        '           VALUES (:movementkey, NEW.documentkey, :goodkey, :id, :fromcontactkey, :documentdate, :tmpquantity); ' + #13#10 +
        ' ' + #13#10 +
        '           INSERT INTO inv_movement (movementkey, documentkey, goodkey, cardkey, contactkey, movementdate, debit) ' + #13#10 +
        '           VALUES (:movementkey, NEW.documentkey, :goodkey, :id, :tocontactkey, :documentdate, :tmpquantity); ' + #13#10 +
        '         end' + #13#10 +
        '         else ' + #13#10 +
        '         if (tmpquantity > 0) then '  + #13#10 +
        '           EXCEPTION INV_E_INSUFFICIENTBALANCE; ' + #13#10 +
        '        end ' + #13#10 +
        '        else ' + #13#10 +
        '        begin ' + #13#10 +
        '        tmpquantity = OLD.quantity - NEW.quantity; ' + #13#10 +
        '        for ' + #13#10 +
        '          select m.movementkey, SUM(m.debit) ' + #13#10 +
        '          from inv_movement m ' + #13#10 +
        '          where m.documentkey = NEW.documentkey ' + #13#10 +
        '          group by 1 ' + #13#10 +
        '          order by 2 ' + #13#10 +
        '          into :movementkey, :oldquantity ' + #13#10 +
        '        do ' + #13#10 +
        '        begin ' + #13#10 +
        '          if (tmpquantity >= oldquantity) then ' + #13#10 +
        '          begin ' + #13#10 +
        '            delete from inv_movement where movementkey = :movementkey; ' + #13#10 +
        '            tmpquantity = tmpquantity - oldquantity; ' + #13#10 +
        '            when EXCEPTION INV_E_INVALIDMOVEMENT do ' + #13#10 +
        '              EXCEPTION INV_E_DONTREDUCEAMOUNT; ' + #13#10 +
        '          end ' + #13#10 +
        '          else ' + #13#10 +
        '          begin ' + #13#10 +
        '            if (tmpquantity > 0) then ' + #13#10 +
        '            begin ' + #13#10 +
        ' ' + #13#10 +
        '              update inv_movement set debit = debit - :tmpquantity ' + #13#10 +
        '              where movementkey = :movementkey and debit <> 0; ' + #13#10 +
        '              update inv_movement set credit = credit - :tmpquantity ' + #13#10 +
        '              where movementkey = :movementkey and credit <> 0; ' + #13#10 +
        ' ' + #13#10 +
        '              tmpquantity = 0; ' + #13#10 +
        '              when EXCEPTION INV_E_INVALIDMOVEMENT do ' + #13#10 +
        '                EXCEPTION INV_E_DONTREDUCEAMOUNT; ' + #13#10 +
        ' ' + #13#10 +
        '            end ' + #13#10 +
        '          end ' + #13#10 +
        '        end ' + #13#10 +
        '        end' + #13#10 +
        '      end ' + #13#10 +
        '    end ' + #13#10 +
        '  end ' + #13#10
   else
     Result := Result +
          '                                         ' + #13#10 +
          '    rdb$set_context(''USER_TRANSACTION'', ''CONTROLREMAINS'', 0); ' + #13#10 +
          '      if (ischange = 1) then ' + #13#10 +
          '      begin ' + #13#10 + GetMakeUpdateCardSQL(Features, '') + #13#10 +
          '      end ' + #13#10 +
          '    if (delayed = 1) then ' + #13#10 +
          '      DELETE FROM inv_movement WHERE documentkey = NEW.documentkey;' + #13#10 +
          '    else ' + #13#10 +
          '    begin ' + #13#10 +
          '/* ���� �������� �� ���������� ������� �������� */ ' + #13#10 +
          '      if (not exists(select id from inv_movement where documentkey = NEW.documentkey)) then ' + #13#10 +
          '      begin ' + #13#10 +
          '        EXECUTE PROCEDURE gd_p_getnextid_ex RETURNING_VALUES :movementkey; ' + #13#10 +
          ' ' + #13#10 +
          '  /* ��������� �������� � inv_movememt */ ' + #13#10 +
          ' ' + #13#10 +
          '        INSERT INTO inv_movement (movementkey, documentkey, goodkey, cardkey, contactkey, movementdate, credit) ' + #13#10 +
          '        VALUES (:movementkey, NEW.documentkey, :goodkey, NEW.fromcardkey, :fromcontactkey, :documentdate, NEW.quantity); ' + #13#10 +
          ' ' + #13#10 +
          '        INSERT INTO inv_movement (movementkey, documentkey, goodkey, cardkey, contactkey, movementdate, debit) ' + #13#10 +
          '        VALUES (:movementkey, NEW.documentkey, :goodkey, NEW.fromcardkey, :tocontactkey, :documentdate, NEW.quantity); ' + #13#10 +
          '      end ' + #13#10 +
          '      else ' + #13#10 +
          '      begin ' + #13#10 +
          '      if (coalesce(oldfromcontactkey, 0) <> coalesce(fromcontactkey, 0)) then ' + #13#10 +
          '      begin ' + #13#10 +
          '        UPDATE inv_movement SET contactkey = :fromcontactkey ' + #13#10 +
          '        WHERE documentkey = NEW.documentkey and credit <> 0; ' + #13#10 +
          '        when EXCEPTION INV_E_INVALIDMOVEMENT do ' + #13#10 +
          '          exception INV_E_DONTCHANGESOURCE; ' + #13#10 +
          '      end ' + #13#10 +
          '      if (coalesce(oldtocontactkey, 0) <> coalesce(tocontactkey, 0)) then ' + #13#10 +
          '      begin ' + #13#10 +
          '        UPDATE inv_movement SET contactkey = :tocontactkey ' + #13#10 +
          '        WHERE documentkey = NEW.documentkey and debit <> 0; ' + #13#10 +
          '        when EXCEPTION INV_E_INVALIDMOVEMENT do ' + #13#10 +
          '          exception INV_E_DONTCHANGEBENEFICIARY; ' + #13#10 +
          '      end ' + #13#10 +
          '      if (coalesce(NEW.quantity, 0) > coalesce(OLD.quantity, 0)) then ' + #13#10 +
          '      begin ' + #13#10 +
          '        select MAX(movementkey) from inv_movement where documentkey = NEW.DOCUMENTKEY ' + #13#10 +
          '        INTO :movementkey; ' + #13#10 +
          '        tmpquantity = coalesce(NEW.quantity, 0) - coalesce(OLD.quantity, 0); ' + #13#10 +
          '        update inv_movement set debit = debit + :tmpquantity ' + #13#10 +
          '        where movementkey = :movementkey and debit <> 0; ' + #13#10 +
          '        update inv_movement set credit = credit + :tmpquantity ' + #13#10 +
          '        where movementkey = :movementkey and credit <> 0; ' + #13#10 +
          ' ' + #13#10 +
          '      end ' + #13#10 +
          '      else ' + #13#10 +
          '      begin ' + #13#10 +
          '        tmpquantity = OLD.quantity - NEW.quantity; ' + #13#10 +
          '        for ' + #13#10 +
          '          select m.movementkey, SUM(m.debit) ' + #13#10 +
          '          from inv_movement m ' + #13#10 +
          '          where m.documentkey = NEW.documentkey ' + #13#10 +
          '          group by 1 ' + #13#10 +
          '          order by 2 ' + #13#10 +
          '          into :movementkey, :oldquantity ' + #13#10 +
          '        do ' + #13#10 +
          '        begin ' + #13#10 +
          '          if (tmpquantity >= oldquantity) then ' + #13#10 +
          '          begin ' + #13#10 +
          '            delete from inv_movement where movementkey = :movementkey; ' + #13#10 +
          '            tmpquantity = tmpquantity - oldquantity; ' + #13#10 +
          '            when EXCEPTION INV_E_INVALIDMOVEMENT do ' + #13#10 +
          '              EXCEPTION INV_E_DONTREDUCEAMOUNT; ' + #13#10 +
          '          end ' + #13#10 +
          '          else ' + #13#10 +
          '          begin ' + #13#10 +
          '            if (tmpquantity > 0) then ' + #13#10 +
          '            begin ' + #13#10 +
          ' ' + #13#10 +
          '              update inv_movement set debit = debit - :tmpquantity ' + #13#10 +
          '              where movementkey = :movementkey and debit <> 0; ' + #13#10 +
          '              update inv_movement set credit = credit - :tmpquantity ' + #13#10 +
          '              where movementkey = :movementkey and credit <> 0; ' + #13#10 +
          ' ' + #13#10 +
          '              tmpquantity = 0; ' + #13#10 +
          ' ' + #13#10 +
          '              when EXCEPTION INV_E_INVALIDMOVEMENT do ' + #13#10 +
          '                EXCEPTION INV_E_DONTREDUCEAMOUNT; ' + #13#10 +
          '            end ' + #13#10 +
          '          end ' + #13#10 +
          '        end ' + #13#10 +
          '      end ' + #13#10 +
          '      if (olddocumentdate <> documentdate and isdeletemovement = 0) then ' + #13#10 +
          '      begin ' + #13#10 +
          '      if (olddocumentdate > documentdate) then ' + #13#10 + GetUpdateDateSQL +
          '      else ' + #13#10 +
          '      begin ' + #13#10 + GetCheckRemainsOnDateSQL(False) + GetUpdateDateSQL +
          '      end ' + #13#10 +
          '      end ' + #13#10 +
          '    end ' + #13#10 +
          '    end ' + #13#10 +
          '  end ' + #13#10;
   Result := Result + 'end ';
end;



// �������� �������� BeforeInsert ��� ��������� ��������� �������
function CreateInsertTrigger_ChangeFeatureDoc: String;
begin

  Result :=
    FixedVariableList + #13#10 + MakeFieldList(ftSource, '') + MakeFieldList(ftDest, 'n') + ConstTriggerText +
    Format(
          '  if (ruid = ''%0:s'') then ' + #13#10 +
          '  begin ' + #13#10 + GetReadFeatureSQL(ftSource, 'F', True, False, '') +
          GetReadFeatureSQL(ftDest, 'T', True, True, 'n'),
          [FieldByName('ruid').AsString]) +
          GetMovementContactSQL(FIE.GetMovement(emCredit), True) +
          GetMovementContactSQL(FIE.GetMovement(emDebit), False) +
        '    if (delayed = 0 and coalesce(NEW.quantity, 0) <> 0) then ' + #13#10 +
        '    begin ' + #13#10 +
        '      tmpquantity = NEW.quantity; ' + #13#10;
     if not FIE.GetFlag(efWithoutSearchRemains) then
       Result := Result +
          GetChooseRemainsSQL(ftSource) +
          '       begin ' + #13#10 +
          '         if (tmpquantity > remains) then ' + #13#10 +
          '           quant = remains; ' + #13#10 +
          '         else ' + #13#10 +
          '           quant = tmpquantity; ' + #13#10 +
          '         NEW.fromcardkey = :id; ' + #13#10 +
          '         cardkey = :id; ' + #13#10 +
          GetNewCardSQL(ftDest, 'n') +
          '      NEW.tocardkey = :id; ' + #13#10 +
          '         EXECUTE PROCEDURE gd_p_getnextid_ex RETURNING_VALUES :movementkey; ' + #13#10 +
          ' ' + #13#10 +
          '         INSERT INTO inv_movement (movementkey, documentkey, goodkey, cardkey, contactkey, movementdate, credit) ' + #13#10 +
          '         VALUES (:movementkey, NEW.documentkey, :goodkey, NEW.fromcardkey, :fromcontactkey, :documentdate, :quant); ' + #13#10 +
          ' ' + #13#10 +
          '         INSERT INTO inv_movement (movementkey, documentkey, goodkey, cardkey, contactkey, movementdate, debit) ' + #13#10 +
          '         VALUES (:movementkey, NEW.documentkey, :goodkey, NEW.tocardkey, :tocontactkey, :documentdate, :quant); ' + #13#10 +
          ' ' + #13#10 +
          '         tmpquantity = tmpquantity - quant; ' + #13#10 +
          '       end ' + #13#10;
      Result := Result +
        '       if (tmpquantity > 0 and NEW.checkremains = 0) then ' + #13#10 +
        '       begin ' + #13#10 +
        GetNewCardSQL(ftSource, '') +
        '         NEW.fromcardkey = :id; ' + #13#10 +
        '         cardkey = :id; ' + #13#10 +
        '         firstdocumentkey = NEW.documentkey; ' + #13#10 +
        GetNewCardSQL(ftDest, 'n') +
        '         NEW.tocardkey = :id; ' + #13#10 +
        '         EXECUTE PROCEDURE gd_p_getnextid_ex RETURNING_VALUES :movementkey; ' + #13#10 +
        ' ' + #13#10 +
        '         INSERT INTO inv_movement (movementkey, documentkey, goodkey, cardkey, contactkey, movementdate, credit) ' + #13#10 +
        '         VALUES (:movementkey, NEW.documentkey, :goodkey, NEW.fromcardkey, :fromcontactkey, :documentdate, :tmpquantity); ' + #13#10 +
        ' ' + #13#10 +
        '         INSERT INTO inv_movement (movementkey, documentkey, goodkey, cardkey, contactkey, movementdate, debit) ' + #13#10 +
        '         VALUES (:movementkey, NEW.documentkey, :goodkey, NEW.tocardkey, :tocontactkey, :documentdate, :tmpquantity); ' + #13#10 +
        '       end' + #13#10 +
        '       else ' + #13#10 +
        '       if (tmpquantity > 0) then '  + #13#10 +
        '         EXCEPTION INV_E_INSUFFICIENTBALANCE; ' + #13#10 +
        '    end ' + #13#10 +
        '    else ' + #13#10 +
        '    begin ' + #13#10 +
        GetNewCardSQL(ftSource, '') +
        '      NEW.fromcardkey = :id; ' + #13#10 +
        '      cardkey = :id; ' + #13#10 +
        '      firstdocumentkey = NEW.documentkey; ' + #13#10 +
        GetNewCardSQL(ftDest, 'n') +
        '      NEW.tocardkey = :id; ' + #13#10 +
        '    end ' + #13#10 +
        '  end ' + #13#10 +
        'end ';
end;

// �������� �������� BeforeUpdate ��� ��������� ��������� �������
function CreateUpdateTrigger_ChangeFeatureDoc: String;
var
  s : String;
begin
    if FIE.GetFlag(efLiveTimeRemains) then
      s := '        if (isdeletemovement = 0 and olddocumentdate <> documentdate) then ' + #13#10 +
           '        begin ' + #13#10 +
           '        if (olddocumentdate > documentdate) then ' + #13#10 + GetUpdateDateSQL +
           '        else ' + #13#10 +
           '        begin ' + #13#10 + GetCheckRemainsOnDateSQL(False) +  GetUpdateDateSQL +
           '        end ' + #13#10 +
           '        end ' + #13#10

    else
      s := '        if (isdeletemovement = 0 and olddocumentdate <> documentdate) then ' + #13#10 +
           '        begin ' + #13#10 +
           '          if (NEW.checkremains = 1 and olddocumentdate > documentdate) then ' + #13#10 +
           '          begin ' + #13#10 + GetCheckRemainsOnDateSQL(True) +
           '          end ' + #13#10 +
           '          if (olddocumentdate < documentdate) then ' + #13#10 +
           '          begin ' + #13#10 + GetCheckRemainsOnDateSQL(False) +
           '          end ' + #13#10 + GetUpdateDateSQL +
           '        end ' + #13#10;

  Result :=
    FixedVariableList + #13#10 +
    MakeFieldList(ftSource, '') +
    MakeFieldList(ftDest, 'n') +
    MakeFieldList(ftSource, 'o') +
    '  declare variable oldgoodkey DFOREIGNKEY; ' + #13#10 +
    '  declare variable oldfromcontactkey DFOREIGNKEY; ' + #13#10 +
    '  declare variable oldtocontactkey DFOREIGNKEY; ' + #13#10 +
    '  declare variable ischange DBOOLEAN; ' + #13#10 +
    '  declare variable istochange DBOOLEAN; ' + #13#10 +
    '  declare variable oldquantity DQUANTITY; ' + #13#10 +
    '  declare variable sqlstatement VARCHAR(4096); ' + #13#10 +
    '  declare variable changefields VARCHAR(4096); ' + #13#10 +
    '  declare variable dtstring VARCHAR(1024); ' + #13#10 +
    '  declare variable cardstring VARCHAR(1024); ' + #13#10 +
    '  declare variable fieldkey DFOREIGNKEY; ' + #13#10 +
    '  declare variable dockey DFOREIGNKEY; ' + #13#10 +
    '  declare variable badmovekey DFOREIGNKEY; ' + #13#10 +
    MakeFieldList(ftDest, 'to$') + ConstTriggerText +
    Format(
          '  if (ruid = ''%0:s'') then ' + #13#10 +
          '  begin ' + #13#10 +
          GetReadFeatureSQL(ftSource, 'F', True, False, '') +
          GetReadFeatureSQL(ftDest, 'T', True, True, 'n'),
                    [FieldByName('ruid').AsString]) +
          GetReadFeatureSQL(ftSource, 'F', False, False, 'o') +
          GetReadFeatureSQL(ftDest, 'T', False, False, 'to$') +
      GetMovementContactSQL(FIE.GetMovement(emCredit), True) +
      GetMovementContactSQL(FIE.GetMovement(emDebit), False) +
      GetOldMovementContactSQL(FIE.GetMovement(emCredit), True) +
      GetOldMovementContactSQL(FIE.GetMovement(emDebit), False) +
      GetCheckFeaturesSQL(ftSource, '', 'o') +
      GetCheckFeaturesSQL(ftDest, 'n', 'to$') +
      GetOldDocumentDateSQL +
        '    rdb$set_context(''USER_TRANSACTION'', ''CONTROLREMAINS'', NEW.checkremains); ' + #13#10 +
        '    if (delayed = 0 and coalesce(NEW.quantity, 0) <> 0) then ' + #13#10 +
        '    begin ' + #13#10 +
        '      if (not exists(select id from inv_movement where documentkey = NEW.documentkey)) then ' + #13#10 +
        '        isdeletemovement = 1; ' + #13#10 +
        '      if (isdeletemovement = 0 and (ischange = 1 or fromcontactkey <> oldfromcontactkey or coalesce(NEW.quantity, 0) = 0)) then' + #13#10 +
        '      begin ' + #13#10 +
        '        DELETE FROM inv_movement WHERE documentkey = NEW.documentkey; ' + #13#10 +
        '        isdeletemovement = 1; ' + #13#10 +
        '      end ' + #13#10 +
        '      if (isdeletemovement = 1 or ischange = 1 or coalesce(NEW.quantity, 0) > coalesce(OLD.quantity, 0) or fromcontactkey <> oldfromcontactkey) then ' + #13#10 +
        '      begin ' + #13#10 +
        '        if (isdeletemovement = 0 and tocontactkey <> oldtocontactkey) then ' + #13#10 +
        '        begin ' + #13#10 +
        '          UPDATE inv_movement SET contactkey = :tocontactkey WHERE documentkey = NEW.documentkey and debit <> 0; ' + #13#10 +
        '          when EXCEPTION INV_E_INVALIDMOVEMENT do ' + #13#10 +
        '            exception INV_E_DONTCHANGEBENEFICIARY; ' + #13#10 +
        '        end ' + #13#10 +
        '        if (ischange = 1 or isdeletemovement = 1) then ' + #13#10 +
        '          tmpquantity = NEW.quantity; ' + #13#10 +
        '        else ' + #13#10 +
        '          tmpquantity = coalesce(NEW.quantity, 0) - coalesce(OLD.quantity, 0); ' + #13#10;
      if not FIE.GetFlag(efWithoutSearchRemains) then
        Result := Result +
          GetChooseRemainsSQL(ftSource) +
          '        begin ' + #13#10 +
          '           if (tmpquantity > remains) then ' + #13#10 +
          '             quant = remains; ' + #13#10 +
          '           else ' + #13#10 +
          '             quant = tmpquantity; ' + #13#10 +
          '           NEW.fromcardkey = :id; ' + #13#10 +
          '           cardkey = :id; ' + #13#10 +
          GetNewCardSQL(ftDest, 'n') +
          '           NEW.tocardkey = :id; ' + #13#10 +
          '           EXECUTE PROCEDURE gd_p_getnextid_ex RETURNING_VALUES :movementkey; ' + #13#10 +
          ' ' + #13#10 +
          '           INSERT INTO inv_movement (movementkey, documentkey, goodkey, cardkey, contactkey, movementdate, credit) ' + #13#10 +
          '           VALUES (:movementkey, NEW.documentkey, :goodkey, NEW.fromcardkey, :fromcontactkey, :documentdate, :quant); ' + #13#10 +
          ' ' + #13#10 +
          '           INSERT INTO inv_movement (movementkey, documentkey, goodkey, cardkey, contactkey, movementdate, debit) ' + #13#10 +
          '           VALUES (:movementkey, NEW.documentkey, :goodkey, NEW.tocardkey, :tocontactkey, :documentdate, :quant); ' + #13#10 +
          ' ' + #13#10 +
          '           tmpquantity = tmpquantity - quant; ' + #13#10 +
          '         end ' + #13#10;
      Result := Result +
        '         if (tmpquantity > 0 and NEW.checkremains = 0) then ' + #13#10 +
        '         begin ' + #13#10 +
        GetNewCardSQL(ftSource, '') +
        '           NEW.fromcardkey = :id; ' + #13#10 +
        '           cardkey = :id; ' + #13#10 +
        '           firstdocumentkey = NEW.documentkey; ' + #13#10 +
        GetNewCardSQL(ftDest, 'n') +
        '           NEW.tocardkey = :id; ' + #13#10 +
        '           EXECUTE PROCEDURE gd_p_getnextid_ex RETURNING_VALUES :movementkey; ' + #13#10 +
        ' ' + #13#10 +
        '           INSERT INTO inv_movement (movementkey, documentkey, goodkey, cardkey, contactkey, movementdate, credit) ' + #13#10 +
        '           VALUES (:movementkey, NEW.documentkey, :goodkey, NEW.fromcardkey, :fromcontactkey, :documentdate, :tmpquantity); ' + #13#10 +
        ' ' + #13#10 +
        '           INSERT INTO inv_movement (movementkey, documentkey, goodkey, cardkey, contactkey, movementdate, debit) ' + #13#10 +
        '           VALUES (:movementkey, NEW.documentkey, :goodkey, NEW.tocardkey, :tocontactkey, :documentdate, :tmpquantity); ' + #13#10 +
        '         end' + #13#10 +
        '         else ' + #13#10 +
        '         if (tmpquantity > 0) then '  + #13#10 +
        '           EXCEPTION INV_E_INSUFFICIENTBALANCE; ' + #13#10 +
        '       end ' + #13#10 +
        '       else ' + #13#10 +
        '         if (coalesce(NEW.quantity, 0) < coalesce(OLD.quantity, 0)) then ' + #13#10 +
        '         begin ' + #13#10 +
        '           if (tocontactkey <> oldtocontactkey) then ' + #13#10 +
        '           begin ' + #13#10 +
        '             UPDATE inv_movement SET contactkey = :tocontactkey WHERE documentkey = NEW.documentkey and debit <> 0; ' + #13#10 +
        '             when EXCEPTION INV_E_INVALIDMOVEMENT do ' + #13#10 +
        '               exception INV_E_DONTCHANGEBENEFICIARY; ' + #13#10 +
        '           end ' + #13#10 +
        '           tmpquantity = OLD.quantity - NEW.quantity; ' + #13#10 +
        '           for ' + #13#10 +
        '             select m.movementkey, SUM(m.debit) ' + #13#10 +
        '             from inv_movement m ' + #13#10 +
        '             where m.documentkey = NEW.documentkey ' + #13#10 +
        '             group by 1 ' + #13#10 +
        '             order by 2 ' + #13#10 +
        '             into :movementkey, :oldquantity ' + #13#10 +
        '           do ' + #13#10 +
        '           begin ' + #13#10 +
        '             if (tmpquantity >= oldquantity) then ' + #13#10 +
        '             begin ' + #13#10 +
        '               delete from inv_movement where movementkey = :movementkey; ' + #13#10 +
        '               tmpquantity = tmpquantity - oldquantity; ' + #13#10 +
        '               when EXCEPTION INV_E_INVALIDMOVEMENT do ' + #13#10 +
        '                 EXCEPTION INV_E_DONTREDUCEAMOUNT; ' + #13#10 +
        '             end ' + #13#10 +
        '             else ' + #13#10 +
        '             begin ' + #13#10 +
        '               if (tmpquantity > 0) then ' + #13#10 +
        '               begin ' + #13#10 +
        ' ' + #13#10 +
        '                 update inv_movement set debit = debit - :tmpquantity ' + #13#10 +
        '                 where movementkey = :movementkey and debit <> 0; ' + #13#10 +
        '                 update inv_movement set credit = credit - :tmpquantity ' + #13#10 +
        '                 where movementkey = :movementkey and credit <> 0; ' + #13#10 +
        ' ' + #13#10 +
        '                 tmpquantity = 0; ' + #13#10 +
        ' ' + #13#10 +
        '                 when EXCEPTION INV_E_INVALIDMOVEMENT do ' + #13#10 +
        '                   EXCEPTION INV_E_DONTREDUCEAMOUNT; ' + #13#10 +
        '               end ' + #13#10 +
        '             end ' + #13#10 +
        '           end ' + #13#10 +
        '         end ' + #13#10 + S +
        '      if (istochange = 1 and ischange = 0 and fromcontactkey = oldfromcontactkey) then ' + #13#10 +
        '      begin ' + #13#10 + GetMakeUpdateCardSQL(ftDest, 'n') +
        '      end ' + #13#10 +
        '    end ' + #13#10 +
        '    else ' + #13#10 +
        '    begin ' + #13#10 +
        '      DELETE FROM inv_movement WHERE documentkey = NEW.documentkey; ' + #13#10 +
        GetNewCardSQL(ftSource, '') +
        '      NEW.fromcardkey = :id; ' + #13#10 +
        '      cardkey = :id; ' + #13#10 +
        '      firstdocumentkey = NEW.documentkey; ' + #13#10 +
        GetNewCardSQL(ftDest, 'n') +
        '      NEW.tocardkey = :id; ' + #13#10 +
        '    end ' + #13#10 +
        '  end ' + #13#10 +
        'end ';
end;

// �������� �������� BeforeInsert ��� ��������� ��������������
function CreateInsertTrigger_InventDoc: String;
var
  Features: TgdInvDocumentEntryFeature;
begin

  Features := ftSource;

  Result :=
    FixedVariableList + #13#10 + MakeFieldList(Features, '') + MakeFieldList(Features, 'o') +
    ' declare variable oldgoodkey DFOREIGNKEY; ' + #13#10 +
    ' declare variable ischange dboolean; ' + #13#10 + ConstTriggerText +
    Format(
          '  if (ruid = ''%0:s'') then ' + #13#10 +
          '  begin ' + #13#10 +
               GetReadFeatureSQL(Features, 'F', True, False, ''),
          [FieldByName('ruid').AsString]) +
          GetMovementContactSQL(FIE.GetMovement(emCredit), True) +
        '    tocontactkey = fromcontactkey; ' + #13#10 +
        '    if (coalesce(NEW.fromquantity, 0) > coalesce(NEW.toquantity, 0)) then ' + #13#10 +
        '    begin ' + #13#10 +
        '    if (delayed = 0) then ' + #13#10 +
        '    begin ' + #13#10 +
        '      tmpquantity = coalesce(NEW.fromquantity, 0) - coalesce(NEW.toquantity, 0); ' + #13#10 +
        GetChooseRemainsSQL(Features) +
        '       begin ' + #13#10 +
        '         if (tmpquantity > remains) then ' + #13#10 +
        '           quant = remains; ' + #13#10 +
        '         else ' + #13#10 +
        '           quant = tmpquantity; ' + #13#10 +
        '         NEW.fromcardkey = :id; ' + #13#10 +
        '         EXECUTE PROCEDURE gd_p_getnextid_ex RETURNING_VALUES :movementkey; ' + #13#10 +
        ' ' + #13#10 +
        '         INSERT INTO inv_movement (movementkey, documentkey, goodkey, cardkey, contactkey, movementdate, credit) ' + #13#10 +
        '         VALUES (:movementkey, NEW.documentkey, :goodkey, :id, :fromcontactkey, :documentdate, :quant); ' + #13#10 +
        ' ' + #13#10 +
        '         tmpquantity = tmpquantity - quant; ' + #13#10 +
        '       end ' + #13#10 +
        '       if (tmpquantity > 0 and NEW.checkremains = 0) then ' + #13#10 +
        '       begin ' + #13#10 +
        GetNewCardSQL(Features, '') +
        '         EXECUTE PROCEDURE gd_p_getnextid_ex RETURNING_VALUES :movementkey; ' + #13#10 +
        ' ' + #13#10 +
        '         INSERT INTO inv_movement (movementkey, documentkey, goodkey, cardkey, contactkey, movementdate, credit) ' + #13#10 +
        '         VALUES (:movementkey, NEW.documentkey, :goodkey, :id, :fromcontactkey, :documentdate, :tmpquantity); ' + #13#10 +
        '       end' + #13#10 +
        '       else ' + #13#10 +
        '       if (tmpquantity > 0) then '  + #13#10 +
        '         EXCEPTION INV_E_INSUFFICIENTBALANCE; ' + #13#10 +
        '    end ' + #13#10 +
        '    else ' + #13#10 +
        '    begin ' + #13#10 +
        GetNewCardSQL(Features, '') +
        '      NEW.fromcardkey = :id; ' + #13#10 +
        '    end ' + #13#10 +
        '    end ' + #13#10 +
        '    else                                   ' + #13#10 +
        '    begin ' + #13#10 +
        '      if (NEW.fromcardkey is NULL) then ' + #13#10 +
        '      begin ' + #13#10 +
        '   ' + #13#10 + GetNewCardSQL(Features, '') +
        '/* ����������� �� � fromcardkey ��������� */ ' + #13#10 +
        '        NEW.fromcardkey = :id; ' + #13#10 +
        '      end ' + #13#10 +
        '      else '  + #13#10 +
        '      begin '  + #13#10 + GetReadFeatureSQL(Features, 'N', False, False, 'o') +
             GetCheckFeaturesSQL(Features, '', 'o') +
        '        if (ischange = 1) then ' + #13#10 +
        '        begin ' + #13#10 +
        '   ' + #13#10 + GetNewCardSQL(Features, '') +
        '/* ����������� �� � fromcardkey ��������� */ ' + #13#10 +
        '          NEW.fromcardkey = :id; ' + #13#10 +
        '        end ' + #13#10 +
        '      end '  + #13#10 +
        ' ' + #13#10 +
        '    if (delayed = 0 and coalesce(NEW.toquantity, 0) - coalesce(NEW.fromquantity, 0) <> 0) then ' + #13#10 +
        '    begin ' + #13#10 +
        '/* ���� �������� �� ���������� ������� �������� */ ' + #13#10 +
        '/* �� ����� ��������� ������� �������� ������ � ���� */ ' + #13#10 +
        '      EXECUTE PROCEDURE gd_p_getnextid_ex RETURNING_VALUES :movementkey; ' + #13#10 +
        ' ' + #13#10 +
        '  /* ��������� �������� � inv_movememt */ ' + #13#10 +
        ' ' + #13#10 +
        '      INSERT INTO inv_movement (movementkey, documentkey, goodkey, cardkey, contactkey, movementdate, debit) ' + #13#10 +
        '      VALUES (:movementkey, NEW.documentkey, :goodkey, NEW.fromcardkey, :tocontactkey, :documentdate, coalesce(NEW.toquantity, 0) - coalesce(NEW.fromquantity, 0)); ' + #13#10 +
        '    end ' + #13#10 +
        '    end ' + #13#10 +
        '  end ' + #13#10 +
        'end ';
end;


// �������� �������� BeforeUpdate ��� ��������� ��������������
function CreateUpdateTrigger_InventDoc: String;
var
  Features: TgdInvDocumentEntryFeature;
begin

  Features := ftSource;

  Result :=
    FixedVariableList + #13#10 + MakeFieldList(Features, '') + MakeFieldList(Features, 'o') +
    '  declare variable oldgoodkey DFOREIGNKEY; ' + #13#10 +
    '  declare variable oldfromcontactkey DFOREIGNKEY; ' + #13#10 +
    '  declare variable oldtocontactkey DFOREIGNKEY; ' + #13#10 +
    '  declare variable oldquantity numeric(15, 4); ' + #13#10 +
    '  declare variable ischange dboolean; ' + #13#10 + ConstTriggerText +
    Format(
          '  if (ruid = ''%0:s'') then ' + #13#10 +
          '  begin ' + #13#10 +
               GetReadFeatureSQL(Features, 'F', True, False, ''),
          [FieldByName('ruid').AsString]) +
          GetMovementContactSQL(FIE.GetMovement(emCredit), True) +
          GetOldMovementContactSQL(FIE.GetMovement(emCredit), True) +
          GetReadFeatureSQL(Features, 'F', False, False, 'o') +
             GetCheckFeaturesSQL(Features, '', 'o') +
             GetOldDocumentDateSQL +
        '    tocontactkey = fromcontactkey; ' + #13#10 +
        '    oldtocontactkey = oldfromcontactkey; ' + #13#10 +
        '    quant = coalesce(NEW.fromquantity, 0) - coalesce(NEW.toquantity, 0); ' + #13#10 +
        '    oldquantity = coalesce(OLD.fromquantity, 0) - coalesce(OLD.toquantity, 0); ' + #13#10 +
        '    if (ischange = 1 or oldfromcontactkey <> fromcontactkey or quant * oldquantity < 0 or delayed = 1 or not EXISTS(select id from inv_movement where documentkey = NEW.documentkey)) then ' + #13#10 +
        '    begin ' + #13#10 +
        '      DELETE FROM inv_movement WHERE documentkey = NEW.documentkey; ' + #13#10 +
        '      if (coalesce(NEW.fromquantity, 0) > coalesce(NEW.toquantity, 0)) then ' + #13#10 +
        '      begin ' + #13#10 +
        '        if (delayed = 0) then ' + #13#10 +
        '        begin ' + #13#10 +
        '          tmpquantity = coalesce(NEW.fromquantity, 0) - coalesce(NEW.toquantity, 0); ' + #13#10 +
        GetChooseRemainsSQL(Features) +
        '          begin ' + #13#10 +
        '            if (tmpquantity > remains) then ' + #13#10 +
        '              quant = remains; ' + #13#10 +
        '            else ' + #13#10 +
        '              quant = tmpquantity; ' + #13#10 +
        '            NEW.fromcardkey = :id; ' + #13#10 +
        '            EXECUTE PROCEDURE gd_p_getnextid_ex RETURNING_VALUES :movementkey; ' + #13#10 +
        ' ' + #13#10 +
        '            INSERT INTO inv_movement (movementkey, documentkey, goodkey, cardkey, contactkey, movementdate, credit) ' + #13#10 +
        '            VALUES (:movementkey, NEW.documentkey, :goodkey, :id, :fromcontactkey, :documentdate, :quant); ' + #13#10 +
        ' ' + #13#10 +
        '            tmpquantity = tmpquantity - quant; ' + #13#10 +
        '          end ' + #13#10 +
        '          if (tmpquantity > 0 and NEW.checkremains = 0) then ' + #13#10 +
        '          begin ' + #13#10 +
        GetNewCardSQL(Features, '') +
        '            EXECUTE PROCEDURE gd_p_getnextid_ex RETURNING_VALUES :movementkey; ' + #13#10 +
        ' ' + #13#10 +
        '            INSERT INTO inv_movement (movementkey, documentkey, goodkey, cardkey, contactkey, movementdate, credit) ' + #13#10 +
        '            VALUES (:movementkey, NEW.documentkey, :goodkey, :id, :fromcontactkey, :documentdate, :tmpquantity); ' + #13#10 +
        '          end' + #13#10 +
        '          else ' + #13#10 +
        '            if (tmpquantity > 0) then '  + #13#10 +
        '              EXCEPTION INV_E_INSUFFICIENTBALANCE; ' + #13#10 +
        '       end ' + #13#10 +
        '       else ' + #13#10 +
        '       begin ' + #13#10 +
        '         if (ischange = 1 or NEW.fromcardkey is null) then ' + #13#10 +
        '         begin ' + #13#10 +
        GetNewCardSQL(Features, '') +
        '         NEW.fromcardkey = :id; ' + #13#10 +
        '         end ' + #13#10 +
        '       end ' + #13#10 +
        '      end ' + #13#10 +
        '      else                                   ' + #13#10 +
        '      begin ' + #13#10 +
        '        if (NEW.fromcardkey is NULL) then ' + #13#10 +
        '        begin ' + #13#10 +
        '      ' + #13#10 + GetNewCardSQL(Features, '') +
        '/* ����������� �� � fromcardkey ��������� */ ' + #13#10 +
        '           NEW.fromcardkey = :id; ' + #13#10 +
        '        end ' + #13#10 +
        '        else '  + #13#10 +
        '        begin '  + #13#10 +
        '          if (ischange = 1) then ' + #13#10 +
        '          begin ' + #13#10 +
        '   ' + #13#10 + GetNewCardSQL(Features, '') +
        '/* ����������� �� � fromcardkey ��������� */ ' + #13#10 +
        '            NEW.fromcardkey = :id; ' + #13#10 +
        '          end ' + #13#10 +
        '        end '  + #13#10 +
        ' ' + #13#10 +
        '        if (delayed = 0 and coalesce(NEW.toquantity, 0) - coalesce(NEW.fromquantity, 0) <> 0) then ' + #13#10 +
        '        begin ' + #13#10 +
        '/* ���� �������� �� ���������� ������� �������� */ ' + #13#10 +
        '/* �� ����� ��������� ������� �������� ������ � ���� */ ' + #13#10 +
        '          EXECUTE PROCEDURE gd_p_getnextid_ex RETURNING_VALUES :movementkey; ' + #13#10 +
        ' ' + #13#10 +
        '  /* ��������� �������� � inv_movememt */ ' + #13#10 +
        ' ' + #13#10 +
        '          INSERT INTO inv_movement (movementkey, documentkey, goodkey, cardkey, contactkey, movementdate, debit) ' + #13#10 +
        '          VALUES (:movementkey, NEW.documentkey, :goodkey, NEW.fromcardkey, :tocontactkey, :documentdate, coalesce(NEW.toquantity, 0) - coalesce(NEW.fromquantity, 0)); ' + #13#10 +
        '        end ' + #13#10 +
        '      end ' + #13#10 +
        '    end ' + #13#10 +
        '    else ' + #13#10 +
        '    begin  ' + #13#10 +
        '      if (coalesce(NEW.fromquantity, 0) > coalesce(NEW.toquantity, 0)) then ' + #13#10 +
        '      begin ' + #13#10 +
        '         ' + #13#10 +
        '        oldquantity = (coalesce(NEW.fromquantity, 0) - coalesce(NEW.toquantity, 0)) - (coalesce(OLD.fromquantity, 0) - coalesce(OLD.toquantity, 0)); ' + #13#10 +
        '        if (oldquantity > 0) then ' + #13#10 +
        '        begin ' + #13#10 +
        '          tmpquantity = oldquantity; ' + #13#10 +
        GetChooseRemainsSQL(Features) +
        '          begin ' + #13#10 +
        '            if (tmpquantity > remains) then ' + #13#10 +
        '              quant = remains; ' + #13#10 +
        '            else ' + #13#10 +
        '              quant = tmpquantity; ' + #13#10 +
        '            NEW.fromcardkey = :id; ' + #13#10 +
        '            EXECUTE PROCEDURE gd_p_getnextid_ex RETURNING_VALUES :movementkey; ' + #13#10 +
        ' ' + #13#10 +
        '            INSERT INTO inv_movement (movementkey, documentkey, goodkey, cardkey, contactkey, movementdate, credit) ' + #13#10 +
        '            VALUES (:movementkey, NEW.documentkey, :goodkey, :id, :fromcontactkey, :documentdate, :quant); ' + #13#10 +
        ' ' + #13#10 +
        '            tmpquantity = tmpquantity - quant; ' + #13#10 +
        '          end ' + #13#10 +
        '          if (tmpquantity > 0 and NEW.checkremains = 0) then ' + #13#10 +
        '          begin ' + #13#10 +
        GetNewCardSQL(Features, '') +
        '            EXECUTE PROCEDURE gd_p_getnextid_ex RETURNING_VALUES :movementkey; ' + #13#10 +
        ' ' + #13#10 +
        '            INSERT INTO inv_movement (movementkey, documentkey, goodkey, cardkey, contactkey, movementdate, credit) ' + #13#10 +
        '            VALUES (:movementkey, NEW.documentkey, :goodkey, :id, :fromcontactkey, :documentdate, :tmpquantity); ' + #13#10 +
        '          end' + #13#10 +
        '          else ' + #13#10 +
        '            if (tmpquantity > 0) then '  + #13#10 +
        '              EXCEPTION INV_E_INSUFFICIENTBALANCE; ' + #13#10 +
        '        end ' + #13#10 +
        '        else ' + #13#10 +
        '        begin ' + #13#10 +
        '           rdb$set_context(''USER_TRANSACTION'', ''CONTROLREMAINS'', NEW.checkremains); ' + #13#10 +
        '           tmpquantity = abs(oldquantity); ' + #13#10 +
        '           for ' + #13#10 +
        '             select m.movementkey, SUM(m.credit) ' + #13#10 +
        '             from inv_movement m ' + #13#10 +
        '             where m.documentkey = NEW.documentkey ' + #13#10 +
        '             group by 1 ' + #13#10 +
        '             order by 2 ' + #13#10 +
        '             into :movementkey, :oldquantity ' + #13#10 +
        '           do ' + #13#10 +
        '           begin ' + #13#10 +
        '             if (tmpquantity >= oldquantity) then ' + #13#10 +
        '             begin ' + #13#10 +
        '               delete from inv_movement where movementkey = :movementkey; ' + #13#10 +
        '               tmpquantity = tmpquantity - oldquantity; ' + #13#10 +
        '               when EXCEPTION INV_E_INVALIDMOVEMENT do ' + #13#10 +
        '                 EXCEPTION INV_E_DONTREDUCEAMOUNT; ' + #13#10 +
        '             end ' + #13#10 +
        '             else ' + #13#10 +
        '             begin ' + #13#10 +
        '               if (tmpquantity > 0) then ' + #13#10 +
        '               begin ' + #13#10 +
        ' ' + #13#10 +
        '                 update inv_movement set credit = credit - :tmpquantity ' + #13#10 +
        '                 where movementkey = :movementkey and credit <> 0; ' + #13#10 +
        ' ' + #13#10 +
        '                 tmpquantity = 0; ' + #13#10 +
        ' ' + #13#10 +
        '               end ' + #13#10 +
        '             end ' + #13#10 +
        '           end ' + #13#10 +
        '        end ' + #13#10 +
        '      end  ' + #13#10 +
        '      else  ' + #13#10 +
        '      begin   ' + #13#10 +
        '        oldquantity = (coalesce(NEW.toquantity, 0) - coalesce(NEW.fromquantity, 0)) - (coalesce(OLD.toquantity, 0) - coalesce(OLD.fromquantity, 0)); ' + #13#10 +
        '        UPDATE inv_movement SET debit = debit + :oldquantity ' + #13#10 +
        '        WHERE documentkey = NEW.documentkey; ' + #13#10 +
        '      end   ' + #13#10 +
        '      if (olddocumentdate <> documentdate) then ' + #13#10 +
        '      begin ' + #13#10 +
        '          if (NEW.checkremains = 1 and olddocumentdate > documentdate and NEW.fromquantity > NEW.toquantity) then ' + #13#10 +
        '          begin ' + #13#10 + GetCheckRemainsOnDateSQL(True) +
        '          end ' + #13#10 +
        '          if (olddocumentdate < documentdate and NEW.fromquantity < NEW.toquantity) then ' + #13#10 +
        '          begin ' + #13#10 + GetCheckRemainsOnDateSQL(False) +
        '          end ' + #13#10 + GetUpdateDateSQL +
        '      end ' + #13#10 +
        '    end ' + #13#10 +
        '  end ' + #13#10 +
        'end ';
end;

// �������� �������� BeforeInsert ��� ��������� �������������
function CreateInsertTrigger_TransformationDoc: String;
begin

  Result :=
    FixedVariableList + #13#10 + MakeFieldList(ftSource, '') + MakeFieldList(ftDest, 'n') + ConstTriggerText +
    Format(
          '  if (ruid = ''%0:s'') then ' + #13#10 +
          '  begin ' + #13#10 +
          '    if (NEW.viewmovementpart = ''I'') then ' + #13#10 +
          '    begin ' + #13#10 +
                 GetReadFeatureSQL(ftSource, 'F', True, False, '') +
          '    end ' + #13#10 +
          '    else '  + #13#10 +
          '    begin '  + #13#10 +
                 GetReadFeatureSQL(ftDest, 'T', True, False, 'n') +
          '    end ' + #13#10,
          [FieldByName('ruid').AsString]) +
          GetMovementContactSQL(FIE.GetMovement(emCredit), True) +
          GetMovementContactSQL(FIE.GetMovement(emDebit), False) +
          '    if (delayed = 0 and (coalesce(NEW.inquantity, 0) <> 0 or coalesce(NEW.outquantity, 0) <> 0)) then ' + #13#10 +
          '    begin ' + #13#10 +
          '      if (NEW.viewmovementpart = ''I'') then ' + #13#10 +
          '      begin ' + #13#10 +
          '        firstdocumentkey = NEW.documentkey; ' + #13#10 +
          ' ' + #13#10 + GetNewCardSQL(ftDest, 'n') +
          '/* ����������� �� � fromcardkey ��������� */ ' + #13#10 +
          '    NEW.fromcardkey = :id; ' + #13#10 +
          '        EXECUTE PROCEDURE gd_p_getnextid_ex RETURNING_VALUES :movementkey; ' + #13#10 +
          ' ' + #13#10 +
          '  /* ��������� �������� � inv_movememt */ ' + #13#10 +
          ' ' + #13#10 +
          '        INSERT INTO inv_movement (movementkey, documentkey, goodkey, cardkey, contactkey, movementdate, debit) ' + #13#10 +
          '        VALUES (:movementkey, NEW.documentkey, :goodkey, :id, :tocontactkey, :documentdate, NEW.inquantity); ' + #13#10 +
          '      end  ' + #13#10 +
          '      else ' + #13#10 +
          '      begin ' + #13#10 +
          '      tmpquantity = coalesce(NEW.outquantity, 0); ' + #13#10 +
          GetChooseRemainsSQL(ftSource) +
          '       begin ' + #13#10 +
          '         if (tmpquantity > remains) then ' + #13#10 +
          '           quant = remains; ' + #13#10 +
          '         else ' + #13#10 +
          '           quant = tmpquantity; ' + #13#10 +
          '         NEW.fromcardkey = :id; ' + #13#10 +
          '         EXECUTE PROCEDURE gd_p_getnextid_ex RETURNING_VALUES :movementkey; ' + #13#10 +
          ' ' + #13#10 +
          '         INSERT INTO inv_movement (movementkey, documentkey, goodkey, cardkey, contactkey, movementdate, credit) ' + #13#10 +
          '         VALUES (:movementkey, NEW.documentkey, :goodkey, :id, :fromcontactkey, :documentdate, :quant); ' + #13#10 +
          ' ' + #13#10 +
          '         tmpquantity = tmpquantity - quant; ' + #13#10 +
          '       end ' + #13#10 +
          '       if (tmpquantity > 0 and NEW.checkremains = 0) then ' + #13#10 +
          '       begin ' + #13#10 +
          GetNewCardSQL(ftSource, '') +
          '         EXECUTE PROCEDURE gd_p_getnextid_ex RETURNING_VALUES :movementkey; ' + #13#10 +
          ' ' + #13#10 +
          '         INSERT INTO inv_movement (movementkey, documentkey, goodkey, cardkey, contactkey, movementdate, credit) ' + #13#10 +
          '         VALUES (:movementkey, NEW.documentkey, :goodkey, :id, :fromcontactkey, :documentdate, :tmpquantity); ' + #13#10 +
          '       end' + #13#10 +
          '       else ' + #13#10 +
          '       if (tmpquantity > 0) then '  + #13#10 +
          '         EXCEPTION INV_E_INSUFFICIENTBALANCE; ' + #13#10 +
          '      end ' + #13#10 +
          '    end ' + #13#10 +
          '    else  ' + #13#10 +
          '  /* ���� �������� ���������� �� �� ��������� �������� */  ' + #13#10 +
          '    begin ' + #13#10 +
          '      if (NEW.viewmovementpart = ''E'') then ' + #13#10 +
          '      begin ' + #13#10 +
                 GetNewCardSQL(ftSource, '') + #13#10 +
          '      end ' + #13#10 +
          '      else ' + #13#10 +
          '      begin ' + #13#10 +
          '        firstdocumentkey = NEW.documentkey; ' + #13#10 +
          GetNewCardSQL(ftDest, 'n') + #13#10 +
          '      end ' + #13#10 +
          '      NEW.fromcardkey = :id; '  + #13#10 +
          '    end ' + #13#10 +
          '  end ' + #13#10 +
          'end  ' + #13#10;
end;

// �������� �������� BeforeUpdate ��� ��������� �������������
function CreateUpdateTrigger_TransformationDoc: String;
begin

  Result :=
    FixedVariableList + #13#10 +
    MakeFieldList(ftSource, '') +
    MakeFieldList(ftDest, 'n') +
    MakeFieldList(ftSource, 'o') +
    '  declare variable oldgoodkey DFOREIGNKEY; ' + #13#10 +
    '  declare variable oldfromcontactkey DFOREIGNKEY; ' + #13#10 +
    '  declare variable oldtocontactkey DFOREIGNKEY; ' + #13#10 +
    '  declare variable ischange DBOOLEAN; ' + #13#10 +
    '  declare variable istochange DBOOLEAN; ' + #13#10 +
    '  declare variable oldquantity DQUANTITY; ' + #13#10 +
    '  declare variable sqlstatement VARCHAR(4096); ' + #13#10 +
    '  declare variable changefields VARCHAR(4096); ' + #13#10 +
    '  declare variable dtstring VARCHAR(1024); ' + #13#10 +
    '  declare variable cardstring VARCHAR(1024); ' + #13#10 +
    '  declare variable fieldkey DFOREIGNKEY; ' + #13#10 +
    '  declare variable dockey DFOREIGNKEY; ' + #13#10 +
    '  declare variable badmovekey DFOREIGNKEY; ' + #13#10 +
    MakeFieldList(ftDest, 'to$') + ConstTriggerText +
    Format(
          '  if (ruid = ''%0:s'') then ' + #13#10 +
          '  begin ' + #13#10 +
          '    if (coalesce(NEW.outquantity, 0) <> 0 or coalesce(OLD.outquantity, 0) <> 0) then ' + #13#10 +
          '    begin '  + #13#10 +
               GetReadFeatureSQL(ftSource, 'F', True, False, '') +
               GetReadFeatureSQL(ftSource, 'F', False, False, 'o') +
          '    end '  + #13#10 +
          '    else '  + #13#10 +
          '    begin '  + #13#10 +
               GetReadFeatureSQL(ftDest, 'T', True, False, 'n') +
               GetReadFeatureSQL(ftDest, 'T', False, False, 'to$') +
          '    end ' + #13#10,
          [FieldByName('ruid').AsString]) +
      GetMovementContactSQL(FIE.GetMovement(emCredit), True) +
      GetMovementContactSQL(FIE.GetMovement(emDebit), False) +
      GetOldMovementContactSQL(FIE.GetMovement(emCredit), True) +
      GetOldMovementContactSQL(FIE.GetMovement(emDebit), False) +
      GetCheckFeaturesSQL(ftSource, '', 'o') +
      GetCheckFeaturesSQL(ftDest, 'n', 'to$') +
      GetOldDocumentDateSQL +
        '    if (NEW.viewmovementpart = ''I'') then ' + #13#10 +
        '    begin '  + #13#10 +
        '      if (delayed = 1) then '  + #13#10 +
        '        DELETE FROM inv_movement WHERE documentkey = NEW.documentkey; '  + #13#10 +
        '    end '  + #13#10 +
        '    else '  + #13#10 +
        '      if (delayed = 1 or fromcontactkey <> oldfromcontactkey or ischange = 1) then '  + #13#10 +
        '      begin ' + #13#10 +
        '        DELETE FROM inv_movement WHERE documentkey = NEW.documentkey; '  + #13#10 +
        '        isdeletemovement = 1; ' + #13#10 +
        '      end ' + #13#10 +
        '    if (delayed = 0 and (coalesce(NEW.inquantity, 0) <> 0 or coalesce(NEW.outquantity, 0) <> 0)) then ' + #13#10 +
        '    begin ' + #13#10 +
        '      if (NEW.viewmovementpart = ''I'') then ' + #13#10 +
        '      begin ' + #13#10 +
        '        if (delayed = 0) then ' + #13#10 +
        '        begin ' + #13#10 +
        '          UPDATE inv_movement SET debit = NEW.inquantity, contactkey = :tocontactkey WHERE documentkey = NEW.documentkey; '  + #13#10 +
        '          when EXCEPTION INV_E_INVALIDMOVEMENT do ' + #13#10 +
        '            exception INV_E_DONTCHANGEBENEFICIARY; ' + #13#10 +
        '        end ' + #13#10 +
        '        if (istochange = 1) then '  + #13#10 +
        '        begin '   + #13#10 +
        GetMakeUpdateCardSQL(ftDest, 'n') + #13#10 +
        '        end '   + #13#10 +
        '        if (isdeletemovement = 0 and olddocumentdate <> documentdate) then ' + #13#10 +
        '        begin ' + #13#10 +
        '          if (olddocumentdate < documentdate) then ' + #13#10 +
        '          begin ' + #13#10 + GetCheckRemainsOnDateSQL(False) +
        '          end ' + #13#10 + GetUpdateDateSQL +
        '        end ' + #13#10 +
        '      end ' + #13#10 +
        '      else ' + #13#10 +
        '      begin ' + #13#10 +
        '        if (delayed = 0 and (coalesce(NEW.inquantity, 0) <> 0 or coalesce(NEW.outquantity, 0) <> 0)) then ' + #13#10 +
        '        begin ' + #13#10 +
        '        rdb$set_context(''USER_TRANSACTION'', ''CONTROLREMAINS'', NEW.checkremains); ' + #13#10 +
        '        if (isdeletemovement = 1) then ' + #13#10 +
        '          oldquantity = NEW.outquantity;' + #13#10 +
        '        else '  + #13#10 +
        '          oldquantity = (coalesce(NEW.outquantity, 0) - coalesce(OLD.outquantity, 0)); ' + #13#10 +
        '        if (oldquantity > 0) then ' + #13#10 +
        '        begin ' + #13#10 +
        '          tmpquantity = oldquantity; ' + #13#10 +
        GetChooseRemainsSQL(ftSource) +
        '          begin ' + #13#10 +
        '            if (tmpquantity > remains) then ' + #13#10 +
        '              quant = remains; ' + #13#10 +
        '            else ' + #13#10 +
        '              quant = tmpquantity; ' + #13#10 +
        '            NEW.fromcardkey = :id; ' + #13#10 +
        '            EXECUTE PROCEDURE gd_p_getnextid_ex RETURNING_VALUES :movementkey; ' + #13#10 +
        ' ' + #13#10 +
        '            INSERT INTO inv_movement (movementkey, documentkey, goodkey, cardkey, contactkey, movementdate, credit) ' + #13#10 +
        '            VALUES (:movementkey, NEW.documentkey, :goodkey, :id, :fromcontactkey, :documentdate, :quant); ' + #13#10 +
        ' ' + #13#10 +
        '            tmpquantity = tmpquantity - quant; ' + #13#10 +
        '          end ' + #13#10 +
        '          if (tmpquantity > 0 and NEW.checkremains = 0) then ' + #13#10 +
        '          begin ' + #13#10 +
        GetNewCardSQL(ftSource, '') +
        '            EXECUTE PROCEDURE gd_p_getnextid_ex RETURNING_VALUES :movementkey; ' + #13#10 +
        ' ' + #13#10 +
        '            INSERT INTO inv_movement (movementkey, documentkey, goodkey, cardkey, contactkey, movementdate, credit) ' + #13#10 +
        '            VALUES (:movementkey, NEW.documentkey, :goodkey, :id, :fromcontactkey, :documentdate, :tmpquantity); ' + #13#10 +
        '          end' + #13#10 +
        '          else ' + #13#10 +
        '            if (tmpquantity > 0) then '  + #13#10 +
        '              EXCEPTION INV_E_INSUFFICIENTBALANCE; ' + #13#10 +
        '        end ' + #13#10 +
        '        else ' + #13#10 +
        '        begin ' + #13#10 +
        '           tmpquantity = abs(oldquantity); ' + #13#10 +
        '           for ' + #13#10 +
        '             select m.movementkey, SUM(m.credit) ' + #13#10 +
        '             from inv_movement m ' + #13#10 +
        '             where m.documentkey = NEW.documentkey ' + #13#10 +
        '             group by 1 ' + #13#10 +
        '             order by 2 ' + #13#10 +
        '             into :movementkey, :oldquantity ' + #13#10 +
        '           do ' + #13#10 +
        '           begin ' + #13#10 +
        '             if (tmpquantity >= oldquantity) then ' + #13#10 +
        '             begin ' + #13#10 +
        '               delete from inv_movement where movementkey = :movementkey; ' + #13#10 +
        '               tmpquantity = tmpquantity - oldquantity; ' + #13#10 +
        '               when EXCEPTION INV_E_INVALIDMOVEMENT do ' + #13#10 +
        '                 EXCEPTION INV_E_DONTREDUCEAMOUNT; ' + #13#10 +
        '             end ' + #13#10 +
        '             else ' + #13#10 +
        '             begin ' + #13#10 +
        '               if (tmpquantity > 0) then ' + #13#10 +
        '               begin ' + #13#10 +
        ' ' + #13#10 +
        '                 update inv_movement set credit = credit - :tmpquantity ' + #13#10 +
        '                 where movementkey = :movementkey and credit <> 0; ' + #13#10 +
        '                 tmpquantity = 0; ' + #13#10 +
        '                 when EXCEPTION INV_E_INVALIDMOVEMENT do ' + #13#10 +
        '                   EXCEPTION INV_E_DONTREDUCEAMOUNT; ' + #13#10 +
        ' ' + #13#10 +
        ' ' + #13#10 +
        '               end ' + #13#10 +
        '             end ' + #13#10 +
        '           end ' + #13#10 +
        '        end ' + #13#10 +
        '        end ' + #13#10 +
        '        if (isdeletemovement = 0 and olddocumentdate <> documentdate) then ' + #13#10 +
        '        begin ' + #13#10 +
        '          if (olddocumentdate > documentdate) then ' + #13#10 +
        '          begin ' + #13#10 + GetCheckRemainsOnDateSQL(True) +
        '          end ' + #13#10 + GetUpdateDateSQL +
        '        end ' + #13#10 +
        '      end ' + #13#10 +
        '    end ' + #13#10 +
        '    else '  + #13#10 +
        '    begin ' + #13#10 +
        '      if (NEW.viewmovementpart = ''I'') then ' + #13#10 +
        '      begin ' + #13#10 +
        '        if (istochange = 1) then ' + #13#10 +
        '        begin ' + #13#10 +
        '          firstdocumentkey = NEW.documentkey; ' + #13#10 +
        GetNewCardSQL(ftDest, 'n') +
        '         NEW.fromcardkey = :id; ' + #13#10 +
        '        end ' + #13#10 +
        '      end ' + #13#10 +
        '      else ' + #13#10 +
        '        if (ischange = 1) then ' + #13#10 +
        '        begin ' + #13#10 +
        GetNewCardSQL(ftSource, '') +
        '         NEW.fromcardkey = :id; ' + #13#10 +
        '        end ' + #13#10 +
        '    end '  + #13#10 +
        '  end ' + #13#10 +
        'end ' + #13#10;
end;

var
  sqlText: String;
  StringList: TStringList;

begin
  R := atDatabase.Relations.ByID(GetTID(FieldByName('linerelkey')));
  if Assigned(R) then
  begin
    RelType := RelationTypeByRelation(R);

    InitFieldArray;

    gdcTrigger := TgdcTrigger.Create(Self);
    try
      gdcTrigger.ReadTransaction := Transaction;
      gdcTrigger.Transaction := Transaction;
      gdcTrigger.SubSet := 'ByTriggerName';

      NameTrigger := 'USR$BI_' + FieldByName('ruid').AsString;

      gdcTrigger.ParamByName('triggername').AsString := NameTrigger;
      gdcTrigger.Open;
      gdcTrigger.Edit;
      gdcTrigger.FieldByName('triggername').AsString := NameTrigger;
      SetTID(gdcTrigger.FieldByName('relationkey'), atDatabase.Relations.ByRelationName(DocLineRelationName).ID);
      gdcTrigger.FieldByName('rdb$trigger_sequence').AsInteger := 0;
      gdcTrigger.FieldByName('rdb$trigger_name').AsString := gdcTrigger.FieldByName('triggername').AsString;
      gdcTrigger.FieldByName('trigger_inactive').AsInteger := 0;
      gdcTrigger.FieldByName('rdb$trigger_type').AsInteger := 1;


      case RelType of
        irtSimple:
  {          gdcTrigger.FieldByName('rdb$trigger_source').AsString := CreateInsertTrigger_SimpleDoc;}
          begin
            StringList := TStringList.Create;
            try
              StringList.Text := CreateInsertTrigger_SimpleDoc;
              StringList.SaveToFile('c:\bases\111.sql');
          gdcTrigger.FieldByName('rdb$trigger_source').AsString := CreateInsertTrigger_SimpleDoc;
            finally
              StringList.Free;
            end;
          end;
        irtFeatureChange:
          gdcTrigger.FieldByName('rdb$trigger_source').AsString := CreateInsertTrigger_ChangeFeatureDoc;
        irtInventorization:
          gdcTrigger.FieldByName('rdb$trigger_source').AsString := CreateInsertTrigger_InventDoc;
        irtTransformation:
{          gdcTrigger.FieldByName('rdb$trigger_source').AsString := CreateInsertTrigger_TransformationDoc;}
          begin
            StringList := TStringList.Create;
            try
              StringList.Text := CreateInsertTrigger_SimpleDoc;
              StringList.SaveToFile('c:\bases\111.sql');
          gdcTrigger.FieldByName('rdb$trigger_source').AsString := CreateInsertTrigger_TransformationDoc;
            finally
              StringList.Free;
            end;
          end;
      end;

      gdcTrigger.Post;

      gdcTrigger.Close;
      NameTrigger := 'USR$BU_' + FieldByName('ruid').AsString;

      gdcTrigger.ParamByName('triggername').AsString := NameTrigger;
      gdcTrigger.Open;
      gdcTrigger.Edit;
      gdcTrigger.FieldByName('triggername').AsString := NameTrigger;
      SetTID(gdcTrigger.FieldByName('relationkey'), atDatabase.Relations.ByRelationName(DocLineRelationName).ID);
      gdcTrigger.FieldByName('rdb$trigger_sequence').AsInteger := 0;
      gdcTrigger.FieldByName('rdb$trigger_name').AsString := gdcTrigger.FieldByName('triggername').AsString;
      gdcTrigger.FieldByName('trigger_inactive').AsInteger := 0;
      gdcTrigger.FieldByName('rdb$trigger_type').AsInteger := 3;


      case RelType of
        irtSimple:
          gdcTrigger.FieldByName('rdb$trigger_source').AsString := CreateUpdateTrigger_SimpleDoc;
        irtFeatureChange:
          gdcTrigger.FieldByName('rdb$trigger_source').AsString := CreateUpdateTrigger_ChangeFeatureDoc;
        irtInventorization:
          gdcTrigger.FieldByName('rdb$trigger_source').AsString := CreateUpdateTrigger_InventDoc;
        irtTransformation:
          gdcTrigger.FieldByName('rdb$trigger_source').AsString := CreateUpdateTrigger_TransformationDoc;
{          begin
            StringList := TStringList.Create;
            try
              StringList.Text := CreateUpdateTrigger_TransformationDoc;
              StringList.SaveToFile('c:\bases\111.sql');
              gdcTrigger.FieldByName('rdb$trigger_source').AsString := CreateUpdateTrigger_TransformationDoc;
            finally
              StringList.Free;
      end;
          end;  }
      end;

      gdcTrigger.Post;

      sqlText := '';
      if AnsiCompareText(FIE.GetMCORelationName(emCredit), DocRelationName) = 0 then
        sqlText := ' NEW.' + FIE.GetMCOSourceFieldName(emCredit) + ' <> OLD.' + FIE.GetMCOSourceFieldName(emCredit);

      if AnsiCompareText(FIE.GetMCORelationName(emDebit), DocRelationName) = 0 then
      begin
        if sqlText <> '' then sqlText := sqlText + ' OR ';
        sqlText := sqlText + ' NEW.' + FIE.GetMCOSourceFieldName(emDebit) + ' <> OLD.' + FIE.GetMCOSourceFieldName(emDebit);
      end;

      if (sqlText <> '') then
      begin
        gdcTrigger.Close;
        NameTrigger := 'USR$AU_' + FieldByName('ruid').AsString;

        gdcTrigger.ParamByName('triggername').AsString := NameTrigger;
        gdcTrigger.Open;
        gdcTrigger.Edit;
        gdcTrigger.FieldByName('triggername').AsString := NameTrigger;
        SetTID(gdcTrigger.FieldByName('relationkey'), atDatabase.Relations.ByRelationName(DocRelationName).ID);
        gdcTrigger.FieldByName('rdb$trigger_sequence').AsInteger := 0;
        gdcTrigger.FieldByName('rdb$trigger_name').AsString := gdcTrigger.FieldByName('triggername').AsString;
        gdcTrigger.FieldByName('trigger_inactive').AsInteger := 0;
        gdcTrigger.FieldByName('rdb$trigger_type').AsInteger := 4;
        gdcTrigger.FieldByName('rdb$trigger_source').AsString :=
          'AS ' +
          'BEGIN ' +
          '  if (' + sqlText + ') then ' +
          '    UPDATE ' + DocLineRelationName + ' SET documentkey = documentkey WHERE masterkey = OLD.documentkey; ' +
          'END';
        gdcTrigger.Post

      end;

      gdcTrigger.Close;
      NameTrigger := 'USR$AU_D_' + FieldByName('ruid').AsString;

      gdcTrigger.ParamByName('triggername').AsString := NameTrigger;
      gdcTrigger.Open;
      gdcTrigger.Edit;
      gdcTrigger.FieldByName('triggername').AsString := NameTrigger;
      SetTID(gdcTrigger.FieldByName('relationkey'), atDatabase.Relations.ByRelationName('GD_DOCUMENT').ID);
      gdcTrigger.FieldByName('rdb$trigger_sequence').AsInteger := 100;
      gdcTrigger.FieldByName('rdb$trigger_name').AsString := gdcTrigger.FieldByName('triggername').AsString;
      gdcTrigger.FieldByName('trigger_inactive').AsInteger := 0;
      gdcTrigger.FieldByName('rdb$trigger_type').AsInteger := 4;
      gdcTrigger.FieldByName('rdb$trigger_source').AsString :=
        'AS ' +
        'BEGIN ' +
        '  if (NEW.documenttypekey = ' + FieldByName('ID').AsString + ' and (OLD.documentdate <> NEW.documentdate AND NEW.parent IS NOT NULL)) then ' +
        '    UPDATE ' + DocLineRelationName + ' SET documentkey = documentkey WHERE documentkey = NEW.id; ' +
        '  if (NEW.documenttypekey = ' + FieldByName('ID').AsString + ' and (OLD.delayed <> NEW.delayed AND NEW.parent IS NULL)) then ' +
        '    UPDATE ' + DocLineRelationName + ' SET documentkey = documentkey WHERE masterkey = NEW.id; ' +
        'END';
      gdcTrigger.Post

    finally
      gdcTrigger.Free;
    end;

  end;
end;

{$ENDIF}

destructor TgdcInvDocumentType.Destroy;
begin
  inherited;
end;

procedure TgdcInvDocumentType.DoAfterCustomProcess(Buff: Pointer;
  Process: TgsCustomProcess);
  var
  {@UNFOLD MACRO INH_ORIG_PARAMS(VAR)}
  {M}
  {M}  Params, LResult: Variant;
  {M}  tmpStrings: TStackStrings;
  {END MACRO}
  {$IFDEF NEWDEPOT}
 { Stream: TStream; }
  {$ENDIF}
  DE: TgdDocumentEntry;
begin
  {@UNFOLD MACRO INH_ORIG_DOAFTERCUSTOMPROCESS('TGDCBASE', 'DOAFTERCUSTOMPROCESS', KEYDOAFTERCUSTOMPROCESS)}
  {M}  try
  {M}    if (not FDataTransfer) and Assigned(gdcBaseMethodControl) then
  {M}    begin
  {M}      SetFirstMethodAssoc('TGDCINVDOCUMENTTYPE', KEYDOAFTERCUSTOMPROCESS);
  {M}      tmpStrings := TStackStrings(ClassMethodAssoc.IntByKey[KEYDOAFTERCUSTOMPROCESS]);
  {M}      if (tmpStrings = nil) or (tmpStrings.IndexOf('TGDCINVDOCUMENTTYPE') = -1) then
  {M}      begin
  {M}        Params := VarArrayOf([GetGdcInterface(Self),
  {M}          Integer(Buff), TgsCustomProcess(Process)]);
  {M}        if gdcBaseMethodControl.ExecuteMethodNew(ClassMethodAssoc, Self, 'TGDCINVDOCUMENTTYPE',
  {M}          'DOAFTERCUSTOMPROCESS', KEYDOAFTERCUSTOMPROCESS, Params, LResult) then
  {M}          exit;
  {M}      end else
  {M}        if tmpStrings.LastClass.gdClassName <> 'TGDCINVDOCUMENTTYPE' then
  {M}        begin
  {M}          Inherited;
  {M}          Exit;
  {M}        end;
  {M}    end;
  {END MACRO}

  inherited;

  if Process = cpInsert then
  begin
    DE := gdClassList.Add('TgdcInvDocument', FieldByName('ruid').AsString, GetParentSubType,
      TgdInvDocumentEntry, FieldbyName('name').AsString) as TgdDocumentEntry;
    DE.TypeID := ID;
    DE.LoadDE(Transaction);
    gdClassList.Add('TgdcInvDocumentLine', FieldByName('ruid').AsString, GetParentSubType,
      TgdInvDocumentEntry, FieldbyName('name').AsString).Assign(DE);

    gdClassList.Add('TgdcInvRemains', FieldByName('ruid').AsString, GetParentSubType, TgdBaseEntry, FieldbyName('name').AsString);
    gdClassList.Add('TgdcInvGoodRemains', FieldByName('ruid').AsString, GetParentSubType, TgdBaseEntry, FieldbyName('name').AsString);
    gdClassList.Add('TgdcSelectedGood', FieldByName('ruid').AsString, GetParentSubType, TgdBaseEntry, FieldbyName('name').AsString);
    gdClassList.Add('TgdcInvMovement', FieldByName('ruid').AsString, GetParentSubType, TgdBaseEntry, FieldbyName('name').AsString);

    gdClassList.Add('Tgdc_frmInvSelectGoodRemains', FieldByName('ruid').AsString, GetParentSubType, TgdFormEntry, FieldbyName('name').AsString);
    gdClassList.Add('Tgdc_frmInvSelectRemains', FieldByName('ruid').AsString, GetParentSubType, TgdFormEntry, FieldbyName('name').AsString);

    gdClassList.CreateFormSubTypes;
  end;

  {$IFDEF NEWDEPOT}

  if not FieldByName('OPTIONS').IsNull then
  begin
{    Stream := TStringStream.Create(FieldByName('OPTIONS').AsString);
    try
      ReadOptions(Stream);
    finally
      Stream.Free;
    end;           }
    InitOpt;

    CreateTempTable;

    CreateTriggers;
    
    DoneOpt;
  end;
  
  {$ENDIF}

  {@UNFOLD MACRO INH_ORIG_FINALLY('TGDCBASE', 'DOAFTERCUSTOMPROCESS', KEYDOAFTERCUSTOMPROCESS)}
  {M}  finally
  {M}    if (not FDataTransfer) and Assigned(gdcBaseMethodControl) then
  {M}      ClearMacrosStack2('TGDCINVDOCUMENTTYPE', 'DOAFTERCUSTOMPROCESS', KEYDOAFTERCUSTOMPROCESS);
  {M}  end;
  {END MACRO}
end;

procedure TgdcInvDocumentType.DoBeforePost;
  {@UNFOLD MACRO INH_ORIG_PARAMS(VAR)}
  {M}VAR
  {M}  Params, LResult: Variant;
  {M}  tmpStrings: TStackStrings;
  {END MACRO}
begin
  {@UNFOLD MACRO INH_ORIG_WITHOUTPARAM('TGDCINVDOCUMENTTYPE', 'DOBEFOREPOST', KEYDOBEFOREPOST)}
  {M}  try
  {M}    if (not FDataTransfer) and Assigned(gdcBaseMethodControl) then
  {M}    begin
  {M}      SetFirstMethodAssoc('TGDCINVDOCUMENTTYPE', KEYDOBEFOREPOST);
  {M}      tmpStrings := TStackStrings(ClassMethodAssoc.IntByKey[KEYDOBEFOREPOST]);
  {M}      if (tmpStrings = nil) or (tmpStrings.IndexOf('TGDCINVDOCUMENTTYPE') = -1) then
  {M}      begin
  {M}        Params := VarArrayOf([GetGdcInterface(Self)]);
  {M}        if gdcBaseMethodControl.ExecuteMethodNew(ClassMethodAssoc, Self, 'TGDCINVDOCUMENTTYPE',
  {M}          'DOBEFOREPOST', KEYDOBEFOREPOST, Params, LResult) then exit;
  {M}      end else
  {M}        if tmpStrings.LastClass.gdClassName <> 'TGDCINVDOCUMENTTYPE' then
  {M}        begin
  {M}          Inherited;
  {M}          Exit;
  {M}        end;
  {M}    end;
  {END MACRO}

  inherited;

  //��������� ��������� �� ����� ���� ������!
  FieldByName('iscommon').AsInteger := 0;

  {@UNFOLD MACRO INH_ORIG_FINALLY('TGDCINVDOCUMENTTYPE', 'DOBEFOREPOST', KEYDOBEFOREPOST)}
  {M}  finally
  {M}    if (not FDataTransfer) and Assigned(gdcBaseMethodControl) then
  {M}      ClearMacrosStack2('TGDCINVDOCUMENTTYPE', 'DOBEFOREPOST', KEYDOBEFOREPOST);
  {M}  end;
  {END MACRO}
end;

procedure TgdcInvDocumentType.DoneOpt;
var
  DE: TgdDocumentEntry;
begin
  FIE := nil;
  inherited;

  DE := gdClassList.Get(TgdInvDocumentEntry, 'TgdcInvDocument', FieldByName('ruid').AsString) as TgdDocumentEntry;
  DE.LoadDE(Transaction);
  gdClassList.Get(TgdInvDocumentEntry, 'TgdcInvDocumentLine', FieldByName('ruid').AsString).Assign(DE);
end;

class function TgdcInvDocumentType.GetDialogFormClassName(
  const ASubType: TgdcSubType): String;
begin
  Result := 'Tgdc_dlgSetupInvDocument';
end;

class function TgdcInvDocumentType.GetHeaderDocumentClass: CgdcBase;
begin
  Result := TgdcInvDocument;
end;

class function TgdcInvDocumentType.GetViewFormClassName(
  const ASubType: TgdcSubType): String;
begin
  Result := 'Tgdc_frmInvDocumentType';
end;

procedure TgdcInvDocumentType.InitOpt;
var
  DE: TgdDocumentEntry;
begin
  inherited;

  DE := gdClassList.FindDocByTypeID(ID, dcpHeader, True);
  if DE is TgdInvDocumentEntry then
    FIE := DE as TgdInvDocumentEntry
  else if DE = nil then
    FIE := nil
  else
    raise EgdcInvDocumentType.Create('Not an inventory document type');
end;

class function TgdcInvDocumentType.InvDocumentTypeBranchKey: TID;
begin
  Result := INV_DOC_INVENTBRANCH;
end;

(*
procedure TgdcInvDocumentType.ReadOptions(Stream: TStream);
var
  Version: String;
  RKey: Integer;
  R: TatRelation;
  F: TatRelationField;
begin
  with TReader.Create(Stream, 1024) do
  try
    // ����� ���������
    Version := ReadString;

    // ������������ ������
    RelationName := ReadString;
    RelationLineName := ReadString;

    if FieldByName('headerrelkey').IsNull then
    begin
      R := atDatabase.Relations.ByRelationName(RelationName);
      if Assigned(R) then
      begin
        if not (State in [dsEdit, dsInsert]) then
          Edit;
        FieldByName('headerrelkey').AsInteger := R.ID;
      end;
    end;

    if FieldByName('linerelkey').IsNull then
    begin
      R := atDatabase.Relations.ByRelationName(RelationLineName);
      if Assigned(R) then
      begin
        if not (State in [dsEdit, dsInsert]) then
          Edit;
        FieldByName('linerelkey').AsInteger := R.ID;
      end;
    end;

    FEnglishName := RelationName;

    if (Version <> gdcInvDocument_Version2_0) and (Version <> gdcInvDocument_Version2_1) and
       (Version <> gdcInvDocument_Version2_2) and (Version <> gdcInvDocument_Version2_3)
    then
    // ��� ��������� ���������
      ReadInteger;

    // ���� ������ �� ������ �������
    if (Version = gdcInvDocument_Version2_2) or
      (Version = gdcInvDocument_Version2_3) or
      (Version = gdcInvDocument_Version2_1) or
      (Version = gdcInvDocument_Version2_0) or
      (Version = gdcInvDocument_Version1_9) then
    begin
      RKey := ReadInteger;
      if (RKey > 0) and FieldByName('reportgroupkey').IsNull then
      begin
        if not (State in [dsEdit, dsInsert]) then Edit;
        FieldByName('reportgroupkey').AsInteger := RKey;
      end;
    end;


//    UpdateEditingSettings;


    // ������
    SetLength(DebitMovement.Predefined, 0);
    SetLength(DebitMovement.SubPredefined, 0);

    DebitMovement.RelationName := ReadString;
    DebitMovement.SourceFieldName := ReadString;
    DebitMovement.SubRelationName := ReadString;
    DebitMovement.SubSourceFieldName := ReadString;

    Read(DebitMovement.ContactType, SizeOf(TgdcInvMovementContactType));

    ReadListBegin;
    while not EndOfList do
    begin
      SetLength(DebitMovement.Predefined,
        Length(DebitMovement.Predefined) + 1);
      DebitMovement.Predefined[Length(DebitMovement.Predefined) - 1] :=
        ReadInteger;
    end;
    ReadListEnd;

    ReadListBegin;
    while not EndOfList do
    begin
      SetLength(DebitMovement.SubPredefined,
        Length(DebitMovement.SubPredefined) + 1);
      DebitMovement.SubPredefined[Length(DebitMovement.SubPredefined) - 1] :=
        ReadInteger;
    end;
    ReadListEnd;

    // ������
    SetLength(CreditMovement.Predefined, 0);
    SetLength(CreditMovement.SubPredefined, 0);

    CreditMovement.RelationName := ReadString;
    CreditMovement.SourceFieldName := ReadString;

    CreditMovement.SubRelationName := ReadString;
    CreditMovement.SubSourceFieldName := ReadString;

    Read(CreditMovement.ContactType, SizeOf(TgdcInvMovementContactType));

    ReadListBegin;
    while not EndOfList do
    begin
      SetLength(CreditMovement.Predefined,
        Length(CreditMovement.Predefined) + 1);
      CreditMovement.Predefined[Length(CreditMovement.Predefined) - 1] :=
        ReadInteger;
    end;
    ReadListEnd;

    ReadListBegin;
    while not EndOfList do
    begin
      SetLength(CreditMovement.SubPredefined,
        Length(CreditMovement.SubPredefined) + 1);
      CreditMovement.SubPredefined[Length(CreditMovement.SubPredefined) - 1] :=
        ReadInteger;
    end;
    ReadListEnd;

    // ��������� ���������
    FSourceFeatures.Clear;
    ReadListBegin;
    while not EndOfList do
    begin
      F := atDatabase.FindRelationField('INV_CARD', ReadString);
      if not Assigned(F) then Continue;
      FSourceFeatures.AddObject(F.FieldName, F);
    end;
    ReadListEnd;

    FDestFeatures.Clear;
    ReadListBegin;
    while not EndOfList do
    begin
      F := atDatabase.FindRelationField('INV_CARD', ReadString);
      if not Assigned(F) then Continue;
      FDestFeatures.AddObject(F.FieldName, F);
    end;
    ReadListEnd;

  {  SetupFeaturesTab;}

    // ��������� ������������
    Read(FSources, SizeOf(TgdcInvReferenceSources));

{    cbReference.Checked := irsGoodRef in Sources;
    cbRemains.Checked := irsRemainsRef in Sources;}
//  cbFromMacro.Checked := irsMacro in Sources;

    // ��������� FIFO, LIFO
    Read(FDirection, SizeOf(TgdcInvMovementDirection));
{    rgMovementDirection.ItemIndex := Integer(Direction);

    // ������� ��������
    cbControlRemains.Checked := ReadBoolean;             }
    FControlRemains := ReadBoolean;
    // ������ ������ � �������� ���������
    if (Version = gdcInvDocument_Version1_9) or
      (Version = gdcInvDocument_Version2_0) or
      (Version = gdcInvDocument_Version2_1) or
      (Version = gdcInvDocument_Version2_2) or
      (Version = gdcInvDocument_Version2_3) or
      (Version = gdcInvDocument_Version2_4) or
      (Version = gdcInvDocument_Version2_5) or
      (Version = gdcInvDocument_Version2_6) or
      (Version = gdcInvDocument_Version3_0)  then
      LiveTimeRemains := ReadBoolean
    else
      LiveTimeRemains := False;

{    if not cbRemains.Checked then
    begin
      // ������� ��������
      cbControlRemains.Checked := False;

      // ������ ������ � �������� ���������
      cbLiveTimeRemains.Checked := False;
    end; }

    // �������� ����� ���� ����������
    DelayedDocument := ReadBoolean;
    // ����� �������������� �����������
    ReadBoolean;

    if (Version = gdcInvDocument_Version2_1) or (Version = gdcInvDocument_Version2_2)
       or (Version = gdcInvDocument_Version2_3) or (Version = gdcInvDocument_Version2_4)
       or (Version = gdcInvDocument_Version2_5)  or
      (Version = gdcInvDocument_Version2_6) or (Version = gdcInvDocument_Version3_0)
    then
      MinusRemains := ReadBoolean
    else
      MinusRemains := False;

{    gbMinusFeatures.Visible := cbMinusRemains.Checked;

    if not cbRemains.Checked then
      cbMinusRemains.Checked := False;                 }

    if (Version = gdcInvDocument_Version2_2) or (Version = gdcInvDocument_Version2_3)
       or (Version = gdcInvDocument_Version2_4) or (Version = gdcInvDocument_Version2_5) or
      (Version = gdcInvDocument_Version2_6) or (Version = gdcInvDocument_Version3_0)
    then
    begin
      ReadListBegin;
      while not EndOfList do
      begin
        F := atDatabase.FindRelationField('INV_CARD', ReadString);
        if not Assigned(F) then Continue;
        FMinusFeatures.AddObject(F.FieldName, F);
      end;
      ReadListEnd;

{      SetupMinusFeaturesTab;}
    end;

    if (Version = gdcInvDocument_Version2_3) or (Version = gdcInvDocument_Version2_4) or
       (Version = gdcInvDocument_Version2_5)  or
      (Version = gdcInvDocument_Version2_6) or
      (Version = gdcInvDocument_Version3_0) then
    begin
      IsChangeCardValue := ReadBoolean;
      IsAppendCardValue := ReadBoolean;
    end;

    if (Version = gdcInvDocument_Version2_4) or (Version = gdcInvDocument_Version2_5)  or
      (Version = gdcInvDocument_Version2_6) or
      (Version = gdcInvDocument_Version3_0) then
      IsUseCompanyKey := ReadBoolean
    else
      IsUseCompanyKey := True;

    if (Version = gdcInvDocument_Version2_5)  or
      (Version = gdcInvDocument_Version2_6) or
      (Version = gdcInvDocument_Version3_0) then
      SaveRestWindowOption := ReadBoolean
    else
      SaveRestWindowOption := False;

    if (Version = gdcInvDocument_Version2_6) or (Version = gdcInvDocument_Version3_0) then
      EndMonthRemains := ReadBoolean
    else
      EndMonthRemains := False;

    if (Version = gdcInvDocument_Version3_0) then
      WithoutSearchRemains := ReadBoolean
    else
      WithoutSearchRemains := False;
  finally
    Free;
  end;
end;
*)

procedure TgdcInvDocumentType.UpdateContactList(lv: TListView;
  const AName: String; V: TgdcMCOPredefined);
var
  I, J: Integer;
  OptID, K: TID;
  Found: Boolean;
begin
  for I := 0 to lv.Items.Count - 1 do
  begin
    K := GetTID(lv.Items[I].SubItems[0]);
    Found := False;
    for J := Low(V) to High(V) do
      if V[J] = K then
      begin
        Found := True;
        break;
      end;
    if not Found then
    begin
      OptID := GetNextID;

      Fq.Close;
      Fq.SQL.Text :=
        'INSERT INTO gd_documenttype_option (id, dtkey, option_name, bool_value, contactkey) ' +
        'VALUES (:id, :dtkey, :option_name, NULL, :ck)';
      SetTID(Fq.ParamByName('id'), OptID);
      SetTID(Fq.ParamByName('dtkey'), ID);
      Fq.ParamByName('option_name').AsString := AName;
      SetTID(Fq.ParamByName('ck'), K);
      Fq.ExecQuery;

      AddNSObject(OptID, AName + '.' + lv.Items[I].Caption, K);
    end;
  end;

  for J := Low(V) to High(V) do
  begin
    Found := False;
    for I := 0 to lv.Items.Count - 1 do
      if GetTID(lv.Items[I].SubItems[0]) = V[J] then
      begin
        Found := True;
        break;
      end;
    if not Found then
    begin
      Fq.Close;
      Fq.SQL.Text :=
        'DELETE FROM gd_documenttype_option ' +
        'WHERE dtkey = :dtkey AND option_name = :option_name AND contactkey = :ck';
      SetTID(Fq.ParamByName('dtkey'), ID);
      Fq.ParamByName('option_name').AsString := AName;
      SetTID(Fq.ParamByname('ck'), V[J]);
      Fq.ExecQuery;
    end;
  end;
end;

procedure TgdcInvDocumentType.UpdateContactTypeOption(
  const AValue: TgdcInvMovementContactType; const APrefix: String);
var
  OptID: TID;
begin
  if GetOptID(APrefix + '.CT.', OptID) then
  begin
    Fq.Close;
    Fq.SQL.Text :=
      'UPDATE gd_documenttype_option SET bool_value = 1, option_name = :option_name, editiondate = CURRENT_TIMESTAMP(0) ' +
      'WHERE id = :id';
    SetTID(Fq.ParamByName('id'), OptID);
    Fq.ParamByName('option_name').AsString := APrefix + '.CT.' + gdcInvMovementContactTypeNames[AValue];
    Fq.ExecQuery;
  end else
  begin
    Fq.Close;
    Fq.SQL.Text :=
      'INSERT INTO gd_documenttype_option (id, dtkey, option_name, bool_value) ' +
      'VALUES (:id, :dtkey, :option_name, 1)';
    SetTID(Fq.ParamByName('id'), OptID);
    SetTID(Fq.ParamByName('dtkey'), ID);
    Fq.ParamByName('option_name').AsString := APrefix + '.CT.' + gdcInvMovementContactTypeNames[AValue];
    Fq.ExecQuery;

    AddNSObject(OptID, APrefix + '.CT');
  end;
end;

procedure TgdcInvDocumentType.UpdateFeatures(
  const AFeature: TgdInvDocumentEntryFeature; SL: TStrings);
var
  I, J: Integer;
  OptID: TID;
  Found: Boolean;
  RF: TatRelationField;
begin
  for I := 0 to SL.Count - 1 do
  begin
    Found := False;

    if FIE <> nil then
    begin
      for J := 0 to FIE.GetFeaturesCount(AFeature) - 1 do
      begin
        if SL[I] = FIE.GetFeature(AFeature, J) then
        begin
          Found := True;
          break;
        end;
      end;
    end;

    if not Found then
    begin
      RF := atDatabase.FindRelationField('INV_CARD', SL[I]);

      if RF = nil then
        raise EgdcInvDocumentType.Create('Invalid INV_CARD field');

      OptID := GetNextID;

      Fq.Close;
      Fq.SQL.Text :=
        'INSERT INTO gd_documenttype_option (id, dtkey, option_name, bool_value, relationfieldkey) ' +
        'VALUES (:id, :dtkey, :option_name, NULL, :rfk)';
      SetTID(Fq.ParamByName('id'), OptID);
      SetTID(Fq.ParamByName('dtkey'), ID);
      Fq.ParamByName('option_name').AsString := InvDocumentFeaturesNames[AFeature];
      SetTID(Fq.ParamByName('rfk'), RF.ID);
      Fq.ExecQuery;

      AddNSObject(OptID, InvDocumentFeaturesNames[AFeature] + '.' + RF.FieldName, RF.ID);
    end;
  end;

  if FIE <> nil then
  begin
    for J := 0 to FIE.GetFeaturesCount(AFeature) - 1 do
    begin
      Found := False;
      for I := 0 to SL.Count - 1 do
      begin
        if SL[I] = FIE.GetFeature(AFeature, J) then
        begin
          Found := True;
          break;
        end;
      end;

      if not Found then
      begin
        RF := atDatabase.FindRelationField('INV_CARD', FIE.GetFeature(AFeature, J));

        if RF = nil then
          raise EgdcInvDocumentType.Create('Invalid INV_CARD field');

        Fq.Close;
        Fq.SQL.Text :=
          'DELETE FROM gd_documenttype_option ' +
          'WHERE dtkey = :dtk AND option_name = :option_name AND relationfieldkey = :rfk ';
        SetTID(Fq.ParamByName('dtk'), ID);
        Fq.ParamByName('option_name').AsString := InvDocumentFeaturesNames[AFeature];
        SetTID(Fq.ParamByname('rfk'), RF.ID);
        Fq.ExecQuery;
      end;
    end;
  end;
end;

procedure TgdcInvDocumentType.UpdateFlag(const AFlag: TgdInvDocumentEntryFlag;
  const AValue, ACheckValue: Boolean);
var
  OptID: TID;
  P: Integer;
  N: String;
begin
  if ACheckValue and ((FIE <> nil) and (FIE.GetFlag(AFlag) = AValue)) then
    exit;

  P := Pos('.', InvDocumentEntryFlagNames[AFlag]);
  if P > 0 then
  begin
    if not AValue then
      raise EgdcInvBaseDocument.Create('Can not set False value to an enum type');

    N := System.Copy(InvDocumentEntryFlagNames[AFlag], 1, P);
  end else
    N := InvDocumentEntryFlagNames[AFlag];

  if (AFlag in [efDirFIFO, efDirLIFO, efDirDefault]) and (
    GetOptID(InvDocumentEntryFlagNames[efDirFIFO], OptID) or
    GetOptID(InvDocumentEntryFlagNames[efDirLIFO], OptID) or
    GetOptID(InvDocumentEntryFlagNames[efDirDefault], OptID)) then
  begin
    Fq.Close;
    Fq.SQL.Text :=
      'UPDATE gd_documenttype_option SET option_name = :option_name, bool_value = 1, editiondate = CURRENT_TIMESTAMP(0) ' +
      'WHERE id = :id';
    Fq.ParamByName('option_name').AsString := InvDocumentEntryFlagNames[AFlag];
    SetTID(Fq.ParamByName('id'), OptID);
    Fq.ExecQuery;
  end;

  if GetOptID(N, OptID) then
  begin
    Fq.Close;
    Fq.SQL.Text :=
      'UPDATE gd_documenttype_option SET option_name = :option_name, bool_value = :v, editiondate = CURRENT_TIMESTAMP(0) ' +
      'WHERE id = :id';
    SetTID(Fq.ParamByName('id'), OptID);
    Fq.ParamByName('option_name').AsString := InvDocumentEntryFlagNames[AFlag];
    if AValue then
      Fq.ParamByName('v').AsInteger := 1
    else
      Fq.ParamByName('v').AsInteger := 0;
    Fq.ExecQuery;
  end else
  begin
    Fq.Close;
    Fq.SQL.Text :=
      'INSERT INTO gd_documenttype_option (id, dtkey, option_name, bool_value) ' +
      'VALUES (:id, :dtkey, :option_name, :v)';
    SetTID(Fq.ParamByName('id'), OptID);
    SetTID(Fq.ParamByName('dtkey'), ID);
    Fq.ParamByName('option_name').AsString := InvDocumentEntryFlagNames[AFlag];
    if AValue then
      Fq.ParamByName('v').AsInteger := 1
    else
      Fq.ParamByName('v').AsInteger := 0;
    Fq.ExecQuery;

    if P > 0 then
      AddNSObject(OptID, System.Copy(InvDocumentEntryFlagNames[AFlag], 1, P - 1))
    else
      AddNSObject(OptID, InvDocumentEntryFlagNames[AFlag]);
  end;
end;

procedure TgdcInvDocumentType.UpdateRF(const ARF: TatRelationField; const AName: String);
var
  OptID: TID;
begin
  if ARF = nil then
    DelOpt(AName)
  else
  begin
    if GetOptID(AName, OptID) then
    begin
      Fq.Close;
      Fq.SQL.Text :=
        'UPDATE gd_documenttype_option SET relationfieldkey = :rfk, editiondate = CURRENT_TIMESTAMP(0) ' +
        'WHERE id = :id';
      SetTID(Fq.ParamByName('id'), OptID);
      SetTID(Fq.ParamByName('rfk'), ARF.ID);
      Fq.ExecQuery;
    end else
    begin
      Fq.Close;
      Fq.SQL.Text :=
        'INSERT INTO gd_documenttype_option (id, dtkey, option_name, bool_value, relationfieldkey) ' +
        'VALUES (:id, :dtkey, :option_name, NULL, :rfk)';
      SetTID(Fq.ParamByName('id'), OptID);
      SetTID(Fq.ParamByName('dtkey'), ID);
      Fq.ParamByName('option_name').AsString := AName;
      SetTID(Fq.ParamByName('rfk'), ARF.ID);
      Fq.ExecQuery;

      AddNSObject(OptID, AName, ARF.ID);
    end;
  end;
end;

initialization
  RegisterGdcClass(TgdcInvDocumentType, '��� ���������� ���������');
  RegisterGdcClass(TgdcInvBaseDocument, '��������� ��������');
  RegisterGdcClass(TgdcInvDocument, '��������� ��������');
  RegisterGdcClass(TgdcInvDocumentLine, '������� ���������� ���������');

finalization
  UnregisterGdcClass(TgdcInvDocumentLine);
  UnregisterGdcClass(TgdcInvDocument);
  UnregisterGdcClass(TgdcInvBaseDocument);
  UnregisterGdcClass(TgdcInvDocumentType);
end.

