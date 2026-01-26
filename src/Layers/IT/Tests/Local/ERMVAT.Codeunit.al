codeunit 144139 "ERM VAT"
{
    // // [FEATURE] [VAT]
    // 
    //  1. Test to verify error on Unapply Vendor Invoice after running Calculate and Post VAT Settlement report with Unrealized VAT True.
    //  2. Test to verify error on Unapply Vendor Credit Memo after running Calculate and Post VAT Settlement report with Unrealized VAT False.
    //  3. Test to verify error on Unapply Customer Invoice after running Calculate and Post VAT Settlement report with Unrealized VAT True.
    //  4. Test to verify error on Unapply Customer Credit Memo after running Calculate and Post VAT Settlement report with Unrealized VAT False.
    //  5. Test to verify Unrealized VAT entry after posting Sales Credit Memo applied to Sales Invoice with Unrealized VAT.
    //  6. Test to verify Unrealized VAT entry after posting Purchase Credit Memo applied to Purchase Invoice with Unrealized VAT.
    //  7. Test to verify Service Tariff No. gets updated on Posted Sales Invoice when VAT Product Posting group is changed on the Sales Invoice Line.
    //  8. Test to verify Service Tariff No. gets updated on Posted Service Invoice when VAT Product Posting group is changed on the Service Invoice Line.
    //  9. Test to verify Service Tariff No. gets updated on Posted Purchase Invoice when VAT Product Posting group is changed on the Purchase Invoice Line.
    // 10. Test to verify Amount Including VAT field Caption on VAT Specification Subform.
    // 
    // Covers Test Cases for WI - 346274
    // ----------------------------------------------------------------------------------------------------------
    // Test Function Name                                                                               TFS ID
    // ----------------------------------------------------------------------------------------------------------
    // UnapplyVendInvoiceErrorWithUnrealizedVAT                                                         156497
    // UnapplyCustInvoiceErrorWithUnrealizedVAT                                                         156499
    // ApplySalesInvoiceToCreditMemoWithUnrealizedVAT                                                   302461
    // ApplyPurchaseInvoiceToCreditMemoWithUnrealizedVAT                                                306986
    // ServiceTariffNoOnSalesInvoice                                                                    242868
    // ServiceTariffNoOnServiceInvoice                                                                  242870
    // ServiceTariffNoOnPurchaseInvoice                                                                 242869
    // AmountIncludingVATCaptionOnVATSpecificationSubform                                               273741
    // 
    // Covers Test Cases for WI - 346781
    // ----------------------------------------------------------------------------------------------------------
    // Test Function Name                                                                               TFS ID
    // ----------------------------------------------------------------------------------------------------------
    // PurchNonDeductibleReverseVAT                                                                     355658

    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [VAT Settlement]
    end;

    var
        Assert: Codeunit Assert;
        LibraryCashFlowHelper: Codeunit "Library - Cash Flow Helper";
        LibraryERM: Codeunit "Library - ERM";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryJournals: Codeunit "Library - Journals";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibraryReportDataset: Codeunit "Library - Report Dataset";
        LibrarySales: Codeunit "Library - Sales";
        LibraryService: Codeunit "Library - Service";
        LibrarySetupStorage: Codeunit "Library - Setup Storage";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibraryRandom: Codeunit "Library - Random";
        LibraryUTUtility: Codeunit "Library UT Utility";
        AmountIncludingVATCap: Label 'Amount Including VAT';
        CannotUnapplyErr: Label 'You cannot unapply %1 No. %2 because the VAT settlement has been calculated and posted.';
        CaptionMsg: Label 'Caption must be same.';
        EntryDoesNotExistErr: Label '%1 with filters %2 does not exist.';
        WrongValueErr: Label 'Wrong value of field %2 in table %1.';
        LibraryUtility: Codeunit "Library - Utility";
        LibraryXPathXMLReader: Codeunit "Library - XPath XML Reader";
        VATCalculationType: Enum "Tax Calculation Type";
        GenPostingType: Enum "General Posting Type";
        isInitialized: Boolean;

    [Test]
    [HandlerFunctions('CalcAndPostVATSettlementRequestPageHandler,ConfirmHandler,UnapplyVendorEntriesModalPageHandler')]
    [Scope('OnPrem')]
    procedure UnapplyVendInvoiceErrorWithUnrealizedVAT()
    var
        VATPostingSetup: Record "VAT Posting Setup";
        Quantity: Decimal;
        DirectUnitCost: Decimal;
    begin
        // Test to verify error on Unapply Vendor Invoice after running Calculate and Post VAT Settlement report with Unrealized VAT True.
        Initialize();
        Quantity := LibraryRandom.RandDecInRange(10, 20, 2);
        DirectUnitCost := LibraryRandom.RandDecInRange(100, 200, 2);
        UnapplyVendorLedgerEntryError(
          true, VATPostingSetup."Unrealized VAT Type"::Percentage, "Gen. Journal Document Type"::Invoice, Quantity, DirectUnitCost,
          Quantity * DirectUnitCost / 2);  // True for Unrealized VAT and partial value required for Amount
    end;

    local procedure UnapplyVendorLedgerEntryError(UnrealizedVAT: Boolean; UnrealizedVATType: Option; DocumentType: Enum "Gen. Journal Document Type"; Quantity: Decimal; DirectUnitCost: Decimal; Amount: Decimal)
    var
        GLAccount: Record "G/L Account";
        GenJournalLine: Record "Gen. Journal Line";
        GenJournalTemplate: Record "Gen. Journal Template";
        GeneralLedgerSetup: Record "General Ledger Setup";
        PurchaseLine: Record "Purchase Line";
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        VATPostingSetup: Record "VAT Posting Setup";
        VendEntryApplyPostedEntries: Codeunit "VendEntry-Apply Posted Entries";
        AppliesToDocNo: Code[20];
    begin
        // Setup: Post Purchase Document and Payment Journal. Run Calculate and Post VAT Settlement report. Update VAT Period closed on Periodic Settlement VAT entry.
        GeneralLedgerSetup.Get();
        UpdateGeneralLedgerSetup(UnrealizedVAT, CalcDate('<CY - 1Y>', WorkDate()));  // Required for test case to set last date of the previous year to Work Date.
        LibraryERM.CreateVATPostingSetupWithAccounts(VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT", LibraryRandom.RandDecInRange(10, 20, 2));
        UpdateVATPostingSetup(
          VATPostingSetup."VAT Bus. Posting Group", VATPostingSetup."VAT Prod. Posting Group", false, UnrealizedVATType);  // False for EU Service.
        AppliesToDocNo :=
          CreateAndPostPurchaseDocument(
            PurchaseLine, DocumentType, CreateVendor(VATPostingSetup."VAT Bus. Posting Group"), '',
            CreateItem(VATPostingSetup."VAT Prod. Posting Group"), Quantity, DirectUnitCost); // Use Blank value for Applies To Doc No
        CreateAndPostGeneralJournalLine(
          GenJournalTemplate.Type::Payments, GenJournalLine."Account Type"::Vendor, PurchaseLine."Buy-from Vendor No.",
          Amount, CreateGLAccount(VATPostingSetup, GLAccount."Gen. Posting Type"::Purchase), DocumentType, AppliesToDocNo);
        RunCalcAndPostVATSettlementReport();
        UpdatePeriodicSettlementVATEntry();
        LibraryERM.FindVendorLedgerEntry(VendorLedgerEntry, PurchaseLine."Document Type", AppliesToDocNo);

        // Exercise: Unapply Vendor Ledger Entry.
        asserterror VendEntryApplyPostedEntries.UnApplyVendLedgEntry(VendorLedgerEntry."Entry No.");

        // Verify: Error on unapply Vendor Ledger Entry.
        Assert.ExpectedError(StrSubstNo(CannotUnapplyErr, PurchaseLine."Document Type", AppliesToDocNo));

        // Tear Down: Update VAT Posting Setup, General Ledger Setup and delete Periodic VAT Settlement entries.
        UpdateGeneralLedgerAndVATPostingSetups(GeneralLedgerSetup, VATPostingSetup);
        DeletePeriodicSettlementVATEntry(WorkDate());
        DeletePeriodicSettlementVATEntry(CalcDate('<1M>', WorkDate()));  // '1M' required for one month next to Workdate
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('CalcAndPostVATSettlementRequestPageHandler,ConfirmHandler,UnapplyCustomerEntriesModalPageHandler')]
    [Scope('OnPrem')]
    procedure UnapplyCustInvoiceErrorWithUnrealizedVAT()
    var
        VATPostingSetup: Record "VAT Posting Setup";
        Quantity: Decimal;
        UnitPrice: Decimal;
    begin
        // Test to verify error on Unapply Customer Invoice after running Calculate and Post VAT Settlement report with Unrealized VAT True.
        Initialize();
        Quantity := LibraryRandom.RandDecInRange(10, 20, 2);
        UnitPrice := LibraryRandom.RandDecInRange(100, 200, 2);
        UnapplyCustomerLedgerEntryError(
          true, VATPostingSetup."Unrealized VAT Type"::Percentage, "Gen. Journal Document Type"::Invoice, Quantity, UnitPrice,
          -Quantity * UnitPrice / 2);  // True for Unrealized VAT and partial value required for Amount
    end;

    local procedure UnapplyCustomerLedgerEntryError(UnrealizedVAT: Boolean; UnrealizedVATType: Option; DocumentType: Enum "Gen. Journal Document Type"; Quantity: Decimal; UnitPrice: Decimal; Amount: Decimal)
    var
        GenJournalLine: Record "Gen. Journal Line";
        GenJournalTemplate: Record "Gen. Journal Template";
        GLAccount: Record "G/L Account";
        GeneralLedgerSetup: Record "General Ledger Setup";
        SalesLine: Record "Sales Line";
        CustLedgerEntry: Record "Cust. Ledger Entry";
        VATPostingSetup: Record "VAT Posting Setup";
        CustEntryApplyPostedEntries: Codeunit "CustEntry-Apply Posted Entries";
        AppliesToDocNo: Code[20];
    begin
        // Setup: Post Sales Document and Cash Receipt Journal. Run Calculate and Post VAT Settlement report. Update VAT Period closed on Periodic Settlement VAT entry.
        GeneralLedgerSetup.Get();
        UpdateGeneralLedgerSetup(UnrealizedVAT, CalcDate('<CY - 1Y>', WorkDate()));  // Required for test case to set last date of the previous year to Work Date.
        LibraryERM.CreateVATPostingSetupWithAccounts(VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT", LibraryRandom.RandDecInRange(10, 20, 2));
        UpdateVATPostingSetup(
          VATPostingSetup."VAT Bus. Posting Group", VATPostingSetup."VAT Prod. Posting Group", false, UnrealizedVATType);  // False for EU Service
        AppliesToDocNo :=
          CreateAndPostSalesDocument(
            SalesLine, DocumentType, CreateCustomer(VATPostingSetup."VAT Bus. Posting Group"), '',
            CreateItem(VATPostingSetup."VAT Prod. Posting Group"), Quantity, UnitPrice);  // Use Blank value for Applies To Doc No.
        CreateAndPostGeneralJournalLine(
          GenJournalTemplate.Type::"Cash Receipts", GenJournalLine."Account Type"::Customer, SalesLine."Sell-to Customer No.",
          Amount, CreateGLAccount(VATPostingSetup, GLAccount."Gen. Posting Type"::Sale), DocumentType, AppliesToDocNo);
        RunCalcAndPostVATSettlementReport();
        UpdatePeriodicSettlementVATEntry();
        LibraryERM.FindCustomerLedgerEntry(CustLedgerEntry, SalesLine."Document Type", AppliesToDocNo);

        // Exercise: Unapply Customer Ledger Entry.
        asserterror CustEntryApplyPostedEntries.UnApplyCustLedgEntry(CustLedgerEntry."Entry No.");

        // Verify: Error on unapply Customer Ledger Entry.
        Assert.ExpectedError(StrSubstNo(CannotUnapplyErr, SalesLine."Document Type", AppliesToDocNo));

        // Tear Down: Update VAT Posting Setup, General Ledger Setup and delete Periodic VAT Settlement entries.
        UpdateGeneralLedgerAndVATPostingSetups(GeneralLedgerSetup, VATPostingSetup);
        DeletePeriodicSettlementVATEntry(WorkDate());
        DeletePeriodicSettlementVATEntry(CalcDate('<1M>', WorkDate()));  // '1M' required for one month next to Workdate
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ApplySalesInvoiceToCreditMemoWithUnrealizedVAT()
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
        SalesLine: Record "Sales Line";
        SalesLine2: Record "Sales Line";
        VATPostingSetup: Record "VAT Posting Setup";
        VATPostingSetup2: Record "VAT Posting Setup";
        AppliesToDocNo: Code[20];
        DocumentNo: Code[20];
    begin
        // Test to verify Unrealized VAT entry after posting Sales Credit Memo applied to Sales Invoice with Unrealized VAT.

        // Setup: Update General Ledger Setup and VAT Posting Setup. Create and Post Sales Invoice.
        Initialize();
        GeneralLedgerSetup.Get();
        UpdateGeneralLedgerSetup(true, CalcDate('<CY - 1Y>', WorkDate()));  // Required for test case to set last date of the previous year to Work Date. True for Unrealized VAT.
        LibraryERM.CreateVATPostingSetupWithAccounts(VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT", LibraryRandom.RandDecInRange(10, 20, 2));
        UpdateVATPostingSetup(
          VATPostingSetup."VAT Bus. Posting Group",
          VATPostingSetup."VAT Prod. Posting Group", false, VATPostingSetup."Unrealized VAT Type"::Percentage);  // False for EU Service
        AppliesToDocNo :=
          CreateAndPostSalesDocument(
            SalesLine, SalesLine."Document Type"::Invoice, CreateCustomer(VATPostingSetup."VAT Bus. Posting Group"), '',
            CreateItem(VATPostingSetup."VAT Prod. Posting Group"), LibraryRandom.RandDec(10, 2),
            LibraryRandom.RandDec(100, 2));  // Use Random value for Quantity and Unit Price, Blank value for Applies To Doc No

        // Exercise: Create and Post Sales Credit Memo after applying posted Sales Invoice.
        DocumentNo :=
          CreateAndPostSalesDocument(
            SalesLine2, SalesLine2."Document Type"::"Credit Memo", SalesLine."Sell-to Customer No.", AppliesToDocNo, SalesLine."No.",
            SalesLine.Quantity, SalesLine."Unit Price");

        // Verify: General Ledger entries.
        VATPostingSetup2.Get(VATPostingSetup."VAT Bus. Posting Group", VATPostingSetup."VAT Prod. Posting Group");
        VerifyGLEntries(
          DocumentNo, VATPostingSetup2."Sales VAT Unreal. Account", VATPostingSetup2."Sales VAT Account",
          Round(SalesLine.Amount * SalesLine."VAT %" / 100));

        // Tear Down: Update VAT Posting Setup and General Ledger Setup.
        UpdateGeneralLedgerAndVATPostingSetups(GeneralLedgerSetup, VATPostingSetup);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ApplyPurchaseInvoiceToCreditMemoWithUnrealizedVAT()
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
        PurchaseLine: Record "Purchase Line";
        PurchaseLine2: Record "Purchase Line";
        VATPostingSetup: Record "VAT Posting Setup";
        VATPostingSetup2: Record "VAT Posting Setup";
        AppliesToDocNo: Code[20];
        DocumentNo: Code[20];
    begin
        // Test to verify Unrealized VAT entry after posting Purchase Credit Memo applied to Purchase Invoice with Unrealized VAT.

        // Setup: Update General Ledger Setup and VAT Posting Setup. Create and Post Purchase Invoice.
        Initialize();
        GeneralLedgerSetup.Get();
        UpdateGeneralLedgerSetup(true, CalcDate('<CY - 1Y>', WorkDate()));  // Required for test case to set last date of the previous year to Work Date. True for Unrealized VAT.
        LibraryERM.CreateVATPostingSetupWithAccounts(VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT", LibraryRandom.RandDecInRange(10, 20, 2));
        UpdateVATPostingSetup(
          VATPostingSetup."VAT Bus. Posting Group",
          VATPostingSetup."VAT Prod. Posting Group", false, VATPostingSetup."Unrealized VAT Type"::Percentage);  // False for EU Service
        AppliesToDocNo :=
          CreateAndPostPurchaseDocument(
            PurchaseLine, PurchaseLine."Document Type"::Invoice, CreateVendor(VATPostingSetup."VAT Bus. Posting Group"), '',
            CreateItem(VATPostingSetup."VAT Prod. Posting Group"), LibraryRandom.RandDecInRange(10, 20, 2),
            LibraryRandom.RandDecInRange(100, 200, 2));  // Use Random value for Quantity and Direct Unit Cost, Blank value for Applies To Doc No

        // Exercise: Create and Post Purchase Credit Memo after applying posted Purchase Invoice.
        DocumentNo :=
          CreateAndPostPurchaseDocument(
            PurchaseLine2, PurchaseLine2."Document Type"::"Credit Memo", PurchaseLine."Buy-from Vendor No.", AppliesToDocNo,
            PurchaseLine."No.", PurchaseLine.Quantity, PurchaseLine."Direct Unit Cost");

        // Verify: General Ledger entries.
        VATPostingSetup2.Get(VATPostingSetup."VAT Bus. Posting Group", VATPostingSetup."VAT Prod. Posting Group");
        VerifyGLEntries(
          DocumentNo, VATPostingSetup2."Purchase VAT Account", VATPostingSetup2."Purch. VAT Unreal. Account",
          Round(PurchaseLine.Amount * PurchaseLine."VAT %" / 100));

        // Tear Down: Update VAT Posting Setup and General Ledger Setup.
        UpdateGeneralLedgerAndVATPostingSetups(GeneralLedgerSetup, VATPostingSetup);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ServiceTariffNoOnSalesInvoice()
    var
        GLAccount: Record "G/L Account";
        SalesHeader: Record "Sales Header";
        VATPostingSetup: Record "VAT Posting Setup";
        VATPostingSetup2: Record "VAT Posting Setup";
        DummyVATPostingSetup: Record "VAT Posting Setup";
        DocumentNo: Code[20];
        GLAccountNo: Code[20];
        GLAccountNo2: Code[20];
    begin
        // Test to verify Service Tariff No. gets updated on Posted Sales Invoice when VAT Product Posting group is changed on the Sales Invoice Line.

        // Setup: Create Sales Invoice of two lines with different VAT Posting Setup. Update VAT Product Posting groups on two Sales Invoice Lines.
        Initialize();
        LibraryERM.CreateVATPostingSetupWithAccounts(VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT", LibraryRandom.RandDecInRange(10, 20, 2));
        UpdateVATPostingSetup(
          VATPostingSetup."VAT Bus. Posting Group",
          VATPostingSetup."VAT Prod. Posting Group", false, VATPostingSetup."Unrealized VAT Type"::" ");  // False for EU Service.
        GLAccountNo := CreateGLAccount(VATPostingSetup, GLAccount."Gen. Posting Type"::Sale);
        LibraryERM.CreateVATPostingSetupWithAccounts(VATPostingSetup2, VATPostingSetup2."VAT Calculation Type"::"Reverse Charge VAT", LibraryRandom.RandDecInRange(10, 20, 2));
        UpdateVATPostingSetup(
          VATPostingSetup2."VAT Bus. Posting Group",
          VATPostingSetup2."VAT Prod. Posting Group", true, VATPostingSetup2."Unrealized VAT Type"::" ");  // True for EU Service.
        LibraryERM.CreateVATPostingSetup(DummyVATPostingSetup, VATPostingSetup."VAT Bus. Posting Group", VATPostingSetup2."VAT Prod. Posting Group");
        GLAccountNo2 := CreateGLAccount(VATPostingSetup2, GLAccount."Gen. Posting Type"::Sale);
        CreateSalesInvoiceWithMultipleLines(SalesHeader, VATPostingSetup."VAT Bus. Posting Group", GLAccountNo, GLAccountNo2);
        UpdateVATProductPostingGroupOnSalesLine(SalesHeader."No.", GLAccountNo, VATPostingSetup2."VAT Prod. Posting Group");
        UpdateVATProductPostingGroupOnSalesLine(SalesHeader."No.", GLAccountNo2, VATPostingSetup."VAT Prod. Posting Group");

        // Exercise: Post Sales Invoice.
        DocumentNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);  // True for Ship and Invoice

        // Verify: Service Tariff No. gets updated on Posted Sales Invoice Lines.
        VerifyPostedSalesInvoiceLine(DocumentNo, GLAccountNo, SalesHeader."Service Tariff No.");
        VerifyPostedSalesInvoiceLine(DocumentNo, GLAccountNo2, '');  // Blank Service Tariff No. for VAT Posting Setup with EU Service as False

        // Tear Down.
        UpdateVATPostingSetups(VATPostingSetup, VATPostingSetup2);
        DummyVATPostingSetup.Delete();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ServiceTariffNoOnServiceInvoice()
    var
        GLAccount: Record "G/L Account";
        ServiceHeader: Record "Service Header";
        VATPostingSetup: Record "VAT Posting Setup";
        VATPostingSetup2: Record "VAT Posting Setup";
        DummyVATPostingSetup: Record "VAT Posting Setup";
        GLAccountNo: Code[20];
        GLAccountNo2: Code[20];
    begin
        // Test to verify Service Tariff No. gets updated on Posted Service Invoice when VAT Product Posting group is changed on the Service Invoice Line.

        // Setup: Create Service Invoice of two lines with different VAT Posting Setup. Update VAT Product Posting groups on two Service Invoice Lines.
        Initialize();
        LibraryERM.CreateVATPostingSetupWithAccounts(VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT", LibraryRandom.RandDecInRange(10, 20, 2));
        UpdateVATPostingSetup(
          VATPostingSetup."VAT Bus. Posting Group",
          VATPostingSetup."VAT Prod. Posting Group", false, VATPostingSetup."Unrealized VAT Type"::" ");
        GLAccountNo := CreateGLAccount(VATPostingSetup, GLAccount."Gen. Posting Type"::Sale);
        LibraryERM.CreateVATPostingSetupWithAccounts(VATPostingSetup2, VATPostingSetup2."VAT Calculation Type"::"Reverse Charge VAT", LibraryRandom.RandDecInRange(10, 20, 2));
        UpdateVATPostingSetup(
          VATPostingSetup2."VAT Bus. Posting Group",
          VATPostingSetup2."VAT Prod. Posting Group", true, VATPostingSetup2."Unrealized VAT Type"::" ");
        LibraryERM.CreateVATPostingSetup(DummyVATPostingSetup, VATPostingSetup."VAT Bus. Posting Group", VATPostingSetup2."VAT Prod. Posting Group");
        GLAccountNo2 := CreateGLAccount(VATPostingSetup2, GLAccount."Gen. Posting Type"::Sale);
        CreateServiceInvoiceWithMultipleLines(ServiceHeader, VATPostingSetup."VAT Bus. Posting Group", GLAccountNo, GLAccountNo2);
        UpdateVATProductPostingGroupOnServiceLine(ServiceHeader."No.", GLAccountNo, VATPostingSetup2."VAT Prod. Posting Group");
        UpdateVATProductPostingGroupOnServiceLine(ServiceHeader."No.", GLAccountNo2, VATPostingSetup."VAT Prod. Posting Group");

        // Exercise: Post Service Invoice.
        LibraryService.PostServiceOrder(ServiceHeader, true, false, true);  // True for Ship and Invoice

        // Verify: Service Tariff No. gets updated on Posted Service Invoice Lines.
        VerifyPostedServiceInvoiceLine(ServiceHeader."Customer No.", GLAccountNo, ServiceHeader."Service Tariff No.");
        VerifyPostedServiceInvoiceLine(ServiceHeader."Customer No.", GLAccountNo2, '');  // Blank Service Tariff No. for VAT Posting Setup with EU Service as False

        // Tear Down.
        UpdateVATPostingSetups(VATPostingSetup, VATPostingSetup2);
        DummyVATPostingSetup.Delete();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ServiceTariffNoOnPurchaseInvoice()
    var
        GLAccount: Record "G/L Account";
        PurchaseHeader: Record "Purchase Header";
        VATPostingSetup: Record "VAT Posting Setup";
        VATPostingSetup2: Record "VAT Posting Setup";
        DummyVATPostingSetup: Record "VAT Posting Setup";
        DocumentNo: Code[20];
        GLAccountNo: Code[20];
        GLAccountNo2: Code[20];
    begin
        // Test to verify Service Tariff No. gets updated on Posted Purchase Invoice when VAT Product Posting group is changed on the Purchase Invoice Line.

        // Setup: Create Purchase Invoice of two lines with different VAT Posting Setup. Update VAT Product Posting groups on two Purchase Invoice Lines.
        Initialize();
        LibraryERM.CreateVATPostingSetupWithAccounts(VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT", LibraryRandom.RandDecInRange(10, 20, 2));
        UpdateVATPostingSetup(
          VATPostingSetup."VAT Bus. Posting Group",
          VATPostingSetup."VAT Prod. Posting Group", false, VATPostingSetup."Unrealized VAT Type"::" ");
        GLAccountNo := CreateGLAccount(VATPostingSetup, GLAccount."Gen. Posting Type"::Purchase);
        LibraryERM.CreateVATPostingSetupWithAccounts(VATPostingSetup2, VATPostingSetup2."VAT Calculation Type"::"Reverse Charge VAT", LibraryRandom.RandDecInRange(10, 20, 2));
        UpdateVATPostingSetup(
          VATPostingSetup2."VAT Bus. Posting Group",
          VATPostingSetup2."VAT Prod. Posting Group", true, VATPostingSetup2."Unrealized VAT Type"::" ");
        LibraryERM.CreateVATPostingSetup(DummyVATPostingSetup, VATPostingSetup."VAT Bus. Posting Group", VATPostingSetup2."VAT Prod. Posting Group");
        GLAccountNo2 := CreateGLAccount(VATPostingSetup2, GLAccount."Gen. Posting Type"::Purchase);
        CreatePurchaseInvoiceWithMultipleLines(PurchaseHeader, VATPostingSetup."VAT Bus. Posting Group", GLAccountNo, GLAccountNo2);
        UpdateVATProductPostingGroupOnPurchaseLine(PurchaseHeader."No.", GLAccountNo, VATPostingSetup2."VAT Prod. Posting Group");
        UpdateVATProductPostingGroupOnPurchaseLine(PurchaseHeader."No.", GLAccountNo2, VATPostingSetup."VAT Prod. Posting Group");

        // Exercise: Post Purchase Invoice.
        DocumentNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);  // True for Receive and Invoice

        // Verify: Service Tariff No. gets updated on Posted Purchase Invoice Lines.
        VerifyPostedPurchaseInvoiceLine(DocumentNo, GLAccountNo, PurchaseHeader."Service Tariff No.");
        VerifyPostedPurchaseInvoiceLine(DocumentNo, GLAccountNo2, '');  // Blank Service Tariff No. for VAT Posting Setup with EU Service as False

        // Tear Down.
        UpdateVATPostingSetups(VATPostingSetup, VATPostingSetup2);
        DummyVATPostingSetup.Delete();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure AmountIncludingVATCaptionOnVATSpecificationSubform()
    var
        VATSpecificationSubform: TestPage "VAT Specification Subform";
    begin
        // Test to verify Amount Including VAT field Caption on VAT Specification Subform.

        // Setup.
        Initialize();

        // Exercise: Open VAT Specification Subform.
        VATSpecificationSubform.OpenEdit();

        // Verify: Amount Including VAT field Caption on VAT Specification Subform.
        Assert.AreEqual(StrSubstNo(AmountIncludingVATCap), VATSpecificationSubform."Amount Including VAT".Caption, CaptionMsg);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchNonDeductibleReverseVAT()
    var
        VATPostingSetup: Record "VAT Posting Setup";
        PurchLine: Record "Purchase Line";
        GLEntry: Record "G/L Entry";
        VATEntry: Record "VAT Entry";
        DocNo: Code[20];
    begin
        // Test to verify that 100% Non-Deductible Reverse Charge VAT posted correctly.

        Initialize();
        CreateHundredPctNDReverseChargeVATPostingSetup(VATPostingSetup);
        DocNo := CreatePostPurchInvoiceWithVATSetup(PurchLine, VATPostingSetup);
        VerifyCreditGLEntryExists(
          GLEntry."Document Type"::Invoice, DocNo, VATPostingSetup."Reverse Chrg. VAT Acc.");
        VerifyReverseChargeDeductibleVATEntries(VATEntry."Document Type"::Invoice, DocNo);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ApplyCustEntryWithNotExistingAppliesToDocNo()
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
        GenJournalLine: Record "Gen. Journal Line";
        GenJnlPostLine: Codeunit "Gen. Jnl.-Post Line";
    begin
        // [FEATURE] [Apply] [Sales]
        // [SCENARIO 381909] Stan gets error when trying to post the payment applied to non-existing sales invoice
        Initialize();

        // [GIVEN] Customer Payment line for 100, which applies to not existing Document
        CreatePaymentLine(
          GenJournalLine, GenJournalLine."Account Type"::Customer, LibrarySales.CreateCustomerNo(),
          -LibraryRandom.RandDec(100, 2), LibraryUTUtility.GetNewCode());

        // [GIVEN] Customer Ledger Entry
        CustLedgerEntry.Init();
        CustLedgerEntry."Customer No." := LibrarySales.CreateCustomerNo();
        CustLedgerEntry."Amount to Apply" := GenJournalLine.Amount;
        CustLedgerEntry.Insert();

        // [WHEN] Apply
        asserterror GenJnlPostLine.CustPostApplyCustLedgEntry(GenJournalLine, CustLedgerEntry);

        // [THEN] "There is no Cust. Ledger Entry within the filter." error appears
        Assert.ExpectedError('There is no Cust. Ledger Entry within the filter.');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ApplyVendEntryWithNotExistingAppliesToDocNo()
    var
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        GenJournalLine: Record "Gen. Journal Line";
        GenJnlPostLine: Codeunit "Gen. Jnl.-Post Line";
    begin
        // [FEATURE] [Apply] [Purchase]
        // [SCENARIO 381909] Stan gets error when trying to post the payment applied to non-existing purchase invoice
        Initialize();

        // [GIVEN] Vendor Payment line for 100, which applies to not existing Document
        CreatePaymentLine(
          GenJournalLine, GenJournalLine."Account Type"::Vendor, LibraryPurchase.CreateVendorNo(),
          LibraryRandom.RandDec(100, 2), LibraryUTUtility.GetNewCode());

        // [GIVEN] Vendor Ledger Entry
        VendorLedgerEntry.Init();
        VendorLedgerEntry."Vendor No." := LibraryPurchase.CreateVendorNo();
        VendorLedgerEntry."Amount to Apply" := GenJournalLine.Amount;
        VendorLedgerEntry.Insert();

        // [WHEN] Apply
        asserterror GenJnlPostLine.VendPostApplyVendLedgEntry(GenJournalLine, VendorLedgerEntry);

        // [THEN] "There is no Vendor Ledger Entry within the filter." error appears.
        Assert.ExpectedError('There is no Vendor Ledger Entry within the filter.');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ApplyCustEntryTwice()
    var
        GenJournalLine: Record "Gen. Journal Line";
        SalesHeader: Record "Sales Header";
        DocumentNo: Code[20];
    begin
        // [FEATURE] [Apply] [Sales]
        // [SCENARIO 381909] Stan gets error when trying to post the payment applied to closed sales invoice (fully applied).
        Initialize();

        // [GIVEN] Posted Sales Document with "Amount incl. VAT" = 100
        LibraryCashFlowHelper.CreateDefaultSalesOrder(SalesHeader);
        SalesHeader.CalcFields("Amount Including VAT");
        DocumentNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // [GIVEN] Posted payment for 100
        CreatePaymentLine(
          GenJournalLine, GenJournalLine."Account Type"::Customer, SalesHeader."Sell-to Customer No.",
          -SalesHeader."Amount Including VAT", DocumentNo);

        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // [GIVEN] Another payment for 100
        CreatePaymentLine(
          GenJournalLine, GenJournalLine."Account Type"::Customer, SalesHeader."Sell-to Customer No.",
          -SalesHeader."Amount Including VAT", DocumentNo);

        // [WHEN] Post the 2nd payment
        asserterror LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // [THEN] "There is no Cust. Ledger Entry within the filter." error appears
        Assert.ExpectedError('There is no Cust. Ledger Entry within the filter.');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ApplyVendEntryTwice()
    var
        GenJournalLine: Record "Gen. Journal Line";
        PurchaseHeader: Record "Purchase Header";
        DocumentNo: Code[20];
    begin
        // [FEATURE] [Apply] [Purchase]
        // [SCENARIO 381909] Stan gets error when trying to post the payment applied to closed purchase invoice (fully applied).
        Initialize();

        // [GIVEN] Posted Purchase Document with "Amount incl. VAT" = 100
        LibraryCashFlowHelper.CreateDefaultPurchaseOrder(PurchaseHeader);
        PurchaseHeader.CalcFields("Amount Including VAT");
        DocumentNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        // [GIVEN] Posted payment for 100
        CreatePaymentLine(
          GenJournalLine, GenJournalLine."Account Type"::Vendor, PurchaseHeader."Buy-from Vendor No.",
          PurchaseHeader."Amount Including VAT", DocumentNo);

        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // [GIVEN] Another payment for 100
        CreatePaymentLine(
          GenJournalLine, GenJournalLine."Account Type"::Vendor, PurchaseHeader."Buy-from Vendor No.",
          PurchaseHeader."Amount Including VAT", DocumentNo);

        // [WHEN] Post the 2nd payment
        asserterror LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // [THEN] "There is no Vendor Ledger Entry within the filter." error appears
        Assert.ExpectedError('There is no Vendor Ledger Entry within the filter.');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ChangedVATBusPostingGroupInSalesOrderWithSellToByFrom()
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
        VATBusinessPostingGroup: Record "VAT Business Posting Group";
        VATRegister: Record "VAT Register";
        NoSeries: Record "No. Series";
        Customer: Record Customer;
        SalesHeader: Record "Sales Header";
    begin
        // [FEATURE] [Sales] [VAT]
        // [SCENARIO 332002] In new sales order VAT Bus. Posting Group is changed to new custom created.
        // [GIVEN] The field "Bill-to/Sell-to VAT Calc." from General Ledger Setup was set up to "Sell-to/Buy-from No.";
        GeneralLedgerSetup.Get();
        GeneralLedgerSetup.Validate("Bill-to/Sell-to VAT Calc.", GeneralLedgerSetup."Bill-to/Sell-to VAT Calc."::"Sell-to/Buy-from No.");
        GeneralLedgerSetup.Modify(true);

        // [GIVEN] VAT Register "V" with sales type was created.
        CreateVateRegisterWithSalesType(VATRegister);

        // [GIVEN] No Series "N" was created with assigned "V".
        LibraryUtility.CreateNoSeries(NoSeries, true, false, true);
        NoSeries.Validate("No. Series Type", NoSeries."No. Series Type"::Sales);
        NoSeries.Validate("VAT Register", VATRegister.Code);
        NoSeries.Modify(true);

        // [GIVEN] VATBusinessPostingGroup "VB" was created with "N" as "Default Sales Operation Type".
        LibraryERM.CreateVATBusinessPostingGroup(VATBusinessPostingGroup);
        VATBusinessPostingGroup.Validate("Default Sales Operation Type", NoSeries.Code);
        VATBusinessPostingGroup.Modify(true);

        // [GIVEN] Sales Order "S" was created.
        LibrarySales.CreateCustomer(Customer);
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, Customer."No.");

        // [WHEN] "VAT Bus. Posting Group" is changed to "VB" in "S"
        SalesHeader.Validate("VAT Bus. Posting Group", VATBusinessPostingGroup.Code);
        SalesHeader.Modify(true);

        // [THEN] "VAT Bus. Posting Group" should be "VB" in "S"
        Assert.AreEqual(SalesHeader."VAT Bus. Posting Group", VATBusinessPostingGroup.Code, 'SalesHeader."VAT Bus. Posting Group"');

        // [THEN] "Operation Type" should be "N" in "S"
        Assert.AreEqual(SalesHeader."Operation Type", NoSeries.Code, 'SalesHeader."Operation Type"');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ChangedVATBusPostingGroupInPurchaseOrderWithSellToByFrom()
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
        VATBusinessPostingGroup: Record "VAT Business Posting Group";
        VATRegister: Record "VAT Register";
        NoSeries: Record "No. Series";
        Vendor: Record Vendor;
        PurchaseHeader: Record "Purchase Header";
    begin
        // [FEATURE] [Purchase] [VAT]
        // [SCENARIO 332002] In new purchase order VAT Bus. Posting Group is changed to new custom created.
        // [GIVEN] The field "Bill-to/Sell-to VAT Calc." from General Ledger Setup was set up to "Sell-to/Buy-from No.";
        GeneralLedgerSetup.Get();
        GeneralLedgerSetup.Validate("Bill-to/Sell-to VAT Calc.", GeneralLedgerSetup."Bill-to/Sell-to VAT Calc."::"Sell-to/Buy-from No.");
        GeneralLedgerSetup.Modify(true);

        // [GIVEN] VAT Register "V" with purchase type was created.
        CreateVateRegisterWithPurchaseType(VATRegister);

        // [GIVEN] No Series "N" was created with assigned "V".
        LibraryUtility.CreateNoSeries(NoSeries, true, false, true);
        NoSeries.Validate("No. Series Type", NoSeries."No. Series Type"::Purchase);
        NoSeries.Validate("VAT Register", VATRegister.Code);
        NoSeries.Modify(true);

        // [GIVEN] VATBusinessPostingGroup "VB" was created with "N" as "Default Sales Operation Type".
        LibraryERM.CreateVATBusinessPostingGroup(VATBusinessPostingGroup);
        VATBusinessPostingGroup.Validate("Default Purch. Operation Type", NoSeries.Code);
        VATBusinessPostingGroup.Modify(true);

        // [GIVEN] Purchase Order "P" was created.
        LibraryPurchase.CreateVendor(Vendor);
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, Vendor."No.");

        // [WHEN] "VAT Bus. Posting Group" is changed to "VB" in "P"
        PurchaseHeader.Validate("VAT Bus. Posting Group", VATBusinessPostingGroup.Code);
        PurchaseHeader.Modify(true);

        // [THEN] "VAT Bus. Posting Group" should be "VB" in "P"
        Assert.AreEqual(PurchaseHeader."VAT Bus. Posting Group", VATBusinessPostingGroup.Code, 'PurchaseHeader."VAT Bus. Posting Group"');

        // [THEN] "Operation Type" should be "N" in "P"
        Assert.AreEqual(PurchaseHeader."Operation Type", NoSeries.Code, 'PurchaseHeader."Operation Type"');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ChangedVATBusPostingGroupInServiceOrderWithSellToByFrom()
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
        VATBusinessPostingGroup: Record "VAT Business Posting Group";
        VATRegister: Record "VAT Register";
        NoSeries: Record "No. Series";
        Customer: Record Customer;
        ServiceHeader: Record "Service Header";
    begin
        // [FEATURE] [Service] [VAT]
        // [SCENARIO 332002] In new service order VAT Bus. Posting Group is changed to new custom created.
        // [GIVEN] The field "Bill-to/Sell-to VAT Calc." from General Ledger Setup was set up to "Sell-to/Buy-from No.";
        GeneralLedgerSetup.Get();
        GeneralLedgerSetup.Validate("Bill-to/Sell-to VAT Calc.", GeneralLedgerSetup."Bill-to/Sell-to VAT Calc."::"Sell-to/Buy-from No.");
        GeneralLedgerSetup.Modify(true);

        // [GIVEN] VAT Register "V" with sales type was created.
        CreateVateRegisterWithSalesType(VATRegister);

        // [GIVEN] No Series "N" was created with assigned "V".
        LibraryUtility.CreateNoSeries(NoSeries, true, false, true);
        NoSeries.Validate("No. Series Type", NoSeries."No. Series Type"::Sales);
        NoSeries.Validate("VAT Register", VATRegister.Code);
        NoSeries.Modify(true);

        // [GIVEN] VATBusinessPostingGroup "VB" was created with "N" as "Default Sales Operation Type".
        LibraryERM.CreateVATBusinessPostingGroup(VATBusinessPostingGroup);
        VATBusinessPostingGroup.Validate("Default Sales Operation Type", NoSeries.Code);
        VATBusinessPostingGroup.Modify(true);

        // [GIVEN] Servise Order "S" was created.
        LibrarySales.CreateCustomer(Customer);
        LibraryService.CreateServiceHeader(ServiceHeader, ServiceHeader."Document Type"::Order, Customer."No.");

        // [WHEN] "VAT Bus. Posting Group" is changed to "VB" in "S"
        ServiceHeader.Validate("VAT Bus. Posting Group", VATBusinessPostingGroup.Code);
        ServiceHeader.Modify(true);

        // [THEN] "VAT Bus. Posting Group" should be "VB" in "S"
        Assert.AreEqual(ServiceHeader."VAT Bus. Posting Group", VATBusinessPostingGroup.Code, 'PurchaseHeader."VAT Bus. Posting Group"');

        // [THEN] "Operation Type" should be "N" in "S"
        Assert.AreEqual(ServiceHeader."Operation Type", NoSeries.Code, 'PurchaseHeader."Operation Type"');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ChangedVATBusPostingGroupInSalesOrderWithBillToPayTo()
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
        VATBusinessPostingGroup: Record "VAT Business Posting Group";
        VATRegister: Record "VAT Register";
        NoSeries: Record "No. Series";
        Customer: Record Customer;
        SalesHeader: Record "Sales Header";
    begin
        // [FEATURE] [Sales] [VAT]
        // [SCENARIO 332002] In new sales order VAT Bus. Posting Group is changed to new custom created.
        // [GIVEN] The field "Bill-to/Sell-to VAT Calc." from General Ledger Setup was set up to "Bill-to/Pay-to No.";
        GeneralLedgerSetup.Get();
        GeneralLedgerSetup.Validate("Bill-to/Sell-to VAT Calc.", GeneralLedgerSetup."Bill-to/Sell-to VAT Calc."::"Bill-to/Pay-to No.");
        GeneralLedgerSetup.Modify(true);

        // [GIVEN] VAT Register "V" with sales type was created.
        CreateVateRegisterWithSalesType(VATRegister);

        // [GIVEN] No Series "N" was created with assigned "V".
        LibraryUtility.CreateNoSeries(NoSeries, true, false, true);
        NoSeries.Validate("No. Series Type", NoSeries."No. Series Type"::Sales);
        NoSeries.Validate("VAT Register", VATRegister.Code);
        NoSeries.Modify(true);

        // [GIVEN] VATBusinessPostingGroup "VB" was created with "N" as "Default Sales Operation Type".
        LibraryERM.CreateVATBusinessPostingGroup(VATBusinessPostingGroup);
        VATBusinessPostingGroup.Validate("Default Sales Operation Type", NoSeries.Code);
        VATBusinessPostingGroup.Modify(true);

        // [GIVEN] Sales Order "S" was created.
        LibrarySales.CreateCustomer(Customer);
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, Customer."No.");

        // [WHEN] "VAT Bus. Posting Group" is changed to "VB" in "S"
        SalesHeader.Validate("VAT Bus. Posting Group", VATBusinessPostingGroup.Code);
        SalesHeader.Modify(true);

        // [THEN] "VAT Bus. Posting Group" should be "VB" in "S"
        Assert.AreEqual(SalesHeader."VAT Bus. Posting Group", VATBusinessPostingGroup.Code, 'SalesHeader."VAT Bus. Posting Group"');

        // [THEN] "Operation Type" should be "N" in "S"
        Assert.AreEqual(SalesHeader."Operation Type", NoSeries.Code, 'SalesHeader."Operation Type"');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ChangedVATBusPostingGroupInPurchaseOrderWithBillToPayTo()
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
        VATBusinessPostingGroup: Record "VAT Business Posting Group";
        VATRegister: Record "VAT Register";
        NoSeries: Record "No. Series";
        Vendor: Record Vendor;
        PurchaseHeader: Record "Purchase Header";
    begin
        // [FEATURE] [Purchase] [VAT]
        // [SCENARIO 332002] In new purchase order VAT Bus. Posting Group is changed to new custom created.
        // [GIVEN] The field "Bill-to/Sell-to VAT Calc." from General Ledger Setup was set up to "Bill-to/Pay-to No.";
        GeneralLedgerSetup.Get();
        GeneralLedgerSetup.Validate("Bill-to/Sell-to VAT Calc.", GeneralLedgerSetup."Bill-to/Sell-to VAT Calc."::"Bill-to/Pay-to No.");
        GeneralLedgerSetup.Modify(true);

        // [GIVEN] VAT Register "V" with purchase type was created.
        CreateVateRegisterWithPurchaseType(VATRegister);

        // [GIVEN] No Series "N" was created with assigned "V".
        LibraryUtility.CreateNoSeries(NoSeries, true, false, true);
        NoSeries.Validate("No. Series Type", NoSeries."No. Series Type"::Purchase);
        NoSeries.Validate("VAT Register", VATRegister.Code);
        NoSeries.Modify(true);

        // [GIVEN] VATBusinessPostingGroup "VB" was created with "N" as "Default Sales Operation Type".
        LibraryERM.CreateVATBusinessPostingGroup(VATBusinessPostingGroup);
        VATBusinessPostingGroup.Validate("Default Purch. Operation Type", NoSeries.Code);
        VATBusinessPostingGroup.Modify(true);

        // [GIVEN] Purchase Order "P" was created.
        LibraryPurchase.CreateVendor(Vendor);
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, Vendor."No.");

        // [WHEN] "VAT Bus. Posting Group" is changed to "VB" in "P"
        PurchaseHeader.Validate("VAT Bus. Posting Group", VATBusinessPostingGroup.Code);
        PurchaseHeader.Modify(true);

        // [THEN] "VAT Bus. Posting Group" should be "VB" in "P"
        Assert.AreEqual(PurchaseHeader."VAT Bus. Posting Group", VATBusinessPostingGroup.Code, 'PurchaseHeader."VAT Bus. Posting Group"');

        // [THEN] "Operation Type" should be "N" in "P"
        Assert.AreEqual(PurchaseHeader."Operation Type", NoSeries.Code, 'PurchaseHeader."Operation Type"');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ChangedVATBusPostingGroupInServiceOrderWithBillToPayTo()
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
        VATBusinessPostingGroup: Record "VAT Business Posting Group";
        VATRegister: Record "VAT Register";
        NoSeries: Record "No. Series";
        Customer: Record Customer;
        ServiceHeader: Record "Service Header";
    begin
        // [FEATURE] [Service] [VAT]
        // [SCENARIO 332002] In new service order VAT Bus. Posting Group is changed to new custom created.
        // [GIVEN] The field "Bill-to/Sell-to VAT Calc." from General Ledger Setup was set up to "Bill-to/Pay-to No.";
        GeneralLedgerSetup.Get();
        GeneralLedgerSetup.Validate("Bill-to/Sell-to VAT Calc.", GeneralLedgerSetup."Bill-to/Sell-to VAT Calc."::"Bill-to/Pay-to No.");
        GeneralLedgerSetup.Modify(true);

        // [GIVEN] VAT Register "V" with sales type was created.
        CreateVateRegisterWithSalesType(VATRegister);

        // [GIVEN] No Series "N" was created with assigned "V".
        LibraryUtility.CreateNoSeries(NoSeries, true, false, true);
        NoSeries.Validate("No. Series Type", NoSeries."No. Series Type"::Sales);
        NoSeries.Validate("VAT Register", VATRegister.Code);
        NoSeries.Modify(true);

        // [GIVEN] VATBusinessPostingGroup "VB" was created with "N" as "Default Sales Operation Type".
        LibraryERM.CreateVATBusinessPostingGroup(VATBusinessPostingGroup);
        VATBusinessPostingGroup.Validate("Default Sales Operation Type", NoSeries.Code);
        VATBusinessPostingGroup.Modify(true);

        // [GIVEN] Servise Order "S" was created.
        LibrarySales.CreateCustomer(Customer);
        LibraryService.CreateServiceHeader(ServiceHeader, ServiceHeader."Document Type"::Order, Customer."No.");

        // [WHEN] "VAT Bus. Posting Group" is changed to "VB" in "S"
        ServiceHeader.Validate("VAT Bus. Posting Group", VATBusinessPostingGroup.Code);
        ServiceHeader.Modify(true);

        // [THEN] "VAT Bus. Posting Group" should be "VB" in "S"
        Assert.AreEqual(ServiceHeader."VAT Bus. Posting Group", VATBusinessPostingGroup.Code, 'PurchaseHeader."VAT Bus. Posting Group"');

        // [THEN] "Operation Type" should be "N" in "S"
        Assert.AreEqual(ServiceHeader."Operation Type", NoSeries.Code, 'PurchaseHeader."Operation Type"');
    end;

    [Test]
    [HandlerFunctions('CalcAndPostVATSettlementFileNameRequestPageHandler')]
    procedure RunCalcPostVATSttlmtWithPostSetOnSalesDocNormalVAT()
    var
        VATPostingSetup: array[3] of Record "VAT Posting Setup";
        VATEntry: array[3] of Record "VAT Entry";
        PostedDocNo: array[3] of Code[20];
        VATSettlementDocNo: Code[20];
        SettlementVATEntryNo: array[3] of Integer;
    begin
        // [FEATURE] [Report] [Sales]
        // [SCENARIO 398537] Run Calc. and Post VAT Settlement report with Post option set on three posted Sales Invoices with different VAT Posting Setup of "Normal VAT" calculation type.
        // [SCENARIO 411666] Run Calc. and Post VAT Settlement report with Post option set on posted Sales Invoice with VAT Posting Setup with VAT% = 0 and "Normal VAT" calculation type.
        Initialize();
        UpdateLastSettlementDateOnGLSetup();

        // [GIVEN] Three VAT Posting Setup records with VAT Calculation Type = "Normal VAT". Second VAT Posting Setup has VAT % = 0.
        CreateThreeVATPostingSetup(VATPostingSetup, VATCalculationType::"Normal VAT");

        // [GIVEN] Three posted Sales Invoices, each posted with its own VAT Posting Setup. Three VAT Entries with Entry No. 901, 902, 903 are created. 902 has Amount = 0.
        PostedDocNo[1] := CreateAndPostSalesInvoice(VATPostingSetup[1]);
        PostedDocNo[2] := CreateAndPostSalesInvoice(VATPostingSetup[2]);
        PostedDocNo[3] := CreateAndPostSalesInvoice(VATPostingSetup[3]);

        // [WHEN] Run report Calc. And Post VAT Settlement with Post option set. Show VAT Entries option is set.
        VATSettlementDocNo := LibraryUtility.GenerateGUID();
        RunCalcAndPostVATSettlementReportWithInitialize(VATSettlementDocNo, VATPostingSetup, true);
        UpdatePeriodicSettlementVATEntry();

        // [THEN] Two VAT Entries with Entry No. 904, 905 and with Type "Settlement" were created.
        // [THEN] VAT Entries 901, 902, 903 were closed. Closed by Entry No. for 901 is 904, for 902 is 0, for 903 is 905.
        // [THEN] "Entry No." for Settlement VAT Entries in report results are 904, 0, 905.
        FindVATEntries(VATEntry, VATPostingSetup, PostedDocNo, GenPostingType::Sale);
        GetSettlementVATEntryNo(SettlementVATEntryNo[1], VATPostingSetup[1], VATSettlementDocNo);
        GetSettlementVATEntryNo(SettlementVATEntryNo[3], VATPostingSetup[3], VATSettlementDocNo);
        VATEntry[1].TestField(Closed, true);
        VATEntry[2].TestField(Closed, true);
        VATEntry[3].TestField(Closed, true);
        VerifyVATEntryClosedByEntryNo(VATEntry, SettlementVATEntryNo);
        VerifyVATEntryNoInVATSettlementReportResults(VATEntry, SettlementVATEntryNo);

        // tear down
        DeletePeriodicSettlementVATEntry(WorkDate());
        DeletePeriodicSettlementVATEntry(CalcDate('<1M>', WorkDate()));
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('CalcAndPostVATSettlementFileNameRequestPageHandler')]
    procedure RunCalcPostVATSttlmtWithPostNotSetOnSalesDocNormalVAT()
    var
        VATPostingSetup: array[3] of Record "VAT Posting Setup";
        VATEntry: array[3] of Record "VAT Entry";
        DummyVATEntry: Record "VAT Entry";
        PostedDocNo: array[3] of Code[20];
        VATSettlementDocNo: Code[20];
        SettlementVATEntryNo: array[3] of Integer;
    begin
        // [FEATURE] [Report] [Sales]
        // [SCENARIO 398537] Run Calc. and Post VAT Settlement report with Post option not set on three posted Sales Invoices with different VAT Posting Setup of "Normal VAT" calculation type.
        Initialize();
        UpdateLastSettlementDateOnGLSetup();

        // [GIVEN] Three VAT Posting Setup records with VAT Calculation Type = "Normal VAT". Second VAT Posting Setup has VAT % = 0.
        CreateThreeVATPostingSetup(VATPostingSetup, VATCalculationType::"Normal VAT");

        // [GIVEN] Three posted Sales Invoices, each posted with its own VAT Posting Setup. Three VAT Entries with Entry No. 901, 902, 903 are created. 902 has Amount = 0.
        PostedDocNo[1] := CreateAndPostSalesInvoice(VATPostingSetup[1]);
        PostedDocNo[2] := CreateAndPostSalesInvoice(VATPostingSetup[2]);
        PostedDocNo[3] := CreateAndPostSalesInvoice(VATPostingSetup[3]);

        // [WHEN] Run report Calc. And Post VAT Settlement with Post option not set. Show VAT Entries option is set.
        VATSettlementDocNo := LibraryUtility.GenerateGUID();
        RunCalcAndPostVATSettlementReportWithInitialize(VATSettlementDocNo, VATPostingSetup, false);

        // [THEN] "Entry No." for Settlement VAT Entries in report results are 904, 0, 905.
        FindVATEntries(VATEntry, VATPostingSetup, PostedDocNo, GenPostingType::Sale);
        DummyVATEntry.FindLast();
        SettlementVATEntryNo[1] := DummyVATEntry."Entry No." + 1;
        SettlementVATEntryNo[2] := 0;
        SettlementVATEntryNo[3] := DummyVATEntry."Entry No." + 2;
        VerifyVATEntryNoInVATSettlementReportResults(VATEntry, SettlementVATEntryNo);

        // tear down
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('CalcAndPostVATSettlementFileNameRequestPageHandler')]
    procedure RunCalcPostVATSttlmtWithPostSetOnPurchaseDocReverseChargeVAT()
    var
        VATPostingSetup: array[3] of Record "VAT Posting Setup";
        PurchaseVATEntry: array[3] of Record "VAT Entry";
        SaleVATEntry: array[3] of Record "VAT Entry";
        PostedDocNo: array[3] of Code[20];
        VATSettlementDocNo: Code[20];
        PurchaseSettlementVATEntryNo: array[3] of Integer;
        SaleSettlementVATEntryNo: array[3] of Integer;
    begin
        // [FEATURE] [Report] [Purchase]
        // [SCENARIO 398537] Run Calc. and Post VAT Settlement report with Post option set on three posted Purchase Invoices with different VAT Posting Setup of "Reverse Charge VAT" calculation type.
        // [SCENARIO 411666] Run Calc. and Post VAT Settlement report with Post option set on posted Purchase Invoice with VAT Posting Setup with VAT% = 0 and "Reverse Charge VAT" calculation type.
        Initialize();
        UpdateLastSettlementDateOnGLSetup();

        // [GIVEN] Three VAT Posting Setup records with VAT Calculation Type = "Reverse Charge VAT". Second VAT Posting Setup has VAT % = 0.
        CreateThreeVATPostingSetup(VATPostingSetup, VATCalculationType::"Reverse Charge VAT");
        UpdateReverseSalesVATNoSeries(VATPostingSetup[1]."VAT Bus. Posting Group");

        // [GIVEN] Three posted Purchase Invoices, each posted with its own VAT Posting Setup.
        // [GIVEN] Three VAT Entries with Entry No. 901, 903, 905 and Type Purchase are created. 903 has Amount = 0.
        // [GIVEN] Three VAT Entries with Entry No. 902, 904, 906 and Type Sale are created. 904 has Amount = 0.
        PostedDocNo[1] := CreateAndPostPurchaseInvoice(VATPostingSetup[1]);
        PostedDocNo[2] := CreateAndPostPurchaseInvoice(VATPostingSetup[2]);
        PostedDocNo[3] := CreateAndPostPurchaseInvoice(VATPostingSetup[3]);

        // [WHEN] Run report Calc. And Post VAT Settlement with Post option set. Show VAT Entries option is set.
        VATSettlementDocNo := LibraryUtility.GenerateGUID();
        RunCalcAndPostVATSettlementReportWithInitialize(VATSettlementDocNo, VATPostingSetup, true);
        UpdatePeriodicSettlementVATEntry();

        // [THEN] Two VAT Entries with Entry No. 907, 909 and with Type "Settlement" were created.
        // [THEN] VAT Entries (Purchase) 901, 903, 905 were closed. Closed by Entry No. for 901 is 907, for 903 is 0, for 905 is 909.
        FindVATEntries(PurchaseVATEntry, VATPostingSetup, PostedDocNo, GenPostingType::Purchase);
        GetNegativeAmountSettlementVATEntryNo(PurchaseSettlementVATEntryNo[1], VATPostingSetup[1], VATSettlementDocNo);
        GetNegativeAmountSettlementVATEntryNo(PurchaseSettlementVATEntryNo[3], VATPostingSetup[3], VATSettlementDocNo);
        PurchaseVATEntry[1].TestField(Closed, true);
        PurchaseVATEntry[2].TestField(Closed, true);
        PurchaseVATEntry[3].TestField(Closed, true);
        VerifyVATEntryClosedByEntryNo(PurchaseVATEntry, PurchaseSettlementVATEntryNo);

        // [THEN] Two VAT Entries with Entry No. 908, 910 and with Type "Settlement" were created.
        // [THEN] VAT Entries 902, 904, 906 (Sale) were closed. Closed by Entry No. for 902 is 908, for 904 is 0, for 906 is 910.
        FindVATEntries(SaleVATEntry, VATPostingSetup, PostedDocNo, GenPostingType::Sale);
        GetPositiveAmountSettlementVATEntryNo(SaleSettlementVATEntryNo[1], VATPostingSetup[1], VATSettlementDocNo);
        GetPositiveAmountSettlementVATEntryNo(SaleSettlementVATEntryNo[3], VATPostingSetup[3], VATSettlementDocNo);
        SaleVATEntry[1].TestField(Closed, true);
        SaleVATEntry[2].TestField(Closed, true);
        SaleVATEntry[3].TestField(Closed, true);
        VerifyVATEntryClosedByEntryNo(SaleVATEntry, SaleSettlementVATEntryNo);

        // [THEN] "Entry No." for Settlement VAT Entries in report results are 907 - 910.
        VerifyReverseChargeVATVATEntryNoInVATSettlementReportResults(PurchaseVATEntry, SaleVATEntry, PurchaseSettlementVATEntryNo, SaleSettlementVATEntryNo);

        // tear down
        DeletePeriodicSettlementVATEntry(WorkDate());
        DeletePeriodicSettlementVATEntry(CalcDate('<1M>', WorkDate()));
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('CalcAndPostVATSettlementFileNameRequestPageHandler')]
    procedure RunCalcPostVATSttlmtWithPostNotSetOnPurchaseDocReverseChargeVAT()
    var
        VATPostingSetup: array[3] of Record "VAT Posting Setup";
        PurchaseVATEntry: array[3] of Record "VAT Entry";
        SaleVATEntry: array[3] of Record "VAT Entry";
        DummyVATEntry: Record "VAT Entry";
        PostedDocNo: array[3] of Code[20];
        VATSettlementDocNo: Code[20];
        PurchaseSettlementVATEntryNo: array[3] of Integer;
        SaleSettlementVATEntryNo: array[3] of Integer;
    begin
        // [FEATURE] [Report] [Sales]
        // [SCENARIO 398537] Run Calc. and Post VAT Settlement report with Post option not set on three posted Purchase Invoices with different VAT Posting Setup of "Reverse Charge VAT" calculation type.
        Initialize();
        UpdateLastSettlementDateOnGLSetup();

        // [GIVEN] Three VAT Posting Setup records with VAT Calculation Type = "Reverse Charge VAT". Second VAT Posting Setup has VAT % = 0.
        CreateThreeVATPostingSetup(VATPostingSetup, VATCalculationType::"Reverse Charge VAT");
        UpdateReverseSalesVATNoSeries(VATPostingSetup[1]."VAT Bus. Posting Group");

        // [GIVEN] Three posted Purchase Invoices, each posted with its own VAT Posting Setup.
        // [GIVEN] Three VAT Entries with Entry No. 901, 903, 905 and Type Purchase are created. 903 has Amount = 0.
        // [GIVEN] Three VAT Entries with Entry No. 902, 904, 906 and Type Sale are created. 904 has Amount = 0.
        PostedDocNo[1] := CreateAndPostPurchaseInvoice(VATPostingSetup[1]);
        PostedDocNo[2] := CreateAndPostPurchaseInvoice(VATPostingSetup[2]);
        PostedDocNo[3] := CreateAndPostPurchaseInvoice(VATPostingSetup[3]);

        // [WHEN] Run report Calc. And Post VAT Settlement with Post option not set. Show VAT Entries option is set.
        VATSettlementDocNo := LibraryUtility.GenerateGUID();
        RunCalcAndPostVATSettlementReportWithInitialize(VATSettlementDocNo, VATPostingSetup, false);

        // [THEN] "Entry No." for Settlement VAT Entries in report results are 907 - 910.
        FindVATEntries(PurchaseVATEntry, VATPostingSetup, PostedDocNo, GenPostingType::Purchase);
        FindVATEntries(SaleVATEntry, VATPostingSetup, PostedDocNo, GenPostingType::Sale);
        DummyVATEntry.FindLast();
        PurchaseSettlementVATEntryNo[1] := DummyVATEntry."Entry No." + 1;
        SaleSettlementVATEntryNo[1] := DummyVATEntry."Entry No." + 2;
        PurchaseSettlementVATEntryNo[2] := 0;
        SaleSettlementVATEntryNo[2] := 0;
        PurchaseSettlementVATEntryNo[3] := DummyVATEntry."Entry No." + 3;
        SaleSettlementVATEntryNo[3] := DummyVATEntry."Entry No." + 4;
        VerifyReverseChargeVATVATEntryNoInVATSettlementReportResults(PurchaseVATEntry, SaleVATEntry, PurchaseSettlementVATEntryNo, SaleSettlementVATEntryNo);

        // tear down
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('CalcAndPostVATSettlementFileNameRequestPageHandler')]
    procedure RunCalcPostVATSttlmtWithPostSetOnSalesDocSalesTax()
    var
        VATPostingSetup: array[3] of Record "VAT Posting Setup";
        VATEntry: array[3] of Record "VAT Entry";
        PostedDocNo: array[3] of Code[20];
        VATSettlementDocNo: Code[20];
        TaxAreaCode: array[3] of Code[20];
        TaxGroupCode: array[3] of Code[20];
        SettlementVATEntryNo: array[3] of Integer;
    begin
        // [FEATURE] [Report] [Sales] [Sales Tax]
        // [SCENARIO 398537] Run Calc. and Post VAT Settlement report with Post option set on three posted Sales Invoices with different VAT Posting Setup of "Sales Tax" calculation type.
        Initialize();
        UpdateLastSettlementDateOnGLSetup();

        // [GIVEN] Three VAT Posting Setup records with VAT Calculation Type = "Sales Tax".
        CreateAndSetupThreeSalesTaxVATPostingSetup(VATPostingSetup, TaxAreaCode, TaxGroupCode);

        // [GIVEN] Three posted Sales Invoices, each posted with its own VAT Posting Setup. Three VAT Entries with Entry No. 901, 902, 903 and Amount = 0 are created.
        PostedDocNo[1] := CreateAndPostSalesInvoiceForSalesTax(VATPostingSetup[1], TaxAreaCode[1], TaxGroupCode[1]);
        PostedDocNo[2] := CreateAndPostSalesInvoiceForSalesTax(VATPostingSetup[2], TaxAreaCode[2], TaxGroupCode[2]);
        PostedDocNo[3] := CreateAndPostSalesInvoiceForSalesTax(VATPostingSetup[3], TaxAreaCode[3], TaxGroupCode[3]);

        // [WHEN] Run report Calc. And Post VAT Settlement with Post option set. Show VAT Entries option is set.
        VATSettlementDocNo := LibraryUtility.GenerateGUID();
        RunCalcAndPostVATSettlementReportWithInitialize(VATSettlementDocNo, VATPostingSetup, true);
        UpdatePeriodicSettlementVATEntry();

        // [THEN] Three VAT Entries with Entry No. 904, 905, 906 and with Type "Settlement" were created.
        // [THEN] VAT Entries 901, 902, 903 were closed. Closed by Entry No. for 901 is 904, for 902 is 905, for 903 is 906.
        // [THEN] "Entry No." for Settlement VAT Entries in report results are 904, 905, 906.
        FindVATEntries(VATEntry, VATPostingSetup, PostedDocNo, GenPostingType::Sale);
        GetSettlementVATEntriesNo(SettlementVATEntryNo, VATPostingSetup, VATSettlementDocNo);
        VerifyVATEntryClosedByEntryNo(VATEntry, SettlementVATEntryNo);
        VerifyVATEntryNoInVATSettlementReportResults(VATEntry, SettlementVATEntryNo);

        // tear down
        DeletePeriodicSettlementVATEntry(WorkDate());
        DeletePeriodicSettlementVATEntry(CalcDate('<1M>', WorkDate()));
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('CalcAndPostVATSettlementFileNameRequestPageHandler')]
    procedure RunCalcPostVATSttlmtWithPostNotSetOnSalesDocSalesTax()
    var
        VATPostingSetup: array[3] of Record "VAT Posting Setup";
        VATEntry: array[3] of Record "VAT Entry";
        DummyVATEntry: Record "VAT Entry";
        PostedDocNo: array[3] of Code[20];
        VATSettlementDocNo: Code[20];
        TaxAreaCode: array[3] of Code[20];
        TaxGroupCode: array[3] of Code[20];
        SettlementVATEntryNo: array[3] of Integer;
    begin
        // [FEATURE] [Report] [Sales] [Sales Tax]
        // [SCENARIO 398537] Run Calc. and Post VAT Settlement report with Post option not set on three posted Sales Invoices with different VAT Posting Setup of "Sales Tax" calculation type.
        Initialize();
        UpdateLastSettlementDateOnGLSetup();

        // [GIVEN] Three VAT Posting Setup records with VAT Calculation Type = "Sales Tax".
        CreateAndSetupThreeSalesTaxVATPostingSetup(VATPostingSetup, TaxAreaCode, TaxGroupCode);

        // [GIVEN] Three posted Sales Invoices, each posted with its own VAT Posting Setup. Three VAT Entries with Entry No. 901, 902, 903 and Amount = 0 are created.
        PostedDocNo[1] := CreateAndPostSalesInvoiceForSalesTax(VATPostingSetup[1], TaxAreaCode[1], TaxGroupCode[1]);
        PostedDocNo[2] := CreateAndPostSalesInvoiceForSalesTax(VATPostingSetup[2], TaxAreaCode[2], TaxGroupCode[2]);
        PostedDocNo[3] := CreateAndPostSalesInvoiceForSalesTax(VATPostingSetup[3], TaxAreaCode[3], TaxGroupCode[3]);

        // [WHEN] Run report Calc. And Post VAT Settlement with Post option not set. Show VAT Entries option is set.
        VATSettlementDocNo := LibraryUtility.GenerateGUID();
        RunCalcAndPostVATSettlementReportWithInitialize(VATSettlementDocNo, VATPostingSetup, false);

        // [THEN] "Entry No." for Settlement VAT Entries in report results are 904, 905, 906.
        FindVATEntries(VATEntry, VATPostingSetup, PostedDocNo, GenPostingType::Sale);
        DummyVATEntry.FindLast();
        SettlementVATEntryNo[1] := DummyVATEntry."Entry No." + 1;
        SettlementVATEntryNo[2] := DummyVATEntry."Entry No." + 2;
        SettlementVATEntryNo[3] := DummyVATEntry."Entry No." + 3;
        VerifyVATEntryNoInVATSettlementReportResults(VATEntry, SettlementVATEntryNo);

        // tear down
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('CalcAndPostVATSettlementFileNameRequestPageHandler')]
    procedure RunCalcPostVATSttlmtWithPostSetOnPurchaseDocSalesTaxUseTax()
    var
        VATPostingSetup: array[3] of Record "VAT Posting Setup";
        VATEntry: array[3] of Record "VAT Entry";
        PostedDocNo: array[3] of Code[20];
        VATSettlementDocNo: Code[20];
        TaxAreaCode: array[3] of Code[20];
        TaxGroupCode: array[3] of Code[20];
        SettlementVATEntryNo: array[3] of Integer;
    begin
        // [FEATURE] [Report] [Purchase] [Sales Tax]
        // [SCENARIO 398537] Run Calc. and Post VAT Settlement report with Post option set on three posted Purchase Invoices with different VAT Posting Setup of "Sales Tax" calculation type. "Use Tax" = true.
        Initialize();
        UpdateLastSettlementDateOnGLSetup();

        // [GIVEN] Three VAT Posting Setup records with VAT Calculation Type = "Sales Tax".
        CreateAndSetupThreeSalesTaxVATPostingSetup(VATPostingSetup, TaxAreaCode, TaxGroupCode);

        // [GIVEN] Three posted Purchase Invoices, each posted with its own VAT Posting Setup. Three VAT Entries with Entry No. 901, 902, 903 are created. 902 has Amount = 0.
        PostedDocNo[1] := CreateAndPostPurchaseInvoiceForSalesTax(VATPostingSetup[1], TaxAreaCode[1], TaxGroupCode[1], true);
        PostedDocNo[2] := CreateAndPostPurchaseInvoiceForSalesTax(VATPostingSetup[2], TaxAreaCode[2], TaxGroupCode[2], true);
        PostedDocNo[3] := CreateAndPostPurchaseInvoiceForSalesTax(VATPostingSetup[3], TaxAreaCode[3], TaxGroupCode[3], true);

        // [WHEN] Run report Calc. And Post VAT Settlement with Post option set. Show VAT Entries option is set.
        VATSettlementDocNo := LibraryUtility.GenerateGUID();
        RunCalcAndPostVATSettlementReportWithInitialize(VATSettlementDocNo, VATPostingSetup, true);
        UpdatePeriodicSettlementVATEntry();

        // [THEN] Three VAT Entries with Entry No. 904, 905, 906 and with Type "Settlement" were created.
        // [THEN] VAT Entries 901, 902, 903 were closed. Closed by Entry No. for each of these VAT Entries was set to 904, 905, 906 respectively.
        // [THEN] "Entry No." for Settlement VAT Entries in report results are 904, 905, 906.
        FindVATEntries(VATEntry, VATPostingSetup, PostedDocNo, GenPostingType::Purchase);
        GetSettlementVATEntriesNo(SettlementVATEntryNo, VATPostingSetup, VATSettlementDocNo);
        VerifyVATEntryClosedByEntryNo(VATEntry, SettlementVATEntryNo);
        VerifyVATEntryNoInVATSettlementReportResults(VATEntry, SettlementVATEntryNo);

        // tear down
        DeletePeriodicSettlementVATEntry(WorkDate());
        DeletePeriodicSettlementVATEntry(CalcDate('<1M>', WorkDate()));
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('CalcAndPostVATSettlementFileNameRequestPageHandler')]
    procedure RunCalcPostVATSttlmtWithPostNotSetOnPurchaseDocSalesTaxUseTax()
    var
        VATPostingSetup: array[3] of Record "VAT Posting Setup";
        VATEntry: array[3] of Record "VAT Entry";
        DummyVATEntry: Record "VAT Entry";
        PostedDocNo: array[3] of Code[20];
        VATSettlementDocNo: Code[20];
        TaxAreaCode: array[3] of Code[20];
        TaxGroupCode: array[3] of Code[20];
        SettlementVATEntryNo: array[3] of Integer;
    begin
        // [FEATURE] [Report] [Purchase] [Sales Tax]
        // [SCENARIO 398537] Run Calc. and Post VAT Settlement report with Post option not set on three posted Purchase Invoices with different VAT Posting Setup of "Sales Tax" calculation type. "Use Tax" = true.
        Initialize();
        UpdateLastSettlementDateOnGLSetup();

        // [GIVEN] Three VAT Posting Setup records with VAT Calculation Type = "Sales Tax".
        CreateAndSetupThreeSalesTaxVATPostingSetup(VATPostingSetup, TaxAreaCode, TaxGroupCode);

        // [GIVEN] Three posted Purchase Invoices, each posted with its own VAT Posting Setup. Three VAT Entries with Entry No. 901, 902, 903 are created.
        PostedDocNo[1] := CreateAndPostPurchaseInvoiceForSalesTax(VATPostingSetup[1], TaxAreaCode[1], TaxGroupCode[1], true);
        PostedDocNo[2] := CreateAndPostPurchaseInvoiceForSalesTax(VATPostingSetup[2], TaxAreaCode[2], TaxGroupCode[2], true);
        PostedDocNo[3] := CreateAndPostPurchaseInvoiceForSalesTax(VATPostingSetup[3], TaxAreaCode[3], TaxGroupCode[3], true);

        // [WHEN] Run report Calc. And Post VAT Settlement with Post option not set. Show VAT Entries option is set.
        VATSettlementDocNo := LibraryUtility.GenerateGUID();
        RunCalcAndPostVATSettlementReportWithInitialize(VATSettlementDocNo, VATPostingSetup, false);

        // [THEN] "Entry No." for Settlement VAT Entries in report results are 904, 905, 906.
        FindVATEntries(VATEntry, VATPostingSetup, PostedDocNo, GenPostingType::Purchase);
        DummyVATEntry.FindLast();
        SettlementVATEntryNo[1] := DummyVATEntry."Entry No." + 1;
        SettlementVATEntryNo[2] := DummyVATEntry."Entry No." + 2;
        SettlementVATEntryNo[3] := DummyVATEntry."Entry No." + 3;
        VerifyVATEntryNoInVATSettlementReportResults(VATEntry, SettlementVATEntryNo);

        // tear down
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('CalcAndPostVATSettlementFileNameRequestPageHandler')]
    procedure RunCalcPostVATSttlmtWithPostSetOnPurchaseDocSalesTax()
    var
        VATPostingSetup: array[3] of Record "VAT Posting Setup";
        VATEntry: array[3] of Record "VAT Entry";
        PostedDocNo: array[3] of Code[20];
        VATSettlementDocNo: Code[20];
        TaxAreaCode: array[3] of Code[20];
        TaxGroupCode: array[3] of Code[20];
        SettlementVATEntryNo: array[3] of Integer;
    begin
        // [FEATURE] [Report] [Purchase] [Sales Tax]
        // [SCENARIO 398537] Run Calc. and Post VAT Settlement report with Post option set on three posted Purchase Invoices with different VAT Posting Setup of "Sales Tax" calculation type. "Use Tax" = false.
        Initialize();
        UpdateLastSettlementDateOnGLSetup();

        // [GIVEN] Three VAT Posting Setup records with VAT Calculation Type = "Sales Tax".
        CreateAndSetupThreeSalesTaxVATPostingSetup(VATPostingSetup, TaxAreaCode, TaxGroupCode);

        // [GIVEN] Three posted Purchase Invoices, each posted with its own VAT Posting Setup. Three VAT Entries with Entry No. 901, 902, 903 are created. 902 has Amount = 0.
        PostedDocNo[1] := CreateAndPostPurchaseInvoiceForSalesTax(VATPostingSetup[1], TaxAreaCode[1], TaxGroupCode[1], false);
        PostedDocNo[2] := CreateAndPostPurchaseInvoiceForSalesTax(VATPostingSetup[2], TaxAreaCode[2], TaxGroupCode[2], false);
        PostedDocNo[3] := CreateAndPostPurchaseInvoiceForSalesTax(VATPostingSetup[3], TaxAreaCode[3], TaxGroupCode[3], false);

        // [WHEN] Run report Calc. And Post VAT Settlement with Post option set. Show VAT Entries option is set.
        VATSettlementDocNo := LibraryUtility.GenerateGUID();
        RunCalcAndPostVATSettlementReportWithInitialize(VATSettlementDocNo, VATPostingSetup, true);
        UpdatePeriodicSettlementVATEntry();

        // [THEN] Three VAT Entries with Entry No. 904, 905, 906 and with Type "Settlement" were created.
        // [THEN] VAT Entries 901, 902, 903 were closed. Closed by Entry No. for each of these VAT Entries was set to 904, 905, 906 respectively.
        // [THEN] "Entry No." for Settlement VAT Entries in report results are 904, 905, 906.
        FindVATEntries(VATEntry, VATPostingSetup, PostedDocNo, GenPostingType::Purchase);
        GetSettlementVATEntriesNo(SettlementVATEntryNo, VATPostingSetup, VATSettlementDocNo);
        VerifyVATEntryClosedByEntryNo(VATEntry, SettlementVATEntryNo);
        VerifyVATEntryNoInVATSettlementReportResults(VATEntry, SettlementVATEntryNo);

        // tear down
        DeletePeriodicSettlementVATEntry(WorkDate());
        DeletePeriodicSettlementVATEntry(CalcDate('<1M>', WorkDate()));
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('CalcAndPostVATSettlementFileNameRequestPageHandler')]
    procedure RunCalcPostVATSttlmtWithPostNotSetOnPurchaseDocSalesTax()
    var
        VATPostingSetup: array[3] of Record "VAT Posting Setup";
        VATEntry: array[3] of Record "VAT Entry";
        DummyVATEntry: Record "VAT Entry";
        PostedDocNo: array[3] of Code[20];
        VATSettlementDocNo: Code[20];
        TaxAreaCode: array[3] of Code[20];
        TaxGroupCode: array[3] of Code[20];
        SettlementVATEntryNo: array[3] of Integer;
    begin
        // [FEATURE] [Report] [Purchase] [Sales Tax]
        // [SCENARIO 398537] Run Calc. and Post VAT Settlement report with Post option not set on three posted Purchase Invoices with different VAT Posting Setup of "Sales Tax" calculation type. "Use Tax" = false.
        Initialize();
        UpdateLastSettlementDateOnGLSetup();

        // [GIVEN] Three VAT Posting Setup records with VAT Calculation Type = "Sales Tax".
        CreateAndSetupThreeSalesTaxVATPostingSetup(VATPostingSetup, TaxAreaCode, TaxGroupCode);

        // [GIVEN] Three posted Purchase Invoices, each posted with its own VAT Posting Setup. Three VAT Entries with Entry No. 901, 902, 903 are created. 902 has Amount = 0.
        PostedDocNo[1] := CreateAndPostPurchaseInvoiceForSalesTax(VATPostingSetup[1], TaxAreaCode[1], TaxGroupCode[1], false);
        PostedDocNo[2] := CreateAndPostPurchaseInvoiceForSalesTax(VATPostingSetup[2], TaxAreaCode[2], TaxGroupCode[2], false);
        PostedDocNo[3] := CreateAndPostPurchaseInvoiceForSalesTax(VATPostingSetup[3], TaxAreaCode[3], TaxGroupCode[3], false);

        // [WHEN] Run report Calc. And Post VAT Settlement with Post option not set. Show VAT Entries option is set.
        VATSettlementDocNo := LibraryUtility.GenerateGUID();
        RunCalcAndPostVATSettlementReportWithInitialize(VATSettlementDocNo, VATPostingSetup, false);

        // [THEN] "Entry No." for Settlement VAT Entries in report results are 904, 905, 906.
        FindVATEntries(VATEntry, VATPostingSetup, PostedDocNo, GenPostingType::Purchase);
        DummyVATEntry.FindLast();
        SettlementVATEntryNo[1] := DummyVATEntry."Entry No." + 1;
        SettlementVATEntryNo[2] := DummyVATEntry."Entry No." + 2;
        SettlementVATEntryNo[3] := DummyVATEntry."Entry No." + 3;
        VerifyVATEntryNoInVATSettlementReportResults(VATEntry, SettlementVATEntryNo);

        // tear down
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('CalcAndPostVATSettlementNoParamsRequestPageHandler')]
    procedure VATPeriodWhenRunCalcPostVATSttlmtWithPostSet()
    var
        VATPostingSetup: array[3] of Record "VAT Posting Setup";
        VATEntry: array[3] of Record "VAT Entry";
        PostedDocNo: array[3] of Code[20];
        VATSettlementDocNo: Code[20];
        SettlementVATEntryNo: array[3] of Integer;
        VATPeriod: Code[10];
    begin
        // [FEATURE] [Report] [Sales]
        // [SCENARIO 405806] VAT Period for Settlement VAT Entries when run Calc. and Post VAT Settlement report with Post option set on posted Sales Invoices.
        // [SCENARIO 411666] VAT Period for VAT Entries with Amount = 0 when run Calc. and Post VAT Settlement report with Post option set on posted Sales Invoices.
        Initialize();
        UpdateLastSettlementDateOnGLSetup();

        // [GIVEN] Three posted Sales Invoices. Three VAT Entries with Entry No. 901, 902, 903 are created. 902 has Amount = 0.
        CreateThreeVATPostingSetup(VATPostingSetup, VATCalculationType::"Normal VAT");
        PostedDocNo[1] := CreateAndPostSalesInvoice(VATPostingSetup[1]);
        PostedDocNo[2] := CreateAndPostSalesInvoice(VATPostingSetup[2]);
        PostedDocNo[3] := CreateAndPostSalesInvoice(VATPostingSetup[3]);

        // [WHEN] Run report Calc. And Post VAT Settlement with Post option set. Show VAT Entries option is set. Ending Date is 31.08.2021.
        VATSettlementDocNo := LibraryUtility.GenerateGUID();
        RunCalcAndPostVATSettlementReportWithInitialize(VATSettlementDocNo, VATPostingSetup, true);
        UpdatePeriodicSettlementVATEntry();

        // [THEN] Two VAT Entries with Entry No. 904, 905 and with Type "Settlement" and VAT Period = '2021/08' were created.
        VATPeriod := GetVATPeriod(CalcDate('<CM>', WorkDate()));
        GetSettlementVATEntryNo(SettlementVATEntryNo[1], VATPostingSetup[1], VATSettlementDocNo);
        GetSettlementVATEntryNo(SettlementVATEntryNo[3], VATPostingSetup[3], VATSettlementDocNo);
        VerifyVATEntryVATPeriod(SettlementVATEntryNo[1], VATPeriod);
        VerifyVATEntryVATPeriod(SettlementVATEntryNo[3], VATPeriod);

        // [THEN] VAT Period was set to '2021/08' for VAT Entries 901, 902, 903.
        FindVATEntries(VATEntry, VATPostingSetup, PostedDocNo, GenPostingType::Sale);
        VerifyVATEntryVATPeriod(VATEntry[1]."Entry No.", VATPeriod);
        VerifyVATEntryVATPeriod(VATEntry[2]."Entry No.", VATPeriod);
        VerifyVATEntryVATPeriod(VATEntry[3]."Entry No.", VATPeriod);

        // tear down
        DeletePeriodicSettlementVATEntry(WorkDate());
        DeletePeriodicSettlementVATEntry(CalcDate('<1M>', WorkDate()));
        LibraryVariableStorage.AssertEmpty();
    end;

    local procedure Initialize()
    begin
        LibraryVariableStorage.Clear();
        LibrarySetupStorage.Restore();
        // Lazy Setup.
        if isInitialized then
            exit;

        LibrarySetupStorage.Save(DATABASE::"General Ledger Setup");

        isInitialized := true;
        Commit();
    end;

    local procedure CreateAndPostGeneralJournalLine(Type: Enum "Gen. Journal Template Type"; AccountType: Enum "Gen. Journal Account Type"; AccountNo: Code[20]; Amount: Decimal; BalAccountNo: Code[20]; AppliesToDocType: Enum "Gen. Journal Document Type"; AppliesToDocNo: Code[20])
    var
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalLine: Record "Gen. Journal Line";
    begin
        CreateGeneralJournalBatch(GenJournalBatch, Type);
        LibraryERM.CreateGeneralJnlLine(
          GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name, GenJournalLine."Document Type"::Payment,
          AccountType, AccountNo, Amount);
        GenJournalLine.Validate("Bal. Account No.", BalAccountNo);
        GenJournalLine.Validate("Applies-to Doc. Type", AppliesToDocType);
        GenJournalLine.Validate("Applies-to Doc. No.", AppliesToDocNo);
        GenJournalLine.Modify(true);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
    end;

    local procedure CreateAndPostPurchaseDocument(var PurchaseLine: Record "Purchase Line"; DocumentType: Enum "Purchase Document Type"; VendorNo: Code[20]; AppliesToDocNo: Code[20]; ItemNo: Code[20]; Quantity: Decimal; DirectUnitCost: Decimal): Code[20]
    var
        PurchaseHeader: Record "Purchase Header";
    begin
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, DocumentType, VendorNo);
        PurchaseHeader.Validate("Applies-to Doc. Type", PurchaseHeader."Applies-to Doc. Type"::Invoice);
        PurchaseHeader.Validate("Applies-to Doc. No.", AppliesToDocNo);
        UpdateVendorCreditMemoNoOnPurchaseHeader(PurchaseHeader);
        CreatePurchaseLine(PurchaseHeader, PurchaseLine, PurchaseLine.Type::Item, ItemNo, Quantity, DirectUnitCost);
        exit(LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true));  // Post as Invoice
    end;

    local procedure CreateAndPostPurchaseInvoice(VATPostingSetup: Record "VAT Posting Setup") PostedDocNo: Code[20]
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        VendorNo: Code[20];
        ItemNo: Code[20];
    begin
        VendorNo := LibraryPurchase.CreateVendorWithVATBusPostingGroup(VATPostingSetup."VAT Bus. Posting Group");
        ItemNo := LibraryInventory.CreateItemNoWithVATProdPostingGroup(VATPostingSetup."VAT Prod. Posting Group");
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Invoice, VendorNo);
        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, ItemNo, LibraryRandom.RandDecInRange(10, 20, 2));
        PurchaseLine.Validate("Direct Unit Cost", LibraryRandom.RandDecInRange(100, 200, 2));
        PurchaseLine.Modify(true);
        PostedDocNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, false, true);
    end;

    local procedure CreateAndPostPurchaseInvoiceForSalesTax(VATPostingSetup: Record "VAT Posting Setup"; TaxAreaCode: Code[20]; TaxGroupCode: Code[20]; UseTax: Boolean) PostedDocNo: Code[20]
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        Vendor: Record Vendor;
        Item: Record Item;
    begin
        LibraryPurchase.CreateVendor(Vendor);
        Vendor.Validate("VAT Bus. Posting Group", VATPostingSetup."VAT Bus. Posting Group");
        Vendor.Validate("Tax Area Code", TaxAreaCode);
        Vendor.Validate("Tax Liable", false);
        Vendor.Validate("Prices Including VAT", false);
        Vendor.Modify(true);

        LibraryInventory.CreateItem(Item);
        Item.Validate("VAT Prod. Posting Group", VATPostingSetup."VAT Prod. Posting Group");
        Item.Validate("Tax Group Code", TaxGroupCode);
        Item.Modify(true);

        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Invoice, Vendor."No.");
        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, Item."No.", LibraryRandom.RandDecInRange(10, 20, 2));
        PurchaseLine.Validate("Direct Unit Cost", LibraryRandom.RandDecInRange(100, 200, 2));
        PurchaseLine.Validate("Use Tax", UseTax);
        PurchaseLine.Modify(true);
        PostedDocNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, false, true);
    end;

    local procedure CreateAndPostSalesDocument(var SalesLine: Record "Sales Line"; DocumentType: Enum "Sales Document Type"; CustomerNo: Code[20]; AppliesToDocNo: Code[20]; ItemNo: Code[20]; Quantity: Decimal; UnitPrice: Decimal): Code[20]
    var
        SalesHeader: Record "Sales Header";
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, DocumentType, CustomerNo);
        SalesHeader.Validate("Applies-to Doc. Type", SalesHeader."Applies-to Doc. Type"::Invoice);
        SalesHeader.Validate("Applies-to Doc. No.", AppliesToDocNo);
        SalesHeader.Modify(true);
        CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, ItemNo, Quantity, UnitPrice);
        exit(LibrarySales.PostSalesDocument(SalesHeader, true, true));  // Post as Invoice
    end;

    local procedure CreateAndPostSalesInvoice(VATPostingSetup: Record "VAT Posting Setup") PostedDocNo: Code[20]
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        CustomerNo: Code[20];
        ItemNo: Code[20];
    begin
        CustomerNo := LibrarySales.CreateCustomerWithVATBusPostingGroup(VATPostingSetup."VAT Bus. Posting Group");
        ItemNo := LibraryInventory.CreateItemNoWithVATProdPostingGroup(VATPostingSetup."VAT Prod. Posting Group");
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Invoice, CustomerNo);
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, ItemNo, LibraryRandom.RandDecInRange(10, 20, 2));
        SalesLine.Validate("Unit Price", LibraryRandom.RandDecInRange(100, 200, 2));
        SalesLine.Modify(true);
        PostedDocNo := LibrarySales.PostSalesDocument(SalesHeader, false, true);
    end;

    local procedure CreateAndPostSalesInvoiceForSalesTax(VATPostingSetup: Record "VAT Posting Setup"; TaxAreaCode: Code[20]; TaxGroupCode: Code[20]) PostedDocNo: Code[20]
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        Customer: Record Customer;
        Item: Record Item;
    begin
        LibrarySales.CreateCustomer(Customer);
        Customer.Validate("VAT Bus. Posting Group", VATPostingSetup."VAT Bus. Posting Group");
        Customer.Validate("Tax Area Code", TaxAreaCode);
        Customer.Validate("Tax Liable", false);
        Customer.Validate("Prices Including VAT", false);
        Customer.Modify(true);

        LibraryInventory.CreateItem(Item);
        Item.Validate("VAT Prod. Posting Group", VATPostingSetup."VAT Prod. Posting Group");
        Item.Validate("Tax Group Code", TaxGroupCode);
        Item.Modify(true);

        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Invoice, Customer."No.");
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, Item."No.", LibraryRandom.RandDecInRange(10, 20, 2));
        SalesLine.Validate("Unit Price", LibraryRandom.RandDecInRange(100, 200, 2));
        SalesLine.Modify(true);
        PostedDocNo := LibrarySales.PostSalesDocument(SalesHeader, false, true);
    end;

    local procedure CreateCustomer(VATBusPostingGroup: Code[20]): Code[20]
    var
        Customer: Record Customer;
        CompanyInformation: Record "Company Information";
    begin
        CompanyInformation.Get();
        LibrarySales.CreateCustomer(Customer);
        Customer.Validate("Country/Region Code", CompanyInformation."Country/Region Code");
        Customer.Validate("VAT Bus. Posting Group", VATBusPostingGroup);
        Customer.Modify(true);
        exit(Customer."No.");
    end;

    local procedure CreateGeneralJournalBatch(var GenJournalBatch: Record "Gen. Journal Batch"; Type: Enum "Gen. Journal Template Type")
    var
        GenJournalTemplate: Record "Gen. Journal Template";
    begin
        GenJournalTemplate.SetRange(Type, Type);
        LibraryERM.FindGenJournalTemplate(GenJournalTemplate);
        LibraryERM.CreateGenJournalBatch(GenJournalBatch, GenJournalTemplate.Name);
    end;

    local procedure CreateSimpleGLAccount(): Code[20]
    var
        GLAccount: Record "G/L Account";
    begin
        LibraryERM.CreateGLAccount(GLAccount);
        exit(GLAccount."No.");
    end;

    local procedure CreateGLAccount(VATPostingSetup: Record "VAT Posting Setup"; GenPostingType: Enum "General Posting Type"): Code[20]
    var
        GLAccount: Record "G/L Account";
        GeneralPostingSetup: Record "General Posting Setup";
    begin
        LibraryERM.FindGeneralPostingSetup(GeneralPostingSetup);
        LibraryERM.CreateGLAccount(GLAccount);
        GLAccount.Validate("Gen. Bus. Posting Group", GeneralPostingSetup."Gen. Bus. Posting Group");
        GLAccount.Validate("Gen. Prod. Posting Group", GeneralPostingSetup."Gen. Prod. Posting Group");
        GLAccount.Validate("VAT Prod. Posting Group", VATPostingSetup."VAT Prod. Posting Group");
        GLAccount.Validate("VAT Bus. Posting Group", VATPostingSetup."VAT Bus. Posting Group");
        GLAccount.Validate("Gen. Posting Type", GenPostingType);
        GLAccount.Modify(true);
        exit(GLAccount."No.");
    end;

    local procedure CreateHundredPctNDReverseChargeVATPostingSetup(var VATPostingSetup: Record "VAT Posting Setup")
    var
        VATProductPostingGroup: Record "VAT Product Posting Group";
        VATIdentifier: Record "VAT Identifier";
    begin
        LibraryERM.FindVATPostingSetup(VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT");
        LibraryERM.CreateVATProductPostingGroup(VATProductPostingGroup);
        LibraryERM.CreateVATPostingSetup(VATPostingSetup, VATPostingSetup."VAT Bus. Posting Group", VATProductPostingGroup.Code);
        LibraryERM.CreateVATIdentifier(VATIdentifier);
        VATPostingSetup.Validate("VAT Identifier", VATIdentifier.Code);
        VATPostingSetup.Validate("VAT Calculation Type", VATPostingSetup."VAT Calculation Type"::"Reverse Charge VAT");
        VATPostingSetup.Validate("VAT %", LibraryRandom.RandInt(10));
        VATPostingSetup.Validate("Deductible %", 0);
        VATPostingSetup.Validate("Purchase VAT Account", CreateSimpleGLAccount());
        VATPostingSetup.Validate("Reverse Chrg. VAT Acc.", CreateSimpleGLAccount());
        VATPostingSetup.Validate("Sales VAT Account", CreateSimpleGLAccount());
        VATPostingSetup.Validate("Nondeductible VAT Account", CreateSimpleGLAccount());
        VATPostingSetup.Modify(true);
    end;

    local procedure CreateItem(VATProdPostingGroup: Code[20]): Code[20]
    var
        Item: Record Item;
    begin
        LibraryInventory.CreateItem(Item);
        Item.Validate("VAT Prod. Posting Group", VATProdPostingGroup);
        Item.Modify(true);
        exit(Item."No.");
    end;

    local procedure CreatePaymentLine(var GenJournalLine: Record "Gen. Journal Line"; AccType: Enum "Gen. Journal Account Type"; No: Code[20]; Amount: Decimal; DocNo: Code[20])
    begin
        LibraryJournals.CreateGenJournalLineWithBatch(
          GenJournalLine, GenJournalLine."Document Type"::Payment, AccType, No, Amount);
        GenJournalLine."Applies-to Doc. Type" := GenJournalLine."Applies-to Doc. Type"::Invoice;
        GenJournalLine."Applies-to Doc. No." := DocNo;
        GenJournalLine.Modify();
    end;

    local procedure CreatePostPurchInvoiceWithVATSetup(var PurchLine: Record "Purchase Line"; VATPostingSetup: Record "VAT Posting Setup"): Code[20]
    var
        GLAccount: Record "G/L Account";
        PurchHeader: Record "Purchase Header";
        GLAccNo: Code[20];
    begin
        LibraryPurchase.CreatePurchHeader(
          PurchHeader, PurchHeader."Document Type"::Invoice, CreateVendor(VATPostingSetup."VAT Bus. Posting Group"));
        GLAccNo :=
          CreateGLAccount(VATPostingSetup, GLAccount."Gen. Posting Type"::Purchase);
        CreatePurchaseLine(
          PurchHeader, PurchLine, PurchLine.Type::"G/L Account", GLAccNo,
          LibraryRandom.RandInt(10), LibraryRandom.RandDec(100, 2));
        exit(LibraryPurchase.PostPurchaseDocument(PurchHeader, true, true));
    end;

    local procedure CreatePurchaseInvoiceWithMultipleLines(var PurchaseHeader: Record "Purchase Header"; VATBusPostingGroup: Code[20]; No: Code[20]; No2: Code[20])
    var
        PurchaseLine: Record "Purchase Line";
    begin
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Invoice, CreateVendor(VATBusPostingGroup));
        UpdateVendorCreditMemoNoOnPurchaseHeader(PurchaseHeader);
        CreatePurchaseLine(
          PurchaseHeader, PurchaseLine, PurchaseLine.Type::"G/L Account", No, LibraryRandom.RandDec(10, 2),
          LibraryRandom.RandDec(100, 2));  // Use Random value for Quantity and Direct Unit Cost
        CreatePurchaseLine(
          PurchaseHeader, PurchaseLine, PurchaseLine.Type::"G/L Account", No2, LibraryRandom.RandDec(10, 2),
          LibraryRandom.RandDec(100, 2));  // Use Random value for Quantity and Direct Unit Cost
    end;

    local procedure CreatePurchaseLine(var PurchaseHeader: Record "Purchase Header"; var PurchaseLine: Record "Purchase Line"; Type: Enum "Purchase Line Type"; No: Code[20]; Quantity: Decimal; DirectUnitCost: Decimal)
    begin
        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, Type, No, Quantity);
        PurchaseLine.Validate("Direct Unit Cost", DirectUnitCost);
        PurchaseLine.Modify(true);
    end;

    local procedure CreateSalesInvoiceWithMultipleLines(var SalesHeader: Record "Sales Header"; VATBusPostingGroup: Code[20]; No: Code[20]; No2: Code[20])
    var
        SalesLine: Record "Sales Line";
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Invoice, CreateCustomer(VATBusPostingGroup));
        CreateSalesLine(
          SalesLine, SalesHeader, SalesLine.Type::"G/L Account", No, LibraryRandom.RandDec(10, 2), LibraryRandom.RandDec(100, 2));  // Use Random value for Quantity and Unit Price
        CreateSalesLine(
          SalesLine, SalesHeader, SalesLine.Type::"G/L Account", No2, LibraryRandom.RandDec(10, 2),
          LibraryRandom.RandDec(100, 2));  // Use Random value for Quantity and Unit Price
    end;

    local procedure CreateSalesLine(var SalesLine: Record "Sales Line"; SalesHeader: Record "Sales Header"; Type: Enum "Sales Line Type"; No: Code[20]; Quantity: Decimal; UnitPrice: Decimal)
    begin
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, Type, No, Quantity);
        SalesLine.Validate("Unit Price", UnitPrice);
        SalesLine.Modify(true);
    end;

    local procedure CreateServiceInvoiceWithMultipleLines(var ServiceHeader: Record "Service Header"; VATBusPostingGroup: Code[20]; No: Code[20]; No2: Code[20])
    var
        ServiceLine: Record "Service Line";
    begin
        LibraryService.CreateServiceHeader(ServiceHeader, ServiceHeader."Document Type"::Invoice, CreateCustomer(VATBusPostingGroup));
        CreateServiceLine(ServiceLine, ServiceHeader, No);
        CreateServiceLine(ServiceLine, ServiceHeader, No2);
    end;

    local procedure CreateServiceLine(var ServiceLine: Record "Service Line"; var ServiceHeader: Record "Service Header"; No: Code[20])
    begin
        LibraryService.CreateServiceLine(ServiceLine, ServiceHeader, ServiceLine.Type::"G/L Account", No);
        ServiceLine.Validate(Quantity, LibraryRandom.RandDec(10, 2));  // Use Random value for Quantity
        ServiceLine.Validate("Unit Price", LibraryRandom.RandDec(100, 2));  // Use Random value for Unit Price
        ServiceLine.Modify(true);
    end;

    local procedure CreateVendor(VATBusPostingGroup: Code[20]): Code[20]
    var
        CompanyInformation: Record "Company Information";
        Vendor: Record Vendor;
    begin
        CompanyInformation.Get();
        LibraryPurchase.CreateVendor(Vendor);
        Vendor.Validate("Country/Region Code", CompanyInformation."Country/Region Code");
        Vendor.Validate("VAT Bus. Posting Group", VATBusPostingGroup);
        Vendor.Modify(true);
        exit(Vendor."No.");
    end;

    local procedure CreateThreeVATPostingSetup(var VATPostingSetup: array[3] of Record "VAT Posting Setup"; VATCalculationType: Enum "Tax Calculation Type")
    var
        i: Integer;
    begin
        LibraryERM.CreateVATPostingSetupWithAccounts(VATPostingSetup[1], VATCalculationType, LibraryRandom.RandDecInRange(10, 20, 2));
        LibraryERM.CreateVATPostingSetupWithAccounts(VATPostingSetup[2], VATCalculationType, 0);
        LibraryERM.CreateVATPostingSetupWithAccounts(VATPostingSetup[3], VATCalculationType, LibraryRandom.RandDecInRange(10, 20, 2));
        for i := 1 to ArrayLen(VATPostingSetup) do begin
            VATPostingSetup[i].Validate("Reverse Chrg. VAT Acc.", LibraryERM.CreateGLAccountNo());
            VATPostingSetup[i].Modify(true);
        end;
    end;

    local procedure CreateAndSetupThreeSalesTaxVATPostingSetup(var VATPostingSetup: array[3] of Record "VAT Posting Setup"; var TaxAreaCode: array[3] of Code[20]; var TaxGroupCode: array[3] of Code[20])
    var
        VATBusinessPostingGroup: Record "VAT Business Posting Group";
        VATProductPostingGroup: Record "VAT Product Posting Group";
        TaxGroup: Record "Tax Group";
        TaxJurisdiction: Record "Tax Jurisdiction";
        TaxArea: Record "Tax Area";
        TaxAreaLine: Record "Tax Area Line";
        TaxDetail: Record "Tax Detail";
        i: Integer;
    begin
        for i := 1 to ArrayLen(VATPostingSetup) do begin
            LibraryERM.CreateVATBusinessPostingGroup(VATBusinessPostingGroup);
            LibraryERM.CreateVATProductPostingGroup(VATProductPostingGroup);
            LibraryERM.CreateVATPostingSetup(VATPostingSetup[i], VATBusinessPostingGroup.Code, VATProductPostingGroup.Code);
            VATPostingSetup[i].Validate("VAT Calculation Type", VATPostingSetup[i]."VAT Calculation Type"::"Sales Tax");
            VATPostingSetup[i].Modify(true);

            LibraryERM.CreateTaxGroup(TaxGroup);
            CreateTaxJurisdiction(TaxJurisdiction);
            LibraryERM.CreateTaxArea(TaxArea);
            LibraryERM.CreateTaxAreaLine(TaxAreaLine, TaxArea.Code, TaxJurisdiction.Code);
            LibraryERM.CreateTaxDetail(TaxDetail, TaxJurisdiction.Code, TaxGroup.Code, TaxDetail."Tax Type"::"Sales Tax", WorkDate());
            TaxDetail.Validate("Maximum Amount/Qty.", 9999999);
            TaxDetail.Validate("Tax Below Maximum", LibraryRandom.RandDecInRange(10, 20, 2));
            TaxDetail.Modify(true);

            TaxAreaCode[i] := TaxArea.Code;
            TaxGroupCode[i] := TaxGroup.Code;
        end;
    end;

    local procedure CreateTaxJurisdiction(var TaxJurisdiction: Record "Tax Jurisdiction")
    var
        GLAccount: Record "G/L Account";
    begin
        LibraryERM.CreateGLAccount(GLAccount);
        GLAccount."Income/Balance" := GLAccount."Income/Balance"::"Balance Sheet";
        GLAccount.Modify();
        LibraryERM.CreateTaxJurisdiction(TaxJurisdiction);
        TaxJurisdiction.Validate("Tax Account (Sales)", GLAccount."No.");
        TaxJurisdiction.Validate("Tax Account (Purchases)", GLAccount."No.");
        TaxJurisdiction.Validate("Reverse Charge (Purchases)", GLAccount."No.");
        TaxJurisdiction.Modify(true);
    end;

    local procedure DeletePeriodicSettlementVATEntry(PeriodDate: Date)
    var
