codeunit 144026 "UT COD Required Description"
{
    // 1. Purpose of the test is to verify error Account Type G/L Account and Description blank on General Journal.
    // 2. Purpose of the test is to verify error Account Type Customer and Description blank on General Journal.
    // 3. Purpose of the test is to verify error Account Type Vendor and Description blank on General Journal.
    // 4. Purpose of the test is to verify error Account Type Bank Account and Description blank on General Journal.
    // 5. Purpose of the test is to verify error Account Type Fixed Asset and Description blank on FA G/L Journal.
    // 6. Purpose of the test is to verify error Account Type G/L Account and Description blank on Cash Journal.
    // 7. Purpose of the test is to verify error Account Type Customer and Description blank on Cash Journal.
    // 8. Purpose of the test is to verify error Account Type Vendor and Description blank on Cash Journal.
    // 9. Purpose of the test is to verify error Account Type Bank Account and Description blank on Cash Journal.
    // 
    // Covers Test Cases for WI - 341774
    // -----------------------------------------------------------------------
    // Test Function Name                                         TFS ID
    // -----------------------------------------------------------------------
    // GLAccountDescriptionBlankOnGeneralJournal                  152078
    // CustomerDescriptionBlankOnGeneralJournal                   152079
    // VendorDescriptionBlankOnGeneralJournal                     152080
    // BankAccountDescriptionBlankOnGeneralJournal                152081
    // FixedAssetDescriptionBlankOnGeneralJournal                 152082
    // GLAccountDescriptionBlankOnCashJournal                     152083
    // CustomerDescriptionBlankOnCashJournal                      152084
    // VendorDescriptionBlankOnCashJournal                        152085
    // BankAccountDescriptionBlankOnCashJournal                   152086

    Subtype = Test;
    TestPermissions = Disabled;

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
    procedure GLAccountDescriptionBlankOnGeneralJournal()
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        // Purpose of the test is to verify error Account Type G/L Account and Description blank on General Journal.
        CreateAndPostGeneralJournal(GenJournalLine."Account Type"::"G/L Account", CreateGLAccount());
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure CustomerDescriptionBlankOnGeneralJournal()
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        // Purpose of the test is to verify error Account Type Customer and Description blank on General Journal.
        CreateAndPostGeneralJournal(GenJournalLine."Account Type"::Customer, CreateCustomer());
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure VendorDescriptionBlankOnGeneralJournal()
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        // Purpose of the test is to verify error Account Type Vendor and Description blank on General Journal.
        CreateAndPostGeneralJournal(GenJournalLine."Account Type"::Vendor, CreateVendor());
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure BankAccountDescriptionBlankOnGeneralJournal()
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        // Purpose of the test is to verify error Account Type Bank Account and Description blank on General Journal.
        CreateAndPostGeneralJournal(GenJournalLine."Account Type"::"Bank Account", CreateBankAccount());
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure FixedAssetDescriptionBlankOnGeneralJournal()
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        // Purpose of the test is to verify error Account Type Fixed Asset and Description blank on FA G/L Journal.
        CreateAndPostGeneralJournal(GenJournalLine."Account Type"::"Fixed Asset", CreateFixedAsset());
    end;

    local procedure CreateAndPostGeneralJournal(AccountType: Enum "Gen. Journal Account Type"; AccountNo: Code[20])
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        // Setup.
        CreateGenJournalLine(GenJournalLine, AccountType, AccountNo);

        // Exercise.
        asserterror CODEUNIT.Run(CODEUNIT::"Gen. Jnl.-Post Batch", GenJournalLine);

        // Verify. Verify actual error,Description must have a value in Gen. Journal Line Journal Template Name.
        Assert.ExpectedErrorCode('TestField');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure GLAccountDescriptionBlankOnCashJournal()
    var
        CBGStatementLine: Record "CBG Statement Line";
    begin
        // Purpose of the test is to verify error Account Type G/L Account and Description blank on Cash Journal.
        CreateAndPostCashJournal(CBGStatementLine."Account Type"::"G/L Account", CreateGLAccount());
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure CustomerDescriptionBlankOnCashJournal()
    var
        CBGStatementLine: Record "CBG Statement Line";
    begin
        // Purpose of the test is to verify error Account Type Customer and Description blank on Cash Journal.
        CreateAndPostCashJournal(CBGStatementLine."Account Type"::Customer, CreateCustomer());
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure VendorDescriptionBlankOnCashJournal()
    var
        CBGStatementLine: Record "CBG Statement Line";
    begin
        // Purpose of the test is to verify error Account Type Vendor and Description blank on Cash Journal.
        CreateAndPostCashJournal(CBGStatementLine."Account Type"::Vendor, CreateVendor());
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure BankAccountDescriptionBlankOnCashJournal()
    var
        CBGStatementLine: Record "CBG Statement Line";
    begin
        // Purpose of the test is to verify error Account Type Bank Account and Description blank on Cash Journal.
        CreateAndPostCashJournal(CBGStatementLine."Account Type"::"Bank Account", CreateBankAccount());
    end;

    local procedure CreateAndPostCashJournal(AccountType: Option; AccountNo: Code[20])
    var
        CBGStatement: Record "CBG Statement";
    begin
        // Setup.
        CreateCGBStatement(CBGStatement, AccountType, AccountNo);

        // Exercise.
        asserterror CBGStatement.ProcessStatementASGenJournal();

        // Verify. Verify actual error,Description must have a value in Gen. Journal Line Journal Template Name.
        Assert.ExpectedErrorCode('TestField');
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

    local procedure CreateCGBStatement(var CBGStatement: Record "CBG Statement"; AccountType: Option; AccountNo: Code[20])
    var
        CBGStatementLine: Record "CBG Statement Line";
    begin
        CBGStatement."Journal Template Name" := CreateGenJournalTemplate();
        CBGStatement."No." := LibraryRandom.RandInt(10);  // Use Random for No.
        CBGStatement.Type := CBGStatement.Type::Cash;
        CBGStatement."Account Type" := CBGStatement."Account Type"::"G/L Account";
        CBGStatement."Account No." := CreateGLAccount();
        CBGStatement.Insert();
        CBGStatementLine."Journal Template Name" := CBGStatement."Journal Template Name";
        CBGStatementLine."No." := CBGStatement."No.";
        CBGStatementLine."Line No." := LibraryRandom.RandInt(10);  // Use Random for Line No.
        CBGStatementLine."Statement Type" := CBGStatement."Account Type";
        CBGStatementLine."Statement No." := CBGStatement."Account No.";
        CBGStatementLine."Account Type" := AccountType;
        CBGStatementLine."Account No." := AccountNo;
        CBGStatementLine.Date := WorkDate();
        CBGStatementLine."Document No." := LibraryUTUtility.GetNewCode();
        CBGStatementLine.Insert();
    end;

    local procedure CreateFixedAsset(): Code[20]
    var
        FixedAsset: Record "Fixed Asset";
    begin
        FixedAsset."No." := LibraryUTUtility.GetNewCode();
        FixedAsset.Insert();
        exit(FixedAsset."No.");
    end;

    local procedure CreateGLAccount(): Code[20]
    var
        GLAccount: Record "G/L Account";
    begin
        GLAccount."No." := LibraryUTUtility.GetNewCode();
        GLAccount.Insert();
        exit(GLAccount."No.");
    end;

    local procedure CreateGenJournalLine(var GenJournalLine: Record "Gen. Journal Line"; AccountType: Enum "Gen. Journal Account Type"; AccountNo: Code[20])
    var
        GenJournalBatch: Record "Gen. Journal Batch";
    begin
        GenJournalBatch."Journal Template Name" := CreateGenJournalTemplate();
        GenJournalBatch.Name := LibraryUTUtility.GetNewCode10();
        GenJournalBatch.Insert();
        GenJournalLine."Journal Template Name" := GenJournalBatch."Journal Template Name";
        GenJournalLine."Journal Batch Name" := GenJournalBatch.Name;
        GenJournalLine."Account Type" := AccountType;
        GenJournalLine."Account No." := AccountNo;
        GenJournalLine."Posting Date" := WorkDate();
        GenJournalLine."Document No." := LibraryUTUtility.GetNewCode();
        GenJournalLine.Amount := LibraryRandom.RandDec(10, 2);  // Use Random for Amount.
        GenJournalLine.Insert();
    end;

    local procedure CreateGenJournalTemplate(): Code[10]
    var
        GenJournalTemplate: Record "Gen. Journal Template";
    begin
        GenJournalTemplate.Name := LibraryUTUtility.GetNewCode10();
        GenJournalTemplate."No. Series" := CreateNoSeries();
        GenJournalTemplate."Source Code" := LibraryUTUtility.GetNewCode10();
        GenJournalTemplate.Insert();
        exit(GenJournalTemplate.Name);
    end;

    local procedure CreateNoSeries(): Code[20]
    var
        NoSeries: Record "No. Series";
        NoSeriesLine: Record "No. Series Line";
    begin
        NoSeries.Code := LibraryUTUtility.GetNewCode10();
        NoSeries.Insert();
        NoSeriesLine."Series Code" := NoSeries.Code;
        NoSeriesLine.Insert();
        exit(NoSeries.Code);
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

