// ShlTanya, 03.02.2019

unit frm_SettingView_unit;

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms,
  StdCtrls, ComCtrls, ExtCtrls, Db, TB2Item, ActnList, TB2Dock,
  TB2Toolbar, SynEdit, gdcStreamSaver, gsStreamHelper, gsSearchReplaceHelper;

type
  Tfrm_SettingView = class(TForm)
    pnlMain: TPanel;
    pnlPositionText: TPanel;
    pnlBottom: TPanel;
    pnlLeft: TPanel;
    splInfo: TSplitter;
    pnlPositions: TPanel;
    lbPositions: TListBox;
    pnlPositionsCaption: TPanel;
    lblPositions: TLabel;
    pnlSettingInfo: TPanel;
    mSettingInfo: TMemo;
    pnlSettingInfoCaption: TPanel;
    lblSettingInfo: TLabel;
    splLeft: TSplitter;
    pnlButtons: TPanel;
    btnClose: TButton;
    TBDock1: TTBDock;
    TBToolbar1: TTBToolbar;
    alMain: TActionList;
    actFind: TAction;
    TBItem1: TTBItem;
    actSaveToFile: TAction;
    TBItem2: TTBItem;
    TBSeparatorItem1: TTBSeparatorItem;
    sePositionText: TSynEdit;
    actFindNext: TAction;
    procedure FormDestroy(Sender: TObject);
    procedure lbPositionsClick(Sender: TObject);
    procedure btnCloseClick(Sender: TObject);
    procedure actFindExecute(Sender: TObject);
    procedure actFindUpdate(Sender: TObject);
    procedure actFindNextExecute(Sender: TObject);
    procedure FormCreate(Sender: TObject);
  private
    FSelectionPos: Integer;
    FSearchReplaceHelper: TgsSearchReplaceHelper;

    procedure ReadSettingOldStream(Stream: TStream);
    procedure ReadSettingNewStream(Stream: TStream; const StreamType: TgsStreamType);
    function FormatDatasetFieldValue(AField: TField): String;
  public
    constructor Create(AnOwner: TComponent); override;
    destructor Destroy; override;

    procedure ReadSetting(Stream: TStream);
  end;

var
  frm_SettingView: Tfrm_SettingView;

implementation

{$R *.DFM}

uses
  DBCLient, DBGrids, gdcBase, SynEditTypes, gdcBaseInterface
  {must be placed after Windows unit!}
  {$IFDEF LOCALIZATION}
    , gd_localization_stub
  {$ENDIF}
  , prp_MessageConst, syn_ManagerInterface_unit;

const
  HexInRow = 16;
  RecordDivider = #13#10'----------------------------------------------------------------------'#13#10#13#10;
  LoadingOrderLineText = '0. ������� �������� �������';

procedure Tfrm_SettingView.ReadSetting(Stream: TStream);
var
  OldCursor: TCursor;
  StreamType: TgsStreamType;
begin
  lbPositions.Clear;
  sePositionText.Lines.Clear;
  mSettingInfo.Clear;
  FSelectionPos := 0;

  // �������� ��� ������
  StreamType := GetStreamType(Stream);
  if StreamType = sttUnknown then
    Exit;

  OldCursor := Screen.Cursor;
  try
    Screen.Cursor := crHourGlass;
    // ������������ ����� ����� ��� ������ �������
    try
      if StreamType <> sttBinaryOld then
        ReadSettingNewStream(Stream, StreamType)
      else
        ReadSettingOldStream(Stream);
    except
      On E: EOutOfMemory do
      begin
        MessageBox(0,
          '��� ����������� ���� ������ ��������� ������������ ��������� ����������� ������.',
          '��������',
          MB_OK or MB_ICONEXCLAMATION or MB_TASKMODAL);
      end;
    end;
  finally
    Screen.Cursor := OldCursor;
  end;

  if lbPositions.Items.Count > 0 then
    sePositionText.Text := (lbPositions.Items.Objects[0] as TStrings).Text;
