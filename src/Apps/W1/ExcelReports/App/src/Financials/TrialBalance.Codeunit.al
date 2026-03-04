// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.Finance.ExcelReports;

#if not CLEAN27
using Microsoft.Finance.Consolidation;
#endif
using Microsoft.Finance.Dimension;
using Microsoft.Finance.GeneralLedger.Account;
using Microsoft.Finance.GeneralLedger.Ledger;
#if not CLEAN27
using System.Environment.Configuration;
#endif

codeunit 4410 "Trial Balance"
{
    var
        GlobalBreakdownByBusinessUnit: Boolean;
        GlobalIncludeBudgetData: Boolean;
        BlankLbl: Label '(BLANK)';

    internal procedure ConfigureTrialBalance(BreakdownByBusinessUnit: Boolean; IncludeBudgetData: Boolean)
    begin
        GlobalBreakdownByBusinessUnit := BreakdownByBusinessUnit;
        GlobalIncludeBudgetData := IncludeBudgetData;
    end;

    internal procedure InsertTrialBalanceReportData(var GLAccount: Record "G/L Account"; var Dimension1Values: Record "Dimension Value" temporary; var Dimension2Values: Record "Dimension Value" temporary; var TrialBalanceData: Record "EXR Trial Balance Buffer")
    begin
        Session.LogMessage('0000PYA', 'Started collecting trial balance data', Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::All, 'Category', 'Excel Reports');
        InsertTBReportData(GLAccount, Dimension1Values, Dimension2Values, TrialBalanceData);
        Session.LogMessage('0000PYD', 'Finished collecting trial balance data', Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::All, 'Category', 'Excel Reports');
    end;

    local procedure InsertTBReportData(var GLAccount: Record "G/L Account"; var Dimension1Values: Record "Dimension Value" temporary; var Dimension2Values: Record "Dimension Value" temporary; var TrialBalanceData: Record "EXR Trial Balance Buffer")
    begin
        if GLAccount.IsEmpty() then
            exit;
#if not CLEAN27
        if IsPerformantTrialBalanceFeatureActive() then
            InsertTrialBalanceReportDataFromQueries(GLAccount, Dimension1Values, Dimension2Values, TrialBalanceData)
        else
            InsertTrialBalanceReportDataLooping(GLAccount, Dimension1Values, Dimension2Values, TrialBalanceData);
#else
        InsertTrialBalanceReportDataFromQueries(GLAccount, Dimension1Values, Dimension2Values, TrialBalanceData);
#endif
    end;

#if not CLEAN27
    local procedure IsPerformantTrialBalanceFeatureActive() Active: Boolean
    var
        FeatureManagementFacade: Codeunit "Feature Management Facade";
    begin
#pragma warning disable AL0432
        OnIsPerformantTrialBalanceFeatureActive(Active);
#pragma warning restore AL0432
        if Active then
            exit(Active);
        exit(FeatureManagementFacade.IsEnabled('EXRPerformantTrialBalance'));
    end;
#endif

    #region Looping approach - to be removed
#if not CLEAN27
    local procedure InsertTrialBalanceReportDataLooping(var GLAccount: Record "G/L Account"; var Dimension1Values: Record "Dimension Value" temporary; var Dimension2Values: Record "Dimension Value" temporary; var TrialBalanceData: Record "EXR Trial Balance Buffer")
    var
        DimensionValue: Record "Dimension Value";
        BusinessUnitFilters, Dimension1Filters, Dimension2Filters : List of [Code[20]];
    begin
        DimensionValue.SetRange("Global Dimension No.", 1);
        InsertDimensionFiltersFromDimensionValues(DimensionValue, Dimension1Filters);
        DimensionValue.SetRange("Global Dimension No.", 2);
        InsertDimensionFiltersFromDimensionValues(DimensionValue, Dimension2Filters);
        if GlobalBreakdownByBusinessUnit then
            InsertBusinessUnitFilters(BusinessUnitFilters);

        Clear(TrialBalanceData);
        TrialBalanceData.DeleteAll();
        repeat
            InsertBreakdownForGLAccount(GLAccount, Dimension1Filters, Dimension2Filters, BusinessUnitFilters, TrialBalanceData, Dimension1Values, Dimension2Values);
        until GLAccount.Next() = 0;
    end;

    local procedure InsertBusinessUnitFilters(var BusinessUnitFilters: List of [Code[20]])
    var
        BusinessUnit: Record "Business Unit";
    begin
        BusinessUnitFilters.Add('');
        if not BusinessUnit.FindSet() then
            exit;
        repeat
            BusinessUnitFilters.Add(BusinessUnit.Code);
        until BusinessUnit.Next() = 0;
    end;

    local procedure InsertDimensionFiltersFromDimensionValues(var DimensionValue: Record "Dimension Value"; var DimensionFilters: List of [Code[20]])
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
#pragma warning disable AL0432
        OnBeforeInsertDimensionFiltersFromDimensionValues(DimensionValue, DimensionFilters, IsHandled);
#pragma warning restore AL0432
        if IsHandled then
            exit;
        DimensionFilters.Add('');
        if not DimensionValue.FindSet() then
            exit;
        repeat
            DimensionFilters.Add(DimensionValue.Code);
        until DimensionValue.Next() = 0;
    end;

    local procedure InsertBreakdownForGLAccount(var GLAccount: Record "G/L Account"; Dimension1Filters: List of [Code[20]]; Dimension2Filters: List of [Code[20]]; BusinessUnitCodeFilters: List of [Code[20]]; var TrialBalanceData: Record "EXR Trial Balance Buffer"; var Dimension1Values: Record "Dimension Value" temporary; var Dimension2Values: Record "Dimension Value" temporary)
    var
        i, j, k : Integer;
    begin
        for i := 1 to Dimension1Filters.Count do
            for j := 1 to Dimension2Filters.Count do
                if GlobalBreakdownByBusinessUnit then
                    for k := 1 to BusinessUnitCodeFilters.Count do
                        InsertGLAccountTotalsForFilters(Dimension1Filters.Get(i), Dimension2Filters.Get(j), BusinessUnitCodeFilters.Get(k), GLAccount, TrialBalanceData, Dimension1Values, Dimension2Values)
                else
                    InsertGLAccountTotalsForFilters(Dimension1Filters.Get(i), Dimension2Filters.Get(j), GLAccount, TrialBalanceData, Dimension1Values, Dimension2Values)
    end;

    local procedure InsertGLAccountTotalsForFilters(Dimension1ValueCode: Code[20]; Dimension2ValueCode: Code[20]; var GLAccount: Record "G/L Account"; var TrialBalanceData: Record "EXR Trial Balance Buffer"; var Dimension1Values: Record "Dimension Value" temporary; var Dimension2Values: Record "Dimension Value" temporary)
    begin
        InsertGLAccountTotalsForFilters(Dimension1ValueCode, Dimension2ValueCode, '', GLAccount, TrialBalanceData, Dimension1Values, Dimension2Values);
    end;

    local procedure InsertGLAccountTotalsForFilters(Dimension1ValueCode: Code[20]; Dimension2ValueCode: Code[20]; BusinessUnitCode: Code[20]; var GLAccount: Record "G/L Account"; var TrialBalanceData: Record "EXR Trial Balance Buffer"; var Dimension1Values: Record "Dimension Value" temporary; var Dimension2Values: Record "Dimension Value" temporary)
    var
        LocalGlAccount: Record "G/L Account";
    begin
        LocalGlAccount.Copy(GLAccount);
        LocalGLAccount.SetFilter("Global Dimension 1 Filter", '= ''%1''', Dimension1ValueCode);
        LocalGLAccount.SetFilter("Global Dimension 2 Filter", '= ''%1''', Dimension2ValueCode);
        if GlobalBreakdownByBusinessUnit then
            LocalGLAccount.SetFilter("Business Unit Filter", '= %1', BusinessUnitCode);
        InsertTrialBalanceDataForGLAccountWithFilters(LocalGlAccount, Dimension1ValueCode, Dimension2ValueCode, BusinessUnitCode, TrialBalanceData, Dimension1Values, Dimension2Values);
    end;

    local procedure InsertTrialBalanceDataForGLAccountWithFilters(var GLAccount: Record "G/L Account"; Dimension1ValueCode: Code[20]; Dimension2ValueCode: Code[20]; BusinessUnitCode: Code[20]; var TrialBalanceData: Record "EXR Trial Balance Buffer"; var Dimension1Values: Record "Dimension Value" temporary; var Dimension2Values: Record "Dimension Value" temporary)
    var
        GLAccount2: Record "G/L Account";
        GLEntry: Record "G/L Entry";
    begin
        Clear(TrialBalanceData);
        if GLAccount.GetFilter("Date Filter") <> '' then begin
            GLEntry.SetFilter("Posting Date", GLAccount.GetFilter("Date Filter"));
            if GLEntry.FindFirst() then begin
                GLAccount2.Copy(GLAccount);
                GLAccount2.SetFilter("Date Filter", '..%1', GLEntry."Posting Date" - 1);
                GLAccount2.CalcFields("Balance at Date", "Add.-Currency Balance at Date");
                TrialBalanceData.Validate("Starting Balance", GLAccount2."Balance at Date");
                TrialBalanceData.Validate("Starting Balance (ACY)", GLAccount2."Add.-Currency Balance at Date");
            end;
        end;
        GlAccount.CalcFields("Net Change", "Balance at Date", "Additional-Currency Net Change", "Add.-Currency Balance at Date", "Budgeted Amount", "Budget at Date");
        TrialBalanceData."G/L Account No." := GlAccount."No.";
        TrialBalanceData."Dimension 1 Code" := Dimension1ValueCode;
        TrialBalanceData."Dimension 2 Code" := Dimension2ValueCode;
        TrialBalanceData."Business Unit Code" := BusinessUnitCode;
        TrialBalanceData.Validate("Net Change", GLAccount."Net Change");
        TrialBalanceData.Validate(Balance, GLAccount."Balance at Date");
        TrialBalanceData.Validate("Net Change (ACY)", GLAccount."Additional-Currency Net Change");
        TrialBalanceData.Validate("Balance (ACY)", GLAccount."Add.-Currency Balance at Date");
        TrialBalanceData.Validate("Budget (Net)", GLAccount."Budgeted Amount");
        TrialBalanceData.Validate("Budget (Bal. at Date)", GLAccount."Budget at Date");
        TrialBalanceData.CalculateBudgetComparisons();
        TrialBalanceData.CheckAllZero();
        if not TrialBalanceData."All Zero" then begin
            TrialBalanceData.Insert(true);
            InsertUsedDimensionValue(1, TrialBalanceData."Dimension 1 Code", Dimension1Values);
            InsertUsedDimensionValue(2, TrialBalanceData."Dimension 2 Code", Dimension2Values);
        end;
    end;
#endif
    #endregion
    #region Query-based approach
    local procedure InsertTrialBalanceReportDataFromQueries(var GLAccount: Record "G/L Account"; var Dimension1Values: Record "Dimension Value" temporary; var Dimension2Values: Record "Dimension Value" temporary; var TrialBalanceData: Record "EXR Trial Balance Buffer")
    var
        LocalGLAccount: Record "G/L Account";
        AccountNoFilter: Text;
        StartDate, EndDate : Date;
    begin
        Session.LogMessage('0000PYC', 'Running query-based trial balance', Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::All, 'Category', 'Excel Reports');
        TrialBalanceData.DeleteAll();
        // We get the dates of the first and last entries for the date filter in G/L Account,
        // the trial balance returns starting balance, net change, and ending balance with regard to such dates
        GetRangeDatesForGLAccountFilter(GLAccount.GetFilter("Date Filter"), StartDate, EndDate);
        AccountNoFilter := GLAccount.GetFilter("No.");

        if GlobalBreakdownByBusinessUnit then
            InsertTrialBalanceFromBUQuery(Dimension1Values, Dimension2Values, TrialBalanceData, StartDate, EndDate, AccountNoFilter)
        else
            InsertTrialBalanceFromQuery(Dimension1Values, Dimension2Values, TrialBalanceData, StartDate, EndDate, AccountNoFilter);

        if GlobalIncludeBudgetData then
            InsertBudgetDataFromQuery(GLAccount, TrialBalanceData, StartDate, EndDate);

        // The query will just return entries for the "Posting" G/L Accounts and nothing for the Total/End-Total accounts,
        // to address that, we calculate the sums from the contents that we now have in the temporary TrialBalanceData table
        LocalGLAccount.SetFilter("Account Type", '%1|%2', "G/L Account Type"::"End-Total", "G/L Account Type"::Total);
        if AccountNoFilter <> '' then
            LocalGLAccount.SetFilter("No.", AccountNoFilter);
        if LocalGLAccount.FindSet() then
            repeat
                if LocalGLAccount.Totaling <> '' then
                    InsertTotalAccountsFromBuffer(LocalGLAccount, TrialBalanceData);
            until LocalGLAccount.Next() = 0;
    end;

    local procedure InsertTrialBalanceFromQuery(var Dimension1Values: Record "Dimension Value" temporary; var Dimension2Values: Record "Dimension Value" temporary; var TrialBalanceData: Record "EXR Trial Balance Buffer"; StartDate: Date; EndDate: Date; AccountNoFilter: Text)
    var
        EXRTrialBalanceQuery: Query "EXR Trial Balance";
    begin
        // We first get the balances at the ending date
        if AccountNoFilter <> '' then
            EXRTrialBalanceQuery.SetFilter(EXRTrialBalanceQuery.AccountNo, AccountNoFilter);
        EXRTrialBalanceQuery.SetFilter(EXRTrialBalanceQuery.PostingDate, '..%1', EndDate);
        EXRTrialBalanceQuery.Open();
        while EXRTrialBalanceQuery.Read() do begin
            TrialBalanceData."G/L Account No." := EXRTrialBalanceQuery.AccountNumber;
            TrialBalanceData."Dimension 1 Code" := EXRTrialBalanceQuery.DimensionValue1Code;
            TrialBalanceData."Dimension 2 Code" := EXRTrialBalanceQuery.DimensionValue2Code;
            // The balances at the ending date are filled in from the values returned in this query
            TrialBalanceData.Validate(Balance, EXRTrialBalanceQuery.Amount);
            TrialBalanceData.Validate("Balance (ACY)", EXRTrialBalanceQuery.ACYAmount);
            // And also in Net Change (which will have later the value at the starting date subtracted)
            TrialBalanceData.Validate("Net Change", EXRTrialBalanceQuery.Amount);
            TrialBalanceData.Validate("Net Change (ACY)", EXRTrialBalanceQuery.ACYAmount);
            TrialBalanceData.CheckAllZero();
            if not TrialBalanceData."All Zero" then begin
                TrialBalanceData.Insert(true);
                InsertUsedDimensionValue(1, TrialBalanceData."Dimension 1 Code", Dimension1Values);
                InsertUsedDimensionValue(2, TrialBalanceData."Dimension 2 Code", Dimension2Values);
            end;
        end;
        EXRTrialBalanceQuery.Close();

        // And now we get the balances at the starting date and modify the ones we have already inserted
        EXRTrialBalanceQuery.SetFilter(EXRTrialBalanceQuery.PostingDate, '..%1', StartDate - 1);
        EXRTrialBalanceQuery.Open();
        while EXRTrialBalanceQuery.Read() do begin
            TrialBalanceData.SetRange("G/L Account No.", EXRTrialBalanceQuery.AccountNumber);
            TrialBalanceData.SetRange("Dimension 1 Code", EXRTrialBalanceQuery.DimensionValue1Code);
            TrialBalanceData.SetRange("Dimension 2 Code", EXRTrialBalanceQuery.DimensionValue2Code);
            if not TrialBalanceData.FindFirst() then begin // This shouldn't happen, but we consider it regardless
                TrialBalanceData."G/L Account No." := EXRTrialBalanceQuery.AccountNumber;
                TrialBalanceData."Dimension 1 Code" := EXRTrialBalanceQuery.DimensionValue1Code;
                TrialBalanceData."Dimension 2 Code" := EXRTrialBalanceQuery.DimensionValue2Code;
                TrialBalanceData.Insert(true);
            end;
            // The balances at starting date are filled in from the values returned in this query
            TrialBalanceData.Validate("Starting Balance", EXRTrialBalanceQuery.Amount);
            TrialBalanceData.Validate("Starting Balance (ACY)", EXRTrialBalanceQuery.ACYAmount);
            // The "Net Change" will be modified from what it had (balance at ending date) to the subtraction with the starting balance
            TrialBalanceData.Validate("Net Change", TrialBalanceData."Net Change" - EXRTrialBalanceQuery.Amount);
            TrialBalanceData.Validate("Net Change (ACY)", TrialBalanceData."Net Change (ACY)" - EXRTrialBalanceQuery.ACYAmount);
            TrialBalanceData.Modify();
            InsertUsedDimensionValue(1, TrialBalanceData."Dimension 1 Code", Dimension1Values);
            InsertUsedDimensionValue(2, TrialBalanceData."Dimension 2 Code", Dimension2Values);
        end;
    end;

    local procedure InsertTrialBalanceFromBUQuery(var Dimension1Values: Record "Dimension Value" temporary; var Dimension2Values: Record "Dimension Value" temporary; var TrialBalanceData: Record "EXR Trial Balance Buffer"; StartDate: Date; EndDate: Date; AccountNoFilter: Text)
    var
        EXRTrialBalanceBUQuery: Query "EXR Trial Balance BU";
    begin
        // We first get the balances at the ending date
        if AccountNoFilter <> '' then
            EXRTrialBalanceBUQuery.SetFilter(EXRTrialBalanceBUQuery.AccountNo, AccountNoFilter);
        EXRTrialBalanceBUQuery.SetFilter(EXRTrialBalanceBUQuery.PostingDate, '..%1', EndDate);
        EXRTrialBalanceBUQuery.Open();
        while EXRTrialBalanceBUQuery.Read() do begin
            TrialBalanceData."G/L Account No." := EXRTrialBalanceBUQuery.AccountNumber;
            TrialBalanceData."Dimension 1 Code" := EXRTrialBalanceBUQuery.DimensionValue1Code;
            TrialBalanceData."Dimension 2 Code" := EXRTrialBalanceBUQuery.DimensionValue2Code;
            TrialBalanceData."Business Unit Code" := EXRTrialBalanceBUQuery.BusinessUnitCode;
            TrialBalanceData.Validate(Balance, EXRTrialBalanceBUQuery.Amount);
            TrialBalanceData.Validate("Balance (ACY)", EXRTrialBalanceBUQuery.ACYAmount);
            TrialBalanceData.Validate("Net Change", EXRTrialBalanceBUQuery.Amount);
            TrialBalanceData.Validate("Net Change (ACY)", EXRTrialBalanceBUQuery.ACYAmount);
            TrialBalanceData.CheckAllZero();
            if not TrialBalanceData."All Zero" then begin
                TrialBalanceData.Insert(true);
                InsertUsedDimensionValue(1, TrialBalanceData."Dimension 1 Code", Dimension1Values);
                InsertUsedDimensionValue(2, TrialBalanceData."Dimension 2 Code", Dimension2Values);
            end;
        end;
        EXRTrialBalanceBUQuery.Close();

        // And now we get the balances at the starting date and modify the ones we have already inserted
        EXRTrialBalanceBUQuery.SetFilter(EXRTrialBalanceBUQuery.PostingDate, '..%1', StartDate - 1);
        EXRTrialBalanceBUQuery.Open();
        while EXRTrialBalanceBUQuery.Read() do begin
            TrialBalanceData.SetRange("G/L Account No.", EXRTrialBalanceBUQuery.AccountNumber);
            TrialBalanceData.SetRange("Dimension 1 Code", EXRTrialBalanceBUQuery.DimensionValue1Code);
            TrialBalanceData.SetRange("Dimension 2 Code", EXRTrialBalanceBUQuery.DimensionValue2Code);
            TrialBalanceData.SetRange("Business Unit Code", EXRTrialBalanceBUQuery.BusinessUnitCode);
            if not TrialBalanceData.FindFirst() then begin
                TrialBalanceData."G/L Account No." := EXRTrialBalanceBUQuery.AccountNumber;
                TrialBalanceData."Dimension 1 Code" := EXRTrialBalanceBUQuery.DimensionValue1Code;
                TrialBalanceData."Dimension 2 Code" := EXRTrialBalanceBUQuery.DimensionValue2Code;
                TrialBalanceData."Business Unit Code" := EXRTrialBalanceBUQuery.BusinessUnitCode;
                TrialBalanceData.Insert(true);
            end;
            TrialBalanceData.Validate("Starting Balance", EXRTrialBalanceBUQuery.Amount);
            TrialBalanceData.Validate("Starting Balance (ACY)", EXRTrialBalanceBUQuery.ACYAmount);
            TrialBalanceData.Validate("Net Change", TrialBalanceData."Net Change" - EXRTrialBalanceBUQuery.Amount);
            TrialBalanceData.Validate("Net Change (ACY)", TrialBalanceData."Net Change (ACY)" - EXRTrialBalanceBUQuery.ACYAmount);
            TrialBalanceData.Modify();
            InsertUsedDimensionValue(1, TrialBalanceData."Dimension 1 Code", Dimension1Values);
            InsertUsedDimensionValue(2, TrialBalanceData."Dimension 2 Code", Dimension2Values);
        end;
    end;

    local procedure InsertTotalAccountsFromBuffer(var TotalAccount: Record "G/L Account"; var TrialBalanceData: Record "EXR Trial Balance Buffer")
    var
        TempDimCombinations: Record "EXR Trial Balance Buffer" temporary;
    begin
        Clear(TrialBalanceData);
        TrialBalanceData.SetFilter("G/L Account No.", TotalAccount.Totaling);
        if not TrialBalanceData.FindSet() then begin
            Clear(TrialBalanceData);
            exit;
        end;

        // Collect distinct (Dimension 1, Dimension 2, Business Unit Code) combinations from the loaded records in the totaling range
        repeat
            TempDimCombinations."G/L Account No." := TotalAccount."No.";
            TempDimCombinations."Dimension 1 Code" := TrialBalanceData."Dimension 1 Code";
            TempDimCombinations."Dimension 2 Code" := TrialBalanceData."Dimension 2 Code";
            TempDimCombinations."Business Unit Code" := TrialBalanceData."Business Unit Code";
            if not TempDimCombinations.Insert() then;
        until TrialBalanceData.Next() = 0;

        // For each combination, compute the sums (in memory) and insert an total record
        if TempDimCombinations.FindSet() then
            repeat
                Clear(TrialBalanceData);
                TrialBalanceData.SetFilter("G/L Account No.", TotalAccount.Totaling);
                TrialBalanceData.SetRange("Dimension 1 Code", TempDimCombinations."Dimension 1 Code");
                TrialBalanceData.SetRange("Dimension 2 Code", TempDimCombinations."Dimension 2 Code");
                TrialBalanceData.SetRange("Business Unit Code", TempDimCombinations."Business Unit Code");
                TrialBalanceData.CalcSums(
                    // LCY
                    "Net Change", "Net Change (Debit)", "Net Change (Credit)",
                    Balance, "Balance (Debit)", "Balance (Credit)",
                    "Starting Balance", "Starting Balance (Debit)", "Starting Balance (Credit)",
                    // ACY
                    "Net Change (ACY)", "Net Change (Debit) (ACY)", "Net Change (Credit) (ACY)",
                    "Balance (ACY)", "Balance (Debit) (ACY)", "Balance (Credit) (ACY)",
                    "Starting Balance (ACY)", "Starting Balance (Debit) (ACY)", "Starting Balance (Credit)(ACY)",
                    // Budget
                    "Budget (Net)", "Budget (Bal. at Date)"
                );
                TrialBalanceData."G/L Account No." := TotalAccount."No.";
                TrialBalanceData."Dimension 1 Code" := TempDimCombinations."Dimension 1 Code";
                TrialBalanceData."Dimension 2 Code" := TempDimCombinations."Dimension 2 Code";
                TrialBalanceData."Business Unit Code" := TempDimCombinations."Business Unit Code";
                TrialBalanceData.CalculateBudgetComparisons();
                TrialBalanceData.CheckAllZero();
                if not TrialBalanceData."All Zero" then
                    TrialBalanceData.Insert(true);
            until TempDimCombinations.Next() = 0;

        Clear(TrialBalanceData);
    end;

    local procedure InsertBudgetDataFromQuery(var GLAccount: Record "G/L Account"; var TrialBalanceData: Record "EXR Trial Balance Buffer"; StartDate: Date; EndDate: Date)
    var
        BudgetFilter: Text;
    begin
        BudgetFilter := GLAccount.GetFilter("Budget Filter");

        ReadBudgetFromQuery(TrialBalanceData, StartDate, EndDate, BudgetFilter, false);
        ReadBudgetFromQuery(TrialBalanceData, StartDate, EndDate, BudgetFilter, true);

        // Calculate budget comparison percentages for all records
        Clear(TrialBalanceData);
        if TrialBalanceData.FindSet() then
            repeat
                TrialBalanceData.CalculateBudgetComparisons();
                TrialBalanceData.Modify();
            until TrialBalanceData.Next() = 0;
    end;

    local procedure ReadBudgetFromQuery(var TrialBalanceData: Record "EXR Trial Balance Buffer"; StartDate: Date; EndDate: Date; BudgetFilter: Text; UpdateBalAtDate: Boolean)
    var
        EXRTrialBalanceBudget: Query "EXR Trial Balance Budget";
    begin
        if UpdateBalAtDate then
            EXRTrialBalanceBudget.SetFilter(EXRTrialBalanceBudget.BudgetDate, '..%1', EndDate)
        else
            EXRTrialBalanceBudget.SetFilter(EXRTrialBalanceBudget.BudgetDate, '%1..%2', StartDate, EndDate);
        if BudgetFilter <> '' then
            EXRTrialBalanceBudget.SetFilter(EXRTrialBalanceBudget.BudgetName, BudgetFilter);
        EXRTrialBalanceBudget.Open();
        while EXRTrialBalanceBudget.Read() do begin
            TrialBalanceData.SetRange("G/L Account No.", EXRTrialBalanceBudget.AccountNumber);
            TrialBalanceData.SetRange("Dimension 1 Code", EXRTrialBalanceBudget.DimensionValue1Code);
            TrialBalanceData.SetRange("Dimension 2 Code", EXRTrialBalanceBudget.DimensionValue2Code);
            if TrialBalanceData.FindFirst() then begin
                if UpdateBalAtDate then
                    TrialBalanceData."Budget (Bal. at Date)" := EXRTrialBalanceBudget.Amount
                else
                    TrialBalanceData."Budget (Net)" := EXRTrialBalanceBudget.Amount;
                TrialBalanceData.Modify();
            end;
        end;
        EXRTrialBalanceBudget.Close();
    end;

    local procedure InsertUsedDimensionValue(GlobalDimensionNo: Integer; DimensionCode: Code[20]; var InsertedDimensionValues: Record "Dimension Value" temporary)
    var
        DimensionValue: Record "Dimension Value";
    begin
        Clear(InsertedDimensionValues);
        if DimensionCode <> '' then
            InsertedDimensionValues.SetRange("Global Dimension No.", GlobalDimensionNo);
        InsertedDimensionValues.SetRange(Code, DimensionCode);
        if not InsertedDimensionValues.IsEmpty() then
            exit;
        if DimensionCode = '' then begin
            InsertedDimensionValues."Dimension Code" := DimensionCode;
            InsertedDimensionValues.Name := BlankLbl;
            InsertedDimensionValues.Insert();
            exit;
        end;
        DimensionValue.CopyFilters(InsertedDimensionValues);
        DimensionValue.FindFirst();
        InsertedDimensionValues.Copy(DimensionValue);
        InsertedDimensionValues.Insert();
    end;

    local procedure GetRangeDatesForGLAccountFilter(GLAccountDateFilter: Text; var StartDate: Date; var EndDate: Date)
    var
        GLEntry: Record "G/L Entry";
    begin
        GLEntry.SetFilter("Posting Date", GLAccountDateFilter);
        GLEntry.SetLoadFields("Posting Date");
        GLEntry.SetCurrentKey("Posting Date");
        GLEntry.SetAscending("Posting Date", true);
        if GLEntry.FindFirst() then
            StartDate := GLEntry."Posting Date";
        if GLEntry.FindLast() then
            EndDate := GLEntry."Posting Date";
        if StartDate = 0D then
            StartDate := WorkDate();
        if EndDate = 0D then
            EndDate := StartDate;
    end;
    #endregion

#if not CLEAN27
    [IntegrationEvent(true, false)]
    [Obsolete('This event is no longer called in the query based retrieval of the trial balance. ', '28.0')]
    local procedure OnBeforeInsertDimensionFiltersFromDimensionValues(var DimensionValue: Record "Dimension Value"; var DimensionFilters: List of [Code[20]]; var IsHandled: Boolean)
    begin
    end;

    [Obsolete('This event is temporary to try the functionality before it''s officially released as a feature in feature management.', '27.0')]
    [IntegrationEvent(true, false)]
    local procedure OnIsPerformantTrialBalanceFeatureActive(var Active: Boolean)
    begin
    end;
#endif
}
