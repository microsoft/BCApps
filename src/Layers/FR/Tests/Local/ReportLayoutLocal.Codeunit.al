codeunit 144001 "Report Layout - Local"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        isInitialized := false;
    end;

    var
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        isInitialized: Boolean;

    [Test]
    [HandlerFunctions('RHGLDetailTrialBalance')]
    [Scope('OnPrem')]
    procedure TestGLDetailTrialBalance()
    begin
        Initialize();
        REPORT.Run(REPORT::"G/L Detail Trial Balance");
    end;

    [Test]
    [HandlerFunctions('RHFRAccountSchedule')]
    [Scope('OnPrem')]
    procedure TestFRAccountSchedule()
    begin
        Initialize();
        REPORT.Run(REPORT::"FR Account Schedule");
    end;

    [Test]
    [HandlerFunctions('RHGLCustLedgerReconciliation')]
    [Scope('OnPrem')]
    procedure TestGLCustLedgerReconciliation()
    begin
        Initialize();
        REPORT.Run(REPORT::"GL/Cust. Ledger Reconciliation");
    end;

    [Test]
    [HandlerFunctions('RHGLJournal')]
    [Scope('OnPrem')]
    procedure TestGLJournal()
    begin
        Initialize();
        REPORT.Run(REPORT::"G/L Journal");
    end;

    [Test]
    [HandlerFunctions('RHGLTrialBalance')]
    [Scope('OnPrem')]
    procedure TestGLTrialBalance()
    begin
        Initialize();
        REPORT.Run(REPORT::"G/L Trial Balance");
    end;

#if not CLEAN28
    [Test]
    [HandlerFunctions('RHFixedAssetProfessionalTax')]
    [Scope('OnPrem')]
    procedure TestFixedAssetProfessionalTax()
    begin
        Initialize();
        REPORT.Run(REPORT::"Fixed Asset-Professional Tax");
    end;
#endif

    [Test]
    [HandlerFunctions('RHVendorJournal')]
    [Scope('OnPrem')]
    procedure TestVendorJournal()
    begin
        Initialize();
        REPORT.Run(REPORT::"Vendor Journal");
    end;

    [Test]
    [HandlerFunctions('RHJournals')]
    [Scope('OnPrem')]
    procedure TestJournals()
    begin
        Initialize();
        REPORT.Run(REPORT::Journals);
    end;

    [Test]
    [HandlerFunctions('RHCustomerJournal')]
    [Scope('OnPrem')]
    procedure TestCustomerJournal()
    begin
        Initialize();
        REPORT.Run(REPORT::"Customer Journal");
    end;

    local procedure Initialize()
    var
        SalesSetup: Record "Sales & Receivables Setup";
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"Report Layout - Local");
        if isInitialized then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"Report Layout - Local");

        // Setup logo to be printed by default
        SalesSetup.Validate("Logo Position on Documents", SalesSetup."Logo Position on Documents"::Center);
        SalesSetup.Modify(true);

        isInitialized := true;
        Commit();
        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"Report Layout - Local");
    end;

    local procedure FomatFileName(ReportCaption: Text) ReportFileName: Text
    begin
        ReportFileName := DelChr(ReportCaption, '=', '/') + '.pdf'
    end;

    [Scope('OnPrem')]
    procedure GetLastDayOftheMonth(LastDay: Date): Date
    begin
        exit(CalcDate('<-1D>', DMY2Date(1, Date2DMY(LastDay, 2) + 1, Date2DMY(LastDay, 3))))
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure RHGLDetailTrialBalance(var GLDetailTrialBalance: TestRequestPage "G/L Detail Trial Balance")
    var
        LibraryFiscalYear: Codeunit "Library - Fiscal Year";
    begin
        GLDetailTrialBalance."G/L Account".SetFilter(
          "Date Filter", StrSubstNo('%1..%2', LibraryFiscalYear.GetFirstPostingDate(false),
            GetLastDayOftheMonth(LibraryFiscalYear.GetFirstPostingDate(false))));
        GLDetailTrialBalance.SaveAsPdf(FomatFileName(GLDetailTrialBalance.Caption));
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure RHFRAccountSchedule(var FRAccountSchedule: TestRequestPage "FR Account Schedule")
    begin
        FRAccountSchedule."FR Acc. Schedule Line".SetFilter("Date Filter", Format(WorkDate()));
        FRAccountSchedule.SaveAsPdf(FomatFileName(FRAccountSchedule.Caption));
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure RHGLCustLedgerReconciliation(var GLCustLedgerReconciliation: TestRequestPage "GL/Cust. Ledger Reconciliation")
    begin
        GLCustLedgerReconciliation.Customer.SetFilter("Date Filter",
          StrSubstNo('%1..%2', CalcDate('<-1Y>', WorkDate()), CalcDate('<+1Y>', WorkDate())));
        GLCustLedgerReconciliation.SaveAsPdf(FomatFileName(GLCustLedgerReconciliation.Caption));
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure RHGLJournal(var GLJournal: TestRequestPage "G/L Journal")
    var
        LibraryFiscalYear: Codeunit "Library - Fiscal Year";
    begin
        GLJournal.Date.SetFilter("Period Start", StrSubstNo('%1..%2',
            LibraryFiscalYear.GetFirstPostingDate(false), GetLastDayOftheMonth(LibraryFiscalYear.GetFirstPostingDate(false))));
        GLJournal.SaveAsPdf(FomatFileName(GLJournal.Caption));
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure RHGLTrialBalance(var GLTrialBalance: TestRequestPage "G/L Trial Balance")
    begin
        GLTrialBalance."G/L Account".SetFilter("Date Filter", Format(WorkDate()));
        GLTrialBalance.SaveAsPdf(FomatFileName(GLTrialBalance.Caption));
    end;

