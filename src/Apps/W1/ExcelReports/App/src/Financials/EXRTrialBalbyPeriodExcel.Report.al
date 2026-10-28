// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.Finance.ExcelReports;

using Microsoft.ExcelReports;
using Microsoft.Finance.Dimension;
using Microsoft.Finance.GeneralLedger.Account;
using Microsoft.Foundation.Company;

report 4408 "EXR Trial Bal by Period Excel"
{
    ApplicationArea = All;
    Caption = 'Trial Balance by Period (Excel)';
    DataAccessIntent = ReadOnly;
    DefaultRenderingLayout = TrialBalancebyPeriodExcelLayout;
    ExcelLayoutMultipleDataSheets = true;
    UsageCategory = ReportsAndAnalysis;
    MaximumDatasetSize = 1000000;

    dataset
    {
        dataitem(TrialBalanceByPeriod; "G/L Account")
        {
            DataItemTableView = sorting("No.");
            RequestFilterFields = "No.", "Account Type", "Date Filter";
            column(AccountNumber; "No.") { IncludeCaption = true; }
            column(AccountName; Name) { IncludeCaption = true; }
            column(IncomeBalance; "Income/Balance") { IncludeCaption = true; }
            column(AccountCategory; "Account Category") { IncludeCaption = true; }
            column(AccountSubcategory; "Account Subcategory Descript.") { IncludeCaption = true; }
            column(AccountType; "Account Type") { IncludeCaption = true; }
            column(Indentation; Indentation) { IncludeCaption = true; }
            column(IndentedAccountName; IndentedAccountName) { }

            dataitem(EXRTrialBalanceBuffer; "EXR Trial Balance Buffer")
            {
                DataItemTableView = sorting("G/L Account No.");
                DataItemLink = "G/L Account No." = field("No.");
                column(Account; "G/L Account No.") { IncludeCaption = true; }
                column(Dimension1Code; "Dimension 1 Code") { IncludeCaption = true; }
                column(Dimension2Code; "Dimension 2 Code") { IncludeCaption = true; }
                column(NetChange; "Net Change") { IncludeCaption = true; }
                column(PeriodStart; "Period Start") { IncludeCaption = true; }
                column(PeriodEnd; "Period End") { IncludeCaption = true; }
            }

            trigger OnAfterGetRecord()
            begin
                Clear(EXRTrialBalanceBuffer);
                EXRTrialBalanceBuffer.DeleteAll();
                IndentedAccountName := PadStr('', TrialBalanceByPeriod.Indentation * 2, ' ') + TrialBalanceByPeriod.Name;

                BuildDataset(TrialBalanceByPeriod);
            end;
        }
        dataitem(Dimension1; "Dimension Value")
        {
            DataItemTableView = sorting("Code") where("Global Dimension No." = const(1));

            column(Dim1Code; Dimension1."Code") { IncludeCaption = true; }
            column(Dim1Name; Dimension1.Name) { IncludeCaption = true; }
        }
        dataitem(Dimension2; "Dimension Value")
        {
            DataItemTableView = sorting("Code") where("Global Dimension No." = const(2));

            column(Dim2Code; Dimension2."Code") { IncludeCaption = true; }
            column(Dim2Name; Dimension2.Name) { IncludeCaption = true; }
        }
    }

    requestpage
    {
        SaveValues = true;
        AboutTitle = 'About Trial Balance by Period (Excel)';
        AboutText = 'View a trial balance with debit/credit columns for net change and balance for a period you specify. You get the report directly in Excel. See amounts in both local currency (LCY) and additional reporting currency (ACY), the latter only showing data if Additional Reporting Currency is in use. In addition to debit/credit for net change and balance the report shows the net debit/credit amount for both net change and balance for comparison. Data is summarized for the period specified in the report''s request page''s Date Filter parameter and grouped by the 2 global dimensions per G/L account category.';

        layout
        {
            area(content)
            {
                group(Options)
                {
                    Caption = 'Options';
                    field(PeriodLengthField; PeriodLength)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Period Length';
                        ToolTip = 'Specifies the period for which data is shown in the report. For example, enter "1M" for one month, "30D" for thirty days, "3Q" for three quarters, or "5Y" for five years.';
                    }
                    field(HideLinesWithZeroValuesField; HideLinesWithZeroValues)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Hide Lines with Zero Values';
                        ToolTip = 'Specifies whether to exclude lines where all calculated amounts are zero.';
                    }
                    // Used to set the date filter on the report header across multiple languages
                    field(RequestDateFilter; DateFilter)
                    {
                        ApplicationArea = All;
                        Caption = 'Date Filter';
                        ToolTip = 'Specifies the Date Filter applied to the EXR Trial Bal. by Period Report.';
                        Visible = false;
                    }
                }
            }
        }

        trigger OnOpenPage()
        begin
            Evaluate(PeriodLength, '<1M>');
        end;

        trigger OnClosePage()
        begin
            DateFilter := TrialBalanceByPeriod.GetFilter("Date Filter");
        end;
    }

    rendering
    {
        layout(TrialBalancebyPeriodExcelLayout)
        {
            Type = Excel;
            LayoutFile = './ReportLayouts/Excel/GeneralLedger/TrialBalancebyPeriodExcel.xlsx';
            Caption = 'Trial Balance by Period Excel';
            Summary = 'Built in layout for the Trial Balance by Period report. This report contains aggregated general ledger data per accounting period for the trial balance with a net debit/credit net change column for each period. Report uses Query connections.';
        }
    }
    labels
    {
        DataRetrieved = 'Data retrieved:';
        TrialBalanceByPeriod = 'Trial Balance by Period';
        TrialBalanceByPeriodPrint = 'Trial Bal. by Period (Print)', MaxLength = 31, Comment = 'Excel worksheet name.';
        TrialBalanceByPeriodAnalysis = 'Trial Bal. by Period (Analysis)', MaxLength = 31, Comment = 'Excel worksheet name.';
        YearPeriodStart = 'Year';
        DateFilterLabel = 'Date Filter:';
        // About the report labels
        AboutTheReportLabel = 'About the report', MaxLength = 31, Comment = 'Excel worksheet name.';
        EnvironmentLabel = 'Environment';
        CompanyLabel = 'Company';
        UserLabel = 'User';
        RunOnLabel = 'Run on';
        ReportNameLabel = 'Report name';
        DocumentationLabel = 'Documentation';
    }
    trigger OnPreReport()
    var
        ThisReportingStartDate: Date;
    begin
        TrialBalanceByPeriod.SecurityFiltering(SecurityFilter::Filtered);
        CompanyInformation.Get();
        ExcelReportsTelemetry.LogReportUsage(Report::"EXR Trial Bal by Period Excel");

        ReportingPeriodStartDate.Add(TrialBalanceByPeriod.GetRangeMin("Date Filter"));
        ThisReportingStartDate := TrialBalanceByPeriod.GetRangeMin("Date Filter");
        repeat
            ThisReportingStartDate := CalcDate(PeriodLength, ThisReportingStartDate);
            ReportingPeriodEndDate.Add(CalcDate('<-1D>', ThisReportingStartDate));
            ReportingPeriodStartDate.Add(ThisReportingStartDate);
        until ThisReportingStartDate >= TrialBalanceByPeriod.GetRangeMax("Date Filter");
        ReportingPeriodEndDate.Add(CalcDate('<-1D>', ThisReportingStartDate));

        LoadGlobalDimensionValueCodes(1, Dimension1Codes, Dimension1CodeLookup);
        LoadGlobalDimensionValueCodes(2, Dimension2Codes, Dimension2CodeLookup);
    end;

    var
        ExcelReportsTelemetry: Codeunit "Excel Reports Telemetry";
        DateFilter: Text;
        HideLinesWithZeroValues: Boolean;
        Dimension1Codes: List of [Code[20]];
        Dimension2Codes: List of [Code[20]];
        Dimension1CodeLookup: Dictionary of [Code[20], Boolean];
        Dimension2CodeLookup: Dictionary of [Code[20], Boolean];

    protected var
        CompanyInformation: Record "Company Information";
        PeriodLength: DateFormula;
        IndentedAccountName: Text;
        ReportingPeriodEndDate: List of [Date];
        ReportingPeriodStartDate: List of [Date];

    local procedure LoadGlobalDimensionValueCodes(GlobalDimensionNo: Integer; var DimensionCodes: List of [Code[20]]; var DimensionCodeLookup: Dictionary of [Code[20], Boolean])
    var
        DimensionValue: Record "Dimension Value";
    begin
        DimensionValue.SetLoadFields(Code);
        DimensionValue.SetRange("Global Dimension No.", GlobalDimensionNo);
        if DimensionValue.FindSet() then
            repeat
                if not DimensionCodeLookup.ContainsKey(DimensionValue.Code) then begin
                    DimensionCodes.Add(DimensionValue.Code);
                    DimensionCodeLookup.Add(DimensionValue.Code, true);
                end;
            until DimensionValue.Next() = 0;
    end;

    local procedure BuildDataset(var GLAccount: Record "G/L Account")
    var
        TempPeriodTotals: Record "EXR Trial Balance Buffer" temporary;
        ThisReportingEndDate: Date;
        ThisReportingStartDate: Date;
        i: Integer;
    begin
        // Each G/L account is read once per period with two grouped queries (net change and balance) instead of
        // calculating flowfields for every dimension combination, which scales with the number of dimension values.
        for i := 1 to ReportingPeriodStartDate.Count() do begin
            ThisReportingStartDate := ReportingPeriodStartDate.Get(i);
            ThisReportingEndDate := ReportingPeriodEndDate.Get(i);

            TempPeriodTotals.Reset();
            TempPeriodTotals.DeleteAll();
            AddEntriesToPeriodTotals(GLAccount, ThisReportingStartDate, ThisReportingEndDate, false, TempPeriodTotals);
            AddEntriesToPeriodTotals(GLAccount, ThisReportingStartDate, ThisReportingEndDate, true, TempPeriodTotals);
            InsertPeriodTotalsIntoDataset(GLAccount."No.", ThisReportingStartDate, ThisReportingEndDate, TempPeriodTotals);
        end;
    end;

    local procedure AddEntriesToPeriodTotals(var GLAccount: Record "G/L Account"; PeriodStartDate: Date; PeriodEndDate: Date; IsBalance: Boolean; var TempPeriodTotals: Record "EXR Trial Balance Buffer" temporary)
    var
        EXRTrialBalByPeriod: Query "EXR Trial Bal by Period";
        Dimension1Code: Code[20];
        Dimension2Code: Code[20];
        IsKnownDimension1Code: Boolean;
        IsKnownDimension2Code: Boolean;
    begin
        // The last reporting period starts the day after it ends (see OnPreReport), so it has no net change.
        if not IsBalance and (PeriodStartDate > PeriodEndDate) then
            exit;
        // Mirror the filters of the G/L Account flowfields: Totaling replaces the account number for total accounts.
        if GLAccount.Totaling <> '' then
            EXRTrialBalByPeriod.SetFilter(GLAccountNo, GLAccount.Totaling)
        else
            EXRTrialBalByPeriod.SetRange(GLAccountNo, GLAccount."No.");
        if IsBalance then
            EXRTrialBalByPeriod.SetFilter(PostingDate, '..%1', PeriodEndDate)
        else
            EXRTrialBalByPeriod.SetRange(PostingDate, PeriodStartDate, PeriodEndDate);
        if GLAccount.GetFilter("Business Unit Filter") <> '' then
            EXRTrialBalByPeriod.SetFilter(BusinessUnitCode, GLAccount.GetFilter("Business Unit Filter"));
        if GLAccount.GetFilter("VAT Reporting Date Filter") <> '' then
            if IsBalance then
                SetVATReportingDateUpperLimitFilter(EXRTrialBalByPeriod, GLAccount)
            else
                EXRTrialBalByPeriod.SetFilter(VATReportingDate, GLAccount.GetFilter("VAT Reporting Date Filter"));
        if GLAccount.GetFilter("Dimension Set ID Filter") <> '' then
            EXRTrialBalByPeriod.SetFilter(DimensionSetID, GLAccount.GetFilter("Dimension Set ID Filter"));
        EXRTrialBalByPeriod.Open();
        while EXRTrialBalByPeriod.Read() do begin
            Dimension1Code := EXRTrialBalByPeriod.DimensionValue1Code;
            Dimension2Code := EXRTrialBalByPeriod.DimensionValue2Code;
            IsKnownDimension1Code := Dimension1CodeLookup.ContainsKey(Dimension1Code);
            IsKnownDimension2Code := Dimension2CodeLookup.ContainsKey(Dimension2Code);

            // A blank dimension code in the dataset means "not filtered on that dimension", so every entry
            // contributes to the account total and to the lines of each global dimension value it carries.
            AddToPeriodTotals(TempPeriodTotals, '', '', IsBalance, EXRTrialBalByPeriod.Amount, EXRTrialBalByPeriod.DebitAmount, EXRTrialBalByPeriod.CreditAmount);
            if IsKnownDimension1Code then
                AddToPeriodTotals(TempPeriodTotals, Dimension1Code, '', IsBalance, EXRTrialBalByPeriod.Amount, EXRTrialBalByPeriod.DebitAmount, EXRTrialBalByPeriod.CreditAmount);
            if IsKnownDimension1Code and IsKnownDimension2Code then
                AddToPeriodTotals(TempPeriodTotals, Dimension1Code, Dimension2Code, IsBalance, EXRTrialBalByPeriod.Amount, EXRTrialBalByPeriod.DebitAmount, EXRTrialBalByPeriod.CreditAmount);
            if IsKnownDimension2Code then
                AddToPeriodTotals(TempPeriodTotals, '', Dimension2Code, IsBalance, EXRTrialBalByPeriod.Amount, EXRTrialBalByPeriod.DebitAmount, EXRTrialBalByPeriod.CreditAmount);
        end;
        EXRTrialBalByPeriod.Close();
    end;

    local procedure SetVATReportingDateUpperLimitFilter(var EXRTrialBalByPeriod: Query "EXR Trial Bal by Period"; var GLAccount: Record "G/L Account")
    var
        VATReportingDateFilter: Text;
        UpperLimit: Date;
    begin
        // "Balance at Date" applies only the upper limit of the VAT Reporting Date Filter.
        VATReportingDateFilter := GLAccount.GetFilter("VAT Reporting Date Filter");
        if not TryGetVATReportingDateUpperLimit(GLAccount, UpperLimit) then begin
            // GetRangeMax fails for filters that are not a single range, so such filters are applied as entered.
            EXRTrialBalByPeriod.SetFilter(VATReportingDate, VATReportingDateFilter);
            exit;
        end;
        if UpperLimit <> 0D then
            EXRTrialBalByPeriod.SetFilter(VATReportingDate, '..%1', UpperLimit)
        else
            // An open-ended range has no upper limit.
            if not VATReportingDateFilter.EndsWith('..') then
                EXRTrialBalByPeriod.SetFilter(VATReportingDate, VATReportingDateFilter);
    end;

    [TryFunction]
    local procedure TryGetVATReportingDateUpperLimit(var GLAccount: Record "G/L Account"; var UpperLimit: Date)
    begin
        UpperLimit := GLAccount.GetRangeMax("VAT Reporting Date Filter");
    end;

    local procedure AddToPeriodTotals(var TempPeriodTotals: Record "EXR Trial Balance Buffer" temporary; Dimension1Code: Code[20]; Dimension2Code: Code[20]; IsBalance: Boolean; Amount: Decimal; DebitAmount: Decimal; CreditAmount: Decimal)
    begin
        if not TempPeriodTotals.Get('', Dimension1Code, Dimension2Code, '', 0D) then begin
            TempPeriodTotals.Init();
            TempPeriodTotals."Dimension 1 Code" := Dimension1Code;
            TempPeriodTotals."Dimension 2 Code" := Dimension2Code;
            TempPeriodTotals.Insert();
        end;
        if IsBalance then begin
            TempPeriodTotals.Balance += Amount;
            TempPeriodTotals."Balance (Debit)" += DebitAmount;
            TempPeriodTotals."Balance (Credit)" += CreditAmount;
        end else begin
            TempPeriodTotals."Net Change" += Amount;
            TempPeriodTotals."Net Change (Debit)" += DebitAmount;
            TempPeriodTotals."Net Change (Credit)" += CreditAmount;
        end;
        TempPeriodTotals.Modify();
    end;

    local procedure InsertPeriodTotalsIntoDataset(GLAccountNo: Code[20]; PeriodStartDate: Date; PeriodEndDate: Date; var TempPeriodTotals: Record "EXR Trial Balance Buffer" temporary)
    var
        Dimension1Code: Code[20];
        Dimension2Code: Code[20];
    begin
        if HideLinesWithZeroValues then begin
            // Combinations without entries are all zero, so only the accumulated ones can produce lines.
            if TempPeriodTotals.FindSet() then
                repeat
                    InsertDatasetLine(GLAccountNo, PeriodStartDate, PeriodEndDate, TempPeriodTotals."Dimension 1 Code", TempPeriodTotals."Dimension 2 Code", TempPeriodTotals);
                until TempPeriodTotals.Next() = 0;
            exit;
        end;

        InsertDatasetLineForCombination(GLAccountNo, PeriodStartDate, PeriodEndDate, '', '', TempPeriodTotals);
        foreach Dimension1Code in Dimension1Codes do begin
            InsertDatasetLineForCombination(GLAccountNo, PeriodStartDate, PeriodEndDate, Dimension1Code, '', TempPeriodTotals);
            foreach Dimension2Code in Dimension2Codes do
                InsertDatasetLineForCombination(GLAccountNo, PeriodStartDate, PeriodEndDate, Dimension1Code, Dimension2Code, TempPeriodTotals);
        end;
        foreach Dimension2Code in Dimension2Codes do
            InsertDatasetLineForCombination(GLAccountNo, PeriodStartDate, PeriodEndDate, '', Dimension2Code, TempPeriodTotals);
    end;

    local procedure InsertDatasetLineForCombination(GLAccountNo: Code[20]; PeriodStartDate: Date; PeriodEndDate: Date; Dimension1Code: Code[20]; Dimension2Code: Code[20]; var TempPeriodTotals: Record "EXR Trial Balance Buffer" temporary)
    begin
        if not TempPeriodTotals.Get('', Dimension1Code, Dimension2Code, '', 0D) then
            TempPeriodTotals.Init();
        InsertDatasetLine(GLAccountNo, PeriodStartDate, PeriodEndDate, Dimension1Code, Dimension2Code, TempPeriodTotals);
    end;

    local procedure InsertDatasetLine(GLAccountNo: Code[20]; PeriodStartDate: Date; PeriodEndDate: Date; Dimension1Code: Code[20]; Dimension2Code: Code[20]; var TempPeriodTotals: Record "EXR Trial Balance Buffer" temporary)
    begin
        Clear(EXRTrialBalanceBuffer);
        EXRTrialBalanceBuffer."G/L Account No." := GLAccountNo;
        EXRTrialBalanceBuffer."Period Start" := PeriodStartDate;
        EXRTrialBalanceBuffer."Period End" := PeriodEndDate;
        EXRTrialBalanceBuffer."Dimension 1 Code" := Dimension1Code;
        EXRTrialBalanceBuffer."Dimension 2 Code" := Dimension2Code;
        EXRTrialBalanceBuffer."Net Change" := TempPeriodTotals."Net Change";
        EXRTrialBalanceBuffer."Net Change (Debit)" := TempPeriodTotals."Net Change (Debit)";
        EXRTrialBalanceBuffer."Net Change (Credit)" := TempPeriodTotals."Net Change (Credit)";
        EXRTrialBalanceBuffer.Balance := TempPeriodTotals.Balance;
        EXRTrialBalanceBuffer."Balance (Debit)" := TempPeriodTotals."Balance (Debit)";
        EXRTrialBalanceBuffer."Balance (Credit)" := TempPeriodTotals."Balance (Credit)";
        EXRTrialBalanceBuffer.CheckAllZero();
        if not HideLinesWithZeroValues or not EXRTrialBalanceBuffer."All Zero" then
            EXRTrialBalanceBuffer.Insert(true);
    end;
}
