// ShlTanya, 11.02.2019

unit gdClosingPeriod;

interface

uses
  IBDatabase, Classes, SysUtils, gd_KeyAssoc, gdcBaseInterface, stdctrls, comctrls,
  IBSQL, forms;

type
  TgsProcessState = (psUnknown, psWorking, psSuccess, psTerminating, psInterrupted, psError);

  TgsBeforeAfterProcessRoutine = procedure;
  TgsOnProcessInterruptionRoutine = procedure(const AErrorMessage: String);
  TgsOnProcessMessage = procedure(const APosition, AMaxPosition: Integer; const AMessage: String);

  TgdClosingPeriod = class(TObject)
  private
    FDontDeleteCardArray: TgdKeyArray;
    // ���� �� ������� ����������� ������
    FWorkingThread: TThread;
    // ������� ���������� ��� �������� �������
    FWriteTransaction: TIBTransaction;
    // ����� ������ ��������� ����� �������� �������
    FLocalStartTime: TDateTime;
    // ��������� ������� � ����������� ��
    FExtDatabasePath: String;
    FExtDatabaseServer: String;
    FExtDatabaseUser: String;
    FExtDatabasePassword: String;
    FCloseDate: TDateTime;
    // ������ ������� ������ �� �������:
    //   ��� ������� - ������-������ ������� ������
    FTableReferenceForeignKeysList: TStringList;
    // ������ �����-��������� ��������� �������� �� ��������
    FFeatureList: TStringList;
    // ���������� ��������� ������� � AC_ENTRY_BALANCE
    FInsertedEntryBalanceRecordCount: Integer;
    // ������ ������������� ��������, � ������� ������� �������� ���. ������
    FEntryAvailableAnalytics: TStringList;
    // ��������� �� ����-������ �� ������� �������
    FAddLineKeyFieldExists: Boolean;
    FInvDocumentTypeKey: TID;
    // ������ �������� AC_ENTRY �� ������� �� ���� ����������� ������
    FDontBalanceAnalytic: String;

    FPseudoClientKey: TID;

    FUserDocumentTypesToDelete: TgdKeyArray;
    FDontDeleteDocumentTypes: TgdKeyArray;
    // ������ �������� �� ����� ����������
    FDummyInvDocumentKeys: TgdKeyIntAssoc;

    FQueriesInitialized: Boolean;
    FIBSQLGetDepotHeaderKey: TIBSQL;
    FIBSQLInsertGdDocument: TIBSQL;
    FIBSQLInsertDocumentHeader: TIBSQL;
    FIBSQLInsertDocumentPosition: TIBSQL;
    FIBSQLInsertInvCard: TIBSQL;
    FIBSQLInsertInvMovement: TIBSQL;
    FIBSQLDeleteRUID: TIBSQL;

    FOnBeforeProcess: TgsBeforeAfterProcessRoutine;
    FOnAfterProcess: TgsBeforeAfterProcessRoutine;
    FOnProcessInterruption: TgsOnProcessInterruptionRoutine;
    FOnProcessMessage: TgsOnProcessMessage;

    FOnlyOurRemains: Boolean;
    // ���� ����������, ����� �� ������ ���������
    //  ��������������� �������� �� ����� �������� �������
    FDoCalculateEntryBalance: Boolean;  // ������� �������������� ������
    FDoCalculateRemains: Boolean;       // ������� ��������� ��������
    FDoReBindDepotCards: Boolean;       // ������������ ��������� �������� � ��������
    FDoDeleteEntry: Boolean;            // �������� ��������
    FDoDeleteDocuments: Boolean;        // �������� ��������� ����������
    FDoDeleteUserDocuments: Boolean;    // �������� ���������������� ����������
    FDoTransferEntryBalance: Boolean;   // ������� �������������� ������ �� AC_ENTRY_BALANCE � AC_ENTRY

    //procedure InsertDatabaseRecord;
    function GetFeatureFieldList(AAlias: String): String;
    function IIF(const Condition: Boolean; const TrueString, FalseString: String): String;
    function GetQueryRecordCount(InIBSQL: TIBSQL): Integer;

    function AddDepotHeader(const FromContact, ToContact, CompanyKey: TID): TID;
    function AddDepotPosition(const FromContact, ToContact, CompanyKey,
      ADocumentParentKey, CardGoodkey: TID; const GoodQuantity: Currency; FeatureDataset: TIBSQL = nil): TID;

    function GetReplacementInvCardKey(const AOldCardKey: TID; AFeatureDataset: TIBSQL;
      const AFromContactkey: TID = -1; const AToContactkey: TID = -1): TID;
    // ��������� ������� ������ ����������� �� �������� �� ����������� ��������� � �������� ������ �����������
    procedure TryToDeleteInvCardReferences(const ADocumentKey: TID);
    // ��������� �������� ������� ������ ����������� �� ����������
    procedure TryToDeleteDocumentReferences(const AID: TID; const AdditionalRelationName: String; const ADocTypeKey: TID = -1);
    function CreateDummyInvDocument(const ADocTypeKey: TID): TID;
    // ������� ������� ��� ������ ���. ������� ���������
    //function TryToTruncateAdditionalTable(const ADocTypeKey: TID; const AdditionalRelationName: String): Boolean;

    procedure DeleteRUID(const AID: TID);

    procedure InitialFillOptions;
    procedure InitializeIBSQLQueries;

    function GetInProcess: Boolean;
  protected
    // ��������� �������
    FProcessState: TgsProcessState;
  public
    constructor Create;
    destructor Destroy; override;

    // ���������� � ������� ������ ����� ��������� ����������, ������� ������ '���������'
    procedure AddDontDeleteDocumentType(DocType: TID);
    procedure ClearDontDeleteDocumentTypes;
    // ���������� � ������� ������ ����� ���������������� ��������� ���������� '��������'
    procedure AddUserDocumentTypeToDelete(DocType: TID);
    procedure ClearUserDocumentTypesToDelete;
    // ���������� � ������� ������ ���������� ��������� ���������
    procedure AddInvCardFeature(FeatureFieldName: String);
    procedure ClearInvCardFeatures;
    // ������������� ��������� ������� � ����������� ��
    procedure SetClosingDatabaseParams(const ADBPAth, ADBServer, ADBUser, ADBPAssword: String);

    // ���������������� ���������� ���� �������� ��� '�������� �������'
    procedure DoClosePeriod;
    // ���������� ���������� �������� �������
    procedure StopProcess;

    // �������������� ������ ���������� ������� ������ �������
    procedure PrepareDontDeleteDocumentList;
    // ��������\��������� �������� ������� ������ '�������� �������'
    procedure SetTriggerActive(SetActive: Boolean);
    // ������� �������������� ������
    procedure CalculateEntryBalance;
    // ������� ��������� ��������
    procedure CalculateRemains;
    // ������������ ��������� �������� � ��������
    procedure ReBindDepotCards;
    // �������� ��������
    procedure DeleteEntry;
    // �������� ��������� ����������
    procedure DeleteDocuments;
    // �������� ���������������� ����������
    procedure DeleteUserDocuments;
    // ������� �������������� ������ �� AC_ENTRY_BALANCE � AC_ENTRY
    procedure TransferEntryBalance;

    procedure DoBeforeProcess;
    procedure DoAfterProcess;
    procedure DoOnProcessInterruption(const AErrorMessage: String);
    procedure DoOnProcessMessage(const APosition, AMaxPosition: Integer; const AMessage: String);

    // �������� �� ������ �������� �������
    property InProcess: Boolean read GetInProcess;
    // ��������� �������
    property ProcessState: TgsProcessState read FProcessState;
    // ���� �������� �������
    property CloseDate: TDateTime read FCloseDate write FCloseDate;

    // �������� ��� ��������� �������������� ��������� ������
    property OnBeforeProcessRoutine: TgsBeforeAfterProcessRoutine read FOnBeforeProcess write FOnBeforeProcess;
    property OnAfterProcessRoutine: TgsBeforeAfterProcessRoutine read FOnAfterProcess write FOnAfterProcess;
    property OnProcessInterruptionRoutine: TgsOnProcessInterruptionRoutine read FOnProcessInterruption write FOnProcessInterruption;
    property OnProcessMessageRoutine: TgsOnProcessMessage read FOnProcessMessage write FOnProcessMessage;

    // ������� ������� ������ �� ������� ������������, ��� �� ���� ���������
    property OnlyOurRemains: Boolean read FOnlyOurRemains write FOnlyOurRemains;
    // ������ �������� AC_ENTRY �� ������� �� ���� ����������� ������ (;FIELD1;FIELD2;FIELD3;)
    property DontBalanceAnalytic: String read FDontBalanceAnalytic write FDontBalanceAnalytic;
    // �������� ��� ������� � �����, ������� ����������, ����� �� ������ ���������
    //  ��������������� �������� �� ����� �������� �������
    property DoCalculateEntryBalance: Boolean read FDoCalculateEntryBalance write FDoCalculateEntryBalance;
    property DoCalculateRemains: Boolean read FDoCalculateRemains write FDoCalculateRemains;
    property DoReBindDepotCards: Boolean read FDoReBindDepotCards write FDoReBindDepotCards;
    property DoDeleteEntry: Boolean read FDoDeleteEntry write FDoDeleteEntry;
    property DoDeleteDocuments: Boolean read FDoDeleteDocuments write FDoDeleteDocuments;
    property DoDeleteUserDocuments: Boolean read FDoDeleteUserDocuments write FDoDeleteUserDocuments;
    property DoTransferEntryBalance: Boolean read FDoTransferEntryBalance write FDoTransferEntryBalance;
  end;

  TgdClosingThread = class(TThread)
  protected
    FModel: TgdClosingPeriod;
  public
    procedure Execute; override;

    property Model: TgdClosingPeriod read FModel write FModel;
  end;

implementation

uses
  gdcInvDocument_unit,          at_classes,             gd_security,
  Windows,                      db,                     contnrs,
  AcctUtils,                    AcctStrings,            controls,
  gdcAcctEntryRegister,         Storages;

const
  InvDocumentRUID = '174849703_1094302532';
  INV_DOCUMENT_HEAD = 'USR$INV_DOCUMENT';
  INV_DOCUMENT_LINE = 'USR$INV_DOCUMENTLINE';
  REFRESH_CLOSING_INFO_INTERVAL = 100;

  SEARCH_NEW_CARDKEY_TEMPLATE =
    'SELECT FIRST(1) ' +
    '  card.id AS cardkey, card.firstdocumentkey, card.firstdate ' +
    'FROM ' +
      INV_DOCUMENT_HEAD + ' head ' +
    '  LEFT JOIN gd_document doc ON doc.id = head.documentkey ' +
    '  LEFT JOIN ' + INV_DOCUMENT_LINE + ' line ON line.masterkey = head.documentkey ' +
    '  LEFT JOIN inv_card card ON card.id = line.fromcardkey ' +
    'WHERE ' +
    '  doc.documentdate = :closedate ' +
    '  AND card.goodkey = :goodkey ' +
    '  AND ' +
    '    ((head.usr$in_contactkey = :contact_01) ' +
    '    OR (head.usr$in_contactkey = :contact_02)) ';
  SEARCH_NEW_CARDKEY_TEMPLATE_SIMPLE =
    'SELECT FIRST(1) ' +
    '  card.id AS cardkey, card.firstdocumentkey, card.firstdate ' +
    'FROM ' +
      INV_DOCUMENT_LINE + ' line ' +
    '  JOIN gd_document doc ON doc.id = line.documentkey ' +
    '  JOIN inv_card card ON card.id = line.fromcardkey ' +
    'WHERE ' +
    '  doc.documentdate = :closedate ' +
    '  AND doc.documenttypekey = :doctypekey ' + 
    '  AND card.goodkey = :goodkey ';

{ TgdClosingPeriod }

constructor TgdClosingPeriod.Create;
begin
  FWriteTransaction := TIBTransaction.Create(Application);
  FWriteTransaction.DefaultDatabase := gdcBaseManager.Database;
  FWriteTransaction.Params.Add('no_auto_undo');

  FTableReferenceForeignKeysList := TStringList.Create;
  // ������ �����-��������� ��������� �������� �� ��������
  FFeatureList := TStringList.Create;

  FUserDocumentTypesToDelete := TgdKeyArray.Create;
  FDontDeleteDocumentTypes := TgdKeyArray.Create;
  FDontDeleteCardArray := TgdKeyArray.Create;
  FDontDeleteCardArray.Sorted := True;

  FDummyInvDocumentKeys := TgdKeyIntAssoc.Create;
  FDummyInvDocumentKeys.Sorted := True;

  FEntryAvailableAnalytics := TStringList.Create;

  FInsertedEntryBalanceRecordCount := 0;
  FProcessState := psUnknown;
  // �������� ���������� � ������� �������� ���. ���������
  FDontBalanceAnalytic := GetDontBalanceAnalyticList;

  FIBSQLGetDepotHeaderKey := TIBSQL.Create(Application);
  FIBSQLInsertGdDocument := TIBSQL.Create(Application);
  FIBSQLInsertDocumentHeader := TIBSQL.Create(Application);
  FIBSQLInsertDocumentPosition := TIBSQL.Create(Application);
  FIBSQLInsertInvCard := TIBSQL.Create(Application);
  FIBSQLInsertInvMovement := TIBSQL.Create(Application);
  FIBSQLDeleteRUID := TIBSQL.Create(Application);
  FQueriesInitialized := False;
end;

destructor TgdClosingPeriod.Destroy;
begin
  FreeAndNil(FWriteTransaction);

  FreeAndNil(FIBSQLDeleteRUID);
  FreeAndNil(FIBSQLInsertGdDocument);
  FreeAndNil(FIBSQLInsertDocumentHeader);
  FreeAndNil(FIBSQLInsertDocumentPosition);
  FreeAndNil(FIBSQLInsertInvCard);
  FreeAndNil(FIBSQLInsertInvMovement);
  FreeAndNil(FIBSQLGetDepotHeaderKey);

  FreeAndNil(FEntryAvailableAnalytics);
  FreeAndNil(FDontDeleteDocumentTypes);
  FreeAndNil(FDontDeleteCardArray);
  FreeAndNil(FDummyInvDocumentKeys);
  FreeAndNil(FUserDocumentTypesToDelete);
  FreeAndNil(FFeatureList);
  FreeAndNil(FTableReferenceForeignKeysList);
end;

procedure TgdClosingPeriod.AddDontDeleteDocumentType(DocType: TID);
begin
  FDontDeleteDocumentTypes.Add(DocType);
end;

procedure TgdClosingPeriod.ClearUserDocumentTypesToDelete;
begin
  FUserDocumentTypesToDelete.Clear;
end;

procedure TgdClosingPeriod.AddUserDocumentTypeToDelete(DocType: TID);
begin
  FUserDocumentTypesToDelete.Add(DocType);
end;

procedure TgdClosingPeriod.ClearDontDeleteDocumentTypes;
begin
  FDontDeleteDocumentTypes.Clear;
end;

procedure TgdClosingPeriod.AddInvCardFeature(FeatureFieldName: String);
begin
  FFeatureList.Add(FeatureFieldName);
end;

procedure TgdClosingPeriod.ClearInvCardFeatures;
begin
  FFeatureList.Clear;
end;

procedure TgdClosingPeriod.CalculateRemains;
var
  moveFieldList, balFieldList, cFieldList: String;
  ibsql: TIBSQL;
  ibsqlOurCompany: TIBSQL;
  OurCompanyListStr: String;
  CurrentContactKey, NextSupplierKey, CurrentSupplierKey: TID;
  LineCount: Integer;
  DocumentParentKey: TID;
