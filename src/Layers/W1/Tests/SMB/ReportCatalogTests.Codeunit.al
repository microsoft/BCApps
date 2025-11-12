#if not CLEAN27
codeunit 139125 ReportCatalogTests
{
    Subtype = Test;
    TestPermissions = Disabled;
    ObsoleteState = Pending;
    ObsoleteReason = 'Codeunit it is testing is obsolete.';
    ObsoleteTag = '27.0';

    trigger OnRun()
    begin
        // [FEATURE] [SMB] [Report Catalog]
    end;

    var
        SmallBusinessReportCatalogCU: Codeunit "Small Business Report Catalog";
        FileManagement: Codeunit "File Management";
        LibraryUtilityOnPrem: Codeunit "Library - Utility OnPrem";
        SavedPDFFile: Text;

    [Test]
    [HandlerFunctions('AgedAccountsReceivableHandler')]
    [Scope('OnPrem')]
    procedure AgedAccountsReceivableReport()
    begin
        SmallBusinessReportCatalogCU.RunAgedAccountsReceivableReport(true);
    end;

    [Test]
    [HandlerFunctions('AgedAccountsPayableReportHandler')]
    [Scope('OnPrem')]
    procedure AgedAccountsPayableReport()
    begin
        SmallBusinessReportCatalogCU.RunAgedAccountsPayableReport(true);
    end;

    [Test]
    [HandlerFunctions('CustomerTop10ListReportHandler')]
    [Scope('OnPrem')]
    procedure CustomerTop10ListReport()
    begin
        SmallBusinessReportCatalogCU.RunCustomerTop10ListReport(true);
    end;

    [Test]
    [HandlerFunctions('VendorTop10ListReportHandler')]
    [Scope('OnPrem')]
    procedure VendorTop10ListReport()
    begin
        SmallBusinessReportCatalogCU.RunVendorTop10ListReport(true);
    end;

    [Test]
    [HandlerFunctions('CustomerStatementReportHandler')]
    [Scope('OnPrem')]
    procedure CustomerStatementReport()
    begin
        SmallBusinessReportCatalogCU.RunCustomerStatementReport(true);
    end;

    [Test]
    [HandlerFunctions('TrialBalanceReportHandler')]
    [Scope('OnPrem')]
    procedure TrialBalanceReport()
    begin
        SmallBusinessReportCatalogCU.RunTrialBalanceReport(true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DetailTrialBalanceReport()
    begin
        SmallBusinessReportCatalogCU.RunDetailTrialBalanceReport(true);
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure AgedAccountsReceivableHandler(var AgedAccountsReceivable: TestRequestPage "Aged Accounts Receivable")
    var
        AgingBy: Option "Due Date","Posting Date","Document Date";
        HeadingType: Option "Date Interval","Number of Days";
    begin
        AgedAccountsReceivable.PeriodLength.AssertEquals('30D');
        AgedAccountsReceivable.AgedAsOf.AssertEquals(WorkDate());
        AgedAccountsReceivable.Agingby.AssertEquals(AgingBy::"Posting Date");
        AgedAccountsReceivable.HeadingType.AssertEquals(HeadingType::"Date Interval");

        SavedPDFFile := FileManagement.ServerTempFileName('.pdf');
        AgedAccountsReceivable.SaveAsPdf(SavedPDFFile);
        LibraryUtilityOnPrem.CheckFileNotEmpty(SavedPDFFile);
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure AgedAccountsPayableReportHandler(var AgedAccountsPayable: TestRequestPage "Aged Accounts Payable")
    var
        AgingBy: Option "Due Date","Posting Date","Document Date";
        HeadingType: Option "Date Interval","Number of Days";
    begin
        AgedAccountsPayable.PeriodLength.AssertEquals('30D');
        AgedAccountsPayable.AgedAsOf.AssertEquals(WorkDate());
        AgedAccountsPayable.AgingBy.AssertEquals(AgingBy::"Posting Date");
        AgedAccountsPayable.HeadingType.AssertEquals(HeadingType::"Date Interval");

        SavedPDFFile := FileManagement.ServerTempFileName('.pdf');
        AgedAccountsPayable.SaveAsPdf(SavedPDFFile);
        LibraryUtilityOnPrem.CheckFileNotEmpty(SavedPDFFile);
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure CustomerTop10ListReportHandler(var CustomerTop10List: TestRequestPage "Customer - Top 10 List")
    var
        ChartType: Option "Bar chart","Pie chart";
    begin
        CustomerTop10List.NoOfRecordsToPrint.AssertEquals(10);
        CustomerTop10List.ChartType.AssertEquals(ChartType::"Bar chart");

        SavedPDFFile := FileManagement.ServerTempFileName('.pdf');
        CustomerTop10List.SaveAsPdf(SavedPDFFile);
        LibraryUtilityOnPrem.CheckFileNotEmpty(SavedPDFFile);
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure VendorTop10ListReportHandler(var VendorTop10List: TestRequestPage "Vendor - Top 10 List")
    var
        ShowType: Option "Purchases (LCY)","Balance (LCY)";
    begin
        VendorTop10List.Quantity.AssertEquals(10);
        VendorTop10List.Show.AssertEquals(ShowType::"Purchases (LCY)");

        SavedPDFFile := FileManagement.ServerTempFileName('.pdf');
        VendorTop10List.SaveAsPdf(SavedPDFFile);
        LibraryUtilityOnPrem.CheckFileNotEmpty(SavedPDFFile);
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure CustomerStatementReportHandler(var CustomerStatement: TestRequestPage Statement)
    var
        AccountingPeriodMgt: Codeunit "Accounting Period Mgt.";
        DateChoice: Option "Due Date","Posting Date";
    begin
        CustomerStatement.ShowOverdueEntries.AssertEquals(false);
        CustomerStatement.IncludeAllCustomerswithLE.AssertEquals(false);
        CustomerStatement.IncludeAllCustomerswithBalance.AssertEquals(true);
        CustomerStatement.IncludeReversedEntries.AssertEquals(false);
        CustomerStatement.IncludeUnappliedEntries.AssertEquals(false);
        CustomerStatement.IncludeAgingBand.AssertEquals(false);
        CustomerStatement.AgingBandPeriodLengt.AssertEquals('1M+CM');
        CustomerStatement.AgingBandby.AssertEquals(DateChoice::"Due Date");
        CustomerStatement.LogInteraction.AssertEquals(true);

        CustomerStatement."Start Date".AssertEquals(AccountingPeriodMgt.FindFiscalYear(WorkDate()));
        CustomerStatement."End Date".AssertEquals(WorkDate());

        SavedPDFFile := FileManagement.ServerTempFileName('.pdf');
        CustomerStatement.SaveAsPdf(SavedPDFFile);
        LibraryUtilityOnPrem.CheckFileNotEmpty(SavedPDFFile);
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure TrialBalanceReportHandler(var TrialBalance: TestRequestPage "Trial Balance")
    begin
        SavedPDFFile := FileManagement.ServerTempFileName('.pdf');
        TrialBalance.SaveAsPdf(SavedPDFFile);
        LibraryUtilityOnPrem.CheckFileNotEmpty(SavedPDFFile);
    end;
}
#endif