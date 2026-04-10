codeunit 134018 "ERM Payment Tolerance Purchase"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Payment Tolerance] [Purchase]
        isInitialized := false;
    end;

    var
        LibraryERM: Codeunit "Library - ERM";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibraryPmtDiscSetup: Codeunit "Library - Pmt Disc Setup";
        LibrarySetupStorage: Codeunit "Library - Setup Storage";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryRandom: Codeunit "Library - Random";
        Assert: Codeunit Assert;
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        isInitialized: Boolean;
        AmountErrorMessage: Label '%1 must be %2 in %3 %4 %5.';
        ExpectedMessage: Label 'The Credit Memo doesn''t have a Corrected Invoice No. Do you want to continue?';

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure PurchaseInvoiceWithLCY()
    var
        DocumentNo: Code[20];
        ExpectedPmtTolAmount: Decimal;
    begin
        // Covers Test Case 124103,124104.
        // Check Vendor Ledger Entry for Payment Tolerance after posting Purchase Invoice without Currency.

        // Create and Post Purchase Invoice without Currency.
        DocumentNo := CreateAndPostPurchaseDocument('', "Purchase Document Type"::Invoice);

        // Verify: Verify Vendor Ledger Entry Amount.
        ExpectedPmtTolAmount := CalcPaymentTolInvoiceLCY(DocumentNo);
        VerifyMaxPaymentTolInvoice(DocumentNo, ExpectedPmtTolAmount);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure PurchaseCreditMemoWithLCY()
    var
        PurchCrMemoHdr: Record "Purch. Cr. Memo Hdr.";
        DocumentNo: Code[20];
    begin
        // Covers Test Case 124087,124088.
        // Check Vendor Ledger Entry for Payment Tolerance after posting Purchase Credit Memo without Currency.

        // Create and Post Purchase Credit Memo without Currency.
        DocumentNo := CreateAndPostPurchaseDocument('', "Purchase Document Type"::"Credit Memo");

        // Verify: Verify Vendor Ledger Entry Amount.
        PurchCrMemoHdr.Get(DocumentNo);
        PurchCrMemoHdr.CalcFields("Amount Including VAT");
        VerifyVendorLedgerEntry(PurchCrMemoHdr."Amount Including VAT", DocumentNo);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure PurchaseInvoiceWithFCY()
    var
        DocumentNo: Code[20];
        ExpectedPmtTolAmount: Decimal;
    begin
        // Covers Test Case 124103,124104.
        // Check Vendor Ledger Entry for Payment Tolerance after posting Purchase Invoice with Currency.

        // Create and Post Purchase Invoice with Currency.
        DocumentNo := CreateAndPostPurchaseDocument(CreateCurrency(), "Purchase Document Type"::Invoice);

        // Verify: Verify Vendor Ledger Entry Amount.
        ExpectedPmtTolAmount := CalcPaymentTolInvoiceFCY(DocumentNo);
        VerifyMaxPaymentTolInvoice(DocumentNo, ExpectedPmtTolAmount);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure PurchaseCreditMemoWithFCY()
    var
        PurchCrMemoHdr: Record "Purch. Cr. Memo Hdr.";
        DocumentNo: Code[20];
    begin
        // Covers Test Case 124087,124088.
        // Check Vendor Ledger Entry  for Payment Tolerance after posting Purchase Credit Memo with Currency.

        // Create and Post Purchase Credit Memo with Currency.
        DocumentNo := CreateAndPostPurchaseDocument(CreateCurrency(), "Purchase Document Type"::"Credit Memo");

        // Verify: Verify Vendor Ledger Entry Amount.
        PurchCrMemoHdr.Get(DocumentNo);
        PurchCrMemoHdr.CalcFields("Amount Including VAT");
        VerifyVendorLedgerEntry(PurchCrMemoHdr."Amount Including VAT", DocumentNo);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure CreditMemoCopyDocument()
    var
        PurchaseHeader: Record "Purchase Header";
        DocumentNo: Code[20];
    begin
        // Covers Test Case 124089.
        // Check Vendor Ledger Entry for Payment Tolerance after posting Purchase Credit Memo and Copy Document.

        // Setup: Update General ledger Setup and Create and Post Purchase Invoice.
        Initialize();
        LibraryPmtDiscSetup.SetPmtTolerance(5);

        CreatePurchaseDocument(PurchaseHeader, '', PurchaseHeader."Document Type"::Invoice);
        PurchaseHeader.Validate("Vendor Invoice No.", PurchaseHeader."No.");
        PurchaseHeader.Modify(true);
        DocumentNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);
        PurchaseHeader.Init();
        PurchaseHeader.Validate("Document Type", PurchaseHeader."Document Type"::"Credit Memo");
        PurchaseHeader.Insert(true);

        // Exercise: Create and Post Purchase Credit Memo after Copy Document with Document Type Posted Invoice.
        LibraryPurchase.CopyPurchaseDocument(PurchaseHeader, "Purchase Document Type From"::"Posted Invoice", DocumentNo, true, true);
        PurchaseHeader.SetRange("Applies-to Doc. No.", DocumentNo);
        PurchaseHeader.FindFirst();
        PurchaseHeader.Validate("Vendor Cr. Memo No.", DocumentNo);
        PurchaseHeader.Modify(true);
        DocumentNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);
        ExecuteUIHandler();  // Need to invoke confirmation message everytime to prevent test failures in ES build.

        // Verify: Max Payment Tolerance is zero for Credit Memo applied to Invoice.
        VerifyMaxPaymentTolCreditMemo(DocumentNo, 0);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure CreditMemoCopyDocumentLineOnly()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        DocumentNo: Code[20];
        ExpectedPmtTolAmount: Decimal;
    begin
        // Covers Test Case 124090.
        // Check Vendor Ledger Entry for Payment Tolerance after posting Purchase Credit Memo and Copy Document with Only Line.

        // Setup: Update General Ledger Setup and Create and Post Purchase invoice and take a Random quantity.
        Initialize();
        LibraryPmtDiscSetup.SetPmtTolerance(5);
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Invoice, CreateVendor());
        PurchaseHeader.Validate("Vendor Invoice No.", PurchaseHeader."No.");
        PurchaseHeader.Validate("Payment Discount %", LibraryRandom.RandInt(5)); // Use Random value for Payment Discount.
        PurchaseHeader.Modify(true);
        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, CreateItem(),
          LibraryRandom.RandInt(10));
        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, CreateItem(),
          LibraryRandom.RandInt(10));
        DocumentNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);
        LibraryPurchase.CreatePurchHeader(
          PurchaseHeader, PurchaseHeader."Document Type"::"Credit Memo", PurchaseHeader."Buy-from Vendor No.");
        PurchaseHeader.Validate("Vendor Cr. Memo No.", PurchaseHeader."No.");
        PurchaseHeader.Modify(true);

        // Exercise: Create and Post Purchase Credit Memo after Copy Document with Document Type Posted Invoice.
        LibraryPurchase.CopyPurchaseDocument(PurchaseHeader, "Purchase Document Type From"::"Posted Invoice", DocumentNo, false, true);
        DocumentNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);
        ExecuteUIHandler();  // Need to invoke confirmation message everytime to prevent test failures in ES build.

        // Verify: Verify Max Payment Tolerance field in Vendor Ledger Entry.
        ExpectedPmtTolAmount := CalcPaymentTolCreditMemoLCY(DocumentNo);
        VerifyMaxPaymentTolCreditMemo(DocumentNo, ExpectedPmtTolAmount);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure CreditMemoCopyDocumentOpenInv()
    var
        PurchaseHeader: Record "Purchase Header";
        DocumentNo: Code[20];
        ExpectedPmtTolAmount: Decimal;
    begin
        // Covers Test Case 124091.
        // Check Vendor Ledger Entry for Payment Tolerance after posting Purchase Credit Memo and Copy Document with Document Type Invoice.

        // Setup: Update General Ledger Setup and Create Purchase Invoice and Insert new record with Document Type Credit memo.
        Initialize();
        LibraryPmtDiscSetup.SetPmtTolerance(5);
        CreatePurchaseDocument(PurchaseHeader, '', PurchaseHeader."Document Type"::Invoice);
        PurchaseHeader.Validate("Vendor Invoice No.", PurchaseHeader."No.");
        PurchaseHeader.Validate("Payment Discount %", LibraryRandom.RandInt(5)); // Use Random value for Payment Discount.
        PurchaseHeader.Modify(true);
        PurchaseHeader.Init();
        PurchaseHeader.Validate("Document Type", PurchaseHeader."Document Type"::"Credit Memo");
        PurchaseHeader.Insert(true);

        // Exercise: Create and Post Purchase Credit Memo after Copy Document with Document Type Invoice.
        LibraryPurchase.CopyPurchaseDocument(PurchaseHeader, "Purchase Document Type From"::Invoice, PurchaseHeader."No.", true, true);
        PurchaseHeader.SetRange("Document Type", PurchaseHeader."Document Type"::"Credit Memo");
        PurchaseHeader.SetRange("No.", PurchaseHeader."No.");
        PurchaseHeader.FindFirst();
        PurchaseHeader.Validate("Vendor Cr. Memo No.", PurchaseHeader."No.");
        PurchaseHeader.Modify(true);
        DocumentNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);
        ExecuteUIHandler();  // Need to invoke confirmation message everytime to prevent test failures in ES build.

        // Verify: Verify Max Payment Tolerance field in Vendor Ledger Entry.
        ExpectedPmtTolAmount := CalcPaymentTolCreditMemoLCY(DocumentNo);
        VerifyMaxPaymentTolCreditMemo(DocumentNo, ExpectedPmtTolAmount);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure PaymentJournaWithDeferralCodeFromPurchaseJournal()
    var
        GenJournalLine: Record "Gen. Journal Line";
        DeferralTemplate: Record "Deferral Template";
        DeferralCode: Code[10];
    begin
        Initialize();

        // [GIVEN] deferral template with equal per period method
        DeferralCode := CreateDeferralTemplate(
            DeferralTemplate."Calc. Method"::"Equal per Period",
            DeferralTemplate."Start Date"::"Posting Date", LibraryRandom.RandIntInRange(2, 5), LibraryUtility.GenerateGUID(), 100);

        // [GIVEN] PurchaseJournal line with Vendor as Bal. Account 
        CreatePurchJnlLineWithVendorBalAcc(GenJournalLine);

        // [GIVEN] PurchaseJournal line with Deferral Code
        GenJournalLine.Validate("Deferral Code", DeferralCode);
        GenJournalLine.Modify();

        // [WHEN] [THEN] Post PurchaseJournal
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure PaymentJournaWithDeferralCodeFromPurchaseJournalNotValid()
    var
        GenJournalLine: Record "Gen. Journal Line";
        DeferralTemplate: Record "Deferral Template";
        SourceCodeSetup: Record "Source Code Setup";
        DeferralCode: Code[10];
        SameSourceCodeErr: Label 'Journal Source Code %1 is same as Source Code set for Purchase/Sales documents. This is not allowed when using deferrals. If you want to use this journal for deferrals, please update Source Codes on Gen Journal Template and generate line again.', Comment = '%1->Source Code';
    begin
        Initialize();

        // [GIVEN] deferral template with equal per period method
        DeferralCode := CreateDeferralTemplate(
            DeferralTemplate."Calc. Method"::"Equal per Period",
            DeferralTemplate."Start Date"::"Posting Date", LibraryRandom.RandIntInRange(2, 5), LibraryUtility.GenerateGUID(), 100);

        // [GIVEN] PurchaseJournal line with Vendor as Bal. Account 
        CreatePurchJnlLineWithVendorBalAcc(GenJournalLine);

        // [WHEN] Source Code on the line is same like for Purchase documents
        SourceCodeSetup.Get();
        GenJournalLine."Source Code" := SourceCodeSetup.Purchases;

        // [THEN] Error should occur
        asserterror GenJournalLine.Validate("Deferral Code", DeferralCode);
        Assert.ExpectedError(StrSubstNo(SameSourceCodeErr, GenJournalLine."Source Code"));
    end;

    local procedure CreatePurchJnlLineWithVendorBalAcc(var GenJournalLine: Record "Gen. Journal Line")
    var
        GenJournalTemplate: Record "Gen. Journal Template";
        GenJournalBatch: Record "Gen. Journal Batch";
        Vendor: Record Vendor;
    begin
        LibraryERM.CreateGenJournalTemplate(GenJournalTemplate);
        if GenJournalTemplate.Type <> Enum::"Gen. Journal Template Type"::Purchases then begin
            GenJournalTemplate.Validate("Type", Enum::"Gen. Journal Template Type"::Purchases);
            GenJournalTemplate.Modify(true);
        end;

        LibraryERM.CreateGenJournalBatch(GenJournalBatch, GenJournalTemplate.Name);
        LibraryERM.CreateGeneralJnlLine(
          GenJournalLine, GenJournalTemplate.Name, GenJournalBatch.Name, GenJournalLine."Document Type"::Payment,
          GenJournalLine."Account Type"::"G/L Account", LibraryERM.CreateGLAccountWithPurchSetup(), LibraryRandom.RandDecInRange(10, 1000, 2));
        LibraryPurchase.CreateVendor(Vendor);
        GenJournalLine.Validate("Bal. Account Type", GenJournalLine."Bal. Account Type"::Vendor);
        GenJournalLine.Validate("Bal. Account No.", Vendor."No.");
        GenJournalLine.Validate(Amount, -GenJournalLine.Amount);
        if GenJournalLine."Source Code" <> GenJournalTemplate."Source Code" then
            GenJournalLine."Source Code" := GenJournalTemplate."Source Code";
        GenJournalLine.Modify(true);
    end;

    procedure CreateDeferralTemplate(CalcMethod: Enum "Deferral Calculation Method"; StartDate: Enum "Deferral Calculation Start Date"; NumOfPeriods: Integer; PeriodDescription: Text[50]; DeferralPct: Decimal): Code[10]
    var
        DeferralTemplate: Record "Deferral Template";
    begin
        LibraryERM.CreateDeferralTemplate(DeferralTemplate, CalcMethod, StartDate, NumOfPeriods);
        DeferralTemplate.Validate("Period Description", PeriodDescription);
        DeferralTemplate.Validate("Deferral %", DeferralPct);
        DeferralTemplate.Modify(true);
        exit(DeferralTemplate."Deferral Code");
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    procedure PurchaseInvoiceWithDeferralEUReverseChargeVAT()
    var
        GeneralPostingSetup: Record "General Posting Setup";
        PurchasePayableSetup: Record "Purchases & Payables Setup";
        DeferralTemplate: Record "Deferral Template";
        VATPostingSetup: Record "VAT Posting Setup";
        Vendor: Record Vendor;
        GLAccount: Record "G/L Account";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        DeferralCode: Code[10];
        InvoiceNo: Code[20];
    begin
        // [SCENARIO 579751] The VAT Entry table with filter <Entry No.: 0..1000, G/L Account No''> must not contain records." error if you try to SET G/L acc. in the VAT Entry created from a Purchase Invoice with Deferrals and Discounts & its VAT Amount is zero in the G/L Entry.
        Initialize();

        // [GIVEN] Create General Posting Setup
        LibraryERM.CreateGeneralPostingSetupInvt(GeneralPostingSetup);

        // [GIVEN] Set Discount Posting to No Discount
        PurchasePayableSetup.Get();
        PurchasePayableSetup."Discount Posting" := PurchasePayableSetup."Discount Posting"::"No Discounts";
        PurchasePayableSetup.Modify(true);

        // [GIVEN] Create Reverse Charge VAT Posting Setup 
        LibraryERM.CreateVATPostingSetupWithAccounts(VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Reverse Charge VAT", 25);
        VATPostingSetup.Validate("Reverse Chrg. VAT Acc.", LibraryERM.CreateGLAccountNo());
        VATPostingSetup.Modify(true);

        // [GIVEN] Create Deferral Template (100%, Straight-Line, Begin. of Period, 2 periods)
        DeferralCode := CreateDeferralTemplate(DeferralTemplate."Calc. Method"::"Straight-Line",
            DeferralTemplate."Start Date"::"Beginning of Period", 2, 'Test Deferral', 100);

        // [GIVEN] Create EU Vendor with EU Posting Types
        LibraryPurchase.CreateVendor(Vendor);
        Vendor.Validate("Gen. Bus. Posting Group", GeneralPostingSetup."Gen. Bus. Posting Group");
        Vendor.Validate("VAT Bus. Posting Group", VATPostingSetup."VAT Bus. Posting Group");
        Vendor.Modify(true);

        // [GIVEN] Create GL Account with VAT Prod. Posting Group = VAT25
        LibraryERM.CreateGLAccount(GLAccount);
        GLAccount.Validate("Gen. Prod. Posting Group", GeneralPostingSetup."Gen. Prod. Posting Group");
        GLAccount.Validate("VAT Prod. Posting Group", VATPostingSetup."VAT Prod. Posting Group");
        GLAccount.Modify(true);

        // [GIVEN] Create Purchase Invoice for EU Vendor and GL Account
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Invoice, Vendor."No.");
        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::"G/L Account", GLAccount."No.", 1);
        PurchaseLine.Validate("Direct Unit Cost", 120);
        PurchaseLine.Validate("Line Discount %", 20);
        PurchaseLine.Validate("Deferral Code", DeferralCode);
        PurchaseLine.Modify(true);

        // [WHEN] Post the purchase Invoice
        InvoiceNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        // [THEN] Verify GL Entry VAT Entry Link table with G/L Entry No. field not populated with 0 value
        VerifyGLEntryVATEntryLink(InvoiceNo);
    end;

    local procedure Initialize()
    var
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"ERM Payment Tolerance Purchase");
        LibrarySetupStorage.Restore();
        ExecuteUIHandler();  // Need to invoke confirmation message everytime to prevent test failures in ES build.

        // Setup demo data.
        if isInitialized then
            exit;

        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"ERM Payment Tolerance Purchase");
        LibraryERMCountryData.CreateVATData();
        LibraryERMCountryData.CreateGeneralPostingSetupData();
        LibraryERMCountryData.UpdateGeneralPostingSetup();
        LibraryERMCountryData.UpdateGeneralLedgerSetup();
        LibraryERMCountryData.UpdatePurchasesPayablesSetup();
        isInitialized := true;
        Commit();
        LibrarySetupStorage.Save(DATABASE::"General Ledger Setup");
        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"ERM Payment Tolerance Purchase");
    end;

    local procedure CreateAndPostPurchaseDocument(CurrencyCode: Code[10]; DocType: Enum "Purchase Document Type"): Code[20]
    var
        PurchaseHeader: Record "Purchase Header";
    begin
        // Setup: Update General Ledger Setup and Create Purchase Document.
        Initialize();
        LibraryPmtDiscSetup.SetPmtTolerance(5);
        CreatePurchaseDocument(PurchaseHeader, CurrencyCode, DocType);

        // Exercise: Post Purchase Document.
        exit(LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true));
    end;

    local procedure CreateCurrency(): Code[10]
    var
        Currency: Record Currency;
    begin
        // Use Random value for Payment Tolerance and Max Payment Tolerance Amount.
        LibraryERM.CreateCurrency(Currency);
        LibraryERM.SetCurrencyGainLossAccounts(Currency);
        Currency.Validate("Payment Tolerance %", LibraryRandom.RandInt(5));
        Currency.Validate("Max. Payment Tolerance Amount", LibraryRandom.RandInt(5));
        Currency.Modify(true);
        LibraryERM.CreateRandomExchangeRate(Currency.Code);
        exit(Currency.Code);
    end;

    local procedure CreateVendor(): Code[20]
    var
        Vendor: Record Vendor;
        PaymentTerms: Record "Payment Terms";
    begin
        // Find Payment Terms Code and Update.
        LibraryERM.GetDiscountPaymentTerm(PaymentTerms);
        PaymentTerms.Validate("Calc. Pmt. Disc. on Cr. Memos", true);
        PaymentTerms.Modify(true);
        LibraryPurchase.CreateVendor(Vendor);
        Vendor.Validate("Payment Terms Code", PaymentTerms.Code);
        Vendor.Validate("Application Method", Vendor."Application Method"::Manual);
        Vendor.Validate("Block Payment Tolerance", false);
        Vendor.Modify(true);
        exit(Vendor."No.");
    end;

    local procedure CreateItem(): Code[20]
    var
        Item: Record Item;
    begin
        LibraryInventory.CreateItem(Item);
        // Cost should be small enough to not make a document exceed Max. Payment Tolerance
        Item.Validate("Last Direct Cost", LibraryRandom.RandInt(7));
        Item.Modify(true);
        exit(Item."No.");
    end;

    local procedure CreatePurchaseDocument(var PurchaseHeader: Record "Purchase Header"; CurrencyCode: Code[10]; DocumentType: Enum "Purchase Document Type")
    var
        PurchaseLine: Record "Purchase Line";
        Counter: Integer;
    begin
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, DocumentType, CreateVendor());
        PurchaseHeader.Validate("Currency Code", CurrencyCode);
        PurchaseHeader.Validate("Vendor Cr. Memo No.", PurchaseHeader."No.");
        PurchaseHeader.Validate("Vendor Invoice No.", PurchaseHeader."No.");
        PurchaseHeader.Modify(true);

        // Use Counter for Creating Multiple Purchase Lines with Random Quantity.
        for Counter := 1 to LibraryRandom.RandInt(3) do begin
            LibraryPurchase.CreatePurchaseLine(
              PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, CreateItem(), LibraryRandom.RandInt(3));
            if DocumentType = PurchaseLine."Document Type"::"Credit Memo" then begin
                PurchaseLine.Validate("Qty. to Receive", 0); // Quantity to Receive must be 0 for Purchase Credit Memo.
                PurchaseLine.Modify(true);
            end;
        end;
    end;

    local procedure FindVendorLedgerEntry(var VendorLedgerEntry: Record "Vendor Ledger Entry"; DocumentNo: Code[20])
    begin
        VendorLedgerEntry.SetRange("Document No.", DocumentNo);
        VendorLedgerEntry.FindFirst();
        VendorLedgerEntry.CalcFields(Amount);
    end;

    local procedure CalcPaymentTolInvoiceFCY(DocumentNo: Code[20]): Decimal
    var
        Currency: Record Currency;
        PurchInvHeader: Record "Purch. Inv. Header";
    begin
        PurchInvHeader.Get(DocumentNo);
        PurchInvHeader.CalcFields("Amount Including VAT");
        Currency.Get(PurchInvHeader."Currency Code");
        exit(PurchInvHeader."Amount Including VAT" * Currency."Payment Tolerance %" / 100);
    end;

    local procedure CalcPaymentTolInvoiceLCY(DocumentNo: Code[20]): Decimal
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
        PurchInvHeader: Record "Purch. Inv. Header";
    begin
        GeneralLedgerSetup.Get();
        PurchInvHeader.Get(DocumentNo);
        PurchInvHeader.CalcFields("Amount Including VAT");
        exit(PurchInvHeader."Amount Including VAT" * GeneralLedgerSetup."Payment Tolerance %" / 100);
    end;

    local procedure CalcPaymentTolCreditMemoLCY(DocumentNo: Code[20]): Decimal
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
        PurchCrMemoHdr: Record "Purch. Cr. Memo Hdr.";
    begin
        GeneralLedgerSetup.Get();
        PurchCrMemoHdr.Get(DocumentNo);
        PurchCrMemoHdr.CalcFields("Amount Including VAT");
        exit(PurchCrMemoHdr."Amount Including VAT" * GeneralLedgerSetup."Payment Tolerance %" / 100);
    end;

    local procedure VerifyVendorLedgerEntry(Amount: Decimal; DocumentNo: Code[20])
    var
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        GeneralLedgerSetup: Record "General Ledger Setup";
    begin
        GeneralLedgerSetup.Get();
        FindVendorLedgerEntry(VendorLedgerEntry, DocumentNo);
        Assert.AreNearlyEqual(Amount, VendorLedgerEntry.Amount, GeneralLedgerSetup."Amount Rounding Precision",
          StrSubstNo(AmountErrorMessage, VendorLedgerEntry.FieldCaption(Amount), Amount, VendorLedgerEntry.TableCaption(),
            VendorLedgerEntry.FieldCaption("Entry No."), VendorLedgerEntry."Entry No."));
    end;

    local procedure VerifyMaxPaymentTolInvoice(DocumentNo: Code[20]; ExpectedPmtTolAmount: Decimal)
    var
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        GeneralLedgerSetup: Record "General Ledger Setup";
    begin
        GeneralLedgerSetup.Get();
        FindVendorLedgerEntry(VendorLedgerEntry, DocumentNo);
        Assert.AreNearlyEqual(-ExpectedPmtTolAmount, VendorLedgerEntry."Max. Payment Tolerance",
          GeneralLedgerSetup."Amount Rounding Precision", StrSubstNo(AmountErrorMessage, VendorLedgerEntry.FieldCaption(Amount),
            ExpectedPmtTolAmount, VendorLedgerEntry.TableCaption(), VendorLedgerEntry.FieldCaption("Entry No."), VendorLedgerEntry."Entry No."));
    end;

    local procedure VerifyMaxPaymentTolCreditMemo(DocumentNo: Code[20]; ExpectedPmtTolAmount: Decimal)
    var
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        GeneralLedgerSetup: Record "General Ledger Setup";
    begin
        GeneralLedgerSetup.Get();
        FindVendorLedgerEntry(VendorLedgerEntry, DocumentNo);
        Assert.AreNearlyEqual(ExpectedPmtTolAmount, VendorLedgerEntry."Max. Payment Tolerance",
          GeneralLedgerSetup."Amount Rounding Precision", StrSubstNo(AmountErrorMessage, VendorLedgerEntry.FieldCaption(Amount),
            ExpectedPmtTolAmount, VendorLedgerEntry.TableCaption(), VendorLedgerEntry.FieldCaption("Entry No."), VendorLedgerEntry."Entry No."));
    end;

    local procedure VerifyGLEntryVATEntryLink(InvoiceNo: Code[20])
    var
        GLEntryVATEntryLink: Record "G/L Entry - VAT Entry Link";
        VATEntry: Record "VAT Entry";
        GLEntry: Record "G/L Entry";
    begin
        VATEntry.SetRange("Document No.", InvoiceNo);
        VATEntry.FindFirst();

        GLEntryVATEntryLink.SetRange("VAT Entry No.", VATEntry."Entry No.");
        GLEntryVATEntryLink.FindFirst();

        GLEntry.Get(GLEntryVATEntryLink."G/L Entry No.");
        Assert.IsTrue(GLEntry.Amount <> 0, 'G/L Entry Amount is zero for VAT Entry No. ' + Format(VATEntry."Entry No."));
    end;

    local procedure ExecuteUIHandler()
    begin
        // Generate Dummy message. Required for executing the test case successfully.
        if Confirm(StrSubstNo(ExpectedMessage)) then;
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandler(Question: Text[1024]; var Reply: Boolean)
    begin
        Reply := true;
    end;
}