begin
  // �������� ����� ������ ������� ��������
  FLocalStartTime := Time;
  // ������������ ��������
  DoOnProcessMessage(0, 1, '������������ ��������...');

  // �������� ������ �����-��������� ��������� �������� �� ��������
  moveFieldList := GetFeatureFieldList('move.');
  balFieldList := GetFeatureFieldList('bal.');
  cFieldList := GetFeatureFieldList('c.');

  // ���� ������� ��� ������� ������� ������ �� ������� ������������, ��
  if FOnlyOurRemains then
  begin
    ibsqlOurCompany := TIBSQL.Create(Application);
    try
      ibsqlOurCompany.Transaction := gdcBaseManager.ReadTransaction;
      ibsqlOurCompany.SQL.Text := 'SELECT companykey FROM gd_ourcompany';
      ibsqlOurCompany.ExecQuery;

      OurCompanyListStr := '';
      while not ibsqlOurCompany.Eof do
      begin
        OurCompanyListStr := OurCompanyListStr + ibsqlOurCompany.FieldByName('companykey').AsString;
        ibsqlOurCompany.Next;
        if not ibsqlOurCompany.Eof then
          OurCompanyListStr := OurCompanyListStr + ',';
      end;
    finally
      FreeAndNil(ibsqlOurCompany);
    end;
  end;

  ibsql := TIBSQL.Create(Application);
  try
    // ������ �� ��������� �������
    // TODO: �������� ���� ��� ������ ���������� (usr$inv_addlinekey) �� ����������
    ibsql.Transaction := gdcBaseManager.ReadTransaction;
    ibsql.SQL.Text :=
      ' SELECT ' +
      '  move.contactkey, ' +
      '  cont.name AS ContactName, ' +
      '  move.SupplierKey, ' +
      '  move.goodkey, ' +
      '  move.companykey, ' +
      '  move.balance ' +
        IIF(moveFieldList <> '', ', ' + moveFieldList, '') +
      ' FROM ' +
      '  ( ' +
      '  SELECT ' +
      '    bal.contactkey, ' +
        IIF(FAddLineKeyFieldExists, ' inv_doc.usr$contactkey ', 'NULL') + ' AS SupplierKey, ' +
      '    bal.goodkey, ' +
      '    bal.companykey, ' +
      '    SUM(bal.balance) AS balance ' +
        IIF(balFieldList <> '', ', ' + balFieldList, '') +
      '  FROM ' +
      '    ( ' +
      '    SELECT ' +
      '      b.contactkey, ' +
      '      c.goodkey, ' +
      '      c.companykey, ' +
      '      SUM(b.balance) AS balance ' +
        IIF(FAddLineKeyFieldExists, ', c.usr$inv_addlinekey ', '') +
        IIF(cFieldList <> '', ', ' + cFieldList, '') +
      '    FROM ' +
      '      inv_balance b ' +
      '      JOIN inv_card c ON c.id = b.cardkey ' +
        IIF(FOnlyOurRemains,
          '      JOIN gd_contact cont ON cont.id = b.contactkey ' +
          '      JOIN gd_contact head_cont ON head_cont.lb <= cont.lb AND head_cont.rb >= cont.rb ', '') +
      '    WHERE ' +
      '      b.balance <> 0 ' +
        IIF(FOnlyOurRemains,
          '      AND head_cont.id IN (' + OurCompanyListStr + ') ', '') +
      '    GROUP BY ' +
      '      b.contactkey, ' +
      '      c.goodkey, ' +
      '      c.companykey ' +
        IIF(FAddLineKeyFieldExists, ', c.usr$inv_addlinekey ', '') +
        IIF(cFieldList <> '', ', ' + cFieldList, '') +
      ' ' +
      '    UNION ALL ' +
      ' ' +
      '    SELECT ' +
      '      m.contactkey, ' +
      '      c.goodkey, ' +
      '      c.companykey, ' +
      '      - SUM(m.debit - m.credit) AS balance ' +
        IIF(FAddLineKeyFieldExists, ', c.usr$inv_addlinekey ', '') +
        IIF(cFieldList <> '', ', ' + cFieldList, '') +
      '    FROM ' +
      '      inv_movement m ' +
      '      JOIN inv_card c on m.cardkey = c.id ' +
        IIF(FOnlyOurRemains,
          '      JOIN gd_contact cont ON cont.id = m.contactkey ' +
          '      JOIN gd_contact head_cont ON head_cont.lb <= cont.lb AND head_cont.rb >= cont.rb ', '') +
      '    WHERE ' +
      '      m.disabled = 0 ' +
      '      AND m.movementdate > :remainsdate ' +
        IIF(FOnlyOurRemains,
          '      AND head_cont.id IN (' + OurCompanyListStr + ') ', '') +
      '    GROUP BY ' +
      '      m.contactkey, ' +
      '      c.goodkey, ' +
      '      c.companykey ' +
        IIF(FAddLineKeyFieldExists, ', c.usr$inv_addlinekey ', '') +
        IIF(cFieldList <> '', ', ' + cFieldList, '') +
      '    ) bal ' +
        IIF(FAddLineKeyFieldExists,
          '    LEFT JOIN usr$inv_addwbillline inv_line ON inv_line.documentkey = bal.usr$inv_addlinekey ' +
          '    LEFT JOIN usr$inv_addwbill inv_doc ON inv_doc.documentkey = inv_line.masterkey ', '') +
      '  GROUP BY ' +
      '    bal.contactkey, ' +
        IIF(FAddLineKeyFieldExists, ' inv_doc.usr$contactkey, ', '') +
      '    bal.goodkey, ' +
      '    bal.companykey ' +
        IIF(balFieldList <> '', ', ' + balFieldList, '') +
      '  ) move ' +
      '   LEFT JOIN gd_contact cont ON cont.id = move.contactkey ' +
      ' ORDER BY ' +
      '   cont.name, move.SupplierKey ';
    ibsql.ParamByName('REMAINSDATE').AsDateTime := FCloseDate;
    ibsql.ExecQuery;                                              // ������� ��� ������� ���

    LineCount := 0;
    CurrentContactKey := -1;
    CurrentSupplierKey := -1;

    // ���� �� �������� ���
    while not ibsql.Eof do
    begin
      // ��� ������� Escape ������� �������
      if FProcessState = psTerminating then
        if Application.MessageBox('���������� �������� �������?', '��������',
           MB_YESNO or MB_ICONQUESTION or MB_SYSTEMMODAL) = IDYES then
          raise Exception.Create('���������� ��������')
        else
          FProcessState := psWorking;

      // ���� �� ���� USR$INV_ADDLINEKEY �������� ����� ����������, �������� ������ ������� � ����
      if not ibsql.FieldByName('SUPPLIERKEY').IsNull then
        NextSupplierKey := GetTID(ibsql.FieldByName('SUPPLIERKEY'))
      else
        NextSupplierKey := FPseudoClientKey;

      // ���� � ����� ������� �� ������ �������, ��� ������� ����������,
      //   ��� ���-�� ������� � ��������� ��������� 2000 (���������� �� ���������),
      //   �� �������� ����� ����� ���������
      if (GetTID(ibsql.FieldByName('CONTACTKEY')) <> CurrentContactKey)
         or (NextSupplierKey <> CurrentSupplierKey)
         or ((LineCount mod 2000) = 0) then
      begin
        // ���� ������� �� ������ �������
        if GetTID(ibsql.FieldByName('CONTACTKEY')) <> CurrentContactKey then
        begin
          // ������������ ��������
          // ������� �������� ����� ������� ����������� ��������
          if CurrentContactKey > 0 then
            DoOnProcessMessage(-1, -1, '  ' + IntToStr(LineCount) + ' �������');
          DoOnProcessMessage(-1, -1, Format('> �������: %s', [ibsql.FieldByName('CONTACTNAME').AsString]));
          // ������� ������� �������
          LineCount := 0;
          // �������� ������� �������
          CurrentContactKey := GetTID(ibsql.FieldByName('CONTACTKEY'));
        end;
        // �������� �������� ����������
        CurrentSupplierKey := NextSupplierKey;
      end;

      // ���� ������� ����������� �� ����� ������ ������� ������ �� CurrentContactKey � CurrentSupplierKey
      if ibsql.FieldByName('BALANCE').AsCurrency >= 0 then
      begin
        // ������� ����� ��������� � ������� �� ID
        DocumentParentKey := AddDepotHeader(CurrentSupplierKey, CurrentContactKey, GetTID(ibsql.FieldByName('COMPANYKEY')));
        // �������� ������� INV_DOCUMENT
        AddDepotPosition(CurrentSupplierKey, CurrentContactKey, GetTID(ibsql.FieldByName('COMPANYKEY')),
          DocumentParentKey, GetTID(ibsql.FieldByName('GOODKEY')), ibsql.FieldByName('BALANCE').AsCurrency, ibsql);
      end
      else
      begin
        // ����� ����� ������ ������ �� FPseudoClientKey � CurrentContactKey (� ������������� ��������� ���-�� ���)
        DocumentParentKey := AddDepotHeader(CurrentContactKey, FPseudoClientKey, GetTID(ibsql.FieldByName('COMPANYKEY')));
        // �������� ������� INV_DOCUMENT
        AddDepotPosition(CurrentContactKey, FPseudoClientKey, GetTID(ibsql.FieldByName('COMPANYKEY')),
          DocumentParentKey, GetTID(ibsql.FieldByName('GOODKEY')), - ibsql.FieldByName('BALANCE').AsCurrency, ibsql);
      end;

      // �������� ������� ������� � ����� ���������
      Inc(LineCount);

      // TODO: ��� ������ ��������� �������� ������� ����� ��������� ����������, ��������� ���� ������� ���������
      //   �� ��������� ���������� ��������, ������������� ������������ ���, ��� ������ ����� ����� �����
      //   �������� ���������������� � ������

      ibsql.Next;
    end;

    // ������������ ��������
    DoOnProcessMessage(1, 1, '������������ �������� ���������...'#13#10 +
      '����������������� ��������: ' + TimeToStr(Time - FLocalStartTime));
  finally
    ibsql.Free;
  end;
end;

procedure TgdClosingPeriod.DeleteDocuments;
const
  UPDATE_INV_CARD_SET_NULL = 'UPDATE inv_card SET %0:s = NULL WHERE %0:s = :dockey;';
  //UPDATE_PACK_INV_CARD_SET_NULL = 'UPDATE inv_card SET %0:s = NULL WHERE %0:s IN (%1:s);';
  //PACK_DOCUMENT_COUNT = 100;
var
  ibsqlDocument: TIBSQL;
  ibsqlDeleteMovement: TIBSQL;
  ibsqlDeleteAddRecord: TIBSQL;
  ibsqlDeleteDocument: TIBSQL;
  ibsqlDeleteEntry: TIBSQL;
  ibsqlUpdateInvCard: TIBSQL;
  DeletedCount: Integer;
  I, DocumentListIndex, DontDeleteIndex: Integer;
  GDDocumentReferenceFieldList: TStringList;
  SQLText: String;
  R: TatRelation;
  DocumentKeysToDelayedDelete: TgdKeyStringAssoc;

  procedure DeleteSingleDocument(const AID: TID; const AdditionalTableName: String; const ForceDelete: Boolean = false);
  begin
    // ������ ������ �� ��������� �������� �� �����-��������� ��������� ��������
    ibsqlUpdateInvCard.Close;
    SetTID(ibsqlUpdateInvCard.ParamByName('DOCKEY'), AID);
    ibsqlUpdateInvCard.ExecQuery;

    // ������ ������� ��������� �� �������������� �������
    try
      ibsqlDeleteAddRecord.Close;
      ibsqlDeleteAddRecord.SQL.Text :=
        ' DELETE FROM ' + AdditionalTableName + ' WHERE documentkey = :dockey ';
      SetTID(ibsqlDeleteAddRecord.ParamByName('DOCKEY'), AID);
      ibsqlDeleteAddRecord.ExecQuery;
    except
      if ForceDelete then
      begin
        // ������� ������� ������ �� ������� ������
        TryToDeleteDocumentReferences(AID, AdditionalTableName);
        // ����� ������� ������� ������
        ibsqlDeleteAddRecord.Close;
        ibsqlDeleteAddRecord.SQL.Text :=
          ' DELETE FROM ' + AdditionalTableName + ' WHERE documentkey = :dockey ';
        SetTID(ibsqlDeleteAddRecord.ParamByName('DOCKEY'), AID);
        ibsqlDeleteAddRecord.ExecQuery;
      end
      else
        raise;
    end;

    // ������ �������� �� ����� ���������
    ibsqlDeleteEntry.Close;
    SetTID(ibsqlDeleteEntry.ParamByName('DOCKEY'), AID);
    ibsqlDeleteEntry.ExecQuery;

    // ������ ��������� �������� �� ����� ���������
    ibsqlDeleteMovement.Close;
    SetTID(ibsqlDeleteMovement.ParamByName('DOCKEY'), AID);
    ibsqlDeleteMovement.ExecQuery;

    // ������ �������� �� GD_DOCUMENT
    try
      ibsqlDeleteDocument.Close;
      SetTID(ibsqlDeleteDocument.ParamByName('DOCKEY'), AID);
      ibsqlDeleteDocument.ExecQuery;

      DeleteRUID(AID);
    except
      on E: Exception do
      begin
        if ForceDelete then
        begin
          // ���� ������ �������� ������� ��-�� ������ �� ��������, ��������� ������� ��� ������
          if (AnsiPos('LINE_FC', E.Message) > 0)
             or (AnsiPos('INV_FK_CARD_PARENT', E.Message) > 0) then
            TryToDeleteInvCardReferences(AID);
          // ������� ������� ������ �� ������� ������
          TryToDeleteDocumentReferences(AID, 'GD_DOCUMENT', GetTID(ibsqlDocument.FieldByName('DOCTYPEKEY')));
          // ����� ������� ������� ������
          ibsqlDeleteDocument.Close;
          SetTID(ibsqlDeleteDocument.ParamByName('DOCKEY'), AID);
          ibsqlDeleteDocument.ExecQuery;
        end
        else
          raise;
      end;
    end;
  end;