end;

procedure Tfrm_SettingView.ReadSettingNewStream(Stream: TStream; const StreamType: TgsStreamType);
var
  StreamDataObject: TgdcStreamDataObject;
  StreamLoadingOrderList: TgdcStreamLoadingOrderList;
  StreamWriterReader: TgdcStreamWriterReader;
  CurrentSettingText: String;
  ClassRecordList: TStringList;
  ElementCounter, DataSetCounter, recCount: Integer;
  CDS: TDataSet;
begin
  StreamDataObject := TgdcStreamDataObject.Create;
  StreamLoadingOrderList := TgdcStreamLoadingOrderList.Create;
  try
    if StreamType <> sttBinaryNew then
      StreamWriterReader := TgdcStreamXMLWriterReader.Create(StreamDataObject, StreamLoadingOrderList)
    else
      StreamWriterReader := TgdcStreamBinaryWriterReader.Create(StreamDataObject, StreamLoadingOrderList);

    // ��������� ������ �� ������
    try
      StreamWriterReader.LoadFromStream(Stream);
    finally
      StreamWriterReader.Free;
    end;

    // ����� ���������� � ���������
    mSettingInfo.Lines.Add('������ ������: ' + IntToStr(StreamDataObject.StreamVersion));
    mSettingInfo.Lines.Add('������������� ����: ' + IntToStr(StreamDataObject.StreamDBID));

    // ������ ������� ������ - ���������� ����� ���������� ���������
    CurrentSettingText := '������� �������� �������:' + #13#10;
    for ElementCounter := 0 to StreamLoadingOrderList.Count - 1 do
      CurrentSettingText := CurrentSettingText +
        Format('%6d: %d - %s %s',
          [ElementCounter, TID264(StreamLoadingOrderList.Items[ElementCounter].RecordID),
          StreamDataObject.gdcObject[StreamLoadingOrderList.Items[ElementCounter].DSIndex].Classname,
          StreamDataObject.gdcObject[StreamLoadingOrderList.Items[ElementCounter].DSIndex].SubType]) + #13#10;
    ClassRecordList := TStringList.Create;
    ClassRecordList.Add(CurrentSettingText);
    lbPositions.Items.AddObject(LoadingOrderLineText, ClassRecordList);

    for DataSetCounter := 0 to StreamDataObject.Count - 1 do
    begin
      recCount := StreamDataObject.ClientDS[DataSetCounter].RecordCount;
      if recCount > 0 then
      begin
        CDS := StreamDataObject.ClientDS[DataSetCounter];
        ClassRecordList := TStringList.Create;
        lbPositions.Items.AddObject(StreamDataObject.gdcObject[DataSetCounter].ClassName + '(' +
          StreamDataObject.gdcObject[DataSetCounter].SubType + ') ' +
          StreamDataObject.gdcObject[DataSetCounter].SetTable, ClassRecordList);

        CDS.First;
        while not CDS.Eof do
        begin
          CurrentSettingText := '';
          // ���������� �������� �����
          for ElementCounter := 0 to CDS.FieldCount - 1 do
          begin
            if not CDS.Fields[ElementCounter].IsNull then
            begin
              CurrentSettingText := CurrentSettingText +
                Format('%2d: %20s', [ElementCounter, CDS.Fields[ElementCounter].FieldName]) + ':  ' +
                FormatDatasetFieldValue(CDS.Fields[ElementCounter]) + #13#10;
            end;
          end;
          // ������� ���� ����������� ������ � ������ ������� ������-�������
          if CurrentSettingText <> '' then
            ClassRecordList.Add(CurrentSettingText);

          CDS.Next;
        end;
      end;
    end;
  finally
    StreamDataObject.Free;
    StreamLoadingOrderList.Free;
  end;
end;

