codeunit 141078 "ERM Mandatory Pmt With Invoice"
{
    // 1. Verify error while posting Payment when Applies To Doc No. is blank and Force Payment With invoice is TRUE.
    // 2. Verify error while posting Payment when Applies To Doc Type and Applies To Doc No. is blank and Force Payment With invoice is TRUE.
    // 3. Verify Payment is posted successfully with Applies-to ID and Applies-to Doc. Type when Force Payment With invoice is TRUE.
    // 
    // Covers Test Cases for WI - 348524
    // ------------------------------------------------------------------------
    // Test Function Name                                                TFS ID
    // ------------------------------------------------------------------------
    // PostPaymentWithAppliesToDocNoBlankError                           171972
    // PostPaymentWithAppliesToDocTypeAndNoBlankError                    171971
    // PostPaymentWithForcePaymentWithInvoice                            171973

    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Force Payment With Invoice] [Applies-To]
    end;

    var
        Assert: Codeunit Assert;
        LibraryERM: Codeunit "Library - ERM";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibraryRandom: Codeunit "Library - Random";
        PaymentWithoutInvoiceErr: Label 'Payment without invoice is not allowed for line %1.';

    [Test]
    [Scope('OnPrem')]
    procedure PostPaymentWithAppliesToDocNoBlankError()
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        // [SCENARIO] error while posting Payment when Applies To Doc No. is blank and Force Payment With Invoice is TRUE.
        PaymentWithoutInvoiceError(GenJournalLine."Applies-to Doc. Type"::Invoice);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostPaymentWithAppliesToDocTypeAndNoBlankError()
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        // [SCENARIO] error while posting Payment when Applies To Doc Type and Applies To Doc No. is blank and Force Payment With Invoice is TRUE.
        PaymentWithoutInvoiceError(GenJournalLine."Applies-to Doc. Type"::" ");
    end;

    local procedure PaymentWithoutInvoiceError(AppliesToDocType: Enum "Gen. Journal Document Type")
    var
        GenJournalLine: Record "Gen. Journal Line";
        GeneralLedgerSetup: Record "General Ledger Setup";
        DocumentNo: Code[20];
    begin
        // [GIVEN] Create and post Purchase Invoice and create Payment.
        GeneralLedgerSetup.Get();
        UpdateForcePaymentWithInvoiceOnGeneralLedgerSetup(true);  // Using TRUE for Force Payment With Invoice.
        DocumentNo := CreateAndPostPurchaseInvoice();
        CreateGenJournalLine(GenJournalLine, DocumentNo, AppliesToDocType);

        // Exercise.
        asserterror LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // Verify.
        Assert.ExpectedError(StrSubstNo(PaymentWithoutInvoiceErr, GenJournalLine."Line No."));

        // Tear Down.
        UpdateForcePaymentWithInvoiceOnGeneralLedgerSetup(GeneralLedgerSetup."Force Payment With Invoice");
    end;

    [Test]
    [HandlerFunctions('ApplyVendorEntriesPageHandler')]
    [Scope('OnPrem')]
    procedure PostPaymentWithForcePaymentWithInvoice()
    var
        GenJournalLine: Record "Gen. Journal Line";
        GeneralLedgerSetup: Record "General Ledger Setup";
        DocumentNo: Code[20];
    begin
        // [SCENARIO] Payment is posted successfully with Applies-to ID and Applies-to Doc. Type when Force Payment With Invoice is TRUE.

        // [GIVEN] Create and post Purchase Invoice and apply Payment to it.
        GeneralLedgerSetup.Get();
        UpdateForcePaymentWithInvoiceOnGeneralLedgerSetup(true);  // Using TRUE for Force Payment With Invoice.
        DocumentNo := CreateAndPostPurchaseInvoice();
        CreateGenJournalLine(GenJournalLine, DocumentNo, GenJournalLine."Applies-to Doc. Type"::Invoice);
        OpenPaymentJournalPageAndApplyPaymentToInvoice(GenJournalLine."Journal Batch Name");

        // Exercise.
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // Verify: Verify Payment is fully applied to Invoice.
        VerifyVendorLedgerEntry(DocumentNo);

        // Tear Down.
        UpdateForcePaymentWithInvoiceOnGeneralLedgerSetup(GeneralLedgerSetup."Force Payment With Invoice");
    end;

    local procedure CreateAndPostPurchaseInvoice(): Code[20]
    var
        Item: Record Item;
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        Vendor: Record Vendor;
    begin
        LibraryPurchase.CreateVendor(Vendor);
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Invoice, Vendor."No.");
        LibraryPurchase.CreatePurchaseLine(
          PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, LibraryInventory.CreateItem(Item), LibraryRandom.RandDec(10, 2));  // Using random value for Quantity.
        PurchaseLine.Validate("Direct Unit Cost", LibraryRandom.RandDec(100, 2));
        PurchaseLine.Modify(true);
        exit(LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true));  // Post as Receive and Invoice.
    end;

    local procedure CreatePaymentJournalBatch(var GenJournalBatch: Record "Gen. Journal Batch")
    var
        GenJournalTemplate: Record "Gen. Journal Template";
    begin
        GenJournalTemplate.SetRange(Type, GenJournalTemplate.Type::Payments);
        LibraryERM.FindGenJournalTemplate(GenJournalTemplate);
        LibraryERM.CreateGenJournalBatch(GenJournalBatch, GenJournalTemplate.Name);
    end;

    local procedure CreateGenJournalLine(var GenJournalLine: Record "Gen. Journal Line"; DocumentNo: Code[20]; AppliesToDocType: Enum "Gen. Journal Document Type")
    var
        BankAccount: Record "Bank Account";
        GenJournalBatch: Record "Gen. Journal Batch";
        PurchInvHeader: Record "Purch. Inv. Header";
    begin
        PurchInvHeader.Get(DocumentNo);
        PurchInvHeader.CalcFields("Amount Including VAT");
        LibraryERM.CreateBankAccount(BankAccount);
        CreatePaymentJournalBatch(GenJournalBatch);
        LibraryERM.CreateGeneralJnlLine(
          GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name, GenJournalLine."Document Type"::Payment,
          GenJournalLine."Account Type"::Vendor, PurchInvHeader."Buy-from Vendor No.", PurchInvHeader."Amount Including VAT");
        GenJournalLine.Validate("Bal. Account Type", GenJournalLine."Bal. Account Type"::"Bank Account");
        GenJournalLine.Validate("Bal. Account No.", BankAccount."No.");
        GenJournalLine.Validate("Applies-to Doc. Type", AppliesToDocType);
        GenJournalLine.Modify(true);
    end;

    local procedure OpenPaymentJournalPageAndApplyPaymentToInvoice(CurrentJnlBatchName: Code[10])
    var
        PaymentJournal: TestPage "Payment Journal";
    begin
        PaymentJournal.OpenEdit();
        PaymentJournal.CurrentJnlBatchName.SetValue(CurrentJnlBatchName);
        PaymentJournal.ApplyEntries.Invoke();  // Opens ApplyVendorEntriesPageHandler.
        PaymentJournal.OK().Invoke();
    end;

    local procedure UpdateForcePaymentWithInvoiceOnGeneralLedgerSetup(ForcePaymentWithInvoice: Boolean)
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
    begin
        GeneralLedgerSetup.Get();
        GeneralLedgerSetup.Validate("Force Payment With Invoice", ForcePaymentWithInvoice);
        GeneralLedgerSetup.Modify(true);
    end;

    local procedure VerifyVendorLedgerEntry(DocumentNo: Code[20])
    var
        VendorLedgerEntry: Record "Vendor Ledger Entry";
    begin
        LibraryERM.FindVendorLedgerEntry(VendorLedgerEntry, VendorLedgerEntry."Document Type"::Invoice, DocumentNo);
        VendorLedgerEntry.TestField(Open, false);
        VendorLedgerEntry.TestField("Remaining Amount", 0);
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ApplyVendorEntriesPageHandler(var ApplyVendorEntries: TestPage "Apply Vendor Entries")
    begin
        ApplyVendorEntries.ActionSetAppliesToID.Invoke();
        ApplyVendorEntries.OK().Invoke();
    end;
}

