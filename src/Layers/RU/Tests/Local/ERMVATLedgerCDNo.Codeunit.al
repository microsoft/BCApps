codeunit 147132 "ERM VAT Ledger CD No."
{
    // // [FEATURE] [UT] [VAT Ledger] [CD No.]

    TestPermissions = NonRestrictive;
    Subtype = Test;
    Permissions = tabledata "VAT Ledger Line" = d;

    var
        LibraryVATLedger: Codeunit "Library - VAT Ledger";
        LibraryRUReports: Codeunit "Library RU Reports";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibraryXMLRead: Codeunit "Library - XML Read";
        LibraryUtility: Codeunit "Library - Utility";
        Assert: Codeunit Assert;
        DIFFERENTTxt: Label 'DIFFERENT';
        IsInitialized: Boolean;
        KnigaPokupTxt: Label 'KnigaPokup';
        KnigaPokupDLTxt: Label 'KnigaPokupDL';
        KnigaProdTxt: Label 'KnigaProd';
        KnigaProdDLTxt: Label 'KnigaProdDL';
        KnPokStrTxt: Label 'KnPokStr';
        KnPokDLStrTxt: Label 'KnPokDLStr';
        KnProdStrTxt: Label 'KnProdStr';
        KnProdDLStrTxt: Label 'KnProdDLStr';
        NomTDTxt: Label 'NomTD';
        NomScFProdTxt: Label 'NomScFProd';
        SvRegNomTxt: Label 'SvRegNom';
        RegNomProslTxt: Label 'RegNomProsl';

    [Test]
    [Scope('OnPrem')]
    procedure LookupPurchaseVATLedgerLine_EmptyCDNo()
    var
        VATLedgerLine: Record "VAT Ledger Line";
        VATLedgerLineCDNo: TestPage "VAT Ledger Line CD No.";
        VendorNo: Code[20];
    begin
        // [FEATURE] [Purchase] [UI]
        // [SCENARIO 203664] Lookup purchase "VAT Ledger Line"."Package No." field in case of empty value
        Initialize();

        // [GIVEN] Purchase VAT Ledger Line with "Package No." = ""
        LibraryVATLedger.MockVendorVATLedgerLine(VATLedgerLine, VendorNo);

        // [WHEN] Lookup "Package No." field
        LookupPurchaseVATLedgerLineCDNoField(VATLedgerLineCDNo, VATLedgerLine);

        // [THEN] Page "VAT Ledger Line CD No." has been opened and "Package No." = ""
        VATLedgerLineCDNo."Package No.".AssertEquals('');
        Assert.IsFalse(VATLedgerLineCDNo.Editable(), '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure LookupPurchaseVATLedgerLine_Single()
    var
        VATLedgerLine: Record "VAT Ledger Line";
        VATLedgerLineCDNo: TestPage "VAT Ledger Line CD No.";
        CDNo: Code[30];
    begin
        // [FEATURE] [Purchase] [UI]
        // [SCENARIO 203664] Lookup purchase "VAT Ledger Line"."Package No." field in case of single value
        Initialize();

        // [GIVEN] Purchase VAT Ledger Line with single "Package No." = "X"
        LibraryVATLedger.MockVendorVATLedgerLineWithCDNo(VATLedgerLine, CDNo);

        // [WHEN] Lookup "Package No." field
        LookupPurchaseVATLedgerLineCDNoField(VATLedgerLineCDNo, VATLedgerLine);

        // [THEN] Page "VAT Ledger Line CD No." has been opened and "Package No." = "X"
        VATLedgerLineCDNo."Package No.".AssertEquals(CDNo);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure LookupPurchaseVATLedgerLine_Multiple()
    var
        VATLedgerLine: Record "VAT Ledger Line";
        VATLedgerLineCDNo: TestPage "VAT Ledger Line CD No.";
        CDNo: array[2] of Code[30];
    begin
        // [FEATURE] [Purchase] [UI]
        // [SCENARIO 203664] Lookup purchase "VAT Ledger Line"."Package No." field in case of multiple values
        Initialize();

        // [GIVEN] Purchase VAT Ledger Line with several "Package No." = "X";"Y"
        MockVendorVATLedgerLineWithTwoCDNo(VATLedgerLine, CDNo);

        // [WHEN] Lookup "Package No." field
        LookupPurchaseVATLedgerLineCDNoField(VATLedgerLineCDNo, VATLedgerLine);

        // [THEN] Page "VAT Ledger Line CD No." has been opened
        // [THEN] There are two records, one with "Package No." = "X", another with "Package No." = "Y"
        VerifyTwoVATLedgerLineCDNoOnPage(VATLedgerLine, VATLedgerLineCDNo);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure LookupSalesVATLedgerLine_EmptyCDNo()
    var
        VATLedgerLine: Record "VAT Ledger Line";
        VATLedgerLineCDNo: TestPage "VAT Ledger Line CD No.";
        CustomerNo: Code[20];
    begin
        // [FEATURE] [Sales] [UI]
        // [SCENARIO 203664] Lookup sales "VAT Ledger Line"."Package No." field in case of empty value
        Initialize();

        // [GIVEN] Sales VAT Ledger Line with "Package No." = ""
        LibraryVATLedger.MockCustomerVATLedgerLine(VATLedgerLine, CustomerNo);

        // [WHEN] Lookup "Package No." field
        LookupSalesVATLedgerLineCDNoField(VATLedgerLineCDNo, VATLedgerLine);

        // [THEN] Page "VAT Ledger Line CD No." has been opened and "Package No." = ""
        VATLedgerLineCDNo."Package No.".AssertEquals('');
        Assert.IsFalse(VATLedgerLineCDNo.Editable(), '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure LookupSalesVATLedgerLine_Single()
    var
        VATLedgerLine: Record "VAT Ledger Line";
        VATLedgerLineCDNo: TestPage "VAT Ledger Line CD No.";
        CDNo: Code[30];
    begin
        // [FEATURE] [Sales] [UI]
        // [SCENARIO 203664] Lookup sales "VAT Ledger Line"."Package No." field
        Initialize();

        // [GIVEN] Sales VAT Ledger Line with "Package No." = "X"
        LibraryVATLedger.MockCustomerVATLedgerLineWithCDNo(VATLedgerLine, CDNo);

        // [WHEN] Lookup "Package No." field
        LookupSalesVATLedgerLineCDNoField(VATLedgerLineCDNo, VATLedgerLine);

        // [THEN] Page "VAT Ledger Line CD No." has been opened and "Package No." = "X"
        VATLedgerLineCDNo."Package No.".AssertEquals(CDNo);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure LookupSalesVATLedgerLine_Multiple()
    var
        VATLedgerLine: Record "VAT Ledger Line";
        VATLedgerLineCDNo: TestPage "VAT Ledger Line CD No.";
        CDNo: array[2] of Code[30];
    begin
        // [FEATURE] [Sales] [UI]
        // [SCENARIO 203664] Lookup sales "VAT Ledger Line"."Package No." field in case of multiple values
        Initialize();

        // [GIVEN] Sales VAT Ledger Line with several "Package No." = "X";"Y"
        MockCustomerVATLedgerLineWithTwoCDNo(VATLedgerLine, CDNo);

        // [WHEN] Lookup "Package No." field
        LookupSalesVATLedgerLineCDNoField(VATLedgerLineCDNo, VATLedgerLine);

        // [THEN] Page "VAT Ledger Line CD No." has been opened
        // [THEN] There are two records, one with "Package No." = "X", another with "Package No." = "Y"
        VerifyTwoVATLedgerLineCDNoOnPage(VATLedgerLine, VATLedgerLineCDNo);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DeletePurchaseVATLedgerLine_Single()
    var
        VATLedgerLine: Record "VAT Ledger Line";
        VATLedgerLineCDNo: Record "VAT Ledger Line CD No.";
        CDNo: Code[30];
    begin
        // [FEATURE] [Purchase]
        // [SCENARIO 203664] Delete purchase "VAT Ledger Line" record with "Package No." value
        Initialize();

        // [GIVEN] Purchase VAT Ledger Line with "Package No." = "X"
        LibraryVATLedger.MockVendorVATLedgerLineWithCDNo(VATLedgerLine, CDNo);
        // [GIVEN] There is a TAB 12411 "VAT Ledger Line CD No." record with "Package No." = "X"
        FilterVATLedgerLineCDNo(VATLedgerLineCDNo, VATLedgerLine);
        Assert.RecordIsNotEmpty(VATLedgerLineCDNo);

        // [WHEN] Delete the purchase VAT Ledger Line
        VATLedgerLine.Delete(true);

        // [THEN] There is no TAB 12411 "VAT Ledger Line CD No." record related to the given purchase VAT Ledger Line
        Assert.RecordIsEmpty(VATLedgerLineCDNo);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DeletePurchaseVATLedgerLine_Multiple()
    var
        VATLedgerLine: Record "VAT Ledger Line";
        VATLedgerLineCDNo: Record "VAT Ledger Line CD No.";
        CDNo: array[2] of Code[30];
    begin
        // [FEATURE] [Purchase]
        // [SCENARIO 203664] Delete purchase "VAT Ledger Line" record with several "Package No." values
        Initialize();

        // [GIVEN] Purchase VAT Ledger Line with several "Package No." values
        MockVendorVATLedgerLineWithTwoCDNo(VATLedgerLine, CDNo);
        // [GIVEN] There are several TAB 12411 "VAT Ledger Line CD No." records related to the purchase VAT Ledger Line
        FilterVATLedgerLineCDNo(VATLedgerLineCDNo, VATLedgerLine);
        Assert.RecordCount(VATLedgerLineCDNo, 2);

        // [WHEN] Delete the purchase VAT Ledger Line
        VATLedgerLine.Delete(true);

        // [THEN] There is no TAB 12411 "VAT Ledger Line CD No." record related to the given purchase VAT Ledger Line
        Assert.RecordIsEmpty(VATLedgerLineCDNo);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DeleteSalesVATLedgerLine_Single()
    var
        VATLedgerLine: Record "VAT Ledger Line";
        VATLedgerLineCDNo: Record "VAT Ledger Line CD No.";
        CDNo: Code[30];
    begin
        // [FEATURE] [Sales]
        // [SCENARIO 203664] Delete sales "VAT Ledger Line" record with "Package No." value
        Initialize();

        // [GIVEN] Sales VAT Ledger Line with "Package No." = "X"
        LibraryVATLedger.MockCustomerVATLedgerLineWithCDNo(VATLedgerLine, CDNo);
        // [GIVEN] There is a TAB 12411 "VAT Ledger Line CD No." record with "Package No." = "X"
        FilterVATLedgerLineCDNo(VATLedgerLineCDNo, VATLedgerLine);
        Assert.RecordIsNotEmpty(VATLedgerLineCDNo);

        // [WHEN] Delete the purchase VAT Ledger Line
        VATLedgerLine.Delete(true);

        // [THEN] There is no TAB 12411 "VAT Ledger Line CD No." record related to the given sales VAT Ledger Line
        Assert.RecordIsEmpty(VATLedgerLineCDNo);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DeleteSalesVATLedgerLine_Multiple()
    var
        VATLedgerLine: Record "VAT Ledger Line";
        VATLedgerLineCDNo: Record "VAT Ledger Line CD No.";
        CDNo: array[2] of Code[30];
    begin
        // [FEATURE] [Sales]
        // [SCENARIO 203664] Delete sales "VAT Ledger Line" record with several "Package No." values
        Initialize();

        // [GIVEN] Sales VAT Ledger Line with several "Package No." values
        MockCustomerVATLedgerLineWithTwoCDNo(VATLedgerLine, CDNo);
        // [GIVEN] There are several TAB 12411 "VAT Ledger Line CD No." records related to the sales VAT Ledger Line
        FilterVATLedgerLineCDNo(VATLedgerLineCDNo, VATLedgerLine);
        Assert.RecordCount(VATLedgerLineCDNo, 2);

        // [WHEN] Delete the sales VAT Ledger Line
        VATLedgerLine.Delete(true);

        // [THEN] There is no TAB 12411 "VAT Ledger Line CD No." record related to the given sales VAT Ledger Line
        Assert.RecordIsEmpty(VATLedgerLineCDNo);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VATLedgerMgt_InsertVATLedgerLineCDNoList_WithoutCDNo()
    var
        VATLedgerLine: Record "VAT Ledger Line";
        VATLedgerLineCDNo: Record "VAT Ledger Line CD No.";
        VATLedgerMgt: Codeunit "VAT Ledger Management";
        VendorNo: Code[20];
        DocumentNo: Code[20];
    begin
        // [SCENARIO 203664] COD 12423 "VAT Ledger Management".InsertVATLedgerLineCDNoList() for a document without "Package No."
        Initialize();

        // [GIVEN] Posted document "D" without "Package No."
        DocumentNo := LibraryUtility.GenerateGUID();
        LibraryVATLedger.MockVendorValueEntryWithCDNo(VendorNo, DocumentNo, '');

        // [GIVEN] VAT Ledger Line
        LibraryVATLedger.MockVendorVATLedgerLine(VATLedgerLine, VendorNo);

        // [WHEN] Run COD 12423 "VAT Ledger Management".InsertVATLedgerLineCDNoList() for the given VAT Ledger Line using "Origin. Document No." = "D"
        VATLedgerLine."Origin. Document No." := DocumentNo;
        VATLedgerMgt.InsertVATLedgerLineCDNoList(VATLedgerLine);

        // [THEN] "VAT Ledger Line"."Package No." = ""
        VATLedgerLine.Find();
        Assert.AreEqual('', VATLedgerLine."Package No.", VATLedgerLine.FieldCaption("Package No."));

        // [THEN] There is no related "VAT Ledger Line CD No." record
        FilterVATLedgerLineCDNo(VATLedgerLineCDNo, VATLedgerLine);
        Assert.RecordIsEmpty(VATLedgerLineCDNo);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VATLedgerMgt_InsertVATLedgerLineCDNoList_Single()
    var
        VATLedgerLine: Record "VAT Ledger Line";
        VATLedgerMgt: Codeunit "VAT Ledger Management";
        VendorNo: Code[20];
        DocumentNo: Code[20];
        CDNo: Code[30];
    begin
        // [SCENARIO 203664] COD 12423 "VAT Ledger Management".InsertVATLedgerLineCDNoList() for a single "Package No." case
        Initialize();

        // [GIVEN] Posted document "D" with item tracking "Package No." = "X"
        // [GIVEN] VAT Ledger Line
        DocumentNo := LibraryUtility.GenerateGUID();
        CDNo := LibraryVATLedger.GenerateCDNoValue;
        LibraryVATLedger.MockVendorVATLedgerLine(VATLedgerLine, VendorNo);
        LibraryVATLedger.MockVendorValueEntryWithCDNo(VendorNo, DocumentNo, CDNo);

        // [WHEN] Run COD 12423 "VAT Ledger Management".InsertVATLedgerLineCDNoList() for the given VAT Ledger Line using "Origin. Document No." = "D"
        VATLedgerLine."Origin. Document No." := DocumentNo;
        VATLedgerMgt.InsertVATLedgerLineCDNoList(VATLedgerLine);

        // [THEN] "VAT Ledger Line"."Package No." = "X"
        VATLedgerLine.Find();
        Assert.AreEqual(CDNo, VATLedgerLine."Package No.", VATLedgerLine.FieldCaption("Package No."));

        // [THEN] "VAT Ledger Line CD No." record has been created with "Package No." = "X"
        VerifyOneVATLedgerLineCDNo(VATLedgerLine, CDNo);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VATLedgerMgt_InsertVATLedgerLineCDNoList_Multiple()
    var
        VATLedgerLine: Record "VAT Ledger Line";
        VATLedgerMgt: Codeunit "VAT Ledger Management";
        VendorNo: Code[20];
        DocumentNo: Code[20];
        CDNo: array[2] of Code[30];
    begin
        // [SCENARIO 203664] COD 12423 "VAT Ledger Management".InsertVATLedgerLineCDNoList() for a multiple "Package No." case
        Initialize();

        // [GIVEN] Posted document "D" with two item tracking "Package No." = "X";"Y"
        // [GIVEN] VAT Ledger Line
        LibraryVATLedger.MockVendorVATLedgerLine(VATLedgerLine, VendorNo);
        DocumentNo := LibraryUtility.GenerateGUID();
        CDNo[1] := LibraryVATLedger.GenerateCDNoValue;
        LibraryVATLedger.MockVendorValueEntryWithCDNo(VendorNo, DocumentNo, CDNo[1]);
        CDNo[2] := LibraryVATLedger.GenerateCDNoValue;
        LibraryVATLedger.MockVendorValueEntryWithCDNo(VendorNo, DocumentNo, CDNo[2]);

        // [WHEN] Run COD 12423 "VAT Ledger Management".InsertVATLedgerLineCDNoList() for the given VAT Ledger Line using "Origin. Document No." = "D"
        VATLedgerLine."Origin. Document No." := DocumentNo;
        VATLedgerMgt.InsertVATLedgerLineCDNoList(VATLedgerLine);

        // [THEN] "VAT Ledger Line"."Package No." = "DIFFERENT" (const text)
        VATLedgerLine.Find();
        Assert.AreEqual(DIFFERENTTxt, VATLedgerLine."Package No.", VATLedgerLine.FieldCaption("Package No."));

        // [THEN] There are two related "VAT Ledger Line CD No." records have been created, one with "Package No." = "X", another with "Package No." = "Y"
        VerifyTwoVATLedgerLineCDNo(VATLedgerLine, CDNo);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VATLedgerMgt_InsertVATLedgerLineCDNoList_Multiple_TheSameCDNoValue()
    var
        VATLedgerLine: Record "VAT Ledger Line";
        VATLedgerMgt: Codeunit "VAT Ledger Management";
        VendorNo: Code[20];
        DocumentNo: Code[20];
        CDNo: Code[30];
    begin
        // [SCENARIO 203664] COD 12423 "VAT Ledger Management".InsertVATLedgerLineCDNoList() for a multiple "Package No." having the same value
        Initialize();

        // [GIVEN] Posted document "D" with two item lines having the same tracking "Package No." = "X"
        // [GIVEN] VAT Ledger Line
        LibraryVATLedger.MockVendorVATLedgerLine(VATLedgerLine, VendorNo);
        DocumentNo := LibraryUtility.GenerateGUID();
        CDNo := LibraryVATLedger.GenerateCDNoValue;
        LibraryVATLedger.MockVendorValueEntryWithCDNo(VendorNo, DocumentNo, CDNo);
        LibraryVATLedger.MockVendorValueEntryWithCDNo(VendorNo, DocumentNo, CDNo);

        // [WHEN] Run COD 12423 "VAT Ledger Management".InsertVATLedgerLineCDNoList() for the given VAT Ledger Line using "Origin. Document No." = "D"
        VATLedgerLine."Origin. Document No." := DocumentNo;
        VATLedgerMgt.InsertVATLedgerLineCDNoList(VATLedgerLine);

        // [THEN] "VAT Ledger Line"."Package No." = "X"
        VATLedgerLine.Find();
        Assert.AreEqual(CDNo, VATLedgerLine."Package No.", VATLedgerLine.FieldCaption("Package No."));

        // [THEN] One "VAT Ledger Line CD No." record has been created with "Package No." = "X"
        VerifyOneVATLedgerLineCDNo(VATLedgerLine, CDNo);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VATLedgerMgt_InsertVATLedgerLineCDNoList_Multiple_CombinedValues()
    var
        VATLedgerLine: Record "VAT Ledger Line";
        VATLedgerMgt: Codeunit "VAT Ledger Management";
        VendorNo: Code[20];
        DocumentNo: Code[20];
        CDNo: array[2] of Code[30];
        i: Integer;
    begin
        // [SCENARIO 203664] COD 12423 "VAT Ledger Management".InsertVATLedgerLineCDNoList() for a multiple "Package No." having the same values and different values
        Initialize();

        // [GIVEN] Posted document "D" with two item lines having the same tracking "Package No." = "X" and two item lines having the same tracking "Package No." = "Y"
        // [GIVEN] VAT Ledger Line
        LibraryVATLedger.MockVendorVATLedgerLine(VATLedgerLine, VendorNo);
        DocumentNo := LibraryUtility.GenerateGUID();
        for i := 1 to ArrayLen(CDNo) do begin
            CDNo[i] := LibraryVATLedger.GenerateCDNoValue;
            LibraryVATLedger.MockVendorValueEntryWithCDNo(VendorNo, DocumentNo, CDNo[i]);
            LibraryVATLedger.MockVendorValueEntryWithCDNo(VendorNo, DocumentNo, CDNo[i]);
        end;

        // [WHEN] Run COD 12423 "VAT Ledger Management".InsertVATLedgerLineCDNoList() for the given VAT Ledger Line using "Origin. Document No." = "D"
        VATLedgerLine."Origin. Document No." := DocumentNo;
        VATLedgerMgt.InsertVATLedgerLineCDNoList(VATLedgerLine);

        // [THEN] "VAT Ledger Line"."Package No." = "DIFFERENT" (const text)
        VATLedgerLine.Find();
        Assert.AreEqual(DIFFERENTTxt, VATLedgerLine."Package No.", VATLedgerLine.FieldCaption("Package No."));

        // [THEN] There are two related "VAT Ledger Line CD No." records have been created, one with "Package No." = "X", another with "Package No." = "Y"
        VerifyTwoVATLedgerLineCDNo(VATLedgerLine, CDNo);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VATLedgerMgt_InsertVATLedgerLineCDNoList_TheSameDocNoFilter()
    var
        SalesVATLedgerLine: Record "VAT Ledger Line";
        PurchaseVATLedgerLine: Record "VAT Ledger Line";
        VATLedgerMgt: Codeunit "VAT Ledger Management";
        VendorNo: Code[20];
        CustomerNo: Code[20];
        DocumentNo: Code[20];
        SalesCDNo: Code[30];
        PurchaseCDNo: Code[30];
    begin
        // [SCENARIO 203664] COD 12423 "VAT Ledger Management".InsertVATLedgerLineCDNoList() filters Value Entry by VATLedgerLine's "C/V Type", "C/V No."
        Initialize();

        // [GIVEN] Posted vendor "V" document "D" with item tracking "Package No." = "X"
        DocumentNo := LibraryUtility.GenerateGUID();
        PurchaseCDNo := LibraryVATLedger.GenerateCDNoValue;
        LibraryVATLedger.MockVendorVATLedgerLine(PurchaseVATLedgerLine, VendorNo);
        LibraryVATLedger.MockVendorValueEntryWithCDNo(VendorNo, DocumentNo, PurchaseCDNo);
        // [GIVEN] Posted customer "C" document "D" (the same document no.) with item tracking "Package No." = "Y"
        SalesCDNo := LibraryVATLedger.GenerateCDNoValue;
        LibraryVATLedger.MockCustomerVATLedgerLine(SalesVATLedgerLine, CustomerNo);
        LibraryVATLedger.MockCustomerValueEntryWithCDNo(CustomerNo, DocumentNo, SalesCDNo);

        // [GIVEN] Run COD 12423 "VAT Ledger Management".InsertVATLedgerLineCDNoList() for the Purchase VAT Ledger Line with "C/V Type" = "Vendor", "C/V No." = "V", "Origin. Document No." = "D"
        PurchaseVATLedgerLine."Origin. Document No." := DocumentNo;
        VATLedgerMgt.InsertVATLedgerLineCDNoList(PurchaseVATLedgerLine);

        // [WHEN] Run COD 12423 "VAT Ledger Management".InsertVATLedgerLineCDNoList() for the Sales VAT Ledger Line with "C/V Type" = "Customer", "C/V No." = "C", "Origin. Document No." = "D"
        SalesVATLedgerLine."Origin. Document No." := DocumentNo;
        VATLedgerMgt.InsertVATLedgerLineCDNoList(SalesVATLedgerLine);

        // [THEN] Purchase "VAT Ledger Line"."Package No." = "X"
        PurchaseVATLedgerLine.Find();
        Assert.AreEqual(PurchaseCDNo, PurchaseVATLedgerLine."Package No.", PurchaseVATLedgerLine.FieldCaption("Package No."));

        // [THEN] One "VAT Ledger Line CD No." record has been created related to the purchase VAT Ledger Line with "Package No." = "X"
        VerifyOneVATLedgerLineCDNo(PurchaseVATLedgerLine, PurchaseCDNo);

        // [THEN] Sales "VAT Ledger Line"."Package No." = "Y"
        SalesVATLedgerLine.Find();
        Assert.AreEqual(SalesCDNo, SalesVATLedgerLine."Package No.", SalesVATLedgerLine.FieldCaption("Package No."));

        // [THEN] One "VAT Ledger Line CD No." record has been created related to the sales VAT Ledger Line with "Package No." = "Y"
        VerifyOneVATLedgerLineCDNo(SalesVATLedgerLine, SalesCDNo);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VATLedgerMgt_DeleteVATLedgerLines()
    var
        VATLedger: Record "VAT Ledger";
        DummyVATLedgerLine: Record "VAT Ledger Line";
        DummyVATLedgerLineCDNo: Record "VAT Ledger Line CD No.";
        VATLedgerMgt: Codeunit "VAT Ledger Management";
    begin
        // [SCENARIO 203664] COD 12423 "VAT Ledger Management".DeleteVATLedgerLines() deletes both normal and add. sheet VAT Ledger Lines
        Initialize();

        // [GIVEN] VAT Ledger
        // [GIVEN] VAT Ledger Line with "Package No." value and "Additional Sheet" = FALSE
        // [GIVEN] VAT Ledger Line with "Package No." value and "Additional Sheet" = TRUE
        MockVATLedgerWithTwoLines(VATLedger);

        // [WHEN] Run COD 12423 "VAT Ledger Management".DeleteVATLedgerLines() for the given VAT Ledger
        VATLedgerMgt.DeleteVATLedgerLines(VATLedger);

        // [THEN] Both VAT Ledger Line's with linked "VAT Ledger Line CD No."s have been deleted
        DummyVATLedgerLine.SetRange(Type, VATLedger.Type);
        DummyVATLedgerLine.SetRange(Code, VATLedger.Code);
        Assert.RecordIsEmpty(DummyVATLedgerLine);

        DummyVATLedgerLineCDNo.SetRange(Type, VATLedger.Type);
        DummyVATLedgerLineCDNo.SetRange(Code, VATLedger.Code);
        Assert.RecordIsEmpty(DummyVATLedgerLineCDNo);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VATLedgerMgt_DeleteVATLedgerAddSheetLines()
    var
        VATLedger: Record "VAT Ledger";
        VATLedgerLine: Record "VAT Ledger Line";
        VATLedgerLineCDNo: Record "VAT Ledger Line CD No.";
        VATLedgerMgt: Codeunit "VAT Ledger Management";
    begin
        // [SCENARIO 203664] COD 12423 "VAT Ledger Management".DeleteVATLedgerLines() deletes only add. sheet VAT Ledger Lines

        // [GIVEN] VAT Ledger
        // [GIVEN] VAT Ledger Line with "Package No." value and "Additional Sheet" = FALSE
        // [GIVEN] VAT Ledger Line with "Package No." value and "Additional Sheet" = TRUE
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

        VATLedgerLineCDNo.SetRange(Type, VATLedger.Type);
        VATLedgerLineCDNo.SetRange(Code, VATLedger.Code);
        Assert.RecordCount(VATLedgerLineCDNo, 1);
        VATLedgerLineCDNo.FindFirst();

        Assert.AreEqual(VATLedgerLine."Line No.", VATLedgerLineCDNo."Line No.", VATLedgerLineCDNo.FieldCaption("Line No."));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CreateVATPurchaseLedger_Single()
    var
        VATLedger: Record "VAT Ledger";
        VATLedgerLine: Record "VAT Ledger Line";
        VendorNo: Code[20];
        DocumentNo: Code[20];
        CDNo: Code[30];
    begin
        // [FEATURE] [Purchase]
        // [SCENARIO 203664] REP 12455 "Create VAT Purchase Ledger" creates one "VAT Ledger Line" record and
        // [SCENARIO 203664] one related "VAT Ledger Line CD No." record for a purchase document with a single "Package No." value
        Initialize();

        // [GIVEN] Posted purchase document: "Vendor No." = "V", "Document No." = "D", "Package No." = "X"
        MockPostedPurchaseInvoiceWithCDNo(VendorNo, DocumentNo, CDNo);
        // [GIVEN] A new VAT Purchase Ledger
        LibraryVATLedger.MockVATLedger(VATLedger, VATLedger.Type::Purchase);

        // [WHEN] Perform "Create Ledger" action for a new VAT Purchase Ledger with "Vendor Filter" = "V"
        LibraryVATLedger.RunCreateVATPurchaseLedgerReport(VATLedger, VendorNo);

        // [THEN] A new VAT Ledger Line has been created:
        // [THEN] "Origin. Document No."= "D"
        // [THEN] "Document No."= "D"
        // [THEN] "Package No." = "X"
        LibraryVATLedger.FindVATLedgerLine(VATLedgerLine, VATLedger);
        VerifyVATLedgerLine(VATLedgerLine, DocumentNo, CDNo, false);

        // [THEN] There is a related "VAT Ledger Line CD No." record with "Package No." = "X"
        VerifyVATLedgerLineCDNo(VATLedgerLine, CDNo);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CreateVATPurchaseLedger_Multiple()
    var
        VATLedger: Record "VAT Ledger";
        VATLedgerLine: Record "VAT Ledger Line";
        VendorNo: Code[20];
        DocumentNo: Code[20];
        CDNo: array[2] of Code[30];
    begin
        // [FEATURE] [Purchase]
        // [SCENARIO 203664] REP 12455 "Create VAT Purchase Ledger" creates one "VAT Ledger Line" record and
        // [SCENARIO 203664] several related "VAT Ledger Line CD No." records for a purchase document with several "Package No." values
        Initialize();

        // [GIVEN] Posted purchase document: "Vendor No." = "V", "Document No." = "D", two "Package No." = "X";"Y"
        MockPostedPurchaseInvoiceWithTwoCDNo(VendorNo, DocumentNo, CDNo);
        // [GIVEN] A new VAT Purchase Ledger
        LibraryVATLedger.MockVATLedger(VATLedger, VATLedger.Type::Purchase);

        // [WHEN] Perform "Create Ledger" action for a new VAT Purchase Ledger with "Vendor Filter" = "V"
        LibraryVATLedger.RunCreateVATPurchaseLedgerReport(VATLedger, VendorNo);

        // [THEN] A new VAT Ledger Line has been created:
        // [THEN] "Origin. Document No."= "D"
        // [THEN] "Document No."= "D"
        // [THEN] "Package No." = "DIFFERENT" (const text)
        LibraryVATLedger.FindVATLedgerLine(VATLedgerLine, VATLedger);
        VerifyVATLedgerLine(VATLedgerLine, DocumentNo, DIFFERENTTxt, false);

        // [THEN] There are two related "VAT Ledger Line CD No." records, one with "Package No." = "X", another with "Package No." = "Y"
        VerifyTwoVATLedgerLineCDNo(VATLedgerLine, CDNo);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CreateVATPurchaseLedger_ClearsLines()
    var
        VATLedger: Record "VAT Ledger";
        VATLedgerLine: Record "VAT Ledger Line";
        VATLedgerLineCDNo: Record "VAT Ledger Line CD No.";
        VendorNo: Code[20];
        DocumentNo: Code[20];
        CDNo: Code[30];
    begin
        // [FEATURE] [Purchase]
        // [SCENARIO 203664] REP 12455 "Create VAT Purchase Ledger" clears existing "VAT Ledger Line" and "VAT Ledger Line CD No." records
        Initialize();

        // [GIVEN] Posted purchase document
        MockPostedPurchaseInvoiceWithCDNo(VendorNo, DocumentNo, CDNo);
        // [GIVEN] A new VAT Purchase Ledger
        LibraryVATLedger.MockVATLedger(VATLedger, VATLedger.Type::Purchase);
        // [GIVEN] Perform "Create Ledger" action for a new VAT Purchase Ledger
        LibraryVATLedger.RunCreateVATPurchaseLedgerReport(VATLedger, VendorNo);
        LibraryVATLedger.FindVATLedgerLine(VATLedgerLine, VATLedger);

        // [WHEN] Perform "Create Ledger" action again
        LibraryVATLedger.RunCreateVATPurchaseLedgerReport(VATLedger, VendorNo);

        // [THEN] There is one "VAT Ledger Line"
        Assert.RecordCount(VATLedgerLine, 1);

        // [THEN] There is one related "VAT Ledger Line CD No."
        FilterVATLedgerLineCDNo(VATLedgerLineCDNo, VATLedgerLine);
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
        CDNo: Code[30];
    begin
        // [FEATURE] [Sales]
        // [SCENARIO 203664] REP 12456 "Create VAT Sales Ledger" creates one "VAT Ledger Line" record and
        // [SCENARIO 203664] one related "VAT Ledger Line CD No." record for a sales document with a single "Package No." value
        Initialize();

        // [GIVEN] Posted sales document: "Customer No." = "C", "Document No." = "D", "Package No." = "X"
        MockPostedSalesInvoiceWithCDNo(CustomerNo, DocumentNo, CDNo);
        // [GIVEN] A new VAT Sales Ledger
        LibraryVATLedger.MockVATLedger(VATLedger, VATLedger.Type::Sales);

        // [WHEN] Perform "Create Ledger" action for a new VAT Sales Ledger with "Csutomer Filter" = "C"
        LibraryVATLedger.RunCreateVATSalesLedgerReport(VATLedger, CustomerNo);

        // [THEN] A new VAT Ledger Line has been created:
        // [THEN] "Origin. Document No."= "D"
        // [THEN] "Document No."= "D"
        // [THEN] "Package No." = "X"
        LibraryVATLedger.FindVATLedgerLine(VATLedgerLine, VATLedger);
        VerifyVATLedgerLine(VATLedgerLine, DocumentNo, CDNo, false);

        // [THEN] There is a related "VAT Ledger Line CD No." record with "Package No." = "X"
        VerifyVATLedgerLineCDNo(VATLedgerLine, CDNo);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CreateVATSalesLedger_Multiple()
    var
        VATLedger: Record "VAT Ledger";
        VATLedgerLine: Record "VAT Ledger Line";
        CustomerNo: Code[20];
        DocumentNo: Code[20];
        CDNo: array[2] of Code[30];
    begin
        // [FEATURE] [Sales]
        // [SCENARIO 203664] REP 12456 "Create VAT Sales Ledger" creates one "VAT Ledger Line" record and
        // [SCENARIO 203664] several related "VAT Ledger Line CD No." records for a sales document with several "Package No." values
        Initialize();

        // [GIVEN] Posted sales document: "Customer No." = "C", "Document No." = "D", two "Package No." = "X";"Y"
        MockPostedSalesInvoiceWithTwoCDNo(CustomerNo, DocumentNo, CDNo);
        // [GIVEN] A new VAT Sales Ledger
        LibraryVATLedger.MockVATLedger(VATLedger, VATLedger.Type::Sales);

        // [WHEN] Perform "Create Ledger" action for a new VAT Sales Ledger with "Csutomer Filter" = "C"
        LibraryVATLedger.RunCreateVATSalesLedgerReport(VATLedger, CustomerNo);

        // [THEN] A new VAT Ledger Line has been created:
        // [THEN] "Origin. Document No."= "D"
        // [THEN] "Document No."= "D"
        // [THEN] "Package No." = "DIFFERENT" (const text)
        LibraryVATLedger.FindVATLedgerLine(VATLedgerLine, VATLedger);
        VerifyVATLedgerLine(VATLedgerLine, DocumentNo, DIFFERENTTxt, false);

        // [THEN] There are two related "VAT Ledger Line CD No." records, one with "Package No." = "X", another with "Package No." = "Y"
        VerifyTwoVATLedgerLineCDNo(VATLedgerLine, CDNo);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CreateVATSalesLedger_ClearLines()
    var
        VATLedger: Record "VAT Ledger";
        VATLedgerLine: Record "VAT Ledger Line";
        VATLedgerLineCDNo: Record "VAT Ledger Line CD No.";
        CustomerNo: Code[20];
        DocumentNo: Code[20];
        CDNo: Code[30];
    begin
        // [FEATURE] [Sales]
        // [SCENARIO 203664] REP 12456 "Create VAT Sales Ledger" clears existing "VAT Ledger Line" and "VAT Ledger Line CD No." records
        Initialize();

        // [GIVEN] Posted sales document
        MockPostedSalesInvoiceWithCDNo(CustomerNo, DocumentNo, CDNo);
        // [GIVEN] A new VAT Sales Ledger
        LibraryVATLedger.MockVATLedger(VATLedger, VATLedger.Type::Sales);
        // [WHEN] Perform "Create Ledger" action for a new VAT Sales Ledger
        LibraryVATLedger.RunCreateVATSalesLedgerReport(VATLedger, CustomerNo);
        LibraryVATLedger.FindVATLedgerLine(VATLedgerLine, VATLedger);

        // [WHEN] Perform "Create Ledger" action again
        LibraryVATLedger.RunCreateVATSalesLedgerReport(VATLedger, CustomerNo);

        // [THEN] There is one "VAT Ledger Line"
        Assert.RecordCount(VATLedgerLine, 1);

        // [THEN] There is one related "VAT Ledger Line CD No."
        FilterVATLedgerLineCDNo(VATLedgerLineCDNo, VATLedgerLine);
        Assert.RecordCount(VATLedgerLine, 1);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CreateVATPurchaseLedger_AddSheet_Single()
    var
        VATLedger: Record "VAT Ledger";
        VATLedgerLine: Record "VAT Ledger Line";
        VendorNo: Code[20];
        DocumentNo: Code[20];
        CDNo: Code[30];
    begin
        // [FEATURE] [Purchase] [Add. Sheet]
        // [SCENARIO 203664] REP 14962 "Create VAT Purch. Led. Ad. Sh." creates one "VAT Ledger Line" record and
        // [SCENARIO 203664] one related "VAT Ledger Line CD No." record for a purchase document with a single "Package No." value
        Initialize();

        // [GIVEN] Posted purchase document: "Vendor No." = "V", "Document No." = "D", "Package No." = "X"
        MockPostedPurchaseInvoiceWithCDNoAddSheet(VendorNo, DocumentNo, CDNo);
        // [GIVEN] A new VAT Purchase Ledger
        LibraryVATLedger.MockVATLedger(VATLedger, VATLedger.Type::Purchase);

        // [WHEN] Perform "Create Additional Sheet" action for a new VAT Purchase Ledger with "Vendor Filter" = "V"
        LibraryVATLedger.RunCreateVATPurchLedAdShReport(VATLedger, VendorNo);

        // [THEN] A new VAT Ledger Line has been created:
        // [THEN] "Origin. Document No."= "D"
        // [THEN] "Document No."= "D"
        // [THEN] "Package No." = "X"
        // [THEN] "Additional Sheet" = TRUE
        LibraryVATLedger.FindVATLedgerLine(VATLedgerLine, VATLedger);
        VerifyVATLedgerLine(VATLedgerLine, DocumentNo, CDNo, true);

        // [THEN] There is a related "VAT Ledger Line CD No." record with "Package No." = "X"
        VerifyVATLedgerLineCDNo(VATLedgerLine, CDNo);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CreateVATPurchaseLedger_AddSheet_Multiple()
    var
        VATLedger: Record "VAT Ledger";
        VATLedgerLine: Record "VAT Ledger Line";
        VendorNo: Code[20];
        DocumentNo: Code[20];
        CDNo: array[2] of Code[30];
    begin
        // [FEATURE] [Purchase] [Add. Sheet]
        // [SCENARIO 203664] REP 14962 "Create VAT Purch. Led. Ad. Sh." creates one "VAT Ledger Line" record and
        // [SCENARIO 203664] several related "VAT Ledger Line CD No." records for a purchase document with several "Package No." values
        Initialize();

        // [GIVEN] Posted purchase document: "Vendor No." = "V", "Document No." = "D", two "Package No." = "X";"Y"
        MockPostedPurchaseInvoiceWithTwoCDNoAddSheet(VendorNo, DocumentNo, CDNo);
        // [GIVEN] A new VAT Purchase Ledger
        LibraryVATLedger.MockVATLedger(VATLedger, VATLedger.Type::Purchase);

        // [WHEN] Perform "Create Additional Sheet" action for a new VAT Purchase Ledger with "Vendor Filter" = "V"
        LibraryVATLedger.RunCreateVATPurchLedAdShReport(VATLedger, VendorNo);

        // [THEN] A new VAT Ledger Line has been created:
        // [THEN] "Origin. Document No."= "D"
        // [THEN] "Document No."= "D"
        // [THEN] "Package No." = "DIFFERENT" (const text)
        // [THEN] "Additional Sheet" = TRUE
        LibraryVATLedger.FindVATLedgerLine(VATLedgerLine, VATLedger);
        VerifyVATLedgerLine(VATLedgerLine, DocumentNo, DIFFERENTTxt, true);

        // [THEN] There are two related "VAT Ledger Line CD No." records, one with "Package No." = "X", another with "Package No." = "Y"
        VerifyTwoVATLedgerLineCDNo(VATLedgerLine, CDNo);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CreateVATPurchaseLedger_AddSheet_ClearLines()
    var
        VATLedger: Record "VAT Ledger";
        VATLedgerLine: Record "VAT Ledger Line";
        VATLedgerLineCDNo: Record "VAT Ledger Line CD No.";
        VendorNo: Code[20];
        DocumentNo: Code[20];
        CDNo: Code[30];
    begin
        // [FEATURE] [Purchase] [Add. Sheet]
        // [SCENARIO 203664] REP 14962 "Create VAT Purch. Led. Ad. Sh." clears existing "VAT Ledger Line" and "VAT Ledger Line CD No." records
        Initialize();

        // [GIVEN] Posted purchase document
        MockPostedPurchaseInvoiceWithCDNoAddSheet(VendorNo, DocumentNo, CDNo);
        // [GIVEN] A new VAT Purchase Ledger
        LibraryVATLedger.MockVATLedger(VATLedger, VATLedger.Type::Purchase);
        // [GIVEN] Perform "Create Additional Sheet" action for a new VAT Purchase Ledger
        LibraryVATLedger.RunCreateVATPurchLedAdShReport(VATLedger, VendorNo);
        LibraryVATLedger.FindVATLedgerLine(VATLedgerLine, VATLedger);

        // [WHEN] Perform "Create Additional Sheet" action again
        LibraryVATLedger.RunCreateVATPurchLedAdShReport(VATLedger, VendorNo);

        // [THEN] There is one "VAT Ledger Line"
        Assert.RecordCount(VATLedgerLine, 1);

        // [THEN] There is one related "VAT Ledger Line CD No."
        FilterVATLedgerLineCDNo(VATLedgerLineCDNo, VATLedgerLine);
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
        CDNo: Code[30];
    begin
        // [FEATURE] [Sales] [Add. Sheet]
        // [SCENARIO 203664] REP 14963 "Create VAT Sales Led. Ad. Sh." creates one "VAT Ledger Line" record and
        // [SCENARIO 203664] one related "VAT Ledger Line CD No." record for a sales document with a single "Package No." value
        Initialize();

        // [GIVEN] Posted sales document: "Customer No." = "C", "Document No." = "D", "Package No." = "X"
        MockPostedSalesInvoiceWithCDNoAddSHeet(CustomerNo, DocumentNo, CDNo);
        // [GIVEN] A new VAT Sales Ledger
        LibraryVATLedger.MockVATLedger(VATLedger, VATLedger.Type::Sales);

        // [WHEN] Perform "Create Ledger" action for a new VAT Sales Ledger with "Csutomer Filter" = "C"
        LibraryVATLedger.RunCreateVATSalesLedAdShReport(VATLedger, CustomerNo);

        // [THEN] A new VAT Ledger Line has been created:
        // [THEN] "Origin. Document No."= "D"
        // [THEN] "Document No."= "D"
        // [THEN] "Package No." = "X"
        // [THEN] "Additional Sheet" = TRUE
        LibraryVATLedger.FindVATLedgerLine(VATLedgerLine, VATLedger);
        VerifyVATLedgerLine(VATLedgerLine, DocumentNo, CDNo, true);

        // [THEN] There is a related "VAT Ledger Line CD No." record with "Package No." = "X"
        VerifyVATLedgerLineCDNo(VATLedgerLine, CDNo);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CreateVATSalesLedger_AddSheet_Multiple()
    var
        VATLedger: Record "VAT Ledger";
        VATLedgerLine: Record "VAT Ledger Line";
        CustomerNo: Code[20];
        DocumentNo: Code[20];
        CDNo: array[2] of Code[30];
    begin
        // [FEATURE] [Sales] [Add. Sheet]
        // [SCENARIO 203664] REP 14963 "Create VAT Sales Led. Ad. Sh." creates one "VAT Ledger Line" record and
        // [SCENARIO 203664] several related "VAT Ledger Line CD No." records for a sales document with several "Package No." values
        Initialize();

        // [GIVEN] Posted sales document: "Customer No." = "C", "Document No." = "D", two "Package No." = "X";"Y"
        MockPostedSalesInvoiceWithTwoCDNoAddSheet(CustomerNo, DocumentNo, CDNo);
        // [GIVEN] A new VAT Sales Ledger
        LibraryVATLedger.MockVATLedger(VATLedger, VATLedger.Type::Sales);

        // [WHEN] Perform "Create Ledger" action for a new VAT Sales Ledger with "Csutomer Filter" = "C"
        LibraryVATLedger.RunCreateVATSalesLedAdShReport(VATLedger, CustomerNo);

        // [THEN] A new VAT Ledger Line has been created:
        // [THEN] "Origin. Document No."= "D"
        // [THEN] "Document No."= "D"
        // [THEN] "Package No." = "DIFFERENT" (const text)
        // [THEN] "Additional Sheet" = TRUE
        LibraryVATLedger.FindVATLedgerLine(VATLedgerLine, VATLedger);
        VerifyVATLedgerLine(VATLedgerLine, DocumentNo, DIFFERENTTxt, true);

        // [THEN] There are two related "VAT Ledger Line CD No." records, one with "Package No." = "X", another with "Package No." = "Y"
        VerifyTwoVATLedgerLineCDNo(VATLedgerLine, CDNo);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CreateVATSalesLedger_AddSheet_ClearLines()
    var
        VATLedger: Record "VAT Ledger";
        VATLedgerLine: Record "VAT Ledger Line";
        VATLedgerLineCDNo: Record "VAT Ledger Line CD No.";
        CustomerNo: Code[20];
        DocumentNo: Code[20];
        CDNo: Code[30];
    begin
        // [FEATURE] [Sales] [Add. Sheet]
        // [SCENARIO 203664] REP 14963 "Create VAT Sales Led. Ad. Sh." clears existing "VAT Ledger Line" and "VAT Ledger Line CD No." records
        Initialize();

        // [GIVEN] Posted sales document
        MockPostedSalesInvoiceWithCDNoAddSHeet(CustomerNo, DocumentNo, CDNo);
        // [GIVEN] A new VAT Sales Ledger
        LibraryVATLedger.MockVATLedger(VATLedger, VATLedger.Type::Sales);
        // [GIVEN] Perform "Create Ledger" action for a new VAT Sales Ledger
        LibraryVATLedger.RunCreateVATSalesLedAdShReport(VATLedger, CustomerNo);
        LibraryVATLedger.FindVATLedgerLine(VATLedgerLine, VATLedger);

        // [WHEN] Perform "Create Ledger" action again
        LibraryVATLedger.RunCreateVATSalesLedAdShReport(VATLedger, CustomerNo);

        // [THEN] There is one "VAT Ledger Line"
        Assert.RecordCount(VATLedgerLine, 1);

        // [THEN] There is one related "VAT Ledger Line CD No."
        FilterVATLedgerLineCDNo(VATLedgerLineCDNo, VATLedgerLine);
        Assert.RecordCount(VATLedgerLine, 1);
    end;

    [Test]
    [HandlerFunctions('VATLedgerExportXML_RPH,MessageHandler')]
    [Scope('OnPrem')]
    procedure XML_Purchase_EmptyCDNo()
    var
        VATLedger: Record "VAT Ledger";
        VendorNo: Code[20];
        DocumentNo: Code[20];
    begin
        // [FEATURE] [XML] [Purchase]
        // [SCENARIO 203664] REP 12461 "VAT Ledger Export XML" exports VAT Purchase Ledger without "Package No." value
        Initialize();

        // [GIVEN] Posted purchase document: "Vendor No." = "V", "Document No." = "D", "Package No." = ""
        LibraryVATLedger.MockPurchaseVATEntry(DocumentNo, VendorNo);
        // [GIVEN] A new VAT Purchase Ledger
        LibraryVATLedger.MockVATLedger(VATLedger, VATLedger.Type::Purchase);
        // [GIVEN] Run "Create Ledger" action for a new VAT Purchase Ledger with "Vendor Filter" = "V"
        LibraryVATLedger.RunCreateVATPurchaseLedgerReport(VATLedger, VendorNo);

        // [WHEN] Perform "Export Ledger XML Format" action
        RunVATLedgerExportXMLReport(VATLedger, false);

        // [THEN] XML has been exported:
        // [THEN] There is a node "KnPokStr" with attribute "NomScFProd" = "D"
        // [THEN] There is no attribute "NomTD" under the "KnPokStr" node
        // [THEN] There is no node "SvRegNom" under the "KnPokStr" node
        LibraryXMLRead.VerifyAttributeValueInSubtree(KnigaPokupTxt, KnPokStrTxt, NomScFProdTxt, DocumentNo);
        LibraryXMLRead.VerifyAttributeAbsenceInSubtree(KnigaPokupTxt, KnPokStrTxt, NomTDTxt);
        LibraryXMLRead.VerifyNodeAbsence(SvRegNomTxt);
    end;

    [Test]
    [HandlerFunctions('VATLedgerExportXML_RPH,MessageHandler')]
    [Scope('OnPrem')]
    procedure XML_Purchase_Single()
    var
        VATLedger: Record "VAT Ledger";
        VendorNo: Code[20];
        DocumentNo: Code[20];
        CDNo: Code[30];
    begin
        // [FEATURE] [XML] [Purchase]
        // [SCENARIO 203664] REP 12461 "VAT Ledger Export XML" exports VAT Purchase Ledger with a single "Package No." value
        Initialize();

        // [GIVEN] Posted purchase document: "Vendor No." = "V", "Document No." = "D", "Package No." = "X"
        MockPostedPurchaseInvoiceWithCDNo(VendorNo, DocumentNo, CDNo);
        // [GIVEN] A new VAT Purchase Ledger
        LibraryVATLedger.MockVATLedger(VATLedger, VATLedger.Type::Purchase);
        // [GIVEN] Run "Create Ledger" action for a new VAT Purchase Ledger with "Vendor Filter" = "V"
        LibraryVATLedger.RunCreateVATPurchaseLedgerReport(VATLedger, VendorNo);

        // [WHEN] Perform "Export Ledger XML Format" action
        RunVATLedgerExportXMLReport(VATLedger, false);

        // [THEN] XML has been exported:
        // [THEN] There is a node "KnPokStr" with attribute "NomScFProd" = "D"
        // [THEN] There is no attribute "NomTD" under the "KnPokStr" node
        // [THEN] There is a node "SvRegNom" with attribute "RegNomProsl" = "X" under the "KnPokStr" node
        LibraryXMLRead.VerifyAttributeValueInSubtree(KnigaPokupTxt, KnPokStrTxt, NomScFProdTxt, DocumentNo);
        LibraryXMLRead.VerifyAttributeAbsenceInSubtree(KnigaPokupTxt, KnPokStrTxt, NomTDTxt);
        LibraryXMLRead.VerifyAttributeValueInSubtree(KnPokStrTxt, SvRegNomTxt, RegNomProslTxt, CDNo);
    end;

    [Test]
    [HandlerFunctions('VATLedgerExportXML_RPH,MessageHandler')]
    [Scope('OnPrem')]
    procedure XML_Purchase_Multiple()
    var
        VATLedger: Record "VAT Ledger";
        VendorNo: Code[20];
        DocumentNo: Code[20];
        CDNo: array[2] of Code[30];
    begin
        // [FEATURE] [XML] [Purchase]
        // [SCENARIO 203664] REP 12461 "VAT Ledger Export XML" exports VAT Purchase Ledger with several "Package No." values
        Initialize();

        // [GIVEN] Posted purchase document: "Vendor No." = "V", "Document No." = "D", two "Package No." = "X";"Y"
        MockPostedPurchaseInvoiceWithTwoCDNo(VendorNo, DocumentNo, CDNo);
        // [GIVEN] A new VAT Purchase Ledger
        LibraryVATLedger.MockVATLedger(VATLedger, VATLedger.Type::Purchase);
        // [GIVEN] Run "Create Ledger" action for a new VAT Purchase Ledger with "Vendor Filter" = "V"
        LibraryVATLedger.RunCreateVATPurchaseLedgerReport(VATLedger, VendorNo);

        // [WHEN] Perform "Export Ledger XML Format" action
        RunVATLedgerExportXMLReport(VATLedger, false);

        // [THEN] XML has been exported:
        // [THEN] There is a node "KnPokStr" with attribute "NomScFProd" = "D"
        // [THEN] There is no attribute "NomTD" under the "KnPokStr" node
        // [THEN] There is a node "SvRegNom" with attribute "RegNomProsl" = "X" under the "KnPokStr" node
        // [THEN] There is a node "SvRegNom" with attribute "RegNomProsl" = "Y" under the "KnPokStr" node
        LibraryXMLRead.VerifyAttributeValueInSubtree(KnigaPokupTxt, KnPokStrTxt, NomScFProdTxt, DocumentNo);
        LibraryXMLRead.VerifyAttributeAbsenceInSubtree(KnigaPokupTxt, KnPokStrTxt, NomTDTxt);
        LibraryXMLRead.VerifyAttributeValueInSubtree(KnPokStrTxt, SvRegNomTxt, RegNomProslTxt, CDNo[2]);
        // LibraryXMLRead.VerifyAttributeValueInSubtree(KnPokStrTxt,SvRegNomTxt,RegNomProslTxt,CDNo[2]);
    end;

    [Test]
    [HandlerFunctions('VATLedgerExportXML_RPH,MessageHandler')]
    [Scope('OnPrem')]
    procedure XML_Sales_EmptyCDNo()
    var
        VATLedger: Record "VAT Ledger";
        CustomerNo: Code[20];
        DocumentNo: Code[20];
    begin
        // [FEATURE] [XML] [Sales]
        // [SCENARIO 203664] REP 12461 "VAT Ledger Export XML" exports VAT Sales Ledger without "Package No." value
        Initialize();

        // [GIVEN] Posted sales document: "Customer No." = "C", "Document No." = "D", "Package No." = ""
        LibraryVATLedger.MockSalesVATEntry(DocumentNo, CustomerNo);
        // [GIVEN] A new VAT Sales Ledger
        LibraryVATLedger.MockVATLedger(VATLedger, VATLedger.Type::Sales);
        // [GIVEN] Run "Create Ledger" action for a new VAT Sales Ledger with "Customer Filter" = "C"
        LibraryVATLedger.RunCreateVATSalesLedgerReport(VATLedger, CustomerNo);

        // [WHEN] Perform "Export Ledger XML Format" action
        RunVATLedgerExportXMLReport(VATLedger, false);

        // [THEN] XML has been exported:
        // [THEN] There is a node "KnPokStr" with attribute "NomScFProd" = "D"
        // [THEN] There is no attribute "NomTD" under the "KnPokStr" node
        // [THEN] There is no node "SvRegNom" under the "KnPokStr" node
        LibraryXMLRead.VerifyAttributeValueInSubtree(KnigaProdTxt, KnProdStrTxt, NomScFProdTxt, DocumentNo);
        LibraryXMLRead.VerifyAttributeAbsenceInSubtree(KnigaProdTxt, KnProdStrTxt, NomTDTxt);
        LibraryXMLRead.VerifyNodeAbsence(SvRegNomTxt);
    end;

    [Test]
    [HandlerFunctions('VATLedgerExportXML_RPH,MessageHandler')]
    [Scope('OnPrem')]
    procedure XML_Sales_Single()
    var
        VATLedger: Record "VAT Ledger";
        CustomerNo: Code[20];
        DocumentNo: Code[20];
        CDNo: Code[30];
    begin
        // [FEATURE] [XML] [Sales]
        // [SCENARIO 203664] REP 12461 "VAT Ledger Export XML" exports VAT Sales Ledger with a single "Package No." value
        Initialize();

        // [GIVEN] Posted sales document: "Customer No." = "C", "Document No." = "D", "Package No." = "X"
        MockPostedSalesInvoiceWithCDNo(CustomerNo, DocumentNo, CDNo);
        // [GIVEN] A new VAT Sales Ledger
        LibraryVATLedger.MockVATLedger(VATLedger, VATLedger.Type::Sales);
        // [GIVEN] Run "Create Ledger" action for a new VAT Sales Ledger with "Customer Filter" = "C"
        LibraryVATLedger.RunCreateVATSalesLedgerReport(VATLedger, CustomerNo);

        // [WHEN] Perform "Export Ledger XML Format" action
        RunVATLedgerExportXMLReport(VATLedger, false);

        // [THEN] XML has been exported:
        // [THEN] There is a node "KnPokStr" with attribute "NomScFProd" = "D"
        // [THEN] There is no attribute "NomTD" under the "KnPokStr" node
        // [THEN] There is a node "SvRegNom" with attribute "RegNomProsl" = "X" under the "KnPokStr" node
        LibraryXMLRead.VerifyAttributeValueInSubtree(KnigaProdTxt, KnProdStrTxt, NomScFProdTxt, DocumentNo);
        LibraryXMLRead.VerifyAttributeAbsenceInSubtree(KnigaProdTxt, KnProdStrTxt, NomTDTxt);
        LibraryXMLRead.VerifyAttributeValueInSubtree(KnProdStrTxt, SvRegNomTxt, RegNomProslTxt, CDNo);
    end;

    [Test]
    [HandlerFunctions('VATLedgerExportXML_RPH,MessageHandler')]
    [Scope('OnPrem')]
    procedure XML_Sales_Multiple()
    var
        VATLedger: Record "VAT Ledger";
        CustomerNo: Code[20];
        DocumentNo: Code[20];
        CDNo: array[2] of Code[30];
    begin
        // [FEATURE] [XML] [Sales]
        // [SCENARIO 203664] REP 12461 "VAT Ledger Export XML" exports VAT Sales Ledger with several "Package No." values
        Initialize();

        // [GIVEN] Posted sales document: "Customer No." = "C", "Document No." = "D", two "Package No." = "X";"Y"
        MockPostedSalesInvoiceWithTwoCDNo(CustomerNo, DocumentNo, CDNo);
        // [GIVEN] A new VAT Sales Ledger
        LibraryVATLedger.MockVATLedger(VATLedger, VATLedger.Type::Sales);
        // [GIVEN] Run "Create Ledger" action for a new VAT Sales Ledger with "Customer Filter" = "C"
        LibraryVATLedger.RunCreateVATSalesLedgerReport(VATLedger, CustomerNo);

        // [WHEN] Perform "Export Ledger XML Format" action
        RunVATLedgerExportXMLReport(VATLedger, false);

        // [THEN] XML has been exported:
        // [THEN] There is a node "KnPokStr" with attribute "NomScFProd" = "D"
        // [THEN] There is no attribute "NomTD" under the "KnPokStr" node
        // [THEN] There is a node "SvRegNom" with attribute "RegNomProsl" = "X" under the "KnProdStr" node
        // [THEN] There is a node "SvRegNom" with attribute "RegNomProsl" = "Y" under the "KnProdStr" node
        LibraryXMLRead.VerifyAttributeValueInSubtree(KnigaProdTxt, KnProdStrTxt, NomScFProdTxt, DocumentNo);
        LibraryXMLRead.VerifyAttributeAbsenceInSubtree(KnigaProdTxt, KnProdStrTxt, NomTDTxt);
        LibraryXMLRead.VerifyAttributeValueInSubtree(KnProdStrTxt, SvRegNomTxt, RegNomProslTxt, CDNo[1]);
        // LibraryXMLRead.VerifyAttributeValueInSubtree(KnProdStrTxt,SvRegNomTxt,RegNomProslTxt,CDNo[2]);
    end;

    [Test]
    [HandlerFunctions('VATLedgerExportXML_RPH,MessageHandler')]
    [Scope('OnPrem')]
    procedure XML_Purchase_AddSheet_EmptyCDNo()
    var
        VATLedger: Record "VAT Ledger";
        VendorNo: Code[20];
        DocumentNo: Code[20];
    begin
        // [FEATURE] [XML] [Purchase] [Add. Sheet]
        // [SCENARIO 203664] REP 12461 "VAT Ledger Export XML" exports add. sheet VAT Purchase Ledger without "Package No." value
        Initialize();

        // [GIVEN] Posted purchase document: "Vendor No." = "V", "Document No." = "D", "Package No." = ""
        LibraryVATLedger.MockPurchaseVATEntryAddSheet(DocumentNo, VendorNo);
        // [GIVEN] A new VAT Purchase Ledger
        LibraryVATLedger.MockVATLedger(VATLedger, VATLedger.Type::Purchase);
        // [GIVEN] Run "Create Additional Sheet" action for a new VAT Purchase Ledger with "Vendor Filter" = "V"
        LibraryVATLedger.RunCreateVATPurchLedAdShReport(VATLedger, VendorNo);

        // [WHEN] Perform "Export Add. Sheet XML Format" action
        RunVATLedgerExportXMLReport(VATLedger, true);

        // [THEN] XML has been exported:
        // [THEN] There is a node "KnPokStr" with attribute "NomScFProd" = "D"
        // [THEN] There is no attribute "NomTD" under the "KnPokStr" node
        // [THEN] There is a node "SvRegNom" with attribute "RegNomProsl" = "X" under the "KnPokStr" node
        LibraryXMLRead.VerifyAttributeValueInSubtree(KnigaPokupDLTxt, KnPokDLStrTxt, NomScFProdTxt, DocumentNo);
        LibraryXMLRead.VerifyAttributeAbsenceInSubtree(KnigaPokupDLTxt, KnPokDLStrTxt, NomTDTxt);
        LibraryXMLRead.VerifyAttributeValueInSubtree(KnPokDLStrTxt, SvRegNomTxt, RegNomProslTxt, CDNo);
    end;

    [Test]
    [HandlerFunctions('VATLedgerExportXML_RPH,MessageHandler')]
    [Scope('OnPrem')]
    procedure XML_Purchase_AddSheet_Single()
    var
        VATLedger: Record "VAT Ledger";
        VendorNo: Code[20];
        DocumentNo: Code[20];
        CDNo: Code[30];
    begin
        // [FEATURE] [XML] [Purchase] [Add. Sheet]
        // [SCENARIO 203664] REP 12461 "VAT Ledger Export XML" exports add. sheet VAT Purchase Ledger with a single "Package No." value
        Initialize();

        // [GIVEN] Posted purchase document: "Vendor No." = "V", "Document No." = "D", "Package No." = "X"
        MockPostedPurchaseInvoiceWithCDNoAddSheet(VendorNo, DocumentNo, CDNo);
        // [GIVEN] A new VAT Purchase Ledger
        LibraryVATLedger.MockVATLedger(VATLedger, VATLedger.Type::Purchase);
        // [GIVEN] Run "Create Additional Sheet" action for a new VAT Purchase Ledger with "Vendor Filter" = "V"
        LibraryVATLedger.RunCreateVATPurchLedAdShReport(VATLedger, VendorNo);

        // [WHEN] Perform "Export Add. Sheet XML Format" action
        RunVATLedgerExportXMLReport(VATLedger, true);

        // [THEN] XML has been exported:
        // [THEN] There is a node "KnPokStr" with attribute "NomScFProd" = "D"
        // [THEN] There is no attribute "NomTD" under the "KnPokStr" node
        // [THEN] There is a node "SvRegNom" with attribute "RegNomProsl" = "X" under the "KnPokDLStr" node
        // [THEN] There is a node "SvRegNom" with attribute "RegNomProsl" = "Y" under the "KnPokDLStr" node
        LibraryXMLRead.VerifyAttributeValueInSubtree(KnigaPokupDLTxt, KnPokDLStrTxt, NomScFProdTxt, DocumentNo);
        LibraryXMLRead.VerifyAttributeAbsenceInSubtree(KnigaPokupDLTxt, KnPokDLStrTxt, NomTDTxt);
        LibraryXMLRead.VerifyAttributeValueInSubtree(KnPokDLStrTxt, SvRegNomTxt, RegNomProslTxt, CDNo[2]);
        // LibraryXMLRead.VerifyAttributeValueInSubtree(KnPokDLStrTxt,SvRegNomTxt,RegNomProslTxt,CDNo[1]);
    end;

    [Test]
    [HandlerFunctions('VATLedgerExportXML_RPH,MessageHandler')]
    [Scope('OnPrem')]
    procedure XML_Purchase_AddSheet_Multiple()
    var
        VATLedger: Record "VAT Ledger";
        VendorNo: Code[20];
        DocumentNo: Code[20];
        CDNo: array[2] of Code[30];
    begin
        // [FEATURE] [XML] [Purchase] [Add. Sheet]
        // [SCENARIO 203664] REP 12461 "VAT Ledger Export XML" exports add. sheet VAT Purchase Ledger with several "Package No." values
        Initialize();

        // [GIVEN] Posted purchase document: "Vendor No." = "V", "Document No." = "D", two "Package No." = "X";"Y"
        MockPostedPurchaseInvoiceWithTwoCDNoAddSheet(VendorNo, DocumentNo, CDNo);
        // [GIVEN] A new VAT Purchase Ledger
        LibraryVATLedger.MockVATLedger(VATLedger, VATLedger.Type::Purchase);
        // [GIVEN] Run "Create Additional Sheet" action for a new VAT Purchase Ledger with "Vendor Filter" = "V"
        LibraryVATLedger.RunCreateVATPurchLedAdShReport(VATLedger, VendorNo);

        // [WHEN] Perform "Export Add. Sheet XML Format" action
        RunVATLedgerExportXMLReport(VATLedger, true);

        // [THEN] XML has been exported:
        // [THEN] There is a node "KnPokStr" with attribute "NomScFProd" = "D"
        // [THEN] There is no attribute "NomTD" under the "KnPokStr" node
        // [THEN] There is no node "SvRegNom" under the "KnPokStr" node
        LibraryXMLRead.VerifyAttributeValueInSubtree(KnigaProdDLTxt, KnProdDLStrTxt, NomScFProdTxt, DocumentNo);
        LibraryXMLRead.VerifyAttributeAbsenceInSubtree(KnigaProdDLTxt, KnProdDLStrTxt, NomTDTxt);
        LibraryXMLRead.VerifyNodeAbsence(SvRegNomTxt);
    end;

    [Test]
    [HandlerFunctions('VATLedgerExportXML_RPH,MessageHandler')]
    [Scope('OnPrem')]
    procedure XML_Sales_AddSheet_EmptyCDNo()
    var
        VATLedger: Record "VAT Ledger";
        CustomerNo: Code[20];
        DocumentNo: Code[20];
    begin
        // [FEATURE] [XML] [Sales] [Add. Sheet]
        // [SCENARIO 203664] REP 12461 "VAT Ledger Export XML" exports add. sheet VAT Sales Ledger without "Package No." value
        Initialize();

        // [GIVEN] Posted sales document: "Customer No." = "C", "Document No." = "D", "Package No." = ""
        LibraryVATLedger.MockSalesVATEntryAddSheet(DocumentNo, CustomerNo);
        // [GIVEN] A new VAT Sales Ledger
        LibraryVATLedger.MockVATLedger(VATLedger, VATLedger.Type::Sales);
        // [GIVEN] Run "Create Additional Sheet" action for a new VAT Sales Ledger with "Customer Filter" = "C"
        LibraryVATLedger.RunCreateVATSalesLedAdShReport(VATLedger, CustomerNo);

        // [WHEN] Perform "Export Add. Sheet XML Format" action
        RunVATLedgerExportXMLReport(VATLedger, true);

        // [THEN] XML has been exported:
        // [THEN] There is a node "KnPokStr" with attribute "NomScFProd" = "D"
        // [THEN] There is no attribute "NomTD" under the "KnPokStr" node
        // [THEN] There is a node "SvRegNom" with attribute "RegNomProsl" = "X" under the "KnPokStr" node
        LibraryXMLRead.VerifyAttributeValueInSubtree(KnigaProdDLTxt, KnProdDLStrTxt, NomScFProdTxt, DocumentNo);
        LibraryXMLRead.VerifyAttributeAbsenceInSubtree(KnigaProdDLTxt, KnProdDLStrTxt, NomTDTxt);
        LibraryXMLRead.VerifyAttributeValueInSubtree(KnProdDLStrTxt, SvRegNomTxt, RegNomProslTxt, CDNo);
    end;

    [Test]
    [HandlerFunctions('VATLedgerExportXML_RPH,MessageHandler')]
    [Scope('OnPrem')]
    procedure XML_Sales_AddSheet_Single()
    var
        VATLedger: Record "VAT Ledger";
        CustomerNo: Code[20];
        DocumentNo: Code[20];
        CDNo: Code[30];
    begin
        // [FEATURE] [XML] [Sales] [Add. Sheet]
        // [SCENARIO 203664] REP 12461 "VAT Ledger Export XML" exports add. sheet VAT Sales Ledger with a single "Package No." value
        Initialize();

        // [GIVEN] Posted sales document: "Customer No." = "C", "Document No." = "D", "Package No." = "X"
        MockPostedSalesInvoiceWithCDNoAddSHeet(CustomerNo, DocumentNo, CDNo);
        // [GIVEN] A new VAT Sales Ledger
        LibraryVATLedger.MockVATLedger(VATLedger, VATLedger.Type::Sales);
        // [GIVEN] Run "Create Additional Sheet" action for a new VAT Sales Ledger with "Customer Filter" = "C"
        LibraryVATLedger.RunCreateVATSalesLedAdShReport(VATLedger, CustomerNo);

        // [WHEN] Perform "Export Add. Sheet XML Format" action
        RunVATLedgerExportXMLReport(VATLedger, true);

        // [THEN] XML has been exported:
        // [THEN] There is a node "KnPokStr" with attribute "NomScFProd" = "D"
        // [THEN] There is no attribute "NomTD" under the "KnPokStr" node
        // [THEN] There is a node "SvRegNom" with attribute "RegNomProsl" = "X" under the "KnProdDLStr" node
        // [THEN] There is a node "SvRegNom" with attribute "RegNomProsl" = "Y" under the "KnProdDLStr" node
        LibraryXMLRead.VerifyAttributeValueInSubtree(KnigaProdDLTxt, KnProdDLStrTxt, NomScFProdTxt, DocumentNo);
        LibraryXMLRead.VerifyAttributeAbsenceInSubtree(KnigaProdDLTxt, KnProdDLStrTxt, NomTDTxt);
        LibraryXMLRead.VerifyAttributeValueInSubtree(KnProdDLStrTxt, SvRegNomTxt, RegNomProslTxt, CDNo[1]);
        // LibraryXMLRead.VerifyAttributeValueInSubtree(KnProdDLStrTxt,SvRegNomTxt,RegNomProslTxt,CDNo[2]);
    end;

    [Test]
    [HandlerFunctions('VATLedgerExportXML_RPH,MessageHandler')]
    [Scope('OnPrem')]
    procedure XML_Sales_AddSheet_Multiple()
    var
        VATLedger: Record "VAT Ledger";
        CustomerNo: Code[20];
        DocumentNo: Code[20];
        CDNo: array[2] of Code[30];
    begin
        // [FEATURE] [XML] [Sales] [Add. Sheet]
        // [SCENARIO 203664] REP 12461 "VAT Ledger Export XML" exports add. sheet VAT Sales Ledger with several "Package No." values
        Initialize();

        // [GIVEN] Posted sales document: "Customer No." = "C", "Document No." = "D", two "Package No." = "X";"Y"
        MockPostedSalesInvoiceWithTwoCDNoAddSheet(CustomerNo, DocumentNo, CDNo);
        // [GIVEN] A new VAT Sales Ledger
        LibraryVATLedger.MockVATLedger(VATLedger, VATLedger.Type::Sales);
        // [GIVEN] Run "Create Additional Sheet" action for a new VAT Sales Ledger with "Customer Filter" = "C"
        LibraryVATLedger.RunCreateVATSalesLedAdShReport(VATLedger, CustomerNo);

        // [WHEN] Perform "Export Add. Sheet XML Format" action
        RunVATLedgerExportXMLReport(VATLedger, true);

        // [THEN] XML has been exported:
        // [THEN] There is a node "KnPokStr" with attribute "NomScFProd" = "D"
        // [THEN] There is no attribute "NomTD" under the "KnPokStr" node
        // [THEN] There is a node "RegNomTD" = "X" under the "KnPokStr" node
        // [THEN] There is a node "RegNomTD" = "Y" under the "KnPokStr" node
        LibraryXMLRead.VerifyAttributeValueInSubtree(KnigaProdDLTxt, KnProdDLStrTxt, NomScFProdTxt, DocumentNo);
        LibraryXMLRead.VerifyAttributeAbsenceInSubtree(KnigaProdDLTxt, KnProdDLStrTxt, NomTDTxt);
        LibraryXMLRead.VerifyNodeValueInSubtree(KnProdDLStrTxt, RegNomTDTxt, CDNo[1]);
        LibraryXMLRead.VerifyNodeValueInSubtree(KnProdDLStrTxt, RegNomTDTxt, CDNo[2]);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VATLedgerLine_GetCDNoListString()
    var
        VATLedger: Record "VAT Ledger";
        VATLedgerLine: Record "VAT Ledger Line";
    begin
        // [SCENARIO 251086] TAB 12405 "VAT Ledger Line".GetCDNoListString() returns concatenation string with all CDNo values separated by ";"
        Initialize();

        LibraryVATLedger.MockVATLedger(VATLedger, VATLedger.Type::Sales);
        LibraryVATLedger.MockVATLedgerLineCDNo(VATLedgerLine, 'A');
        LibraryVATLedger.MockVATLedgerLineCDNo(VATLedgerLine, 'B');
        Assert.AreEqual('A;B', VATLedgerLine.GetCDNoListString, '');
    end;

    local procedure Initialize()
    begin
        LibraryVariableStorage.Clear();

        if IsInitialized then
            exit;

        IsInitialized := true;
    end;

    local procedure MockPostedPurchaseInvoiceWithCDNo(var VendorNo: Code[20]; var DocumentNo: Code[20]; var CDNo: Code[30])
    begin
        LibraryVATLedger.MockPurchaseVATEntry(DocumentNo, VendorNo);

        CDNo := LibraryVATLedger.GenerateCDNoValue;
        LibraryVATLedger.MockVendorValueEntryWithCDNo(VendorNo, DocumentNo, CDNo);
    end;

    local procedure MockPostedPurchaseInvoiceWithTwoCDNo(var VendorNo: Code[20]; var DocumentNo: Code[20]; var CDNo: array[2] of Code[30])
    var
        i: Integer;
    begin
        LibraryVATLedger.MockPurchaseVATEntry(DocumentNo, VendorNo);

        for i := 1 to ArrayLen(CDNo) do begin
            CDNo[i] := LibraryVATLedger.GenerateCDNoValue;
            LibraryVATLedger.MockVendorValueEntryWithCDNo(VendorNo, DocumentNo, CDNo[i]);
        end;
    end;

    local procedure MockPostedSalesInvoiceWithCDNo(var CustomerNo: Code[20]; var DocumentNo: Code[20]; var CDNo: Code[30])
    begin
        LibraryVATLedger.MockSalesVATEntry(DocumentNo, CustomerNo);

        CDNo := LibraryVATLedger.GenerateCDNoValue;
        LibraryVATLedger.MockCustomerValueEntryWithCDNo(CustomerNo, DocumentNo, CDNo);
    end;

    local procedure MockPostedSalesInvoiceWithTwoCDNo(var CustomerNo: Code[20]; var DocumentNo: Code[20]; var CDNo: array[2] of Code[30])
    var
        i: Integer;
    begin
        LibraryVATLedger.MockSalesVATEntry(DocumentNo, CustomerNo);

        for i := 1 to ArrayLen(CDNo) do begin
            CDNo[i] := LibraryVATLedger.GenerateCDNoValue;
            LibraryVATLedger.MockCustomerValueEntryWithCDNo(CustomerNo, DocumentNo, CDNo[i]);
        end;
    end;

    local procedure MockPostedPurchaseInvoiceWithCDNoAddSheet(var VendorNo: Code[20]; var DocumentNo: Code[20]; var CDNo: Code[30])
    begin
        LibraryVATLedger.MockPurchaseVATEntryAddSheet(DocumentNo, VendorNo);

        CDNo := LibraryVATLedger.GenerateCDNoValue;
        LibraryVATLedger.MockVendorValueEntryWithCDNo(VendorNo, DocumentNo, CDNo);
    end;

    local procedure MockPostedPurchaseInvoiceWithTwoCDNoAddSheet(var VendorNo: Code[20]; var DocumentNo: Code[20]; var CDNo: array[2] of Code[30])
    var
        i: Integer;
    begin
        LibraryVATLedger.MockPurchaseVATEntryAddSheet(DocumentNo, VendorNo);

        for i := 1 to ArrayLen(CDNo) do begin
            CDNo[i] := LibraryVATLedger.GenerateCDNoValue;
            LibraryVATLedger.MockVendorValueEntryWithCDNo(VendorNo, DocumentNo, CDNo[i]);
        end;
    end;

    local procedure MockPostedSalesInvoiceWithCDNoAddSHeet(var CustomerNo: Code[20]; var DocumentNo: Code[20]; var CDNo: Code[30])
    begin
        LibraryVATLedger.MockSalesVATEntryAddSheet(DocumentNo, CustomerNo);

        CDNo := LibraryVATLedger.GenerateCDNoValue;
        LibraryVATLedger.MockCustomerValueEntryWithCDNo(CustomerNo, DocumentNo, CDNo);
    end;

    local procedure MockPostedSalesInvoiceWithTwoCDNoAddSheet(var CustomerNo: Code[20]; var DocumentNo: Code[20]; var CDNo: array[2] of Code[30])
    var
        i: Integer;
    begin
        LibraryVATLedger.MockSalesVATEntryAddSheet(DocumentNo, CustomerNo);

        for i := 1 to ArrayLen(CDNo) do begin
            CDNo[i] := LibraryVATLedger.GenerateCDNoValue;
            LibraryVATLedger.MockCustomerValueEntryWithCDNo(CustomerNo, DocumentNo, CDNo[i]);
        end;
    end;

    local procedure MockVATLedgerWithTwoLines(var VATLedger: Record "VAT Ledger")
    var
        VATLedgerLine: Record "VAT Ledger Line";
        DummyVATLedgerLineCDNo: Record "VAT Ledger Line CD No.";
    begin
        LibraryVATLedger.MockVATLedger(VATLedger, VATLedger.Type::Purchase);

        LibraryVATLedger.MockVATLedgerLineForTheGivenVATLedger(VATLedgerLine, VATLedger, false);
        LibraryVATLedger.MockVATLedgerLineCDNo(VATLedgerLine, LibraryVATLedger.GenerateCDNoValue);

        LibraryVATLedger.MockVATLedgerLineForTheGivenVATLedger(VATLedgerLine, VATLedger, true);
        LibraryVATLedger.MockVATLedgerLineCDNo(VATLedgerLine, LibraryVATLedger.GenerateCDNoValue);

        VATLedgerLine.SetRange(Type, VATLedger.Type);
        VATLedgerLine.SetRange(Code, VATLedger.Code);
        Assert.RecordCount(VATLedgerLine, 2);

        DummyVATLedgerLineCDNo.SetRange(Type, VATLedger.Type);
        DummyVATLedgerLineCDNo.SetRange(Code, VATLedger.Code);
        Assert.RecordCount(DummyVATLedgerLineCDNo, 2);
    end;

    local procedure MockVendorVATLedgerLineWithTwoCDNo(var VATLedgerLine: Record "VAT Ledger Line"; var CDNo: array[2] of Code[30])
    begin
        MockVATLedgerLineWithTwoCDNo(
          VATLedgerLine, CDNo, VATLedgerLine.Type::Purchase, VATLedgerLine."C/V Type"::Vendor, LibraryVATLedger.MockVendorNo);
    end;

    local procedure MockCustomerVATLedgerLineWithTwoCDNo(var VATLedgerLine: Record "VAT Ledger Line"; var CDNo: array[2] of Code[30])
    begin
        MockVATLedgerLineWithTwoCDNo(
          VATLedgerLine, CDNo, VATLedgerLine.Type::Sales, VATLedgerLine."C/V Type"::Customer, LibraryVATLedger.MockCustomerNo(''));
    end;

    local procedure MockVATLedgerLineWithTwoCDNo(var VATLedgerLine: Record "VAT Ledger Line"; var CDNo: array[2] of Code[30]; Type: Option; CVType: Option; CVNo: Code[20])
    var
        i: Integer;
    begin
        LibraryVATLedger.MockVATLedgerLine(VATLedgerLine, Type, CVType, CVNo);
        for i := 1 to ArrayLen(CDNo) do begin
            CDNo[i] := LibraryVATLedger.GenerateCDNoValue;
            LibraryVATLedger.MockVATLedgerLineCDNo(VATLedgerLine, CDNo[i]);
        end;
    end;

    local procedure RunVATLedgerExportXMLReport(VATLedger: Record "VAT Ledger"; AddSheet: Boolean)
    var
        VATLedgerExportXML: Report "VAT Ledger Export XML";
        FullFileName: Text;
    begin
        Clear(VATLedgerExportXML);
        VATLedgerExportXML.InitializeReport(VATLedger.Type, VATLedger.Code, AddSheet);
        VATLedgerExportXML.UseRequestPage(true);
        Commit();
        VATLedgerExportXML.Run();

        FullFileName := TemporaryPath + '\' + LibraryVariableStorage.DequeueText + '.xml';
        LibraryXMLRead.Initialize(FullFileName);
    end;

    local procedure FilterVATLedgerLineCDNo(var VATLedgerLineCDNo: Record "VAT Ledger Line CD No."; VATLedgerLine: Record "VAT Ledger Line")
    begin
        with VATLedgerLineCDNo do begin
            SetRange(Type, VATLedgerLine.Type);
            SetRange(Code, VATLedgerLine.Code);
            SetRange("Line No.", VATLedgerLine."Line No.");
        end;
    end;

    local procedure LookupPurchaseVATLedgerLineCDNoField(var VATLedgerLineCDNo: TestPage "VAT Ledger Line CD No."; VATLedgerLine: Record "VAT Ledger Line")
    var
        VATPurchaseLedgerSubform: TestPage "VAT Purchase Ledger Subform";
    begin
        VATPurchaseLedgerSubform.OpenView();
        VATPurchaseLedgerSubform.GotoRecord(VATLedgerLine);
        VATLedgerLineCDNo.Trap();
        VATPurchaseLedgerSubform."Package No.".Lookup();
    end;

    local procedure LookupSalesVATLedgerLineCDNoField(var VATLedgerLineCDNo: TestPage "VAT Ledger Line CD No."; VATLedgerLine: Record "VAT Ledger Line")
    var
        VATSalesLedgerSubform: TestPage "VAT Sales Ledger Subform";
    begin
        VATSalesLedgerSubform.OpenView();
        VATSalesLedgerSubform.GotoRecord(VATLedgerLine);
        VATLedgerLineCDNo.Trap();
        VATSalesLedgerSubform."Package No.".Lookup();
    end;

    local procedure VerifyVATLedgerLine(VATLedgerLine: Record "VAT Ledger Line"; ExpectedDocumentNo: Code[20]; ExpectedCDNo: Code[30]; ExpectedAddSheet: Boolean)
    begin
        with VATLedgerLine do begin
            Assert.AreEqual(ExpectedDocumentNo, "Origin. Document No.", FieldCaption("Origin. Document No."));
            Assert.AreEqual(ExpectedDocumentNo, "Document No.", FieldCaption("Document No."));
            Assert.AreEqual(ExpectedCDNo, "Package No.", FieldCaption("Package No."));
            Assert.AreEqual(ExpectedAddSheet, "Additional Sheet", FieldCaption("Additional Sheet"));
        end;
    end;

    local procedure VerifyVATLedgerLineCDNo(VATLedgerLine: Record "VAT Ledger Line"; CDNo: Code[30])
    var
        VATLedgerLineCDNo: Record "VAT Ledger Line CD No.";
    begin
        FilterVATLedgerLineCDNo(VATLedgerLineCDNo, VATLedgerLine);
        VATLedgerLineCDNo.FindFirst();
        Assert.AreEqual(CDNo, VATLedgerLineCDNo."Package No.", VATLedgerLineCDNo.FieldCaption("Package No."));
    end;

    local procedure VerifyOneVATLedgerLineCDNo(VATLedgerLine: Record "VAT Ledger Line"; CDNo: Code[30])
    var
        VATLedgerLineCDNo: Record "VAT Ledger Line CD No.";
    begin
        FilterVATLedgerLineCDNo(VATLedgerLineCDNo, VATLedgerLine);
        VATLedgerLineCDNo.FindFirst();
        Assert.AreEqual(CDNo, VATLedgerLineCDNo."Package No.", VATLedgerLineCDNo.FieldCaption("Package No."));
        Assert.RecordCount(VATLedgerLineCDNo, 1);
    end;

    local procedure VerifyTwoVATLedgerLineCDNo(VATLedgerLine: Record "VAT Ledger Line"; CDNo: array[2] of Code[30])
    var
        VATLedgerLineCDNo: Record "VAT Ledger Line CD No.";
    begin
        FilterVATLedgerLineCDNo(VATLedgerLineCDNo, VATLedgerLine);
        Assert.RecordCount(VATLedgerLineCDNo, 2);

        VATLedgerLineCDNo.SetRange("Package No.", CDNo[1]);
        Assert.RecordCount(VATLedgerLineCDNo, 1);

        VATLedgerLineCDNo.SetRange("Package No.", CDNo[2]);
        Assert.RecordCount(VATLedgerLineCDNo, 1);
    end;

    local procedure VerifyTwoVATLedgerLineCDNoOnPage(VATLedgerLine: Record "VAT Ledger Line"; VATLedgerLineCDNo: TestPage "VAT Ledger Line CD No.")
    var
        CDNo: array[2] of Code[30];
    begin
        CDNo[1] := VATLedgerLineCDNo."Package No.".Value();
        VATLedgerLineCDNo.Next();
        CDNo[2] := VATLedgerLineCDNo."Package No.".Value();
        Assert.IsFalse(VATLedgerLineCDNo.Next(), '');
        VerifyTwoVATLedgerLineCDNo(VATLedgerLine, CDNo);
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure VATLedgerExportXML_RPH(var VATLedgerExportXML: TestRequestPage "VAT Ledger Export XML")
    begin
        LibraryVariableStorage.Enqueue(VATLedgerExportXML.FileName.Value);
        VATLedgerExportXML.OK().Invoke();
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure MessageHandler(Message: Text[1024])
    begin
    end;
}

