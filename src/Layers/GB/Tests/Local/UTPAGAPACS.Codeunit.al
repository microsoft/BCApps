#if not CLEAN27
codeunit 144010 "UT PAG APACS"
{
    // 1. Purpose of the test is to validate Preview Check GB on Payment Journal When Check Printed True Account Type Customer.
    // 2. Purpose of the test is to validate Preview Check GB on Payment Journal When Check Printed False Account Type Customer.
    // 3. Purpose of the test is to validate Preview Check GB on Payment Journal When Check Printed True Account Type Vendor.
    // 4. Purpose of the test is to validate Preview Check GB on Payment Journal When Check Printed False Account Type Vendor.
    // 5. Purpose of the test is to validate Preview Check GB on Payment Journal When Check Printed True Account Type Bank Account.
    // 6. Purpose of the test is to validate Preview Check GB on Payment Journal When Check Printed False Account Type Bank Account.
    // 7. Purpose of the test is to validate Preview Check GB on Payment Journal When Check Printed True Account Type Fixed Asset.
    // 8. Purpose of the test is to validate Preview Check GB on Payment Journal When Check Printed False Account Type Fixed Asset.
    // 
    // Covers Test Cases for WI - 340238
    // -----------------------------------------------------------------------
    // Test Function Name                                              TFS ID
    // -----------------------------------------------------------------------
    // CheckPrintedTrueAccountTypeCustomerPaymentJournal               153335
    // CheckPrintedFalseAccountTypeCustomerPaymentJournal              153335
    // CheckPrintedTrueAccountTypeVendorPaymentJournal                 153335
    // CheckPrintedFalseAccountTypeVendorPaymentJournal                153335
    // CheckPrintedTrueAccountTypeBankAccountPaymentJournal            153335
    // CheckPrintedFalseAccountTypeBankAccountPaymentJournal           153335
    // CheckPrintedTrueAccountTypeFixedAssetPaymentJournal             153335
    // CheckPrintedFalseAccountTypeFixedAssetPaymentJournal            153335

    Subtype = Test;
    TestPermissions = Disabled;
    ObsoleteState = Pending;
    ObsoleteReason = 'Page it is testing is obsolete.';
    ObsoleteTag = '27.0';

    trigger OnRun()
    begin
    end;

    var
        Assert: Codeunit Assert;
        LibraryUTUtility: Codeunit "Library UT Utility";
        LibraryRandom: Codeunit "Library - Random";

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure CheckPrintedTrueAccountTypeCustomerPaymentJournal()
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        // Purpose of the test is to validate Preview Check GB on Payment Journal When Check Printed True Account Type Customer.
        PreviewCheckPaymentJournal(true, GenJournalLine."Account Type"::Customer, CreateCustomer());
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure CheckPrintedFalseAccountTypeCustomerPaymentJournal()
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        // Purpose of the test is to validate Preview Check GB on Payment Journal When Check Printed False Account Type Customer.
        PreviewCheckPaymentJournal(false, GenJournalLine."Account Type"::Customer, CreateCustomer());
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure CheckPrintedTrueAccountTypeVendorPaymentJournal()
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        // Purpose of the test is to validate Preview Check GB on Payment Journal When Check Printed True Account Type Vendor.
        PreviewCheckPaymentJournal(true, GenJournalLine."Account Type"::Vendor, CreateVendor());
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure CheckPrintedFalseAccountTypeVendorPaymentJournal()
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        // Purpose of the test is to validate Preview Check GB on Payment Journal When Check Printed False Account Type Vendor.
        PreviewCheckPaymentJournal(false, GenJournalLine."Account Type"::Vendor, CreateVendor());
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure CheckPrintedTrueAccountTypeBankAccountPaymentJournal()
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        // Purpose of the test is to validate Preview Check GB on Payment Journal When Check Printed True Account Type Bank Account.
        PreviewCheckPaymentJournal(true, GenJournalLine."Account Type"::"Bank Account", CreateBankAccount());
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure CheckPrintedFalseAccountTypeBankAccountPaymentJournal()
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        // Purpose of the test is to validate Preview Check GB on Payment Journal When Check Printed False Account Type Bank Account.
        PreviewCheckPaymentJournal(false, GenJournalLine."Account Type"::"Bank Account", CreateBankAccount());
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure CheckPrintedTrueAccountTypeFixedAssetPaymentJournal()
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        // Purpose of the test is to validate Preview Check GB on Payment Journal When Check Printed True Account Type Fixed Asset.
        PreviewCheckPaymentJournal(true, GenJournalLine."Account Type"::"Fixed Asset", CreateFixedAsset());
    end;

    local procedure PreviewCheckPaymentJournal(CheckPrinted: Boolean; AccountType: Enum "Gen. Journal Account Type"; AccountNo: Code[20])
    var
        DocumentNo: Code[20];
    begin
        // Setup.
        DocumentNo := CreateGenJournalLine(CheckPrinted, AccountType, AccountNo);

        // Exercise.
        OpenPagePaymentJournalPreviewCheck(DocumentNo);

        // Verify.
        OpenPageCheckPreviewGB(DocumentNo);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure CheckPrintedFalseAccountTypeFixedAssetPaymentJournalError()
    var
        GenJournalLine: Record "Gen. Journal Line";
        DocumentNo: Code[20];
    begin
        // Purpose of the test is to validate Preview Check GB on Payment Journal When Check Printed False Account Type Fixed Asset.

        // Setup.
        DocumentNo := CreateGenJournalLine(false, GenJournalLine."Account Type"::"Fixed Asset", CreateFixedAsset());
        OpenPagePaymentJournalPreviewCheck(DocumentNo);

        // Exercise.
        asserterror OpenPageCheckPreviewGB(DocumentNo);

        // Verify. Verify actual error,Account Type must not be Fixed Asset in Gen. Journal Line Journal Template Name.
        Assert.ExpectedErrorCode('FormAbort:CSide');
    end;

    local procedure CreateBankAccount(): Code[20]
    var
        BankAccount: Record "Bank Account";
    begin
        BankAccount."No." := LibraryUTUtility.GetNewCode();
        BankAccount.Insert();
        exit(BankAccount."No.");
    end;

    local procedure CreateCustomer(): Code[20]
    var
        Customer: Record Customer;
    begin
        Customer."No." := LibraryUTUtility.GetNewCode();
        Customer.Insert();
        exit(Customer."No.");
    end;

    local procedure CreateFixedAsset(): Code[20]
    var
        FixedAsset: Record "Fixed Asset";
    begin
        FixedAsset."No." := LibraryUTUtility.GetNewCode();
        FixedAsset.Insert();
        exit(FixedAsset."No.");
    end;

    local procedure CreateVendor(): Code[20]
    var
        Vendor: Record Vendor;
    begin
        Vendor."No." := LibraryUTUtility.GetNewCode();
        Vendor.Insert();
        exit(Vendor."No.");
    end;

    local procedure CreateGenJournalLine(CheckPrinted: Boolean; AccountType: Enum "Gen. Journal Account Type"; AccountNo: Code[20]): Code[20]
    var
        GenJournalLine: Record "Gen. Journal Line";
        GenJournalLine2: Record "Gen. Journal Line";
    begin
        GenJournalLine2.FindLast();
        GenJournalLine."Line No." := GenJournalLine2."Line No." + 10;
        GenJournalLine."Account Type" := AccountType;
        GenJournalLine."Account No." := AccountNo;
        GenJournalLine."Document Type" := GenJournalLine."Document Type"::Payment;
        GenJournalLine."Document No." := LibraryUTUtility.GetNewCode();
        GenJournalLine.Description := LibraryUTUtility.GetNewCode();
        GenJournalLine.Amount := LibraryRandom.RandDec(10, 2);
        GenJournalLine."Bal. Account Type" := GenJournalLine."Bal. Account Type"::"Bank Account";
        GenJournalLine."Bal. Account No." := CreateBankAccount();
        GenJournalLine."Check Printed" := CheckPrinted;
        GenJournalLine.Insert();
        exit(GenJournalLine."Document No.");
    end;

    local procedure OpenPagePaymentJournalPreviewCheck(DocumentNo: Code[20])
    var
        PaymentJournal: TestPage "Payment Journal";
    begin
        PaymentJournal.OpenEdit();
        PaymentJournal.FILTER.SetFilter("Document No.", DocumentNo);
        PaymentJournal.PreviewCheck.Invoke();
        PaymentJournal.Close();
    end;

    local procedure OpenPageCheckPreviewGB(DocumentNo: Code[20])
    var
        CheckPreviewGB: TestPage "Check Preview GB";
    begin
        CheckPreviewGB.OpenEdit();
        CheckPreviewGB.FILTER.SetFilter("Document No.", DocumentNo);
        CheckPreviewGB.Close();
    end;
}
#endif
