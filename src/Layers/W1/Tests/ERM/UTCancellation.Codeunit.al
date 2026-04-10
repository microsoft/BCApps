codeunit 137027 "UT Cancellation"
{
    Permissions = TableData "Sales Invoice Header" = ri,
                  TableData "Sales Cr.Memo Header" = ri,
                  TableData "Purch. Inv. Header" = ri,
                  TableData "Purch. Cr. Memo Hdr." = ri,
                  TableData "No. Series" = ri,
                  TableData "Cancelled Document" = ri;
    Subtype = Test;
    TestPermissions = NonRestrictive;

    trigger OnRun()
    begin
        // [FEATURE] [Cancelled Document] [Invoice] [Credit Memo] [Sales] [Purchase] [UT]
    end;

    var
        Assert: Codeunit Assert;
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        LibrarySetupStorage: Codeunit "Library - Setup Storage";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryLowerPermissions: Codeunit "Library - Lower Permissions";
        IsInitialized: Boolean;

    [Test]
    [Scope('OnPrem')]
    procedure CreateSalesInvToCrMemoCancelledDocument()
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
        CancelledDocument: Record "Cancelled Document";
    begin
        // [FEATURE] [Sales]
        // [SCENARIO 168492] "Cancelled Document" is created when call procedure InsertSalesInvToCrMemoCancelledDocument

        Initialize();
        MockSalesInvCrMemo(SalesInvoiceHeader, SalesCrMemoHeader);
        LibraryLowerPermissions.SetSalesDocsCreate();

        CancelledDocument.InsertSalesInvToCrMemoCancelledDocument(SalesInvoiceHeader."No.", SalesCrMemoHeader."No.");

        VerifyCancelledDocument(DATABASE::"Sales Invoice Header", SalesInvoiceHeader."No.", SalesCrMemoHeader."No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CreateSalesCrMemoToInvCancelledDocument()
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
        NewSalesInvoiceHeader: Record "Sales Invoice Header";
        CancelledDocument: Record "Cancelled Document";
    begin
        // [FEATURE] [Sales]
        // [SCENARIO 168492] "Cancelled Document" is created when call InsertSalesCrMemoToInvCancelledDocument

        Initialize();
        MockSalesInvCrMemo(SalesInvoiceHeader, SalesCrMemoHeader);
        MockCancelledDocument(
          CancelledDocument, DATABASE::"Sales Invoice Header", SalesInvoiceHeader."No.", SalesCrMemoHeader."No.");
        MockSalesInvoice(NewSalesInvoiceHeader);
        LibraryLowerPermissions.SetSalesDocsCreate();

        Clear(CancelledDocument);
        CancelledDocument.InsertSalesCrMemoToInvCancelledDocument(SalesCrMemoHeader."No.", NewSalesInvoiceHeader."No.");

        VerifyCancelledDocument(DATABASE::"Sales Cr.Memo Header", SalesCrMemoHeader."No.", NewSalesInvoiceHeader."No.");

        Assert.IsFalse(CancelledDocument.Get(DATABASE::"Sales Invoice Header", SalesInvoiceHeader."No."), '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesInvCancelledFlowField()
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
        CancelledDocument: Record "Cancelled Document";
    begin
        // [FEATURE] [Sales]
        // [SCENARIO 168492] The flow field "Cancelled" of "Sales Invoice Header" is calculated by "Cancelled Document" table

        Initialize();
        MockSalesInvCrMemo(SalesInvoiceHeader, SalesCrMemoHeader);
        LibraryLowerPermissions.SetSalesDocsCreate();
        MockCancelledDocument(
          CancelledDocument, DATABASE::"Sales Invoice Header", SalesInvoiceHeader."No.", SalesCrMemoHeader."No.");

        SalesInvoiceHeader.CalcFields(Cancelled);
        SalesInvoiceHeader.TestField(Cancelled);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesCrMemoCancelledFlowField()
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
        CancelledDocument: Record "Cancelled Document";
    begin
        // [FEATURE] [Sales]
        // [SCENARIO 168492] The flow field "Cancelled" of "Sales Credit Memo Header" is calculated by "Cancelled Document" table

        Initialize();
        MockSalesInvCrMemo(SalesInvoiceHeader, SalesCrMemoHeader);
        LibraryLowerPermissions.SetSalesDocsCreate();
        MockCancelledDocument(
          CancelledDocument, DATABASE::"Sales Cr.Memo Header", SalesCrMemoHeader."No.", SalesInvoiceHeader."No.");

        SalesCrMemoHeader.CalcFields(Cancelled);
        SalesCrMemoHeader.TestField(Cancelled);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CreatePurchInvToCrMemoCancelledDocument()
    var
        PurchInvHeader: Record "Purch. Inv. Header";
        PurchCrMemoHdr: Record "Purch. Cr. Memo Hdr.";
        CancelledDocument: Record "Cancelled Document";
    begin
        // [FEATURE] [Purchase]
        // [SCENARIO 168492] "Cancelled Document" is created when call procedure InsertPurchInvToCrMemoCancelledDocument

        Initialize();
        MockPurchInvCrMemo(PurchInvHeader, PurchCrMemoHdr);
        LibraryLowerPermissions.SetPurchDocsCreate();

        CancelledDocument.InsertPurchInvToCrMemoCancelledDocument(PurchInvHeader."No.", PurchCrMemoHdr."No.");

        VerifyCancelledDocument(DATABASE::"Purch. Inv. Header", PurchInvHeader."No.", PurchCrMemoHdr."No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CreatePurchCrMemoToInvCancelledDocument()
    var
        PurchInvHeader: Record "Purch. Inv. Header";
        PurchCrMemoHdr: Record "Purch. Cr. Memo Hdr.";
        NewPurchInvHeader: Record "Purch. Inv. Header";
        CancelledDocument: Record "Cancelled Document";
    begin
        // [FEATURE] [Purchase]
        // [SCENARIO 168492] "Cancelled Document" is created when call InsertPurchCrMemoToInvCancelledDocument

        Initialize();
        MockPurchInvCrMemo(PurchInvHeader, PurchCrMemoHdr);
        MockCancelledDocument(
          CancelledDocument, DATABASE::"Purch. Inv. Header", PurchInvHeader."No.", PurchCrMemoHdr."No.");
        MockPurchInvoice(NewPurchInvHeader);
        LibraryLowerPermissions.SetPurchDocsCreate();

        Clear(CancelledDocument);
        CancelledDocument.InsertPurchCrMemoToInvCancelledDocument(PurchCrMemoHdr."No.", NewPurchInvHeader."No.");

        VerifyCancelledDocument(DATABASE::"Purch. Cr. Memo Hdr.", PurchCrMemoHdr."No.", NewPurchInvHeader."No.");

        Assert.IsFalse(CancelledDocument.Get(DATABASE::"Purch. Inv. Header", PurchInvHeader."No."), '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchInvCancelledFlowField()
    var
        PurchInvHeader: Record "Purch. Inv. Header";
        PurchCrMemoHdr: Record "Purch. Cr. Memo Hdr.";
        CancelledDocument: Record "Cancelled Document";
    begin
        // [FEATURE] [Purchase]
        // [SCENARIO 168492] The flow field "Cancelled" of "Purchase Invoice Header" is calculated by "Cancelled Document" table

        Initialize();
        MockPurchInvCrMemo(PurchInvHeader, PurchCrMemoHdr);
        LibraryLowerPermissions.SetPurchDocsCreate();
        MockCancelledDocument(
          CancelledDocument, DATABASE::"Purch. Inv. Header", PurchInvHeader."No.", PurchCrMemoHdr."No.");

        PurchInvHeader.CalcFields(Cancelled);
        PurchInvHeader.TestField(Cancelled);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchCrMemoCancelledFlowField()
    var
        PurchInvHeader: Record "Purch. Inv. Header";
        PurchCrMemoHdr: Record "Purch. Cr. Memo Hdr.";
        CancelledDocument: Record "Cancelled Document";
    begin
        // [FEATURE] [Purchase]
        // [SCENARIO 168492] The flow field "Cancelled" of "Purchase Credit Memo Header" is calculated by "Cancelled Document" table

        Initialize();
        MockPurchInvCrMemo(PurchInvHeader, PurchCrMemoHdr);
        LibraryLowerPermissions.SetPurchDocsCreate();
        MockCancelledDocument(
          CancelledDocument, DATABASE::"Purch. Cr. Memo Hdr.", PurchCrMemoHdr."No.", PurchInvHeader."No.");

        PurchCrMemoHdr.CalcFields(Cancelled);
        PurchCrMemoHdr.TestField(Cancelled);
    end;

    local procedure Initialize()
    var
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"UT Cancellation");
        LibrarySetupStorage.Restore();
        if IsInitialized then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"UT Cancellation");

        LibraryERMCountryData.CreateVATData();
        LibraryERMCountryData.UpdateGeneralLedgerSetup();
        LibraryERMCountryData.UpdateGeneralPostingSetup();
        LibraryERMCountryData.UpdateSalesReceivablesSetup();
        LibraryERMCountryData.CreateGeneralPostingSetupData();
        LibrarySetupStorage.Save(DATABASE::"General Ledger Setup");

        IsInitialized := true;
        Commit();
        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"UT Cancellation");
    end;

    local procedure MockSalesInvCrMemo(var SalesInvoiceHeader: Record "Sales Invoice Header"; var SalesCrMemoHeader: Record "Sales Cr.Memo Header")
    begin
        MockSalesInvoice(SalesInvoiceHeader);
        MockSalesCrMemo(SalesCrMemoHeader);
    end;

    local procedure MockSalesInvoice(var SalesInvoiceHeader: Record "Sales Invoice Header")
    begin
        SalesInvoiceHeader.Init();
        SalesInvoiceHeader."No." := LibraryUtility.GenerateGUID();
        SalesInvoiceHeader.Insert();
    end;

    local procedure MockSalesCrMemo(var SalesCrMemoHeader: Record "Sales Cr.Memo Header")
    begin
        SalesCrMemoHeader.Init();
        SalesCrMemoHeader."No." := LibraryUtility.GenerateGUID();
        SalesCrMemoHeader.Insert();
    end;

    local procedure MockPurchInvCrMemo(var PurchInvHeader: Record "Purch. Inv. Header"; var PurchCrMemoHdr: Record "Purch. Cr. Memo Hdr.")
    begin
        MockPurchInvoice(PurchInvHeader);
        MockPurchCrMemo(PurchCrMemoHdr);
    end;

    local procedure MockPurchInvoice(var PurchInvHeader: Record "Purch. Inv. Header")
    begin
        PurchInvHeader.Init();
        PurchInvHeader."No." := LibraryUtility.GenerateGUID();
        PurchInvHeader.Insert();
    end;

    local procedure MockPurchCrMemo(var PurchCrMemoHdr: Record "Purch. Cr. Memo Hdr.")
    begin
        PurchCrMemoHdr.Init();
        PurchCrMemoHdr."No." := LibraryUtility.GenerateGUID();
        PurchCrMemoHdr.Insert();
    end;

    local procedure MockCancelledDocument(var CancelledDocument: Record "Cancelled Document"; SourceID: Integer; CancelledDocNo: Code[20]; CancelledByDocNo: Code[20])
    begin
        CancelledDocument.Init();
        CancelledDocument."Source ID" := SourceID;
        CancelledDocument."Cancelled Doc. No." := CancelledDocNo;
        CancelledDocument."Cancelled By Doc. No." := CancelledByDocNo;
        CancelledDocument.Insert();
    end;

    local procedure VerifyCancelledDocument(SourceID: Integer; CancelledDocNo: Code[20]; CancelledByDocNo: Code[20])
    var
        CancelledDocument: Record "Cancelled Document";
    begin
        CancelledDocument.Get(SourceID, CancelledDocNo);
        CancelledDocument.TestField("Cancelled By Doc. No.", CancelledByDocNo);
    end;
}

