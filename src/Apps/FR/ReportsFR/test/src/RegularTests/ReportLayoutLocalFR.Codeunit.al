// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.GeneralLedger.Reports;

using Microsoft.Purchases.Reports;
using Microsoft.Sales.Reports;
using Microsoft.Sales.Setup;

codeunit 144051 "Report Layout - Local FR"
{
    Subtype = Test;
    TestPermissions = Disabled;
    TestType = IntegrationTest;

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
        REPORT.Run(REPORT::"G/L Detail Trial Balance FR");
    end;

    [Test]
    [HandlerFunctions('RHGLJournal')]
    [Scope('OnPrem')]
    procedure TestGLJournal()
    begin
        Initialize();
        REPORT.Run(REPORT::"G/L Journal FR");
    end;

    [Test]
    [HandlerFunctions('RHGLTrialBalance')]
    [Scope('OnPrem')]
    procedure TestGLTrialBalance()
    begin
        Initialize();
        REPORT.Run(REPORT::"G/L Trial Balance FR");
    end;

    [Test]
    [HandlerFunctions('RHVendorJournal')]
    [Scope('OnPrem')]
    procedure TestVendorJournal()
    begin
        Initialize();
        REPORT.Run(REPORT::"Vendor Journal FR");
    end;

    [Test]
    [HandlerFunctions('RHJournals')]
    [Scope('OnPrem')]
    procedure TestJournals()
    begin
        Initialize();
        REPORT.Run(REPORT::"Journals FR");
    end;

    [Test]
    [HandlerFunctions('RHCustomerJournal')]
    [Scope('OnPrem')]
    procedure TestCustomerJournal()
    begin
        Initialize();
        REPORT.Run(REPORT::"Customer Journal FR");
    end;

    local procedure Initialize()
    var
        SalesSetup: Record "Sales & Receivables Setup";
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"Report Layout - Local FR");
        if isInitialized then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"Report Layout - Local FR");

        // Setup logo to be printed by default
        SalesSetup.Validate("Logo Position on Documents", SalesSetup."Logo Position on Documents"::Center);
        SalesSetup.Modify(true);

        isInitialized := true;
        Commit();
        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"Report Layout - Local FR");
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
    procedure RHGLDetailTrialBalance(var GLDetailTrialBalance: TestRequestPage "G/L Detail Trial Balance FR")
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
    procedure RHGLJournal(var GLJournal: TestRequestPage "G/L Journal FR")
    var
        LibraryFiscalYear: Codeunit "Library - Fiscal Year";
    begin
        GLJournal.Date.SetFilter("Period Start", StrSubstNo('%1..%2',
            LibraryFiscalYear.GetFirstPostingDate(false), GetLastDayOftheMonth(LibraryFiscalYear.GetFirstPostingDate(false))));
        GLJournal.SaveAsPdf(FomatFileName(GLJournal.Caption));
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure RHGLTrialBalance(var GLTrialBalance: TestRequestPage "G/L Trial Balance FR")
    begin
        GLTrialBalance."G/L Account".SetFilter("Date Filter", Format(WorkDate()));
        GLTrialBalance.SaveAsPdf(FomatFileName(GLTrialBalance.Caption));
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure RHVendorJournal(var VendorJournal: TestRequestPage "Vendor Journal FR")
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
    procedure RHJournals(var Journals: TestRequestPage "Journals FR")
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
    procedure RHCustomerJournal(var CustomerJournal: TestRequestPage "Customer Journal FR")
    var
        PeriodType: Option Date,Week,Month,Quarter,Year;
    begin
        CustomerJournal.Date.SetFilter("Period Type", Format(PeriodType::Date));
        CustomerJournal.Date.SetFilter("Period Start", Format(WorkDate()));
        CustomerJournal.SaveAsPdf(FomatFileName(CustomerJournal.Caption));
    end;
}

