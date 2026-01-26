codeunit 147309 "VAT on Change Log Statistics"
{
    //  1. Test VAT Amount on Posted Purchase Invoice Statistics After Changing VAT Amount.
    //  2. Test VAT Amount on Posted Sales Invoice Statistics After Changing VAT Amount.
    //
    //  TFS_TS_ID = 277578
    //  Covers Test cases:
    //  ----------------------------------------------------------------
    //  Test Function Name                                       TFS ID
    //  ----------------------------------------------------------------
    //  TestVATAmountOnPostedPurchaseInvoiceStatistics
    //  TestVATAmountOnPostedSalesInvoiceStatistics              277578

    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
    end;

    var
        LibraryERM: Codeunit "Library - ERM";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibrarySales: Codeunit "Library - Sales";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibraryRandom: Codeunit "Library - Random";

#if not CLEAN26
    [Obsolete('The statistics action will be replaced with the PurchaseOrderStatistics action. The new action uses RunObject and does not run the action trigger. Use a page extension to modify the behaviour.', '26.0')]
    [Test]
    [HandlerFunctions('PurchaseOrderStatisticsHandler,VATAmountLinesHandler')]
    [Scope('OnPrem')]
    procedure TestVATAmountOnPostedPurchaseInvoiceStatistics()
    var
        PurchaseHeader: Record "Purchase Header";
        AllowVATDifference: Boolean;
        OldVATDifferenceAllowed: Decimal;
        PostedDocumentNo: Code[20];
    begin
        // Check VAT Amount on Purchase Invoice Statistics After Changing VAT Amount.

        // Setup: Modify GeneralLedger And PurchasesPayables Setup, Create Purchase Order, VAT Amount Modified Using Handler.
        Initialize();
        OldVATDifferenceAllowed := UpdateGeneralLedgerSetup(LibraryRandom.RandDec(0, 1));
        AllowVATDifference := UpdatePurchasesPayablesSetup(true);
        UpdateVendorPostingGroup();
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, CreateVendor());
        CreateMultiplePurchaseLines(PurchaseHeader);
        OpenPurchaseOrderStatisticsPage(PurchaseHeader."No.");  // Open Purchase Order Statistics Page to Change VAT Amount on VAT Amount Lines using VATAmountLinesHandler.

        // Exercise.
        PostedDocumentNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        // Verify: Verify VAT Amount on Statistics of Purchase Invoice.
        VerifyVATAmountOnPostPurchaseInvStatistics(PostedDocumentNo);

        // Tear Down: Set Default Value in General Ledger Setup, PurchasesPayables Setup for VAT Difference.
        UpdateGeneralLedgerSetup(OldVATDifferenceAllowed);
        UpdatePurchasesPayablesSetup(AllowVATDifference);
    end;
#endif

    [Test]
    [HandlerFunctions('PurchOrderStatisticsHandler,VATAmountLinesHandler')]
    [Scope('OnPrem')]
    procedure TestVATAmountOnPostedPurchInvoiceStatistics()
    var
        PurchaseHeader: Record "Purchase Header";
        AllowVATDifference: Boolean;
        OldVATDifferenceAllowed: Decimal;
        PostedDocumentNo: Code[20];
    begin
        // Check VAT Amount on Purchase Invoice Statistics After Changing VAT Amount.

        // Setup: Modify GeneralLedger And PurchasesPayables Setup, Create Purchase Order, VAT Amount Modified Using Handler.
        Initialize();
        OldVATDifferenceAllowed := UpdateGeneralLedgerSetup(LibraryRandom.RandDec(0, 1));
        AllowVATDifference := UpdatePurchasesPayablesSetup(true);
        UpdateVendorPostingGroup();
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, CreateVendor());
        CreateMultiplePurchaseLines(PurchaseHeader);
        OpenPurchOrderStatisticsPage(PurchaseHeader."No.");  // Open Purchase Order Statistics Page to Change VAT Amount on VAT Amount Lines using VATAmountLinesHandler.

        // Exercise.
        PostedDocumentNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        // Verify: Verify VAT Amount on Statistics of Purchase Invoice.
        VerifyVATAmountOnPostPurchaseInvStatistics(PostedDocumentNo);

        // Tear Down: Set Default Value in General Ledger Setup, PurchasesPayables Setup for VAT Difference.
        UpdateGeneralLedgerSetup(OldVATDifferenceAllowed);
        UpdatePurchasesPayablesSetup(AllowVATDifference);
    end;