begin
  FLocalStartTime := Time;

  // ������������ ��������
  DoOnProcessMessage(0, 1000, '�������� ����������...');

  ibsqlDocument := TIBSQL.Create(Application);
  ibsqlDeleteAddRecord := TIBSQL.Create(Application);
  ibsqlDeleteMovement := TIBSQL.Create(Application);
  ibsqlDeleteDocument := TIBSQL.Create(Application);
  ibsqlDeleteEntry := TIBSQL.Create(Application);
  ibsqlUpdateInvCard := TIBSQL.Create(Application);

  // ������ ����������� �������� ����������
  DocumentKeysToDelayedDelete := TgdKeyStringAssoc.Create;
  try
    DocumentKeysToDelayedDelete.Sorted := False;

    GDDocumentReferenceFieldList := TStringList.Create;
    try
      // ������� ��� ������ �� AC_ENTRY �� GD_DOCUMENT
      R := atDatabase.Relations.ByRelationName('AC_ENTRY');
      for I := 0 to R.RelationFields.Count - 1 do
      begin
        if Assigned(R.RelationFields[I].ForeignKey) and Assigned(R.RelationFields[I].References) then
          if R.RelationFields[I].References.RelationName = 'GD_DOCUMENT' then
            GDDocumentReferenceFieldList.Add(R.RelationFields[I].FieldName);
      end;
      // ������ �� �������� ��������
      ibsqlDeleteEntry.Transaction := FWriteTransaction;
      SQLText := '';
      // ������ ����� �������������� � DeletePackDocuments
      for I := 0 to GDDocumentReferenceFieldList.Count - 1 do
      begin
        if SQLText <> '' then
        begin
          SQLText := SQLText + ' OR ';
        end;
        SQLText := SQLText + ' ( ' + GDDocumentReferenceFieldList.Strings[I] + ' = :dockey ) ';
      end;
      ibsqlDeleteEntry.SQL.Text :=
        'DELETE FROM ac_entry WHERE ' + SQLText;
      ibsqlDeleteEntry.Prepare;

      // ������� ��� ���������������� ������ �� INV_CARD �� GD_DOCUMENT
      GDDocumentReferenceFieldList.Clear;
      R := atDatabase.Relations.ByRelationName('INV_CARD');
      for I := 0 to R.RelationFields.Count - 1 do
      begin
        if Assigned(R.RelationFields[I].ForeignKey) and Assigned(R.RelationFields[I].References) then
          if (R.RelationFields[I].References.RelationName = 'GD_DOCUMENT')
             and (R.RelationFields[I].IsUserDefined) then
            GDDocumentReferenceFieldList.Add(R.RelationFields[I].FieldName);
      end;
      // ������ �� �������� ������ �� ��������� ��������� �� ��������� ��������
      ibsqlUpdateInvCard.Transaction := FWriteTransaction;
      SQLText := #13#10;
      for I := 0 to GDDocumentReferenceFieldList.Count - 1 do
      begin
        SQLText := SQLText + Format(UPDATE_INV_CARD_SET_NULL, [GDDocumentReferenceFieldList.Strings[I]]) + #13#10;
      end;
      ibsqlUpdateInvCard.SQL.Text :=
        'EXECUTE BLOCK (dockey TYPE OF DINTKEY = :dockey) AS BEGIN ' + SQLText + ' END ';
      ibsqlUpdateInvCard.Prepare;
    finally
      GDDocumentReferenceFieldList.Free;
    end;

    // ������� ������ ���������� �� �������� ����������, ������� ����� �� ����������
    ibsqlDocument.Transaction := gdcBaseManager.ReadTransaction;
    ibsqlDeleteAddRecord.Transaction := FWriteTransaction;
    // ������ �� �������� ���������� ��������, ������������ � ������������� ���������
    ibsqlDeleteMovement.Transaction := FWriteTransaction;
    ibsqlDeleteMovement.SQL.Text :=
      ' DELETE FROM inv_movement WHERE documentkey = :dockey ';
    ibsqlDeleteMovement.Prepare;
    // ������ �� �������� ��������� �� gd_document
    ibsqlDeleteDocument.Transaction := FWriteTransaction;
    ibsqlDeleteDocument.SQL.Text :=
      ' DELETE FROM gd_document WHERE id = :dockey ';
    ibsqlDeleteDocument.Prepare;

    // ������ �� ��������� ���������� ��������, �������� ����������� �������� �� ������� ��������,
    //   ������� � �������� �������
    ibsqlDocument.SQL.Text :=
      'SELECT ' +
      '  doc.documentdate, ' +
      '  doc.creationdate, ' +
      '  doc.documenttypekey AS doctypekey, ' +
      '  doc.id AS documentkey, ' +
      '  IIF(doc.parent IS NULL, 0, 1) AS is_position, ' +
      '  IIF(doc.parent IS NULL, headtable.relationname, linetable.relationname) AS addtablename ' +
      'FROM ' +
      '  gd_document doc ' +
      '  LEFT JOIN gd_documenttype t ON t.id = doc.documenttypekey ' +
      '  LEFT JOIN at_relations headtable ON headtable.id = t.headerrelkey ' +
      '  LEFT JOIN at_relations linetable ON linetable.id = t.linerelkey ' +
      'WHERE ' +
      '  doc.documentdate < :closedate ' +
      '  AND t.classname = ''TgdcInvDocumentType'' ' +
      '  AND t.documenttype = ''D'' ' +
      '  AND NOT headtable.id IS NULL ' +
      '  AND NOT linetable.id IS NULL ' +
      'ORDER BY ' +
      '  doc.documentdate DESC, 4 DESC, doc.creationdate DESC, doc.id DESC ';
    ibsqlDocument.ParamByName('CLOSEDATE').AsDateTime := FCloseDate;
    ibsqlDocument.ExecQuery;

    DeletedCount := 0;
    // ���� �� ��������� ����������, ���������� ��������
    while not ibsqlDocument.Eof do
    begin
      // ��� ������� Escape ������� �������
      if FProcessState = psTerminating then
      begin
        if Application.MessageBox('���������� �������� �������?', '��������',
           MB_YESNO or MB_ICONQUESTION or MB_SYSTEMMODAL) = IDYES then
        begin
          // ������� ������ ����������, ������� �� ���������� �������
          if DocumentKeysToDelayedDelete.Count > 0 then
            DoOnProcessMessage(-1, -1, '�� ��������� ���������:');
          I := 0;
          while (I <= DocumentKeysToDelayedDelete.Count - 1) do
          begin
            try
              // ������� ������� ��������
              DeleteSingleDocument(DocumentKeysToDelayedDelete.Keys[I],
                DocumentKeysToDelayedDelete.ValuesByIndex[I], True);
              // ������� �������� �� ������ ����������
              DocumentKeysToDelayedDelete.Delete(I);
            except
              on E: Exception do
              begin
                DoOnProcessMessage(-1, -1, E.Message + #13#10 +
                  DocumentKeysToDelayedDelete.ValuesByIndex[I] +
                  ' ( ' + TID2S(DocumentKeysToDelayedDelete.Keys[I]) + ' )');
                Inc(I);  
              end;
            end;
          end;

          raise Exception.Create('���������� ��������');
        end
        else
          FProcessState := psWorking;
      end;

      // �������� ����� �� ������� ��������
      if not FDontDeleteCardArray.Find(GetTID(ibsqlDocument.FieldByName('DOCUMENTKEY')), DontDeleteIndex) then
      begin
        // ������ ������� �������� � ��� ��������
        try
          // ������� ������� ��������
          DeleteSingleDocument(GetTID(ibsqlDocument.FieldByName('DOCUMENTKEY')),
            ibsqlDocument.FieldByName('ADDTABLENAME').AsString, True);
          Inc(DeletedCount);
        except
          // ������������ ������ �������� ���������
          on E: Exception do
          begin
            // ������� �������� � ������ ����������� ��������
            DocumentListIndex := DocumentKeysToDelayedDelete.Add(GetTID(ibsqlDocument.FieldByName('DOCUMENTKEY')));
            DocumentKeysToDelayedDelete.ValuesByIndex[DocumentListIndex] := ibsqlDocument.FieldByName('ADDTABLENAME').AsString;
          end;
        end;

        if (DeletedCount > 0) and (DeletedCount mod 5000 = 0) then
        begin
          // ����������� ����������
          FWriteTransaction.Commit;
          FWriteTransaction.StartTransaction;
        end;

        // ������ 50000 ���������� ����� ��������� ���������� ��������
        if (DocumentKeysToDelayedDelete.Count > 0) and (DeletedCount > 0) and (DeletedCount mod 50000 = 0) then
        begin
          DoOnProcessMessage(-1, -1, '������: ' + IntToStr(DocumentKeysToDelayedDelete.Count));

          I := 0;
          while (I <= DocumentKeysToDelayedDelete.Count - 1) do
          begin
            try
              // ������� ������� ��������
              DeleteSingleDocument(DocumentKeysToDelayedDelete.Keys[I],
                DocumentKeysToDelayedDelete.ValuesByIndex[I], True);
              Inc(DeletedCount);
              // ������� �������� �� ������ ����������
              DocumentKeysToDelayedDelete.Delete(I);
            except
              Inc(I);
              // ���� �� ���������� �������, �� ������ �� ������ - ������� ������� � ��������� ���
            end;
          end;
        end;

        // ������������ ��������
        DoOnProcessMessage(DeletedCount, -1, '');
      end;

      // �������� � ���������� ���������
      ibsqlDocument.Next;
    end;

    // ��������� ��� ������� ������� ���������� ���������
    if DocumentKeysToDelayedDelete.Count > 0 then
    begin
      DoOnProcessMessage(-1, -1, '�� ��������� ���������:');
      I := 0;
      while (I <= DocumentKeysToDelayedDelete.Count - 1) do
      begin
        try
          // ������� ������� ��������
          DeleteSingleDocument(DocumentKeysToDelayedDelete.Keys[I],
            DocumentKeysToDelayedDelete.ValuesByIndex[I], True);
          Inc(DeletedCount);
          // ������� �������� �� ������ ����������
          DocumentKeysToDelayedDelete.Delete(I);
        except
          on E: Exception do
          begin
            DoOnProcessMessage(-1, -1, E.Message + #13#10 +
              DocumentKeysToDelayedDelete.ValuesByIndex[I] +
              ' ( ' + TID2S(DocumentKeysToDelayedDelete.Keys[I]) + ' )');
            Inc(I);
          end;
        end;
      end;
    end;

    // ������������ ��������
    DoOnProcessMessage(DeletedCount, DeletedCount, '');
    DoOnProcessMessage(-1, -1, TimeToStr(Time) + ': �������� ������� �������� ����������...'#13#10 +
      IntToStr(DeletedCount) + ' �������, ' + IntToStr(DocumentKeysToDelayedDelete.Count) + ' ������'#13#10 +
      '����������������� ��������: ' + TimeToStr(Time - FLocalStartTime));
  finally
    FreeAndNil(DocumentKeysToDelayedDelete);

    FreeAndNil(ibsqlUpdateInvCard);
    FreeAndNil(ibsqlDeleteEntry);
    FreeAndNil(ibsqlDeleteAddRecord);
    FreeAndNil(ibsqlDeleteDocument);
    FreeAndNil(ibsqlDeleteMovement);
    FreeAndNil(ibsqlDocument);
  end;
end;

procedure TgdClosingPeriod.DeleteEntry;
var
  ibsql: TIBSQL;
begin
  FLocalStartTime := Time;

  // ������������ ��������
  DoOnProcessMessage(0, 1, '�������� ��������...');

  ibsql := TIBSQL.Create(Application);
  try
    ibsql.Transaction := FWriteTransaction;
    ibsql.SQL.Text := 'DELETE FROM ac_entry WHERE entrydate < :closedate ';
    ibsql.ParamByName('CLOSEDATE').AsDateTime := FCloseDate;
    ibsql.ExecQuery;
  finally
    ibsql.Free;
  end;

  // ������������ ��������
  DoOnProcessMessage(1, 1, '�������� �������� ���������'#13#10 +
    '����������������� ��������: ' + TimeToStr(Time - FLocalStartTime));
end;

procedure TgdClosingPeriod.DeleteUserDocuments;
var
  ibsqlSelectDocument: TIBSQL;
  ibsqlDeleteDocument, ibsqlDeleteUserRecord: TIBSQL;
  DocumentTypeCounter: Integer;
  DocumentTypeListStr: String;
  CurrentRelationName: String;
  DeletedCount, DocumentListIndex, I, AllRecordCount: Integer;
  DocumentKeysToDelayedDelete: TgdKeyStringAssoc;

  procedure DeleteSingleDocument(const AID: TID; const AdditionalTableName: String);
  begin
    if CurrentRelationName <> AdditionalTableName then
    begin
      CurrentRelationName := AdditionalTableName;
      ibsqlDeleteUserRecord.Close;
      ibsqlDeleteUserRecord.SQL.Text :=
        Format('DELETE FROM %0:s WHERE documentkey = :documentkey', [CurrentRelationName]);
      ibsqlDeleteUserRecord.Prepare;
    end;

    // ������ ������ �� ���������������� �������
    try
      ibsqlDeleteUserRecord.Close;
      SetTID(ibsqlDeleteUserRecord.ParamByName('DOCUMENTKEY'), AID);
      ibsqlDeleteUserRecord.ExecQuery;
    except
      // ������� ������� ������ �� ������� ������
      TryToDeleteDocumentReferences(AID, CurrentRelationName);
      // ����� ������� ������� ������
      ibsqlDeleteUserRecord.Close;
      SetTID(ibsqlDeleteUserRecord.ParamByName('DOCUMENTKEY'), AID);
      ibsqlDeleteUserRecord.ExecQuery;
    end;

    // ������ ������ �� gd_document
    try
      DeleteRUID(AID);

      ibsqlDeleteDocument.Close;
      SetTID(ibsqlDeleteDocument.ParamByName('DOCUMENTKEY'), AID);
      ibsqlDeleteDocument.ExecQuery;
    except
      // ������� ������� ������ �� ������� ������
      TryToDeleteDocumentReferences(AID, 'GD_DOCUMENT');
      // ����� ������� ������� ������
      ibsqlDeleteDocument.Close;
      SetTID(ibsqlDeleteDocument.ParamByName('DOCUMENTKEY'), AID);
      ibsqlDeleteDocument.ExecQuery;
    end;
  end;

begin
  FLocalStartTime := Time;

  // ������������ ��������
  DoOnProcessMessage(0, 1, '�������� ���������������� ����������...');

  // ���� ������ ���� �� ���� ��� ���������������� ����������
  if FUserDocumentTypesToDelete.Count > 0 then
  begin
    // ���������� ������ � ID ����� ���������������� ����������
    for DocumentTypeCounter := 0 to FUserDocumentTypesToDelete.Count - 1 do
    begin
      if DocumentTypeListStr <> '' then
        DocumentTypeListStr := DocumentTypeListStr + ', ';
      DocumentTypeListStr := DocumentTypeListStr + TID2S(FUserDocumentTypesToDelete.Keys[DocumentTypeCounter]);
    end;

    ibsqlSelectDocument := TIBSQL.Create(Application);
    ibsqlDeleteDocument := TIBSQL.Create(Application);
    ibsqlDeleteUserRecord := TIBSQL.Create(Application);
    // ������ ����������� �������� ����������
    DocumentKeysToDelayedDelete := TgdKeyStringAssoc.Create;
    try
      // ������ ��� �������� ������ �� gd_document �� ����������� ID
      ibsqlDeleteDocument.Transaction := FWriteTransaction;
      ibsqlDeleteDocument.SQL.Text := 'DELETE FROM gd_document WHERE id = :documentkey';
      ibsqlDeleteDocument.Prepare;

      ibsqlDeleteUserRecord.Transaction := FWriteTransaction;

      // ������ �������� ���������������� ��������� ���������� �����, ������� ������� �� ���� ��������
      //   ��������� �� � ������� �������� �� ����, ����� �� ID
      ibsqlSelectDocument.Transaction := gdcBaseManager.ReadTransaction;
      ibsqlSelectDocument.SQL.Text := Format(
        'SELECT ' +
        '  d.id AS documentkey, ' +
        '  t.id AS doctypekey, ' +
        '  IIF(d.parent IS NULL, h_rel.relationname, l_rel.relationname) AS add_rel_name ' +
        'FROM ' +
        '  gd_document d ' +
        '  LEFT JOIN gd_documenttype t ON t.id = d.documenttypekey ' +
        '  LEFT JOIN at_relations h_rel ON h_rel.id = t.headerrelkey ' +
        '  LEFT JOIN at_relations l_rel ON l_rel.id = t.linerelkey ' +
        'WHERE ' +
        '  d.documentdate < :closedate ' +
        '  AND d.documenttypekey IN (%0:s) ' +
        '  AND NOT t.headerrelkey IS NULL ' +
        'ORDER BY ' +
        '  d.documentdate DESC, d.id DESC', [DocumentTypeListStr]);
      ibsqlSelectDocument.ParamByName('CLOSEDATE').AsDateTime := FCloseDate;
      ibsqlSelectDocument.ExecQuery;

      // ��������� ����� ���-�� ���������� �������
      AllRecordCount := GetQueryRecordCount(ibsqlSelectDocument);
      if AllRecordCount > -1 then
        DoOnProcessMessage(0, AllRecordCount, '');

      CurrentRelationName := '';
      DeletedCount := 0;
      while not ibsqlSelectDocument.Eof do
      begin
        // ��� ������� Escape ������� �������
        if FProcessState = psTerminating then
        begin
          if Application.MessageBox('���������� �������� �������?', '��������',
             MB_YESNO or MB_ICONQUESTION or MB_SYSTEMMODAL) = IDYES then
            raise Exception.Create('���������� ��������')
          else
            FProcessState := psWorking;
        end;

        // ������ ������� ��������
        try
          // ������� ������� ��������
          DeleteSingleDocument(GetTID(ibsqlSelectDocument.FieldByName('DOCUMENTKEY')),
            ibsqlSelectDocument.FieldByName('ADD_REL_NAME').AsString);
          Inc(DeletedCount);
        except
          // ������������ ������ �������� ���������
          on E: Exception do
          begin
            // ������� �������� � ������ ����������� ��������
            DocumentListIndex := DocumentKeysToDelayedDelete.Add(GetTID(ibsqlSelectDocument.FieldByName('DOCUMENTKEY')));
            DocumentKeysToDelayedDelete.ValuesByIndex[DocumentListIndex] := ibsqlSelectDocument.FieldByName('ADD_REL_NAME').AsString;
          end;
        end;

        if (DeletedCount > 0) and (DeletedCount mod 5000 = 0) then
        begin
          // ����������� ����������
          FWriteTransaction.Commit;
          FWriteTransaction.StartTransaction;
        end;

        // ������ 50000 ���������� ����� ��������� ���������� ��������
        if (DocumentKeysToDelayedDelete.Count > 0) and (DeletedCount > 0) and (DeletedCount mod 50000 = 0) then
        begin
          DoOnProcessMessage(-1, -1, '������: ' + IntToStr(DocumentKeysToDelayedDelete.Count));

          I := 0;
          while (I <= DocumentKeysToDelayedDelete.Count - 1) do
          begin
            try
              // ������� ������� ��������
              DeleteSingleDocument(DocumentKeysToDelayedDelete.Keys[I],
                DocumentKeysToDelayedDelete.ValuesByIndex[I]);
              Inc(DeletedCount);
              // ������� �������� �� ������ ����������
              DocumentKeysToDelayedDelete.Delete(I);
            except
              Inc(I);
              // ���� �� ���������� �������, �� ������ �� ������ - ������� ������� � ��������� ���
            end;
          end;
        end;

        // ������������ ��������
        DoOnProcessMessage(DeletedCount, -1, '');

        ibsqlSelectDocument.Next;
      end;

      // ������������ ��������
      DoOnProcessMessage(DeletedCount, DeletedCount, '');
      DoOnProcessMessage(-1, -1, TimeToStr(Time) + ': �������� ������� �������� ���������������� ����������...'#13#10 +
        IntToStr(DeletedCount) + ' �������, ' + IntToStr(DocumentKeysToDelayedDelete.Count) + ' ������'#13#10 +
        '����������������� ��������: ' + TimeToStr(Time - FLocalStartTime));
    finally
      FreeAndNil(DocumentKeysToDelayedDelete);
      ibsqlDeleteUserRecord.Free;
      ibsqlDeleteDocument.Free;
      ibsqlSelectDocument.Free;
    end;
  end;
