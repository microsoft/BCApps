codeunit 144016 "Library CODA Data Provider"
{

    trigger OnRun()
    begin
    end;

    var
        LibraryRandom: Codeunit "Library - Random";
        Assert: Codeunit Assert;

    [Normal]
    [Scope('OnPrem')]
    procedure ImportMultipleStatementsToCODAstatementDataFiles(FileNo: Integer) fileName: Text
    var
        tempFile: File;
    begin
        tempFile.CreateTempFile(TEXTENCODING::Windows);
        fileName := tempFile.Name;
        tempFile.Close();
        tempFile.TextMode := true;
        tempFile.Create(fileName, TEXTENCODING::Windows);
        if FileNo = 1 then
            // CODA file 07022000.008
            Write7022000008(tempFile)
        else begin
            // CODA file 07022600.005
            Write7022600005A(tempFile);
            Write7022600005B(tempFile);
            Write7022600005C(tempFile);
            Write7022600005D(tempFile);
        end;
        tempFile.Close();
    end;

    [Normal]
    [Scope('OnPrem')]
    procedure ImportAccountTypeTestDataFile() FileName: Text
    var
        tempFile: File;
    begin
        // AL Mapping of the TFS data file 'Fortis 210409.txt
        tempFile.CreateTempFile(TEXTENCODING::Windows);
        FileName := tempFile.Name;
        tempFile.Close();
        tempFile.TextMode := true;
        tempFile.Create(FileName, TEXTENCODING::Windows);

        WriteFortis210409(tempFile);

        tempFile.Close();
    end;

    [Normal]
    [Scope('OnPrem')]
    procedure PrintOneOfMultipleCODAStatementsDataFile() FileName: Text
    var
        tempFile: File;
    begin
        // Implementation of the CODA file CODA1_Multiple.txt
        tempFile.CreateTempFile(TEXTENCODING::Windows);
        FileName := tempFile.Name;
        tempFile.Close();
        tempFile.TextMode := true;
        tempFile.Create(FileName, TEXTENCODING::Windows);
        WriteCODA1MultipleA(tempFile);
        WriteCODA1MultipleB(tempFile);
        WriteCODA1MultipleC(tempFile);
        WriteCODA1MultipleD(tempFile);
        tempFile.Close();
    end;

    [Normal]
    [Scope('OnPrem')]
    procedure OntVangenCODA20090416DataFile() FileName: Text
    var
        tempFile: File;
    begin
        // Implementation of the CODA file Ontvangen CODA.2009-04-16_Original.txt
        tempFile.CreateTempFile(TEXTENCODING::Windows);
        FileName := tempFile.Name;
        tempFile.Close();
        tempFile.TextMode := true;
        tempFile.Create(FileName, TEXTENCODING::Windows);
        WriteOntVangenCODA20090416(tempFile);
        tempFile.Close();
    end;

    [Scope('OnPrem')]
    procedure OntVangenCODAScenario373926DataFile() FileName: Text
    var
        tempFile: File;
    begin
        tempFile.CreateTempFile(TEXTENCODING::Windows);
        FileName := tempFile.Name;
        tempFile.Close();
        tempFile.TextMode := true;
        tempFile.Create(FileName, TEXTENCODING::Windows);
        WriteOntVangenCODAScenario373926(tempFile);
        tempFile.Close();
    end;

    [Normal]
    [Scope('OnPrem')]
    procedure OnCODAScenario557240DataFile() FileName: Text
    var
        tempFile: File;
    begin
        tempFile.CreateTempFile(TextEncoding::Windows);
        FileName := tempFile.Name;
        tempFile.Close();
        tempFile.TextMode := true;
        tempFile.Create(FileName, TextEncoding::Windows);
        WriteOnCODAScenario557240(tempFile);
        tempFile.Close();
    end;

    [Normal]
    [Scope('OnPrem')]
    procedure OnCODAScenario560840DataFile() FileName: Text
    var
        tempFile: File;
    begin
        tempFile.CreateTempFile(TextEncoding::Windows);
        FileName := tempFile.Name;
        tempFile.Close();
        tempFile.TextMode := true;
        tempFile.Create(FileName, TextEncoding::Windows);
        WriteOnCODAScenario560840(tempFile);
        tempFile.Close();
    end;

    [Scope('OnPrem')]
    procedure InsertSampleCODAStatement(var CODAStatement: Record "CODA Statement"; BankAccountNo: Code[20])
    begin
        CODAStatement.Init();
        CODAStatement."Bank Account No." := BankAccountNo;
        CODAStatement."Statement No." := Format(LibraryRandom.RandInt(210));
        CODAStatement."Statement Ending Balance" := LibraryRandom.RandDecInRange(100000, 200000, 1);
        CODAStatement."Statement Date" := WorkDate();
        CODAStatement."Balance Last Statement" := LibraryRandom.RandDecInRange(10000, 100000, 1);
        CODAStatement."CODA Statement No." := 0;
        CODAStatement.Insert();

        InsertSampleCODAStatementLines(CODAStatement."Statement No.", CODAStatement."Bank Account No.");
    end;

    [Scope('OnPrem')]
    procedure InsertSampleCODAStatementLines(CODAStatementNo: Code[20]; BankAccountNo: Code[20])
    begin
        InsertSampleCODAStatementLine1(CODAStatementNo, BankAccountNo);
        InsertSampleCODAStatementLine2(CODAStatementNo, BankAccountNo);
        InsertSampleCODAStatementLine3(CODAStatementNo, BankAccountNo);
        InsertSampleCODAStatementLine4(CODAStatementNo, BankAccountNo);
        InsertSampleCODAStatementLine5(CODAStatementNo, BankAccountNo);
        InsertSampleCODAStatementLine6(CODAStatementNo, BankAccountNo);
        InsertSampleCODAStatementLine7(CODAStatementNo, BankAccountNo);
        InsertSampleCODAStatementLine8(CODAStatementNo, BankAccountNo);
        InsertSampleCODAStatementLine9(CODAStatementNo, BankAccountNo);
        InsertSampleCODAStatementLine10(CODAStatementNo, BankAccountNo);
        InsertSampleCODAStatementLine11(CODAStatementNo, BankAccountNo);
        InsertSampleCODAStatementLine12(CODAStatementNo, BankAccountNo);
        InsertSampleCODAStatementLine13(CODAStatementNo, BankAccountNo);
        InsertSampleCODAStatementLine14(CODAStatementNo, BankAccountNo);
        InsertSampleCODAStatementLine15(CODAStatementNo, BankAccountNo);
    end;

    [Scope('OnPrem')]
    procedure ValidateSampleCODAStatement(CODAStatement: Record "CODA Statement")
    begin
        ValidateSampleCODAStatementLine(CODAStatement."Statement No.", 10000);
        ValidateSampleCODAStatementLine(CODAStatement."Statement No.", 30000);
        ValidateSampleCODAStatementLine(CODAStatement."Statement No.", 40000);
        ValidateSampleCODAStatementLine(CODAStatement."Statement No.", 60000);
        ValidateSampleCODAStatementLine(CODAStatement."Statement No.", 70000);
        ValidateSampleCODAStatementLine(CODAStatement."Statement No.", 80000);
        ValidateSampleCODAStatementLine(CODAStatement."Statement No.", 120000);
        ValidateSampleCODAStatementLine(CODAStatement."Statement No.", 130000);
    end;

    local procedure WriteFortis210409(var tempFile: File)
    begin
        tempFile.Write(
          '0000021040920005                  DISTRAC NV                GEBABEBB   00448825928 00000                                       2'
          );
        tempFile.Write('10084230002155541 EUR0BE                  0000000746171930200409' +
          'DISTRAC NV                                                   001');
        tempFile.Write('21000100000000900000404        0000000002689840210409001500000  ' +
          '                                                   21040908401 0');
        tempFile.Write('2300010000210005816416 EUR                     NV F.C.F.        ' +
          '                                                             0 1');
        tempFile.Write('31000100010000900000404        001500001001NV F.C.F.            ' +
          '                                                             1 0');
        tempFile.Write('3200010001STEENWEG OP TIELEN 51              2300 TURNHOUT      ' +
          '                                                             0 0');
        tempFile.Write('21000200000000900000405        100000000005970021040900402000111' +
          '304114376967100031      00476521040916009TOTAL 553121040908401 0');
        tempFile.Write('2200020000      FLEURUS   000000000000000000000000000EUR0611713 ' +
          '                                                             1 0');
        tempFile.Write('2300020000                                     TOTAL 5531      F' +
          'LEURUS            00976                                      0 1');
        tempFile.Write('31000200010000900000405        004020001001TOTAL 5531      FLEUR' +
          'US                                                           1 0');
        tempFile.Write('3200020001                                   0000               ' +
          '                                                             0 0');
        tempFile.Write('8084230002155541 EUR0BE                  0000000748802070210409 ' +
          '                                                               0');
        tempFile.Write('9               000011000000000059700000000002689840            ' +
          '                                                               1');
    end;

    local procedure Write7022000008(var tempFile: File)
    begin
        // CODA file 07022000.008
        tempFile.Write('0000019020772505   0000000074789  THIELEMANS ROBBIE         0000' +
          '000000000430018420 00000                                       1');
        tempFile.Write('1 032737010689443 EUR0BE                  0000000236074080140207' +
          'INVERTO NV                KBC-Bedrijfsrekening               001');
        tempFile.Write('2100010000BJUA00109 TBOINDNLOON1000000001352480190207001010000ON' +
          'KOSTEN BELCOMP EN VDVIJVER                         1902070320100');
        tempFile.Write('2200010000                                                     D' +
          'IV ONKO                     000000000000000                  100');
        tempFile.Write('2300010000467538877123                         FIBECON BVBA     ' +
          '         MEERSBLOEM MELDEN 30      9700 OUDENAARDE           000');
        tempFile.Write('8032737010689443 EUR0BE                  0000000234721600190207 ' +
          '                                                                ');
        tempFile.Write('9               000005000000001352480000000000000000            ' +
          '                                                               2');
    end;

    local procedure Write7022600005A(var tempFile: File)
    begin
        tempFile.Write('0000002010772505D  0000000074789  INVERTO NV                0000' +
          '000000000430018420 00000                                       1');
        tempFile.Write('1 001737010689443 EUR0BE                  0000000291493520291206' +
          'INVERTO NV                KBC-Bedrijfsrekening               001');
        tempFile.Write('2100010000HIRQA1H6L BKTKOSKOKFG1000000000020000010107303370000Aa' +
          'nrekening kaartbijdrage   5526 1454 7849 0607      0201070011000');
        tempFile.Write('2100010001HIRQA1H6L BKTKOSKOKFG1000000000020000010107803370060  ' +
          '                                                   0201070011000');
        tempFile.Write('2100020000HIWC00001 CKZKOSKOSBK1000000000018700020107013370000  ' +
          '  COMMERCIELE KREDIETZAAK MET REFERTE      727-64440201070010100');
        tempFile.Write('2200020000961-49                                                ' +
          '                            000000000000000                  000');
        tempFile.Write('2100030000OL9426419JBBOEUBCRECL000000000799200003010734150000000' +
          '352037002A3545                                     0201070011100');
        tempFile.Write('2200030000                                                     4' +
          '550-63629896326             000000000000000                  001');
        tempFile.Write('3100030001OL9426419JBBOEUBCRECL341500001001ROSTI POLSKA SP. Z.O.' +
          'O.            Elewatorska 29                                 1 0');
        tempFile.Write('320003000115-620  Bia ystok                                     ' +
          '                                                             0 1');
        tempFile.Write('3100030002OL9426419JBBOEUBCRECL341500001002INVOIC               ' +
          '                                                             0 0');
        tempFile.Write('2100030003OL9426419JBBOEUBCRECL000000000799200003010784150100110' +
          '5000000007992000000000007992000000100000000EUR     0201070011100');
        tempFile.Write('2200030003         000000007992000                              ' +
          '                            000000000000000                  000');
        tempFile.Write('2100040000HNOA00002BTBOGOVOVERS000000000151250002010700150000062' +
          '91                                                 0201070010100');
        tempFile.Write('2300040000472302320181                         TEAM LASERPRESS N' +
          'V        JACQUES PARYSLAAN 8       9940 EVERGEM              000');
        tempFile.Write('2100050000HOUP00283BTBOINDNLOON0000000001024930020107001500000FT' +
          ' 6314                                              0201070010100');
        tempFile.Write('2300050000738010356689                         EVILO NV         ' +
          '         SCHELDESTRAAT 35 A        8553 OTEGEM               000');
        tempFile.Write('2100060000OL9447899JBBNEUBCRCL1000000003378098003010734150000000' +
          '352037002C0877                                     0201070011001');
        tempFile.Write('3100060001OL9447899JBBNEUBCRCL1341500001001SPLASHPOWER LTD      ' +
          '              3110001                                        1 0');
        tempFile.Write('320006000129                                                    ' +
          '                                                             0 1');
        tempFile.Write('3100060002OL9447899JBBNEUBCRCL1341500001002INV 6320             ' +
          '                                                             0 0');
        tempFile.Write('2100060003OL9447899JBBNEUBCRCL1000000003378098003010784150100110' +
          '5000000033780980000000033780980000100000000EUR     0201070011100');
        tempFile.Write('2200060003         000000033780980                              ' +
          '                            000000000000000                  000');
        tempFile.Write('8001737010689443 EUR0BE                  0000000335765230020107 ' +
          '                                                                ');
        tempFile.Write('9               000023000000000038700000000044310410            ' +
          '                                                               1');
        tempFile.Write('0000003010772505D  0000000074789  INVERTO NV                0000' +
          '000000000430018420 00000                                       1');
        tempFile.Write('1 002737010689443 EUR0BE                  0000000335765230020107' +
          'INVERTO NV                KBC-Bedrijfsrekening               001');
        tempFile.Write('2100010000OL9460983JBBOEUBCRECL000000002220652004010734150000000' +
          '352037003A7683                                     0301070021100');
        tempFile.Write('2200010000                                                     T' +
          '47A70102AU78                000000000000000                  001');
        tempFile.Write('3100010001OL9460983JBBOEUBCRECL341500001001STECA BATTERIELADESYS' +
          'TEME UND      PRAEZISIONSELEKTRONIK GMBH                     1 0');
        tempFile.Write('3200010001MAMMOSTRASSE 1                     87700 MEMMINGEN    ' +
          '                                                             0 1');
        tempFile.Write('3100010002OL9460983JBBOEUBCRECL341500001002INV. 6318 / 30.11.200' +
          '6             INV. 6315 / 24.11.2006                         1 0');
        tempFile.Write('3200010002./. BELASTUNG 17004039 / 19.12.2006                   ' +
          '                                                             0 0');
        tempFile.Write('2100010003OL9460983JBBOEUBCRECL000000002220652004010784150100110' +
          '5000000022206520000000022206520000100000000EUR     0301070021100');
        tempFile.Write('2200010003         000000022206520                              ' +
          '                            000000000000000                  000');
        tempFile.Write('8002737010689443 EUR0BE                  0000000357971750030107 ' +
          '                                                                ');
        tempFile.Write('9               000010000000000000000000000022206520            ' +
          '                                                               1');
        tempFile.Write('0000005010772505D  0000000074789  INVERTO NV                0000' +
          '000000000430018420 00000                                       1');
        tempFile.Write('1 003737010689443 EUR0BE                  0000000357971750040107' +
          'INVERTO NV                KBC-Bedrijfsrekening               001');
        tempFile.Write('2100010000JCRL02237 TBOINDNLOON1000000013310000050107001010000FA' +
          'CT ST06012                                         0501070030100');
        tempFile.Write('2200010000                                                     6' +
          '/1900                       000000000000000                  100');
        tempFile.Write('2300010000737016385868                         STEREYO          ' +
          '         ZONNESTR 7                9810 NAZARETH             000');
        tempFile.Write('8003737010689443 EUR0BE                  0000000344661750050107 ' +
          '                                                                ');
        tempFile.Write('9               000005000000013310000000000000000000            ' +
          '                                                               1');
        tempFile.Write('0000008010772505D  0000000074789  INVERTO NV                0000' +
          '000000000430018420 00000                                       1');
        tempFile.Write('1 004737010689443 EUR0BE                  0000000344661750050107' +
          'INVERTO NV                KBC-Bedrijfsrekening               001');
        tempFile.Write('2100010000JQQJA0CUQ IKLINNINNIG1000000003670020060107313410000  ' +
          '            INVESTERINGSKREDIET     726-3754303-95 0801070041000');
        tempFile.Write('2100010001JQQJA0CUQ IKLINNINNIG1000000003333330060107813410660  ' +
          '                                                   0801070040000');
        tempFile.Write('2100010002JQQJA0CUQ IKLINNINNIG1000000000336690060107813410020  ' +
          '                                                   0801070041000');
        tempFile.Write('2100020000OL9441847JBBNEUNCRCL1000000005292465008010734150000000' +
          '352037008A2593                                     0801070041001');
        tempFile.Write('3100020001OL9441847JBBNEUNCRCL1341500001001PHILIPS LIGHTING BV  ' +
          '              P.O. BOX 1                                     1 0');
        tempFile.Write('3200020001BUILDING AA                        OSS                ' +
          '                                                             0 1');
        tempFile.Write('3100020002OL9441847JBBNEUNCRCL13415000010026710280720000130 6306' +
          ' 6309 6311                                                   0 0');
        tempFile.Write('2100020003OL9441847JBBNEUNCRCL1000000005292465008010784150100110' +
          '5000000052924650000000052924650000100000000EUR     0801070041100');
        tempFile.Write('2200020003         000000052924650                              ' +
          '                            000000000000000                  000');
        tempFile.Write('2100030000OL9441848KBBNKOSDIVKS100000000001089008010734137000000' +
          '352037008A2593                                     0801070041000');
        tempFile.Write('2100030001OL9441848KBBNKOSDIVKS1000000000009000080107841370130  ' +
          '                                                   0801070040000');
        tempFile.Write('2100030002OL9441848KBBNKOSDIVKS100000000000189008010784137011110' +
          '6000000000001890000000000009000002100000000200000000801070041100');
        tempFile.Write('220003000200001890                                              ' +
          '                            000000000000000                  000');
        tempFile.Write('2100040000KBIS00253 TBOINDNLOON100000000304899008010700101000110' +
          '1006000522050                                      0801070040100');
        tempFile.Write('2200040000                                                     6' +
          '1823                        000000000000000                  100');
        tempFile.Write('2300040000828998553034                         HERBERIGS SPRL   ' +
          '         WIJNGAARDSTRAAT 5         9700 OUDENAARDE           000');
        tempFile.Write('2100050000KBIS00254 TBOINDNLOON100000000001479008010700101000110' +
          '1006000523969                                      0801070040100');
        tempFile.Write('2200050000                                                     6' +
          '1867                        000000000000000                  100');
        tempFile.Write('2300050000828998553034                         HERBERIGS SPRL   ' +
          '         WIJNGAARDSTRAAT 5         9700 OUDENAARDE           000');
        tempFile.Write('2100060000KBIS00255 TBOINDNLOON100000000360973008010700101000110' +
          '1007000047537                                      0801070040100');
        tempFile.Write('2200060000                                                     6' +
          '/1941                       000000000000000                  100');
        tempFile.Write('2300060000828998553034                         HERBERIGS SPRL   ' +
          '         WIJNGAARDSTRAAT 5         9700 OUDENAARDE           000');
        tempFile.Write('8004737010689443 EUR0BE                  0000000387231980080107 ' +
          '                                                                ');
        tempFile.Write('9               000024000000010354420000000052924650            ' +
          '                                                               1');
        tempFile.Write('0000009010772505D  0000000074789  INVERTO NV                0000' +
          '000000000430018420 00000                                       1');
        tempFile.Write('1 005737010689443 EUR0BE                  0000000387231980080107' +
          'INVERTO NV                KBC-Bedrijfsrekening               001');
        tempFile.Write('2100010000KFXWA0BSQ IKLINNINNIG1000000000991820090107313410000  ' +
          '            INVESTERINGSKREDIET     726-2764912-07 0901070051000');
        tempFile.Write('2100010001KFXWA0BSQ IKLINNINNIG1000000000947310090107813410660  ' +
          '                                                   0901070050000');
        tempFile.Write('2100010002KFXWA0BSQ IKLINNINNIG1000000000044510090107813410020  ' +
          '                                                   0901070051000');
        tempFile.Write('2100020000KGNAA0ANJ DOMALGDOV01100000000070164009010700501000110' +
          '774071599264509010774422-LF-0  2532992   413664   00901070050100');
        tempFile.Write('22000200000426403684                                            ' +
          '                            000000000000000                  100');
        tempFile.Write('2300020000000000000000                         KBC LEASE BELGIUM' +
          '                                                             000');
        tempFile.Write('2100030000KHMC01793 TBOINDNLOON1000000000553560090107001010000IN' +
          'V 7006237 RI KLNR 92164                            0901070050100');
        tempFile.Write('2200030000                                                     6' +
          '1695                        000000000000000                  100');
        tempFile.Write('2300030000437751551186                         ACAL             ' +
          '         LOZENBERG 4               1932 ZAVENTEM             000');
        tempFile.Write('2100040000KHMC01794 TBOINDNLOON1000000000209570090107001010000FA' +
          'CT2070004583                                       0901070050100');
        tempFile.Write('2200040000                                                     6' +
          '1744                        000000000000000                  100');
        tempFile.Write('2300040000390041400059                         AIR COMPACT BELGI' +
          'UM NV    BRUSSelseSTWG 427         9050 LEDEBERG (GENT       000');
        tempFile.Write('2100050000KHMC01795 TBOINDNLOON100000000011173009010700101000009' +
          '0059 2000 06006310                                 0901070050100');
        tempFile.Write('2200050000                                                     6' +
          '/1575                       000000000000000                  100');
        tempFile.Write('2300050000293018003760                         ATEM             ' +
          '         BEDRIJVENPARK DE VEERT 4  2830 WILLEBROEK           000');
        tempFile.Write('2100060000KHMC01796 TBOINDNLOON100000000010682009010700101000009' +
          '0059 2000 06006658                                 0901070050100');
        tempFile.Write('2200060000                                                     6' +
          '/1615                       000000000000000                  100');
        tempFile.Write('2300060000293018003760                         ATEM             ' +
          '         BEDRIJVENPARK DE VEERT 4  2830 WILLEBROEK           000');
        tempFile.Write('2100070000KHMC01797 TBOINDNLOON100000000015277009010700101000110' +
          '1200601108664                                      0901070050100');
        tempFile.Write('2200070000                                                     6' +
          '1668                        000000000000000                  100');
        tempFile.Write('2300070000220057681084                         AUTOBAR BELGIUM S' +
          'A        BOOMSESTEENWEG 73         2630 AARTSELAAR           000');
        tempFile.Write('2100080000KHMC01798 TBOINDNLOON100000000032818009010700101000110' +
          '1200601236986                                      0901070050100');
        tempFile.Write('2200080000                                                     6' +
          '1798                        000000000000000                  100');
        tempFile.Write('2300080000220057681084                         AUTOBAR BELGIUM S' +
          'A        BOOMSESTEENWEG 73         2630 AARTSELAAR           000');
        tempFile.Write('2100090000KHMC01799 TBOINDNLOON100000000008494009010700101000110' +
          '1200641227460                                      0901070050100');
        tempFile.Write('2200090000                                                     6' +
          '1804                        000000000000000                  100');
        tempFile.Write('2300090000220057681084                         AUTOBAR BELGIUM S' +
          'A        BOOMSESTEENWEG 73         2630 AARTSELAAR           000');
        tempFile.Write('2100100000KHMC01800 TBOINDNLOON100000000017015009010700101000110' +
          '1200601285284                                      0901070050100');
        tempFile.Write('2200100000                                                     6' +
          '1813                        000000000000000                  100');
        tempFile.Write('2300100000220057681084                         AUTOBAR BELGIUM S' +
          'A        BOOMSESTEENWEG 73         2630 AARTSELAAR           000');
        tempFile.Write('2100110000KHMC01801 TBOINDNLOON1000000000512740090107001010000FA' +
          'CT 28016149 S01 028                                0901070050100');
        tempFile.Write('2200110000                                                     6' +
          '1592                        000000000000000                  100');
        tempFile.Write('2300110000285020504213                         BARCO KUURNE     ' +
          '         NOORDLAAN 5               8520 KUURNE               000');
        tempFile.Write('2100120000KHMC01802 TBOINDNLOON1000000000902630090107001010000FT' +
          '111602572 602741 602867 602892 602981 603069 6030720901070050100');
        tempFile.Write('2200120000                                                     6' +
          '1607829                     000000000000000                  100');
        tempFile.Write('2300120000447964515175                         BUYSSE WILLEMS GA' +
          'RAGE     JACQUES PARIJSLAAN 8      9940 EVERGEM              000');
        tempFile.Write('2100130000KHMC01803 TBOINDNLOON100000000076807009010700101000110' +
          '1009005562044                                      0901070050100');
        tempFile.Write('2200130000                                                     6' +
          '1671                        000000000000000                  100');
        tempFile.Write('2300130000220043968823                         CARE             ' +
          '         LUCHTHAVENLEI 7B BUS 2    2100 DEURNE (ANTW.)       000');
        tempFile.Write('2100140000KHMC01804 TBOINDNLOON100000000076807009010700101000110' +
          '1009005671875                                      0901070050100');
        tempFile.Write('2200140000                                                     6' +
          '1874                        000000000000000                  100');
        tempFile.Write('2300140000220043968823                         CARE             ' +
          '         LUCHTHAVENLEI 7B BUS 2    2100 DEURNE (ANTW.)       000');
        tempFile.Write('2100150000KHMC01805 TBOINDNLOON1000000010619930090107001010000IN' +
          'V164091 164092 164170 164168 164169 164184         0901070050100');
        tempFile.Write('2200150000                                                     6' +
          '1704712                     000000000000000                  100');
        tempFile.Write('2300150000443900193149                         CMAC             ' +
          '         IZ KL FRANKRIJK 28        9600 RONSE                000');
        tempFile.Write('2100160000KHMC01806 TBOINDNLOON1000000005455890090107001010000IN' +
          'V 06111601 111602 111603                           0901070050100');
        tempFile.Write('2200160000                                                     6' +
          '168789                      000000000000000                  100');
        tempFile.Write('2300160000063991768047                         CPE              ' +
          '         SCHEURBOEK 6A             9860 OOSTERZELE           000');
        tempFile.Write('2100170000KHMC01807 TBOINDNLOON1000000000135680090107001010000BR' +
          'U0905683                                           0901070050100');
        tempFile.Write('2200170000                                                     6' +
          '1779                        000000000000000                  100');
        tempFile.Write('2300170000482910700226                         DHL              ' +
          '         POSTBUS 31                1831 DIEGEM               000');
        tempFile.Write('2100180000KHMC01808 TBOINDNLOON1000000000732900090107001010000IN' +
          'V122810 KLANT822346                                0901070050100');
        tempFile.Write('2200180000                                                     6' +
          '1667                        000000000000000                  100');
        tempFile.Write('2300180000825601419034                         EBV              ' +
          '         EXCELSIORLN 68            1930 ZAVENTEM             000');
        tempFile.Write('2100190000KHMC01809 TBOINDNLOON1000000000961950090107001010000IN' +
          'V 712559 717757 720476                             0901070050100');
        tempFile.Write('2200190000                                                     6' +
          '1731885                     000000000000000                  100');
        tempFile.Write('2300190000419706600164                         ECOMAL           ' +
          '         BATTelseSTWG 455E         2800 MECHELEN             000');
        tempFile.Write('2100200000KHMC01810 TBOINDNLOON1000000002447810090107001010000FA' +
          'CT504658                                           0901070050100');
        tempFile.Write('2200200000                                                     6' +
          '1727                        000000000000000                  100');
        tempFile.Write('2300200000414002661169                         EUROPRINT        ' +
          '         ZANDVOORTSTRAAT 21        2800 MECHELEN             000');
        tempFile.Write('2100210000KHMC01811 TBOINDNLOON1000000000467990090107001010000IN' +
          'V96133105 TO96142988                               0901070050100');
        tempFile.Write('2200210000                                                     6' +
          '149991                      000000000000000                  100');
        tempFile.Write('2300210000733031146932                         FABORY           ' +
          '         ZWEDENSTRAAT 4            9940 EVERGEM              000');
        tempFile.Write('2100220000KHMC01812 TBOINDNLOON100000000007132009010700101000110' +
          '1162033288470                                      0901070050100');
        tempFile.Write('2200220000                                                     6' +
          '1854                        000000000000000                  100');
        tempFile.Write('2300220000437750115182                         FACQ             ' +
          '         GANGSTR 20                1050 BRUSSEL 5            000');
        tempFile.Write('2100230000KHMC01813 TBOINDNLOON1000000001408000090107001010000IN' +
          'V841175 853828                                     0901070050100');
        tempFile.Write('2200230000                                                     6' +
          '176449                      000000000000000                  100');
        tempFile.Write('2300230000720520635687                         FUTURE ELECTRONIC' +
          'S        BRANDSTR 15A              9160 LOKEREN              000');
        tempFile.Write('2100240000KHMC01814 TBOINDNLOON1000000001275340090107001010000IN' +
          'V108687                                            0901070050100');
        tempFile.Write('2200240000                                                     6' +
          '1683                        000000000000000                  100');
        tempFile.Write('2300240000410065152192                         GIVATEC          ' +
          '         INDUSTRIEWEG 5            3001 HEVERLEE             000');
        tempFile.Write('2100250000KHMC01815 TBOINDNLOON1000000000045190090107001010000FA' +
          'CT94886                                            0901070050100');
        tempFile.Write('2200250000                                                     6' +
          '1769                        000000000000000                  100');
        tempFile.Write('2300250000335043322468                         IMES OOST VLAANDE' +
          'REN      KORTE MAGERSTRAAT 3       9050 GENTBRUGGE           000');
        tempFile.Write('2100260000KHMC01816 TBOINDNLOON1000000001830000090107001010000IN' +
          'V191537                                            0901070050100');
        tempFile.Write('2200260000                                                     6' +
          '1526                        000000000000000                  100');
        tempFile.Write('2300260000340182596777                         LEM INSTRUMENTS  ' +
          '                                   1000 BRUSSEL 1            000');
        tempFile.Write('2100270000KHMC01817 TBOINDNLOON100000000017302009010700101000110' +
          '1206193754509                                      0901070050100');
        tempFile.Write('2200270000                                                     6' +
          '1776                        000000000000000                  100');
        tempFile.Write('2300270000340013762419                         LYRECO           ' +
          '         RUE DE CHENEE 53          4031 ANGLEUR              000');
        tempFile.Write('2100280000KHMC01818 TBOINDNLOON1000000000832470090107001010000IN' +
          'V4082537                                           0901070050100');
        tempFile.Write('2200280000                                                     6' +
          '1662                        000000000000000                  100');
        tempFile.Write('2300280000552270880026                         MISCO            ' +
          '         POSTBUS 156               1930 ZAVENTEM             000');
        tempFile.Write('2100290000KHMC01819 TBOINDNLOON1000000000457380090107001010000IN' +
          'V VG062501107                                      0901070050100');
        tempFile.Write('2200290000                                                     6' +
          '1654                        000000000000000                  100');
        tempFile.Write('2300290000414520300154                         NIJKERK ELECTRONI' +
          'CS       NOORDERLAAN 111           2030 ANTWERPEN 3          000');
        tempFile.Write('2100300000KHMC01820 TBOINDNLOON1000000000146170090107001010000IN' +
          'VOICE 60107183RI CUSTOMER 42103297                 0901070050100');
        tempFile.Write('2200300000                                                     6' +
          '1738                        000000000000000                  100');
        tempFile.Write('2300300000432401944101                         OMRON            ' +
          '         STATIONSSTRAAT 24         1702 GROOT-BIJGAARD       000');
        tempFile.Write('2100310000KHMC01821 TBOINDNLOON1000000000572330090107001010000IN' +
          'V23807                                             0901070050100');
        tempFile.Write('2200310000                                                     6' +
          '1835                        000000000000000                  100');
        tempFile.Write('2300310000320050648420                         PCB              ' +
          '         ELLERMANSTRAAT 74         2060 ANTWERPEN 6          000');
        tempFile.Write('2100320000KHMC01822 TBOINDNLOON1000000000223730090107001010000IN' +
          'V61331 60554                                       0901070050100');
        tempFile.Write('2200320000                                                     6' +
          '164882                      000000000000000                  100');
        tempFile.Write('2300320000437750008179                         PHOENIX CONTACT  ' +
          '         MINERVASTRAAT 10-12       1930 ZAVENTEM             000');
        tempFile.Write('2100330000KHMC01823 TBOINDNLOON100000000640961009010700101000110' +
          '1060680430143                                      0901070050100');
        tempFile.Write('2200330000                                                     6' +
          '1834                        000000000000000                  100');
        tempFile.Write('2300330000001446507648                         RANDSTAD PROF    ' +
          '         HEIZEL ESPLANADE          1020 BRUSSEL 2            000');
        tempFile.Write('2100340000KHMC01824 TBOINDNLOON1000000001053590090107001010000IN' +
          'V6299051                                           0901070050100');
        tempFile.Write('2200340000                                                     6' +
          '1773                        000000000000000                  100');
        tempFile.Write('2300340000437751190165                         REXEL            ' +
          '         RUE DE LA TECHNOLOGIE     1082 BRUSSEL              000');
        tempFile.Write('2100350000KHMC01825 TBOINDNLOON1000000000533320090107001010000IN' +
          'V553060 557754                                     0901070050100');
        tempFile.Write('2200350000                                                     6' +
          '169465                      000000000000000                  100');
        tempFile.Write('2300350000310161043025                         RS COMPONENTS    ' +
          '         BD PAEPSEMLAAN 22         1070 ANDERLECHT           000');
        tempFile.Write('2100360000KHMC01826 TBOINDNLOON1000000006014750090107001010000IN' +
          'V4495806 TO4555463                                 0901070050100');
        tempFile.Write('2200360000                                                     6' +
          '150491                      000000000000000                  100');
        tempFile.Write('2300360000825601531087                         RUTRONIK         ' +
          '         INDUSTRIESTRASSE 2        7522 ISPRINGEN            000');
        tempFile.Write('2100370000KHMC01827 TBOINDNLOON1000000002420000090107001010000IN' +
          'V50780                                             0901070050100');
        tempFile.Write('2200370000                                                     6' +
          '1801                        000000000000000                  100');
        tempFile.Write('2300370000430084575196                         SEHER            ' +
          '         ASSESTEENWEG 117 2        1740 TERNAT               000');
        tempFile.Write('2100380000KHMC01828 TBOINDNLOON1000000000470090090107001010000IN' +
          'V9166859                                           0901070050100');
        tempFile.Write('2200380000                                                     6' +
          '1642                        000000000000000                  100');
        tempFile.Write('2300380000310000321503                         SPOERLE          ' +
          '         MINERVASTRAAT 14B2        1930 ZAVENTEM             000');
        tempFile.Write('2100390000KHMC01829 TBOINDNLOON100000000048822009010700101000110' +
          '1630311096035                                      0901070050100');
        tempFile.Write('2200390000                                                     6' +
          '1752                        000000000000000                  100');
        tempFile.Write('2300390000407050860119                         STANDAARD BOEKHAN' +
          'DEL      INDUSTRIEPARK NOORD 28A   9100 ST-NIKLAAS           000');
        tempFile.Write('2100400000KHMC01830 TBOINDNLOON1000000001064250090107001010000IN' +
          'V10052583 10052504 10052509                        0901070050100');
        tempFile.Write('2200400000                                                     6' +
          '1780 82                     000000000000000                  100');
        tempFile.Write('2300400000472302320181                         TEAM             ' +
          '         JACQUES PARIJSLAAN 8      9940 EVERGEM              000');
        tempFile.Write('2100410000KHMC01831 TBOINDNLOON1000000000715970090107001010000DI' +
          'V INV                                              0901070050100');
        tempFile.Write('2200410000                                                     6' +
          '1899                        000000000000000                  100');
        tempFile.Write('2300410000210049670015                         TNT              ' +
          '                                                             000');
        tempFile.Write('2100420000KHMC01832 TBOINDNLOON1000000000380000090107001010000IN' +
          'V80274362                                          0901070050100');
        tempFile.Write('2200420000                                                     6' +
          '1736                        000000000000000                  100');
        tempFile.Write('2300420000720540560602                         TYCO EL          ' +
          '                                                             000');
        tempFile.Write('2100430000KHMC01833 TBOINDNLOON1000000000323740090107001010000IN' +
          'V611791 KLANT 4268                                 0901070050100');
        tempFile.Write('2200430000                                                     6' +
          '1777                        000000000000000                  100');
        tempFile.Write('2300430000068241941669                         VANSICHEN        ' +
          '         BREDEWEG 62               3723 KORTESSEM            000');
        tempFile.Write('2100440000KHMC01834 TBOINDNLOON1000000000527620090107001010000IN' +
          'V601717                                            0901070050100');
        tempFile.Write('2200440000                                                     6' +
          '1698                        000000000000000                  100');
        tempFile.Write('2300440000446064891124                         VANDEVYVER       ' +
          '         BENELUXLN 1               9060 ZELZATE              000');
        tempFile.Write('2100450000KHMC01835 TBOINDNLOON1000000000024200090107001010000FA' +
          'CT602844 8612                                      0901070050100');
        tempFile.Write('2200450000                                                     6' +
          '1665                        000000000000000                  100');
        tempFile.Write('2300450000645141021968                         VENTOMATIC       ' +
          '         CHRYSANTENSTRAAT 59B      9820 MERELBEKE            000');
        tempFile.Write('2100460000KHMC01836 TBOINDNLOON1000000004416500090107001010000IN' +
          'V606087                                            0901070050100');
        tempFile.Write('2200460000                                                     6' +
          '1845                        000000000000000                  100');
        tempFile.Write('2300460000443563835141                         VANSTEENBRUGGHE N' +
          'V        BERCHEMWEG 95             9700 OUDENAARDE           000');
        tempFile.Write('2100470000KHMC01837 TBOINDNLOON1000000001698840090107001010000IN' +
          'V223602                                            0901070050100');
        tempFile.Write('2200470000                                                     6' +
          '1750                        000000000000000                  100');
        tempFile.Write('2300470000891374071719                         WYNANT           ' +
          '         AALSTSTRAAT 28            9700 OUDENAARDE           000');
        tempFile.Write('2100480000OL9470740IUBOEUBTRFCS100000000059200008010734101000000' +
          '352037009A1848                                     0901070051100');
        tempFile.Write('2200480000                                                     6' +
          '1802                        000000000000000                  001');
        tempFile.Write('3100480001OL9470740IUBOEUBTRFCS341010001001AMECHA BV            ' +
          '              GRASBEEMD 15A                                  1 0');
        tempFile.Write('32004800015705 DE HELMOND NL                 NL                 ' +
          '                                                             0 1');
        tempFile.Write('3100480002OL9470740IUBOEUBTRFCS341010001002FACT06223            ' +
          '                                                             0 1');
        tempFile.Write('3100480003OL9470740IUBOEUBTRFCS341010001004INTERNATIONALE NEDERL' +
          'ANDEN BANK NV                                                0 0');
        tempFile.Write('2100480004OL9470740IUBOEUBTRFCS100000000059200008010784101100110' +
          '5000000000592000000000000592000000100000000EUR     0901070051100');
        tempFile.Write('2200480004         000000000592000                              ' +
          '                            000000000000000                  000');
        tempFile.Write('2100490000OL9470741IUBOEUBTRFCS100000000065000008010734101000000' +
          '352037009A1849                                     0901070051100');
        tempFile.Write('2200490000                                                     6' +
          '1864 65                     000000000000000                  001');
        tempFile.Write('3100490001OL9470741IUBOEUBTRFCS341010001001BALKHAUSEN           ' +
          '              RUDOLF DIESEL STR 17                           1 0');
        tempFile.Write('320049000128857 SYKE DE                      DE                 ' +
          '                                                             0 1');
        tempFile.Write('3100490002OL9470741IUBOEUBTRFCS341010001002INVOICE 0703023      ' +
          '              0703024                                        0 1');
        tempFile.Write('3100490003OL9470741IUBOEUBTRFCS341010001004DEUTSCHE BANK AG     ' +
          '                                                             0 0');
        tempFile.Write('2100490004OL9470741IUBOEUBTRFCS100000000065000008010784101100110' +
          '5000000000650000000000000650000000100000000EUR     0901070051100');
        tempFile.Write('2200490004         000000000650000                              ' +
          '                            000000000000000                  000');
        tempFile.Write('2100500000OL9470742IUBOEUBTRFCS100000000002690008010734101000000' +
          '352037009A1850                                     0901070051100');
        tempFile.Write('2200500000                                                     6' +
          '1841                        000000000000000                  001');
        tempFile.Write('3100500001OL9470742IUBOEUBTRFCS341010001001BERGQUIST-ITC        ' +
          '              HADERSLEBENER STR. 19A                         1 0');
        tempFile.Write('320050000125421 PINNEBERG DE                 DE                 ' +
          '                                                             0 1');
    end;

    local procedure Write7022600005B(var tempFile: File)
    begin
        tempFile.Write('3100500002OL9470742IUBOEUBTRFCS341010001002INV93750             ' +
          '                                                             0 1');
        tempFile.Write('3100500003OL9470742IUBOEUBTRFCS341010001004DEUTSCHE BANK AG     ' +
          '                                                             0 0');
        tempFile.Write('2100500004OL9470742IUBOEUBTRFCS100000000002690008010784101100110' +
          '5000000000026900000000000026900000100000000EUR     0901070051100');
        tempFile.Write('2200500004         000000000026900                              ' +
          '                            000000000000000                  000');
        tempFile.Write('2100510000OL9470743IUBOEUBTRFCS100000000033000008010734101000000' +
          '352037009A1851                                     0901070051100');
        tempFile.Write('2200510000                                                     6' +
          '1713                        000000000000000                  001');
        tempFile.Write('3100510001OL9470743IUBOEUBTRFCS341010001001KEMA QUALITY BV      ' +
          '              UTRECHTSESTEENWEG 310                          1 0');
        tempFile.Write('32005100016812AR ARNHEM NL                   NL                 ' +
          '                                                             0 1');
        tempFile.Write('3100510002OL9470743IUBOEUBTRFCS34101000100217268 2188747        ' +
          '                                                             0 1');
        tempFile.Write('3100510003OL9470743IUBOEUBTRFCS341010001004ABN AMRO BANK NV     ' +
          '                                                             0 0');
        tempFile.Write('2100510004OL9470743IUBOEUBTRFCS100000000033000008010784101100110' +
          '5000000000330000000000000330000000100000000EUR     0901070051100');
        tempFile.Write('2200510004         000000000330000                              ' +
          '                            000000000000000                  000');
        tempFile.Write('2100520000OL9470744IUBOEUBTRFCS100000000026095008010734101000000' +
          '352037009A1857                                     0901070051100');
        tempFile.Write('2200520000                                                     6' +
          '1739                        000000000000000                  001');
        tempFile.Write('3100520001OL9470744IUBOEUBTRFCS341010001001TTI INC              ' +
          '              GANGHOFERSTRASSE 34                            1 0');
        tempFile.Write('320052000182216 MAISACH-GERNLINDEN DE        DE                 ' +
          '                                                             0 1');
        tempFile.Write('3100520002OL9470744IUBOEUBTRFCS341010001002INV E00888030        ' +
          '                                                             0 1');
        tempFile.Write('3100520003OL9470744IUBOEUBTRFCS341010001004RABOBANK NEDERLAND   ' +
          '                                                             0 0');
        tempFile.Write('2100520004OL9470744IUBOEUBTRFCS100000000026095008010784101100110' +
          '5000000000260950000000000260950000100000000EUR     0901070051100');
        tempFile.Write('2200520004         000000000260950                              ' +
          '                            000000000000000                  000');
        tempFile.Write('2100530000OL9470745IUBOEUBTRFCS100000000272921008010734101000000' +
          '352037009A1858                                     0901070051100');
        tempFile.Write('2200530000                                                     6' +
          '1692 1719 1853              000000000000000                  001');
        tempFile.Write('3100530001OL9470745IUBOEUBTRFCS341010001001VERMEULEN PRINTSSERVI' +
          'CE            HELMONDSEWEG 7B                                1 0');
        tempFile.Write('32005300015735 RA AARLE-RIXTEL NL            NL                 ' +
          '                                                             0 1');
        tempFile.Write('3100530002OL9470745IUBOEUBTRFCS341010001002INV IO6 07298 07     ' +
          '              430                                            0 1');
        tempFile.Write('3100530003OL9470745IUBOEUBTRFCS341010001004RABOBANK NEDERLAND   ' +
          '                                                             0 0');
        tempFile.Write('2100530004OL9470745IUBOEUBTRFCS100000000272921008010784101100110' +
          '5000000002729210000000002729210000100000000EUR     0901070051100');
        tempFile.Write('2200530004         000000002729210                              ' +
          '                            000000000000000                  000');
        tempFile.Write('2100540000OL9470746IUBOEUBTRFCS100000000037500008010734101000000' +
          '352037009A1852                                     0901070051100');
        tempFile.Write('2200540000                                                     6' +
          '1728                        000000000000000                  001');
        tempFile.Write('3100540001OL9470746IUBOEUBTRFCS341010001001KONING EN HARTMAN BV ' +
          '              POSTBUS 416                                    1 0');
        tempFile.Write('32005400011000AK AMSTERDAM NL                NL                 ' +
          '                                                             0 1');
        tempFile.Write('3100540002OL9470746IUBOEUBTRFCS341010001002INV5100052503        ' +
          '                                                             0 1');
        tempFile.Write('3100540003OL9470746IUBOEUBTRFCS341010001004VAN LANSCHOT F BANKIE' +
          'RS NV                                                        0 0');
        tempFile.Write('2100540004OL9470746IUBOEUBTRFCS100000000037500008010784101100110' +
          '5000000000375000000000000375000000100000000EUR     0901070051100');
        tempFile.Write('2200540004         000000000375000                              ' +
          '                            000000000000000                  000');
        tempFile.Write('2100550000OL9470747IUBOEUBTRFCS100000000173224008010734101000000' +
          '352037009A1853                                     0901070051100');
        tempFile.Write('2200550000                                                     6' +
          '1882                        000000000000000                  001');
        tempFile.Write('3100550001OL9470747IUBOEUBTRFCS341010001001PHILIPS OVAR         ' +
          '              EN109/IC1 ZONA IND OVAR                        1 0');
        tempFile.Write('32005500013880728 OVAR PT                    PT                 ' +
          '                                                             0 1');
        tempFile.Write('3100550002OL9470747IUBOEUBTRFCS341010001002INV789179            ' +
          '                                                             0 1');
        tempFile.Write('3100550003OL9470747IUBOEUBTRFCS341010001004BANCO BILBAO VIZCAYA ' +
          'ARGENTARIA (PO                                               0 0');
        tempFile.Write('2100550004OL9470747IUBOEUBTRFCS100000000173224008010784101100110' +
          '5000000001732240000000001732240000100000000EUR     0901070051100');
        tempFile.Write('2200550004         000000001732240                              ' +
          '                            000000000000000                  000');
        tempFile.Write('2100560000OL9470749IUBOEUBTRFCS100000000362410008010734101000000' +
          '352037009A1854                                     0901070051100');
        tempFile.Write('2200560000                                                     6' +
          '169647                      000000000000000                  001');
        tempFile.Write('3100560001OL9470749IUBOEUBTRFCS341010001001PIHER                ' +
          '              AMBACHTSSTR 13B                                1 0');
        tempFile.Write('32005600013861 HR NIJKERK NL                 NL                 ' +
          '                                                             0 1');
        tempFile.Write('3100560002OL9470749IUBOEUBTRFCS341010001002INV110640 110692     ' +
          '                                                             0 1');
        tempFile.Write('3100560003OL9470749IUBOEUBTRFCS341010001004ABN AMRO BANK NV     ' +
          '                                                             0 0');
        tempFile.Write('2100560004OL9470749IUBOEUBTRFCS100000000362410008010784101100110' +
          '5000000003624100000000003624100000100000000EUR     0901070051100');
        tempFile.Write('2200560004         000000003624100                              ' +
          '                            000000000000000                  000');
        tempFile.Write('2100570000OL9470750IUBOEUBTRFCS100000000025001008010734101000000' +
          '352037009A1856                                     0901070051100');
        tempFile.Write('2200570000                                                     6' +
          '1814                        000000000000000                  001');
        tempFile.Write('3100570001OL9470750IUBOEUBTRFCS341010001001BV SNIJ-UNIE HIFI    ' +
          '              ZOUTKETEN 23                                   1 0');
        tempFile.Write('32005700011601EX ENKHUIZEN NL                NL                 ' +
          '                                                             0 1');
        tempFile.Write('3100570002OL9470750IUBOEUBTRFCS341010001002INV267116 KLANT2     ' +
          '              136                                            0 1');
        tempFile.Write('3100570003OL9470750IUBOEUBTRFCS341010001004INTERNATIONALE NEDERL' +
          'ANDEN BANK NV                                                0 0');
        tempFile.Write('2100570004OL9470750IUBOEUBTRFCS100000000025001008010784101100110' +
          '5000000000250010000000000250010000100000000EUR     0901070051100');
        tempFile.Write('2200570004         000000000250010                              ' +
          '                            000000000000000                  000');
        tempFile.Write('2100580000OL9470751IUBOEUNTRFCS100000001604164008010734101000000' +
          '352037009A1855                                     0901070051001');
        tempFile.Write('3100580001OL9470751IUBOEUNTRFCS341010001001PUNCH TECHNIX NV     ' +
          '              KROMMESPIERINGWEG 289B                         1 0');
        tempFile.Write('32005800012141BS VIJFHUIZEN NL               NL                 ' +
          '                                                             0 1');
        tempFile.Write('3100580002OL9470751IUBOEUNTRFCS341010001002INV204700680         ' +
          '              FACTUUR204700252 PUNCH TECHNIX NV              0 1');
        tempFile.Write('3100580003OL9470751IUBOEUNTRFCS341010001004BANQUE ARTESIA NEDERL' +
          'AND                                                          0 0');
        tempFile.Write('2100580004OL9470751IUBOEUNTRFCS100000001604164008010784101100110' +
          '5000000016041640000000016041640000100000000EUR     0901070051100');
        tempFile.Write('2200580004         000000016041640                              ' +
          '                            000000000000000                  000');
        tempFile.Write('2100590000OL9470752KUBOKOSDIVKS100000000001210008010734137000000' +
          '352037009A1855                                     0901070051000');
        tempFile.Write('2100590001OL9470752KUBOKOSDIVKS1000000000010000080107841370260  ' +
          '                                                   0901070050000');
        tempFile.Write('2100590002OL9470752KUBOKOSDIVKS100000000000210008010784137011110' +
          '6000000000002100000000000010000002100000000200000000901070051100');
        tempFile.Write('220059000200002100                                              ' +
          '                            000000000000000                  000');
        tempFile.Write('2100600000KJXV14365BOVSBBNONTVA000000000061147009010700150000062' +
          '90                                                 0901070050100');
        tempFile.Write('220060000010/062-260985                                         ' +
          '                            000000000000000                  100');
        tempFile.Write('2300600000260035911186                         GO TO SA         ' +
          '         CHEMIN DE HAMEAU 25       6120    HAM-SUR-HEURE     000');
        tempFile.Write('21006100007409A3A5G KGDTTNTERNG1000000008000000080107009010000  ' +
          '                                                   0901070050000');
        tempFile.Write('8005737010689443 EUR0BE                  0000000292458810090107 ' +
          '                                                                ');
        tempFile.Write('9               000238000000095384640000000000611470            ' +
          '                                                               1');
        tempFile.Write('0000010010772505D  0000000074789  INVERTO NV                0000' +
          '000000000430018420 00000                                       1');
        tempFile.Write('1 006737010689443 EUR0BE                  0000000292458810090107' +
          'INVERTO NV                KBC-Bedrijfsrekening               001');
        tempFile.Write('2100010000KTTEA0CTR DOMALGDOV01100000000105784010010700501000110' +
          '7740784372894100107I=0701599551 R=36291539        01001070060100');
        tempFile.Write('22000100000403063902                                            ' +
          '                            000000000000000                  100');
        tempFile.Write('2300010000000000000000                         NV TOTAL BELGIUM ' +
          'SA                                                           000');
        tempFile.Write('2100020000LEGLA0B5R DOMNINDIN01100000007880763010010700501000110' +
          '7740784719367110107      060534695                01001070060100');
        tempFile.Write('22000200000409823416                                            ' +
          '                            000000000000000                  100');
        tempFile.Write('2300020000000000000000                         HULP DER PATROONS' +
          ' DOMICIL.                                                    000');
        tempFile.Write('8006737010689443 EUR0BE                  0000000212593340100107 ' +
          '                                                                ');
        tempFile.Write('9               000008000000079865470000000000000000            ' +
          '                                                               1');
        tempFile.Write('0000011010772505D  0000000074789  INVERTO NV                0000' +
          '000000000430018420 00000                                       1');
        tempFile.Write('1 007737010689443 EUR0BE                  0000000212593340100107' +
          'INVERTO NV                KBC-Bedrijfsrekening               001');
        tempFile.Write('2100010000LJEHA0APR DOMALGDOV01100000000028146011010700501000110' +
          '774071599264511010773518-LF-0  2536630   413794   01101070070100');
        tempFile.Write('22000100000426403684                                            ' +
          '                            000000000000000                  100');
        tempFile.Write('2300010000000000000000                         KBC LEASE BELGIUM' +
          '                                                             000');
        tempFile.Write('2100020000LJEHA0APS DOMALGDOV01100000000028702011010700501000110' +
          '774071599264511010773520-LF-0  2536631   413794   01101070070100');
        tempFile.Write('22000200000426403684                                            ' +
          '                            000000000000000                  100');
        tempFile.Write('2300020000000000000000                         KBC LEASE BELGIUM' +
          '                                                             000');
        tempFile.Write('2100030000LJEHA0APT DOMALGDOV01100000000033999011010700501000110' +
          '774071599264511010773521-LF-0  2536632   413794   01101070070100');
        tempFile.Write('22000300000426403684                                            ' +
          '                            000000000000000                  100');
        tempFile.Write('2300030000000000000000                         KBC LEASE BELGIUM' +
          '                                                             000');
        tempFile.Write('8007737010689443 EUR0BE                  0000000211684870110107 ' +
          '                                                                ');
        tempFile.Write('9               000011000000000908470000000000000000            ' +
          '                                                               1');
        tempFile.Write('0000012010772505D  0000000074789  INVERTO NV                0000' +
          '000000000430018420 00000                                       1');
        tempFile.Write('1 008737010689443 EUR0BE                  0000000211684870110107' +
          'INVERTO NV                KBC-Bedrijfsrekening               001');
        tempFile.Write('2100010000OL9464620JBBNEUBCRCL1000000002898250012010734150000000' +
          '352037012A3186                                     1201070081001');
        tempFile.Write('3100010001OL9464620JBBNEUBCRCL1341500001001PHILIPS LIGHTING BV  ' +
          '              P.O. BOX 1                                     1 0');
        tempFile.Write('3200010001BUILDING AA                        OSS                ' +
          '                                                             0 1');
        tempFile.Write('3100010002OL9464620JBBNEUBCRCL13415000010026710280720000227 6324' +
          ' 6326                                                        0 0');
        tempFile.Write('2100010003OL9464620JBBNEUBCRCL1000000002898250012010784150100110' +
          '5000000028982500000000028982500000100000000EUR     1201070081100');
        tempFile.Write('2200010003         000000028982500                              ' +
          '                            000000000000000                  000');
        tempFile.Write('2100020000MGLC00104BTBOGOVOVERS0000000000112530120107001500000  ' +
          '          6303                                     1201070080100');
        tempFile.Write('2300020000443900062197                         SANTENS NV       ' +
          '         GALGESTRAAT 157           9700 OUDENAARDE           000');
        tempFile.Write('8008737010689443 EUR0BE                  0000000240779900120107 ' +
          '                                                                ');
        tempFile.Write('9               000010000000000000000000000029095030            ' +
          '                                                               1');
        tempFile.Write('0000015010772505D  0000000074789  INVERTO NV                0000' +
          '000000000430018420 00000                                       1');
        tempFile.Write('1 009737010689443 EUR0BE                  0000000240779900120107' +
          'INVERTO NV                KBC-Bedrijfsrekening               001');
        tempFile.Write('2100010000MLMPA0AMU DOMALGDOV01100000000028712015010700501000110' +
          '774071599264515010778359-LF-0  2540014   413946   01501070090100');
        tempFile.Write('22000100000426403684                                            ' +
          '                            000000000000000                  100');
        tempFile.Write('2300010000000000000000                         KBC LEASE BELGIUM' +
          '                                                             000');
        tempFile.Write('2100020000MUUB02943LKKTOVSOVKUG100000000347147015010700319000112' +
          '45526145478490607    1431                          1501070090100');
        tempFile.Write('2300020000666000000483                                          ' +
          '                                                             000');
        tempFile.Write('8009737010689443 EUR0BE                  0000000237021310150107 ' +
          '                                                                ');
        tempFile.Write('9               000007000000003758590000000000000000            ' +
          '                                                               1');
        tempFile.Write('0000016010772505D  0000000074789  INVERTO NV                0000' +
          '000000000430018420 00000                                       1');
        tempFile.Write('1 010737010689443 EUR0BE                  0000000237021310150107' +
          'INVERTO NV                KBC-Bedrijfsrekening               001');
        tempFile.Write('2100010000NAIAA0AA0 DOMNINDIN01100000000001084016010700501000110' +
          '7740784719367170107      070031236                01601070100100');
        tempFile.Write('22000100000409823416                                            ' +
          '                            000000000000000                  100');
        tempFile.Write('2300010000000000000000                         HULP DER PATROONS' +
          ' DOMICIL.                                                    000');
        tempFile.Write('2100020000NKGU00273 TBOINDNLOON1000000000020010160107001010000EX' +
          'P TANKEN                                           1601070100100');
        tempFile.Write('2200020000                                                     D' +
          'IV6117                      000000000000000                  100');
        tempFile.Write('2300020000001336470848                         VALLAEY MATTHIAS ' +
          '                                                             000');
        tempFile.Write('2100030000NKGU00274 TBOINDNLOON1000000000136250160107001010000EX' +
          'P DEC06                                            1601070100100');
        tempFile.Write('2200030000                                                     D' +
          'IV6118                      000000000000000                  100');
        tempFile.Write('2300030000737101218432                         VAN DE SYPE DAVID' +
          '         STATIONSSTR 124           9450 HAALTERT             000');
        tempFile.Write('2100040000NKGU00275 TBOINDNLOON1000000000092920160107001010000EX' +
          'P DEC06                                            1601070100100');
        tempFile.Write('2200040000                                                     D' +
          'IV6119                      000000000000000                  100');
        tempFile.Write('2300040000979382731184                         ROMEYNS DIRK     ' +
          '         WAFELSTRAAT 26            9630 ZWALM                000');
        tempFile.Write('2100050000NKGU00276 TBOINDNLOON1000000000093500160107001010000EX' +
          'P DEC06                                            1601070100100');
        tempFile.Write('2200050000                                                     D' +
          'IV6120                      000000000000000                  100');
        tempFile.Write('2300050000733163053996                         VERMEER PAUL     ' +
          '         TEN OTTER 80              2980 ZOERSEL              000');
        tempFile.Write('2100060000NKGU00277 TBOINDNLOON1000000000116800160107001010000EX' +
          'P JAN07                                            1601070100100');
        tempFile.Write('2200060000                                                     D' +
          'IV                          000000000000000                  100');
        tempFile.Write('2300060000737005116185                         ISABELLE VAN DER ' +
          'PLAETSEN VARENDRIESKOUTER 4        9031 DRONGEN              000');
        tempFile.Write('8010737010689443 EUR0BE                  0000000236550990160107 ' +
          '                                                                ');
        tempFile.Write('9               000020000000000470320000000000000000            ' +
          '                                                               1');
        tempFile.Write('0000017010772505D  0000000074789  INVERTO NV                0000' +
          '000000000430018420 00000                                       1');
        tempFile.Write('1 011737010689443 EUR0BE                  0000000236550990160107' +
          'INVERTO NV                KBC-Bedrijfsrekening               001');
        tempFile.Write('2100010000NOEOA0BUR DOMDCDDID01100000000002804017010700501000110' +
          '7740745036768180107F. 2007040813 DOMICIL.         01701070110100');
        tempFile.Write('22000100000455530509                                            ' +
          '                            000000000000000                  100');
        tempFile.Write('2300010000000000000000                         ISABEL           ' +
          '                                                             000');
        tempFile.Write('2100020000NRGD00175 TBOINDNLOON1000000004537500170107001010000FA' +
          'CT 27019                                           1701070110100');
        tempFile.Write('2200020000                                                     6' +
          '1778                        000000000000000                  100');
        tempFile.Write('2300020000738609290061                         ASTRA TEC BVBA   ' +
          '         INDUSTRIELAAN 19          8810 LICHTERVELDE         000');
        tempFile.Write('2100030000NRGD00176 TBOINDNLOON1000000005313300170107001010000IN' +
          'V6205 MIN VOORSCHOT MIN TEVEEL GEST                1701070110100');
        tempFile.Write('2200030000                                                     6' +
          '1957 MI                     000000000000000                  100');
        tempFile.Write('2300030000390031747246                         IPL              ' +
          '                                                             000');
        tempFile.Write('21000400007409A3BWQ KGDTTNTERNG1000000004000000160107009010000  ' +
          '                                                   1701070110000');
        tempFile.Write('8011737010689443 EUR0BE                  0000000222672150170107 ' +
          '                                                                ');
        tempFile.Write('9               000012000000013878840000000000000000            ' +
          '                                                               1');
        tempFile.Write('0000018010772505D  0000000074789  INVERTO NV                0000' +
          '000000000430018420 00000                                       1');
        tempFile.Write('1 012737010689443 EUR0BE                  0000000222672150170107' +
          'INVERTO NV                KBC-Bedrijfsrekening               001');
        tempFile.Write('2100010000OCGP00069BTBOGOVOVERS000000000122210018010700150000063' +
          '13;                                                1801070120100');
        tempFile.Write('2300010000443900193149                         C-MAC ELECTROMAG ' +
          'N.V.     INDUSTRIEZONE 28          9600 RONSE                000');
        tempFile.Write('8012737010689443 EUR0BE                  0000000223894250180107 ' +
          '                                                                ');
        tempFile.Write('9               000004000000000000000000000001222100            ' +
          '                                                               1');
        tempFile.Write('0000019010772505D  0000000074789  INVERTO NV                0000' +
          '000000000430018420 00000                                       1');
        tempFile.Write('1 013737010689443 EUR0BE                  0000000223894250180107' +
          'INVERTO NV                KBC-Bedrijfsrekening               001');
        tempFile.Write('2100010000OOQXA0AAO DOMNINDIN01100000000099810019010700501000110' +
          '7740784398863220107               0070140918      01901070130100');
        tempFile.Write('22000100000876383320                                            ' +
          '                            000000000000000                  100');
        tempFile.Write('2300010000000000000000                         D''IETEREN SERVICE' +
          'S                                                            000');
        tempFile.Write('2100020000OQEJ02375 TBOINDNLOON1000000003700000190107001010000FA' +
          'CTUUR F20060264                                    1901070130100');
        tempFile.Write('2200020000                                                     6' +
          '1961                        000000000000000                  100');
        tempFile.Write('2300020000447962409164                         DE GOUDEN KROON  ' +
          '         MARKTPLEIN 3-9            9940 EVERGEM              000');
        tempFile.Write('2100030000OQEJ02376 TBOINDNLOON10000000116142301901070010100002 ' +
          'AF MIN 2 VF MIN TEV BET                            1901070130100');
        tempFile.Write('2200030000                                                     7' +
          '0048 59                     000000000000000                  100');
        tempFile.Write('2300030000467538877123                         FIBECON BVBA     ' +
          '         MEERSBLOEM MELDEN 30      9700 OUDENAARDE           000');
        tempFile.Write('2100040000OL9414457JBBNEUBCRCL1000000000738811019010734150000000' +
          '352037019A2387                                     1901070131001');
        tempFile.Write('3100040001OL9414457JBBNEUBCRCL1341500001001PHILIPS LIGHTING BV  ' +
          '              P.O. BOX 1                                     1 0');
        tempFile.Write('3200040001BUILDING AA                                           ' +
          '                                                             0 1');
        tempFile.Write('3100040002OL9414457JBBNEUBCRCL13415000010026710280720000287 6327' +
          '                                                             0 0');
        tempFile.Write('2100040003OL9414457JBBNEUBCRCL1000000000738811019010784150100110' +
          '5000000007388110000000007388110000100000000EUR     1901070131100');
        tempFile.Write('2200040003         000000007388110                              ' +
          '                            000000000000000                  000');
        tempFile.Write('2100050000OTJZ07706BOVSBBNONTVA0000000006470000190107001500000IN' +
          'VOICE 6227                                         1901070130100');
        tempFile.Write('2300050000293047693339                         NV PELEMAN INDUST' +
          'RIES     RIJKSWEG 7                2870    PUURS             000');
        tempFile.Write('8013737010689443 EUR0BE                  0000000221440030190107 ' +
          '                                                                ');
        tempFile.Write('9               000019000000016312330000000013858110            ' +
          '                                                               1');
        tempFile.Write('0000022010772505D  0000000074789  INVERTO NV                0000' +
          '000000000430018420 00000                                       1');
        tempFile.Write('1 014737010689443 EUR0BE                  0000000221440030190107' +
          'INVERTO NV                KBC-Bedrijfsrekening               001');
        tempFile.Write('2100010000PERF03204 TBOINDNLOON1000000000260000220107001010000IN' +
          'SCHRIJVING LED EUROPE                              2201070140100');
        tempFile.Write('2200010000                                                     D' +
          'IV6108                      000000000000000                  100');
        tempFile.Write('2300010000091013155653                         BAO              ' +
          '         GABRIELLE PETITSTRAAT 4B121080 BRUSSEL 8            000');
        tempFile.Write('8014737010689443 EUR0BE                  0000000221180030220107 ' +
          '                                                                ');
        tempFile.Write('9               000005000000000260000000000000000000            ' +
          '                                                               1');
        tempFile.Write('0000023010772505D  0000000074789  INVERTO NV                0000' +
          '000000000430018420 00000                                       1');
        tempFile.Write('1 015737010689443 EUR0BE                  0000000221180030220107' +
          'INVERTO NV                KBC-Bedrijfsrekening               001');
        tempFile.Write('2100010000PQJJA0AM3 DOMALGDOV01100000000039663023010700501000110' +
          '774071599264523010775560-LF-0  2548125   414271   02301070150100');
        tempFile.Write('22000100000426403684                                            ' +
          '                            000000000000000                  100');
        tempFile.Write('2300010000000000000000                         KBC LEASE BELGIUM' +
          '                                                             000');
        tempFile.Write('2100020000PRFQ01851BTBOINDNLOON0000000000354000230107001500000FA' +
          'KT 7008    17/01/07   OUD IJZER                    2301070150100');
        tempFile.Write('2300020000449461774136                         DEKEUKELEIRE G & ' +
          'F BVBA   KOOPVAARDIJLAAN 49        9000  GENT                000');
        tempFile.Write('8015737010689443 EUR0BE                  0000000221137400230107 ' +
          '                                                                ');
        tempFile.Write('9               000007000000000396630000000000354000            ' +
          '                                                               1');
        tempFile.Write('0000025010772505D  0000000074789  INVERTO NV                0000' +
          '000000000430018420 00000                                       1');
        tempFile.Write('1 016737010689443 EUR0BE                  0000000221137400240107' +
          'INVERTO NV                KBC-Bedrijfsrekening               001');
        tempFile.Write('2100010000QPGEA0B06 DOMALGDOV01100000000117504025010700501000110' +
          '7740784372894250107I=0701631865 R=37005468        02501070160100');
        tempFile.Write('22000100000403063902                                            ' +
          '                            000000000000000                  100');
        tempFile.Write('2300010000000000000000                         NV TOTAL BELGIUM ' +
          'SA                                                           000');
        tempFile.Write('2100020000QYVWA0ACA DOMNINDIN01100000000000456025010700501000110' +
          '7740784719367260107      070042466                02501070160100');
        tempFile.Write('22000200000409823416                                            ' +
          '                            000000000000000                  100');
        tempFile.Write('2300020000000000000000                         HULP DER PATROONS' +
          ' DOMICIL.                                                    000');
        tempFile.Write('2100030000QYVWA0ACB DOMNINDIN01100000002232500025010700501000110' +
          '7740784719367260107      060534697                02501070160100');
        tempFile.Write('22000300000409823416                                            ' +
          '                            000000000000000                  100');
        tempFile.Write('2300030000000000000000                         HULP DER PATROONS' +
          ' DOMICIL.                                                    000');
        tempFile.Write('8016737010689443 EUR0BE                  0000000197632800250107 ' +
          '                                                                ');
        tempFile.Write('9               000011000000023504600000000000000000            ' +
          '                                                               1');
        tempFile.Write('0000026010772505D  0000000074789  INVERTO NV                0000' +
          '000000000430018420 00000                                       1');
        tempFile.Write('1 017737010689443 EUR0BE                  0000000197632800250107' +
          'INVERTO NV                KBC-Bedrijfsrekening               001');
        tempFile.Write('2100010000OL9456866JBBNEUNCRCL1000000010144318026010734150000000' +
          '352037026A2463                                     2601070171001');
        tempFile.Write('3100010001OL9456866JBBNEUNCRCL1341500001001PHILIPS LIGHTING BV  ' +
          '              P.O. BOX 1                                     1 0');
        tempFile.Write('3200010001BUILDING AA                        OSS                ' +
          '                                                             0 1');
        tempFile.Write('3100010002OL9456866JBBNEUNCRCL13415000010026710280720000415 6235' +
          ' 6274 6310                                                   0 0');
        tempFile.Write('2100010003OL9456866JBBNEUNCRCL1000000010144318026010784150100110' +
          '5000000101443180000000101443180000100000000EUR     2601070171100');
        tempFile.Write('2200010003         000000101443180                              ' +
          '                            000000000000000                  000');
        tempFile.Write('2100020000OL9456867KBBNKOSDIVKS100000000001089026010734137000000' +
          '352037026A2463                                     2601070171000');
        tempFile.Write('2100020001OL9456867KBBNKOSDIVKS1000000000009000260107841370130  ' +
          '                                                   2601070170000');
        tempFile.Write('2100020002OL9456867KBBNKOSDIVKS100000000000189026010784137011110' +
          '6000000000001890000000000009000002100000000200000002601070171100');
        tempFile.Write('220002000200001890                                              ' +
          '                            000000000000000                  000');
        tempFile.Write('2100030000OL9460898JBBOEUBCRECL000000001575055029010734150000000' +
          '352037026A6016                                     2601070171100');
        tempFile.Write('2200030000                                                     T' +
          '47A70124AD86                000000000000000                  001');
        tempFile.Write('3100030001OL9460898JBBOEUBCRECL341500001001STECA BATTERIELADESYS' +
          'TEME UND      PRAEZISIONSELEKTRONIK GMBH                     1 0');
        tempFile.Write('3200030001MAMMOSTRASSE 1                     87700 MEMMINGEN    ' +
          '                                                             0 1');
        tempFile.Write('3100030002OL9460898JBBOEUBCRECL341500001002INV. 6347 / 27.12.200' +
          '6             INV. 6336 - 6339 VOM 22.12.2006                0 0');
        tempFile.Write('2100030003OL9460898JBBOEUBCRECL000000001575055029010784150100110' +
          '5000000015750550000000015750550000100000000EUR     2601070171100');
        tempFile.Write('2200030003         000000015750550                              ' +
          '                            000000000000000                  000');
        tempFile.Write('2100040000OL7079304 KGDBDCVBDEG1000000000470390250107309050000Uw' +
          ' bestelling                      34118493343       2601070171000');
    end;

    local procedure Write7022600005C(var tempFile: File)
    begin
        tempFile.Write('2100040001OL7079304 KGDBDCVBDEG100000000047039025010780905100110' +
          '5000000000470390000000000470390000063777500GBP     2601070171100');
        tempFile.Write('2200040001         000000000470390                              ' +
          '                            000000000000000                  000');
        tempFile.Write('2100050000RIQX00752BTBOINDNLOON0000000000224760260107001500000FA' +
          'CT. 6287                                           2601070170100');
        tempFile.Write('2300050000443900270143                         PRINTED CARPETS V' +
          'E.DE.BE. IND.PARK KL FRANKRIJK 62  9600  RONSE               000');
        tempFile.Write('8017737010689443 EUR0BE                  0000000314570010260107 ' +
          '                                                                ');
        tempFile.Write('9               000024000000000481280000000117418490            ' +
          '                                                               1');
        tempFile.Write('0000029010772505D  0000000074789  INVERTO NV                0000' +
          '000000000430018420 00000                                       1');
        tempFile.Write('1 018737010689443 EUR0BE                  0000000314570010260107' +
          'INVERTO NV                KBC-Bedrijfsrekening               001');
        tempFile.Write('2100010000RUIXA0AMU DOMALGDOV01100000000036048029010700501000110' +
          '774071599264529010774337-LF-0  2557333   414652   02901070180100');
        tempFile.Write('22000100000426403684                                            ' +
          '                            000000000000000                  100');
        tempFile.Write('2300010000000000000000                         KBC LEASE BELGIUM' +
          '                                                             000');
        tempFile.Write('2100020000RVQH03264 TBOINDNLOON100000000001800029010700101000110' +
          '1079934278829                                      2901070180100');
        tempFile.Write('2200020000                                                     D' +
          'IV7002                      000000000000000                  100');
        tempFile.Write('2300020000390044242058                         VORMETAL O W-VLAA' +
          'NDEREN   TRAMSTRAAT 61             9052 ZWIJNAARDE           000');
        tempFile.Write('2100030000RVQH03265 TBOINDNLOON100000000139379029010700101000110' +
          '1000043806412                                      2901070180100');
        tempFile.Write('2200030000                                                     6' +
          '/1933                       000000000000000                  100');
        tempFile.Write('2300030000435411161155                         PROXIMUS         ' +
          '         VOORTUIGANGSTRAAT 55      1210 BRUSSEL 21           000');
        tempFile.Write('2100040000SABYA0A4M DOMNINDIN01100000000034704029010700501000110' +
          '774076656127030010753220361 30/01                 02901070180100');
        tempFile.Write('22000400000000008314                                            ' +
          '                            000000000000000                  100');
        tempFile.Write('2300040000000000000000                         KBC-VERZEKERINGEN' +
          '                                                             000');
        tempFile.Write('2100050000OL9410136IUBOEUBTRFCS100000000019559026010734101000000' +
          '352037029B9459                                     2901070181100');
        tempFile.Write('2200050000                                                     7' +
          '0095                        000000000000000                  001');
        tempFile.Write('3100050001OL9410136IUBOEUBTRFCS341010001001PACK FEINDRAHTE      ' +
          '              AM BAUWEG 9-11                                 1 0');
        tempFile.Write('320005000151645 GUMMERSBACH DE               DE                 ' +
          '                                                             0 1');
        tempFile.Write('3100050002OL9410136IUBOEUBTRFCS341010001002RECHNUNG7500167      ' +
          '                                                             0 1');
        tempFile.Write('3100050003OL9410136IUBOEUBTRFCS341010001004DEUTSCHE BANK AG     ' +
          '                                                             0 0');
        tempFile.Write('2100050004OL9410136IUBOEUBTRFCS100000000019559026010784101100110' +
          '5000000000195590000000000195590000100000000EUR     2901070181100');
        tempFile.Write('2200050004         000000000195590                              ' +
          '                            000000000000000                  000');
        tempFile.Write('8018737010689443 EUR0BE                  0000000312255110290107 ' +
          '                                                                ');
        tempFile.Write('9               000022000000002314900000000000000000            ' +
          '                                                               1');
        tempFile.Write('0000030010772505D  0000000074789  INVERTO NV                0000' +
          '000000000430018420 00000                                       1');
        tempFile.Write('1 019737010689443 EUR0BE                  0000000312255110290107' +
          'INVERTO NV                KBC-Bedrijfsrekening               001');
        tempFile.Write('2100010000SPUG00352 TBOINDNLOON1000000013915000300107001010000FA' +
          'CT ST07001                                         3001070190100');
        tempFile.Write('2200010000                                                     7' +
          '0117                        000000000000000                  100');
        tempFile.Write('2300010000737016385868                         STEREYO          ' +
          '         ZONNESTR 7                9810 NAZARETH             000');
        tempFile.Write('2100020000SQOE00126 BHKDGLDTBLO1000000037058260300107101050000  ' +
          '                                                   3001070191000');
        tempFile.Write('2100020001SQNQ00001 TBOSOCOVERS1000000002050020300107501050000/A' +
          '/ LONEN 01/2007                                    3001070190100');
        tempFile.Write('2300020001449276421179                         KALFSVEL ALBERIK ' +
          '                                                             000');
        tempFile.Write('2100020002SQNQ00002 TBOSOCOVERS1000000003062420300107501050000/A' +
          '/ LONEN 01/2007                                    3001070190100');
        tempFile.Write('2300020002290019346063                         DE CLERCQ JOHN   ' +
          '                                                             000');
        tempFile.Write('2100020003SQNQ00003 TBOSOCOVERS1000000002262070300107501050000/A' +
          '/ LONEN 01/2007                                    3001070190100');
        tempFile.Write('2300020003001188642141                         DE BOODT SEBASTIA' +
          'AN                                                           000');
        tempFile.Write('2100020004SQNQ00004 TBOSOCOVERS1000000001567550300107501050000/A' +
          '/ LONEN 01/2007                                    3001070190100');
        tempFile.Write('2300020004780507355378                         VAN DEN BOSSCHE G' +
          'EERT                                                         000');
        tempFile.Write('2100020005SQNQ00005 TBOSOCOVERS1000000002047500300107501050000/A' +
          '/ LONEN 01/2007                                    3001070190100');
        tempFile.Write('2300020005979382731184                         ROMEYNS DIRK     ' +
          '                                                             000');
        tempFile.Write('2100020006SQNQ00006 TBOSOCOVERS1000000001875970300107501050000/A' +
          '/ LONEN 01/2007                                    3001070190100');
        tempFile.Write('2300020006777529118508                         VANDAMME PATRICK ' +
          '                                                             000');
        tempFile.Write('2100020007SQNQ00007 TBOSOCOVERS1000000001723310300107501050000/A' +
          '/ LONEN 01/2007                                    3001070190100');
        tempFile.Write('2300020007737446195801                         CANNOODT HENDRIK ' +
          '                                                             000');
        tempFile.Write('2100020008SQNQ00008 TBOSOCOVERS1000000001822980300107501050000/A' +
          '/ LONEN 01/2007                                    3001070190100');
        tempFile.Write('2300020008285032993567                         KIEKENS KRISTOF  ' +
          '                                                             000');
        tempFile.Write('2100020009SQNQ00009 TBOSOCOVERS1000000002295220300107501050000/A' +
          '/ LONEN 01/2007                                    3001070190100');
        tempFile.Write('2300020009738425378970                         DE MEERLEER GUIDO' +
          '                                                             000');
        tempFile.Write('2100020010SQNQ00010 TBOSOCOVERS1000000002553870300107501050000/A' +
          '/ LONEN 01/2007                                    3001070190100');
        tempFile.Write('2300020010290015438276                         GHIJSELEN JOZEF  ' +
          '                                                             000');
        tempFile.Write('2100020011SQNQ00011 TBOSOCOVERS1000000001721390300107501050000/A' +
          '/ LONEN 01/2007                                    3001070190100');
        tempFile.Write('2300020011001336470848                         VALLAEY MATTHIAS ' +
          '                                                             000');
        tempFile.Write('2100020012SQNQ00012 TBOSOCOVERS1000000001926210300107501050000/A' +
          '/ LONEN 01/2007                                    3001070190100');
        tempFile.Write('2300020012737101218432                         VAN DE SYPE DAVID' +
          '                                                             000');
        tempFile.Write('2100020013SQNQ00013 TBOSOCOVERS1000000001316770300107501050000/A' +
          '/ LONEN 01/2007                                    3001070190100');
        tempFile.Write('2300020013063952649462                         MOENS BRAM       ' +
          '                                                             000');
        tempFile.Write('2100020014SQNQ00014 TBOSOCOVERS1000000002086650300107501050000/A' +
          '/ LONEN 01/2007                                    3001070190100');
        tempFile.Write('2300020014293016209361                         VAEL PHILIP      ' +
          '                                                             000');
        tempFile.Write('2100020015SQNQ00015 TBOSOCOVERS1000000001661660300107501050000/A' +
          '/ LONEN 01/2007                                    3001070190100');
        tempFile.Write('2300020015737005116185                         VAN DER PLAETSEN ' +
          'ISABELLE                                                     000');
        tempFile.Write('2100020016SQNQ00016 TBOSOCOVERS1000000001911840300107501050000/A' +
          '/ LONEN 01/2007                                    3001070190100');
        tempFile.Write('2300020016733163053996                         VERMEER PAUL     ' +
          '                                                             000');
        tempFile.Write('2100020017SQNQ00017 TBOSOCOVERS1000000001232440300107501050000/A' +
          '/ LONEN 01/2007                                    3001070190100');
        tempFile.Write('2300020017001347713047                         MINJAUW WOUTER   ' +
          '                                                             000');
        tempFile.Write('2100020018SQNQ00018 TBOSOCOVERS1000000001318760300107501050000/A' +
          '/ LONEN 01/2007                                    3001070190100');
        tempFile.Write('2300020018800226253891                         HERTOGE ANN      ' +
          '                                                             000');
        tempFile.Write('2100020019SQNQ00019 TBOSOCOVERS1000000001324090300107501050000/A' +
          '/ LONEN 01/2007                                    3001070190100');
        tempFile.Write('2300020019780539341736                         DE SAEDELEER SONJ' +
          'A                                                            000');
        tempFile.Write('2100020020SQNQ00020 TBOSOCOVERS1000000001297540300107501050000/A' +
          '/ LONEN 01/2007                                    3001070191100');
        tempFile.Write('2300020020063967633538                         COTTRELL ROY     ' +
          '                                                             000');
        tempFile.Write('8019737010689443 EUR0BE                  0000000261281850300107 ' +
          '                                                                ');
        tempFile.Write('9               000046000000050973260000000000000000            ' +
          '                                                               1');
        tempFile.Write('0000031010772505D  0000000074789  INVERTO NV                0000' +
          '000000000430018420 00000                                       1');
        tempFile.Write('1 020737010689443 EUR0BE                  0000000261281850300107' +
          'INVERTO NV                KBC-Bedrijfsrekening               001');
        tempFile.Write('2100010000TAAZA0D3Y IKLINNINNIG1000000000755750310107313410000  ' +
          '            INVESTERINGSKREDIET     726-3667975-97 3101070201000');
        tempFile.Write('2100010001TAAZA0D3Y IKLINNINNIG1000000000693670310107813410660  ' +
          '                                                   3101070200000');
        tempFile.Write('2100010002TAAZA0D3Y IKLINNINNIG1000000000062080310107813410020  ' +
          '                                                   3101070201000');
        tempFile.Write('2100020000TEBF03361 TBOINDNLOON1000000000147260310107001010000FA' +
          'CT 7006771RI                                       3101070200100');
        tempFile.Write('2200020000                                                     6' +
          '1818                        000000000000000                  100');
        tempFile.Write('2300020000230099456544                         ACAL             ' +
          '         LOZENBERG 4               1932 ZAVENTEM             000');
        tempFile.Write('2100030000TEBF03362 TBOINDNLOON1000000000417140310107001010000FA' +
          'CT870084                                           3101070200100');
        tempFile.Write('2200030000                                                     7' +
          '0014                        000000000000000                  100');
        tempFile.Write('2300030000444564625163                         ALLCOMM          ' +
          '         BRUSSelseSTEENWEG 424-426 9050 LEDEBERG (GENT       000');
        tempFile.Write('2100040000TEBF03363 TBOINDNLOON1000000002074860310107001010000FA' +
          'CT2500281402 1403 86009 86010                      3101070200100');
        tempFile.Write('2200040000                                                     6' +
          '1788 92                     000000000000000                  100');
        tempFile.Write('2300040000459250650182                         AVNET EUROPE NV  ' +
          '         KOUTERVELDSTRAAT 20       1831 DIEGEM               000');
        tempFile.Write('2100050000TEBF03364 TBOINDNLOON1000000000400380310107001010000IN' +
          'V284121 84120 84787                                3101070200100');
        tempFile.Write('2200050000                                                     6' +
          '1862 87                     000000000000000                  100');
        tempFile.Write('2300050000459250650182                         AVNET EUROPE NV  ' +
          '         KOUTERVELDSTRAAT 20       1831 DIEGEM               000');
        tempFile.Write('2100060000TEBF03365 TBOINDNLOON100000000015125031010700101000110' +
          '1571033615082                                      3101070200100');
        tempFile.Write('2200060000                                                     7' +
          '0053                        000000000000000                  100');
        tempFile.Write('2300060000000171003118                         BELGACOM         ' +
          '         K ALBERT II LAAN 27       1030 BRUSSEL 3            000');
        tempFile.Write('2100070000TEBF03366 TBOINDNLOON1000000000428540310107001010000FA' +
          'CT CF6 23848                                       3101070200100');
        tempFile.Write('2200070000                                                     6' +
          '1898                        000000000000000                  100');
        tempFile.Write('2300070000210033172032                         CEGELEC          ' +
          '         WOLUWELN 60               1200 BRUSSEL              000');
        tempFile.Write('2100080000TEBF03367 TBOINDNLOON100000000295773031010700101000016' +
          '4682 683 161505 161625                             3101070200100');
        tempFile.Write('2200080000                                                     D' +
          'IV                          000000000000000                  100');
        tempFile.Write('2300080000443900193149                         CMAC             ' +
          '         IZ KL FRANKRIJK 28        9600 RONSE                000');
        tempFile.Write('2100090000TEBF03368 TBOINDNLOON1000000000108750310107001010000FA' +
          'CT2007 015                                         3101070200100');
        tempFile.Write('2200090000                                                     7' +
          '0046                        000000000000000                  100');
        tempFile.Write('2300090000068211139826                         CONFISERIE SYLVIE' +
          '         ANTOON CATRIESTRAAT 48    9031 DRONGEN              000');
        tempFile.Write('2100100000TEBF03369 TBOINDNLOON1000000000546320310107001010000FA' +
          'CT602540                                           3101070200100');
        tempFile.Write('2200100000                                                     6' +
          '1951                        000000000000000                  100');
        tempFile.Write('2300100000462912815161                         DECOSTERE        ' +
          '         BURCHTHOF 10-11           8580 AVELGEM              000');
        tempFile.Write('2100110000TEBF03370 TBOINDNLOON1000000000421610310107001010000FT' +
          ' BRU0929445                                        3101070200100');
        tempFile.Write('2200110000                                                     6' +
          '1947                        000000000000000                  100');
        tempFile.Write('2300110000482910700226                         DHL              ' +
          '         POSTBUS 31                1831 DIEGEM               000');
        tempFile.Write('2100120000TEBF03371 TBOINDNLOON1000000000166910310107001010000FT' +
          ' BRU0915766                                        3101070200100');
        tempFile.Write('2200120000                                                     6' +
          '1873                        000000000000000                  100');
        tempFile.Write('2300120000482910700226                         DHL              ' +
          '         POSTBUS 31                1831 DIEGEM               000');
        tempFile.Write('2100130000TEBF03372 TBOINDNLOON1000000000068240310107001010000FT' +
          ' BRU0916695                                        3101070200100');
        tempFile.Write('2200130000                                                     6' +
          '1872                        000000000000000                  100');
        tempFile.Write('2300130000482910700226                         DHL              ' +
          '         POSTBUS 31                1831 DIEGEM               000');
        tempFile.Write('2100140000TEBF03373 TBOINDNLOON1000000002366570310107001010000FA' +
          'CT504859                                           3101070200100');
        tempFile.Write('2200140000                                                     6' +
          '1840                        000000000000000                  100');
        tempFile.Write('2300140000414002661169                         EUROPRINT        ' +
          '         ZANDVOORTSTRAAT 21        2800 MECHELEN             000');
        tempFile.Write('2100150000TEBF03374 TBOINDNLOON1000000010845780310107001010000CO' +
          'NS INV141                                          3101070200100');
        tempFile.Write('2200150000                                                     6' +
          '1771                        000000000000000                  100');
        tempFile.Write('2300150000720540538471                         FARNELL IN ONE   ' +
          '         RUE DE L''AEROPOSTALE 11   4460 GRACE-HOLLOGNE       000');
        tempFile.Write('2100160000TEBF03375 TBOINDNLOON100000000004937031010700101000110' +
          '1162033393150                                      3101070200100');
        tempFile.Write('2200160000                                                     7' +
          '0056                        000000000000000                  100');
        tempFile.Write('2300160000437750115182                         FACQ             ' +
          '         GANGSTR 20                1050 BRUSSEL 5            000');
        tempFile.Write('2100170000TEBF03376 TBOINDNLOON100000000030120031010700101000110' +
          '1612631487833                                      3101070200100');
        tempFile.Write('2200170000                                                     6' +
          '1880                        000000000000000                  100');
        tempFile.Write('2300170000437751190165                         REXEL            ' +
          '         RUE DE LA TECHNOLOGIE     1082 BRUXELLES            000');
        tempFile.Write('2100180000OL9453892IUBOEUBTRFCS100000000004356030010734101000000' +
          '352037031A1449                                     3101070201100');
        tempFile.Write('2200180000                                                     6' +
          '1914                        000000000000000                  001');
        tempFile.Write('3100180001OL9453892IUBOEUBTRFCS341010001001ERIKS BV             ' +
          '              TOERMALIJNSTRAAT 5                             1 0');
        tempFile.Write('32001800011800BK ALKMAAR NL                  NL                 ' +
          '                                                             0 1');
        tempFile.Write('3100180002OL9453892IUBOEUBTRFCS341010001002FACT9101877291       ' +
          '                                                             0 1');
        tempFile.Write('3100180003OL9453892IUBOEUBTRFCS341010001004RABOBANK NEDERLAND   ' +
          '                                                             0 0');
        tempFile.Write('2100180004OL9453892IUBOEUBTRFCS100000000004356030010784101100110' +
          '5000000000043560000000000043560000100000000EUR     3101070201100');
        tempFile.Write('2200180004         000000000043560                              ' +
          '                            000000000000000                  000');
        tempFile.Write('2100190000OL9453893IUBOEUBTRFCS100000000241410030010734101000000' +
          '352037031A1448                                     3101070201100');
        tempFile.Write('2200190000                                                     6' +
          '1938 939                    000000000000000                  001');
        tempFile.Write('3100190001OL9453893IUBOEUBTRFCS341010001001BERGQUIST-ITC        ' +
          '              HADERSLEBENER STR. 19A                         1 0');
        tempFile.Write('320019000125421 PINNEBERG DE                 DE                 ' +
          '                                                             0 1');
        tempFile.Write('3100190002OL9453893IUBOEUBTRFCS341010001002INV93954 93946       ' +
          '                                                             0 1');
        tempFile.Write('3100190003OL9453893IUBOEUBTRFCS341010001004DEUTSCHE BANK AG     ' +
          '                                                             0 0');
        tempFile.Write('2100190004OL9453893IUBOEUBTRFCS100000000241410030010784101100110' +
          '5000000002414100000000002414100000100000000EUR     3101070201100');
        tempFile.Write('2200190004         000000002414100                              ' +
          '                            000000000000000                  000');
        tempFile.Write('2100200000OL9453894IUBOEUBTRFCS100000000015780030010734101000000' +
          '352037031A1450                                     3101070201001');
        tempFile.Write('3100200001OL9453894IUBOEUBTRFCS341010001001DIGI KEY CORPORATION ' +
          '              PO BOX 52                                      1 0');
        tempFile.Write('32002000017500AB ENSCHEDE NL                 NL                 ' +
          '                                                             0 1');
        tempFile.Write('3100200002OL9453894IUBOEUBTRFCS341010001002INV22025799 2204     ' +
          '                                                             0 1');
        tempFile.Write('3100200003OL9453894IUBOEUBTRFCS341010001004LLOYDS TSB BANK PLC  ' +
          '                                                             0 0');
        tempFile.Write('2100200004OL9453894IUBOEUBTRFCS100000000015780030010784101100110' +
          '5000000000157800000000000157800000100000000EUR     3101070201100');
        tempFile.Write('2200200004         000000000157800                              ' +
          '                            000000000000000                  000');
        tempFile.Write('8020737010689443 EUR0BE                  0000000236458730310107 ' +
          '                                                                ');
        tempFile.Write('9               000076000000024823120000000000000000            ' +
          '                                                               1');
        tempFile.Write('0000001020772505D  0000000074789  INVERTO NV                0000' +
          '000000000430018420 00000                                       1');
        tempFile.Write('1 021737010689443 EUR0BE                  0000000236458730310107' +
          'INVERTO NV                KBC-Bedrijfsrekening               001');
        tempFile.Write('2100010000TQTKA0M00 DOMNINDIN01100000000034704031010700501000110' +
          '774076656127001020753220361 01/02                 00102070210100');
        tempFile.Write('22000100000000008314                                            ' +
          '                            000000000000000                  100');
        tempFile.Write('2300010000000000000000                         KBC-VERZEKERINGEN' +
          '                                                             000');
        tempFile.Write('2100020000TXJT00179 TBOINDNLOON100000000010600001020700101000037' +
          '933 730678                                         0102070210100');
        tempFile.Write('2200020000                                                     7' +
          '0019                        000000000000000                  100');
        tempFile.Write('2300020000723540244980                         JEVEKA BV        ' +
          '                                                             000');
        tempFile.Write('2100030000TXJT00180 TBOINDNLOON100000000009062001020700101000110' +
          '1206195491314                                      0102070210100');
        tempFile.Write('2200030000                                                     6' +
          '1940                        000000000000000                  100');
        tempFile.Write('2300030000340013762419                         LYRECO           ' +
          '         RUE DE CHENEE 53          4031 ANGLEUR              000');
        tempFile.Write('2100040000TXJT00181 TBOINDNLOON1000000000072600010207001010000FA' +
          'CT7235 7236                                        0102070210100');
        tempFile.Write('2200040000                                                     6' +
          '1888 89                     000000000000000                  100');
        tempFile.Write('2300040000000003149567                         MATEDEX          ' +
          '         AVENUE DE L''ARTISANAT 4   1420 BRAINE-L''ALLEU       000');
        tempFile.Write('2100050000TXJT00182 TBOINDNLOON1000000000343820010207001010000FA' +
          'CT60234                                            0102070210100');
        tempFile.Write('2200050000                                                     6' +
          '1926                        000000000000000                  100');
        tempFile.Write('2300050000271004538218                         NITRON NV        ' +
          '         RUE DE LA MAITRISE 2      1400 MONSTREUX            000');
        tempFile.Write('2100060000TXJT00183 TBOINDNLOON1000000000253160010207001010000FA' +
          'CT4100072921                                       0102070210100');
        tempFile.Write('2200060000                                                     6' +
          '1868                        000000000000000                  100');
        tempFile.Write('2300060000405012480190                         OTTO WOLFF NV    ' +
          '         DELLINGSTRAAT 57          2800 MECHELEN             000');
        tempFile.Write('2100070000TXJT00184 TBOINDNLOON1000000000433710010207001010000FA' +
          'CT 26105980 KLANT 3160                             0102070210100');
        tempFile.Write('2200070000                                                     6' +
          '1715                        000000000000000                  100');
        tempFile.Write('2300070000320032338254                         PEPPERL+ FUCHS NV' +
          '         METROPOOLSTRAAT 11        2900 SCHOTEN              000');
        tempFile.Write('2100080000TXJT00185 TBOINDNLOON1000000001252920010207001010000NO' +
          'TA1566700309                                       0102070210100');
        tempFile.Write('2200080000                                                     7' +
          '0009                        000000000000000                  100');
        tempFile.Write('2300080000001308220408                         ROMBAUT  C       ' +
          '         JAGERSSTR 20 BUS 9        2140 BORGERHOUT (AN       000');
        tempFile.Write('2100090000TXJT00186 TBOINDNLOON1000000007062250010207001010000DI' +
          'V INV                                              0102070210100');
        tempFile.Write('2200090000                                                     D' +
          'IV INV                      000000000000000                  100');
        tempFile.Write('2300090000825601531087                         RUTRONIK         ' +
          '         INDUSTRIESTRASSE 2        7522 ISPRINGEN            000');
        tempFile.Write('2100100000TXJT00187 TBOINDNLOON1000000000977170010207001010000IN' +
          'V9168630 8632 8645 9288                            0102070210100');
        tempFile.Write('2200100000                                                     D' +
          'IV                          000000000000000                  100');
        tempFile.Write('2300100000310000321503                         SPOERLE          ' +
          '         MINERVASTRAAT 14B2        1930 ZAVENTEM             000');
        tempFile.Write('2100110000TXJT00188 TBOINDNLOON1000000004118200010207001010000FA' +
          'CT10052711 712 713 714 52772                       0102070210100');
        tempFile.Write('2200110000                                                     D' +
          'IV                          000000000000000                  100');
        tempFile.Write('2300110000472302320181                         TEAM             ' +
          '         JACQUES PARIJSLAAN 8      9940 EVERGEM              000');
        tempFile.Write('2100120000TXJT00189 TBOINDNLOON1000000000166830010207001010000IN' +
          'V680908 670323                                     0102070210100');
        tempFile.Write('2200120000                                                     6' +
          '1937 70                     000000000000000                  100');
        tempFile.Write('2300120000210049670015                         TNT              ' +
          '                                                             000');
        tempFile.Write('2100130000TXJT00190 TBOINDNLOON1000000000251680010207001010000FA' +
          'CT2006 514                                         0102070210100');
        tempFile.Write('2200130000                                                     6' +
          '1879                        000000000000000                  100');
        tempFile.Write('2300130000380020603881                         VANGO PRINTING   ' +
          '         HIJFTESTRAAT 55           9080 LOCHRISTI            000');
        tempFile.Write('2100140000UGRD00495BTBOGOVOVERS000000005844663001020700150000063' +
          '32 6334                                            0102070210100');
        tempFile.Write('2300140000482901003155                         BEKAERT COORDINAT' +
          'IECENTRUMBEKAERTSTRAAT 2           8550 ZWEVEGEM             000');
        tempFile.Write('8021737010689443 EUR0BE                  0000000279429360010207 ' +
          '                                                                ');
        tempFile.Write('9               000043000000015476000000000058446630            ' +
          '                                                               1');
        tempFile.Write('0000002020772505D  0000000074789  INVERTO NV                0000' +
          '000000000430018420 00000                                       1');
        tempFile.Write('1 022737010689443 EUR0BE                  0000000279429360010207' +
          'INVERTO NV                KBC-Bedrijfsrekening               001');
        tempFile.Write('21000100007409A3C88 KGDTTNTERNG1000000005777620010207009010000  ' +
          '                                                   0202070220000');
        tempFile.Write('8022737010689443 EUR0BE                  0000000273651740020207 ' +
          '                                                                ');
        tempFile.Write('9               000003000000005777620000000000000000            ' +
          '                                                               1');
        tempFile.Write('0000005020772505D  0000000074789  INVERTO NV                0000' +
          '000000000430018420 00000                                       1');
        tempFile.Write('1 023737010689443 EUR0BE                  0000000273651740020207' +
          'INVERTO NV                KBC-Bedrijfsrekening               001');
        tempFile.Write('2100010000VGCN03809 TBOINDNLOON100000000031052005020700101000110' +
          '1061135212219                                      0502070230100');
        tempFile.Write('2200010000                                                     D' +
          'IV7011                      000000000000000                  100');
        tempFile.Write('2300010000679200231036                         BELASTINGEN      ' +
          '         AUTOS                     1000 BRUSSEL 1            000');
        tempFile.Write('2100020000VGCN03810 TBOINDNLOON100000000095623005020700101000110' +
          '1061143082757                                      0502070230100');
        tempFile.Write('2200020000                                                     D' +
          'IV7012                      000000000000000                  100');
        tempFile.Write('2300020000679200231036                         BELASTINGEN      ' +
          '         AUTOS                     1000 BRUSSEL 1            000');
        tempFile.Write('8023737010689443 EUR0BE                  0000000272384990050207 ' +
          '                                                                ');
        tempFile.Write('9               000008000000001266750000000000000000            ' +
          '                                                               1');
        tempFile.Write('0000006020772505D  0000000074789  INVERTO NV                0000' +
          '000000000430018420 00000                                       1');
        tempFile.Write('1 024737010689443 EUR0BE                  0000000272384990050207' +
          'INVERTO NV                KBC-Bedrijfsrekening               001');
        tempFile.Write('2100010000VVXKA0CN4 IKLINNINNIG1000000003660120060207313410000  ' +
          '            INVESTERINGSKREDIET     726-3754303-95 0602070241000');
        tempFile.Write('2100010001VVXKA0CN4 IKLINNINNIG1000000003333330060207813410660  ' +
          '                                                   0602070240000');
        tempFile.Write('2100010002VVXKA0CN4 IKLINNINNIG1000000000326790060207813410020  ' +
          '                                                   0602070241000');
        tempFile.Write('2100020000OL7087022 KGDBDCVBDEG1000000000805180050207309050000Uw' +
          ' bestelling                      34110007257       0602070241000');
        tempFile.Write('2100020001OL7087022 KGDBDCVBDEG100000000080518005020780905100110' +
          '5000000000805180000000000805180000124195500USD     0602070241100');
        tempFile.Write('2200020001         000000000805180                              ' +
          '                            000000000000000                  000');
        tempFile.Write('2100030000OL9498991JBBNEUBCRCL1000000002381053007020734150000000' +
          '352037037B7942                                     0602070241001');
        tempFile.Write('3100030001OL9498991JBBNEUBCRCL1341500001001SPLASHPOWER LTD      ' +
          '              THE JEFFREYS BUILDING, COWLEY RD               1 0');
        tempFile.Write('3200030001CAMBRIDGE CB4 0WS                                     ' +
          '                                                             0 1');
        tempFile.Write('3100030002OL9498991JBBNEUBCRCL1341500001002INV 6346             ' +
          '                                                             0 0');
        tempFile.Write('2100030003OL9498991JBBNEUBCRCL1000000002381053007020784150100110' +
          '5000000023810530000000023810530000100000000EUR     0602070241100');
        tempFile.Write('2200030003         000000023810530                              ' +
          '                            000000000000000                  000');
        tempFile.Write('8024737010689443 EUR0BE                  0000000291730220060207 ' +
          '                                                                ');
        tempFile.Write('9               000014000000004465300000000023810530            ' +
          '                                                               1');
        tempFile.Write('0000007020772505D  0000000074789  INVERTO NV                0000' +
          '000000000430018420 00000                                       1');
    end;

    local procedure Write7022600005D(var tempFile: File)
    begin
        tempFile.Write('1 025737010689443 EUR0BE                  0000000291730220060207' +
          'INVERTO NV                KBC-Bedrijfsrekening               001');
        tempFile.Write('2100010000OL9407316JBBOEUBCRECL000000000740800008020734150000000' +
          '352037038A1971                                     0702070251100');
        tempFile.Write('2200010000                                                     4' +
          '550-70360575928             000000000000000                  001');
        tempFile.Write('3100010001OL9407316JBBOEUBCRECL341500001001ROSTI POLSKA SP. Z.O.' +
          'O.            Elewatorska 29                                 1 0');
        tempFile.Write('320001000115-620  Bia ystok                                     ' +
          '                                                             0 1');
        tempFile.Write('3100010002OL9407316JBBOEUBCRECL341500001002INVOICE  7003        ' +
          '              SUROWIEC                                       0 0');
        tempFile.Write('2100010003OL9407316JBBOEUBCRECL000000000740800008020784150100110' +
          '5000000007408000000000007408000000100000000EUR     0702070251100');
        tempFile.Write('2200010003         000000007408000                              ' +
          '                            000000000000000                  000');
        tempFile.Write('8025737010689443 EUR0BE                  0000000299138220070207 ' +
          '                                                                ');
        tempFile.Write('9               000009000000000000000000000007408000            ' +
          '                                                               1');
        tempFile.Write('0000008020772505D  0000000074789  INVERTO NV                0000' +
          '000000000430018420 00000                                       1');
        tempFile.Write('1 026737010689443 EUR0BE                  0000000299138220070207' +
          'INVERTO NV                KBC-Bedrijfsrekening               001');
        tempFile.Write('2100010000XASOA0AM2 DOMALGDOV01100000000070164008020700501000110' +
          '774071599264508020774422-LF-0  2569189   415130   00802070260100');
        tempFile.Write('22000100000426403684                                            ' +
          '                            000000000000000                  100');
        tempFile.Write('2300010000000000000000                         KBC LEASE BELGIUM' +
          '                                                             000');
        tempFile.Write('2100020000XBRY02063 TBOINDNLOON1000000009292560080207001010000FA' +
          'CT20061767 FACT20061768 MIN 2 CN                   0802070260100');
        tempFile.Write('2200020000                                                     6' +
          '1838 61                     000000000000000                  100');
        tempFile.Write('2300020000230056163828                         TRINSY TECHNICS  ' +
          '         ANTWERPSESTWG 120         2390 MALLE                000');
        tempFile.Write('2100030000XBRY02064 TBOINDNLOON1000000003523520080207001010000FA' +
          'CT60317                                            0802070260100');
        tempFile.Write('2200030000                                                     6' +
          '1844                        000000000000000                  100');
        tempFile.Write('2300030000733028656658                         VAN VOXDALE      ' +
          '         LANGE WINKELHAAKSTRAAT 26 2060 BERCHEM (ANTW.       000');
        tempFile.Write('2100040000OL9432203IUBOEUBTRFCS100000000700000007020734101000000' +
          '352037039A1708                                     0802070261100');
        tempFile.Write('2200040000                                                     7' +
          '0131                        000000000000000                  001');
        tempFile.Write('3100040001OL9432203IUBOEUBTRFCS341010001001NICHIA EUROPE BV     ' +
          '              HORNWEG 18                                     1 0');
        tempFile.Write('32000400011045 AR AMSTERDAM NL               NL                 ' +
          '                                                             0 1');
        tempFile.Write('3100040002OL9432203IUBOEUBTRFCS341010001002INVOICE 20070248     ' +
          '                                                             0 1');
        tempFile.Write('3100040003OL9432203IUBOEUBTRFCS341010001004BANK OF TOKYO - MITSU' +
          'BISHI UFJ (HOL                                               0 0');
        tempFile.Write('2100040004OL9432203IUBOEUBTRFCS100000000700000007020784101100110' +
          '5000000007000000000000007000000000100000000EUR     0802070261100');
        tempFile.Write('2200040004         000000007000000                              ' +
          '                            000000000000000                  000');
        tempFile.Write('8026737010689443 EUR0BE                  0000000278620500080207 ' +
          '                                                                ');
        tempFile.Write('9               000019000000020517720000000000000000            ' +
          '                                                               1');
        tempFile.Write('0000009020772505D  0000000074789  INVERTO NV                0000' +
          '000000000430018420 00000                                       1');
        tempFile.Write('1 027737010689443 EUR0BE                  0000000278620500080207' +
          'INVERTO NV                KBC-Bedrijfsrekening               001');
        tempFile.Write('2100010000XNQXA0BCT IKLINNINNIG1000000000991820090207313410000  ' +
          '            INVESTERINGSKREDIET     726-2764912-07 0902070271000');
        tempFile.Write('2100010001XNQXA0BCT IKLINNINNIG1000000000950930090207813410660  ' +
          '                                                   0902070270000');
        tempFile.Write('2100010002XNQXA0BCT IKLINNINNIG1000000000040890090207813410020  ' +
          '                                                   0902070271000');
        tempFile.Write('2100020000OL9459477JBBNEUBCRCL1000000003540602009020734150000000' +
          '352037040A2319                                     0902070271001');
        tempFile.Write('3100020001OL9459477JBBNEUBCRCL1341500001001PHILIPS LIGHTING BV  ' +
          '              P.O. BOX 1                                     1 0');
        tempFile.Write('3200020001BUILDING AA                        OSS                ' +
          '                                                             0 1');
        tempFile.Write('3100020002OL9459477JBBNEUBCRCL13415000010026710280720000573 6308' +
          ' 6323 6342                                                   0 0');
        tempFile.Write('2100020003OL9459477JBBNEUBCRCL1000000003540602009020784150100110' +
          '5000000035406020000000035406020000100000000EUR     0902070271100');
        tempFile.Write('2200020003         000000035406020                              ' +
          '                            000000000000000                  000');
        tempFile.Write('2100030000XXNGA0B1O DOMNINDIN01100000000016858009020700501000110' +
          '7740784719367120207      070042467                00902070270100');
        tempFile.Write('22000300000409823416                                            ' +
          '                            000000000000000                  100');
        tempFile.Write('2300030000000000000000                         HULP DER PATROONS' +
          ' DOMICIL.                                                    000');
        tempFile.Write('2100040000XXNGA0B1P DOMNINDIN01100000001610006009020700501000110' +
          '7740784719367120207      070042480                00902070270100');
        tempFile.Write('22000400000409823416                                            ' +
          '                            000000000000000                  100');
        tempFile.Write('2300040000000000000000                         HULP DER PATROONS' +
          ' DOMICIL.                                                    000');
        tempFile.Write('8027737010689443 EUR0BE                  0000000296766060090207 ' +
          '                                                                ');
        tempFile.Write('9               000017000000017260460000000035406020            ' +
          '                                                               1');
        tempFile.Write('0000012020772505D  0000000074789  INVERTO NV                0000' +
          '000000000430018420 00000                                       1');
        tempFile.Write('1 028737010689443 EUR0BE                  0000000296766060090207' +
          'INVERTO NV                KBC-Bedrijfsrekening               001');
        tempFile.Write('2100010000YCTIA0APN DOMALGDOV01100000000028146012020700501000110' +
          '774071599264512020773518-LF-0  2573027   415350   01202070280100');
        tempFile.Write('22000100000426403684                                            ' +
          '                            000000000000000                  100');
        tempFile.Write('2300010000000000000000                         KBC LEASE BELGIUM' +
          '                                                             000');
        tempFile.Write('2100020000YCTIA0APO DOMALGDOV01100000000028702012020700501000110' +
          '774071599264512020773520-LF-0  2573028   415350   01202070280100');
        tempFile.Write('22000200000426403684                                            ' +
          '                            000000000000000                  100');
        tempFile.Write('2300020000000000000000                         KBC LEASE BELGIUM' +
          '                                                             000');
        tempFile.Write('2100030000YCTIA0APP DOMALGDOV01100000000033999012020700501000110' +
          '774071599264512020773521-LF-0  2573029   415350   01202070280100');
        tempFile.Write('22000300000426403684                                            ' +
          '                            000000000000000                  100');
        tempFile.Write('2300030000000000000000                         KBC LEASE BELGIUM' +
          '                                                             000');
        tempFile.Write('2100040000YCUGA0CVW DOMALGDOV01100000000138109012020700501000110' +
          '7740784372894120207I=0701668378 R=37017803        01202070280100');
        tempFile.Write('22000400000403063902                                            ' +
          '                            000000000000000                  100');
        tempFile.Write('2300040000000000000000                         NV TOTAL BELGIUM ' +
          'SA                                                           000');
        tempFile.Write('2100050000YGQM02428LKKTOVSOVKUG100000000499090012020700319000112' +
          '45526145478490607    1435                          1202070280100');
        tempFile.Write('2300050000666000000483                                          ' +
          '                                                             000');
        tempFile.Write('8028737010689443 EUR0BE                  0000000289485600120207 ' +
          '                                                                ');
        tempFile.Write('9               000016000000007280460000000000000000            ' +
          '                                                               1');
        tempFile.Write('0000013020772505D  0000000074789  INVERTO NV                0000' +
          '000000000430018420 00000                                       1');
        tempFile.Write('1 029737010689443 EUR0BE                  0000000289485600120207' +
          'INVERTO NV                KBC-Bedrijfsrekening               001');
        tempFile.Write('2100010000YPQM05627BOVSBBNONTVA000000000007026013020700150000017' +
          '01212007001422 6088 6088CN 632   9                 1302070290100');
        tempFile.Write('2300010000685668801833                         PHILIPS INNOVATIV' +
          'E APPLICATSTEENWEG OP GIERLE 417           TURNHOUT          000');
        tempFile.Write('2100020000YQCBA0AMJ DOMALGDOV01100000000028712013020700501000110' +
          '774071599264513020778359-LF-0  2576022   415418   01302070290100');
        tempFile.Write('22000200000426403684                                            ' +
          '                            000000000000000                  100');
        tempFile.Write('2300020000000000000000                         KBC LEASE BELGIUM' +
          '                                                             000');
        tempFile.Write('2100030000YUPBA0E2M DOMUCVDIU01100000000002045013020700501000110' +
          '7740784397045130207227764/68145298                01302070290100');
        tempFile.Write('22000300000000938128                                            ' +
          '                            000000000000000                  100');
        tempFile.Write('2300030000000000000000                         TAXIPOST         ' +
          '                                                             000');
        tempFile.Write('8029737010689443 EUR0BE                  0000000289248290130207 ' +
          '                                                                ');
        tempFile.Write('9               000010000000000307570000000000070260            ' +
          '                                                               1');
        tempFile.Write('0000014020772505D  0000000074789  INVERTO NV                0000' +
          '000000000430018420 00000                                       1');
        tempFile.Write('1 030737010689443 EUR0BE                  0000000289248290130207' +
          'INVERTO NV                KBC-Bedrijfsrekening               001');
        tempFile.Write('2100010000ZFFP02090 TBOINDNLOON100000000072659014020700101000110' +
          '1061222384503                                      1402070300100');
        tempFile.Write('2200010000                                                     D' +
          'IV7019                      000000000000000                  100');
        tempFile.Write('2300010000679200231036                         BELASTINGEN AUTOS' +
          '         KON ALBERT II LAAN        1030 BRUSSEL 3            000');
        tempFile.Write('2100020000ZFFP02091 TBOINDNLOON1000000008558820140207001010000FA' +
          'CT 1491                                            1402070300100');
        tempFile.Write('2200020000                                                     7' +
          '0198                        000000000000000                  100');
        tempFile.Write('2300020000467538877123                         FIBECON BVBA     ' +
          '         MEERSBLOEM MELDEN 30      9700 OUDENAARDE           000');
        tempFile.Write('2100030000ZFFP02092 TBOINDNLOON1000000000035000140207001010000/A' +
          '/ EXP NOV DEC JAN                                  1402070300100');
        tempFile.Write('2200030000                                                     D' +
          'IV7013                      000000000000000                  100');
        tempFile.Write('2300030000780507355378                         VANDENBOSSCHE GEE' +
          'RT                                                           000');
        tempFile.Write('2100040000ZFFP02093 TBOINDNLOON1000000000316180140207001010000/A' +
          '/ EXP JAN07 HALT TUV                               1402070300100');
        tempFile.Write('2200040000                                                     D' +
          'IV7015                      000000000000000                  100');
        tempFile.Write('2300040000293016209361                         VAEL PHILIP      ' +
          '                                                             000');
        tempFile.Write('2100050000ZFFP02094 TBOINDNLOON1000000000028100140207001010000/A' +
          '/ EXP AANKOOP MACRO                                1402070300100');
        tempFile.Write('2200050000                                                     D' +
          'IV7016                      000000000000000                  100');
        tempFile.Write('2300050000979382731184                         ROMEYNS DIRK     ' +
          '         WAFELSTRAAT 26            9630 ZWALM                000');
        tempFile.Write('2100060000ZFFP02095 TBOINDNLOON1000000000020600140207001010000/A' +
          '/ EXP TREIN 080207                                 1402070300100');
        tempFile.Write('2200060000                                                     D' +
          'IV7020                      000000000000000                  100');
        tempFile.Write('2300060000001347713047                         WOUTER MINJAUW   ' +
          '         DENTERGEMSTRAAT 67        8780 OOSTROZEBEKE         000');
        tempFile.Write('2100070000ZFFP02096 TBOINDNLOON1000000000285200140207001010000/A' +
          '/ EXP SPLASH JAN FEB 07                            1402070300100');
        tempFile.Write('2200070000                                                     D' +
          'IV7022                      000000000000000                  100');
        tempFile.Write('2300070000290019346063                         DE CLERCQ JOHN   ' +
          '         BLEKTE 81                 9340 LEDE                 000');
        tempFile.Write('2100080000ZFFP02097 TBOINDNLOON100000000001050014020700101000110' +
          '1000060345518                                      1402070300100');
        tempFile.Write('2200080000                                                     D' +
          'IV7017                      000000000000000                  100');
        tempFile.Write('2300080000679205479140                         VOLMACHTEN       ' +
          '         MUNTCENTRUM               1000 BRUSSEL 1            000');
        tempFile.Write('2100090000ZFFP02098 TBOINDNLOON1000000015028010140207001010000FA' +
          'CT1865 1866 1867                                   1402070300100');
        tempFile.Write('2200090000                                                     6' +
          '1943 44                     000000000000000                  100');
        tempFile.Write('2300090000230056163828                         TRINSY TECHNICS  ' +
          '         ANTWERPSESTWG 120         2390 MALLE                000');
        tempFile.Write('2100100000ZFFP02099 TBOINDNLOON1000000000037080140207001010000FA' +
          'CT 111700303 112600758                             1402070300100');
        tempFile.Write('2200100000                                                     6' +
          '1916 70                     000000000000000                  100');
        tempFile.Write('2300100000290028356050                         BUYSSE WILLEMS GA' +
          'RAGE     JACQUES PARIJSLAAN 8      9940 EVERGEM              000');
        tempFile.Write('2100110000ZFFP02100 TBOINDNLOON1000000003598200140207001010000DI' +
          'V INV                                              1402070300100');
        tempFile.Write('2200110000                                                     6' +
          '1805 83                     000000000000000                  100');
        tempFile.Write('2300110000825601531087                         RUTRONIK         ' +
          '         INDUSTRIESTRASSE 2        7522 ISPRINGEN            000');
        tempFile.Write('2100120000ZFFP02101 TBOINDNLOON1000000000176620140207001010000FA' +
          'CT 576488 KL 014347                                1402070300100');
        tempFile.Write('2200120000                                                     6' +
          '1927                        000000000000000                  100');
        tempFile.Write('2300120000444961820157                         HANSSENS HOUT NV ' +
          '         PORT ARTHURLAAN 90        9000 GENT                 000');
        tempFile.Write('2100130000ZFFP02102 TBOINDNLOON1000000000562650140207001010000FA' +
          'CT 171144 KLANT 12032                              1402070300100');
        tempFile.Write('2200130000                                                     7' +
          '0090                        000000000000000                  100');
        tempFile.Write('2300130000685616301086                         NV FLUKE BELGIUM ' +
          '         LANGEVELDPARK UNIT7       1600 ST-PIETERS-LEE       000');
        tempFile.Write('2100140000ZFFP02103 TBOINDNLOON1000000000285310140207001010000FA' +
          'CT 0180688                                         1402070300100');
        tempFile.Write('2200140000                                                     6' +
          '1866                        000000000000000                  100');
        tempFile.Write('2300140000459250790127                         BINPAC           ' +
          '         IZ OOST, VRIJHEIDWEG 8    3700 TONGEREN             000');
        tempFile.Write('2100150000ZFFP02104 TBOINDNLOON1000000002860150140207001010000FA' +
          'CT 165279 280 161772 161896                        1402070300100');
        tempFile.Write('2200150000                                                     7' +
          '0092 87                     000000000000000                  100');
        tempFile.Write('2300150000443900193149                         CMAC             ' +
          '         IZ KL FRANKRIJK 28        9600 RONSE                000');
        tempFile.Write('2100160000ZFFP02105 TBOINDNLOON1000000001499400140207001010000BR' +
          'U0948706                                           1402070300100');
        tempFile.Write('2200160000                                                     7' +
          '0143                        000000000000000                  100');
        tempFile.Write('2300160000482910700226                         DHL              ' +
          '         POSTBUS 31                1831 DIEGEM               000');
        tempFile.Write('2100170000ZFFP02106 TBOINDNLOON1000000000092930140207001010000FA' +
          'CT614BE00972                                       1402070300100');
        tempFile.Write('2200170000                                                     6' +
          '1816                        000000000000000                  100');
        tempFile.Write('2300170000230099418451                         SEMIKRON         ' +
          '         LEUVENSESTEENWEG 510B9    1930 ZAVENTEM             000');
        tempFile.Write('2100180000ZFFP02107 TBOINDNLOON1000000000367840140207001010000FA' +
          'CT 70061248                                        1402070300100');
        tempFile.Write('2200180000                                                     6' +
          '1617                        000000000000000                  100');
        tempFile.Write('2300180000737427040422                         INTERCARE        ' +
          '         KORTE MAGERSTR 5          9050 GENTBRUGGE           000');
        tempFile.Write('2100190000ZFFP02108 TBOINDNLOON1000000000105390140207001010000FA' +
          'CT6069815                                          1402070300100');
        tempFile.Write('2200190000                                                     6' +
          '1921                        000000000000000                  100');
        tempFile.Write('2300190000230030914021                         VINK             ' +
          '         INDUSTRIEPARK 7           2220 HEIST-OP-DEN-B       000');
        tempFile.Write('2100200000ZFFP02109 TBOINDNLOON1000000000271800140207001010000FA' +
          'CT687804 685187 689218 695010 702325               1402070300100');
        tempFile.Write('2200200000                                                     7' +
          '0078 17                     000000000000000                  100');
        tempFile.Write('2300200000210049670015                         TNT              ' +
          '                                                             000');
        tempFile.Write('2100210000ZFFP02110 TBOINDNLOON1000000000623390140207001010000FA' +
          'CT 260620                                          1402070300100');
        tempFile.Write('2200210000                                                     6' +
          '1953                        000000000000000                  100');
        tempFile.Write('2300210000293021332779                         NOTEBAERT        ' +
          '         AALSTSTRAAT 6             9700 OUDENAARDE           000');
        tempFile.Write('2100220000ZFFP02111 TBOINDNLOON1000000003530760140207001010000FA' +
          'CT 28016690S01028                                  1402070300100');
        tempFile.Write('2200220000                                                     6' +
          '1751                        000000000000000                  100');
        tempFile.Write('2300220000285020504213                         BARCO KUURNE     ' +
          '         NOORDLAAN 5               8520 KUURNE               000');
        tempFile.Write('2100230000ZFFP02112 TBOINDNLOON1000000001116250140207001010000FA' +
          'CT F06121401                                       1402070300100');
        tempFile.Write('2200230000                                                     6' +
          '1911                        000000000000000                  100');
        tempFile.Write('2300230000063991768047                         CPE              ' +
          '         SCHEURBOEK 6A             9860 OOSTERZELE           000');
        tempFile.Write('2100240000ZFFP02113 TBOINDNLOON1000000003254900140207001010000FA' +
          'CT 7241730                                         1402070300100');
        tempFile.Write('2200240000                                                     7' +
          '0021                        000000000000000                  100');
        tempFile.Write('2300240000419706600164                         ECOMAL           ' +
          '         BATTelseSTWG 455E         2800 MECHELEN             000');
        tempFile.Write('2100250000ZFFP02114 TBOINDNLOON1000000000320650140207001010000FA' +
          'CT 23830                                           1402070300100');
        tempFile.Write('2200250000                                                     6' +
          '1886                        000000000000000                  100');
        tempFile.Write('2300250000320050648420                         PCB              ' +
          '         ELLERMANSTRAAT 74         2060 ANTWERPEN 6          000');
        tempFile.Write('2100260000ZFFP02115 TBOINDNLOON100000000092889014020700101000110' +
          '1000043806513                                      1402070300100');
        tempFile.Write('2200260000                                                     7' +
          '0100                        000000000000000                  100');
        tempFile.Write('2300260000435411161155                         PROXIMUS         ' +
          '         VOORTUIGANGSTRAAT 55      1210 BRUSSEL 21           000');
        tempFile.Write('2100270000ZFFP02116 TBOINDNLOON1000000003820840140207001010000FA' +
          'CT 111605534                                       1402070300100');
        tempFile.Write('2200270000                                                     6' +
          '1884                        000000000000000                  100');
        tempFile.Write('2300270000737502090534                         VANHOONACKER OUDE' +
          'NAARDE   WESTERING 31              9700 OUDENAARDE           000');
        tempFile.Write('2100280000OL9449950IUBOEUBTRFCS100000000070000013020734101000000' +
          '352037045A1181                                     1402070301100');
        tempFile.Write('2200280000                                                     7' +
          '0028                        000000000000000                  001');
        tempFile.Write('3100280001OL9449950IUBOEUBTRFCS341010001001VOGHT ELECTRONIC COMP' +
          'ONENT         VOGHT ELECTR PLATZ 1                           1 0');
        tempFile.Write('320028000194130 OBERNZELL DE                 DE                 ' +
          '                                                             0 1');
        tempFile.Write('3100280002OL9449950IUBOEUBTRFCS341010001002INV1038385           ' +
          '                                                             0 1');
        tempFile.Write('3100280003OL9449950IUBOEUBTRFCS341010001004COMMERZBANK AG       ' +
          '                                                             0 0');
        tempFile.Write('2100280004OL9449950IUBOEUBTRFCS100000000070000013020784101100110' +
          '5000000000700000000000000700000000100000000EUR     1402070301100');
        tempFile.Write('2200280004         000000000700000                              ' +
          '                            000000000000000                  000');
        tempFile.Write('2100290000OL9449951IUBOEUBTRFCS100000000024216013020734101000000' +
          '352037045A1180                                     1402070301100');
        tempFile.Write('2200290000                                                     3' +
          'INV                         000000000000000                  001');
        tempFile.Write('3100290001OL9449951IUBOEUBTRFCS341010001001DIGI KEY CORPORATION ' +
          '              PO BOX 52                                      1 0');
        tempFile.Write('32002900017500AB ENSCHEDE NL                 NL                 ' +
          '                                                             0 1');
        tempFile.Write('3100290002OL9449951IUBOEUBTRFCS341010001002INV22113733 2212     ' +
          '              3054 22123483                                  0 1');
        tempFile.Write('3100290003OL9449951IUBOEUBTRFCS341010001004LLOYDS TSB BANK PLC  ' +
          '                                                             0 0');
        tempFile.Write('2100290004OL9449951IUBOEUBTRFCS100000000024216013020784101100110' +
          '5000000000242160000000000242160000100000000EUR     1402070301100');
        tempFile.Write('2200290004         000000000242160                              ' +
          '                            000000000000000                  000');
        tempFile.Write('2100300000OL9449952IUBOEUBTRFCS100000000086000013020734101000000' +
          '352037045A1179                                     1402070301001');
        tempFile.Write('3100300001OL9449952IUBOEUBTRFCS341010001001BERGQUIST-ITC        ' +
          '              HADERSLEBENER STR. 19A                         1 0');
        tempFile.Write('320030000125421 PINNEBERG DE                 DE                 ' +
          '                                                             0 1');
        tempFile.Write('3100300002OL9449952IUBOEUBTRFCS341010001002INVOICE 94090        ' +
          '                                                             0 1');
        tempFile.Write('3100300003OL9449952IUBOEUBTRFCS341010001004DEUTSCHE BANK AG     ' +
          '                                                             0 0');
        tempFile.Write('2100300004OL9449952IUBOEUBTRFCS100000000086000013020784101100110' +
          '5000000000860000000000000860000000100000000EUR     1402070301100');
        tempFile.Write('2200300004         000000000860000                              ' +
          '                            000000000000000                  000');
        tempFile.Write('2100310000OL9449953IUBOEUBTRFCS100000000008150013020734101000000' +
          '352037045A1178                                     1402070301100');
        tempFile.Write('2200310000                                                     D' +
          'IV7014                      000000000000000                  001');
        tempFile.Write('3100310001OL9449953IUBOEUBTRFCS341010001001ABONNEMENTENLAND     ' +
          '              POSTBUS 20                                     1 0');
        tempFile.Write('32003100011910AA UITGEEST NL                 NL                 ' +
          '                                                             0 1');
        tempFile.Write('3100310002OL9449953IUBOEUBTRFCS341010001002FACTUUR 30370573     ' +
          '              KLANTNR 7682031                                0 1');
        tempFile.Write('3100310003OL9449953IUBOEUBTRFCS341010001004POSTBANK NV          ' +
          '                                                             0 0');
        tempFile.Write('2100310004OL9449953IUBOEUBTRFCS100000000008150013020784101100110' +
          '5000000000081500000000000081500000100000000EUR     1402070301100');
        tempFile.Write('2200310004         000000000081500                              ' +
          '                            000000000000000                  000');
        tempFile.Write('2100320000OL9449954IUBOEUBTRFCS100000000179300013020734101000000' +
          '352037045A1182                                     1402070301001');
        tempFile.Write('3100320001OL9449954IUBOEUBTRFCS341010001001ZUKEN BV             ' +
          '              SCHEPENLAAN 18A                                1 0');
        tempFile.Write('32003200016002EE WEERT NL                    NL                 ' +
          '                                                             0 1');
        tempFile.Write('3100320002OL9449954IUBOEUBTRFCS341010001002FACT ZNL100488       ' +
          '                                                             0 1');
        tempFile.Write('3100320003OL9449954IUBOEUBTRFCS341010001004ABN AMRO BANK NV     ' +
          '                                                             0 0');
        tempFile.Write('2100320004OL9449954IUBOEUBTRFCS100000000179300013020784101100110' +
          '5000000001793000000000001793000000100000000EUR     1402070301100');
        tempFile.Write('2200320004         000000001793000                              ' +
          '                            000000000000000                  000');
        tempFile.Write('8030737010689443 EUR0BE                  0000000237109580140207 ' +
          '                                                                ');
        tempFile.Write('9               000121000000052138710000000000000000            ' +
          '                                                               1');
        tempFile.Write('0000016020772505D  0000000074789  INVERTO NV                0000' +
          '000000000430018420 00000                                       1');
        tempFile.Write('1 031737010689443 EUR0BE                  0000000237109580150207' +
          'INVERTO NV                KBC-Bedrijfsrekening               001');
        tempFile.Write('2100010000AIBHA0AAN DOMNINDIN01100000000099810016020700501000110' +
          '7740784398863190207               0070142022      01602070310100');
        tempFile.Write('22000100000876383320                                            ' +
          '                            000000000000000                  100');
        tempFile.Write('2300010000000000000000                         D''IETEREN SERVICE' +
          'S                                                            000');
        tempFile.Write('2100020000AUBOA0CH4 DOMDCDDID01100000000003740016020700501000110' +
          '7740745036768190207F. 2007065205 DOMICIL.         01602070310100');
        tempFile.Write('22000200000455530509                                            ' +
          '                            000000000000000                  100');
        tempFile.Write('2300020000000000000000                         ISABEL           ' +
          '                                                             000');
        tempFile.Write('8031737010689443 EUR0BE                  0000000236074080160207 ' +
          '                                                                ');
        tempFile.Write('9               000008000000001035500000000000000000            ' +
          '                                                               1');
        tempFile.Write('0000019020772505D  0000000074789  INVERTO NV                0000' +
          '000000000430018420 00000                                       1');
        tempFile.Write('1 032737010689443 EUR0BE                  0000000236074080140207' +
          'INVERTO NV                KBC-Bedrijfsrekening               001');
        tempFile.Write('2100010000BJUA00109 TBOINDNLOON1000000001352480190207001010000ON' +
          'KOSTEN BELCOMP EN VDVIJVER                         1902070320100');
        tempFile.Write('2200010000                                                     D' +
          'IV ONKO                     000000000000000                  100');
        tempFile.Write('2300010000467538877123                         FIBECON BVBA     ' +
          '         MEERSBLOEM MELDEN 30      9700 OUDENAARDE           000');
        tempFile.Write('8032737010689443 EUR0BE                  0000000234721600190207 ' +
          '                                                                ');
        tempFile.Write('9               000005000000001352480000000000000000            ' +
          '                                                               1');
        tempFile.Write('0000020020772505D  0000000074789  INVERTO NV                0000' +
          '000000000430018420 00000                                       1');
        tempFile.Write('1 033737010689443 EUR0BE                  0000000234721600190207' +
          'INVERTO NV                KBC-Bedrijfsrekening               002');
        tempFile.Write('2100010000BNIVA0AMT DOMALGDOV01100000000039663020020700501000110' +
          '774071599264520020775560-LF-0  2584186   415775   02002070330100');
        tempFile.Write('22000100000426403684                                            ' +
          '                            000000000000000                  100');
        tempFile.Write('2300010000000000000000                         KBC LEASE BELGIUM' +
          '                                                             000');
        tempFile.Write('2100020000BOUJ01943 TBOINDNLOON100000001698636020020700101000110' +
          '1086444207901                                      2002070330100');
        tempFile.Write('2200020000                                                     A' +
          'ANSLJ 2                     000000000000000                  100');
        tempFile.Write('2300020000679200250133                         VENN BELAST      ' +
          '         G CROMMENLAAN 6 BUS 101   9050 LEDEBERG (GENT       000');
        tempFile.Write('2100030000BRLY08683BOVSBBNONTVA000000000030752020020700150000057' +
          '90131579 CREDITNOTA 010207                         2002070330100');
        tempFile.Write('2300030000000171003118                         Belgacom PO  NOOR' +
          'D        Stationsstraat, 58        2800 Mechelen             000');
        tempFile.Write('8033737010689443 EUR0BE                  0000000217646130200207 ' +
          '                                                                ');
        tempFile.Write('9               000010000000017382990000000000307520            ' +
          '                                                               2');
    end;

    local procedure WriteOntVangenCODA20090416(var tempFile: File)
    begin
        tempFile.Write('0000016040972505        00094905  MGH 2002 NV               KRED' +
          'BEBB   00477997984 00000                                       2');
        tempFile.Write('10070734020020001 EUR0BE                  0000000099198010150409' +
          'MGH 2002 NV               KBC-Business Comfortrekening       067');
        tempFile.Write('2100010000MLFQA0DMQ IKKINNINNIG1000000000519120160409313410000  ' +
          '            KBC-INVESTERINGSKREDIET 726-5361582-84 16040907011 0');
        tempFile.Write('2300010000726536158284                                          ' +
          '                                                             0 0');
        tempFile.Write('2100010001MLFQA0DMQ IKKINNINNIG1000000000510000160409813410660  ' +
          '                                                   16040907000 0');
        tempFile.Write('2100010002MLFQA0DMQ IKKINNINNIG1000000000009120160409813410020  ' +
          '                                                   16040907010 0');
        tempFile.Write('2100020000MLNF04958BOVSBBNONTVA0000000049956120160409001500000FA' +
          '  VF09-0053 + 0083 + 0086 + 0023                   16040907001 0');
        tempFile.Write('2300020000551292970078                         SONAC GENT N V   ' +
          '                                                             0 1');
        tempFile.Write('3100020001MLNF04958BOVSBBNONTVA001500001001SONAC GENT N V       ' +
          '                                                             1 0');
        tempFile.Write('3200020001BRAAMTWEG                2         9042   MENDONK     ' +
          '                                                             0 0');
        tempFile.Write('2100030000MMASA0AKW DOMALGDOV01100000000049197016040900501000110' +
          '7740831711120160409KF09144333  3682144   464573   016040907001 0');
        tempFile.Write('22000300000426403684                                            ' +
          '                                                             1 0');
        tempFile.Write('2300030000                                     KBC LEASE BELGIUM' +
          '                                                             0 1');
        tempFile.Write('3100030001MMASA0AKW DOMALGDOV01005010001001KBC LEASE BELGIUM    ' +
          '                                                             0 0');
        tempFile.Write('2100040000MQSZ03583LKKTOVSOVKUG100000000044115016040900403000112' +
          '45526145493809534    1097                          16040907001 0');
        tempFile.Write('2300040000666000000483                                          ' +
          '                                                             0 0');
        tempFile.Write('2100050000MSSF04942 TBOINDNLOON100000003950213016040900101000110' +
          '1047799798426                                      16040907001 0');
        tempFile.Write('2300050000679200300047                         BTW ONTVANGSTEN  ' +
          '                                                             0 1');
        tempFile.Write('3100050001MSSF04942 TBOINDNLOON001010001001BTW ONTVANGSTEN      ' +
          '                                                             1 0');
        tempFile.Write('3200050001                                          BRUSSEL     ' +
          '                                                             0 0');
        tempFile.Write('2100060000MSSF04943 TBOINDNLOON1000000000250000160409001010000  ' +
          '                                                   16040907001 0');
        tempFile.Write('2300060000293003907034                         IME- VRIENDENKRIN' +
          'G                                                            0 1');
        tempFile.Write('3100060001MSSF04943 TBOINDNLOON001010001001IME- VRIENDENKRING   ' +
          '                                                             1 0');
        tempFile.Write('3200060001KON. ASTRIDLAAN 14                 2830   WILLEBROEK  ' +
          '                                                             0 0');
        tempFile.Write('2100070000MUKH00749 BHKDGLDTBNL1000000036218470160409101070000  ' +
          '                                                   16040907010 0');
        tempFile.Write('2100070001MTWT00001 TBOGOVOVERS100000000081238016040950107000110' +
          '1520142058864                                      16040907001 0');
        tempFile.Write('2300070001000013190077                         ELECTRABEL C/O   ' +
          '                                                             0 1');
        tempFile.Write('3100070002MTWT00001 TBOGOVOVERS501070001001ELECTRABEL C/O       ' +
          '                                                             1 0');
        tempFile.Write('3200070002FRANKLIN ROOSEVELTLAAN 1           9000   GENT        ' +
          '                                                             0 0');
        tempFile.Write('2100070003MTWT00002 TBOGOVOVERS100000000084702016040950107000110' +
          '1550051894888                                      16040907001 0');
        tempFile.Write('2300070003000013190077                         ELECTRABEL C/O   ' +
          '                                                             0 1');
        tempFile.Write('3100070004MTWT00002 TBOGOVOVERS501070001001ELECTRABEL C/O       ' +
          '                                                             1 0');
        tempFile.Write('3200070004FRANKLIN ROOSEVELTLAAN 1           9000   GENT        ' +
          '                                                             0 0');
        tempFile.Write('2100070005MTWT00003 TBOGOVOVERS100000000029899016040950107000110' +
          '1093030330570                                      16040907001 0');
        tempFile.Write('2300070005230014660053                         PREMED VZW       ' +
          '                                                             0 1');
        tempFile.Write('3100070006MTWT00003 TBOGOVOVERS501070001001PREMED VZW           ' +
          '                                                             1 0');
        tempFile.Write('3200070006TIENSEVEST 61 BUS 2                3010   KESSEL-LO (L' +
          'EU                                                           0 0');
        tempFile.Write('2100070007MTWT00004 TBOGOVOVERS100000000004291016040950107000110' +
          '1033504946620                                      16040907001 0');
        tempFile.Write('2300070007405050461148                         TELENET NV       ' +
          '                                                             0 1');
        tempFile.Write('3100070008MTWT00004 TBOGOVOVERS501070001001TELENET NV           ' +
          '                                                             1 0');
        tempFile.Write('3200070008LIERSESTWG 4                       2800   MECHELEN    ' +
          '                                                             0 0');
        tempFile.Write('2100070009MTWT00005 TBOGOVOVERS100000000287254016040950107000110' +
          '1110129030024                                      16040907001 0');
        tempFile.Write('2300070009452920385120                         FISCO-CONSULT BVB' +
          'A                                                            0 1');
        tempFile.Write('3100070010MTWT00005 TBOGOVOVERS501070001001FISCO-CONSULT BVBA   ' +
          '                                                             1 0');
        tempFile.Write('3200070010KAUTERSHOEK 21 BUS1                3290   DIEST       ' +
          '                                                             0 0');
        tempFile.Write('2100070011MTWT00006 TBOGOVOVERS1000000000464410160409501070000V1' +
          '/40900695                                          16040907001 0');
        tempFile.Write('2300070011001412713050                         OFFICE PLUS NV   ' +
          '                                                             0 1');
        tempFile.Write('3100070012MTWT00006 TBOGOVOVERS501070001001OFFICE PLUS NV       ' +
          '                                                             1 0');
        tempFile.Write('3200070012HENRY FORDLAAN 18                  3600   GENK        ' +
          '                                                             0 0');
        tempFile.Write('2100070013MTWT00007 TBOGOVOVERS100000000044891016040950107000020' +
          '0900199                                            16040907001 0');
        tempFile.Write('2300070013068235204819                         SRT GROUP SPRL TR' +
          'ANSPORT A                                                    0 1');
        tempFile.Write('3100070014MTWT00007 TBOGOVOVERS501070001001SRT GROUP SPRL TRANSP' +
          'ORT A                                                        1 0');
        tempFile.Write('3200070014NIEUWBRUGSTRAAT 71                 1830   MACHELEN (BT' +
          '.)                                                           0 0');
        tempFile.Write('2100070015MTWT00008 TBOGOVOVERS100000000020570016040950107000090' +
          '084                                                16040907001 0');
        tempFile.Write('2300070015103010290051                         MEA              ' +
          '                                                             0 1');
        tempFile.Write('3100070016MTWT00008 TBOGOVOVERS501070001001MEA                  ' +
          '                                                             1 0');
        tempFile.Write('3200070016KRAANKINDERSSTRAAT 3-7             9000   GENT        ' +
          '                                                             0 0');
        tempFile.Write('2100070017MTWT00009 TBOGOVOVERS100000000542107016040950107000091' +
          '0051478                                            16040907001 0');
        tempFile.Write('2300070017210052380052                         SEW CARON-VECTOR ' +
          ' SA                                                          0 1');
        tempFile.Write('3100070018MTWT00009 TBOGOVOVERS501070001001SEW CARON-VECTOR  SA ' +
          '                                                             1 0');
        tempFile.Write('3200070018AV. EIFFEL 5                       1300   WAVRE       ' +
          '                                                             0 0');
        tempFile.Write('2100070019MTWT00010 TBOGOVOVERS100000000137692016040950107000000' +
          '1737                                               16040907001 0');
        tempFile.Write('2300070019210081374059                         SAFETY-KLEEN BELG' +
          'IUM SA                                                       0 1');
        tempFile.Write('3100070020MTWT00010 TBOGOVOVERS501070001001SAFETY-KLEEN BELGIUM ' +
          'SA                                                           1 0');
        tempFile.Write('3200070020INDUSTRIELAAN 130                  1070   ANDERLECHT  ' +
          '                                                             0 0');
        tempFile.Write('2100070021MTWT00011 TBOGOVOVERS100000000012289016040950107000001' +
          '0/29014893                                         16040907001 0');
        tempFile.Write('2300070021220004005732                         ROMBOUTS         ' +
          '                                                             0 1');
        tempFile.Write('3100070022MTWT00011 TBOGOVOVERS501070001001ROMBOUTS             ' +
          '                                                             1 0');
        tempFile.Write('3200070022ANTWERPSESTEENWEG 136              2630   AARTSELAAR  ' +
          '                                                             0 0');
        tempFile.Write('2100070023MTWT00012 TBOGOVOVERS100000000009099016040950107000086' +
          '00385276                                           16040907001 0');
        tempFile.Write('2300070023271001598815                         MEWA SERVIBEL NV ' +
          '                                                             0 1');
        tempFile.Write('3100070024MTWT00012 TBOGOVOVERS501070001001MEWA SERVIBEL NV     ' +
          '                                                             1 0');
        tempFile.Write('3200070024MOTSTRAAT 54                       2800   MECHELEN    ' +
          '                                                             0 0');
        tempFile.Write('2100070025MTWT00013 TBOGOVOVERS100000000086288016040950107000000' +
          '090808                                             16040907001 0');
        tempFile.Write('2300070025293018439048                         TRANSMO NV       ' +
          '                                                             0 1');
        tempFile.Write('3100070026MTWT00013 TBOGOVOVERS501070001001TRANSMO NV           ' +
          '                                                             1 0');
        tempFile.Write('3200070026PEDRO COLOMALAAN 9                 2880   BORNEM      ' +
          '                                                             0 0');
        tempFile.Write('2100070027MTWT00014 TBOGOVOVERS100000000235950016040950107000090' +
          '030 90031 90032 90033                              16040907001 0');
        tempFile.Write('2300070027310068982951                         WOODTOOLS - INTER' +
          'PROFIEL                                                      0 1');
        tempFile.Write('3100070028MTWT00014 TBOGOVOVERS501070001001WOODTOOLS - INTERPROF' +
          'IEL                                                          1 0');
        tempFile.Write('3200070028PEUTIESESTEENWEG 120               1830   MACHELEN    ' +
          '                                                             0 0');
        tempFile.Write('2100070029MTWT00015 TBOGOVOVERS100000000031952016040950107000042' +
          '006009 MRT/09                                      16040907001 0');
        tempFile.Write('2300070029310100270097                         DKV BELGIUM NV   ' +
          '                                                             0 1');
        tempFile.Write('3100070030MTWT00015 TBOGOVOVERS501070001001DKV BELGIUM NV       ' +
          '                                                             1 0');
        tempFile.Write('3200070030BD BISCHOFFSHEIMLAAN 1-8           1000   BRUSSEL     ' +
          '                                                             0 0');
        tempFile.Write('2100070031MTWT00016 TBOGOVOVERS1000000000572330160409501070000FZ' +
          '2900524                                            16040907001 0');
        tempFile.Write('2300070031310180545075                         OKA.BE           ' +
          '                                                             0 1');
        tempFile.Write('3100070032MTWT00016 TBOGOVOVERS501070001001OKA.BE               ' +
          '                                                             1 0');
        tempFile.Write('3200070032MAALBEEKWEG 8                      1930   ZAVENTEM    ' +
          '                                                             0 0');
        tempFile.Write('2100070033MTWT00017 TBOGOVOVERS100000000039348016040950107000041' +
          '2-200904.23100004                                  16040907001 0');
        tempFile.Write('2300070033330025371921                         GYKIERE BVBA GARA' +
          'GE CITRO‰                                                    0 1');
        tempFile.Write('3100070034MTWT00017 TBOGOVOVERS501070001001GYKIERE BVBA GARAGE C' +
          'ITRO‰                                                        1 0');
        tempFile.Write('3200070034PERKSESTEENWEG 21 K                1820   MELSBROEK   ' +
          '                                                             0 0');
        tempFile.Write('2100070035MTWT00018 TBOGOVOVERS100000000003436016040950107000027' +
          '04904/00018                                        16040907001 0');
        tempFile.Write('2300070035335002828406                         CARGLASS         ' +
          '                                                             0 1');
        tempFile.Write('3100070036MTWT00018 TBOGOVOVERS501070001001CARGLASS             ' +
          '                                                             1 0');
        tempFile.Write('3200070036MECHelseSTEENWEG 289 TOTAA         1800   VILVOORDE   ' +
          '                                                             0 0');
        tempFile.Write('2100070037MTWT00019 TBOGOVOVERS100000000037740016040950107000090' +
          '1711 901966                                        16040907001 0');
        tempFile.Write('2300070037363003860135                         TRABELINT        ' +
          '                                                             0 1');
        tempFile.Write('3100070038MTWT00019 TBOGOVOVERS501070001001TRABELINT            ' +
          '                                                             1 0');
        tempFile.Write('3200070038BRUCARGO 750                       1931   BRUCARGO ZAV' +
          'EN                                                           0 0');
        tempFile.Write('2100070039MTWT00020 TBOGOVOVERS100000001257536016040950107000009' +
          '004800 09004801 09004802 09004803 09004804 0900480516040907001 0');
        tempFile.Write('2200070039 09004806 09004807 09004808 09004809 09004810 ... ... ' +
          '                                                             1 0');
        tempFile.Write('2300070039414004622185                         MANO             ' +
          '                                                             0 1');
        tempFile.Write('3100070040MTWT00020 TBOGOVOVERS501070001001MANO                 ' +
          '                                                             1 0');
        tempFile.Write('3200070040JUBELLAAN 78                       2800   MECHELEN    ' +
          '                                                             0 0');
        tempFile.Write('2100070041MTWT00021 TBOGOVOVERS100000000114648016040950107000024' +
          '0598                                               16040907001 0');
        tempFile.Write('2300070041450054900137                         ACTIEF INTERIM   ' +
          '                                                             0 1');
        tempFile.Write('3100070042MTWT00021 TBOGOVOVERS501070001001ACTIEF INTERIM       ' +
          '                                                             1 0');
        tempFile.Write('3200070042J.B. NOW‚LEI 28                    1800   VILVOORDE   ' +
          '                                                             0 0');
        tempFile.Write('2100070043MTWT00022 TBOGOVOVERS1000000000344850160409501070000F0' +
          '9/020333                                           16040907001 0');
        tempFile.Write('2300070043453717465139                         TRIUS N.V. ICT SO' +
          'LUTIONS                                                      0 1');
        tempFile.Write('3100070044MTWT00022 TBOGOVOVERS501070001001TRIUS N.V. ICT SOLUTI' +
          'ONS                                                          1 0');
        tempFile.Write('3200070044HENRY FORDLAAN 18                  3600   GENK        ' +
          '                                                             0 0');
        tempFile.Write('2100070045MTWT00023 TBOGOVOVERS100000000037090016040950107000029' +
          '2437                                               16040907001 0');
        tempFile.Write('2300070045464111058181                         PRECISA MOTOREN N' +
          '.V.                                                          0 1');
        tempFile.Write('3100070046MTWT00023 TBOGOVOVERS501070001001PRECISA MOTOREN N.V. ' +
          '                                                             1 0');
        tempFile.Write('3200070046NOORDSTRAAT 14                     8560   MOORSELE    ' +
          '                                                             0 0');
        tempFile.Write('2100070047MTWT00024 TBOGOVOVERS1000000000140610160409501070000H7' +
          '3574/F72827                                        16040907001 0');
        tempFile.Write('2300070047466715460186                         VAN MARCKE       ' +
          '                                                             0 1');
        tempFile.Write('3100070048MTWT00024 TBOGOVOVERS501070001001VAN MARCKE           ' +
          '                                                             1 0');
        tempFile.Write('3200070048MECHelseSTEENWEG 287               1800   VILVOORDE   ' +
          '                                                             0 0');
        tempFile.Write('2100070049MTWT00025 TBOGOVOVERS100000000004334016040950107000020' +
          '09475430 2009483363                                16040907001 0');
        tempFile.Write('2300070049720520419762                         UPS              ' +
          '                                                             0 1');
        tempFile.Write('3100070050MTWT00025 TBOGOVOVERS501070001001UPS                  ' +
          '                                                             1 0');
        tempFile.Write('3200070050WOLUWELAAN 156                     1831   DIEGEM      ' +
          '                                                             0 0');
        tempFile.Write('2100070051MTWT00026 TBOGOVOVERS100000000207520016040950107000009' +
          '0308                                               16040907001 0');
        tempFile.Write('2300070051733054566065                         BRANDMARK        ' +
          '                                                             0 1');
        tempFile.Write('3100070052MTWT00026 TBOGOVOVERS501070001001BRANDMARK            ' +
          '                                                             1 0');
        tempFile.Write('3200070052PANNENHUISSTRAAT 359               2500   LIER        ' +
          '                                                             0 0');
        tempFile.Write('2100070053MTWT00027 TBOGOVOVERS100000000159753016040950107000062' +
          '1372280 19-04                                      16040907011 0');
        tempFile.Write('2300070053860080627691                         AXA BELGIUM NV   ' +
          '                                                             0 1');
        tempFile.Write('3100070054MTWT00027 TBOGOVOVERS501070001001AXA BELGIUM NV       ' +
          '                                                             1 0');
        tempFile.Write('3200070054SINTE VEERLEDREEF 1                1820   STEENOKKERZE' +
          'EL                                                           0 0');
        tempFile.Write('2100080000MWKM00651 BHKDGLDOUBO1000000014959870150409241010000  ' +
          '                                                   16040907010 0');
        tempFile.Write('2100080001MVYVA0AY3BSCTOBBUBVFF100000000169500015040960101000043' +
          '573706                                             16040907001 0');
        tempFile.Write('2200080001                                                      ' +
          '                                  NDEAFIHH                   1 0');
        tempFile.Write('2300080001FI1022901800127402                   VEM MOTORS FINLAN' +
          'D OY                                                         0 1');
        tempFile.Write('3100080002MVYVA0AY3BSCTOBBUBVFF601010001001VEM MOTORS FINLAND OY' +
          '                                                             1 0');
        tempFile.Write('3200080002KEH.NREUNA 4                                          ' +
          '                                                             0 0');
        tempFile.Write('2100080003MVYVA0AY4BSCTOBBUBVFF1000000012936320150409601010000F0' +
          '901097                                             16040907001 0');
        tempFile.Write('2200080003                                                      ' +
          '                                  CCBPFRPPLIL                1 0');
        tempFile.Write('2300080003FR7613507001651441331210901          NT TRANSMISSIONS ' +
          '                                                             0 1');
        tempFile.Write('3100080004MVYVA0AY4BSCTOBBUBVFF601010001001NT TRANSMISSIONS     ' +
          '                                                             1 0');
        tempFile.Write('3200080004Z.I. PLACE GUTENBERG                                  ' +
          '                                                             0 0');
        tempFile.Write('2100080005MVYVA0AY5BSCTOBBUBVFF100000000032855015040960101000084' +
          '596                                                16040907011 0');
        tempFile.Write('2200080005                                                      ' +
          '                                  BNPAFRPPCNA                1 0');
        tempFile.Write('2300080005FR7630004004160001002239136          PTP INDUSTRY SAS ' +
          '                                                             0 1');
        tempFile.Write('3100080006MVYVA0AY5BSCTOBBUBVFF601010001001PTP INDUSTRY SAS     ' +
          '                                                             1 0');
        tempFile.Write('3200080006LA BELLE ORGE                                         ' +
          '                                                             0 0');
        tempFile.Write('8070734020020001 EUR0BE                  0000000056771420160409 ' +
          '                                                               0');
        tempFile.Write('9               000150000000092382710000000049956120            ' +
          '                                                               2');
    end;

    local procedure WriteOntVangenCODAScenario373926(var tempFile: File)
    begin
        tempFile.Write('0000010092072505        00503659  HERMANS  JOHAN            KRED' +
          'BEBB   00820877643 00000                                       2');
        tempFile.Write('10157734028222864 EUR0BE                  0000000048168530080920C & F HERMANS' +
          ' BV          KBC-Business Comfortrekening       157');
        tempFile.Write('2100010000HEPW03654 TK4TBNINNIG1000000000837630100920313010000Terugbetaling' +
          '    420-3332395-64                      10092015711 0');
        tempFile.Write('2300010000420333239564                                                     ' +
          '                                                  0 0');
        tempFile.Write('2100010001HEPW03654 TK4TBNINNIG1000000000832340100920813010550' +
          '                                                     10092015700 0');
        tempFile.Write('2100010002HEPW03654 TK4TBNINNIG1000000000005290100920813010020' +
          '                                                     10092015710 0');
        tempFile.Write('2100020000HGJT40426 SDDBDTBDREC1000000000078930100920005010001' +
          '127100920110BE65ZZZ0403063902                  BEB20010092015701 0');
        tempFile.Write('22000200000000400-7606481-71           I 0717945808 R B0880966' +
          ' I0000016740433-110407179458082020  GEBABEBB                   1 0');
        tempFile.Write('2300020000BE62210047007161                     TOTAL BELGIUM' +
          '                      //20200908-BEDO1                      0    0 1');
        tempFile.Write('3100020001HGJT40426 SDDBDTBDREC005010001001TOTAL BELGIUM' +
          '                                                                     1 0');
        tempFile.Write('3200020001                                              ' +
          '                        BE65ZZZ0403063902                            0 0');
        tempFile.Write('2100030000HOUY01870 BKTUBBBECPG1000000000001500100920304' +
          '0200011136703420000000801251289904056009092012195IKEA ZAVEN10092015711 0');
        tempFile.Write('2200030000TEM-FOZAVENTEM  000000000001500000100000000EUR0000000' +
          '                                                              1 0');
        tempFile.Write('2300030000                                                     ' +
          '                   00000                                      0 0');
        tempFile.Write('2100030001HOUY01870 BKTUBBBECPG1000000000001500100920804021000' +
          '                                                     10092015710 0');
        tempFile.Write('2100040000HOUY01871 BKTUBBBECPG1000000000000300100920304020001' +
          '1136703420000000801231948304165809092012205MERA CLAEY10092015711 0');
        tempFile.Write('2200040000S BVBARUDDERVOOR000000000000300000100000000EUR0000000' +
          '                                                              1 0');
        tempFile.Write('2300040000                                                     ' +
          '                   00000                                      0 0');
        tempFile.Write('2100040001HOUY01871 BKTUBBBECPG1000000000000300100920804021000' +
          '                                                     10092015710 0');
        tempFile.Write('8157734028222864 EUR0BE                  0000000047250170100920' +
          '                                                                0');

        tempFile.Write('9               000019000000000918360000000000000000' +
          '                                                                           2');
    end;

    local procedure WriteCODA1MultipleA(var tempFile: File)
    begin
        tempFile.Write('0000002010729005D  0000000074789  INVERTO NV                0000' +
          '000000000058315707 00000                                       1');
        tempFile.Write('1 001290004614187 EUR0BE                  0000000291493520291206' +
          'INVERTO NV                KBC-Bedrijfsrekening               001');
        tempFile.Write('2100010000HIRQA1H6L BKTKOSKOKFG1000000000020000010107303370000Aa' +
          'nrekening kaartbijdrage   5526 1454 7849 0607      0201070011000');
        tempFile.Write('2100010001HIRQA1H6L BKTKOSKOKFG1000000000020000010107803370060  ' +
          '                                                   0201070011000');
        tempFile.Write('2100020000HIWC00001 CKZKOSKOSBK1000000000018700020107013370000  ' +
          '  COMMERCIELE KREDIETZAAK MET REFERTE      727-64440201070010100');
        tempFile.Write('2200020000961-49                                                ' +
          '                            000000000000000                  000');
        tempFile.Write('2100030000OL9426419JBBOEUBCRECL000000000799200003010734150000000' +
          '352037002A3545                                     0201070011100');
        tempFile.Write('2200030000                                                     4' +
          '550-63629896326             000000000000000                  001');
        tempFile.Write('3100030001OL9426419JBBOEUBCRECL341500001001ROSTI POLSKA SP. Z.O.' +
          'O.            Elewatorska 29                                 1 0');
        tempFile.Write('320003000115-620  Bia ystok                                     ' +
          '                                                             0 1');
        tempFile.Write('3100030002OL9426419JBBOEUBCRECL341500001002INVOIC               ' +
          '                                                             0 0');
        tempFile.Write('2100030003OL9426419JBBOEUBCRECL000000000799200003010784150100110' +
          '5000000007992000000000007992000000100000000EUR     0201070011100');
        tempFile.Write('2200030003         000000007992000                              ' +
          '                            000000000000000                  000');
        tempFile.Write('2100040000HNOA00002BTBOGOVOVERS000000000151250002010700150000062' +
          '91                                                 0201070010100');
        tempFile.Write('2300040000472302320181                         TEAM LASERPRESS N' +
          'V        JACQUES PARYSLAAN 8       9940 EVERGEM              000');
        tempFile.Write('2100050000HOUP00283BTBOINDNLOON0000000001024930020107001500000FT' +
          ' 6314                                              0201070010100');
        tempFile.Write('2300050000738010356689                         EVILO NV         ' +
          '         SCHELDESTRAAT 35 A        8553 OTEGEM               000');
        tempFile.Write('2100060000OL9447899JBBNEUBCRCL1000000003378098003010734150000000' +
          '352037002C0877                                     0201070011001');
        tempFile.Write('3100060001OL9447899JBBNEUBCRCL1341500001001SPLASHPOWER LTD      ' +
          '              3110001                                        1 0');
        tempFile.Write('320006000129                                                    ' +
          '                                                             0 1');
        tempFile.Write('3100060002OL9447899JBBNEUBCRCL1341500001002INV 6320             ' +
          '                                                             0 0');
        tempFile.Write('2100060003OL9447899JBBNEUBCRCL1000000003378098003010784150100110' +
          '5000000033780980000000033780980000100000000EUR     0201070011100');
        tempFile.Write('2200060003         000000033780980                              ' +
          '                            000000000000000                  000');
        tempFile.Write('8001290004614187 EUR0BE                  0000000335765230020107 ' +
          '                                                                ');
        tempFile.Write('9               000023000000000038700000000044310410            ' +
          '                                                               1');
        tempFile.Write('0000003010729005D  0000000074789  INVERTO NV                0000' +
          '000000000058315707 00000                                       1');
        tempFile.Write('1 002290004614187 EUR0BE                  0000000335765230020107' +
          'INVERTO NV                KBC-Bedrijfsrekening               001');
        tempFile.Write('2100010000OL9460983JBBOEUBCRECL000000002220652004010734150000000' +
          '352037003A7683                                     0301070021100');
        tempFile.Write('2200010000                                                     T' +
          '47A70102AU78                000000000000000                  001');
        tempFile.Write('3100010001OL9460983JBBOEUBCRECL341500001001STECA BATTERIELADESYS' +
          'TEME UND      PRAEZISIONSELEKTRONIK GMBH                     1 0');
        tempFile.Write('3200010001MAMMOSTRASSE 1                     87700 MEMMINGEN    ' +
          '                                                             0 1');
        tempFile.Write('3100010002OL9460983JBBOEUBCRECL341500001002INV. 6318 / 30.11.200' +
          '6             INV. 6315 / 24.11.2006                         1 0');
        tempFile.Write('3200010002./. BELASTUNG 17004039 / 19.12.2006                   ' +
          '                                                             0 0');
        tempFile.Write('2100010003OL9460983JBBOEUBCRECL000000002220652004010784150100110' +
          '5000000022206520000000022206520000100000000EUR     0301070021100');
        tempFile.Write('2200010003         000000022206520                              ' +
          '                            000000000000000                  000');
        tempFile.Write('8002290004614187 EUR0BE                  0000000357971750030107 ' +
          '                                                                ');
        tempFile.Write('9               000010000000000000000000000022206520            ' +
          '                                                               1');
        tempFile.Write('0000005010729005D  0000000074789  INVERTO NV                0000' +
          '000000000058315707 00000                                       1');
        tempFile.Write('1 003290004614187 EUR0BE                  0000000357971750040107' +
          'INVERTO NV                KBC-Bedrijfsrekening               001');
        tempFile.Write('2100010000JCRL02237 TBOINDNLOON1000000013310000050107001010000FA' +
          'CT ST06012                                         0501070030100');
        tempFile.Write('2200010000                                                     6' +
          '/1900                       000000000000000                  100');
        tempFile.Write('2300010000737016385868                         STEREYO          ' +
          '         ZONNESTR 7                9810 NAZARETH             000');
        tempFile.Write('8003290004614187 EUR0BE                  0000000344661750050107 ' +
          '                                                                ');
        tempFile.Write('9               000005000000013310000000000000000000            ' +
          '                                                               1');
        tempFile.Write('0000008010729005D  0000000074789  INVERTO NV                0000' +
          '000000000058315707 00000                                       1');
        tempFile.Write('1 004290004614187 EUR0BE                  0000000344661750050107' +
          'INVERTO NV                KBC-Bedrijfsrekening               001');
        tempFile.Write('2100010000JQQJA0CUQ IKLINNINNIG1000000003670020060107313410000  ' +
          '            INVESTERINGSKREDIET     726-3754303-95 0801070041000');
        tempFile.Write('2100010001JQQJA0CUQ IKLINNINNIG1000000003333330060107813410660  ' +
          '                                                   0801070040000');
        tempFile.Write('2100010002JQQJA0CUQ IKLINNINNIG1000000000336690060107813410020  ' +
          '                                                   0801070041000');
        tempFile.Write('2100020000OL9441847JBBNEUNCRCL1000000005292465008010734150000000' +
          '352037008A2593                                     0801070041001');
        tempFile.Write('3100020001OL9441847JBBNEUNCRCL1341500001001PHILIPS LIGHTING BV  ' +
          '              P.O. BOX 1                                     1 0');
        tempFile.Write('3200020001BUILDING AA                        OSS                ' +
          '                                                             0 1');
        tempFile.Write('3100020002OL9441847JBBNEUNCRCL13415000010026710280720000130 6306' +
          ' 6309 6311                                                   0 0');
        tempFile.Write('2100020003OL9441847JBBNEUNCRCL1000000005292465008010784150100110' +
          '5000000052924650000000052924650000100000000EUR     0801070041100');
        tempFile.Write('2200020003         000000052924650                              ' +
          '                            000000000000000                  000');
        tempFile.Write('2100030000OL9441848KBBNKOSDIVKS100000000001089008010734137000000' +
          '352037008A2593                                     0801070041000');
        tempFile.Write('2100030001OL9441848KBBNKOSDIVKS1000000000009000080107841370130  ' +
          '                                                   0801070040000');
        tempFile.Write('2100030002OL9441848KBBNKOSDIVKS100000000000189008010784137011110' +
          '6000000000001890000000000009000002100000000200000000801070041100');
        tempFile.Write('220003000200001890                                              ' +
          '                            000000000000000                  000');
        tempFile.Write('2100040000KBIS00253 TBOINDNLOON100000000304899008010700101000110' +
          '1006000522050                                      0801070040100');
        tempFile.Write('2200040000                                                     6' +
          '1823                        000000000000000                  100');
        tempFile.Write('2300040000828998553034                         HERBERIGS SPRL   ' +
          '         WIJNGAARDSTRAAT 5         9700 OUDENAARDE           000');
        tempFile.Write('2100050000KBIS00254 TBOINDNLOON100000000001479008010700101000110' +
          '1006000523969                                      0801070040100');
        tempFile.Write('2200050000                                                     6' +
          '1867                        000000000000000                  100');
        tempFile.Write('2300050000828998553034                         HERBERIGS SPRL   ' +
          '         WIJNGAARDSTRAAT 5         9700 OUDENAARDE           000');
        tempFile.Write('2100060000KBIS00255 TBOINDNLOON100000000360973008010700101000110' +
          '1007000047537                                      0801070040100');
        tempFile.Write('2200060000                                                     6' +
          '/1941                       000000000000000                  100');
        tempFile.Write('2300060000828998553034                         HERBERIGS SPRL   ' +
          '         WIJNGAARDSTRAAT 5         9700 OUDENAARDE           000');
        tempFile.Write('8004290004614187 EUR0BE                  0000000387231980080107 ' +
          '                                                                ');
        tempFile.Write('9               000024000000010354420000000052924650            ' +
          '                                                               1');
        tempFile.Write('0000009010729005D  0000000074789  INVERTO NV                0000' +
          '000000000058315707 00000                                       1');
        tempFile.Write('1 005290004614187 EUR0BE                  0000000387231980080107' +
          'INVERTO NV                KBC-Bedrijfsrekening               001');
        tempFile.Write('2100010000KFXWA0BSQ IKLINNINNIG1000000000991820090107313410000  ' +
          '            INVESTERINGSKREDIET     726-2764912-07 0901070051000');
        tempFile.Write('2100010001KFXWA0BSQ IKLINNINNIG1000000000947310090107813410660  ' +
          '                                                   0901070050000');
        tempFile.Write('2100010002KFXWA0BSQ IKLINNINNIG1000000000044510090107813410020  ' +
          '                                                   0901070051000');
        tempFile.Write('2100020000KGNAA0ANJ DOMALGDOV01100000000070164009010700501000110' +
          '774071599264509010774422-LF-0  2532992   413664   00901070050100');
        tempFile.Write('22000200000426403684                                            ' +
          '                            000000000000000                  100');
        tempFile.Write('2300020000000000000000                         KBC LEASE BELGIUM' +
          '                                                             000');
        tempFile.Write('2100030000KHMC01793 TBOINDNLOON1000000000553560090107001010000IN' +
          'V 7006237 RI KLNR 92164                            0901070050100');
        tempFile.Write('2200030000                                                     6' +
          '1695                        000000000000000                  100');
        tempFile.Write('2300030000437751551186                         ACAL             ' +
          '         LOZENBERG 4               1932 ZAVENTEM             000');
        tempFile.Write('2100040000KHMC01794 TBOINDNLOON1000000000209570090107001010000FA' +
          'CT2070004583                                       0901070050100');
        tempFile.Write('2200040000                                                     6' +
          '1744                        000000000000000                  100');
        tempFile.Write('2300040000390041400059                         AIR COMPACT BELGI' +
          'UM NV    BRUSSelseSTWG 427         9050 LEDEBERG (GENT       000');
        tempFile.Write('2100050000KHMC01795 TBOINDNLOON100000000011173009010700101000009' +
          '0059 2000 06006310                                 0901070050100');
        tempFile.Write('2200050000                                                     6' +
          '/1575                       000000000000000                  100');
        tempFile.Write('2300050000293018003760                         ATEM             ' +
          '         BEDRIJVENPARK DE VEERT 4  2830 WILLEBROEK           000');
        tempFile.Write('2100060000KHMC01796 TBOINDNLOON100000000010682009010700101000009' +
          '0059 2000 06006658                                 0901070050100');
        tempFile.Write('2200060000                                                     6' +
          '/1615                       000000000000000                  100');
        tempFile.Write('2300060000293018003760                         ATEM             ' +
          '         BEDRIJVENPARK DE VEERT 4  2830 WILLEBROEK           000');
        tempFile.Write('2100070000KHMC01797 TBOINDNLOON100000000015277009010700101000110' +
          '1200601108664                                      0901070050100');
        tempFile.Write('2200070000                                                     6' +
          '1668                        000000000000000                  100');
        tempFile.Write('2300070000220057681084                         AUTOBAR BELGIUM S' +
          'A        BOOMSESTEENWEG 73         2630 AARTSELAAR           000');
        tempFile.Write('2100080000KHMC01798 TBOINDNLOON100000000032818009010700101000110' +
          '1200601236986                                      0901070050100');
        tempFile.Write('2200080000                                                     6' +
          '1798                        000000000000000                  100');
        tempFile.Write('2300080000220057681084                         AUTOBAR BELGIUM S' +
          'A        BOOMSESTEENWEG 73         2630 AARTSELAAR           000');
        tempFile.Write('2100090000KHMC01799 TBOINDNLOON100000000008494009010700101000110' +
          '1200641227460                                      0901070050100');
        tempFile.Write('2200090000                                                     6' +
          '1804                        000000000000000                  100');
        tempFile.Write('2300090000220057681084                         AUTOBAR BELGIUM S' +
          'A        BOOMSESTEENWEG 73         2630 AARTSELAAR           000');
        tempFile.Write('2100100000KHMC01800 TBOINDNLOON100000000017015009010700101000110' +
          '1200601285284                                      0901070050100');
        tempFile.Write('2200100000                                                     6' +
          '1813                        000000000000000                  100');
        tempFile.Write('2300100000220057681084                         AUTOBAR BELGIUM S' +
          'A        BOOMSESTEENWEG 73         2630 AARTSELAAR           000');
        tempFile.Write('2100110000KHMC01801 TBOINDNLOON1000000000512740090107001010000FA' +
          'CT 28016149 S01 028                                0901070050100');
        tempFile.Write('2200110000                                                     6' +
          '1592                        000000000000000                  100');
        tempFile.Write('2300110000285020504213                         BARCO KUURNE     ' +
          '         NOORDLAAN 5               8520 KUURNE               000');
        tempFile.Write('2100120000KHMC01802 TBOINDNLOON1000000000902630090107001010000FT' +
          '111602572 602741 602867 602892 602981 603069 6030720901070050100');
        tempFile.Write('2200120000                                                     6' +
          '1607829                     000000000000000                  100');
        tempFile.Write('2300120000447964515175                         BUYSSE WILLEMS GA' +
          'RAGE     JACQUES PARIJSLAAN 8      9940 EVERGEM              000');
        tempFile.Write('2100130000KHMC01803 TBOINDNLOON100000000076807009010700101000110' +
          '1009005562044                                      0901070050100');
        tempFile.Write('2200130000                                                     6' +
          '1671                        000000000000000                  100');
        tempFile.Write('2300130000220043968823                         CARE             ' +
          '         LUCHTHAVENLEI 7B BUS 2    2100 DEURNE (ANTW.)       000');
        tempFile.Write('2100140000KHMC01804 TBOINDNLOON100000000076807009010700101000110' +
          '1009005671875                                      0901070050100');
        tempFile.Write('2200140000                                                     6' +
          '1874                        000000000000000                  100');
        tempFile.Write('2300140000220043968823                         CARE             ' +
          '         LUCHTHAVENLEI 7B BUS 2    2100 DEURNE (ANTW.)       000');
        tempFile.Write('2100150000KHMC01805 TBOINDNLOON1000000010619930090107001010000IN' +
          'V164091 164092 164170 164168 164169 164184         0901070050100');
        tempFile.Write('2200150000                                                     6' +
          '1704712                     000000000000000                  100');
        tempFile.Write('2300150000443900193149                         CMAC             ' +
          '         IZ KL FRANKRIJK 28        9600 RONSE                000');
        tempFile.Write('2100160000KHMC01806 TBOINDNLOON1000000005455890090107001010000IN' +
          'V 06111601 111602 111603                           0901070050100');
        tempFile.Write('2200160000                                                     6' +
          '168789                      000000000000000                  100');
        tempFile.Write('2300160000063991768047                         CPE              ' +
          '         SCHEURBOEK 6A             9860 OOSTERZELE           000');
        tempFile.Write('2100170000KHMC01807 TBOINDNLOON1000000000135680090107001010000BR' +
          'U0905683                                           0901070050100');
        tempFile.Write('2200170000                                                     6' +
          '1779                        000000000000000                  100');
        tempFile.Write('2300170000482910700226                         DHL              ' +
          '         POSTBUS 31                1831 DIEGEM               000');
        tempFile.Write('2100180000KHMC01808 TBOINDNLOON1000000000732900090107001010000IN' +
          'V122810 KLANT822346                                0901070050100');
        tempFile.Write('2200180000                                                     6' +
          '1667                        000000000000000                  100');
        tempFile.Write('2300180000825601419034                         EBV              ' +
          '         EXCELSIORLN 68            1930 ZAVENTEM             000');
        tempFile.Write('2100190000KHMC01809 TBOINDNLOON1000000000961950090107001010000IN' +
          'V 712559 717757 720476                             0901070050100');
        tempFile.Write('2200190000                                                     6' +
          '1731885                     000000000000000                  100');
        tempFile.Write('2300190000419706600164                         ECOMAL           ' +
          '         BATTelseSTWG 455E         2800 MECHELEN             000');
        tempFile.Write('2100200000KHMC01810 TBOINDNLOON1000000002447810090107001010000FA' +
          'CT504658                                           0901070050100');
        tempFile.Write('2200200000                                                     6' +
          '1727                        000000000000000                  100');
        tempFile.Write('2300200000414002661169                         EUROPRINT        ' +
          '         ZANDVOORTSTRAAT 21        2800 MECHELEN             000');
        tempFile.Write('2100210000KHMC01811 TBOINDNLOON1000000000467990090107001010000IN' +
          'V96133105 TO96142988                               0901070050100');
        tempFile.Write('2200210000                                                     6' +
          '149991                      000000000000000                  100');
        tempFile.Write('2300210000733031146932                         FABORY           ' +
          '         ZWEDENSTRAAT 4            9940 EVERGEM              000');
        tempFile.Write('2100220000KHMC01812 TBOINDNLOON100000000007132009010700101000110' +
          '1162033288470                                      0901070050100');
        tempFile.Write('2200220000                                                     6' +
          '1854                        000000000000000                  100');
        tempFile.Write('2300220000437750115182                         FACQ             ' +
          '         GANGSTR 20                1050 BRUSSEL 5            000');
        tempFile.Write('2100230000KHMC01813 TBOINDNLOON1000000001408000090107001010000IN' +
          'V841175 853828                                     0901070050100');
        tempFile.Write('2200230000                                                     6' +
          '176449                      000000000000000                  100');
        tempFile.Write('2300230000720520635687                         FUTURE ELECTRONIC' +
          'S        BRANDSTR 15A              9160 LOKEREN              000');
        tempFile.Write('2100240000KHMC01814 TBOINDNLOON1000000001275340090107001010000IN' +
          'V108687                                            0901070050100');
        tempFile.Write('2200240000                                                     6' +
          '1683                        000000000000000                  100');
        tempFile.Write('2300240000410065152192                         GIVATEC          ' +
          '         INDUSTRIEWEG 5            3001 HEVERLEE             000');
        tempFile.Write('2100250000KHMC01815 TBOINDNLOON1000000000045190090107001010000FA' +
          'CT94886                                            0901070050100');
        tempFile.Write('2200250000                                                     6' +
          '1769                        000000000000000                  100');
        tempFile.Write('2300250000335043322468                         IMES OOST VLAANDE' +
          'REN      KORTE MAGERSTRAAT 3       9050 GENTBRUGGE           000');
        tempFile.Write('2100260000KHMC01816 TBOINDNLOON1000000001830000090107001010000IN' +
          'V191537                                            0901070050100');
        tempFile.Write('2200260000                                                     6' +
          '1526                        000000000000000                  100');
        tempFile.Write('2300260000340182596777                         LEM INSTRUMENTS  ' +
          '                                   1000 BRUSSEL 1            000');
        tempFile.Write('2100270000KHMC01817 TBOINDNLOON100000000017302009010700101000110' +
          '1206193754509                                      0901070050100');
        tempFile.Write('2200270000                                                     6' +
          '1776                        000000000000000                  100');
        tempFile.Write('2300270000340013762419                         LYRECO           ' +
          '         RUE DE CHENEE 53          4031 ANGLEUR              000');
        tempFile.Write('2100280000KHMC01818 TBOINDNLOON1000000000832470090107001010000IN' +
          'V4082537                                           0901070050100');
        tempFile.Write('2200280000                                                     6' +
          '1662                        000000000000000                  100');
        tempFile.Write('2300280000552270880026                         MISCO            ' +
          '         POSTBUS 156               1930 ZAVENTEM             000');
        tempFile.Write('2100290000KHMC01819 TBOINDNLOON1000000000457380090107001010000IN' +
          'V VG062501107                                      0901070050100');
        tempFile.Write('2200290000                                                     6' +
          '1654                        000000000000000                  100');
        tempFile.Write('2300290000414520300154                         NIJKERK ELECTRONI' +
          'CS       NOORDERLAAN 111           2030 ANTWERPEN 3          000');
        tempFile.Write('2100300000KHMC01820 TBOINDNLOON1000000000146170090107001010000IN' +
          'VOICE 60107183RI CUSTOMER 42103297                 0901070050100');
        tempFile.Write('2200300000                                                     6' +
          '1738                        000000000000000                  100');
        tempFile.Write('2300300000432401944101                         OMRON            ' +
          '         STATIONSSTRAAT 24         1702 GROOT-BIJGAARD       000');
        tempFile.Write('2100310000KHMC01821 TBOINDNLOON1000000000572330090107001010000IN' +
          'V23807                                             0901070050100');
        tempFile.Write('2200310000                                                     6' +
          '1835                        000000000000000                  100');
        tempFile.Write('2300310000320050648420                         PCB              ' +
          '         ELLERMANSTRAAT 74         2060 ANTWERPEN 6          000');
        tempFile.Write('2100320000KHMC01822 TBOINDNLOON1000000000223730090107001010000IN' +
          'V61331 60554                                       0901070050100');
        tempFile.Write('2200320000                                                     6' +
          '164882                      000000000000000                  100');
        tempFile.Write('2300320000437750008179                         PHOENIX CONTACT  ' +
          '         MINERVASTRAAT 10-12       1930 ZAVENTEM             000');
        tempFile.Write('2100330000KHMC01823 TBOINDNLOON100000000640961009010700101000110' +
          '1060680430143                                      0901070050100');
        tempFile.Write('2200330000                                                     6' +
          '1834                        000000000000000                  100');
        tempFile.Write('2300330000001446507648                         RANDSTAD PROF    ' +
          '         HEIZEL ESPLANADE          1020 BRUSSEL 2            000');
        tempFile.Write('2100340000KHMC01824 TBOINDNLOON1000000001053590090107001010000IN' +
          'V6299051                                           0901070050100');
        tempFile.Write('2200340000                                                     6' +
          '1773                        000000000000000                  100');
        tempFile.Write('2300340000437751190165                         REXEL            ' +
          '         RUE DE LA TECHNOLOGIE     1082 BRUSSEL              000');
        tempFile.Write('2100350000KHMC01825 TBOINDNLOON1000000000533320090107001010000IN' +
          'V553060 557754                                     0901070050100');
        tempFile.Write('2200350000                                                     6' +
          '169465                      000000000000000                  100');
        tempFile.Write('2300350000310161043025                         RS COMPONENTS    ' +
          '         BD PAEPSEMLAAN 22         1070 ANDERLECHT           000');
        tempFile.Write('2100360000KHMC01826 TBOINDNLOON1000000006014750090107001010000IN' +
          'V4495806 TO4555463                                 0901070050100');
        tempFile.Write('2200360000                                                     6' +
          '150491                      000000000000000                  100');
        tempFile.Write('2300360000825601531087                         RUTRONIK         ' +
          '         INDUSTRIESTRASSE 2        7522 ISPRINGEN            000');
        tempFile.Write('2100370000KHMC01827 TBOINDNLOON1000000002420000090107001010000IN' +
          'V50780                                             0901070050100');
        tempFile.Write('2200370000                                                     6' +
          '1801                        000000000000000                  100');
        tempFile.Write('2300370000430084575196                         SEHER            ' +
          '         ASSESTEENWEG 117 2        1740 TERNAT               000');
        tempFile.Write('2100380000KHMC01828 TBOINDNLOON1000000000470090090107001010000IN' +
          'V9166859                                           0901070050100');
        tempFile.Write('2200380000                                                     6' +
          '1642                        000000000000000                  100');
        tempFile.Write('2300380000310000321503                         SPOERLE          ' +
          '         MINERVASTRAAT 14B2        1930 ZAVENTEM             000');
        tempFile.Write('2100390000KHMC01829 TBOINDNLOON100000000048822009010700101000110' +
          '1630311096035                                      0901070050100');
        tempFile.Write('2200390000                                                     6' +
          '1752                        000000000000000                  100');
        tempFile.Write('2300390000407050860119                         STANDAARD BOEKHAN' +
          'DEL      INDUSTRIEPARK NOORD 28A   9100 ST-NIKLAAS           000');
        tempFile.Write('2100400000KHMC01830 TBOINDNLOON1000000001064250090107001010000IN' +
          'V10052583 10052504 10052509                        0901070050100');
        tempFile.Write('2200400000                                                     6' +
          '1780 82                     000000000000000                  100');
        tempFile.Write('2300400000472302320181                         TEAM             ' +
          '         JACQUES PARIJSLAAN 8      9940 EVERGEM              000');
        tempFile.Write('2100410000KHMC01831 TBOINDNLOON1000000000715970090107001010000DI' +
          'V INV                                              0901070050100');
        tempFile.Write('2200410000                                                     6' +
          '1899                        000000000000000                  100');
        tempFile.Write('2300410000210049670015                         TNT              ' +
          '                                                             000');
        tempFile.Write('2100420000KHMC01832 TBOINDNLOON1000000000380000090107001010000IN' +
          'V80274362                                          0901070050100');
        tempFile.Write('2200420000                                                     6' +
          '1736                        000000000000000                  100');
        tempFile.Write('2300420000720540560602                         TYCO EL          ' +
          '                                                             000');
        tempFile.Write('2100430000KHMC01833 TBOINDNLOON1000000000323740090107001010000IN' +
          'V611791 KLANT 4268                                 0901070050100');
        tempFile.Write('2200430000                                                     6' +
          '1777                        000000000000000                  100');
        tempFile.Write('2300430000068241941669                         VANSICHEN        ' +
          '         BREDEWEG 62               3723 KORTESSEM            000');
        tempFile.Write('2100440000KHMC01834 TBOINDNLOON1000000000527620090107001010000IN' +
          'V601717                                            0901070050100');
        tempFile.Write('2200440000                                                     6' +
          '1698                        000000000000000                  100');
        tempFile.Write('2300440000446064891124                         VANDEVYVER       ' +
          '         BENELUXLN 1               9060 ZELZATE              000');
        tempFile.Write('2100450000KHMC01835 TBOINDNLOON1000000000024200090107001010000FA' +
          'CT602844 8612                                      0901070050100');
        tempFile.Write('2200450000                                                     6' +
          '1665                        000000000000000                  100');
        tempFile.Write('2300450000645141021968                         VENTOMATIC       ' +
          '         CHRYSANTENSTRAAT 59B      9820 MERELBEKE            000');
        tempFile.Write('2100460000KHMC01836 TBOINDNLOON1000000004416500090107001010000IN' +
          'V606087                                            0901070050100');
        tempFile.Write('2200460000                                                     6' +
          '1845                        000000000000000                  100');
        tempFile.Write('2300460000443563835141                         VANSTEENBRUGGHE N' +
          'V        BERCHEMWEG 95             9700 OUDENAARDE           000');
        tempFile.Write('2100470000KHMC01837 TBOINDNLOON1000000001698840090107001010000IN' +
          'V223602                                            0901070050100');
        tempFile.Write('2200470000                                                     6' +
          '1750                        000000000000000                  100');
        tempFile.Write('2300470000891374071719                         WYNANT           ' +
          '         AALSTSTRAAT 28            9700 OUDENAARDE           000');
        tempFile.Write('2100480000OL9470740IUBOEUBTRFCS100000000059200008010734101000000' +
          '352037009A1848                                     0901070051100');
        tempFile.Write('2200480000                                                     6' +
          '1802                        000000000000000                  001');
        tempFile.Write('3100480001OL9470740IUBOEUBTRFCS341010001001AMECHA BV            ' +
          '              GRASBEEMD 15A                                  1 0');
        tempFile.Write('32004800015705 DE HELMOND NL                 NL                 ' +
          '                                                             0 1');
        tempFile.Write('3100480002OL9470740IUBOEUBTRFCS341010001002FACT06223            ' +
          '                                                             0 1');
        tempFile.Write('3100480003OL9470740IUBOEUBTRFCS341010001004INTERNATIONALE NEDERL' +
          'ANDEN BANK NV                                                0 0');
        tempFile.Write('2100480004OL9470740IUBOEUBTRFCS100000000059200008010784101100110' +
          '5000000000592000000000000592000000100000000EUR     0901070051100');
        tempFile.Write('2200480004         000000000592000                              ' +
          '                            000000000000000                  000');
        tempFile.Write('2100490000OL9470741IUBOEUBTRFCS100000000065000008010734101000000' +
          '352037009A1849                                     0901070051100');
        tempFile.Write('2200490000                                                     6' +
          '1864 65                     000000000000000                  001');
        tempFile.Write('3100490001OL9470741IUBOEUBTRFCS341010001001BALKHAUSEN           ' +
          '              RUDOLF DIESEL STR 17                           1 0');
        tempFile.Write('320049000128857 SYKE DE                      DE                 ' +
          '                                                             0 1');
        tempFile.Write('3100490002OL9470741IUBOEUBTRFCS341010001002INVOICE 0703023      ' +
          '              0703024                                        0 1');
        tempFile.Write('3100490003OL9470741IUBOEUBTRFCS341010001004DEUTSCHE BANK AG     ' +
          '                                                             0 0');
        tempFile.Write('2100490004OL9470741IUBOEUBTRFCS100000000065000008010784101100110' +
          '5000000000650000000000000650000000100000000EUR     0901070051100');
        tempFile.Write('2200490004         000000000650000                              ' +
          '                            000000000000000                  000');
        tempFile.Write('2100500000OL9470742IUBOEUBTRFCS100000000002690008010734101000000' +
          '352037009A1850                                     0901070051100');
        tempFile.Write('2200500000                                                     6' +
          '1841                        000000000000000                  001');
        tempFile.Write('3100500001OL9470742IUBOEUBTRFCS341010001001BERGQUIST-ITC        ' +
          '              HADERSLEBENER STR. 19A                         1 0');
        tempFile.Write('320050000125421 PINNEBERG DE                 DE                 ' +
          '                                                             0 1');
    end;

    local procedure WriteCODA1MultipleB(var tempFile: File)
    begin
        tempFile.Write('3100500002OL9470742IUBOEUBTRFCS341010001002INV93750             ' +
          '                                                             0 1');
        tempFile.Write('3100500003OL9470742IUBOEUBTRFCS341010001004DEUTSCHE BANK AG     ' +
          '                                                             0 0');
        tempFile.Write('2100500004OL9470742IUBOEUBTRFCS100000000002690008010784101100110' +
          '5000000000026900000000000026900000100000000EUR     0901070051100');
        tempFile.Write('2200500004         000000000026900                              ' +
          '                            000000000000000                  000');
        tempFile.Write('2100510000OL9470743IUBOEUBTRFCS100000000033000008010734101000000' +
          '352037009A1851                                     0901070051100');
        tempFile.Write('2200510000                                                     6' +
          '1713                        000000000000000                  001');
        tempFile.Write('3100510001OL9470743IUBOEUBTRFCS341010001001KEMA QUALITY BV      ' +
          '              UTRECHTSESTEENWEG 310                          1 0');
        tempFile.Write('32005100016812AR ARNHEM NL                   NL                 ' +
          '                                                             0 1');
        tempFile.Write('3100510002OL9470743IUBOEUBTRFCS34101000100217268 2188747        ' +
          '                                                             0 1');
        tempFile.Write('3100510003OL9470743IUBOEUBTRFCS341010001004ABN AMRO BANK NV     ' +
          '                                                             0 0');
        tempFile.Write('2100510004OL9470743IUBOEUBTRFCS100000000033000008010784101100110' +
          '5000000000330000000000000330000000100000000EUR     0901070051100');
        tempFile.Write('2200510004         000000000330000                              ' +
          '                            000000000000000                  000');
        tempFile.Write('2100520000OL9470744IUBOEUBTRFCS100000000026095008010734101000000' +
          '352037009A1857                                     0901070051100');
        tempFile.Write('2200520000                                                     6' +
          '1739                        000000000000000                  001');
        tempFile.Write('3100520001OL9470744IUBOEUBTRFCS341010001001TTI INC              ' +
          '              GANGHOFERSTRASSE 34                            1 0');
        tempFile.Write('320052000182216 MAISACH-GERNLINDEN DE        DE                 ' +
          '                                                             0 1');
        tempFile.Write('3100520002OL9470744IUBOEUBTRFCS341010001002INV E00888030        ' +
          '                                                             0 1');
        tempFile.Write('3100520003OL9470744IUBOEUBTRFCS341010001004RABOBANK NEDERLAND   ' +
          '                                                             0 0');
        tempFile.Write('2100520004OL9470744IUBOEUBTRFCS100000000026095008010784101100110' +
          '5000000000260950000000000260950000100000000EUR     0901070051100');
        tempFile.Write('2200520004         000000000260950                              ' +
          '                            000000000000000                  000');
        tempFile.Write('2100530000OL9470745IUBOEUBTRFCS100000000272921008010734101000000' +
          '352037009A1858                                     0901070051100');
        tempFile.Write('2200530000                                                     6' +
          '1692 1719 1853              000000000000000                  001');
        tempFile.Write('3100530001OL9470745IUBOEUBTRFCS341010001001VERMEULEN PRINTSSERVI' +
          'CE            HELMONDSEWEG 7B                                1 0');
        tempFile.Write('32005300015735 RA AARLE-RIXTEL NL            NL                 ' +
          '                                                             0 1');
        tempFile.Write('3100530002OL9470745IUBOEUBTRFCS341010001002INV IO6 07298 07     ' +
          '              430                                            0 1');
        tempFile.Write('3100530003OL9470745IUBOEUBTRFCS341010001004RABOBANK NEDERLAND   ' +
          '                                                             0 0');
        tempFile.Write('2100530004OL9470745IUBOEUBTRFCS100000000272921008010784101100110' +
          '5000000002729210000000002729210000100000000EUR     0901070051100');
        tempFile.Write('2200530004         000000002729210                              ' +
          '                            000000000000000                  000');
        tempFile.Write('2100540000OL9470746IUBOEUBTRFCS100000000037500008010734101000000' +
          '352037009A1852                                     0901070051100');
        tempFile.Write('2200540000                                                     6' +
          '1728                        000000000000000                  001');
        tempFile.Write('3100540001OL9470746IUBOEUBTRFCS341010001001KONING EN HARTMAN BV ' +
          '              POSTBUS 416                                    1 0');
        tempFile.Write('32005400011000AK AMSTERDAM NL                NL                 ' +
          '                                                             0 1');
        tempFile.Write('3100540002OL9470746IUBOEUBTRFCS341010001002INV5100052503        ' +
          '                                                             0 1');
        tempFile.Write('3100540003OL9470746IUBOEUBTRFCS341010001004VAN LANSCHOT F BANKIE' +
          'RS NV                                                        0 0');
        tempFile.Write('2100540004OL9470746IUBOEUBTRFCS100000000037500008010784101100110' +
          '5000000000375000000000000375000000100000000EUR     0901070051100');
        tempFile.Write('2200540004         000000000375000                              ' +
          '                            000000000000000                  000');
        tempFile.Write('2100550000OL9470747IUBOEUBTRFCS100000000173224008010734101000000' +
          '352037009A1853                                     0901070051100');
        tempFile.Write('2200550000                                                     6' +
          '1882                        000000000000000                  001');
        tempFile.Write('3100550001OL9470747IUBOEUBTRFCS341010001001PHILIPS OVAR         ' +
          '              EN109/IC1 ZONA IND OVAR                        1 0');
        tempFile.Write('32005500013880728 OVAR PT                    PT                 ' +
          '                                                             0 1');
        tempFile.Write('3100550002OL9470747IUBOEUBTRFCS341010001002INV789179            ' +
          '                                                             0 1');
        tempFile.Write('3100550003OL9470747IUBOEUBTRFCS341010001004BANCO BILBAO VIZCAYA ' +
          'ARGENTARIA (PO                                               0 0');
        tempFile.Write('2100550004OL9470747IUBOEUBTRFCS100000000173224008010784101100110' +
          '5000000001732240000000001732240000100000000EUR     0901070051100');
        tempFile.Write('2200550004         000000001732240                              ' +
          '                            000000000000000                  000');
        tempFile.Write('2100560000OL9470749IUBOEUBTRFCS100000000362410008010734101000000' +
          '352037009A1854                                     0901070051100');
        tempFile.Write('2200560000                                                     6' +
          '169647                      000000000000000                  001');
        tempFile.Write('3100560001OL9470749IUBOEUBTRFCS341010001001PIHER                ' +
          '              AMBACHTSSTR 13B                                1 0');
        tempFile.Write('32005600013861 HR NIJKERK NL                 NL                 ' +
          '                                                             0 1');
        tempFile.Write('3100560002OL9470749IUBOEUBTRFCS341010001002INV110640 110692     ' +
          '                                                             0 1');
        tempFile.Write('3100560003OL9470749IUBOEUBTRFCS341010001004ABN AMRO BANK NV     ' +
          '                                                             0 0');
        tempFile.Write('2100560004OL9470749IUBOEUBTRFCS100000000362410008010784101100110' +
          '5000000003624100000000003624100000100000000EUR     0901070051100');
        tempFile.Write('2200560004         000000003624100                              ' +
          '                            000000000000000                  000');
        tempFile.Write('2100570000OL9470750IUBOEUBTRFCS100000000025001008010734101000000' +
          '352037009A1856                                     0901070051100');
        tempFile.Write('2200570000                                                     6' +
          '1814                        000000000000000                  001');
        tempFile.Write('3100570001OL9470750IUBOEUBTRFCS341010001001BV SNIJ-UNIE HIFI    ' +
          '              ZOUTKETEN 23                                   1 0');
        tempFile.Write('32005700011601EX ENKHUIZEN NL                NL                 ' +
          '                                                             0 1');
        tempFile.Write('3100570002OL9470750IUBOEUBTRFCS341010001002INV267116 KLANT2     ' +
          '              136                                            0 1');
        tempFile.Write('3100570003OL9470750IUBOEUBTRFCS341010001004INTERNATIONALE NEDERL' +
          'ANDEN BANK NV                                                0 0');
        tempFile.Write('2100570004OL9470750IUBOEUBTRFCS100000000025001008010784101100110' +
          '5000000000250010000000000250010000100000000EUR     0901070051100');
        tempFile.Write('2200570004         000000000250010                              ' +
          '                            000000000000000                  000');
        tempFile.Write('2100580000OL9470751IUBOEUNTRFCS100000001604164008010734101000000' +
          '352037009A1855                                     0901070051001');
        tempFile.Write('3100580001OL9470751IUBOEUNTRFCS341010001001PUNCH TECHNIX NV     ' +
          '              KROMMESPIERINGWEG 289B                         1 0');
        tempFile.Write('32005800012141BS VIJFHUIZEN NL               NL                 ' +
          '                                                             0 1');
        tempFile.Write('3100580002OL9470751IUBOEUNTRFCS341010001002INV204700680         ' +
          '              FACTUUR204700252 PUNCH TECHNIX NV              0 1');
        tempFile.Write('3100580003OL9470751IUBOEUNTRFCS341010001004BANQUE ARTESIA NEDERL' +
          'AND                                                          0 0');
        tempFile.Write('2100580004OL9470751IUBOEUNTRFCS100000001604164008010784101100110' +
          '5000000016041640000000016041640000100000000EUR     0901070051100');
        tempFile.Write('2200580004         000000016041640                              ' +
          '                            000000000000000                  000');
        tempFile.Write('2100590000OL9470752KUBOKOSDIVKS100000000001210008010734137000000' +
          '352037009A1855                                     0901070051000');
        tempFile.Write('2100590001OL9470752KUBOKOSDIVKS1000000000010000080107841370260  ' +
          '                                                   0901070050000');
        tempFile.Write('2100590002OL9470752KUBOKOSDIVKS100000000000210008010784137011110' +
          '6000000000002100000000000010000002100000000200000000901070051100');
        tempFile.Write('220059000200002100                                              ' +
          '                            000000000000000                  000');
        tempFile.Write('2100600000KJXV14365BOVSBBNONTVA000000000061147009010700150000062' +
          '90                                                 0901070050100');
        tempFile.Write('220060000010/062-260985                                         ' +
          '                            000000000000000                  100');
        tempFile.Write('2300600000260035911186                         GO TO SA         ' +
          '         CHEMIN DE HAMEAU 25       6120    HAM-SUR-HEURE     000');
        tempFile.Write('21006100007409A3A5G KGDTTNTERNG1000000008000000080107009010000  ' +
          '                                                   0901070050000');
        tempFile.Write('8005290004614187 EUR0BE                  0000000292458810090107 ' +
          '                                                                ');
        tempFile.Write('9               000238000000095384640000000000611470            ' +
          '                                                               1');
        tempFile.Write('0000010010729005D  0000000074789  INVERTO NV                0000' +
          '000000000058315707 00000                                       1');
        tempFile.Write('1 006290004614187 EUR0BE                  0000000292458810090107' +
          'INVERTO NV                KBC-Bedrijfsrekening               001');
        tempFile.Write('2100010000KTTEA0CTR DOMALGDOV01100000000105784010010700501000110' +
          '7740784372894100107I=0701599551 R=36291539        01001070060100');
        tempFile.Write('22000100000403063902                                            ' +
          '                            000000000000000                  100');
        tempFile.Write('2300010000000000000000                         NV TOTAL BELGIUM ' +
          'SA                                                           000');
        tempFile.Write('2100020000LEGLA0B5R DOMNINDIN01100000007880763010010700501000110' +
          '7740784719367110107      060534695                01001070060100');
        tempFile.Write('22000200000409823416                                            ' +
          '                            000000000000000                  100');
        tempFile.Write('2300020000000000000000                         HULP DER PATROONS' +
          ' DOMICIL.                                                    000');
        tempFile.Write('8006290004614187 EUR0BE                  0000000212593340100107 ' +
          '                                                                ');
        tempFile.Write('9               000008000000079865470000000000000000            ' +
          '                                                               1');
        tempFile.Write('0000011010729005D  0000000074789  INVERTO NV                0000' +
          '000000000058315707 00000                                       1');
        tempFile.Write('1 007290004614187 EUR0BE                  0000000212593340100107' +
          'INVERTO NV                KBC-Bedrijfsrekening               001');
        tempFile.Write('2100010000LJEHA0APR DOMALGDOV01100000000028146011010700501000110' +
          '774071599264511010773518-LF-0  2536630   413794   01101070070100');
        tempFile.Write('22000100000426403684                                            ' +
          '                            000000000000000                  100');
        tempFile.Write('2300010000000000000000                         KBC LEASE BELGIUM' +
          '                                                             000');
        tempFile.Write('2100020000LJEHA0APS DOMALGDOV01100000000028702011010700501000110' +
          '774071599264511010773520-LF-0  2536631   413794   01101070070100');
        tempFile.Write('22000200000426403684                                            ' +
          '                            000000000000000                  100');
        tempFile.Write('2300020000000000000000                         KBC LEASE BELGIUM' +
          '                                                             000');
        tempFile.Write('2100030000LJEHA0APT DOMALGDOV01100000000033999011010700501000110' +
          '774071599264511010773521-LF-0  2536632   413794   01101070070100');
        tempFile.Write('22000300000426403684                                            ' +
          '                            000000000000000                  100');
        tempFile.Write('2300030000000000000000                         KBC LEASE BELGIUM' +
          '                                                             000');
        tempFile.Write('8007290004614187 EUR0BE                  0000000211684870110107 ' +
          '                                                                ');
        tempFile.Write('9               000011000000000908470000000000000000            ' +
          '                                                               1');
        tempFile.Write('0000012010729005D  0000000074789  INVERTO NV                0000' +
          '000000000058315707 00000                                       1');
        tempFile.Write('1 008290004614187 EUR0BE                  0000000211684870110107' +
          'INVERTO NV                KBC-Bedrijfsrekening               001');
        tempFile.Write('2100010000OL9464620JBBNEUBCRCL1000000002898250012010734150000000' +
          '352037012A3186                                     1201070081001');
        tempFile.Write('3100010001OL9464620JBBNEUBCRCL1341500001001PHILIPS LIGHTING BV  ' +
          '              P.O. BOX 1                                     1 0');
        tempFile.Write('3200010001BUILDING AA                        OSS                ' +
          '                                                             0 1');
        tempFile.Write('3100010002OL9464620JBBNEUBCRCL13415000010026710280720000227 6324' +
          ' 6326                                                        0 0');
        tempFile.Write('2100010003OL9464620JBBNEUBCRCL1000000002898250012010784150100110' +
          '5000000028982500000000028982500000100000000EUR     1201070081100');
        tempFile.Write('2200010003         000000028982500                              ' +
          '                            000000000000000                  000');
        tempFile.Write('2100020000MGLC00104BTBOGOVOVERS0000000000112530120107001500000  ' +
          '          6303                                     1201070080100');
        tempFile.Write('2300020000443900062197                         SANTENS NV       ' +
          '         GALGESTRAAT 157           9700 OUDENAARDE           000');
        tempFile.Write('8008290004614187 EUR0BE                  0000000240779900120107 ' +
          '                                                                ');
        tempFile.Write('9               000010000000000000000000000029095030            ' +
          '                                                               1');
        tempFile.Write('0000015010729005D  0000000074789  INVERTO NV                0000' +
          '000000000058315707 00000                                       1');
        tempFile.Write('1 009290004614187 EUR0BE                  0000000240779900120107' +
          'INVERTO NV                KBC-Bedrijfsrekening               001');
        tempFile.Write('2100010000MLMPA0AMU DOMALGDOV01100000000028712015010700501000110' +
          '774071599264515010778359-LF-0  2540014   413946   01501070090100');
        tempFile.Write('22000100000426403684                                            ' +
          '                            000000000000000                  100');
        tempFile.Write('2300010000000000000000                         KBC LEASE BELGIUM' +
          '                                                             000');
        tempFile.Write('2100020000MUUB02943LKKTOVSOVKUG100000000347147015010700319000112' +
          '45526145478490607    1431                          1501070090100');
        tempFile.Write('2300020000666000000483                                          ' +
          '                                                             000');
        tempFile.Write('8009290004614187 EUR0BE                  0000000237021310150107 ' +
          '                                                                ');
        tempFile.Write('9               000007000000003758590000000000000000            ' +
          '                                                               1');
        tempFile.Write('0000016010729005D  0000000074789  INVERTO NV                0000' +
          '000000000058315707 00000                                       1');
        tempFile.Write('1 010290004614187 EUR0BE                  0000000237021310150107' +
          'INVERTO NV                KBC-Bedrijfsrekening               001');
        tempFile.Write('2100010000NAIAA0AA0 DOMNINDIN01100000000001084016010700501000110' +
          '7740784719367170107      070031236                01601070100100');
        tempFile.Write('22000100000409823416                                            ' +
          '                            000000000000000                  100');
        tempFile.Write('2300010000000000000000                         HULP DER PATROONS' +
          ' DOMICIL.                                                    000');
        tempFile.Write('2100020000NKGU00273 TBOINDNLOON1000000000020010160107001010000EX' +
          'P TANKEN                                           1601070100100');
        tempFile.Write('2200020000                                                     D' +
          'IV6117                      000000000000000                  100');
        tempFile.Write('2300020000001336470848                         VALLAEY MATTHIAS ' +
          '                                                             000');
        tempFile.Write('2100030000NKGU00274 TBOINDNLOON1000000000136250160107001010000EX' +
          'P DEC06                                            1601070100100');
        tempFile.Write('2200030000                                                     D' +
          'IV6118                      000000000000000                  100');
        tempFile.Write('2300030000737101218432                         VAN DE SYPE DAVID' +
          '         STATIONSSTR 124           9450 HAALTERT             000');
        tempFile.Write('2100040000NKGU00275 TBOINDNLOON1000000000092920160107001010000EX' +
          'P DEC06                                            1601070100100');
        tempFile.Write('2200040000                                                     D' +
          'IV6119                      000000000000000                  100');
        tempFile.Write('2300040000979382731184                         ROMEYNS DIRK     ' +
          '         WAFELSTRAAT 26            9630 ZWALM                000');
        tempFile.Write('2100050000NKGU00276 TBOINDNLOON1000000000093500160107001010000EX' +
          'P DEC06                                            1601070100100');
        tempFile.Write('2200050000                                                     D' +
          'IV6120                      000000000000000                  100');
        tempFile.Write('2300050000733163053996                         VERMEER PAUL     ' +
          '         TEN OTTER 80              2980 ZOERSEL              000');
        tempFile.Write('2100060000NKGU00277 TBOINDNLOON1000000000116800160107001010000EX' +
          'P JAN07                                            1601070100100');
        tempFile.Write('2200060000                                                     D' +
          'IV                          000000000000000                  100');
        tempFile.Write('2300060000737005116185                         ISABELLE VAN DER ' +
          'PLAETSEN VARENDRIESKOUTER 4        9031 DRONGEN              000');
        tempFile.Write('8010290004614187 EUR0BE                  0000000236550990160107 ' +
          '                                                                ');
        tempFile.Write('9               000020000000000470320000000000000000            ' +
          '                                                               1');
        tempFile.Write('0000017010729005D  0000000074789  INVERTO NV                0000' +
          '000000000058315707 00000                                       1');
        tempFile.Write('1 011290004614187 EUR0BE                  0000000236550990160107' +
          'INVERTO NV                KBC-Bedrijfsrekening               001');
        tempFile.Write('2100010000NOEOA0BUR DOMDCDDID01100000000002804017010700501000110' +
          '7740745036768180107F. 2007040813 DOMICIL.         01701070110100');
        tempFile.Write('22000100000455530509                                            ' +
          '                            000000000000000                  100');
        tempFile.Write('2300010000000000000000                         ISABEL           ' +
          '                                                             000');
        tempFile.Write('2100020000NRGD00175 TBOINDNLOON1000000004537500170107001010000FA' +
          'CT 27019                                           1701070110100');
        tempFile.Write('2200020000                                                     6' +
          '1778                        000000000000000                  100');
        tempFile.Write('2300020000738609290061                         ASTRA TEC BVBA   ' +
          '         INDUSTRIELAAN 19          8810 LICHTERVELDE         000');
        tempFile.Write('2100030000NRGD00176 TBOINDNLOON1000000005313300170107001010000IN' +
          'V6205 MIN VOORSCHOT MIN TEVEEL GEST                1701070110100');
        tempFile.Write('2200030000                                                     6' +
          '1957 MI                     000000000000000                  100');
        tempFile.Write('2300030000390031747246                         IPL              ' +
          '                                                             000');
        tempFile.Write('21000400007409A3BWQ KGDTTNTERNG1000000004000000160107009010000  ' +
          '                                                   1701070110000');
        tempFile.Write('8011290004614187 EUR0BE                  0000000222672150170107 ' +
          '                                                                ');
        tempFile.Write('9               000012000000013878840000000000000000            ' +
          '                                                               1');
        tempFile.Write('0000018010729005D  0000000074789  INVERTO NV                0000' +
          '000000000058315707 00000                                       1');
        tempFile.Write('1 012290004614187 EUR0BE                  0000000222672150170107' +
          'INVERTO NV                KBC-Bedrijfsrekening               001');
        tempFile.Write('2100010000OCGP00069BTBOGOVOVERS000000000122210018010700150000063' +
          '13;                                                1801070120100');
        tempFile.Write('2300010000443900193149                         C-MAC ELECTROMAG ' +
          'N.V.     INDUSTRIEZONE 28          9600 RONSE                000');
        tempFile.Write('8012290004614187 EUR0BE                  0000000223894250180107 ' +
          '                                                                ');
        tempFile.Write('9               000004000000000000000000000001222100            ' +
          '                                                               1');
        tempFile.Write('0000019010729005D  0000000074789  INVERTO NV                0000' +
          '000000000058315707 00000                                       1');
        tempFile.Write('1 013290004614187 EUR0BE                  0000000223894250180107' +
          'INVERTO NV                KBC-Bedrijfsrekening               001');
        tempFile.Write('2100010000OOQXA0AAO DOMNINDIN01100000000099810019010700501000110' +
          '7740784398863220107               0070140918      01901070130100');
        tempFile.Write('22000100000876383320                                            ' +
          '                            000000000000000                  100');
        tempFile.Write('2300010000000000000000                         D''IETEREN SERVICE' +
          'S                                                            000');
        tempFile.Write('2100020000OQEJ02375 TBOINDNLOON1000000003700000190107001010000FA' +
          'CTUUR F20060264                                    1901070130100');
        tempFile.Write('2200020000                                                     6' +
          '1961                        000000000000000                  100');
        tempFile.Write('2300020000447962409164                         DE GOUDEN KROON  ' +
          '         MARKTPLEIN 3-9            9940 EVERGEM              000');
        tempFile.Write('2100030000OQEJ02376 TBOINDNLOON10000000116142301901070010100002 ' +
          'AF MIN 2 VF MIN TEV BET                            1901070130100');
        tempFile.Write('2200030000                                                     7' +
          '0048 59                     000000000000000                  100');
        tempFile.Write('2300030000467538877123                         FIBECON BVBA     ' +
          '         MEERSBLOEM MELDEN 30      9700 OUDENAARDE           000');
        tempFile.Write('2100040000OL9414457JBBNEUBCRCL1000000000738811019010734150000000' +
          '352037019A2387                                     1901070131001');
        tempFile.Write('3100040001OL9414457JBBNEUBCRCL1341500001001PHILIPS LIGHTING BV  ' +
          '              P.O. BOX 1                                     1 0');
        tempFile.Write('3200040001BUILDING AA                                           ' +
          '                                                             0 1');
        tempFile.Write('3100040002OL9414457JBBNEUBCRCL13415000010026710280720000287 6327' +
          '                                                             0 0');
        tempFile.Write('2100040003OL9414457JBBNEUBCRCL1000000000738811019010784150100110' +
          '5000000007388110000000007388110000100000000EUR     1901070131100');
        tempFile.Write('2200040003         000000007388110                              ' +
          '                            000000000000000                  000');
        tempFile.Write('2100050000OTJZ07706BOVSBBNONTVA0000000006470000190107001500000IN' +
          'VOICE 6227                                         1901070130100');
        tempFile.Write('2300050000293047693339                         NV PELEMAN INDUST' +
          'RIES     RIJKSWEG 7                2870    PUURS             000');
        tempFile.Write('8013290004614187 EUR0BE                  0000000221440030190107 ' +
          '                                                                ');
        tempFile.Write('9               000019000000016312330000000013858110            ' +
          '                                                               1');
        tempFile.Write('0000022010729005D  0000000074789  INVERTO NV                0000' +
          '000000000058315707 00000                                       1');
        tempFile.Write('1 014290004614187 EUR0BE                  0000000221440030190107' +
          'INVERTO NV                KBC-Bedrijfsrekening               001');
        tempFile.Write('2100010000PERF03204 TBOINDNLOON1000000000260000220107001010000IN' +
          'SCHRIJVING LED EUROPE                              2201070140100');
        tempFile.Write('2200010000                                                     D' +
          'IV6108                      000000000000000                  100');
        tempFile.Write('2300010000091013155653                         BAO              ' +
          '         GABRIELLE PETITSTRAAT 4B121080 BRUSSEL 8            000');
        tempFile.Write('8014290004614187 EUR0BE                  0000000221180030220107 ' +
          '                                                                ');
        tempFile.Write('9               000005000000000260000000000000000000            ' +
          '                                                               1');
        tempFile.Write('0000023010729005D  0000000074789  INVERTO NV                0000' +
          '000000000058315707 00000                                       1');
        tempFile.Write('1 015290004614187 EUR0BE                  0000000221180030220107' +
          'INVERTO NV                KBC-Bedrijfsrekening               001');
        tempFile.Write('2100010000PQJJA0AM3 DOMALGDOV01100000000039663023010700501000110' +
          '774071599264523010775560-LF-0  2548125   414271   02301070150100');
        tempFile.Write('22000100000426403684                                            ' +
          '                            000000000000000                  100');
        tempFile.Write('2300010000000000000000                         KBC LEASE BELGIUM' +
          '                                                             000');
        tempFile.Write('2100020000PRFQ01851BTBOINDNLOON0000000000354000230107001500000FA' +
          'KT 7008    17/01/07   OUD IJZER                    2301070150100');
        tempFile.Write('2300020000449461774136                         DEKEUKELEIRE G & ' +
          'F BVBA   KOOPVAARDIJLAAN 49        9000  GENT                000');
        tempFile.Write('8015290004614187 EUR0BE                  0000000221137400230107 ' +
          '                                                                ');
        tempFile.Write('9               000007000000000396630000000000354000            ' +
          '                                                               1');
        tempFile.Write('0000025010729005D  0000000074789  INVERTO NV                0000' +
          '000000000058315707 00000                                       1');
        tempFile.Write('1 016290004614187 EUR0BE                  0000000221137400240107' +
          'INVERTO NV                KBC-Bedrijfsrekening               001');
        tempFile.Write('2100010000QPGEA0B06 DOMALGDOV01100000000117504025010700501000110' +
          '7740784372894250107I=0701631865 R=37005468        02501070160100');
        tempFile.Write('22000100000403063902                                            ' +
          '                            000000000000000                  100');
        tempFile.Write('2300010000000000000000                         NV TOTAL BELGIUM ' +
          'SA                                                           000');
        tempFile.Write('2100020000QYVWA0ACA DOMNINDIN01100000000000456025010700501000110' +
          '7740784719367260107      070042466                02501070160100');
        tempFile.Write('22000200000409823416                                            ' +
          '                            000000000000000                  100');
        tempFile.Write('2300020000000000000000                         HULP DER PATROONS' +
          ' DOMICIL.                                                    000');
        tempFile.Write('2100030000QYVWA0ACB DOMNINDIN01100000002232500025010700501000110' +
          '7740784719367260107      060534697                02501070160100');
        tempFile.Write('22000300000409823416                                            ' +
          '                            000000000000000                  100');
        tempFile.Write('2300030000000000000000                         HULP DER PATROONS' +
          ' DOMICIL.                                                    000');
        tempFile.Write('8016290004614187 EUR0BE                  0000000197632800250107 ' +
          '                                                                ');
        tempFile.Write('9               000011000000023504600000000000000000            ' +
          '                                                               1');
        tempFile.Write('0000026010729005D  0000000074789  INVERTO NV                0000' +
          '000000000058315707 00000                                       1');
        tempFile.Write('1 017290004614187 EUR0BE                  0000000197632800250107' +
          'INVERTO NV                KBC-Bedrijfsrekening               001');
        tempFile.Write('2100010000OL9456866JBBNEUNCRCL1000000010144318026010734150000000' +
          '352037026A2463                                     2601070171001');
        tempFile.Write('3100010001OL9456866JBBNEUNCRCL1341500001001PHILIPS LIGHTING BV  ' +
          '              P.O. BOX 1                                     1 0');
        tempFile.Write('3200010001BUILDING AA                        OSS                ' +
          '                                                             0 1');
        tempFile.Write('3100010002OL9456866JBBNEUNCRCL13415000010026710280720000415 6235' +
          ' 6274 6310                                                   0 0');
        tempFile.Write('2100010003OL9456866JBBNEUNCRCL1000000010144318026010784150100110' +
          '5000000101443180000000101443180000100000000EUR     2601070171100');
        tempFile.Write('2200010003         000000101443180                              ' +
          '                            000000000000000                  000');
        tempFile.Write('2100020000OL9456867KBBNKOSDIVKS100000000001089026010734137000000' +
          '352037026A2463                                     2601070171000');
        tempFile.Write('2100020001OL9456867KBBNKOSDIVKS1000000000009000260107841370130  ' +
          '                                                   2601070170000');
        tempFile.Write('2100020002OL9456867KBBNKOSDIVKS100000000000189026010784137011110' +
          '6000000000001890000000000009000002100000000200000002601070171100');
        tempFile.Write('220002000200001890                                              ' +
          '                            000000000000000                  000');
        tempFile.Write('2100030000OL9460898JBBOEUBCRECL000000001575055029010734150000000' +
          '352037026A6016                                     2601070171100');
        tempFile.Write('2200030000                                                     T' +
          '47A70124AD86                000000000000000                  001');
        tempFile.Write('3100030001OL9460898JBBOEUBCRECL341500001001STECA BATTERIELADESYS' +
          'TEME UND      PRAEZISIONSELEKTRONIK GMBH                     1 0');
        tempFile.Write('3200030001MAMMOSTRASSE 1                     87700 MEMMINGEN    ' +
          '                                                             0 1');
        tempFile.Write('3100030002OL9460898JBBOEUBCRECL341500001002INV. 6347 / 27.12.200' +
          '6             INV. 6336 - 6339 VOM 22.12.2006                0 0');
        tempFile.Write('2100030003OL9460898JBBOEUBCRECL000000001575055029010784150100110' +
          '5000000015750550000000015750550000100000000EUR     2601070171100');
        tempFile.Write('2200030003         000000015750550                              ' +
          '                            000000000000000                  000');
        tempFile.Write('2100040000OL7079304 KGDBDCVBDEG1000000000470390250107309050000Uw' +
          ' bestelling                      34118493343       2601070171000');
    end;

    local procedure WriteCODA1MultipleC(var tempFile: File)
    begin
        tempFile.Write('2100040001OL7079304 KGDBDCVBDEG100000000047039025010780905100110' +
          '5000000000470390000000000470390000063777500GBP     2601070171100');
        tempFile.Write('2200040001         000000000470390                              ' +
          '                            000000000000000                  000');
        tempFile.Write('2100050000RIQX00752BTBOINDNLOON0000000000224760260107001500000FA' +
          'CT. 6287                                           2601070170100');
        tempFile.Write('2300050000443900270143                         PRINTED CARPETS V' +
          'E.DE.BE. IND.PARK KL FRANKRIJK 62  9600  RONSE               000');
        tempFile.Write('8017290004614187 EUR0BE                  0000000314570010260107 ' +
          '                                                                ');
        tempFile.Write('9               000024000000000481280000000117418490            ' +
          '                                                               1');
        tempFile.Write('0000029010729005D  0000000074789  INVERTO NV                0000' +
          '000000000058315707 00000                                       1');
        tempFile.Write('1 018290004614187 EUR0BE                  0000000314570010260107' +
          'INVERTO NV                KBC-Bedrijfsrekening               001');
        tempFile.Write('2100010000RUIXA0AMU DOMALGDOV01100000000036048029010700501000110' +
          '774071599264529010774337-LF-0  2557333   414652   02901070180100');
        tempFile.Write('22000100000426403684                                            ' +
          '                            000000000000000                  100');
        tempFile.Write('2300010000000000000000                         KBC LEASE BELGIUM' +
          '                                                             000');
        tempFile.Write('2100020000RVQH03264 TBOINDNLOON100000000001800029010700101000110' +
          '1079934278829                                      2901070180100');
        tempFile.Write('2200020000                                                     D' +
          'IV7002                      000000000000000                  100');
        tempFile.Write('2300020000390044242058                         VORMETAL O W-VLAA' +
          'NDEREN   TRAMSTRAAT 61             9052 ZWIJNAARDE           000');
        tempFile.Write('2100030000RVQH03265 TBOINDNLOON100000000139379029010700101000110' +
          '1000043806412                                      2901070180100');
        tempFile.Write('2200030000                                                     6' +
          '/1933                       000000000000000                  100');
        tempFile.Write('2300030000435411161155                         PROXIMUS         ' +
          '         VOORTUIGANGSTRAAT 55      1210 BRUSSEL 21           000');
        tempFile.Write('2100040000SABYA0A4M DOMNINDIN01100000000034704029010700501000110' +
          '774076656127030010753220361 30/01                 02901070180100');
        tempFile.Write('22000400000000008314                                            ' +
          '                            000000000000000                  100');
        tempFile.Write('2300040000000000000000                         KBC-VERZEKERINGEN' +
          '                                                             000');
        tempFile.Write('2100050000OL9410136IUBOEUBTRFCS100000000019559026010734101000000' +
          '352037029B9459                                     2901070181100');
        tempFile.Write('2200050000                                                     7' +
          '0095                        000000000000000                  001');
        tempFile.Write('3100050001OL9410136IUBOEUBTRFCS341010001001PACK FEINDRAHTE      ' +
          '              AM BAUWEG 9-11                                 1 0');
        tempFile.Write('320005000151645 GUMMERSBACH DE               DE                 ' +
          '                                                             0 1');
        tempFile.Write('3100050002OL9410136IUBOEUBTRFCS341010001002RECHNUNG7500167      ' +
          '                                                             0 1');
        tempFile.Write('3100050003OL9410136IUBOEUBTRFCS341010001004DEUTSCHE BANK AG     ' +
          '                                                             0 0');
        tempFile.Write('2100050004OL9410136IUBOEUBTRFCS100000000019559026010784101100110' +
          '5000000000195590000000000195590000100000000EUR     2901070181100');
        tempFile.Write('2200050004         000000000195590                              ' +
          '                            000000000000000                  000');
        tempFile.Write('8018290004614187 EUR0BE                  0000000312255110290107 ' +
          '                                                                ');
        tempFile.Write('9               000022000000002314900000000000000000            ' +
          '                                                               1');
        tempFile.Write('0000030010729005D  0000000074789  INVERTO NV                0000' +
          '000000000058315707 00000                                       1');
        tempFile.Write('1 019290004614187 EUR0BE                  0000000312255110290107' +
          'INVERTO NV                KBC-Bedrijfsrekening               001');
        tempFile.Write('2100010000SPUG00352 TBOINDNLOON1000000013915000300107001010000FA' +
          'CT ST07001                                         3001070190100');
        tempFile.Write('2200010000                                                     7' +
          '0117                        000000000000000                  100');
        tempFile.Write('2300010000737016385868                         STEREYO          ' +
          '         ZONNESTR 7                9810 NAZARETH             000');
        tempFile.Write('2100020000SQOE00126 BHKDGLDTBLO1000000037058260300107101050000  ' +
          '                                                   3001070191000');
        tempFile.Write('2100020001SQNQ00001 TBOSOCOVERS1000000002050020300107501050000/A' +
          '/ LONEN 01/2007                                    3001070190100');
        tempFile.Write('2300020001449276421179                         KALFSVEL ALBERIK ' +
          '                                                             000');
        tempFile.Write('2100020002SQNQ00002 TBOSOCOVERS1000000003062420300107501050000/A' +
          '/ LONEN 01/2007                                    3001070190100');
        tempFile.Write('2300020002290019346063                         DE CLERCQ JOHN   ' +
          '                                                             000');
        tempFile.Write('2100020003SQNQ00003 TBOSOCOVERS1000000002262070300107501050000/A' +
          '/ LONEN 01/2007                                    3001070190100');
        tempFile.Write('2300020003001188642141                         DE BOODT SEBASTIA' +
          'AN                                                           000');
        tempFile.Write('2100020004SQNQ00004 TBOSOCOVERS1000000001567550300107501050000/A' +
          '/ LONEN 01/2007                                    3001070190100');
        tempFile.Write('2300020004780507355378                         VAN DEN BOSSCHE G' +
          'EERT                                                         000');
        tempFile.Write('2100020005SQNQ00005 TBOSOCOVERS1000000002047500300107501050000/A' +
          '/ LONEN 01/2007                                    3001070190100');
        tempFile.Write('2300020005979382731184                         ROMEYNS DIRK     ' +
          '                                                             000');
        tempFile.Write('2100020006SQNQ00006 TBOSOCOVERS1000000001875970300107501050000/A' +
          '/ LONEN 01/2007                                    3001070190100');
        tempFile.Write('2300020006777529118508                         VANDAMME PATRICK ' +
          '                                                             000');
        tempFile.Write('2100020007SQNQ00007 TBOSOCOVERS1000000001723310300107501050000/A' +
          '/ LONEN 01/2007                                    3001070190100');
        tempFile.Write('2300020007737446195801                         CANNOODT HENDRIK ' +
          '                                                             000');
        tempFile.Write('2100020008SQNQ00008 TBOSOCOVERS1000000001822980300107501050000/A' +
          '/ LONEN 01/2007                                    3001070190100');
        tempFile.Write('2300020008285032993567                         KIEKENS KRISTOF  ' +
          '                                                             000');
        tempFile.Write('2100020009SQNQ00009 TBOSOCOVERS1000000002295220300107501050000/A' +
          '/ LONEN 01/2007                                    3001070190100');
        tempFile.Write('2300020009738425378970                         DE MEERLEER GUIDO' +
          '                                                             000');
        tempFile.Write('2100020010SQNQ00010 TBOSOCOVERS1000000002553870300107501050000/A' +
          '/ LONEN 01/2007                                    3001070190100');
        tempFile.Write('2300020010290015438276                         GHIJSELEN JOZEF  ' +
          '                                                             000');
        tempFile.Write('2100020011SQNQ00011 TBOSOCOVERS1000000001721390300107501050000/A' +
          '/ LONEN 01/2007                                    3001070190100');
        tempFile.Write('2300020011001336470848                         VALLAEY MATTHIAS ' +
          '                                                             000');
        tempFile.Write('2100020012SQNQ00012 TBOSOCOVERS1000000001926210300107501050000/A' +
          '/ LONEN 01/2007                                    3001070190100');
        tempFile.Write('2300020012737101218432                         VAN DE SYPE DAVID' +
          '                                                             000');
        tempFile.Write('2100020013SQNQ00013 TBOSOCOVERS1000000001316770300107501050000/A' +
          '/ LONEN 01/2007                                    3001070190100');
        tempFile.Write('2300020013063952649462                         MOENS BRAM       ' +
          '                                                             000');
        tempFile.Write('2100020014SQNQ00014 TBOSOCOVERS1000000002086650300107501050000/A' +
          '/ LONEN 01/2007                                    3001070190100');
        tempFile.Write('2300020014293016209361                         VAEL PHILIP      ' +
          '                                                             000');
        tempFile.Write('2100020015SQNQ00015 TBOSOCOVERS1000000001661660300107501050000/A' +
          '/ LONEN 01/2007                                    3001070190100');
        tempFile.Write('2300020015737005116185                         VAN DER PLAETSEN ' +
          'ISABELLE                                                     000');
        tempFile.Write('2100020016SQNQ00016 TBOSOCOVERS1000000001911840300107501050000/A' +
          '/ LONEN 01/2007                                    3001070190100');
        tempFile.Write('2300020016733163053996                         VERMEER PAUL     ' +
          '                                                             000');
        tempFile.Write('2100020017SQNQ00017 TBOSOCOVERS1000000001232440300107501050000/A' +
          '/ LONEN 01/2007                                    3001070190100');
        tempFile.Write('2300020017001347713047                         MINJAUW WOUTER   ' +
          '                                                             000');
        tempFile.Write('2100020018SQNQ00018 TBOSOCOVERS1000000001318760300107501050000/A' +
          '/ LONEN 01/2007                                    3001070190100');
        tempFile.Write('2300020018800226253891                         HERTOGE ANN      ' +
          '                                                             000');
        tempFile.Write('2100020019SQNQ00019 TBOSOCOVERS1000000001324090300107501050000/A' +
          '/ LONEN 01/2007                                    3001070190100');
        tempFile.Write('2300020019780539341736                         DE SAEDELEER SONJ' +
          'A                                                            000');
        tempFile.Write('2100020020SQNQ00020 TBOSOCOVERS1000000001297540300107501050000/A' +
          '/ LONEN 01/2007                                    3001070191100');
        tempFile.Write('2300020020063967633538                         COTTRELL ROY     ' +
          '                                                             000');
        tempFile.Write('8019290004614187 EUR0BE                  0000000261281850300107 ' +
          '                                                                ');
        tempFile.Write('9               000046000000050973260000000000000000            ' +
          '                                                               1');
        tempFile.Write('0000031010729005D  0000000074789  INVERTO NV                0000' +
          '000000000058315707 00000                                       1');
        tempFile.Write('1 020290004614187 EUR0BE                  0000000261281850300107' +
          'INVERTO NV                KBC-Bedrijfsrekening               001');
        tempFile.Write('2100010000TAAZA0D3Y IKLINNINNIG1000000000755750310107313410000  ' +
          '            INVESTERINGSKREDIET     726-3667975-97 3101070201000');
        tempFile.Write('2100010001TAAZA0D3Y IKLINNINNIG1000000000693670310107813410660  ' +
          '                                                   3101070200000');
        tempFile.Write('2100010002TAAZA0D3Y IKLINNINNIG1000000000062080310107813410020  ' +
          '                                                   3101070201000');
        tempFile.Write('2100020000TEBF03361 TBOINDNLOON1000000000147260310107001010000FA' +
          'CT 7006771RI                                       3101070200100');
        tempFile.Write('2200020000                                                     6' +
          '1818                        000000000000000                  100');
        tempFile.Write('2300020000230099456544                         ACAL             ' +
          '         LOZENBERG 4               1932 ZAVENTEM             000');
        tempFile.Write('2100030000TEBF03362 TBOINDNLOON1000000000417140310107001010000FA' +
          'CT870084                                           3101070200100');
        tempFile.Write('2200030000                                                     7' +
          '0014                        000000000000000                  100');
        tempFile.Write('2300030000444564625163                         ALLCOMM          ' +
          '         BRUSSelseSTEENWEG 424-426 9050 LEDEBERG (GENT       000');
        tempFile.Write('2100040000TEBF03363 TBOINDNLOON1000000002074860310107001010000FA' +
          'CT2500281402 1403 86009 86010                      3101070200100');
        tempFile.Write('2200040000                                                     6' +
          '1788 92                     000000000000000                  100');
        tempFile.Write('2300040000459250650182                         AVNET EUROPE NV  ' +
          '         KOUTERVELDSTRAAT 20       1831 DIEGEM               000');
        tempFile.Write('2100050000TEBF03364 TBOINDNLOON1000000000400380310107001010000IN' +
          'V284121 84120 84787                                3101070200100');
        tempFile.Write('2200050000                                                     6' +
          '1862 87                     000000000000000                  100');
        tempFile.Write('2300050000459250650182                         AVNET EUROPE NV  ' +
          '         KOUTERVELDSTRAAT 20       1831 DIEGEM               000');
        tempFile.Write('2100060000TEBF03365 TBOINDNLOON100000000015125031010700101000110' +
          '1571033615082                                      3101070200100');
        tempFile.Write('2200060000                                                     7' +
          '0053                        000000000000000                  100');
        tempFile.Write('2300060000000171003118                         BELGACOM         ' +
          '         K ALBERT II LAAN 27       1030 BRUSSEL 3            000');
        tempFile.Write('2100070000TEBF03366 TBOINDNLOON1000000000428540310107001010000FA' +
          'CT CF6 23848                                       3101070200100');
        tempFile.Write('2200070000                                                     6' +
          '1898                        000000000000000                  100');
        tempFile.Write('2300070000210033172032                         CEGELEC          ' +
          '         WOLUWELN 60               1200 BRUSSEL              000');
        tempFile.Write('2100080000TEBF03367 TBOINDNLOON100000000295773031010700101000016' +
          '4682 683 161505 161625                             3101070200100');
        tempFile.Write('2200080000                                                     D' +
          'IV                          000000000000000                  100');
        tempFile.Write('2300080000443900193149                         CMAC             ' +
          '         IZ KL FRANKRIJK 28        9600 RONSE                000');
        tempFile.Write('2100090000TEBF03368 TBOINDNLOON1000000000108750310107001010000FA' +
          'CT2007 015                                         3101070200100');
        tempFile.Write('2200090000                                                     7' +
          '0046                        000000000000000                  100');
        tempFile.Write('2300090000068211139826                         CONFISERIE SYLVIE' +
          '         ANTOON CATRIESTRAAT 48    9031 DRONGEN              000');
        tempFile.Write('2100100000TEBF03369 TBOINDNLOON1000000000546320310107001010000FA' +
          'CT602540                                           3101070200100');
        tempFile.Write('2200100000                                                     6' +
          '1951                        000000000000000                  100');
        tempFile.Write('2300100000462912815161                         DECOSTERE        ' +
          '         BURCHTHOF 10-11           8580 AVELGEM              000');
        tempFile.Write('2100110000TEBF03370 TBOINDNLOON1000000000421610310107001010000FT' +
          ' BRU0929445                                        3101070200100');
        tempFile.Write('2200110000                                                     6' +
          '1947                        000000000000000                  100');
        tempFile.Write('2300110000482910700226                         DHL              ' +
          '         POSTBUS 31                1831 DIEGEM               000');
        tempFile.Write('2100120000TEBF03371 TBOINDNLOON1000000000166910310107001010000FT' +
          ' BRU0915766                                        3101070200100');
        tempFile.Write('2200120000                                                     6' +
          '1873                        000000000000000                  100');
        tempFile.Write('2300120000482910700226                         DHL              ' +
          '         POSTBUS 31                1831 DIEGEM               000');
        tempFile.Write('2100130000TEBF03372 TBOINDNLOON1000000000068240310107001010000FT' +
          ' BRU0916695                                        3101070200100');
        tempFile.Write('2200130000                                                     6' +
          '1872                        000000000000000                  100');
        tempFile.Write('2300130000482910700226                         DHL              ' +
          '         POSTBUS 31                1831 DIEGEM               000');
        tempFile.Write('2100140000TEBF03373 TBOINDNLOON1000000002366570310107001010000FA' +
          'CT504859                                           3101070200100');
        tempFile.Write('2200140000                                                     6' +
          '1840                        000000000000000                  100');
        tempFile.Write('2300140000414002661169                         EUROPRINT        ' +
          '         ZANDVOORTSTRAAT 21        2800 MECHELEN             000');
        tempFile.Write('2100150000TEBF03374 TBOINDNLOON1000000010845780310107001010000CO' +
          'NS INV141                                          3101070200100');
        tempFile.Write('2200150000                                                     6' +
          '1771                        000000000000000                  100');
        tempFile.Write('2300150000720540538471                         FARNELL IN ONE   ' +
          '         RUE DE L''AEROPOSTALE 11   4460 GRACE-HOLLOGNE       000');
        tempFile.Write('2100160000TEBF03375 TBOINDNLOON100000000004937031010700101000110' +
          '1162033393150                                      3101070200100');
        tempFile.Write('2200160000                                                     7' +
          '0056                        000000000000000                  100');
        tempFile.Write('2300160000437750115182                         FACQ             ' +
          '         GANGSTR 20                1050 BRUSSEL 5            000');
        tempFile.Write('2100170000TEBF03376 TBOINDNLOON100000000030120031010700101000110' +
          '1612631487833                                      3101070200100');
        tempFile.Write('2200170000                                                     6' +
          '1880                        000000000000000                  100');
        tempFile.Write('2300170000437751190165                         REXEL            ' +
          '         RUE DE LA TECHNOLOGIE     1082 BRUXELLES            000');
        tempFile.Write('2100180000OL9453892IUBOEUBTRFCS100000000004356030010734101000000' +
          '352037031A1449                                     3101070201100');
        tempFile.Write('2200180000                                                     6' +
          '1914                        000000000000000                  001');
        tempFile.Write('3100180001OL9453892IUBOEUBTRFCS341010001001ERIKS BV             ' +
          '              TOERMALIJNSTRAAT 5                             1 0');
        tempFile.Write('32001800011800BK ALKMAAR NL                  NL                 ' +
          '                                                             0 1');
        tempFile.Write('3100180002OL9453892IUBOEUBTRFCS341010001002FACT9101877291       ' +
          '                                                             0 1');
        tempFile.Write('3100180003OL9453892IUBOEUBTRFCS341010001004RABOBANK NEDERLAND   ' +
          '                                                             0 0');
        tempFile.Write('2100180004OL9453892IUBOEUBTRFCS100000000004356030010784101100110' +
          '5000000000043560000000000043560000100000000EUR     3101070201100');
        tempFile.Write('2200180004         000000000043560                              ' +
          '                            000000000000000                  000');
        tempFile.Write('2100190000OL9453893IUBOEUBTRFCS100000000241410030010734101000000' +
          '352037031A1448                                     3101070201100');
        tempFile.Write('2200190000                                                     6' +
          '1938 939                    000000000000000                  001');
        tempFile.Write('3100190001OL9453893IUBOEUBTRFCS341010001001BERGQUIST-ITC        ' +
          '              HADERSLEBENER STR. 19A                         1 0');
        tempFile.Write('320019000125421 PINNEBERG DE                 DE                 ' +
          '                                                             0 1');
        tempFile.Write('3100190002OL9453893IUBOEUBTRFCS341010001002INV93954 93946       ' +
          '                                                             0 1');
        tempFile.Write('3100190003OL9453893IUBOEUBTRFCS341010001004DEUTSCHE BANK AG     ' +
          '                                                             0 0');
        tempFile.Write('2100190004OL9453893IUBOEUBTRFCS100000000241410030010784101100110' +
          '5000000002414100000000002414100000100000000EUR     3101070201100');
        tempFile.Write('2200190004         000000002414100                              ' +
          '                            000000000000000                  000');
        tempFile.Write('2100200000OL9453894IUBOEUBTRFCS100000000015780030010734101000000' +
          '352037031A1450                                     3101070201001');
        tempFile.Write('3100200001OL9453894IUBOEUBTRFCS341010001001DIGI KEY CORPORATION ' +
          '              PO BOX 52                                      1 0');
        tempFile.Write('32002000017500AB ENSCHEDE NL                 NL                 ' +
          '                                                             0 1');
        tempFile.Write('3100200002OL9453894IUBOEUBTRFCS341010001002INV22025799 2204     ' +
          '                                                             0 1');
        tempFile.Write('3100200003OL9453894IUBOEUBTRFCS341010001004LLOYDS TSB BANK PLC  ' +
          '                                                             0 0');
        tempFile.Write('2100200004OL9453894IUBOEUBTRFCS100000000015780030010784101100110' +
          '5000000000157800000000000157800000100000000EUR     3101070201100');
        tempFile.Write('2200200004         000000000157800                              ' +
          '                            000000000000000                  000');
        tempFile.Write('8020290004614187 EUR0BE                  0000000236458730310107 ' +
          '                                                                ');
        tempFile.Write('9               000076000000024823120000000000000000            ' +
          '                                                               1');
        tempFile.Write('0000001020729005D  0000000074789  INVERTO NV                0000' +
          '000000000058315707 00000                                       1');
        tempFile.Write('1 021290004614187 EUR0BE                  0000000236458730310107' +
          'INVERTO NV                KBC-Bedrijfsrekening               001');
        tempFile.Write('2100010000TQTKA0M00 DOMNINDIN01100000000034704031010700501000110' +
          '774076656127001020753220361 01/02                 00102070210100');
        tempFile.Write('22000100000000008314                                            ' +
          '                            000000000000000                  100');
        tempFile.Write('2300010000000000000000                         KBC-VERZEKERINGEN' +
          '                                                             000');
        tempFile.Write('2100020000TXJT00179 TBOINDNLOON100000000010600001020700101000037' +
          '933 730678                                         0102070210100');
        tempFile.Write('2200020000                                                     7' +
          '0019                        000000000000000                  100');
        tempFile.Write('2300020000723540244980                         JEVEKA BV        ' +
          '                                                             000');
        tempFile.Write('2100030000TXJT00180 TBOINDNLOON100000000009062001020700101000110' +
          '1206195491314                                      0102070210100');
        tempFile.Write('2200030000                                                     6' +
          '1940                        000000000000000                  100');
        tempFile.Write('2300030000340013762419                         LYRECO           ' +
          '         RUE DE CHENEE 53          4031 ANGLEUR              000');
        tempFile.Write('2100040000TXJT00181 TBOINDNLOON1000000000072600010207001010000FA' +
          'CT7235 7236                                        0102070210100');
        tempFile.Write('2200040000                                                     6' +
          '1888 89                     000000000000000                  100');
        tempFile.Write('2300040000000003149567                         MATEDEX          ' +
          '         AVENUE DE L''ARTISANAT 4   1420 BRAINE-L''ALLEU       000');
        tempFile.Write('2100050000TXJT00182 TBOINDNLOON1000000000343820010207001010000FA' +
          'CT60234                                            0102070210100');
        tempFile.Write('2200050000                                                     6' +
          '1926                        000000000000000                  100');
        tempFile.Write('2300050000271004538218                         NITRON NV        ' +
          '         RUE DE LA MAITRISE 2      1400 MONSTREUX            000');
        tempFile.Write('2100060000TXJT00183 TBOINDNLOON1000000000253160010207001010000FA' +
          'CT4100072921                                       0102070210100');
        tempFile.Write('2200060000                                                     6' +
          '1868                        000000000000000                  100');
        tempFile.Write('2300060000405012480190                         OTTO WOLFF NV    ' +
          '         DELLINGSTRAAT 57          2800 MECHELEN             000');
        tempFile.Write('2100070000TXJT00184 TBOINDNLOON1000000000433710010207001010000FA' +
          'CT 26105980 KLANT 3160                             0102070210100');
        tempFile.Write('2200070000                                                     6' +
          '1715                        000000000000000                  100');
        tempFile.Write('2300070000320032338254                         PEPPERL+ FUCHS NV' +
          '         METROPOOLSTRAAT 11        2900 SCHOTEN              000');
        tempFile.Write('2100080000TXJT00185 TBOINDNLOON1000000001252920010207001010000NO' +
          'TA1566700309                                       0102070210100');
        tempFile.Write('2200080000                                                     7' +
          '0009                        000000000000000                  100');
        tempFile.Write('2300080000001308220408                         ROMBAUT  C       ' +
          '         JAGERSSTR 20 BUS 9        2140 BORGERHOUT (AN       000');
        tempFile.Write('2100090000TXJT00186 TBOINDNLOON1000000007062250010207001010000DI' +
          'V INV                                              0102070210100');
        tempFile.Write('2200090000                                                     D' +
          'IV INV                      000000000000000                  100');
        tempFile.Write('2300090000825601531087                         RUTRONIK         ' +
          '         INDUSTRIESTRASSE 2        7522 ISPRINGEN            000');
        tempFile.Write('2100100000TXJT00187 TBOINDNLOON1000000000977170010207001010000IN' +
          'V9168630 8632 8645 9288                            0102070210100');
        tempFile.Write('2200100000                                                     D' +
          'IV                          000000000000000                  100');
        tempFile.Write('2300100000310000321503                         SPOERLE          ' +
          '         MINERVASTRAAT 14B2        1930 ZAVENTEM             000');
        tempFile.Write('2100110000TXJT00188 TBOINDNLOON1000000004118200010207001010000FA' +
          'CT10052711 712 713 714 52772                       0102070210100');
        tempFile.Write('2200110000                                                     D' +
          'IV                          000000000000000                  100');
        tempFile.Write('2300110000472302320181                         TEAM             ' +
          '         JACQUES PARIJSLAAN 8      9940 EVERGEM              000');
        tempFile.Write('2100120000TXJT00189 TBOINDNLOON1000000000166830010207001010000IN' +
          'V680908 670323                                     0102070210100');
        tempFile.Write('2200120000                                                     6' +
          '1937 70                     000000000000000                  100');
        tempFile.Write('2300120000210049670015                         TNT              ' +
          '                                                             000');
        tempFile.Write('2100130000TXJT00190 TBOINDNLOON1000000000251680010207001010000FA' +
          'CT2006 514                                         0102070210100');
        tempFile.Write('2200130000                                                     6' +
          '1879                        000000000000000                  100');
        tempFile.Write('2300130000380020603881                         VANGO PRINTING   ' +
          '         HIJFTESTRAAT 55           9080 LOCHRISTI            000');
        tempFile.Write('2100140000UGRD00495BTBOGOVOVERS000000005844663001020700150000063' +
          '32 6334                                            0102070210100');
        tempFile.Write('2300140000482901003155                         BEKAERT COORDINAT' +
          'IECENTRUMBEKAERTSTRAAT 2           8550 ZWEVEGEM             000');
        tempFile.Write('8021290004614187 EUR0BE                  0000000279429360010207 ' +
          '                                                                ');
        tempFile.Write('9               000043000000015476000000000058446630            ' +
          '                                                               1');
        tempFile.Write('0000002020729005D  0000000074789  INVERTO NV                0000' +
          '000000000058315707 00000                                       1');
        tempFile.Write('1 022290004614187 EUR0BE                  0000000279429360010207' +
          'INVERTO NV                KBC-Bedrijfsrekening               001');
        tempFile.Write('21000100007409A3C88 KGDTTNTERNG1000000005777620010207009010000  ' +
          '                                                   0202070220000');
        tempFile.Write('8022290004614187 EUR0BE                  0000000273651740020207 ' +
          '                                                                ');
        tempFile.Write('9               000003000000005777620000000000000000            ' +
          '                                                               1');
        tempFile.Write('0000005020729005D  0000000074789  INVERTO NV                0000' +
          '000000000058315707 00000                                       1');
        tempFile.Write('1 023290004614187 EUR0BE                  0000000273651740020207' +
          'INVERTO NV                KBC-Bedrijfsrekening               001');
        tempFile.Write('2100010000VGCN03809 TBOINDNLOON100000000031052005020700101000110' +
          '1061135212219                                      0502070230100');
        tempFile.Write('2200010000                                                     D' +
          'IV7011                      000000000000000                  100');
        tempFile.Write('2300010000679200231036                         BELASTINGEN      ' +
          '         AUTOS                     1000 BRUSSEL 1            000');
        tempFile.Write('2100020000VGCN03810 TBOINDNLOON100000000095623005020700101000110' +
          '1061143082757                                      0502070230100');
        tempFile.Write('2200020000                                                     D' +
          'IV7012                      000000000000000                  100');
        tempFile.Write('2300020000679200231036                         BELASTINGEN      ' +
          '         AUTOS                     1000 BRUSSEL 1            000');
        tempFile.Write('8023290004614187 EUR0BE                  0000000272384990050207 ' +
          '                                                                ');
        tempFile.Write('9               000008000000001266750000000000000000            ' +
          '                                                               1');
        tempFile.Write('0000006020729005D  0000000074789  INVERTO NV                0000' +
          '000000000058315707 00000                                       1');
        tempFile.Write('1 024290004614187 EUR0BE                  0000000272384990050207' +
          'INVERTO NV                KBC-Bedrijfsrekening               001');
        tempFile.Write('2100010000VVXKA0CN4 IKLINNINNIG1000000003660120060207313410000  ' +
          '            INVESTERINGSKREDIET     726-3754303-95 0602070241000');
        tempFile.Write('2100010001VVXKA0CN4 IKLINNINNIG1000000003333330060207813410660  ' +
          '                                                   0602070240000');
        tempFile.Write('2100010002VVXKA0CN4 IKLINNINNIG1000000000326790060207813410020  ' +
          '                                                   0602070241000');
        tempFile.Write('2100020000OL7087022 KGDBDCVBDEG1000000000805180050207309050000Uw' +
          ' bestelling                      34110007257       0602070241000');
        tempFile.Write('2100020001OL7087022 KGDBDCVBDEG100000000080518005020780905100110' +
          '5000000000805180000000000805180000124195500USD     0602070241100');
        tempFile.Write('2200020001         000000000805180                              ' +
          '                            000000000000000                  000');
        tempFile.Write('2100030000OL9498991JBBNEUBCRCL1000000002381053007020734150000000' +
          '352037037B7942                                     0602070241001');
        tempFile.Write('3100030001OL9498991JBBNEUBCRCL1341500001001SPLASHPOWER LTD      ' +
          '              THE JEFFREYS BUILDING, COWLEY RD               1 0');
        tempFile.Write('3200030001CAMBRIDGE CB4 0WS                                     ' +
          '                                                             0 1');
        tempFile.Write('3100030002OL9498991JBBNEUBCRCL1341500001002INV 6346             ' +
          '                                                             0 0');
        tempFile.Write('2100030003OL9498991JBBNEUBCRCL1000000002381053007020784150100110' +
          '5000000023810530000000023810530000100000000EUR     0602070241100');
        tempFile.Write('2200030003         000000023810530                              ' +
          '                            000000000000000                  000');
        tempFile.Write('8024290004614187 EUR0BE                  0000000291730220060207 ' +
          '                                                                ');
        tempFile.Write('9               000014000000004465300000000023810530            ' +
          '                                                               1');
        tempFile.Write('0000007020729005D  0000000074789  INVERTO NV                0000' +
          '000000000058315707 00000                                       1');
    end;

    local procedure WriteCODA1MultipleD(var tempFile: File)
    begin
        tempFile.Write('1 025290004614187 EUR0BE                  0000000291730220060207' +
          'INVERTO NV                KBC-Bedrijfsrekening               001');
        tempFile.Write('2100010000OL9407316JBBOEUBCRECL000000000740800008020734150000000' +
          '352037038A1971                                     0702070251100');
        tempFile.Write('2200010000                                                     4' +
          '550-70360575928             000000000000000                  001');
        tempFile.Write('3100010001OL9407316JBBOEUBCRECL341500001001ROSTI POLSKA SP. Z.O.' +
          'O.            Elewatorska 29                                 1 0');
        tempFile.Write('320001000115-620  Bia ystok                                     ' +
          '                                                             0 1');
        tempFile.Write('3100010002OL9407316JBBOEUBCRECL341500001002INVOICE  7003        ' +
          '              SUROWIEC                                       0 0');
        tempFile.Write('2100010003OL9407316JBBOEUBCRECL000000000740800008020784150100110' +
          '5000000007408000000000007408000000100000000EUR     0702070251100');
        tempFile.Write('2200010003         000000007408000                              ' +
          '                            000000000000000                  000');
        tempFile.Write('8025290004614187 EUR0BE                  0000000299138220070207 ' +
          '                                                                ');
        tempFile.Write('9               000009000000000000000000000007408000            ' +
          '                                                               1');
        tempFile.Write('0000008020729005D  0000000074789  INVERTO NV                0000' +
          '000000000058315707 00000                                       1');
        tempFile.Write('1 026290004614187 EUR0BE                  0000000299138220070207' +
          'INVERTO NV                KBC-Bedrijfsrekening               001');
        tempFile.Write('2100010000XASOA0AM2 DOMALGDOV01100000000070164008020700501000110' +
          '774071599264508020774422-LF-0  2569189   415130   00802070260100');
        tempFile.Write('22000100000426403684                                            ' +
          '                            000000000000000                  100');
        tempFile.Write('2300010000000000000000                         KBC LEASE BELGIUM' +
          '                                                             000');
        tempFile.Write('2100020000XBRY02063 TBOINDNLOON1000000009292560080207001010000FA' +
          'CT20061767 FACT20061768 MIN 2 CN                   0802070260100');
        tempFile.Write('2200020000                                                     6' +
          '1838 61                     000000000000000                  100');
        tempFile.Write('2300020000230056163828                         TRINSY TECHNICS  ' +
          '         ANTWERPSESTWG 120         2390 MALLE                000');
        tempFile.Write('2100030000XBRY02064 TBOINDNLOON1000000003523520080207001010000FA' +
          'CT60317                                            0802070260100');
        tempFile.Write('2200030000                                                     6' +
          '1844                        000000000000000                  100');
        tempFile.Write('2300030000733028656658                         VAN VOXDALE      ' +
          '         LANGE WINKELHAAKSTRAAT 26 2060 BERCHEM (ANTW.       000');
        tempFile.Write('2100040000OL9432203IUBOEUBTRFCS100000000700000007020734101000000' +
          '352037039A1708                                     0802070261100');
        tempFile.Write('2200040000                                                     7' +
          '0131                        000000000000000                  001');
        tempFile.Write('3100040001OL9432203IUBOEUBTRFCS341010001001NICHIA EUROPE BV     ' +
          '              HORNWEG 18                                     1 0');
        tempFile.Write('32000400011045 AR AMSTERDAM NL               NL                 ' +
          '                                                             0 1');
        tempFile.Write('3100040002OL9432203IUBOEUBTRFCS341010001002INVOICE 20070248     ' +
          '                                                             0 1');
        tempFile.Write('3100040003OL9432203IUBOEUBTRFCS341010001004BANK OF TOKYO - MITSU' +
          'BISHI UFJ (HOL                                               0 0');
        tempFile.Write('2100040004OL9432203IUBOEUBTRFCS100000000700000007020784101100110' +
          '5000000007000000000000007000000000100000000EUR     0802070261100');
        tempFile.Write('2200040004         000000007000000                              ' +
          '                            000000000000000                  000');
        tempFile.Write('8026290004614187 EUR0BE                  0000000278620500080207 ' +
          '                                                                ');
        tempFile.Write('9               000019000000020517720000000000000000            ' +
          '                                                               1');
        tempFile.Write('0000009020729005D  0000000074789  INVERTO NV                0000' +
          '000000000058315707 00000                                       1');
        tempFile.Write('1 027290004614187 EUR0BE                  0000000278620500080207' +
          'INVERTO NV                KBC-Bedrijfsrekening               001');
        tempFile.Write('2100010000XNQXA0BCT IKLINNINNIG1000000000991820090207313410000  ' +
          '            INVESTERINGSKREDIET     726-2764912-07 0902070271000');
        tempFile.Write('2100010001XNQXA0BCT IKLINNINNIG1000000000950930090207813410660  ' +
          '                                                   0902070270000');
        tempFile.Write('2100010002XNQXA0BCT IKLINNINNIG1000000000040890090207813410020  ' +
          '                                                   0902070271000');
        tempFile.Write('2100020000OL9459477JBBNEUBCRCL1000000003540602009020734150000000' +
          '352037040A2319                                     0902070271001');
        tempFile.Write('3100020001OL9459477JBBNEUBCRCL1341500001001PHILIPS LIGHTING BV  ' +
          '              P.O. BOX 1                                     1 0');
        tempFile.Write('3200020001BUILDING AA                        OSS                ' +
          '                                                             0 1');
        tempFile.Write('3100020002OL9459477JBBNEUBCRCL13415000010026710280720000573 6308' +
          ' 6323 6342                                                   0 0');
        tempFile.Write('2100020003OL9459477JBBNEUBCRCL1000000003540602009020784150100110' +
          '5000000035406020000000035406020000100000000EUR     0902070271100');
        tempFile.Write('2200020003         000000035406020                              ' +
          '                            000000000000000                  000');
        tempFile.Write('2100030000XXNGA0B1O DOMNINDIN01100000000016858009020700501000110' +
          '7740784719367120207      070042467                00902070270100');
        tempFile.Write('22000300000409823416                                            ' +
          '                            000000000000000                  100');
        tempFile.Write('2300030000000000000000                         HULP DER PATROONS' +
          ' DOMICIL.                                                    000');
        tempFile.Write('2100040000XXNGA0B1P DOMNINDIN01100000001610006009020700501000110' +
          '7740784719367120207      070042480                00902070270100');
        tempFile.Write('22000400000409823416                                            ' +
          '                            000000000000000                  100');
        tempFile.Write('2300040000000000000000                         HULP DER PATROONS' +
          ' DOMICIL.                                                    000');
        tempFile.Write('8027290004614187 EUR0BE                  0000000296766060090207 ' +
          '                                                                ');
        tempFile.Write('9               000017000000017260460000000035406020            ' +
          '                                                               1');
        tempFile.Write('0000012020729005D  0000000074789  INVERTO NV                0000' +
          '000000000058315707 00000                                       1');
        tempFile.Write('1 028290004614187 EUR0BE                  0000000296766060090207' +
          'INVERTO NV                KBC-Bedrijfsrekening               001');
        tempFile.Write('2100010000YCTIA0APN DOMALGDOV01100000000028146012020700501000110' +
          '774071599264512020773518-LF-0  2573027   415350   01202070280100');
        tempFile.Write('22000100000426403684                                            ' +
          '                            000000000000000                  100');
        tempFile.Write('2300010000000000000000                         KBC LEASE BELGIUM' +
          '                                                             000');
        tempFile.Write('2100020000YCTIA0APO DOMALGDOV01100000000028702012020700501000110' +
          '774071599264512020773520-LF-0  2573028   415350   01202070280100');
        tempFile.Write('22000200000426403684                                            ' +
          '                            000000000000000                  100');
        tempFile.Write('2300020000000000000000                         KBC LEASE BELGIUM' +
          '                                                             000');
        tempFile.Write('2100030000YCTIA0APP DOMALGDOV01100000000033999012020700501000110' +
          '774071599264512020773521-LF-0  2573029   415350   01202070280100');
        tempFile.Write('22000300000426403684                                            ' +
          '                            000000000000000                  100');
        tempFile.Write('2300030000000000000000                         KBC LEASE BELGIUM' +
          '                                                             000');
        tempFile.Write('2100040000YCUGA0CVW DOMALGDOV01100000000138109012020700501000110' +
          '7740784372894120207I=0701668378 R=37017803        01202070280100');
        tempFile.Write('22000400000403063902                                            ' +
          '                            000000000000000                  100');
        tempFile.Write('2300040000000000000000                         NV TOTAL BELGIUM ' +
          'SA                                                           000');
        tempFile.Write('2100050000YGQM02428LKKTOVSOVKUG100000000499090012020700319000112' +
          '45526145478490607    1435                          1202070280100');
        tempFile.Write('2300050000666000000483                                          ' +
          '                                                             000');
        tempFile.Write('8028290004614187 EUR0BE                  0000000289485600120207 ' +
          '                                                                ');
        tempFile.Write('9               000016000000007280460000000000000000            ' +
          '                                                               1');
        tempFile.Write('0000013020729005D  0000000074789  INVERTO NV                0000' +
          '000000000058315707 00000                                       1');
        tempFile.Write('1 029290004614187 EUR0BE                  0000000289485600120207' +
          'INVERTO NV                KBC-Bedrijfsrekening               001');
        tempFile.Write('2100010000YPQM05627BOVSBBNONTVA000000000007026013020700150000017' +
          '01212007001422 6088 6088CN 632   9                 1302070290100');
        tempFile.Write('2300010000685668801833                         PHILIPS INNOVATIV' +
          'E APPLICATSTEENWEG OP GIERLE 417           TURNHOUT          000');
        tempFile.Write('2100020000YQCBA0AMJ DOMALGDOV01100000000028712013020700501000110' +
          '774071599264513020778359-LF-0  2576022   415418   01302070290100');
        tempFile.Write('22000200000426403684                                            ' +
          '                            000000000000000                  100');
        tempFile.Write('2300020000000000000000                         KBC LEASE BELGIUM' +
          '                                                             000');
        tempFile.Write('2100030000YUPBA0E2M DOMUCVDIU01100000000002045013020700501000110' +
          '7740784397045130207227764/68145298                01302070290100');
        tempFile.Write('22000300000000938128                                            ' +
          '                            000000000000000                  100');
        tempFile.Write('2300030000000000000000                         TAXIPOST         ' +
          '                                                             000');
        tempFile.Write('8029290004614187 EUR0BE                  0000000289248290130207 ' +
          '                                                                ');
        tempFile.Write('9               000010000000000307570000000000070260            ' +
          '                                                               1');
        tempFile.Write('0000014020729005D  0000000074789  INVERTO NV                0000' +
          '000000000058315707 00000                                       1');
        tempFile.Write('1 030290004614187 EUR0BE                  0000000289248290130207' +
          'INVERTO NV                KBC-Bedrijfsrekening               001');
        tempFile.Write('2100010000ZFFP02090 TBOINDNLOON100000000072659014020700101000110' +
          '1061222384503                                      1402070300100');
        tempFile.Write('2200010000                                                     D' +
          'IV7019                      000000000000000                  100');
        tempFile.Write('2300010000679200231036                         BELASTINGEN AUTOS' +
          '         KON ALBERT II LAAN        1030 BRUSSEL 3            000');
        tempFile.Write('2100020000ZFFP02091 TBOINDNLOON1000000008558820140207001010000FA' +
          'CT 1491                                            1402070300100');
        tempFile.Write('2200020000                                                     7' +
          '0198                        000000000000000                  100');
        tempFile.Write('2300020000467538877123                         FIBECON BVBA     ' +
          '         MEERSBLOEM MELDEN 30      9700 OUDENAARDE           000');
        tempFile.Write('2100030000ZFFP02092 TBOINDNLOON1000000000035000140207001010000/A' +
          '/ EXP NOV DEC JAN                                  1402070300100');
        tempFile.Write('2200030000                                                     D' +
          'IV7013                      000000000000000                  100');
        tempFile.Write('2300030000780507355378                         VANDENBOSSCHE GEE' +
          'RT                                                           000');
        tempFile.Write('2100040000ZFFP02093 TBOINDNLOON1000000000316180140207001010000/A' +
          '/ EXP JAN07 HALT TUV                               1402070300100');
        tempFile.Write('2200040000                                                     D' +
          'IV7015                      000000000000000                  100');
        tempFile.Write('2300040000293016209361                         VAEL PHILIP      ' +
          '                                                             000');
        tempFile.Write('2100050000ZFFP02094 TBOINDNLOON1000000000028100140207001010000/A' +
          '/ EXP AANKOOP MACRO                                1402070300100');
        tempFile.Write('2200050000                                                     D' +
          'IV7016                      000000000000000                  100');
        tempFile.Write('2300050000979382731184                         ROMEYNS DIRK     ' +
          '         WAFELSTRAAT 26            9630 ZWALM                000');
        tempFile.Write('2100060000ZFFP02095 TBOINDNLOON1000000000020600140207001010000/A' +
          '/ EXP TREIN 080207                                 1402070300100');
        tempFile.Write('2200060000                                                     D' +
          'IV7020                      000000000000000                  100');
        tempFile.Write('2300060000001347713047                         WOUTER MINJAUW   ' +
          '         DENTERGEMSTRAAT 67        8780 OOSTROZEBEKE         000');
        tempFile.Write('2100070000ZFFP02096 TBOINDNLOON1000000000285200140207001010000/A' +
          '/ EXP SPLASH JAN FEB 07                            1402070300100');
        tempFile.Write('2200070000                                                     D' +
          'IV7022                      000000000000000                  100');
        tempFile.Write('2300070000290019346063                         DE CLERCQ JOHN   ' +
          '         BLEKTE 81                 9340 LEDE                 000');
        tempFile.Write('2100080000ZFFP02097 TBOINDNLOON100000000001050014020700101000110' +
          '1000060345518                                      1402070300100');
        tempFile.Write('2200080000                                                     D' +
          'IV7017                      000000000000000                  100');
        tempFile.Write('2300080000679205479140                         VOLMACHTEN       ' +
          '         MUNTCENTRUM               1000 BRUSSEL 1            000');
        tempFile.Write('2100090000ZFFP02098 TBOINDNLOON1000000015028010140207001010000FA' +
          'CT1865 1866 1867                                   1402070300100');
        tempFile.Write('2200090000                                                     6' +
          '1943 44                     000000000000000                  100');
        tempFile.Write('2300090000230056163828                         TRINSY TECHNICS  ' +
          '         ANTWERPSESTWG 120         2390 MALLE                000');
        tempFile.Write('2100100000ZFFP02099 TBOINDNLOON1000000000037080140207001010000FA' +
          'CT 111700303 112600758                             1402070300100');
        tempFile.Write('2200100000                                                     6' +
          '1916 70                     000000000000000                  100');
        tempFile.Write('2300100000290028356050                         BUYSSE WILLEMS GA' +
          'RAGE     JACQUES PARIJSLAAN 8      9940 EVERGEM              000');
        tempFile.Write('2100110000ZFFP02100 TBOINDNLOON1000000003598200140207001010000DI' +
          'V INV                                              1402070300100');
        tempFile.Write('2200110000                                                     6' +
          '1805 83                     000000000000000                  100');
        tempFile.Write('2300110000825601531087                         RUTRONIK         ' +
          '         INDUSTRIESTRASSE 2        7522 ISPRINGEN            000');
        tempFile.Write('2100120000ZFFP02101 TBOINDNLOON1000000000176620140207001010000FA' +
          'CT 576488 KL 014347                                1402070300100');
        tempFile.Write('2200120000                                                     6' +
          '1927                        000000000000000                  100');
        tempFile.Write('2300120000444961820157                         HANSSENS HOUT NV ' +
          '         PORT ARTHURLAAN 90        9000 GENT                 000');
        tempFile.Write('2100130000ZFFP02102 TBOINDNLOON1000000000562650140207001010000FA' +
          'CT 171144 KLANT 12032                              1402070300100');
        tempFile.Write('2200130000                                                     7' +
          '0090                        000000000000000                  100');
        tempFile.Write('2300130000685616301086                         NV FLUKE BELGIUM ' +
          '         LANGEVELDPARK UNIT7       1600 ST-PIETERS-LEE       000');
        tempFile.Write('2100140000ZFFP02103 TBOINDNLOON1000000000285310140207001010000FA' +
          'CT 0180688                                         1402070300100');
        tempFile.Write('2200140000                                                     6' +
          '1866                        000000000000000                  100');
        tempFile.Write('2300140000459250790127                         BINPAC           ' +
          '         IZ OOST, VRIJHEIDWEG 8    3700 TONGEREN             000');
        tempFile.Write('2100150000ZFFP02104 TBOINDNLOON1000000002860150140207001010000FA' +
          'CT 165279 280 161772 161896                        1402070300100');
        tempFile.Write('2200150000                                                     7' +
          '0092 87                     000000000000000                  100');
        tempFile.Write('2300150000443900193149                         CMAC             ' +
          '         IZ KL FRANKRIJK 28        9600 RONSE                000');
        tempFile.Write('2100160000ZFFP02105 TBOINDNLOON1000000001499400140207001010000BR' +
          'U0948706                                           1402070300100');
        tempFile.Write('2200160000                                                     7' +
          '0143                        000000000000000                  100');
        tempFile.Write('2300160000482910700226                         DHL              ' +
          '         POSTBUS 31                1831 DIEGEM               000');
        tempFile.Write('2100170000ZFFP02106 TBOINDNLOON1000000000092930140207001010000FA' +
          'CT614BE00972                                       1402070300100');
        tempFile.Write('2200170000                                                     6' +
          '1816                        000000000000000                  100');
        tempFile.Write('2300170000230099418451                         SEMIKRON         ' +
          '         LEUVENSESTEENWEG 510B9    1930 ZAVENTEM             000');
        tempFile.Write('2100180000ZFFP02107 TBOINDNLOON1000000000367840140207001010000FA' +
          'CT 70061248                                        1402070300100');
        tempFile.Write('2200180000                                                     6' +
          '1617                        000000000000000                  100');
        tempFile.Write('2300180000737427040422                         INTERCARE        ' +
          '         KORTE MAGERSTR 5          9050 GENTBRUGGE           000');
        tempFile.Write('2100190000ZFFP02108 TBOINDNLOON1000000000105390140207001010000FA' +
          'CT6069815                                          1402070300100');
        tempFile.Write('2200190000                                                     6' +
          '1921                        000000000000000                  100');
        tempFile.Write('2300190000230030914021                         VINK             ' +
          '         INDUSTRIEPARK 7           2220 HEIST-OP-DEN-B       000');
        tempFile.Write('2100200000ZFFP02109 TBOINDNLOON1000000000271800140207001010000FA' +
          'CT687804 685187 689218 695010 702325               1402070300100');
        tempFile.Write('2200200000                                                     7' +
          '0078 17                     000000000000000                  100');
        tempFile.Write('2300200000210049670015                         TNT              ' +
          '                                                             000');
        tempFile.Write('2100210000ZFFP02110 TBOINDNLOON1000000000623390140207001010000FA' +
          'CT 260620                                          1402070300100');
        tempFile.Write('2200210000                                                     6' +
          '1953                        000000000000000                  100');
        tempFile.Write('2300210000293021332779                         NOTEBAERT        ' +
          '         AALSTSTRAAT 6             9700 OUDENAARDE           000');
        tempFile.Write('2100220000ZFFP02111 TBOINDNLOON1000000003530760140207001010000FA' +
          'CT 28016690S01028                                  1402070300100');
        tempFile.Write('2200220000                                                     6' +
          '1751                        000000000000000                  100');
        tempFile.Write('2300220000285020504213                         BARCO KUURNE     ' +
          '         NOORDLAAN 5               8520 KUURNE               000');
        tempFile.Write('2100230000ZFFP02112 TBOINDNLOON1000000001116250140207001010000FA' +
          'CT F06121401                                       1402070300100');
        tempFile.Write('2200230000                                                     6' +
          '1911                        000000000000000                  100');
        tempFile.Write('2300230000063991768047                         CPE              ' +
          '         SCHEURBOEK 6A             9860 OOSTERZELE           000');
        tempFile.Write('2100240000ZFFP02113 TBOINDNLOON1000000003254900140207001010000FA' +
          'CT 7241730                                         1402070300100');
        tempFile.Write('2200240000                                                     7' +
          '0021                        000000000000000                  100');
        tempFile.Write('2300240000419706600164                         ECOMAL           ' +
          '         BATTelseSTWG 455E         2800 MECHELEN             000');
        tempFile.Write('2100250000ZFFP02114 TBOINDNLOON1000000000320650140207001010000FA' +
          'CT 23830                                           1402070300100');
        tempFile.Write('2200250000                                                     6' +
          '1886                        000000000000000                  100');
        tempFile.Write('2300250000320050648420                         PCB              ' +
          '         ELLERMANSTRAAT 74         2060 ANTWERPEN 6          000');
        tempFile.Write('2100260000ZFFP02115 TBOINDNLOON100000000092889014020700101000110' +
          '1000043806513                                      1402070300100');
        tempFile.Write('2200260000                                                     7' +
          '0100                        000000000000000                  100');
        tempFile.Write('2300260000435411161155                         PROXIMUS         ' +
          '         VOORTUIGANGSTRAAT 55      1210 BRUSSEL 21           000');
        tempFile.Write('2100270000ZFFP02116 TBOINDNLOON1000000003820840140207001010000FA' +
          'CT 111605534                                       1402070300100');
        tempFile.Write('2200270000                                                     6' +
          '1884                        000000000000000                  100');
        tempFile.Write('2300270000737502090534                         VANHOONACKER OUDE' +
          'NAARDE   WESTERING 31              9700 OUDENAARDE           000');
        tempFile.Write('2100280000OL9449950IUBOEUBTRFCS100000000070000013020734101000000' +
          '352037045A1181                                     1402070301100');
        tempFile.Write('2200280000                                                     7' +
          '0028                        000000000000000                  001');
        tempFile.Write('3100280001OL9449950IUBOEUBTRFCS341010001001VOGHT ELECTRONIC COMP' +
          'ONENT         VOGHT ELECTR PLATZ 1                           1 0');
        tempFile.Write('320028000194130 OBERNZELL DE                 DE                 ' +
          '                                                             0 1');
        tempFile.Write('3100280002OL9449950IUBOEUBTRFCS341010001002INV1038385           ' +
          '                                                             0 1');
        tempFile.Write('3100280003OL9449950IUBOEUBTRFCS341010001004COMMERZBANK AG       ' +
          '                                                             0 0');
        tempFile.Write('2100280004OL9449950IUBOEUBTRFCS100000000070000013020784101100110' +
          '5000000000700000000000000700000000100000000EUR     1402070301100');
        tempFile.Write('2200280004         000000000700000                              ' +
          '                            000000000000000                  000');
        tempFile.Write('2100290000OL9449951IUBOEUBTRFCS100000000024216013020734101000000' +
          '352037045A1180                                     1402070301100');
        tempFile.Write('2200290000                                                     3' +
          'INV                         000000000000000                  001');
        tempFile.Write('3100290001OL9449951IUBOEUBTRFCS341010001001DIGI KEY CORPORATION ' +
          '              PO BOX 52                                      1 0');
        tempFile.Write('32002900017500AB ENSCHEDE NL                 NL                 ' +
          '                                                             0 1');
        tempFile.Write('3100290002OL9449951IUBOEUBTRFCS341010001002INV22113733 2212     ' +
          '              3054 22123483                                  0 1');
        tempFile.Write('3100290003OL9449951IUBOEUBTRFCS341010001004LLOYDS TSB BANK PLC  ' +
          '                                                             0 0');
        tempFile.Write('2100290004OL9449951IUBOEUBTRFCS100000000024216013020784101100110' +
          '5000000000242160000000000242160000100000000EUR     1402070301100');
        tempFile.Write('2200290004         000000000242160                              ' +
          '                            000000000000000                  000');
        tempFile.Write('2100300000OL9449952IUBOEUBTRFCS100000000086000013020734101000000' +
          '352037045A1179                                     1402070301001');
        tempFile.Write('3100300001OL9449952IUBOEUBTRFCS341010001001BERGQUIST-ITC        ' +
          '              HADERSLEBENER STR. 19A                         1 0');
        tempFile.Write('320030000125421 PINNEBERG DE                 DE                 ' +
          '                                                             0 1');
        tempFile.Write('3100300002OL9449952IUBOEUBTRFCS341010001002INVOICE 94090        ' +
          '                                                             0 1');
        tempFile.Write('3100300003OL9449952IUBOEUBTRFCS341010001004DEUTSCHE BANK AG     ' +
          '                                                             0 0');
        tempFile.Write('2100300004OL9449952IUBOEUBTRFCS100000000086000013020784101100110' +
          '5000000000860000000000000860000000100000000EUR     1402070301100');
        tempFile.Write('2200300004         000000000860000                              ' +
          '                            000000000000000                  000');
        tempFile.Write('2100310000OL9449953IUBOEUBTRFCS100000000008150013020734101000000' +
          '352037045A1178                                     1402070301100');
        tempFile.Write('2200310000                                                     D' +
          'IV7014                      000000000000000                  001');
        tempFile.Write('3100310001OL9449953IUBOEUBTRFCS341010001001ABONNEMENTENLAND     ' +
          '              POSTBUS 20                                     1 0');
        tempFile.Write('32003100011910AA UITGEEST NL                 NL                 ' +
          '                                                             0 1');
        tempFile.Write('3100310002OL9449953IUBOEUBTRFCS341010001002FACTUUR 30370573     ' +
          '              KLANTNR 7682031                                0 1');
        tempFile.Write('3100310003OL9449953IUBOEUBTRFCS341010001004POSTBANK NV          ' +
          '                                                             0 0');
        tempFile.Write('2100310004OL9449953IUBOEUBTRFCS100000000008150013020784101100110' +
          '5000000000081500000000000081500000100000000EUR     1402070301100');
        tempFile.Write('2200310004         000000000081500                              ' +
          '                            000000000000000                  000');
        tempFile.Write('2100320000OL9449954IUBOEUBTRFCS100000000179300013020734101000000' +
          '352037045A1182                                     1402070301001');
        tempFile.Write('3100320001OL9449954IUBOEUBTRFCS341010001001ZUKEN BV             ' +
          '              SCHEPENLAAN 18A                                1 0');
        tempFile.Write('32003200016002EE WEERT NL                    NL                 ' +
          '                                                             0 1');
        tempFile.Write('3100320002OL9449954IUBOEUBTRFCS341010001002FACT ZNL100488       ' +
          '                                                             0 1');
        tempFile.Write('3100320003OL9449954IUBOEUBTRFCS341010001004ABN AMRO BANK NV     ' +
          '                                                             0 0');
        tempFile.Write('2100320004OL9449954IUBOEUBTRFCS100000000179300013020784101100110' +
          '5000000001793000000000001793000000100000000EUR     1402070301100');
        tempFile.Write('2200320004         000000001793000                              ' +
          '                            000000000000000                  000');
        tempFile.Write('8030290004614187 EUR0BE                  0000000237109580140207 ' +
          '                                                                ');
        tempFile.Write('9               000121000000052138710000000000000000            ' +
          '                                                               1');
        tempFile.Write('0000016020729005D  0000000074789  INVERTO NV                0000' +
          '000000000058315707 00000                                       1');
        tempFile.Write('1 031290004614187 EUR0BE                  0000000237109580150207' +
          'INVERTO NV                KBC-Bedrijfsrekening               001');
        tempFile.Write('2100010000AIBHA0AAN DOMNINDIN01100000000099810016020700501000110' +
          '7740784398863190207               0070142022      01602070310100');
        tempFile.Write('22000100000876383320                                            ' +
          '                            000000000000000                  100');
        tempFile.Write('2300010000000000000000                         D''IETEREN SERVICE' +
          'S                                                            000');
        tempFile.Write('2100020000AUBOA0CH4 DOMDCDDID01100000000003740016020700501000110' +
          '7740745036768190207F. 2007065205 DOMICIL.         01602070310100');
        tempFile.Write('22000200000455530509                                            ' +
          '                            000000000000000                  100');
        tempFile.Write('2300020000000000000000                         ISABEL           ' +
          '                                                             000');
        tempFile.Write('8031290004614187 EUR0BE                  0000000236074080160207 ' +
          '                                                                ');
        tempFile.Write('9               000008000000001035500000000000000000            ' +
          '                                                               1');
        tempFile.Write('0000019020729005D  0000000074789  INVERTO NV                0000' +
          '000000000058315707 00000                                       1');
        tempFile.Write('1 032290004614187 EUR0BE                  0000000236074080140207' +
          'INVERTO NV                KBC-Bedrijfsrekening               001');
        tempFile.Write('2100010000BJUA00109 TBOINDNLOON1000000001352480190207001010000ON' +
          'KOSTEN BELCOMP EN VDVIJVER                         1902070320100');
        tempFile.Write('2200010000                                                     D' +
          'IV ONKO                     000000000000000                  100');
        tempFile.Write('2300010000467538877123                         FIBECON BVBA     ' +
          '         MEERSBLOEM MELDEN 30      9700 OUDENAARDE           000');
        tempFile.Write('8032290004614187 EUR0BE                  0000000234721600190207 ' +
          '                                                                ');
        tempFile.Write('9               000005000000001352480000000000000000            ' +
          '                                                               1');
        tempFile.Write('0000020020729005D  0000000074789  INVERTO NV                0000' +
          '000000000058315707 00000                                       1');
        tempFile.Write('1 033290004614187 EUR0BE                  0000000234721600190207' +
          'INVERTO NV                KBC-Bedrijfsrekening               002');
        tempFile.Write('2100010000BNIVA0AMT DOMALGDOV01100000000039663020020700501000110' +
          '774071599264520020775560-LF-0  2584186   415775   02002070330100');
        tempFile.Write('22000100000426403684                                            ' +
          '                            000000000000000                  100');
        tempFile.Write('2300010000000000000000                         KBC LEASE BELGIUM' +
          '                                                             000');
        tempFile.Write('2100020000BOUJ01943 TBOINDNLOON100000001698636020020700101000110' +
          '1086444207901                                      2002070330100');
        tempFile.Write('2200020000                                                     A' +
          'ANSLJ 2                     000000000000000                  100');
        tempFile.Write('2300020000679200250133                         VENN BELAST      ' +
          '         G CROMMENLAAN 6 BUS 101   9050 LEDEBERG (GENT       000');
        tempFile.Write('2100030000BRLY08683BOVSBBNONTVA000000000030752020020700150000057' +
          '90131579 CREDITNOTA 010207                         2002070330100');
        tempFile.Write('2300030000000171003118                         Belgacom PO  NOOR' +
          'D        Stationsstraat, 58        2800 Mechelen             000');
        tempFile.Write('8033290004614187 EUR0BE                  0000000217646130200207 ' +
          '                                                                ');
        tempFile.Write('9               000010000000017382990000000000307520            ' +
          '                                                               2');
    end;

    local procedure WriteOnCODAScenario557240(var TempFile: File)
    begin
        TempFile.Write('0000016092430005        33610135  MY AMERICAN SHOP SRL      BBRUBEBB   00058315707 00000                                       2');
        TempFile.Write('12157BE75363216340251                  EUR0000000026688480150924MY AMERICAN SHOP SRL      Compte à vue                       157');
        TempFile.Write('2100010000CAL/F/1322404000639  1000000033671370160924030030000Mouvement lié à la transaction FXForward             16092415701 0');
        TempFile.Write('2200010000       - 33.671,37FXN71322404  (ING Trade : DI1242640                                                              1 0');
        TempFile.Write('2300010000                                                                        0P00106)                                   0 1');
        TempFile.Write('3100010001CAL/F/1322404000639  030030000Transaction FX Forward avec la référence 71322404 Conclue avec ING Belgiu            0 1');
        TempFile.Write('3100010002CAL/F/1322404000639  030030000m SA/NV le 16/09/2024 ING vous a acheté 33.671,37 EUR ING vous a vendu 37            0 1');
        TempFile.Write('3100010003CAL/F/1322404000639  030030000.400,00 USD Taux de change: 1,110736                                                 0 1');
        TempFile.Write('3100010004CAL/F/1322404000639  030030000MAMERICBAS                                                                           0 0');
        TempFile.Write('2100020000I160733008384000637  0000000009058060160924001500000YYW1036909217794/PAYPAL                              16092415701 0');
        TempFile.Write('2200020000                                                     YYW1036909217794                   PPLXLUL2                   1 0');
        TempFile.Write('2300020000LU89751000135104200E                 PayPal Europe S.a.r.l. et Cie S.C.A                                           0 1');
        TempFile.Write('3100020001I160733008384000637  001500001001PayPal Europe S.a.r.l. et Cie S.C.A                                               1 0');
        TempFile.Write('320002000122-24 Boulevard Royal, 2449 Luxembo                                                                                0 1');
        TempFile.Write('3100020002I160733008384000637  001500000Virement en euros (SEPA) De: PayPal Europe S.a.r.l. et Cie S.C.A 22-24 Bo            0 1');
        TempFile.Write('3100020003I160733008384000637  001500000ulevard Royal, 2449 Luxembourg Luxembourg IBAN: LU89751000135104200E Comm            0 1');
        TempFile.Write('3100020004I160733008384000637  001500000unication : YYW1036909217794/PAYPAL Info personnelle: YYW1036909217794               0 1');
        TempFile.Write('3100020005I160733008384000637  001500000Communication: YYW1036909217794/PAYPAL Info personnelle: YYW1036909217794            0 1');
        TempFile.Write('3100020006I160733008384000637  001500000                                                                                     0 0');
        TempFile.Write('2100030000I160918319904000640  0000000000018350160924001500000MYAMERICANSHOP                                       16092415701 0');
        TempFile.Write('2200030000                                                     MYAMERICA-MG1ZLB5GSYHFLPSAGKTRGPXDICITINL2X                   1 0');
        TempFile.Write('2300030000NL41CITI2032304805                   STRIPE                                                                        0 1');
        TempFile.Write('3100030001I160918319904000640  001500001001STRIPE                                                                            1 0');
        TempFile.Write('3200030001CO A L GOODBODY IFSC NORTH WALL QUA                                                                                0 1');
        TempFile.Write('3100030002I160918319904000640  001500000Virement en euros (SEPA) De: STRIPE CO A L GOODBODY IFSC NORTH WALL QUADU            0 1');
        TempFile.Write('3100030003I160918319904000640  001500000BLIN,DUBLIN 1,D01H104 Irlande (Eire) IBAN: NL41CITI2032304805 Communicati            0 1');
        TempFile.Write('3100030004I160918319904000640  001500000on : MYAMERICANSHOP Info personnelle: MYAMERICA-MG1ZLB5GSYHFLPSAGKTRGPXDI            0 1');
        TempFile.Write('3100030005I160918319904000640  001500000                                                                                     0 1');
        TempFile.Write('3100030006I160918319904000640  001500000Communication: MYAMERICANSHOP Info personnelle: MYAMERICA-MG1ZLB5GSYHFLPS            0 1');
        TempFile.Write('3100030007I160918319904000640  001500000AGKTRGPXDI                                                                           0 0');
        TempFile.Write('2100040000I161133458289000641  0000000017105830160924001500000REF T08123471.2409.11                                16092415701 0');
        TempFile.Write('2200040000                                                     T08123471.2409.11                  CITINL2X                   1 0');
        TempFile.Write('2300040000NL70CITI2032329018                   Stichting Mollie Payments                                                     0 1');
        TempFile.Write('3100040001I161133458289000641  001500001001Stichting Mollie Payments                                                         1 0');
        TempFile.Write('3200040001126Keizersgracht                   Amsterdam,1015 CW                                                               0 1');
        TempFile.Write('3100040002I161133458289000641  001500000Virement en euros (SEPA) De: Stichting Mollie Payments 126Keizersgracht A            0 1');
        TempFile.Write('3100040003I161133458289000641  001500000msterdam,1015 CW Pays-Bas IBAN: NL70CITI2032329018 Communication : REF T0            0 1');
        TempFile.Write('3100040004I161133458289000641  0015000008123471.2409.11 Info personnelle: T08123471.2409.11                                  0 1');
        TempFile.Write('3100040005I161133458289000641  001500000Communication: REF T08123471.2409.11 Info personnelle: T08123471.2409.11             0 1');
        TempFile.Write('3100040006I161133458289000641  001500000                                                                                     0 0');
        TempFile.Write('2100050000I161432508450000646  0000000006090410160924001500000YYW1036965172577/PAYPAL                              16092415701 0');
        TempFile.Write('2200050000                                                     YYW1036965172577                   PPLXLUL2                   1 0');
        TempFile.Write('2300050000LU89751000135104200E                 PayPal Europe S.a.r.l. et Cie S.C.A                                           0 1');
        TempFile.Write('3100050001I161432508450000646  001500001001PayPal Europe S.a.r.l. et Cie S.C.A                                               1 0');
        TempFile.Write('320005000122-24 Boulevard Royal, 2449 Luxembo                                                                                0 1');
        TempFile.Write('3100050002I161432508450000646  001500000Virement en euros (SEPA) De: PayPal Europe S.a.r.l. et Cie S.C.A 22-24 Bo            0 1');
        TempFile.Write('3100050003I161432508450000646  001500000ulevard Royal, 2449 Luxembourg Luxembourg IBAN: LU89751000135104200E Comm            0 1');
        TempFile.Write('3100050004I161432508450000646  001500000unication : YYW1036965172577/PAYPAL Info personnelle: YYW1036965172577               0 1');
        TempFile.Write('3100050005I161432508450000646  001500000Communication: YYW1036965172577/PAYPAL Info personnelle: YYW1036965172577            0 1');
        TempFile.Write('3100050006I161432508450000646  001500000                                                                                     0 0');
        TempFile.Write('21000600003506629111036000642  00000000005900001609240045300002024/PF/5889                                         16092415700 0');
        TempFile.Write('21000700003506629111037000643  00000000004100001609240045300002024/PF/5889                                         16092415700 0');
        TempFile.Write('21000800003506629111038000644  00000000047500001609240045300002024/PF/6201 +2K                                     16092415700 0');
        TempFile.Write('21000900003506629111039000645  00000000022900001609240045300002024/PF/6410                                         16092415700 0');
        TempFile.Write('21001000006667113656701000638  1000000011116800160924004030000ING : MASTERCARD  251     71136567-01/073 R.77113656716092415701 0');
        TempFile.Write('2200100000116                                                                                                                0 0');
        TempFile.Write('8157BE75363216340251                  EUR0000000022212960160924                                                                0');
        TempFile.Write('9               000056000000044788170000000040312650                                                                           1');
        TempFile.Write('0000016092430005        33610135  MY AMERICAN SHOP SRL      BBRUBEBB   00058315707 00000                                       2');
        TempFile.Write('12026BE75363216340251                  USD0000000022640040110924MY AMERICAN SHOP SRL      Compte à vue                       026');
        TempFile.Write('2100010000CAL/F/1322404000050  0000000037400000160924030520000Mouvement lié à la transaction FXForward             16092402601 0');
        TempFile.Write('2200010000       + 37.400,00FXN71322404  (ING Trade : DI1242640                                                              1 0');
        TempFile.Write('2300010000                                                                        0P00106)                                   0 1');
        TempFile.Write('3100010001CAL/F/1322404000050  030520000Transaction FX Forward avec la référence 71322404 Conclue avec ING Belgiu            0 1');
        TempFile.Write('3100010002CAL/F/1322404000050  030520000m SA/NV le 16/09/2024 ING vous a acheté 33.671,37 EUR ING vous a vendu 37            0 1');
        TempFile.Write('3100010003CAL/F/1322404000050  030520000.400,00 USD Taux de change: 1,110736                                                 0 1');
        TempFile.Write('3100010004CAL/F/1322404000050  030520000MAMERICBAS                                                                           0 0');
        TempFile.Write('21000200003771655794909000051  1000000059678000160924041010000Euroboisson 20248003                                 16092402601 0');
        TempFile.Write('2200020000                                                                                        NOSCCATT                   1 0');
        TempFile.Write('2300020000301710036013                      USDLaugin Solutions Inc                                                          0 1');
        TempFile.Write('31000200013771655794909000051  041010001001Laugin Solutions Inc                                                              1 0');
        TempFile.Write('3200020001 516 1ere Avenue Montreal CA                                                                                       0 1');
        TempFile.Write('31000200023771655794909000051  001500000Virement en euros (SEPA) De: PayPal Europe S.a.r.l. et Cie S.C.A 22-24 Bo            0 1');
        TempFile.Write('31000200033771655794909000051  04101000016H779456 Date valeur 16/09/2024 Lordre spécifie Tous frais à charge du              0 1');
        TempFile.Write('31000200043771655794909000051  041010000 bénéficiaire.Compte bénéf. 301710036013 Bénéficiaire : Laugin Solution              0 1');
        TempFile.Write('31000200053771655794909000051  041010000s Inc 516 1ere Avenue Montreal CA Communication Euroboisson 20248003 Corr            0 1');
        TempFile.Write('31000200063771655794909000051  041010000espondant : NOSCCATT BANK OF NOVA SCOTIA international banking division 4            0 1');
        TempFile.Write('31000200073771655794909000051  0410100004 KING STREET WEST Canada toronto ont m5h 1h1                                        0 1');
        TempFile.Write('31000200083771655794909000051  041010001004301710036013                                                                      0 1');
        TempFile.Write('31000200093771655794909000051  041010001001Laugin Solutions Inc                516 1ere Avenue Montreal CA                   0 1');
        TempFile.Write('31000200103771655794909000051  041010001002Euroboisson 20248003                                                              0 1');
        TempFile.Write('31000200113771655794909000051  041010001005NOSCCATT                                                                          0 1');
        TempFile.Write('31000200123771655794909000051  041010001105000000059678000000000059678000000100000000USD            CA00000005381            1 0');
        TempFile.Write('32000200127300                                                                                                               0 1');
        TempFile.Write('31000200133771655794909000051  041010000Pièce justificative en annexe                                                        0 0');
        TempFile.Write('8026BE75363216340251                  USD0000000000362040160924                                                                0');
        TempFile.Write('9               000027000000059678000000000037400000                                                                           2');
    end;

    local procedure WriteOnCODAScenario560840(var TempFile: File)
    begin
        TempFile.Write('0000004122330005        23362335  TELE-SECOURS ASBL         BBRUBEBB   00000000000 00000                                       2');
        TempFile.Write('12337BE04310075819431                  EUR0000000128771080031223TELE-SECOURS ASBL         Compte à vue                       337');
        TempFile.Write('2100010000DOMREC1814858002207  1000000000967490041223005010001127041223110BE12ZZZ0456810810                  10176204122333701 0');
        TempFile.Write('22000100002                            091736889225            A683PEF2                           GEBABEBB      0            1 0');
        TempFile.Write('2300010000BE05210023359975                  EURORANGE                                                                   0    0 1');
        TempFile.Write('3100010001DOMREC1814858002207  005010001001ORANGE                                                                            0 1');
        TempFile.Write('3100010002DOMREC1814858002207  005010000DEBIT POUR DOMICILIATION EN EUROS (SEPA) Ce jour, nous débitons votre com            0 1');
        TempFile.Write('3100010003DOMREC1814858002207  005010000pte en faveur de: ORANGE Identification: BE12 ZZZ 0456810810 Compte: BE05            0 1');
        TempFile.Write('3100010004DOMREC1814858002207  005010000210023359975 BIC: GEBABEBB Mandat: 1017622 Réglementation: SEPA SDD Core             0 1');
        TempFile.Write('3100010005DOMREC1814858002207  005010000Type: Encaissement récurrent Référence unique: A683PEF2 Communication: **            0 1');
        TempFile.Write('3100010006DOMREC1814858002207  005010000*091/7368/89225***                                                                   0 0');
        TempFile.Write('21000200003010483001553002208  0000000009330870041223201500000REGROUPEMENT DE    375 VCS                           04122333710 0');
        TempFile.Write('21000200013010483001553002208  0000000000021070041223601500000000006664001        000006664001                     04122333701 0');
        TempFile.Write('2200020001                                                     NOTPROVIDED                        BBRUBEBB                   1 0');
        TempFile.Write('2300020001BE07363129032066                     M OLIVER EMMES                                                                0 1');
        TempFile.Write('31000200023010483001553002208  601500001001M OLIVER EMMES                                                                    1 0');
        TempFile.Write('3200020002RUE DU SCEPTRE 10/1E               1050        IXELLES                                                             0 0');
        TempFile.Write('21000200033010483001553002208  0000000000021070041223601500000                                                     04122333701 0');
        TempFile.Write('2200020003                                                     NOTPROVIDED                        BBRUBEBB                   1 0');
        TempFile.Write('2300020003BE89310022988985                     M ANDRE BLONDEAU                                                              0 1');
        TempFile.Write('31000200043010483001553002208  601500001001M ANDRE BLONDEAU                                                                  1 0');
        TempFile.Write('3200020004AV EDM PARMENTIER 124/105          1150        ST-PIET-WOLUWE                                                      0 0');
        TempFile.Write('21000200053010483001553002208  0000000000015400041223601500000abonnement mensuel                                   04122333701 0');
        TempFile.Write('2200020005                                                     NOTPROVIDED                        BBRUBEBB                   1 0');
        TempFile.Write('2300020005BE61363197897117                     TRAUTTMANSDORFF-WEINSBERG                                                     0 1');
        TempFile.Write('31000200063010483001553002208  601500001001TRAUTTMANSDORFF-WEINSBERG                                                         1 0');
        TempFile.Write('3200020006AV F ROOSEVELT 91                  1050        IXELLES                                                             0 0');
        TempFile.Write('21000200073010483001553002208  0000000000015400041223601500000000009423649        000/0094/23649                   04122333701 0');
        TempFile.Write('2200020007                                                     NOTPROVIDED                        BBRUBEBB                   1 0');
        TempFile.Write('2300020007BE64310142994052                     M MICHEL DAWANT                                                               0 1');
        TempFile.Write('31000200083010483001553002208  601500001001M MICHEL DAWANT                                                                   1 0');
        TempFile.Write('3200020008RUE VERGOTE 30                     1200        ST-LAMB-WOLUWE                                                      0 0');
        TempFile.Write('21000200093010483001553002208  0000000000015400041223601500000abonnement tele secours - reference: 73725           04122333701 0');
        TempFile.Write('2200020009                                                     NOTPROVIDED                        BBRUBEBB                   1 0');
        TempFile.Write('2300020009BE85363030852306                     MME CLAUDE PENTECOST                                                          0 1');
        TempFile.Write('31000200103010483001553002208  601500001001MME CLAUDE PENTECOST                                                              1 0');
        TempFile.Write('3200020010AV DE L OBSERVATOIRE  9/6          1180        UCCLE                                                               0 0');
        TempFile.Write('21000200113010483001553002208  0000000000015400041223601500000Beullens Cecile                                      04122333701 0');
        TempFile.Write('2200020011                                                     NOTPROVIDED                        GKCCBEBB                   1 0');
        TempFile.Write('2300020011BE23063960664591                     Beullens Cecile                                                               0 1');
        TempFile.Write('31000200123010483001553002208  601500001001Beullens Cecile                                                                   1 0');
        TempFile.Write('3200020012CHAUSSEE DE LOUVAIN    316         5004  BOUGE                                                                     0 0');
        TempFile.Write('21000200133010483001553002208  0000000000015400041223601500000Reference client 75701                               04122333701 0');
        TempFile.Write('2200020013                                                     176631995                          GEBABEBB                   1 0');
        TempFile.Write('2300020013BE03210076642984                     RAYMOND DE L HOTELLERIE                                                       0 1');
        TempFile.Write('31000200143010483001553002208  601500001001RAYMOND DE L HOTELLERIE                                                           1 0');
        TempFile.Write('3200020014Av.des Traquets 147    000-B       1160 AUDERGHEM                                                                  0 0');
        TempFile.Write('21000200153010483001553002208  0000000000015400041223601500000Contrat affiliation 94445                            04122333701 0');
        TempFile.Write('2200020015                                                     174660710                          GEBABEBB                   1 0');
        TempFile.Write('2300020015BE36271080514981                     LE SERGEANT DHENDECOURT A                                                     0 1');
        TempFile.Write('31000200163010483001553002208  601500001001LE SERGEANT DHENDECOURT A                                                         1 0');
        TempFile.Write('3200020016av.  Combattants 86     1          1332 GENVAL                                                                     0 0');
        TempFile.Write('21000200173010483001553002208  0000000000015400041223601500000                                                     04122333701 0');
        TempFile.Write('2200020017                                                     176747448                          GEBABEBB                   1 0');
        TempFile.Write('2300020017BE50001522319818                     GLINNE MICHELE                                                                0 1');
        TempFile.Write('31000200183010483001553002208  601500001001GLINNE MICHELE                                                                    1 0');
        TempFile.Write('3200020018RUE DES MARTYRS 12                 7040 QUEVY                                                                      0 0');
        TempFile.Write('21000200193010483001553002208  0000000000015400041223601500000CONTRAT DAFFILIATION NUMERO 304059                   04122333701 0');
        TempFile.Write('2200020019                                                     176685018                          GEBABEBB                   1 0');
        TempFile.Write('2300020019BE64240010849452                     DEMBLON MONIQUE                                                               0 1');
        TempFile.Write('31000200203010483001553002208  601500001001DEMBLON MONIQUE                                                                   1 0');
        TempFile.Write('3200020020Rue de lHopital 7                 4540 AMAY                                                                        0 0');
        TempFile.Write('21000200213010483001553002208  0000000000021070041223601500000REFERENCES 65283                                     04122333701 0');
        TempFile.Write('2200020021                                                     171150225                          GEBABEBB                   1 0');
        TempFile.Write('2300020021BE23210013496691                     MME SUZANNE RUCQUOY                                                           0 1');
        TempFile.Write('31000200223010483001553002208  601500001001MME SUZANNE RUCQUOY                                                               1 0');
        TempFile.Write('3200020022Avenue de lAurore 4               1950 KRAAINEM                                                                    0 0');
        TempFile.Write('21000200233010483001553002208  0000000000021070041223601500000                                                     04122333701 0');
        TempFile.Write('2200020023                                                     NOTPROVIDED                        GEBABEBB                   1 0');
        TempFile.Write('2300020023BE91210057009376                     COLLIGNON NICOLE                                                              0 1');
        TempFile.Write('31000200243010483001553002208  601500001001COLLIGNON NICOLE                                                                  1 0');
        TempFile.Write('3200020024RUE DES IBIS 1                     1170     WATERMAEL-BOITSFORT                                                    0 0');
        TempFile.Write('21000200253010483001553002208  0000000000005400041223601500000                                                     04122333701 0');
        TempFile.Write('2200020025                                                     NOTPROVIDED                        GKCCBEBB                   1 0');
        TempFile.Write('2300020025BE41063106658710                     ALLAERTS LYDIE                                                                0 1');
        TempFile.Write('31000200263010483001553002208  601500001001ALLAERTS LYDIE                                                                    1 0');
        TempFile.Write('3200020026RUE FAYS                79         4400  FLEMALLE                                                                  0 0');
        TempFile.Write('21000200273010483001553002208  0000000000015400041223601500000                                                     04122333701 0');
        TempFile.Write('2200020027                                                     NOTPROVIDED                        CPHBBE75                   1 0');
        TempFile.Write('2300020027BE08126204906813                     M., Mme SIMON GODEAU Armand                                                   0 1');
        TempFile.Write('31000200283010483001553002208  601500001001M., Mme SIMON GODEAU Armand                                                       1 0');
        TempFile.Write('3200020028Rue Cardinal Mercier 2 /A/3        6150      ANDERLUES                                                             0 0');
        TempFile.Write('21000200293010483001553002208  0000000000015400041223601500000000009860755        000/0098/60755 REGINE MASURE     04122333701 0');
        TempFile.Write('2200020029                                                     NOTPROVIDED                        CREGBEBB                   1 0');
        TempFile.Write('2300020029BE49732032351571                     MASURE REGINE                                                                 0 1');
        TempFile.Write('31000200303010483001553002208  601500001001MASURE REGINE                                                                     1 0');
        TempFile.Write('3200020030CHAUSSEE DE TOURNAI  92            7520    RAMEGNIES-CHIN                                                          0 0');
        TempFile.Write('21000200313010483001553002208  0000000000023000041223601500000000030047566        30047566                         04122333701 0');
        TempFile.Write('2200020031                                                     NOTPROVIDED                        GEBABEBB                   1 0');
        TempFile.Write('2300020031BE41210022412510                     VANDEN BORREN GHISLAINE                                                       0 1');
        TempFile.Write('31000200323010483001553002208  601500001001VANDEN BORREN GHISLAINE                                                           1 0');
        TempFile.Write('3200020032Rue Henri Vieuxtemps 9             1070     ANDERLECHT                                                             0 0');
        TempFile.Write('21000200333010483001553002208  0000000000015400041223601500000                                                     04122333701 0');
        TempFile.Write('2200020033                                                     NOTPROVIDED                        KREDBEBB                   1 0');
        TempFile.Write('2300020033BE96433809298105                     DE CATERS MARIE                                                               0 1');
        TempFile.Write('31000200343010483001553002208  601500001001DE CATERS MARIE                                                                   1 0');
        TempFile.Write('3200020034VAL DU SCHEID        80            2517    LUXEMBOURG                                                              0 0');
        TempFile.Write('21000200353010483001553002208  000000000001540004122360150000017/06/19459 (FERRARINI LUCIA 73316)                  04122333701 0');
        TempFile.Write('2200020035                                                     NOTPROVIDED                        GKCCBEBB                   1 0');
        TempFile.Write('2300020035BE75063989391951                     FERRARINI LUCIA                                                               0 1');
        TempFile.Write('31000200363010483001553002208  601500001001FERRARINI LUCIA                                                                   1 0');
        TempFile.Write('3200020036RUE PAIROIS            111         7370  DOUR                                                                      0 0');
        TempFile.Write('21000200373010483001553002208  0000000000021070041223601500000ref client 94724                                     04122333701 0');
        TempFile.Write('2200020037                                                     175224955                          GEBABEBB                   1 0');
        TempFile.Write('2300020037BE86210023987950                     CHARLES AGNES                                                                 0 1');
        TempFile.Write('31000200383010483001553002208  601500001001CHARLES AGNES                                                                     1 0');
        TempFile.Write('3200020038Av.Leo.Wiener 22     A             1170 WATERMAEL-BOITSFORT                                                        0 0');
        TempFile.Write('21000200393010483001553002208  0000000000015400041223601500000                                                     04122333701 0');
        TempFile.Write('2200020039                                                     NOTPROVIDED                        GKCCBEBB                   1 0');
        TempFile.Write('2300020039BE95063229960258                     VANDEREST ISABELLE                                                            0 1');
        TempFile.Write('31000200403010483001553002208  601500001001VANDEREST ISABELLE                                                                1 0');
        TempFile.Write('3200020040RUE JOSEPH WAUTERS   50 33         4520  WANZE                                                                     0 0');
        TempFile.Write('21000200413010483001553002208  0000000000029000041223601500000                                                     04122333701 0');
        TempFile.Write('2200020041                                                     NOTPROVIDED                        GKCCBEBB                   1 0');
        TempFile.Write('2300020041BE27063945375573                     UYTDENBROEK MICHEL                                                            0 1');
        TempFile.Write('31000200423010483001553002208  601500001001UYTDENBROEK MICHEL                                                                1 0');
        TempFile.Write('3200020042RUE GENERAL HENRY       19         1040  BRUXELLES                                                                 0 0');
        TempFile.Write('21000200433010483001553002208  0000000000021070041223601500000                                                     04122333701 0');
        TempFile.Write('2200020043                                                     172130388                          GEBABEBB                   1 0');
        TempFile.Write('2300020043BE73210025686460                     ANSKENS ROSITA                                                                0 1');
        TempFile.Write('31000200443010483001553002208  601500001001ANSKENS ROSITA                                                                    1 0');
        TempFile.Write('3200020044AVENUE DES ROSSIGNOLS 15           1970 WEZEMBEEK-OPPEM                                                            0 0');
        TempFile.Write('21000200453010483001553002208  0000000000021070041223601500000REF 88492                                            04122333701 0');
        TempFile.Write('2200020045                                                     NOTPROVIDED                        KREDBEBB                   1 0');
        TempFile.Write('2300020045BE76437705603195                     VANBIERVLIET YVONNE                                                           0 1');
        TempFile.Write('31000200463010483001553002208  601500001001VANBIERVLIET YVONNE                                                               1 0');
        TempFile.Write('3200020046WEERSTANDSTRAAT      51   B5       1140    EVERE                                                                   0 0');
        TempFile.Write('21000200473010483001553002208  0000000000017400041223601500000ref client 71998                                     04122333701 0');
        TempFile.Write('2200020047                                                     NOTPROVIDED                        GKCCBEBB                   1 0');
        TempFile.Write('2300020047BE35063041477437                     DENIS MARIE-THERESE                                                           0 1');
        TempFile.Write('31000200483010483001553002208  601500001001DENIS MARIE-THERESE                                                               1 0');
        TempFile.Write('3200020048RUE DU GRAND PRE        12         5500  DINANT                                                                    0 0');
        TempFile.Write('21000200493010483001553002208  0000000000021070041223601500000                                                     04122333701 0');
        TempFile.Write('2200020049                                                     NOTPROVIDED                        GKCCBEBB                   1 0');
        TempFile.Write('2300020049BE80063180967477                     Verhulst Dominique                                                            0 1');
        TempFile.Write('31000200503010483001553002208  601500001001Verhulst Dominique                                                                1 0');
        TempFile.Write('3200020050AVENUE LE MARINEL    151/7         1040  BRUXELLES                                                                 0 0');
        TempFile.Write('21000200513010483001553002208  0000000000017400041223601500000NUM DE FACTURE 12/12/27126   REF CLIENT 70196        04122333701 0');
        TempFile.Write('2200020051                                                     162746235                          GEBABEBB                   1 0');
        TempFile.Write('2300020051BE07001201264366                     WYNANTS PAULA                                                                 0 1');
        TempFile.Write('31000200523010483001553002208  601500001001WYNANTS PAULA                                                                     1 0');
        TempFile.Write('3200020052Av. Dr E.Cordier 25                1160 AUDERGHEM                                                                  0 0');
        TempFile.Write('21000200533010483001553002208  0000000000015400041223601500000000009102438        +++000/0091/02438+++             04122333701 0');
        TempFile.Write('2200020053                                                     NOTPROVIDED                        BPOTBEB1                   1 0');
        TempFile.Write('2300020053BE37000093384728                     Mme MARIA MOMBERS                                                             0 1');
        TempFile.Write('31000200543010483001553002208  601500001001Mme MARIA MOMBERS                                                                 1 0');
        TempFile.Write('3200020054AVENUE DE LA STATION,15 /0011      4130 ESNEUX                                                                     0 0');
        TempFile.Write('21000200553010483001553002208  0000000000017400041223601500000000008780116        000/0087/80116                   04122333701 0');
        TempFile.Write('2200020055                                                     NOTPROVIDED                        BPOTBEB1                   1 0');
        TempFile.Write('2300020055BE69000010435378                     Mme MARIE BRONCHAIN                                                           0 1');
        TempFile.Write('31000200563010483001553002208  601500001001Mme MARIE BRONCHAIN                                                               1 0');
        TempFile.Write('3200020056RUE NAYABOIS, 19                   6030 CHARLEROI                                                                  0 0');
        TempFile.Write('21000200573010483001553002208  0000000000015400041223601500000000009789825        000009789825                     04122333701 0');
        TempFile.Write('2200020057                                                     NOTPROVIDED                        BPOTBEB1XXX                1 0');
        TempFile.Write('2300020057BE82000068023268                     M. Pierre Cavrot                                                              0 1');
        TempFile.Write('31000200583010483001553002208  601500001001M. Pierre Cavrot                                                                  1 0');
        TempFile.Write('3200020058Avenue Jean de Luxembourg,29       1330 RIXENSART                                                                  0 0');
        TempFile.Write('21000200593010483001553002208  0000000002107000041223601500000                                                     04122333701 0');
        TempFile.Write('2200020059                                                     NOTPROVIDED                        BPOTBEB1                   1 0');
        TempFile.Write('2300020059BE53000024381453                     Mme ELISABETH PHILIPPE                                                        0 1');
        TempFile.Write('31000200603010483001553002208  601500001001Mme ELISABETH PHILIPPE                                                            1 0');
        TempFile.Write('3200020060RUE DU GOUVERNEMENT, 24            7000 MONS                                                                       0 0');
        TempFile.Write('21000200613010483001553002208  0000000000017400041223601500000000030355340        000/0303/55340                   04122333701 0');
        TempFile.Write('2200020061                                                     NOTPROVIDED                        BBRUBEBB                   1 0');
        TempFile.Write('2300020061BE14363233551283                     MME MAGUY NANIOT                                                              0 1');
        TempFile.Write('31000200623010483001553002208  601500001001MME MAGUY NANIOT                                                                  1 0');
        TempFile.Write('3200020062RUE DU CHAUFOUR 54/A               5190        SPY                                                                 0 0');
        TempFile.Write('21000200633010483001553002208  0000000000023000041223601500000000009790027        000009790027                     04122333701 0');
        TempFile.Write('2200020063                                                     NOTPROVIDED                        CREGBEBBXXX                1 0');
        TempFile.Write('2300020063BE74732020288007                     TANNIER VALENTIN                                                              0 1');
        TempFile.Write('31000200643010483001553002208  601500001001TANNIER VALENTIN                                                                  1 0');
        TempFile.Write('3200020064RUE DU BIENNE        11            1350     FOLX-LES-CAVES                                                         0 0');
        TempFile.Write('21000200653010483001553002208  0000000000023000041223601500000000009790027        000009790027                     04122333701 0');
        TempFile.Write('2200020065                                                     NOTPROVIDED                        CREGBEBBXXX                1 0');
        TempFile.Write('2300020065BE74732020288007                     TANNIER VALENTIN                                                              0 1');
        TempFile.Write('31000200663010483001553002208  601500001001TANNIER VALENTIN                                                                  1 0');
        TempFile.Write('3200020066RUE DU BIENNE        11            1350     FOLX-LES-CAVES                                                         0 0');
        TempFile.Write('21000200673010483001553002208  0000000000017400041223601500000Ref. 65479                                           04122333701 0');
        TempFile.Write('2200020067                                                     I65V23336L021881                   CTBKBEBX                   1 0');
        TempFile.Write('2300020067BE69134501303978                     MME LILIANE WINTQUIN                                                          0 1');
        TempFile.Write('31000200683010483001553002208  601500001001MME LILIANE WINTQUIN                                                              1 0');
        TempFile.Write('3200020068AVENUE GOUVERNEUR BOVESSE 13 BTE 175100 JAMBES                                                                     0 0');
        TempFile.Write('21000200693010483001553002208  0000000000015400041223601500000000030444761        +++000/0304/44761+++             04122333701 0');
        TempFile.Write('2200020069                                                     NOTPROVIDED                        BBRUBEBB                   1 0');
        TempFile.Write('2300020069BE11363237117348                     M VINCENT LOHEST                                                              0 1');
        TempFile.Write('31000200703010483001553002208  601500001001M VINCENT LOHEST                                                                  1 0');
        TempFile.Write('3200020070TIENNE STRICHEAUX 60               1370        JODOIGNE                                                            0 0');
        TempFile.Write('21000200713010483001553002208  0000000000023000041223601500000                                                     04122333701 0');
        TempFile.Write('2200020071                                                     NOTPROVIDED                        BBRUBEBB                   1 0');
        TempFile.Write('2300020071BE49363169471871                     MME NICOLE COLLIN                                                             0 1');
        TempFile.Write('31000200723010483001553002208  601500001001MME NICOLE COLLIN                                                                 1 0');
        TempFile.Write('3200020072PLACE E FLAGEY 31 BT 8             1050        IXELLES                                                             0 0');
        TempFile.Write('21000200733010483001553002208  0000000000015400041223601500000MME AMALIA ZERRA                                     04122333701 0');
        TempFile.Write('2200020073                                                     I65V23335L029078                   CTBKBEBX                   1 0');
        TempFile.Write('2300020073BE54954749786197                     MME AMALIA ZERRA                                                              0 1');
        TempFile.Write('31000200743010483001553002208  601500001001MME AMALIA ZERRA                                                                  1 0');
        TempFile.Write('3200020074RUE DE SARS 44                     7080 FRAMERIES                                                                  0 0');
        TempFile.Write('21000200753010483001553002208  0000000000015400041223601500000000007756764        000007756764                     04122333701 0');
        TempFile.Write('2200020075                                                     NOTPROVIDED                        BBRUBEBB                   1 0');
        TempFile.Write('2300020075BE98363168154893                     M CLAUDE BRISMEE                                                              0 1');
        TempFile.Write('31000200763010483001553002208  601500001001M CLAUDE BRISMEE                                                                  1 0');
        TempFile.Write('3200020076CHAUSSEE DE NIVELLES 15            6230        PONT-A-CELLES                                                       0 0');
        TempFile.Write('21000200773010483001553002208  0000000000023000041223601500000000030412631        000030412631                     04122333701 0');
        TempFile.Write('2200020077                                                     NOTPROVIDED                        CREGBEBBXXX                1 0');
        TempFile.Write('2300020077BE95732048529858                     DE RUYTER-MICHEL V + C                                                        0 1');
        TempFile.Write('31000200783010483001553002208  601500001001DE RUYTER-MICHEL V + C                                                            1 0');
        TempFile.Write('3200020078RUE DES FOUGERES     25   BIS      7500     TOURNAI                                                                0 0');
        TempFile.Write('21000200793010483001553002208  0000000000017400041223601500000000030123651        000/0301/23651                   04122333701 0');
        TempFile.Write('2200020079                                                     NOTPROVIDED                        BBRUBEBB                   1 0');
        TempFile.Write('2300020079BE19370017520412                     MME NICOLE PIENS                                                              0 1');
        TempFile.Write('31000200803010483001553002208  601500001001MME NICOLE PIENS                                                                  1 0');
        TempFile.Write('3200020080AV DES SPORTS 15                   7020        NIMY                                                                0 0');
        TempFile.Write('21000200813010483001553002208  0000000000015400041223601500000                                                     04122333701 0');
        TempFile.Write('2200020081                                                     NOTPROVIDED                        BBRUBEBB                   1 0');
        TempFile.Write('2300020081BE60363236605470                     VANDEMEULEBROUCKE                                                             0 1');
        TempFile.Write('31000200823010483001553002208  601500001001VANDEMEULEBROUCKE                                                                 1 0');
        TempFile.Write('3200020082AV E MESENS 80                     1040        ETTERBEEK                                                           0 0');
        TempFile.Write('21000200833010483001553002208  0000000000029000041223601500000000009355547        000009355547                     04122333701 0');
        TempFile.Write('2200020083                                                     NOTPROVIDED                        CREGBEBBXXX                1 0');
        TempFile.Write('2300020083BE07732061761466                     DEDECKER BERNADETTE                                                           0 1');
        TempFile.Write('31000200843010483001553002208  601500001001DEDECKER BERNADETTE                                                               1 0');
        TempFile.Write('3200020084RUE DES FOURCHES     57            7904     PIPAIX                                                                 0 0');
        TempFile.Write('21000200853010483001553002208  0000000000015400041223601500000000030103039        000030103039                     04122333701 0');
        TempFile.Write('2200020085                                                     NOTPROVIDED                        CREGBEBBXXX                1 0');
        TempFile.Write('2300020085BE24732068005438                     DEGEN DANIELLE                                                                0 1');
        TempFile.Write('31000200863010483001553002208  601500001001DEGEN DANIELLE                                                                    1 0');
        TempFile.Write('3200020086AV.ALEXANDRE BERTRAND52   B10      1190     BRUXELLES                                                              0 0');
        TempFile.Write('21000200873010483001553002208  0000000000025000041223601500000000030086467        000030086467                     04122333701 0');
        TempFile.Write('2200020087                                                     NOTPROVIDED                        CREGBEBBXXX                1 0');
        TempFile.Write('2300020087BE18732027578565                     DEPREZ POL                                                                    0 1');
        TempFile.Write('31000200883010483001553002208  601500001001DEPREZ POL                                                                        1 0');
        TempFile.Write('3200020088RUE GONTRAN BACHY    7             7032     SPIENNES                                                               0 0');
        TempFile.Write('21000200893010483001553002208  0000000000015400041223601500000000030088184        000030088184                     04122333701 0');
        TempFile.Write('2200020089                                                     NOTPROVIDED                        KREDBEBBXXX                1 0');
        TempFile.Write('2300020089BE29735047169064                     ANCIAUX SYLVIE                                                                0 1');
        TempFile.Write('31000200903010483001553002208  601500001001ANCIAUX SYLVIE                                                                    1 0');
        TempFile.Write('3200020090CLOS DE LOASIS      26            1140     EVERE                                                                   0 0');
        TempFile.Write('21000200913010483001553002208  0000000000015400041223601500000000008817195        000008817195                     04122333701 0');
        TempFile.Write('2200020091                                                     NOTPROVIDED                        BBRUBEBB                   1 0');
        TempFile.Write('2300020091BE04363183717131                     MME LUCIE BOUCQUEY FOUARGE                                                    0 1');
        TempFile.Write('31000200923010483001553002208  601500001001MME LUCIE BOUCQUEY FOUARGE                                                        1 0');
        TempFile.Write('3200020092AV MONTGOLFIER 7                   1150        ST-PIET-WOLUWE                                                      0 0');
        TempFile.Write('21000200933010483001553002208  0000000000023000041223601500000000009430117        000/0094/30117                   04122333701 0');
        TempFile.Write('2200020093                                                     NOTPROVIDED                        BBRUBEBB                   1 0');
        TempFile.Write('2300020093BE06363039962222                     VANCUTSEM DUBOIS                                                              0 1');
        TempFile.Write('31000200943010483001553002208  601500001001VANCUTSEM DUBOIS                                                                  1 0');
        TempFile.Write('3200020094RUE WAYEZ 73                       1420        BRAINE-LALLEU                                                       0 0');
        TempFile.Write('21000200953010483001553002208  0000000000029000041223601500000000030454865        +++000/0304/54865+++             04122333701 0');
        TempFile.Write('2200020095                                                     NOTPROVIDED                        BBRUBEBB                   1 0');
        TempFile.Write('2300020095BE32310060830002                     MME GEORGETTE LEBLICQ                                                         0 1');
        TempFile.Write('31000200963010483001553002208  601500001001MME GEORGETTE LEBLICQ                                                             1 0');
        TempFile.Write('3200020096AV FRANKLIN ROOSEVELT 124          1330        RIXENSART                                                           0 0');
        TempFile.Write('21000200973010483001553002208  0000000000015400041223601500000000009491852        000009491852                     04122333701 0');
        TempFile.Write('2200020097                                                     NOTPROVIDED                        KREDBEBBXXX                1 0');
        TempFile.Write('2300020097BE69432918176178                     ROMDENNE JACQUELINE                                                           0 1');
        TempFile.Write('31000200983010483001553002208  601500001001ROMDENNE JACQUELINE                                                               1 0');
        TempFile.Write('3200020098RUE DE MEXICO        19   B0002    1080     MOLENBEEK-SAINT-JEAN                                                   0 0');
        TempFile.Write('21000200993010483001553002208  0000000000023000041223601500000000009094859        000-0090-94859                   04122333701 0');
        TempFile.Write('2200020099                                                     NOTPROVIDED                        BBRUBEBB                   1 0');
        TempFile.Write('2300020099BE68630051708234                     GRUMIAUX CHRISTOPHE GESTIO                                                    0 1');
        TempFile.Write('31000201003010483001553002208  601500001001GRUMIAUX CHRISTOPHE GESTIO                                                        1 0');
        TempFile.Write('3200020100RUE CLEMENCEAU 1                   7340        COLFONTAINE                                                         0 0');
        TempFile.Write('21000201013010483001553002208  0000000000015400041223601500000000008786681        000008786681                     04122333701 0');
        TempFile.Write('2200020101                                                     NOTPROVIDED                        KREDBEBBXXX                1 0');
        TempFile.Write('2300020101BE88735026253541                     ALLARD LUDOVIC                                                                0 1');
        TempFile.Write('31000201023010483001553002208  601500001001ALLARD LUDOVIC                                                                    1 0');
        TempFile.Write('3200020102CHAUSSEE DE WATERLOO 1525 B28      1180     UCCLE                                                                  0 0');
        TempFile.Write('21000201033010483001553002208  0000000000021070041223601500000000009672314        000009672314                     04122333701 0');
        TempFile.Write('2200020103                                                     NOTPROVIDED                        KREDBEBBXXX                1 0');
        TempFile.Write('2300020103BE96737048292505                     BUYSSE ISABELLE                                                               0 1');
        TempFile.Write('31000201043010483001553002208  601500001001BUYSSE ISABELLE                                                                   1 0');
        TempFile.Write('3200020104AV. DES FRANCISCAINS 24            1150     WOLUWE-SAINT-PIERRE                                                    0 0');
        TempFile.Write('21000201053010483001553002208  0000000000021070041223601500000000030185083        000030185083                     04122333701 0');
        TempFile.Write('2200020105                                                     NOTPROVIDED                        CREGBEBBXXX                1 0');
        TempFile.Write('2300020105BE78732328018786                     MAUROY JENNY                                                                  0 1');
        TempFile.Write('31000201063010483001553002208  601500001001MAUROY JENNY                                                                      1 0');
        TempFile.Write('3200020106AVENUE DES DEPORTES  16            1367     GEROMPONT                                                              0 0');
        TempFile.Write('21000201073010483001553002208  0000000000023000041223601500000000009698380        000/0096/98380                   04122333701 0');
        TempFile.Write('2200020107                                                     11/23                              BBRUBEBB                   1 0');
        TempFile.Write('2300020107BE08363234329913                     LISON MICHELE - GESTION                                                       0 1');
        TempFile.Write('31000201083010483001553002208  601500001001LISON MICHELE - GESTION                                                           1 0');
        TempFile.Write('3200020108AVENUE MINERVE 3/188               1190        FOREST                                                              0 0');
        TempFile.Write('21000201093010483001553002208  0000000000029000041223601500000000006430591        000/0064/30591                   04122333701 0');
        TempFile.Write('2200020109                                                     NOTPROVIDED                        BBRUBEBB                   1 0');
        TempFile.Write('2300020109BE80630025144277                     AP MME ANNE KOHLER                                                            0 1');
        TempFile.Write('31000201103010483001553002208  601500001001AP MME ANNE KOHLER                                                                1 0');
        TempFile.Write('3200020110CH DE BRUXELLES 287                1190        FOREST                                                              0 0');
        TempFile.Write('21000201113010483001553002208  0000000000015400041223601500000000007727967        000007727967                     04122333701 0');
        TempFile.Write('2200020111                                                     NOTPROVIDED                        CREGBEBBXXX                1 0');
        TempFile.Write('2300020111BE74732658130907                     DEBODINANCE ALICE                                                             0 1');
        TempFile.Write('31000201123010483001553002208  601500001001DEBODINANCE ALICE                                                                 1 0');
        TempFile.Write('3200020112RUE DU HAMBEAU       18            5580     ROCHEFORT                                                              0 0');
        TempFile.Write('21000201133010483001553002208  0000000000015400041223601500000000009521255        000/0095/21255                   04122333701 0');
        TempFile.Write('2200020113                                                     20231204CEC101003997-00105         KEYTBEBB                   1 0');
        TempFile.Write('2300020113BE89651165877985                     Jacques Remi                                                                  0 1');
        TempFile.Write('31000201143010483001553002208  601500001001Jacques Remi                                                                      1 0');
        TempFile.Write('3200020114Bld Louis Mettewie 91B9            1080 Molenbeek Saint Jean                                                       0 0');
        TempFile.Write('21000201153010483001553002208  0000000000015400041223601500000Mme IRMA LECLERE                                     04122333701 0');
        TempFile.Write('2200020115                                                     VZ33363AS4KBGM01                   CTBKBEBX                   1 0');
        TempFile.Write('2300020115BE68953144274634                     Mme IRMA LECLERE                                                              0 1');
        TempFile.Write('31000201163010483001553002208  601500001001Mme IRMA LECLERE                                                                  1 0');
        TempFile.Write('3200020116RUE ALEX FOUARGE 3                 4540 AMAY                                                                       0 0');
        TempFile.Write('21000201173010483001553002208  0000000000021070041223601500000000030066158        000030066158                     04122333701 0');
        TempFile.Write('2200020117                                                     NOTPROVIDED                        ARSPBE22XXX                1 0');
        TempFile.Write('2300020117BE23973434119591                     LUCIENNE DEGELAEN                                                             0 1');
        TempFile.Write('31000201183010483001553002208  601500001001LUCIENNE DEGELAEN                                                                 1 0');
        TempFile.Write('3200020118AVENUE DARROMANCHES 5             1410 WATERLOO                                                                    0 0');
        TempFile.Write('21000201193010483001553002208  0000000000015400041223601500000000030284713        000030284713                     04122333701 0');
        TempFile.Write('2200020119                                                     NOTPROVIDED                        CREGBEBBXXX                1 0');
        TempFile.Write('2300020119BE46198254860136                     TULKENS DENISE                                                                0 1');
        TempFile.Write('31000201203010483001553002208  601500001001TULKENS DENISE                                                                    1 0');
        TempFile.Write('3200020120CHEMIN DE MARBISOEUL 19            6120     MARBAIX (HAINAUT)                                                      0 0');
        TempFile.Write('21000201213010483001553002208  0000000000015400041223601500000000009064244        000/0090/64244                   04122333701 0');
        TempFile.Write('2200020121                                                     NOTPROVIDED                        BBRUBEBB                   1 0');
        TempFile.Write('2300020121BE62375102517561                     MME CHRISTIANE GEORGES                                                        0 1');
        TempFile.Write('31000201223010483001553002208  601500001001MME CHRISTIANE GEORGES                                                            1 0');
        TempFile.Write('3200020122AV DES MILLE METRES 40             1150        WOLUWE-ST-PIER                                                      0 0');
        TempFile.Write('21000201233010483001553002208  0000000000015400041223601500000000030182154        000/0301/82154                   04122333701 0');
        TempFile.Write('2200020123                                                     NOTPROVIDED                        BBRUBEBB                   1 0');
        TempFile.Write('2300020123BE69350025060778                     MME SERGE DUPONT                                                              0 1');
        TempFile.Write('31000201243010483001553002208  601500001001MME SERGE DUPONT                                                                  1 0');
        TempFile.Write('3200020124DREVE DES SHETLANDS 2/5            1150        WOLUWE-ST-PIER                                                      0 0');
        TempFile.Write('21000201253010483001553002208  0000000000015400041223601500000000009473159        000009473159                     04122333701 0');
        TempFile.Write('2200020125                                                     NOTPROVIDED                        CREGBEBBXXX                1 0');
        TempFile.Write('2300020125BE80732305019177                     JEUGT-COOSEMANS E + M                                                         0 1');
        TempFile.Write('31000201263010483001553002208  601500001001JEUGT-COOSEMANS E + M                                                             1 0');
        TempFile.Write('3200020126RUE DES ACACIAS      20            1320     NODEBAIS                                                               0 0');
        TempFile.Write('21000201273010483001553002208  0000000000021070041223601500001101000001087208                                      04122333701 0');
        TempFile.Write('2200020127                                                     023593828                          GEBABEBB                   1 0');
        TempFile.Write('2300020127BE14001021457183                     FRANCKX HELENE                                                                0 1');
        TempFile.Write('31000201283010483001553002208  601500001001FRANCKX HELENE                                                                    1 0');
        TempFile.Write('3200020128Avenue Voltaire 175    B030        1030 SCHAERBEEK                                                                 0 0');
        TempFile.Write('21000201293010483001553002208  0000000000017400041223601500001101000001399022                                      04122333701 0');
        TempFile.Write('2200020129                                                     NOTPROVIDED                        GKCCBEBB                   1 0');
        TempFile.Write('2300020129BE12063512786592                     Piette Rosine                                                                 0 1');
        TempFile.Write('31000201303010483001553002208  601500001001Piette Rosine                                                                     1 0');
        TempFile.Write('3200020130AVENUE DU DOMAINE   169/25         1190  BRUXELLES                                                                 0 0');
        TempFile.Write('21000201313010483001553002208  0000000000015400041223601500001101000001906048                                      04122333701 0');
        TempFile.Write('2200020131                                                     066580001                          GEBABEBB                   1 0');
        TempFile.Write('2300020131BE28001193470620                     RIGGI MARIA                                                                   0 1');
        TempFile.Write('31000201323010483001553002208  601500001001RIGGI MARIA                                                                       1 0');
        TempFile.Write('3200020132RUE DU JONCQUOIS 73                7000 MONS                                                                       0 0');
        TempFile.Write('21000201333010483001553002208  0000000000015400041223601500001101000004363178                                      04122333701 0');
        TempFile.Write('2200020133                                                     082865761                          GEBABEBB                   1 0');
        TempFile.Write('2300020133BE92270012859223                     CHEVALIER ARLETTE                                                             0 1');
        TempFile.Write('31000201343010483001553002208  601500001001CHEVALIER ARLETTE                                                                 1 0');
        TempFile.Write('3200020134RUE MORANFAYT 22                   7370 DOUR                                                                       0 0');
        TempFile.Write('21000201353010483001553002208  0000000000021070041223601500001101000004379144                                      04122333701 0');
        TempFile.Write('2200020135                                                     NOTPROVIDED                        GKCCBEBB                   1 0');
        TempFile.Write('2300020135BE20063983572456                     ARSIC MILKA                                                                   0 1');
        TempFile.Write('31000201363010483001553002208  601500001001ARSIC MILKA                                                                       1 0');
        TempFile.Write('3200020136RUE DE LINFANTE      59/4         1410  WATERLOO                                                                   0 0');
        TempFile.Write('21000201373010483001553002208  0000000000015400041223601500001101000004706318                                      04122333701 0');
        TempFile.Write('2200020137                                                     NOTPROVIDED                        BBRUBEBB                   1 0');
        TempFile.Write('2300020137BE14363015669883                     MME FATIMA EL HIJAZI                                                          0 1');
        TempFile.Write('31000201383010483001553002208  601500001001MME FATIMA EL HIJAZI                                                              1 0');
        TempFile.Write('3200020138R FORET D HOUTHULST 35/5           1000        BRUXELLES                                                           0 0');
        TempFile.Write('21000201393010483001553002208  0000000000015400041223601500001101000004796143                                      04122333701 0');
        TempFile.Write('2200020139                                                     NOTPROVIDED                        BPOTBEB1                   1 0');
        TempFile.Write('2300020139BE71000123390969                     Mme CLAUDINE SMOLDERS                                                         0 1');
        TempFile.Write('31000201403010483001553002208  601500001001Mme CLAUDINE SMOLDERS                                                             1 0');
        TempFile.Write('3200020140Rue de lInstitut Dogniaux, 9       6040 Charleroi                                                                  0 0');
        TempFile.Write('21000201413010483001553002208  0000000000021070041223601500001101000004901732                                      04122333701 0');
        TempFile.Write('2200020141                                                     NOTPROVIDED                        BBRUBEBB                   1 0');
        TempFile.Write('2300020141BE80630050858977                     MME EMILIENNE AUBIN                                                           0 1');
        TempFile.Write('31000201423010483001553002208  601500001001MME EMILIENNE AUBIN                                                               1 0');
        TempFile.Write('3200020142RUE ANSELME MARY 5                 7190        ECAUSSINNES                                                         0 0');
        TempFile.Write('21000201433010483001553002208  0000000000014700041223601500001101000004942855                                      04122333701 0');
        TempFile.Write('2200020143                                                     NOTPROVIDED                        GKCCBEBB                   1 0');
        TempFile.Write('2300020143BE54063165245797                     LOOZE FABIENNE                                                                0 1');
        TempFile.Write('31000201443010483001553002208  601500001001LOOZE FABIENNE                                                                    1 0');
        TempFile.Write('3200020144RUE LEON DURAY          14         7110  HOUDENG-GOEGNIES                                                          0 0');
        TempFile.Write('21000201453010483001553002208  0000000000021070041223601500001101000006032790                                      04122333701 0');
        TempFile.Write('2200020145                                                     NOTPROVIDED                        BBRUBEBB                   1 0');
        TempFile.Write('2300020145BE88630164723641                     NICOLE VERMEYLEN                                                              0 1');
        TempFile.Write('31000201463010483001553002208  601500001001NICOLE VERMEYLEN                                                                  1 0');
        TempFile.Write('3200020146RES EMILE LESAFFRE 2               7911        BUISSENAL                                                           0 0');
        TempFile.Write('21000201473010483001553002208  0000000000015400041223601500001101000006110794                                      04122333701 0');
        TempFile.Write('2200020147                                                     NOTPROVIDED                        GEBABEBB                   1 0');
        TempFile.Write('2300020147BE78001110930286                     WILLEMS RENEE                                                                 0 1');
        TempFile.Write('31000201483010483001553002208  601500001001WILLEMS RENEE                                                                     1 0');
        TempFile.Write('3200020148Chee de Fleurus 208                6060     CHARLEROI                                                              0 0');
        TempFile.Write('21000201493010483001553002208  0000000000021070041223601500001101000006298027                                      04122333701 0');
        TempFile.Write('2200020149                                                     NOTPROVIDED                        BBRUBEBB                   1 0');
        TempFile.Write('2300020149BE49310005634271                     MME LILIANE LAITAT                                                            0 1');
        TempFile.Write('31000201503010483001553002208  601500001001MME LILIANE LAITAT                                                                1 0');
        TempFile.Write('3200020150OUDE GERAARDSBERGSEBAAN 78         1701        DILBEEK                                                             0 0');
        TempFile.Write('21000201513010483001553002208  0000000000015400041223601500001101000006535675                                      04122333701 0');
        TempFile.Write('2200020151                                                     NOTPROVIDED                        BBRUBEBB                   1 0');
        TempFile.Write('2300020151BE82360011200068                     MME ELIANE ABATTUCCI                                                          0 1');
        TempFile.Write('31000201523010483001553002208  601500001001MME ELIANE ABATTUCCI                                                              1 0');
        TempFile.Write('3200020152RUE DE LOUVROY 30                  6120        NALINNES                                                            0 0');
        TempFile.Write('21000201533010483001553002208  0000000000015400041223601500001101000006633786                                      04122333701 0');
        TempFile.Write('2200020153                                                     NOTPROVIDED                        GKCCBEBB                   1 0');
        TempFile.Write('2300020153BE46063102645536                     Limelette Martine                                                             0 1');
        TempFile.Write('31000201543010483001553002208  601500001001Limelette Martine                                                                 1 0');
        TempFile.Write('3200020154RUE DE BRAY            109         7110  MAURAGE                                                                   0 0');
        TempFile.Write('21000201553010483001553002208  0000000000015400041223601500001101000006639749                                      04122333701 0');
        TempFile.Write('2200020155                                                     NOTPROVIDED                        KREDBEBB                   1 0');
        TempFile.Write('2300020155BE98736031605593                     DE BOLLE CLEMENCE                                                             0 1');
        TempFile.Write('31000201563010483001553002208  601500001001DE BOLLE CLEMENCE                                                                 1 0');
        TempFile.Write('3200020156CHAUSSEE DE ROODEBEEK163           1200    BRUXELLES                                                               0 0');
        TempFile.Write('21000201573010483001553002208  0000000000017400041223601500001101000006684108                                      04122333701 0');
        TempFile.Write('2200020157                                                     NOTPROVIDED                        GKCCBEBB                   1 0');
        TempFile.Write('2300020157BE04061934474031                     DE LENTDECKER LUCIENNE                                                        0 1');
        TempFile.Write('31000201583010483001553002208  601500001001DE LENTDECKER LUCIENNE                                                            1 0');
        TempFile.Write('3200020158AVENUE DE JETTE      301/7         1083  GANSHOREN                                                                 0 0');
        TempFile.Write('21000201593010483001553002208  0000000000021070041223601500001101000006726645                                      04122333701 0');
        TempFile.Write('2200020159                                                     NOTPROVIDED                        GKCCBEBB                   1 0');
        TempFile.Write('2300020159BE75063522317551                     PROVOST FRANCOISE                                                             0 1');
        TempFile.Write('31000201603010483001553002208  601500001001PROVOST FRANCOISE                                                                 1 0');
        TempFile.Write('3200020160AV DE LHIPPODROME      54         1970  WEZEMBEEK-OPPEM                                                            0 0');
        TempFile.Write('21000201613010483001553002208  0000000000015400041223601500001101000006750085                                      04122333701 0');
        TempFile.Write('2200020161                                                     NOTPROVIDED                        GKCCBEBB                   1 0');
        TempFile.Write('2300020161BE12799510384292                     Ciccarelli Gaudenzio                                                          0 1');
        TempFile.Write('31000201623010483001553002208  601500001001Ciccarelli Gaudenzio                                                              1 0');
        TempFile.Write('3200020162RUE DE LA FOURCHE       13         7340  COLFONTAINE                                                               0 0');
        TempFile.Write('21000201633010483001553002208  0000000000021070041223601500001101000006765243                                      04122333701 0');
        TempFile.Write('2200020163                                                     NOTPROVIDED                        GKCCBEBB                   1 0');
        TempFile.Write('2300020163BE58063117616979                     VRANCX LEA                                                                    0 1');
        TempFile.Write('31000201643010483001553002208  601500001001VRANCX LEA                                                                        1 0');
        TempFile.Write('3200020164AVENUE DE LA CLUSE       2         1200  BRUXELLES                                                                 0 0');
        TempFile.Write('21000201653010483001553002208  0000000000017400041223601500001101000006767263                                      04122333701 0');
        TempFile.Write('2200020165                                                     152671629                          GEBABEBB                   1 0');
        TempFile.Write('2300020165BE96140058155005                     BOLANOS-CASTILLA MARIA                                                        0 1');
        TempFile.Write('31000201663010483001553002208  601500001001BOLANOS-CASTILLA MARIA                                                            1 0');
        TempFile.Write('3200020166Rue Dr A. Schweitzer 9             4040 HERSTAL                                                                    0 0');
        TempFile.Write('21000201673010483001553002208  0000000000021070041223601500001101000006794949                                      04122333701 0');
        TempFile.Write('2200020167                                                     NOTPROVIDED                        GKCCBEBB                   1 0');
        TempFile.Write('2300020167BE05063662417075                     DANGRIAUX JOSSELINE                                                           0 1');
        TempFile.Write('31000201683010483001553002208  601500001001DANGRIAUX JOSSELINE                                                               1 0');
        TempFile.Write('3200020168CHEMIN DU PRINCE       381         7050  JURBISE                                                                   0 0');
        TempFile.Write('21000201693010483001553002208  0000000000014310041223601500001101000006819096                                      04122333701 0');
        TempFile.Write('2200020169                                                     NOTPROVIDED                        CREGBEBB                   1 0');
        TempFile.Write('2300020169BE67732034875187                     VICAIRE DANIELLE                                                              0 1');
        TempFile.Write('31000201703010483001553002208  601500001001VICAIRE DANIELLE                                                                  1 0');
        TempFile.Write('3200020170RUE CROISETTES       58            7190    ECAUSSINNES-DENGHIEN                                                    0 0');
        TempFile.Write('21000201713010483001553002208  0000000000017400041223601500001101000006921756                                      04122333701 0');
        TempFile.Write('2200020171                                                     NOTPROVIDED                        GKCCBEBB                   1 0');
        TempFile.Write('2300020171BE87063510245394                     Peeters Bertha                                                                0 1');
        TempFile.Write('31000201723010483001553002208  601500001001Peeters Bertha                                                                    1 0');
        TempFile.Write('3200020172RUE DES ECOLES          82         6031  MONCEAU-SUR-SAMBRE                                                        0 0');
        TempFile.Write('21000201733010483001553002208  0000000000015400041223601500001101000006930749                                      04122333701 0');
        TempFile.Write('2200020173                                                     159914529                          GEBABEBB                   1 0');
        TempFile.Write('2300020173BE26210045675029                     JACOBS ELIAZAR                                                                0 1');
        TempFile.Write('31000201743010483001553002208  601500001001JACOBS ELIAZAR                                                                    1 0');
        TempFile.Write('3200020174Bld L.Mettewie 67     20           1080 MOLENBEEK-SAINT-JEAN                                                       0 0');
        TempFile.Write('21000201753010483001553002208  0000000000015400041223601500001101000006940752                                      04122333701 0');
        TempFile.Write('2200020175                                                     170034237                          GEBABEBB                   1 0');
        TempFile.Write('2300020175BE34271026612990                     WALHAIN MARIE                                                                 0 1');
        TempFile.Write('31000201763010483001553002208  601500001001WALHAIN MARIE                                                                     1 0');
        TempFile.Write('3200020176Avenue des Sorbiers 40             1420 BRAINE-LALLEUD                                                             0 0');
        TempFile.Write('21000201773010483001553002208  0000000000021070041223601500001101000006945907                                      04122333701 0');
        TempFile.Write('2200020177                                                     163686869                          GEBABEBB                   1 0');
        TempFile.Write('2300020177BE67240077094287                     CARNIER ROSINE                                                                0 1');
        TempFile.Write('31000201783010483001553002208  601500001001CARNIER ROSINE                                                                    1 0');
        TempFile.Write('3200020178RUE BOIS DE SCLESSIN 12            4102 SERAING                                                                    0 0');
        TempFile.Write('21000201793010483001553002208  0000000000015400041223601500001101000006961768                                      04122333701 0');
        TempFile.Write('2200020179                                                     NOTPROVIDED                        BPOTBEB1                   1 0');
        TempFile.Write('2300020179BE27000088713873                     Mme RENEE ROSY                                                                0 1');
        TempFile.Write('31000201803010483001553002208  601500001001Mme RENEE ROSY                                                                    1 0');
        TempFile.Write('3200020180RUE DE NIL, 13                     1435 MONT-SAINT-GUIBERT                                                         0 0');
        TempFile.Write('21000201813010483001553002208  0000000000021070041223601500001101000006991575                                      04122333701 0');
        TempFile.Write('2200020181                                                     NOTPROVIDED                        BBRUBEBB                   1 0');
        TempFile.Write('2300020181BE60310023162070                     MME MARGIT KRANEWITTER                                                        0 1');
        TempFile.Write('31000201823010483001553002208  601500001001MME MARGIT KRANEWITTER                                                            1 0');
        TempFile.Write('3200020182AVENUE DE JANVIER 23/4             1200        ST-LAMB-WOLUWE                                                      0 0');
        TempFile.Write('21000201833010483001553002208  0000000000013570041223601500001101000007002891                                      04122333701 0');
        TempFile.Write('2200020183                                                     NOTPROVIDED                        AXABBE22                   1 0');
        TempFile.Write('2300020183BE72750628662216                     Wittevrongel Roger                                                            0 1');
        TempFile.Write('31000201843010483001553002208  601500001001Wittevrongel Roger                                                                1 0');
        TempFile.Write('3200020184Chaussee d Enghien 22              1430 BIERGHES                                                                   0 0');
        TempFile.Write('21000201853010483001553002208  0000000000015400041223601500001101000007013201                                      04122333701 0');
        TempFile.Write('2200020185                                                     ordre permanent                    BBRUBEBB                   1 0');
        TempFile.Write('2300020185BE34310100958090                     MME MARIE-JEANNE SAEYS                                                        0 1');
        TempFile.Write('31000201863010483001553002208  601500001001MME MARIE-JEANNE SAEYS                                                            1 0');
        TempFile.Write('3200020186AV MARIUS RENARD 27 BTE 16         1070        ANDERLECHT                                                          0 0');
        TempFile.Write('21000201873010483001553002208  0000000000015400041223601500001101000007028557                                      04122333701 0');
        TempFile.Write('2200020187                                                     NOTPROVIDED                        BPOTBEB1                   1 0');
        TempFile.Write('2300020187BE84000428125159                     Mme MONIQUE LIGNY                                                             0 1');
        TempFile.Write('31000201883010483001553002208  601500001001Mme MONIQUE LIGNY                                                                 1 0');
        TempFile.Write('3200020188RUE DES NATIONS, 45                4102 SERAING                                                                    0 0');
        TempFile.Write('21000201893010483001553002208  0000000000021070041223601500001101000007033712                                      04122333701 0');
        TempFile.Write('2200020189                                                     164291648                          GEBABEBB                   1 0');
        TempFile.Write('2300020189BE57210037469435                     MME MONIKA HOHERZ                                                             0 1');
        TempFile.Write('31000201903010483001553002208  601500001001MME MONIKA HOHERZ                                                                 1 0');
        TempFile.Write('3200020190AVENUE DES MIMOSAS 18              1150 WOLUWE-SAINT-PIERRE                                                        0 0');
        TempFile.Write('21000201913010483001553002208  0000000000015400041223601500001101000007062711                                      04122333701 0');
        TempFile.Write('2200020191                                                     164561674                          GEBABEBB                   1 0');
        TempFile.Write('2300020191BE61001043993317                     VILLERS JENNY                                                                 0 1');
        TempFile.Write('31000201923010483001553002208  601500001001VILLERS JENNY                                                                     1 0');
        TempFile.Write('3200020192Av.d.lUniversite 68     002-E     1050 IXELLES                                                                     0 0');
        TempFile.Write('21000201933010483001553002208  0000000000015400041223601500001101000007063317                                      04122333701 0');
        TempFile.Write('2200020193                                                     164534677                          GEBABEBB                   1 0');
        TempFile.Write('2300020193BE26210042483729                     WICK JOSEPHINA                                                                0 1');
        TempFile.Write('31000201943010483001553002208  601500001001WICK JOSEPHINA                                                                    1 0');
        TempFile.Write('3200020194Av.d/l Ferme Rose 13     13        1180 UCCLE                                                                      0 0');
        TempFile.Write('21000201953010483001553002208  0000000000021070041223601500001101000007064832                                      04122333701 0');
        TempFile.Write('2200020195                                                     NOTPROVIDED                        KREDBEBB                   1 0');
        TempFile.Write('2300020195BE19734207085612                     DOMBROWSKI NEE NALIK CHRISTEL                                                 0 1');
        TempFile.Write('31000201963010483001553002208  601500001001DOMBROWSKI NEE NALIK CHRISTEL                                                     1 0');
        TempFile.Write('3200020196R. BATONNIER BRAFFORT22            1200    WOLUWE-SAINT-LAMBERT                                                    0 0');
        TempFile.Write('21000201973010483001553002208  0000000000015400041223601500001101000007081707                                      04122333701 0');
        TempFile.Write('2200020197                                                     NOTPROVIDED                        BBRUBEBB                   1 0');
        TempFile.Write('2300020197BE88310154167341                     MME GABRIELLE VEKENS                                                          0 1');
        TempFile.Write('31000201983010483001553002208  601500001001MME GABRIELLE VEKENS                                                              1 0');
        TempFile.Write('3200020198RUE EMILE REGARD 29/1              1180        UCCLE                                                               0 0');
        TempFile.Write('21000201993010483001553002208  0000000000015400041223601500001101000007107268                                      04122333701 0');
        TempFile.Write('2200020199                                                     175498500                          GEBABEBB                   1 0');
        TempFile.Write('2300020199BE22271075331747                     MAT JEAN                                                                      0 1');
        TempFile.Write('31000202003010483001553002208  601500001001MAT JEAN                                                                          1 0');
        TempFile.Write('3200020200CLOS BOURDON 31                    1420 BRAINE-LALLEUD                                                             0 0');
        TempFile.Write('21000202013010483001553002208  0000000000014870041223601500001101000007158903                                      04122333701 0');
        TempFile.Write('2200020201                                                     168315722                          GEBABEBB                   1 0');
        TempFile.Write('2300020201BE43001081162101                     HUYNH THI                                                                     0 1');
        TempFile.Write('31000202023010483001553002208  601500001001HUYNH THI                                                                         1 0');
        TempFile.Write('3200020202RUE DRIES 116                      1200 WOLUWE-SAINT-LAMBERT                                                       0 0');
        TempFile.Write('21000202033010483001553002208  0000000000009920041223601500001101000007166276                                      04122333701 0');
        TempFile.Write('2200020203                                                     NOTPROVIDED                        NICABEBB                   1 0');
        TempFile.Write('2300020203BE78103113326986                     M. Joseph Diels                                                               0 1');
        TempFile.Write('31000202043010483001553002208  601500001001M. Joseph Diels                                                                   1 0');
        TempFile.Write('3200020204Rue de la Het,13                   6721 ANLIER                                                                     0 0');
        TempFile.Write('21000202053010483001553002208  0000000000021070041223601500001101000007175269                                      04122333701 0');
        TempFile.Write('2200020205                                                     168246186                          GEBABEBB                   1 0');
        TempFile.Write('2300020205BE09001610991457                     COLLAVINI ANTONIA                                                             0 1');
        TempFile.Write('31000202063010483001553002208  601500001001COLLAVINI ANTONIA                                                                 1 0');
        TempFile.Write('3200020206WARANDEBERG 30                     1970 WEZEMBEEK-OPPEM                                                            0 0');
        TempFile.Write('21000202073010483001553002208  0000000000021070041223601500001101000007184161                                      04122333701 0');
        TempFile.Write('2200020207                                                     NOTPROVIDED                        GKCCBEBB                   1 0');
        TempFile.Write('2300020207BE23063159667691                     Henrion Janine                                                                0 1');
        TempFile.Write('31000202083010483001553002208  601500001001Henrion Janine                                                                    1 0');
        TempFile.Write('3200020208RUE OLIVIER BENNE        6         1357  HELECINE                                                                  0 0');
        TempFile.Write('21000202093010483001553002208  0000000000015400041223601500001101000007184969                                      04122333701 0');
        TempFile.Write('2200020209                                                     NOTPROVIDED                        GEBABEBB                   1 0');
        TempFile.Write('2300020209BE79001375696133                     WILSENS MARIETTE                                                              0 1');
        TempFile.Write('31000202103010483001553002208  601500001001WILSENS MARIETTE                                                                  1 0');
        TempFile.Write('3200020210Rue des Mesanges 6                 4041     HERSTAL                                                                0 0');
        TempFile.Write('21000202113010483001553002208  0000000000017400041223601500001101000007206793                                      04122333701 0');
        TempFile.Write('2200020211                                                     NOTPROVIDED                        ARSPBE22                   1 0');
        TempFile.Write('2300020211BE60979083930970                     MONIKA HONKOMP                                                                0 1');
        TempFile.Write('31000202123010483001553002208  601500001001MONIKA HONKOMP                                                                    1 0');
        TempFile.Write('3200020212RUE FRANCOIS VANDER ELST  74       1950 KRAAINEM                                                                   0 0');
        TempFile.Write('21000202133010483001553002208  0000000000021070041223601500001101000007271966                                      04122333701 0');
        TempFile.Write('2200020213                                                     170531294                          GEBABEBB                   1 0');
        TempFile.Write('2300020213BE65267012006696                     SCHANUS MARIE                                                                 0 1');
        TempFile.Write('31000202143010483001553002208  601500001001SCHANUS MARIE                                                                     1 0');
        TempFile.Write('3200020214Rue de la Lisiere 14               6790 AUBANGE                                                                    0 0');
        TempFile.Write('21000202153010483001553002208  0000000000021070041223601500001101000007274592                                      04122333701 0');
        TempFile.Write('2200020215                                                     170949891                          GEBABEBB                   1 0');
        TempFile.Write('2300020215BE25001071528482                     ANDRIEU MARIE                                                                 0 1');
        TempFile.Write('31000202163010483001553002208  601500001001ANDRIEU MARIE                                                                     1 0');
        TempFile.Write('3200020216Av.d/l Heronniere 102    B023      1160 AUDERGHEM                                                                  0 0');
        TempFile.Write('21000202173010483001553002208  0000000000017400041223601500001101000007276313                                      04122333701 0');
        TempFile.Write('2200020217                                                     170385133                          GEBABEBB                   1 0');
        TempFile.Write('2300020217BE56210025553488                     VAN COPPENOLLE HILDA                                                          0 1');
        TempFile.Write('31000202183010483001553002208  601500001001VAN COPPENOLLE HILDA                                                              1 0');
        TempFile.Write('3200020218Edm.Parmentierln 150    B022       1150 SINT-PIETERS-WOLUWE                                                        0 0');
        TempFile.Write('21000202193010483001553002208  0000000000029000041223601500001101000007302076                                      04122333701 0');
        TempFile.Write('2200020219                                                     NOTPROVIDED                        BPOTBEB1                   1 0');
        TempFile.Write('2300020219BE91000162511776                     Mme Patricia Gerin                                                            0 1');
        TempFile.Write('31000202203010483001553002208  601500001001Mme Patricia Gerin                                                                1 0');
        TempFile.Write('3200020220Rue de la Hulle,39 /8              5170 Profondeville                                                              0 0');
        TempFile.Write('21000202213010483001553002208  0000000000029000041223601500001101000007337543                                      04122333701 0');
        TempFile.Write('2200020221                                                     NOTPROVIDED                        GKCCBEBB                   1 0');
        TempFile.Write('2300020221BE31063452865955                     Maes Annie                                                                    0 1');
        TempFile.Write('31000202223010483001553002208  601500001001Maes Annie                                                                        1 0');
        TempFile.Write('3200020222RUE PAUL DEMADE          4         7780  COMINES-WARNETON                                                          0 0');
        TempFile.Write('21000202233010483001553002208  0000000000021070041223601500001101000007344314                                      04122333701 0');
        TempFile.Write('2200020223                                                     NOTPROVIDED                        BBRUBEBB                   1 0');
        TempFile.Write('2300020223BE69363054605178                     MME GISELE DE GRYSE                                                           0 1');
        TempFile.Write('31000202243010483001553002208  601500001001MME GISELE DE GRYSE                                                               1 0');
        TempFile.Write('3200020224RUE DES HELLENES 62                1050        BRUXELLES                                                           0 0');
        TempFile.Write('21000202253010483001553002208  0000000000017400041223601500001101000007416355                                      04122333701 0');
        TempFile.Write('2200020225                                                     NOTPROVIDED                        KREDBEBBXXX                1 0');
        TempFile.Write('2300020225BE27736000059173                     MUGA GARCIA MARIA                                                             0 1');
        TempFile.Write('31000202263010483001553002208  601500001001MUGA GARCIA MARIA                                                                 1 0');
        TempFile.Write('3200020226BOULEVARD DU REGENT  24   B6       1000     BRUXELLES                                                              0 0');
        TempFile.Write('21000202273010483001553002208  0000000000015400041223601500001101000007486376                                      04122333701 0');
        TempFile.Write('2200020227                                                     NOTPROVIDED                        BBRUBEBB                   1 0');
        TempFile.Write('2300020227BE72363160493816                     COECKELBERGH                                                                  0 1');
        TempFile.Write('31000202283010483001553002208  601500001001COECKELBERGH                                                                      1 0');
        TempFile.Write('3200020228AV MONTJOIE 149                    1180        UCCLE                                                               0 0');
        TempFile.Write('21000202293010483001553002208  0000000000015400041223601500001101000007547913                                      04122333701 0');
        TempFile.Write('2200020229                                                     NOTPROVIDED                        GEBABEBB                   1 0');
        TempFile.Write('2300020229BE24001298096638                     VAMBOUCQ MARIE-ANDREE                                                         0 1');
        TempFile.Write('31000202303010483001553002208  601500001001VAMBOUCQ MARIE-ANDREE                                                             1 0');
        TempFile.Write('3200020230Rue de Quievremont 23              7950 CHIEVRES                                                                   0 0');
        TempFile.Write('21000202313010483001553002208  0000000000015400041223601500001101000007589440                                      04122333701 0');
        TempFile.Write('2200020231                                                     C3L04SBETDQVJCZ0                   BPOTBEB1                   1 0');
        TempFile.Write('2300020231BE78000337064286                     Mme THERESE DUMONT                                                            0 1');
        TempFile.Write('31000202323010483001553002208  601500001001Mme THERESE DUMONT                                                                1 0');
        TempFile.Write('3200020232Rue du Dr. Edmond Isaac,12         7390 QUAREGNON                                                                  0 0');
        TempFile.Write('21000202333010483001553002208  0000000000015400041223601500001101000007620257                                      04122333701 0');
        TempFile.Write('2200020233                                                     170888976                          GEBABEBB                   1 0');
        TempFile.Write('2300020233BE18001648172365                     GOOSSENS IDA                                                                  0 1');
        TempFile.Write('31000202343010483001553002208  601500001001GOOSSENS IDA                                                                      1 0');
        TempFile.Write('3200020234R.Eglise St-Philippe 11     0003   5600 PHILIPPEVILLE                                                              0 0');
        TempFile.Write('21000202353010483001553002208  0000000000015400041223601500001101000007630058                                      04122333701 0');
        TempFile.Write('2200020235                                                     NOTPROVIDED                        GKCCBEBB                   1 0');
        TempFile.Write('2300020235BE98063123632393                     Rhodius Jacqueline                                                            0 1');
        TempFile.Write('31000202363010483001553002208  601500001001Rhodius Jacqueline                                                                1 0');
        TempFile.Write('3200020236CH VIVIER ST-LAURENT    12         1320  BEAUVECHAIN                                                               0 0');
        TempFile.Write('21000202373010483001553002208  0000000000015400041223601500001101000007664010                                      04122333701 0');
        TempFile.Write('2200020237                                                     NOTPROVIDED                        GEBABEBB                   1 0');
        TempFile.Write('2300020237BE30271060302811                     CAULKIN JOAN                                                                  0 1');
        TempFile.Write('31000202383010483001553002208  601500001001CAULKIN JOAN                                                                      1 0');
        TempFile.Write('3200020238Allee du Coulombier 5              1400 NIVELLES                                                                   0 0');
        TempFile.Write('21000202393010483001553002208  0000000000015400041223601500001101000007666535                                      04122333701 0');
        TempFile.Write('2200020239                                                     NOTPROVIDED                        BPOTBEB1                   1 0');
        TempFile.Write('2300020239BE92000063973823                     Mme YVETTE COLICIS                                                            0 1');
        TempFile.Write('31000202403010483001553002208  601500001001Mme YVETTE COLICIS                                                                1 0');
        TempFile.Write('3200020240RUE SAINT-ROCH, 21                 1300 WAVRE                                                                      0 0');
        TempFile.Write('21000202413010483001553002208  0000000000023000041223601500001101000007675124                                      04122333701 0');
        TempFile.Write('2200020241                                                     NOTPROVIDED                        GKCCBEBB                   1 0');
        TempFile.Write('2300020241BE04063015442031                     MANBRE HUGUETTE                                                               0 1');
        TempFile.Write('31000202423010483001553002208  601500001001MANBRE HUGUETTE                                                                   1 0');
        TempFile.Write('3200020242RUE DES ECOLES         175         7034  OBOURG                                                                    0 0');
        TempFile.Write('21000202433010483001553002208  0000000000021070041223601500001101000007725846                                      04122333701 0');
        TempFile.Write('2200020243                                                     172397608                          GEBABEBB                   1 0');
        TempFile.Write('2300020243BE16143098074074                     PRAET COLETTE                                                                 0 1');
        TempFile.Write('31000202443010483001553002208  601500001001PRAET COLETTE                                                                     1 0');
        TempFile.Write('3200020244RUE DU TRY 7                       1440 BRAINE-LE-CHATEAU                                                          0 0');
        TempFile.Write('21000202453010483001553002208  0000000000021070041223601500001101000007727765                                      04122333701 0');
        TempFile.Write('2200020245                                                     NOTPROVIDED                        BBRUBEBB                   1 0');
        TempFile.Write('2300020245BE22310067149247                     MME MATYLDA GORDON                                                            0 1');
        TempFile.Write('31000202463010483001553002208  601500001001MME MATYLDA GORDON                                                                1 0');
        TempFile.Write('3200020246AV DE BROQUEVILLE 134/4            1200        WOLUWE-ST-LAMB                                                      0 0');
        TempFile.Write('21000202473010483001553002208  0000000000021070041223601500001101000007775760                                      04122333701 0');
        TempFile.Write('2200020247                                                     NOTPROVIDED                        GEBABEBB                   1 0');
        TempFile.Write('2300020247BE49001080315571                     LISART PHILIPPE                                                               0 1');
        TempFile.Write('31000202483010483001553002208  601500001001LISART PHILIPPE                                                                   1 0');
        TempFile.Write('3200020248RUE DE GAESBECQ 5                  1460 ITTRE                                                                      0 0');
        TempFile.Write('21000202493010483001553002208  0000000000021070041223601500001101000007781622                                      04122333701 0');
        TempFile.Write('2200020249                                                     171441049                          GEBABEBB                   1 0');
        TempFile.Write('2300020249BE22001303966047                     PAQUET-DOFFAGNE                                                               0 1');
        TempFile.Write('31000202503010483001553002208  601500001001PAQUET-DOFFAGNE                                                                   1 0');
        TempFile.Write('3200020250Allee du Long Fetu 12              1400 NIVELLES                                                                   0 0');
        TempFile.Write('21000202513010483001553002208  0000000000015400041223601500001101000007816681                                      04122333701 0');
        TempFile.Write('2200020251                                                     NOTPROVIDED                        BBRUBEBB                   1 0');
        TempFile.Write('2300020251BE47363139053580                     M DOMINIQUE LEJEUNE                                                           0 1');
        TempFile.Write('31000202523010483001553002208  601500001001M DOMINIQUE LEJEUNE                                                               1 0');
        TempFile.Write('3200020252RUE LEON FREDERIC 24               1030        SCHAERBEEK                                                          0 0');
        TempFile.Write('21000202533010483001553002208  0000000000017400041223601500001101000007835879                                      04122333701 0');
        TempFile.Write('2200020253                                                     NOTPROVIDED                        GKCCBEBB                   1 0');
        TempFile.Write('2300020253BE67063095472687                     Godfroid Louise                                                               0 1');
        TempFile.Write('31000202543010483001553002208  601500001001Godfroid Louise                                                                   1 0');
        TempFile.Write('3200020254RUE DE WAND             68         1020  BRUXELLES                                                                 0 0');
        TempFile.Write('21000202553010483001553002208  0000000000015400041223601500001101000007851138                                      04122333701 0');
        TempFile.Write('2200020255                                                     NOTPROVIDED                        BBRUBEBB                   1 0');
        TempFile.Write('2300020255BE66377071402343                     VANDENBORRE ET MME MARIE-J                                                    0 1');
        TempFile.Write('31000202563010483001553002208  601500001001VANDENBORRE ET MME MARIE-J                                                        1 0');
        TempFile.Write('3200020256LOGIS MILITAIRE 20                 7950        CHIEVRES                                                            0 0');
        TempFile.Write('21000202573010483001553002208  0000000000023000041223601500001101000007858717                                      04122333701 0');
        TempFile.Write('2200020257                                                     NOTPROVIDED                        GKCCBEBB                   1 0');
        TempFile.Write('2300020257BE16063572303974                     VAN DE VUCHT GERARDINA                                                        0 1');
        TempFile.Write('31000202583010483001553002208  601500001001VAN DE VUCHT GERARDINA                                                            1 0');
        TempFile.Write('3200020258RUE JULES LAHAYE    300/10         1090  BRUXELLES                                                                 0 0');
        TempFile.Write('21000202593010483001553002208  0000000000017400041223601500001101000007934495                                      04122333701 0');
        TempFile.Write('2200020259                                                     NOTPROVIDED                        GKCCBEBB                   1 0');
        TempFile.Write('2300020259BE21063651322703                     De Goedt Marie-Ange                                                           0 1');
        TempFile.Write('31000202603010483001553002208  601500001001De Goedt Marie-Ange                                                               1 0');
        TempFile.Write('3200020260AVENUE DE PRAGUE        11         6183  TRAZEGNIES                                                                0 0');
        TempFile.Write('21000202613010483001553002208  0000000000015400041223601500001101000007957535                                      04122333701 0');
        TempFile.Write('2200020261                                                     NOTPROVIDED                        BBRUBEBB                   1 0');
        TempFile.Write('2300020261BE02377111899540                     M GILBERT DRICOT                                                              0 1');
        TempFile.Write('31000202623010483001553002208  601500001001M GILBERT DRICOT                                                                  1 0');
        TempFile.Write('3200020262RUE FERRER(WB) 15                  6224        WANFERCEE-BAUL                                                      0 0');
        TempFile.Write('21000202633010483001553002208  0000000000015400041223601500001101000007982490                                      04122333701 0');
        TempFile.Write('2200020263                                                     NOTPROVIDED                        BPOTBEB1                   1 0');
        TempFile.Write('2300020263BE03000019621884                     Mme RENEE JOURDAIN                                                            0 1');
        TempFile.Write('31000202643010483001553002208  601500001001Mme RENEE JOURDAIN                                                                1 0');
        TempFile.Write('3200020264RUE DU MONUMENT,122                5620 Florennes                                                                  0 0');
        TempFile.Write('21000202653010483001553002208  0000000000015400041223601500001101000007989160                                      04122333701 0');
        TempFile.Write('2200020265                                                     NOTPROVIDED                        BNAGBEBB                   1 0');
        TempFile.Write('2300020265BE95132544365758                     LILOT PAULETTE                                                                0 1');
        TempFile.Write('31000202663010483001553002208  601500001001LILOT PAULETTE                                                                    1 0');
        TempFile.Write('3200020266QUAI ED. VAN-BENEDEN 25/6A         4020 LIEGE                                                                      0 0');
        TempFile.Write('21000202673010483001553002208  0000000000015400041223601500001101000008116371                                      04122333701 0');
        TempFile.Write('2200020267                                                     NOTPROVIDED                        BBRUBEBB                   1 0');
        TempFile.Write('2300020267BE76363154914595                     M BERNARD GOUDAILLER                                                          0 1');
        TempFile.Write('31000202683010483001553002208  601500001001M BERNARD GOUDAILLER                                                              1 0');
        TempFile.Write('3200020268CH DE BRUXELLES 132/01             7500        TOURNAI                                                             0 0');
        TempFile.Write('21000202693010483001553002208  0000000000017400041223601500001101000008140825                                      04122333701 0');
        TempFile.Write('2200020269                                                     NOTPROVIDED                        BBRUBEBB                   1 0');
        TempFile.Write('2300020269BE40310109365263                     DE SMAELE VVE CHATELLE GIL                                                    0 1');
        TempFile.Write('31000202703010483001553002208  601500001001DE SMAELE VVE CHATELLE GIL                                                        1 0');
        TempFile.Write('3200020270AV DU CAPRICORNE 26                1200        WOLUWE-ST-LAMB                                                      0 0');
        TempFile.Write('21000202713010483001553002208  0000000000017400041223601500001101000008242572                                      04122333701 0');
        TempFile.Write('2200020271                                                     172115934                          GEBABEBB                   1 0');
        TempFile.Write('2300020271BE58240032046679                     WILLAERT GERDA                                                                0 1');
        TempFile.Write('31000202723010483001553002208  601500001001WILLAERT GERDA                                                                    1 0');
        TempFile.Write('3200020272Rue Harkay 294                     4400 MONS-LEZ-LIEGE                                                             0 0');
        TempFile.Write('21000202733010483001553002208  0000000000015400041223601500001101000008250151                                      04122333701 0');
        TempFile.Write('2200020273                                                     NOTPROVIDED                        NICABEBB                   1 0');
        TempFile.Write('2300020273BE13103066733139                     Calamera - Diliberto                                                          0 1');
        TempFile.Write('31000202743010483001553002208  601500001001Calamera - Diliberto                                                              1 0');
        TempFile.Write('3200020274Rue des Forges,285/0R02            1480 Tubize                                                                     0 0');
        TempFile.Write('21000202753010483001553002208  0000000000015400041223601500001101000008286325                                      04122333701 0');
        TempFile.Write('2200020275                                                     NOTPROVIDED                        GEBABEBB                   1 0');
        TempFile.Write('2300020275BE94001734739714                     BOURGUIGNON MARIETTE                                                          0 1');
        TempFile.Write('31000202763010483001553002208  601500001001BOURGUIGNON MARIETTE                                                              1 0');
        TempFile.Write('3200020276RUE DES AIRELLES 131               4100     SERAING                                                                0 0');
        TempFile.Write('21000202773010483001553002208  0000000000015400041223601500001101000008288446                                      04122333701 0');
        TempFile.Write('2200020277                                                     NOTPROVIDED                        BPOTBEB1                   1 0');
        TempFile.Write('2300020277BE06000068658822                     Mme MARIA GOOSSENS                                                            0 1');
        TempFile.Write('31000202783010483001553002208  601500001001Mme MARIA GOOSSENS                                                                1 0');
        TempFile.Write('3200020278Avenue Albert Ier,286/004          1332 Rixensart                                                                  0 0');
        TempFile.Write('21000202793010483001553002208  0000000000015400041223601500001101000008309058                                      04122333701 0');
        TempFile.Write('2200020279                                                     NOTPROVIDED                        BBRUBEBB                   1 0');
        TempFile.Write('2300020279BE75310129481851                     MME JEANNINE VANDERWALLE                                                      0 1');
        TempFile.Write('31000202803010483001553002208  601500001001MME JEANNINE VANDERWALLE                                                          1 0');
        TempFile.Write('3200020280BD LOUIS METTEWIE 83 BT 26         1080        BRUXELLES                                                           0 0');
        TempFile.Write('21000202813010483001553002208  0000000000015400041223601500001101000008315021                                      04122333701 0');
        TempFile.Write('2200020281                                                     3507213199                         BPOTBEB1                   1 0');
        TempFile.Write('2300020281BE54000000000097                     Coquette Elisabeth Josette                                                    0 1');
        TempFile.Write('31000202823010483001553002208  601500001001Coquette Elisabeth Josette                                                        1 0');
        TempFile.Write('3200020282Avenue Schattens (Ado, 31 /Bt11    1410 Waterloo                                                                   0 0');
        TempFile.Write('21000202833010483001553002208  0000000000015400041223601500001101000008322091                                      04122333701 0');
        TempFile.Write('2200020283                                                     NOTPROVIDED                        GEBABEBB                   1 0');
        TempFile.Write('2300020283BE93001703559567                     DE SCHEPPER PAULA                                                             0 1');
        TempFile.Write('31000202843010483001553002208  601500001001DE SCHEPPER PAULA                                                                 1 0');
        TempFile.Write('3200020284Av. Mat. De Jonge 5                1083 GANSHOREN                                                                  0 0');
        TempFile.Write('21000202853010483001553002208  0000000000015400041223601500001101000008364329                                      04122333701 0');
        TempFile.Write('2200020285                                                     NOTPROVIDED                        BBRUBEBB                   1 0');
        TempFile.Write('2300020285BE24363171815938                     MME ANTONINA INFOSINO                                                         0 1');
        TempFile.Write('31000202863010483001553002208  601500001001MME ANTONINA INFOSINO                                                             1 0');
        TempFile.Write('3200020286RUE FAIGNART 48                    7100        LA LOUVIERE                                                         0 0');
        TempFile.Write('21000202873010483001553002208  0000000000015400041223601500001101000008390803                                      04122333701 0');
        TempFile.Write('2200020287                                                     NOTPROVIDED                        GKCCBEBB                   1 0');
        TempFile.Write('2300020287BE29063652337664                     Bakonyi Katalin                                                               0 1');
        TempFile.Write('31000202883010483001553002208  601500001001Bakonyi Katalin                                                                   1 0');
        TempFile.Write('3200020288AV ADOLPHE SCHATTENS 49/10         1410  WATERLOO                                                                  0 0');
        TempFile.Write('21000202893010483001553002208  0000000000025000041223601500001101000008399287                                      04122333701 0');
        TempFile.Write('2200020289                                                     NOTPROVIDED                        GKCCBEBB                   1 0');
        TempFile.Write('2300020289BE97068901927649                     Hamoline Martine                                                              0 1');
        TempFile.Write('31000202903010483001553002208  601500001001Hamoline Martine                                                                  1 0');
        TempFile.Write('3200020290FELIX VERHAEGHESTRAAT   36         8790  WAREGEM                                                                   0 0');
        TempFile.Write('21000202913010483001553002208  0000000000015400041223601500001101000008408886                                      04122333701 0');
        TempFile.Write('2200020291                                                     NOTPROVIDED                        GEBABEBB                   1 0');
        TempFile.Write('2300020291BE17240003299721                     EL HAMRI NAIMA                                                                0 1');
        TempFile.Write('31000202923010483001553002208  601500001001EL HAMRI NAIMA                                                                    1 0');
        TempFile.Write('3200020292PLACE FERRER 13 0002               4610     BEYNE-HEUSAY                                                           0 0');
        TempFile.Write('21000202933010483001553002208  0000000000017400041223601500001101000008413738                                      04122333701 0');
        TempFile.Write('2200020293                                                     NOTPROVIDED                        GKCCBEBB                   1 0');
        TempFile.Write('2300020293BE40061658066063                     PIPART WILLY                                                                  0 1');
        TempFile.Write('31000202943010483001553002208  601500001001PIPART WILLY                                                                      1 0');
        TempFile.Write('3200020294BOULEVARD EISENHOWER   103         7500  TOURNAI                                                                   0 0');
        TempFile.Write('21000202953010483001553002208  0000000000015400041223601500001101000008433037                                      04122333701 0');
        TempFile.Write('2200020295                                                     NOTPROVIDED                        BPOTBEB1                   1 0');
        TempFile.Write('2300020295BE12000104681992                     M. ANDRE DERSIN                                                               0 1');
        TempFile.Write('31000202963010483001553002208  601500001001M. ANDRE DERSIN                                                                   1 0');
        TempFile.Write('3200020296Rue Pol Gigot(S),70                7332 Saint-Ghislain                                                             0 0');
        TempFile.Write('21000202973010483001553002208  0000000000015400041223601500001101000008460824                                      04122333701 0');
        TempFile.Write('2200020297                                                     NOTPROVIDED                        GKCCBEBB                   1 0');
        TempFile.Write('2300020297BE72063960618216                     Ngaba Mubo                                                                    0 1');
        TempFile.Write('31000202983010483001553002208  601500001001Ngaba Mubo                                                                        1 0');
        TempFile.Write('3200020298EN HAUTE MAREXHE        39         4040  HERSTAL                                                                   0 0');
        TempFile.Write('21000202993010483001553002208  0000000000017400041223601500001101000008474665                                      04122333701 0');
        TempFile.Write('2200020299                                                     NOTPROVIDED                        GKCCBEBB                   1 0');
        TempFile.Write('2300020299BE29063940223964                     VERGAUTS EDOUARD                                                              0 1');
        TempFile.Write('31000203003010483001553002208  601500001001VERGAUTS EDOUARD                                                                  1 0');
        TempFile.Write('3200020300RUE DU PRE DU SERGENT   13         7170  MANAGE                                                                    0 0');
        TempFile.Write('21000203013010483001553002208  0000000000015400041223601500001101000008485375                                      04122333701 0');
        TempFile.Write('2200020301                                                     NOTPROVIDED                        GKCCBEBB                   1 0');
        TempFile.Write('2300020301BE74063101876307                     NASCA MARIA                                                                   0 1');
        TempFile.Write('31000203023010483001553002208  601500001001NASCA MARIA                                                                       1 0');
        TempFile.Write('3200020302RUE DE WASMES          120         7390  QUAREGNON                                                                 0 0');
        TempFile.Write('21000203033010483001553002208  0000000000014870041223601500001101000008499725                                      04122333701 0');
        TempFile.Write('2200020303                                                     174457002                          GEBABEBB                   1 0');
        TempFile.Write('2300020303BE30001425066911                     VALLEJO Y ORBEA JOSEFA                                                        0 1');
        TempFile.Write('31000203043010483001553002208  601500001001VALLEJO Y ORBEA JOSEFA                                                            1 0');
        TempFile.Write('3200020304Avenue Andromede 23     B041       1200 WOLUWE-SAINT-LAMBERT                                                       0 0');
        TempFile.Write('21000203053010483001553002208  0000000000015400041223601500001101000008502048                                      04122333701 0');
        TempFile.Write('2200020305                                                     175875631                          GEBABEBB                   1 0');
        TempFile.Write('2300020305BE43001526935301                     BRASSEUR DE WARISOUX SOLAN                                                    0 1');
        TempFile.Write('31000203063010483001553002208  601500001001BRASSEUR DE WARISOUX SOLAN                                                        1 0');
        TempFile.Write('3200020306Chee de Waterloo 753    8          1180 UCCLE                                                                      0 0');
        TempFile.Write('21000203073010483001553002208  0000000000021070041223601500001101000008504573                                      04122333701 0');
        TempFile.Write('2200020307                                                     NOTPROVIDED                        BBRUBEBB                   1 0');
        TempFile.Write('2300020307BE18363112066665                     MME MARIA LIVECCHI                                                            0 1');
        TempFile.Write('31000203083010483001553002208  601500001001MME MARIA LIVECCHI                                                                1 0');
        TempFile.Write('3200020308VAN SEVERLAAN 82/51                1970        WEZEMBEEK-O                                                         0 0');
        TempFile.Write('21000203093010483001553002208  0000000000015400041223601500001101000008533471                                      04122333701 0');
        TempFile.Write('2200020309                                                     NOTPROVIDED                        BBRUBEBB                   1 0');
        TempFile.Write('2300020309BE70310022080825                     MME MARIE-BERTHE SPEE                                                         0 1');
        TempFile.Write('31000203103010483001553002208  601500001001MME MARIE-BERTHE SPEE                                                             1 0');
        TempFile.Write('3200020310CHEMIN DES HAYES 17                1380        CT-ST-GERMAIN                                                       0 0');
        TempFile.Write('21000203113010483001553002208  0000000000015400041223601500001101000008566716                                      04122333701 0');
        TempFile.Write('2200020311                                                     NOTPROVIDED                        GEBABEBB                   1 0');
        TempFile.Write('2300020311BE39001001022519                     MILLET CLAUDINE                                                               0 1');
        TempFile.Write('31000203123010483001553002208  601500001001MILLET CLAUDINE                                                                   1 0');
        TempFile.Write('3200020312Av.Sold.Britan. 22                 1070     ANDERLECHT                                                             0 0');
        TempFile.Write('21000203133010483001553002208  0000000000021070041223601500001101000008568231                                      04122333701 0');
        TempFile.Write('2200020313                                                     NOTPROVIDED                        CPHBBE75                   1 0');
        TempFile.Write('2300020313BE73126200459260                     Mme GOSSUIN Emilienne                                                         0 1');
        TempFile.Write('31000203143010483001553002208  601500001001Mme GOSSUIN Emilienne                                                             1 0');
        TempFile.Write('3200020314Rue Deburges 10                    7110      HOUDENG-GOEGNIES                                                      0 0');
        TempFile.Write('21000203153010483001553002208  0000000000015400041223601500001101000008573786                                      04122333701 0');
        TempFile.Write('2200020315                                                     NOTPROVIDED                        GKCCBEBB                   1 0');
        TempFile.Write('2300020315BE63063266815208                     de Halloy de Waulsort S.                                                      0 1');
        TempFile.Write('31000203163010483001553002208  601500001001de Halloy de Waulsort S.                                                          1 0');
        TempFile.Write('3200020316RUE SAINTE-ANNE        150         1300  WAVRE                                                                     0 0');
        TempFile.Write('21000203173010483001553002208  0000000000015400041223601500001101000008600967                                      04122333701 0');
        TempFile.Write('2200020317                                                     NOTPROVIDED                        BBRUBEBB                   1 0');
        TempFile.Write('2300020317BE12363099973492                     MME SUZANNE LECLERCQ                                                          0 1');
        TempFile.Write('31000203183010483001553002208  601500001001MME SUZANNE LECLERCQ                                                              1 0');
        TempFile.Write('3200020318AV DE PEVILLE 16                   4030        GRIVEGNEE                                                           0 0');
        TempFile.Write('21000203193010483001553002208  0000000000021070041223601500001101000008618145                                      04122333701 0');
        TempFile.Write('2200020319                                                     NOTPROVIDED                        ARSPBE22                   1 0');
        TempFile.Write('2300020319BE19979374352812                     GEORGES VANOPBROEKE                                                           0 1');
        TempFile.Write('31000203203010483001553002208  601500001001GEORGES VANOPBROEKE                                                               1 0');
        TempFile.Write('3200020320FAZANTENLAAN 21                    3090 OVERIJSE                                                                   0 0');
        TempFile.Write('21000203213010483001553002208  0000000000015500041223601500001101000008672002                                      04122333701 0');
        TempFile.Write('2200020321                                                     NOTPROVIDED                        GKCCBEBB                   1 0');
        TempFile.Write('2300020321BE63062446913008                     Dumont - BOUHIER                                                              0 1');
        TempFile.Write('31000203223010483001553002208  601500001001Dumont - BOUHIER                                                                  1 0');
        TempFile.Write('3200020322RUE DU RUANDA           17         1040  ETTERBEEK                                                                 0 0');
        TempFile.Write('21000203233010483001553002208  0000000000025000041223601500001101000008680991                                      04122333701 0');
        TempFile.Write('2200020323                                                     173059792                          GEBABEBB                   1 0');
        TempFile.Write('2300020323BE31001114244555                     SCHMALE RUTH                                                                  0 1');
        TempFile.Write('31000203243010483001553002208  601500001001SCHMALE RUTH                                                                      1 0');
        TempFile.Write('3200020324RUE DES COTTAGES 33                1180 UCCLE                                                                      0 0');
        TempFile.Write('21000203253010483001553002208  0000000000017400041223601500001101000008698270                                      04122333701 0');
        TempFile.Write('2200020325                                                     NOTPROVIDED                        GKCCBEBB                   1 0');
        TempFile.Write('2300020325BE04062123624031                     FORET ALAIN                                                                   0 1');
        TempFile.Write('31000203263010483001553002208  601500001001FORET ALAIN                                                                       1 0');
        TempFile.Write('3200020326RUE VICTOR HUGO        115         1030  BRUXELLES                                                                 0 0');
        TempFile.Write('21000203273010483001553002208  0000000000015400041223601500001101000008737878                                      04122333701 0');
        TempFile.Write('2200020327                                                     NOTPROVIDED                        NICABEBB                   1 0');
        TempFile.Write('2300020327BE57103103486035                     Mme Raymonde Hardenne                                                         0 1');
        TempFile.Write('31000203283010483001553002208  601500001001Mme Raymonde Hardenne                                                             1 0');
        TempFile.Write('3200020328Rue de Villereau(BOE),9            4250 Geer                                                                       0 0');
        TempFile.Write('21000203293010483001553002208  0000000000017400041223601500001101000008755258                                      04122333701 0');
        TempFile.Write('2200020329                                                     NOTPROVIDED                        NICABEBB                   1 0');
        TempFile.Write('2300020329BE67103060937387                     Mme Renee Pirson                                                              0 1');
        TempFile.Write('31000203303010483001553002208  601500001001Mme Renee Pirson                                                                  1 0');
        TempFile.Write('3200020330Avenue Prince de Liege(JB),159/00055100 Namur                                                                      0 0');
        TempFile.Write('21000203313010483001553002208  0000000000017400041223601500001101000008776476                                      04122333701 0');
        TempFile.Write('2200020331                                                     173810937                          GEBABEBB                   1 0');
        TempFile.Write('2300020331BE87240038207694                     GOOSSENS FRANCOISE                                                            0 1');
        TempFile.Write('31000203323010483001553002208  601500001001GOOSSENS FRANCOISE                                                                1 0');
        TempFile.Write('3200020332AVENUE BLONDEN 48     0051         4000 LIEGE                                                                      0 0');
        TempFile.Write('21000203333010483001553002208  0000000000017400041223601500001101000008780116                                      04122333701 0');
        TempFile.Write('2200020333                                                     NOTPROVIDED                        BPOTBEB1                   1 0');
        TempFile.Write('2300020333BE69000010435378                     Mme MARIE BRONCHAIN                                                           0 1');
        TempFile.Write('31000203343010483001553002208  601500001001Mme MARIE BRONCHAIN                                                               1 0');
        TempFile.Write('3200020334RUE NAYABOIS, 19                   6030 CHARLEROI                                                                  0 0');
        TempFile.Write('21000203353010483001553002208  0000000000015400041223601500001101000008786984                                      04122333701 0');
        TempFile.Write('2200020335                                                     NOTPROVIDED                        BPOTBEB1                   1 0');
        TempFile.Write('2300020335BE06000096294122                     BRASSEUR                                                                      0 1');
        TempFile.Write('31000203363010483001553002208  601500001001BRASSEUR                                                                          1 0');
        TempFile.Write('3200020336Rue Dury (Emile),152               1410 WATERLOO                                                                   0 0');
        TempFile.Write('21000203373010483001553002208  0000000000017400041223601500001101000008791028                                      04122333701 0');
        TempFile.Write('2200020337                                                     NOTPROVIDED                        BBRUBEBB                   1 0');
        TempFile.Write('2300020337BE04340089152031                     MME LILIANE PIROTTE                                                           0 1');
        TempFile.Write('31000203383010483001553002208  601500001001MME LILIANE PIROTTE                                                               1 0');
        TempFile.Write('3200020338RUE DE ROTHEUX 329/23              4100        SERAING                                                             0 0');
        TempFile.Write('21000203393010483001553002208  0000000000029000041223601500001101000008827505                                      04122333701 0');
        TempFile.Write('2200020339                                                     NOTPROVIDED                        BBRUBEBB                   1 0');
        TempFile.Write('2300020339BE73363182963460                     MME FRANCOISE MARTENS                                                         0 1');
        TempFile.Write('31000203403010483001553002208  601500001001MME FRANCOISE MARTENS                                                             1 0');
        TempFile.Write('3200020340AV DES SEQUOIAS 7                  1950        KRAAINEM                                                            0 0');
        TempFile.Write('21000203413010483001553002208  0000000000023000041223601500001101000008846396                                      04122333701 0');
        TempFile.Write('2200020341                                                     0000000287/0000000003/             BBRUBEBB                   1 0');
        TempFile.Write('2300020341BE31363222917255                     SONDERVORST GEORGE GESTION                                                    0 1');
        TempFile.Write('31000203423010483001553002208  601500001001SONDERVORST GEORGE GESTION                                                        1 0');
        TempFile.Write('3200020342ROUTE DE BEAUMONT 7                1380        CT-ST-GERMAIN                                                       0 0');
        TempFile.Write('21000203433010483001553002208  0000000000015400041223601500001101000008871658                                      04122333701 0');
        TempFile.Write('2200020343                                                     NOTPROVIDED                        GEBABEBB                   1 0');
        TempFile.Write('2300020343BE40250013606963                     LAMOTTE GHISLAINE                                                             0 1');
        TempFile.Write('31000203443010483001553002208  601500001001LAMOTTE GHISLAINE                                                                 1 0');
        TempFile.Write('3200020344Bd Frere Orban 1                   5000 NAMUR                                                                      0 0');
        TempFile.Write('21000203453010483001553002208  0000000000017400041223601500001101000008907226                                      04122333701 0');
        TempFile.Write('2200020345                                                     173956041                          GEBABEBB                   1 0');
        TempFile.Write('2300020345BE12250014754492                     QUOILIN MARTHE                                                                0 1');
        TempFile.Write('31000203463010483001553002208  601500001001QUOILIN MARTHE                                                                    1 0');
        TempFile.Write('3200020346BUZIN 9                            5370 HAVELANGE                                                                  0 0');
        TempFile.Write('21000203473010483001553002208  0000000000015400041223601500001101000008943093                                      04122333701 0');
        TempFile.Write('2200020347                                                     NOTPROVIDED                        GEBABEBB                   1 0');
        TempFile.Write('2300020347BE87001251978794                     BORREMANS CHRISTINE                                                           0 1');
        TempFile.Write('31000203483010483001553002208  601500001001BORREMANS CHRISTINE                                                               1 0');
        TempFile.Write('3200020348Chee de Ruisbroek 35 002-G         1190     FOREST                                                                 0 0');
        TempFile.Write('21000203493010483001553002208  0000000000017400041223601500001101000008946228                                      04122333701 0');
        TempFile.Write('2200020349                                                     NOTPROVIDED                        CREGBEBB                   1 0');
        TempFile.Write('2300020349BE09732038723057                     GHISLAIN MARIE                                                                0 1');
        TempFile.Write('31000203503010483001553002208  601500001001GHISLAIN MARIE                                                                    1 0');
        TempFile.Write('3200020350RUE DU CHAMP LABBE  15            1332    GENVAL                                                                   0 0');
        TempFile.Write('21000203513010483001553002208  0000000000021070041223601500001101000008989977                                      04122333701 0');
        TempFile.Write('2200020351                                                     173697290                          GEBABEBB                   1 0');
        TempFile.Write('2300020351BE17001014777321                     BAYER CATHERINE                                                               0 1');
        TempFile.Write('31000203523010483001553002208  601500001001BAYER CATHERINE                                                                   1 0');
        TempFile.Write('3200020352Av. du Domaine 169    B11          1190 FOREST                                                                     0 0');
        TempFile.Write('21000203533010483001553002208  0000000000015400041223601500001101000009036457                                      04122333701 0');
        TempFile.Write('2200020353                                                     NOTPROVIDED                        BPOTBEB1                   1 0');
        TempFile.Write('2300020353BE63000445114408                     Mme Arlette Fleurquin                                                         0 1');
        TempFile.Write('31000203543010483001553002208  601500001001Mme Arlette Fleurquin                                                             1 0');
        TempFile.Write('3200020354Rue de Dour(B-C),59                7300 Boussu                                                                     0 0');
        TempFile.Write('21000203553010483001553002208  0000000000015400041223601500001101000009080412                                      04122333701 0');
        TempFile.Write('2200020355                                                     NOTPROVIDED                        BBRUBEBB                   1 0');
        TempFile.Write('2300020355BE40360040348063                     MME CONCETTA POLITO                                                           0 1');
        TempFile.Write('31000203563010483001553002208  601500001001MME CONCETTA POLITO                                                               1 0');
        TempFile.Write('3200020356RUE DE GILLY 460                   6200        CHATELINEAU                                                         0 0');
        TempFile.Write('21000203573010483001553002208  0000000000015400041223601500001101000009101327                                      04122333701 0');
        TempFile.Write('2200020357                                                     174369146                          GEBABEBB                   1 0');
        TempFile.Write('2300020357BE73001031775660                     SCHOONEN ANDRE                                                                0 1');
        TempFile.Write('31000203583010483001553002208  601500001001SCHOONEN ANDRE                                                                    1 0');
        TempFile.Write('3200020358R.Stevens-Delannoy 62              1020 BRUXELLES                                                                  0 0');
        TempFile.Write('21000203593010483001553002208  0000000000015400041223601500001101000009110623                                      04122333701 0');
        TempFile.Write('2200020359                                                     NOTPROVIDED                        BBRUBEBB                   1 0');
        TempFile.Write('2300020359BE41377075152910                     M GUY DE MOOR                                                                 0 1');
        TempFile.Write('31000203603010483001553002208  601500001001M GUY DE MOOR                                                                     1 0');
        TempFile.Write('3200020360AV W CHURCHILL 160 14              1180        UCCLE                                                               0 0');
        TempFile.Write('21000203613010483001553002208  0000000000015400041223601500001101000009122646                                      04122333701 0');
        TempFile.Write('2200020361                                                     NOTPROVIDED                        GKCCBEBB                   1 0');
        TempFile.Write('2300020361BE56063022800388                     Bingen Jacqueline                                                             0 1');
        TempFile.Write('31000203623010483001553002208  601500001001Bingen Jacqueline                                                                 1 0');
        TempFile.Write('3200020362AVENUE DU DAIM          19         1170  WATERMAEL-BOITSFORT                                                       0 0');
        TempFile.Write('21000203633010483001553002208  0000000000021070041223601500001101000009136588                                      04122333701 0');
        TempFile.Write('2200020363                                                     0000000133/                        BBRUBEBB                   1 0');
        TempFile.Write('2300020363BE59310080862926                     MME ALINA SOREL                                                               0 1');
        TempFile.Write('31000203643010483001553002208  601500001001MME ALINA SOREL                                                                   1 0');
        TempFile.Write('3200020364AV MOLIERE 63 BTE 1                1190        FOREST                                                              0 0');
        TempFile.Write('21000203653010483001553002208  0000000000025000041223601500001101000009167712                                      04122333701 0');
        TempFile.Write('2200020365                                                     NOTPROVIDED                        NICABEBB                   1 0');
        TempFile.Write('2300020365BE61103016455817                     Mme Gilberte Vandenabeelle                                                    0 1');
        TempFile.Write('31000203663010483001553002208  601500001001Mme Gilberte Vandenabeelle                                                        1 0');
        TempFile.Write('3200020366Rue Triboureau,17                  7190 Ecaussinnes                                                                0 0');
        TempFile.Write('21000203673010483001553002208  0000000000023000041223601500001101000009168924                                      04122333701 0');
        TempFile.Write('2200020367                                                     NOTPROVIDED                        GEBABEBB                   1 0');
        TempFile.Write('2300020367BE85240024541206                     CLAESSEN JOSIANE                                                              0 1');
        TempFile.Write('31000203683010483001553002208  601500001001CLAESSEN JOSIANE                                                                  1 0');
        TempFile.Write('3200020368THIER DE HODIMONT 81               4800     VERVIERS                                                               0 0');
        TempFile.Write('21000203693010483001553002208  0000000000021070041223601500001101000009186203                                      04122333701 0');
        TempFile.Write('2200020369                                                     NOTPROVIDED                        BBRUBEBB                   1 0');
        TempFile.Write('2300020369BE89363115046585                     M LEOPOLD M DEKERPEL                                                          0 1');
        TempFile.Write('31000203703010483001553002208  601500001001M LEOPOLD M DEKERPEL                                                              1 0');
        TempFile.Write('3200020370RUE DE LAGRONOME 171              1070        ANDERLECHT                                                           0 0');
        TempFile.Write('21000203713010483001553002208  0000000000015400041223601500001101000009196711                                      04122333701 0');
        TempFile.Write('2200020371                                                     NOTPROVIDED                        BBRUBEBB                   1 0');
        TempFile.Write('2300020371BE76363105085695                     MME LIDIA FINETTI                                                             0 1');
        TempFile.Write('31000203723010483001553002208  601500001001MME LIDIA FINETTI                                                                 1 0');
        TempFile.Write('3200020372RUE DU FORT 380                    4100        SERAING                                                             0 0');
        TempFile.Write('21000203733010483001553002208  0000000000015400041223601500001101000009200852                                      04122333701 0');
        TempFile.Write('2200020373                                                     NOTPROVIDED                        GEBABEBB                   1 0');
        TempFile.Write('2300020373BE03210076914584                     VANTUYCKOM JACQUES                                                            0 1');
        TempFile.Write('31000203743010483001553002208  601500001001VANTUYCKOM JACQUES                                                                1 0');
        TempFile.Write('3200020374Rue a lEau 14                     1380     LASNE                                                                   0 0');
        TempFile.Write('21000203753010483001553002208  0000000000015400041223601500001101000009202771                                      04122333701 0');
        TempFile.Write('2200020375                                                     NOTPROVIDED                        GEBABEBB                   1 0');
        TempFile.Write('2300020375BE56275045148188                     PIERRE-CAMBIER                                                                0 1');
        TempFile.Write('31000203763010483001553002208  601500001001PIERRE-CAMBIER                                                                    1 0');
        TempFile.Write('3200020376R.d.lAbbaye 164                   7800 ATH                                                                         0 0');
        TempFile.Write('21000203773010483001553002208  0000000000025000041223601500001101000009203074                                      04122333701 0');
        TempFile.Write('2200020377                                                     NOTPROVIDED                        BPOTBEB1                   1 0');
        TempFile.Write('2300020377BE94000138759914                     M. Maurice Thonard                                                            0 1');
        TempFile.Write('31000203783010483001553002208  601500001001M. Maurice Thonard                                                                1 0');
        TempFile.Write('3200020378Rue Principale,8                   4190 FERRIERES                                                                  0 0');
        TempFile.Write('21000203793010483001553002208  0000000000015400041223601500001101000009213481                                      04122333701 0');
        TempFile.Write('2200020379                                                     NOTPROVIDED                        BBRUBEBB                   1 0');
        TempFile.Write('2300020379BE85363097530106                     MME FRANCOISE YERNAUX                                                         0 1');
        TempFile.Write('31000203803010483001553002208  601500001001MME FRANCOISE YERNAUX                                                             1 0');
        TempFile.Write('3200020380RUE A DETIENNE 3/B0.3              1030        SCHAERBEEK                                                          0 0');
        TempFile.Write('21000203813010483001553002208  0000000000017400041223601500001101000009214592                                      04122333701 0');
        TempFile.Write('2200020381                                                     NOTPROVIDED                        BPOTBEB1                   1 0');
        TempFile.Write('2300020381BE69000454879678                     Mme Marie-Claire Nicolas                                                      0 1');
        TempFile.Write('31000203823010483001553002208  601500001001Mme Marie-Claire Nicolas                                                          1 0');
        TempFile.Write('3200020382Rue de la Station, Nismes,15       5670 Viroinval                                                                  0 0');
        TempFile.Write('21000203833010483001553002208  0000000000021070041223601500001101000009226215                                      04122333701 0');
        TempFile.Write('2200020383                                                     174779361                          GEBABEBB                   1 0');
        TempFile.Write('2300020383BE54293034167697                     VAN DER HAEGEN JOSEPHA                                                        0 1');
        TempFile.Write('31000203843010483001553002208  601500001001VAN DER HAEGEN JOSEPHA                                                            1 0');
        TempFile.Write('3200020384R.P.Broodcoorens 46     D-36       1310 LA HULPE                                                                   0 0');
        TempFile.Write('21000203853010483001553002208  0000000000015400041223601500001101000009232376                                      04122333701 0');
        TempFile.Write('2200020385                                                     NOTPROVIDED                        GEBABEBB                   1 0');
        TempFile.Write('2300020385BE97240038416549                     BISSCHOPS-THIEBAUT                                                            0 1');
        TempFile.Write('31000203863010483001553002208  601500001001BISSCHOPS-THIEBAUT                                                                1 0');
        TempFile.Write('3200020386RUE FRAISCHAMPS 125                4030 LIEGE                                                                      0 0');
        TempFile.Write('21000203873010483001553002208  0000000000015400041223601500001101000009243288                                      04122333701 0');
        TempFile.Write('2200020387                                                     NOTPROVIDED                        GKCCBEBB                   1 0');
        TempFile.Write('2300020387BE02061960791040                     PALIN LIDIA                                                                   0 1');
        TempFile.Write('31000203883010483001553002208  601500001001PALIN LIDIA                                                                       1 0');
        TempFile.Write('3200020388RUE DES FABRIQUES        3         7070  VILLE-SUR-HAINE                                                           0 0');
        TempFile.Write('21000203893010483001553002208  0000000000015400041223601500001101000009243490                                      04122333701 0');
        TempFile.Write('2200020389                                                     NOTPROVIDED                        BPOTBEB1                   1 0');
        TempFile.Write('2300020389BE59000337572326                     Mme MARIE BEGUIN                                                              0 1');
        TempFile.Write('31000203903010483001553002208  601500001001Mme MARIE BEGUIN                                                                  1 0');
        TempFile.Write('3200020390Rue des Residences,Moustier,28     5190 Jemeppe-sur-Sambre                                                         0 0');
        TempFile.Write('21000203913010483001553002208  0000000000015400041223601500001101000009254810                                      04122333701 0');
        TempFile.Write('2200020391                                                     NOTPROVIDED                        ARSPBE22                   1 0');
        TempFile.Write('2300020391BE62973157239761                     JACQUELINE VAN AUDENHOVE                                                      0 1');
        TempFile.Write('31000203923010483001553002208  601500001001JACQUELINE VAN AUDENHOVE                                                          1 0');
        TempFile.Write('3200020392QUAI DE VEEWEYDE 11                1070 ANDERLECHT                                                                 0 0');
        TempFile.Write('21000203933010483001553002208  0000000000015400041223601500001101000009255113                                      04122333701 0');
        TempFile.Write('2200020393                                                     VZ33363AUNPTNT01                   CTBKBEBX                   1 0');
        TempFile.Write('2300020393BE88950161971541                     Mme MARGUERITE DEMOL                                                          0 1');
        TempFile.Write('31000203943010483001553002208  601500001001Mme MARGUERITE DEMOL                                                              1 0');
        TempFile.Write('3200020394CHAUSSEE DE MONS 25 BTE 18         1400 NIVELLES                                                                   0 0');
        TempFile.Write('21000203953010483001553002208  0000000000015400041223601500001101000009260567                                      04122333701 0');
        TempFile.Write('2200020395                                                     NOTPROVIDED                        BPOTBEB1                   1 0');
        TempFile.Write('2300020395BE57000444234435                     Mme GINETTE VINCENT                                                           0 1');
        TempFile.Write('31000203963010483001553002208  601500001001Mme GINETTE VINCENT                                                               1 0');
        TempFile.Write('3200020396Rue Vinave(ENG),38 /B000           4480 ENGIS                                                                      0 0');
        TempFile.Write('21000203973010483001553002208  0000000000023000041223601500001101000009261678                                      04122333701 0');
        TempFile.Write('2200020397                                                     VZ333620A469GB01                   CTBKBEBX                   1 0');
        TempFile.Write('2300020397BE25950160995982                     M DANIEL BONHOMME OU Mme CLAIRE                                               0 1');
        TempFile.Write('31000203983010483001553002208  601500001001M DANIEL BONHOMME OU Mme CLAIRE                                                   1 0');
        TempFile.Write('3200020398PLACE VERHEYLEWEGHEN 16            1200 WOLUWE-SAINT-LAMBERT                                                       0 0');
        TempFile.Write('21000203993010483001553002208  0000000000015400041223601500001101000009263496                                      04122333701 0');
        TempFile.Write('2200020399                                                     NOTPROVIDED                        GKCCBEBB                   1 0');
        TempFile.Write('2300020399BE03063913890484                     Miller Micheline                                                              0 1');
        TempFile.Write('31000204003010483001553002208  601500001001Miller Micheline                                                                  1 0');
        TempFile.Write('3200020400RUE FRERES TAYMANS      47         1480  TUBIZE                                                                    0 0');
        TempFile.Write('21000204013010483001553002208  0000000000015400041223601500001101000009263601                                      04122333701 0');
        TempFile.Write('2200020401                                                     NOTPROVIDED                        BBRUBEBB                   1 0');
        TempFile.Write('2300020401BE53363154590253                     M MARCEL NEVEN                                                                0 1');
        TempFile.Write('31000204023010483001553002208  601500001001M MARCEL NEVEN                                                                    1 0');
        TempFile.Write('3200020402AV REINE ELISABETH 23              1410        WATERLOO                                                            0 0');
        TempFile.Write('21000204033010483001553002208  0000000000017400041223601500001101000009268348                                      04122333701 0');
        TempFile.Write('2200020403                                                     NOTPROVIDED                        BBRUBEBB                   1 0');
        TempFile.Write('2300020403BE15363145130430                     MME COLETTE CRICK                                                             0 1');
        TempFile.Write('31000204043010483001553002208  601500001001MME COLETTE CRICK                                                                 1 0');
        TempFile.Write('3200020404DREVE DU CAPORAL 1 BT 3            1180        UCCLE                                                               0 0');
        TempFile.Write('21000204053010483001553002208  0000000000017400041223601500001101000009278553                                      04122333701 0');
        TempFile.Write('2200020405                                                     NOTPROVIDED                        CREGBEBBXXX                1 0');
        TempFile.Write('2300020405BE18198027524165                     MANET MAURICE                                                                 0 1');
        TempFile.Write('31000204063010483001553002208  601500001001MANET MAURICE                                                                     1 0');
        TempFile.Write('3200020406RUE DE LESCAFENE    4             6532     RAGNIES                                                                 0 0');
        TempFile.Write('21000204073010483001553002208  0000000000025000041223601500001101000009282795                                      04122333701 0');
        TempFile.Write('2200020407                                                     NOTPROVIDED                        AXABBE22                   1 0');
        TempFile.Write('2300020407BE03750700516984                     Ansay Thierry                                                                 0 1');
        TempFile.Write('31000204083010483001553002208  601500001001Ansay Thierry                                                                     1 0');
        TempFile.Write('3200020408Impasse des Mesanges 11            5340 GESVES                                                                     0 0');
        TempFile.Write('21000204093010483001553002208  0000000000015400041223601500001101000009308461                                      04122333701 0');
        TempFile.Write('2200020409                                                     NOTPROVIDED                        GEBABEBB                   1 0');
        TempFile.Write('2300020409BE83240092102615                     BECKER HELENE                                                                 0 1');
        TempFile.Write('31000204103010483001553002208  601500001001BECKER HELENE                                                                     1 0');
        TempFile.Write('3200020410Rue du Nouveau Sart 18             4050     CHAUDFONTAINE                                                          0 0');
        TempFile.Write('21000204113010483001553002208  0000000000023000041223601500001101000009309471                                      04122333701 0');
        TempFile.Write('2200020411                                                     NOTPROVIDED                        BPOTBEB1                   1 0');
        TempFile.Write('2300020411BE14000081080983                     DEBRUS-VANDENBERGHE                                                           0 1');
        TempFile.Write('31000204123010483001553002208  601500001001DEBRUS-VANDENBERGHE                                                               1 0');
        TempFile.Write('3200020412RUE DES SAULES, 33                 1380 LASNE                                                                      0 0');
        TempFile.Write('21000204133010483001553002208  0000000000015400041223601500001101000009325033                                      04122333701 0');
        TempFile.Write('2200020413                                                     NOTPROVIDED                        BBRUBEBB                   1 0');
        TempFile.Write('2300020413BE50310081104618                     MME NICOLE VIELVOYE                                                           0 1');
        TempFile.Write('31000204143010483001553002208  601500001001MME NICOLE VIELVOYE                                                               1 0');
        TempFile.Write('3200020414CLOS DU VERGER 10                  1471        LOUPOIGNE                                                           0 0');
        TempFile.Write('21000204153010483001553002208  0000000000015400041223601500001101000009325134                                      04122333701 0');
        TempFile.Write('2200020415                                                     e563296b605d48bf9037443949         BPOTBEB1                   1 0');
        TempFile.Write('2300020415BE54000000000097                     Raymond Julia Carpe                                                           0 1');
        TempFile.Write('31000204163010483001553002208  601500001001Raymond Julia Carpe                                                               1 0');
        TempFile.Write('3200020416Rue de lEnseignement, 62           4102 Seraing                                                                    0 0');
        TempFile.Write('21000204173010483001553002208  0000000000015400041223601500001101000009336955                                      04122333701 0');
        TempFile.Write('2200020417                                                     93396                              BBRUBEBB                   1 0');
        TempFile.Write('2300020417BE03377120643684                     MME DAMSIN ROSE                                                               0 1');
        TempFile.Write('31000204183010483001553002208  601500001001MME DAMSIN ROSE                                                                   1 0');
        TempFile.Write('3200020418PROMENADE DES OURS 13 2            5300        ANDENNE                                                             0 0');
        TempFile.Write('21000204193010483001553002208  0000000000021070041223601500001101000009369691                                      04122333701 0');
        TempFile.Write('2200020419                                                     NOTPROVIDED                        BBRUBEBB                   1 0');
        TempFile.Write('2300020419BE17377138883021                     M PIERRE DEJOIE                                                               0 1');
        TempFile.Write('31000204203010483001553002208  601500001001M PIERRE DEJOIE                                                                   1 0');
        TempFile.Write('3200020420RUE JACQUES DESIRA 15              4340        VILLERS-LEVEQ                                                       0 0');
        TempFile.Write('21000204213010483001553002208  0000000000015400041223601500001101000009373735                                      04122333701 0');
        TempFile.Write('2200020421                                                     NOTPROVIDED                        BBRUBEBB                   1 0');
        TempFile.Write('2300020421BE21363234231903                     TORDEURS CHR. - GESTION                                                       0 1');
        TempFile.Write('31000204223010483001553002208  601500001001TORDEURS CHR. - GESTION                                                           1 0');
        TempFile.Write('3200020422GRANDROUTE 204                    1428        LILLOIS-WITTERZEE                                                    0 0');
        TempFile.Write('21000204233010483001553002208  0000000000021070041223601500001101000009377977                                      04122333701 0');
        TempFile.Write('2200020423                                                     NOTPROVIDED                        BBRUBEBB                   1 0');
        TempFile.Write('2300020423BE25310084729182                     M DANIEL OZMEC                                                                0 1');
        TempFile.Write('31000204243010483001553002208  601500001001M DANIEL OZMEC                                                                    1 0');
        TempFile.Write('3200020424RUE DE LEGLISE 126                6927        TELLIN                                                               0 0');
        TempFile.Write('21000204253010483001553002208  0000000000029000041223601500001101000009387374                                      04122333701 0');
        TempFile.Write('2200020425                                                     NOTPROVIDED                        GKCCBEBB                   1 0');
        TempFile.Write('2300020425BE43063111207101                     Sadones Gerard                                                                0 1');
        TempFile.Write('31000204263010483001553002208  601500001001Sadones Gerard                                                                    1 0');
        TempFile.Write('3200020426CHAUSSEE DE NIVELLES    70         6230  PONT-A-CELLES                                                             0 0');
        TempFile.Write('21000204273010483001553002208  0000000000015400041223601500001101000009389802                                      04122333701 0');
        TempFile.Write('2200020427                                                     NOTPROVIDED                        NICABEBB                   1 0');
        TempFile.Write('2300020427BE47103101405080                     Mme Helene Filippini                                                          0 1');
        TempFile.Write('31000204283010483001553002208  601500001001Mme Helene Filippini                                                              1 0');
        TempFile.Write('3200020428RUE OCTAVE CHABOT 73               4357 HANEFFE                                                                    0 0');
        TempFile.Write('21000204293010483001553002208  0000000000015400041223601500001101000009391115                                      04122333701 0');
        TempFile.Write('2200020429                                                     174785102                          GEBABEBB                   1 0');
        TempFile.Write('2300020429BE66001755558843                     CLAES JEANNINE                                                                0 1');
        TempFile.Write('31000204303010483001553002208  601500001001CLAES JEANNINE                                                                    1 0');
        TempFile.Write('3200020430Dreve du Bonheur 1                 1150 WOLUWE-SAINT-PIERRE                                                        0 0');
        TempFile.Write('21000204313010483001553002208  0000000000015400041223601500001101000009405057                                      04122333701 0');
        TempFile.Write('2200020431                                                     NOTPROVIDED                        BBRUBEBB                   1 0');
        TempFile.Write('2300020431BE53377020497753                     MME MARIA BRAEM                                                               0 1');
        TempFile.Write('31000204323010483001553002208  601500001001MME MARIA BRAEM                                                                   1 0');
        TempFile.Write('3200020432ROUTE DU GROS BUCHY 9/1            6850        CARLSBOURG                                                          0 0');
        TempFile.Write('21000204333010483001553002208  0000000000015400041223601500001101000009411929                                      04122333701 0');
        TempFile.Write('2200020433                                                     NOTPROVIDED                        GKCCBEBB                   1 0');
        TempFile.Write('2300020433BE05063661126975                     Decerf Gilberte                                                               0 1');
        TempFile.Write('31000204343010483001553002208  601500001001Decerf Gilberte                                                                   1 0');
        TempFile.Write('3200020434BD GUSTAVE KLEYER      181         4000  LIEGE                                                                     0 0');
        TempFile.Write('21000204353010483001553002208  0000000000023000041223601500001101000009412737                                      04122333701 0');
        TempFile.Write('2200020435                                                     NOTPROVIDED                        BBRUBEBB                   1 0');
        TempFile.Write('2300020435BE53363025269853                     MME JOELLE D ARMIENTO                                                         0 1');
        TempFile.Write('31000204363010483001553002208  601500001001MME JOELLE D ARMIENTO                                                             1 0');
        TempFile.Write('3200020436SQ DE RIMINI 8                     4100        SERAING                                                             0 0');
        TempFile.Write('21000204373010483001553002208  0000000000015400041223601500001101000009422033                                      04122333701 0');
        TempFile.Write('2200020437                                                     VZ33361JRY6PHG01                   CTBKBEBX                   1 0');
        TempFile.Write('2300020437BE95950142214358                     Mme LILIANE DE WEERDT                                                         0 1');
        TempFile.Write('31000204383010483001553002208  601500001001Mme LILIANE DE WEERDT                                                             1 0');
        TempFile.Write('3200020438CHAUSSEE DE MONS 428               1480 TUBIZE                                                                     0 0');
        TempFile.Write('21000204393010483001553002208  0000000000015400041223601500001101000009447901                                      04122333701 0');
        TempFile.Write('2200020439                                                     NOTPROVIDED                        BNAGBEBB                   1 0');
        TempFile.Write('2300020439BE20635395770256                     MME CAMMAERTS PAULA                                                           0 1');
        TempFile.Write('31000204403010483001553002208  601500001001MME CAMMAERTS PAULA                                                               1 0');
        TempFile.Write('3200020440RUE E. TOUSSAINT 54/12             1090       JETTE                                                                0 0');
        TempFile.Write('21000204413010483001553002208  0000000000021070041223601500001101000009451840                                      04122333701 0');
        TempFile.Write('2200020441                                                     NOTPROVIDED                        NICABEBB                   1 0');
        TempFile.Write('2300020441BE61103111089017                     VAILLANT L BRUMAGNE V                                                         0 1');
        TempFile.Write('31000204423010483001553002208  601500001001VAILLANT L BRUMAGNE V                                                             1 0');
        TempFile.Write('3200020442AV BOUVREUILS    8                 1340 OTTIGNIES                                                                  0 0');
        TempFile.Write('21000204433010483001553002208  0000000000015400041223601500001101000009458712                                      04122333701 0');
        TempFile.Write('2200020443                                                     NOTPROVIDED                        BBRUBEBB                   1 0');
        TempFile.Write('2300020443BE88363014773241                     MME GERMAINE COMES                                                            0 1');
        TempFile.Write('31000204443010483001553002208  601500001001MME GERMAINE COMES                                                                1 0');
        TempFile.Write('3200020444CLOS LAURIERS ROSES 103 3          1140        EVERE                                                               0 0');
        TempFile.Write('21000204453010483001553002208  0000000000015400041223601500001101000009466388                                      04122333701 0');
        TempFile.Write('2200020445                                                     NOTPROVIDED                        BBRUBEBB                   1 0');
        TempFile.Write('2300020445BE57310048504635                     MME MARIA BAECKELMANS                                                         0 1');
        TempFile.Write('31000204463010483001553002208  601500001001MME MARIA BAECKELMANS                                                             1 0');
        TempFile.Write('3200020446AV DE LA BELLE VOIE 1/6            1300        WAVRE                                                               0 0');
        TempFile.Write('21000204473010483001553002208  0000000000015400041223601500001101000009475078                                      04122333701 0');
        TempFile.Write('2200020447                                                     176717894                          GEBABEBB                   1 0');
        TempFile.Write('2300020447BE50210034577118                     LANOTTE DANIELE                                                               0 1');
        TempFile.Write('31000204483010483001553002208  601500001001LANOTTE DANIELE                                                                   1 0');
        TempFile.Write('3200020448Av.de Tervueren 66     CB74        1040 ETTERBEEK                                                                  0 0');
        TempFile.Write('21000204493010483001553002208  0000000000015400041223601500001101000009482657                                      04122333701 0');
        TempFile.Write('2200020449                                                     NOTPROVIDED                        BPOTBEB1                   1 0');
        TempFile.Write('2300020449BE91000094563276                     Mme MARIE BERTRAND                                                            0 1');
        TempFile.Write('31000204503010483001553002208  601500001001Mme MARIE BERTRAND                                                                1 0');
        TempFile.Write('3200020450CHAUSSEEE D ALSEMBERG,1033/E140    1180 BRUXELLES                                                                  0 0');
        TempFile.Write('21000204513010483001553002208  0000000000017400041223601500001101000009504784                                      04122333701 0');
        TempFile.Write('2200020451                                                     NOTPROVIDED                        BBRUBEBB                   1 0');
        TempFile.Write('2300020451BE37371012635328                     MME BETSY DENEVE                                                              0 1');
        TempFile.Write('31000204523010483001553002208  601500001001MME BETSY DENEVE                                                                  1 0');
        TempFile.Write('3200020452RUE DE VIRELLES 22                 6460        CHIMAY                                                              0 0');
        TempFile.Write('21000204533010483001553002208  0000000000015400041223601500001101000009506097                                      04122333701 0');
        TempFile.Write('2200020453                                                     NOTPROVIDED                        GEBABEBB                   1 0');
        TempFile.Write('2300020453BE25001949029282                     FRIEDLENDER LAURA                                                             0 1');
        TempFile.Write('31000204543010483001553002208  601500001001FRIEDLENDER LAURA                                                                 1 0');
        TempFile.Write('3200020454Av. du Vieux Moutier 22 A          1640     RHODE-SAINT-GENESE                                                     0 0');
        TempFile.Write('21000204553010483001553002208  0000000000015400041223601500001101000009526511                                      04122333701 0');
        TempFile.Write('2200020455                                                     NOTPROVIDED                        GKCCBEBB                   1 0');
        TempFile.Write('2300020455BE14063001324083                     LIENART JACQUES                                                               0 1');
        TempFile.Write('31000204563010483001553002208  601500001001LIENART JACQUES                                                                   1 0');
        TempFile.Write('3200020456RUE DE FERRIERE          1         1470  GENAPPE                                                                   0 0');
        TempFile.Write('21000204573010483001553002208  0000000000021070041223601500001101000009531359                                      04122333701 0');
        TempFile.Write('2200020457                                                     NOTPROVIDED                        GEBABEBB                   1 0');
        TempFile.Write('2300020457BE97210098512949                     NTINIAROPOULOU DIMITRIA                                                       0 1');
        TempFile.Write('31000204583010483001553002208  601500001001NTINIAROPOULOU DIMITRIA                                                           1 0');
        TempFile.Write('3200020458R.Emile Carpentier 21              1070     ANDERLECHT                                                             0 0');
        TempFile.Write('21000204593010483001553002208  0000000000023000041223601500001101000009533682                                      04122333701 0');
        TempFile.Write('2200020459                                                     NOTPROVIDED                        BBRUBEBB                   1 0');
        TempFile.Write('2300020459BE09377130690157                     MME JEANNE MALHERBE                                                           0 1');
        TempFile.Write('31000204603010483001553002208  601500001001MME JEANNE MALHERBE                                                               1 0');
        TempFile.Write('3200020460RUE DE LESPLANADE 18/8            4141        LOUVEIGNE                                                            0 0');
        TempFile.Write('21000204613010483001553002208  0000000000015400041223601500001101000009547325                                      04122333701 0');
        TempFile.Write('2200020461                                                     NOTPROVIDED                        BPOTBEB1                   1 0');
        TempFile.Write('2300020461BE19000076864012                     Mme JOSETTE HIOLLE                                                            0 1');
        TempFile.Write('31000204623010483001553002208  601500001001Mme JOSETTE HIOLLE                                                                1 0');
        TempFile.Write('3200020462Avenue de la Croix du Sud,9        1410 WATERLOO                                                                   0 0');
        TempFile.Write('21000204633010483001553002208  0000000000015400041223601500001101000009551567                                      04122333701 0');
        TempFile.Write('2200020463                                                     NOTPROVIDED                        BNAGBEBB                   1 0');
        TempFile.Write('2300020463BE33634276360146                     DELFOSSE MARIETTE                                                             0 1');
        TempFile.Write('31000204643010483001553002208  601500001001DELFOSSE MARIETTE                                                                 1 0');
        TempFile.Write('3200020464RUE HIPPOLYTE-CORNET 50            4032 CHENEE                                                                     0 0');
        TempFile.Write('21000204653010483001553002208  0000000000015400041223601500001101000009564503                                      04122333701 0');
        TempFile.Write('2200020465                                                     NOTPROVIDED                        BPOTBEB1                   1 0');
        TempFile.Write('2300020465BE89000026266485                     Mme Fernande Gilles                                                           0 1');
        TempFile.Write('31000204663010483001553002208  601500001001Mme Fernande Gilles                                                               1 0');
        TempFile.Write('3200020466RUE ABBECHAMPS, 67                 5300 ANDENNE                                                                    0 0');
        TempFile.Write('21000204673010483001553002208  0000000000017400041223601500001101000009568745                                      04122333701 0');
        TempFile.Write('2200020467                                                     NOTPROVIDED                        ARSPBE22                   1 0');
        TempFile.Write('2300020467BE60973467436970                     ANNE GODET                                                                    0 1');
        TempFile.Write('31000204683010483001553002208  601500001001ANNE GODET                                                                        1 0');
        TempFile.Write('3200020468RUE DU LOMBARD 61                  5000 NAMUR                                                                      0 0');
        TempFile.Write('21000204693010483001553002208  0000000000017400041223601500001101000009579859                                      04122333701 0');
        TempFile.Write('2200020469                                                     NOTPROVIDED                        BPOTBEB1                   1 0');
        TempFile.Write('2300020469BE96000465552005                     M. PIERRE BOURGUIGNON                                                         0 1');
        TempFile.Write('31000204703010483001553002208  601500001001M. PIERRE BOURGUIGNON                                                             1 0');
        TempFile.Write('3200020470Rue Francois Jassogne,5            5300 ANDENNE                                                                    0 0');
        TempFile.Write('21000204713010483001553002208  0000000000023000041223601500001101000009588953                                      04122333701 0');
        TempFile.Write('2200020471                                                     NOTPROVIDED                        BBRUBEBB                   1 0');
        TempFile.Write('2300020471BE47363194227180                     MME MARTINE DAGNEAU                                                           0 1');
        TempFile.Write('31000204723010483001553002208  601500001001MME MARTINE DAGNEAU                                                               1 0');
        TempFile.Write('3200020472CH DE BRUXELLES 111C  BTE7         1410        WATERLOO                                                            0 0');
        TempFile.Write('21000204733010483001553002208  0000000000015400041223601500001101000009597946                                      04122333701 0');
        TempFile.Write('2200020473                                                     NOTPROVIDED                        BBRUBEBB                   1 0');
        TempFile.Write('2300020473BE98310044329793                     MLLE FRANCINE COLLIN                                                          0 1');
        TempFile.Write('31000204743010483001553002208  601500001001MLLE FRANCINE COLLIN                                                              1 0');
        TempFile.Write('3200020474RUE DU MONUMENT 47                 1340        OTTIGNIES                                                           0 0');
        TempFile.Write('21000204753010483001553002208  0000000000015400041223601500001101000009602289                                      04122333701 0');
        TempFile.Write('2200020475                                                     NOTPROVIDED                        GKCCBEBB                   1 0');
        TempFile.Write('2300020475BE97063717733549                     Leblanc Monique                                                               0 1');
        TempFile.Write('31000204763010483001553002208  601500001001Leblanc Monique                                                                   1 0');
        TempFile.Write('3200020476AV FORET DE SOIGNES    365         1640  RHODE-SAINT-GENESE                                                        0 0');
        TempFile.Write('21000204773010483001553002208  0000000000015400041223601500001101000009603097                                      04122333701 0');
        TempFile.Write('2200020477                                                     VZ33361ZZ5BC0T01                   CTBKBEBX                   1 0');
        TempFile.Write('2300020477BE03953140583984                     Mme NADINE BAUDOUX                                                            0 1');
        TempFile.Write('31000204783010483001553002208  601500001001Mme NADINE BAUDOUX                                                                1 0');
        TempFile.Write('3200020478RUE DE BOURGOGNE 20                6150 ANDERLUES                                                                  0 0');
        TempFile.Write('21000204793010483001553002208  0000000000015400041223601500001101000009615225                                      04122333701 0');
        TempFile.Write('2200020479                                                     NOTPROVIDED                        BNAGBEBB                   1 0');
        TempFile.Write('2300020479BE11634226250148                     CUELERS RENEE                                                                 0 1');
        TempFile.Write('31000204803010483001553002208  601500001001CUELERS RENEE                                                                     1 0');
        TempFile.Write('3200020480AVENUE DES ALOUETTES(N) 13         4121 NEUVILLE-EN-CONDROZ                                                        0 0');
        TempFile.Write('21000204813010483001553002208  0000000000010000041223601500001101000009621790                                      04122333701 0');
        TempFile.Write('2200020481                                                     I65V23336L013457                   CTBKBEBX                   1 0');
        TempFile.Write('2300020481BE98950156661193                     MME JOCELINE SEGAERT                                                          0 1');
        TempFile.Write('31000204823010483001553002208  601500001001MME JOCELINE SEGAERT                                                              1 0');
        TempFile.Write('3200020482RUE DE LETHIOPIE 29               6010 COUILLET                                                                    0 0');
        TempFile.Write('21000204833010483001553002208  0000000000015400041223601500001101000009626238                                      04122333701 0');
        TempFile.Write('2200020483                                                     NOTPROVIDED                        NICABEBB                   1 0');
        TempFile.Write('2300020483BE64103113148952                     Mme Odette Wilmes                                                             0 1');
        TempFile.Write('31000204843010483001553002208  601500001001Mme Odette Wilmes                                                                 1 0');
        TempFile.Write('3200020484Rue dEngihoul, 71                  4550 Nandrin                                                                    0 0');
        TempFile.Write('21000204853010483001553002208  0000000000015400041223601500001101000009630581                                      04122333701 0');
        TempFile.Write('2200020485                                                     NOTPROVIDED                        NICABEBB                   1 0');
        TempFile.Write('2300020485BE75103032522451                     M. Francois Moureau                                                           0 1');
        TempFile.Write('31000204863010483001553002208  601500001001M. Francois Moureau                                                               1 0');
        TempFile.Write('3200020486Au long pre,61                     4053 Chaudfontaine                                                              0 0');
        TempFile.Write('21000204873010483001553002208  0000000000023000041223601500001101000009657257                                      04122333701 0');
        TempFile.Write('2200020487                                                     NOTPROVIDED                        GKCCBEBB                   1 0');
        TempFile.Write('2300020487BE44063470014545                     POLLAERT CHRISTIANE                                                           0 1');
        TempFile.Write('31000204883010483001553002208  601500001001POLLAERT CHRISTIANE                                                               1 0');
        TempFile.Write('3200020488RUE D LA BROUCHETERRE 11/6         6000  CHARLEROI                                                                 0 0');
        TempFile.Write('21000204893010483001553002208  0000000000023000041223601500001101000009663119                                      04122333701 0');
        TempFile.Write('2200020489                                                     NOTPROVIDED                        GKCCBEBB                   1 0');
        TempFile.Write('2300020489BE04063607539731                     Stalens Veronique                                                             0 1');
        TempFile.Write('31000204903010483001553002208  601500001001Stalens Veronique                                                                 1 0');
        TempFile.Write('3200020490AVENUE DES MUSICIENS 5/001         1348  LOUVAIN-LA-NEUVE                                                          0 0');
        TempFile.Write('21000204913010483001553002208  0000000000021070041223601500001101000009665341                                      04122333701 0');
        TempFile.Write('2200020491                                                     NOTPROVIDED                        GKCCBEBB                   1 0');
        TempFile.Write('2300020491BE53061787366053                     SOUGNEZ SYLVIA                                                                0 1');
        TempFile.Write('31000204923010483001553002208  601500001001SOUGNEZ SYLVIA                                                                    1 0');
        TempFile.Write('3200020492CHEMIN DE MESSE          1         4520  WANZE                                                                     0 0');
        TempFile.Write('21000204933010483001553002208  0000000000015400041223601500001101000009665745                                      04122333701 0');
        TempFile.Write('2200020493                                                     NOTPROVIDED                        BBRUBEBB                   1 0');
        TempFile.Write('2300020493BE19340064512112                     M FREDDY ABSIL                                                                0 1');
        TempFile.Write('31000204943010483001553002208  601500001001M FREDDY ABSIL                                                                    1 0');
        TempFile.Write('3200020494RUE DUFRENOY 9                     4570        MARCHIN                                                             0 0');
        TempFile.Write('21000204953010483001553002208  0000000000021070041223601500001101000009675142                                      04122333701 0');
        TempFile.Write('2200020495                                                     NOTPROVIDED                        AXABBE22                   1 0');
        TempFile.Write('2300020495BE93750679582667                     Tchung Im Soun - Motte dit Falisse                                            0 1');
        TempFile.Write('31000204963010483001553002208  601500001001Tchung Im Soun - Motte dit Falisse                                                1 0');
        TempFile.Write('3200020496Rue de Joie 67                     4000 LIEGE                                                                      0 0');
        TempFile.Write('21000204973010483001553002208  0000000000015400041223601500001101000009677162                                      04122333701 0');
        TempFile.Write('2200020497                                                     175461208                          GEBABEBB                   1 0');
        TempFile.Write('2300020497BE03001433522984                     OVERTUS PAULE                                                                 0 1');
        TempFile.Write('31000204983010483001553002208  601500001001OVERTUS PAULE                                                                     1 0');
        TempFile.Write('3200020498Rue du Moulin 23     0308          1340 OTTIGNIES-LOUVAIN-LA-NEUVE                                                 0 0');
        TempFile.Write('21000204993010483001553002208  0000000000021070041223601500001101000009684640                                      04122333701 0');
        TempFile.Write('2200020499                                                     NOTPROVIDED                        BBRUBEBB                   1 0');
        TempFile.Write('2300020499BE81363124391224                     M WILLY BODART                                                                0 1');
        TempFile.Write('31000205003010483001553002208  601500001001M WILLY BODART                                                                    1 0');
        TempFile.Write('3200020500RUE DES COMMERES 17 RCD            6536        THUILLIES                                                           0 0');
        TempFile.Write('21000205013010483001553002208  0000000000015400041223601500001101000009698582                                      04122333701 0');
        TempFile.Write('2200020501                                                     NOTPROVIDED                        BPOTBEB1                   1 0');
        TempFile.Write('2300020501BE92000177172823                     Mme YVETTE MOORS                                                              0 1');
        TempFile.Write('31000205023010483001553002208  601500001001Mme YVETTE MOORS                                                                  1 0');
        TempFile.Write('3200020502RUE DE LANTIN,71 /0001             4000 Liege                                                                      0 0');
        TempFile.Write('21000205033010483001553002208  0000000000015400041223601500001101000009699996                                      04122333701 0');
        TempFile.Write('2200020503                                                     NOTPROVIDED                        BBRUBEBB                   1 0');
        TempFile.Write('2300020503BE38310008059372                     MME ANDREE DENEF                                                              0 1');
        TempFile.Write('31000205043010483001553002208  601500001001MME ANDREE DENEF                                                                  1 0');
        TempFile.Write('3200020504SQ P HAUWAERTS 28 BTE 8            1140        EVERE                                                               0 0');
        TempFile.Write('21000205053010483001553002208  0000000000015400041223601500001101000009705050                                      04122333701 0');
        TempFile.Write('2200020505                                                     NOTPROVIDED                        BPOTBEB1                   1 0');
        TempFile.Write('2300020505BE87000177160594                     Mme Jeannine Bollen                                                           0 1');
        TempFile.Write('31000205063010483001553002208  601500001001Mme Jeannine Bollen                                                               1 0');
        TempFile.Write('3200020506RUE DU RONDAY, 10                  4460 GRACE-HOLLOGNE                                                             0 0');
        TempFile.Write('21000205073010483001553002208  0000000000017400041223601500001101000009711215                                      04122333701 0');
        TempFile.Write('2200020507                                                     NOTPROVIDED                        BPOTBEB1                   1 0');
        TempFile.Write('2300020507BE73000005399260                     Mme Agnes Carette                                                             0 1');
        TempFile.Write('31000205083010483001553002208  601500001001Mme Agnes Carette                                                                 1 0');
        TempFile.Write('3200020508Rue du Pont-de-Pierre,13           5500 Dinant                                                                     0 0');
        TempFile.Write('21000205093010483001553002208  0000000000015400041223601500001101000009722228                                      04122333701 0');
        TempFile.Write('2200020509                                                     NOTPROVIDED                        GEBABEBB                   1 0');
        TempFile.Write('2300020509BE98001169897293                     VAN DAMME GILBERTE                                                            0 1');
        TempFile.Write('31000205103010483001553002208  601500001001VAN DAMME GILBERTE                                                                1 0');
        TempFile.Write('3200020510Allee du Millenaire 8              1390     GREZ-DOICEAU                                                           0 0');
        TempFile.Write('21000205113010483001553002208  0000000000015400041223601500001101000009737988                                      04122333701 0');
        TempFile.Write('2200020511                                                     NOTPROVIDED                        AXABBE22                   1 0');
        TempFile.Write('2300020511BE06750627886822                     Descamps Roger                                                                0 1');
        TempFile.Write('31000205123010483001553002208  601500001001Descamps Roger                                                                    1 0');
        TempFile.Write('3200020512Clos des Orchidees 11              4432 ALLEUR                                                                     0 0');
        TempFile.Write('21000205133010483001553002208  0000000000015400041223601500001101000009754055                                      04122333701 0');
        TempFile.Write('2200020513                                                     NOTPROVIDED                        BBRUBEBB                   1 0');
        TempFile.Write('2300020513BE64360107412752                     M GEORGES LEFEBVRE                                                            0 1');
        TempFile.Write('31000205143010483001553002208  601500001001M GEORGES LEFEBVRE                                                                1 0');
        TempFile.Write('3200020514RUE DE LORNOIS 8                  1367        RAMILLIES-OFFU                                                       0 0');
        TempFile.Write('21000205153010483001553002208  0000000000023000041223601500001101000009762543                                      04122333701 0');
        TempFile.Write('2200020515                                                     NOTPROVIDED                        GEBABEBB                   1 0');
        TempFile.Write('2300020515BE65271074667396                     BAUDUIN FRANCINE                                                              0 1');
        TempFile.Write('31000205163010483001553002208  601500001001BAUDUIN FRANCINE                                                                  1 0');
        TempFile.Write('3200020516Rue GrandMere 9                   1421 BRAINE-LALLEUD                                                              0 0');
        TempFile.Write('21000205173010483001553002208  0000000000015400041223601500001101000009770526                                      04122333701 0');
        TempFile.Write('2200020517                                                     NOTPROVIDED                        BBRUBEBB                   1 0');
        TempFile.Write('2300020517BE48630022064327                     MR ERIC ROBERTS JONES                                                         0 1');
        TempFile.Write('31000205183010483001553002208  601500001001MR ERIC ROBERTS JONES                                                             1 0');
        TempFile.Write('3200020518AV J ET P CARSOEL 136              1180        UCCLE                                                               0 0');
        TempFile.Write('21000205193010483001553002208  0000000000025000041223601500001101000009777394                                      04122333701 0');
        TempFile.Write('2200020519                                                     NOTPROVIDED                        BBRUBEBB                   1 0');
        TempFile.Write('2300020519BE15360094024530                     MLLE MARYVONNE PIQUERY                                                        0 1');
        TempFile.Write('31000205203010483001553002208  601500001001MLLE MARYVONNE PIQUERY                                                            1 0');
        TempFile.Write('3200020520RUE MAJOIS(RES) 27                 7134        BINCHE                                                              0 0');
        TempFile.Write('21000205213010483001553002208  0000000000015400041223601500001101000009785276                                      04122333701 0');
        TempFile.Write('2200020521                                                     NOTPROVIDED                        BBRUBEBB                   1 0');
        TempFile.Write('2300020521BE84377070773459                     MME GUDELIE SCHATAN                                                           0 1');
        TempFile.Write('31000205223010483001553002208  601500001001MME GUDELIE SCHATAN                                                               1 0');
        TempFile.Write('3200020522AV. ALPHONSE XIII 67               1180        UCCLE                                                               0 0');
        TempFile.Write('21000205233010483001553002208  0000000000023000041223601500001101000009800636                                      04122333701 0');
        TempFile.Write('2200020523                                                     0000000021/                        BBRUBEBB                   1 0');
        TempFile.Write('2300020523BE48630181580827                     MLLE CAMILLE DEMOULIN                                                         0 1');
        TempFile.Write('31000205243010483001553002208  601500001001MLLE CAMILLE DEMOULIN                                                             1 0');
        TempFile.Write('3200020524RUE DU FORBOT 14                   5520        ONHAYE                                                              0 0');
        TempFile.Write('21000205253010483001553002208  0000000000015400041223601500001101000009807003                                      04122333701 0');
        TempFile.Write('2200020525                                                     NOTPROVIDED                        DEUTBEBE                   1 0');
        TempFile.Write('2300020525BE47611932171080                     M. Samuel Jean                                                                0 1');
        TempFile.Write('31000205263010483001553002208  601500001001M. Samuel Jean                                                                    1 0');
        TempFile.Write('3200020526RUE AMERICAINE 186 B11             1050 IXELLES                                                                    0 0');
        TempFile.Write('21000205273010483001553002208  0000000000015400041223601500001101000009810336                                      04122333701 0');
        TempFile.Write('2200020527                                                     NOTPROVIDED                        BBRUBEBB                   1 0');
        TempFile.Write('2300020527BE95340010827258                     M JACQUES REUTER                                                              0 1');
        TempFile.Write('31000205283010483001553002208  601500001001M JACQUES REUTER                                                                  1 0');
        TempFile.Write('3200020528CHEMIN DES CRETES 8                4130        ESNEUX                                                              0 0');
        TempFile.Write('21000205293010483001553002208  0000000000046000041223601500001101000009811346                                      04122333701 0');
        TempFile.Write('2200020529                                                     NOTPROVIDED                        GKCCBEBB                   1 0');
        TempFile.Write('2300020529BE09063505168557                     BUIDIN MICHELINE                                                              0 1');
        TempFile.Write('31000205303010483001553002208  601500001001BUIDIN MICHELINE                                                                  1 0');
        TempFile.Write('3200020530DIGUE DES PEUPLIERS   55 B         7000  MONS                                                                      0 0');
        TempFile.Write('21000205313010483001553002208  0000000000017400041223601500001101000009819127                                      04122333701 0');
        TempFile.Write('2200020531                                                     NOTPROVIDED                        GKCCBEBB                   1 0');
        TempFile.Write('2300020531BE65063554516396                     Quertinmont Serge                                                             0 1');
        TempFile.Write('31000205323010483001553002208  601500001001Quertinmont Serge                                                                 1 0');
        TempFile.Write('3200020532RUE SAINT-SANG        83/1         7141  CARNIERES                                                                 0 0');
        TempFile.Write('21000205333010483001553002208  0000000000015400041223601500001101000009822056                                      04122333701 0');
        TempFile.Write('2200020533                                                     NOTPROVIDED                        GEBABEBB                   1 0');
        TempFile.Write('2300020533BE49001299875071                     DEPREZ MARGUERITE                                                             0 1');
        TempFile.Write('31000205343010483001553002208  601500001001DEPREZ MARGUERITE                                                                 1 0');
        TempFile.Write('3200020534Allee Chambourees 11               1400     NIVELLES                                                               0 0');
        TempFile.Write('21000205353010483001553002208  0000000000015400041223601500001101000009825894                                      04122333701 0');
        TempFile.Write('2200020535                                                     NOTPROVIDED                        GEBABEBB                   1 0');
        TempFile.Write('2300020535BE96142065531205                     FRANCHI-PIGNATELLI                                                            0 1');
        TempFile.Write('31000205363010483001553002208  601500001001FRANCHI-PIGNATELLI                                                                1 0');
        TempFile.Write('3200020536QUAI DE ROME 47 0071               4000     LIEGE                                                                  0 0');
        TempFile.Write('21000205373010483001553002208  0000000000015400041223601500001101000009838022                                      04122333701 0');
        TempFile.Write('2200020537                                                     NOTPROVIDED                        BBRUBEBB                   1 0');
        TempFile.Write('2300020537BE60310018195670                     M CHARLES WERBROUCK                                                           0 1');
        TempFile.Write('31000205383010483001553002208  601500001001M CHARLES WERBROUCK                                                               1 0');
        TempFile.Write('3200020538AV DE L ETE 13                     1410        WATERLOO                                                            0 0');
        TempFile.Write('21000205393010483001553002208  0000000000021070041223601500001101000009839133                                      04122333701 0');
        TempFile.Write('2200020539                                                     NOTPROVIDED                        BBRUBEBB                   1 0');
        TempFile.Write('2300020539BE79310023041933                     MME ELISABETH JANSSENS                                                        0 1');
        TempFile.Write('31000205403010483001553002208  601500001001MME ELISABETH JANSSENS                                                            1 0');
        TempFile.Write('3200020540AV DE BROQUEVILLE 287/6            1200        WOLUWE-ST-LAMB                                                      0 0');
        TempFile.Write('21000205413010483001553002208  0000000000015400041223601500001101000009840244                                      04122333701 0');
        TempFile.Write('2200020541                                                     NOTPROVIDED                        BPOTBEB1                   1 0');
        TempFile.Write('2300020541BE19000020099612                     BILLE-SCHONE                                                                  0 1');
        TempFile.Write('31000205423010483001553002208  601500001001BILLE-SCHONE                                                                      1 0');
        TempFile.Write('3200020542RUE EMILE HENRICOT, 29/31          1490 COURT-SAINT-ETIENNE                                                        0 0');
        TempFile.Write('21000205433010483001553002208  0000000000015400041223601500001101000009840749                                      04122333701 0');
        TempFile.Write('2200020543                                                     NOTPROVIDED                        NICABEBB                   1 0');
        TempFile.Write('2300020543BE84103016964459                     Mme Ginette Godfroid                                                          0 1');
        TempFile.Write('31000205443010483001553002208  601500001001Mme Ginette Godfroid                                                              1 0');
        TempFile.Write('3200020544Rue de lEnseignement, 9 / 0006       5190 Jemeppe-sur-Sambre                                                       0 0');
        TempFile.Write('21000205453010483001553002208  0000000000021070041223601500001101000009853681                                      04122333701 0');
        TempFile.Write('2200020545                                                     175786185                          GEBABEBB                   1 0');
        TempFile.Write('2300020545BE54001014358197                     LIBERT ANDREE                                                                 0 1');
        TempFile.Write('31000205463010483001553002208  601500001001LIBERT ANDREE                                                                     1 0');
        TempFile.Write('3200020546AVENUE CLAETERBOSCH 16     0001    1070 ANDERLECHT                                                                 0 0');
        TempFile.Write('21000205473010483001553002208  0000000000015400041223601500001101000009854691                                      04122333701 0');
        TempFile.Write('2200020547                                                     NOTPROVIDED                        BBRUBEBB                   1 0');
        TempFile.Write('2300020547BE18340013786465                     M HENRI SALAVARDA                                                             0 1');
        TempFile.Write('31000205483010483001553002208  601500001001M HENRI SALAVARDA                                                                 1 0');
        TempFile.Write('3200020548RUE DU ROI ALBERT 343              4680        OUPEYE                                                              0 0');
        TempFile.Write('21000205493010483001553002208  0000000000015400041223601500001101000009855095                                      04122333701 0');
        TempFile.Write('2200020549                                                     NOTPROVIDED                        BBRUBEBB                   1 0');
        TempFile.Write('2300020549BE07340013088166                     MME IRENE CARRE                                                               0 1');
        TempFile.Write('31000205503010483001553002208  601500001001MME IRENE CARRE                                                                   1 0');
        TempFile.Write('3200020550RUE DU MERY 18 7                   4000        LIEGE                                                               0 0');
        TempFile.Write('21000205513010483001553002208  0000000000015400041223601500001101000009882983                                      04122333701 0');
        TempFile.Write('2200020551                                                     NOTPROVIDED                        NICABEBB                   1 0');
        TempFile.Write('2300020551BE27103109426273                     Mme Marthe Decueper                                                           0 1');
        TempFile.Write('31000205523010483001553002208  601500001001Mme Marthe Decueper                                                               1 0');
        TempFile.Write('3200020552Rue Gerard,11                      1450 Chastre                                                                    0 0');
        TempFile.Write('21000205533010483001553002208  0000000000025000041223601500001101000009889956                                      04122333701 0');
        TempFile.Write('2200020553                                                     NOTPROVIDED                        BPOTBEB1                   1 0');
        TempFile.Write('2300020553BE10000063845804                     Mme DENISE PECKERS                                                            0 1');
        TempFile.Write('31000205543010483001553002208  601500001001Mme DENISE PECKERS                                                                1 0');
        TempFile.Write('3200020554RUE DES SOPREYES,41                4051 Chaudfontaine                                                              0 0');
        TempFile.Write('21000205553010483001553002208  0000000000015400041223601500001101000009893996                                      04122333701 0');
        TempFile.Write('2200020555                                                     NOTPROVIDED                        GEBABEBB                   1 0');
        TempFile.Write('2300020555BE65210024002296                     LEPOUTRE JACQUELINE                                                           0 1');
        TempFile.Write('31000205563010483001553002208  601500001001LEPOUTRE JACQUELINE                                                               1 0');
        TempFile.Write('3200020556Av.E.V.Becelaere 26 8              1170     WATERMAEL-BOITSFORT                                                    0 0');
        TempFile.Write('21000205573010483001553002208  0000000000015400041223601500001101000009899454                                      04122333701 0');
        TempFile.Write('2200020557                                                     176690822                          GEBABEBB                   1 0');
        TempFile.Write('2300020557BE67001294056687                     AGOSTINELLI GIANANGELA                                                        0 1');
        TempFile.Write('31000205583010483001553002208  601500001001AGOSTINELLI GIANANGELA                                                            1 0');
        TempFile.Write('3200020558Rue dHoudeng 66                   7070 LE ROEULX                                                                   0 0');
        TempFile.Write('21000205593010483001553002208  0000000000023000041223601500001101000009911780                                      04122333701 0');
        TempFile.Write('2200020559                                                     NOTPROVIDED                        BBRUBEBB                   1 0');
        TempFile.Write('2300020559BE35363207570037                     MADAME NADINE HOTTON                                                          0 1');
        TempFile.Write('31000205603010483001553002208  601500001001MADAME NADINE HOTTON                                                              1 0');
        TempFile.Write('3200020560RUE DE LABBAYE 11 BTE 1           7800        ATH                                                                  0 0');
        TempFile.Write('21000205613010483001553002208  0000000000015400041223601500001101000009919561                                      04122333701 0');
        TempFile.Write('2200020561                                                     NOTPROVIDED                        GKCCBEBB                   1 0');
        TempFile.Write('2300020561BE77061878186042                     BOURGEOIS - PIRSON                                                            0 1');
        TempFile.Write('31000205623010483001553002208  601500001001BOURGEOIS - PIRSON                                                                1 0');
        TempFile.Write('3200020562RUE DES PRIESSES        75         4400  FLEMALLE                                                                  0 0');
        TempFile.Write('21000205633010483001553002208  0000000000015400041223601500001101000009939567                                      04122333701 0');
        TempFile.Write('2200020563                                                     NOTPROVIDED                        BBRUBEBB                   1 0');
        TempFile.Write('2300020563BE17377064978721                     M JEAN JACQUES GUILLEMANT                                                     0 1');
        TempFile.Write('31000205643010483001553002208  601500001001M JEAN JACQUES GUILLEMANT                                                         1 0');
        TempFile.Write('3200020564RUE A. LAMBERT 35                  7012        FLENU                                                               0 0');
        TempFile.Write('21000205653010483001553002208  0000000000015400041223601500001101000009943409                                      04122333701 0');
        TempFile.Write('2200020565                                                     NOTPROVIDED                        BPOTBEB1                   1 0');
        TempFile.Write('2300020565BE48000451789927                     Mme Zenona Zagraj                                                             0 1');
        TempFile.Write('31000205663010483001553002208  601500001001Mme Zenona Zagraj                                                                 1 0');
        TempFile.Write('3200020566Rue Haute Rochette,126             4400 Flemalle                                                                   0 0');
        TempFile.Write('21000205673010483001553002208  0000000000017000041223601500001101000009947146                                      04122333701 0');
        TempFile.Write('2200020567                                                     NOT PROVIDED                       GEBABEBB                   1 0');
        TempFile.Write('2300020567BE81001111379924                     DELMOTTE MARIE                                                                0 1');
        TempFile.Write('31000205683010483001553002208  601500001001DELMOTTE MARIE                                                                    1 0');
        TempFile.Write('3200020568Jaak Ballingsstr. 18               1140     EVERE                                                                  0 0');
        TempFile.Write('21000205693010483001553002208  0000000000015400041223601500001101000009958260                                      04122333701 0');
        TempFile.Write('2200020569                                                     NOTPROVIDED                        GEBABEBB                   1 0');
        TempFile.Write('2300020569BE59001299889926                     LA MENDOLA PIETRA                                                             0 1');
        TempFile.Write('31000205703010483001553002208  601500001001LA MENDOLA PIETRA                                                                 1 0');
        TempFile.Write('3200020570Rue Vinave 50                      4420     SAINT-NICOLAS                                                          0 0');
        TempFile.Write('21000205713010483001553002208  0000000000021070041223601500001101000009993525                                      04122333701 0');
        TempFile.Write('2200020571                                                     NOTPROVIDED                        GEBABEBB                   1 0');
        TempFile.Write('2300020571BE04001074132631                     WALELIGN TSIGUEREDA                                                           0 1');
        TempFile.Write('31000205723010483001553002208  601500001001WALELIGN TSIGUEREDA                                                               1 0');
        TempFile.Write('3200020572RUE DE THEUX 67     M000           1050 IXELLES                                                                    0 0');
        TempFile.Write('21000205733010483001553002208  0000000000015400041223601500001101000009997868                                      04122333701 0');
        TempFile.Write('2200020573                                                     NOTPROVIDED                        BBRUBEBB                   1 0');
        TempFile.Write('2300020573BE10363215113304                     MME STEPHANIE TAMBOUR                                                         0 1');
        TempFile.Write('31000205743010483001553002208  601500001001MME STEPHANIE TAMBOUR                                                             1 0');
        TempFile.Write('3200020574RUE DES ENFANTS(LEV) 6             7134        EPINOIS                                                             0 0');
        TempFile.Write('21000205753010483001553002208  0000000000017400041223601500001101000030008665                                      04122333701 0');
        TempFile.Write('2200020575                                                     NOTPROVIDED                        BBRUBEBB                   1 0');
        TempFile.Write('2300020575BE47363229205380                     AVAERT GERY - GESTION                                                         0 1');
        TempFile.Write('31000205763010483001553002208  601500001001AVAERT GERY - GESTION                                                             1 0');
        TempFile.Write('3200020576RUE NEUVE 33                       7060        SOIGNIES                                                            0 0');
        TempFile.Write('21000205773010483001553002208  0000000000023000041223601500001101000030016547                                      04122333701 0');
        TempFile.Write('2200020577                                                     NOTPROVIDED                        GKCCBEBB                   1 0');
        TempFile.Write('2300020577BE10063691762104                     PIETTE OLIVIER                                                                0 1');
        TempFile.Write('31000205783010483001553002208  601500001001PIETTE OLIVIER                                                                    1 0');
        TempFile.Write('3200020578HESTROY               31/C         5330  ASSESSE                                                                   0 0');
        TempFile.Write('21000205793010483001553002208  0000000000023000041223601500001101000030019476                                      04122333701 0');
        TempFile.Write('2200020579                                                     NOTPROVIDED                        AXABBE22                   1 0');
        TempFile.Write('2300020579BE97750909829749                     Devadder Marcel                                                               0 1');
        TempFile.Write('31000205803010483001553002208  601500001001Devadder Marcel                                                                   1 0');
        TempFile.Write('3200020580Avenue Bel-Air 110 B 12            1180 UCCLE                                                                      0 0');
        TempFile.Write('21000205813010483001553002208  0000000000015400041223601500001101000030026247                                      04122333701 0');
        TempFile.Write('2200020581                                                     NOTPROVIDED                        AXABBE22                   1 0');
        TempFile.Write('2300020581BE91750695510976                     Cuvelier Marie-Jeanne - Verhelst Ma                                           0 1');
        TempFile.Write('31000205823010483001553002208  601500001001Cuvelier Marie-Jeanne - Verhelst Ma                                               1 0');
        TempFile.Write('3200020582Rue Sainte-Helene 21               6724 RULLES                                                                     0 0');
        TempFile.Write('21000205833010483001553002208  0000000000015400041223601500001101000030035341                                      04122333701 0');
        TempFile.Write('2200020583                                                     NOTPROVIDED                        BBRUBEBB                   1 0');
        TempFile.Write('2300020583BE23360023550491                     MME CHRISTINE DUPERROY                                                        0 1');
        TempFile.Write('31000205843010483001553002208  601500001001MME CHRISTINE DUPERROY                                                            1 0');
        TempFile.Write('3200020584AV V EMMANUEL III 12/5             1180        UCCLE                                                               0 0');
        TempFile.Write('21000205853010483001553002208  0000000000515400041223601500001101000030038472                                      04122333701 0');
        TempFile.Write('2200020585                                                     NOTPROVIDED                        GKCCBEBB                   1 0');
        TempFile.Write('2300020585BE41063106658710                     ALLAERTS LYDIE                                                                0 1');
        TempFile.Write('31000205863010483001553002208  601500001001ALLAERTS LYDIE                                                                    1 0');
        TempFile.Write('3200020586RUE FAYS                79         4400  FLEMALLE                                                                  0 0');
        TempFile.Write('21000205873010483001553002208  0000000000023000041223601500001101000030040492                                      04122333701 0');
        TempFile.Write('2200020587                                                     NOTPROVIDED                        BPOTBEB1                   1 0');
        TempFile.Write('2300020587BE18000455111165                     Mme CHRISTIANE CHASPIERRE                                                     0 1');
        TempFile.Write('31000205883010483001553002208  601500001001Mme CHRISTIANE CHASPIERRE                                                         1 0');
        TempFile.Write('3200020588Tienne du Sarment,8                1300 Wavre                                                                      0 0');
        TempFile.Write('21000205893010483001553002208  0000000000017400041223601500001101000030043728                                      04122333701 0');
        TempFile.Write('2200020589                                                     NOTPROVIDED                        BPOTBEB1                   1 0');
        TempFile.Write('2300020589BE05000077132275                     M. ARTHUR VANDERWEYEN                                                         0 1');
        TempFile.Write('31000205903010483001553002208  601500001001M. ARTHUR VANDERWEYEN                                                             1 0');
        TempFile.Write('3200020590Avenue Cardinal Micara,9           1160 AUDERGHEM                                                                  0 0');
        TempFile.Write('21000205913010483001553002208  0000000000017400041223601500001101000030050495                                      04122333701 0');
        TempFile.Write('2200020591                                                     NOTPROVIDED                        BPOTBEB1                   1 0');
        TempFile.Write('2300020591BE18000107957865                     Mme JOSETTE ISTACE                                                            0 1');
        TempFile.Write('31000205923010483001553002208  601500001001Mme JOSETTE ISTACE                                                                1 0');
        TempFile.Write('3200020592Rue de France, Hermeton,39         5540 HASTIERE                                                                   0 0');
        TempFile.Write('21000205933010483001553002208  0000000000015400041223601500001101000030053630                                      04122333701 0');
        TempFile.Write('2200020593                                                     NOTPROVIDED                        BPOTBEB1                   1 0');
        TempFile.Write('2300020593BE46000076216536                     Mme GILBERTE WALLEMACQ                                                        0 1');
        TempFile.Write('31000205943010483001553002208  601500001001Mme GILBERTE WALLEMACQ                                                            1 0');
        TempFile.Write('3200020594Rue des Canonniers 3,0 /52         7000 Mons                                                                       0 0');
        TempFile.Write('21000205953010483001553002208  0000000000015400041223601500001101000030060296                                      04122333701 0');
        TempFile.Write('2200020595                                                     NOTPROVIDED                        GKCCBEBB                   1 0');
        TempFile.Write('2300020595BE02063119611240                     TOURNEUR - KEMPENEERS                                                         0 1');
        TempFile.Write('31000205963010483001553002208  601500001001TOURNEUR - KEMPENEERS                                                             1 0');
        TempFile.Write('3200020596AVENUE PAUL BRIEN     29/A         4280  HANNUT                                                                    0 0');
        TempFile.Write('21000205973010483001553002208  0000000000023000041223601500001101000030081518                                      04122333701 0');
        TempFile.Write('2200020597                                                     NOTPROVIDED                        NICABEBB                   1 0');
        TempFile.Write('2300020597BE05850814332475                     Mme Marie Dethier                                                             0 1');
        TempFile.Write('31000205983010483001553002208  601500001001Mme Marie Dethier                                                                 1 0');
        TempFile.Write('3200020598Rue de Carnelle,135                6200 Chatelet                                                                   0 0');
        TempFile.Write('21000205993010483001553002208  0000000000025000041223601500001101000030087073                                      04122333701 0');
        TempFile.Write('2200020599                                                     NOTPROVIDED                        GKCCBEBB                   1 0');
        TempFile.Write('2300020599BE86776597360150                     SOUBRY MARINA                                                                 0 1');
        TempFile.Write('31000206003010483001553002208  601500001001SOUBRY MARINA                                                                     1 0');
        TempFile.Write('3200020600AU CHESSION           1/22         4053  EMBOURG                                                                   0 0');
        TempFile.Write('21000206013010483001553002208  0000000000015400041223601500001101000030093743                                      04122333701 0');
        TempFile.Write('2200020601                                                     NOTPROVIDED                        GKCCBEBB                   1 0');
        TempFile.Write('2300020601BE90063099812732                     Herzfeld Marguerite                                                           0 1');
        TempFile.Write('31000206023010483001553002208  601500001001Herzfeld Marguerite                                                               1 0');
        TempFile.Write('3200020602AVENUE DE MESSIDOR   300/4         1180  UCCLE                                                                     0 0');
        TempFile.Write('21000206033010483001553002208  0000000000015400041223601500001101000030094450                                      04122333701 0');
        TempFile.Write('2200020603                                                     176569778                          GEBABEBB                   1 0');
        TempFile.Write('2300020603BE06271070130022                     SCAVEE BERNARD                                                                0 1');
        TempFile.Write('31000206043010483001553002208  601500001001SCAVEE BERNARD                                                                    1 0');
        TempFile.Write('3200020604Avenue Marie-Louise 30             1410 WATERLOO                                                                   0 0');
        TempFile.Write('21000206053010483001553002208  0000000000023000041223601500001101000030096066                                      04122333701 0');
        TempFile.Write('2200020605                                                     NOTPROVIDED                        GEBABEBB                   1 0');
        TempFile.Write('2300020605BE58001765776579                     MORVANT-PALMER                                                                0 1');
        TempFile.Write('31000206063010483001553002208  601500001001MORVANT-PALMER                                                                    1 0');
        TempFile.Write('3200020606Rue Nysten 30 0012                 4000     LIEGE                                                                  0 0');
        TempFile.Write('21000206073010483001553002208  0000000000025000041223601500001101000030100312                                      04122333701 0');
        TempFile.Write('2200020607                                                     NOTPROVIDED                        BPOTBEB1                   1 0');
        TempFile.Write('2300020607BE57000007268835                     M. GILLES GUINOTTE                                                            0 1');
        TempFile.Write('31000206083010483001553002208  601500001001M. GILLES GUINOTTE                                                                1 0');
        TempFile.Write('3200020608RUE HAUT VINAVE, 71                4682 OUPEYE                                                                     0 0');
        TempFile.Write('21000206093010483001553002208  0000000000021070041223601500001101000030101423                                      04122333701 0');
        TempFile.Write('2200020609                                                     NOTPROVIDED                        GEBABEBB                   1 0');
        TempFile.Write('2300020609BE11210032339448                     HELDENBERGH PIERRE                                                            0 1');
        TempFile.Write('31000206103010483001553002208  601500001001HELDENBERGH PIERRE                                                                1 0');
        TempFile.Write('3200020610r.Colonel Bourg 108 B023           1030     SCHAERBEEK                                                             0 0');
        TempFile.Write('21000206113010483001553002208  0000000000021070041223601500001101000030109204                                      04122333701 0');
        TempFile.Write('2200020611                                                     NOTPROVIDED                        GKCCBEBB                   1 0');
        TempFile.Write('2300020611BE40063635925163                     PEETERS FLORENTINE                                                            0 1');
        TempFile.Write('31000206123010483001553002208  601500001001PEETERS FLORENTINE                                                                1 0');
        TempFile.Write('3200020612RUE EDOUARD BRANLY    23/9         1190  BRUXELLES                                                                 0 0');
        TempFile.Write('21000206133010483001553002208  0000000000015400041223601500001101000030115870                                      04122333701 0');
        TempFile.Write('2200020613                                                     NOTPROVIDED                        GKCCBEBB                   1 0');
        TempFile.Write('2300020613BE27062562010073                     LIPPUS NELLY                                                                  0 1');
        TempFile.Write('31000206143010483001553002208  601500001001LIPPUS NELLY                                                                      1 0');
        TempFile.Write('3200020614RUE LOUIS SOCQUET     56/3         1030  SCHAERBEEK                                                                0 0');
        TempFile.Write('21000206153010483001553002208  0000000000015400041223601500001101000030126782                                      04122333701 0');
        TempFile.Write('2200020615                                                     NOTPROVIDED                        GKCCBEBB                   1 0');
        TempFile.Write('2300020615BE74063943264007                     Tassier - TAETER                                                              0 1');
        TempFile.Write('31000206163010483001553002208  601500001001Tassier - TAETER                                                                  1 0');
        TempFile.Write('3200020616PLACE DES PRIMEVERES     2         1348  LOUVAIN-LA-NEUVE                                                          0 0');
        TempFile.Write('21000206173010483001553002208  0000000000015400041223601500001101000030140526                                      04122333701 0');
        TempFile.Write('2200020617                                                     0000000001/NOVEMBRE 2023           BBRUBEBB                   1 0');
        TempFile.Write('2300020617BE32363233465502                     DANNEELS DOMINIQUE - Poche                                                    0 1');
        TempFile.Write('31000206183010483001553002208  601500001001DANNEELS DOMINIQUE - Poche                                                        1 0');
        TempFile.Write('3200020618CH DE GRAMPTINNE 72                5340        GESVES                                                              0 0');
        TempFile.Write('21000206193010483001553002208  0000000000017400041223601500001101000030145374                                      04122333701 0');
        TempFile.Write('2200020619                                                     NOTPROVIDED                        BBRUBEBB                   1 0');
        TempFile.Write('2300020619BE59310114812926                     MLLE DANIELE VINCENT                                                          0 1');
        TempFile.Write('31000206203010483001553002208  601500001001MLLE DANIELE VINCENT                                                              1 0');
        TempFile.Write('3200020620RUE DES FLORALIES 87 BT 92         1200        WOLUWE-ST-LAMB                                                      0 0');
        TempFile.Write('21000206213010483001553002208  0000000000015400041223601500001101000030148610                                      04122333701 0');
        TempFile.Write('2200020621                                                     NOTPROVIDED                        KREDBEBB                   1 0');
        TempFile.Write('2300020621BE21736031887503                     HEURTER-BARBERO P + G                                                         0 1');
        TempFile.Write('31000206223010483001553002208  601500001001HEURTER-BARBERO P + G                                                             1 0');
        TempFile.Write('3200020622AVENUE CIRCULAIRE    144A B14      1180    UCCLE                                                                   0 0');
        TempFile.Write('21000206233010483001553002208  0000000000015400041223601500001101000030148812                                      04122333701 0');
        TempFile.Write('2200020623                                                     NOTPROVIDED                        NICABEBB                   1 0');
        TempFile.Write('2300020623BE62103111006161                     Mme Agnes Tits                                                                0 1');
        TempFile.Write('31000206243010483001553002208  601500001001Mme Agnes Tits                                                                    1 0');
        TempFile.Write('3200020624Chaussee de Namur,24               1367 Ramillies                                                                  0 0');
        TempFile.Write('21000206253010483001553002208  0000000000015400041223601500001101000030155478                                      04122333701 0');
        TempFile.Write('2200020625                                                     NOTPROVIDED                        GKCCBEBB                   1 0');
        TempFile.Write('2300020625BE82063680070368                     Vermaut Anne                                                                  0 1');
        TempFile.Write('31000206263010483001553002208  601500001001Vermaut Anne                                                                      1 0');
        TempFile.Write('3200020626RUE JEAN-S. BACH         9         1420  BRAINE-LALLEUD                                                            0 0');
        TempFile.Write('21000206273010483001553002208  0000000000023000041223601500001101000030160532                                      04122333701 0');
        TempFile.Write('2200020627                                                     NOTPROVIDED                        BBRUBEBB                   1 0');
        TempFile.Write('2300020627BE46363179469036                     MME MYRIAM ZALUDKOWSKI                                                        0 1');
        TempFile.Write('31000206283010483001553002208  601500001001MME MYRIAM ZALUDKOWSKI                                                            1 0');
        TempFile.Write('3200020628AV J ET P CARSOEL 89/65            1180        UCCLE                                                               0 0');
        TempFile.Write('21000206293010483001553002208  0000000000023000041223601500001101000030162451                                      04122333701 0');
        TempFile.Write('2200020629                                                     NOTPROVIDED                        BPOTBEB1                   1 0');
        TempFile.Write('2300020629BE70000065322325                     M. JACQUES LAURENT                                                            0 1');
        TempFile.Write('31000206303010483001553002208  601500001001M. JACQUES LAURENT                                                                1 0');
        TempFile.Write('3200020630Chemin d Hestroy(LU),15           5170 Profondeville                                                               0 0');
        TempFile.Write('21000206313010483001553002208  0000000000017400041223601500001101000030163057                                      04122333701 0');
        TempFile.Write('2200020631                                                     NOTPROVIDED                        BPOTBEB1                   1 0');
        TempFile.Write('2300020631BE02000308415540                     Mme MARIA VAN TICHELT                                                         0 1');
        TempFile.Write('31000206323010483001553002208  601500001001Mme MARIA VAN TICHELT                                                             1 0');
        TempFile.Write('3200020632SAINT MORT, 199                    5300 ANDENNE                                                                    0 0');
        TempFile.Write('21000206333010483001553002208  0000000000025000041223601500001101000030166188                                      04122333701 0');
        TempFile.Write('2200020633                                                     NOTPROVIDED                        BPOTBEB1                   1 0');
        TempFile.Write('2300020633BE94000435143414                     M. Jean-Pierre Goossens                                                       0 1');
        TempFile.Write('31000206343010483001553002208  601500001001M. Jean-Pierre Goossens                                                           1 0');
        TempFile.Write('3200020634Rue des Chateaux dEau 52, 01       6061 Charleroi                                                                  0 0');
        TempFile.Write('21000206353010483001553002208  0000000000017400041223601500001101000030186093                                      04122333701 0');
        TempFile.Write('2200020635                                                     NOTPROVIDED                        GKCCBEBB                   1 0');
        TempFile.Write('2300020635BE35063095525837                     DAL CHRISTIANE                                                                0 1');
        TempFile.Write('31000206363010483001553002208  601500001001DAL CHRISTIANE                                                                    1 0');
        TempFile.Write('3200020636RUE DU MOULIN           70         7090  BRAINE-LE-COMTE                                                           0 0');
        TempFile.Write('21000206373010483001553002208  0000000000029000041223601500001101000030189531                                      04122333701 0');
        TempFile.Write('2200020637                                                     NOTPROVIDED                        AXABBE22                   1 0');
        TempFile.Write('2300020637BE09750706615557                     Laurent Andree                                                                0 1');
        TempFile.Write('31000206383010483001553002208  601500001001Laurent Andree                                                                    1 0');
        TempFile.Write('3200020638Bd du Souverain 139                1160 AUDERGHEM                                                                  0 0');
        TempFile.Write('21000206393010483001553002208  0000000000021070041223601500001101000030192864                                      04122333701 0');
        TempFile.Write('2200020639                                                     NOTPROVIDED                        BBRUBEBB                   1 0');
        TempFile.Write('2300020639BE14310061264983                     MME MURIEL PARMENTIER                                                         0 1');
        TempFile.Write('31000206403010483001553002208  601500001001MME MURIEL PARMENTIER                                                             1 0');
        TempFile.Write('3200020640AVE CHAZAL 97                      1030        SCHAARBEEK                                                          0 0');
        TempFile.Write('21000206413010483001553002208  0000000000015400041223601500001101000030197817                                      04122333701 0');
        TempFile.Write('2200020641                                                     NOTPROVIDED                        GEBABEBB                   1 0');
        TempFile.Write('2300020641BE83271051903015                     YERNAUX-WARNIER                                                               0 1');
        TempFile.Write('31000206423010483001553002208  601500001001YERNAUX-WARNIER                                                                   1 0');
        TempFile.Write('3200020642Rue des Ateliers 30     303        1332 RIXENSART                                                                  0 0');
        TempFile.Write('21000206433010483001553002208  0000000000015400041223601500001101000030204079                                      04122333701 0');
        TempFile.Write('2200020643                                                     NOTPROVIDED                        GEBABEBB                   1 0');
        TempFile.Write('2300020643BE35271022019537                     PRINGALLE-FOSSET                                                              0 1');
        TempFile.Write('31000206443010483001553002208  601500001001PRINGALLE-FOSSET                                                                  1 0');
        TempFile.Write('3200020644AVENUE DE LA HOULETTE 2            1410     WATERLOO                                                               0 0');
        TempFile.Write('21000206453010483001553002208  0000000000015400041223601500001101000030209234                                      04122333701 0');
        TempFile.Write('2200020645                                                     NOTPROVIDED                        GEBABEBB                   1 0');
        TempFile.Write('2300020645BE73001023171760                     STEPMAN PIERRE                                                                0 1');
        TempFile.Write('31000206463010483001553002208  601500001001STEPMAN PIERRE                                                                    1 0');
        TempFile.Write('3200020646RUE DE BRUGES 1                    1080 MOLENBEEK-SAINT-JEAN                                                       0 0');
        TempFile.Write('21000206473010483001553002208  0000000000015400041223601500001101000030214688                                      04122333701 0');
        TempFile.Write('2200020647                                                     NOTPROVIDED                        BBRUBEBB                   1 0');
        TempFile.Write('2300020647BE95652837214358                     MME MARIETTE BILLEN                                                           0 1');
        TempFile.Write('31000206483010483001553002208  601500001001MME MARIETTE BILLEN                                                               1 0');
        TempFile.Write('3200020648RUE VIGNOBLE 16                    4130        ESNEUX                                                              0 0');
        TempFile.Write('21000206493010483001553002208  0000000000029000041223601500001101000030216611                                      04122333701 0');
        TempFile.Write('2200020649                                                     NOTPROVIDED                        GKCCBEBB                   1 0');
        TempFile.Write('2300020649BE37063009340428                     GISSELEIRE JEAN                                                               0 1');
        TempFile.Write('31000206503010483001553002208  601500001001GISSELEIRE JEAN                                                                   1 0');
        TempFile.Write('3200020650RUE MEYERBEER           19         1190  BRUXELLES                                                                 0 0');
        TempFile.Write('21000206513010483001553002208  0000000000017000041223601500001101000030226513                                      04122333701 0');
        TempFile.Write('2200020651                                                     NOTPROVIDED                        BPOTBEB1                   1 0');
        TempFile.Write('2300020651BE94000435143414                     M. Jean-Pierre Goossens                                                       0 1');
        TempFile.Write('31000206523010483001553002208  601500001001M. Jean-Pierre Goossens                                                           1 0');
        TempFile.Write('3200020652Rue des Chateaux dEau 52, 01       6061 Charleroi                                                                  0 0');
        TempFile.Write('21000206533010483001553002208  0000000000015400041223601500001101000030226614                                      04122333701 0');
        TempFile.Write('2200020653                                                     NOTPROVIDED                        BPOTBEB1                   1 0');
        TempFile.Write('2300020653BE62000154352561                     M. LUC VANDEN BULCKE                                                          0 1');
        TempFile.Write('31000206543010483001553002208  601500001001M. LUC VANDEN BULCKE                                                              1 0');
        TempFile.Write('3200020654RUE DHEUVAL, 52                   1490 COURT-SAINT-ETIENNE                                                         0 0');
        TempFile.Write('21000206553010483001553002208  0000000000015400041223601500001101000030235001                                      04122333701 0');
        TempFile.Write('2200020655                                                     NOTPROVIDED                        DEUTBEBE                   1 0');
        TempFile.Write('2300020655BE62611590409061                     M+Mme De Loos - De Bruyn                                                      0 1');
        TempFile.Write('31000206563010483001553002208  601500001001M+Mme De Loos - De Bruyn                                                          1 0');
        TempFile.Write('3200020656RUE DE NIL 3                       1435 MONT-SAINT-GUIBERT                                                         0 0');
        TempFile.Write('21000206573010483001553002208  0000000000015400041223601500001101000030236516                                      04122333701 0');
        TempFile.Write('2200020657                                                     176418892                          GEBABEBB                   1 0');
        TempFile.Write('2300020657BE69210042100678                     PELTZER MARGUERITE                                                            0 1');
        TempFile.Write('31000206583010483001553002208  601500001001PELTZER MARGUERITE                                                                1 0');
        TempFile.Write('3200020658Av.Fr.Roosevelt 226                1050 BRUXELLES                                                                  0 0');
        TempFile.Write('21000206593010483001553002208  0000000000015400041223601500001101000030247933                                      04122333701 0');
        TempFile.Write('2200020659                                                     NOTPROVIDED                        BPOTBEB1                   1 0');
        TempFile.Write('2300020659BE39000095158919                     M. JEAN JAMIN                                                                 0 1');
        TempFile.Write('31000206603010483001553002208  601500001001M. JEAN JAMIN                                                                     1 0');
        TempFile.Write('3200020660Rue du Deuxieme Chasseurs(BL),3    5001 NAMUR                                                                      0 0');
        TempFile.Write('21000206613010483001553002208  0000000000015400041223601500001101000030252377                                      04122333701 0');
        TempFile.Write('2200020661                                                     NOTPROVIDED                        GKCCBEBB                   1 0');
        TempFile.Write('2300020661BE09063011952657                     CIVILTA - ALONGI                                                              0 1');
        TempFile.Write('31000206623010483001553002208  601500001001CIVILTA - ALONGI                                                                  1 0');
        TempFile.Write('3200020662RUE GRANDROUTE        151         4610  BEYNE-HEUSAY                                                               0 0');
        TempFile.Write('21000206633010483001553002208  0000000000023000041223601500001101000030252882                                      04122333701 0');
        TempFile.Write('2200020663                                                     NOTPROVIDED                        BPOTBEB1                   1 0');
        TempFile.Write('2300020663BE91000026207376                     Mme FRANCINE GAILLEZ                                                          0 1');
        TempFile.Write('31000206643010483001553002208  601500001001Mme FRANCINE GAILLEZ                                                              1 0');
        TempFile.Write('3200020664Rue Pierre Decoster,9 /01-3        1190 FOREST                                                                     0 0');
        TempFile.Write('21000206653010483001553002208  0000000000015400041223601500001101000030254704                                      04122333701 0');
        TempFile.Write('2200020665                                                     NOTPROVIDED                        BPOTBEB1                   1 0');
        TempFile.Write('2300020665BE46000093715336                     M. Yvon Es                                                                    0 1');
        TempFile.Write('31000206663010483001553002208  601500001001M. Yvon Es                                                                        1 0');
        TempFile.Write('3200020666Rue des Pres(H),16                 7334 SAINT-GHISLAIN                                                             0 0');
        TempFile.Write('21000206673010483001553002208  0000000000015400041223601500001101000030267737                                      04122333701 0');
        TempFile.Write('2200020667                                                     20231204CEC101003997-00105         KEYTBEBB                   1 0');
        TempFile.Write('2300020667BE23651153802091                     Paulette Gerard                                                               0 1');
        TempFile.Write('31000206683010483001553002208  601500001001Paulette Gerard                                                                   1 0');
        TempFile.Write('3200020668Rue Champ Rodange 127              1410 Waterloo                                                                   0 0');
        TempFile.Write('21000206693010483001553002208  0000000000015400041223601500001101000030273292                                      04122333701 0');
        TempFile.Write('2200020669                                                     NOTPROVIDED                        AXABBE22                   1 0');
        TempFile.Write('2300020669BE43750602567701                     Saglime Antonino - Canale Angela                                              0 1');
        TempFile.Write('31000206703010483001553002208  601500001001Saglime Antonino - Canale Angela                                                  1 0');
        TempFile.Write('3200020670Rue Andre Renard 92                4420 MONTEGNEE                                                                  0 0');
        TempFile.Write('21000206713010483001553002208  0000000000012400041223601500001101000030277033                                      04122333701 0');
        TempFile.Write('2200020671                                                     VZ33362WNQZ1K001                   CTBKBEBX                   1 0');
        TempFile.Write('2300020671BE65953135657596                     M MATHIEU SPIRLET OU Mme MARIE A                                              0 1');
        TempFile.Write('31000206723010483001553002208  601500001001M MATHIEU SPIRLET OU Mme MARIE A                                                  1 0');
        TempFile.Write('3200020672GELIVAUX 18                        4877 OLNE                                                                       0 0');
        TempFile.Write('21000206733010483001553002208  0000000000015400041223601500001101000030287036                                      04122333701 0');
        TempFile.Write('2200020673                                                     NOTPROVIDED                        BBRUBEBB                   1 0');
        TempFile.Write('2300020673BE41370114035210                     MME IOLANDA COLANTONIO                                                        0 1');
        TempFile.Write('31000206743010483001553002208  601500001001MME IOLANDA COLANTONIO                                                            1 0');
        TempFile.Write('3200020674RUE REINE ASTRID 57                7160        CHAPELLE-HERL                                                       0 0');
        TempFile.Write('21000206753010483001553002208  0000000000023000041223601500001101000030289258                                      04122333701 0');
        TempFile.Write('2200020675                                                     NOTPROVIDED                        GKCCBEBB                   1 0');
        TempFile.Write('2300020675BE79063646883133                     Acciocchi Fernand                                                             0 1');
        TempFile.Write('31000206763010483001553002208  601500001001Acciocchi Fernand                                                                 1 0');
        TempFile.Write('3200020676RUE DE HUSQUET     24/0001         4820  DISON                                                                     0 0');
        TempFile.Write('21000206773010483001553002208  0000000000017400041223601500001101000030289460                                      04122333701 0');
        TempFile.Write('2200020677                                                     NOTPROVIDED                        BPOTBEB1                   1 0');
        TempFile.Write('2300020677BE85000119960506                     M. ROBERT TAQUET                                                              0 1');
        TempFile.Write('31000206783010483001553002208  601500001001M. ROBERT TAQUET                                                                  1 0');
        TempFile.Write('3200020678Chaussee dEcaussinnes, 207         7090 BRAINE-LE-COMTE                                                            0 0');
        TempFile.Write('21000206793010483001553002208  0000000000015400041223601500001101000030294716                                      04122333701 0');
        TempFile.Write('2200020679                                                     NOTPROVIDED                        GEBABEBB                   1 0');
        TempFile.Write('2300020679BE18001022658165                     VERMEULEN JEAN                                                                0 1');
        TempFile.Write('31000206803010483001553002208  601500001001VERMEULEN JEAN                                                                    1 0');
        TempFile.Write('3200020680Av. des Rogations 70               1200     WOLUWE-SAINT-LAMBERT                                                   0 0');
        TempFile.Write('21000206813010483001553002208  0000000000015400041223601500001101000030297241                                      04122333701 0');
        TempFile.Write('2200020681                                                     NOTPROVIDED                        AXABBE22                   1 0');
        TempFile.Write('2300020681BE29750936312264                     Karaol Fatma                                                                  0 1');
        TempFile.Write('31000206823010483001553002208  601500001001Karaol Fatma                                                                      1 0');
        TempFile.Write('3200020682Rue de Liery 88                    4621 RETINNE                                                                    0 0');
        TempFile.Write('21000206833010483001553002208  0000000000029000041223601500001101000030301786                                      04122333701 0');
        TempFile.Write('2200020683                                                     NOTPROVIDED                        BBRUBEBB                   1 0');
        TempFile.Write('2300020683BE72310156473416                     MME GHISLAINE REIZER                                                          0 1');
        TempFile.Write('31000206843010483001553002208  601500001001MME GHISLAINE REIZER                                                              1 0');
        TempFile.Write('3200020684J P CARSOELLAAN 89 BUS 4           1180        UKKEL                                                               0 0');
        TempFile.Write('21000206853010483001553002208  0000000000023000041223601500001101000030311082                                      04122333701 0');
        TempFile.Write('2200020685                                                     NOTPROVIDED                        GEBABEBB                   1 0');
        TempFile.Write('2300020685BE82001823587468                     EL HADDAD OURIAGHLI MOHAMM                                                    0 1');
        TempFile.Write('31000206863010483001553002208  601500001001EL HADDAD OURIAGHLI MOHAMM                                                        1 0');
        TempFile.Write('3200020686RUE DE NIVELLES 34                 1330     RIXENSART                                                              0 0');
        TempFile.Write('21000206873010483001553002208  0000000000015400041223601500001101000030314722                                      04122333701 0');
        TempFile.Write('2200020687                                                     NOTPROVIDED                        GKCCBEBB                   1 0');
        TempFile.Write('2300020687BE03063710462084                     Bielmeier Johanna                                                             0 1');
        TempFile.Write('31000206883010483001553002208  601500001001Bielmeier Johanna                                                                 1 0');
        TempFile.Write('3200020688RUE JULES COISMAN        7         1320  BEAUVECHAIN                                                               0 0');
        TempFile.Write('21000206893010483001553002208  0000000000015400041223601500001101000030315934                                      04122333701 0');
        TempFile.Write('2200020689                                                     NOTPROVIDED                        GEBABEBB                   1 0');
        TempFile.Write('2300020689BE30001013893611                     DERCHE MICHELE                                                                0 1');
        TempFile.Write('31000206903010483001553002208  601500001001DERCHE MICHELE                                                                    1 0');
        TempFile.Write('3200020690Avenue Artemis 25     B005         1140 EVERE                                                                      0 0');
        TempFile.Write('21000206913010483001553002208  0000000000021070041223601500001101000030318762                                      04122333701 0');
        TempFile.Write('2200020691                                                     NOTPROVIDED                        BBRUBEBB                   1 0');
        TempFile.Write('2300020691BE67310113393187                     MME EMILIENNE LOMMEE                                                          0 1');
        TempFile.Write('31000206923010483001553002208  601500001001MME EMILIENNE LOMMEE                                                              1 0');
        TempFile.Write('3200020692RUE DU CORNET 128 BTE 11           1040        ETTERBEEK                                                           0 0');
        TempFile.Write('21000206933010483001553002208  0000000000015400041223601500001101000030320075                                      04122333701 0');
        TempFile.Write('2200020693                                                     NOTPROVIDED                        BPOTBEB1                   1 0');
        TempFile.Write('2300020693BE76000063040195                     M. Marcel Willaumez                                                           0 1');
        TempFile.Write('31000206943010483001553002208  601500001001M. Marcel Willaumez                                                               1 0');
        TempFile.Write('3200020694RUE DU HERDEAU, 4                  5660 COUVIN                                                                     0 0');
        TempFile.Write('21000206953010483001553002208  0000000000023000041223601500001101000030322907                                      04122333701 0');
        TempFile.Write('2200020695                                                     NOTPROVIDED                        NICABEBB                   1 0');
        TempFile.Write('2300020695BE89850810967585                     M. Pierre Dumont                                                              0 1');
        TempFile.Write('31000206963010483001553002208  601500001001M. Pierre Dumont                                                                  1 0');
        TempFile.Write('3200020696Avenue de la Pairelle,78/0009      5000 Namur                                                                      0 0');
        TempFile.Write('21000206973010483001553002208  0000000000015400041223601500001101000030338768                                      04122333701 0');
        TempFile.Write('2200020697                                                     NOTPROVIDED                        BNAGBEBB                   1 0');
        TempFile.Write('2300020697BE52132551858909                     BATAIRE JOCELYNE                                                              0 1');
        TempFile.Write('31000206983010483001553002208  601500001001BATAIRE JOCELYNE                                                                  1 0');
        TempFile.Write('3200020698RUE PISONCHAMPS 32                 4400 FLEMALLE                                                                   0 0');
        TempFile.Write('21000206993010483001553002208  0000000000023000041223601500001101000030343923                                      04122333701 0');
        TempFile.Write('2200020699                                                     NOTPROVIDED                        GKCCBEBB                   1 0');
        TempFile.Write('2300020699BE66063432135843                     BERNARD FERNANDE                                                              0 1');
        TempFile.Write('31000207003010483001553002208  601500001001BERNARD FERNANDE                                                                  1 0');
        TempFile.Write('3200020700CHAUSSEE DE NAMUR     27/8         1300  WAVRE                                                                     0 0');
        TempFile.Write('21000207013010483001553002208  0000000000015400041223601500001101000030344428                                      04122333701 0');
        TempFile.Write('2200020701                                                     NOTPROVIDED                        BPOTBEB1                   1 0');
        TempFile.Write('2300020701BE36000063339481                     Mme DENISE GENOT                                                              0 1');
        TempFile.Write('31000207023010483001553002208  601500001001Mme DENISE GENOT                                                                  1 0');
        TempFile.Write('3200020702Avenue Henri Pirard(O),17          1350 Orp-Jauche                                                                 0 0');
        TempFile.Write('21000207033010483001553002208  0000000000015400041223601500001101000030347155                                      04122333701 0');
        TempFile.Write('2200020703                                                     NOTPROVIDED                        GEBABEBB                   1 0');
        TempFile.Write('2300020703BE70210090478925                     CARDON DE LICHTBUER EMILIE                                                    0 1');
        TempFile.Write('31000207043010483001553002208  601500001001CARDON DE LICHTBUER EMILIE                                                        1 0');
        TempFile.Write('3200020704Av.de Tervueren 194    2           1150 WOLUWE-SAINT-PIERRE                                                        0 0');
        TempFile.Write('21000207053010483001553002208  0000000000017400041223601500001101000030348771                                      04122333701 0');
        TempFile.Write('2200020705                                                     NOTPROVIDED                        GKCCBEBB                   1 0');
        TempFile.Write('2300020705BE41063748818110                     KAYE BRIGITTE                                                                 0 1');
        TempFile.Write('31000207063010483001553002208  601500001001KAYE BRIGITTE                                                                     1 0');
        TempFile.Write('3200020706RUE DE TERWAGNE         11         5641  FURNAUX                                                                   0 0');
        TempFile.Write('21000207073010483001553002208  0000000000015400041223601500001101000030350589                                      04122333701 0');
        TempFile.Write('2200020707                                                     NOTPROVIDED                        AXABBE22                   1 0');
        TempFile.Write('2300020707BE03750904886284                     Larsille Yvette                                                               0 1');
        TempFile.Write('31000207083010483001553002208  601500001001Larsille Yvette                                                                   1 0');
        TempFile.Write('3200020708Rue de l Abbaye 6 / D7             1420 BRAINE-L ALLEUD                                                            0 0');
        TempFile.Write('21000207093010483001553002208  0000000000015400041223601500001101000030351195                                      04122333701 0');
        TempFile.Write('2200020709                                                     NOTPROVIDED                        BBRUBEBB                   1 0');
        TempFile.Write('2300020709BE93363181121167                     M FREDDY PAQUAY                                                               0 1');
        TempFile.Write('31000207103010483001553002208  601500001001M FREDDY PAQUAY                                                                   1 0');
        TempFile.Write('3200020710RUE MORAY 13                       4218        COUTHUIN                                                            0 0');
        TempFile.Write('21000207113010483001553002208  0000000000015400041223601500001101000030353724                                      04122333701 0');
        TempFile.Write('2200020711                                                     NOTPROVIDED                        BPOTBEB1                   1 0');
        TempFile.Write('2300020711BE15000018316630                     Mme Marie-Therese Coppens                                                     0 1');
        TempFile.Write('31000207123010483001553002208  601500001001Mme Marie-Therese Coppens                                                         1 0');
        TempFile.Write('3200020712RUE DE LETANG, 12                 1310 LA HULPE                                                                    0 0');
        TempFile.Write('21000207133010483001553002208  0000000000015400041223601500001101000030354330                                      04122333701 0');
        TempFile.Write('2200020713                                                     NOTPROVIDED                        GEBABEBB                   1 0');
        TempFile.Write('2300020713BE73210020671560                     VERSCHAFFEL CHRISTIAN                                                         0 1');
        TempFile.Write('31000207143010483001553002208  601500001001VERSCHAFFEL CHRISTIAN                                                             1 0');
        TempFile.Write('3200020714Rue de Meves 12                    1325 CHAUMONT-GISTOUX                                                           0 0');
        TempFile.Write('21000207153010483001553002208  0000000000017400041223601500001101000030357562                                      04122333701 0');
        TempFile.Write('2200020715                                                     NOTPROVIDED                        GKCCBEBB                   1 0');
        TempFile.Write('2300020715BE68063974025434                     Pickart Anne-Marie                                                            0 1');
        TempFile.Write('31000207163010483001553002208  601500001001Pickart Anne-Marie                                                                1 0');
        TempFile.Write('3200020716CHEMIN DE LHERITAGE    11         5377  SOMME-LEUZE                                                                0 0');
        TempFile.Write('21000207173010483001553002208  0000000000015400041223601500001101000030358269                                      04122333701 0');
        TempFile.Write('2200020717                                                     176687073                          GEBABEBB                   1 0');
        TempFile.Write('2300020717BE32210046836302                     DE BOECK LAMBERT                                                              0 1');
        TempFile.Write('31000207183010483001553002208  601500001001DE BOECK LAMBERT                                                                  1 0');
        TempFile.Write('3200020718RUE DE PERCKE 46                   1180 UCCLE                                                                      0 0');
        TempFile.Write('21000207193010483001553002208  0000000000021070041223601500001101000030372417                                      04122333701 0');
        TempFile.Write('2200020719                                                     NOTPROVIDED                        GEBABEBB                   1 0');
        TempFile.Write('2300020719BE98001869170293                     OBREEN MARIANNE                                                               0 1');
        TempFile.Write('31000207203010483001553002208  601500001001OBREEN MARIANNE                                                                   1 0');
        TempFile.Write('3200020720RUE DU CRAETVELD 133    B055       1120 BRUXELLES                                                                  0 0');
        TempFile.Write('21000207213010483001553002208  0000000000017400041223601500001101000030376255                                      04122333701 0');
        TempFile.Write('2200020721                                                     NOTPROVIDED                        BBRUBEBB                   1 0');
        TempFile.Write('2300020721BE05363034390075                     MME DANIELLE PAUL                                                             0 1');
        TempFile.Write('31000207223010483001553002208  601500001001MME DANIELLE PAUL                                                                 1 0');
        TempFile.Write('3200020722RUE DES POMMIERS 37                7090        BRAINE-COMTE                                                        0 0');
        TempFile.Write('21000207233010483001553002208  0000000000015400041223601500001101000030384036                                      04122333701 0');
        TempFile.Write('2200020723                                                     NOTPROVIDED                        BBRUBEBB                   1 0');
        TempFile.Write('2300020723BE96310085545905                     MME ANNE LIBERT                                                               0 1');
        TempFile.Write('31000207243010483001553002208  601500001001MME ANNE LIBERT                                                                   1 0');
        TempFile.Write('3200020724RUE DU TIERNAT 39                  1340        OTTIG-LOUVLNEU                                                      0 0');
        TempFile.Write('21000207253010483001553002208  0000000000023000041223601500001101000030387268                                      04122333701 0');
        TempFile.Write('2200020725                                                     NOTPROVIDED                        GKCCBEBB                   1 0');
        TempFile.Write('2300020725BE21063061562703                     Sourdeau Jean-Pierre                                                          0 1');
        TempFile.Write('31000207263010483001553002208  601500001001Sourdeau Jean-Pierre                                                              1 0');
        TempFile.Write('3200020726RUE PIERVENNE        39/21         5590  CINEY                                                                     0 0');
        TempFile.Write('21000207273010483001553002208  0000000000021070041223601500001101000030389389                                      04122333701 0');
        TempFile.Write('2200020727                                                     NOTPROVIDED                        GEBABEBB                   1 0');
        TempFile.Write('2300020727BE98271022432593                     BARTHOLOME-DUMORTIER                                                          0 1');
        TempFile.Write('31000207283010483001553002208  601500001001BARTHOLOME-DUMORTIER                                                              1 0');
        TempFile.Write('3200020728AVENUE HENRI HOUSSAYE 56           1410     WATERLOO                                                               0 0');
        TempFile.Write('21000207293010483001553002208  0000000000021070041223601500001101000030396160                                      04122333701 0');
        TempFile.Write('2200020729                                                     NOTPROVIDED                        BPOTBEB1                   1 0');
        TempFile.Write('2300020729BE70000109273025                     Mme Jeanne Malengret                                                          0 1');
        TempFile.Write('31000207303010483001553002208  601500001001Mme Jeanne Malengret                                                              1 0');
        TempFile.Write('3200020730PLACE ADOLPHE SAX,1 /b023          1050 IXELLES                                                                    0 0');
        TempFile.Write('21000207313010483001553002208  0000000000015400041223601500001101000030399089                                      04122333701 0');
        TempFile.Write('2200020731                                                     NOTPROVIDED                        BPOTBEB1                   1 0');
        TempFile.Write('2300020731BE20000479971356                     Mme MARTINE STORMS                                                            0 1');
        TempFile.Write('31000207323010483001553002208  601500001001Mme MARTINE STORMS                                                                1 0');
        TempFile.Write('3200020732Rue de l Etang, Gd - L., 8           5031 Gembloux                                                                 0 0');
        TempFile.Write('21000207333010483001553002208  0000000000023000041223601500001101000030399897                                      04122333701 0');
        TempFile.Write('2200020733                                                     NOTPROVIDED                        BPOTBEB1                   1 0');
        TempFile.Write('2300020733BE54000093052197                     Mme HELENE CASTANAS                                                           0 1');
        TempFile.Write('31000207343010483001553002208  601500001001Mme HELENE CASTANAS                                                               1 0');
        TempFile.Write('3200020734Rue des Stations,8                 7191 Ecaussinnes                                                                0 0');
        TempFile.Write('21000207353010483001553002208  0000000000015400041223601500001101000030400406                                      04122333701 0');
        TempFile.Write('2200020735                                                     NOTPROVIDED                        GEBABEBB                   1 0');
        TempFile.Write('2300020735BE21240077231303                     RAHIER-LECLERCQ                                                               0 1');
        TempFile.Write('31000207363010483001553002208  601500001001RAHIER-LECLERCQ                                                                   1 0');
        TempFile.Write('3200020736Rue de lAunaie 7                  4031     LIEGE                                                                   0 0');
        TempFile.Write('21000207373010483001553002208  0000000000021070041223601500001101000030428896                                      04122333701 0');
        TempFile.Write('2200020737                                                     NOTPROVIDED                        BPOTBEB1                   1 0');
        TempFile.Write('2300020737BE96000122637605                     Mme ELIANE DEVOS                                                              0 1');
        TempFile.Write('31000207383010483001553002208  601500001001Mme ELIANE DEVOS                                                                  1 0');
        TempFile.Write('3200020738Rue Ruisseau-des-Forges,14         5620 FLORENNES                                                                  0 0');
        TempFile.Write('21000207393010483001553002208  0000000000023000041223601500001101000030430314                                      04122333701 0');
        TempFile.Write('2200020739                                                     NOTPROVIDED                        BPOTBEB1                   1 0');
        TempFile.Write('2300020739BE34000031000590                     M. GUY SANREY                                                                 0 1');
        TempFile.Write('31000207403010483001553002208  601500001001M. GUY SANREY                                                                     1 0');
        TempFile.Write('3200020740Rue dAgimont, Rosee, 193           5620 FLORENNES                                                                  0 0');
        TempFile.Write('21000207413010483001553002208  0000000000015400041223601500001101000030430415                                      04122333701 0');
        TempFile.Write('2200020741                                                     NOTPROVIDED                        BBRUBEBB                   1 0');
        TempFile.Write('2300020741BE73930006537460                     TONNON-DURVIAUX                                                               0 1');
        TempFile.Write('31000207423010483001553002208  601500001001TONNON-DURVIAUX                                                                   1 0');
        TempFile.Write('3200020742RUE DU PLATEAU 8                   5310        EGHEZEE                                                             0 0');
        TempFile.Write('21000207433010483001553002208  0000000000021070041223601500001101000030436677                                      04122333701 0');
        TempFile.Write('2200020743                                                     NOTPROVIDED                        GEBABEBB                   1 0');
        TempFile.Write('2300020743BE76293025495695                     HEBRANT MARTHE                                                                0 1');
        TempFile.Write('31000207443010483001553002208  601500001001HEBRANT MARTHE                                                                    1 0');
        TempFile.Write('3200020744VREDELAAN 37                       1502 HALLE                                                                      0 0');
        TempFile.Write('21000207453010483001553002208  0000000000015400041223601500001101000030444660                                      04122333701 0');
        TempFile.Write('2200020745                                                     NOTPROVIDED                        GEBABEBB                   1 0');
        TempFile.Write('2300020745BE46001024294536                     TAVIAUX MARIE-JEANNE                                                          0 1');
        TempFile.Write('31000207463010483001553002208  601500001001TAVIAUX MARIE-JEANNE                                                              1 0');
        TempFile.Write('3200020746RUE DE BEAUMONT 78                 6536     THUIN                                                                  0 0');
        TempFile.Write('21000207473010483001553002208  0000000000015400041223601500001101000030445367                                      04122333701 0');
        TempFile.Write('2200020747                                                     NOTPROVIDED                        GEBABEBB                   1 0');
        TempFile.Write('2300020747BE47001587432480                     GENART FILIP                                                                  0 1');
        TempFile.Write('31000207483010483001553002208  601500001001GENART FILIP                                                                      1 0');
        TempFile.Write('3200020748Av.Grand Cortil 48                 1348     LOUVAIN-LA-NEUVE                                                       0 0');
        TempFile.Write('21000207493010483001553002208  0000000000021070041223601500001101000030446781                                      04122333711 0');
        TempFile.Write('2200020749                                                     NOTPROVIDED                        GEBABEBB                   1 0');
        TempFile.Write('2300020749BE52271007030209                     CREVECOEUR-MAUQUOY                                                            0 1');
        TempFile.Write('31000207503010483001553002208  601500001001CREVECOEUR-MAUQUOY                                                                1 0');
        TempFile.Write('3200020750Rue Jules Coisman 5                1320 BEAUVECHAIN                                                                0 0');
        TempFile.Write('8337BE04310075819431                  EUR0000000137134460041223                                                                0');
        TempFile.Write('9               001887000000000967490000000009330870                                                                           2');
    end;

    [Scope('OnPrem')]
    procedure InsertSampleCODAStatementLine1(StatementNo: Code[20]; BankAccountNo: Code[20])
    var
        CODAStatementLine: Record "CODA Statement Line";
    begin
        CODAStatementLine.Init();
        CODAStatementLine."Bank Account No." := BankAccountNo;
        CODAStatementLine."Statement No." := StatementNo;
        CODAStatementLine."Statement Line No." := 10000;
        CODAStatementLine.ID := CODAStatementLine.ID::Movement;
        CODAStatementLine.Type := CODAStatementLine.Type::Global;
        CODAStatementLine."Bank Reference No." := '230058315713';
        CODAStatementLine."Statement Amount" := 498297;
        CODAStatementLine."Transaction Date" := CalcDate('<CM+30D>', WorkDate());
        CODAStatementLine."Transaction Type" := 0;
        CODAStatementLine."Transaction Family" := 1;
        CODAStatementLine.Transaction := 50;
        CODAStatementLine."Transaction Category" := 0;
        CODAStatementLine."Message Type" := CODAStatementLine."Message Type"::"Non standard format";
        CODAStatementLine."Type Standard Format Message" := 0;
        CODAStatementLine."Statement Message" := '*** 00/9906/86864***';
        CODAStatementLine."Posting Date" := CODAStatementLine."Transaction Date";
        CODAStatementLine."Globalisation Code" := 0;
        CODAStatementLine."Bank Account No. Other Party" := '230058315713';
        CODAStatementLine."Name Other Party" := 'The Cannon Group PLC';
        CODAStatementLine."Address Other Party" := '192 Market Square';
        CODAStatementLine."City Other Party" := 'MECHELEN';
        CODAStatementLine."Attached to Line No." := 0;
        CODAStatementLine."System-Created Entry" := false;
        CODAStatementLine."Account Type" := CODAStatementLine."Account Type"::"G/L Account";
        CODAStatementLine."Document No." := CopyStr(StatementNo + '/1', 1, MaxStrLen(CODAStatementLine."Document No."));
        CODAStatementLine."Unapplied Amount" := CODAStatementLine."Statement Amount";
        CODAStatementLine.Insert();
    end;

    [Scope('OnPrem')]
    procedure InsertSampleCODAStatementLine2(StatementNo: Code[20]; BankAccountNo: Code[20])
    var
        CODAStatementLine: Record "CODA Statement Line";
    begin
        CODAStatementLine.Init();
        CODAStatementLine."Bank Account No." := BankAccountNo;
        CODAStatementLine."Statement No." := StatementNo;
        CODAStatementLine."Statement Line No." := 20000;
        CODAStatementLine.ID := CODAStatementLine.ID::"Free Message";
        CODAStatementLine.Type := CODAStatementLine.Type::Global;
        CODAStatementLine."Transaction Date" := CalcDate('<CM+30D>', WorkDate());
        CODAStatementLine."Transaction Type" := 0;
        CODAStatementLine."Transaction Family" := 0;
        CODAStatementLine.Transaction := 0;
        CODAStatementLine."Transaction Category" := 0;
        CODAStatementLine."Message Type" := CODAStatementLine."Message Type"::"Non standard format";
        CODAStatementLine."Type Standard Format Message" := 0;
        CODAStatementLine."Statement Message" := 'REF. 850719730107                             + 498.297 EUR';
        CODAStatementLine."Globalisation Code" := 0;
        CODAStatementLine."Attached to Line No." := 10000;
        CODAStatementLine."System-Created Entry" := false;
        CODAStatementLine."Account Type" := CODAStatementLine."Account Type"::"G/L Account";
        CODAStatementLine."Document No." := CopyStr(StatementNo + '/1', 1, MaxStrLen(CODAStatementLine."Document No."));
        CODAStatementLine.Insert();
    end;

    [Scope('OnPrem')]
    procedure InsertSampleCODAStatementLine3(StatementNo: Code[20]; BankAccountNo: Code[20])
    var
        CODAStatementLine: Record "CODA Statement Line";
    begin
        CODAStatementLine.Init();
        CODAStatementLine."Bank Account No." := BankAccountNo;
        CODAStatementLine."Statement No." := StatementNo;
        CODAStatementLine."Statement Line No." := 30000;
        CODAStatementLine.ID := CODAStatementLine.ID::Movement;
        CODAStatementLine.Type := CODAStatementLine.Type::Global;
        CODAStatementLine."Bank Reference No." := '4850743000074';
        CODAStatementLine."Statement Amount" := 6967;
        CODAStatementLine."Transaction Date" := CalcDate('<CM+30D>', WorkDate());
        CODAStatementLine."Transaction Type" := 2;
        CODAStatementLine."Transaction Family" := 1;
        CODAStatementLine.Transaction := 50;
        CODAStatementLine."Transaction Category" := 0;
        CODAStatementLine."Message Type" := CODAStatementLine."Message Type"::"Non standard format";
        CODAStatementLine."Type Standard Format Message" := 0;
        CODAStatementLine."Statement Message" := 'REF. **/36.9288';
        CODAStatementLine."Posting Date" := CODAStatementLine."Transaction Date";
        CODAStatementLine."System-Created Entry" := false;
        CODAStatementLine."Account Type" := CODAStatementLine."Account Type"::"G/L Account";
        CODAStatementLine."Document No." := CopyStr(StatementNo + '/1', 1, MaxStrLen(CODAStatementLine."Document No."));
        CODAStatementLine."Unapplied Amount" := CODAStatementLine."Statement Amount";
        CODAStatementLine.Insert();
    end;

    [Scope('OnPrem')]
    procedure InsertSampleCODAStatementLine4(StatementNo: Code[20]; BankAccountNo: Code[20])
    var
        CODAStatementLine: Record "CODA Statement Line";
    begin
        CODAStatementLine.Init();
        CODAStatementLine."Bank Account No." := BankAccountNo;
        CODAStatementLine."Statement No." := StatementNo;
        CODAStatementLine."Statement Line No." := 40000;
        CODAStatementLine.ID := CODAStatementLine.ID::Movement;
        CODAStatementLine.Type := CODAStatementLine.Type::Global;
        CODAStatementLine."Bank Reference No." := '230058315713';
        CODAStatementLine."Statement Amount" := 100200;
        CODAStatementLine."Transaction Date" := CalcDate('<CM+30D>', WorkDate());
        CODAStatementLine."Transaction Type" := 0;
        CODAStatementLine."Transaction Family" := 1;
        CODAStatementLine.Transaction := 50;
        CODAStatementLine."Transaction Category" := 0;
        CODAStatementLine."Message Type" := CODAStatementLine."Message Type"::"Non standard format";
        CODAStatementLine."Type Standard Format Message" := 0;
        CODAStatementLine."Statement Message" := '*** 00/9906/84037***';
        CODAStatementLine."Posting Date" := CODAStatementLine."Transaction Date";
        CODAStatementLine."Bank Account No. Other Party" := '310054005646';
        CODAStatementLine."Name Other Party" := 'Deerfield Graphics Company';
        CODAStatementLine."Address Other Party" := '10 Deerfield Road';
        CODAStatementLine."City Other Party" := 'BRAS';
        CODAStatementLine."System-Created Entry" := false;
        CODAStatementLine."Account Type" := CODAStatementLine."Account Type"::"G/L Account";
        CODAStatementLine."Document No." := CopyStr(StatementNo + '/3', 1, MaxStrLen(CODAStatementLine."Document No."));
        CODAStatementLine."Unapplied Amount" := CODAStatementLine."Statement Amount";
        CODAStatementLine.Insert();
    end;

    [Scope('OnPrem')]
    procedure InsertSampleCODAStatementLine5(StatementNo: Code[20]; BankAccountNo: Code[20])
    var
        CODAStatementLine: Record "CODA Statement Line";
    begin
        CODAStatementLine.Init();
        CODAStatementLine."Bank Account No." := BankAccountNo;
        CODAStatementLine."Statement No." := StatementNo;
        CODAStatementLine."Statement Line No." := 50000;
        CODAStatementLine.ID := CODAStatementLine.ID::"Free Message";
        CODAStatementLine.Type := CODAStatementLine.Type::Global;
        CODAStatementLine."Transaction Type" := 0;
        CODAStatementLine."Transaction Family" := 0;
        CODAStatementLine.Transaction := 0;
        CODAStatementLine."Transaction Category" := 0;
        CODAStatementLine."Message Type" := CODAStatementLine."Message Type"::"Non standard format";
        CODAStatementLine."Type Standard Format Message" := 0;
        CODAStatementLine."Statement Message" := 'REF. 850719730107                             + 100.200 EUR';
        CODAStatementLine."Posting Date" := CODAStatementLine."Transaction Date";
        CODAStatementLine."Attached to Line No." := 80000;
        CODAStatementLine."System-Created Entry" := false;
        CODAStatementLine."Account Type" := CODAStatementLine."Account Type"::"G/L Account";
        CODAStatementLine."Document No." := CopyStr(StatementNo + '/3', 1, MaxStrLen(CODAStatementLine."Document No."));
        CODAStatementLine."Unapplied Amount" := CODAStatementLine."Statement Amount";
        CODAStatementLine.Insert();
    end;

    [Scope('OnPrem')]
    procedure InsertSampleCODAStatementLine6(StatementNo: Code[20]; BankAccountNo: Code[20])
    var
        CODAStatementLine: Record "CODA Statement Line";
    begin
        CODAStatementLine.Init();
        CODAStatementLine."Bank Account No." := BankAccountNo;
        CODAStatementLine."Statement No." := StatementNo;
        CODAStatementLine."Statement Line No." := 60000;
        CODAStatementLine.ID := CODAStatementLine.ID::Movement;
        CODAStatementLine.Type := CODAStatementLine.Type::Global;
        CODAStatementLine."Bank Reference No." := '4850750705981';
        CODAStatementLine."Statement Amount" := -1208;
        CODAStatementLine."Transaction Date" := CalcDate('<CM+30D>', WorkDate());
        CODAStatementLine."Transaction Type" := 0;
        CODAStatementLine."Transaction Family" := 3;
        CODAStatementLine.Transaction := 3;
        CODAStatementLine."Transaction Category" := 0;
        CODAStatementLine."Message Type" := CODAStatementLine."Message Type"::"Standard format";
        CODAStatementLine."Type Standard Format Message" := 107;
        CODAStatementLine."Statement Message" := '4001969689460002 00001602010000 ARAL MECHELEN    MECHELEN';
        CODAStatementLine."Posting Date" := CODAStatementLine."Transaction Date";
        CODAStatementLine."System-Created Entry" := false;
        CODAStatementLine."Account Type" := CODAStatementLine."Account Type"::"G/L Account";
        CODAStatementLine."Document No." := CopyStr(StatementNo + '/4', 1, MaxStrLen(CODAStatementLine."Document No."));
        CODAStatementLine."Unapplied Amount" := CODAStatementLine."Statement Amount";
        CODAStatementLine.Insert();
    end;

    [Scope('OnPrem')]
    procedure InsertSampleCODAStatementLine7(StatementNo: Code[20]; BankAccountNo: Code[20])
    var
        CODAStatementLine: Record "CODA Statement Line";
        Customer: Record Customer;
    begin
        CODAStatementLine.Init();
        CODAStatementLine."Bank Account No." := BankAccountNo;
        CODAStatementLine."Statement No." := StatementNo;
        CODAStatementLine."Statement Line No." := 70000;
        CODAStatementLine.ID := CODAStatementLine.ID::Movement;
        CODAStatementLine.Type := CODAStatementLine.Type::Global;
        CODAStatementLine."Bank Reference No." := '788535710831';
        CODAStatementLine."Statement Amount" := 426053;
        CODAStatementLine."Transaction Date" := CalcDate('<CM+30D>', WorkDate());
        CODAStatementLine."Transaction Type" := 0;
        CODAStatementLine."Transaction Family" := 1;
        CODAStatementLine.Transaction := 50;
        CODAStatementLine."Transaction Category" := 0;
        CODAStatementLine."Message Type" := CODAStatementLine."Message Type"::"Standard format";
        CODAStatementLine."Type Standard Format Message" := 101;
        CODAStatementLine."Statement Message" := '000010300285';
        CODAStatementLine."Posting Date" := CODAStatementLine."Transaction Date";
        CODAStatementLine."Bank Account No. Other Party" := '788535710831';
        Customer.Get('20000');
        CODAStatementLine."Name Other Party" := CopyStr(Customer.Name, 1, MaxStrLen(CODAStatementLine."Name Other Party"));
        CODAStatementLine."Address Other Party" := '153 Thomas Drive';
        CODAStatementLine."City Other Party" := 'BRUSSEL';
        CODAStatementLine."Attached to Line No." := 0;
        CODAStatementLine."System-Created Entry" := false;
        CODAStatementLine."Account Type" := CODAStatementLine."Account Type"::"G/L Account";
        CODAStatementLine."Document No." := CopyStr(StatementNo + '/5', 1, MaxStrLen(CODAStatementLine."Document No."));
        CODAStatementLine."Unapplied Amount" := CODAStatementLine."Statement Amount";
        CODAStatementLine.Insert();
    end;

    [Scope('OnPrem')]
    procedure InsertSampleCODAStatementLine8(StatementNo: Code[20]; BankAccountNo: Code[20])
    var
        CODAStatementLine: Record "CODA Statement Line";
    begin
        CODAStatementLine.Init();
        CODAStatementLine."Bank Account No." := BankAccountNo;
        CODAStatementLine."Statement No." := StatementNo;
        CODAStatementLine."Statement Line No." := 80000;
        CODAStatementLine.ID := CODAStatementLine.ID::Movement;
        CODAStatementLine.Type := CODAStatementLine.Type::Global;
        CODAStatementLine."Bank Reference No." := '4866447710582';
        CODAStatementLine."Statement Amount" := -182;
        CODAStatementLine."Transaction Date" := CalcDate('<CM+30D>', WorkDate());
        CODAStatementLine."Transaction Type" := 3;
        CODAStatementLine."Transaction Family" := 41;
        CODAStatementLine.Transaction := 37;
        CODAStatementLine."Transaction Category" := 0;
        CODAStatementLine."Message Type" := CODAStatementLine."Message Type"::"Non standard format";
        CODAStatementLine."Type Standard Format Message" := 0;
        CODAStatementLine."Posting Date" := CODAStatementLine."Transaction Date";
        CODAStatementLine."System-Created Entry" := false;
        CODAStatementLine."Account Type" := CODAStatementLine."Account Type"::"G/L Account";
        CODAStatementLine."Document No." := CopyStr(StatementNo + '/6', 1, MaxStrLen(CODAStatementLine."Document No."));
        CODAStatementLine."Unapplied Amount" := CODAStatementLine."Statement Amount";
        CODAStatementLine.Insert();
    end;

    [Scope('OnPrem')]
    procedure InsertSampleCODAStatementLine9(StatementNo: Code[20]; BankAccountNo: Code[20])
    var
        CODAStatementLine: Record "CODA Statement Line";
    begin
        CODAStatementLine.Init();
        CODAStatementLine."Bank Account No." := BankAccountNo;
        CODAStatementLine."Statement No." := StatementNo;
        CODAStatementLine."Statement Line No." := 90000;
        CODAStatementLine.ID := CODAStatementLine.ID::Information;
        CODAStatementLine.Type := CODAStatementLine.Type::Global;
        CODAStatementLine."Bank Reference No." := '4866447710582';
        CODAStatementLine."Transaction Date" := CalcDate('<CM+30D>', WorkDate());
        CODAStatementLine."Transaction Type" := 3;
        CODAStatementLine."Transaction Family" := 41;
        CODAStatementLine.Transaction := 37;
        CODAStatementLine."Transaction Category" := 0;
        CODAStatementLine."Message Type" := CODAStatementLine."Message Type"::"Non standard format";
        CODAStatementLine."Type Standard Format Message" := 0;
        CODAStatementLine."Statement Message" := 'RABOBANK NETHERLANDS';
        CODAStatementLine."Attached to Line No." := 160000;
        CODAStatementLine."System-Created Entry" := false;
        CODAStatementLine."Account Type" := CODAStatementLine."Account Type"::"G/L Account";
        CODAStatementLine."Document No." := CopyStr(StatementNo + '/6', 1, MaxStrLen(CODAStatementLine."Document No."));
        CODAStatementLine."Unapplied Amount" := CODAStatementLine."Statement Amount";
        CODAStatementLine.Insert();
    end;

    [Scope('OnPrem')]
    procedure InsertSampleCODAStatementLine10(StatementNo: Code[20]; BankAccountNo: Code[20])
    var
        CODAStatementLine: Record "CODA Statement Line";
    begin
        CODAStatementLine.Init();
        CODAStatementLine."Bank Account No." := BankAccountNo;
        CODAStatementLine."Statement No." := StatementNo;
        CODAStatementLine."Statement Line No." := 100000;
        CODAStatementLine.ID := CODAStatementLine.ID::Information;
        CODAStatementLine.Type := CODAStatementLine.Type::Global;
        CODAStatementLine."Bank Reference No." := '4866447710582';
        CODAStatementLine."Transaction Type" := 3;
        CODAStatementLine."Transaction Family" := 41;
        CODAStatementLine.Transaction := 37;
        CODAStatementLine."Transaction Category" := 0;
        CODAStatementLine."Message Type" := CODAStatementLine."Message Type"::"Non standard format";
        CODAStatementLine."Statement Message" := 'TRANSFER ORDER CHARGES :                        EUR         5550,00';
        CODAStatementLine."Attached to Line No." := 160000;
        CODAStatementLine."System-Created Entry" := false;
        CODAStatementLine."Account Type" := CODAStatementLine."Account Type"::"G/L Account";
        CODAStatementLine."Document No." := CopyStr(StatementNo + '/6', 1, MaxStrLen(CODAStatementLine."Document No."));
        CODAStatementLine."Unapplied Amount" := CODAStatementLine."Statement Amount";
        CODAStatementLine.Insert();
    end;

    [Scope('OnPrem')]
    procedure InsertSampleCODAStatementLine11(StatementNo: Code[20]; BankAccountNo: Code[20])
    var
        CODAStatementLine: Record "CODA Statement Line";
    begin
        CODAStatementLine.Init();
        CODAStatementLine."Bank Account No." := BankAccountNo;
        CODAStatementLine."Statement No." := StatementNo;
        CODAStatementLine."Statement Line No." := 110000;
        CODAStatementLine.ID := CODAStatementLine.ID::"Free Message";
        CODAStatementLine.Type := CODAStatementLine.Type::Global;
        CODAStatementLine."Transaction Type" := 0;
        CODAStatementLine."Transaction Family" := 0;
        CODAStatementLine.Transaction := 0;
        CODAStatementLine."Transaction Category" := 0;
        CODAStatementLine."Message Type" := CODAStatementLine."Message Type"::"Non standard format";
        CODAStatementLine."Statement Message" := 'REF. 866447710582                                 FOLIO 01';
        CODAStatementLine."Attached to Line No." := 160000;
        CODAStatementLine."System-Created Entry" := false;
        CODAStatementLine."Account Type" := CODAStatementLine."Account Type"::"G/L Account";
        CODAStatementLine."Document No." := CopyStr(StatementNo + '/6', 1, MaxStrLen(CODAStatementLine."Document No."));
        CODAStatementLine."Unapplied Amount" := CODAStatementLine."Statement Amount";
        CODAStatementLine.Insert();
    end;

    [Scope('OnPrem')]
    procedure InsertSampleCODAStatementLine12(StatementNo: Code[20]; BankAccountNo: Code[20])
    var
        CODAStatementLine: Record "CODA Statement Line";
    begin
        CODAStatementLine.Init();
        CODAStatementLine."Bank Account No." := BankAccountNo;
        CODAStatementLine."Statement No." := StatementNo;
        CODAStatementLine."Statement Line No." := 120000;
        CODAStatementLine.ID := CODAStatementLine.ID::Movement;
        CODAStatementLine.Type := CODAStatementLine.Type::Detail;
        CODAStatementLine."Bank Reference No." := '4866447710582';
        CODAStatementLine."Statement Amount" := -32;
        CODAStatementLine."Transaction Date" := CalcDate('<CM+30D>', WorkDate());
        CODAStatementLine."Transaction Type" := 8;
        CODAStatementLine."Transaction Family" := 41;
        CODAStatementLine.Transaction := 37;
        CODAStatementLine."Transaction Category" := 11;
        CODAStatementLine."Message Type" := CODAStatementLine."Message Type"::"Standard format";
        CODAStatementLine."Type Standard Format Message" := 106;
        CODAStatementLine."Statement Message" := '0000000000320000000150000002100000000 000000000032000';
        CODAStatementLine."Posting Date" := CODAStatementLine."Transaction Date";
        CODAStatementLine."Attached to Line No." := 160000;
        CODAStatementLine."System-Created Entry" := false;
        CODAStatementLine."Account Type" := CODAStatementLine."Account Type"::"G/L Account";
        CODAStatementLine."Document No." := CopyStr(StatementNo + '/6-1', 1, MaxStrLen(CODAStatementLine."Document No."));
        CODAStatementLine."Unapplied Amount" := CODAStatementLine."Statement Amount";
        CODAStatementLine.Insert();
    end;

    [Scope('OnPrem')]
    procedure InsertSampleCODAStatementLine13(StatementNo: Code[20]; BankAccountNo: Code[20])
    var
        CODAStatementLine: Record "CODA Statement Line";
    begin
        CODAStatementLine.Init();
        CODAStatementLine."Bank Account No." := BankAccountNo;
        CODAStatementLine."Statement No." := StatementNo;
        CODAStatementLine."Statement Line No." := 130000;
        CODAStatementLine.ID := CODAStatementLine.ID::Movement;
        CODAStatementLine.Type := CODAStatementLine.Type::Detail;
        CODAStatementLine."Bank Reference No." := '4866447710582';
        CODAStatementLine."Statement Amount" := -150;
        CODAStatementLine."Transaction Date" := CalcDate('<CM+30D>', WorkDate());
        CODAStatementLine."Transaction Type" := 8;
        CODAStatementLine."Transaction Family" := 41;
        CODAStatementLine.Transaction := 37;
        CODAStatementLine."Transaction Category" := 13;
        CODAStatementLine."Message Type" := CODAStatementLine."Message Type"::"Non standard format";
        CODAStatementLine."Posting Date" := CODAStatementLine."Transaction Date";
        CODAStatementLine."Attached to Line No." := 160000;
        CODAStatementLine."System-Created Entry" := false;
        CODAStatementLine."Account Type" := CODAStatementLine."Account Type"::"G/L Account";
        CODAStatementLine."Document No." := CopyStr(StatementNo + '/6-2', 1, MaxStrLen(CODAStatementLine."Document No."));
        CODAStatementLine."Unapplied Amount" := CODAStatementLine."Statement Amount";
        CODAStatementLine.Insert();
    end;

    [Scope('OnPrem')]
    procedure InsertSampleCODAStatementLine14(StatementNo: Code[20]; BankAccountNo: Code[20])
    var
        CODAStatementLine: Record "CODA Statement Line";
    begin
        CODAStatementLine.Init();
        CODAStatementLine."Bank Account No." := BankAccountNo;
        CODAStatementLine."Statement No." := StatementNo;
        CODAStatementLine."Statement Line No." := 140000;
        CODAStatementLine.ID := CODAStatementLine.ID::Movement;
        CODAStatementLine.Type := CODAStatementLine.Type::Global;
        CODAStatementLine."Bank Reference No." := '4866447710582';
        CODAStatementLine."Statement Amount" := -220099;
        CODAStatementLine."Transaction Date" := CalcDate('<CM+30D>', WorkDate());
        CODAStatementLine."Transaction Type" := 0;
        CODAStatementLine."Transaction Family" := 1;
        CODAStatementLine.Transaction := 1;
        CODAStatementLine."Transaction Category" := 0;
        CODAStatementLine."Message Type" := CODAStatementLine."Message Type"::"Non standard format";
        CODAStatementLine."Type Standard Format Message" := 0;
        CODAStatementLine."Statement Message" := '101000010802665';
        CODAStatementLine."Posting Date" := CODAStatementLine."Transaction Date";
        CODAStatementLine."Globalisation Code" := 0;
        CODAStatementLine."Bank Account No. Other Party" := '431068010811';
        CODAStatementLine."Name Other Party" := 'CoolWood Technologies';
        CODAStatementLine."Address Other Party" := '33 Hitech Drive';
        CODAStatementLine."City Other Party" := 'ANDERLECHT';
        CODAStatementLine."Attached to Line No." := 0;
        CODAStatementLine."System-Created Entry" := false;
        CODAStatementLine."Account Type" := CODAStatementLine."Account Type"::"G/L Account";
        CODAStatementLine."Document No." := CopyStr(StatementNo + '/7', 1, MaxStrLen(CODAStatementLine."Document No."));
        CODAStatementLine."Unapplied Amount" := CODAStatementLine."Statement Amount";
        CODAStatementLine.Insert();
    end;

    [Scope('OnPrem')]
    procedure InsertSampleCODAStatementLine15(StatementNo: Code[20]; BankAccountNo: Code[20])
    var
        CODAStatementLine: Record "CODA Statement Line";
    begin
        CODAStatementLine.Init();
        CODAStatementLine."Bank Account No." := BankAccountNo;
        CODAStatementLine."Statement No." := StatementNo;
        CODAStatementLine."Statement Line No." := 150000;
        CODAStatementLine.ID := CODAStatementLine.ID::Movement;
        CODAStatementLine.Type := CODAStatementLine.Type::Global;
        CODAStatementLine."Bank Reference No." := '4866447710582';
        CODAStatementLine."Statement Amount" := -1700;
        CODAStatementLine."Transaction Date" := CalcDate('<CM+30D>', WorkDate());
        CODAStatementLine."Transaction Type" := 0;
        CODAStatementLine."Transaction Family" := 1;
        CODAStatementLine.Transaction := 1;
        CODAStatementLine."Transaction Category" := 0;
        CODAStatementLine."Message Type" := CODAStatementLine."Message Type"::"Standard format";
        CODAStatementLine."Type Standard Format Message" := 101;
        CODAStatementLine."Statement Message" := '198411561414';
        CODAStatementLine."Posting Date" := CODAStatementLine."Transaction Date";
        CODAStatementLine."Globalisation Code" := 0;
        CODAStatementLine."Bank Account No. Other Party" := '431068011114';
        CODAStatementLine."Name Other Party" := 'MILLERS & CO';
        CODAStatementLine."Attached to Line No." := 0;
        CODAStatementLine."System-Created Entry" := false;
        CODAStatementLine."Account Type" := CODAStatementLine."Account Type"::"G/L Account";
        CODAStatementLine."Document No." := CopyStr(StatementNo + '/8', 1, MaxStrLen(CODAStatementLine."Document No."));
        CODAStatementLine."Unapplied Amount" := CODAStatementLine."Statement Amount";
        CODAStatementLine.Insert();
    end;

    [Scope('OnPrem')]
    procedure ValidateSampleCODAStatementLine(StatementNo: Code[20]; StatementLineNo: Integer)
    var
        CODAStatementLine: Record "CODA Statement Line";
    begin
        CODAStatementLine.Init();
        CODAStatementLine.SetRange("Statement No.", StatementNo);
        CODAStatementLine.SetRange("Statement Line No.", StatementLineNo);

        CODAStatementLine.FindFirst();

        case StatementLineNo of
            10000, 30000, 40000:
                ValidateSampleCODAStatementLine1(CODAStatementLine);
            60000:
                ValidateSampleCODAStatementLine6(CODAStatementLine);
            70000:
                ValidateSampleCODAStatementLine7(CODAStatementLine);
            80000:
                ValidateSampleCODAStatementLine8(CODAStatementLine);
            120000:
                ValidateSampleCODAStatementLine12(CODAStatementLine);
            130000:
                ValidateSampleCODAStatementLine13(CODAStatementLine);
        end;
    end;

    [Scope('OnPrem')]
    procedure ValidateSampleCODAStatementLine1(CODAStatementLine: Record "CODA Statement Line")
    begin
        Assert.AreEqual(CODAStatementLine."Statement Message", CODAStatementLine.Description, 'Line ' +
          Format(CODAStatementLine."Statement Line No."));
        Assert.AreEqual(true, CODAStatementLine."System-Created Entry", 'Line ' + Format(CODAStatementLine."Statement Line No."));
    end;

    [Scope('OnPrem')]
    procedure ValidateSampleCODAStatementLine6(CODAStatementLine: Record "CODA Statement Line")
    var
        GLAccount: Record "G/L Account";
    begin
        GLAccount.Get('499999');
        Assert.AreEqual(GLAccount.Name, CODAStatementLine.Description, 'Line ' + Format(CODAStatementLine."Statement Line No."));
        Assert.AreEqual(true, CODAStatementLine."System-Created Entry", 'Line ' + Format(CODAStatementLine."Statement Line No."));
        Assert.AreEqual(CODAStatementLine."Application Status"::"Partly applied", CODAStatementLine."Application Status", 'Line ' +
          Format(CODAStatementLine."Statement Line No."));
        Assert.AreEqual('499999', CODAStatementLine."Account No.", 'Line ' + Format(CODAStatementLine."Statement Line No."));
        Assert.AreEqual(0, CODAStatementLine.Amount, 'Line ' + Format(CODAStatementLine."Statement Line No."));
        Assert.AreEqual(0, CODAStatementLine."Amount (LCY)", 'Line ' + Format(CODAStatementLine."Statement Line No."));
        Assert.AreEqual(-1208, CODAStatementLine."Unapplied Amount", 'Line ' + Format(CODAStatementLine."Statement Line No."));
    end;

    [Scope('OnPrem')]
    procedure ValidateSampleCODAStatementLine7(CODAStatementLine: Record "CODA Statement Line")
    begin
        Assert.AreEqual(CODAStatementLine."Name Other Party", CODAStatementLine.Description, 'Line ' +
          Format(CODAStatementLine."Statement Line No."));
        Assert.AreEqual(true, CODAStatementLine."System-Created Entry", 'Line ' + Format(CODAStatementLine."Statement Line No."));
        Assert.AreEqual(CODAStatementLine."Document No.", CODAStatementLine."Applies-to ID", 'Line ' +
          Format(CODAStatementLine."Statement Line No."));
        Assert.AreEqual(CODAStatementLine."Application Status"::Applied, CODAStatementLine."Application Status", 'Line ' +
          Format(CODAStatementLine."Statement Line No."));
        Assert.AreEqual(CODAStatementLine."Account Type"::Customer, CODAStatementLine."Account Type", 'Line ' +
          Format(CODAStatementLine."Statement Line No."));
        Assert.AreEqual('20000', CODAStatementLine."Account No.", 'Line ' + Format(CODAStatementLine."Statement Line No."));
        Assert.AreEqual(CODAStatementLine."Document Type"::Payment, CODAStatementLine."Document Type", 'Line ' +
          Format(CODAStatementLine."Statement Line No."));
        Assert.AreEqual(426053, CODAStatementLine.Amount, 'Line ' + Format(CODAStatementLine."Statement Line No."));
        Assert.AreEqual(0, CODAStatementLine."Unapplied Amount", 'Line ' + Format(CODAStatementLine."Statement Line No."));
        Assert.AreEqual(CODAStatementLine."Name Other Party", CODAStatementLine."Account Name", 'Line ' +
          Format(CODAStatementLine."Statement Line No."));
    end;

    [Scope('OnPrem')]
    procedure ValidateSampleCODAStatementLine8(CODAStatementLine: Record "CODA Statement Line")
    begin
        Assert.AreEqual(true, CODAStatementLine."System-Created Entry", 'Line ' + Format(CODAStatementLine."Statement Line No."));
        Assert.AreEqual(-182, CODAStatementLine."Unapplied Amount", 'Line ' + Format(CODAStatementLine."Statement Line No."));
    end;

    [Scope('OnPrem')]
    procedure ValidateSampleCODAStatementLine12(CODAStatementLine: Record "CODA Statement Line")
    begin
        Assert.AreEqual(true, CODAStatementLine."System-Created Entry", 'Line ' + Format(CODAStatementLine."Statement Line No."));
        Assert.AreEqual(CODAStatementLine."Application Status"::"Partly applied", CODAStatementLine."Application Status", 'Line ' +
          Format(CODAStatementLine."Statement Line No."));
        Assert.AreEqual('411000', CODAStatementLine."Account No.", 'Line ' + Format(CODAStatementLine."Statement Line No."));
        Assert.AreEqual(0, CODAStatementLine.Amount, 'Line ' + Format(CODAStatementLine."Statement Line No."));
        Assert.AreEqual(0, CODAStatementLine."Amount (LCY)", 'Line ' + Format(CODAStatementLine."Statement Line No."));
        Assert.AreEqual(-32, CODAStatementLine."Unapplied Amount", 'Line ' + Format(CODAStatementLine."Statement Line No."));
    end;

    [Scope('OnPrem')]
    procedure ValidateSampleCODAStatementLine13(CODAStatementLine: Record "CODA Statement Line")
    begin
        Assert.AreEqual(true, CODAStatementLine."System-Created Entry", 'Line ' + Format(CODAStatementLine."Statement Line No."));
        Assert.AreEqual(CODAStatementLine.Description, CODAStatementLine."Application Information", 'Line ' +
          Format(CODAStatementLine."Statement Line No."));
        Assert.AreEqual(CODAStatementLine."Application Status"::"Partly applied", CODAStatementLine."Application Status", 'Line ' +
          Format(CODAStatementLine."Statement Line No."));
        Assert.AreEqual('656000', CODAStatementLine."Account No.", 'Line ' + Format(CODAStatementLine."Statement Line No."));
        Assert.AreEqual(0, CODAStatementLine.Amount, 'Line ' + Format(CODAStatementLine."Statement Line No."));
        Assert.AreEqual(0, CODAStatementLine."Amount (LCY)", 'Line ' + Format(CODAStatementLine."Statement Line No."));
        Assert.AreEqual(-150, CODAStatementLine."Unapplied Amount", 'Line ' + Format(CODAStatementLine."Statement Line No."));
    end;
}

