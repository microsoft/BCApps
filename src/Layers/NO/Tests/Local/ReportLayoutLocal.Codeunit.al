codeunit 141000 "Report Layout - Local"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Report]
    end;

    var
        Assert: Codeunit Assert;
        XFULLTxt: Label 'FULL';
        XWITHOUTTxt: Label 'WITHOUT';
        XHIGHTxt: Label 'HIGH';
        XLOWTxt: Label 'LOW';
        XOUTSIDETxt: Label 'OUTSIDE';
        XSERVVATTxt: Label 'SERVICE';
        XCUSTNOVATTxt: Label 'CUSTNOVAT';
        XCUSTHIGHTxt: Label 'CUSTHIGH';
        XCUSTLOWTxt: Label 'CUSTLOW';
        XVENDNOVATTxt: Label 'VENDNOVAT';
        XVENDHIGHTxt: Label 'VENDHIGH';
        XVENDLOWTxt: Label 'VENDLOW';
        LibraryVariableStorage: Codeunit "Library - Variable Storage";

    [Test]
    [HandlerFunctions('RHTrialBalancePreviousPeriod')]
    [Scope('OnPrem')]
    procedure TestTrialBalancePreviousPeriod()
    var
        FileMgt: Codeunit "File Management";
    begin
        // [FEATURE] [Trial Balance]
        // Execute
        REPORT.Run(REPORT::"Trial Balance/Previous Period");

        // Verify
        FileMgt.ServerFileExists(LibraryVariableStorage.DequeueText());
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VerifyDemoData_VATCodes()
    var
        VATReportingCode: Record "VAT Reporting Code";
    begin
        // [FEATURE] [VAT] [Trade Settlement] [DEMO]
        // [SCENARIO 168591] Demodata "VAT Reporting Code" list
        VerifyDemoDataVATCodePurch('0', VATReportingCode."Trade Settlement 2017 Box No."::" ", VATReportingCode."Reverse Charge Report Box No."::" ");
        VerifyDemoDataVATCodePurch('1', VATReportingCode."Trade Settlement 2017 Box No."::"14", VATReportingCode."Reverse Charge Report Box No."::" ");
        VerifyDemoDataVATCodePurch('11', VATReportingCode."Trade Settlement 2017 Box No."::"15", VATReportingCode."Reverse Charge Report Box No."::" ");
        VerifyDemoDataVATCodePurch('12', VATReportingCode."Trade Settlement 2017 Box No."::"15", VATReportingCode."Reverse Charge Report Box No."::" ");
        VerifyDemoDataVATCodePurch('13', VATReportingCode."Trade Settlement 2017 Box No."::"16", VATReportingCode."Reverse Charge Report Box No."::" ");
        VerifyDemoDataVATCodePurch('14', VATReportingCode."Trade Settlement 2017 Box No."::"17", VATReportingCode."Reverse Charge Report Box No."::" ");
        VerifyDemoDataVATCodePurch('15', VATReportingCode."Trade Settlement 2017 Box No."::"18", VATReportingCode."Reverse Charge Report Box No."::" ");
        VerifyDemoDataVATCodePurch('2', VATReportingCode."Trade Settlement 2017 Box No."::" ", VATReportingCode."Reverse Charge Report Box No."::" ");
        VerifyDemoDataVATCodePurch('21', VATReportingCode."Trade Settlement 2017 Box No."::" ", VATReportingCode."Reverse Charge Report Box No."::" ");
        VerifyDemoDataVATCodePurch('22', VATReportingCode."Trade Settlement 2017 Box No."::" ", VATReportingCode."Reverse Charge Report Box No."::" ");
        VerifyDemoDataVATCodePurch('23', VATReportingCode."Trade Settlement 2017 Box No."::" ", VATReportingCode."Reverse Charge Report Box No."::" ");
        VerifyDemoDataVATCodeSales('3', VATReportingCode."Trade Settlement 2017 Box No."::"3", VATReportingCode."Reverse Charge Report Box No."::" ");
        VerifyDemoDataVATCodeSales('31', VATReportingCode."Trade Settlement 2017 Box No."::"4", VATReportingCode."Reverse Charge Report Box No."::" ");
        VerifyDemoDataVATCodeSales('32', VATReportingCode."Trade Settlement 2017 Box No."::"4", VATReportingCode."Reverse Charge Report Box No."::" ");
        VerifyDemoDataVATCodeSales('33', VATReportingCode."Trade Settlement 2017 Box No."::"5", VATReportingCode."Reverse Charge Report Box No."::" ");
        VerifyDemoDataVATCodePurch('4', VATReportingCode."Trade Settlement 2017 Box No."::" ", VATReportingCode."Reverse Charge Report Box No."::" ");
        VerifyDemoDataVATCodeSales('5', VATReportingCode."Trade Settlement 2017 Box No."::"6", VATReportingCode."Reverse Charge Report Box No."::" ");
        VerifyDemoDataVATCodeSales('51', VATReportingCode."Trade Settlement 2017 Box No."::"7", VATReportingCode."Reverse Charge Report Box No."::" ");
        VerifyDemoDataVATCodeSales('52', VATReportingCode."Trade Settlement 2017 Box No."::"8", VATReportingCode."Reverse Charge Report Box No."::" ");
        VerifyDemoDataVATCodeSales('6', VATReportingCode."Trade Settlement 2017 Box No."::" ", VATReportingCode."Reverse Charge Report Box No."::" ");
        VerifyDemoDataVATCodeSales('7', VATReportingCode."Trade Settlement 2017 Box No."::" ", VATReportingCode."Reverse Charge Report Box No."::" ");
        VerifyDemoDataVATCodePurch('81', VATReportingCode."Trade Settlement 2017 Box No."::"9", VATReportingCode."Reverse Charge Report Box No."::"17");
        VerifyDemoDataVATCodePurch('82', VATReportingCode."Trade Settlement 2017 Box No."::"9", VATReportingCode."Reverse Charge Report Box No."::" ");
        VerifyDemoDataVATCodePurch('83', VATReportingCode."Trade Settlement 2017 Box No."::"10", VATReportingCode."Reverse Charge Report Box No."::"18");
        VerifyDemoDataVATCodePurch('84', VATReportingCode."Trade Settlement 2017 Box No."::"10", VATReportingCode."Reverse Charge Report Box No."::" ");
        VerifyDemoDataVATCodePurch('85', VATReportingCode."Trade Settlement 2017 Box No."::" ", VATReportingCode."Reverse Charge Report Box No."::" ");
        VerifyDemoDataVATCodePurch('86', VATReportingCode."Trade Settlement 2017 Box No."::"12", VATReportingCode."Reverse Charge Report Box No."::"17");
        VerifyDemoDataVATCodePurch('87', VATReportingCode."Trade Settlement 2017 Box No."::"12", VATReportingCode."Reverse Charge Report Box No."::" ");
        VerifyDemoDataVATCodePurch('88', VATReportingCode."Trade Settlement 2017 Box No."::"12", VATReportingCode."Reverse Charge Report Box No."::"17");
        VerifyDemoDataVATCodePurch('89', VATReportingCode."Trade Settlement 2017 Box No."::"12", VATReportingCode."Reverse Charge Report Box No."::" ");
        VerifyDemoDataVATCodePurch('91', VATReportingCode."Trade Settlement 2017 Box No."::"13", VATReportingCode."Reverse Charge Report Box No."::"14");
        VerifyDemoDataVATCodePurch('92', VATReportingCode."Trade Settlement 2017 Box No."::"14", VATReportingCode."Reverse Charge Report Box No."::" ");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VerifyDemoData_VATPostingSetup()
    begin
        // [FEATURE] [VAT] [Trade Settlement] [DEMO]
        // [SCENARIO 168591] Demodata "VAT Posting Setup" list
        VerifyDemoDataVATPostingSetup(XCUSTNOVATTxt, XWITHOUTTxt, '0', '84', '');
        VerifyDemoDataVATPostingSetup(XCUSTNOVATTxt, XHIGHTxt, '', '81', '81');
        VerifyDemoDataVATPostingSetup(XCUSTNOVATTxt, XOUTSIDETxt, '', '83', '83');
        VerifyDemoDataVATPostingSetup(XCUSTNOVATTxt, XLOWTxt, '', '82', '82');
        VerifyDemoDataVATPostingSetup(XCUSTHIGHTxt, XFULLTxt, '13', '52', '');
        VerifyDemoDataVATPostingSetup(XCUSTHIGHTxt, XWITHOUTTxt, '', '5', '');
        VerifyDemoDataVATPostingSetup(XCUSTHIGHTxt, XHIGHTxt, '3', '3', '');
        VerifyDemoDataVATPostingSetup(XCUSTHIGHTxt, XOUTSIDETxt, '', '52', '');
        VerifyDemoDataVATPostingSetup(XCUSTHIGHTxt, XLOWTxt, '', '33', '');
        VerifyDemoDataVATPostingSetup(XCUSTLOWTxt, XWITHOUTTxt, '', '5', '');
        VerifyDemoDataVATPostingSetup(XCUSTLOWTxt, XHIGHTxt, '', '31', '');
        VerifyDemoDataVATPostingSetup(XCUSTLOWTxt, XOUTSIDETxt, '', '52', '');
        VerifyDemoDataVATPostingSetup(XCUSTLOWTxt, XLOWTxt, '', '32', '');
        VerifyDemoDataVATPostingSetup(XVENDNOVATTxt, XWITHOUTTxt, '', '89', '');
        VerifyDemoDataVATPostingSetup(XVENDNOVATTxt, XHIGHTxt, '', '88', '88');
        VerifyDemoDataVATPostingSetup(XVENDNOVATTxt, XLOWTxt, '', '87', '');
        VerifyDemoDataVATPostingSetup(XVENDNOVATTxt, XSERVVATTxt, '14', '86', '86');
        VerifyDemoDataVATPostingSetup(XVENDHIGHTxt, XFULLTxt, '11', '', '15');
        VerifyDemoDataVATPostingSetup(XVENDHIGHTxt, XWITHOUTTxt, '', '', '13');
        VerifyDemoDataVATPostingSetup(XVENDHIGHTxt, XHIGHTxt, '1', '', '1');
        VerifyDemoDataVATPostingSetup(XVENDHIGHTxt, XLOWTxt, '', '', '1');
        VerifyDemoDataVATPostingSetup(XVENDLOWTxt, XWITHOUTTxt, '', '', '13');
        VerifyDemoDataVATPostingSetup(XVENDLOWTxt, XHIGHTxt, '', '', '11');
        VerifyDemoDataVATPostingSetup(XVENDLOWTxt, XLOWTxt, '', '', '12');
    end;

    local procedure VerifyDemoDataVATCodeSales(ExpectedCode: Code[10]; BoxNo: Option; ReverseChargeBoxNo: Option)
    var
        VATReportingCode: Record "VAT Reporting Code";
    begin
        VATReportingCode.Get(ExpectedCode);
        Assert.AreEqual(VATReportingCode."Test Gen. Posting Type"::" ", VATReportingCode."Test Gen. Posting Type", '');
        Assert.AreEqual(VATReportingCode."Gen. Posting Type"::Sale, VATReportingCode."Gen. Posting Type", '');
        Assert.AreEqual(BoxNo, VATReportingCode."Trade Settlement 2017 Box No.", '');
        Assert.AreEqual(ReverseChargeBoxNo, VATReportingCode."Reverse Charge Report Box No.", '');
    end;

    local procedure VerifyDemoDataVATCodePurch(ExpectedCode: Code[10]; BoxNo: Option; ReverseChargeBoxNo: Option)
    var
        VATReportingCode: Record "VAT Reporting Code";
    begin
        VATReportingCode.Get(ExpectedCode);
        Assert.AreEqual(VATReportingCode."Test Gen. Posting Type"::" ", VATReportingCode."Test Gen. Posting Type", '');
        Assert.AreEqual(VATReportingCode."Gen. Posting Type"::Purchase, VATReportingCode."Gen. Posting Type", '');
        Assert.AreEqual(BoxNo, VATReportingCode."Trade Settlement 2017 Box No.", '');
        Assert.AreEqual(ReverseChargeBoxNo, VATReportingCode."Reverse Charge Report Box No.", '');
    end;

    local procedure VerifyDemoDataVATPostingSetup(VATBusPostingGroupCode: Code[10]; VATProdPostingGroupCode: Code[10]; VATCode: Code[10]; SalesVATReportingCode: Code[10]; PurchaseVATReportingCode: Code[10])
    var
        VATPostingSetup: Record "VAT Posting Setup";
    begin
        VATPostingSetup.Get(VATBusPostingGroupCode, VATProdPostingGroupCode);
        Assert.AreEqual(VATCode, VATPostingSetup."VAT Number", '');
        Assert.AreEqual(SalesVATReportingCode, VATPostingSetup."Sale VAT Reporting Code", '');
        Assert.AreEqual(PurchaseVATReportingCode, VATPostingSetup."Purch. VAT Reporting Code", '');
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure RHTrialBalancePreviousPeriod(var TrialBalancePreviousPeriod: TestRequestPage "Trial Balance/Previous Period")
    var
        FileMgt: Codeunit "File Management";
        FileName: Text;
    begin
        TrialBalancePreviousPeriod."G/L Account".SetFilter("Date Filter", Format(CalcDate('<-1Y>', WorkDate())));
        FileName := FileMgt.ServerTempFileName('pdf');
        LibraryVariableStorage.Enqueue(FileName);
        TrialBalancePreviousPeriod.SaveAsPdf(FileName);
    end;
}

