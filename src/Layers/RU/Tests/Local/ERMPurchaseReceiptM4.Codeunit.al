codeunit 144703 "ERM Purchase Receipt M-4"
{
    // // [FEATURE] [Report] [M-4]

    TestPermissions = NonRestrictive;
    Subtype = Test;

    trigger OnRun()
    begin
    end;

    var
        LibraryERM: Codeunit "Library - ERM";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryReportValidation: Codeunit "Library - Report Validation";
        LibraryRUReports: Codeunit "Library RU Reports";
        LibraryRandom: Codeunit "Library - Random";
        LibraryInventory: Codeunit "Library - Inventory";
        isInitialized: Boolean;

    [Test]
    [Scope('OnPrem')]
    procedure M4_DocumentNo()
    var
        DocumentNo: Code[20];
        LineQty: Integer;
    begin
        // [FEATURE] [Purchase Receipt M-4]
        DocumentNo := PrintM4PurchaseOrder(LineQty);

        LibraryReportValidation.VerifyCellValue(5, 7, DocumentNo);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure M4_TotalAmount()
    var
        PurchaseHeader: Record "Purchase Header";
        DocumentNo: Code[20];
        LineQty: Integer;
    begin
        // [FEATURE] [Purchase Receipt M-4]
        DocumentNo := PrintM4PurchaseOrder(LineQty);

        LibraryReportValidation.VerifyCellValue(
          22 + LineQty, 8, LibraryRUReports.GetPurchaseTotalAmount(PurchaseHeader."Document Type"::Order, DocumentNo));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure M4_AmountIncVAT()
    var
        PurchaseHeader: Record "Purchase Header";
        DocumentNo: Code[20];
        LineQty: Integer;
    begin
        // [FEATURE] [Purchase Receipt M-4]
        DocumentNo := PrintM4PurchaseOrder(LineQty);

        LibraryReportValidation.VerifyCellValue(
          22 + LineQty, 10, LibraryRUReports.GetPurchaseTotalAmountIncVAT(PurchaseHeader."Document Type"::Order, DocumentNo));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure M4_VendorFullName()
    var
        Vendor: Record Vendor;
        LineQty: Integer;
    begin
        // [FEATURE] [Purchase Receipt M-4]
        // [SCENARIO 377549] "Purchase Receipt M-4" report prints Vendor's "Full Name"
        GetVendorFromPurchOrder(Vendor, PrintM4PurchaseOrder(LineQty));

        LibraryReportValidation.VerifyCellValueByRef('D', 14, 1, Vendor."Full Name");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostedM4_CheckDocumentNo()
    var
        DocumentNo: Code[20];
        LineQty: Integer;
    begin
        // [FEATURE] [Posted Purchase Receipt M-4]
        DocumentNo := PrintM4PostedPurchaseInvoice(LineQty);

        LibraryReportValidation.VerifyCellValue(5, 7, DocumentNo);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostedM4_TotalAmount()
    var
        DocumentNo: Code[20];
        LineQty: Integer;
    begin
        // [FEATURE] [Posted Purchase Receipt M-4]
        DocumentNo := PrintM4PostedPurchaseInvoice(LineQty);

        LibraryReportValidation.VerifyCellValue(
          22 + LineQty, 8, LibraryRUReports.GetPostedPurchaseTotalAmount(DocumentNo));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostedM4_AmountIncVAT()
    var
        DocumentNo: Code[20];
        LineQty: Integer;
    begin
        // [FEATURE] [Posted Purchase Receipt M-4]
        DocumentNo := PrintM4PostedPurchaseInvoice(LineQty);

        LibraryReportValidation.VerifyCellValue(
          22 + LineQty, 10, LibraryRUReports.GetPostedPurchaseTotalAmountIncVAT(DocumentNo));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostedM4_VendorFullName()
    var
        Vendor: Record Vendor;
        LineQty: Integer;
    begin
        // [FEATURE] [Posted Purchase Receipt M-4]
        // [SCENARIO 377549] "Posted Purchase Receipt M-4" report prints Vendor's "Full Name"
        GetVendorFromPostedPurchOrder(Vendor, PrintM4PostedPurchaseInvoice(LineQty));

        LibraryReportValidation.VerifyCellValueByRef('D', 14, 1, Vendor."Full Name");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PrintM4PurchaseOrderWith20CharsItemNo()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        PurchaseReceiptM4: Report "Purchase Receipt M-4";
        GLAccountNo: Code[20];
    begin
        // [SCENARIO 203310] M-4 Report for Purchase Order can be printed if line has "No." of 20 chars
        Initialize();

        // [GIVEN] Purchase Order "PO"
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, LibraryPurchase.CreateVendorNo());

        // [GIVEN] Purchase Line having 20 chars long "No."
        GLAccountNo := LibraryERM.CreateGLAccountWithPurchSetup();

        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::"G/L Account", GLAccountNo, 1);

        // [WHEN] Print M-4 Report for "PO"
        LibraryReportValidation.SetFileName(LibraryUtility.GenerateGUID());
        Commit();
        PurchaseHeader.SetRecFilter();
        PurchaseReceiptM4.SetTableView(PurchaseHeader);
        PurchaseReceiptM4.SetFileNameSilent(LibraryReportValidation.GetFileName());
        PurchaseReceiptM4.UseRequestPage(false);
        PurchaseReceiptM4.Run();

        // [THEN] M-4 Report is printed and contains "PO"'s "No."
        LibraryReportValidation.VerifyCellValue(5, 7, PurchaseHeader."No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PrintM4PostedPurchaseOrderWith20CharsItemNo()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchInvHeader: Record "Purch. Inv. Header";
        PurchaseLine: Record "Purchase Line";
        PostedPurchaseReceiptM4: Report "Posted Purchase Receipt M-4";
        DocumentNo: Code[20];
        GLAccountNo: Code[20];
    begin
        // [SCENARIO 203310] M-4 Report for Posted Purchase Order can be printed if line has "No." of 20 chars
        Initialize();

        // [GIVEN] Purchase Order "PO"
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, LibraryPurchase.CreateVendorNo());

        // [GIVEN] Purchase Line having 20 chars long "No."
        GLAccountNo := LibraryERM.CreateGLAccountWithPurchSetup();

        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::"G/L Account", GLAccountNo, 1);

        // [GIVEN] "PO" is posted
        DocumentNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        // [WHEN] Print M-4 Report for posted Purchase Receipt
        LibraryReportValidation.SetFileName(LibraryUtility.GenerateGUID());
        Commit();
        PurchInvHeader.SetRange("No.", DocumentNo);
        PostedPurchaseReceiptM4.SetTableView(PurchInvHeader);
        PostedPurchaseReceiptM4.SetFileNameSilent(LibraryReportValidation.GetFileName());
        PostedPurchaseReceiptM4.UseRequestPage(false);
        PostedPurchaseReceiptM4.Run();

        // [THEN] M-4 Report is printed and contains "No." of posted Purchase Receipt
        LibraryReportValidation.VerifyCellValue(5, 7, DocumentNo);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PrintM4PurchaseInvoiceWith32PurchaseLines()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        ItemNo: Code[20];
        Index: Integer;
        PurchaseReceiptM4: Report "Purchase Receipt M-4";
    begin
        // [SCENARIO 360186] M-4 report lost a line on print form
        Initialize();

        // [GIVEN] Purchase Invoice with 32 lines; Quantity of i-th line equals to i 
        ItemNo := LibraryInventory.CreateItemNo();
        LibraryPurchase.CreatePurchHeader(
            PurchaseHeader, PurchaseHeader."Document Type"::Invoice, LibraryPurchase.CreateVendorNo());
        for Index := 1 to 32 do
            LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, ItemNo, Index);

        // [WHEN] Print M-4 Report for Purchase Invoice
        LibraryReportValidation.SetFileName(LibraryUtility.GenerateGUID());
        Commit();
        PurchaseHeader.SetRange("No.", PurchaseHeader."No.");
        PurchaseReceiptM4.SetTableView(PurchaseHeader);
        PurchaseReceiptM4.SetFileNameSilent(LibraryReportValidation.GetFileName());
        PurchaseReceiptM4.UseRequestPage(false);
        PurchaseReceiptM4.Run();

        // [THEN] Line with quantity = 30 should exists on the report
        LibraryReportValidation.VerifyCellValue(
            LibraryReportValidation.FindRowNoFromColumnNoAndValue(6, '30'), 1, ItemNo);
    end;

    local procedure Initialize()
    var
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
    begin
        if isInitialized then
            exit;

        LibraryERMCountryData.UpdateGeneralPostingSetup();

        isInitialized := true;
        Commit();
    end;

    local procedure PrintM4PurchaseOrder(var LineQty: Integer): Code[20]
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseReceiptM4: Report "Purchase Receipt M-4";
    begin
        Initialize();

        LineQty := LibraryRandom.RandIntInRange(2, 5);
        LibraryRUReports.CreatePurchDocument(PurchaseHeader, PurchaseHeader."Document Type"::Order, LineQty);

        LibraryReportValidation.SetFileName(LibraryUtility.GenerateGUID());
        Commit();
        PurchaseHeader.SetRange("Document Type", PurchaseHeader."Document Type"::Order);
        PurchaseHeader.SetRange("No.", PurchaseHeader."No.");
        PurchaseReceiptM4.SetTableView(PurchaseHeader);
        PurchaseReceiptM4.SetFileNameSilent(LibraryReportValidation.GetFileName());
        PurchaseReceiptM4.UseRequestPage(false);
        PurchaseReceiptM4.Run();

        exit(PurchaseHeader."No.");
    end;

    local procedure PrintM4PostedPurchaseInvoice(var LineQty: Integer) DocumentNo: Code[20]
    var
        PurchaseHeader: Record "Purchase Header";
        PurchInvHeader: Record "Purch. Inv. Header";
        PostedPurchaseReceiptM4: Report "Posted Purchase Receipt M-4";
    begin
        Initialize();

        LineQty := LibraryRandom.RandIntInRange(2, 5);
        DocumentNo := LibraryRUReports.CreatePostPurchDocument(PurchaseHeader."Document Type"::Order, LineQty);

        LibraryReportValidation.SetFileName(LibraryUtility.GenerateGUID());
        Commit();
        PurchInvHeader.SetRange("No.", DocumentNo);
        PostedPurchaseReceiptM4.SetTableView(PurchInvHeader);
        PostedPurchaseReceiptM4.SetFileNameSilent(LibraryReportValidation.GetFileName());
        PostedPurchaseReceiptM4.UseRequestPage(false);
        PostedPurchaseReceiptM4.Run();
    end;

    local procedure GetVendorFromPurchOrder(var Vendor: Record Vendor; DocumentNo: Code[20])
    var
        PurchaseHeader: Record "Purchase Header";
    begin
        PurchaseHeader.Get(PurchaseHeader."Document Type"::Order, DocumentNo);
        Vendor.Get(PurchaseHeader."Buy-from Vendor No.");
    end;

    local procedure GetVendorFromPostedPurchOrder(var Vendor: Record Vendor; DocumentNo: Code[20])
    var
        PurchInvHeader: Record "Purch. Inv. Header";
    begin
        PurchInvHeader.Get(DocumentNo);
        Vendor.Get(PurchInvHeader."Buy-from Vendor No.");
    end;
}

