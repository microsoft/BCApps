codeunit 144056 "Test CH Allowed Posting Dates"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
    end;

    var
        LibraryFiscalYear: Codeunit "Library - Fiscal Year";
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        IsInitialized: Boolean;

    local procedure Initialize()
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"Test CH Allowed Posting Dates");
        if IsInitialized then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"Test CH Allowed Posting Dates");

        LibraryERMCountryData.UpdateGeneralPostingSetup();
        IsInitialized := true;
        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"Test CH Allowed Posting Dates");
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure AllowPostingFromIsUpdatedToFiscYearStartDate()
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
    begin
        Initialize();

        // Setup.
        GeneralLedgerSetup.Get();
        GeneralLedgerSetup.Validate("Allow Posting From", LibraryFiscalYear.GetFirstPostingDate(false));
        GeneralLedgerSetup.Modify(true);

        // Exercise.
        CloseFiscalYear();
        LibraryFiscalYear.CreateFiscalYear();

        // Verify.
        GeneralLedgerSetup.Get();
        GeneralLedgerSetup.TestField("Allow Posting From", LibraryFiscalYear.GetFirstPostingDate(false));
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure AllowPostingFromWithNoOpenFiscYear()
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
        OrigAllowPostingFromDate: Date;
    begin
        Initialize();

        // Setup.
        GeneralLedgerSetup.Get();
        GeneralLedgerSetup.Validate("Allow Posting From", LibraryFiscalYear.GetLastPostingDate(false));
        GeneralLedgerSetup.Modify(true);
        OrigAllowPostingFromDate := GeneralLedgerSetup."Allow Posting From";

        // Exercise.
        CloseFiscalYear();

        // Verify.
        GeneralLedgerSetup.Get();
        GeneralLedgerSetup.TestField("Allow Posting From", OrigAllowPostingFromDate);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure AllowPostingFromAfterOpenFiscYear()
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
        OrigAllowPostingFromDate: Date;
    begin
        Initialize();

        // Setup.
        GeneralLedgerSetup.Get();
        GeneralLedgerSetup.Validate("Allow Posting From", LibraryFiscalYear.GetLastPostingDate(false));
        GeneralLedgerSetup.Modify(true);
        OrigAllowPostingFromDate := GeneralLedgerSetup."Allow Posting From";

        // Exercise.
        CloseFiscalYear();
        LibraryFiscalYear.CreateFiscalYear();

        // Verify.
        GeneralLedgerSetup.Get();
        GeneralLedgerSetup.TestField("Allow Posting From", OrigAllowPostingFromDate);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure AllowPostingToBeforeAllowPostingFrom()
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
    begin
        Initialize();

        // Setup.
        GeneralLedgerSetup.Get();
        GeneralLedgerSetup.Validate("Allow Posting From", LibraryFiscalYear.GetFirstPostingDate(false));
        GeneralLedgerSetup.Validate("Allow Posting To", LibraryFiscalYear.GetFirstPostingDate(false));
        GeneralLedgerSetup.Modify(true);

        // Exercise.
        CloseFiscalYear();
        LibraryFiscalYear.CreateFiscalYear();

        // Verify.
        GeneralLedgerSetup.Get();
        GeneralLedgerSetup.TestField("Allow Posting To", 0D);
    end;

    local procedure CloseFiscalYear()
    var
        AccountingPeriod: Record "Accounting Period";
    begin
        AccountingPeriod.SetRange("New Fiscal Year", true);
        AccountingPeriod.SetRange(Closed, false);
        CODEUNIT.Run(CODEUNIT::"Fiscal Year-Close", AccountingPeriod);
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandler(Question: Text[1024]; var Reply: Boolean)
    begin
        Reply := true;
    end;
}

