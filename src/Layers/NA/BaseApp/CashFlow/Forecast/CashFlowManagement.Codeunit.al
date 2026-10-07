// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.CashFlow.Forecast;

using Microsoft.CashFlow.Account;
using Microsoft.CashFlow.Comment;
using Microsoft.CashFlow.Setup;
using Microsoft.CashFlow.Worksheet;
using Microsoft.Finance.Analysis;
using Microsoft.Finance.GeneralLedger.Account;
using Microsoft.Finance.GeneralLedger.Budget;
using Microsoft.Finance.SalesTax;
using Microsoft.Finance.VAT.Ledger;
using Microsoft.FixedAssets.FixedAsset;
using Microsoft.Foundation.NoSeries;
using Microsoft.Projects.Project.Planning;
using Microsoft.Purchases.Document;
using Microsoft.Purchases.Payables;
using Microsoft.Purchases.Posting;
using Microsoft.Sales.Document;
using Microsoft.Sales.Posting;
using Microsoft.Sales.Receivables;
using System.Security.AccessControl;
using System.Threading;

codeunit 841 "Cash Flow Management"
{

    trigger OnRun()
    begin
    end;

    var
#pragma warning disable AA0470
        SourceDataDoesNotExistErr: Label 'Source data does not exist for %1: %2.', Comment = 'Source data doesn''t exist for G/L Account: 8210.';
        SourceDataDoesNotExistInfoErr: Label 'Source data does not exist in %1 for %2: %3.', Comment = 'Source data doesn''t exist in Vendor Ledger Entry for Document No.: PO000123.';
#pragma warning restore AA0470
        SourceTypeNotSupportedErr: Label 'Source type is not supported.';
        DefaultTxt: Label 'Default';
        DummyDate: Date;
        CashFlowTxt: Label 'CashFlow';
        CashFlowForecastTxt: Label 'Cash Flow Forecast';
        CashFlowAbbreviationTxt: Label 'CF', Comment = 'Abbreviation of Cash Flow';
        UpdatingMsg: Label 'Updating Cash Flow Forecast...';
        JobQueueEntryDescTxt: Label 'Auto-created for updating of cash flow figures. Can be deleted if not used. Will be recreated when the feature is activated.';

    [Scope('OnPrem')]
    procedure ShowSourceDocument(CFVariant: Variant)
    var
        CFRecordRef: RecordRef;
        Handled: Boolean;
    begin
        OnBeforeShowSourceDocument(CFVariant, Handled);
        if Handled then
            exit;

        CFRecordRef.GetTable(CFVariant);
        case CFRecordRef.Number of
            DATABASE::"Cash Flow Worksheet Line":
                ShowSourceLocalCFWorkSheetLine(true, CFVariant);
            DATABASE::"Cash Flow Forecast Entry":
                ShowSourceLocalCFEntry(true, CFVariant);
        end;
    end;

    [Scope('OnPrem')]
    procedure ShowSource(CFVariant: Variant)
    var
        CFRecordRef: RecordRef;
        Handled: Boolean;
    begin
        OnBeforeShowSource(CFVariant, Handled);
        if Handled then
            exit;

        CFRecordRef.GetTable(CFVariant);
        case CFRecordRef.Number of
            DATABASE::"Cash Flow Worksheet Line":
                ShowSourceLocalCFWorkSheetLine(false, CFVariant);
            DATABASE::"Cash Flow Forecast Entry":
                ShowSourceLocalCFEntry(false, CFVariant);
        end;
    end;

    local procedure ShowSourceLocalCFWorkSheetLine(ShowDocument: Boolean; CFVariant: Variant)
    var
        CashFlowWorksheetLine: Record "Cash Flow Worksheet Line";
    begin
        CashFlowWorksheetLine := CFVariant;
        CashFlowWorksheetLine.TestField("Source Type");
        if CashFlowWorksheetLine."Source Type" <> CashFlowWorksheetLine."Source Type"::Tax then
            CashFlowWorksheetLine.TestField("Source No.");
        if CashFlowWorksheetLine."Source Type" = CashFlowWorksheetLine."Source Type"::"G/L Budget" then
            CashFlowWorksheetLine.TestField("G/L Budget Name");

        ShowSourceLocal(ShowDocument,
          CashFlowWorksheetLine."Source Type",
          CashFlowWorksheetLine."Source No.",
          CashFlowWorksheetLine."G/L Budget Name",
          CashFlowWorksheetLine."Document Date",
          CashFlowWorksheetLine."Document No.");
    end;

    local procedure ShowSourceLocalCFEntry(ShowDocument: Boolean; CFVariant: Variant)
    var
        CashFlowForecastEntry: Record "Cash Flow Forecast Entry";
    begin
        CashFlowForecastEntry := CFVariant;
        CashFlowForecastEntry.TestField("Source Type");
        if CashFlowForecastEntry."Source Type" <> CashFlowForecastEntry."Source Type"::Tax then
            CashFlowForecastEntry.TestField("Source No.");
        if CashFlowForecastEntry."Source Type" = CashFlowForecastEntry."Source Type"::"G/L Budget" then
            CashFlowForecastEntry.TestField("G/L Budget Name");

        ShowSourceLocal(ShowDocument,
          CashFlowForecastEntry."Source Type",
          CashFlowForecastEntry."Source No.",
          CashFlowForecastEntry."G/L Budget Name",
          CashFlowForecastEntry."Document Date",
          CashFlowForecastEntry."Document No.");
    end;

    local procedure ShowSourceLocal(ShowDocument: Boolean; SourceType: Enum "Cash Flow Source Type"; SourceNo: Code[20]; BudgetName: Code[10]; DocumentDate: Date; DocumentNo: Code[20])
    var
        CFWorksheetLine: Record "Cash Flow Worksheet Line";
        IsHandled: Boolean;
    begin
        case SourceType of
            CFWorksheetLine."Source Type"::"Liquid Funds":
                ShowLiquidFunds(SourceNo, ShowDocument);
            CFWorksheetLine."Source Type"::Receivables:
                ShowCustomer(SourceNo, ShowDocument);
            CFWorksheetLine."Source Type"::Payables:
                ShowVendor(SourceNo, ShowDocument);
            CFWorksheetLine."Source Type"::"Sales Orders":
                ShowSalesOrder(SourceNo);
            CFWorksheetLine."Source Type"::"Purchase Orders":
                ShowPurchaseOrder(SourceNo);
            CFWorksheetLine."Source Type"::"Cash Flow Manual Revenue":
                ShowManualRevenue(SourceNo);
            CFWorksheetLine."Source Type"::"Cash Flow Manual Expense":
                ShowManualExpense(SourceNo);
            CFWorksheetLine."Source Type"::"Fixed Assets Budget",
            CFWorksheetLine."Source Type"::"Fixed Assets Disposal":
                ShowFixedAsset(SourceNo);
            CFWorksheetLine."Source Type"::"G/L Budget":
                ShowGLBudget(BudgetName, SourceNo);
            CFWorksheetLine."Source Type"::Job:
                ShowJob(SourceNo, DocumentDate, DocumentNo);
            CFWorksheetLine."Source Type"::Tax:
                ShowTax(SourceNo, DocumentDate);
            CFWorksheetLine."Source Type"::"Azure AI":
                ShowAzureAIForecast();
            else begin
                IsHandled := false;
                OnShowSourceLocalSourceTypeCase(SourceType, SourceNo, ShowDocument, DocumentNo, DocumentDate, BudgetName, IsHandled);
                if not IsHandled then
                    Error(SourceTypeNotSupportedErr);
            end;
        end;
    end;

    local procedure ShowLiquidFunds(SourceNo: Code[20]; ShowDocument: Boolean)
    var
        GLAccount: Record "G/L Account";
    begin
        GLAccount.SetRange("No.", SourceNo);
        if not GLAccount.FindFirst() then
            Error(SourceDataDoesNotExistErr, GLAccount.TableCaption(), SourceNo);
        if ShowDocument then
            PAGE.Run(PAGE::"G/L Account Card", GLAccount)
        else
            PAGE.Run(PAGE::"Chart of Accounts", GLAccount);
    end;

    local procedure ShowCustomer(SourceNo: Code[20]; ShowDocument: Boolean)
    var
        CustLedgEntry: Record "Cust. Ledger Entry";
    begin
        CustLedgEntry.SetRange("Document No.", SourceNo);
        if not CustLedgEntry.FindFirst() then
            Error(SourceDataDoesNotExistInfoErr, CustLedgEntry.TableCaption(), CustLedgEntry.FieldCaption("Document No."), SourceNo);
        if ShowDocument then
            CustLedgEntry.ShowDoc()
        else
            PAGE.Run(0, CustLedgEntry);
    end;

    local procedure ShowVendor(SourceNo: Code[20]; ShowDocument: Boolean)
    var
        VendLedgEntry: Record "Vendor Ledger Entry";
    begin
        VendLedgEntry.SetRange("Document No.", SourceNo);
        if not VendLedgEntry.FindFirst() then
            Error(SourceDataDoesNotExistInfoErr, VendLedgEntry.TableCaption(), VendLedgEntry.FieldCaption("Document No."), SourceNo);
        if ShowDocument then
            VendLedgEntry.ShowDoc()
        else
            PAGE.Run(0, VendLedgEntry);
    end;

    local procedure ShowSalesOrder(SourceNo: Code[20])
    var
        SalesHeader: Record "Sales Header";
        SalesOrder: Page "Sales Order";
        SourceType: Enum "Cash Flow Source Type";
    begin
        SalesHeader.SetRange("Document Type", SalesHeader."Document Type"::Order);
        SalesHeader.SetRange("No.", SourceNo);
        if not SalesHeader.FindFirst() then
            Error(SourceDataDoesNotExistErr, SourceType::"Sales Orders", SourceNo);
        SalesOrder.SetTableView(SalesHeader);
        SalesOrder.Run();
    end;

    local procedure ShowPurchaseOrder(SourceNo: Code[20])
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseOrder: Page "Purchase Order";
        SourceType: Enum "Cash Flow Source Type";
    begin
        PurchaseHeader.SetRange("Document Type", PurchaseHeader."Document Type"::Order);
        PurchaseHeader.SetRange("No.", SourceNo);
        if not PurchaseHeader.FindFirst() then
            Error(SourceDataDoesNotExistErr, SourceType::"Purchase Orders", SourceNo);
        PurchaseOrder.SetTableView(PurchaseHeader);
        PurchaseOrder.Run();
    end;

    local procedure ShowManualRevenue(SourceNo: Code[20])
    var
        CFManualRevenue: Record "Cash Flow Manual Revenue";
        CFManualRevenues: Page "Cash Flow Manual Revenues";
    begin
        CFManualRevenue.SetRange(Code, SourceNo);
        if not CFManualRevenue.FindFirst() then
            Error(SourceDataDoesNotExistErr, CFManualRevenues.Caption, SourceNo);
        CFManualRevenues.SetTableView(CFManualRevenue);
        CFManualRevenues.Run();
    end;

    local procedure ShowManualExpense(SourceNo: Code[20])
    var
        CFManualExpense: Record "Cash Flow Manual Expense";
        CFManualExpenses: Page "Cash Flow Manual Expenses";
    begin
        CFManualExpense.SetRange(Code, SourceNo);
        if not CFManualExpense.FindFirst() then
            Error(SourceDataDoesNotExistErr, CFManualExpenses.Caption, SourceNo);
        CFManualExpenses.SetTableView(CFManualExpense);
        CFManualExpenses.Run();
    end;

    local procedure ShowFixedAsset(SourceNo: Code[20])
    var
        FixedAsset: Record "Fixed Asset";
    begin
        FixedAsset.SetRange("No.", SourceNo);
        if not FixedAsset.FindFirst() then
            Error(SourceDataDoesNotExistInfoErr, FixedAsset.TableCaption(), FixedAsset.FieldCaption("No."), SourceNo);
        PAGE.Run(PAGE::"Fixed Asset Card", FixedAsset);
    end;

    local procedure ShowGLBudget(BudgetName: Code[10]; SourceNo: Code[20])
    var
        GLBudgetName: Record "G/L Budget Name";
        GLAccount: Record "G/L Account";
        Budget: Page Budget;
    begin
        if not GLAccount.Get(SourceNo) then
            Error(SourceDataDoesNotExistErr, GLAccount.TableCaption(), SourceNo);
        if not GLBudgetName.Get(BudgetName) then
            Error(SourceDataDoesNotExistErr, GLBudgetName.TableCaption(), BudgetName);
        Budget.SetBudgetName(BudgetName);
        Budget.SetGLAccountFilter(SourceNo);
        Budget.Run();
    end;

    local procedure ShowAzureAIForecast()
    begin
    end;

    procedure CashFlowNameFullLength(CashFlowNo: Code[20]): Text[100]
    var
        CashFlowForecast: Record "Cash Flow Forecast";
    begin
        if CashFlowForecast.Get(CashFlowNo) then
            exit(CashFlowForecast.Description);

        exit('')
    end;

    procedure CashFlowAccountName(CashFlowAccountNo: Code[20]): Text[100]
    var
        CashFlowAccount: Record "Cash Flow Account";
    begin
        if CashFlowAccount.Get(CashFlowAccountNo) then
            exit(CashFlowAccount.Name);
        exit('')
    end;

    local procedure ShowJob(SourceNo: Code[20]; DocumentDate: Date; DocumentNo: Code[20])
    var
        JobPlanningLine: Record "Job Planning Line";
        JobPlanningLines: Page "Job Planning Lines";
    begin
        JobPlanningLine.SetRange("Job No.", SourceNo);
        JobPlanningLine.SetRange("Document Date", DocumentDate);
        JobPlanningLine.SetRange("Document No.", DocumentNo);
        JobPlanningLine.SetFilter("Line Type",
          StrSubstNo('%1|%2',
            JobPlanningLine."Line Type"::Billable,
            JobPlanningLine."Line Type"::"Both Budget and Billable"));
        if not JobPlanningLine.FindFirst() then
            Error(SourceDataDoesNotExistErr, JobPlanningLines.Caption, SourceNo);
        JobPlanningLines.SetTableView(JobPlanningLine);
        JobPlanningLines.Run();
    end;

    local procedure ShowTax(SourceNo: Code[20]; TaxPayableDate: Date)
    var
        PurchaseHeader: Record "Purchase Header";
        SalesHeader: Record "Sales Header";
        VATEntry: Record "VAT Entry";
        SalesOrderList: Page "Sales Order List";
        PurchaseOrderList: Page "Purchase Order List";
        SourceNum: Integer;
    begin
        Evaluate(SourceNum, SourceNo);
        case SourceNum of
            DATABASE::"Purchase Header":
                begin
                    SetViewOnPurchaseHeaderForTaxCalc(PurchaseHeader, TaxPayableDate);
                    PurchaseOrderList.SkipShowingLinesWithoutVAT();
                    PurchaseOrderList.SetTableView(PurchaseHeader);
                    PurchaseOrderList.Run();
                end;
            DATABASE::"Sales Header":
                begin
                    SetViewOnSalesHeaderForTaxCalc(SalesHeader, TaxPayableDate);
                    SalesOrderList.SkipShowingLinesWithoutVAT();
                    SalesOrderList.SetTableView(SalesHeader);
                    SalesOrderList.Run();
                end;
            DATABASE::"VAT Entry":
                begin
                    SetViewOnVATEntryForTaxCalc(VATEntry, TaxPayableDate);
                    PAGE.Run(PAGE::"VAT Entries", VATEntry);
                end;
        end;
    end;

    procedure RecurrenceToRecurringFrequency(Recurrence: Option " ",Daily,Weekly,Monthly,Quarterly,Yearly) RecurringFrequency: Text
    begin
        case Recurrence of
            Recurrence::Daily:
                RecurringFrequency := '<1D>';
            Recurrence::Weekly:
                RecurringFrequency := '<1W>';
            Recurrence::Monthly:
                RecurringFrequency := '<1M>';
            Recurrence::Quarterly:
                RecurringFrequency := '<1Q>';
            Recurrence::Yearly:
                RecurringFrequency := '<1Y>';
            else
                RecurringFrequency := '';
        end;
    end;

    procedure RecurringFrequencyToRecurrence(RecurringFrequency: DateFormula; var RecurrenceOut: Option " ",Daily,Weekly,Monthly,Quarterly,Yearly)
    var
        Daily: DateFormula;
        Weekly: DateFormula;
        Monthly: DateFormula;
        Quarterly: DateFormula;
        Yearly: DateFormula;
    begin
        Evaluate(Daily, '<1D>');
        Evaluate(Weekly, '<1W>');
        Evaluate(Monthly, '<1M>');
        Evaluate(Quarterly, '<1Q>');
        Evaluate(Yearly, '<1Y>');

        case RecurringFrequency of
            Daily:
                RecurrenceOut := RecurrenceOut::Daily;
            Weekly:
                RecurrenceOut := RecurrenceOut::Weekly;
            Monthly:
                RecurrenceOut := RecurrenceOut::Monthly;
            Quarterly:
                RecurrenceOut := RecurrenceOut::Quarterly;
            Yearly:
                RecurrenceOut := RecurrenceOut::Yearly;
            else
                RecurrenceOut := RecurrenceOut::" ";
        end;
    end;

    procedure CreateAndStartJobQueueEntry(UpdateFrequency: Option Never,Daily,Weekly)
    var
        JobQueueEntry: Record "Job Queue Entry";
        JobQueueManagement: Codeunit "Job Queue Management";
    begin
        // Create a new job queue entry for Cash Flow Forecast
        JobQueueEntry."No. of Minutes between Runs" := UpdateFrequencyToNoOfMinutes(UpdateFrequency);
        JobQueueEntry."Object Type to Run" := JobQueueEntry."Object Type to Run"::Codeunit;
        JobQueueEntry."Object ID to Run" := CODEUNIT::"Cash Flow Forecast Update";
        JobQueueEntry.Description := CopyStr(JobQueueEntryDescTxt, 1, MaxStrLen(JobQueueEntry.Description));
        JobQueueManagement.CreateJobQueueEntry(JobQueueEntry);

        // Start it
        CODEUNIT.Run(CODEUNIT::"Job Queue - Enqueue", JobQueueEntry);
    end;

    procedure DeleteJobQueueEntries()
    var
        JobQueueEntry: Record "Job Queue Entry";
        JobQueueManagement: Codeunit "Job Queue Management";
    begin
        JobQueueManagement.DeleteJobQueueEntries(JobQueueEntry."Object Type to Run"::Codeunit, CODEUNIT::"Cash Flow Forecast Update");
    end;

    procedure GetCashAccountFilter() CashAccountFilter: Text
    var
        GLAccountCategory: Record "G/L Account Category";
    begin
        GLAccountCategory.SetRange("Additional Report Definition", GLAccountCategory."Additional Report Definition"::"Cash Accounts");
        if not GLAccountCategory.FindSet() then
            exit;

        CashAccountFilter := GLAccountCategory.GetTotaling();

        while GLAccountCategory.Next() <> 0 do
            CashAccountFilter += '|' + GLAccountCategory.GetTotaling();

        CashAccountFilter := CashAccountFilter.TrimStart('|').TrimEnd('|');
    end;

    procedure SetupCashFlow(LiquidFundsGLAccountFilter: Code[250])
    var
        CashFlowNoSeriesCode: Code[20];
    begin
        DeleteExistingSetup();
        CreateCashFlowAccounts(LiquidFundsGLAccountFilter);
        CashFlowNoSeriesCode := CreateCashFlowNoSeries();
        CreateCashFlowSetup(CashFlowNoSeriesCode);
        CreateCashFlowForecast();
        CreateCashFlowChartSetup();
        CreateCashFlowReportSelection();
    end;

    local procedure DeleteExistingSetup()
    var
        CashFlowForecast: Record "Cash Flow Forecast";
        CashFlowAccount: Record "Cash Flow Account";
        CashFlowAccountComment: Record "Cash Flow Account Comment";
        CashFlowSetup: Record "Cash Flow Setup";
        CashFlowWorksheetLine: Record "Cash Flow Worksheet Line";
        CashFlowForecastEntry: Record "Cash Flow Forecast Entry";
        CashFlowManualRevenue: Record "Cash Flow Manual Revenue";
        CashFlowManualExpense: Record "Cash Flow Manual Expense";
        CashFlowReportSelection: Record "Cash Flow Report Selection";
        CashFlowChartSetup: Record "Cash Flow Chart Setup";
        JobQueueEntry: Record "Job Queue Entry";
        JobQueueManagement: Codeunit "Job Queue Management";
    begin
        CashFlowForecast.DeleteAll();
        CashFlowAccount.DeleteAll();
        CashFlowAccountComment.DeleteAll();
        CashFlowSetup.DeleteAll();
        CashFlowWorksheetLine.DeleteAll();
        CashFlowForecastEntry.DeleteAll();
        CashFlowManualRevenue.DeleteAll();
        CashFlowManualExpense.DeleteAll();
        CashFlowReportSelection.DeleteAll();
        CashFlowChartSetup.DeleteAll();
        JobQueueManagement.DeleteJobQueueEntries(JobQueueEntry."Object Type to Run"::Codeunit, CODEUNIT::"Cash Flow Forecast Update");
    end;

    local procedure CreateCashFlowAccounts(LiquidFundsGLAccountFilter: Code[250])
    var
        CashFlowAccount: Record "Cash Flow Account";
    begin
        CreateCashFlowAccount(CashFlowAccount."Source Type"::Receivables, '');
        CreateCashFlowAccount(CashFlowAccount."Source Type"::Payables, '');
        CreateCashFlowAccount(CashFlowAccount."Source Type"::"Sales Orders", '');
        CreateCashFlowAccount(CashFlowAccount."Source Type"::"Purchase Orders", '');
        CreateCashFlowAccount(CashFlowAccount."Source Type"::"Fixed Assets Budget", '');
        CreateCashFlowAccount(CashFlowAccount."Source Type"::"Fixed Assets Disposal", '');
        CreateCashFlowAccount(CashFlowAccount."Source Type"::"Liquid Funds", LiquidFundsGLAccountFilter);
        CreateCashFlowAccount(CashFlowAccount."Source Type"::Job, '');
        CreateCashFlowAccount(CashFlowAccount."Source Type"::"Cash Flow Manual Expense", '');
        CreateCashFlowAccount(CashFlowAccount."Source Type"::"Cash Flow Manual Revenue", '');
        CreateCashFlowAccount(CashFlowAccount."Source Type"::Tax, '');
        OnAfterCreateCashFlowAccounts(LiquidFundsGLAccountFilter);
    end;

    procedure CreateCashFlowAccount(SourceType: Enum "Cash Flow Source Type"; LiquidFundsGLAccountFilter: Code[250])
    var
        CashFlowAccount: Record "Cash Flow Account";
    begin
        InitCashFlowAccount(CashFlowAccount, SourceType);
        if SourceType = CashFlowAccount."Source Type"::"Liquid Funds" then begin
            CashFlowAccount."G/L Integration" := CashFlowAccount."G/L Integration"::Balance;
            CashFlowAccount."G/L Account Filter" := LiquidFundsGLAccountFilter;
        end;
        CashFlowAccount.Insert();
    end;

    procedure GetNoFromSourceType(SourceType: Option): Text
    var
        CashFlowAccount: Record "Cash Flow Account";
    begin
        CashFlowAccount."Source Type" := "Cash Flow Source Type".FromInteger(SourceType);
        exit(CopyStr(StrSubstNo('%1-%2', SourceType, Format(CashFlowAccount."Source Type")), 1, MaxStrLen(CashFlowAccount."No.")));
    end;

    local procedure InitCashFlowAccount(var CashFlowAccount: Record "Cash Flow Account"; SourceType: Enum "Cash Flow Source Type")
    begin
        CashFlowAccount.Init();
        CashFlowAccount.Validate("Source Type", SourceType);
        CashFlowAccount.Validate("No.", GetNoFromSourceType(SourceType.AsInteger()));
        CashFlowAccount.Validate(Name, Format(CashFlowAccount."Source Type", MaxStrLen(CashFlowAccount.Name)));
    end;

    local procedure CreateCashFlowForecast()
    var
        CashFlowForecast: Record "Cash Flow Forecast";
    begin
        CashFlowForecast.Init();
        CashFlowForecast.Validate("No.", DefaultTxt);
        CashFlowForecast.Validate(Description, DefaultTxt);
        CashFlowForecast.ValidateShowInChart(true);
        CashFlowForecast."Overdue CF Dates to Work Date" := true;
        CashFlowForecast.Insert();
    end;

    local procedure CreateCashFlowNoSeries(): Code[20]
    var
        NoSeries: Record "No. Series";
        NoSeriesLine: Record "No. Series Line";
    begin
        if NoSeries.Get(CashFlowTxt) then
            exit(NoSeries.Code);

        NoSeries.Init();
        NoSeries.Code := CashFlowTxt;
        NoSeries.Description := CashFlowForecastTxt;
        NoSeries."Default Nos." := true;
        NoSeries."Manual Nos." := true;
        NoSeries.Insert();

        NoSeriesLine.Init();
        NoSeriesLine."Series Code" := NoSeries.Code;
        NoSeriesLine."Line No." := 10000;
        NoSeriesLine.Validate("Starting No.", CashFlowAbbreviationTxt + '000001');
        NoSeriesLine.Insert(true);

        exit(NoSeries.Code);
    end;

    local procedure CreateCashFlowSetup(CashFlowNoSeriesCode: Code[20])
    var
        CashFlowSetup: Record "Cash Flow Setup";
        CashFlowAccount: Record "Cash Flow Account";
    begin
        CashFlowSetup.Init();
        CashFlowSetup.Validate("Cash Flow Forecast No. Series", CashFlowNoSeriesCode);
        CashFlowSetup.Validate("Receivables CF Account No.", GetNoFromSourceType(CashFlowAccount."Source Type"::Receivables.AsInteger()));
        CashFlowSetup.Validate("Payables CF Account No.", GetNoFromSourceType(CashFlowAccount."Source Type"::Payables.AsInteger()));
        CashFlowSetup.Validate("Sales Order CF Account No.", GetNoFromSourceType(CashFlowAccount."Source Type"::"Sales Orders".AsInteger()));
        CashFlowSetup.Validate("Purch. Order CF Account No.", GetNoFromSourceType(CashFlowAccount."Source Type"::"Purchase Orders".AsInteger()));
        CashFlowSetup.Validate("FA Budget CF Account No.", GetNoFromSourceType(CashFlowAccount."Source Type"::"Fixed Assets Budget".AsInteger()));
        CashFlowSetup.Validate(
            "FA Disposal CF Account No.", GetNoFromSourceType(CashFlowAccount."Source Type"::"Fixed Assets Disposal".AsInteger()));
        CashFlowSetup.Validate("Job CF Account No.", GetNoFromSourceType(CashFlowAccount."Source Type"::Job.AsInteger()));
        CashFlowSetup.Validate("Tax CF Account No.", GetNoFromSourceType(CashFlowAccount."Source Type"::Tax.AsInteger()));
        OnBeforeInsertOnCreateCashFlowSetup(CashFlowSetup, CashFlowNoSeriesCode);
        CashFlowSetup.Insert();
    end;

    local procedure CreateCashFlowChartSetup()
    var
        User: Record User;
    begin
        if not User.FindSet() then
            CreateCashFlowChartSetupForUser(UserId)
        else
            repeat
                CreateCashFlowChartSetupForUser(User."User Name");
            until User.Next() = 0;
    end;

    local procedure CreateCashFlowChartSetupForUser(UserName: Code[50])
    var
        CashFlowChartSetup: Record "Cash Flow Chart Setup";
    begin
        CashFlowChartSetup.Init();
        CashFlowChartSetup."User ID" := UserName;
        CashFlowChartSetup.Show := CashFlowChartSetup.Show::Combined;
        CashFlowChartSetup."Start Date" := CashFlowChartSetup."Start Date"::"Working Date";
        CashFlowChartSetup."Period Length" := CashFlowChartSetup."Period Length"::Month;
        CashFlowChartSetup."Group By" := CashFlowChartSetup."Group By"::"Source Type";
        CashFlowChartSetup.Insert();
    end;

    local procedure CreateCashFlowReportSelection()
    var
        CashFlowReportSelection: Record "Cash Flow Report Selection";
    begin
        CashFlowReportSelection.NewRecord();
        CashFlowReportSelection.Validate("Report ID", 846);
        CashFlowReportSelection.Insert();
    end;

    procedure UpdateCashFlowForecast(AzureAIEnabled: Boolean)
    var
        CashFlowForecast: Record "Cash Flow Forecast";
        CashFlowSetup: Record "Cash Flow Setup";
        SuggestWorksheetLines: Report "Suggest Worksheet Lines";
        Window: Dialog;
        Sources: array[16] of Boolean;
        Index: Integer;
        SourceType: Enum "Cash Flow Source Type";
        Handled: Boolean;
    begin
        OnBeforeUpdateCashFlowForecast(AzureAIEnabled, Handled);
        if Handled then
            exit;

        Window.Open(UpdatingMsg);

        if not CashFlowSetup.Get() then
            exit;

        if not CashFlowForecast.Get(CashFlowSetup."CF No. on Chart in Role Center") then
            exit;

        UpdateCashFlowForecastManualPaymentHorizon(CashFlowForecast);

        for Index := 1 to ArrayLen(Sources) do
            Sources[Index] := true;

        Sources[SourceType::"Azure AI".AsInteger()] := AzureAIEnabled;
        SuggestWorksheetLines.InitializeRequest(
          Sources, CashFlowSetup."CF No. on Chart in Role Center", CashFlowForecast."Default G/L Budget Name", true);
        SuggestWorksheetLines.UseRequestPage := false;
        OnBeforeRunSuggestWorksheetLinesOnUpdateCashFlowForecast(SuggestWorksheetLines);
        SuggestWorksheetLines.Run();
        CODEUNIT.Run(CODEUNIT::"Cash Flow Wksh.-Register Batch");

        Window.Close();
    end;

    local procedure UpdateCashFlowForecastManualPaymentHorizon(var CashFlowForecast: Record "Cash Flow Forecast")
    begin
        CashFlowForecast.Validate("Manual Payments From", WorkDate());
        CashFlowForecast.Validate("Manual Payments To", CalcDate('<+1Y>', WorkDate()));
        CashFlowForecast.Modify();
    end;

    local procedure UpdateFrequencyToNoOfMinutes(UpdateFrequency: Option Never,Daily,Weekly): Integer
    begin
        case UpdateFrequency of
            UpdateFrequency::Never:
                exit(0);
            UpdateFrequency::Daily:
                exit(60 * 24);
            UpdateFrequency::Weekly:
                exit(60 * 24 * 7);
        end;
    end;

    procedure SetViewOnPurchaseHeaderForTaxCalc(var PurchaseHeader: Record "Purchase Header"; TaxPaymentDueDate: Date)
    var
        CashFlowSetup: Record "Cash Flow Setup";
        StartDate: Date;
        EndDate: Date;
    begin
        DummyDate := 0D;
        PurchaseHeader.SetRange("Document Type", PurchaseHeader."Document Type"::Order);
        PurchaseHeader.SetFilter("Document Date", '<>%1', DummyDate);
        if TaxPaymentDueDate <> DummyDate then begin
            CashFlowSetup.GetTaxPeriodStartEndDates(TaxPaymentDueDate, StartDate, EndDate);
            PurchaseHeader.SetFilter("Document Date", StrSubstNo('%1..%2', StartDate, EndDate));
        end;
        PurchaseHeader.SetCurrentKey("Document Date");
        PurchaseHeader.SetAscending("Document Date", true);
    end;

    procedure SetViewOnSalesHeaderForTaxCalc(var SalesHeader: Record "Sales Header"; TaxPaymentDueDate: Date)
    var
        CashFlowSetup: Record "Cash Flow Setup";
        StartDate: Date;
        EndDate: Date;
    begin
        SalesHeader.SetRange("Document Type", SalesHeader."Document Type"::Order);
        SalesHeader.SetFilter("Document Date", '<>%1', DummyDate);
        if TaxPaymentDueDate <> DummyDate then begin
            CashFlowSetup.GetTaxPeriodStartEndDates(TaxPaymentDueDate, StartDate, EndDate);
            SalesHeader.SetFilter("Document Date", StrSubstNo('%1..%2', StartDate, EndDate));
        end;
        SalesHeader.SetCurrentKey("Document Date");
        SalesHeader.SetAscending("Document Date", true);
    end;

    procedure SetViewOnVATEntryForTaxCalc(var VATEntry: Record "VAT Entry"; TaxPaymentDueDate: Date)
    var
        CashFlowSetup: Record "Cash Flow Setup";
        StartDate: Date;
        EndDate: Date;
    begin
        VATEntry.SetFilter(Type, StrSubstNo('%1|%2', VATEntry.Type::Purchase, VATEntry.Type::Sale));
        VATEntry.SetFilter("VAT Calculation Type", StrSubstNo('<>%1', VATEntry."VAT Calculation Type"::"Reverse Charge VAT"));
        VATEntry.SetRange(Closed, false);
        VATEntry.SetFilter(Amount, '<>%1', 0);
        VATEntry.SetFilter("Document Date", '<>%1', DummyDate);
        if TaxPaymentDueDate <> DummyDate then begin
            CashFlowSetup.GetTaxPeriodStartEndDates(TaxPaymentDueDate, StartDate, EndDate);
            VATEntry.SetFilter("Document Date", StrSubstNo('%1..%2', StartDate, EndDate));
        end;
        VATEntry.SetCurrentKey("Document Date");
        VATEntry.SetAscending("Document Date", true);

        OnAfterSetViewOnVATEntryForTaxCalc(VATEntry, TaxPaymentDueDate, DummyDate);
    end;

    procedure GetTaxAmountFromSalesOrder(SalesHeader: Record "Sales Header"): Decimal
    var
        NewSalesLine: Record "Sales Line";
        NewSalesLineLCY: Record "Sales Line";
        TempSalesLine: Record "Sales Line" temporary;
        TempSalesTaxAmountLine: Record "Sales Tax Amount Line" temporary;
        TempSalesTaxAmtLine: Record "Sales Tax Amount Line" temporary;
        SalesPost: Codeunit "Sales-Post";
        SalesTaxCalculate: Codeunit "Sales Tax Calculate";
        QtyType: Option General,Invoicing,Shipping;
        VATAmount: Decimal;
        VATAmountText: Text[30];
        ProfitLCY: Decimal;
        ProfitPct: Decimal;
        TotalAdjCostLCY: Decimal;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeGetTaxAmountFromSalesOrder(SalesHeader, VATAmount, IsHandled);
        if IsHandled then
            exit(VATAmount);

        if SalesHeader."Tax Area Code" = '' then begin
            SalesPost.SumSalesLinesTemp(SalesHeader, TempSalesLine, QtyType::Invoicing, NewSalesLine, NewSalesLineLCY,
              VATAmount, VATAmountText, ProfitLCY, ProfitPct, TotalAdjCostLCY);
            exit(-1 * VATAmount);
        end;

        SalesPost.GetSalesLines(SalesHeader, TempSalesLine, QtyType::Invoicing);
        Clear(SalesPost);
        SalesTaxCalculate.StartSalesTaxCalculation();
        TempSalesLine.SetFilter(Type, '>0');
        TempSalesLine.SetFilter(Quantity, '<>0');
        TempSalesLine.SetFilter("Tax Group Code", '<>%1', '');
        if TempSalesLine.Find('-') then
            repeat
                SalesTaxCalculate.AddSalesLine(TempSalesLine);
            until TempSalesLine.Next() = 0;
        TempSalesLine.Reset();

        SalesTaxCalculate.EndSalesTaxCalculation(SalesHeader."Posting Date");
        SalesTaxCalculate.GetSalesTaxAmountLineTable(TempSalesTaxAmountLine);

        SalesTaxCalculate.GetSummarizedSalesTaxTable(TempSalesTaxAmtLine);

        TempSalesTaxAmtLine.Reset();
        TempSalesTaxAmtLine.SetCurrentKey("Print Order", "Tax Area Code for Key", "Tax Jurisdiction Code");
        if TempSalesTaxAmtLine.Find('-') then
            repeat
                VATAmount := VATAmount + TempSalesTaxAmtLine."Tax Amount";
            until TempSalesTaxAmtLine.Next() = 0;
        exit(-1 * VATAmount);
    end;

    procedure GetTaxAmountFromPurchaseOrder(PurchaseHeader: Record "Purchase Header"): Decimal
    var
        NewPurchLine: Record "Purchase Line";
        NewPurchLineLCY: Record "Purchase Line";
        TempPurchLine: Record "Purchase Line" temporary;
        TempSalesTaxAmountLine: Record "Sales Tax Amount Line" temporary;
        TempSalesTaxAmtLine: Record "Sales Tax Amount Line" temporary;
        PurchPost: Codeunit "Purch.-Post";
        SalesTaxCalculate: Codeunit "Sales Tax Calculate";
        QtyType: Option General,Invoicing,Shipping;
        VATAmount: Decimal;
        VATAmountText: Text[30];
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeGetTaxAmountFromPurchaseOrder(PurchaseHeader, VATAmount, IsHandled);
        if IsHandled then
            exit(VATAmount);

        if PurchaseHeader."Tax Area Code" = '' then begin
            PurchPost.SumPurchLinesTemp(PurchaseHeader, TempPurchLine, QtyType::Invoicing, NewPurchLine, NewPurchLineLCY,
              VATAmount, VATAmountText);
            exit(VATAmount);
        end;

        PurchPost.GetPurchLines(PurchaseHeader, TempPurchLine, QtyType::Invoicing);
        Clear(PurchPost);
        SalesTaxCalculate.StartSalesTaxCalculation();
        TempPurchLine.SetFilter(Type, '>0');
        TempPurchLine.SetFilter(Quantity, '<>0');
        if TempPurchLine.Find('-') then
            repeat
                SalesTaxCalculate.AddPurchLine(TempPurchLine);
            until TempPurchLine.Next() = 0;
        TempPurchLine.Reset();

        SalesTaxCalculate.EndSalesTaxCalculation(PurchaseHeader."Posting Date");
        SalesTaxCalculate.GetSalesTaxAmountLineTable(TempSalesTaxAmountLine);

        SalesTaxCalculate.GetSummarizedSalesTaxTable(TempSalesTaxAmtLine);

        TempSalesTaxAmtLine.Reset();
        TempSalesTaxAmtLine.SetCurrentKey("Print Order", "Tax Area Code for Key", "Tax Jurisdiction Code");
        if TempSalesTaxAmtLine.Find('-') then
            repeat
                VATAmount := VATAmount + TempSalesTaxAmtLine."Tax Amount";
            until TempSalesTaxAmtLine.Next() = 0;
        exit(VATAmount);
    end;

    procedure GetTotalAmountFromSalesOrder(SalesHeader: Record "Sales Header") Result: Decimal
    begin
        SalesHeader.CalcFields("Amount Including VAT");
        Result := SalesHeader."Amount Including VAT";
        OnAfterGetTotalAmountFromSalesOrder(SalesHeader, Result);
    end;

    procedure GetTotalAmountFromPurchaseOrder(PurchaseHeader: Record "Purchase Header"): Decimal
    begin
        PurchaseHeader.CalcFields("Amount Including VAT");
        exit(PurchaseHeader."Amount Including VAT");
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeGetTaxAmountFromPurchaseOrder(PurchaseHeader: Record "Purchase Header"; var VATAmount: Decimal; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeGetTaxAmountFromSalesOrder(SalesHeader: Record "Sales Header"; var VATAmount: Decimal; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeShowSource(CFVariant: Variant; var Handled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeShowSourceDocument(CFVariant: Variant; var Handled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeUpdateCashFlowForecast(AzureAIEnabled: Boolean; var Handled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnShowSourceLocalSourceTypeCase(SourceType: Enum "Cash Flow Source Type"; SourceNo: Code[20]; ShowDocument: Boolean; DocumentNo: Code[20]; DocumentDate: Date; BudgetName: Code[10]; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSetViewOnVATEntryForTaxCalc(var VATEntry: Record "VAT Entry"; TaxPaymentDueDate: Date; DummyDate: Date)
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnAfterCreateCashFlowAccounts(LiquidFundsGLAccountFilter: Code[250])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterGetTotalAmountFromSalesOrder(SalesHeader: Record "Sales Header"; var Result: Decimal)
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnBeforeInsertOnCreateCashFlowSetup(var CashFlowSetup: Record "Cash Flow Setup"; CashFlowNoSeriesCode: Code[20])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeRunSuggestWorksheetLinesOnUpdateCashFlowForecast(var SuggestWorksheetLines: Report "Suggest Worksheet Lines")
    begin
    end;
}