#if not CLEAN26
    [Obsolete('The statistics action will be replaced with the SalesStatistics action. The new action uses RunObject and does not run the action trigger', '26.0')]
    [Test]
    [HandlerFunctions('SalesOrderStatisticsHandler,VATAmountLinesHandler')]
    [Scope('OnPrem')]
    procedure TestVATAmountOnPostedSalesInvoiceStatistics()
    var
        SalesHeader: Record "Sales Header";
        AllowVATDifference: Boolean;
        OldVATDifferenceAllowed: Decimal;
        PostedDocumentNo: Code[20];
    begin
        // Check VAT Amount on Sales Invoice Statistics After Changing VAT Amount.

        // Setup: Modify General Ledger Setup And Purchases Payables Setup, Create Sales Order, VAT Amount Modified Using Handler.
        Initialize();
        OldVATDifferenceAllowed := UpdateGeneralLedgerSetup(LibraryRandom.RandDec(0, 1));
        AllowVATDifference := UpdateSalesReceivableSetup(true);
        UpdateCustomerPostingGroup();
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, CreateCustomer());
        CreateMultipleSalesLines(SalesHeader);
        OpenSalesOrderStatisticsPage(SalesHeader."No.");  // Open Sales Order Statistics Page to Change VAT Amount on VAT Amount Lines using VATAmountLinesHandler.

        // Exercise.
        PostedDocumentNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // Verify: Verify VAT Amount on Statistics of Sales Invoice.
        VerifyVATAmountOnPostSalesInvStatistics(PostedDocumentNo);

        // Tear Down: Set Default Value in General Ledger Setup, SalesAndReceivable Setup for VAT Difference.
        UpdateGeneralLedgerSetup(OldVATDifferenceAllowed);
        UpdateSalesReceivableSetup(AllowVATDifference);
    end;
