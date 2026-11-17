// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Bank.Payment;

using Microsoft.Bank.BankAccount;
using Microsoft.Bank.Reports;
using Microsoft.Bank.Setup;
using Microsoft.Finance.GeneralLedger.Journal;
using Microsoft.Foundation.Address;
using Microsoft.Foundation.Company;
using Microsoft.Foundation.PaymentTerms;
using Microsoft.Purchases.Setup;
using Microsoft.Purchases.Vendor;
using Microsoft.Sales.Customer;
using Microsoft.Sales.Receivables;
using System.Environment.Configuration;
using System.IO;

codeunit 148239 "Banking FI Flow Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;
        LibraryBanking: Codeunit "Library - Banking FI";
        LibraryERM: Codeunit "Library - ERM";
        LibrarySales: Codeunit "Library - Sales";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibrarySetupStorage: Codeunit "Library - Setup Storage";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibraryFileMgtHandler: Codeunit "Library - File Mgt Handler";
        FileManagement: Codeunit "File Management";
        Payments: Codeunit "Ref. Payment Management FI";

    [Test]
    [HandlerFunctions('ImportRequestPage')]
    procedure ReferenceFileCreatesMatchedReceipt()
    var
        BankAccount: Record "Bank Account";
        JournalBatch: Record "Gen. Journal Batch";
        CustomerLedgerEntry: Record "Cust. Ledger Entry";
        FileName: Text;
    begin
        // [FEATURE] [AI test 0.3]
        // [SCENARIO] Importing a reference file matches invoice "I" and creates receipt "R".
        Initialize();

        // [GIVEN] Open invoice "I", bank "B" and a reference file for its full amount.
        CreateInvoice(CustomerLedgerEntry, false);
        CreateImportSetup(BankAccount, JournalBatch);
        FileName := CreateReferenceFile(CustomerLedgerEntry."Payment Reference No.");
        Commit();

        // [WHEN] The real FI import report reads the file.
        RunImport(FileName, BankAccount."No.", JournalBatch);

        // [THEN] FI history retains the payment data and receipt "R" applies to "I".
        VerifyImportedPayment(BankAccount, CustomerLedgerEntry, true);
        VerifyReceipt(JournalBatch, CustomerLedgerEntry, BankAccount."No.");
        LibraryVariableStorage.AssertEmpty();
        Erase(FileName);
        ReleaseSubscriptions();
    end;

    [Test]
    [HandlerFunctions('ImportRequestPage')]
    procedure ReimportDoesNotDuplicateReceiptJournal()
    var
        BankAccount: Record "Bank Account";
        JournalBatch: Record "Gen. Journal Batch";
        CustomerLedgerEntry: Record "Cust. Ledger Entry";
        FileName: Text;
    begin
        // [FEATURE] [AI test 0.3]
        // [SCENARIO] Reimporting payment "P" preserves the original single receipt "R".
        Initialize();

        // [GIVEN] Payment "P" has already produced receipt "R".
        CreateInvoice(CustomerLedgerEntry, false);
        CreateImportSetup(BankAccount, JournalBatch);
        FileName := CreateReferenceFile(CustomerLedgerEntry."Payment Reference No.");
        Commit();
        RunImport(FileName, BankAccount."No.", JournalBatch);
        VerifyReceipt(JournalBatch, CustomerLedgerEntry, BankAccount."No.");

        // [WHEN] The same file is imported again.
        RunImport(FileName, BankAccount."No.", JournalBatch);

        // [THEN] There is still exactly one receipt with the original amount and application.
        // Legacy TestDomesticImportOfThePaymentFileTheSecondTime guarantees journal, not history, deduplication.
        VerifyReceipt(JournalBatch, CustomerLedgerEntry, BankAccount."No.");
        LibraryVariableStorage.AssertEmpty();
        Erase(FileName);
        ReleaseSubscriptions();
    end;

    [Test]
    [HandlerFunctions('ImportRequestPage,UnmatchedPaymentMessage')]
    procedure UnmatchedReferenceCreatesNoReceipt()
    var
        BankAccount: Record "Bank Account";
        JournalBatch: Record "Gen. Journal Batch";
        CustomerLedgerEntry: Record "Cust. Ledger Entry";
        JournalLine: Record "Gen. Journal Line";
        FileName: Text;
        JournalCount: Integer;
    begin
        // [FEATURE] [AI test 0.3]
        // [SCENARIO] Unmatched payment "P" stays unposted and cannot create an unrelated receipt.
        Initialize();

        // [GIVEN] An invoice "I" exists but its reference differs from payment "P".
        CreateInvoice(CustomerLedgerEntry, false);
        CustomerLedgerEntry."Payment Reference No." := '1030232';
        CustomerLedgerEntry.Modify();
        CreateImportSetup(BankAccount, JournalBatch);
        FileName := CreateReferenceFile('1030229');
        JournalCount := JournalLine.Count();
        Commit();

        // [WHEN] The reference file is imported.
        RunImport(FileName, BankAccount."No.", JournalBatch);

        // [THEN] Payment "P" is retained unmatched and no journal anywhere has been added.
        VerifyImportedPayment(BankAccount, CustomerLedgerEntry, false);
        VerifyNoReceipt(JournalBatch, JournalCount);
        Assert.AreEqual('Non-applied entries in the system!', LibraryVariableStorage.DequeueText(), 'Unexpected unmatched-payment message.');
        LibraryVariableStorage.AssertEmpty();
        Erase(FileName);
        ReleaseSubscriptions();
    end;

    [Test]
    procedure DomesticExportTransfersOnlyEligibleRows()
    var
        BankAccount: Record "Bank Account";
        OtherBankAccount: Record "Bank Account";
        Vendor: Record Vendor;
        VendorBankAccount: Record "Vendor Bank Account";
        EligiblePayment: Record "Ref. Payment - Exported FI";
        ForeignPayment: Record "Ref. Payment - Exported FI";
        CreditMemo: Record "Ref. Payment - Exported FI";
        TransferredPayment: Record "Ref. Payment - Exported FI";
        OtherBankPayment: Record "Ref. Payment - Exported FI";
        ExportPayment: Report "Export Ref. Payment -  LMP FI";
    begin
        // [FEATURE] [AI test 0.3]
        // [SCENARIO] LMP exports only eligible invoice "I" and preserves its financial payload.
        Initialize();

        // [GIVEN] Vendor "V" has invoice "I" and four rows excluded by bank, type or status.
        CreateExportSetup(BankAccount, Vendor, VendorBankAccount, true);
        CreateExportPayment(EligiblePayment, BankAccount, VendorBankAccount);
        CreateExportPayment(ForeignPayment, BankAccount, VendorBankAccount);
        ForeignPayment."Foreign Payment" := true;
        ForeignPayment.Modify();
        CreateExportPayment(CreditMemo, BankAccount, VendorBankAccount);
        CreditMemo."Document Type" := CreditMemo."Document Type"::"Credit Memo";
        CreditMemo.Modify();
        CreateExportPayment(TransferredPayment, BankAccount, VendorBankAccount);
        TransferredPayment.Transferred := true;
        TransferredPayment."Batch Code" := 'ALREADY SENT';
        TransferredPayment.Modify();
        LibraryERM.CreateBankAccount(OtherBankAccount);
        OtherBankAccount."Country/Region Code" := '';
        OtherBankAccount.Modify();
        CreateExportPayment(OtherBankPayment, OtherBankAccount, VendorBankAccount);
        BankAccount.SetRecFilter();
        ExportPayment.SetTableView(BankAccount);
        ExportPayment.InitializeRequest(true);

        // [WHEN] The production LMP report writes its file.
        ExportPayment.RunModal();

        // [THEN] Only "I" is newly transferred and the file contains its account, amount, date and message.
        VerifyExportedPayment(EligiblePayment);
        VerifyUnchangedExport(ForeignPayment);
        VerifyUnchangedExport(CreditMemo);
        VerifyUnchangedExport(TransferredPayment);
        VerifyUnchangedExport(OtherBankPayment);
        VerifyDomesticPayload(ExportPayment.GetFileName(), EligiblePayment, Vendor);
        Erase(ExportPayment.GetFileName());
        ReleaseSubscriptions();
    end;

    [Test]
    procedure ForeignExportPreservesDomesticSepaAndSentRows()
    var
        BankAccount: Record "Bank Account";
        Vendor: Record Vendor;
        VendorBankAccount: Record "Vendor Bank Account";
        DomesticVendor: Record Vendor;
        DomesticVendorBankAccount: Record "Vendor Bank Account";
        DomesticBankAccount: Record "Bank Account";
        EligiblePayment: Record "Ref. Payment - Exported FI";
        DomesticPayment: Record "Ref. Payment - Exported FI";
        SepaPayment: Record "Ref. Payment - Exported FI";
        TransferredPayment: Record "Ref. Payment - Exported FI";
        ExportPayment: Report "Export Ref. Payment -  LUM FI";
    begin
        // [FEATURE] [AI test 0.3]
        // [SCENARIO] LUM writes foreign payment "P" without changing domestic, non-foreign SEPA or previously sent rows.
        Initialize();

        // [GIVEN] Foreign payment "P" and a previously sent foreign payment exist at bank "B".
        CreateForeignExportSetup(BankAccount, Vendor, VendorBankAccount, true);
        CreateExportPayment(EligiblePayment, BankAccount, VendorBankAccount);
        CreateExportPayment(TransferredPayment, BankAccount, VendorBankAccount);
        TransferredPayment.Transferred := true;
        TransferredPayment."Transfer Date" := WorkDate() - 1;
        TransferredPayment."Transfer Time" := 120000T;
        TransferredPayment."Batch Code" := 'ALREADY SENT';
        TransferredPayment.Modify();

        // [GIVEN] Domestic and non-foreign SEPA rows belong to an unrelated bank "B2".
        CreateExportSetup(DomesticBankAccount, DomesticVendor, DomesticVendorBankAccount, true);
        CreateExportPayment(DomesticPayment, DomesticBankAccount, DomesticVendorBankAccount);
        DomesticVendorBankAccount."SEPA Payment Enabled" := true;
        DomesticVendorBankAccount.Modify(true);
        CreateExportPayment(SepaPayment, DomesticBankAccount, DomesticVendorBankAccount);
        VerifyForeignExportFixture(EligiblePayment, DomesticPayment, SepaPayment, TransferredPayment);
        BankAccount.SetRecFilter();
        ExportPayment.SetTableView(BankAccount);
        ExportPayment.InitializeRequest(true);

        // [WHEN] The real LUM report exports "P" with transaction-level due-date handling.
        ExportPayment.RunModal();

        // [THEN] The captured file contains only "P"; unrelated and already-sent rows remain unchanged.
        // LUM's broad OnPostReport foreign-row update prevents claiming other-bank/applied foreign-row isolation.
        VerifyForeignExportedPayment(EligiblePayment);
        VerifyUnchangedExport(DomesticPayment);
        VerifyUnchangedExport(SepaPayment);
        VerifyUnchangedExport(TransferredPayment);
        VerifyForeignPayload(ExportPayment.GetFileName(), EligiblePayment, Vendor, VendorBankAccount);
        Erase(ExportPayment.GetFileName());
        ReleaseSubscriptions();
    end;

    [Test]
    procedure DomesticCombinationPreservesTotalAndAffiliation()
    var
        BankAccount: Record "Bank Account";
        Vendor: Record Vendor;
        VendorBankAccount: Record "Vendor Bank Account";
        FirstPayment: Record "Ref. Payment - Exported FI";
        SecondPayment: Record "Ref. Payment - Exported FI";
    begin
        // [FEATURE] [AI test 0.3]
        // [SCENARIO] Combining payments "P1" and "P2" preserves totals, bank and affiliation.
        Initialize();

        // [GIVEN] Bank "B" permits combination of two domestic payments for vendor "V".
        CreateExportSetup(BankAccount, Vendor, VendorBankAccount, true);
        CreateExportPayment(FirstPayment, BankAccount, VendorBankAccount);
        CreateExportPayment(SecondPayment, BankAccount, VendorBankAccount);

        // [WHEN] Production payment management combines domestic payments.
        Payments.CombineVendPmt(0);

        // [THEN] The combined row totals "P1" and "P2", which remain affiliated source rows.
        VerifyCombinedPayments(FirstPayment, SecondPayment);
        ReleaseSubscriptions();
    end;

    [Test]
    procedure DomesticCombinationRequiresBankPermission()
    var
        BankAccount: Record "Bank Account";
        Vendor: Record Vendor;
        VendorBankAccount: Record "Vendor Bank Account";
        FirstPayment: Record "Ref. Payment - Exported FI";
        SecondPayment: Record "Ref. Payment - Exported FI";
        ReferenceFileSetup: Record "Reference File Setup FI";
    begin
        // [FEATURE] [AI test 0.3]
        // [SCENARIO] Bank "B" disallows combination, so payments "P1" and "P2" remain unchanged.
        Initialize();

        // [GIVEN] Two domestic payments exist for a bank without combination permission.
        CreateExportSetup(BankAccount, Vendor, VendorBankAccount, false);
        CreateExportPayment(FirstPayment, BankAccount, VendorBankAccount);
        CreateExportPayment(SecondPayment, BankAccount, VendorBankAccount);
        Commit();

        // [WHEN] Combination is requested.
        asserterror Payments.CombineVendPmt(0);

        // [THEN] Bank permission is required and neither source row is combined.
        Assert.ExpectedError(ReferenceFileSetup.FieldCaption("Allow Comb. Domestic Pmts."));
        Assert.ExpectedErrorCode('TestField');
        VerifyUnchangedExport(FirstPayment);
        VerifyUnchangedExport(SecondPayment);
        ReleaseSubscriptions();
    end;

    [Test]
    procedure ForeignCombinationPreservesTotalAndAffiliation()
    var
        BankAccount: Record "Bank Account";
        Vendor: Record Vendor;
        VendorBankAccount: Record "Vendor Bank Account";
        FirstPayment: Record "Ref. Payment - Exported FI";
        SecondPayment: Record "Ref. Payment - Exported FI";
    begin
        // [FEATURE] [AI test 0.3]
        // [SCENARIO] Foreign payments "P1" and "P2" retain totals and source affiliations when combined.
        Initialize();

        // [GIVEN] Bank "B" permits combination of two foreign payments for vendor "V".
        CreateForeignExportSetup(BankAccount, Vendor, VendorBankAccount, true);
        CreateExportPayment(FirstPayment, BankAccount, VendorBankAccount);
        CreateExportPayment(SecondPayment, BankAccount, VendorBankAccount);

        // [WHEN] Production payment management combines foreign payments.
        Payments.CombineVendPmt(1);

        // [THEN] The combined foreign row retains both amounts and the source group.
        VerifyCombinedPayments(FirstPayment, SecondPayment);
        ReleaseSubscriptions();
    end;

    [Test]
    procedure ForeignCombinationRequiresBankPermission()
    var
        BankAccount: Record "Bank Account";
        Vendor: Record Vendor;
        VendorBankAccount: Record "Vendor Bank Account";
        FirstPayment: Record "Ref. Payment - Exported FI";
        SecondPayment: Record "Ref. Payment - Exported FI";
        ReferenceFileSetup: Record "Reference File Setup FI";
    begin
        // [FEATURE] [AI test 0.3]
        // [SCENARIO] Bank "B" can disallow foreign combination independently of domestic permission.
        Initialize();

        // [GIVEN] Domestic combination is allowed but foreign combination is disabled for bank "B".
        CreateForeignExportSetup(BankAccount, Vendor, VendorBankAccount, false);
        CreateExportPayment(FirstPayment, BankAccount, VendorBankAccount);
        CreateExportPayment(SecondPayment, BankAccount, VendorBankAccount);
        Commit();

        // [WHEN] Foreign combination is requested.
        asserterror Payments.CombineVendPmt(1);

        // [THEN] The foreign permission is required and neither source payment is changed.
        Assert.ExpectedError(ReferenceFileSetup.FieldCaption("Allow Comb. Foreign Pmts."));
        Assert.ExpectedErrorCode('TestField');
        VerifyUnchangedExport(FirstPayment);
        VerifyUnchangedExport(SecondPayment);
        VerifyExportRowCount(2);
        ReleaseSubscriptions();
    end;

    [Test]
    procedure FullPaymentClearsDiscountWhenNewFieldEnabled()
    var
        CustomerLedgerEntry: Record "Cust. Ledger Entry";
        PaymentJournalLine: Record "Gen. Journal Line";
    begin
        // [FEATURE] [AI test 0.3]
        // [SCENARIO] Posting full payment "P" closes invoice "I" without taking discount using the new FI field.
        Initialize();

        // [GIVEN] Posted invoice "I" has discount and the new disregard field enabled.
        CreateInvoice(CustomerLedgerEntry, true);
        CreateFullPaymentJournal(PaymentJournalLine, CustomerLedgerEntry);

        // [WHEN] Payment "P" is posted and applied through the real journal posting pipeline.
        LibraryERM.PostGeneralJnlLine(PaymentJournalLine);

        // [THEN] Both entries close with zero remaining amount and no discount taken.
        VerifyPostedFullPayment(CustomerLedgerEntry, PaymentJournalLine."Document No.");
        ReleaseSubscriptions();
    end;

    [Test]
    procedure FullPaymentRetainsDiscountWhenNewFieldDisabled()
    var
        CustomerLedgerEntry: Record "Cust. Ledger Entry";
        PaymentJournalLine: Record "Gen. Journal Line";
        ExpectedDiscount: Decimal;
    begin
        // [FEATURE] [AI test 0.3]
        // [SCENARIO] A full payment of invoice "I" retains discount when the new FI field is disabled.
        Initialize();

        // [GIVEN] Posted invoice "I" has discount but does not disregard it at full payment.
        CreateInvoice(CustomerLedgerEntry, false);
        ExpectedDiscount := CustomerLedgerEntry."Remaining Pmt. Disc. Possible";
        PrepareFullPayment(PaymentJournalLine, CustomerLedgerEntry);

        // [WHEN] The public FI full-payment check processes its application.
        Payments.CheckIfPaidInFull(PaymentJournalLine);

        // [THEN] The discount and balance remain unchanged.
        VerifyDiscount(CustomerLedgerEntry, ExpectedDiscount);
        ReleaseSubscriptions();
    end;

    [Test]
    procedure FullPaymentAfterToleranceRetainsDiscount()
    var
        CustomerLedgerEntry: Record "Cust. Ledger Entry";
        PaymentJournalLine: Record "Gen. Journal Line";
        ExpectedDiscount: Decimal;
    begin
        // [FEATURE] [AI test 0.3]
        // [SCENARIO] A payment after invoice "I" discount tolerance date does not clear its discount.
        Initialize();

        // [GIVEN] Invoice "I" disregards full-payment discount, but payment "P" is too late.
        CreateInvoice(CustomerLedgerEntry, true);
        ExpectedDiscount := CustomerLedgerEntry."Remaining Pmt. Disc. Possible";
        PrepareFullPayment(PaymentJournalLine, CustomerLedgerEntry);
        PaymentJournalLine."Posting Date" := CustomerLedgerEntry."Pmt. Disc. Tolerance Date" + 1;

        // [WHEN] The public FI full-payment check processes its application.
        Payments.CheckIfPaidInFull(PaymentJournalLine);

        // [THEN] The expired discount is not rewritten by the full-payment check.
        VerifyDiscount(CustomerLedgerEntry, ExpectedDiscount);
        ReleaseSubscriptions();
    end;

    [Test]
    procedure PartialPaymentRetainsUnpaidDiscount()
    var
        CustomerLedgerEntry: Record "Cust. Ledger Entry";
        PaymentJournalLine: Record "Gen. Journal Line";
        ExpectedDiscount: Decimal;
    begin
        // [FEATURE] [AI test 0.3]
        // [SCENARIO] An on-time near-full payment of invoice "I" leaves the unpaid eligible discount instead of clearing it.
        Initialize();

        // [GIVEN] Invoice "I" disregards full-payment discount, but payment "P" leaves part of its discount unpaid.
        CreateInvoice(CustomerLedgerEntry, true);
        ExpectedDiscount := PreparePartialPayment(PaymentJournalLine, CustomerLedgerEntry);

        // [WHEN] The public FI full-payment check processes the partial application.
        Payments.CheckIfPaidInFull(PaymentJournalLine);

        // [THEN] Only the unpaid discount remains possible and no balance is posted or closed.
        VerifyDiscount(CustomerLedgerEntry, ExpectedDiscount);
        ReleaseSubscriptions();
    end;

    local procedure Initialize()
    var
        ImportedPayment: Record "Ref. Payment - Imported FI";
        ExportedPayment: Record "Ref. Payment - Exported FI";
