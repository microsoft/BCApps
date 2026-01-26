codeunit 145403 "AU Feature Bugs"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
    end;

    var
        Assert: Codeunit Assert;
        LibraryAPACLocalization: Codeunit "Library - APAC Localization";
        LibraryERM: Codeunit "Library - ERM";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibraryRandom: Codeunit "Library - Random";
        LibrarySales: Codeunit "Library - Sales";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibraryReportDataset: Codeunit "Library - Report Dataset";
        AmountMustBeZeroMsg: Label 'Amount must be zero.';
        WHTAmountErr: Label 'WHT amount should match with %1', Comment = '%1 = Expected Amount';

    [Test]
    [Scope('OnPrem')]
    procedure PaymentAppliedToPurchaseInvoiceWithWHT()
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
        GenJournalLine: Record "Gen. Journal Line";
        VATPostingSetup: Record "VAT Posting Setup";
        DocumentNo: Code[20];
    begin
        // [FEATURE] [WHT]
        // [SCENARIO] Payment Journal is posted successfully when applied to Invoice with WHT.

        // [GIVEN] Create and post Purchase Invoice and apply Payment to it.
        GeneralLedgerSetup.Get();
        UpdateGeneralLedgerSetup(true, true, true, true);  // Using TRUE for EnableTaxInvoices,EnableWHT,PrintTaxInvoicesOnPosting,UnrealizedVAT.
        FindAndUpdateVATPostingSetup(VATPostingSetup);
        DocumentNo := CreateAndPostPurchaseInvoice(VATPostingSetup);
        CreateAndApplyPaymentToPurchaseInvoice(GenJournalLine, DocumentNo);

        // Exercise.
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // [THEN] Verify that Payment is fully applied to Invoice.
        VerifyVendorLedgerEntry(GenJournalLine."Account No.");

        // Tear Down: Roll back VAT Posting Setup and General Ledger Setup.
        UpdateVATPostingSetup(
          VATPostingSetup."VAT Bus. Posting Group", VATPostingSetup."VAT Prod. Posting Group", VATPostingSetup."Unrealized VAT Type");
        UpdateGeneralLedgerSetup(
          GeneralLedgerSetup."Enable Tax Invoices", GeneralLedgerSetup."Enable WHT", GeneralLedgerSetup."Print Tax Invoices on Posting",
          GeneralLedgerSetup."Unrealized VAT");
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure PostGeneralJnlLineAndReverseEntryWithGST()
    var
        DocumentNo: Code[20];
    begin
        // [FEATURE] [GST] [Purchase] [Reverse]
        // [SCENARIO] reversed GST Purchase Entry gets created.

        // [GIVEN] Create and Post General Journal Line, Reverse them and Check GST Purchase Entry.
        DocumentNo := CreateAndPostGeneralJournalLine();

        // Exercise: Reverse Posted Entry.
        ReverseEntry();

        // [THEN] Verify that reversed GST Purchase Entry gets created.
        VerifyGSTPurchaseEntry(DocumentNo);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VerifyWHTPostingGroupNotToBeIndicatedForCommentLines()
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
        VATPostingSetup: Record "VAT Posting Setup";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        PurchaseLine2: Record "Purchase Line";
        WHTPostingSetup: Record "WHT Posting Setup";
        StandardText: Record "Standard Text";
    begin
        // [SCENARIO 452097] WHT posting group code must be indicated for comment lines on the Purchase invoice page

        // [GIVEN] Create WHT Posting Setup, Update General Ledger Setup and VAT Posting Setup
        CreateWHTPostingSetup(WHTPostingSetup);
        UpdateGeneralLedgerSetup(true, true, true, true);  // Using TRUE for EnableTaxInvoices,EnableWHT,PrintTaxInvoicesOnPosting,UnrealizedVAT.
        FindAndUpdateVATPostingSetup(VATPostingSetup);

        // [GIVEN] Create Purchase Header
        LibraryPurchase.CreatePurchHeader(
          PurchaseHeader, PurchaseHeader."Document Type"::Invoice, CreateVendor(VATPostingSetup."VAT Bus. Posting Group",
            WHTPostingSetup."WHT Business Posting Group"));

        // [GIVEN] Create Purchase Line with Type as G/L Account
        LibraryPurchase.CreatePurchaseLine(
          PurchaseLine, PurchaseHeader, PurchaseLine.Type::"G/L Account", CreateGLAccount(VATPostingSetup."VAT Prod. Posting Group",
            WHTPostingSetup."WHT Product Posting Group"), LibraryRandom.RandDec(10, 2));  // Using random value for Quantity.

        // [GIVEN] Create Standard Text
        LibrarySales.CreateStandardText(StandardText);

        // [GIVEN] Create Purchase Line with Type as empty
        LibraryPurchase.CreatePurchaseLine(PurchaseLine2, PurchaseHeader, PurchaseLine2.Type::" ", StandardText.Code, LibraryRandom.RandInt(10));

        // [WHEN] WHT Product Posting Group assigned with empty value when Purchase Line Type as empty
        PurchaseLine2."WHT Business Posting Group" := WHTPostingSetup."WHT Business Posting Group";
        PurchaseLine2.Modify();

        // [THEN] Verify Purchase Invoice to be posted without WHT Posting Group indication
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, false, true);

        // Tear Down: Roll back VAT Posting Setup and General Ledger Setup
        UpdateVATPostingSetup(
          VATPostingSetup."VAT Bus. Posting Group", VATPostingSetup."VAT Prod. Posting Group", VATPostingSetup."Unrealized VAT Type");
        UpdateGeneralLedgerSetup(
          GeneralLedgerSetup."Enable Tax Invoices", GeneralLedgerSetup."Enable WHT", GeneralLedgerSetup."Print Tax Invoices on Posting",
          GeneralLedgerSetup."Unrealized VAT");
    end;

    [Test]
    //[HandlerFunctions('HandleEditdimSetEntryForm')]
    [Scope('OnPrem')]
    procedure VerifyDimensionValueLenOnWHT()
    var
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalLine: Record "Gen. Journal Line";
        WHTPostingSetup: Record "WHT Posting Setup";
        VATPostingSetup: Record "VAT Posting Setup";
        DimensionValue: Record "Dimension Value";
        ShortcutDimCode: Code[20];
        VendorNo: Code[20];
        Amount: Decimal;
    begin
        // [SCENARIO 449150] Dimension value characters limit error 'The length of the string is 20, but it must be less than or equal to 10 characters. Value: XXXXXXXXXXX'
        // [GIVEN] Create Setup and Disable GST Australia and Enable WHT to true on General Ledger Setup  
        CreateWHTPostingSetup(WHTPostingSetup);
        UpdateGeneralLedgerSetup(true, true, true, true);
        UpdateGSTAusOnGenLedgSetup(false);
        FindAndUpdateVATPostingSetup(VATPostingSetup);

        // [THEN] Create General journal Batch and Create Dimension Code.
        PrepareGeneralJournal(GenJournalBatch);
        ShortcutDimCode := FindShortcutDimension();
        CreateDimensionValue(DimensionValue, ShortcutDimCode);

        // [GIVEN] Create the general journal line
        LibraryERM.CreateGeneralJnlLine(
          GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name, GenJournalLine."Document Type"::Payment,
          GenJournalLine."Account Type"::Vendor, CreateVendor(VATPostingSetup."VAT Bus. Posting Group",
            WHTPostingSetup."WHT Business Posting Group"), LibraryRandom.RandInt(1000));

        // [THEN] Change shortcut dimension on the general journal line
        GenJournalLine.Validate("Shortcut Dimension 1 Code", DimensionValue.Code);
        GenJournalLine.Modify(true);
        VendorNo := GenJournalLine."Account No.";
        Amount := GenJournalLine.Amount;

        // [THEN] Post genjournal line 
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        //[VERIFY] Verify the posted Vendor Ledger Entry.
        VerifyVendorLedgerEntry(VendorNo, Amount);
    end;

    [Test]
    [HandlerFunctions('BudgetRequestPageHandler')]
    [Scope('OnPrem')]
    procedure GLBudgetAddNewGLBudgetEntryWith2DecimalPlaces()
    var
        GLAccount: Record "G/L Account";
        GLBudgetName: Record "G/L Budget Name";
        BudgetAmount: Decimal;
        GLAccountNo: Code[20];
    begin
        // [SCENARIO 457899] G/L Budget  doesn't show the same amount as the Budget G/L Entries.

        // [GIVEN] Create GL Budget Name and GL Account
        LibraryERM.CreateGLBudgetName(GLBudgetName);
        LibraryERM.CreateGLAccount(GLAccount);

        // [GIVEN] Enqueue value for BudgetRequestPageHandler.
        LibraryVariableStorage.Enqueue(GLAccountNo);

        // [GIVEN] Creaet GL Budget Entry and add Budget Amount 
        BudgetAmount := LibraryRandom.RandDec(1000000, 2);
        CreateGLBudgetEntry(GLBudgetName.Name, GLAccount."No.", BudgetAmount);
        Commit();

        // [THEN] Run the Budget report
        REPORT.Run(REPORT::Budget);

        // [VERIFY] Verify the Budget Amount on xml will be same.
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementWithValueExists('TotalBudgetAmount', BudgetAmount);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CreateWHTSetupAndPostPurchaseOrderWithMultipleLines()
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
        VATPostingSetup: Record "VAT Posting Setup";
        WHTBusinessPostingGroup: Record "WHT Business Posting Group";
        WHTProductPostingGroup: Record "WHT Product Posting Group";
        WHTPostingSetup: Record "WHT Posting Setup";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: array[2] of Record "Purchase Line";
        PostedDocumentNo: Code[20];
        VendorNo: Code[20];
        DirectUnitCost: Decimal;
    begin
        // [SCENARIO 592550] No inconsistency when posting purchase invoice partially with WHT calculation rule = Invoice
        // [GIVEN] Enable WHT and disable GST on General Ledger Setup
        GeneralLedgerSetup.Get();
        UpdateGeneralLedgerSetup(true, true, true, true);

        // [GIVEN] Disable GST Australia on General Ledger Setup
        UpdateGSTAusOnGenLedgSetup(false);

        // [GIVEN] Find VAT Posting Setup
        FindAndUpdateVATPostingSetup(VATPostingSetup);

        // [GIVEN] Assign random Direct Unit Cost
        DirectUnitCost := LibraryRandom.RandDec(100, 2);

        // [GIVEN] Create WHT Business Posting Group 
        LibraryAPACLocalization.CreateWHTBusinessPostingGroup(WHTBusinessPostingGroup);

        // [GIVEN] Create WHT Product Posting Group 
        LibraryAPACLocalization.CreateWHTProductPostingGroup(WHTProductPostingGroup);

        // [GIVEN] Create WHT Posting Setup
        CreateWHTPostingSetupWithSpecificGroups(WHTPostingSetup, WHTBusinessPostingGroup.Code, WHTProductPostingGroup.Code, LibraryRandom.RandInt(10));

        // [GIVEN] Create vendor with WHT setup
        VendorNo := CreateVendor(VATPostingSetup."VAT Bus. Posting Group", WHTBusinessPostingGroup.Code);

        // [GIVEN] Create Purchase Order
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, VendorNo);

        // [GIVEN] Add first purchase line
        CreatePurchaseLineWithGLAccount(PurchaseHeader, PurchaseLine[1], VATPostingSetup."VAT Prod. Posting Group", WHTProductPostingGroup.Code, DirectUnitCost);

        // [GIVEN] Add second purchase line and set quantity to receive as 0
        CreatePurchaseLineWithGLAccount(PurchaseHeader, PurchaseLine[2], VATPostingSetup."VAT Prod. Posting Group", WHTProductPostingGroup.Code, DirectUnitCost);
        PurchaseLine[2].Validate("Qty. to Receive", 0);
        PurchaseLine[2].Modify();

        // [WHEN] Post first Purchase line in Purchase Order
        PostedDocumentNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        // [THEN] Verify successful posting of first Purchase line
        VerifyPostedPurchaseInvoiceExists(PostedDocumentNo);

        // [THEN] Verify WHT Amount in WHT Entry
        VerifyWHTCalculations(PostedDocumentNo, WHTPostingSetup."WHT %");

        // [GIVEN] Update Purchase Header with Vendor Invoice No.
        PurchaseHeader.Validate("Vendor Invoice No.", LibraryRandom.RandText(10));
        PurchaseHeader.Modify(true);

        // [GIVEN] Post second Purchase line in Purchase Order
        PostedDocumentNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        // [THEN] Verify successful posting
        VerifyPostedPurchaseInvoiceExists(PostedDocumentNo);

        // [THEN] Verify WHT Amount in WHT Entry
        VerifyWHTCalculations(PostedDocumentNo, WHTPostingSetup."WHT %");

        // [TEAR DOWN] Roll back VAT Posting Setup and General Ledger Setup
        UpdateVATPostingSetup(
            VATPostingSetup."VAT Bus. Posting Group", VATPostingSetup."VAT Prod. Posting Group", VATPostingSetup."Unrealized VAT Type");
        UpdateGeneralLedgerSetup(
            GeneralLedgerSetup."Enable Tax Invoices", GeneralLedgerSetup."Enable WHT",
            GeneralLedgerSetup."Print Tax Invoices on Posting", GeneralLedgerSetup."Unrealized VAT");
    end;

    local procedure CreateAndPostGeneralJournalLine(): Code[20]
    var
        GenJournalLine: Record "Gen. Journal Line";
        GenJournalBatch: Record "Gen. Journal Batch";
        GLAccount: Record "G/L Account";
        VATPostingSetup: Record "VAT Posting Setup";
        Vendor: Record Vendor;
    begin
        CreateVATPostingSetup(VATPostingSetup);
        LibraryPurchase.CreateVendor(Vendor);
        CreateGeneralJournalBatch(GenJournalBatch);
        LibraryERM.CreateGeneralJnlLine(
            GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name, GenJournalLine."Document Type"::Invoice,
            GenJournalLine."Account Type"::"G/L Account", LibraryERM.CreateGLAccountWithVATPostingSetup(
            VATPostingSetup, GLAccount."Gen. Posting Type"::Purchase), LibraryRandom.RandInt(100));
        GenJournalLine.Validate("Bal. Account Type", GenJournalLine."Bal. Account Type"::Vendor);
        GenJournalLine.Validate("Bal. Account No.", Vendor."No.");
        GenJournalLine.Modify(true);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
        exit(GenJournalLine."Document No.");
    end;

    local procedure CreateVATPostingSetup(var VATPostingSetup: Record "VAT Posting Setup")
    var
        GLAccount: Record "G/L Account";
        VATBusPostingGroup: Record "VAT Business Posting Group";
        VATProdPostingGroup: Record "VAT Product Posting Group";
    begin
        LibraryERM.CreateGLAccount(GLAccount);
        LibraryERM.CreateVATBusinessPostingGroup(VATBusPostingGroup);
        LibraryERM.CreateVATProductPostingGroup(VATProdPostingGroup);
        LibraryERM.CreateVATPostingSetup(VATPostingSetup, VATBusPostingGroup.Code, VATProdPostingGroup.Code);
        VATPostingSetup.Validate("VAT %", LibraryRandom.RandInt(10));
        VATPostingSetup.Validate("Purchase VAT Account", GLAccount."No.");
        VATPostingSetup.Modify(true);
    end;

    local procedure ReverseEntry()
    var
        ReversalEntry: Record "Reversal Entry";
        GLRegister: Record "G/L Register";
    begin
        GLRegister.FindLast();
        ReversalEntry.SetHideDialog(true);
        ReversalEntry.ReverseRegister(GLRegister."No.");
    end;

    local procedure CreateAndApplyPaymentToPurchaseInvoice(var GenJournalLine: Record "Gen. Journal Line"; AppliesToDocNo: Code[20])
    var
        BankAccount: Record "Bank Account";
        GenJournalBatch: Record "Gen. Journal Batch";
        PurchInvHeader: Record "Purch. Inv. Header";
    begin
        PurchInvHeader.Get(AppliesToDocNo);
        PurchInvHeader.CalcFields("Amount Including VAT");
        LibraryERM.CreateBankAccount(BankAccount);
        CreateGeneralJournalBatch(GenJournalBatch);
        LibraryERM.CreateGeneralJnlLine(
          GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name, GenJournalLine."Document Type"::Payment,
          GenJournalLine."Account Type"::Vendor, PurchInvHeader."Buy-from Vendor No.", PurchInvHeader."Amount Including VAT");
        GenJournalLine.Validate("Bal. Account Type", GenJournalLine."Bal. Account Type"::"Bank Account");
        GenJournalLine.Validate("Bal. Account No.", BankAccount."No.");
        GenJournalLine.Validate("Applies-to Doc. Type", GenJournalLine."Applies-to Doc. Type"::Invoice);
        GenJournalLine.Validate("Applies-to Doc. No.", AppliesToDocNo);
        GenJournalLine.Modify(true);
    end;

    local procedure CreateAndPostPurchaseInvoice(VATPostingSetup: Record "VAT Posting Setup"): Code[20]
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        WHTPostingSetup: Record "WHT Posting Setup";
    begin
        CreateWHTPostingSetup(WHTPostingSetup);
        LibraryPurchase.CreatePurchHeader(
          PurchaseHeader, PurchaseHeader."Document Type"::Invoice, CreateVendor(VATPostingSetup."VAT Bus. Posting Group",
            WHTPostingSetup."WHT Business Posting Group"));
        LibraryPurchase.CreatePurchaseLine(
          PurchaseLine, PurchaseHeader, PurchaseLine.Type::"G/L Account", CreateGLAccount(VATPostingSetup."VAT Prod. Posting Group",
            WHTPostingSetup."WHT Product Posting Group"), LibraryRandom.RandDec(10, 2));  // Using random value for Quantity.
        PurchaseLine.Validate("Direct Unit Cost", LibraryRandom.RandDec(100, 2));
        PurchaseLine.Validate("VAT Prod. Posting Group", VATPostingSetup."VAT Prod. Posting Group");
        PurchaseLine.Modify(true);
        exit(LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true));  // Post as Receive and Invoice.
    end;

    local procedure CreateGeneralJournalBatch(var GenJournalBatch: Record "Gen. Journal Batch")
    var
        GenJournalTemplate: Record "Gen. Journal Template";
    begin
        GenJournalTemplate.SetRange(Type, GenJournalTemplate.Type::Payments);
        LibraryERM.FindGenJournalTemplate(GenJournalTemplate);
        LibraryERM.CreateGenJournalBatch(GenJournalBatch, GenJournalTemplate.Name);
    end;

    local procedure CreateGLAccount(VATProdPostingGroup: Code[20]; WHTProductPostingGroup: Code[20]): Code[20]
    var
        GeneralPostingSetup: Record "General Posting Setup";
        GLAccount: Record "G/L Account";
    begin
        LibraryERM.FindGeneralPostingSetup(GeneralPostingSetup);
        LibraryERM.CreateGLAccount(GLAccount);
        GLAccount.Validate("Gen. Prod. Posting Group", GeneralPostingSetup."Gen. Prod. Posting Group");
        GLAccount.Validate("VAT Prod. Posting Group", VATProdPostingGroup);
        GLAccount.Validate("WHT Product Posting Group", WHTProductPostingGroup);
        GLAccount.Modify(true);
        exit(GLAccount."No.");
    end;

    local procedure CreateVendor(VATBusPostingGroup: Code[20]; WHTBusinessPostingGroup: Code[20]): Code[20]
    var
        Vendor: Record Vendor;
    begin
        LibraryPurchase.CreateVendor(Vendor);
        Vendor.Validate(ABN, '');  // As required by the test case using ABN as blank.
        Vendor.Validate("VAT Bus. Posting Group", VATBusPostingGroup);
        Vendor.Validate("WHT Business Posting Group", WHTBusinessPostingGroup);
        Vendor.Modify(true);
        exit(Vendor."No.");
    end;

    local procedure CreateWHTPostingSetup(var WHTPostingSetup: Record "WHT Posting Setup")
    var
        GLAccount: Record "G/L Account";
        WHTBusinessPostingGroup: Record "WHT Business Posting Group";
        WHTProductPostingGroup: Record "WHT Product Posting Group";
    begin
        LibraryERM.CreateGLAccount(GLAccount);
        LibraryAPACLocalization.CreateWHTBusinessPostingGroup(WHTBusinessPostingGroup);
        LibraryAPACLocalization.CreateWHTProductPostingGroup(WHTProductPostingGroup);
        LibraryAPACLocalization.CreateWHTPostingSetup(WHTPostingSetup, WHTBusinessPostingGroup.Code, WHTProductPostingGroup.Code);
        WHTPostingSetup.Validate("WHT %", LibraryRandom.RandDec(10, 2));
        WHTPostingSetup.Validate("WHT Minimum Invoice Amount", LibraryRandom.RandDec(1000, 2));
        WHTPostingSetup.Validate("Realized WHT Type", WHTPostingSetup."Realized WHT Type"::Payment);
        WHTPostingSetup.Validate("Prepaid WHT Account Code", GLAccount."No.");
        WHTPostingSetup.Validate("Payable WHT Account Code", GLAccount."No.");
        WHTPostingSetup.Validate("Purch. WHT Adj. Account No.", GLAccount."No.");
        WHTPostingSetup.Validate("Sales WHT Adj. Account No.", GLAccount."No.");
        WHTPostingSetup.Modify(true);
    end;

    local procedure FindAndUpdateVATPostingSetup(var VATPostingSetup: Record "VAT Posting Setup")
    begin
        LibraryERM.FindVATPostingSetup(VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT");
        UpdateVATPostingSetup(
          VATPostingSetup."VAT Bus. Posting Group", VATPostingSetup."VAT Prod. Posting Group",
          VATPostingSetup."Unrealized VAT Type"::Percentage);
    end;

    local procedure UpdateGeneralLedgerSetup(EnableTaxInvoices: Boolean; EnableWHT: Boolean; PrintTaxInvoicesOnPosting: Boolean; UnrealizedVAT: Boolean)
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
    begin
        GeneralLedgerSetup.Get();
        GeneralLedgerSetup.Validate("Enable Tax Invoices", EnableTaxInvoices);
        GeneralLedgerSetup.Validate("Enable WHT", EnableWHT);
        GeneralLedgerSetup.Validate("Print Tax Invoices on Posting", PrintTaxInvoicesOnPosting);
        GeneralLedgerSetup.Validate("Unrealized VAT", UnrealizedVAT);
        GeneralLedgerSetup.Modify(true);
    end;

    local procedure UpdateVATPostingSetup(VATBusPostingGroup: Code[20]; VATProdPostingGroup: Code[20]; UnrealizedVATType: Option)
    var
        GLAccount: Record "G/L Account";
        VATPostingSetup: Record "VAT Posting Setup";
    begin
        VATPostingSetup.Get(VATBusPostingGroup, VATProdPostingGroup);
        LibraryERM.CreateGLAccount(GLAccount);
        VATPostingSetup.Validate("Unrealized VAT Type", UnrealizedVATType);
        VATPostingSetup.Validate("Purchase VAT Account", GLAccount."No.");
        VATPostingSetup.Validate("Purch. VAT Unreal. Account", GLAccount."No.");
        VATPostingSetup.Modify(true);
    end;

    local procedure VerifyVendorLedgerEntry(VendorNo: Code[20])
    var
        VendorLedgerEntry: Record "Vendor Ledger Entry";
    begin
        VendorLedgerEntry.SetRange("Vendor No.", VendorNo);
        VendorLedgerEntry.SetRange("Document Type", VendorLedgerEntry."Document Type"::Invoice);
        VendorLedgerEntry.FindFirst();
        VendorLedgerEntry.TestField(Open, false);
        VendorLedgerEntry.TestField("Remaining Amount", 0);
    end;

    local procedure VerifyGSTPurchaseEntry(DocumentNo: Code[20])
    var
        GSTPurchaseEntry: Record "GST Purchase Entry";
    begin
        GSTPurchaseEntry.SetRange("Document No.", DocumentNo);
        GSTPurchaseEntry.SetRange("Document Type", GSTPurchaseEntry."Document Type"::Invoice);
        GSTPurchaseEntry.FindFirst();
        GSTPurchaseEntry.CalcSums(Amount);
        Assert.AreEqual(GSTPurchaseEntry.Amount, 0, AmountMustBeZeroMsg);
    end;

    local procedure PrepareGeneralJournal(var GenJournalBatch: Record "Gen. Journal Batch")
    begin
        LibraryERM.SelectGenJnlBatch(GenJournalBatch);
        LibraryERM.ClearGenJournalLines(GenJournalBatch);
    end;

    local procedure FindShortcutDimension(): Code[20]
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
    begin
        GeneralLedgerSetup.Get();
        exit(GeneralLedgerSetup."Shortcut Dimension 1 Code");
    end;

    local procedure UpdateGSTAusOnGenLedgSetup(EnableGSTAustralia: Boolean)
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
    begin
        GeneralLedgerSetup.Get();
        GeneralLedgerSetup.Validate("Enable GST (Australia)", EnableGSTAustralia);
        GeneralLedgerSetup.Modify(true);
    end;

    procedure CreateDimensionValue(var DimensionValue: Record "Dimension Value"; DimensionCode: Code[20])
    begin
        DimensionValue.Init();
        DimensionValue.Validate("Dimension Code", DimensionCode);
        DimensionValue.Validate(
          Code, 'XXXXXXXXXXXXXXXXXXXX');
        DimensionValue.Insert(true);
    end;

    local procedure VerifyVendorLedgerEntry(VendorNo: Code[20]; RemainingAmount: Decimal)
    var
        VendorLedgerEntry: Record "Vendor Ledger Entry";
    begin
        VendorLedgerEntry.SetRange("Vendor No.", VendorNo);
        VendorLedgerEntry.FindSet();
        VendorLedgerEntry.CalcFields("Remaining Amount");
        repeat
            VendorLedgerEntry.TestField("Remaining Amount", RemainingAmount);
        until VendorLedgerEntry.Next() = 0;
    end;

    local procedure CreateGLBudgetEntry(GLBudgetName: Code[10]; AccountNo: Code[20]; Amount2: Decimal): Integer
    var
        GLBudgetEntry: Record "G/L Budget Entry";
    begin
        LibraryERM.CreateGLBudgetEntry(GLBudgetEntry, WorkDate(), AccountNo, GLBudgetName);
        GLBudgetEntry.Validate(Amount, Amount2);  // Taking Variable name Amount2 due to global variable.
        GLBudgetEntry.Modify(true);
        GLBudgetEntry.TestField("Last Date Modified");
        exit(GLBudgetEntry."Entry No.");
    end;

    local procedure CreatePurchaseLineWithGLAccount(var PurchaseHeader: Record "Purchase Header"; var PurchaseLine: Record "Purchase Line"; VATProdPostingGroup: Code[20]; WHTProductPostingGroup: Code[20]; DirectUnitCost: Decimal)
    var
        GLAccountNo: Code[20];
    begin
        GLAccountNo := CreateGLAccount(VATProdPostingGroup, WHTProductPostingGroup);
        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::"G/L Account", GLAccountNo, 1);
        PurchaseLine.Validate("Direct Unit Cost", DirectUnitCost);
        PurchaseLine.Validate("VAT Prod. Posting Group", VATProdPostingGroup);
        PurchaseLine.Modify(true);
    end;

    local procedure CreateWHTPostingSetupWithSpecificGroups(
        var WHTPostingSetup: Record "WHT Posting Setup";
        WHTBusinessPostingGroup: Code[20];
        WHTProductPostingGroup: Code[20];
        WHTPercent: Integer)
    var
        GLAccount1: Record "G/L Account";
        GLAccount2: Record "G/L Account";
        GLAccount3: Record "G/L Account";
        GLAccount4: Record "G/L Account";
        BankAccount: Record "Bank Account";
        WHTRevenueTypes: Record "WHT Revenue Types";
    begin
        LibraryERM.CreateGLAccount(GLAccount1);
        LibraryERM.CreateGLAccount(GLAccount2);
        LibraryERM.CreateGLAccount(GLAccount3);
        LibraryERM.CreateGLAccount(GLAccount4);
        LibraryERM.CreateBankAccount(BankAccount);
        LibraryAPACLocalization.CreateWHTRevenueTypes(WHTRevenueTypes);

        LibraryAPACLocalization.CreateWHTPostingSetup(WHTPostingSetup, WHTBusinessPostingGroup, WHTProductPostingGroup);
        WHTPostingSetup.Validate("WHT Calculation Rule", WHTPostingSetup."WHT Calculation Rule"::"Greater than");
        WHTPostingSetup.Validate("WHT %", WHTPercent);
        WHTPostingSetup.Validate("Realized WHT Type", WHTPostingSetup."Realized WHT Type"::Invoice);
        WHTPostingSetup.Validate("Revenue Type", WHTRevenueTypes.Code);
        WHTPostingSetup.Validate("Prepaid WHT Account Code", GLAccount1."No.");
        WHTPostingSetup.Validate("Payable WHT Account Code", GLAccount2."No.");
        WHTPostingSetup.Validate("Bal. Prepaid Account No.", BankAccount."No.");
        WHTPostingSetup.Validate("Bal. Payable Account No.", BankAccount."No.");
        WHTPostingSetup.Validate("Purch. WHT Adj. Account No.", GLAccount3."No.");
        WHTPostingSetup.Validate("Sales WHT Adj. Account No.", GLAccount4."No.");
        WHTPostingSetup.Modify(true);
    end;

    local procedure VerifyPostedPurchaseInvoiceExists(DocumentNo: Code[20])
    var
        PurchInvHeader: Record "Purch. Inv. Header";
    begin
        PurchInvHeader.Get(DocumentNo);
        PurchInvHeader.TestField("No.", DocumentNo);
    end;

    local procedure VerifyWHTCalculations(DocumentNo: Code[20]; ExpectedWHTPercent: Decimal)
    var
        WHTEntry: Record "WHT Entry";
        PurchInvLine: Record "Purch. Inv. Line";
        ExpectedWHTAmount: Decimal;
        TotalLineAmount: Decimal;
    begin
        // Calculate expected WHT amount
        PurchInvLine.SetRange("Document No.", DocumentNo);
        PurchInvLine.SetFilter("WHT Product Posting Group", '<>%1', '');
        PurchInvLine.FindSet();
        repeat
            TotalLineAmount += PurchInvLine."Line Amount";
        until PurchInvLine.Next() = 0;

        ExpectedWHTAmount := TotalLineAmount * ExpectedWHTPercent / 100;

        // Verify WHT Entry amount
        WHTEntry.SetRange("Document No.", DocumentNo);
        WHTEntry.SetRange("Document Type", WHTEntry."Document Type"::Invoice);
        WHTEntry.FindFirst();
        Assert.AreNearlyEqual(ExpectedWHTAmount, Abs(WHTEntry.Amount), 0.01, StrSubstNo(WHTAmountErr, ExpectedWHTAmount));
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandler(Question: Text[1024]; var Reply: Boolean)
    begin
        Reply := true;
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure MessageHandler(Message: Text[1024])
    begin
        // Message Handler.
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure BudgetRequestPageHandler(var Budget: TestRequestPage Budget)
    var
        No: Variant;
    begin
        LibraryVariableStorage.Dequeue(No);
        Budget."G/L Account".SetFilter("No.", No);
        Budget.StartingDate.SetValue(Format(WorkDate()));
        Budget.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;
}