#if not CLEAN27
        PeriodicSettlementVATEntry: Record "Periodic Settlement VAT Entry";
#else
        PeriodicSettlementVATEntry: Record "Periodic VAT Settlement Entry";
#endif
    begin
        FindPeriodicSettlementVATEntry(PeriodicSettlementVATEntry, PeriodDate);
        PeriodicSettlementVATEntry.Delete(true);
    end;

#if not CLEAN27
    local procedure FindPeriodicSettlementVATEntry(var PeriodicSettlementVATEntry: Record "Periodic Settlement VAT Entry"; PeriodDate: Date)
    begin
        PeriodicSettlementVATEntry.SetRange(
          "VAT Period", Format(Date2DMY(PeriodDate, 3)) + '/' + ConvertStr(Format(Date2DMY(PeriodDate, 2), 2), ' ', '0'));  // Value Zero required for VAT Period.
        PeriodicSettlementVATEntry.FindFirst();
    end;
#else
    local procedure FindPeriodicSettlementVATEntry(var PeriodicSettlementVATEntry: Record "Periodic VAT Settlement Entry"; PeriodDate: Date)
    begin
        PeriodicSettlementVATEntry.SetRange(
          "VAT Period", Format(Date2DMY(PeriodDate, 3)) + '/' + ConvertStr(Format(Date2DMY(PeriodDate, 2), 2), ' ', '0'));  // Value Zero required for VAT Period.
        PeriodicSettlementVATEntry.FindFirst();
    end;
