codeunit 144061 "Test ESR Localized Features"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [ESR]
    end;

    var
        Assert: Codeunit Assert;
        LibraryCH: Codeunit "Library - CH";
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
        LibraryRandom: Codeunit "Library - Random";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibraryERM: Codeunit "Library - ERM";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryJournals: Codeunit "Library - Journals";
        IsInitialized: Boolean;
        PaymentRefNoErr: Label 'Payment Reference No. should be be %1.', Comment = '%1 - Expected Payment Reference no.';

    [Test]
    [Scope('OnPrem')]
    procedure TestIBANAndBankAccountFieldActivation()
    var
        VendorBankAccountCard: TestPage "Vendor Bank Account Card";
    begin
        Init();
        VendorBankAccountCard.OpenNew();
        VendorBankAccountCard.Code.SetValue('POST');
        VendorBankAccountCard."Payment Form".SetValue('Post Payment Domestic');
        VendorBankAccountCard."Giro Account No.".SetValue('60-010083-3');

        // If the bank account is set the IBAN field should not be editable.
        VendorBankAccountCard."Bank Account No.".SetValue('012-345678.009');
        Assert.IsFalse(VendorBankAccountCard.IBAN.Enabled(), 'The IBAN field should be disabled when the bank account is set');

        // If the bank account is not set the IBAN field should be editable.
        VendorBankAccountCard."Bank Account No.".SetValue('');
        Assert.IsTrue(VendorBankAccountCard.IBAN.Enabled(),
          'The IBAN field should be enabled when the bank account is not set');

        // If the IBAN field is set the bank account should be disabled.
        VendorBankAccountCard.IBAN.SetValue('CH5604835012345678009');
        Assert.IsFalse(VendorBankAccountCard."Bank Account No.".Enabled(),
          'The Bank account No. field should be disabled when the IBAN field is set');

        // If the IBAN field is not set the bank account should be enabled.
        VendorBankAccountCard.IBAN.SetValue('');
        Assert.IsTrue(VendorBankAccountCard."Bank Account No.".Enabled(),
          'The Bank account No. field should be enabled when the IBAN field is not set');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure UpdateFromESRFromBankCodeIsNotAllowed()
    var
        Vendor: Record Vendor;
        VATPostingSetup: Record "VAT Posting Setup";
        GeneralPostingSetup: Record "General Posting Setup";
        PurchaseOrder: TestPage "Purchase Order";
    begin
        Init();

        // Setup PostingSetup and VAT PostingSetup.
        LibraryERM.FindGeneralPostingSetup(GeneralPostingSetup);
        LibraryERM.FindVATPostingSetup(VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT");

        // Create a new vendor
        LibraryCH.CreateVendor(Vendor, GeneralPostingSetup."Gen. Bus. Posting Group", VATPostingSetup."VAT Bus. Posting Group");
        CreateVendorBankAccounts(Vendor."No.");

        // Open the new purchase orders page
        PurchaseOrder.OpenNew();
        PurchaseOrder."Buy-from Vendor Name".SetValue(Vendor."No.");
        PurchaseOrder."Posting Date".SetValue(WorkDate());
        PurchaseOrder."Vendor Invoice No.".SetValue(Format(LibraryRandom.RandIntInRange(11111, 99999)));

        PurchaseOrder."ESR/ISR Coding Line".SetValue('0100000400689>331459012023430000000000001+010033140>');

        // We should get ESR and ESR Amount 400.68
        PurchaseOrder."Bank Code".AssertEquals('ESR');
        Assert.IsTrue(PurchaseOrder."ESR Amount".AsDecimal() = 400.68, 'Wrong value for the ESR Amount Field');

        // Now try to change ESR to Bank
        asserterror PurchaseOrder."Bank Code".SetValue('BANK');

        // We should get the expected error message containing the words ESR and ESR+ and the vendor no.
        Assert.IsTrue(
          (StrPos(GetLastErrorText, 'ESR') > 0) and
          (StrPos(GetLastErrorText, 'ESR+') > 0) and
          (StrPos(GetLastErrorText, Vendor."No.") > 0), 'Unexpected error message');
    end;

    [Test]
    procedure PostVendorPaymentWithESRReferenceUsingAppliesToID()
    var
        PurchaseHeader: Record "Purchase Header";
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        GenJournalLine: Record "Gen. Journal Line";
        InvoiceNo: Code[20];
    begin
        // [FEATURE] [Vendor] [Payment] [Reference No.] [Applies-to ID]
        // [SCENARIO 406307] Post vendor payment with ESR Reference No. using Applies-To ID
        Init();

        // [GIVEN] Posted purchase invoice with ESR Reference No.
        InvoiceNo := PostPurchaseInvoiceWithESRReferenceNo(PurchaseHeader);

        // [GIVEN] Payment journal line with vendor payment applied to the invoice using Applies-To ID
        LibraryERM.FindVendorLedgerEntry(VendorLedgerEntry, VendorLedgerEntry."Document Type"::Invoice, InvoiceNo);
        VendorLedgerEntry.CalcFields("Remaining Amount");
        CreateVendorPayment(
            GenJournalLine, PurchaseHeader."Buy-from Vendor No.", PurchaseHeader."Bank Code",
            -VendorLedgerEntry."Remaining Amount", PurchaseHeader."Reference No.", '', LibraryUtility.GenerateGUID());
        VendorLedgerEntry.Validate("Amount to Apply", VendorLedgerEntry."Remaining Amount");
        VendorLedgerEntry.Validate("Applies-to ID", GenJournalLine."Applies-to ID");
        Codeunit.Run(Codeunit::"Vend. Entry-Edit", VendorLedgerEntry);

        // [WHEN] Post the journal
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // [THEN] The journal has been posted
        LibraryERM.FindVendorLedgerEntry(VendorLedgerEntry, VendorLedgerEntry."Document Type"::Payment, GenJournalLine."Document No.");
        VendorLedgerEntry.TestField("Reference No.", PurchaseHeader."Reference No.");
    end;

    [Test]
    procedure PostVendorPaymentWithESRReferenceUsingApplyToDocNo()
    var
        PurchaseHeader: Record "Purchase Header";
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        GenJournalLine: Record "Gen. Journal Line";
        InvoiceNo: Code[20];
    begin
        // [FEATURE] [Vendor] [Payment] [Reference No.] [Applies-to Doc. No.]
        // [SCENARIO 406307] Post vendor payment with ESR Reference No. using Applies-to Doc. No.
        Init();

        // [GIVEN] Posted purchase invoice with ESR Reference No.
        InvoiceNo := PostPurchaseInvoiceWithESRReferenceNo(PurchaseHeader);

        // [GIVEN] Payment journal line with vendor payment applied to the invoice using Applies-to Doc. No.
        LibraryERM.FindVendorLedgerEntry(VendorLedgerEntry, VendorLedgerEntry."Document Type"::Invoice, InvoiceNo);
        VendorLedgerEntry.CalcFields("Remaining Amount");
        CreateVendorPayment(
            GenJournalLine, PurchaseHeader."Buy-from Vendor No.", PurchaseHeader."Bank Code",
            -VendorLedgerEntry."Remaining Amount", PurchaseHeader."Reference No.", InvoiceNo, '');

        // [WHEN] Post the journal
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // [THEN] The journal has been posted
        LibraryERM.FindVendorLedgerEntry(VendorLedgerEntry, VendorLedgerEntry."Document Type"::Payment, GenJournalLine."Document No.");
        VendorLedgerEntry.TestField("Reference No.", PurchaseHeader."Reference No.");
    end;

    [Test]
    procedure PostVendorPaymentPaymentReference()
    var
        PurchaseHeader: Record "Purchase Header";
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        GenJournalLine: Record "Gen. Journal Line";
        InvoiceNo: Code[20];
        ExpectedValue: Code[50];
    begin
        // [SCENARIO 441116] To validate if payment reference number is getting populated on Payment Journal line when updated applies-to doc. no.
        Init();

        // [GIVEN] Posted purchase invoice with ESR Reference No.
        InvoiceNo := PostPurchaseInvoiceWithPaymentReference(PurchaseHeader);

        // [GIVEN] Payment journal line with vendor payment applied to the invoice using Applies-To ID
        LibraryERM.FindVendorLedgerEntry(VendorLedgerEntry, VendorLedgerEntry."Document Type"::Invoice, InvoiceNo);
        VendorLedgerEntry.CalcFields("Remaining Amount");

        // [WHEN] Vendor payment Journal line is created manually and applies-to doc. no. is updated.
        CreateVendorPayment(
            GenJournalLine, PurchaseHeader."Buy-from Vendor No.", PurchaseHeader."Bank Code",
            -VendorLedgerEntry."Remaining Amount", PurchaseHeader."Reference No.", '', LibraryUtility.GenerateGUID());

        // [THEN] Payment reference no. is also updated from vendord ledger entry.
        ExpectedValue := LibraryVariableStorage.DequeueText();
        Assert.AreEqual(ExpectedValue, GenJournalLine."Payment Reference", StrSubstNo(PaymentRefNoErr, ExpectedValue));
    end;

    local procedure Init()
    begin
        LibraryVariableStorage.Clear();

        if IsInitialized then
            exit;

        LibraryERMCountryData.UpdateGeneralPostingSetup();
        IsInitialized := true;
    end;

    local procedure PostPurchaseInvoiceWithESRReferenceNo(var PurchaseHeader: Record "Purchase Header"): Code[20]
    begin
        LibraryPurchase.CreatePurchaseInvoice(PurchaseHeader);
        PurchaseHeader.CalcFields("Amount Including VAT");
        PurchaseHeader.Validate("Bank Code", CreateESRVendorBankAccount(PurchaseHeader."Buy-from Vendor No."));
        PurchaseHeader.Validate("Reference No.", '000000000000000000000000058');
        PurchaseHeader.Validate("ESR Amount", PurchaseHeader."Amount Including VAT");
        PurchaseHeader.Modify(true);
        exit(LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true));
    end;

    local procedure CreateVendorBankAccounts(VendorNumber: Code[20])
    var
        VendorBankAccount1: Record "Vendor Bank Account";
    begin
        VendorBankAccount1.Validate("Vendor No.", VendorNumber);
        VendorBankAccount1.Validate(Code, 'BANK');
        VendorBankAccount1.Validate("Payment Form", VendorBankAccount1."Payment Form"::"Bank Payment Domestic");
        VendorBankAccount1.Insert(true);

        CreateESRVendorBankAccount(VendorNumber);
    end;

    local procedure CreateESRVendorBankAccount(VendorNo: Code[20]): Code[20]
    var
        VendorBankAccount: Record "Vendor Bank Account";
    begin
        VendorBankAccount.Validate("Vendor No.", VendorNo);
        VendorBankAccount.Validate(Code, 'ESR');
        VendorBankAccount.Validate("ESR Type", VendorBankAccount."ESR Type"::"9/27");
        VendorBankAccount.Validate("Payment Form", VendorBankAccount."Payment Form"::ESR);
        VendorBankAccount.Validate("ESR Account No.", '01-003314-0');
        VendorBankAccount.Insert(true);
        exit(VendorBankAccount.Code);
    end;

    local procedure CreateVendorPayment(var GenJournalLine: Record "Gen. Journal Line"; VendorNo: Code[20]; ReceiptBankAccount: Code[20]; Amount: Decimal; ReferenceNo: Code[35]; AppliesToInvoiceNo: Code[20]; AppliesToID: Code[50])
    begin
        LibraryJournals.CreateGenJournalLineWithBatch(
          GenJournalLine, GenJournalLine."Document Type"::Payment, GenJournalLine."Account Type"::Vendor, VendorNo, Amount);
        GenJournalLine.Validate("Recipient Bank Account", ReceiptBankAccount);
        if AppliesToInvoiceNo <> '' then begin
            GenJournalLine.Validate("Applies-to Doc. Type", GenJournalLine."Applies-to Doc. Type"::Invoice);
            GenJournalLine.Validate("Applies-to Doc. No.", AppliesToInvoiceNo);
        end else
            GenJournalLine.Validate("Applies-to ID", AppliesToID);
        GenJournalLine.Validate("Reference No.", ReferenceNo);
        GenJournalLine.Modify(true);
    end;

    local procedure PostPurchaseInvoiceWithPaymentReference(var PurchaseHeader: Record "Purchase Header"): Code[20]
    begin
        LibraryPurchase.CreatePurchaseInvoice(PurchaseHeader);
        PurchaseHeader.CalcFields("Amount Including VAT");
        PurchaseHeader.Validate("Bank Code", CreateESRVendorBankAccount(PurchaseHeader."Buy-from Vendor No."));
        PurchaseHeader.Validate("Reference No.", '000000000000000000000000058');
        LibraryVariableStorage.Enqueue(PurchaseHeader."Payment Reference");
        PurchaseHeader.Validate("ESR Amount", PurchaseHeader."Amount Including VAT");
        PurchaseHeader.Validate("Payment Reference", LibraryRandom.RandText(50));
        PurchaseHeader.Modify(true);
        exit(LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true));
    end;
}

