codeunit 144071 "UT PAG LocNum"
{
    // 1. Purpose of the test is to validate Preview Check on Payment Journal when Account Type Vendor and Credit Amount zero.
    // 2. Purpose of the test is to validate Preview Check on Payment Journal when Account Type Vendor and Debit Amount zero.
    // 3. Purpose of the test is to validate Preview Check on Payment Journal when Account Type Customer and Credit Amount zero.
    // 4. Purpose of the test is to validate Preview Check on Payment Journal when Account Type Customer and Debit Amount zero.
    // 
    // Covers Test Cases for WI - 351132
    // -----------------------------------------------------------------------
    // Test Function Name                                               TFS ID
    // -----------------------------------------------------------------------
    // CheckPreviewPaymentJournalWithVendorDebitAmount                  151230
    // CheckPreviewPaymentJournalWithVendorCreditAmount                 151232
    // CheckPreviewPaymentJournalWithCustomerDebitAmount                151231
    // CheckPreviewPaymentJournalWithCustomerCreditAmount               151233

    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
    end;

    var
        LibraryUTUtility: Codeunit "Library UT Utility";
        LibraryRandom: Codeunit "Library - Random";

    //[Test]
    [Scope('OnPrem')]
    procedure CheckPreviewPaymentJournalWithVendorDebitAmount()
    var
        GenJournalLine: Record "Gen. Journal Line";
        Amount: Decimal;
    begin
        // Purpose of the test is to validate Preview Check on Payment Journal when Account Type Vendor and Credit Amount zero.

        // Setup.
        Amount := LibraryRandom.RandDec(100, 2);
        CheckPreviewPaymentJournal(GenJournalLine."Account Type"::Vendor, CreateVendor(), 0, Amount, Amount);  // Using 0 for Credit Amount, Random - Debit Amount, Amount.
    end;

    //[Test]
    [Scope('OnPrem')]
    procedure CheckPreviewPaymentJournalWithVendorCreditAmount()
    var
        GenJournalLine: Record "Gen. Journal Line";
        Amount: Decimal;
    begin
        // Purpose of the test is to validate Preview Check on Payment Journal when Account Type Vendor and Debit Amount zero.

        // Setup.
        Amount := LibraryRandom.RandDec(100, 2);
        CheckPreviewPaymentJournal(GenJournalLine."Account Type"::Vendor, CreateVendor(), Amount, 0, Amount);  // Using 0 for Debit Amount, Random - Credit Amount, Amount.
    end;

    //[Test]
    [Scope('OnPrem')]
    procedure CheckPreviewPaymentJournalWithCustomerDebitAmount()
    var
        GenJournalLine: Record "Gen. Journal Line";
        Amount: Decimal;
    begin
        // Purpose of the test is to validate Preview Check on Payment Journal when Account Type Customer and Credit Amount zero.

        // Setup.
        Amount := LibraryRandom.RandDec(100, 2);
        CheckPreviewPaymentJournal(GenJournalLine."Account Type"::Customer, CreateCustomer(), 0, Amount, Amount);  // Using 0 for Credit Amount, Random - Debit Amount, Amount.
    end;

    //[Test]
    [Scope('OnPrem')]
    procedure CheckPreviewPaymentJournalWithCustomerCreditAmount()
    var
        GenJournalLine: Record "Gen. Journal Line";
        Amount: Decimal;
    begin
        // Purpose of the test is to validate Preview Check on Payment Journal when Account Type Customer and Debit Amount zero.

        // Setup.
        Amount := LibraryRandom.RandDec(100, 2);
        CheckPreviewPaymentJournal(GenJournalLine."Account Type"::Customer, CreateCustomer(), Amount, 0, Amount);  // Using 0 for Debit Amount, Random - Credit Amount, Amount.
    end;

    local procedure CheckPreviewPaymentJournal(AccountType: Enum "Gen. Journal Document Type"; AccountNo: Code[20]; CreditAmount: Decimal; DebitAmount: Decimal; Amount: Decimal)
    var
        GenJournalLine: Record "Gen. Journal Line";
        DocumentNo: Code[20];
    begin
        // Create General Journal Line.
        DocumentNo := CreateGenJournalLine(AccountType, AccountNo, CreditAmount, DebitAmount, Amount);
        Commit();

        // Exercise.
        OpenPagePaymentJournalPreviewCheck(DocumentNo);

        // Verify: Verify values and Check Amount in text on Check Preview page.
        VerifyCheckPreviewPage(DocumentNo, Amount);

        // Tear Down.
        GenJournalLine.SetRange("Document No.", DocumentNo);
        GenJournalLine.DeleteAll();
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

    local procedure CreateGenJournalLine(AccountType: Enum "Gen. Journal Account Type"; AccountNo: Code[20]; CreditAmount: Decimal; DebitAmount: Decimal; Amount: Decimal): Code[20]
    var
        GenJournalLine: Record "Gen. Journal Line";
        GenJournalLine2: Record "Gen. Journal Line";
    begin
        GenJournalLine2.FindLast();
        GenJournalLine."Line No." := GenJournalLine2."Line No." + LibraryRandom.RandInt(10);
        GenJournalLine."Document No." := LibraryUTUtility.GetNewCode();
        GenJournalLine."Account Type" := AccountType;
        GenJournalLine."Account No." := AccountNo;
        GenJournalLine."Document Type" := GenJournalLine."Document Type"::Payment;
        GenJournalLine."Credit Amount" := CreditAmount;
        GenJournalLine."Debit Amount" := DebitAmount;
        GenJournalLine.Amount := Amount;
        GenJournalLine."Bal. Account Type" := GenJournalLine."Bal. Account Type"::"Bank Account";
        GenJournalLine."Bal. Account No." := CreateBankAccount();
        GenJournalLine."Bank Payment Type" := GenJournalLine."Bank Payment Type"::"Computer Check";
        GenJournalLine.Insert();
        exit(GenJournalLine."Document No.");
    end;

    local procedure CreateVendor(): Code[20]
    var
        Vendor: Record Vendor;
    begin
        Vendor."No." := LibraryUTUtility.GetNewCode();
        Vendor.Insert();
        exit(Vendor."No.");
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

    local procedure VerifyCheckPreviewPage(DocumentNo: Code[20]; CheckAmount: Decimal)
    var
        CompanyInformation: Record "Company Information";
        CheckPreview: TestPage "Check Preview";
        Check: Report Check;
        AmountText: array[2] of Text[80];
    begin
        CompanyInformation.Get();
        CheckPreview.OpenEdit();
        CheckPreview.FILTER.SetFilter("Document No.", DocumentNo);
        CheckPreview."CompanyAddr[1]".AssertEquals(CompanyInformation.Name);
        CheckPreview.CheckAmount.AssertEquals(CheckAmount);

        // Verify Check Amount in text.
        Check.InitTextVariable();
        Check.FormatNoText(AmountText, CheckAmount, '');  // Use blank for Currency.
        CheckPreview.AmountText.AssertEquals(AmountText[1]);
        CheckPreview.Close();
    end;
}

