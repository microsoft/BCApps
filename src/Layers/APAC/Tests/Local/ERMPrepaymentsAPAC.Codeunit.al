codeunit 141015 "ERM Prepayments APAC"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Prepayment]
    end;

    var
        Assert: Codeunit Assert;
        LibraryERM: Codeunit "Library - ERM";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibraryReportDataset: Codeunit "Library - Report Dataset";
        LibrarySales: Codeunit "Library - Sales";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibraryRandom: Codeunit "Library - Random";
        AmountErr: Label '%1 must be %2 in %3.';
        GLAccNoCap: Label 'No_GLAcc';

    [Test]
    [Scope('OnPrem')]
    procedure PurchPrepaymentInvoicePostWithDiffPct()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        PrepaymentInvoiceNo: Code[20];
        PrepaymentInvoiceNo2: Code[20];
        PrepaymentPct: Decimal;
        OldFullGSTOnPrepayment: Boolean;
    begin
        // [FEATURE] [Purchase]
        // [SCENARIO] GL Entries in case of different Prepayment % with different Type on Purchase Line.

        // [GIVEN] Create Purchase Order, post multiple Prepayment Invoice with different percentage.
        Initialize();
        OldFullGSTOnPrepayment := UpdateGeneralLedgerSetup(false);
        PrepaymentPct := 100;  // Required as Manual requirement.
        CreatePurchaseOrder(PurchaseHeader, PrepaymentPct / 4, true);  // 25 % Prepayment, Compress Prepayment - TRUE.
        LibraryPurchase.PostPurchasePrepaymentInvoice(PurchaseHeader);
        FindPurchaseLine(PurchaseLine, PurchaseHeader."No.");
        PrepaymentInvoiceNo := PostPrepaymentInvoiceAfterReopen(PurchaseLine, PurchaseHeader, PrepaymentPct / 2);  // 50 % Prepayment.
        PrepaymentInvoiceNo2 := PostPrepaymentInvoiceAfterReopen(PurchaseLine, PurchaseHeader, PrepaymentPct);  // 100 % Prepayment.
        UpdateVendorInvoiceNo(PurchaseHeader);

        // Exercise.
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);  // Receive & Invoice - TRUE.

        // [THEN] Verify GL Entries total Amount with Purchase Line values.
        VerifyGLEntries(PrepaymentInvoiceNo, PurchaseLine."Prepmt. Amt. Incl. VAT" / 2);  // Calculate 50 % Prepayment amount.
        VerifyGLEntries(PrepaymentInvoiceNo2, PurchaseLine."Prepmt. Amt. Incl. VAT");
        VerifyGLEntries(
          PurchaseHeader."Last Posting No.", PurchaseLine."Amount Including VAT" - PurchaseLine."Prepayment Amount" +
          PurchaseLine."Prepayment Amount");

        // Tear Down.
        UpdateGeneralLedgerSetup(OldFullGSTOnPrepayment);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchPrepaymentInvoiceWithoutCompressPayment()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
    begin
        // [FEATURE] [Purchase]
        // [SCENARIO] GL Entries in case of Prepayment % without Compress Prepayment on Purchase Header.

        // [GIVEN] Create Purchase Order without Compress Payment, post Prepayment Invoice.
        Initialize();
        CreatePurchaseOrder(PurchaseHeader, LibraryRandom.RandDecInRange(10, 20, 2), false);  // Using Random for Prepayment % and Compress Prepayment - FALSE
        LibraryPurchase.PostPurchasePrepaymentInvoice(PurchaseHeader);
        FindPurchaseLine(PurchaseLine, PurchaseHeader."No.");
        UpdateVendorInvoiceNo(PurchaseHeader);

        // Exercise.
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);  // Receive & Invoice - TRUE.

        // [THEN] Verify GL Entries total Amount with Purchase Line values.
        VerifyGLEntries(PurchaseHeader."Last Prepayment No.", PurchaseLine."Prepmt. Amt. Incl. VAT");
        VerifyGLEntries(
          PurchaseHeader."Last Posting No.", PurchaseLine."Amount Including VAT" - PurchaseLine."Prepayment Amount" +
          PurchaseLine."Prepayment Amount");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesPrepaymentInvoiceWithoutCompressPayment()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
    begin
        // [FEATURE] [Sales]
        // [SCENARIO] GL Entries in case of Prepayment % without Compress Prepayment on Sales Header.

        // [GIVEN] Create Sales Order without Compress Payment, post Prepayment Invoice.
        Initialize();
        CreateSalesOrder(SalesLine);
        SalesHeader.Get(SalesLine."Document Type", SalesLine."Document No.");
        LibrarySales.PostSalesPrepaymentInvoice(SalesHeader);
        SalesLine.Get(SalesLine."Document Type", SalesLine."Document No.", SalesLine."Line No.");

        // Exercise.
        LibrarySales.PostSalesDocument(SalesHeader, true, true);  // Ship & Invoice - TRUE.

        // [THEN] Verify GL Entries total Amount with Sales Line values.
        VerifyGLEntries(SalesHeader."Last Prepayment No.", SalesLine."Prepmt. Amt. Incl. VAT");
        VerifyGLEntries(
          SalesHeader."Last Posting No.", SalesLine."Amount Including VAT" - SalesLine."Prepayment Amount" +
          SalesLine."Prepayment Amount");
    end;

    [Test]
    [HandlerFunctions('BudgetRequestPageHandler')]
    [Scope('OnPrem')]
    procedure GLAccountOnBudgetReport()
    var
        GLAccountNo: Code[20];
    begin
        // [FEATURE] [Report] [Budget]
        // [SCENARIO] GL Account on Budget Report.

        // Setup.
        GLAccountNo := CreateGLAccount('');  // Using Blank for Gen. Prod. Posting Group.
        LibraryVariableStorage.Enqueue(GLAccountNo);  // Enqueue value for BudgetRequestPageHandler.
        Commit();  // Commit required for run Budget Report.

        // Exercise.
        REPORT.Run(REPORT::Budget);  // Call BudgetRequestPageHandler.

        // [THEN] Verify GL Account No. on Budget Report
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementWithValueExists(GLAccNoCap, GLAccountNo);
    end;

    local procedure Initialize()
    begin
        LibraryVariableStorage.Clear();
    end;

    local procedure CreateCustomer(GenBusPostingGroup: Code[20]): Code[20]
    var
        Customer: Record Customer;
    begin
        LibrarySales.CreateCustomer(Customer);
        Customer.Validate("Gen. Bus. Posting Group", GenBusPostingGroup);
        Customer.Modify(true);
        exit(Customer."No.");
    end;

    local procedure CreateGeneralBusinessPostingGroup(DefVATBusinessPostingGroup: Code[20]): Code[20]
    var
        GenBusinessPostingGroup: Record "Gen. Business Posting Group";
    begin
        LibraryERM.CreateGenBusPostingGroup(GenBusinessPostingGroup);
        GenBusinessPostingGroup.Validate("Def. VAT Bus. Posting Group", DefVATBusinessPostingGroup);
        GenBusinessPostingGroup.Modify(true);
        exit(GenBusinessPostingGroup.Code);
    end;

    local procedure CreateGeneralPostingSetup(var GeneralPostingSetup: Record "General Posting Setup")
    var
        GLAccount: Record "G/L Account";
        VATPostingSetup: Record "VAT Posting Setup";
        GenProdPostingGroupCode: Code[20];
        GLAccountNo: Code[20];
    begin
        LibraryERM.CreateGLAccount(GLAccount);
        LibraryERM.FindVATPostingSetup(VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT");
        GenProdPostingGroupCode := CreateGeneralProductPostingGroup(VATPostingSetup."VAT Prod. Posting Group");
        GLAccountNo := CreateGLAccount(GenProdPostingGroupCode);
        LibraryERM.CreateGeneralPostingSetup(
          GeneralPostingSetup, CreateGeneralBusinessPostingGroup(VATPostingSetup."VAT Bus. Posting Group"), GenProdPostingGroupCode);
        GeneralPostingSetup.Validate("Sales Account", GLAccountNo);
        GeneralPostingSetup.Validate("Sales Prepayments Account", GLAccountNo);
        GeneralPostingSetup.Validate("COGS Account", GLAccountNo);
        GeneralPostingSetup.Validate("Purch. Account", GLAccountNo);
        GeneralPostingSetup.Validate("Purch. Prepayments Account", GLAccountNo);
        GeneralPostingSetup.Validate("Direct Cost Applied Account", GLAccountNo);
        GeneralPostingSetup.Modify(true);
    end;

    local procedure CreateGeneralProductPostingGroup(DefVATProdPostingGroup: Code[20]): Code[20]
    var
        GenProdPostingGroup: Record "Gen. Product Posting Group";
    begin
        LibraryERM.CreateGenProdPostingGroup(GenProdPostingGroup);
        GenProdPostingGroup.Validate("Def. VAT Prod. Posting Group", DefVATProdPostingGroup);
        GenProdPostingGroup.Modify(true);
        exit(GenProdPostingGroup.Code);
    end;

    local procedure CreateGLAccount(GenProdPostingGroup: Code[20]): Code[20]
    var
        GLAccount: Record "G/L Account";
    begin
        LibraryERM.CreateGLAccount(GLAccount);
        GLAccount.Validate("Gen. Prod. Posting Group", GenProdPostingGroup);
        GLAccount.Modify(true);
        exit(GLAccount."No.");
    end;

    local procedure CreateItem(GenProdPostingGroup: Code[20]): Code[20]
    var
        Item: Record Item;
    begin
        LibraryInventory.CreateItem(Item);
        Item.Validate("Gen. Prod. Posting Group", GenProdPostingGroup);
        Item.Modify(true);
        exit(Item."No.");
    end;

    local procedure CreatePurchaseOrder(var PurchaseHeader: Record "Purchase Header"; PrepaymentPct: Decimal; CompressPrepayment: Boolean)
    var
        GeneralPostingSetup: Record "General Posting Setup";
        PurchaseLine: Record "Purchase Line";
    begin
        CreateGeneralPostingSetup(GeneralPostingSetup);
        LibraryPurchase.CreatePurchHeader(
          PurchaseHeader, PurchaseHeader."Document Type"::Order, CreateVendor(GeneralPostingSetup."Gen. Bus. Posting Group"));
        PurchaseHeader.Validate("Prepayment %", PrepaymentPct);
        PurchaseHeader.Validate("Compress Prepayment", CompressPrepayment);
        PurchaseHeader.Modify(true);
        LibraryPurchase.CreatePurchaseLine(
          PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, CreateItem(
            GeneralPostingSetup."Gen. Prod. Posting Group"), LibraryRandom.RandDec(10, 2));  // Random value is used for Quantity.
        PurchaseLine.Validate("Direct Unit Cost", LibraryRandom.RandDec(100, 2));
        PurchaseLine.Validate("Prepayment %", PurchaseHeader."Prepayment %");
        PurchaseLine.Modify(true);
    end;

    local procedure CreateSalesOrder(var SalesLine: Record "Sales Line")
    var
        GeneralPostingSetup: Record "General Posting Setup";
        SalesHeader: Record "Sales Header";
    begin
        CreateGeneralPostingSetup(GeneralPostingSetup);
        LibrarySales.CreateSalesHeader(
          SalesHeader, SalesHeader."Document Type"::Order, CreateCustomer(GeneralPostingSetup."Gen. Bus. Posting Group"));
        SalesHeader.Validate("Compress Prepayment", false);
        SalesHeader.Modify(true);
        LibrarySales.CreateSalesLine(
          SalesLine, SalesHeader, SalesLine.Type::Item, CreateItem(
            GeneralPostingSetup."Gen. Prod. Posting Group"), LibraryRandom.RandDec(10, 2));  // Random value is used for Quantity.
        SalesLine.Validate("Unit Price", LibraryRandom.RandDec(100, 2));
        SalesLine.Validate("Prepayment %", LibraryRandom.RandDec(20, 2));
        SalesLine.Modify(true);
    end;

    local procedure CreateVendor(GenBusPostingGroup: Code[20]): Code[20]
    var
        Vendor: Record Vendor;
    begin
        LibraryPurchase.CreateVendor(Vendor);
        Vendor.Validate("Gen. Bus. Posting Group", GenBusPostingGroup);
        Vendor.Modify(true);
        exit(Vendor."No.");
    end;

    local procedure FindPurchaseLine(var PurchaseLine: Record "Purchase Line"; DocumentNo: Code[20])
    begin
        PurchaseLine.SetRange("Document No.", DocumentNo);
        PurchaseLine.FindFirst();
    end;

    local procedure GetPrepaymentPurchaseInvoiceNo(ExternalDocumentNo: Code[20]): Code[20]
    var
        VendorLedgerEntry: Record "Vendor Ledger Entry";
    begin
        VendorLedgerEntry.SetRange("External Document No.", ExternalDocumentNo);
        VendorLedgerEntry.FindFirst();
        exit(VendorLedgerEntry."Document No.");
    end;

    local procedure PostPrepaymentInvoiceAfterReopen(var PurchaseLine: Record "Purchase Line"; PurchaseHeader: Record "Purchase Header"; PrepaymentPct: Decimal): Code[20]
    begin
        // Find Purchase Line, Reopen Purchase Order, update Prepayment % and Vendor Invoice No. on Purchase Header.
        FindPurchaseLine(PurchaseLine, PurchaseHeader."No.");
        LibraryPurchase.ReopenPurchaseDocument(PurchaseHeader);
        PurchaseHeader.Validate("Prepayment %", PrepaymentPct);
        UpdateVendorInvoiceNo(PurchaseHeader);

        // Update Prepayment % on Purchase Line and post Prepayment Invoice.
        PurchaseLine.Validate("Prepayment %", PurchaseHeader."Prepayment %");
        PurchaseLine.Modify(true);
        LibraryPurchase.PostPurchasePrepaymentInvoice(PurchaseHeader);
        exit(GetPrepaymentPurchaseInvoiceNo(PurchaseHeader."Vendor Invoice No."));
    end;

    local procedure UpdateGeneralLedgerSetup(FullGSTOnPrepayment: Boolean) OldFullGSTOnPrepayment: Boolean
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
    begin
        GeneralLedgerSetup.Get();
        OldFullGSTOnPrepayment := GeneralLedgerSetup."Full GST on Prepayment";
        GeneralLedgerSetup.Validate("Full GST on Prepayment", FullGSTOnPrepayment);
        GeneralLedgerSetup.Modify(true);
    end;

    local procedure UpdateVendorInvoiceNo(var PurchaseHeader: Record "Purchase Header")
    begin
        PurchaseHeader.Validate("Vendor Invoice No.", LibraryUtility.GenerateGUID());
        PurchaseHeader.Modify(true);
    end;

    local procedure VerifyGLEntries(DocumentNo: Code[20]; Amount: Decimal)
    var
        GLEntry: Record "G/L Entry";
        CreditAmount: Decimal;
    begin
        GLEntry.SetRange("Document No.", DocumentNo);
        GLEntry.FindSet();
        repeat
            CreditAmount += GLEntry."Credit Amount";
        until GLEntry.Next() = 0;
        Assert.AreNearlyEqual(
          CreditAmount, Amount, LibraryERM.GetAmountRoundingPrecision(),
          StrSubstNo(AmountErr, GLEntry.FieldCaption("Credit Amount"), Amount, GLEntry.TableCaption()));
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure BudgetRequestPageHandler(var Budget: TestRequestPage Budget)
    var
        No: Variant;
    begin
        LibraryVariableStorage.Dequeue(No);
        Budget."G/L Account".SetFilter("No.", No);
        Budget.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;
}

