codeunit 134556 "ERM CF GL Budget"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Cash Flow] [G/L Integration]
    end;

    var
        LibraryRandom: Codeunit "Library - Random";
        Assert: Codeunit Assert;
        LibraryERM: Codeunit "Library - ERM";
        LibraryCashFlow: Codeunit "Library - Cash Flow";
        LibraryDimension: Codeunit "Library - Dimension";

    [Test]
    [Scope('OnPrem')]
    procedure GLBudgetIntegrationBeginTotal()
    var
        GLAccount: Record "G/L Account";
        CashFlowAccount: Record "Cash Flow Account";
    begin
        GLBudgetIntegration(GLAccount."Account Type"::"Begin-Total", CashFlowAccount."G/L Integration"::Budget);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure GLBudgetIntegrationEndTotal()
    var
        GLAccount: Record "G/L Account";
        CashFlowAccount: Record "Cash Flow Account";
    begin
        // Integration on End-Total accounts should fail the test
        asserterror GLBudgetIntegration(GLAccount."Account Type"::"End-Total", CashFlowAccount."G/L Integration"::Budget);
        // Assert.ExpectedError('There is no CashFlowForecast Ledger Entry within the filter.');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure GLBudgetIntegrationBudget()
    var
        GLAccount: Record "G/L Account";
        CashFlowAccount: Record "Cash Flow Account";
    begin
        GLBudgetIntegration(GLAccount."Account Type"::Posting, CashFlowAccount."G/L Integration"::Budget);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure GLBudgetIntegrationBalance()
    var
        GLAccount: Record "G/L Account";
        CashFlowAccount: Record "Cash Flow Account";
    begin
        // Integration with balance sheet should fail the test
        asserterror GLBudgetIntegration(GLAccount."Account Type"::Posting, CashFlowAccount."G/L Integration"::Balance);
        // Assert.ExpectedError('There is no CashFlowForecast Ledger Entry within the filter.');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure GLBudgetIntegrationBoth()
    var
        GLAccount: Record "G/L Account";
        CashFlowAccount: Record "Cash Flow Account";
    begin
        GLBudgetIntegration(GLAccount."Account Type"::Posting, CashFlowAccount."G/L Integration"::Both);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure GLBudgetIntegrationBlank()
    var
        GLAccount: Record "G/L Account";
        CashFlowAccount: Record "Cash Flow Account";
    begin
        // No integration should fail the test
        asserterror GLBudgetIntegration(GLAccount."Account Type"::Posting, CashFlowAccount."G/L Integration"::" ");
        // Assert.ExpectedError('There is no CashFlowForecast Ledger Entry within the filter.');
    end;

    local procedure GLBudgetIntegration(GLAccountType: Enum "G/L Account Type"; Integration: Option)
    var
        CashFlowForecast: Record "Cash Flow Forecast";
        CashFlowAccount: Record "Cash Flow Account";
        TempCashFlowForecastEntry: Record "Cash Flow Forecast Entry" temporary;
        GLAccount: Record "G/L Account";
        GLBudgetName: Record "G/L Budget Name";
        GLBudgetEntry: Record "G/L Budget Entry";
        FromDate: Date;
        ToDate: Date;
    begin
        // Setup
        FromDate := DMY2Date(1, 1, Date2DMY(WorkDate(), 3));
        ToDate := DMY2Date(31, 12, Date2DMY(WorkDate(), 3));

        LibraryCashFlow.FindCashFlowAccount(CashFlowAccount);
        FindGLAccount(GLAccount, GLAccountType);
        LinkCFAccount(CashFlowAccount, GLAccount, Integration);
        // End-Total accounts posts to Begin-Total counterparts
        if GLAccount."Account Type" = GLAccount."Account Type"::"End-Total" then
            FindBeginAccount(GLAccount);

        LibraryERM.CreateGLBudgetName(GLBudgetName);
        LibraryERM.CreateGLBudgetEntry(GLBudgetEntry, WorkDate(), GLAccount."No.", GLBudgetName.Name);
        GLBudgetEntry.Validate("Dimension Set ID", CreateDimensionSetID());
        GLBudgetEntry.Validate(Amount, LibraryRandom.RandDec(1000, 2));
        GLBudgetEntry.Modify(true);
        StoreCashFlowBudgetEntry(TempCashFlowForecastEntry, GLBudgetEntry);
        LibraryCashFlow.CreateCashFlowCard(CashFlowForecast);
        CashFlowForecast.Validate("G/L Budget From", FromDate);
        CashFlowForecast.Validate("G/L Budget To", ToDate);
        CashFlowForecast.Modify(true);
        LibraryCashFlow.ClearJournal();

        // Exercise
        LibraryCashFlow.FillBudgetJournal(false, CashFlowForecast."No.", GLBudgetName.Name);
        LibraryCashFlow.PostJournal();

        // Verify
        VerifyCashFlowLedgerEntries(TempCashFlowForecastEntry, CashFlowForecast);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure GLBalanceIntegrationBeginTotal()
    var
        GLAccount: Record "G/L Account";
        CashFlowAccount: Record "Cash Flow Account";
    begin
        // Integration on Begin-Total should fail the test
        asserterror GLBalanceIntegration(GLAccount."Account Type"::"Begin-Total", CashFlowAccount."G/L Integration"::Balance);
        // Assert.ExpectedError('There is no CashFlowForecast Ledger Entry within the filter.');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure GLBalanceIntegrationEndTotal()
    var
        GLAccount: Record "G/L Account";
        CashFlowAccount: Record "Cash Flow Account";
    begin
        GLBalanceIntegration(GLAccount."Account Type"::"End-Total", CashFlowAccount."G/L Integration"::Balance);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure GLBalanceIntegrationBudget()
    var
        GLAccount: Record "G/L Account";
        CashFlowAccount: Record "Cash Flow Account";
    begin
        // Integration with budget should fail the test
        asserterror GLBalanceIntegration(GLAccount."Account Type"::Posting, CashFlowAccount."G/L Integration"::Budget);
        // Assert.ExpectedError('There is no CashFlowForecast Ledger Entry within the filter.');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure GLBalanceIntegrationBalance()
    var
        GLAccount: Record "G/L Account";
        CashFlowAccount: Record "Cash Flow Account";
    begin
        GLBalanceIntegration(GLAccount."Account Type"::Posting, CashFlowAccount."G/L Integration"::Balance);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure GLBalanceIntegrationBoth()
    var
        GLAccount: Record "G/L Account";
        CashFlowAccount: Record "Cash Flow Account";
    begin
        GLBalanceIntegration(GLAccount."Account Type"::Posting, CashFlowAccount."G/L Integration"::Both);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure GLBalanceIntegrationNone()
    var
        GLAccount: Record "G/L Account";
        CashFlowAccount: Record "Cash Flow Account";
    begin
        // No integration should fail the test
        asserterror GLBalanceIntegration(GLAccount."Account Type"::Posting, CashFlowAccount."G/L Integration"::" ");
        // Assert.ExpectedError('There is no CashFlowForecast Ledger Entry within the filter.');
    end;

    local procedure GLBalanceIntegration(GLAccountType: Enum "G/L Account Type"; Integration: Option)
    var
        CashFlowForecast: Record "Cash Flow Forecast";
        CashFlowAccount: Record "Cash Flow Account";
        TempCashFlowForecastEntry: Record "Cash Flow Forecast Entry" temporary;
        GLAccount: Record "G/L Account";
        ConsiderSource: array[16] of Boolean;
    begin
        // Setup
        ClearCFAccountLinks();
        LibraryCashFlow.FindCashFlowAccount(CashFlowAccount);
        CreateGLAccountWithBalance(GLAccount, GLAccountType);
        LinkCFAccount(CashFlowAccount, GLAccount, Integration);

        StoreCashFlowBalanceEntry(TempCashFlowForecastEntry, GLAccount);
        LibraryCashFlow.CreateCashFlowCard(CashFlowForecast);
        LibraryCashFlow.ClearJournal();

        // Exercise
        ConsiderSource[CashFlowForecast."Source Type Filter"::"Liquid Funds".AsInteger()] := true;
        LibraryCashFlow.FillJournal(ConsiderSource, CashFlowForecast."No.", false);
        LibraryCashFlow.PostJournal();

        // Verify
        VerifyCashFlowLedgerEntries(TempCashFlowForecastEntry, CashFlowForecast);
    end;

    local procedure StoreCashFlowBudgetEntry(var CashFlowForecastEntry: Record "Cash Flow Forecast Entry"; GLBudgetEntry: Record "G/L Budget Entry")
    begin
        CashFlowForecastEntry."Amount (LCY)" := -GLBudgetEntry.Amount;
        CashFlowForecastEntry."Dimension Set ID" := GLBudgetEntry."Dimension Set ID";
        CashFlowForecastEntry."Cash Flow Date" := GLBudgetEntry.Date;
        CashFlowForecastEntry.Insert(false);
    end;

    local procedure StoreCashFlowBalanceEntry(var CashFlowForecastEntry: Record "Cash Flow Forecast Entry"; GLAccount: Record "G/L Account")
    begin
        GLAccount.CalcFields(Balance);
        CashFlowForecastEntry."Amount (LCY)" := GLAccount.Balance;
        CashFlowForecastEntry."Dimension Set ID" := 0;
        // GLAccount."Dimension Set ID";
        CashFlowForecastEntry."Cash Flow Date" := WorkDate();
        CashFlowForecastEntry.Insert(false);
    end;

    local procedure FindGLAccount(var GLAccount: Record "G/L Account"; AccountType: Enum "G/L Account Type")
    begin
        // Filter G/L Account so that errors are not generated due to mandatory fields.
        GLAccount.SetRange(Blocked, false);
        GLAccount.SetRange("Account Type", AccountType);
        GLAccount.FindFirst();
    end;

    local procedure CreateGLAccountWithBalance(var GLAccount: Record "G/L Account"; AccountType: Enum "G/L Account Type")
    var
        BeginTotalAccNo: Code[20];
    begin
        case AccountType of
            GLAccount."Account Type"::"Begin-Total":
                GLAccount.Get(CreateGLAccWithType(GLAccount."Account Type"::"Begin-Total"));
            GLAccount."Account Type"::Posting:
                GLAccount.Get(CreatePostGLAccount());
            GLAccount."Account Type"::"End-Total":
                begin
                    BeginTotalAccNo := CreateGLAccWithType(GLAccount."Account Type"::"Begin-Total");
                    CreatePostGLAccount();
                    GLAccount.Get(CreateGLAccWithType(GLAccount."Account Type"::"End-Total"));
                    GLAccount.Validate(
                      Totaling, StrSubstNo('%1..%2', BeginTotalAccNo, GLAccount."No."));
                    GLAccount.Modify(true);
                end;
        end;
    end;

    local procedure CreatePostGLAccount(): Code[20]
    var
        GLAccount: Record "G/L Account";
        GenJnlLine: Record "Gen. Journal Line";
        GenJnlBatch: Record "Gen. Journal Batch";
    begin
        LibraryERM.FindGLAccount(GLAccount);
        InitGenJnlLine(GenJnlLine);
        GenJnlBatch.Get(GenJnlLine."Journal Template Name", GenJnlLine."Journal Batch Name");
        LibraryERM.ClearGenJournalLines(GenJnlBatch);
        LibraryERM.CreateGeneralJnlLine(
          GenJnlLine, GenJnlLine."Journal Template Name", GenJnlLine."Journal Batch Name",
          "Gen. Journal Document Type"::" ", GenJnlLine."Account Type"::"G/L Account", CreateGLAccWithType(GLAccount."Account Type"::Posting), 1);
        GenJnlLine.Validate("Bal. Account Type", GenJnlLine."Bal. Account Type"::"G/L Account");
        GenJnlLine.Validate("Bal. Account No.", GLAccount."No.");
        GenJnlLine.Modify(true);
        LibraryERM.PostGeneralJnlLine(GenJnlLine);
        exit(GenJnlLine."Account No.");
    end;

    local procedure CreateGLAccWithType(AccountType: Enum "G/L Account Type"): Code[20]
    var
        GLAccount: Record "G/L Account";
    begin
        LibraryERM.CreateGLAccount(GLAccount);
        GLAccount.Validate("Account Type", AccountType);
        GLAccount.Modify(true);
        exit(GLAccount."No.");
    end;

    local procedure InitGenJnlLine(var GenJnlLine: Record "Gen. Journal Line")
    var
        GenJnlTemplate: Record "Gen. Journal Template";
        GenJnlBatch: Record "Gen. Journal Batch";
    begin
        GenJnlTemplate.SetRange(Type, GenJnlTemplate.Type::General); // required for NL
        LibraryERM.FindGenJournalTemplate(GenJnlTemplate);
        LibraryERM.FindGenJournalBatch(GenJnlBatch, GenJnlTemplate.Name);
        GenJnlLine."Journal Template Name" := GenJnlBatch."Journal Template Name";
        GenJnlLine."Journal Batch Name" := GenJnlBatch.Name;
    end;

    local procedure FindBeginAccount(var GLAccount: Record "G/L Account")
    var
        GLAccount2: Record "G/L Account";
    begin
        // Returns the matching Begin-Total account to an End-Total account
        GLAccount2.Get(GLAccount."No.");
        repeat
            GLAccount2.Next(-1);
        until (GLAccount2.Indentation = GLAccount.Indentation) and (GLAccount2."Account Type" = GLAccount2."Account Type"::"Begin-Total");

        GLAccount.Get(GLAccount2."No.");
    end;

    local procedure ClearCFAccountLinks()
    var
        CFAccount: Record "Cash Flow Account";
    begin
        CFAccount.ModifyAll("G/L Account Filter", '');
        CFAccount.ModifyAll("G/L Integration", CFAccount."G/L Integration"::" ");
    end;

    local procedure LinkCFAccount(var CFAccount: Record "Cash Flow Account"; var GLAccount: Record "G/L Account"; LinkType: Option)
    begin
        CFAccount.Validate("G/L Account Filter", GLAccount."No.");
        CFAccount.Validate("G/L Integration", LinkType);
        CFAccount.Modify(true);
    end;

    local procedure CreateDimensionSetID(): Integer
    var
        Dimension: Record Dimension;
        DimensionValue: Record "Dimension Value";
    begin
        LibraryDimension.CreateDimension(Dimension);
        LibraryDimension.CreateDimensionValue(DimensionValue, Dimension.Code);
        exit(LibraryDimension.CreateDimSet(0, Dimension.Code, DimensionValue.Code));
    end;

    local procedure VerifyCashFlowLedgerEntries(var CashFlowForecastEntry: Record "Cash Flow Forecast Entry"; CashFlowForecast: Record "Cash Flow Forecast")
    var
        CashFlowForecastEntry2: Record "Cash Flow Forecast Entry";
    begin
        CashFlowForecastEntry2.SetRange("Cash Flow Forecast No.", CashFlowForecast."No.");
        CashFlowForecastEntry2.FindSet();
        CashFlowForecastEntry.FindSet();
        Assert.AreEqual(CashFlowForecastEntry.Count, CashFlowForecastEntry2.Count, 'Unexpected number of cash flow ledger entries');

        repeat
            CashFlowForecastEntry.SetRange("Amount (LCY)", CashFlowForecastEntry2."Amount (LCY)");
            CashFlowForecastEntry.SetRange("Dimension Set ID", CashFlowForecastEntry2."Dimension Set ID");
            CashFlowForecastEntry.SetRange("Cash Flow Date", CashFlowForecastEntry2."Cash Flow Date");
            Assert.IsTrue(CashFlowForecastEntry.FindFirst(), 'Did not find expected cash flow ledger entry');
        until CashFlowForecastEntry2.Next() = 0;
    end;
}