#if not CLEAN30
        FeatureManagementFacade: Codeunit "Feature Management Facade";
        BankingFeature: Codeunit "Banking Payments Feature FI";
#endif
    begin
        // Functional cutover fixture only: no DataTransfer/migration coverage is claimed.
        // Do not bind the manual feature override: raw BaseApp and app gates must agree.
        LibraryBanking.SetCompletedFeatureFixture();
#if not CLEAN30
        Assert.IsTrue(
            FeatureManagementFacade.IsEnabled('BankingAndPaymentsFI'),
            'The platform-provisioned feature must be enabled for both BaseApp and app financial paths.');
        BankingFeature.EnsureEnabled();
#endif
        Clear(Payments);
        Clear(LibrarySetupStorage);
        LibrarySetupStorage.SavePurchasesSetup();
        LibrarySetupStorage.SaveCompanyInformation();
        LibraryVariableStorage.Clear();
        ImportedPayment.DeleteAll(true);
        ExportedPayment.DeleteAll(true);
        LibraryFileMgtHandler.SetDownloadSubscriberActivated(true);
        BindSubscription(LibraryFileMgtHandler);
    end;

    local procedure CreateJournalBatch(var JournalBatch: Record "Gen. Journal Batch"; BankAccountNo: Code[20]; CashReceipts: Boolean)
    var
        JournalTemplate: Record "Gen. Journal Template";
    begin
        LibraryERM.CreateGenJournalTemplate(JournalTemplate);
        if CashReceipts then begin
            JournalTemplate.Validate(Type, JournalTemplate.Type::"Cash Receipts");
            JournalTemplate.Modify(true);
        end;
        LibraryERM.CreateGenJournalBatch(JournalBatch, JournalTemplate.Name);
        JournalBatch.Validate("Bal. Account Type", JournalBatch."Bal. Account Type"::"Bank Account");
        JournalBatch.Validate("Bal. Account No.", BankAccountNo);
        JournalBatch."No. Series" := LibraryERM.CreateNoSeriesCode();
        JournalBatch.Modify(true);
    end;

    local procedure CreateInvoice(var CustomerLedgerEntry: Record "Cust. Ledger Entry"; DisregardDiscount: Boolean)
    var
        Customer: Record Customer;
        PaymentTerms: Record "Payment Terms";
        BankAccount: Record "Bank Account";
        JournalBatch: Record "Gen. Journal Batch";
        JournalLine: Record "Gen. Journal Line";
    begin
        LibraryERM.CreatePaymentTerms(PaymentTerms);
        Evaluate(PaymentTerms."Due Date Calculation", '<30D>');
        Evaluate(PaymentTerms."Discount Date Calculation", '<5D>');
        PaymentTerms."Discount %" := 2;
        PaymentTerms."Disreg. Full Payment Discount" := DisregardDiscount;
        PaymentTerms.Modify(true);
        LibrarySales.CreateCustomer(Customer);
        Customer.Validate("Currency Code", '');
        Customer.Validate("Payment Terms Code", PaymentTerms.Code);
        Customer."Block Payment Tolerance" := false;
        Customer.Modify(true);
        LibraryERM.CreateBankAccount(BankAccount);
        CreateJournalBatch(JournalBatch, BankAccount."No.", false);
        LibraryERM.CreateGeneralJnlLine(
            JournalLine, JournalBatch."Journal Template Name", JournalBatch.Name,
            JournalLine."Document Type"::Invoice, JournalLine."Account Type"::Customer, Customer."No.", 2000);
        JournalLine."Payment Reference No." := '1030229';
        JournalLine.Modify(true);
        LibraryERM.PostGeneralJnlLine(JournalLine);
        CustomerLedgerEntry.SetRange("Customer No.", Customer."No.");
        CustomerLedgerEntry.SetRange("Document Type", CustomerLedgerEntry."Document Type"::Invoice);
        CustomerLedgerEntry.FindFirst();
        VerifyInvoiceFixture(CustomerLedgerEntry, DisregardDiscount);
    end;

    local procedure VerifyInvoiceFixture(CustomerLedgerEntry: Record "Cust. Ledger Entry"; DisregardDiscount: Boolean)
    begin
        Assert.AreEqual('1030229', CustomerLedgerEntry."Payment Reference No.", 'Posting must copy the new reference field.');
        Assert.AreEqual(DisregardDiscount, CustomerLedgerEntry."Disreg. Full Payment Discount", 'Posting must copy the new payment-terms field.');
        Assert.AreEqual(40, CustomerLedgerEntry."Remaining Pmt. Disc. Possible", 'The posted invoice must have a nonzero discount.');
        Assert.IsTrue(CustomerLedgerEntry."Pmt. Disc. Tolerance Date" >= CustomerLedgerEntry."Posting Date", 'The invoice must qualify for an on-time full-payment discount check.');
    end;

    local procedure CreateImportSetup(var BankAccount: Record "Bank Account"; var JournalBatch: Record "Gen. Journal Batch")
    var
        ReferenceFileSetup: Record "Reference File Setup FI";
    begin
        LibraryERM.CreateBankAccount(BankAccount);
        BankAccount."Bank Account No." := '2229018-7205';
        BankAccount.Modify(true);
        ReferenceFileSetup."No." := BankAccount."No.";
        ReferenceFileSetup.Insert(true);
        CreateJournalBatch(JournalBatch, BankAccount."No.", true);
    end;

    local procedure CreateReferenceFile(ReferenceNo: Code[20]): Text
    var
        PaymentFile: File;
        FileName: Text;
    begin
        // Same fixed-width layout and filing identity as legacy import sample 4; use the current posting date.
        FileName := FileManagement.ServerTempFileName('txt');
        PaymentFile.TextMode := true;
        PaymentFile.Create(FileName);
        PaymentFile.Write('006082323592 08948590810654467340000000000000000000000000000000000000000000000000000000000');
        PaymentFile.Write(
            '3' + '22290100087205' +
            Format(WorkDate(), 0, '<Year,2><Month,2><Day,2>') +
            Format(WorkDate(), 0, '<Year,2><Month,2><Day,2>') +
            '08232588NGP40738' +
            PadStr('', 20 - StrLen(ReferenceNo), '0') + ReferenceNo +
            'TESTIAS1    1J00002000000A0');
        PaymentFile.Close();
        exit(FileName);
    end;

    local procedure RunImport(FileName: Text; BankAccountNo: Code[20]; JournalBatch: Record "Gen. Journal Batch")
    var
        ImportPayment: Report "Import Ref. Payment FI";
    begin
        LibraryVariableStorage.Enqueue(BankAccountNo);
        ImportPayment.InitializeRequest(FileName);
        ImportPayment.SetLedgerNames(JournalBatch.Name, JournalBatch."Journal Template Name");
        ImportPayment.UseRequestPage(true);
        ImportPayment.RunModal();
    end;

    local procedure VerifyImportedPayment(BankAccount: Record "Bank Account"; CustomerLedgerEntry: Record "Cust. Ledger Entry"; ExpectedMatched: Boolean)
    var
        ImportedPayment: Record "Ref. Payment - Imported FI";
    begin
        Assert.AreEqual(2, ImportedPayment.Count(), 'The file must create a header and one payment.');
        ImportedPayment.SetRange("Record ID", 3);
        Assert.AreEqual(1, ImportedPayment.Count(), 'Exactly one transaction must be imported.');
        ImportedPayment.FindFirst();
        Assert.AreEqual('1030229', ImportedPayment."Reference No.", 'Leading reference zeros must be removed.');
        Assert.AreEqual('22290100087205', ImportedPayment."Account No.", 'The bank account must survive parsing.');
        Assert.AreEqual(BankAccount."No.", ImportedPayment."Bank Account Code", 'The payment must resolve to the configured bank.');
        Assert.AreEqual(WorkDate(), ImportedPayment."Banks Posting Date", 'The posting date must survive parsing.');
        Assert.AreEqual(WorkDate(), ImportedPayment."Banks Payment Date", 'The payment date must survive parsing.');
        Assert.AreEqual('08232588NGP40738', ImportedPayment."Filing Code", 'The filing identity must survive parsing.');
        Assert.AreEqual('TESTIAS1', DelChr(ImportedPayment."Payers Name", '>', ' '), 'The payer must survive parsing.');
        Assert.AreEqual(2000, ImportedPayment.Amount, 'The amount must be converted from cents.');
        Assert.AreEqual(ExpectedMatched, ImportedPayment.Matched, 'Unexpected match state.');
        Assert.IsFalse(ImportedPayment."Posted to G/L", 'Import must not post the receipt.');
        if ExpectedMatched then begin
            Assert.AreEqual(CustomerLedgerEntry."Entry No.", ImportedPayment."Entry No.", 'The payment must match the invoice entry.');
            Assert.AreEqual(CustomerLedgerEntry."Document No.", ImportedPayment."Document No.", 'The payment must match the invoice document.');
            Assert.AreEqual(CustomerLedgerEntry."Customer No.", ImportedPayment."Customer No.", 'The payment must match the customer.');
        end else begin
            Assert.AreEqual(0, ImportedPayment."Entry No.", 'An unmatched reference must not link to an invoice.');
            Assert.AreEqual('', ImportedPayment."Customer No.", 'An unmatched reference must not link to a customer.');
        end;
    end;

    local procedure VerifyReceipt(JournalBatch: Record "Gen. Journal Batch"; CustomerLedgerEntry: Record "Cust. Ledger Entry"; BankAccountNo: Code[20])
    var
        JournalLine: Record "Gen. Journal Line";
    begin
        JournalLine.SetRange("Journal Template Name", JournalBatch."Journal Template Name");
        JournalLine.SetRange("Journal Batch Name", JournalBatch.Name);
        Assert.AreEqual(1, JournalLine.Count(), 'Reimport must not duplicate the receipt journal.');
        JournalLine.FindFirst();
        Assert.AreEqual(-2000, JournalLine.Amount, 'The receipt must reverse the imported amount sign.');
        Assert.AreEqual(JournalLine."Account Type"::Customer, JournalLine."Account Type", 'The receipt must use a customer account.');
        Assert.AreEqual(CustomerLedgerEntry."Customer No.", JournalLine."Account No.", 'Unexpected receipt customer.');
        Assert.AreEqual(JournalLine."Document Type"::Payment, JournalLine."Document Type", 'The receipt must be a payment.');
        Assert.AreEqual(JournalLine."Applies-to Doc. Type"::Invoice, JournalLine."Applies-to Doc. Type", 'The receipt must apply to an invoice.');
        Assert.AreEqual(CustomerLedgerEntry."Document No.", JournalLine."Applies-to Doc. No.", 'Unexpected receipt application.');
        Assert.AreEqual(CustomerLedgerEntry."Payment Reference No.", JournalLine."Payment Reference No.", 'The receipt must retain its reference.');
        Assert.AreEqual('08232588NGP40738', JournalLine.Comment, 'The receipt must retain its filing identity for deduplication.');
        Assert.AreEqual(JournalLine."Bal. Account Type"::"Bank Account", JournalLine."Bal. Account Type", 'The receipt must balance to a bank.');
        Assert.AreEqual(BankAccountNo, JournalLine."Bal. Account No.", 'Unexpected receipt bank.');
        Assert.AreEqual(WorkDate(), JournalLine."Posting Date", 'Unexpected receipt date.');
        Assert.AreEqual(JournalBatch."Posting No. Series", JournalLine."Posting No. Series", 'The receipt must use its batch posting series.');
    end;

    local procedure VerifyNoReceipt(JournalBatch: Record "Gen. Journal Batch"; ExpectedJournalCount: Integer)
    var
        JournalLine: Record "Gen. Journal Line";
    begin
        Assert.AreEqual(ExpectedJournalCount, JournalLine.Count(), 'An unmatched reference must not add journals in another batch.');
        JournalLine.SetRange("Journal Template Name", JournalBatch."Journal Template Name");
        JournalLine.SetRange("Journal Batch Name", JournalBatch.Name);
        Assert.IsTrue(JournalLine.IsEmpty(), 'An unmatched reference must not create a receipt.');
    end;

    local procedure CreateExportSetup(var BankAccount: Record "Bank Account"; var Vendor: Record Vendor; var VendorBankAccount: Record "Vendor Bank Account"; AllowCombination: Boolean)
    var
        ReferenceFileSetup: Record "Reference File Setup FI";
        PurchasesSetup: Record "Purchases & Payables Setup";
    begin
        LibraryERM.CreateBankAccount(BankAccount);
        BankAccount."Country/Region Code" := '';
        BankAccount."Bank Account No." := '2229018-7205';
        BankAccount.Modify(true);
        ReferenceFileSetup."No." := BankAccount."No.";
        ReferenceFileSetup."Allow Comb. Domestic Pmts." := AllowCombination;
        ReferenceFileSetup.Insert(true);
        LibraryPurchase.CreateVendor(Vendor);
        Vendor.Name := 'Financial flow regression vendor with long name';
        Vendor.Modify(true);
        LibraryPurchase.CreateVendorBankAccount(VendorBankAccount, Vendor."No.");
        VendorBankAccount."Country/Region Code" := '';
        VendorBankAccount."Bank Account No." := '2229018-7206';
        VendorBankAccount.Modify(true);
        PurchasesSetup.Get();
        PurchasesSetup."Payment Batch Nos." := LibraryERM.CreateNoSeriesCode();
        PurchasesSetup.Modify(true);
    end;

    local procedure CreateForeignExportSetup(var BankAccount: Record "Bank Account"; var Vendor: Record Vendor; var VendorBankAccount: Record "Vendor Bank Account"; AllowForeignCombination: Boolean)
    var
        CompanyInformation: Record "Company Information";
        ReferenceFileSetup: Record "Reference File Setup FI";
        CountryCode: Code[2];
    begin
        CreateExportSetup(BankAccount, Vendor, VendorBankAccount, true);
        CompanyInformation.Get();
        CompanyInformation."Business Identity Code" := '1234567-1';
        CompanyInformation.Modify(true);
        CountryCode := 'GB';
        if CompanyInformation."Country/Region Code" = CountryCode then
            CountryCode := 'DE';
        EnsureForeignCountry(CountryCode);
        Vendor.Validate("Country/Region Code", CountryCode);
        Vendor.Modify(true);
        VendorBankAccount.Validate("Country/Region Code", CountryCode);
        VendorBankAccount."SEPA Payment Enabled" := false;
        if CountryCode = 'GB' then
            VendorBankAccount.Validate(IBAN, 'GB82WEST12345698765432')
        else
            VendorBankAccount.Validate(IBAN, 'DE89370400440532013000');
        VendorBankAccount.Modify(true);

        EnsureForeignPaymentType('A', 0);
        EnsureForeignPaymentType('B', 1);
        ReferenceFileSetup.Get(BankAccount."No.");
        ReferenceFileSetup.Validate("Default Payment Method", 'A');
        ReferenceFileSetup.Validate("Default Service Fee Code", 'B');
        ReferenceFileSetup."Allow Comb. Foreign Pmts." := AllowForeignCombination;
        // The real transaction-level option avoids the batch-date modal dialog; no page is intercepted.
        ReferenceFileSetup."Due Date Handling" := ReferenceFileSetup."Due Date Handling"::Transaction;
        ReferenceFileSetup."Exchange Rate Contract No." := 'FX-CONTRACT';
        ReferenceFileSetup.Modify(true);
    end;

    local procedure EnsureForeignCountry(CountryCode: Code[2])
    var
        CountryRegion: Record "Country/Region";
    begin
        // LUM uses the actual country key in a two-character slot, not the table's ISO-code field.
        if CountryRegion.Get(CountryCode) then
            exit;
        CountryRegion.Init();
        CountryRegion.Code := CountryCode;
        CountryRegion.Name := 'Foreign payment test country';
        CountryRegion.Insert(true);
    end;

    local procedure EnsureForeignPaymentType(PaymentCode: Code[1]; CodeType: Option "Payment Method","Service Fee")
    var
        ForeignPaymentType: Record "Foreign Payment Types FI";
    begin
        if ForeignPaymentType.Get(PaymentCode, CodeType) then
            exit;
        ForeignPaymentType.Init();
        ForeignPaymentType.Code := PaymentCode;
        ForeignPaymentType."Code Type" := CodeType;
        ForeignPaymentType.Insert(true);
    end;

    local procedure CreateExportPayment(var ExportedPayment: Record "Ref. Payment - Exported FI"; BankAccount: Record "Bank Account"; VendorBankAccount: Record "Vendor Bank Account")
    begin
        ExportedPayment.Init();
        ExportedPayment."No." := ExportedPayment.GetLastLineNo() + 1;
        ExportedPayment.Validate("Vendor No.", VendorBankAccount."Vendor No.");
        ExportedPayment.Validate("Payment Account", BankAccount."No.");
        ExportedPayment.Validate("Vendor Account", VendorBankAccount.Code);
        ExportedPayment.Validate("Payment Date", WorkDate());
        ExportedPayment."Document Type" := ExportedPayment."Document Type"::Invoice;
        ExportedPayment.Validate(Amount, 1000);
        ExportedPayment.Validate("Message Type", ExportedPayment."Message Type"::Message);
        ExportedPayment."Invoice Message" := 'Invoice settlement';
        ExportedPayment.Insert(true);
    end;

    local procedure VerifyExportedPayment(OriginalPayment: Record "Ref. Payment - Exported FI")
    var
        ExportedPayment: Record "Ref. Payment - Exported FI";
    begin
        ExportedPayment.Get(OriginalPayment."No.");
        Assert.IsTrue(ExportedPayment.Transferred, 'The eligible invoice must be marked transferred.');
        Assert.AreEqual(Today(), ExportedPayment."Transfer Date", 'The transfer date must be recorded.');
        Assert.AreNotEqual('', ExportedPayment."Batch Code", 'The export batch identity must be recorded.');
        VerifyPaymentData(OriginalPayment, ExportedPayment);
    end;

    local procedure VerifyUnchangedExport(OriginalPayment: Record "Ref. Payment - Exported FI")
    var
        ExportedPayment: Record "Ref. Payment - Exported FI";
    begin
        ExportedPayment.Get(OriginalPayment."No.");
        Assert.AreEqual(OriginalPayment.Transferred, ExportedPayment.Transferred, 'An excluded row must keep its transfer status.');
        Assert.AreEqual(OriginalPayment."Transfer Date", ExportedPayment."Transfer Date", 'An excluded row must keep its transfer date.');
        Assert.AreEqual(OriginalPayment."Transfer Time", ExportedPayment."Transfer Time", 'An excluded row must keep its transfer time.');
        Assert.AreEqual(OriginalPayment."Batch Code", ExportedPayment."Batch Code", 'An excluded row must keep its batch identity.');
        Assert.AreEqual(OriginalPayment."Applied Payments", ExportedPayment."Applied Payments", 'A rejected combination must not apply source rows.');
        Assert.AreEqual(OriginalPayment."Affiliated to Line", ExportedPayment."Affiliated to Line", 'A rejected combination must not affiliate source rows.');
        VerifyPaymentData(OriginalPayment, ExportedPayment);
    end;

    local procedure VerifyForeignExportFixture(EligiblePayment: Record "Ref. Payment - Exported FI"; DomesticPayment: Record "Ref. Payment - Exported FI"; SepaPayment: Record "Ref. Payment - Exported FI"; TransferredPayment: Record "Ref. Payment - Exported FI")
    begin
        Assert.IsTrue(EligiblePayment."Foreign Payment", 'The export fixture must contain a foreign payment.');
        Assert.IsFalse(EligiblePayment.Transferred, 'The export fixture must contain an unsent payment.');
        Assert.IsFalse(DomesticPayment."Foreign Payment", 'The unrelated domestic payment must not be foreign.');
        Assert.IsFalse(SepaPayment."Foreign Payment", 'This preservation case covers non-foreign SEPA, not foreign SEPA selected by LUM.');
        Assert.IsTrue(SepaPayment."SEPA Payment", 'The unrelated SEPA payment must have the SEPA flag.');
        Assert.IsTrue(TransferredPayment."Foreign Payment", 'The previously sent payment must exercise the foreign status exclusion.');
        Assert.IsTrue(TransferredPayment.Transferred, 'The status-excluded payment must already be transferred.');
    end;

    local procedure VerifyForeignExportedPayment(OriginalPayment: Record "Ref. Payment - Exported FI")
    var
        ExportedPayment: Record "Ref. Payment - Exported FI";
    begin
        ExportedPayment.Get(OriginalPayment."No.");
        Assert.IsTrue(OriginalPayment."Foreign Payment", 'The fixture must exercise the foreign selection path.');
        Assert.IsFalse(OriginalPayment.Transferred, 'The fixture must contain an unsent foreign payment.');
        Assert.IsTrue(ExportedPayment.Transferred, 'LUM must transfer the eligible foreign payment.');
        Assert.IsFalse(ExportedPayment."Applied Payments", 'The exported payment must remain an unapplied source row.');
        // Unlike LMP, LUM does not populate transfer timestamps or a batch code.
        VerifyPaymentData(OriginalPayment, ExportedPayment);
    end;

    local procedure VerifyExportRowCount(ExpectedCount: Integer)
    var
        ExportedPayment: Record "Ref. Payment - Exported FI";
    begin
        Assert.AreEqual(ExpectedCount, ExportedPayment.Count(), 'Unexpected number of payment rows after combination.');
    end;

    local procedure VerifyPaymentData(OriginalPayment: Record "Ref. Payment - Exported FI"; ExportedPayment: Record "Ref. Payment - Exported FI")
    begin
        Assert.AreEqual(OriginalPayment.Amount, ExportedPayment.Amount, 'The amount must be preserved.');
        Assert.AreEqual(OriginalPayment."Amount (LCY)", ExportedPayment."Amount (LCY)", 'The LCY amount must be preserved.');
        Assert.AreEqual(OriginalPayment."Currency Code", ExportedPayment."Currency Code", 'The currency must be preserved.');
        Assert.AreEqual(OriginalPayment."Payment Account", ExportedPayment."Payment Account", 'The payment bank must be preserved.');
        Assert.AreEqual(OriginalPayment."Vendor No.", ExportedPayment."Vendor No.", 'The vendor must be preserved.');
        Assert.AreEqual(OriginalPayment."Vendor Account", ExportedPayment."Vendor Account", 'The vendor bank must be preserved.');
        Assert.AreEqual(OriginalPayment."Payment Date", ExportedPayment."Payment Date", 'The payment date must be preserved.');
        Assert.AreEqual(OriginalPayment."Message Type", ExportedPayment."Message Type", 'The message type must be preserved.');
        Assert.AreEqual(OriginalPayment."Invoice Message", ExportedPayment."Invoice Message", 'The message must be preserved.');
        Assert.AreEqual(OriginalPayment."Document Type", ExportedPayment."Document Type", 'The document type must be preserved.');
        Assert.AreEqual(OriginalPayment."Foreign Payment", ExportedPayment."Foreign Payment", 'The foreign classification must be preserved.');
        Assert.AreEqual(OriginalPayment."SEPA Payment", ExportedPayment."SEPA Payment", 'The SEPA classification must be preserved.');
        Assert.AreEqual(OriginalPayment."Foreign Payment Method", ExportedPayment."Foreign Payment Method", 'The foreign payment method must be preserved.');
        Assert.AreEqual(OriginalPayment."Foreign Banks Service Fee", ExportedPayment."Foreign Banks Service Fee", 'The foreign service-fee instruction must be preserved.');
    end;

    local procedure VerifyForeignPayload(FileName: Text; ExportedPayment: Record "Ref. Payment - Exported FI"; Vendor: Record Vendor; VendorBankAccount: Record "Vendor Bank Account")
    var
        PaymentFile: File;
        FileLine: Text;
    begin
        PaymentFile.TextMode := true;
        PaymentFile.Open(FileName);
        Assert.IsTrue(PaymentFile.Read(FileLine) > 0, 'The LUM header must exist.');
        Assert.AreEqual(600, StrLen(FileLine), 'The LUM header must be 600 characters.');
        Assert.AreEqual('LUM200', CopyStr(FileLine, 1, 6), 'Unexpected LUM header.');
        Assert.AreEqual(Format(ExportedPayment."Payment Date", 0, '<Year4><Month,2><Day,2>'), CopyStr(FileLine, 51, 8), 'The header must retain the payment date.');
        Assert.IsTrue(PaymentFile.Read(FileLine) > 0, 'The LUM transaction must exist.');
        Assert.AreEqual(600, StrLen(FileLine), 'The LUM transaction must be 600 characters.');
        Assert.AreEqual('LUM21', CopyStr(FileLine, 1, 5), 'Unexpected LUM transaction.');
        Assert.AreEqual(CopyStr(Vendor.Name, 1, 35), CopyStr(FileLine, 7, 35), 'The vendor name must be truncated to 35 characters.');
        Assert.AreEqual(Vendor."Country/Region Code", CopyStr(FileLine, 147, 2), 'The beneficiary country must survive export.');
        Assert.AreEqual(VendorBankAccount.IBAN, DelChr(CopyStr(FileLine, 300, 34), '>', ' '), 'The beneficiary IBAN must survive export.');
        Assert.AreEqual(ExportedPayment."Invoice Message", DelChr(CopyStr(FileLine, 334, 70), '>', ' '), 'The payment message must survive export.');
        Assert.AreEqual('000000000100000', CopyStr(FileLine, 474, 15), 'The transaction must express the amount in cents.');
        Assert.AreEqual('EUR', CopyStr(FileLine, 489, 3), 'Blank payment currency must use the LUM EUR fallback.');
        Assert.AreEqual('FX-CONTRACT', DelChr(CopyStr(FileLine, 495, 14), '>', ' '), 'The exchange-rate contract must survive export.');
        Assert.AreEqual(ExportedPayment."Foreign Payment Method", CopyStr(FileLine, 509, 1), 'The payment method must survive export.');
        Assert.AreEqual(ExportedPayment."Foreign Banks Service Fee", CopyStr(FileLine, 510, 1), 'The service-fee instruction must survive export.');
        Assert.AreEqual(Format(ExportedPayment."Payment Date", 0, '<Day,2><Month,2><Year4>'), CopyStr(FileLine, 511, 8), 'Transaction-level handling must retain the payment date.');
        Assert.AreEqual('22290100087205', CopyStr(FileLine, 545, 14), 'The paying bank account must survive export.');
        Assert.AreEqual('EUR', CopyStr(FileLine, 559, 3), 'Blank paying-bank currency must use the LUM EUR fallback.');
        Assert.IsTrue(PaymentFile.Read(FileLine) > 0, 'The LUM footer must exist.');
        Assert.AreEqual(600, StrLen(FileLine), 'The LUM footer must be 600 characters.');
        Assert.AreEqual('LUM290', CopyStr(FileLine, 1, 6), 'Unexpected LUM footer.');
        Assert.AreEqual('00001', CopyStr(FileLine, 27, 5), 'Only one unsent foreign payment must be counted.');
        Assert.AreEqual('000000000100000', CopyStr(FileLine, 37, 15), 'The footer must total only the exported amount in cents.');
        Assert.IsTrue(PaymentFile.Read(FileLine) = 0, 'Domestic, non-foreign SEPA and previously sent rows must not create transactions.');
        PaymentFile.Close();
    end;

    local procedure VerifyDomesticPayload(FileName: Text; ExportedPayment: Record "Ref. Payment - Exported FI"; Vendor: Record Vendor)
    var
        PaymentFile: File;
        FileLine: Text;
    begin
        PaymentFile.TextMode := true;
        PaymentFile.Open(FileName);
        Assert.IsTrue(PaymentFile.Read(FileLine) > 0, 'The LMP header must exist.');
        Assert.AreEqual(300, StrLen(FileLine), 'The LMP header must be 300 characters.');
        Assert.AreEqual('LM0300', CopyStr(FileLine, 1, 6), 'Unexpected LMP header.');
        Assert.IsTrue(PaymentFile.Read(FileLine) > 0, 'The LMP transaction must exist.');
        Assert.AreEqual(300, StrLen(FileLine), 'The LMP transaction must be 300 characters.');
        Assert.AreEqual('LM0310', CopyStr(FileLine, 1, 6), 'Unexpected LMP transaction.');
        Assert.AreEqual('22290100087205', CopyStr(FileLine, 7, 14), 'The payload must contain the paying bank account.');
        Assert.AreEqual(CopyStr(Vendor.Name, 1, 30), CopyStr(FileLine, 21, 30), 'The payload must truncate the vendor name to 30 characters.');
        Assert.AreEqual('22290100087206', CopyStr(FileLine, 91, 14), 'The payload must contain the vendor bank account.');
        Assert.AreEqual('5', CopyStr(FileLine, 108, 1), 'The payload must use the message code.');
        Assert.AreEqual(ExportedPayment."Invoice Message", DelChr(CopyStr(FileLine, 109, 70), '>', ' '), 'The payload must retain the invoice message.');
        Assert.AreEqual(Format(ExportedPayment."Payment Date", 0, '<Year,2><Month,2><Day,2>'), CopyStr(FileLine, 181, 6), 'The payload must retain the due date.');
        Assert.AreEqual('000000100000', CopyStr(FileLine, 187, 12), 'The payload must express the amount in cents.');
        Assert.IsTrue(PaymentFile.Read(FileLine) > 0, 'The LMP footer must exist.');
        Assert.AreEqual(300, StrLen(FileLine), 'The LMP footer must be 300 characters.');
        Assert.AreEqual('LM0390', CopyStr(FileLine, 1, 6), 'Unexpected LMP footer.');
        Assert.AreEqual('000001', CopyStr(FileLine, 36, 6), 'The footer must count only the eligible transaction.');
        Assert.AreEqual('0000000100000', CopyStr(FileLine, 42, 13), 'The footer must total only the eligible amount in cents.');
        Assert.IsTrue(PaymentFile.Read(FileLine) = 0, 'Excluded rows must not add transactions to the file.');
        PaymentFile.Close();
    end;

    local procedure VerifyCombinedPayments(FirstPayment: Record "Ref. Payment - Exported FI"; SecondPayment: Record "Ref. Payment - Exported FI")
    var
        CombinedPayment: Record "Ref. Payment - Exported FI";
    begin
        CombinedPayment.SetRange("Applied Payments", false);
        Assert.AreEqual(1, CombinedPayment.Count(), 'Only one combined row must remain available.');
        CombinedPayment.FindFirst();
        Assert.AreEqual(FirstPayment."Foreign Payment", CombinedPayment."Foreign Payment", 'Combination must preserve the foreign classification.');
        Assert.AreEqual(FirstPayment."SEPA Payment", CombinedPayment."SEPA Payment", 'Combination must preserve the SEPA classification.');
        Assert.AreEqual(FirstPayment.Amount + SecondPayment.Amount, CombinedPayment.Amount, 'Combination must preserve the total.');
        Assert.AreEqual(FirstPayment."Amount (LCY)" + SecondPayment."Amount (LCY)", CombinedPayment."Amount (LCY)", 'Combination must preserve the LCY total.');
        Assert.AreEqual(FirstPayment."Vendor No.", CombinedPayment."Vendor No.", 'Combination must preserve the vendor.');
        Assert.AreEqual(FirstPayment."Vendor Account", CombinedPayment."Vendor Account", 'Combination must preserve the vendor bank.');
        Assert.AreEqual(FirstPayment."Payment Account", CombinedPayment."Payment Account", 'Combination must preserve the paying bank.');
        Assert.AreEqual(FirstPayment."Payment Date", CombinedPayment."Payment Date", 'Combination must preserve the date.');
        Assert.AreEqual(FirstPayment."Currency Code", CombinedPayment."Currency Code", 'Combination must preserve the currency.');
        Assert.AreEqual(FirstPayment."No.", CombinedPayment."Affiliated to Line", 'The combined row must affiliate to the first nonzero source identity.');
        Assert.IsFalse(CombinedPayment.Transferred, 'Combination must not transfer a payment.');
        VerifyAffiliatedSource(FirstPayment, CombinedPayment."Affiliated to Line");
        VerifyAffiliatedSource(SecondPayment, CombinedPayment."Affiliated to Line");
        VerifyExportRowCount(3);
    end;

    local procedure VerifyAffiliatedSource(OriginalPayment: Record "Ref. Payment - Exported FI"; AffiliatedLineNo: Integer)
    var
        SourcePayment: Record "Ref. Payment - Exported FI";
    begin
        SourcePayment.Get(OriginalPayment."No.");
        Assert.IsTrue(SourcePayment."Applied Payments", 'The source payment must be marked combined.');
        Assert.AreEqual(AffiliatedLineNo, SourcePayment."Affiliated to Line", 'The source must retain its group affiliation.');
        VerifyPaymentData(OriginalPayment, SourcePayment);
    end;

    local procedure PrepareFullPayment(var JournalLine: Record "Gen. Journal Line"; CustomerLedgerEntry: Record "Cust. Ledger Entry")
    begin
        // Boundary tests use a genuinely posted invoice and its detailed ledger balance.
        CustomerLedgerEntry.CalcFields("Remaining Amount");
        JournalLine."Account Type" := JournalLine."Account Type"::Customer;
        JournalLine."Account No." := CustomerLedgerEntry."Customer No.";
        JournalLine."Document Type" := JournalLine."Document Type"::Payment;
        JournalLine."Applies-to Doc. Type" := JournalLine."Applies-to Doc. Type"::Invoice;
        JournalLine."Applies-to Doc. No." := CustomerLedgerEntry."Document No.";
        JournalLine."Posting Date" := CustomerLedgerEntry."Posting Date";
        JournalLine.Amount := -CustomerLedgerEntry."Remaining Amount";
    end;

    local procedure PreparePartialPayment(var JournalLine: Record "Gen. Journal Line"; CustomerLedgerEntry: Record "Cust. Ledger Entry") ExpectedDiscount: Decimal
    begin
        PrepareFullPayment(JournalLine, CustomerLedgerEntry);
        Assert.AreEqual(0, CustomerLedgerEntry."Accepted Payment Tolerance", 'The partial-discount branch requires no accepted tolerance.');
        ExpectedDiscount := CustomerLedgerEntry."Remaining Pmt. Disc. Possible" / 2;
        Assert.IsTrue(ExpectedDiscount > 0, 'The partial payment must leave a nonzero eligible discount.');
        // Pay more than the net discounted amount, but less than the gross invoice amount.
        JournalLine.Amount += ExpectedDiscount;
    end;

    local procedure CreateFullPaymentJournal(var JournalLine: Record "Gen. Journal Line"; CustomerLedgerEntry: Record "Cust. Ledger Entry")
    var
        BankAccount: Record "Bank Account";
        JournalBatch: Record "Gen. Journal Batch";
    begin
        CustomerLedgerEntry.CalcFields("Remaining Amount");
        LibraryERM.CreateBankAccount(BankAccount);
        CreateJournalBatch(JournalBatch, BankAccount."No.", true);
        LibraryERM.CreateGeneralJnlLine(
            JournalLine, JournalBatch."Journal Template Name", JournalBatch.Name,
            JournalLine."Document Type"::Payment, JournalLine."Account Type"::Customer,
            CustomerLedgerEntry."Customer No.", -CustomerLedgerEntry."Remaining Amount");
        JournalLine.Validate("Applies-to Doc. Type", JournalLine."Applies-to Doc. Type"::Invoice);
        JournalLine.Validate("Applies-to Doc. No.", CustomerLedgerEntry."Document No.");
        JournalLine.Modify(true);
    end;

    local procedure VerifyPostedFullPayment(CustomerLedgerEntry: Record "Cust. Ledger Entry"; PaymentDocumentNo: Code[20])
    var
        PaymentEntry: Record "Cust. Ledger Entry";
    begin
        CustomerLedgerEntry.Get(CustomerLedgerEntry."Entry No.");
        CustomerLedgerEntry.CalcFields("Remaining Amount");
        Assert.IsFalse(CustomerLedgerEntry.Open, 'The full payment must close the invoice.');
        Assert.AreEqual(0, CustomerLedgerEntry."Remaining Amount", 'The invoice must have no residual balance.');
        Assert.AreEqual(0, CustomerLedgerEntry."Remaining Pmt. Disc. Possible", 'The new FI field must clear the full-payment discount.');
        Assert.AreEqual(0, CustomerLedgerEntry."Pmt. Disc. Given (LCY)", 'No payment discount may be taken on the invoice.');
        PaymentEntry.SetRange("Customer No.", CustomerLedgerEntry."Customer No.");
        PaymentEntry.SetRange("Document Type", PaymentEntry."Document Type"::Payment);
        PaymentEntry.SetRange("Document No.", PaymentDocumentNo);
        Assert.AreEqual(1, PaymentEntry.Count(), 'Exactly one payment must have been posted.');
        PaymentEntry.FindFirst();
        PaymentEntry.CalcFields("Remaining Amount");
        Assert.IsFalse(PaymentEntry.Open, 'The full payment must also close.');
        Assert.AreEqual(0, PaymentEntry."Remaining Amount", 'The payment must not retain an unapplied discount balance.');
    end;

    local procedure VerifyDiscount(OriginalEntry: Record "Cust. Ledger Entry"; ExpectedDiscount: Decimal)
    var
        CustomerLedgerEntry: Record "Cust. Ledger Entry";
    begin
        CustomerLedgerEntry.Get(OriginalEntry."Entry No.");
        CustomerLedgerEntry.CalcFields("Remaining Amount", "Original Amount");
        Assert.AreEqual(ExpectedDiscount, CustomerLedgerEntry."Remaining Pmt. Disc. Possible", 'Unexpected remaining discount after the FI full-payment check.');
        Assert.AreEqual(CustomerLedgerEntry."Original Amount", CustomerLedgerEntry."Remaining Amount", 'Checking discount must not post or change the original unpaid balance.');
        Assert.IsTrue(CustomerLedgerEntry.Open, 'Checking discount must not close the invoice.');
    end;

    local procedure ReleaseSubscriptions()
    begin
        LibrarySetupStorage.Restore();
        UnbindSubscription(LibraryFileMgtHandler);
    end;

    [RequestPageHandler]
    procedure ImportRequestPage(var RequestPage: TestRequestPage "Import Ref. Payment FI")
    begin
        RequestPage.BankAccCode.SetValue(LibraryVariableStorage.DequeueText());
        RequestPage.OK().Invoke();
    end;

    [MessageHandler]
    procedure UnmatchedPaymentMessage(Message: Text[1024])
    begin
        LibraryVariableStorage.Enqueue(Message);
    end;
}
