codeunit 134036 "ERM Customer Balance Manl Appl"
{
    Subtype = Test;
    TestPermissions = NonRestrictive;

    trigger OnRun()
    begin
        // [FEATURE] [General Journal Line] [Balance (LCY)]
        IsInitialized := false;
    end;

    var
        LibraryERM: Codeunit "Library - ERM";
        LibraryRandom: Codeunit "Library - Random";
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        IsInitialized: Boolean;

    [Test]
    [Scope('OnPrem')]
    procedure CustomerWithBalancingAcc()
    var
        GenJournalLine: Record "Gen. Journal Line";
        InvoiceBalanceLCY: Decimal;
    begin
        // Application using Applies to Document No. and Verify Balance LCY field on General Journal Line.

        // Setup.
        // Create and Post General Journal Line for Invoice and Payment.
        Initialize();
        CreateGeneralJournalLine(
          GenJournalLine, GenJournalLine."Document Type"::Invoice, GenJournalLine."Account Type"::Customer, CreateCustomer(),
          GenJournalLine."Bal. Account Type"::"Bank Account", CreateBankAccount(), LibraryRandom.RandDec(5, 2));
        InvoiceBalanceLCY := GenJournalLine."Balance (LCY)";
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
        CreateGeneralJournalLine(
          GenJournalLine, GenJournalLine."Document Type"::Payment, GenJournalLine."Bal. Account Type"::"Bank Account",
          GenJournalLine."Bal. Account No.", GenJournalLine."Account Type"::Customer, GenJournalLine."Account No.", GenJournalLine.Amount);
        InvoiceBalanceLCY += GenJournalLine."Balance (LCY)";

        // Exercise: Execute Application of Payment Entry to Invoice.
        UpdateGeneralJournalLine(GenJournalLine, GenJournalLine."Document No.");

        // Verify: Verify Balance LCY field on General Journal Line.
        GenJournalLine.TestField("Balance (LCY)", InvoiceBalanceLCY);

        // Teardown: Delete unposted General Journal Line for test case cleanup.
        GenJournalLine.Delete(true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CustomerWithoutBalancingAcc()
    var
        GenJournalLine: Record "Gen. Journal Line";
        Assert: Codeunit Assert;
        InvoiceAmount: Decimal;
        BalanceLCY: Decimal;
    begin
        // Create General Journal Lines for invoice and Payment and Verify Balance LCY field.

        // Setup.
        Initialize();

        // Exercise: Create General Journal Line for both Invoice and Payment.
        CreateGeneralJournalLine(
          GenJournalLine, GenJournalLine."Document Type"::Invoice, GenJournalLine."Account Type"::Customer, CreateCustomer(),
          GenJournalLine."Bal. Account Type"::"Bank Account", '', LibraryRandom.RandDec(5, 2));
        InvoiceAmount := GenJournalLine.Amount;
        BalanceLCY := GenJournalLine."Balance (LCY)";
        CreateGeneralJournalLine(
          GenJournalLine, GenJournalLine."Document Type"::Payment, GenJournalLine."Bal. Account Type"::"Bank Account", CreateBankAccount(),
          GenJournalLine."Bal. Account Type"::"Bank Account", '', LibraryRandom.RandDec(5, 2));
        InvoiceAmount += GenJournalLine.Amount;
        BalanceLCY += GenJournalLine."Balance (LCY)";

        // Verify: Verify Balance LCY field on General Journal Line.
        Assert.AreEqual(InvoiceAmount, BalanceLCY, 'Amount Must be equal');

        // Teardown: Delete all unposted General Journal Lines for test case cleanup.
        GenJournalLine.DeleteAll(true);
    end;

    local procedure Initialize()
    var
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"ERM Customer Balance Manl Appl");
        if IsInitialized then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"ERM Customer Balance Manl Appl");
        LibraryERMCountryData.CreateVATData();
        LibraryERMCountryData.UpdateGeneralPostingSetup();
        IsInitialized := true;
        Commit();
        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"ERM Customer Balance Manl Appl");
    end;

    local procedure CreateCustomer(): Code[20]
    var
        Customer: Record Customer;
        LibrarySales: Codeunit "Library - Sales";
    begin
        LibrarySales.CreateCustomer(Customer);
        exit(Customer."No.");
    end;

    local procedure CreateBankAccount(): Code[20]
    var
        BankAccount: Record "Bank Account";
        BankAccountPostingGroup: Record "Bank Account Posting Group";
    begin
        BankAccountPostingGroup.FindLast();
        LibraryERM.CreateBankAccount(BankAccount);
        BankAccount.Validate("Bank Acc. Posting Group", BankAccountPostingGroup.Code);
        BankAccount.Modify(true);
        exit(BankAccount."No.");
    end;

    local procedure CreateGeneralJournalLine(var GenJournalLine: Record "Gen. Journal Line"; DocumentType: Enum "Gen. Journal Document Type"; AccountType: Enum "Gen. Journal Account Type"; AccountNo: Code[20]; BalAccountType: Enum "Gen. Journal Account Type"; BalAccountNo: Code[20]; ApplicationAmount: Decimal)
    var
        GenJournalBatch: Record "Gen. Journal Batch";
    begin
        LibraryERM.SelectGenJnlBatch(GenJournalBatch);
        LibraryERM.ClearGenJournalLines(GenJournalBatch);
        LibraryERM.CreateGeneralJnlLine(
          GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name, DocumentType, AccountType,
          AccountNo, ApplicationAmount);
        GenJournalLine.Validate("Bal. Account Type", BalAccountType);
        GenJournalLine.Validate("Bal. Account No.", BalAccountNo);
        GenJournalLine.Modify(true);
    end;

    local procedure UpdateGeneralJournalLine(GenJournalLine: Record "Gen. Journal Line"; DocumentNo: Code[20])
    begin
        GenJournalLine.Validate("Applies-to Doc. Type", GenJournalLine."Document Type"::Invoice);
        GenJournalLine.Validate("Applies-to Doc. No.", DocumentNo);
        GenJournalLine.Modify(true);
    end;
}