#endif
    [Test]
    [HandlerFunctions('SalesOrderStatisticsHandlerNM,VATAmountLinesHandler')]
    [Scope('OnPrem')]
    procedure TestVATAmountOnPostedSalesInvoiceStatisticsNM()
    var
        SalesHeader: Record "Sales Header";
        AllowVATDifference: Boolean;
        OldVATDifferenceAllowed: Decimal;
        PostedDocumentNo: Code[20];
    begin
        // Check VAT Amount on Sales Invoice Statistics After Changing VAT Amount.

        // Setup: Modify General Ledger Setup And Purchases Payables Setup, Create Sales Order, VAT Amount Modified Using Handler.
        Initialize();
        OldVATDifferenceAllowed := UpdateGeneralLedgerSetup(LibraryRandom.RandDec(0, 1));
        AllowVATDifference := UpdateSalesReceivableSetup(true);
        UpdateCustomerPostingGroup();
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, CreateCustomer());
        CreateMultipleSalesLines(SalesHeader);
        OpenSalesOrderStatisticsPageNM(SalesHeader."No.");  // Open Sales Order Statistics Page to Change VAT Amount on VAT Amount Lines using VATAmountLinesHandler.

        // Exercise.
        PostedDocumentNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // Verify: Verify VAT Amount on Statistics of Sales Invoice.
        VerifyVATAmountOnPostSalesInvStatistics(PostedDocumentNo);

        // Tear Down: Set Default Value in General Ledger Setup, SalesAndReceivable Setup for VAT Difference.
        UpdateGeneralLedgerSetup(OldVATDifferenceAllowed);
        UpdateSalesReceivableSetup(AllowVATDifference);
    end;

    local procedure Initialize()
    begin
        LibraryVariableStorage.Clear();
    end;

    local procedure CreateCustomer(): Code[20]
    var
        Customer: Record Customer;
        VATPostingSetup: Record "VAT Posting Setup";
    begin
        LibraryERM.FindVATPostingSetup(VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT");
        LibrarySales.CreateCustomer(Customer);
        Customer.Validate("VAT Bus. Posting Group", VATPostingSetup."VAT Bus. Posting Group");
        Customer.Modify(true);
        exit(Customer."No.");
    end;

    local procedure CreateGLAccountWithVATProdPostingGroup(VATProductPostingGroup: Code[20]): Code[20]
    var
        GLAccount: Record "G/L Account";
        GeneralPostingSetup: Record "General Posting Setup";
    begin
        LibraryERM.FindGeneralPostingSetup(GeneralPostingSetup);
        LibraryERM.CreateGLAccount(GLAccount);
        GLAccount.Validate("Gen. Prod. Posting Group", GeneralPostingSetup."Gen. Prod. Posting Group");
        GLAccount.Validate("VAT Prod. Posting Group", VATProductPostingGroup);
        GLAccount.Modify(true);
        exit(GLAccount."No.");
    end;

    local procedure CreateMultiplePurchaseLines(var PurchaseHeader: Record "Purchase Header")
    var
        VATPostingSetup: Record "VAT Posting Setup";
        Counter: Integer;
        GLAccountNo: Code[20];
    begin
        // Create Purchase Lines with Random Quantity And Direct Unit Cost.
        LibraryERM.FindVATPostingSetup(VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT");
        GLAccountNo := CreateGLAccountWithVATProdPostingGroup(VATPostingSetup."VAT Prod. Posting Group");
        for Counter := 1 to LibraryRandom.RandIntInRange(2, 4) do begin
            CreatePurchaseLines(PurchaseHeader, VATPostingSetup."VAT Prod. Posting Group", GLAccountNo);
            FindVATPostingSetup(VATPostingSetup, VATPostingSetup."VAT Bus. Posting Group", VATPostingSetup."VAT Prod. Posting Group");
        end;
    end;

    local procedure CreateMultipleSalesLines(var SalesHeader: Record "Sales Header")
    var
        VATPostingSetup: Record "VAT Posting Setup";
        Counter: Integer;
        GLAccountNo: Code[20];
    begin
        // Create Sales Lines with Random Quantity And Direct Unit Cost.
        LibraryERM.FindVATPostingSetup(VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT");
        GLAccountNo := CreateGLAccountWithVATProdPostingGroup(VATPostingSetup."VAT Prod. Posting Group");
        for Counter := 1 to LibraryRandom.RandIntInRange(2, 4) do begin
            CreateSalesLines(SalesHeader, VATPostingSetup."VAT Prod. Posting Group", GLAccountNo);
            FindVATPostingSetup(VATPostingSetup, VATPostingSetup."VAT Bus. Posting Group", VATPostingSetup."VAT Prod. Posting Group");
        end;
    end;

    local procedure CreatePurchaseLines(var PurchaseHeader: Record "Purchase Header"; VATProdPostingGroup: Code[20]; GLAccountNo: Code[20])
    var
        PurchaseLine: Record "Purchase Line";
    begin
        LibraryPurchase.CreatePurchaseLine(
          PurchaseLine, PurchaseHeader, PurchaseLine.Type::"G/L Account", GLAccountNo, LibraryRandom.RandDec(10, 2));
        PurchaseLine.Validate("Direct Unit Cost", LibraryRandom.RandDec(100, 2));
        PurchaseLine.Validate("VAT Prod. Posting Group", VATProdPostingGroup);
        PurchaseLine.Modify(true);
    end;

    local procedure CreateSalesLines(var SalesHeader: Record "Sales Header"; VATProdPostingGroup: Code[20]; GLAccountNo: Code[20])
    var
        SalesLine: Record "Sales Line";
    begin
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::"G/L Account", GLAccountNo, LibraryRandom.RandDec(10, 2));
        SalesLine.Validate("Unit Price", LibraryRandom.RandDec(100, 2));
        SalesLine.Validate("VAT Prod. Posting Group", VATProdPostingGroup);
        SalesLine.Modify(true);
    end;

    local procedure CreateVendor(): Code[20]
    var
        Vendor: Record Vendor;
        VATPostingSetup: Record "VAT Posting Setup";
    begin
        LibraryERM.FindVATPostingSetup(VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT");
        LibraryPurchase.CreateVendor(Vendor);
        Vendor.Validate("VAT Bus. Posting Group", VATPostingSetup."VAT Bus. Posting Group");
        Vendor.Modify(true);
        exit(Vendor."No.");
    end;

    local procedure FindVATPostingSetup(var VATPostingSetup: Record "VAT Posting Setup"; VATBusinessPostingGroup: Code[20]; VATProductPostingGroup: Code[20])
    begin
        Clear(VATPostingSetup);
        VATPostingSetup.SetFilter("VAT Bus. Posting Group", VATBusinessPostingGroup);
        VATPostingSetup.SetFilter("VAT Prod. Posting Group", '<>%1', VATProductPostingGroup);
        VATPostingSetup.SetFilter("VAT %", '>0');
        VATPostingSetup.Next(LibraryRandom.RandInt(VATPostingSetup.Count));
    end;

#if not CLEAN26
    [Obsolete('The statistics action will be replaced with the PurchaseOrderStatistics action. The new action uses RunObject and does not run the action trigger. Use a page extension to modify the behaviour.', '26.0')]
    local procedure OpenPurchaseOrderStatisticsPage(No: Code[20])
    var
        PurchaseOrder: TestPage "Purchase Order";
    begin
        PurchaseOrder.OpenView();
        PurchaseOrder.FILTER.SetFilter("No.", No);
        PurchaseOrder.Statistics.Invoke();
    end;
#endif

    local procedure OpenPurchOrderStatisticsPage(No: Code[20])
    var
        PurchaseOrder: TestPage "Purchase Order";
    begin
        PurchaseOrder.OpenView();
        PurchaseOrder.FILTER.SetFilter("No.", No);
        PurchaseOrder.PurchaseOrderStatistics.Invoke();
    end;

#if not CLEAN26
    [Obsolete('The statistics action will be replaced with the SalesStatistics action. The new action uses RunObject and does not run the action trigger', '26.0')]
    local procedure OpenSalesOrderStatisticsPage(No: Code[20])
    var
        SalesOrder: TestPage "Sales Order";
    begin
        SalesOrder.OpenView();
        SalesOrder.FILTER.SetFilter("No.", No);
        SalesOrder.Statistics.Invoke();
    end;
#endif
    local procedure OpenSalesOrderStatisticsPageNM(No: Code[20])
    var
        SalesOrder: TestPage "Sales Order";
    begin
        SalesOrder.OpenView();
        SalesOrder.FILTER.SetFilter("No.", No);
        SalesOrder.SalesOrderStatistics.Invoke();
    end;

    local procedure UpdateCustomerPostingGroup()
    var
        GLAccount: Record "G/L Account";
        CustomerPostingGroup: Record "Customer Posting Group";
    begin
        LibraryERM.FindGLAccount(GLAccount);
        CustomerPostingGroup.FindFirst();
        CustomerPostingGroup.Validate("Bills Account", GLAccount."No.");
        CustomerPostingGroup.Modify(true);
    end;

    local procedure UpdateGeneralLedgerSetup(MaxVATDifferenceAllowed: Decimal) OldVATDifferenceAllowed: Decimal
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
    begin
        GeneralLedgerSetup.Get();
        OldVATDifferenceAllowed := GeneralLedgerSetup."Max. VAT Difference Allowed";
        GeneralLedgerSetup.Validate("Max. VAT Difference Allowed", MaxVATDifferenceAllowed);
        LibraryVariableStorage.Enqueue(MaxVATDifferenceAllowed);
        GeneralLedgerSetup.Modify(true);
    end;

    local procedure UpdatePurchasesPayablesSetup(AllowVATDifference: Boolean) OldAllowVATDifference: Boolean
    var
        PurchasesPayablesSetup: Record "Purchases & Payables Setup";
    begin
        PurchasesPayablesSetup.Get();
        OldAllowVATDifference := PurchasesPayablesSetup."Allow VAT Difference";
        PurchasesPayablesSetup.Validate("Allow VAT Difference", AllowVATDifference);
        PurchasesPayablesSetup.Modify(true);
    end;

    local procedure UpdateSalesReceivableSetup(AllowVATDifference: Boolean) OldAllowVATDifference: Boolean
    var
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
    begin
        SalesReceivablesSetup.Get();
        OldAllowVATDifference := SalesReceivablesSetup."Allow VAT Difference";
        SalesReceivablesSetup.Validate("Allow VAT Difference", AllowVATDifference);
        SalesReceivablesSetup.Modify(true);
    end;

    local procedure UpdateVendorPostingGroup()
    var
        GLAccount: Record "G/L Account";
        VendorPostingGroup: Record "Vendor Posting Group";
    begin
        LibraryERM.FindGLAccount(GLAccount);
        VendorPostingGroup.FindFirst();
        VendorPostingGroup.Validate("Bills Account", GLAccount."No.");
        VendorPostingGroup.Modify(true);
    end;

    local procedure VerifyVATAmountOnPostPurchaseInvStatistics(No: Code[20])
    var
        PurchInvHeader: Record "Purch. Inv. Header";
        PostedPurchaseInvoice: TestPage "Posted Purchase Invoice";
        PurchaseInvoiceStatistics: TestPage "Purchase Invoice Statistics";
        VATAmount: Variant;
    begin
        // Verify VAT Amount on VAT Amount lines in Statistics of Posted Purchase Invoice.
        PurchInvHeader.SetRange("No.", No);
        PurchInvHeader.FindFirst();
        PurchaseInvoiceStatistics.Trap();

        PostedPurchaseInvoice.OpenView();
        PostedPurchaseInvoice.GotoRecord(PurchInvHeader);
        PostedPurchaseInvoice.Statistics.Invoke();

        PurchaseInvoiceStatistics.SubForm.First();
        PurchaseInvoiceStatistics.SubForm.FILTER.SetFilter("VAT Amount", '>0');
        LibraryVariableStorage.Dequeue(VATAmount);
        PurchaseInvoiceStatistics.SubForm."VAT Amount".AssertEquals(VATAmount);
    end;

    local procedure VerifyVATAmountOnPostSalesInvStatistics(No: Code[20])
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
        PostedSalesInvoice: TestPage "Posted Sales Invoice";
        SalesInvoiceStatistics: TestPage "Sales Invoice Statistics";
        VATAmount: Variant;
    begin
        // Verify VAT Amount on VAT Amount lines in Statistics of Posted Sales Invoice.
        SalesInvoiceHeader.SetRange("No.", No);
        SalesInvoiceHeader.FindFirst();
        SalesInvoiceStatistics.Trap();

        PostedSalesInvoice.OpenView();
        PostedSalesInvoice.GotoRecord(SalesInvoiceHeader);
        PostedSalesInvoice.Statistics.Invoke();

        SalesInvoiceStatistics.Subform.First();
        SalesInvoiceStatistics.Subform.FILTER.SetFilter("VAT Amount", '>0');
        LibraryVariableStorage.Dequeue(VATAmount);
        SalesInvoiceStatistics.Subform."VAT Amount".AssertEquals(VATAmount);
    end;

#if not CLEAN26
    [Obsolete('The statistics action will be replaced with the PurchaseOrderStatistics action. The new action uses RunObject and does not run the action trigger. Use a page extension to modify the behaviour.', '26.0')]
    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure PurchaseOrderStatisticsHandler(var PurchaseOrderStatistics: TestPage "Purchase Order Statistics")
    begin
        // Modal Page Handler used to open VAT Amount Lines Page.
        PurchaseOrderStatistics.NoOfVATLines_Invoicing.DrillDown();
    end;
#endif

    [PageHandler]
    [Scope('OnPrem')]
    procedure PurchOrderStatisticsHandler(var PurchaseOrderStatistics: TestPage "Purchase Order Statistics")
    begin
        // Modal Page Handler used to open VAT Amount Lines Page.
        PurchaseOrderStatistics.NoOfVATLines_Invoicing.DrillDown();
    end;

#if not CLEAN26
    [Obsolete('The statistics action will be replaced with the SalesStatistics action. The new action uses RunObject and does not run the action trigger', '26.0')]
    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure SalesOrderStatisticsHandler(var SalesOrderStatistics: TestPage "Sales Order Statistics")
    begin
        // Modal Page Handler used to open VAT Amount Lines Page.
        SalesOrderStatistics.NoOfVATLines_Invoicing.DrillDown();
    end;
#endif
    [PageHandler]
    [Scope('OnPrem')]
    procedure SalesOrderStatisticsHandlerNM(var SalesOrderStatistics: TestPage "Sales Order Statistics")
    begin
        // Modal Page Handler used to open VAT Amount Lines Page.
        SalesOrderStatistics.NoOfVATLines_Invoicing.DrillDown();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure VATAmountLinesHandler(var VATAmountLine: TestPage "VAT Amount Lines")
    var
        OldVATDifferenceAllowed: Variant;
        OldVATDifferenceAllowed2: Decimal;
    begin
        // Modal Page Handler used to change VAT Amount on VAT Amount Lines.
        LibraryVariableStorage.Dequeue(OldVATDifferenceAllowed);
        OldVATDifferenceAllowed2 := OldVATDifferenceAllowed;
        LibraryVariableStorage.Enqueue(VATAmountLine."VAT Amount".AsDecimal() + OldVATDifferenceAllowed2);
        VATAmountLine."VAT Amount".SetValue(VATAmountLine."VAT Amount".AsDecimal() + OldVATDifferenceAllowed2);
    end;
}
