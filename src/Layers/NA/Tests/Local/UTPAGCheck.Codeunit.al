codeunit 141003 "UT PAG Check"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Check Preview] [UI]
    end;

    var
        LibraryUTUtility: Codeunit "Library UT Utility";
        LibraryRandom: Codeunit "Library - Random";

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnAfterGetRecordAccountTypeGLAccountCheckPreview()
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        // Purpose of the test is to validate OnAfterGetRecord Trigger of PAGE - 404 Check Preview.
        OnAfterGetRecordAccountTypeCheckPreview(GenJournalLine."Account Type"::"G/L Account", '');  // Blank value for General Ledger Account number.
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnAfterGetRecordAccountTypeCustomerCheckPreview()
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        // Purpose of the test is to validate OnAfterGetRecord Trigger of PAGE - 404 Check Preview.
        OnAfterGetRecordAccountTypeCheckPreview(GenJournalLine."Account Type"::Customer, CreateCustomer());
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnAfterGetRecordAccountTypeVendorCheckPreview()
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        // Purpose of the test is to validate OnAfterGetRecord Trigger of PAGE - 404 Check Preview.
        OnAfterGetRecordAccountTypeCheckPreview(GenJournalLine."Account Type"::Vendor, CreateVendor());
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnAfterGetRecordAccountTypeBankAccountCheckPreview()
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        // Purpose of the test is to validate OnAfterGetRecord Trigger of PAGE - 404 Check Preview.
        OnAfterGetRecordAccountTypeCheckPreview(GenJournalLine."Account Type"::"Bank Account", CreateBankAccount());
    end;

    local procedure OnAfterGetRecordAccountTypeCheckPreview(AccountType: Enum "Gen. Journal Account Type"; AccountNo: Code[20])
    var
        GenJournalLine: Record "Gen. Journal Line";
        CheckPreview: TestPage "Check Preview";
    begin
        // Create General Journal Line for required Account Type.
        CreateGeneralJournalLine(GenJournalLine, AccountType, AccountNo);

        // Exercise: Open Page - Check Preview.
        CheckPreview.OpenEdit();
        CheckPreview.GotoRecord(GenJournalLine);

        // Verify: Verify Document Number, Check Status Text and Amount on Check Preview Page.
        CheckPreview."Document No.".AssertEquals(GenJournalLine."Document No.");
        CheckPreview.CheckStatusText.AssertEquals('Printed Check');
        CheckPreview.CheckAmount.AssertEquals(GenJournalLine.Amount);
    end;

    local procedure CreateBankAccount(): Code[20]
    var
        BankAccount: Record "Bank Account";
        CompanyInformation: Record "Company Information";
    begin
        CompanyInformation.Get();
        BankAccount."No." := LibraryUTUtility.GetNewCode();
        BankAccount."Country/Region Code" := 'CA';
        BankAccount."Check Date Format" := LibraryRandom.RandIntInRange(0, 3);  // Check Date Format - option Range 0 to 3.
        BankAccount."Bank Communication" := LibraryRandom.RandIntInRange(0, 2);  // Bank Communication - option Range 0 to 2.
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

    local procedure CreateGeneralJournalLine(var GenJournalLine: Record "Gen. Journal Line"; AccountType: Enum "Gen. Journal Account Type"; AccountNo: Code[20])
    var
        GenJournalBatch: Record "Gen. Journal Batch";
    begin
        CreateGeneralJournalTemplateAndBatch(GenJournalBatch);
        GenJournalLine."Journal Template Name" := GenJournalBatch."Journal Template Name";
        GenJournalLine."Journal Batch Name" := GenJournalBatch.Name;
        GenJournalLine."Line No." := LibraryRandom.RandInt(10);
        GenJournalLine."Account Type" := AccountType;
        GenJournalLine."Account No." := AccountNo;
        GenJournalLine."Bal. Account Type" := GenJournalLine."Bal. Account Type"::"Bank Account";
        GenJournalLine."Bal. Account No." := CreateBankAccount();
        GenJournalLine."Document No." := LibraryUTUtility.GetNewCode();
        GenJournalLine."Bank Payment Type" := GenJournalLine."Bank Payment Type"::"Computer Check";
        GenJournalLine.Amount := LibraryRandom.RandDec(10, 2);
        GenJournalLine."Check Printed" := true;  // Default value - FALSE, update as TRUE.
        GenJournalLine.Insert();
    end;

    local procedure CreateGeneralJournalTemplateAndBatch(var GenJournalBatch: Record "Gen. Journal Batch")
    var
        GenJournalTemplate: Record "Gen. Journal Template";
    begin
        GenJournalTemplate.Name := LibraryUTUtility.GetNewCode10();
        GenJournalTemplate.Insert();
        GenJournalBatch."Journal Template Name" := GenJournalTemplate.Name;
        GenJournalBatch.Name := LibraryUTUtility.GetNewCode10();
        GenJournalBatch.Insert();
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

