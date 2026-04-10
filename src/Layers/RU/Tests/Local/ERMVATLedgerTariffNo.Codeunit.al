codeunit 147133 "ERM VAT Ledger Tariff No."
{
    // // [FEATURE] [UT] [VAT Ledger] [Tariff No.]

    TestPermissions = NonRestrictive;
    Subtype = Test;
    Permissions = tabledata "VAT Ledger Line" = d;

    var
        LibraryVATLedger: Codeunit "Library - VAT Ledger";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibraryUtility: Codeunit "Library - Utility";
        Assert: Codeunit Assert;
        DIFFERENTTxt: Label 'DIFFERENT';
        IsInitialized: Boolean;

    [Test]
    [Scope('OnPrem')]
    procedure LookupPurchaseVATLedgerLine_EmptyTariffNo()
    var
        VATLedgerLine: Record "VAT Ledger Line";
        VATLedgerLineTariffNo: TestPage "VAT Ledger Line Tariff No.";
        VendorNo: Code[20];
    begin
        // [FEATURE] [Purchase] [UI]
        // [SCENARIO 231729] Lookup purchase "VAT Ledger Line"."Tariff No." field in case of empty value
        Initialize();

        // [GIVEN] Purchase VAT Ledger Line with "Tariff No." = ""
        LibraryVATLedger.MockVendorVATLedgerLine(VATLedgerLine, VendorNo);

        // [WHEN] Lookup "Tariff No." field
        LookupPurchaseVATLedgerLineTariffNoField(VATLedgerLineTariffNo, VATLedgerLine);

        // [THEN] Page "VAT Ledger Line Tariff No." has been opened and "Tariff No." = ""
        VATLedgerLineTariffNo."Tariff No.".AssertEquals('');
        Assert.IsFalse(VATLedgerLineTariffNo.Editable(), '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure LookupPurchaseVATLedgerLine_Single()
    var
        VATLedgerLine: Record "VAT Ledger Line";
        VATLedgerLineTariffNo: TestPage "VAT Ledger Line Tariff No.";
        TariffNo: Code[20];
    begin
        // [FEATURE] [Purchase] [UI]
        // [SCENARIO 231729] Lookup purchase "VAT Ledger Line"."Tariff No." field in case of single value
        Initialize();

        // [GIVEN] Purchase VAT Ledger Line with single "Tariff No." = "X"
        LibraryVATLedger.MockVendorVATLedgerLineWithTariffNo(VATLedgerLine, TariffNo);

        // [WHEN] Lookup "Tariff No." field
        LookupPurchaseVATLedgerLineTariffNoField(VATLedgerLineTariffNo, VATLedgerLine);

        // [THEN] Page "VAT Ledger Line Tariff No." has been opened and "Tariff No." = "X"
        VATLedgerLineTariffNo."Tariff No.".AssertEquals(TariffNo);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure LookupPurchaseVATLedgerLine_Multiple()
    var
        VATLedgerLine: Record "VAT Ledger Line";
        VATLedgerLineTariffNo: TestPage "VAT Ledger Line Tariff No.";
        TariffNo: array[2] of Code[20];
    begin
        // [FEATURE] [Purchase] [UI]
        // [SCENARIO 231729] Lookup purchase "VAT Ledger Line"."Tariff No." field in case of multiple values
        Initialize();

        // [GIVEN] Purchase VAT Ledger Line with several "Tariff No." = "X";"Y"
        MockVendorVATLedgerLineWithTwoTariffNo(VATLedgerLine, TariffNo);

        // [WHEN] Lookup "Tariff No." field
        LookupPurchaseVATLedgerLineTariffNoField(VATLedgerLineTariffNo, VATLedgerLine);

        // [THEN] Page "VAT Ledger Line Tariff No." has been opened
        // [THEN] There are two records, one with "Tariff No." = "X", another with "Tariff No." = "Y"
        VerifyTwoVATLedgerLineTariffNoOnPage(VATLedgerLine, VATLedgerLineTariffNo);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure LookupSalesVATLedgerLine_EmptyTariffNo()
    var
        VATLedgerLine: Record "VAT Ledger Line";
        VATLedgerLineTariffNo: TestPage "VAT Ledger Line Tariff No.";
        CustomerNo: Code[20];
    begin
        // [FEATURE] [Sales] [UI]
        // [SCENARIO 231729] Lookup sales "VAT Ledger Line"."Tariff No." field in case of empty value
        Initialize();

        // [GIVEN] Sales VAT Ledger Line with "Tariff No." = ""
        LibraryVATLedger.MockCustomerVATLedgerLine(VATLedgerLine, CustomerNo);

        // [WHEN] Lookup "Tariff No." field
        LookupSalesVATLedgerLineTariffNoField(VATLedgerLineTariffNo, VATLedgerLine);

        // [THEN] Page "VAT Ledger Line Tariff No." has been opened and "Tariff No." = ""
        VATLedgerLineTariffNo."Tariff No.".AssertEquals('');
        Assert.IsFalse(VATLedgerLineTariffNo.Editable(), '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure LookupSalesVATLedgerLine_Single()
    var
        VATLedgerLine: Record "VAT Ledger Line";
        VATLedgerLineTariffNo: TestPage "VAT Ledger Line Tariff No.";
        TariffNo: Code[20];
    begin
        // [FEATURE] [Sales] [UI]
        // [SCENARIO 231729] Lookup sales "VAT Ledger Line"."Tariff No." field
        Initialize();

        // [GIVEN] Sales VAT Ledger Line with "Tariff No." = "X"
        LibraryVATLedger.MockCustomerVATLedgerLineWithTariffNo(VATLedgerLine, TariffNo);

        // [WHEN] Lookup "Tariff No." field
        LookupSalesVATLedgerLineTariffNoField(VATLedgerLineTariffNo, VATLedgerLine);

        // [THEN] Page "VAT Ledger Line Tariff No." has been opened and "Tariff No." = "X"
        VATLedgerLineTariffNo."Tariff No.".AssertEquals(TariffNo);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure LookupSalesVATLedgerLine_Multiple()
    var
        VATLedgerLine: Record "VAT Ledger Line";
        VATLedgerLineTariffNo: TestPage "VAT Ledger Line Tariff No.";
        TariffNo: array[2] of Code[20];
    begin
        // [FEATURE] [Sales] [UI]
        // [SCENARIO 231729] Lookup sales "VAT Ledger Line"."Tariff No." field in case of multiple values
        Initialize();

        // [GIVEN] Sales VAT Ledger Line with several "Tariff No." = "X";"Y"
        MockCustomerVATLedgerLineWithTwoTariffNo(VATLedgerLine, TariffNo);

        // [WHEN] Lookup "Tariff No." field
        LookupSalesVATLedgerLineTariffNoField(VATLedgerLineTariffNo, VATLedgerLine);

        // [THEN] Page "VAT Ledger Line Tariff No." has been opened
        // [THEN] There are two records, one with "Tariff No." = "X", another with "Tariff No." = "Y"
        VerifyTwoVATLedgerLineTariffNoOnPage(VATLedgerLine, VATLedgerLineTariffNo);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DeletePurchaseVATLedgerLine_Single()
    var
        VATLedgerLine: Record "VAT Ledger Line";
        VATLedgerLineTariffNo: Record "VAT Ledger Line Tariff No.";
        TariffNo: Code[20];
    begin
        // [FEATURE] [Purchase]
        // [SCENARIO 231729] Delete purchase "VAT Ledger Line" record with "Tariff No." value
        Initialize();

        // [GIVEN] Purchase VAT Ledger Line with "Tariff No." = "X"
        LibraryVATLedger.MockVendorVATLedgerLineWithTariffNo(VATLedgerLine, TariffNo);
        // [GIVEN] There is a TAB 12412 "VAT Ledger Line Tariff No." record with "Tariff No." = "X"
        FilterVATLedgerLineTariffNo(VATLedgerLineTariffNo, VATLedgerLine);
        Assert.RecordIsNotEmpty(VATLedgerLineTariffNo);

        // [WHEN] Delete the purchase VAT Ledger Line
        VATLedgerLine.Delete(true);

        // [THEN] There is no TAB 12412 "VAT Ledger Line Tariff No." record related to the given purchase VAT Ledger Line
        Assert.RecordIsEmpty(VATLedgerLineTariffNo);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DeletePurchaseVATLedgerLine_Multiple()
    var
        VATLedgerLine: Record "VAT Ledger Line";
        VATLedgerLineTariffNo: Record "VAT Ledger Line Tariff No.";
        TariffNo: array[2] of Code[20];
    begin
        // [FEATURE] [Purchase]
        // [SCENARIO 231729] Delete purchase "VAT Ledger Line" record with several "Tariff No." values
        Initialize();

        // [GIVEN] Purchase VAT Ledger Line with several "Tariff No." values
        MockVendorVATLedgerLineWithTwoTariffNo(VATLedgerLine, TariffNo);
        // [GIVEN] There are several TAB 12412 "VAT Ledger Line Tariff No." records related to the purchase VAT Ledger Line
        FilterVATLedgerLineTariffNo(VATLedgerLineTariffNo, VATLedgerLine);
        Assert.RecordCount(VATLedgerLineTariffNo, 2);

        // [WHEN] Delete the purchase VAT Ledger Line
        VATLedgerLine.Delete(true);

        // [THEN] There is no TAB 12412 "VAT Ledger Line Tariff No." record related to the given purchase VAT Ledger Line
        Assert.RecordIsEmpty(VATLedgerLineTariffNo);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DeleteSalesVATLedgerLine_Single()
    var
        VATLedgerLine: Record "VAT Ledger Line";
        VATLedgerLineTariffNo: Record "VAT Ledger Line Tariff No.";
        TariffNo: Code[20];
    begin
        // [FEATURE] [Sales]
        // [SCENARIO 231729] Delete sales "VAT Ledger Line" record with "Tariff No." value
        Initialize();

        // [GIVEN] Sales VAT Ledger Line with "Tariff No." = "X"
        LibraryVATLedger.MockCustomerVATLedgerLineWithTariffNo(VATLedgerLine, TariffNo);
        // [GIVEN] There is a TAB 12412 "VAT Ledger Line Tariff No." record with "Tariff No." = "X"
        FilterVATLedgerLineTariffNo(VATLedgerLineTariffNo, VATLedgerLine);
        Assert.RecordIsNotEmpty(VATLedgerLineTariffNo);

        // [WHEN] Delete the purchase VAT Ledger Line
        VATLedgerLine.Delete(true);

        // [THEN] There is no TAB 12412 "VAT Ledger Line Tariff No." record related to the given sales VAT Ledger Line
        Assert.RecordIsEmpty(VATLedgerLineTariffNo);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DeleteSalesVATLedgerLine_Multiple()
    var
        VATLedgerLine: Record "VAT Ledger Line";
        VATLedgerLineTariffNo: Record "VAT Ledger Line Tariff No.";
        TariffNo: array[2] of Code[20];
    begin
        // [FEATURE] [Sales]
        // [SCENARIO 231729] Delete sales "VAT Ledger Line" record with several "Tariff No." values
        Initialize();

        // [GIVEN] Sales VAT Ledger Line with several "Tariff No." values
        MockCustomerVATLedgerLineWithTwoTariffNo(VATLedgerLine, TariffNo);
        // [GIVEN] There are several TAB 12412 "VAT Ledger Line Tariff No." records related to the sales VAT Ledger Line
        FilterVATLedgerLineTariffNo(VATLedgerLineTariffNo, VATLedgerLine);
        Assert.RecordCount(VATLedgerLineTariffNo, 2);

        // [WHEN] Delete the sales VAT Ledger Line
        VATLedgerLine.Delete(true);

        // [THEN] There is no TAB 12412 "VAT Ledger Line Tariff No." record related to the given sales VAT Ledger Line
        Assert.RecordIsEmpty(VATLedgerLineTariffNo);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VATLedgerMgt_InsertVATLedgerLineTariffNoList_WithoutTariffNo()
    var
        VATLedgerLine: Record "VAT Ledger Line";
        VATLedgerLineTariffNo: Record "VAT Ledger Line Tariff No.";
        VATLedgerMgt: Codeunit "VAT Ledger Management";
        CustomerNo: Code[20];
        DocumentNo: Code[20];
    begin
        // [SCENARIO 231729] COD 12423 "VAT Ledger Management".InsertVATLedgerLineTariffNoList() for a document without "Tariff No."
        Initialize();

        // [GIVEN] Posted document "D" without "Tariff No."
        DocumentNo := LibraryUtility.GenerateGUID();
        LibraryVATLedger.MockCustomerValueEntryWithTariffNo(CustomerNo, DocumentNo, '');

        // [GIVEN] VAT Ledger Line
        LibraryVATLedger.MockCustomerVATLedgerLine(VATLedgerLine, CustomerNo);

        // [WHEN] Run COD 12423 "VAT Ledger Management".InsertVATLedgerLineTariffNoList() for the given VAT Ledger Line using "Origin. Document No." = "D"
        VATLedgerLine."Origin. Document No." := DocumentNo;
        VATLedgerMgt.InsertVATLedgerLineTariffNoList(VATLedgerLine);

        // [THEN] "VAT Ledger Line"."Tariff No." = ""
        VATLedgerLine.Find();
        Assert.AreEqual('', VATLedgerLine."Tariff No.", VATLedgerLine.FieldCaption("Tariff No."));

        // [THEN] There is no related "VAT Ledger Line Tariff No." record
        FilterVATLedgerLineTariffNo(VATLedgerLineTariffNo, VATLedgerLine);
        Assert.RecordIsEmpty(VATLedgerLineTariffNo);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VATLedgerMgt_InsertVATLedgerLineTariffNoList_Single()
    var
        VATLedgerLine: Record "VAT Ledger Line";
        VATLedgerMgt: Codeunit "VAT Ledger Management";
        CustomerNo: Code[20];
        DocumentNo: Code[20];
        TariffNo: Code[20];
    begin
        // [SCENARIO 231729] COD 12423 "VAT Ledger Management".InsertVATLedgerLineTariffNoList() for a single "Tariff No." case
        Initialize();

        // [GIVEN] Posted document "D" with item tracking "Tariff No." = "X"
        // [GIVEN] VAT Ledger Line
        LibraryVATLedger.MockCustomerVATLedgerLine(VATLedgerLine, CustomerNo);
        DocumentNo := LibraryVATLedger.MockSalesInvHeader(CustomerNo, '');
        TariffNo := LibraryVATLedger.MockTariffNo();
        LibraryVATLedger.MockCustomerValueEntryWithTariffNo(CustomerNo, DocumentNo, TariffNo);

        // [WHEN] Run COD 12423 "VAT Ledger Management".InsertVATLedgerLineTariffNoList() for the given VAT Ledger Line using "Origin. Document No." = "D"
        VATLedgerLine."Origin. Document No." := DocumentNo;
        VATLedgerMgt.InsertVATLedgerLineTariffNoList(VATLedgerLine);

        // [THEN] "VAT Ledger Line"."Tariff No." = "X"
        VATLedgerLine.Find();
        Assert.AreEqual(TariffNo, VATLedgerLine."Tariff No.", VATLedgerLine.FieldCaption("Tariff No."));

        // [THEN] "VAT Ledger Line Tariff No." record has been created with "Tariff No." = "X"
        VerifyOneVATLedgerLineTariffNo(VATLedgerLine, TariffNo);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VATLedgerMgt_InsertVATLedgerLineTariffNoList_Multiple()
    var
        VATLedgerLine: Record "VAT Ledger Line";
        VATLedgerMgt: Codeunit "VAT Ledger Management";
        CustomerNo: Code[20];
        DocumentNo: Code[20];
        TariffNo: array[2] of Code[20];
    begin
        // [SCENARIO 231729] COD 12423 "VAT Ledger Management".InsertVATLedgerLineTariffNoList() for a multiple "Tariff No." case
        Initialize();

        // [GIVEN] Posted document "D" with two item tracking "Tariff No." = "X";"Y"
        // [GIVEN] VAT Ledger Line
        LibraryVATLedger.MockCustomerVATLedgerLine(VATLedgerLine, CustomerNo);
        DocumentNo := LibraryVATLedger.MockSalesInvHeader(CustomerNo, '');
        TariffNo[1] := LibraryVATLedger.MockTariffNo();
        LibraryVATLedger.MockCustomerValueEntryWithTariffNo(CustomerNo, DocumentNo, TariffNo[1]);
        TariffNo[2] := LibraryVATLedger.MockTariffNo();
        LibraryVATLedger.MockCustomerValueEntryWithTariffNo(CustomerNo, DocumentNo, TariffNo[2]);

        // [WHEN] Run COD 12423 "VAT Ledger Management".InsertVATLedgerLineTariffNoList() for the given VAT Ledger Line using "Origin. Document No." = "D"
        VATLedgerLine."Origin. Document No." := DocumentNo;
        VATLedgerMgt.InsertVATLedgerLineTariffNoList(VATLedgerLine);

        // [THEN] "VAT Ledger Line"."Tariff No." = "DIFFERENT" (const text)
        VATLedgerLine.Find();
        Assert.AreEqual(DIFFERENTTxt, VATLedgerLine."Tariff No.", VATLedgerLine.FieldCaption("Tariff No."));

        // [THEN] There are two related "VAT Ledger Line Tariff No." records have been created, one with "Tariff No." = "X", another with "Tariff No." = "Y"
        VerifyTwoVATLedgerLineTariffNo(VATLedgerLine, TariffNo);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VATLedgerMgt_InsertVATLedgerLineTariffNoList_Multiple_TheSameTariffNoValue()
    var
        VATLedgerLine: Record "VAT Ledger Line";
        VATLedgerMgt: Codeunit "VAT Ledger Management";
        CustomerNo: Code[20];
        DocumentNo: Code[20];
        TariffNo: Code[20];
    begin
        // [SCENARIO 231729] COD 12423 "VAT Ledger Management".InsertVATLedgerLineTariffNoList() for a multiple "Tariff No." having the same value
        Initialize();

        // [GIVEN] Posted document "D" with two item lines having the same tracking "Tariff No." = "X"
        // [GIVEN] VAT Ledger Line
        LibraryVATLedger.MockCustomerVATLedgerLine(VATLedgerLine, CustomerNo);
        DocumentNo := LibraryVATLedger.MockSalesInvHeader(CustomerNo, '');
        TariffNo := LibraryVATLedger.MockTariffNo();
        LibraryVATLedger.MockCustomerValueEntryWithTariffNo(CustomerNo, DocumentNo, TariffNo);
        LibraryVATLedger.MockCustomerValueEntryWithTariffNo(CustomerNo, DocumentNo, TariffNo);

        // [WHEN] Run COD 12423 "VAT Ledger Management".InsertVATLedgerLineTariffNoList() for the given VAT Ledger Line using "Origin. Document No." = "D"
        VATLedgerLine."Origin. Document No." := DocumentNo;
        VATLedgerMgt.InsertVATLedgerLineTariffNoList(VATLedgerLine);

        // [THEN] "VAT Ledger Line"."Tariff No." = "X"
        VATLedgerLine.Find();
        Assert.AreEqual(TariffNo, VATLedgerLine."Tariff No.", VATLedgerLine.FieldCaption("Tariff No."));

        // [THEN] One "VAT Ledger Line Tariff No." record has been created with "Tariff No." = "X"
        VerifyOneVATLedgerLineTariffNo(VATLedgerLine, TariffNo);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VATLedgerMgt_InsertVATLedgerLineTariffNoList_Multiple_CombinedValues()
    var
        VATLedgerLine: Record "VAT Ledger Line";
        VATLedgerMgt: Codeunit "VAT Ledger Management";
        CustomerNo: Code[20];
        DocumentNo: Code[20];
        TariffNo: array[2] of Code[20];
        i: Integer;
    begin
        // [SCENARIO 231729] COD 12423 "VAT Ledger Management".InsertVATLedgerLineTariffNoList() for a multiple "Tariff No." having the same values and different values
        Initialize();

        // [GIVEN] Posted document "D" with two item lines having the same tracking "Tariff No." = "X" and two item lines having the same tracking "Tariff No." = "Y"
        // [GIVEN] VAT Ledger Line
        LibraryVATLedger.MockCustomerVATLedgerLine(VATLedgerLine, CustomerNo);
        DocumentNo := LibraryVATLedger.MockSalesInvHeader(CustomerNo, '');
        for i := 1 to ArrayLen(TariffNo) do begin
            TariffNo[i] := LibraryVATLedger.MockTariffNo();
            LibraryVATLedger.MockCustomerValueEntryWithTariffNo(CustomerNo, DocumentNo, TariffNo[i]);
            LibraryVATLedger.MockCustomerValueEntryWithTariffNo(CustomerNo, DocumentNo, TariffNo[i]);
        end;

        // [WHEN] Run COD 12423 "VAT Ledger Management".InsertVATLedgerLineTariffNoList() for the given VAT Ledger Line using "Origin. Document No." = "D"
        VATLedgerLine."Origin. Document No." := DocumentNo;
        VATLedgerMgt.InsertVATLedgerLineTariffNoList(VATLedgerLine);

        // [THEN] "VAT Ledger Line"."Tariff No." = "DIFFERENT" (const text)
        VATLedgerLine.Find();
        Assert.AreEqual(DIFFERENTTxt, VATLedgerLine."Tariff No.", VATLedgerLine.FieldCaption("Tariff No."));

        // [THEN] There are two related "VAT Ledger Line Tariff No." records have been created, one with "Tariff No." = "X", another with "Tariff No." = "Y"
        VerifyTwoVATLedgerLineTariffNo(VATLedgerLine, TariffNo);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VATLedgerMgt_DeleteVATLedgerLines()
    var
        VATLedger: Record "VAT Ledger";
        DummyVATLedgerLine: Record "VAT Ledger Line";
        DummyVATLedgerLineTariffNo: Record "VAT Ledger Line Tariff No.";
        VATLedgerMgt: Codeunit "VAT Ledger Management";
    begin
        // [SCENARIO 231729] COD 12423 "VAT Ledger Management".DeleteVATLedgerLines() deletes both normal and add. sheet VAT Ledger Lines
        Initialize();

        // [GIVEN] VAT Ledger
        // [GIVEN] VAT Ledger Line with "Tariff No." value and "Additional Sheet" = FALSE
        // [GIVEN] VAT Ledger Line with "Tariff No." value and "Additional Sheet" = TRUE
        MockVATLedgerWithTwoLines(VATLedger);

        // [WHEN] Run COD 12423 "VAT Ledger Management".DeleteVATLedgerLines() for the given VAT Ledger
        VATLedgerMgt.DeleteVATLedgerLines(VATLedger);

        // [THEN] Both VAT Ledger Line's with linked "VAT Ledger Line Tariff No."s have been deleted
        DummyVATLedgerLine.SetRange(Type, VATLedger.Type);
        DummyVATLedgerLine.SetRange(Code, VATLedger.Code);
        Assert.RecordIsEmpty(DummyVATLedgerLine);

        DummyVATLedgerLineTariffNo.SetRange(Type, VATLedger.Type);
        DummyVATLedgerLineTariffNo.SetRange(Code, VATLedger.Code);
        Assert.RecordIsEmpty(DummyVATLedgerLineTariffNo);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VATLedgerMgt_DeleteVATLedgerAddSheetLines()
    var
        VATLedger: Record "VAT Ledger";
        VATLedgerLine: Record "VAT Ledger Line";
        VATLedgerLineTariffNo: Record "VAT Ledger Line Tariff No.";
        VATLedgerMgt: Codeunit "VAT Ledger Management";
    begin
        // [SCENARIO 231729] COD 12423 "VAT Ledger Management".DeleteVATLedgerLines() deletes only add. sheet VAT Ledger Lines

        // [GIVEN] VAT Ledger
        // [GIVEN] VAT Ledger Line with "Tariff No." value and "Additional Sheet" = FALSE
        // [GIVEN] VAT Ledger Line with "Tariff No." value and "Additional Sheet" = TRUE
        MockVATLedgerWithTwoLines(VATLedger);

        // [WHEN] Run COD 12423 "VAT Ledger Management".DeleteVATLedgerLines() for the given VAT Ledger
        VATLedgerMgt.DeleteVATLedgerAddSheetLines(VATLedger);

        // [THEN] VAT Ledger Line with "Additional Sheet" = TRUE has been deleted
        // [THEN] VAT Ledger Line with "Additional Sheet" = FALSE is not deleted
        VATLedgerLine.SetRange(Type, VATLedger.Type);
        VATLedgerLine.SetRange(Code, VATLedger.Code);
        VATLedgerLine.SetRange("Additional Sheet", true);
        Assert.RecordIsEmpty(VATLedgerLine);

        VATLedgerLine.SetRange("Additional Sheet", false);
        Assert.RecordCount(VATLedgerLine, 1);
        VATLedgerLine.FindFirst();

        VATLedgerLineTariffNo.SetRange(Type, VATLedger.Type);
        VATLedgerLineTariffNo.SetRange(Code, VATLedger.Code);
        Assert.RecordCount(VATLedgerLineTariffNo, 1);
        VATLedgerLineTariffNo.FindFirst();

        Assert.AreEqual(VATLedgerLine."Line No.", VATLedgerLineTariffNo."Line No.", VATLedgerLineTariffNo.FieldCaption("Line No."));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CreateVATPurchaseLedger_Single()
    var
        VATLedger: Record "VAT Ledger";
        VATLedgerLine: Record "VAT Ledger Line";
        VATLedgerLineTariffNo: Record "VAT Ledger Line Tariff No.";
        VendorNo: Code[20];
        DocumentNo: Code[20];
        TariffNo: Code[20];
    begin
        // [FEATURE] [Purchase]
        // [SCENARIO 231729] REP 12455 "Create VAT Purchase Ledger" creates one "VAT Ledger Line" record and
        // [SCENARIO 231729] one related "VAT Ledger Line Tariff No." record for a purchase document with a single "Tariff No." value
        Initialize();

        // [GIVEN] Posted purchase document: "Vendor No." = "V", "Document No." = "D", "Tariff No." = "X"
        MockPostedPurchaseInvoiceWithTariffNo(VendorNo, DocumentNo, TariffNo);
        // [GIVEN] A new VAT Purchase Ledger
        LibraryVATLedger.MockVATLedger(VATLedger, VATLedger.Type::Purchase);

        // [WHEN] Perform "Create Ledger" action for a new VAT Purchase Ledger with "Vendor Filter" = "V"
        LibraryVATLedger.RunCreateVATPurchaseLedgerReport(VATLedger, VendorNo);

        // [THEN] A new VAT Ledger Line has been created:
        // [THEN] "Origin. Document No."= "D"
        // [THEN] "Document No."= "D"
        // [THEN] "Tariff No." = ""
        LibraryVATLedger.FindVATLedgerLine(VATLedgerLine, VATLedger);
        VerifyVATLedgerLine(VATLedgerLine, DocumentNo, '', false);

        // [THEN] There is no TAB 12412 "VAT Ledger Line Tariff No." record related to the given purchase VAT Ledger Line
        FilterVATLedgerLineTariffNo(VATLedgerLineTariffNo, VATLedgerLine);
        Assert.RecordIsEmpty(VATLedgerLineTariffNo);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CreateVATPurchaseLedger_Multiple()
    var
        VATLedger: Record "VAT Ledger";
        VATLedgerLine: Record "VAT Ledger Line";
        VATLedgerLineTariffNo: Record "VAT Ledger Line Tariff No.";
        VendorNo: Code[20];
        DocumentNo: Code[20];
        TariffNo: array[2] of Code[20];
    begin
        // [FEATURE] [Purchase]
        // [SCENARIO 231729] REP 12455 "Create VAT Purchase Ledger" creates one "VAT Ledger Line" record and
        // [SCENARIO 231729] several related "VAT Ledger Line Tariff No." records for a purchase document with several "Tariff No." values
        Initialize();

        // [GIVEN] Posted purchase document: "Vendor No." = "V", "Document No." = "D", two "Tariff No." = "X";"Y"
        MockPostedPurchaseInvoiceWithTwoTariffNo(VendorNo, DocumentNo, TariffNo);
        // [GIVEN] A new VAT Purchase Ledger
        LibraryVATLedger.MockVATLedger(VATLedger, VATLedger.Type::Purchase);

        // [WHEN] Perform "Create Ledger" action for a new VAT Purchase Ledger with "Vendor Filter" = "V"
        LibraryVATLedger.RunCreateVATPurchaseLedgerReport(VATLedger, VendorNo);

        // [THEN] A new VAT Ledger Line has been created:
        // [THEN] "Origin. Document No."= "D"
        // [THEN] "Document No."= "D"
        // [THEN] "Tariff No." = ""
        LibraryVATLedger.FindVATLedgerLine(VATLedgerLine, VATLedger);
        VerifyVATLedgerLine(VATLedgerLine, DocumentNo, '', false);

        // [THEN] There is no TAB 12412 "VAT Ledger Line Tariff No." record related to the given purchase VAT Ledger Line
        FilterVATLedgerLineTariffNo(VATLedgerLineTariffNo, VATLedgerLine);
        Assert.RecordIsEmpty(VATLedgerLineTariffNo);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CreateVATPurchaseLedger_ClearsLines()
    var
        VATLedger: Record "VAT Ledger";
        VATLedgerLine: Record "VAT Ledger Line";
        VATLedgerLineTariffNo: Record "VAT Ledger Line Tariff No.";
        VendorNo: Code[20];
        DocumentNo: Code[20];
        TariffNo: Code[20];
    begin
        // [FEATURE] [Purchase]
        // [SCENARIO 231729] REP 12455 "Create VAT Purchase Ledger" clears existing "VAT Ledger Line" and "VAT Ledger Line Tariff No." records
        Initialize();

        // [GIVEN] Posted purchase document
        MockPostedPurchaseInvoiceWithTariffNo(VendorNo, DocumentNo, TariffNo);
        // [GIVEN] A new VAT Purchase Ledger
        LibraryVATLedger.MockVATLedger(VATLedger, VATLedger.Type::Purchase);
        // [GIVEN] Perform "Create Ledger" action for a new VAT Purchase Ledger
        LibraryVATLedger.RunCreateVATPurchaseLedgerReport(VATLedger, VendorNo);
        LibraryVATLedger.FindVATLedgerLine(VATLedgerLine, VATLedger);

        // [WHEN] Perform "Create Ledger" action again
        LibraryVATLedger.RunCreateVATPurchaseLedgerReport(VATLedger, VendorNo);

        // [THEN] There is one "VAT Ledger Line"
        Assert.RecordCount(VATLedgerLine, 1);

        // [THEN] There is one related "VAT Ledger Line Tariff No."
        FilterVATLedgerLineTariffNo(VATLedgerLineTariffNo, VATLedgerLine);
        Assert.RecordCount(VATLedgerLine, 1);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CreateVATSalesLedger_Single()
    var
        VATLedger: Record "VAT Ledger";
        VATLedgerLine: Record "VAT Ledger Line";
        CustomerNo: Code[20];
        DocumentNo: Code[20];
        TariffNo: Code[20];
    begin
        // [FEATURE] [Sales]
        // [SCENARIO 231729] REP 12456 "Create VAT Sales Ledger" creates one "VAT Ledger Line" record and
        // [SCENARIO 231729] one related "VAT Ledger Line Tariff No." record for a sales document with a single "Tariff No." value
        Initialize();

        // [GIVEN] Posted sales document: "Customer No." = "C", "Document No." = "D", "Tariff No." = "X"
        MockPostedSalesInvoiceWithTariffNo(CustomerNo, DocumentNo, TariffNo);
        // [GIVEN] A new VAT Sales Ledger
        LibraryVATLedger.MockVATLedger(VATLedger, VATLedger.Type::Sales);

        // [WHEN] Perform "Create Ledger" action for a new VAT Sales Ledger with "Csutomer Filter" = "C"
        LibraryVATLedger.RunCreateVATSalesLedgerReport(VATLedger, CustomerNo);

        // [THEN] A new VAT Ledger Line has been created:
        // [THEN] "Origin. Document No."= "D"
        // [THEN] "Document No."= "D"
        // [THEN] "Tariff No." = "X"
        LibraryVATLedger.FindVATLedgerLine(VATLedgerLine, VATLedger);
        VerifyVATLedgerLine(VATLedgerLine, DocumentNo, TariffNo, false);

        // [THEN] There is a related "VAT Ledger Line Tariff No." record with "Tariff No." = "X"
        VerifyVATLedgerLineTariffNo(VATLedgerLine, TariffNo);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CreateVATSalesLedger_Multiple()
    var
        VATLedger: Record "VAT Ledger";
        VATLedgerLine: Record "VAT Ledger Line";
        CustomerNo: Code[20];
        DocumentNo: Code[20];
        TariffNo: array[2] of Code[20];
    begin
        // [FEATURE] [Sales]
        // [SCENARIO 231729] REP 12456 "Create VAT Sales Ledger" creates one "VAT Ledger Line" record and
        // [SCENARIO 231729] several related "VAT Ledger Line Tariff No." records for a sales document with several "Tariff No." values
        Initialize();

        // [GIVEN] Posted sales document: "Customer No." = "C", "Document No." = "D", two "Tariff No." = "X";"Y"
        MockPostedSalesInvoiceWithTwoTariffNo(CustomerNo, DocumentNo, TariffNo);
        // [GIVEN] A new VAT Sales Ledger
        LibraryVATLedger.MockVATLedger(VATLedger, VATLedger.Type::Sales);

        // [WHEN] Perform "Create Ledger" action for a new VAT Sales Ledger with "Csutomer Filter" = "C"
        LibraryVATLedger.RunCreateVATSalesLedgerReport(VATLedger, CustomerNo);

        // [THEN] A new VAT Ledger Line has been created:
        // [THEN] "Origin. Document No."= "D"
        // [THEN] "Document No."= "D"
        // [THEN] "Tariff No." = "DIFFERENT" (const text)
        LibraryVATLedger.FindVATLedgerLine(VATLedgerLine, VATLedger);
        VerifyVATLedgerLine(VATLedgerLine, DocumentNo, DIFFERENTTxt, false);

        // [THEN] There are two related "VAT Ledger Line Tariff No." records, one with "Tariff No." = "X", another with "Tariff No." = "Y"
        VerifyTwoVATLedgerLineTariffNo(VATLedgerLine, TariffNo);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CreateVATSalesLedger_ClearLines()
    var
        VATLedger: Record "VAT Ledger";
        VATLedgerLine: Record "VAT Ledger Line";
        VATLedgerLineTariffNo: Record "VAT Ledger Line Tariff No.";
        CustomerNo: Code[20];
        DocumentNo: Code[20];
        TariffNo: Code[20];
    begin
        // [FEATURE] [Sales]
        // [SCENARIO 231729] REP 12456 "Create VAT Sales Ledger" clears existing "VAT Ledger Line" and "VAT Ledger Line Tariff No." records
        Initialize();

        // [GIVEN] Posted sales document
        MockPostedSalesInvoiceWithTariffNo(CustomerNo, DocumentNo, TariffNo);
        // [GIVEN] A new VAT Sales Ledger
        LibraryVATLedger.MockVATLedger(VATLedger, VATLedger.Type::Sales);
        // [WHEN] Perform "Create Ledger" action for a new VAT Sales Ledger
        LibraryVATLedger.RunCreateVATSalesLedgerReport(VATLedger, CustomerNo);
        LibraryVATLedger.FindVATLedgerLine(VATLedgerLine, VATLedger);

        // [WHEN] Perform "Create Ledger" action again
        LibraryVATLedger.RunCreateVATSalesLedgerReport(VATLedger, CustomerNo);

        // [THEN] There is one "VAT Ledger Line"
        Assert.RecordCount(VATLedgerLine, 1);

        // [THEN] There is one related "VAT Ledger Line Tariff No."
        FilterVATLedgerLineTariffNo(VATLedgerLineTariffNo, VATLedgerLine);
        Assert.RecordCount(VATLedgerLine, 1);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CreateVATPurchaseLedger_AddSheet_Single()
    var
        VATLedger: Record "VAT Ledger";
        VATLedgerLine: Record "VAT Ledger Line";
        VATLedgerLineTariffNo: Record "VAT Ledger Line Tariff No.";
        VendorNo: Code[20];
        DocumentNo: Code[20];
        TariffNo: Code[20];
    begin
        // [FEATURE] [Purchase] [Add. Sheet]
        // [SCENARIO 231729] REP 14962 "Create VAT Purch. Led. Ad. Sh." creates one "VAT Ledger Line" record and
        // [SCENARIO 231729] one related "VAT Ledger Line Tariff No." record for a purchase document with a single "Tariff No." value
        Initialize();

        // [GIVEN] Posted purchase document: "Vendor No." = "V", "Document No." = "D", "Tariff No." = "X"
        MockPostedPurchaseInvoiceWithTariffNoAddSheet(VendorNo, DocumentNo, TariffNo);
        // [GIVEN] A new VAT Purchase Ledger
        LibraryVATLedger.MockVATLedger(VATLedger, VATLedger.Type::Purchase);

        // [WHEN] Perform "Create Additional Sheet" action for a new VAT Purchase Ledger with "Vendor Filter" = "V"
        LibraryVATLedger.RunCreateVATPurchLedAdShReport(VATLedger, VendorNo);

        // [THEN] A new VAT Ledger Line has been created:
        // [THEN] "Origin. Document No."= "D"
        // [THEN] "Document No."= "D"
        // [THEN] "Tariff No." = ""
        // [THEN] "Additional Sheet" = TRUE
        LibraryVATLedger.FindVATLedgerLine(VATLedgerLine, VATLedger);
        VerifyVATLedgerLine(VATLedgerLine, DocumentNo, '', true);

        // [THEN] There is no TAB 12412 "VAT Ledger Line Tariff No." record related to the given purchase VAT Ledger Line
        FilterVATLedgerLineTariffNo(VATLedgerLineTariffNo, VATLedgerLine);
        Assert.RecordIsEmpty(VATLedgerLineTariffNo);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CreateVATPurchaseLedger_AddSheet_Multiple()
    var
        VATLedger: Record "VAT Ledger";
        VATLedgerLine: Record "VAT Ledger Line";
        VATLedgerLineTariffNo: Record "VAT Ledger Line Tariff No.";
        VendorNo: Code[20];
        DocumentNo: Code[20];
        TariffNo: array[2] of Code[20];
    begin
        // [FEATURE] [Purchase] [Add. Sheet]
        // [SCENARIO 231729] REP 14962 "Create VAT Purch. Led. Ad. Sh." creates one "VAT Ledger Line" record and
        // [SCENARIO 231729] several related "VAT Ledger Line Tariff No." records for a purchase document with several "Tariff No." values
        Initialize();

        // [GIVEN] Posted purchase document: "Vendor No." = "V", "Document No." = "D", two "Tariff No." = "X";"Y"
        MockPostedPurchaseInvoiceWithTwoTariffNoAddSheet(VendorNo, DocumentNo, TariffNo);
        // [GIVEN] A new VAT Purchase Ledger
        LibraryVATLedger.MockVATLedger(VATLedger, VATLedger.Type::Purchase);

        // [WHEN] Perform "Create Additional Sheet" action for a new VAT Purchase Ledger with "Vendor Filter" = "V"
        LibraryVATLedger.RunCreateVATPurchLedAdShReport(VATLedger, VendorNo);

        // [THEN] A new VAT Ledger Line has been created:
        // [THEN] "Origin. Document No."= "D"
        // [THEN] "Document No."= "D"
        // [THEN] "Tariff No." = ""
        // [THEN] "Additional Sheet" = TRUE
        LibraryVATLedger.FindVATLedgerLine(VATLedgerLine, VATLedger);
        VerifyVATLedgerLine(VATLedgerLine, DocumentNo, '', true);

        // [THEN] There is no TAB 12412 "VAT Ledger Line Tariff No." record related to the given purchase VAT Ledger Line
        FilterVATLedgerLineTariffNo(VATLedgerLineTariffNo, VATLedgerLine);
        Assert.RecordIsEmpty(VATLedgerLineTariffNo);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CreateVATPurchaseLedger_AddSheet_ClearLines()
    var
        VATLedger: Record "VAT Ledger";
        VATLedgerLine: Record "VAT Ledger Line";
        VATLedgerLineTariffNo: Record "VAT Ledger Line Tariff No.";
        VendorNo: Code[20];
        DocumentNo: Code[20];
        TariffNo: Code[20];
    begin
        // [FEATURE] [Purchase] [Add. Sheet]
        // [SCENARIO 231729] REP 14962 "Create VAT Purch. Led. Ad. Sh." clears existing "VAT Ledger Line" and "VAT Ledger Line Tariff No." records
        Initialize();

        // [GIVEN] Posted purchase document
        MockPostedPurchaseInvoiceWithTariffNoAddSheet(VendorNo, DocumentNo, TariffNo);
        // [GIVEN] A new VAT Purchase Ledger
        LibraryVATLedger.MockVATLedger(VATLedger, VATLedger.Type::Purchase);
        // [GIVEN] Perform "Create Additional Sheet" action for a new VAT Purchase Ledger
        LibraryVATLedger.RunCreateVATPurchLedAdShReport(VATLedger, VendorNo);
        LibraryVATLedger.FindVATLedgerLine(VATLedgerLine, VATLedger);

        // [WHEN] Perform "Create Additional Sheet" action again
        LibraryVATLedger.RunCreateVATPurchLedAdShReport(VATLedger, VendorNo);

        // [THEN] There is one "VAT Ledger Line"
        Assert.RecordCount(VATLedgerLine, 1);

        // [THEN] There is one related "VAT Ledger Line Tariff No."
        FilterVATLedgerLineTariffNo(VATLedgerLineTariffNo, VATLedgerLine);
        Assert.RecordCount(VATLedgerLine, 1);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CreateVATSalesLedger_AddSheet_Single()
    var
        VATLedger: Record "VAT Ledger";
        VATLedgerLine: Record "VAT Ledger Line";
        CustomerNo: Code[20];
        DocumentNo: Code[20];
        TariffNo: Code[20];
    begin
        // [FEATURE] [Sales] [Add. Sheet]
        // [SCENARIO 231729] REP 14963 "Create VAT Sales Led. Ad. Sh." creates one "VAT Ledger Line" record and
        // [SCENARIO 231729] one related "VAT Ledger Line Tariff No." record for a sales document with a single "Tariff No." value
        Initialize();

        // [GIVEN] Posted sales document: "Customer No." = "C", "Document No." = "D", "Tariff No." = "X"
        MockPostedSalesInvoiceWithTariffNoAddSheet(CustomerNo, DocumentNo, TariffNo);
        // [GIVEN] A new VAT Sales Ledger
        LibraryVATLedger.MockVATLedger(VATLedger, VATLedger.Type::Sales);

        // [WHEN] Perform "Create Ledger" action for a new VAT Sales Ledger with "Csutomer Filter" = "C"
        LibraryVATLedger.RunCreateVATSalesLedAdShReport(VATLedger, CustomerNo);

        // [THEN] A new VAT Ledger Line has been created:
        // [THEN] "Origin. Document No."= "D"
        // [THEN] "Document No."= "D"
        // [THEN] "Tariff No." = "X"
        // [THEN] "Additional Sheet" = TRUE
        LibraryVATLedger.FindVATLedgerLine(VATLedgerLine, VATLedger);
        VerifyVATLedgerLine(VATLedgerLine, DocumentNo, TariffNo, true);

        // [THEN] There is a related "VAT Ledger Line Tariff No." record with "Tariff No." = "X"
        VerifyVATLedgerLineTariffNo(VATLedgerLine, TariffNo);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CreateVATSalesLedger_AddSheet_Multiple()
    var
        VATLedger: Record "VAT Ledger";
        VATLedgerLine: Record "VAT Ledger Line";
        CustomerNo: Code[20];
        DocumentNo: Code[20];
        TariffNo: array[2] of Code[20];
    begin
        // [FEATURE] [Sales] [Add. Sheet]
        // [SCENARIO 231729] REP 14963 "Create VAT Sales Led. Ad. Sh." creates one "VAT Ledger Line" record and
        // [SCENARIO 231729] several related "VAT Ledger Line Tariff No." records for a sales document with several "Tariff No." values
        Initialize();

        // [GIVEN] Posted sales document: "Customer No." = "C", "Document No." = "D", two "Tariff No." = "X";"Y"
        MockPostedSalesInvoiceWithTwoTariffNoAddSheet(CustomerNo, DocumentNo, TariffNo);
        // [GIVEN] A new VAT Sales Ledger
        LibraryVATLedger.MockVATLedger(VATLedger, VATLedger.Type::Sales);

        // [WHEN] Perform "Create Ledger" action for a new VAT Sales Ledger with "Csutomer Filter" = "C"
        LibraryVATLedger.RunCreateVATSalesLedAdShReport(VATLedger, CustomerNo);

        // [THEN] A new VAT Ledger Line has been created:
        // [THEN] "Origin. Document No."= "D"
        // [THEN] "Document No."= "D"
        // [THEN] "Tariff No." = "DIFFERENT" (const text)
        // [THEN] "Additional Sheet" = TRUE
        LibraryVATLedger.FindVATLedgerLine(VATLedgerLine, VATLedger);
        VerifyVATLedgerLine(VATLedgerLine, DocumentNo, DIFFERENTTxt, true);

        // [THEN] There are two related "VAT Ledger Line Tariff No." records, one with "Tariff No." = "X", another with "Tariff No." = "Y"
        VerifyTwoVATLedgerLineTariffNo(VATLedgerLine, TariffNo);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CreateVATSalesLedger_AddSheet_ClearLines()
    var
        VATLedger: Record "VAT Ledger";
        VATLedgerLine: Record "VAT Ledger Line";
        VATLedgerLineTariffNo: Record "VAT Ledger Line Tariff No.";
        CustomerNo: Code[20];
        DocumentNo: Code[20];
        TariffNo: Code[20];
    begin
        // [FEATURE] [Sales] [Add. Sheet]
        // [SCENARIO 231729] REP 14963 "Create VAT Sales Led. Ad. Sh." clears existing "VAT Ledger Line" and "VAT Ledger Line Tariff No." records
        Initialize();

        // [GIVEN] Posted sales document
        MockPostedSalesInvoiceWithTariffNoAddSheet(CustomerNo, DocumentNo, TariffNo);
        // [GIVEN] A new VAT Sales Ledger
        LibraryVATLedger.MockVATLedger(VATLedger, VATLedger.Type::Sales);
        // [GIVEN] Perform "Create Ledger" action for a new VAT Sales Ledger
        LibraryVATLedger.RunCreateVATSalesLedAdShReport(VATLedger, CustomerNo);
        LibraryVATLedger.FindVATLedgerLine(VATLedgerLine, VATLedger);

        // [WHEN] Perform "Create Ledger" action again
        LibraryVATLedger.RunCreateVATSalesLedAdShReport(VATLedger, CustomerNo);

        // [THEN] There is one "VAT Ledger Line"
        Assert.RecordCount(VATLedgerLine, 1);

        // [THEN] There is one related "VAT Ledger Line Tariff No."
        FilterVATLedgerLineTariffNo(VATLedgerLineTariffNo, VATLedgerLine);
        Assert.RecordCount(VATLedgerLine, 1);
    end;

    local procedure Initialize()
    begin
        LibraryVariableStorage.Clear();

        if IsInitialized then
            exit;

        LibraryVATLedger.UpdateCompanyInformationEAEU();

        IsInitialized := true;
    end;

    local procedure MockPostedPurchaseInvoiceWithTariffNo(var VendorNo: Code[20]; var DocumentNo: Code[20]; var TariffNo: Code[20])
    begin
        LibraryVATLedger.MockPurchaseVATEntry(DocumentNo, VendorNo);

        TariffNo := LibraryVATLedger.MockTariffNo();
        LibraryVATLedger.MockVendorValueEntryWithTariffNo(VendorNo, DocumentNo, TariffNo);
    end;

    local procedure MockPostedPurchaseInvoiceWithTwoTariffNo(var VendorNo: Code[20]; var DocumentNo: Code[20]; var TariffNo: array[2] of Code[20])
    var
        i: Integer;
    begin
        LibraryVATLedger.MockPurchaseVATEntry(DocumentNo, VendorNo);

        for i := 1 to ArrayLen(TariffNo) do begin
            TariffNo[i] := LibraryVATLedger.MockTariffNo();
            LibraryVATLedger.MockVendorValueEntryWithTariffNo(VendorNo, DocumentNo, TariffNo[i]);
        end;
    end;

    local procedure MockPostedSalesInvoiceWithTariffNo(var CustomerNo: Code[20]; var DocumentNo: Code[20]; var TariffNo: Code[20])
    begin
        LibraryVATLedger.MockSalesVATEntry(DocumentNo, CustomerNo);

        TariffNo := LibraryVATLedger.MockTariffNo();
        LibraryVATLedger.MockCustomerValueEntryWithTariffNo(CustomerNo, DocumentNo, TariffNo);
    end;

    local procedure MockPostedSalesInvoiceWithTwoTariffNo(var CustomerNo: Code[20]; var DocumentNo: Code[20]; var TariffNo: array[2] of Code[20])
    var
        i: Integer;
    begin
        LibraryVATLedger.MockSalesVATEntry(DocumentNo, CustomerNo);

        for i := 1 to ArrayLen(TariffNo) do begin
            TariffNo[i] := LibraryVATLedger.MockTariffNo();
            LibraryVATLedger.MockCustomerValueEntryWithTariffNo(CustomerNo, DocumentNo, TariffNo[i]);
        end;
    end;

    local procedure MockPostedPurchaseInvoiceWithTariffNoAddSheet(var VendorNo: Code[20]; var DocumentNo: Code[20]; var TariffNo: Code[20])
    begin
        LibraryVATLedger.MockPurchaseVATEntryAddSheet(DocumentNo, VendorNo);

        TariffNo := LibraryVATLedger.MockTariffNo();
        LibraryVATLedger.MockVendorValueEntryWithTariffNo(VendorNo, DocumentNo, TariffNo);
    end;

    local procedure MockPostedPurchaseInvoiceWithTwoTariffNoAddSheet(var VendorNo: Code[20]; var DocumentNo: Code[20]; var TariffNo: array[2] of Code[20])
    var
        i: Integer;
    begin
        LibraryVATLedger.MockPurchaseVATEntryAddSheet(DocumentNo, VendorNo);

        for i := 1 to ArrayLen(TariffNo) do begin
            TariffNo[i] := LibraryVATLedger.MockTariffNo();
            LibraryVATLedger.MockVendorValueEntryWithTariffNo(VendorNo, DocumentNo, TariffNo[i]);
        end;
    end;

    local procedure MockPostedSalesInvoiceWithTariffNoAddSheet(var CustomerNo: Code[20]; var DocumentNo: Code[20]; var TariffNo: Code[20])
    begin
        LibraryVATLedger.MockSalesVATEntryAddSheet(DocumentNo, CustomerNo);

        TariffNo := LibraryVATLedger.MockTariffNo();
        LibraryVATLedger.MockCustomerValueEntryWithTariffNo(CustomerNo, DocumentNo, TariffNo);
    end;

    local procedure MockPostedSalesInvoiceWithTwoTariffNoAddSheet(var CustomerNo: Code[20]; var DocumentNo: Code[20]; var TariffNo: array[2] of Code[20])
    var
        i: Integer;
    begin
        LibraryVATLedger.MockSalesVATEntryAddSheet(DocumentNo, CustomerNo);

        for i := 1 to ArrayLen(TariffNo) do begin
            TariffNo[i] := LibraryVATLedger.MockTariffNo();
            LibraryVATLedger.MockCustomerValueEntryWithTariffNo(CustomerNo, DocumentNo, TariffNo[i]);
        end;
    end;

    local procedure MockVATLedgerWithTwoLines(var VATLedger: Record "VAT Ledger")
    var
        VATLedgerLine: Record "VAT Ledger Line";
        DummyVATLedgerLineTariffNo: Record "VAT Ledger Line Tariff No.";
    begin
        LibraryVATLedger.MockVATLedger(VATLedger, VATLedger.Type::Purchase);

        LibraryVATLedger.MockVATLedgerLineForTheGivenVATLedger(VATLedgerLine, VATLedger, false);
        LibraryVATLedger.MockVATLedgerLineTariffNo(VATLedgerLine, LibraryVATLedger.MockTariffNo());

        LibraryVATLedger.MockVATLedgerLineForTheGivenVATLedger(VATLedgerLine, VATLedger, true);
        LibraryVATLedger.MockVATLedgerLineTariffNo(VATLedgerLine, LibraryVATLedger.MockTariffNo());

        VATLedgerLine.SetRange(Type, VATLedger.Type);
        VATLedgerLine.SetRange(Code, VATLedger.Code);
        Assert.RecordCount(VATLedgerLine, 2);

        DummyVATLedgerLineTariffNo.SetRange(Type, VATLedger.Type);
        DummyVATLedgerLineTariffNo.SetRange(Code, VATLedger.Code);
        Assert.RecordCount(DummyVATLedgerLineTariffNo, 2);
    end;

    local procedure MockVendorVATLedgerLineWithTwoTariffNo(var VATLedgerLine: Record "VAT Ledger Line"; var TariffNo: array[2] of Code[20])
    begin
        MockVATLedgerLineWithTwoTariffNo(
          VATLedgerLine, TariffNo, VATLedgerLine.Type::Purchase, VATLedgerLine."C/V Type"::Vendor, LibraryVATLedger.MockVendorNo());
    end;

    local procedure MockCustomerVATLedgerLineWithTwoTariffNo(var VATLedgerLine: Record "VAT Ledger Line"; var TariffNo: array[2] of Code[20])
    begin
        MockVATLedgerLineWithTwoTariffNo(
          VATLedgerLine, TariffNo, VATLedgerLine.Type::Sales,
          VATLedgerLine."C/V Type"::Customer, LibraryVATLedger.MockCustomerNo(LibraryVATLedger.MockCountryEAEU()));
    end;

    local procedure MockVATLedgerLineWithTwoTariffNo(var VATLedgerLine: Record "VAT Ledger Line"; var TariffNo: array[2] of Code[20]; Type: Option; CVType: Option; CVNo: Code[20])
    var
        i: Integer;
    begin
        LibraryVATLedger.MockVATLedgerLine(VATLedgerLine, Type, CVType, CVNo);
        for i := 1 to ArrayLen(TariffNo) do begin
            TariffNo[i] := LibraryVATLedger.MockTariffNo();
            LibraryVATLedger.MockVATLedgerLineTariffNo(VATLedgerLine, TariffNo[i]);
        end;
    end;

    local procedure FilterVATLedgerLineTariffNo(var VATLedgerLineTariffNo: Record "VAT Ledger Line Tariff No."; VATLedgerLine: Record "VAT Ledger Line")
    begin
        VATLedgerLineTariffNo.SetRange(Type, VATLedgerLine.Type);
        VATLedgerLineTariffNo.SetRange(Code, VATLedgerLine.Code);
        VATLedgerLineTariffNo.SetRange("Line No.", VATLedgerLine."Line No.");
    end;

    local procedure LookupPurchaseVATLedgerLineTariffNoField(var VATLedgerLineTariffNo: TestPage "VAT Ledger Line Tariff No."; VATLedgerLine: Record "VAT Ledger Line")
    var
        VATPurchaseLedgerSubform: TestPage "VAT Purchase Ledger Subform";
    begin
        VATPurchaseLedgerSubform.OpenView();
        VATPurchaseLedgerSubform.GotoRecord(VATLedgerLine);
        VATLedgerLineTariffNo.Trap();
        VATPurchaseLedgerSubform."Tariff No.".Lookup();
    end;

    local procedure LookupSalesVATLedgerLineTariffNoField(var VATLedgerLineTariffNo: TestPage "VAT Ledger Line Tariff No."; VATLedgerLine: Record "VAT Ledger Line")
    var
        VATSalesLedgerSubform: TestPage "VAT Sales Ledger Subform";
    begin
        VATSalesLedgerSubform.OpenView();
        VATSalesLedgerSubform.GotoRecord(VATLedgerLine);
        VATLedgerLineTariffNo.Trap();
        VATSalesLedgerSubform."Tariff No.".Lookup();
    end;

    local procedure VerifyVATLedgerLine(VATLedgerLine: Record "VAT Ledger Line"; ExpectedDocumentNo: Code[20]; ExpectedTariffNo: Code[20]; ExpectedAddSheet: Boolean)
    begin
        Assert.AreEqual(ExpectedDocumentNo, VATLedgerLine."Origin. Document No.", VATLedgerLine.FieldCaption("Origin. Document No."));
        Assert.AreEqual(ExpectedDocumentNo, VATLedgerLine."Document No.", VATLedgerLine.FieldCaption("Document No."));
        Assert.AreEqual(ExpectedTariffNo, VATLedgerLine."Tariff No.", VATLedgerLine.FieldCaption("Tariff No."));
        Assert.AreEqual(ExpectedAddSheet, VATLedgerLine."Additional Sheet", VATLedgerLine.FieldCaption("Additional Sheet"));
    end;

    local procedure VerifyVATLedgerLineTariffNo(VATLedgerLine: Record "VAT Ledger Line"; TariffNo: Code[20])
    var
        VATLedgerLineTariffNo: Record "VAT Ledger Line Tariff No.";
    begin
        FilterVATLedgerLineTariffNo(VATLedgerLineTariffNo, VATLedgerLine);
        VATLedgerLineTariffNo.FindFirst();
        Assert.AreEqual(TariffNo, VATLedgerLineTariffNo."Tariff No.", VATLedgerLineTariffNo.FieldCaption("Tariff No."));
    end;

    local procedure VerifyOneVATLedgerLineTariffNo(VATLedgerLine: Record "VAT Ledger Line"; TariffNo: Code[20])
    var
        VATLedgerLineTariffNo: Record "VAT Ledger Line Tariff No.";
    begin
        FilterVATLedgerLineTariffNo(VATLedgerLineTariffNo, VATLedgerLine);
        VATLedgerLineTariffNo.FindFirst();
        Assert.AreEqual(TariffNo, VATLedgerLineTariffNo."Tariff No.", VATLedgerLineTariffNo.FieldCaption("Tariff No."));
        Assert.RecordCount(VATLedgerLineTariffNo, 1);
    end;

    local procedure VerifyTwoVATLedgerLineTariffNo(VATLedgerLine: Record "VAT Ledger Line"; TariffNo: array[2] of Code[20])
    var
        VATLedgerLineTariffNo: Record "VAT Ledger Line Tariff No.";
    begin
        FilterVATLedgerLineTariffNo(VATLedgerLineTariffNo, VATLedgerLine);
        Assert.RecordCount(VATLedgerLineTariffNo, 2);

        VATLedgerLineTariffNo.SetRange("Tariff No.", TariffNo[1]);
        Assert.RecordCount(VATLedgerLineTariffNo, 1);

        VATLedgerLineTariffNo.SetRange("Tariff No.", TariffNo[2]);
        Assert.RecordCount(VATLedgerLineTariffNo, 1);
    end;

    local procedure VerifyTwoVATLedgerLineTariffNoOnPage(VATLedgerLine: Record "VAT Ledger Line"; VATLedgerLineTariffNo: TestPage "VAT Ledger Line Tariff No.")
    var
        TariffNo: array[2] of Code[20];
    begin
        TariffNo[1] := VATLedgerLineTariffNo."Tariff No.".Value();
        VATLedgerLineTariffNo.Next();
        TariffNo[2] := VATLedgerLineTariffNo."Tariff No.".Value();
        Assert.IsFalse(VATLedgerLineTariffNo.Next(), '');
        VerifyTwoVATLedgerLineTariffNo(VATLedgerLine, TariffNo);
    end;
}