#if not CLEAN28
    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure RHFixedAssetProfessionalTax(var FixedAssetProfessionalTax: TestRequestPage "Fixed Asset-Professional Tax")
    begin
        FixedAssetProfessionalTax.StartingDate.SetValue(WorkDate());
        FixedAssetProfessionalTax.EndDate.SetValue(CalcDate('<+10Y>', WorkDate()));
        FixedAssetProfessionalTax.SaveAsPdf(FomatFileName(FixedAssetProfessionalTax.Caption));
    end;
#endif

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure RHVendorJournal(var VendorJournal: TestRequestPage "Vendor Journal")
    var
        LibraryFiscalYear: Codeunit "Library - Fiscal Year";
        PeriodType: Option Date,Week,Month,Quarter,Year;
    begin
        VendorJournal.Date.SetFilter("Period Type", Format(PeriodType::Quarter));
        VendorJournal.Date.SetFilter("Period Start", Format(LibraryFiscalYear.GetAccountingPeriodDate(WorkDate())));
        VendorJournal.SaveAsPdf(FomatFileName(VendorJournal.Caption));
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure RHJournals(var Journals: TestRequestPage Journals)
    var
        LibraryFiscalYear: Codeunit "Library - Fiscal Year";
        PeriodType: Option Date,Week,Month,Quarter,Year;
    begin
        Journals.Date.SetFilter("Period Type", Format(PeriodType::Year));
        Journals.Date.SetFilter("Period Start", Format(LibraryFiscalYear.GetAccountingPeriodDate(WorkDate())));
        Journals.SaveAsPdf(FomatFileName(Journals.Caption));
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure RHCustomerJournal(var CustomerJournal: TestRequestPage "Customer Journal")
    var
        PeriodType: Option Date,Week,Month,Quarter,Year;
    begin
        CustomerJournal.Date.SetFilter("Period Type", Format(PeriodType::Date));
        CustomerJournal.Date.SetFilter("Period Start", Format(WorkDate()));
        CustomerJournal.SaveAsPdf(FomatFileName(CustomerJournal.Caption));
    end;
}