procedure Tfrm_SettingView.ReadSettingOldStream(Stream: TStream);
var
  I: Integer;
  MS: TMemoryStream;
  LoadClassName, LoadSubType: String;
  CDS: TDataset;
  OS: TgdcObjectSet;
  OldPos: Integer;
  stRecord: TgsStreamRecord;
  stVersion: String;
  PrSet: TgdcPropertySet;
  CurrentSettingText: String;
  SettingInfoAdded: Boolean;
  ClassRecordList: TStringList;
  ClassRecordListIndex: Integer;
begin
  SettingInfoAdded := False;
  OS := TgdcObjectSet.Create(TgdcBase, '');
  PrSet := TgdcPropertySet.Create('', nil, '');
  try
    OS.LoadFromStream(Stream);

    // ������ ������� ������ - ���������� ����� ���������� ���������
    CurrentSettingText := '������� �������� �������:' + #13#10;
    for I := 0 to OS.Count - 1 do
      CurrentSettingText := CurrentSettingText + Format('%6d: %d', [I, TID264(OS.Items[I])]) + #13#10;

    ClassRecordList := TStringList.Create;
    ClassRecordList.Add(CurrentSettingText);
    lbPositions.Items.AddObject(LoadingOrderLineText, ClassRecordList);

    while Stream.Position < Stream.Size do
    begin
      Stream.ReadBuffer(I, SizeOf(I));
      if I <> cst_StreamLabel then
        raise Exception.Create('Invalid stream format');

      OldPos := Stream.Position;
      SetLength(stVersion, Length(cst_WithVersion));
      Stream.ReadBuffer(stVersion[1], Length(cst_WithVersion));
      if stVersion = cst_WithVersion then
      begin
        Stream.ReadBuffer(stRecord.StreamVersion, SizeOf(stRecord.StreamVersion));
        if stRecord.StreamVersion >= 1 then
          Stream.ReadBuffer(stRecord.StreamDBID, SizeOf(stRecord.StreamDBID));
      end else
      begin
        stRecord.StreamVersion := 0;
        stRecord.StreamDBID := -1;
        Stream.Position := OldPos;
      end;

      // ����� ���������� � ���������
      if not SettingInfoAdded then
      begin
        mSettingInfo.Lines.Add('������ ������: ' + IntToStr(stRecord.StreamVersion));
        mSettingInfo.Lines.Add('������������� ����: ' + IntToStr(stRecord.StreamDBID));
        SettingInfoAdded := True;
      end;

      LoadClassName := StreamReadString(Stream);
      LoadSubType := StreamReadString(Stream);

      ClassRecordListIndex := lbPositions.Items.IndexOf(LoadClassName + '(' + LoadSubType + ')');
      if ClassRecordListIndex > -1 then
      begin
        ClassRecordList := (lbPositions.Items.Objects[ClassRecordListIndex] as TStringList);
      end
      else
      begin
        ClassRecordList := TStringList.Create;
        lbPositions.Items.AddObject(LoadClassName + '(' + LoadSubType + ')', ClassRecordList);
      end;

      if stRecord.StreamVersion >= 2 then
        PrSet.LoadFromStream(Stream);

      Stream.ReadBuffer(I, SizeOf(I));
      MS := TMemoryStream.Create;
      try
        MS.CopyFrom(Stream, I);
        MS.Position := 0;
        CDS := TClientDataSet.Create(nil);
        try
          TClientDataSet(CDS).LoadFromStream(MS);
          CDS.Open;

          CurrentSettingText := '';
          for I := 0 to CDS.FieldCount - 1 do
          begin
            if not CDS.Fields[I].IsNull then
            begin
              CurrentSettingText := CurrentSettingText +
                Format('%2d: %20s', [I, CDS.Fields[I].FieldName]) + ':  ' + FormatDatasetFieldValue(CDS.Fields[I]) + #13#10;
            end;
          end;

          if PrSet.Count > 0 then
            CurrentSettingText := CurrentSettingText + #13#10'��������'#13#10;
          for I := 0 to PrSet.Count - 1 do
            CurrentSettingText := CurrentSettingText +
              Format('%2d: %20s', [I, PrSet.Name[I]]) + ':  ' + VarToStr(PrSet.Value[PrSet.Name[I]]) + #13#10;

          if CurrentSettingText <> '' then
          begin
            ClassRecordList.Add(CurrentSettingText);
          end;
        finally
          FreeAndNil(CDS);
        end;
      finally
        MS.Free;
      end;
    end;
  finally
    PrSet.Free;
    OS.Free;
  end;
