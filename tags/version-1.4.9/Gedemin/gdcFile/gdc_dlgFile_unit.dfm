inherited gdc_dlgFile: Tgdc_dlgFile
  Left = 375
  Top = 217
  HelpContext = 20
  Caption = '����'
  ClientHeight = 361
  ClientWidth = 378
  OldCreateOrder = True
  PixelsPerInch = 96
  TextHeight = 13
  inherited btnAccess: TButton
    Left = 2
    Top = 333
  end
  inherited btnNew: TButton
    Left = 74
    Top = 333
  end
  inherited btnOK: TButton
    Left = 235
    Top = 333
  end
  inherited btnCancel: TButton
    Left = 307
    Top = 333
  end
  inherited btnHelp: TButton
    Left = 146
    Top = 333
  end
  inherited Panel1: TPanel
    Width = 378
    Height = 326
    inherited GroupBox1: TGroupBox
      Width = 361
      Height = 161
      inherited Label3: TLabel
        Top = 131
        Width = 77
        Caption = '������ �����:'
      end
      inherited lblDataSize: TLabel
        Top = 131
        Visible = False
      end
      object dbtDataSize: TDBText [6]
        Left = 128
        Top = 131
        Width = 65
        Height = 17
        DataField = 'datasize'
        DataSource = dsgdcBase
      end
      object Label6: TLabel [7]
        Left = 24
        Top = 84
        Width = 53
        Height = 13
        Caption = '��������:'
      end
      object dbmDescription: TDBMemo
        Left = 128
        Top = 82
        Width = 209
        Height = 47
        DataField = 'description'
        DataSource = dsgdcBase
        TabOrder = 2
      end
    end
    object GroupBox2: TGroupBox
      Left = 8
      Top = 168
      Width = 361
      Height = 153
      TabOrder = 1
      object Image1: TImage
        Left = 24
        Top = 24
        Width = 121
        Height = 113
        Picture.Data = {
          09544D65746166696C65920F0000D7CDC69A0000000000004A0AFB085E020000
          0000FE57010009000003BC0700000300CC0000000000050000000C02FB084A0A
          050000000B020000000004000000050101000400000004010D00040000000601
          01000400000002010200050000000102FFFFFFFF040000002E01180008000000
          FA0205000000000000000000040000002D01000007000000FC020000A38C8C00
          0000040000002D0101002000000024030E00DF0191083302B808FB0591081907
          E7088D07D708360AA2062E0A73061009F70510099305F9073D058102D807F501
          6308DF019108DF01910807000000FC020000FFFFFF000000040000002D010200
          04000000F00101001A00000024030B00E6000501E700D501AE006C029E012F03
          A7003C05230246084905DE07720700065A059B01E6000501E600050107000000
          FC020000CCCCFF000000040000002D01010004000000F0010200120000002403
          070036017A036B009B038400D603F50111065101D00336017A0336017A031400
          000024030800E000C0043900FF04F50163080C0446082002E107C3002A05E000
          C004E000C00407000000FC020000F09999000000040000002D01020004000000
          F00101001600000024030900F50320002300DA0016000301C303630291040F02
          5202540114045300F5032000F50320001A00000024030B00D4000E0231005202
          31008202C3033704E604DF03F80490035B048303BF03BD03BD006502D4000E02
          D4000E0207000000FC020000F7A856000000040000002D01010004000000F001
          02002000000024030E000D013C0309018E031001E9033E011804A20130042A03
          5005D703D5055404F00543044A05A2044F04E10345042B0114030D013C030D01
          3C0307000000FC020000F0EAB2000000040000002D01020004000000F0010100
          26000000240311003A036A015E035D01BB034501F80336013D04250186041401
          D20402011E05F0006705DF00AC05CF00E905C1004506AC006806A4009507D700
          A503AC013A036A013A036A0114000000240308005D036304DA03710486030605
          75037D052A0350053B0399045D0363045D0363041000000024030600AA028705
          20037C05C9030406C8022306AA028705AA02870507000000FC020000D1BABA00
          0000040000002D01010004000000F00102002800000024031200C502FF06B402
          64075C02CA07DA033008D106E9070707D4076C07E907C407DE072608CE073D08
          BC0762089D0784087F0793087207A708B1063B0833062B069206C502FF06C502
          FF0607000000FC0200007A7AAD000000040000002D01020004000000F0010100
          4E00000024032500AE00BD03FF00A9032F01260473013904F802540569027605
          C80223060A040106DC0441062207870545089805BF083A069E0870073408C707
          5B07EF07F606D807A506F30797033D082002E1073103B9076607640712085A07
          5608BB064B08A9063208810624086B0617085706050841065A075306EB066206
          B9066A06B702E0068002EF06A400FA03DB018A05AE00BD03AE00BD0307000000
          FC020000948D4D000000040000002D01010004000000F0010200160000002403
          09003106EC055007E005C307D3059107A105A3077305330787059A06C7053106
          EC053106EC0507000000FC020000B8AD4C000000040000002D01020004000000
          F00101001C00000024030C00190357051303EE043B037B045D033A04C6037104
          A4038204640393044503E0044503320575037D05190357051903570514000000
          2403080034035F01240696008606AB00EA036701DE06E800F903E60134035F01
          34035F011A00000024030B0069027605E80258058B03B105FC030206B5030E06
          6703DB052E03A205D2029805C8022306690276056902760507000000FC020000
          FFB2B2000000040000002D01010004000000F001020028000000240312000E05
          A402D30563021006AE02B80571045C05C204590598050E054305FF04E104F004
          9D04E1047D04DE046E04E1044804F204D7030705660312053203F704B5020E05
          A4020E05A40207000000FC020000FF4D4D000000040000002D01020004000000
          F00101003E00000024031D0001058C02FB0542024206D302D30515042706EB04
          9D05CC046005AC052805F9040B0552043E059B03180510035505D3029D05E702
          82052803B4054A034F05150482050B044F05A40492055604B105BA03B1058A03
          E7051703C2050D03CF05B5027B05A702880585021205C60201058C0201058C02
          07000000FC020000B56C43000000040000002D01010004000000F00102001C00
          000024030C002101F0034A01AF037C0194038301D5030E025904DC02D0043B03
          7B0405036505650130042F0126042101F0032101F00316000000240309002B01
          350315015F0376016C031D0348043B037B047803410454011A032B0135032B01
          3503340000002403180093033C05C9039B052504C005280439056504A0041404
          C904F503E004EB03B504EF035C04E604DF03E1047D04B4049F0494044D05D204
          CE058908AE04420823048609AA045009D004DC04410678042906AB03D5058C03
          760593033C0593033C051400000024030800100668037A07DA0258094D03FF08
          8703D6056704CC050104100668031006680307000000FC020000AE4D4D000000
          040000002D01020004000000F001010010000000240306004300860253006702
          EF032604DA037104430086024300860207000000FC020000D1BABA0000000400
          00002D01010004000000F00102002A00000024031300E700D5011B04FC02F903
          9803AC045B0312053203F704A702FB0542022E06A40210064D037D079C02E307
          A4024508E9013B085F01BA0717010A043E02C3036302E1006501E700D501E700
          D50107000000FC020000AE4D4D000000040000002D01020004000000F0010100
          36000000240319006A00F2005B041C0075068F0009036201D403A9014A07D000
          A407AC001908EB004C0839014F081202E307A4027D07AB026C07D70211070303
          A10625030506760310064D034206D302B7073E02FE07E601EA074A01B7072D01
          0D0431026A00F2006A00F20007000000FC020000D1BABA000000040000002D01
          010004000000F00102002600000024031100E70571044F08D10348082E045208
          7B049D08B104DC04E205A904C7058E046F05B304BB04D804A70434055E056405
          88056A05E704A305B1041506D704E7057104E705710407000000FC020000AE4D
          4D000000040000002D01020004000000F00101001200000024030700DE03C003
          B004AC03A504D8030405B3031B052503DE03C003DE03C00307000000FC020000
          000000000000040000002D01010004000000F001020048000000240322001100
          CB0000001101B8006D01CF00C301D4000E02BD006502F7001A021401C3010E01
          8401CD037C02B7072D01D4078401D407E6018F073C024606C4023506EA02B207
          5902FD0725021F08CF0114085B01E0071C01AC07050122074401E4030802BF00
          0F01B6033102B6034E022200FF003F00E2003A042A002D0686001E040D001100
          CB001100CB002200000024030F00E000F7011A003E0207008602D7038104E504
          FA030A059F03DE0314043701DC02BC032A04CB035B04430086023B005C02DD00
          1C02E000F701E000F7012E00000024031500EA007A02C703CE031B0542031B05
          2503170489033C043603BF040103310411032904B602F9035102D70368020004
          B602AA0242020004EB020A041E03EF035D03DC018D02EC037E03C703B003EA00
          7A02EA007A024200000024031F006904AB027F0558025807AB01110651024906
          95024906E7021C067203E0050904DD055B041506D704C2057604B7050C04F705
          5C032806DC02DD0555020E05A4022105CD02300536031D05AE03FF042304F404
          9B04160510056405880512055705DA04D704CE044904F804900307052003CE04
          B3026904AB026904AB0216000000240309006405880552050C0583059F04B005
          A3041506D7049D05CC047305100564058805640588052A000000240313002406
          3A037D079C02CE07930208085C023D08D90126082401D107DA003B070B01B707
          B7000808D2004C081D015E08B30157081C021108A102E307BD029007BA02F705
          940324063A0324063A036200000024032F0015010D03F7005003FB00E7032401
          3D0468015404DC01B504F9027905390384058B03B105A603E6057F045706DA04
          62069609E6048B09940448082E047409B204CB0429067F04E6055A0484057804
          C40443042205380484055A04000678042906C803D305A60380059E030405B503
          AE048B03EE047C03480575037D05350353052A03E6044C03670423039F040503
          F50405034F05730139046F01E7037301A3035101D0033E0118041501CC031501
          5F035C01320315010D0315010D031C00000024030C00E1047D04B4049F049E04
          DB047F046A059E04B1054A05790521054F05B4046E05B804F904E904D004E104
          7D04E1047D040E0000002403050068054005A006FD0461056A05680540056805
          40053400000024031800100182036B009B037000D70375020C07DA0770061A08
          8E063E08C806120843072D076E071C086E077F08D70679085C064E0823065E07
          430632075606FE064306C002C3066F01EA049B02C7068002EF068000B1030301
          9B0310018203100182032000000024030E00D1006304D900A304CE00D904BB00
          FD04A10010050201C8051402C7074A01FC05CE00100546019E05E800E3040201
          9F04D1006304D10063043E00000024031D00DE00AF048200D9043900E9043100
          1A055E015007DF019108E306F3071307E3075707FA074008DB07A8087B07DD08
          8E06B808E40515085505D606A505F407AB056F080906A6085B06AA08D5067C08
          67074108A9078507C2073107A707BF06E007030249085500F804E800CB04DE00
          AF04DE00AF042000000024030E002002E1077A028E07A30243079802E9064E05
          9606E3020007C8024B07DA042D07BD027C079F029A078102AC07820674072002
          E1072002E1071800000024030A00E802580522026205B802390624041D06FC03
          0206D3020C068402880516036505E8025805E802580514000000240308009305
          1906DF0510067706FD050D07E9055007E0050206EC0593051906930519061E00
          000024030D006407CE009A06AC0075068F003E068C0090025D01C103BE01DF06
          F400B503910162035B014406A9007806B7006407CE006407CE0007000000FC02
          0000F7A856000000040000002D01020004000000F00101001000000024030600
          24060404DC065103E5070103A4085103240604042406040407000000FC020000
          000000000000040000002D01010004000000F00102002E000000240315006707
          C502470945035E0990037508DF0357081B0466085F0488089004CB08B504EB04
          E0057C08AA04400885041C07C40431085B0435080504E4058804D50549044309
          5E038407F3022C0664036707C5026707C502120000002403070096078A05DA07
          DC051107EA058307C6056807930596078A0596078A05030000000000}
        Stretch = True
      end
      object Label5: TLabel
        Left = 184
        Top = 24
        Width = 153
        Height = 33
        Alignment = taCenter
        AutoSize = False
        Caption = '������� ��� ������ � ���������� �����:'
        WordWrap = True
      end
      object Button1: TButton
        Left = 185
        Top = 65
        Width = 150
        Height = 25
        Action = actLoadDataFromFile
        TabOrder = 0
      end
      object Button2: TButton
        Left = 185
        Top = 89
        Width = 150
        Height = 25
        Action = actSaveDataToFile
        TabOrder = 1
      end
      object Button3: TButton
        Left = 185
        Top = 113
        Width = 150
        Height = 25
        Action = actViewFile
        TabOrder = 2
      end
    end
  end
  inherited alBase: TActionList
    Left = 326
    Top = 65535
    object actLoadDataFromFile: TAction
      Caption = '��������� � �����'
      Hint = '��������� ������ �� �����'
      OnExecute = actLoadDataFromFileExecute
    end
    object actSaveDataToFile: TAction
      Caption = '��������� �� ����'
      Hint = '���������� ����� �� ����'
      OnExecute = actSaveDataToFileExecute
      OnUpdate = actSaveDataToFileUpdate
    end
    object actViewFile: TAction
      Caption = '�������� �����'
      Hint = '�������� ����������� �����'
      OnExecute = actViewFileExecute
      OnUpdate = actViewFileUpdate
    end
  end
  inherited dsgdcBase: TDataSource
    Left = 288
  end
  inherited pm_dlgG: TPopupMenu
    Left = 256
    Top = 8
  end
  inherited ibtrCommon: TIBTransaction
    Left = 176
    Top = 0
  end
  object OpenDialog: TOpenDialog
    Filter = '��� �����|*.*'
    Left = 224
  end
  object SaveDialog: TSaveDialog
    Filter = '��� �����|*.*'
    Options = [ofOverwritePrompt, ofHideReadOnly, ofPathMustExist, ofEnableSizing]
    Left = 200
    Top = 8
  end
end