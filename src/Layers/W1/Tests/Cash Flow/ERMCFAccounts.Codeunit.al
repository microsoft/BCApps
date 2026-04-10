codeunit 134555 "ERM CF Accounts"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Cash Flow] [Cash Flow Account]
        isInitialized := false;
    end;

    var
        LibraryRandom: Codeunit "Library - Random";
        LibraryApplicationArea: Codeunit "Library - Application Area";
        Assert: Codeunit Assert;
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        LibraryCashFlow: Codeunit "Library - Cash Flow";
        CFHelper: Codeunit "Library - Cash Flow Helper";
        SourceType: Option " ",Receivables,Payables,"Liquid Funds","Cash Flow Manual Expense","Cash Flow Manual Revenue","Sales Order","Purchase Order","Fixed Assets Budget","Fixed Assets Disposal","Service Orders","G/L Budget";
        isInitialized: Boolean;
        ROLLBACK: Label 'Rollback.';

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure CFAccountIndent()
    var
        CashFlowAccount: Record "Cash Flow Account";
        TempCashFlowAccount: Record "Cash Flow Account" temporary;
        AccountNo: Code[20];
    begin
        Initialize();
        // Clear existing cash flow account to make room for our test
        CashFlowAccount.DeleteAll();

        // Create new setup starting from account 0000, expected setup:
        // |0001
        // |  0002
        // |  0003
        // |    0004
        // |  0005
        // |0006
        AccountNo := '0000';

        CreateCashFlowAccount(CashFlowAccount, AccountNo, CashFlowAccount."Account Type"::"Begin-Total");
        StoreAccount(TempCashFlowAccount, CashFlowAccount."No.", 0);

        CreateCashFlowAccount(CashFlowAccount, AccountNo, CashFlowAccount."Account Type"::Entry);
        StoreAccount(TempCashFlowAccount, CashFlowAccount."No.", 1);

        CreateCashFlowAccount(CashFlowAccount, AccountNo, CashFlowAccount."Account Type"::"Begin-Total");
        StoreAccount(TempCashFlowAccount, CashFlowAccount."No.", 1);

        CreateCashFlowAccount(CashFlowAccount, AccountNo, CashFlowAccount."Account Type"::Entry);
        StoreAccount(TempCashFlowAccount, CashFlowAccount."No.", 2);

        CreateCashFlowAccount(CashFlowAccount, AccountNo, CashFlowAccount."Account Type"::"End-Total");
        StoreAccount(TempCashFlowAccount, CashFlowAccount."No.", 1);

        CreateCashFlowAccount(CashFlowAccount, AccountNo, CashFlowAccount."Account Type"::"End-Total");
        StoreAccount(TempCashFlowAccount, CashFlowAccount."No.", 0);

        // Exercise
        CODEUNIT.Run(CODEUNIT::"Cash Flow Account - Indent");

        // Validate correct indentation
        VerifyIndentation(TempCashFlowAccount);

        // Roll back account setup
        asserterror Error(ROLLBACK);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CFAccountSelectionFilter()
    var
        CashFlowAccount: Record "Cash Flow Account";
        SelectionFilterManagement: Codeunit SelectionFilterManagement;
        AccountNo: Code[20];
        ExpectedFilter: Code[80];
    begin
        Initialize();
        // Clear existing cash flow account to make room for our test
        CashFlowAccount.DeleteAll();

        // Create new setup starting from account 0000, expected setup:
        // |0001
        // |0002 (*)
        // |0003
        // |0004 (*)
        // |0005 (*)
        // |0006
        // (*) indicates account is marked
        // This setup should produce a filter: 0002|0004..0005
        AccountNo := '0000';

        CreateCashFlowAccount(CashFlowAccount, AccountNo, CashFlowAccount."Account Type"::"Begin-Total");

        CreateCashFlowAccount(CashFlowAccount, AccountNo, CashFlowAccount."Account Type"::Entry);
        CashFlowAccount.Mark(true);

        ExpectedFilter := SelectionFilterManagement.AddQuotes(CashFlowAccount."No.") + '|';

        CreateCashFlowAccount(CashFlowAccount, AccountNo, CashFlowAccount."Account Type"::Entry);

        CreateCashFlowAccount(CashFlowAccount, AccountNo, CashFlowAccount."Account Type"::Entry);
        CashFlowAccount.Mark(true);
        ExpectedFilter += SelectionFilterManagement.AddQuotes(CashFlowAccount."No.") + '..';

        CreateCashFlowAccount(CashFlowAccount, AccountNo, CashFlowAccount."Account Type"::Entry);
        CashFlowAccount.Mark(true);
        ExpectedFilter += SelectionFilterManagement.AddQuotes(CashFlowAccount."No.");

        CreateCashFlowAccount(CashFlowAccount, AccountNo, CashFlowAccount."Account Type"::"End-Total");

        // Validate correct filter generated from markings
        CashFlowAccount.MarkedOnly(true);
        Assert.AreEqual(
          ExpectedFilter, SelectionFilterManagement.GetSelectionFilterForCashFlowAccount(CashFlowAccount),
          'Incorrect account filter generated');

        // Roll back account setup
        asserterror Error(ROLLBACK);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure FAInvestAccount()
    var
        CashFlowSetup: Record "Cash Flow Setup";
        FASetup: Record "FA Setup";
        FixedAsset: Record "Fixed Asset";
        FAPostingDateFormula: DateFormula;
        ConsiderSource: array[16] of Boolean;
    begin
        Initialize();
        Evaluate(FAPostingDateFormula, '<1M>');
        FASetup.Get();
        CFHelper.CreateFixedAssetForInvestment(
          FixedAsset, FASetup."Default Depr. Book", FAPostingDateFormula,
          LibraryRandom.RandDec(1000, 2));

        ConsiderSource[SourceType::"Fixed Assets Budget"] := true;
        CashFlowAccountPosting(CashFlowSetup.FieldNo("FA Budget CF Account No."), ConsiderSource);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure FASaleAccount()
    var
        CashFlowSetup: Record "Cash Flow Setup";
        FASetup: Record "FA Setup";
        FixedAsset: Record "Fixed Asset";
        DeprecStartDateFormula: DateFormula;
        DeprecEndDateFormula: DateFormula;
        ExpectedDisposalDateFormula: DateFormula;
        ConsiderSource: array[16] of Boolean;
    begin
        Initialize();
        Evaluate(DeprecStartDateFormula, '<-2Y>');
        Evaluate(DeprecEndDateFormula, '<1M-D5>');
        Evaluate(ExpectedDisposalDateFormula, '<1M+1W-WD1>');
        FASetup.Get();
        CFHelper.CreateFixedAssetForDisposal(FixedAsset, FASetup."Default Depr. Book", DeprecStartDateFormula, DeprecEndDateFormula,
          ExpectedDisposalDateFormula, LibraryRandom.RandDec(1000, 2));

        ConsiderSource[SourceType::"Fixed Assets Disposal"] := true;
        CashFlowAccountPosting(CashFlowSetup.FieldNo("FA Disposal CF Account No."), ConsiderSource);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PayablesAccount()
    var
        CashFlowSetup: Record "Cash Flow Setup";
        ConsiderSource: array[16] of Boolean;
    begin
        ConsiderSource[SourceType::Payables] := true;
        CashFlowAccountPosting(CashFlowSetup.FieldNo("Payables CF Account No."), ConsiderSource);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchaseAccount()
    var
        CashFlowSetup: Record "Cash Flow Setup";
        ConsiderSource: array[16] of Boolean;
    begin
        ConsiderSource[SourceType::"Purchase Order"] := true;
        LibraryApplicationArea.EnableFoundationSetup();
        CashFlowAccountPosting(CashFlowSetup.FieldNo("Purch. Order CF Account No."), ConsiderSource);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ReceivablesAccount()
    var
        CashFlowSetup: Record "Cash Flow Setup";
        ConsiderSource: array[16] of Boolean;
    begin
        ConsiderSource[SourceType::Receivables] := true;
        CashFlowAccountPosting(CashFlowSetup.FieldNo("Receivables CF Account No."), ConsiderSource);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesAccount()
    var
        CashFlowSetup: Record "Cash Flow Setup";
        ConsiderSource: array[16] of Boolean;
    begin
        ConsiderSource[SourceType::"Sales Order"] := true;
        CashFlowAccountPosting(CashFlowSetup.FieldNo("Sales Order CF Account No."), ConsiderSource);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ServiceAccount()
    var
        CashFlowSetup: Record "Cash Flow Setup";
        ConsiderSource: array[16] of Boolean;
    begin
        ConsiderSource[SourceType::"Service Orders"] := true;
        CashFlowAccountPosting(CashFlowSetup.FieldNo("Service CF Account No."), ConsiderSource);
    end;

    [Normal]
    local procedure CashFlowAccountPosting(FieldNo: Integer; ConsiderSource: array[16] of Boolean)
    var
        CashFlowAccount: Record "Cash Flow Account";
        CashFlowForecast: Record "Cash Flow Forecast";
        RecRef: RecordRef;
        FieldRef: FieldRef;
    begin
        // Setup: Generically modify CF Setup
        Initialize();
        LibraryCashFlow.CreateCashFlowAccount(CashFlowAccount, CashFlowAccount."Account Type"::Entry);
        RecRef.Open(DATABASE::"Cash Flow Setup");
        RecRef.FindFirst();
        FieldRef := RecRef.Field(FieldNo);
        FieldRef.Validate(CashFlowAccount."No.");
        RecRef.Modify(true);

        LibraryCashFlow.CreateCashFlowCard(CashFlowForecast);
        LibraryCashFlow.ClearJournal();

        // Exercise
        LibraryCashFlow.FillJournal(ConsiderSource, CashFlowForecast."No.", false);
        LibraryCashFlow.PostJournal();

        // Verify
        VerifyLedgerEntryAccount(CashFlowForecast, CashFlowAccount);
    end;

    [Normal]
    local procedure Initialize()
    var
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"ERM CF Accounts");
        if isInitialized then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"ERM CF Accounts");

        LibraryERMCountryData.UpdateGeneralLedgerSetup();

        isInitialized := true;
        Commit();
        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"ERM CF Accounts");
    end;

    local procedure CreateCashFlowAccount(var CashFlowAccount: Record "Cash Flow Account"; var AccountNo: Code[20]; AccountType: Enum "Cash Flow Account Type")
    begin
        AccountNo := IncStr(AccountNo);
        CashFlowAccount.Init();
        CashFlowAccount.Validate("No.", AccountNo);
        CashFlowAccount.Validate("Account Type", AccountType);
        CashFlowAccount.Validate(Name, CashFlowAccount."No.");
        CashFlowAccount.Insert(true);
    end;

    [Normal]
    local procedure StoreAccount(var TempCashFlowAccount: Record "Cash Flow Account" temporary; No: Code[20]; ExpectedIndentation: Integer)
    begin
        TempCashFlowAccount.Init();
        TempCashFlowAccount."No." := No;
        TempCashFlowAccount.Indentation := ExpectedIndentation;
        TempCashFlowAccount.Insert();
    end;

    [Normal]
    local procedure VerifyIndentation(var CashFlowAccount: Record "Cash Flow Account")
    var
        CashFlowAccount2: Record "Cash Flow Account";
    begin
        CashFlowAccount.FindSet();
        repeat
            CashFlowAccount2.Get(CashFlowAccount."No.");
            CashFlowAccount2.TestField(Indentation, CashFlowAccount.Indentation);
        until CashFlowAccount.Next() = 0;
    end;

    [Normal]
    local procedure VerifyLedgerEntryAccount(CashFlowForecast: Record "Cash Flow Forecast"; CashFlowAccount: Record "Cash Flow Account")
    var
        CashFlowForecastEntry: Record "Cash Flow Forecast Entry";
    begin
        CashFlowForecastEntry.SetRange("Cash Flow Forecast No.", CashFlowForecast."No.");
        CashFlowForecastEntry.FindSet();

        repeat
            CashFlowForecastEntry.TestField("Cash Flow Account No.", CashFlowAccount."No.");
        until CashFlowForecastEntry.Next() = 0;
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandler(Msg: Text[1024]; var Reply: Boolean)
    begin
        Reply := true;
    end;
}