#endif

    local procedure FindVATEntries(var VATEntry: array[3] of Record "VAT Entry"; VATPostingSetup: array[3] of Record "VAT Posting Setup"; DocumentNo: array[3] of Code[20]; GenPostingType: Enum "General Posting Type")
    var
        i: Integer;
    begin
        for i := 1 to ArrayLen(VATEntry) do begin
            VATEntry[i].SetRange("VAT Bus. Posting Group", VATPostingSetup[i]."VAT Bus. Posting Group");
            VATEntry[i].SetRange("VAT Prod. Posting Group", VATPostingSetup[i]."VAT Prod. Posting Group");
            VATEntry[i].SetRange("Document No.", DocumentNo[i]);
            VATEntry[i].SetRange(Type, GenPostingType);
            VATEntry[i].FindFirst();
        end;
    end;

    local procedure GetSettlementVATEntryNo(var SettlementVATEntryNo: Integer; VATPostingSetup: Record "VAT Posting Setup"; DocumentNo: Code[20])
    var
        VATEntry: Record "VAT Entry";
    begin
        VATEntry.SetRange("VAT Bus. Posting Group", VATPostingSetup."VAT Bus. Posting Group");
        VATEntry.SetRange("VAT Prod. Posting Group", VATPostingSetup."VAT Prod. Posting Group");
        VATEntry.SetRange("Document No.", DocumentNo);
        VATEntry.SetRange(Type, VATEntry.Type::Settlement);
        VATEntry.FindFirst();
        SettlementVATEntryNo := VATEntry."Entry No.";
    end;

    local procedure GetSettlementVATEntriesNo(var SettlementVATEntryNo: array[3] of Integer; VATPostingSetup: array[3] of Record "VAT Posting Setup"; DocumentNo: Code[20])
    var
        i: Integer;
    begin
        for i := 1 to ArrayLen(SettlementVATEntryNo) do
            GetSettlementVATEntryNo(SettlementVATEntryNo[i], VATPostingSetup[i], DocumentNo);
    end;

    local procedure GetPositiveAmountSettlementVATEntryNo(var SettlementVATEntryNo: Integer; VATPostingSetup: Record "VAT Posting Setup"; DocumentNo: Code[20])
    var
        VATEntry: Record "VAT Entry";
    begin
        VATEntry.SetRange("VAT Bus. Posting Group", VATPostingSetup."VAT Bus. Posting Group");
        VATEntry.SetRange("VAT Prod. Posting Group", VATPostingSetup."VAT Prod. Posting Group");
        VATEntry.SetRange("Document No.", DocumentNo);
        VATEntry.SetRange(Type, VATEntry.Type::Settlement);
        VATEntry.SetFilter(Amount, '>%1', 0);
        VATEntry.FindFirst();
        SettlementVATEntryNo := VATEntry."Entry No.";
    end;

    local procedure GetNegativeAmountSettlementVATEntryNo(var SettlementVATEntryNo: Integer; VATPostingSetup: Record "VAT Posting Setup"; DocumentNo: Code[20])
    var
        VATEntry: Record "VAT Entry";
    begin
        VATEntry.SetRange("VAT Bus. Posting Group", VATPostingSetup."VAT Bus. Posting Group");
        VATEntry.SetRange("VAT Prod. Posting Group", VATPostingSetup."VAT Prod. Posting Group");
        VATEntry.SetRange("Document No.", DocumentNo);
        VATEntry.SetRange(Type, VATEntry.Type::Settlement);
        VATEntry.SetFilter(Amount, '<%1', 0);
        VATEntry.FindFirst();
        SettlementVATEntryNo := VATEntry."Entry No.";
    end;

    local procedure GetStartingDate(): Date
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
    begin
        GeneralLedgerSetup.Get();
        exit(CalcDate('<1D>', GeneralLedgerSetup."Last Settlement Date"));  // 1D is required as Starting date for Calc. and Post VAT Settlement report should be the next Day of Last Settlement Date.
    end;

    local procedure GetVATPeriod(EndingDate: Date): Code[10]
    var
        Year: Text[4];
        Month: Text[2];
    begin
        Year := Format(Date2DMY(EndingDate, 3));
        Month := ConvertStr(Format(Date2DMY(EndingDate, 2), 2), ' ', '0');
        exit(StrSubstNo('%1/%2', Year, Month));
    end;

    local procedure RunCalcAndPostVATSettlementReport()
    var
        GLAccount: Record "G/L Account";
    begin
        LibraryERM.CreateGLAccount(GLAccount);
        LibraryVariableStorage.Enqueue(GetStartingDate());
        LibraryVariableStorage.Enqueue(GLAccount."No.");
        Commit();  // Commit required to run the report
        REPORT.Run(REPORT::"Calc. and Post VAT Settlement");
    end;

    local procedure RunCalcAndPostVATSettlementReportWithInitialize(DocumentNo: Code[20]; VATPostingSetup: array[3] of Record "VAT Posting Setup"; PostSettlement: Boolean)
    var
        FilterVATPostingSetup: Record "VAT Posting Setup";
        CalcAndPostVATSettlement: Report "Calc. and Post VAT Settlement";
        GLAccountNo: Code[20];
    begin
        GLAccountNo := LibraryERM.CreateGLAccountNo();
        CalcAndPostVATSettlement.InitializeRequest(WorkDate(), WorkDate(), WorkDate(), DocumentNo, GLAccountNo, GLAccountNo, GLAccountNo, true, PostSettlement);
        FilterVATPostingSetup.SetFilter("VAT Bus. Posting Group", '%1|%2|%3', VATPostingSetup[1]."VAT Bus. Posting Group", VATPostingSetup[2]."VAT Bus. Posting Group", VATPostingSetup[3]."VAT Bus. Posting Group");
        CalcAndPostVATSettlement.SetTableView(FilterVATPostingSetup);
        Commit();
        CalcAndPostVATSettlement.Run();
    end;

    local procedure UpdateGeneralLedgerAndVATPostingSetups(GeneralLedgerSetup: Record "General Ledger Setup"; VATPostingSetup: Record "VAT Posting Setup")
    begin
        UpdateVATPostingSetup(
          VATPostingSetup."VAT Bus. Posting Group",
          VATPostingSetup."VAT Prod. Posting Group", VATPostingSetup."EU Service", VATPostingSetup."Unrealized VAT Type");
        UpdateGeneralLedgerSetup(GeneralLedgerSetup."Unrealized VAT", GeneralLedgerSetup."Last Settlement Date");
    end;

    local procedure UpdateGeneralLedgerSetup(UnrealizedVAT: Boolean; LastSettlementDate: Date)
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
    begin
        GeneralLedgerSetup.Get();
        GeneralLedgerSetup.Validate("Unrealized VAT", UnrealizedVAT);
        GeneralLedgerSetup.Validate("Last Settlement Date", LastSettlementDate);
        GeneralLedgerSetup.Modify(true);
    end;

    local procedure UpdateLastSettlementDateOnGLSetup()
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
    begin
        GeneralLedgerSetup.Get();
        GeneralLedgerSetup.Validate("Last Settlement Date", CalcDate('<-CM - 1D>', WorkDate()));
        GeneralLedgerSetup.Modify(true);
    end;

    local procedure UpdatePeriodicSettlementVATEntry()
    var
