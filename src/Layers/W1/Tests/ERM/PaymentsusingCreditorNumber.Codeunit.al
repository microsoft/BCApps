codeunit 134160 "Payments using Creditor Number"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Creditor] [Purchase]
        IsInitialized := false;
    end;

    var
        Assert: Codeunit Assert;
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        LibraryERM: Codeunit "Library - ERM";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibrarySales: Codeunit "Library - Sales";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
        LibraryRandom: Codeunit "Library - Random";
        NotFoundErr: Label '%1 was not found.';
        LibrarySetupStorage: Codeunit "Library - Setup Storage";
        IsInitialized: Boolean;

    [Test]
    [Scope('OnPrem')]
    procedure ApplyPurchInvWithCreditorInfoAuto()
    var
        GenJnlBatch: Record "Gen. Journal Batch";
        GenJnlLine: Record "Gen. Journal Line";
        PmtGenJnlBatch: Record "Gen. Journal Batch";
        PmtGenJnlLine: Record "Gen. Journal Line";
        Vendor: Record Vendor;
        PaymentMethod: Record "Payment Method";
        CreditorNo: Code[8];
        PaymentReference: Code[16];
    begin
        Initialize();

        // Pre-Setup
        LibraryPurchase.CreateVendor(Vendor);
        LibraryERM.SelectGenJnlBatch(GenJnlBatch);
        LibraryERM.CreateGeneralJnlLine(GenJnlLine,
          GenJnlBatch."Journal Template Name", GenJnlBatch.Name, GenJnlLine."Document Type"::Invoice,
          GenJnlLine."Account Type"::Vendor, Vendor."No.", -1 * LibraryRandom.RandDec(1000, 2));

        // Setup
        CreditorNo := AddCreditorNoOnGenJnlLine(GenJnlLine);
        PaymentReference := AddPaymentReferenceOnGenJnlLine(GenJnlLine);
        LibraryERM.PostGeneralJnlLine(GenJnlLine);

        // Exercise
        LibraryPurchase.SelectPmtJnlBatch(PmtGenJnlBatch);
        LibraryERM.CreatePaymentMethod(PaymentMethod);
        Vendor."Payment Method Code" := PaymentMethod.Code;
        Vendor.Modify(true);
        Vendor.SetRange("No.", Vendor."No.");
        SuggestVendorPayments(Vendor, PmtGenJnlBatch);

        // Verify
        FindGenJnlLine(PmtGenJnlLine, PmtGenJnlBatch, PmtGenJnlLine."Account Type"::Vendor, Vendor."No.");
        PmtGenJnlLine.TestField("Payment Method Code", GetPmtMethodCodeFromVendorLedgerEntry(Vendor."No."));
        PmtGenJnlLine.TestField("Creditor No.", CreditorNo);
        PmtGenJnlLine.TestField("Payment Reference", PaymentReference);
    end;

    [Test]
    [HandlerFunctions('ApplyVendorEntriesPageHandler')]
    [Scope('OnPrem')]
    procedure ApplyPurchInvWithCreditorInfoManual()
    var
        GenJnlBatch: Record "Gen. Journal Batch";
        GenJnlLine: Record "Gen. Journal Line";
        PmtGenJnlBatch: Record "Gen. Journal Batch";
        PmtGenJnlLine: Record "Gen. Journal Line";
        Vendor: Record Vendor;
        PaymentJournal: TestPage "Payment Journal";
    begin
        Initialize();

        // Pre-Setup
        LibraryPurchase.CreateVendor(Vendor);
        LibraryERM.SelectGenJnlBatch(GenJnlBatch);
        LibraryERM.CreateGeneralJnlLine(GenJnlLine,
          GenJnlBatch."Journal Template Name", GenJnlBatch.Name, GenJnlLine."Document Type"::Invoice,
          GenJnlLine."Account Type"::Vendor, Vendor."No.", -1 * LibraryRandom.RandDec(1000, 2));
        AddCreditorNoOnGenJnlLine(GenJnlLine);
        AddPaymentReferenceOnGenJnlLine(GenJnlLine);
        LibraryERM.PostGeneralJnlLine(GenJnlLine);

        // Setup
        LibraryPurchase.SelectPmtJnlBatch(PmtGenJnlBatch);
        LibraryERM.CreateGeneralJnlLine(PmtGenJnlLine,
          PmtGenJnlBatch."Journal Template Name", PmtGenJnlBatch.Name, PmtGenJnlLine."Document Type"::Payment,
          PmtGenJnlLine."Account Type"::Vendor, Vendor."No.", 0);

        // Exercise
        PaymentJournal.OpenEdit();
        PaymentJournal.CurrentJnlBatchName.Value := PmtGenJnlLine."Journal Batch Name";
        PaymentJournal.GotoRecord(PmtGenJnlLine);
        PaymentJournal.ApplyEntries.Invoke();
        PaymentJournal.Close();

        // Verify
        FindGenJnlLine(PmtGenJnlLine, PmtGenJnlBatch, PmtGenJnlLine."Account Type"::Vendor, Vendor."No.");
        PmtGenJnlLine.TestField("Applies-to ID", PmtGenJnlLine."Document No.");
        PmtGenJnlLine.TestField("Payment Method Code", GenJnlLine."Payment Method Code");
        PmtGenJnlLine.TestField("Creditor No.", '');
        PmtGenJnlLine.TestField("Payment Reference", '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CreateVendorWithValidCreditorNo()
    var
        Vendor: Record Vendor;
    begin
        Initialize();

        // Setup
        LibraryPurchase.CreateVendor(Vendor);

        // Exercise
        Vendor.Validate("Creditor No.", Format(LibraryRandom.RandIntInRange(11111111, 99999999)));

        // Verify
        // No errors occur!
    end;

    [Test]
    [Scope('OnPrem')]
    procedure EditPurchInvoiceCreditorInfo()
    var
        PurchHeader: Record "Purchase Header";
        Vendor: Record Vendor;
        PurchaseInvoice: TestPage "Purchase Invoice";
        NewCreditorNo: Code[8];
        NewPaymentRef: Code[16];
    begin
        Initialize();

        // Pre-Setup
        CreateVendorWithCreditorNo(Vendor);

        // Setup
        LibraryPurchase.CreatePurchHeader(PurchHeader, PurchHeader."Document Type"::Invoice, Vendor."No.");

        // Pre-Exercise
        NewCreditorNo := Format(LibraryRandom.RandIntInRange(11111111, 99999999));
        NewPaymentRef := GetRandomPaymentReference();

        // Exercise
        PurchaseInvoice.OpenEdit();
        PurchaseInvoice.GotoRecord(PurchHeader);
        PurchaseInvoice."Creditor No.".Value := NewCreditorNo;
        PurchaseInvoice."Payment Reference".Value := NewPaymentRef;
        PurchaseInvoice.OK().Invoke();

        // Verify
        VerifyCreditorInfoOnPurchInvoice(Vendor."No.", NewCreditorNo, NewPaymentRef);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure EditVendorLedgerEntryCreditorInfo()
    var
        GenJnlBatch: Record "Gen. Journal Batch";
        GenJnlLine: Record "Gen. Journal Line";
        Vendor: Record Vendor;
        VendorLedgerEntry: Record "Vendor Ledger Entry";
    begin
        Initialize();

        // Pre-Setup
        CreateVendorWithCreditorNo(Vendor);
        LibraryERM.SelectGenJnlBatch(GenJnlBatch);
        LibraryERM.CreateGeneralJnlLine(GenJnlLine,
          GenJnlBatch."Journal Template Name", GenJnlBatch.Name, GenJnlLine."Document Type"::Invoice,
          GenJnlLine."Account Type"::Vendor, Vendor."No.", -1 * LibraryRandom.RandDec(1000, 2));
        LibraryERM.PostGeneralJnlLine(GenJnlLine);

        // Setup
        VendorLedgerEntry.SetRange("Vendor No.", Vendor."No.");
        VendorLedgerEntry.SetRange("Document Type", VendorLedgerEntry."Document Type"::Invoice);
        VendorLedgerEntry.FindLast();

        // Pre-Exercise
        VendorLedgerEntry.Open := false;
        VendorLedgerEntry.Modify();

        // Exercise
        VendorLedgerEntry.Validate("Payment Reference", GetRandomPaymentReference());

        // Verify
        // No errors occur!
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostGenJnlLineForVendorWithCreditorNo()
    var
        GenJnlBatch: Record "Gen. Journal Batch";
        GenJnlLine: Record "Gen. Journal Line";
        Vendor: Record Vendor;
    begin
        Initialize();

        // Pre-Setup
        CreateVendorWithCreditorNo(Vendor);
        LibraryERM.SelectGenJnlBatch(GenJnlBatch);

        // Setup
        LibraryERM.CreateGeneralJnlLine(GenJnlLine,
          GenJnlBatch."Journal Template Name", GenJnlBatch.Name, GenJnlLine."Document Type"::Invoice,
          GenJnlLine."Account Type"::Vendor, Vendor."No.", -1 * LibraryRandom.RandDec(1000, 2));

        // Exercise
        LibraryERM.PostGeneralJnlLine(GenJnlLine);

        // Verify
        VerifyCreditorInfoOnVendorLedgerEntry(Vendor, '', GenJnlLine."Payment Method Code");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostGenJnlLineForVendorWithPaymentRef()
    var
        GenJnlBatch: Record "Gen. Journal Batch";
        GenJnlLine: Record "Gen. Journal Line";
        Vendor: Record Vendor;
        PaymentReference: Code[16];
    begin
        Initialize();

        // Pre-Setup
        CreateVendorWithCreditorNo(Vendor);
        LibraryERM.SelectGenJnlBatch(GenJnlBatch);

        // Setup
        LibraryERM.CreateGeneralJnlLine(GenJnlLine,
          GenJnlBatch."Journal Template Name", GenJnlBatch.Name, GenJnlLine."Document Type"::Invoice,
          GenJnlLine."Account Type"::Vendor, Vendor."No.", -1 * LibraryRandom.RandDec(1000, 2));
        PaymentReference := AddPaymentReferenceOnGenJnlLine(GenJnlLine);

        // Exercise
        LibraryERM.PostGeneralJnlLine(GenJnlLine);

        // Verify
        VerifyCreditorInfoOnVendorLedgerEntry(Vendor, PaymentReference, GenJnlLine."Payment Method Code");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostPurchInvForVendorWithCreditorNo()
    var
        Item: Record Item;
        PurchHeader: Record "Purchase Header";
        PurchLine: Record "Purchase Line";
        Vendor: Record Vendor;
        PurchasesPayablesSetup: Record "Purchases & Payables Setup";
    begin
        // [FEATURE] [Payment Reference]
        Initialize();

        // Pre-Setup
        CreateVendorWithCreditorNo(Vendor);
        LibraryInventory.CreateItem(Item);
        // BUG 362612: Copy Vendor Invoice No. to Payment Reference field
        PurchasesPayablesSetup.Get();
        PurchasesPayablesSetup.Validate("Copy Inv. No. To Pmt. Ref.", false);
        PurchasesPayablesSetup.Modify(true);

        // Setup
        LibraryPurchase.CreatePurchHeader(PurchHeader, PurchHeader."Document Type"::Invoice, Vendor."No.");
        LibraryPurchase.CreatePurchaseLine(PurchLine, PurchHeader, PurchLine.Type::Item, Item."No.", LibraryRandom.RandInt(10));

        // Exercise
        LibraryPurchase.PostPurchaseDocument(PurchHeader, false, true);

        // Verify
        VerifyCreditorInfoOnPostedPurchInvoice(Vendor, '', PurchHeader."Payment Method Code");
        VerifyCreditorInfoOnVendorLedgerEntry(Vendor, '', PurchHeader."Payment Method Code");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostPurchInvForVendorWithVendInvNo()
    var
        Item: Record Item;
        PurchHeader: Record "Purchase Header";
        PurchLine: Record "Purchase Line";
        Vendor: Record Vendor;
        PurchasesPayablesSetup: Record "Purchases & Payables Setup";
    begin
        // [FEATURE] [Payment Reference]
        // [SCENARIO 362612] A "Vendor Invoice No." copies to the "Payment Reference" during purchase invoice posting
        // [SCENARIO 362612] when the "Copy Inv. No. To Pmt. Ref." option is enabled in Purchases & Payables Setup

        Initialize();

        // [GIVEN] "Copy Inv. No. To Pmt. Ref." is enabled in the Purchases & Payables Setup
        CreateVendorWithCreditorNo(Vendor);
        LibraryInventory.CreateItem(Item);
        PurchasesPayablesSetup.Get();
        PurchasesPayablesSetup.Validate("Copy Inv. No. To Pmt. Ref.", true);
        PurchasesPayablesSetup.Modify(true);

        // [GIVEN] Purchase Invoice
        LibraryPurchase.CreatePurchHeader(PurchHeader, PurchHeader."Document Type"::Invoice, Vendor."No.");
        LibraryPurchase.CreatePurchaseLine(PurchLine, PurchHeader, PurchLine.Type::Item, Item."No.", LibraryRandom.RandInt(10));

        // [WHEN] Post Purchase Invoice
        LibraryPurchase.PostPurchaseDocument(PurchHeader, false, true);

        // [THEN] "Vendor Invoice No." exists in the "Payment Reference" field of the Vendor Ledger Entry
        VerifyCreditorInfoOnVendorLedgerEntry(Vendor, PurchHeader."Vendor Invoice No.", PurchHeader."Payment Method Code");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostPurchInvForVendorWithPaymentRef()
    var
        Item: Record Item;
        PurchHeader: Record "Purchase Header";
        PurchLine: Record "Purchase Line";
        Vendor: Record Vendor;
        PaymentReference: Code[16];
    begin
        Initialize();

        // Pre-Setup
        CreateVendorWithCreditorNo(Vendor);
        LibraryInventory.CreateItem(Item);

        // Setup
        LibraryPurchase.CreatePurchHeader(PurchHeader, PurchHeader."Document Type"::Invoice, Vendor."No.");
        LibraryPurchase.CreatePurchaseLine(PurchLine, PurchHeader, PurchLine.Type::Item, Item."No.", LibraryRandom.RandInt(10));
        PaymentReference := AddPaymentReferenceOnPurchDoc(PurchHeader);

        // Exercise
        LibraryPurchase.PostPurchaseDocument(PurchHeader, false, true);

        // Verify
        VerifyCreditorInfoOnPostedPurchInvoice(Vendor, PaymentReference, PurchHeader."Payment Method Code");
        VerifyCreditorInfoOnVendorLedgerEntry(Vendor, PaymentReference, PurchHeader."Payment Method Code");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure UpdateVendorCardCreditorNo()
    var
        Vendor: Record Vendor;
        VendorCard: TestPage "Vendor Card";
        CreditorNo: Code[10];
        VendorNo: Code[20];
    begin
        Initialize();

        // Setup
        LibraryPurchase.CreateVendor(Vendor);

        // Post-Setup
        VendorNo := Vendor."No.";

        // Pre-Exercise
        CreditorNo := Format(LibraryRandom.RandIntInRange(11111111, 99999999));

        // Exercise
        VendorCard.OpenEdit();
        VendorCard.GotoRecord(Vendor);
        VendorCard."Creditor No.".Value := CreditorNo;
        VendorCard.OK().Invoke();

        // Verify
        Vendor.Get(VendorNo);
        Vendor.TestField("Creditor No.", CreditorNo);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure UpdatePurchaseOrderCreditorNoNumericOnlyDisabled()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseOrder: TestPage "Purchase Order";
        CreditorNo: Code[20];
    begin
        // [FEATURE] [UI]
        // [SCENARIO 275540] "Creditor No." allows non-numeric values on table "Purchase Header"

        Initialize();

        // [GIVEN] Purchase Header 'PO01' with "Document Type" = "Order"
        PurchaseHeader.Init();
        PurchaseHeader."Document Type" := PurchaseHeader."Document Type"::Order;
        PurchaseHeader."No." := LibraryUtility.GenerateGUID();
        PurchaseHeader.Insert();

        // [GIVEN] CreditorNo = 'ABC', non-numeric
        CreditorNo := CopyStr(LibraryUtility.GenerateRandomText(MaxStrLen(CreditorNo)), 1, MaxStrLen(CreditorNo));

        // [WHEN] Update field "Creditor No." on page "Purchase Order" for Purchase Header 'PO01' with CreditorNo
        PurchaseOrder.OpenEdit();
        PurchaseOrder.GotoRecord(PurchaseHeader);
        PurchaseOrder."Creditor No.".SetValue(CreditorNo);
        PurchaseOrder.Close();

        // [THEN] "Creditor No." = 'ABC' for Purchase Header 'PO01'
        PurchaseHeader.Find();
        PurchaseHeader.TestField("Creditor No.", CreditorNo);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure UpdateVendorLedgerEntriesCreditorNoNumericOnlyDisabled()
    var
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        VendorLedgerEntries: TestPage "Vendor Ledger Entries";
        CreditorNo: Code[20];
    begin
        // [FEATURE] [UI]
        // [SCENARIO 275540] "Creditor No." allows non-numeric values on table "Vendor Ledger Entry"

        Initialize();

        // [GIVEN] Vendor Ledger Entry 'X' created
        VendorLedgerEntry.Init();
        VendorLedgerEntry."Entry No." := LibraryUtility.GetNewRecNo(VendorLedgerEntry, VendorLedgerEntry.FieldNo("Entry No."));
        VendorLedgerEntry.Insert();

        // [GIVEN] CreditorNo = 'ABC', non-numeric
        CreditorNo := CopyStr(LibraryUtility.GenerateRandomText(MaxStrLen(CreditorNo)), 1, MaxStrLen(CreditorNo));

        // [WHEN] Update field "Creditor No." on page "Vendor Ledger Entries" for Vendor Ledger Entry 'X' with CreditorNo
        VendorLedgerEntries.OpenEdit();
        VendorLedgerEntries.GotoRecord(VendorLedgerEntry);
        VendorLedgerEntries."Creditor No.".SetValue(CreditorNo);
        VendorLedgerEntries.Close();

        // [THEN] "Creditor No." = 'ABC' for Vendor Ledger Entry 'X'
        VendorLedgerEntry.Find();
        VendorLedgerEntry.TestField("Creditor No.", CreditorNo);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure UpdatePostedPurchaseInvoiceNoNumericOnlyDisabled()
    var
        PurchInvHeader: Record "Purch. Inv. Header";
        PostedPurchaseInvoice: TestPage "Posted Purchase Invoice";
        CreditorNo: Code[20];
    begin
        // [FEATURE] [UI]
        // [SCENARIO 275540] "Creditor No." allows non-numeric values on table "Purchase Invoice Header"

        Initialize();

        // [GIVEN] Purchase Invoice Header 'PI01'
        PurchInvHeader.Init();
        PurchInvHeader."No." := LibraryUtility.GenerateGUID();
        PurchInvHeader.Insert();

        // [GIVEN] CreditorNo = 'ABC', non-numeric
        CreditorNo := CopyStr(LibraryUtility.GenerateRandomText(MaxStrLen(CreditorNo)), 1, MaxStrLen(CreditorNo));

        // [WHEN] Update field "Creditor No." on page "Posted Purchase Invoice" for Purchase Invoice Header 'PI01' with CreditorNo
        PostedPurchaseInvoice.OpenEdit();
        PostedPurchaseInvoice.GotoRecord(PurchInvHeader);
        PostedPurchaseInvoice."Creditor No.".SetValue(CreditorNo);
        PostedPurchaseInvoice.OK().Invoke();

        // [THEN] "Creditor No." = 'ABC' for Purchase Invoice Header 'PI01'
        PurchInvHeader.Find();
        PurchInvHeader.TestField("Creditor No.", CreditorNo);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure UpdateGenJnlLineNoNumericOnlyDisabled()
    var
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalLine: Record "Gen. Journal Line";
        PaymentJournal: TestPage "Payment Journal";
        CreditorNo: Code[20];
    begin
        // [FEATURE] [UI]
        // [SCENARIO 275540] "Creditor No." allows non-numeric values on table "Gen. Journal Line"

        Initialize();

        // [GIVEN] Gen. Journal Batch 'JB01' with "Journal Template Name" = 'PAYMENT'
        // [GIVEN] Gen. Journal Line 'JL01' with "Journal Template Name" = 'PAYMENT', "Journal Batch Name" = 'JB01'
        LibraryERM.CreateGenJournalBatch(GenJournalBatch, LibraryPurchase.SelectPmtJnlTemplate());
        MockPaymentGenJournalLine(GenJournalLine, GenJournalBatch);

        // [GIVEN] CreditorNo = 'ABC', non-numeric
        CreditorNo := CopyStr(LibraryUtility.GenerateRandomText(MaxStrLen(CreditorNo)), 1, MaxStrLen(CreditorNo));

        // [WHEN] Update field "Creditor No." on page "Payment Journal" for Gen. Journal Line 'JL01' with CreditorNo
        Commit();
        PaymentJournal.OpenEdit();
        PaymentJournal.CurrentJnlBatchName.SetValue(GenJournalLine."Journal Batch Name");
        PaymentJournal.GotoRecord(GenJournalLine);
        PaymentJournal."Creditor No.".SetValue(CreditorNo);
        PaymentJournal.Close();

        // [THEN] "Creditor No." = 'ABC' for Gen. Journal Line 'JL01'
        GenJournalLine.Find();
        GenJournalLine.TestField("Creditor No.", CreditorNo);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure UpdateVendorCardCreditorNoNumericOnlyDisabled()
    var
        Vendor: Record Vendor;
        VendorCard: TestPage "Vendor Card";
        CreditorNo: Code[20];
    begin
        // [FEATURE] [UI]
        // [SCENARIO 275540] "Creditor No." allows non-numeric values on table "Vendor"

        Initialize();

        // [GIVEN] Vendor 'X' created
        LibraryPurchase.CreateVendor(Vendor);

        // [GIVEN] CreditorNo = 'ABC', non-numeric
        CreditorNo := CopyStr(LibraryUtility.GenerateRandomText(MaxStrLen(CreditorNo)), 1, MaxStrLen(CreditorNo));

        // [WHEN] Update field "Creditor No." on page "Vendor Card" for Vendor 'X' with CreditorNo
        VendorCard.OpenEdit();
        VendorCard.GotoRecord(Vendor);
        VendorCard."Creditor No.".SetValue(CreditorNo);
        VendorCard.OK().Invoke();

        // [THEN] "Creditor No." = 'ABC' for Vendor 'X'
        Vendor.Find();
        Vendor.TestField("Creditor No.", CreditorNo);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostGenJnlLineForCustomerPaymentMethod()
    var
        GenJnlBatch: Record "Gen. Journal Batch";
        GenJnlLine: Record "Gen. Journal Line";
        Customer: Record Customer;
    begin
        Initialize();

        // Pre-Setup
        LibrarySales.CreateCustomer(Customer);
        LibraryERM.SelectGenJnlBatch(GenJnlBatch);

        // Setup
        LibraryERM.CreateGeneralJnlLine(GenJnlLine,
          GenJnlBatch."Journal Template Name", GenJnlBatch.Name, GenJnlLine."Document Type"::Invoice,
          GenJnlLine."Account Type"::Customer, Customer."No.", LibraryRandom.RandDec(1000, 2));
        GenJnlLine.TestField("Payment Method Code", Customer."Payment Method Code");
        // Exercise
        LibraryERM.PostGeneralJnlLine(GenJnlLine);

        // Verify
        VerifyPaymentMethodCodeonCustLedgerEntry(Customer, GenJnlLine."Payment Method Code");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostSalesInvForCustPaymentMethod()
    var
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        Customer: Record Customer;
    begin
        Initialize();

        // Pre-Setup
        LibrarySales.CreateCustomer(Customer);
        LibraryInventory.CreateItem(Item);

        // Setup
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Invoice, Customer."No.");
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, Item."No.", LibraryRandom.RandInt(10));

        // Exercise
        LibrarySales.PostSalesDocument(SalesHeader, false, true);

        // Verify
        VerifyPaymentMethodOnPostedSalesInv(Customer, SalesHeader."Payment Method Code");
        VerifyPaymentMethodCodeonCustLedgerEntry(Customer, SalesHeader."Payment Method Code");
    end;

    local procedure Initialize()
    begin
        LibrarySetupStorage.Restore();
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"Payments using Creditor Number");
        if IsInitialized then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"Payments using Creditor Number");

        LibraryERMCountryData.CreateVATData();
        LibraryERMCountryData.UpdateGeneralPostingSetup();
        LibrarySetupStorage.SavePurchasesSetup();
        IsInitialized := true;
        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"Payments using Creditor Number");
    end;

    local procedure MockPaymentGenJournalLine(var GenJournalLine: Record "Gen. Journal Line"; GenJournalBatch: Record "Gen. Journal Batch")
    begin
        GenJournalLine.Init();
        GenJournalLine."Journal Template Name" := GenJournalBatch."Journal Template Name";
        GenJournalLine."Journal Batch Name" := GenJournalBatch.Name;
        GenJournalLine."Line No." := GenJournalLine.GetNewLineNo(GenJournalBatch."Journal Template Name", GenJournalBatch.Name);
        GenJournalLine.Insert();
    end;

    local procedure AddCreditorNoOnGenJnlLine(var GenJnlLine: Record "Gen. Journal Line") CreditorNo: Code[8]
    begin
        CreditorNo := Format(LibraryRandom.RandIntInRange(11111111, 99999999));
        GenJnlLine.Validate("Creditor No.", CreditorNo);
        GenJnlLine.Modify(true);
    end;

    local procedure AddPaymentReferenceOnGenJnlLine(var GenJnlLine: Record "Gen. Journal Line") PaymentReference: Code[16]
    begin
        PaymentReference := GetRandomPaymentReference();
        GenJnlLine.Validate("Payment Reference", PaymentReference);
        GenJnlLine.Modify(true);
    end;

    local procedure AddPaymentReferenceOnPurchDoc(var PurchHeader: Record "Purchase Header") PaymentReference: Code[16]
    begin
        PaymentReference := GetRandomPaymentReference();
        PurchHeader.Validate("Payment Reference", PaymentReference);
        PurchHeader.Modify(true);
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ApplyVendorEntriesPageHandler(var ApplyVendorEntries: TestPage "Apply Vendor Entries")
    begin
        ApplyVendorEntries.ActionSetAppliesToID.Invoke();
        ApplyVendorEntries.OK().Invoke();
    end;

    local procedure CreateVendorWithCreditorNo(var Vendor: Record Vendor)
    begin
        LibraryPurchase.CreateVendor(Vendor);
        Vendor.Validate("Creditor No.", Format(LibraryRandom.RandIntInRange(11111111, 99999999)));
        Vendor.Modify(true);
    end;

    local procedure FindGenJnlLine(var GenJnlLine: Record "Gen. Journal Line"; GenJnlBatch: Record "Gen. Journal Batch"; AccountType: Enum "Gen. Journal Account Type"; AccountNo: Code[20])
    begin
        GenJnlLine.SetRange("Journal Template Name", GenJnlBatch."Journal Template Name");
        GenJnlLine.SetRange("Journal Batch Name", GenJnlBatch.Name);
        GenJnlLine.SetRange("Account Type", AccountType);
        GenJnlLine.SetRange("Account No.", AccountNo);
        GenJnlLine.FindLast();
    end;

    local procedure GetPmtMethodCodeFromVendorLedgerEntry(VendorNo: Code[20]): Code[10]
    var
        VendorLedgerEntry: Record "Vendor Ledger Entry";
    begin
        VendorLedgerEntry.SetRange("Vendor No.", VendorNo);
        VendorLedgerEntry.SetRange("Document Type", VendorLedgerEntry."Document Type"::Invoice);
        VendorLedgerEntry.FindLast();
        exit(VendorLedgerEntry."Payment Method Code");
    end;

    local procedure GetRandomPaymentReference(): Code[16]
    var
        RefNo: Integer;
    begin
        RefNo := LibraryRandom.RandIntInRange(11111111, 99999999);
        exit(StrSubstNo('%1%2', RefNo, RefNo));
    end;

    local procedure SuggestVendorPayments(var Vendor: Record Vendor; GenJnlBatch: Record "Gen. Journal Batch")
    var
        GenJnlLine: Record "Gen. Journal Line";
        SuggestVendorPayments: Report "Suggest Vendor Payments";
    begin
        GenJnlLine.Init();
        GenJnlLine.Validate("Journal Template Name", GenJnlBatch."Journal Template Name");
        GenJnlLine.Validate("Journal Batch Name", GenJnlBatch.Name);

        SuggestVendorPayments.SetGenJnlLine(GenJnlLine);
        SuggestVendorPayments.SetTableView(Vendor);
        SuggestVendorPayments.InitializeRequest(
            WorkDate(), false, 0, false, WorkDate(), LibraryUtility.GenerateGUID(), false, "Gen. Journal Account Type"::"G/L Account", '', "Bank Payment Type"::" ");
        SuggestVendorPayments.UseRequestPage(false);
        SuggestVendorPayments.RunModal();
    end;

    local procedure VerifyCreditorInfoOnPurchInvoice(VendorNo: Code[20]; CreditorNo: Code[8]; PaymentReference: Code[16])
    var
        PurchHeader: Record "Purchase Header";
    begin
        PurchHeader.SetRange("Document Type", PurchHeader."Document Type"::Invoice);
        PurchHeader.SetRange("Pay-to Vendor No.", VendorNo);
        PurchHeader.SetRange("Creditor No.", CreditorNo);
        PurchHeader.SetRange("Payment Reference", PaymentReference);
        Assert.IsFalse(PurchHeader.IsEmpty, StrSubstNo(NotFoundErr, PurchHeader.TableCaption()));
    end;

    local procedure VerifyCreditorInfoOnPostedPurchInvoice(Vendor: Record Vendor; PaymentReference: Code[16]; PaymentMethodCode: Code[10])
    var
        PurchInvHeader: Record "Purch. Inv. Header";
    begin
        PurchInvHeader.SetRange("Pay-to Vendor No.", Vendor."No.");
        PurchInvHeader.SetRange("Creditor No.", Vendor."Creditor No.");
        PurchInvHeader.SetRange("Payment Reference", PaymentReference);
        PurchInvHeader.SetRange("Payment Method Code", PaymentMethodCode);
        Assert.IsFalse(PurchInvHeader.IsEmpty, StrSubstNo(NotFoundErr, PurchInvHeader.TableCaption()));
    end;

    local procedure VerifyCreditorInfoOnVendorLedgerEntry(Vendor: Record Vendor; PaymentReference: Code[50]; PaymentMethodCode: Code[10])
    var
        VendorLedgerEntry: Record "Vendor Ledger Entry";
    begin
        VendorLedgerEntry.SetRange("Vendor No.", Vendor."No.");
        VendorLedgerEntry.SetRange("Document Type", VendorLedgerEntry."Document Type"::Invoice);
        VendorLedgerEntry.SetRange("Creditor No.", Vendor."Creditor No.");
        VendorLedgerEntry.SetRange("Payment Reference", PaymentReference);
        VendorLedgerEntry.SetRange("Payment Method Code", PaymentMethodCode);
        Assert.IsFalse(VendorLedgerEntry.IsEmpty, StrSubstNo(NotFoundErr, VendorLedgerEntry.TableCaption()));
    end;

    local procedure VerifyPaymentMethodOnPostedSalesInv(Customer: Record Customer; PaymentMethodCode: Code[10])
    var
        SalesInvHeader: Record "Sales Invoice Header";
    begin
        SalesInvHeader.SetRange("Bill-to Customer No.", Customer."No.");
        SalesInvHeader.SetRange("Payment Method Code", PaymentMethodCode);
        Assert.IsFalse(SalesInvHeader.IsEmpty, StrSubstNo(NotFoundErr, SalesInvHeader.TableCaption()));
    end;

    local procedure VerifyPaymentMethodCodeonCustLedgerEntry(Customer: Record Customer; PaymentMethodCode: Code[10])
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
    begin
        CustLedgerEntry.SetRange("Customer No.", Customer."No.");
        CustLedgerEntry.SetRange("Document Type", CustLedgerEntry."Document Type"::Invoice);
        CustLedgerEntry.SetRange("Payment Method Code", PaymentMethodCode);
        Assert.IsFalse(CustLedgerEntry.IsEmpty, StrSubstNo(NotFoundErr, CustLedgerEntry.TableCaption()));
    end;
}

