codeunit 137181 "Costing BW"
{
    Subtype = Test;

    trigger OnRun()
    begin
    end;

    var
        RunManager: Codeunit "Testscript Run Manager";
        BW_Tok: Label 'BW';
        Text0001_Err: Label '''Cannot find Entry no: %1 and Project Code: %2 in WHSE test cases. Test configuration error!!!''';
        WMSBWInitialized: Boolean;

    [Test]
    [Scope('OnPrem')]
    procedure BWTC1()
    begin
        WMSBWExecuteTC(1);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure BWTC2()
    begin
        WMSBWExecuteTC(2);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure BWTC3()
    begin
        WMSBWExecuteTC(3);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure BWTC4()
    begin
        WMSBWExecuteTC(4);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure BWTC5()
    begin
        WMSBWExecuteTC(5);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure BWTC6()
    begin
        WMSBWExecuteTC(6);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure BWTC7()
    begin
        WMSBWExecuteTC(7);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure BWTC8()
    begin
        WMSBWExecuteTC(8);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure BWTC9()
    begin
        WMSBWExecuteTC(9);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure BWTC10()
    begin
        WMSBWExecuteTC(10);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure BWTC11()
    begin
        WMSBWExecuteTC(11);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure BWTC12()
    begin
        WMSBWExecuteTC(12);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure BWTC13()
    begin
        WMSBWExecuteTC(13);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure BWTC14()
    begin
        WMSBWExecuteTC(14);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure BWTC15()
    begin
        WMSBWExecuteTC(15);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure BWTC16()
    begin
        WMSBWExecuteTC(16);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure BWTC17()
    begin
        WMSBWExecuteTC(17);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure BWTC18()
    begin
        WMSBWExecuteTC(18);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure BWTC19()
    begin
        WMSBWExecuteTC(19);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure BWTC20()
    begin
        WMSBWExecuteTC(20);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure BWTC21()
    begin
        WMSBWExecuteTC(21);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure BWTC22()
    begin
        WMSBWExecuteTC(22);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure BWTC23()
    begin
        WMSBWExecuteTC(23);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure BWTC24()
    begin
        WMSBWExecuteTC(24);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure BWTC25()
    begin
        WMSBWExecuteTC(25);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure BWTC26()
    begin
        WMSBWExecuteTC(26);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure BWTC27()
    begin
        WMSBWExecuteTC(27);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure BWTC28()
    begin
        WMSBWExecuteTC(28);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure BWTC29()
    begin
        WMSBWExecuteTC(29);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure BWTC30()
    begin
        WMSBWExecuteTC(30);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure BWTC31()
    begin
        WMSBWExecuteTC(31);
    end;

    [Test]
    [HandlerFunctions('YesConfirmHandler')]
    [Scope('OnPrem')]
    procedure BWTC32()
    begin
        WMSBWExecuteTC(32);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure BWTC33()
    begin
        WMSBWExecuteTC(33);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure BWTC34()
    begin
        WMSBWExecuteTC(34);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure BWTC35()
    begin
        WMSBWExecuteTC(35);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure BWTC36()
    begin
        WMSBWExecuteTC(36);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure BWTC37()
    begin
        WMSBWExecuteTC(37);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure BWTC38()
    begin
        WMSBWExecuteTC(38);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure BWTC39()
    begin
        WMSBWExecuteTC(39);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure BWTC40()
    begin
        WMSBWExecuteTC(40);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure BWTC41()
    begin
        WMSBWExecuteTC(41);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure BWTC42()
    begin
        WMSBWExecuteTC(42);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure BWTC43()
    begin
        WMSBWExecuteTC(43);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure BWTC44()
    begin
        WMSBWExecuteTC(44);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure BWTC45()
    begin
        WMSBWExecuteTC(45);
    end;

    [Normal]
    local procedure WMSBWExecuteTC(EntryNo: Integer)
    var
        TestCase: Record "Whse. Test Case";
        TestscriptBW: Codeunit "BW Testscript";
    begin
        WMSBWInitialize();

        TestCase.Reset();
        TestCase.SetRange("Entry No.", EntryNo);
        TestCase.SetRange("Project Code", BW_Tok);

        if TestCase.FindFirst() then begin
            TestscriptBW.SetLastIteration(TestCase."Use Case No.", TestCase."Test Case No.", 0, 0, TestCase."Project Code");
            TestscriptBW.SetKeepUseCases(true);
            TestscriptBW.SetShowScriptResult(false);
            TestscriptBW.Run();
            RunManager.ValidateWMSBWRun(TestCase);
        end else
            Error(Text0001_Err, EntryNo, BW_Tok);
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

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure YesConfirmHandler(ConfirmMessage: Text[1024]; var Reply: Boolean)
    begin
        Reply := true;
    end;
}

