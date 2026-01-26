codeunit 144041 "UT PAG Number To Text"
{
    // 1. Purpose of the test is to verify amount in text on Page Check Preview Account Type Vendor.
    // 2. Purpose of the test is to verify amount in text on Page Check Preview Account Type Customer.
    // 
    // Covers Test Cases for WI - 344432.
    // -----------------------------------------------------------------------
    // Test Function Name                                       TFS ID
    // -----------------------------------------------------------------------
    // PreviewCheckAccountTypeVendorPaymentJournal              151195,151197
    // PreviewCheckAccountTypeCustomerPaymentJournal            151196,151198

    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
    end;

    var
        LibraryUTUtility: Codeunit "Library UT Utility";
        LibraryRandom: Codeunit "Library - Random";

    //[Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure PreviewCheckAccountTypeVendorPaymentJournal()
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        // Purpose of the test is to verify amount in text on Page Check Preview Account Type Vendor.
        PreviewCheckPaymentJournal(GenJournalLine."Account Type"::Vendor, CreateVendor());
    end;

    //[Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure PreviewCheckAccountTypeCustomerPaymentJournal()
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        // Purpose of the test is to verify amount in text on Page Check Preview Account Type Customer.
        PreviewCheckPaymentJournal(GenJournalLine."Account Type"::Customer, CreateCustomer());
    end;

    local procedure PreviewCheckPaymentJournal(AccountType: Enum "Gen. Journal Account Type"; AccountNo: Code[20])
    var
        GenJournalLine: Record "Gen. Journal Line";
        Check: Report Check;
        CheckPreview: TestPage "Check Preview";
        AmountInText: array[2] of Text[80];
    begin
        // Setup: Create General Journal Line and Calculate Amount in Text.
        CreateGenJournalLine(GenJournalLine, AccountType, AccountNo);
        Check.InitTextVariable();
        Check.FormatNoText(AmountInText, GenJournalLine.Amount, '');  // Use blank for Currency.

        // Exercise.
        CheckPreview.OpenView();

        // Verify: Verify Amount in Text on Page.
        CheckPreview.FILTER.SetFilter("Document No.", GenJournalLine."Document No.");
        CheckPreview.AmountText.AssertEquals(AmountInText[1]);

        // Teardown.
        CheckPreview.Close();
    end;

    local procedure CreateCustomer(): Code[20]
    var
        Customer: Record Customer;
    begin
        Customer."No." := LibraryUTUtility.GetNewCode();
        Customer.Insert();
        exit(Customer."No.");
    end;

    local procedure CreateGenJournalLine(var GenJournalLine: Record "Gen. Journal Line"; AccountType: Enum "Gen. Journal Account Type"; AccountNo: Code[20])
    begin
        GenJournalLine."Account Type" := AccountType;
        GenJournalLine."Account No." := AccountNo;
        GenJournalLine."Document Type" := GenJournalLine."Document Type"::Payment;
        GenJournalLine."Document No." := LibraryUTUtility.GetNewCode();
        GenJournalLine.Description := LibraryUTUtility.GetNewCode();
        GenJournalLine.Amount := LibraryRandom.RandDec(10, 2);
        GenJournalLine."Bal. Account Type" := GenJournalLine."Bal. Account Type"::"Bank Account";
        GenJournalLine."Bal. Account No." := LibraryUTUtility.GetNewCode();
        GenJournalLine.Insert();
    end;

    local procedure CreateVendor(): Code[20]
    var
        Vendor: Record Vendor;
    begin
        Vendor."No." := LibraryUTUtility.GetNewCode();
        Vendor.Insert();
        exit(Vendor."No.");
    end;
}

