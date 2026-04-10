#if not CLEAN27
// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Utilities;

using Microsoft.Finance.GeneralLedger.Reports;
using Microsoft.Foundation.Period;
using Microsoft.Purchases.Reports;
using Microsoft.Sales.Customer;
using Microsoft.Sales.Reports;
using System.IO;

codeunit 9025 "Small Business Report Catalog"
{
    ObsoleteState = Pending;
    ObsoleteReason = 'The page that this codeunit is used in is no longer used. Therefore, this codeunit is no longer needed.';
    ObsoleteTag = '27.0';

    trigger OnRun()
    begin
    end;

    var
        ToFileNameTxt: Label 'DetailTrialBalance.xlsx';

    procedure RunAgedAccountsReceivableReport(UseRequestPage: Boolean)
    var
        AgedAccountsReceivable: Report "Aged Accounts Receivable";
        PeriodLength: DateFormula;
        AgingBy: Option "Due Date","Posting Date","Document Date";
        HeadingType: Option "Date Interval","Number of Days";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeRunAgedAccountsReceivableReport(UseRequestPage, IsHandled);
        if IsHandled then
            exit;

        Evaluate(PeriodLength, '<30D>');
        AgedAccountsReceivable.InitializeRequest(
          WorkDate(), AgingBy::"Posting Date", PeriodLength, false, false, HeadingType::"Date Interval", false);
        AgedAccountsReceivable.UseRequestPage(UseRequestPage);

        AgedAccountsReceivable.Run();
    end;

    procedure RunAgedAccountsPayableReport(UseRequestPage: Boolean)
    var
        AgedAccountsPayable: Report "Aged Accounts Payable";
        PeriodLength: DateFormula;
        AgingBy: Option "Due Date","Posting Date","Document Date";
        HeadingType: Option "Date Interval","Number of Days";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeRunAgedAccountsPayableReport(UseRequestPage, IsHandled);
        if IsHandled then
            exit;

        Evaluate(PeriodLength, '<30D>');
        AgedAccountsPayable.InitializeRequest(
          WorkDate(), AgingBy::"Posting Date", PeriodLength, false, false, HeadingType::"Date Interval", false);
        AgedAccountsPayable.UseRequestPage(UseRequestPage);

        AgedAccountsPayable.Run();
    end;

    procedure RunCustomerTop10ListReport(UseRequestPage: Boolean)
    var
        CustomerTop10ListReport: Report "Customer - Top 10 List";
        ChartType: Option "Bar chart","Pie chart";
        ShowType: Option "Sales (LCY)","Balance (LCY)";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeRunCustomerTop10ListReport(UseRequestPage, IsHandled);
        if IsHandled then
            exit;

        CustomerTop10ListReport.InitializeRequest(ChartType::"Bar chart", ShowType::"Sales (LCY)", 10);
        CustomerTop10ListReport.UseRequestPage(UseRequestPage);
        CustomerTop10ListReport.Run();
    end;

    procedure RunVendorTop10ListReport(UseRequestPage: Boolean)
    var
        VendorTop10ListReport: Report "Vendor - Top 10 List";
        ShowType: Option "Purchases (LCY)","Balance (LCY)";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeRunVendorTop10ListReport(UseRequestPage, IsHandled);
        if IsHandled then
            exit;

        VendorTop10ListReport.InitializeRequest(ShowType::"Purchases (LCY)", 10);
        VendorTop10ListReport.UseRequestPage(UseRequestPage);
        VendorTop10ListReport.Run();
    end;

    procedure RunCustomerStatementReport(UseRequestPage: Boolean)
    var
        CustomerStatementReport: Report Statement;
        AccountingPeriodMgt: Codeunit "Accounting Period Mgt.";
        NewPrintEntriesDue: Boolean;
        NewPrintAllHavingEntry: Boolean;
        NewPrintAllHavingBal: Boolean;
        NewPrintReversedEntries: Boolean;
        NewPrintUnappliedEntries: Boolean;
        NewIncludeAgingBand: Boolean;
        NewPeriodLength: Text[30];
        NewDateChoice: Option;
        NewLogInteraction: Boolean;
        NewStartDate: Date;
        NewEndDate: Date;
        DateChoice: Option "Due Date","Posting Date";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeRunCustomerStatementReport(UseRequestPage, IsHandled);
        if IsHandled then
            exit;

        // Use default parameters when you launch the request page, with Start/End Date being the YTD of current financial year
        NewPrintEntriesDue := false;
        NewPrintAllHavingEntry := false;
        NewPrintAllHavingBal := true;
        NewPrintReversedEntries := false;
        NewPrintUnappliedEntries := false;
        NewIncludeAgingBand := false;
        NewPeriodLength := '<1M+CM>';
        NewDateChoice := DateChoice::"Due Date";
        NewLogInteraction := true;

        NewStartDate := AccountingPeriodMgt.FindFiscalYear(WorkDate());
        NewEndDate := WorkDate();

        CustomerStatementReport.InitializeRequest(
          NewPrintEntriesDue, NewPrintAllHavingEntry, NewPrintAllHavingBal, NewPrintReversedEntries,
          NewPrintUnappliedEntries, NewIncludeAgingBand, NewPeriodLength, NewDateChoice,
          NewLogInteraction, NewStartDate, NewEndDate);
        CustomerStatementReport.UseRequestPage(UseRequestPage);
        CustomerStatementReport.Run();
    end;

    procedure RunTrialBalanceReport(UseRequestPage: Boolean)
    var
        TrialBalance: Report "Trial Balance";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeRunTrialBalanceReport(UseRequestPage, IsHandled);
        if IsHandled then
            exit;

        TrialBalance.UseRequestPage(UseRequestPage);
        TrialBalance.Run();
    end;

    [Scope('OnPrem')]
    procedure RunDetailTrialBalanceReport(UseRequestPage: Boolean)
    var
        DetailTrialBalance: Report "Detail Trial Balance";
        FileMgt: Codeunit "File Management";
        FileName: Text;
        ToFile: Text;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeRunDetailTrialBalanceReport(UseRequestPage, IsHandled);
        if IsHandled then
            exit;

        DetailTrialBalance.UseRequestPage(UseRequestPage);

        FileName := FileMgt.ServerTempFileName('xlsx');
        // Render report on the server
        DetailTrialBalance.SaveAsExcel(FileName);

        ToFile := ToFileNameTxt;
        Download(FileName, '', FileMgt.Magicpath(), '', ToFile);
        Erase(FileName);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeRunCustomerStatementReport(UseRequestPage: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeRunCustomerTop10ListReport(UseRequestPage: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeRunVendorTop10ListReport(UseRequestPage: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeRunTrialBalanceReport(UseRequestPage: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeRunDetailTrialBalanceReport(UseRequestPage: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeRunAgedAccountsReceivableReport(UseRequestPage: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeRunAgedAccountsPayableReport(UseRequestPage: Boolean; var IsHandled: Boolean)
    begin
    end;
}
#endif