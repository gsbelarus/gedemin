�
 TFORM1 0�	  TPF0TForm1Form1Left� Top~Width,Height�CaptionForm1Color	clBtnFaceFont.CharsetDEFAULT_CHARSET
Font.ColorclWindowTextFont.Height�	Font.NameMS Sans Serif
Font.Style OldCreateOrderOnCreate
FormCreatePixelsPerInch`
TextHeight 	TSplitter	Splitter1LeftTop)WidthHeightHCursorcrHSplit  	TgsIBGrid	gsIBGrid1Left Top)WidthHeightHAlignalLeft
DataSourceDataSource1	PopupMenu
PopupMenu1TabOrder StripedInternalMenuKindimkWithSeparatorExpands ExpandsActiveExpandsSeparate
Conditions ConditionsActiveCheckBox.VisibleScaleColumnsMinColWidth(Aliases   	TgsIBGrid	gsIBGrid2LeftTop)Width HeightHAlignalClient
DataSourceDataSource2	PopupMenu
PopupMenu2TabOrderStripedInternalMenuKindimkWithSeparatorExpands ExpandsActiveExpandsSeparate
Conditions ConditionsActiveCheckBox.VisibleScaleColumnsMinColWidth(Aliases   TPanelPanel1Left Top Width$Height)AlignalTopTabOrder TEditEdit1LeftTopWidthyHeightTabOrder Text50  TEditEdit2Left� TopWidthyHeightTabOrderText100  TButtonButton1LeftTopWidthKHeightCaptionButton1TabOrderOnClickButton1Click   TDataSourceDataSource1DataSetIBQuery1Left� Top  TDataSourceDataSource2DataSet
IBDataSet1Left Top  TIBQueryIBQuery1DatabasedmDatabase.ibdbGAdminTransactiondmDatabase.ibtrAttrBufferChunks�CachedUpdatesSQL.StringsSELECT   *FROM   gd_good gg  , gd_goodgroup grWHERE  gr.lb > :lb  AND gr.rb <= :rb  AND gg.groupkey = gr.id0  AND g_sec_test(gg.afull, /*UserGroup*/-1) <> 0 Left� Top(	ParamDataDataType	ftUnknownNamelb	ParamType	ptUnknown DataType	ftUnknownNamerb	ParamType	ptUnknown    
TIBDataSet
IBDataSet1DatabasedmDatabase.ibdbGAdminTransactiondmDatabase.ibtrAttrBufferChunks�CachedUpdatesSelectSQL.StringsSELECT   *FROM   gd_good gg  , gd_goodgroup grWHERE  gr.lb > :lb  AND gr.rb <= :rb  AND gg.groupkey = gr.id0  AND g_sec_test(gg.afull, /*UserGroup*/-1) <> 0 Left Top(  TgsQueryFiltergsQueryFilter1DatabasedmDatabase.ibdbGAdmin
FilterMenu
PopupMenu2	IBDataSet
IBDataSet1Left�Top  TgsQueryFiltergsQueryFilter2DatabasedmDatabase.ibdbGAdmin
FilterMenu
PopupMenu1	IBDataSetIBQuery1Left� Top  
TPopupMenu
PopupMenu1Left� Top(  
TPopupMenu
PopupMenu2Left�Top(  	TboAccess	boAccess1DataSetList.StringsIBQuery1
IBDataSet1 Left� TopH   