end;

procedure TgdClosingPeriod.DoClosePeriod;
begin
  // �������� ���� ���������� ��������� ��������
  FWorkingThread := TgdClosingThread.Create(True);             
  TgdClosingThread(FWorkingThread).Model := Self;
  FWorkingThread.FreeOnTerminate := True;
  FWorkingThread.Priority := tpLower;
  FWorkingThread.Resume;
end;

{procedure TgdClosingPeriod.InsertDatabaseRecord;
var
  ibsql: TIBSQL;
begin
  ibsql := TIBSQL.Create(nil);
  try
    ibsql.Transaction := FWriteTransaction;
    ibsql.SQL.Text :=
      'INSERT INTO db_closehistory (databasepath, server, username, userpassword, closedate) ' +
      'VALUES (:path, :server, :username, :userpassword, :closedate) ';
    ibsql.ParamByName('PATH').AsString := FExtDatabasePath;
    ibsql.ParamByName('SERVER').AsString := FExtDatabaseServer;
    ibsql.ParamByName('USERNAME').AsString := FExtDatabaseUser;
    ibsql.ParamByName('USERPASSWORD').AsString := FExtDatabasePassword;
    ibsql.ParamByName('CLOSEDATE').AsDateTime := FCloseDate;
    ibsql.ExecQuery;
  finally
    ibsql.Free;
  end;
end;}

procedure TgdClosingPeriod.ReBindDepotCards;
const
  UPDATE_DOCUMENT_CARDKEY_TEMPLATE =
    'UPDATE ' +
    '  %0:s line ' +
    'SET ' +
    '  line.%1:s = :new_cardkey ' +
    'WHERE ' +
    '  line.%1:s = :old_cardkey ' +
    '  AND (SELECT doc.documentdate FROM gd_document doc WHERE doc.id = line.documentkey) >= :closedate ';
  CardkeyFieldCount = 2;
  CardkeyFieldNames: array[0..CardkeyFieldCount - 1] of String = ('FROMCARDKEY', 'TOCARDKEY');
var
  ibsql: TIBSQL;
  ibsqlSearchNewCardkey: TIBSQL;
  ibsqlUpdateCard: TIBSQL;
  ibsqlUpdateFirstDocKey: TIBSQL;
  ibsqlUpdateInvMovement: TIBSQL;
  ibsqlUpdateDocumentCardkey: TIBSQL;
  CurrentCardKey, CurrentFirstDocKey, CurrentFromContactkey, CurrentToContactkey: TID;
  CurrentRelationName: String;
  DocumentParentKey: TID;
  NewCardKey, FirstDocumentKey: TID;
  FirstDate: TDateTime;
  FeatureCounter, RecordCounter: Integer;
  cFeatureList: String;

  procedure UpdateInvCard(const OldCardkey, NewCardkey: TID);
  begin
    // ������� ������ �� ������������ ��������
    SetTID(ibsqlUpdateCard.ParamByName('OLD_PARENT'), OldCardkey);
    SetTID(ibsqlUpdateCard.ParamByName('NEW_PARENT'), NewCardkey);
    ibsqlUpdateCard.ExecQuery;
    ibsqlUpdateCard.Close;
  end;

  procedure UpdateFirstDocKey(const OldDocKey, NewDocKey: TID; const NewDocDate: TDateTime);
  begin
    if NewDocKey > -1 then
    begin
      // ������� ������ �� ������������ ��������
      SetTID(ibsqlUpdateFirstDocKey.ParamByName('OLDDOCKEY'), OldDocKey);
      SetTID(ibsqlUpdateFirstDocKey.ParamByName('NEWDOCKEY'), NewDocKey);
      ibsqlUpdateFirstDocKey.ParamByName('NEWDATE').AsDateTime := NewDocDate;
      ibsqlUpdateFirstDocKey.ExecQuery;
      ibsqlUpdateFirstDocKey.Close;
    end;  
  end;

  procedure UpdateInvMovement(const OldCardkey, NewCardkey: TID);
  begin
    // ������� ������ �� �������� �� ��������
    SetTID(ibsqlUpdateInvMovement.ParamByName('OLD_CARDKEY'), OldCardkey);
    SetTID(ibsqlUpdateInvMovement.ParamByName('NEW_CARDKEY'), NewCardkey);
    ibsqlUpdateInvMovement.ExecQuery;
    ibsqlUpdateInvMovement.Close;
  end;

  procedure UpdateDocumentCardkey(const RelationName: String; const OldCardkey, NewCardkey: TID);
  var
    I: Integer;
  begin
    for I := 0 to CardkeyFieldCount - 1 do
    begin
      if Assigned(atDatabase.FindRelationField(RelationName, CardkeyFieldNames[I])) then
      begin
        ibsqlUpdateDocumentCardkey.SQL.Text := Format(UPDATE_DOCUMENT_CARDKEY_TEMPLATE,
          [RelationName, CardkeyFieldNames[I]]);
        SetTID(ibsqlUpdateDocumentCardkey.ParamByName('OLD_CARDKEY'), OldCardkey);
        SetTID(ibsqlUpdateDocumentCardkey.ParamByName('NEW_CARDKEY'), NewCardkey);
        ibsqlUpdateDocumentCardkey.ParamByName('CLOSEDATE').AsDateTime := FCloseDate;
        ibsqlUpdateDocumentCardkey.ExecQuery;
        ibsqlUpdateDocumentCardkey.Close;
      end;
    end;
  end;