#if not CLEAN27
        PeriodicSettlementVATEntry: Record "Periodic Settlement VAT Entry";
#else
        PeriodicSettlementVATEntry: Record "Periodic VAT Settlement Entry";
#endif
    begin
        FindPeriodicSettlementVATEntry(PeriodicSettlementVATEntry, WorkDate());
        PeriodicSettlementVATEntry.Validate("VAT Period Closed", false);
        PeriodicSettlementVATEntry.Modify(true);
    end;

    local procedure UpdateVATPostingSetup(VATBusPostingGroup: Code[20]; VATProdPostingGroup: Code[20]; EUService: Boolean; UnrealizedVATType: Option)
    var
        GLAccount: Record "G/L Account";
        VATPostingSetup: Record "VAT Posting Setup";
    begin
        VATPostingSetup.Get(VATBusPostingGroup, VATProdPostingGroup);
        LibraryERM.CreateGLAccount(GLAccount);
        VATPostingSetup.Validate("Sales VAT Unreal. Account", GLAccount."No.");
        VATPostingSetup.Validate("Purch. VAT Unreal. Account", GLAccount."No.");
        VATPostingSetup.Validate("EU Service", EUService);
        VATPostingSetup.Validate("Unrealized VAT Type", UnrealizedVATType);
        VATPostingSetup.Modify(true);
    end;

    local procedure UpdateVATPostingSetups(VATPostingSetup: Record "VAT Posting Setup"; VATPostingSetup2: Record "VAT Posting Setup")
    begin
        UpdateVATPostingSetup(
          VATPostingSetup."VAT Bus. Posting Group",
          VATPostingSetup."VAT Prod. Posting Group", VATPostingSetup."EU Service", VATPostingSetup."Unrealized VAT Type");
        UpdateVATPostingSetup(
          VATPostingSetup2."VAT Bus. Posting Group",
          VATPostingSetup2."VAT Prod. Posting Group", VATPostingSetup2."EU Service", VATPostingSetup2."Unrealized VAT Type");
    end;

    local procedure UpdateVATProductPostingGroupOnPurchaseLine(DocumentNo: Code[20]; No: Code[20]; VATProdPostingGroup: Code[20])
    var
        PurchaseLine: Record "Purchase Line";
    begin
        PurchaseLine.SetRange("Document Type", PurchaseLine."Document Type"::Invoice);
        PurchaseLine.SetRange("Document No.", DocumentNo);
        PurchaseLine.SetRange("No.", No);
        PurchaseLine.FindFirst();
        PurchaseLine.Validate("VAT Prod. Posting Group", VATProdPostingGroup);
        PurchaseLine.Modify(true);
    end;

    local procedure UpdateVATProductPostingGroupOnSalesLine(DocumentNo: Code[20]; No: Code[20]; VATProdPostingGroup: Code[20])
    var
        SalesLine: Record "Sales Line";
    begin
        SalesLine.SetRange("Document Type", SalesLine."Document Type"::Invoice);
        SalesLine.SetRange("Document No.", DocumentNo);
        SalesLine.SetRange("No.", No);
        SalesLine.FindFirst();
        SalesLine.Validate("VAT Prod. Posting Group", VATProdPostingGroup);
        SalesLine.Modify(true);
    end;

    local procedure UpdateVATProductPostingGroupOnServiceLine(DocumentNo: Code[20]; No: Code[20]; VATProdPostingGroup: Code[20])
    var
        ServiceLine: Record "Service Line";
    begin
        ServiceLine.SetRange("Document Type", ServiceLine."Document Type"::Invoice);
        ServiceLine.SetRange("Document No.", DocumentNo);
        ServiceLine.SetRange("No.", No);
        ServiceLine.FindFirst();
        ServiceLine.Validate("VAT Prod. Posting Group", VATProdPostingGroup);
        ServiceLine.Modify(true);
    end;

    local procedure UpdateVendorCreditMemoNoOnPurchaseHeader(var PurchaseHeader: Record "Purchase Header")
    begin
        PurchaseHeader.Validate("Vendor Cr. Memo No.", PurchaseHeader."Buy-from Vendor No.");
        PurchaseHeader.Modify(true);
    end;

    local procedure UpdateReverseSalesVATNoSeries(VATBusPostingGroupCode: Code[20])
    var
        VATBusinessPostingGroup: Record "VAT Business Posting Group";
        NoSeries: Record "No. Series";
    begin
        VATBusinessPostingGroup.Get(VATBusPostingGroupCode);
        NoSeries.Get(VATBusinessPostingGroup."Default Purch. Operation Type");
        NoSeries.Validate("Reverse Sales VAT No. Series", '');
        NoSeries.Modify(true);
    end;

    local procedure VerifyGLEntry(DocumentType: Enum "Gen. Journal Document Type"; DocumentNo: Code[20]; GLAccountNo: Code[20]; Amount: Decimal)
    var
        GLEntry: Record "G/L Entry";
    begin
        GLEntry.SetRange("Document Type", DocumentType);
        GLEntry.SetRange("Document No.", DocumentNo);
        GLEntry.SetRange("G/L Account No.", GLAccountNo);
        GLEntry.FindFirst();
        GLEntry.TestField(Amount, Amount);
    end;

    local procedure VerifyGLEntries(DocumentNo: Code[20]; GLAccountNo: Code[20]; GLAccountNo2: Code[20]; Amount: Decimal)
    var
        GLEntry: Record "G/L Entry";
    begin
        VerifyGLEntry(GLEntry."Document Type"::"Credit Memo", DocumentNo, GLAccountNo, Amount);
        VerifyGLEntry(GLEntry."Document Type"::"Credit Memo", DocumentNo, GLAccountNo2, -Amount);
    end;

    local procedure VerifyCreditGLEntryExists(DocType: Enum "Gen. Journal Document Type"; DocNo: Code[20]; GLAccNo: Code[20])
    var
        GLEntry: Record "G/L Entry";
    begin
        GLEntry.SetRange("Document Type", DocType);
        GLEntry.SetRange("Document No.", DocNo);
        GLEntry.SetRange("G/L Account No.", GLAccNo);
        Assert.IsTrue(GLEntry.FindFirst(), StrSubstNo(EntryDoesNotExistErr, GLEntry.TableCaption(), GLEntry.GetFilters));
        Assert.AreEqual(Abs(GLEntry.Amount), GLEntry."Credit Amount", StrSubstNo(WrongValueErr, GLEntry.TableCaption(), GLEntry.FieldCaption("Credit Amount")));
    end;

    local procedure VerifyReverseChargeDeductibleVATEntries(DocType: Enum "Gen. Journal Document Type"; DocNo: Code[20])
    var
        VATEntry: Record "VAT Entry";
        ExpectedVATBase: Decimal;
        ExpectedVATAmount: Decimal;
    begin
        VATEntry.SetRange("Document Type", DocType);
        VATEntry.SetRange("Document No.", DocNo);
        VATEntry.SetRange(Type, VATEntry.Type::Purchase);
        VATEntry.FindFirst();
        Assert.AreEqual(0, VATEntry.Base, StrSubstNo(WrongValueErr, VATEntry.TableCaption(), VATEntry.FieldCaption(Base)));
        Assert.AreEqual(0, VATEntry.Amount, StrSubstNo(WrongValueErr, VATEntry.TableCaption(), VATEntry.FieldCaption(Amount)));
        Assert.IsTrue(
          VATEntry."Nondeductible Base" <> 0, StrSubstNo(WrongValueErr, VATEntry.TableCaption(), VATEntry.FieldCaption("Nondeductible Base")));
        Assert.IsTrue(
          VATEntry."Nondeductible Amount" <> 0, StrSubstNo(WrongValueErr, VATEntry.TableCaption(), VATEntry.FieldCaption("Nondeductible Amount")));
        ExpectedVATBase := -VATEntry."Nondeductible Base";
        ExpectedVATAmount := -VATEntry."Nondeductible Amount";
        VATEntry.SetRange(Type, VATEntry.Type::Sale);
        VATEntry.FindFirst();
        Assert.AreEqual(0, VATEntry."Nondeductible Base", StrSubstNo(WrongValueErr, VATEntry.TableCaption(), VATEntry.FieldCaption("Nondeductible Base")));
        Assert.AreEqual(0, VATEntry."Nondeductible Amount", StrSubstNo(WrongValueErr, VATEntry.TableCaption(), VATEntry.FieldCaption("Nondeductible Amount")));
        Assert.AreEqual(ExpectedVATBase, VATEntry.Base, StrSubstNo(WrongValueErr, VATEntry.TableCaption(), VATEntry.FieldCaption(Base)));
        Assert.AreEqual(ExpectedVATAmount, VATEntry.Amount, StrSubstNo(WrongValueErr, VATEntry.TableCaption(), VATEntry.FieldCaption(Amount)));
    end;

    local procedure VerifyPostedPurchaseInvoiceLine(DocumentNo: Code[20]; No: Code[20]; ServiceTariffNo: Code[10])
    var
        PurchaseInvoiceLine: Record "Purch. Inv. Line";
    begin
        PurchaseInvoiceLine.SetRange("Document No.", DocumentNo);
        PurchaseInvoiceLine.SetRange("No.", No);
        PurchaseInvoiceLine.FindFirst();
        PurchaseInvoiceLine.TestField("Service Tariff No.", ServiceTariffNo);
    end;

    local procedure VerifyPostedSalesInvoiceLine(DocumentNo: Code[20]; No: Code[20]; ServiceTariffNo: Code[10])
    var
        SalesInvoiceLine: Record "Sales Invoice Line";
    begin
        SalesInvoiceLine.SetRange("Document No.", DocumentNo);
        SalesInvoiceLine.SetRange("No.", No);
        SalesInvoiceLine.FindFirst();
        SalesInvoiceLine.TestField("Service Tariff No.", ServiceTariffNo);
    end;

    local procedure VerifyPostedServiceInvoiceLine(CustomerNo: Code[20]; No: Code[20]; ServiceTariffNo: Code[10])
    var
        ServiceInvoiceLine: Record "Service Invoice Line";
    begin
        ServiceInvoiceLine.SetRange("Customer No.", CustomerNo);
        ServiceInvoiceLine.SetRange("No.", No);
        ServiceInvoiceLine.FindFirst();
        ServiceInvoiceLine.TestField("Service Tariff No.", ServiceTariffNo);
    end;

    local procedure VerifyVATEntryClosedByEntryNo(VATEntry: array[3] of Record "VAT Entry"; SettlementVATEntryNo: array[3] of Integer)
    var
        i: Integer;
    begin
        for i := 1 to ArrayLen(VATEntry) do
            VATEntry[i].TestField("Closed by Entry No.", SettlementVATEntryNo[i]);
    end;

    local procedure VerifyVATEntryVATPeriod(VATEntryNo: Integer; VATPeriod: Code[10])
    var
        VATEntry: Record "VAT Entry";
    begin
        VATEntry.Get(VATEntryNo);
        VATEntry.TestField("VAT Period", VATPeriod);
    end;

    local procedure VerifyVATEntryNoInVATSettlementReportResults(VATEntry: array[3] of Record "VAT Entry"; SettlementVATEntryNo: array[3] of Integer)
    var
        Node: DotNet XmlNode;
        i: Integer;
    begin
        LibraryXPathXMLReader.Initialize(LibraryVariableStorage.DequeueText(), '');

        for i := 1 to ArrayLen(VATEntry) do begin
            LibraryXPathXMLReader.GetNodeByElementNameByIndex('/DataSet/Result', Node, (i * 2) - 2);
            LibraryXPathXMLReader.VerifyNodeValueFromParentNode(Node, 'VATBusPostGr_VATPostingSetup', VATEntry[i]."VAT Bus. Posting Group");
            LibraryXPathXMLReader.VerifyNodeValueFromParentNode(Node, 'VATProdPostGr_VATPostingSetup', VATEntry[i]."VAT Prod. Posting Group");
            LibraryXPathXMLReader.VerifyNodeValueFromParentNode(Node, 'EntryNo_VATEntry', Format(VATEntry[i]."Entry No."));

            LibraryXPathXMLReader.GetNodeByElementNameByIndex('/DataSet/Result', Node, (i * 2) - 1);
            LibraryXPathXMLReader.VerifyNodeValueFromParentNode(Node, 'VATBusPostGr_VATPostingSetup', VATEntry[i]."VAT Bus. Posting Group");
            LibraryXPathXMLReader.VerifyNodeValueFromParentNode(Node, 'VATProdPostGr_VATPostingSetup', VATEntry[i]."VAT Prod. Posting Group");
            LibraryXPathXMLReader.VerifyNodeValueFromParentNode(Node, 'NextVATEntryNo', Format(SettlementVATEntryNo[i]));
        end;
    end;

    local procedure VerifyReverseChargeVATVATEntryNoInVATSettlementReportResults(PurchaseVATEntry: array[3] of Record "VAT Entry"; SaleVATEntry: array[3] of Record "VAT Entry"; PurchaseSettlementVATEntryNo: array[3] of Integer; SaleSettlementVATEntryNo: array[3] of Integer)
    var
        Node: DotNet XmlNode;
        i: Integer;
    begin
        LibraryXPathXMLReader.Initialize(LibraryVariableStorage.DequeueText(), '');

        for i := 1 to ArrayLen(PurchaseVATEntry) do begin
            LibraryXPathXMLReader.GetNodeByElementNameByIndex('/DataSet/Result', Node, (i * 4) - 4);
            LibraryXPathXMLReader.VerifyNodeValueFromParentNode(Node, 'VATBusPostGr_VATPostingSetup', PurchaseVATEntry[i]."VAT Bus. Posting Group");
            LibraryXPathXMLReader.VerifyNodeValueFromParentNode(Node, 'VATProdPostGr_VATPostingSetup', PurchaseVATEntry[i]."VAT Prod. Posting Group");
            LibraryXPathXMLReader.VerifyNodeValueFromParentNode(Node, 'EntryNo_VATEntry', Format(PurchaseVATEntry[i]."Entry No."));
            LibraryXPathXMLReader.VerifyNodeValueFromParentNode(Node, 'Type_VATEntry', 'Purchase');

            LibraryXPathXMLReader.GetNodeByElementNameByIndex('/DataSet/Result', Node, (i * 4) - 3);
            LibraryXPathXMLReader.VerifyNodeValueFromParentNode(Node, 'VATBusPostGr_VATPostingSetup', PurchaseVATEntry[i]."VAT Bus. Posting Group");
            LibraryXPathXMLReader.VerifyNodeValueFromParentNode(Node, 'VATProdPostGr_VATPostingSetup', PurchaseVATEntry[i]."VAT Prod. Posting Group");
            LibraryXPathXMLReader.VerifyNodeValueFromParentNode(Node, 'NextVATEntryNo', Format(PurchaseSettlementVATEntryNo[i]));

            LibraryXPathXMLReader.GetNodeByElementNameByIndex('/DataSet/Result', Node, (i * 4) - 2);
            LibraryXPathXMLReader.VerifyNodeValueFromParentNode(Node, 'VATBusPostGr_VATPostingSetup', SaleVATEntry[i]."VAT Bus. Posting Group");
            LibraryXPathXMLReader.VerifyNodeValueFromParentNode(Node, 'VATProdPostGr_VATPostingSetup', SaleVATEntry[i]."VAT Prod. Posting Group");
            LibraryXPathXMLReader.VerifyNodeValueFromParentNode(Node, 'EntryNo_VATEntry', Format(SaleVATEntry[i]."Entry No."));
            LibraryXPathXMLReader.VerifyNodeValueFromParentNode(Node, 'Type_VATEntry', 'Sale');

            LibraryXPathXMLReader.GetNodeByElementNameByIndex('/DataSet/Result', Node, (i * 4) - 1);
            LibraryXPathXMLReader.VerifyNodeValueFromParentNode(Node, 'VATBusPostGr_VATPostingSetup', SaleVATEntry[i]."VAT Bus. Posting Group");
            LibraryXPathXMLReader.VerifyNodeValueFromParentNode(Node, 'VATProdPostGr_VATPostingSetup', SaleVATEntry[i]."VAT Prod. Posting Group");
            LibraryXPathXMLReader.VerifyNodeValueFromParentNode(Node, 'NextVATEntryNo', Format(SaleSettlementVATEntryNo[i]));
        end;
    end;

    local procedure CreateVateRegisterWithSalesType(var VATRegister: Record "VAT Register")
    begin
        VATRegister.Init();
        VATRegister.Code := LibraryUtility.GenerateRandomCode(VATRegister.FieldNo(Code), DATABASE::"VAT Register");
        VATRegister.Description := VATRegister.Code;
        VATRegister.Type := VATRegister.Type::Sale;
        VATRegister.Insert();
    end;

    local procedure CreateVateRegisterWithPurchaseType(var VATRegister: Record "VAT Register")
    begin
        VATRegister.Init();
        VATRegister.Code := LibraryUtility.GenerateRandomCode(VATRegister.FieldNo(Code), DATABASE::"VAT Register");
        VATRegister.Description := VATRegister.Code;
        VATRegister.Type := VATRegister.Type::Purchase;
        VATRegister.Insert();
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure CalcAndPostVATSettlementRequestPageHandler(var CalcAndPostVATSettlement: TestRequestPage "Calc. and Post VAT Settlement")
    var
        AccountNo: Variant;
        StartingDate: Variant;
    begin
        LibraryVariableStorage.Dequeue(StartingDate);
        LibraryVariableStorage.Dequeue(AccountNo);
        CalcAndPostVATSettlement.StartingDate.SetValue(StartingDate);
        CalcAndPostVATSettlement.SettlementAcc.SetValue(AccountNo);
        CalcAndPostVATSettlement.GLGainsAccount.SetValue(AccountNo);
        CalcAndPostVATSettlement.GLLossesAccount.SetValue(AccountNo);
        CalcAndPostVATSettlement.DocumentNo.SetValue(AccountNo);
        CalcAndPostVATSettlement.Post.SetValue(true);
        CalcAndPostVATSettlement.ShowVATEntries.SetValue(true);
        CalcAndPostVATSettlement.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    procedure CalcAndPostVATSettlementFileNameRequestPageHandler(var CalcAndPostVATSettlement: TestRequestPage "Calc. and Post VAT Settlement")
    var
        FileName: Text;
    begin
        FileName := LibraryReportDataset.GetFileName();
        LibraryVariableStorage.Enqueue(FileName);
        CalcAndPostVATSettlement.SaveAsXml(LibraryReportDataset.GetParametersFileName(), FileName);
    end;

    [RequestPageHandler]
    procedure CalcAndPostVATSettlementNoParamsRequestPageHandler(var CalcAndPostVATSettlement: TestRequestPage "Calc. and Post VAT Settlement")
    begin
        CalcAndPostVATSettlement.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandler(Question: Text; var Reply: Boolean)
    begin
        Reply := true;
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure UnapplyCustomerEntriesModalPageHandler(var UnapplyCustomerEntries: TestPage "Unapply Customer Entries")
    begin
        UnapplyCustomerEntries.Unapply.Invoke();
        UnapplyCustomerEntries.Close();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure UnapplyVendorEntriesModalPageHandler(var UnapplyVendorEntries: TestPage "Unapply Vendor Entries")
    begin
        UnapplyVendorEntries.Unapply.Invoke();
        UnapplyVendorEntries.Close();
    end;
}

