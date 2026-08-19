codeunit 137180 "Costing WMS"
{
    Subtype = Test;

    trigger OnRun()
    begin
    end;

    var
        RunManager: Codeunit "Testscript Run Manager";
        WMSBWInitialized: Boolean;
        Text0001_Err: Label '''Cannot find Entry no: %1 and Project Code: %2 in WHSE test cases. Test configuration error!!!''';
        WMS_Tok: Label 'WMS';

    [Test]
    [Scope('OnPrem')]
    procedure WMSTC1()
    begin
        WMSBWExecuteTC(1);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure WMSTC2()
    begin
        WMSBWExecuteTC(2);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure WMSTC3()
    begin
        WMSBWExecuteTC(3);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure WMSTC4()
    begin
        WMSBWExecuteTC(4);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure WMSTC5()
    begin
        WMSBWExecuteTC(5);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure WMSTC6()
    begin
        WMSBWExecuteTC(6);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure WMSTC7()
    begin
        WMSBWExecuteTC(7);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure WMSTC8()
    begin
        WMSBWExecuteTC(8);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure WMSTC9()
    begin
        WMSBWExecuteTC(9);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure WMSTC10()
    begin
        WMSBWExecuteTC(10);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure WMSTC11()
    begin
        WMSBWExecuteTC(11);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure WMSTC12()
    begin
        WMSBWExecuteTC(12);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure WMSTC13()
    begin
        WMSBWExecuteTC(13);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure WMSTC14()
    begin
        WMSBWExecuteTC(14);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure WMSTC15()
    begin
        WMSBWExecuteTC(15);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure WMSTC16()
    begin
        WMSBWExecuteTC(16);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure WMSTC17()
    begin
        WMSBWExecuteTC(17);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure WMSTC18()
    begin
        WMSBWExecuteTC(18);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure WMSTC19()
    begin
        WMSBWExecuteTC(19);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure WMSTC20()
    begin
        WMSBWExecuteTC(20);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure WMSTC21()
    begin
        WMSBWExecuteTC(21);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure WMSTC22()
    begin
        WMSBWExecuteTC(22);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure WMSTC23()
    begin
        WMSBWExecuteTC(23);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure WMSTC24()
    begin
        WMSBWExecuteTC(24);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure WMSTC25()
    begin
        WMSBWExecuteTC(25);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure WMSTC26()
    begin
        WMSBWExecuteTC(26);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure WMSTC27()
    begin
        WMSBWExecuteTC(27);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure WMSTC28()
    begin
        WMSBWExecuteTC(28);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure WMSTC29()
    begin
        WMSBWExecuteTC(29);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure WMSTC30()
    begin
        WMSBWExecuteTC(30);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure WMSTC31()
    begin
        WMSBWExecuteTC(31);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure WMSTC32()
    begin
        WMSBWExecuteTC(32);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure WMSTC33()
    begin
        WMSBWExecuteTC(33);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure WMSTC34()
    begin
        WMSBWExecuteTC(34);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure WMSTC35()
    begin
        WMSBWExecuteTC(35);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure WMSTC36()
    begin
        WMSBWExecuteTC(36);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure WMSTC37()
    begin
        WMSBWExecuteTC(37);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure WMSTC38()
    begin
        WMSBWExecuteTC(38);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure WMSTC39()
    begin
        WMSBWExecuteTC(39);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure WMSTC40()
    begin
        WMSBWExecuteTC(40);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure WMSTC42()
    begin
        WMSBWExecuteTC(42);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure WMSTC43()
    begin
        WMSBWExecuteTC(43);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure WMSTC44()
    begin
        WMSBWExecuteTC(44);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure WMSTC45()
    begin
        WMSBWExecuteTC(45);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure WMSTC46()
    begin
        WMSBWExecuteTC(46);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure WMSTC47()
    begin
        WMSBWExecuteTC(47);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure WMSTC48()
    begin
        WMSBWExecuteTC(48);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure WMSTC49()
    begin
        WMSBWExecuteTC(49);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure WMSTC50()
    begin
        WMSBWExecuteTC(50);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure WMSTC51()
    begin
        WMSBWExecuteTC(51);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure WMSTC52()
    begin
        WMSBWExecuteTC(52);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure WMSTC53()
    begin
        WMSBWExecuteTC(53);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure WMSTC54()
    begin
        WMSBWExecuteTC(54);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure WMSTC55()
    begin
        WMSBWExecuteTC(55);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure WMSTC56()
    begin
        WMSBWExecuteTC(56);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure WMSTC57()
    begin
        WMSBWExecuteTC(57);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure WMSTC58()
    begin
        WMSBWExecuteTC(58);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure WMSTC59()
    begin
        WMSBWExecuteTC(59);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure WMSTC60()
    begin
        WMSBWExecuteTC(60);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure WMSTC61()
    begin
        WMSBWExecuteTC(61);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure WMSTC62()
    begin
        WMSBWExecuteTC(62);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure WMSTC65()
    begin
        WMSBWExecuteTC(65);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure WMSTC66()
    begin
        WMSBWExecuteTC(66);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure WMSTC71()
    begin
        WMSBWExecuteTC(71);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure WMSTC72()
    begin
        WMSBWExecuteTC(72);
    end;

    [Normal]
    local procedure WMSBWExecuteTC(EntryNo: Integer)
    var
        TestCase: Record "Whse. Test Case";
        TestscriptWMS: Codeunit "WMS Testscript";
    begin
        WMSBWInitialize();

        TestCase.Reset();
        TestCase.SetRange("Entry No.",EntryNo);
        TestCase.SetRange("Project Code",WMS_Tok);

        if TestCase.FindFirst() then begin
          TestscriptWMS.SetLastIteration(TestCase."Use Case No.",TestCase."Test Case No.",0,0,TestCase."Project Code");
          TestscriptWMS.SetKeepUseCases(true);
          TestscriptWMS.SetShowTestResults(false);
          TestscriptWMS.Run();
          RunManager.ValidateWMSBWRun(TestCase);
        end else
         Error(Text0001_Err,EntryNo,WMS_Tok);
    end;

    [Normal]
    local procedure WMSBWInitialize()
    begin
        RunManager.ClearTestResultTable();

        if WMSBWInitialized then
          exit;

        RunManager.PrepareWMSBW();
        WMSBWInitialized := true;
        Commit();
    end;
}