begin
  InitializeIBSQLQueries;
  
  FLocalStartTime := Time;

  // ������������ ��������
  DoOnProcessMessage(0, 35000, '������������ ��������� ��������...');

  ibsql := TIBSQL.Create(Application);
  ibsqlSearchNewCardkey := TIBSQL.Create(Application);
  ibsqlUpdateCard := TIBSQL.Create(Application);
  ibsqlUpdateFirstDocKey := TIBSQL.Create(Application);
  ibsqlUpdateInvMovement := TIBSQL.Create(Application);
  ibsqlUpdateDocumentCardkey := TIBSQL.Create(Application);
  try
    // ��������� ������ �� ������������ ��������
    ibsqlUpdateCard.Transaction := FWriteTransaction;
    ibsqlUpdateCard.SQL.Text :=
      'UPDATE ' +
      '  inv_card c ' +
      'SET ' +
      '  c.parent = :new_parent ' +
      'WHERE ' +
      '  c.parent = :old_parent ' +
      '  AND (SELECT FIRST(1) m.movementdate ' +
      '       FROM inv_movement m ' +
      '       WHERE m.cardkey = c.id ' +
      '       ORDER BY m.movementdate DESC) >= :closedate ';
    ibsqlUpdateCard.ParamByName('CLOSEDATE').AsDateTime := FCloseDate;
    ibsqlUpdateCard.Prepare;
    // ��������� ������ �� �������� ������� � ���� �������
    ibsqlUpdateFirstDocKey.Transaction := FWriteTransaction;
    ibsqlUpdateFirstDocKey.SQL.Text :=
      'UPDATE inv_card c ' +
      'SET ' +
      '  c.firstdocumentkey = :newdockey, ' +
      '  c.firstdate = :newdate ' +
      'WHERE ' +
      '  c.firstdocumentkey = :olddockey ';
    ibsqlUpdateFirstDocKey.Prepare;
    // ��������� � �������� ������ �� ��������� ��������
    ibsqlUpdateInvMovement.Transaction := FWriteTransaction;
    ibsqlUpdateInvMovement.SQL.Text :=
      'UPDATE ' +
      '  inv_movement m ' +
      'SET ' +
      '  m.cardkey = :new_cardkey ' +
      'WHERE ' +
      '  m.cardkey = :old_cardkey ' +
      '  AND m.movementdate >= :closedate ';
    ibsqlUpdateInvMovement.ParamByName('CLOSEDATE').AsDateTime := FCloseDate;
    ibsqlUpdateInvMovement.Prepare;
    // ��������� � ��������������� �������� ��������� ���������� ������ �� ��������� ��������
    ibsqlUpdateDocumentCardkey.Transaction := FWriteTransaction;

    // ������� ���������� �������� � ��������� ��������
    ibsqlSearchNewCardkey.Transaction := FWriteTransaction;

    // ������� ������ ��������� ��������� ��������� ��������
    cFeatureList := GetFeatureFieldList('c.');
    // �������� ��� �������� ������� ��������� � �������� �� ����� ��������
    ibsql.Transaction := gdcBaseManager.ReadTransaction;
    ibsql.SQL.Text :=
      'SELECT' + #13#10 +
      '  m1.contactkey as fromcontactkey,' + #13#10 +
      '  m.contactkey as tocontactkey,' + #13#10 +
      '  linerel.relationname,' + #13#10 +
      '  c.id AS cardkey_new, ' + #13#10 +
      '  c1.id as cardkey_old,' + #13#10 +
      '  c.goodkey,' + #13#10 +
      '  c.companykey, c.firstdocumentkey' + #13#10 +
        IIF(cFeatureList <> '', ', ' + cFeatureList + #13#10, '') +
      'FROM' + #13#10 +
      '  gd_document d' + #13#10 +
      '  JOIN gd_documenttype t ON t.id = d.documenttypekey' + #13#10 +
      '  LEFT JOIN inv_movement m ON m.documentkey = d.id' + #13#10 +
      '  LEFT JOIN inv_movement m1 ON m1.movementkey = m.movementkey AND m1.id <> m.id' + #13#10 +
      '  LEFT JOIN inv_card c ON c.id = m.cardkey' + #13#10 +
      '  LEFT JOIN inv_card c1 ON c1.id = m1.cardkey' + #13#10 +
      '  LEFT JOIN gd_document d_old ON ((d_old.id = c.documentkey) or (d_old.id = c1.documentkey))' + #13#10 +
      '  LEFT JOIN at_relations linerel ON linerel.id = t.linerelkey' + #13#10 +
      'WHERE' + #13#10 +
      '  d.documentdate >= :closedate' + #13#10 +
      '  AND t.classname = ''TgdcInvDocumentType''' + #13#10 +
      '  AND t.documenttype = ''D''' + #13#10 +
      '  AND d_old.documentdate < :closedate';
    ibsql.ParamByName('CLOSEDATE').AsDateTime := FCloseDate;
    ibsql.ExecQuery;

    RecordCounter := 0;
    FirstDocumentKey := -1;
    FirstDate := FCloseDate;
    while not ibsql.Eof do
    begin
      // ��� ������� Escape ������� �������
      if FProcessState = psTerminating then
        if Application.MessageBox('���������� �������� �������?', '��������',
           MB_YESNO or MB_ICONQUESTION or MB_SYSTEMMODAL) = IDYES then
          raise Exception.Create('���������� ��������')
        else
          FProcessState := psWorking;

      // ������������ ��������
      Inc(RecordCounter);
      DoOnProcessMessage(RecordCounter, -1, '');

      if ibsql.FieldByName('CARDKEY_OLD').IsNull then
        CurrentCardKey := GetTID(ibsql.FieldByName('CARDKEY_NEW'))
      else
        CurrentCardKey := GetTID(ibsql.FieldByName('CARDKEY_OLD'));
      CurrentFirstDocKey := GetTID(ibsql.FieldByName('FIRSTDOCUMENTKEY'));
      CurrentFromContactkey := GetTID(ibsql.FieldByName('FROMCONTACTKEY'));
      CurrentToContactkey := GetTID(ibsql.FieldByName('TOCONTACTKEY'));
      CurrentRelationName := ibsql.FieldByName('RELATIONNAME').AsString;

      if (CurrentFromContactkey > 0) or (CurrentToContactkey > 0) then
      begin
        // ������ ���������� �������� ��� ������ ���������
        ibsqlSearchNewCardkey.SQL.Text := SEARCH_NEW_CARDKEY_TEMPLATE;
        for FeatureCounter := 0 to FFeatureList.Count - 1 do
        begin
          if not ibsql.FieldByName(FFeatureList.Strings[FeatureCounter]).IsNull then
            ibsqlSearchNewCardkey.SQL.Text := ibsqlSearchNewCardkey.SQL.Text +
              Format(' AND card.%0:s = :%0:s ', [FFeatureList.Strings[FeatureCounter]])
          else
            ibsqlSearchNewCardkey.SQL.Text := ibsqlSearchNewCardkey.SQL.Text +
              Format(' AND card.%0:s IS NULL ', [FFeatureList.Strings[FeatureCounter]]);
        end;
        ibsqlSearchNewCardkey.ParamByName('CLOSEDATE').AsDateTime := FCloseDate;
        SetTID(ibsqlSearchNewCardkey.ParamByName('GOODKEY'), ibsql.FieldByName('GOODKEY'));
        SetTID(ibsqlSearchNewCardkey.ParamByName('CONTACT_01'), CurrentFromContactkey);
        SetTID(ibsqlSearchNewCardkey.ParamByName('CONTACT_02'), CurrentToContactkey);
        for FeatureCounter := 0 to FFeatureList.Count - 1 do
        begin
          if not ibsql.FieldByName(FFeatureList.Strings[FeatureCounter]).IsNull then
            SetVar2Param(ibsqlSearchNewCardkey.ParamByName(FFeatureList.Strings[FeatureCounter]),
              GetFieldAsVar(ibsql.FieldByName(FFeatureList.Strings[FeatureCounter])));
        end;
        ibsqlSearchNewCardkey.ExecQuery;

        // ���� �� ����� ���������� ��������, ��������� ���������� �������� INV_DOCUMENT
        if ibsqlSearchNewCardkey.RecordCount > 0 then
        begin
          NewCardKey := GetTID(ibsqlSearchNewCardkey.FieldByName('CARDKEY'));
          FirstDocumentKey := GetTID(ibsqlSearchNewCardkey.FieldByName('FIRSTDOCUMENTKEY'));
          FirstDate := ibsqlSearchNewCardkey.FieldByName('FIRSTDATE').AsDateTime;
        end
        else
        begin
          // ������ �������� ��� ���. ���������
          ibsqlSearchNewCardkey.Close;
          ibsqlSearchNewCardkey.SQL.Text := SEARCH_NEW_CARDKEY_TEMPLATE;
          ibsqlSearchNewCardkey.ParamByName('CLOSEDATE').AsDateTime := FCloseDate;
          SetTID(ibsqlSearchNewCardkey.ParamByName('GOODKEY'), ibsql.FieldByName('GOODKEY'));
          SetTID(ibsqlSearchNewCardkey.ParamByName('CONTACT_01'), CurrentFromContactkey);
          SetTID(ibsqlSearchNewCardkey.ParamByName('CONTACT_02'), CurrentToContactkey);
          ibsqlSearchNewCardkey.ExecQuery;

          if ibsqlSearchNewCardkey.RecordCount > 0 then
          begin
            NewCardKey := GetTID(ibsqlSearchNewCardkey.FieldByName('CARDKEY'));
            FirstDocumentKey := GetTID(ibsqlSearchNewCardkey.FieldByName('FIRSTDOCUMENTKEY'));
            FirstDate := ibsqlSearchNewCardkey.FieldByName('FIRSTDATE').AsDateTime;
          end
          else
          begin
            // ����� ������� �������� �������� �������, � ������������ �� ��������� �� ��������
            DocumentParentKey := AddDepotHeader(CurrentFromContactkey, CurrentFromContactkey, GetTID(ibsql.FieldByName('COMPANYKEY')));
            NewCardKey := AddDepotPosition(CurrentFromContactkey, CurrentFromContactkey, GetTID(ibsql.FieldByName('COMPANYKEY')),
              DocumentParentKey, GetTID(ibsql.FieldByName('GOODKEY')), 0);

            DoOnProcessMessage(-1, -1, Format('  ������ �������� �������� ������� ID = %0:d', [TID264(DocumentParentKey)]));
          end;
        end;
        ibsqlSearchNewCardkey.Close;
      end
      else
      begin
        // ������ ���������� �������� ��� ������ ���������
        ibsqlSearchNewCardkey.SQL.Text := SEARCH_NEW_CARDKEY_TEMPLATE_SIMPLE;
        for FeatureCounter := 0 to FFeatureList.Count - 1 do
        begin
          if not ibsql.FieldByName(FFeatureList.Strings[FeatureCounter]).IsNull then
            ibsqlSearchNewCardkey.SQL.Text := ibsqlSearchNewCardkey.SQL.Text +
              Format(' AND card.%0:s = :%0:s ', [FFeatureList.Strings[FeatureCounter]])
          else
            ibsqlSearchNewCardkey.SQL.Text := ibsqlSearchNewCardkey.SQL.Text +
              Format(' AND card.%0:s IS NULL ', [FFeatureList.Strings[FeatureCounter]]);
        end;
        ibsqlSearchNewCardkey.ParamByName('CLOSEDATE').AsDateTime := FCloseDate;
        SetTID(ibsqlSearchNewCardkey.ParamByName('DOCTYPEKEY'), FInvDocumentTypeKey);
        SetTID(ibsqlSearchNewCardkey.ParamByName('GOODKEY'), ibsql.FieldByName('GOODKEY'));
        for FeatureCounter := 0 to FFeatureList.Count - 1 do
        begin
          if not ibsql.FieldByName(FFeatureList.Strings[FeatureCounter]).IsNull then
            SetVar2Param(ibsqlSearchNewCardkey.ParamByName(FFeatureList.Strings[FeatureCounter]),
              GetFieldAsVar(ibsql.FieldByName(FFeatureList.Strings[FeatureCounter])));
        end;
        ibsqlSearchNewCardkey.ExecQuery;

        if ibsqlSearchNewCardkey.RecordCount > 0 then
          NewCardKey := GetTID(ibsqlSearchNewCardkey.FieldByName('CARDKEY'))
        else
          NewCardKey := -1;
          
        ibsqlSearchNewCardkey.Close;
      end;

      if NewCardKey > 0 then
      begin
        UpdateInvCard(CurrentCardKey, NewCardKey);                                // ������� ������ �� ������������ ��������
        UpdateFirstDocKey(CurrentFirstDocKey, FirstDocumentKey, FirstDate);       // ������� ������ �� �������� ������� � ���� �������
        UpdateInvMovement(CurrentCardKey, NewCardKey);                            // ������� ������ �� �������� �� ��������
        UpdateDocumentCardkey(CurrentRelationName, CurrentCardKey, NewCardKey);   // ������� ������ �� �������� � ��������� ����������
      end
      else
      begin
        DoOnProcessMessage(-1, -1, Format('  ������ ������������ �������� OLD_CARDKEY = %0:d', [TID264(CurrentCardKey)]));
      end;

      ibsql.Next;
    end;

    // ������������ ��������
    DoOnProcessMessage(RecordCounter, RecordCounter,
      '�������� ������� ������������ ��������� ��������...'#13#10 +
      '����������������� ��������: ' + TimeToStr(Time - FLocalStartTime));
  finally
    ibsqlUpdateDocumentCardkey.Free;
    ibsqlUpdateInvMovement.Free;
    ibsqlUpdateFirstDocKey.Free;
    ibsqlUpdateCard.Free;
    ibsqlSearchNewCardkey.Free;
    ibsql.Free;
  end;
end;

procedure TgdClosingPeriod.SetTriggerActive(SetActive: Boolean);
const
  AlterTriggerCount = 4;
  // �������� INV_BU_CARD ��-�� ������ Too many concurrent executions of the same request ��� ����������
  //  parent ��������
  AlterTriggerArray: array[0 .. AlterTriggerCount - 1] of String =
    ('INV_BD_MOVEMENT', 'INV_BU_MOVEMENT', 'AC_ENTRY_DO_BALANCE', 'INV_BU_CARD');
var
  ibsql: TIBSQL;
  WasActive: Boolean;
  StateStr: String;
  I: Integer;
begin
  WasActive := FWriteTransaction.Active;
  // ���������\����������� ��������� �������� �� ��������� ����������
  if WasActive then
    FWriteTransaction.Commit;
  FWriteTransaction.StartTransaction;

  if SetActive then
  begin
    StateStr := 'ACTIVE';
    DoOnProcessMessage(-1, -1, '��������� ���������');
  end
  else
  begin
    StateStr := 'INACTIVE';
    DoOnProcessMessage(-1, -1, '����������� ���������');
  end;

  ibsql := TIBSQL.Create(Application);
  try
    ibsql.Transaction := FWriteTransaction;

    for I := 0 to AlterTriggerCount - 1 do
    begin
      ibsql.SQL.Text := 'ALTER TRIGGER ' + AlterTriggerArray[I] + ' '  + StateStr;
      ibsql.ExecQuery;
      ibsql.Close;
    end;
  finally
    ibsql.Free;
  end;

  FWriteTransaction.Commit;
  if WasActive then
    FWriteTransaction.StartTransaction;
end;

procedure TgdClosingPeriod.TryToDeleteDocumentReferences(const AID: TID;
  const AdditionalRelationName: String; const ADocTypeKey: TID = -1);
var
  TableReferenceIndex: Integer;
  OL: TObjectList;
  ibsql, ibsqlUpdate, ibsqlSelect: TIBSQL;
  ReferencesRelationName, ReferencesFieldName: String;
  AdditionalFieldName: String;
  ForeignKeyCounter: Integer;
begin
  // �������� ��� ���������� ������� ������ ������� ������, ���� ��� ��� ���
  if not FTableReferenceForeignKeysList.Find(AdditionalRelationName, TableReferenceIndex) then
  begin
    // �������� ����� ������ ������� ������ ����������� �� ���������� �������
    TableReferenceIndex := FTableReferenceForeignKeysList.AddObject(AdditionalRelationName, TObjectList.Create(False));
    OL := TObjectList.Create(False);
    try
      // ������� ������ ������� ������ ����������� �� ���������� �������
      atDatabase.ForeignKeys.ConstraintsByReferencedRelation(AdditionalRelationName, OL);
      // ������� ������ ������� ������� �����
      for ForeignKeyCounter := 0 to OL.Count - 1 do
      begin
        if TatForeignKey(OL.Items[ForeignKeyCounter]).IsSimpleKey
           and TatForeignKey(OL.Items[ForeignKeyCounter]).ConstraintField.IsUserDefined then
          TObjectList(FTableReferenceForeignKeysList.Objects[TableReferenceIndex]).Add(OL.Items[ForeignKeyCounter]);
      end;
    except
      OL.Free;
    end;
  end;

  // ������� �� ������ ������� ������, � ������ ������ ����������� �� ����������
  OL := TObjectList(FTableReferenceForeignKeysList.Objects[TableReferenceIndex]);
  ibsql := TIBSQL.Create(Application);
  ibsqlUpdate := TIBSQL.Create(Application);
  ibsqlSelect := TIBSQL.Create(Application);
  try
    ibsql.Transaction := FWriteTransaction;
    ibsqlUpdate.Transaction := FWriteTransaction;
    ibsqlSelect.Transaction := FWriteTransaction;
    // ���� �� ������� ������
    for ForeignKeyCounter := 0 to OL.Count - 1 do
    begin
      // ��� ������� ������� �������� ������ �� ���������� ������
      ReferencesRelationName := TatForeignKey(OL[ForeignKeyCounter]).Relation.RelationName;
      // ��� ����-������ �� ���������� ������
      ReferencesFieldName := TatForeignKey(OL.Items[ForeignKeyCounter]).ConstraintField.FieldName;
      // ��� ���� �� ������� AdditionalRelationName �� ������� ��������� ReferencesFieldName
      AdditionalFieldName := TatForeignKey(OL.Items[ForeignKeyCounter]).ReferencesField.FieldName;
      // ������ ������ ����������� �� ���������� ������ � ������� �� �������� �������� �����
      ibsql.Close;
      ibsql.SQL.Text := Format('SELECT * FROM %0:s WHERE %1:s = :aid', [ReferencesRelationName, ReferencesFieldName]);
      SetTID(ibsql.ParamByName('AID'), AID);
      ibsql.ExecQuery;
      // ���� ����� ������
      if ibsql.RecordCount > 0 then
      begin
        // ���� ����-������ ����� ��������, ������� ���.
        // ����� �������� ������ �� �������� ������ �� ����
        if TatForeignKey(OL.Items[ForeignKeyCounter]).ConstraintField.IsNullable then
        begin
          ibsqlUpdate.Close;
          ibsqlUpdate.SQL.Text := Format('UPDATE %0:s SET %1:s = NULL WHERE %1:s = :aid', [ReferencesRelationName, ReferencesFieldName]);
          SetTID(ibsqlUpdate.ParamByName('AID'), AID);
          ibsqlUpdate.ExecQuery;
        end
        else
        begin
          if ADocTypeKey <> -1 then
          begin
            ibsqlUpdate.Close;
            ibsqlUpdate.SQL.Text := Format('UPDATE %0:s SET %1:s = :newkey WHERE %1:s = :aid', [ReferencesRelationName, ReferencesFieldName]);
            SetTID(ibsqlUpdate.ParamByName('AID'), AID);
            SetTID(ibsqlUpdate.ParamByName('NEWKEY'), CreateDummyInvDocument(ADocTypeKey));
            ibsqlUpdate.ExecQuery;
          end  
          else
            DoOnProcessMessage(-1, -1, Format('NOT NULL: %1:s(%2:s) -> %0:s',
              [AdditionalRelationName, ReferencesRelationName, ReferencesFieldName]));
        end;
      end;
    end;
  finally
    ibsqlSelect.Free;
    ibsqlUpdate.Free; 
    ibsql.Free;
  end;
end;

function TgdClosingPeriod.GetFeatureFieldList(AAlias: String): String;
var
  I: Integer;
begin
  Result := '';
  // ������� �� ������ ��������� ���������
  for I := 0 to FFeatureList.Count - 1 do
  begin
    if Result <> '' then
      Result := Result + ', ';
    // ��������� ��������� ��� ����
    Result := Result + AAlias + FFeatureList.Strings[i];
  end;
end;

function TgdClosingPeriod.IIF(const Condition: Boolean; const TrueString, FalseString: String): String;
begin
  if Condition then
    Result := TrueString
  else
    Result := FalseString;
end;

procedure TgdClosingPeriod.CalculateEntryBalance;
const
  ibMainBegin =
    ' SELECT ' +
    '  companykey, ' +
    '  accountkey, ' +
    '  currkey, ' +
    '  SUM(debitncu) AS DebitNCU, ' +
    '  SUM(creditncu) AS CreditNCU, ' +
    '  SUM(debitcurr) AS DebitCURR, ' +
    '  SUM(creditcurr) AS CreditCURR, ' +
    '  SUM(debiteq) AS Debiteq, ' +
    '  SUM(crediteq) AS Crediteq ';
  ibMainMiddle =
    ' FROM ' +
    '  ac_entry ' +
    ' WHERE ' +
    '  accountkey = :acckey ' +
    '  AND entrydate < :balancedate ' +
    ' GROUP BY ' +
    '  companykey, ' +
    '  accountkey, ' +
    '  currkey ';
  ibMainEnd =
    ' HAVING ' +
    '   SUM(debitncu - creditncu) <> 0 ' +
    '   OR SUM(debitcurr - creditcurr) <> 0 ' +
    '   OR SUM(debiteq - crediteq) <> 0 ';
  ibWriteBegin =
    ' INSERT INTO ac_entry_balance ' +
    ' (companykey, accountkey, currkey, debitncu, creditncu, debitcurr, creditcurr, debiteq, crediteq ';
  ibWriteValues =
    ') VALUES (:companykey, :accountkey, :currkey, :debitncu, :creditncu, :debitcurr, :creditcurr, :debiteq, :crediteq ';

var
  ibsql: TIBSQL;
  ibsqlAccount: TIBSQL;
  AnalyticCounter: Integer;
  Analytics: String;
  BalanceAnalytics, InsertAnalytics: String;
  RecordCounter: Integer;
begin
  FLocalStartTime := Time;

  // ������������ ��������
  DoOnProcessMessage(-1, -1, '���������� ������������� ��������...');

  // ������� �������� ���� �����-�������� � ������
  Analytics := '';
  for AnalyticCounter := 0 to FEntryAvailableAnalytics.Count - 1 do
  begin
    if Analytics <> '' then
      Analytics := Analytics + ',';
    Analytics := Analytics + ' ac.' + FEntryAvailableAnalytics.Strings[AnalyticCounter];
  end;

  ibsql := TIBSQL.Create(Application);
  ibsqlAccount := TIBSQL.Create(Application);
  try
    ibsql.Transaction := FWriteTransaction;
    ibsqlAccount.Transaction := gdcBaseManager.ReadTransaction;

    // ������� ���-�� ������
    ibsqlAccount.SQL.Text := 'SELECT COUNT(ag.id) as AccCount FROM ac_account ag';
    ibsqlAccount.ExecQuery;

    // ������������ ��������
    DoOnProcessMessage(0, ibsqlAccount.FieldByName('AccCount').AsInteger, '�������� ���������� ������...');

    // ������ ������ ������ ������
    ibsql.SQL.Text := 'DELETE FROM ac_entry_balance';
    ibsql.ExecQuery;

    DoOnProcessMessage(-1, -1, '������ ������������� ��������...');

    // ������� ��� �����
    ibsqlAccount.Close;
    ibsqlAccount.SQL.Text :=
      ' SELECT ' +
      '   ac.id, ac.alias ' +
        IIF(Analytics <> '', ', ' + Analytics, '') +
      ' FROM ' +
      '   ac_account ac ' +
      ' ORDER BY ' +
      '   ac.alias ';
    ibsqlAccount.ExecQuery;

    RecordCounter := 0;
    while not ibsqlAccount.Eof do
    begin
      // ��� ������� Escape ������� �������
      if FProcessState = psTerminating then
        if Application.MessageBox('���������� �������� �������?', '��������',
           MB_YESNO or MB_ICONQUESTION or MB_SYSTEMMODAL) = IDYES then
          raise Exception.Create('���������� ��������')
        else
          FProcessState := psWorking;

      // ������������ ��������
      Inc(RecordCounter);
      DoOnProcessMessage(RecordCounter, -1, '');

      // ������� ��������� ��������� �� �������������� �����
      BalanceAnalytics := '';
      InsertAnalytics := '';
      for AnalyticCounter := 0 to FEntryAvailableAnalytics.Count - 1 do
      begin
        if ibsqlAccount.FieldByName(FEntryAvailableAnalytics.Strings[AnalyticCounter]).AsInteger = 1 then
        begin
          BalanceAnalytics := BalanceAnalytics + ', ' + FEntryAvailableAnalytics.Strings[AnalyticCounter];
          InsertAnalytics := InsertAnalytics + ', :' + FEntryAvailableAnalytics.Strings[AnalyticCounter];
        end;
      end;

      // ���������� ������ �� ������
      ibsql.Close;
      ibsql.SQL.Text := ibWriteBegin + BalanceAnalytics + ') ' + ibMainBegin +
        BalanceAnalytics + ibMainMiddle + BalanceAnalytics + ibMainEnd;
      ibsql.ParamByName('BALANCEDATE').AsDateTime := FCloseDate;
      SetTID(ibsql.ParamByName('ACCKEY'), ibsqlAccount.FieldByName('ID'));
      ibsql.ExecQuery;

      // �������� ���-�� ����������� �������, ����� ������������ ��� ��� �������� ���. �������� � AC_ENTRY
      FInsertedEntryBalanceRecordCount := FInsertedEntryBalanceRecordCount + ibsql.RowsAffected;

      ibsqlAccount.Next;
    end;

    // ��������� ����� �������� ���������� gd_g_entry_balance_date
    ibsql.Close;
    ibsql.SQL.Text :=
      Format('SET GENERATOR gd_g_entry_balance_date TO %d', [Round(FCloseDate) + IBDateDelta]);
    ibsql.ExecQuery;

     // ���� ������� ���������� �������, �� �������� ��������� ������������� ���������
    if Assigned(GlobalStorage) then
      GlobalStorage.WriteString(DontBalanceAnalyticStorageFolder, DontBalanceAnalyticStorageValue,
        FDontBalanceAnalytic);

    // ������������ ��������
    DoOnProcessMessage(RecordCounter, RecordCounter, '���������� ������������� �������� ���������'#13#10 +
      '����������������� ��������: ' + TimeToStr(Time - FLocalStartTime));
  finally
    ibsqlAccount.Free;
    ibsql.Free;
  end;
end;

procedure TgdClosingPeriod.TransferEntryBalance;
const
  DocumentTypeKeyRUID = '806001_17';
  TRRecordKeyRUID = '807100_17';
  TransactionKeyRUID = '807001_17';

  ibMainBegin =
    ' SELECT ' +
    '  companykey, ' +
    '  accountkey, ' +
    '  currkey, ' +
    '  debitncu, ' +
    '  creditncu, ' +
    '  debitcurr, ' +
    '  creditcurr, ' +
    '  debiteq, ' +
    '  crediteq ';
  ibMainMiddle =
    ' FROM ' +
    '  ac_entry_balance ';
  ibACEntryWriteBegin =
    ' INSERT INTO ac_entry ' +
    ' (recordkey, entrydate, transactionkey, documentkey, masterdockey, companykey, accountkey, accountpart, currkey, ' +
    '  debitncu, creditncu, debitcurr, creditcurr, debiteq, crediteq ';
  ibACEntryWriteValues =
    ' VALUES ' +
    ' (:recordkey, :entrydate, :transactionkey, :documentkey, :masterdockey, :companykey, :accountkey, :accountpart, :currkey, ' +
    '  :debitncu, :creditncu, :debitcurr, :creditcurr, :debiteq, :crediteq ';
var
  ibsqlSelect: TIBSQL;
  ibsqlInsertGDDocument: TIBSQL;
  ibsqlInsertACRecord: TIBSQL;
  ibsqlInsertACEntry: TIBSQL;
  DocumentTypeKey, TransactionKey, TRRecordKey: TID;
  NextDocumentKey, NextRecordKey: TID;
  InsertAnalytics, ValuesAnalytics: String;
  AnalyticCounter: Integer;
  CurrentCompanyKey: TID;
  RecordCounter: Integer;
begin
  FLocalStartTime := Time;

  // ������������ ��������
  DoOnProcessMessage(-1, -1, '����������� ������������� ��������...');

  ibsqlSelect := TIBSQL.Create(Application);
  ibsqlInsertACRecord := TIBSQL.Create(Application);
  ibsqlInsertGDDocument := TIBSQL.Create(Application);
  ibsqlInsertACEntry := TIBSQL.Create(Application);
  try
    ibsqlSelect.Transaction := FWriteTransaction;
    ibsqlInsertACRecord.Transaction := FWriteTransaction;
    ibsqlInsertGDDocument.Transaction := FWriteTransaction;
    ibsqlInsertACEntry.Transaction := FWriteTransaction;

    // ������� ���� ���� ���������� ��������� ��� ��������
    DocumentTypeKey := gdcBaseManager.GetIDByRUIDString(DocumentTypeKeyRUID);
    // ������ �� ������� ������ � gd_document
    ibsqlInsertGDDocument.SQL.Text := Format(
      'INSERT INTO gd_document ' +
      '  (id, documenttypekey, number, documentdate, companykey, afull, achag, aview, creatorkey, editorkey) ' +
      'VALUES ' +
      '  (:id, %0:d, ''1'', :documentdate, :companykey, -1, -1, -1, %1:d, %1:d) ', [TID264(DocumentTypeKey), TID264(IBLogin.ContactKey)]);
    ibsqlInsertGDDocument.Prepare;

    // ������� ���� ������� ��������
    TRRecordKey := gdcBaseManager.GetIDByRUIDString(TRRecordKeyRUID);
    // ������� ���� ������� ��������
    TransactionKey := gdcBaseManager.GetIDByRUIDString(TransactionKeyRUID);
    // ������ �� ������� �������� � AC_RECORD
    ibsqlInsertACRecord.SQL.Text := Format(
      'INSERT INTO ac_record ' +
      '  (id, trrecordkey, transactionkey, recorddate, documentkey, masterdockey, companykey, afull, achag, aview) ' +
      'VALUES ' +
      '  (:id, %0:d, %1:d, :recorddate, :documentkey, :documentkey, :companykey, -1, -1, -1) ', [TID264(TRRecordKey), TID264(TransactionKey)]);
    ibsqlInsertACRecord.Prepare;

    // ������� ��������� ��������� �� �������������� �����
    ValuesAnalytics := '';
    for AnalyticCounter := 0 to FEntryAvailableAnalytics.Count - 1 do
      ValuesAnalytics := ValuesAnalytics + ', ' + FEntryAvailableAnalytics.Strings[AnalyticCounter];

    // ������� ������ �� AC_ENTRY_BALANCE
    ibsqlSelect.SQL.Text :=
      ' SELECT ' +
      '   companykey, accountkey, currkey, debitncu, creditncu, debitcurr, creditcurr, debiteq, crediteq ' +
        ValuesAnalytics +
      ' FROM ' +
      '   ac_entry_balance ';
    ibsqlSelect.ExecQuery;

    DoOnProcessMessage(0, FInsertedEntryBalanceRecordCount, '');

    CurrentCompanyKey := -1;
    NextDocumentKey := -1;
    RecordCounter := 0;
    while not ibsqlSelect.Eof do
    begin
      if FProcessState = psTerminating then
        if Application.MessageBox('���������� �������� �������?', '��������',
           MB_YESNO or MB_ICONQUESTION or MB_SYSTEMMODAL) = IDYES then
          raise Exception.Create('���������� ��������')
        else
          FProcessState := psWorking;

      if CurrentCompanyKey <> GetTID(ibsqlSelect.FieldByName('COMPANYKEY')) then
      begin
        CurrentCompanyKey := GetTID(ibsqlSelect.FieldByName('COMPANYKEY'));
        // ��������� ����� ��� ���������
        NextDocumentKey := gdcBaseManager.GetNextID;
        // �������� ���������
        SetTID(ibsqlInsertGDDocument.ParamByName('ID'), NextDocumentKey);
        ibsqlInsertGDDocument.ParamByName('DOCUMENTDATE').AsDateTime := FCloseDate - 1;
        SetTID(ibsqlInsertGDDocument.ParamByName('COMPANYKEY'), CurrentCompanyKey);
        ibsqlInsertGDDocument.ExecQuery;
      end;

      // ��������� ����� ��������� ��������
      NextRecordKey := gdcBaseManager.GetNextID;
      // ������� ��������� ��������
      ibsqlInsertACRecord.Close;
      SetTID(ibsqlInsertACRecord.ParamByName('ID'), NextRecordKey);
      ibsqlInsertACRecord.ParamByName('RECORDDATE').AsDateTime := FCloseDate - 1;
      SetTID(ibsqlInsertACRecord.ParamByName('DOCUMENTKEY'), NextDocumentKey);
      SetTID(ibsqlInsertACRecord.ParamByName('COMPANYKEY'), CurrentCompanyKey);
      ibsqlInsertACRecord.ExecQuery;

      // ������� ��������� ��������� �� �������������� �����
      InsertAnalytics := '';
      ValuesAnalytics := '';
      for AnalyticCounter := 0 to FEntryAvailableAnalytics.Count - 1 do
      begin
        if not ibsqlSelect.FieldByName(FEntryAvailableAnalytics.Strings[AnalyticCounter]).IsNull then
        begin
          InsertAnalytics := InsertAnalytics + ', ' + FEntryAvailableAnalytics.Strings[AnalyticCounter];
          ValuesAnalytics := ValuesAnalytics + ', :' + FEntryAvailableAnalytics.Strings[AnalyticCounter];
        end;
      end;
      // ���������� ������ �� ������� �������� � AC_ENTRY
      ibsqlInsertACEntry.SQL.Text :=
        ibACEntryWriteBegin + InsertAnalytics + ')' +
        ibACEntryWriteValues + ValuesAnalytics + ')';
      // ������� ��������� ����� ��������
      ibsqlInsertACEntry.Close;
      SetTID(ibsqlInsertACEntry.ParamByName('RECORDKEY'), NextRecordKey);
      ibsqlInsertACEntry.ParamByName('ENTRYDATE').AsDateTime := FCloseDate - 1;
      SetTID(ibsqlInsertACEntry.ParamByName('TRANSACTIONKEY'), TransactionKey);
      SetTID(ibsqlInsertACEntry.ParamByName('DOCUMENTKEY'), NextDocumentKey);
      SetTID(ibsqlInsertACEntry.ParamByName('COMPANYKEY'), CurrentCompanyKey);
      SetTID(ibsqlInsertACEntry.ParamByName('ACCOUNTKEY'), ibsqlSelect.FieldByName('ACCOUNTKEY'));
      ibsqlInsertACEntry.ParamByName('ACCOUNTPART').AsString := 'D';
      SetTID(ibsqlInsertACEntry.ParamByName('CURRKEY'), ibsqlSelect.FieldByName('CURRKEY'));
      ibsqlInsertACEntry.ParamByName('DEBITNCU').AsCurrency := ibsqlSelect.FieldByName('DEBITNCU').AsCurrency;
      ibsqlInsertACEntry.ParamByName('DEBITCURR').AsCurrency := ibsqlSelect.FieldByName('DEBITCURR').AsCurrency;
      ibsqlInsertACEntry.ParamByName('DEBITEQ').AsCurrency := ibsqlSelect.FieldByName('DEBITEQ').AsCurrency;
      ibsqlInsertACEntry.ParamByName('CREDITNCU').AsCurrency := 0;
      ibsqlInsertACEntry.ParamByName('CREDITCURR').AsCurrency := 0;
      ibsqlInsertACEntry.ParamByName('CREDITEQ').AsCurrency := 0;
      for AnalyticCounter := 0 to FEntryAvailableAnalytics.Count - 1 do
      begin
        if not ibsqlSelect.FieldByName(FEntryAvailableAnalytics.Strings[AnalyticCounter]).IsNull then
        begin
          SetVar2Param(ibsqlInsertACEntry.ParamByName(FEntryAvailableAnalytics.Strings[AnalyticCounter]),
            GetFieldAsVar(ibsqlSelect.FieldByName(FEntryAvailableAnalytics.Strings[AnalyticCounter])));
        end;
      end;
      ibsqlInsertACEntry.ExecQuery;
      // ������� ���������� ����� ��������
      ibsqlInsertACEntry.Close;
      SetTID(ibsqlInsertACEntry.ParamByName('RECORDKEY'), NextRecordKey);
      ibsqlInsertACEntry.ParamByName('ENTRYDATE').AsDateTime := FCloseDate - 1;
      SetTID(ibsqlInsertACEntry.ParamByName('TRANSACTIONKEY'), TransactionKey);
      SetTID(ibsqlInsertACEntry.ParamByName('DOCUMENTKEY'), NextDocumentKey);
      SetTID(ibsqlInsertACEntry.ParamByName('COMPANYKEY'), CurrentCompanyKey);
      SetTID(ibsqlInsertACEntry.ParamByName('ACCOUNTKEY'), ibsqlSelect.FieldByName('ACCOUNTKEY'));
      ibsqlInsertACEntry.ParamByName('ACCOUNTPART').AsString := 'C';
      SetTID(ibsqlInsertACEntry.ParamByName('CURRKEY'), ibsqlSelect.FieldByName('CURRKEY'));
      ibsqlInsertACEntry.ParamByName('DEBITNCU').AsCurrency := 0;
      ibsqlInsertACEntry.ParamByName('DEBITCURR').AsCurrency := 0;
      ibsqlInsertACEntry.ParamByName('DEBITEQ').AsCurrency := 0;
      ibsqlInsertACEntry.ParamByName('CREDITNCU').AsCurrency := ibsqlSelect.FieldByName('CREDITNCU').AsCurrency;
      ibsqlInsertACEntry.ParamByName('CREDITCURR').AsCurrency := ibsqlSelect.FieldByName('CREDITCURR').AsCurrency;
      ibsqlInsertACEntry.ParamByName('CREDITEQ').AsCurrency := ibsqlSelect.FieldByName('CREDITEQ').AsCurrency;
      for AnalyticCounter := 0 to FEntryAvailableAnalytics.Count - 1 do
      begin
        if not ibsqlSelect.FieldByName(FEntryAvailableAnalytics.Strings[AnalyticCounter]).IsNull then
        begin
          SetVar2Param(ibsqlInsertACEntry.ParamByName(FEntryAvailableAnalytics.Strings[AnalyticCounter]),
            GetFieldAsVar(ibsqlSelect.FieldByName(FEntryAvailableAnalytics.Strings[AnalyticCounter])));
        end;
      end;
      ibsqlInsertACEntry.ExecQuery;

      // ������������ ��������
      Inc(RecordCounter);
      DoOnProcessMessage(RecordCounter, -1, '');

      ibsqlSelect.Next;
    end;

    DoOnProcessMessage(-1, -1, '�������� ��������� ������...');

    ibsqlSelect.Close;
    ibsqlSelect.SQL.Text := 'DELETE FROM ac_entry_balance';
    ibsqlSelect.ExecQuery;

    ibsqlSelect.Close;
    ibsqlSelect.SQL.Text := 'SET GENERATOR gd_g_entry_balance_date TO 0';
    ibsqlSelect.ExecQuery;
  finally
    ibsqlInsertACEntry.Free;
    ibsqlInsertGDDocument.Free;
    ibsqlInsertACRecord.Free;
    ibsqlSelect.Free;
  end;
  // ������������ ��������
  DoOnProcessMessage(FInsertedEntryBalanceRecordCount, FInsertedEntryBalanceRecordCount,
    '����������� ������������� �������� ���������'#13#10 +
    '����������������� ��������: ' + TimeToStr(Time - FLocalStartTime));
end;

procedure TgdClosingPeriod.InitialFillOptions;
var
  AcAccountRelation: TatRelation;
  AnalyticCounter, ForeignKeyCounter: Integer;
  TableReferenceIndex: Integer;
  OL: TObjectList;
begin
  // �� ������������� ����� ���������� ������ ������ ��� ������������ ��������
  FPseudoClientKey := gdcBaseManager.GetIDByRUID(147004309, 31587988);            // TODO: �������� ������ �� �� ����� �������� � ����������
  // ������� ���������� ������������� ���������
  FEntryAvailableAnalytics.Clear;
  AcAccountRelation := atDatabase.Relations.ByRelationName('AC_ACCOUNT');
  if Assigned(AcAccountRelation) then
  begin
    for AnalyticCounter := 0 to AcAccountRelation.RelationFields.Count - 1 do
    begin
      if AcAccountRelation.RelationFields.Items[AnalyticCounter].IsUserDefined
         and (AnsiPos(';' + AcAccountRelation.RelationFields.Items[AnalyticCounter].FieldName + ';', FDontBalanceAnalytic) = 0) then
        FEntryAvailableAnalytics.Add(AcAccountRelation.RelationFields.Items[AnalyticCounter].FieldName);
    end;
  end
  else
    raise Exception.Create('AC_ACCOUNT not found!');

  // �������� ��� INV_CARD ������ ������� ������ �� ��������� ������
  if not FTableReferenceForeignKeysList.Find('INV_CARD', TableReferenceIndex) then
  begin
    // �������� ����� ������ ������� ������ ����������� �� ���������� �������
    TableReferenceIndex := FTableReferenceForeignKeysList.AddObject('INV_CARD', TObjectList.Create(False));
    OL := TObjectList.Create(False);
    try
      // ������� ������ ������� ������ ����������� �� ���������� �������
      atDatabase.ForeignKeys.ConstraintsByReferencedRelation('INV_CARD', OL);
      // ������� ������ ������� ������� �����
      for ForeignKeyCounter := 0 to OL.Count - 1 do
      begin
        if (TatForeignKey(OL.Items[ForeignKeyCounter]).ConstraintField.FieldName = 'FROMCARDKEY')
           or (TatForeignKey(OL.Items[ForeignKeyCounter]).ConstraintField.FieldName = 'TOCARDKEY')
           or (TatForeignKey(OL.Items[ForeignKeyCounter]).ConstraintField.FieldName = 'PARENT') then
          TObjectList(FTableReferenceForeignKeysList.Objects[TableReferenceIndex]).Add(OL.Items[ForeignKeyCounter]);
      end;
    except
      OL.Free;
    end;
  end;
end;

function TgdClosingPeriod.AddDepotHeader(const FromContact, ToContact, CompanyKey: TID): TID;
var
  NextDocumentKey: TID;
begin
  // ��������� ����� ����� � ������ ����������
  FIBSQLGetDepotHeaderKey.Close;
  SetTID(FIBSQLGetDepotHeaderKey.ParamByName('OUTCONTACT'), FromContact);
  SetTID(FIBSQLGetDepotHeaderKey.ParamByName('INCONTACT'), ToContact);
  FIBSQLGetDepotHeaderKey.ExecQuery;

  if FIBSQLGetDepotHeaderKey.RecordCount > 0 then
  begin
    Result := GetTID(FIBSQLGetDepotHeaderKey.FieldByName('DOCUMENTKEY'));
  end
  else
  begin
    // ���� ����� ����� �� �������, ������� �����
    
    // ������� �� ��������� �����
    NextDocumentKey := gdcBaseManager.GetNextID;
    // ������� ������ � gd_document
    FIBSQLInsertGdDocument.Close;
    SetTID(FIBSQLInsertGdDocument.ParamByName('ID'), NextDocumentKey);
    FIBSQLInsertGdDocument.ParamByName('PARENT').Clear;
    SetTID(FIBSQLInsertGdDocument.ParamByName('COMPANYKEY'), CompanyKey);
    FIBSQLInsertGdDocument.ParamByName('DOCUMENTDATE').AsDateTime := FCloseDate;
    FIBSQLInsertGdDocument.ExecQuery;

    // ������� ������ � �������������� ������� ��������� �����
    FIBSQLInsertDocumentHeader.Close;
    SetTID(FIBSQLInsertDocumentHeader.ParamByName('DOCUMENTKEY'), NextDocumentKey);
    SetTID(FIBSQLInsertDocumentHeader.ParamByName('OUTCONTACT'), FromContact);
    SetTID(FIBSQLInsertDocumentHeader.ParamByName('INCONTACT'), ToContact);
    FIBSQLInsertDocumentHeader.ExecQuery;

    Result := NextDocumentKey;
  end;
end;

function TgdClosingPeriod.AddDepotPosition(const FromContact, ToContact, CompanyKey,
  ADocumentParentKey, CardGoodkey: TID; const GoodQuantity: Currency; FeatureDataset: TIBSQL = nil): TID;
var
  NextDocumentKey, NextMovementKey, NextCardKey: TID;
  FieldCounter: Integer;
begin
  // ������� �� ��������� �������
  NextDocumentKey := gdcBaseManager.GetNextID;
  // ������� ������ � gd_document
  FIBSQLInsertGdDocument.Close;
  SetTID(FIBSQLInsertGdDocument.ParamByName('ID'), NextDocumentKey);
  SetTID(FIBSQLInsertGdDocument.ParamByName('PARENT'), ADocumentParentKey);
  SetTID(FIBSQLInsertGdDocument.ParamByName('COMPANYKEY'), CompanyKey);
  FIBSQLInsertGdDocument.ParamByName('DOCUMENTDATE').AsDateTime := FCloseDate;
  FIBSQLInsertGdDocument.ExecQuery;

  // ������� �� ����� ��������� ��������
  NextCardKey := gdcBaseManager.GetNextID;
  // �������� ����� ��������� ��������
  FIBSQLInsertInvCard.Close;
  SetTID(FIBSQLInsertInvCard.ParamByName('ID'), NextCardKey);
  SetTID(FIBSQLInsertInvCard.ParamByName('GOODKEY'), CardGoodkey);
  SetTID(FIBSQLInsertInvCard.ParamByName('DOCUMENTKEY'), NextDocumentKey);
  SetTID(FIBSQLInsertInvCard.ParamByName('COMPANYKEY'), CompanyKey);
  for FieldCounter := 0 to FFeatureList.Count - 1 do
    if Assigned(FeatureDataset) then
      SetVar2Param(FIBSQLInsertInvCard.ParamByName(FFeatureList.Strings[FieldCounter]),
        GetFieldAsVar(FeatureDataset.FieldByName(FFeatureList.Strings[FieldCounter])))
    else
      FIBSQLInsertInvCard.ParamByName(FFeatureList.Strings[FieldCounter]).Clear;
  // �������� ���� USR$INV_ADDLINEKEY �������� ������ ������� ������� �� �������
  if FAddLineKeyFieldExists then
    SetTID(FIBSQLInsertInvCard.ParamByName('USR$INV_ADDLINEKEY'), NextDocumentKey);
  FIBSQLInsertInvCard.ExecQuery;

  // ������� �� ���������� ��������
  NextMovementKey := gdcBaseManager.GetNextID;
  // �������� ��������� ����� ���������� ��������
  FIBSQLInsertInvMovement.Close;
  SetTID(FIBSQLInsertInvMovement.ParamByName('MOVEMENTKEY'), NextMovementKey);
  SetTID(FIBSQLInsertInvMovement.ParamByName('DOCUMENTKEY'), NextDocumentKey);
  SetTID(FIBSQLInsertInvMovement.ParamByName('CONTACTKEY'), ToContact);
  SetTID(FIBSQLInsertInvMovement.ParamByName('CARDKEY'), NextCardKey);
  FIBSQLInsertInvMovement.ParamByName('DEBIT').AsCurrency := GoodQuantity;
  FIBSQLInsertInvMovement.ParamByName('CREDIT').AsCurrency := 0;
  FIBSQLInsertInvMovement.ExecQuery;
  // �������� ���������� ����� ���������� ��������
  FIBSQLInsertInvMovement.Close;
  SetTID(FIBSQLInsertInvMovement.ParamByName('MOVEMENTKEY'), NextMovementKey);
  SetTID(FIBSQLInsertInvMovement.ParamByName('DOCUMENTKEY'), NextDocumentKey);
  SetTID(FIBSQLInsertInvMovement.ParamByName('CONTACTKEY'), FromContact);
  SetTID(FIBSQLInsertInvMovement.ParamByName('CARDKEY'), NextCardKey);
  FIBSQLInsertInvMovement.ParamByName('DEBIT').AsCurrency := 0;
  FIBSQLInsertInvMovement.ParamByName('CREDIT').AsCurrency := GoodQuantity;
  FIBSQLInsertInvMovement.ExecQuery;

  // ������� ������ � �������������� ������� ��������� �������
  FIBSQLInsertDocumentPosition.Close;
  SetTID(FIBSQLInsertDocumentPosition.ParamByName('DOCUMENTKEY'), NextDocumentKey);
  SetTID(FIBSQLInsertDocumentPosition.ParamByName('MASTERKEY'), ADocumentParentKey);
  SetTID(FIBSQLInsertDocumentPosition.ParamByName('FROMCARDKEY'), NextCardKey);
  FIBSQLInsertDocumentPosition.ParamByName('QUANTITY').AsCurrency := GoodQuantity;
  FIBSQLInsertDocumentPosition.ExecQuery;

  Result := NextCardKey;
end;

procedure TgdClosingPeriod.InitializeIBSQLQueries;
var
  gdcObject: TgdcInvDocument;
  InvDocumentInField, InvDocumentOutField: ShortString;
  InvRelationName, InvRelationLineName: ShortString;
  FieldCounter: Integer;
  SQLText: String;
begin
  if not FQueriesInitialized then
  begin
    // ������� ���� ���� ���������� ��������� ��� ��������
    FInvDocumentTypeKey := gdcBaseManager.GetIDByRUIDString(InvDocumentRUID);

    if FInvDocumentTypeKey > 0 then
    begin
      // ��������� �� ����-������ �� ������� �������
      FAddLineKeyFieldExists := Assigned(atDatabase.FindRelationField('INV_CARD', 'USR$INV_ADDLINEKEY'));
      // ������� ����������� ������������ ������ � �����
      gdcObject := TgdcInvDocument.Create(Application);
      try
        gdcObject.Transaction := FWriteTransaction;
        gdcObject.SubType := InvDocumentRUID;
        gdcObject.SubSet := 'ByID';
        // �������� �����-������ �� ��������, �� ������� � � ������� ����������� ���
        InvDocumentInField := gdcObject.MovementTarget.SourceFieldName;
        InvDocumentOutField := gdcObject.MovementSource.SourceFieldName;
        InvRelationName := gdcObject.RelationName;
        InvRelationLineName := gdcObject.RelationLineName;
      finally
        gdcObject.Free;
      end;

      // ������ ���������� ���� ��������� �� InvRelationName �� ��������� ���������� � ������
      FIBSQLGetDepotHeaderKey.Transaction := FWriteTransaction;
      FIBSQLGetDepotHeaderKey.SQL.Text := Format(
        ' SELECT documentkey FROM %0:s ' +
        ' WHERE %1:s = :incontact AND %2:s = :outcontact ', [InvRelationName, InvDocumentInField, InvDocumentOutField]);
      FIBSQLGetDepotHeaderKey.Prepare;

      // ������ �� ������� ������ � gd_document
      FIBSQLInsertGdDocument.Transaction := FWriteTransaction;
      FIBSQLInsertGdDocument.SQL.Text := Format(
        'INSERT INTO gd_document ' +
        '  (id, parent, documenttypekey, number, documentdate, companykey, afull, achag, aview, creatorkey, editorkey) ' +
        'VALUES ' +
        '  (:id, :parent, %0:d, ''1'', :documentdate, :companykey, -1, -1, -1, %1:d, %1:d) ', [TID264(FInvDocumentTypeKey), TID264(IBLogin.ContactKey)]);
      FIBSQLInsertGdDocument.Prepare;

      // ������ �� ������� ������ � ����� ���������� ���������
      FIBSQLInsertDocumentHeader.Transaction := FWriteTransaction;
      FIBSQLInsertDocumentHeader.SQL.Text := Format(
        'INSERT INTO %0:s ' +
        '  (documentkey, %1:s, %2:s) ' +
        'VALUES ' +
        '  (:documentkey, :incontact, :outcontact) ', [InvRelationName, InvDocumentInField, InvDocumentOutField]);
      FIBSQLInsertDocumentHeader.Prepare;

      // ������ �� ������� ������ � ������� ���������� ���������
      FIBSQLInsertDocumentPosition.Transaction := FWriteTransaction;
      FIBSQLInsertDocumentPosition.SQL.Text := Format(
        'INSERT INTO %0:s ' +
        '  (documentkey, masterkey, fromcardkey, quantity) ' +
        'VALUES ' +
        '  (:documentkey, :masterkey, :fromcardkey, :quantity) ', [InvRelationLineName]);
      FIBSQLInsertDocumentPosition.Prepare;
    end;

    // ������ �� �������� ��������� ��������
    FIBSQLInsertInvCard.Transaction := FWriteTransaction;
    SQLText :=
      'INSERT INTO inv_card ' +
      '  (id, goodkey, documentkey, firstdocumentkey, firstdate, companykey';
    // ����-��������
    for FieldCounter := 0 to FFeatureList.Count - 1 do
      SQLText := SQLText + ', ' + FFeatureList.Strings[FieldCounter];
    // ���� ��������� ����-������ �� ������� �������
    if FAddLineKeyFieldExists then
      SQLText := SQLText + ', USR$INV_ADDLINEKEY';
    SQLText := SQLText + ') VALUES ' +
      '  (:id, :goodkey, :documentkey, :documentkey, :firstdate, :companykey';
    // ����-��������
    for FieldCounter := 0 to FFeatureList.Count - 1 do
      SQLText := SQLText + ', :' + FFeatureList.Strings[FieldCounter];
    // ���� ��������� ����-������ �� ������� �������
    if FAddLineKeyFieldExists then
      SQLText := SQLText + ', :USR$INV_ADDLINEKEY';
    SQLText := SQLText + ')';
    FIBSQLInsertInvCard.SQL.Text := SQLText;
    FIBSQLInsertInvCard.ParamByName('FIRSTDATE').AsDateTime := FCloseDate;
    FIBSQLInsertInvCard.Prepare;

    // ������ �� �������� ���������� ��������
    FIBSQLInsertInvMovement.Transaction := FWriteTransaction;
    FIBSQLInsertInvMovement.SQL.Text :=
      'INSERT INTO inv_movement ' +
      '  (movementkey, movementdate, documentkey, contactkey, cardkey, debit, credit) ' +
      'VALUES ' +
      '  (:movementkey, :movementdate, :documentkey, :contactkey, :cardkey, :debit, :credit) ';
    FIBSQLInsertInvMovement.ParamByName('MOVEMENTDATE').AsDateTime := FCloseDate;
    FIBSQLInsertInvMovement.Prepare;

    // �������� �����
    FIBSQLDeleteRUID.Transaction := FWriteTransaction;
    FIBSQLDeleteRUID.SQL.Text :=
      'DELETE FROM gd_ruid ' +
      'WHERE ' +
      '  id = :id ';
    FIBSQLDeleteRUID.Prepare;

    FQueriesInitialized := True;
  end;
end;

procedure TgdClosingPeriod.SetClosingDatabaseParams(const ADBPAth,
  ADBServer, ADBUser, ADBPAssword: String);
begin
  FExtDatabasePath := ADBPAth;
  FExtDatabaseServer := ADBServer;
  FExtDatabaseUser := ADBUser;
  FExtDatabasePassword := ADBPAssword;
end;

procedure TgdClosingPeriod.DoAfterProcess;
begin
  // ���� ������� �� ���������, � �� �� ��������� ��-�� ������, �� ������ ��� ��� ������ �������
  if not (FProcessState in [psInterrupted, psError]) then
    FProcessState := psSuccess;
  // ������ ������� ����������  
  if FWriteTransaction.InTransaction then
    FWriteTransaction.Commit;
  if Assigned(FOnAfterProcess) then
    FOnAfterProcess;
end;

procedure TgdClosingPeriod.DoBeforeProcess;
begin
  // ������ ��� ������ ����� ������
  FProcessState := psWorking;
  if Assigned(FOnBeforeProcess) then
    FOnBeforeProcess;
  FWriteTransaction.StartTransaction;
  InitialFillOptions;
  InitializeIBSQLQueries;  
end;

procedure TgdClosingPeriod.DoOnProcessInterruption(const AErrorMessage: String);
begin
  // ���� ������� ���  ������� �������������, ������ ���, ����� ������ ��� ������� ���������� ��-�� ������
  if FProcessState = psTerminating then
    FProcessState := psInterrupted
  else
    FProcessState := psError;  
  // ������� ������� ����������
  if FWriteTransaction.InTransaction then
    FWriteTransaction.Rollback;
  if Assigned(FOnProcessInterruption) then
    FOnProcessInterruption(AErrorMessage);
end;

procedure TgdClosingPeriod.DoOnProcessMessage(const APosition, AMaxPosition: Integer; const AMessage: String);
begin
  if Assigned(FOnProcessMessage) then
    FOnProcessMessage(APosition, AMaxPosition, AMessage);
end;

function TgdClosingPeriod.GetInProcess: Boolean;
begin
  Result := (FProcessState = psWorking);
end;

procedure TgdClosingPeriod.StopProcess;
begin
  if InProcess then
  begin
    FProcessState := psTerminating;
  end;
end;

procedure TgdClosingPeriod.PrepareDontDeleteDocumentList;
var
  ibsqlSelect: TIBSQL;
  DocTypeCounter: Integer;
  TempOutVariable: Integer;
begin
  ibsqlSelect := TIBSQL.Create(Application);
  try
    // ���������� ������ ������� ������� ����� ���������� �����, ������� ������ �������
    ibsqlSelect.Transaction := FWriteTransaction;
    ibsqlSelect.SQL.Text :=
      ' SELECT ' +
      '   d.id, c.firstdocumentkey AS firstid ' +
      ' FROM ' +
      '   gd_document d ' +
      '   LEFT JOIN inv_card c ON c.documentkey = d.id ' +
      ' WHERE ' +
      '   d.documenttypekey = :doctypekey ' +
      '   AND d.documentdate < :closedate ' +
      '   AND NOT d.parent IS NULL ' +
      ' ORDER BY ' +
      '   d.id';
    ibsqlSelect.ParamByName('CLOSEDATE').AsDateTime := FCloseDate;

    // ������� �� ����� ����������, ������� ������ �������
    for DocTypeCounter := 0 to FDontDeleteDocumentTypes.Count - 1 do
    begin
      SetTID(ibsqlSelect.ParamByName('DOCTYPEKEY'), FDontDeleteDocumentTypes.Keys[DocTypeCounter]);
      ibsqlSelect.ExecQuery;

      // ������� �� ���� ������ � ������� �� � ������
      while not ibsqlSelect.Eof do
      begin
        if not FDontDeleteCardArray.Find(GetTID(ibsqlSelect.FieldByName('ID')), TempOutVariable) then
          FDontDeleteCardArray.Add(GetTID(ibsqlSelect.FieldByName('ID')));
        if not FDontDeleteCardArray.Find(GetTID(ibsqlSelect.FieldByName('FIRSTID')), TempOutVariable) then
          FDontDeleteCardArray.Add(GetTID(ibsqlSelect.FieldByName('FIRSTID')));

        ibsqlSelect.Next;
      end;

      ibsqlSelect.Close;
    end;

    //DoOnProcessMessage(-1, -1, Format('���-�� ����������: %d', [FDontDeleteCardArray.Count]));
  finally
    FreeAndNil(ibsqlSelect);
  end;
end;

function TgdClosingPeriod.CreateDummyInvDocument(const ADocTypeKey: TID): TID;
var
  ibsqlDocumentInsert: TIBSQL;
  NextDocumentKey: TID;
  DummyDocumentIndex: Integer;
begin
  // ������ ����� ��� � ������, �������� ��� ���� ��� ������� ��������
  if FDummyInvDocumentKeys.Find(ADocTypeKey, DummyDocumentIndex) then
  begin
    Result := FDummyInvDocumentKeys.ValuesByIndex[DummyDocumentIndex];
  end
  else
  begin
    ibsqlDocumentInsert := TIBSQL.Create(Application);
    try
      NextDocumentKey := gdcBaseManager.GetNextID;
      // ������� ������ � GD_DOCUMENT
      ibsqlDocumentInsert.Transaction := FWriteTransaction;
      ibsqlDocumentInsert.SQL.Text := Format(
        'INSERT INTO gd_document ' +
        '  (id, parent, documenttypekey, number, documentdate, companykey, afull, achag, aview, creatorkey, editorkey) ' +
        'VALUES ' +
        '  (%0:d, :parent, %1:d, ''CP_DUMMY'', :documentdate, %2:d, -1, -1, -1, %3d, %3d) ',
        [TID264(NextDocumentKey), TID264(ADocTypeKey), TID264(IBLogin.CompanyKey), TID264(IBLogin.ContactKey)]);
      ibsqlDocumentInsert.FieldByName('DOCUMENTDATE').AsDateTime := FCloseDate;
      ibsqlDocumentInsert.ExecQuery;
    finally
      FreeAndNil(ibsqlDocumentInsert);
    end;

    // �������� ���� ��������
    DummyDocumentIndex := FDummyInvDocumentKeys.Add(ADocTypeKey);
    FDummyInvDocumentKeys.ValuesByIndex[DummyDocumentIndex] := NextDocumentKey;

    Result := NextDocumentKey;
  end;
end;

procedure TgdClosingPeriod.TryToDeleteInvCardReferences(const ADocumentKey: TID);
var
  TableReferenceIndex: Integer;
  OL: TObjectList;
  ibsqlCardSelect, ibsqlDocumentSelect, ibsqlDocumentUpdate: TIBSQL;
  ReferencesRelationName, ReferencesFieldName: String;
  ForeignKeyCounter, FeatureCounter: Integer;
  CardReplacementKey: TID;
begin
  TableReferenceIndex := FTableReferenceForeignKeysList.IndexOf('INV_CARD');
  if TableReferenceIndex > -1 then
  begin
    OL := TObjectList(FTableReferenceForeignKeysList.Objects[TableReferenceIndex]);

    ibsqlCardSelect := TIBSQL.Create(Application);
    ibsqlDocumentSelect := TIBSQL.Create(Application);
    ibsqlDocumentUpdate := TIBSQL.Create(Application);
    try
      ibsqlDocumentSelect.Transaction := FWriteTransaction;
      ibsqlDocumentUpdate.Transaction := FWriteTransaction;

      // ������� ����� �������� ������� ��������� �� ���������� ��������
      ibsqlCardSelect.Transaction := FWriteTransaction;
      ibsqlCardSelect.SQL.Text :=
        'SELECT ' +
        '  c.id, c.goodkey ';
      for FeatureCounter := 0 to FFeatureList.Count - 1 do
        ibsqlCardSelect.SQL.Text := ibsqlCardSelect.SQL.Text + ', c.' + FFeatureList.Strings[FeatureCounter];
      ibsqlCardSelect.SQL.Text := ibsqlCardSelect.SQL.Text + Format(
        'FROM ' +
        '  inv_card c ' +
        'WHERE ' +
        '  c.documentkey = %0:d ' +
        '  OR (c.firstdocumentkey = %0:d)', [TID264(ADocumentKey)]);
      ibsqlCardSelect.ExecQuery;
      // ���� ����� �������� ������ ����
      while not ibsqlCardSelect.Eof do
      begin
        // ���� �� ������� ������
        for ForeignKeyCounter := 0 to OL.Count - 1 do
        begin
          // ��� ������� ������� �������� ������ �� ���������� ������
          ReferencesRelationName := TatForeignKey(OL[ForeignKeyCounter]).Relation.RelationName;
          // ��� ����-������ �� ���������� ������
          ReferencesFieldName := TatForeignKey(OL.Items[ForeignKeyCounter]).ConstraintField.FieldName;

          // ������� ������ �� ��������� ������, ����������� �� ��������� ��������
          ibsqlDocumentSelect.SQL.Text := Format(
            'SELECT ' +
            '  d.documentdate, d.id ' +
            'FROM ' +
            '  %0:s l ' +
            '  JOIN gd_document d ON d.id = l.documentkey ' +
            'WHERE ' +
            '  l.%1:s = %2:d ', [ReferencesRelationName, ReferencesFieldName, TID264(ibsqlCardSelect.FieldByName('ID'))]);
          ibsqlDocumentSelect.ExecQuery;

          if ibsqlDocumentSelect.RecordCount > 0 then
          begin
            while not ibsqlDocumentSelect.Eof do
            begin
              // ����� ���������� �������� ��� ������
              CardReplacementKey := GetReplacementInvCardKey(GetTID(ibsqlCardSelect.FieldByName('ID')), ibsqlCardSelect);
              if CardReplacementKey > -1 then
              begin
                ibsqlDocumentUpdate.SQL.Text := Format(
                  'UPDATE %0:s SET %1:s = %2:d WHERE %1:s = %3:d',
                  [ReferencesRelationName, ReferencesFieldName, TID264(CardReplacementKey), TID264(ibsqlCardSelect.FieldByName('ID'))]);
                ibsqlDocumentUpdate.ExecQuery;
                ibsqlDocumentUpdate.Close;
              end;
              ibsqlDocumentSelect.Next;
            end;
            ibsqlDocumentUpdate.Close;
          end;
          ibsqlDocumentSelect.Close;
        end;
        ibsqlCardSelect.Next;
      end;
    finally
      FreeAndNil(ibsqlDocumentUpdate);
      FreeAndNil(ibsqlDocumentSelect);
      FreeAndNil(ibsqlCardSelect);
    end;
  end;  
end;

(*function TgdClosingPeriod.TryToTruncateAdditionalTable(
  const ADocTypeKey: TID; const AdditionalRelationName: String): Boolean;
var
  ibsqlDelete: TIBSQL;
begin
  ibsqlDelete := TIBSQL.Create(Application);
  try
    ibsqlDelete.Transaction := FWriteTransaction;
    ibsqlDelete.SQL.Text := Format(
      'DELETE FROM %s m ' +
      'WHERE EXISTS(SELECT ' +
      '               d.id ' +
      '             FROM ' +
      '               gd_document d ' +
      '             WHERE ' +
      '               d.id = m.documentkey ' +
      '               AND d.documenttypekey = :doctype ' +
      '               AND d.documentdate < :closedate) ' +
      '        OR NOT EXISTS(SELECT ' +
      '                        d.id ' +
      '                      FROM ' +
      '                        gd_document d ' +
      '                      WHERE ' +
      '                        d.id = m.documentkey) ', [AdditionalRelationName]);
    try
      ibsqlDelete.ParamByName('doctype').AsInteger := ADocTypeKey;
      ibsqlDelete.ParamByName('closedate').AsDateTime := FCloseDate;
      ibsqlDelete.ExecQuery;
      Result := True;
    except
      Result := False;
    end;
  finally
    FreeAndNil(ibsqlDelete);
  end;
end;*)

function TgdClosingPeriod.GetReplacementInvCardKey(const AOldCardKey: TID;
  AFeatureDataset: TIBSQL; const AFromContactkey, AToContactkey: TID): TID;
var
  ibsqlSearchNewCardkey: TIBSQL;
begin
  Result := -1;

  ibsqlSearchNewCardkey := TIBSQL.Create(Application);
  try
    ibsqlSearchNewCardkey.Transaction := FWriteTransaction;
    // ������ ���������� �������� ��� ������ ���������
    ibsqlSearchNewCardkey.SQL.Text := SEARCH_NEW_CARDKEY_TEMPLATE_SIMPLE;
    {for FeatureCounter := 0 to FFeatureList.Count - 1 do
    begin
      if not AFeatureDataset.FieldByName(FFeatureList.Strings[FeatureCounter]).IsNull then
        ibsqlSearchNewCardkey.SQL.Text := ibsqlSearchNewCardkey.SQL.Text +
          Format(' AND card.%0:s = :%0:s ', [FFeatureList.Strings[FeatureCounter]])
      else
        ibsqlSearchNewCardkey.SQL.Text := ibsqlSearchNewCardkey.SQL.Text +
          Format(' AND card.%0:s IS NULL ', [FFeatureList.Strings[FeatureCounter]]);
    end;}
    ibsqlSearchNewCardkey.ParamByName('CLOSEDATE').AsDateTime := FCloseDate;
    SetTID(ibsqlSearchNewCardkey.ParamByName('DOCTYPEKEY'), FInvDocumentTypeKey);
    SetTID(ibsqlSearchNewCardkey.ParamByName('GOODKEY'), AFeatureDataset.FieldByName('GOODKEY'));
    {for FeatureCounter := 0 to FFeatureList.Count - 1 do
    begin
      if not AFeatureDataset.FieldByName(FFeatureList.Strings[FeatureCounter]).IsNull then
        ibsqlSearchNewCardkey.ParamByName(FFeatureList.Strings[FeatureCounter]).AsVariant :=
          AFeatureDataset.FieldByName(FFeatureList.Strings[FeatureCounter]).AsVariant;
    end;}
    ibsqlSearchNewCardkey.ExecQuery;

    if ibsqlSearchNewCardkey.RecordCount > 0 then
      Result := GetTID(ibsqlSearchNewCardkey.FieldByName('CARDKEY'));
  finally
    FreeAndNil(ibsqlSearchNewCardkey);
  end;
end;

procedure TgdClosingPeriod.DeleteRUID(const AID: TID);
begin
  // ������� ���� ��� ������
  if FIBSQLDeleteRUID.Open then
    FIBSQLDeleteRUID.Close;
  // ������ ���� �� ����������� �����  
  SetTID(FIBSQLDeleteRUID.ParamByName('ID'), AID);
  FIBSQLDeleteRUID.ExecQuery;
  FIBSQLDeleteRUID.Close;
end;

function TgdClosingPeriod.GetQueryRecordCount(InIBSQL: TIBSQL): Integer;
var
  ibsqlCount: TIBSQL;
  ParamCounter: Integer;
begin
  Result := -1;

  ibsqlCount := TIBSQL.Create(Application);
  try
    ibsqlCount.Transaction := InIBSQL.Transaction;
    ibsqlCount.SQL.Text :=
      'SELECT count(*) AS rec_count FROM (' + InIBSQL.SQL.Text + ')';
    for ParamCounter := 0 to InIBSQL.Params.Count - 1 do
      SetVar2Param(ibsqlCount.Params[ParamCounter], GetFieldAsVar(InIBSQL.Params[ParamCounter]));
    ibsqlCount.ExecQuery;

    if ibsqlCount.RecordCount > 0 then
      Result := ibsqlCount.FieldByName('rec_count').AsInteger;
  finally
    FreeAndNil(ibsqlCount);
  end;
end;

{ TgdClosingThread }

procedure TgdClosingThread.Execute;
begin
  // ������� ���������� ������ �������� ��������
  Model.DoBeforeProcess;

  Model.SetTriggerActive(False);
  try
    try
      Model.PrepareDontDeleteDocumentList;

      // ���������� ������������� ��������
      if Model.DoCalculateEntryBalance then
        Model.CalculateEntryBalance;

      // �������� ��������
      if Model.DoDeleteEntry then
        Model.DeleteEntry;

      // ���������� ��������� ��������
      if Model.DoCalculateRemains then
        Model.CalculateRemains;

      // ������������ ��������� ��������
      if Model.DoReBindDepotCards then
        Model.ReBindDepotCards;

      // �������� ����������
      if Model.DoDeleteDocuments then
        Model.DeleteDocuments;

      // �������� ���������������� ����������
      if Model.DoDeleteUserDocuments then
        Model.DeleteUserDocuments;

      // ����������� ������������� �������� �� AC_ENTRY_BALANCE � AC_ENTRY
      if Model.DoTransferEntryBalance then
        Model.TransferEntryBalance;
    except
      on E: Exception do
      begin
        // ������� ���������� �������������� ��������
        Model.DoOnProcessInterruption(E.Message);
      end;
    end;
  finally
    // ��������� ���������
    Model.SetTriggerActive(True);
    // ������� ���������� ��������� �������� ��������
    Model.DoAfterProcess;

    Self.Terminate;
  end;
end;

end.
