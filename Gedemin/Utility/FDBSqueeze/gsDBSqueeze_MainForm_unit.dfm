object gsDBSqueeze_MainForm: TgsDBSqueeze_MainForm
  Left = 632
  Top = 295
  Width = 940
  Height = 576
  BorderIcons = [biSystemMenu, biMinimize]
  Caption = '������� ������ ���� ������'
  Color = clBtnFace
  Font.Charset = RUSSIAN_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  Menu = MainMenu
  OldCreateOrder = False
  Position = poDesktopCenter
  ShowHint = True
  OnCloseQuery = FormCloseQuery
  PixelsPerInch = 96
  TextHeight = 13
  object Label1: TLabel
    Left = 304
    Top = 292
    Width = 85
    Height = 13
    Caption = 'Backup Directory:'
    Enabled = False
  end
  object pnl1: TPanel
    Left = 0
    Top = 0
    Width = 924
    Height = 517
    Align = alClient
    BevelOuter = bvNone
    BorderWidth = 4
    TabOrder = 0
    object shp10: TShape
      Left = 56
      Top = 24
      Width = 65
      Height = 65
    end
    object shp15: TShape
      Left = 124
      Top = 329
      Width = 83
      Height = 2
      Brush.Color = clBtnShadow
      Pen.Color = clGrayText
    end
    object shp16: TShape
      Left = 88
      Top = 337
      Width = 127
      Height = 2
      Brush.Color = clBtnShadow
      Pen.Color = clGrayText
    end
    object shp17: TShape
      Left = 48
      Top = 337
      Width = 167
      Height = 2
      Brush.Color = clBtnShadow
      Pen.Color = clGrayText
    end
    object pgcMain: TPageControl
      Left = 4
      Top = 4
      Width = 916
      Height = 485
      ActivePage = tsSettings
      Align = alClient
      MultiLine = True
      TabOrder = 0
      TabStop = False
      TabWidth = 100
      object tsSettings: TTabSheet
        BorderWidth = 4
        Caption = '���������'
        object lbl1: TLabel
          Left = 15
          Top = 4
          Width = 69
          Height = 13
          Caption = '���� ������:'
        end
        object Label2: TLabel
          Left = 95
          Top = 24
          Width = 236
          Height = 13
          Caption = '[������[/����]:]����_�_�����_����_������ '
          Font.Charset = RUSSIAN_CHARSET
          Font.Color = clWindowText
          Font.Height = -11
          Font.Name = 'Tahoma'
          Font.Style = [fsItalic]
          ParentFont = False
        end
        object lbl2: TLabel
          Left = 15
          Top = 47
          Width = 76
          Height = 13
          Caption = '������������:'
        end
        object lbl3: TLabel
          Left = 216
          Top = 47
          Width = 41
          Height = 13
          Caption = '������:'
        end
        object Label3: TLabel
          Left = 389
          Top = 4
          Width = 93
          Height = 13
          Caption = '������� �������:'
        end
        object lbl4: TLabel
          Left = 602
          Top = 4
          Width = 88
          Height = 13
          Caption = '������ �������:'
        end
        object edDatabaseName: TEdit
          Left = 95
          Top = 1
          Width = 259
          Height = 21
          Hint = '����:[\�������][\����] '
          TabOrder = 0
        end
        object btnDatabaseBrowse: TButton
          Left = 354
          Top = 2
          Width = 20
          Height = 19
          Action = actDatabaseBrowse
          TabOrder = 3
          TabStop = False
        end
        object edUserName: TEdit
          Left = 95
          Top = 43
          Width = 92
          Height = 21
          Enabled = False
          TabOrder = 4
          Text = 'SYSDBA'
        end
        object edPassword: TEdit
          Left = 262
          Top = 43
          Width = 92
          Height = 21
          PasswordChar = '*'
          TabOrder = 5
        end
        object cbbCharset: TComboBox
          Left = 491
          Top = 1
          Width = 94
          Height = 21
          TabStop = False
          Style = csDropDownList
          DropDownCount = 5
          ItemHeight = 13
          TabOrder = 1
        end
        object btnConnect: TButton
          Left = 95
          Top = 70
          Width = 92
          Height = 21
          Action = actConnect
          TabOrder = 6
          TabStop = False
        end
        object btntTestConnection: TButton
          Left = 188
          Top = 70
          Width = 92
          Height = 21
          Action = actDisconnect
          TabOrder = 7
          TabStop = False
        end
        object seBuffer: TSpinEdit
          Left = 698
          Top = 1
          Width = 79
          Height = 22
          MaxValue = 0
          MinValue = 0
          TabOrder = 2
          Value = 0
        end
        object Panel2: TPanel
          Left = 0
          Top = 96
          Width = 900
          Height = 353
          Align = alBottom
          BevelOuter = bvNone
          TabOrder = 8
          object GroupBox1: TGroupBox
            Left = 0
            Top = 0
            Width = 481
            Height = 353
            Align = alLeft
            Caption = '  ���������  '
            TabOrder = 0
            object lbl5: TLabel
              Left = 13
              Top = 22
              Width = 250
              Height = 13
              Caption = '������� ������ �� gd_document � ����� ������:'
            end
            object dtpClosingDate: TDateTimePicker
              Left = 268
              Top = 18
              Width = 86
              Height = 21
              Hint = '���������� ������ � ������� ���������'
              CalAlignment = dtaLeft
              Date = 41380.5593590046
              Time = 41380.5593590046
              Color = clWhite
              DateFormat = dfShort
              DateMode = dmComboBox
              Kind = dtkDate
              ParseInput = False
              TabOrder = 0
              TabStop = False
            end
            object chkCalculateSaldo: TCheckBox
              Left = 13
              Top = 46
              Width = 334
              Height = 17
              TabStop = False
              Caption = '���������� � ��������� ������������� � ��������� ������'
              Checked = True
              State = cbChecked
              TabOrder = 1
              OnClick = actDefocusExecute
            end
            object btnSelectDocTypes: TButton
              Left = 12
              Top = 70
              Width = 173
              Height = 21
              Action = actSelectDocTypes
              TabOrder = 2
              TabStop = False
            end
            object mIgnoreDocTypes: TMemo
              Left = 12
              Top = 95
              Width = 453
              Height = 215
              TabStop = False
              Color = clWhite
              ReadOnly = True
              ScrollBars = ssVertical
              TabOrder = 3
            end
            object rbExcluding: TRadioButton
              Left = 11
              Top = 331
              Width = 262
              Height = 15
              Caption = '������������ ���, ����� ��������� �����'
              TabOrder = 5
              OnClick = actDefocusExecute
            end
            object rbIncluding: TRadioButton
              Left = 11
              Top = 315
              Width = 249
              Height = 14
              Caption = '������������ ������ ��������� ����'
              Checked = True
              TabOrder = 4
              TabStop = True
              OnClick = actDefocusExecute
            end
          end
          object grpOptions: TGroupBox
            Left = 487
            Top = 0
            Width = 413
            Height = 353
            Align = alClient
            Caption = '  �����  '
            TabOrder = 2
            object chkGetStatiscits: TCheckBox
              Left = 13
              Top = 22
              Width = 309
              Height = 17
              Hint = '���������� �� ��������� � �����'
              TabStop = False
              Caption = '�������� ���������� �� � ����� ���������� ��������'
              Checked = True
              State = cbChecked
              TabOrder = 0
              OnClick = actDefocusExecute
            end
          end
          object Panel3: TPanel
            Left = 481
            Top = 0
            Width = 6
            Height = 353
            Align = alLeft
            BevelOuter = bvNone
            TabOrder = 1
          end
        end
      end
      object tsLogs: TTabSheet
        Caption = '������'
        ImageIndex = 2
        object pnlLogButton: TPanel
          Left = 0
          Top = 430
          Width = 908
          Height = 27
          Align = alBottom
          BevelOuter = bvNone
          TabOrder = 1
          object btnClearGeneralLog: TButton
            Tag = 1
            Left = 796
            Top = 4
            Width = 109
            Height = 21
            Action = actClearLog
            Anchors = [akRight, akBottom]
            TabOrder = 0
            TabStop = False
          end
        end
        object pnlLogs: TPanel
          Left = 0
          Top = 0
          Width = 908
          Height = 430
          Align = alClient
          BevelOuter = bvNone
          TabOrder = 0
          object Splitter1: TSplitter
            Left = 450
            Top = 0
            Width = 3
            Height = 430
            Cursor = crHSplit
          end
          object mLog: TMemo
            Left = 0
            Top = 0
            Width = 450
            Height = 430
            Align = alLeft
            Font.Charset = RUSSIAN_CHARSET
            Font.Color = clWindowText
            Font.Height = -12
            Font.Name = 'Courier New'
            Font.Style = []
            ParentFont = False
            ScrollBars = ssBoth
            TabOrder = 0
          end
          object mSqlLog: TMemo
            Left = 453
            Top = 0
            Width = 455
            Height = 430
            Align = alClient
            Font.Charset = RUSSIAN_CHARSET
            Font.Color = clWindowText
            Font.Height = -12
            Font.Name = 'Courier New'
            Font.Style = []
            ParentFont = False
            ReadOnly = True
            ScrollBars = ssBoth
            TabOrder = 1
          end
        end
      end
      object tsStatistics: TTabSheet
        Caption = '����������'
        ImageIndex = 3
        object shp3: TShape
          Left = 13
          Top = 12
          Width = 306
          Height = 28
          Pen.Color = 671448
          Pen.Mode = pmMask
          Pen.Style = psInsideFrame
          Pen.Width = 3
        end
        object shp4: TShape
          Left = 367
          Top = 38
          Width = 234
          Height = 331
          Brush.Style = bsClear
          Pen.Color = clBtnShadow
          Pen.Width = 3
        end
        object shp2: TShape
          Left = 366
          Top = 12
          Width = 236
          Height = 27
          Pen.Color = 671448
          Pen.Mode = pmMask
          Pen.Style = psInsideFrame
          Pen.Width = 3
        end
        object shp6: TShape
          Left = 14
          Top = 38
          Width = 304
          Height = 331
          Brush.Style = bsClear
          Pen.Color = clBtnShadow
          Pen.Width = 3
        end
        object Shape1: TShape
          Left = 652
          Top = 39
          Width = 216
          Height = 126
          Brush.Style = bsClear
          Pen.Color = clBtnShadow
          Pen.Width = 3
        end
        object Shape2: TShape
          Left = 651
          Top = 13
          Width = 218
          Height = 27
          Pen.Color = 671448
          Pen.Mode = pmMask
          Pen.Style = psInsideFrame
          Pen.Width = 3
        end
        object txt2: TStaticText
          Left = 14
          Top = 11
          Width = 302
          Height = 25
          Alignment = taCenter
          AutoSize = False
          Caption = '���������� ������� � ��������'
          Color = 2058236
          Font.Charset = RUSSIAN_CHARSET
          Font.Color = clWhite
          Font.Height = -17
          Font.Name = 'Tahoma'
          Font.Style = []
          ParentColor = False
          ParentFont = False
          TabOrder = 0
        end
        object pnl2: TPanel
          Left = 367
          Top = 38
          Width = 233
          Height = 330
          Alignment = taLeftJustify
          BevelOuter = bvSpace
          TabOrder = 4
          object StaticText6: TStaticText
            Left = 13
            Top = 14
            Width = 100
            Height = 18
            Alignment = taCenter
            AutoSize = False
            BorderStyle = sbsSunken
            Caption = 'User'
            Color = 2058236
            Font.Charset = RUSSIAN_CHARSET
            Font.Color = clWindow
            Font.Height = -11
            Font.Name = 'Tahoma'
            Font.Style = []
            ParentColor = False
            ParentFont = False
            TabOrder = 0
          end
          object sttxtUser: TStaticText
            Left = 123
            Top = 15
            Width = 97
            Height = 17
            Alignment = taCenter
            AutoSize = False
            BorderStyle = sbsSunken
            Color = clHighlightText
            ParentColor = False
            TabOrder = 1
          end
          object sttxtDialect: TStaticText
            Left = 123
            Top = 39
            Width = 97
            Height = 17
            Alignment = taCenter
            AutoSize = False
            BorderStyle = sbsSunken
            Color = clHighlightText
            ParentColor = False
            TabOrder = 3
          end
          object StaticText5: TStaticText
            Left = 13
            Top = 38
            Width = 100
            Height = 18
            Alignment = taCenter
            AutoSize = False
            BorderStyle = sbsSunken
            Caption = 'SQL Dialect'
            Color = 2058236
            Font.Charset = RUSSIAN_CHARSET
            Font.Color = clWindow
            Font.Height = -11
            Font.Name = 'Tahoma'
            Font.Style = []
            ParentColor = False
            ParentFont = False
            TabOrder = 2
          end
          object sttxt32: TStaticText
            Left = 13
            Top = 62
            Width = 100
            Height = 18
            Alignment = taCenter
            AutoSize = False
            BorderStyle = sbsSunken
            Caption = 'Server Version'
            Color = 2058236
            Font.Charset = RUSSIAN_CHARSET
            Font.Color = clWindow
            Font.Height = -11
            Font.Name = 'Tahoma'
            Font.Style = []
            ParentColor = False
            ParentFont = False
            TabOrder = 4
          end
          object sttxtServerVer: TStaticText
            Left = 123
            Top = 63
            Width = 97
            Height = 17
            Alignment = taCenter
            AutoSize = False
            BorderStyle = sbsSunken
            Color = clHighlightText
            ParentColor = False
            TabOrder = 5
          end
          object sttxt34: TStaticText
            Left = 13
            Top = 86
            Width = 100
            Height = 18
            Alignment = taCenter
            AutoSize = False
            BorderStyle = sbsSunken
            Caption = 'ODS Version'
            Color = 2058236
            Font.Charset = RUSSIAN_CHARSET
            Font.Color = clWindow
            Font.Height = -11
            Font.Name = 'Tahoma'
            Font.Style = []
            ParentColor = False
            ParentFont = False
            TabOrder = 6
          end
          object sttxtODSVer: TStaticText
            Left = 123
            Top = 87
            Width = 97
            Height = 17
            Alignment = taCenter
            AutoSize = False
            BorderStyle = sbsSunken
            Color = clHighlightText
            ParentColor = False
            TabOrder = 7
          end
          object sttxtRemoteProtocol: TStaticText
            Left = 123
            Top = 111
            Width = 97
            Height = 17
            Alignment = taCenter
            AutoSize = False
            BorderStyle = sbsSunken
            Color = clHighlightText
            ParentColor = False
            TabOrder = 9
          end
          object StaticText7: TStaticText
            Left = 13
            Top = 110
            Width = 100
            Height = 18
            Alignment = taCenter
            AutoSize = False
            BorderStyle = sbsSunken
            Caption = 'Remote Protocol'
            Color = 2058236
            Font.Charset = RUSSIAN_CHARSET
            Font.Color = clWindow
            Font.Height = -11
            Font.Name = 'Tahoma'
            Font.Style = []
            ParentColor = False
            ParentFont = False
            TabOrder = 8
          end
          object StaticText8: TStaticText
            Left = 13
            Top = 134
            Width = 100
            Height = 18
            Alignment = taCenter
            AutoSize = False
            BorderStyle = sbsSunken
            Caption = 'Remote Address'
            Color = 2058236
            Font.Charset = RUSSIAN_CHARSET
            Font.Color = clWindow
            Font.Height = -11
            Font.Name = 'Tahoma'
            Font.Style = []
            ParentColor = False
            ParentFont = False
            TabOrder = 10
          end
          object sttxtRemoteAddr: TStaticText
            Left = 123
            Top = 135
            Width = 97
            Height = 17
            Alignment = taCenter
            AutoSize = False
            BorderStyle = sbsSunken
            Color = clHighlightText
            ParentColor = False
            TabOrder = 11
          end
          object sttxtPageSize: TStaticText
            Left = 123
            Top = 159
            Width = 97
            Height = 17
            Alignment = taCenter
            AutoSize = False
            BorderStyle = sbsSunken
            Color = clHighlightText
            ParentColor = False
            TabOrder = 13
          end
          object StaticText9: TStaticText
            Left = 13
            Top = 158
            Width = 100
            Height = 18
            Alignment = taCenter
            AutoSize = False
            BorderStyle = sbsSunken
            Caption = 'Page Size'
            Color = 2058236
            Font.Charset = RUSSIAN_CHARSET
            Font.Color = clWindow
            Font.Height = -11
            Font.Name = 'Tahoma'
            Font.Style = []
            ParentColor = False
            ParentFont = False
            TabOrder = 12
          end
          object StaticText10: TStaticText
            Left = 13
            Top = 182
            Width = 100
            Height = 18
            Alignment = taCenter
            AutoSize = False
            BorderStyle = sbsSunken
            Caption = 'Page Buffers'
            Color = 2058236
            Font.Charset = RUSSIAN_CHARSET
            Font.Color = clWindow
            Font.Height = -11
            Font.Name = 'Tahoma'
            Font.Style = []
            ParentColor = False
            ParentFont = False
            TabOrder = 14
          end
          object sttxtPageBuffers: TStaticText
            Left = 123
            Top = 183
            Width = 97
            Height = 17
            Alignment = taCenter
            AutoSize = False
            BorderStyle = sbsSunken
            Color = clHighlightText
            ParentColor = False
            TabOrder = 15
          end
          object sttxtForcedWrites: TStaticText
            Left = 123
            Top = 207
            Width = 97
            Height = 17
            Alignment = taCenter
            AutoSize = False
            BorderStyle = sbsSunken
            Color = clHighlightText
            ParentColor = False
            TabOrder = 17
          end
          object StaticText11: TStaticText
            Left = 13
            Top = 206
            Width = 100
            Height = 18
            Alignment = taCenter
            AutoSize = False
            BorderStyle = sbsSunken
            Caption = 'Forced Writes'
            Color = 2058236
            Font.Charset = RUSSIAN_CHARSET
            Font.Color = clWindow
            Font.Height = -11
            Font.Name = 'Tahoma'
            Font.Style = []
            ParentColor = False
            ParentFont = False
            TabOrder = 16
          end
          object StaticText12: TStaticText
            Left = 13
            Top = 229
            Width = 100
            Height = 18
            Alignment = taCenter
            AutoSize = False
            BorderStyle = sbsSunken
            Caption = 'Garbage Collection'
            Color = 2058236
            Font.Charset = RUSSIAN_CHARSET
            Font.Color = clWindow
            Font.Height = -11
            Font.Name = 'Tahoma'
            Font.Style = []
            ParentColor = False
            ParentFont = False
            TabOrder = 18
          end
          object sttxtGarbageCollection: TStaticText
            Left = 123
            Top = 230
            Width = 97
            Height = 17
            Alignment = taCenter
            AutoSize = False
            BorderStyle = sbsSunken
            Color = clHighlightText
            ParentColor = False
            TabOrder = 19
          end
        end
        object sttxt30: TStaticText
          Left = 367
          Top = 11
          Width = 232
          Height = 25
          Alignment = taCenter
          AutoSize = False
          Caption = '�������� ��'
          Color = 2058236
          Font.Charset = RUSSIAN_CHARSET
          Font.Color = clWhite
          Font.Height = -17
          Font.Name = 'Tahoma'
          Font.Style = []
          ParentColor = False
          ParentFont = False
          TabOrder = 1
        end
        object pnl4: TPanel
          Left = 14
          Top = 38
          Width = 303
          Height = 330
          TabOrder = 3
          object txt10: TStaticText
            Left = 123
            Top = 14
            Width = 79
            Height = 17
            Alignment = taCenter
            AutoSize = False
            BorderStyle = sbsSunken
            Caption = 'ORIGINAL'
            Color = 2058236
            Font.Charset = RUSSIAN_CHARSET
            Font.Color = clWindow
            Font.Height = -11
            Font.Name = 'Tahoma'
            Font.Style = []
            ParentColor = False
            ParentFont = False
            TabOrder = 0
          end
          object sttxt11: TStaticText
            Left = 211
            Top = 14
            Width = 79
            Height = 17
            Alignment = taCenter
            AutoSize = False
            BorderStyle = sbsSunken
            Caption = 'CURRENT'
            Color = 2058236
            Font.Charset = RUSSIAN_CHARSET
            Font.Color = clWindow
            Font.Height = -11
            Font.Name = 'Tahoma'
            Font.Style = []
            ParentColor = False
            ParentFont = False
            TabOrder = 1
          end
          object sttxtGdDocAfter: TStaticText
            Left = 211
            Top = 42
            Width = 79
            Height = 17
            Alignment = taCenter
            AutoSize = False
            BorderStyle = sbsSunken
            Color = clHighlightText
            ParentColor = False
            TabOrder = 4
          end
          object sttxtGdDoc: TStaticText
            Left = 123
            Top = 42
            Width = 79
            Height = 17
            Alignment = taCenter
            AutoSize = False
            BorderStyle = sbsSunken
            Color = clHighlightText
            ParentColor = False
            TabOrder = 3
          end
          object txt3: TStaticText
            Left = 11
            Top = 41
            Width = 100
            Height = 18
            Alignment = taCenter
            AutoSize = False
            BorderStyle = sbsSunken
            Caption = 'GD_DOCUMENT'
            Color = 671448
            Font.Charset = RUSSIAN_CHARSET
            Font.Color = clWindow
            Font.Height = -11
            Font.Name = 'Tahoma'
            Font.Style = []
            ParentColor = False
            ParentFont = False
            TabOrder = 2
          end
          object txt4: TStaticText
            Left = 11
            Top = 70
            Width = 100
            Height = 17
            Alignment = taCenter
            AutoSize = False
            BorderStyle = sbsSunken
            Caption = 'AC_ENTRY'
            Color = 671448
            Font.Charset = RUSSIAN_CHARSET
            Font.Color = clWindow
            Font.Height = -11
            Font.Name = 'Tahoma'
            Font.Style = []
            ParentColor = False
            ParentFont = False
            TabOrder = 5
          end
          object sttxtAcEntry: TStaticText
            Left = 123
            Top = 70
            Width = 79
            Height = 17
            Alignment = taCenter
            AutoSize = False
            BorderStyle = sbsSunken
            Color = clHighlightText
            ParentColor = False
            TabOrder = 6
          end
          object sttxtAcEntryAfter: TStaticText
            Left = 211
            Top = 70
            Width = 79
            Height = 17
            Alignment = taCenter
            AutoSize = False
            BorderStyle = sbsSunken
            Color = clHighlightText
            ParentColor = False
            TabOrder = 7
          end
          object txt5: TStaticText
            Left = 11
            Top = 98
            Width = 100
            Height = 17
            Alignment = taCenter
            AutoSize = False
            BorderStyle = sbsSunken
            Caption = 'INV_MOVEMENT'
            Color = 671448
            Font.Charset = RUSSIAN_CHARSET
            Font.Color = clWindow
            Font.Height = -11
            Font.Name = 'Tahoma'
            Font.Style = []
            ParentColor = False
            ParentFont = False
            TabOrder = 8
          end
          object sttxtInvMovement: TStaticText
            Left = 123
            Top = 98
            Width = 79
            Height = 17
            Alignment = taCenter
            AutoSize = False
            BorderStyle = sbsSunken
            Color = clHighlightText
            ParentColor = False
            TabOrder = 9
          end
          object sttxtInvMovementAfter: TStaticText
            Left = 211
            Top = 98
            Width = 79
            Height = 17
            Alignment = taCenter
            AutoSize = False
            BorderStyle = sbsSunken
            Color = clHighlightText
            ParentColor = False
            TabOrder = 10
          end
          object txt6: TStaticText
            Left = 11
            Top = 124
            Width = 100
            Height = 17
            Alignment = taCenter
            AutoSize = False
            BorderStyle = sbsSunken
            Caption = 'INV_CARD'
            Color = 671448
            Font.Charset = RUSSIAN_CHARSET
            Font.Color = clWindow
            Font.Height = -11
            Font.Name = 'Tahoma'
            Font.Style = []
            ParentColor = False
            ParentFont = False
            TabOrder = 11
          end
          object sttxtInvCard: TStaticText
            Left = 123
            Top = 125
            Width = 79
            Height = 17
            Alignment = taCenter
            AutoSize = False
            BorderStyle = sbsSunken
            Color = clHighlightText
            ParentColor = False
            TabOrder = 12
          end
          object sttxtInvCardAfter: TStaticText
            Left = 211
            Top = 125
            Width = 79
            Height = 17
            Alignment = taCenter
            AutoSize = False
            BorderStyle = sbsSunken
            Color = clHighlightText
            ParentColor = False
            TabOrder = 13
          end
          object sttxt2: TStaticText
            Left = 0
            Top = 159
            Width = 302
            Height = 24
            Alignment = taCenter
            AutoSize = False
            Caption = '���������� ��� ��������'
            Color = 2058236
            Font.Charset = RUSSIAN_CHARSET
            Font.Color = clWhite
            Font.Height = -17
            Font.Name = 'Tahoma'
            Font.Style = []
            ParentColor = False
            ParentFont = False
            TabOrder = 14
          end
          object sttxt3: TStaticText
            Left = 11
            Top = 195
            Width = 100
            Height = 17
            Alignment = taCenter
            AutoSize = False
            BorderStyle = sbsSunken
            Caption = 'GD_DOCUMENT'
            Color = 671448
            Font.Charset = RUSSIAN_CHARSET
            Font.Color = clWindow
            Font.Height = -11
            Font.Name = 'Tahoma'
            Font.Style = []
            ParentColor = False
            ParentFont = False
            TabOrder = 15
          end
          object sttxt4: TStaticText
            Left = 11
            Top = 219
            Width = 100
            Height = 17
            Alignment = taCenter
            AutoSize = False
            BorderStyle = sbsSunken
            Caption = 'AC_ENTRY'
            Color = 671448
            Font.Charset = RUSSIAN_CHARSET
            Font.Color = clWindow
            Font.Height = -11
            Font.Name = 'Tahoma'
            Font.Style = []
            ParentColor = False
            ParentFont = False
            TabOrder = 18
          end
          object sttxt5: TStaticText
            Left = 11
            Top = 244
            Width = 100
            Height = 17
            Alignment = taCenter
            AutoSize = False
            BorderStyle = sbsSunken
            Caption = 'INV_MOVEMENT'
            Color = 671448
            Font.Charset = RUSSIAN_CHARSET
            Font.Color = clWindow
            Font.Height = -11
            Font.Name = 'Tahoma'
            Font.Style = []
            ParentColor = False
            ParentFont = False
            TabOrder = 21
          end
          object sttxt6: TStaticText
            Left = 11
            Top = 268
            Width = 100
            Height = 17
            Alignment = taCenter
            AutoSize = False
            BorderStyle = sbsSunken
            Caption = 'INV_CARD'
            Color = 671448
            Font.Charset = RUSSIAN_CHARSET
            Font.Color = clWindow
            Font.Height = -11
            Font.Name = 'Tahoma'
            Font.Style = []
            ParentColor = False
            ParentFont = False
            TabOrder = 24
          end
          object sttxtProcGdDoc: TStaticText
            Left = 124
            Top = 196
            Width = 79
            Height = 17
            Alignment = taCenter
            AutoSize = False
            BorderStyle = sbsSunken
            Color = clHighlightText
            ParentColor = False
            TabOrder = 16
          end
          object sttxtProcAcEntry: TStaticText
            Left = 123
            Top = 220
            Width = 79
            Height = 17
            Alignment = taCenter
            AutoSize = False
            BorderStyle = sbsSunken
            Color = clHighlightText
            ParentColor = False
            TabOrder = 19
          end
          object sttxtProcInvMovement: TStaticText
            Left = 123
            Top = 244
            Width = 79
            Height = 17
            Alignment = taCenter
            AutoSize = False
            BorderStyle = sbsSunken
            Color = clHighlightText
            ParentColor = False
            TabOrder = 22
          end
          object sttxtProcInvCard: TStaticText
            Left = 122
            Top = 268
            Width = 79
            Height = 17
            Alignment = taCenter
            AutoSize = False
            BorderStyle = sbsSunken
            Color = clHighlightText
            ParentColor = False
            TabOrder = 25
          end
          object sttxtAfterProcGdDoc: TStaticText
            Left = 212
            Top = 196
            Width = 79
            Height = 17
            Alignment = taCenter
            AutoSize = False
            BorderStyle = sbsSunken
            Color = clHighlightText
            ParentColor = False
            TabOrder = 17
          end
          object sttxtAfterProcAcEntry: TStaticText
            Left = 212
            Top = 220
            Width = 79
            Height = 17
            Alignment = taCenter
            AutoSize = False
            BorderStyle = sbsSunken
            Color = clHighlightText
            ParentColor = False
            TabOrder = 20
          end
          object sttxtAfterProcInvMovement: TStaticText
            Left = 212
            Top = 244
            Width = 79
            Height = 17
            Alignment = taCenter
            AutoSize = False
            BorderStyle = sbsSunken
            Color = clHighlightText
            ParentColor = False
            TabOrder = 23
          end
          object sttxtAfterProcInvCard: TStaticText
            Left = 212
            Top = 268
            Width = 79
            Height = 17
            Alignment = taCenter
            AutoSize = False
            BorderStyle = sbsSunken
            Color = clHighlightText
            ParentColor = False
            TabOrder = 26
          end
          object btnGetStatistics: TButton
            Left = 122
            Top = 296
            Width = 79
            Height = 21
            Action = actGet
            Caption = '��������'
            Font.Charset = RUSSIAN_CHARSET
            Font.Color = clWindowText
            Font.Height = -11
            Font.Name = 'Tahoma'
            Font.Style = []
            ParentFont = False
            TabOrder = 27
            TabStop = False
            OnMouseDown = btnGetStatisticsMouseDown
          end
          object btnUpdateStatistics: TBitBtn
            Left = 212
            Top = 296
            Width = 79
            Height = 21
            Action = actGet
            Caption = '��������'
            TabOrder = 28
            TabStop = False
            OnMouseDown = btnGetStatisticsMouseDown
          end
        end
        object Panel4: TPanel
          Left = 652
          Top = 39
          Width = 215
          Height = 125
          Alignment = taLeftJustify
          BevelOuter = bvSpace
          TabOrder = 5
          object sttxtOrigInvCard: TStaticText
            Left = 15
            Top = 62
            Width = 90
            Height = 17
            Alignment = taCenter
            AutoSize = False
            BorderStyle = sbsSunken
            Color = clHighlightText
            ParentColor = False
            TabOrder = 3
          end
          object sttxtCurInvCard: TStaticText
            Left = 112
            Top = 62
            Width = 90
            Height = 17
            Alignment = taCenter
            AutoSize = False
            BorderStyle = sbsSunken
            Color = clHighlightText
            ParentColor = False
            TabOrder = 4
          end
          object StaticText1: TStaticText
            Left = 15
            Top = 38
            Width = 90
            Height = 18
            Alignment = taCenter
            AutoSize = False
            BorderStyle = sbsSunken
            Caption = 'ORIGINAL'
            Color = 2058236
            Font.Charset = RUSSIAN_CHARSET
            Font.Color = clWindow
            Font.Height = -11
            Font.Name = 'Tahoma'
            Font.Style = []
            ParentColor = False
            ParentFont = False
            TabOrder = 1
          end
          object StaticText2: TStaticText
            Left = 112
            Top = 38
            Width = 90
            Height = 18
            Alignment = taCenter
            AutoSize = False
            BorderStyle = sbsSunken
            Caption = 'CURRENT'
            Color = 2058236
            Font.Charset = RUSSIAN_CHARSET
            Font.Color = clWindow
            Font.Height = -11
            Font.Name = 'Tahoma'
            Font.Style = []
            ParentColor = False
            ParentFont = False
            TabOrder = 2
          end
          object btnGetStatisticsInvCard: TButton
            Left = 14
            Top = 91
            Width = 90
            Height = 21
            Action = actGetStatisticsInvCard
            Caption = '��������'
            Font.Charset = RUSSIAN_CHARSET
            Font.Color = clWindowText
            Font.Height = -11
            Font.Name = 'Tahoma'
            Font.Style = []
            ParentFont = False
            TabOrder = 5
            TabStop = False
            OnMouseDown = btnGetStatisticsMouseDown
          end
          object btnUpdateStatisticsInvCard: TBitBtn
            Left = 112
            Top = 91
            Width = 90
            Height = 21
            Action = actGetStatisticsInvCard
            Caption = '��������'
            TabOrder = 6
            TabStop = False
            OnMouseDown = btnGetStatisticsMouseDown
          end
          object txt1: TStaticText
            Left = 1
            Top = 8
            Width = 213
            Height = 18
            Alignment = taCenter
            AutoSize = False
            Caption = '���������� ������� INV_CARD'
            Color = 671448
            Font.Charset = RUSSIAN_CHARSET
            Font.Color = clWhite
            Font.Height = -13
            Font.Name = 'Tahoma'
            Font.Style = []
            ParentColor = False
            ParentFont = False
            TabOrder = 0
          end
        end
        object StaticText29: TStaticText
          Left = 652
          Top = 12
          Width = 214
          Height = 25
          Alignment = taCenter
          AutoSize = False
          Caption = '����������� ��������'
          Color = 2058236
          Font.Charset = RUSSIAN_CHARSET
          Font.Color = clWhite
          Font.Height = -17
          Font.Name = 'Tahoma'
          Font.Style = []
          ParentColor = False
          ParentFont = False
          TabOrder = 2
        end
      end
    end
    object Panel1: TPanel
      Left = 4
      Top = 489
      Width = 916
      Height = 24
      Align = alBottom
      BevelOuter = bvNone
      TabOrder = 1
      object lblProgress: TLabel
        Left = 745
        Top = 0
        Width = 52
        Height = 13
        Alignment = taCenter
        Caption = 'lblProgress'
        Layout = tlCenter
      end
      object pbMain: TProgressBar
        Left = 1
        Top = 5
        Width = 796
        Height = 19
        Anchors = [akLeft, akRight, akBottom]
        DragCursor = crDefault
        Min = 0
        Max = 12500
        Smooth = True
        TabOrder = 0
      end
      object stConnect: TStaticText
        Left = 802
        Top = 5
        Width = 122
        Height = 19
        Alignment = taCenter
        Anchors = [akRight, akBottom]
        AutoSize = False
        BorderStyle = sbsSunken
        Caption = '���������'
        TabOrder = 1
      end
    end
  end
  object ActionList: TActionList
    Left = 829
    Top = 446
    object actGo: TAction
      Caption = '������ �������'
      OnExecute = actGoExecute
      OnUpdate = actGoUpdate
    end
    object actCompany: TAction
      Caption = 'actCompany'
    end
    object actDatabaseBrowse: TAction
      Caption = '...'
      OnExecute = actDatabaseBrowseExecute
      OnUpdate = actDatabaseBrowseUpdate
    end
    object actGet: TAction
      Caption = 'actGet'
      OnExecute = actGetExecute
      OnUpdate = actGetUpdate
    end
    object actUpdate: TAction
      Caption = 'actUpdate'
    end
    object actStop: TAction
      Caption = '���������� �������'
      OnExecute = actStopExecute
      OnUpdate = actStopUpdate
    end
    object actDisconnect: TAction
      Caption = '�����������'
      OnExecute = actDisconnectExecute
      OnUpdate = actDisconnectUpdate
    end
    object actClearLog: TAction
      Caption = '��������'
      OnExecute = actClearLogExecute
    end
    object actDefocus: TAction
      OnExecute = actDefocusExecute
    end
    object actConfigBrowse: TAction
      Caption = 'actConfigBrowse'
    end
    object actConnect: TAction
      Caption = '������������'
      OnExecute = actConnectExecute
      OnUpdate = actConnectUpdate
    end
    object actExit: TAction
      Caption = '�����'
      OnExecute = actExitExecute
      OnUpdate = actExitUpdate
    end
    object actLoadConfig: TAction
      Caption = '��������� ������������...'
      OnExecute = actLoadConfigExecute
      OnUpdate = actLoadConfigUpdate
    end
    object actSaveConfig: TAction
      Caption = '��������� ������������...'
      OnExecute = actSaveConfigExecute
      OnUpdate = actSaveConfigUpdate
    end
    object actAbout: TAction
      Caption = '� ���������...'
      OnExecute = actAboutExecute
    end
    object actSelectDocTypes: TAction
      Caption = '������� ���� ����������...'
      OnExecute = actSelectDocTypesExecute
      OnUpdate = actSelectDocTypesUpdate
    end
    object actMergeCardDlg: TAction
      Caption = 'actMergeCardDlg'
    end
    object actCardSetup: TAction
      Caption = '����������� ��������'
      OnExecute = actCardSetupExecute
      OnUpdate = actCardSetupUpdate
    end
    object actSaveLog: TAction
      Caption = 'actSaveLog'
      OnExecute = actSaveLogExecute
      OnUpdate = actSaveLogUpdate
    end
    object actSaldoTest: TAction
      Caption = 'actSaldoTest'
      OnExecute = actSaldoTestExecute
      OnUpdate = actSaldoTestUpdate
    end
    object actGetStatisticsInvCard: TAction
      Caption = 'actGetStatisticsInvCard'
      OnExecute = actGetStatisticsInvCardExecute
      OnUpdate = actGetStatisticsInvCardUpdate
    end
  end
  object MainMenu: TMainMenu
    Left = 864
    Top = 447
    object N1: TMenuItem
      Caption = '���� ������'
      object N4: TMenuItem
        Action = actConnect
      end
      object N5: TMenuItem
        Action = actDisconnect
      end
      object N6: TMenuItem
        Caption = '-'
      end
      object N11: TMenuItem
        Action = actGo
      end
      object STOP1: TMenuItem
        Action = actStop
      end
      object N3: TMenuItem
        Caption = '-'
      end
      object N2: TMenuItem
        Action = actExit
      end
    end
    object N12: TMenuItem
      Caption = '�����������'
      object N15: TMenuItem
        Action = actCardSetup
      end
      object TEST1: TMenuItem
        Action = actSaldoTest
        Caption = '�������� ������'
      end
    end
    object N14: TMenuItem
      Caption = '���������'
      object N7: TMenuItem
        Action = actLoadConfig
      end
      object N8: TMenuItem
        Action = actSaveConfig
      end
      object N10: TMenuItem
        Caption = '-'
      end
      object N13: TMenuItem
        Action = actSaveLog
        Caption = 'C�������� ������ � ����...'
      end
    end
    object N9: TMenuItem
      Action = actAbout
    end
  end
end