end;

procedure Tfrm_SettingView.FormDestroy(Sender: TObject);
var
  I: Integer;
begin
  for I := 0 to lbPositions.Items.Count - 1 do
    if Assigned(lbPositions.Items.Objects[I]) then
      lbPositions.Items.Objects[I].Free;
end;

procedure Tfrm_SettingView.lbPositionsClick(Sender: TObject);
var
  ClassRecordList: TStringList;
  RecordCount: Integer;
  TempStr: String;
  I: Integer;
begin
  sePositionText.Lines.Clear;

  ClassRecordList := TStringList(lbPositions.Items.Objects[lbPositions.ItemIndex]);
  // ������� ������� - ������� �������� ��������
  if lbPositions.ItemIndex = 0 then
  begin
    TempStr := ClassRecordList.Text;
  end
  else
  begin
    RecordCount := ClassRecordList.Count;
    TempStr := '���������� �������: ' + IntToStr(RecordCount) + #13#10#13#10;

    for I := 0 to RecordCount - 1 do
    begin
      TempStr := TempStr + IntToStr(I + 1) + ' �� ' + IntToStr(RecordCount) + #13#10 +
        ClassRecordList.Strings[I] + RecordDivider;
    end;
  end;

  sePositionText.Text := TempStr;
end;

procedure Tfrm_SettingView.btnCloseClick(Sender: TObject);
begin
  Self.Close;
end;

procedure Tfrm_SettingView.actFindExecute(Sender: TObject);
begin
  FSearchReplaceHelper.Search;
end;

procedure Tfrm_SettingView.actFindUpdate(Sender: TObject);
begin
  (Sender as TAction).Enabled := sePositionText.Lines.Count > 0;
end;

procedure Tfrm_SettingView.actFindNextExecute(Sender: TObject);
begin
  FSearchReplaceHelper.SearchNext;
end;

procedure Tfrm_SettingView.FormCreate(Sender: TObject);
begin
  if Assigned(SynManager) then
  begin
    sePositionText.Font.Assign(SynManager.GetHighlighterFont);
    sePositionText.Gutter.Font.Assign(SynManager.GetHighlighterFont);
    mSettingInfo.Font.Assign(SynManager.GetHighlighterFont);
  end;
end;

function Tfrm_SettingView.FormatDatasetFieldValue(AField: TField): String;
var
  TrimmedFieldValue: String;
begin
  TrimmedFieldValue := Trim(AField.AsString);

  case AField.DataType of
    ftString:
      Result := '"' + TrimmedFieldValue + '"';

    ftMemo:
      if AnsiPos(#13#10, TrimmedFieldValue) > 0 then
        Result := #13#10#13#10 + TrimmedFieldValue + #13#10
      else
        Result := '"' + TrimmedFieldValue + '"';

    ftBLOB, ftGraphic:
      //Result := #13#10 + ConvertBinaryToHex(AField.AsString);
      Result := '<BLOB> Size: ' + IntToStr(Length(AField.AsString));
  else
    Result := TrimmedFieldValue;
  end;
end;

constructor Tfrm_SettingView.Create(AnOwner: TComponent);
begin
  inherited;
  // ��������������� ������ ��� ������ �� ���� �����
  FSearchReplaceHelper := TgsSearchReplaceHelper.Create(sePositionText);
end;

destructor Tfrm_SettingView.Destroy;
begin
  FreeAndNil(FSearchReplaceHelper);
  inherited;
end;

end.
