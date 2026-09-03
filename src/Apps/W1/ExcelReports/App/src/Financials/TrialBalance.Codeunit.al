// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.Finance.ExcelReports;

using Microsoft.Finance.Dimension;
using Microsoft.Finance.GeneralLedger.Account;

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
        InsertTrialBalanceReportDataFromQueries(GLAccount, Dimension1Values, Dimension2Values, TrialBalanceData);
    end;


    #region Looping approach - to be removed
    #endregion
    #region Query-based approach
    local procedure InsertTrialBalanceReportDataFromQueries(var GLAccount: Record "G/L Account"; var Dimension1Values: Record "Dimension Value" temporary; var Dimension2Values: Record "Dimension Value" temporary; var TrialBalanceData: Record "EXR Trial Balance Buffer")
    var
        TempTotalsBuffer: Record "EXR Trial Balance Buffer" temporary;
        AccountToTotals: Dictionary of [Code[20], List of [Code[20]]];
        AccountNoFilter, Dimension1Filter, Dimension2Filter : Text;
        StartDate, EndDate : Date;
    begin
        Session.LogMessage('0000PYC', 'Running query-based trial balance', Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::All, 'Category', 'Excel Reports');
        TrialBalanceData.DeleteAll();
        // We get the dates of the first and last entries for the date filter in G/L Account,
        // the trial balance returns starting balance, net change, and ending balance with regard to such dates
        GetRangeDatesForGLAccountFilter(GLAccount.GetFilter("Date Filter"), StartDate, EndDate);
        AccountNoFilter := GLAccount.GetFilter("No.");
        Dimension1Filter := GLAccount.GetFilter("Global Dimension 1 Filter");
        Dimension2Filter := GLAccount.GetFilter("Global Dimension 2 Filter");

        if GlobalBreakdownByBusinessUnit then
            InsertTrialBalanceFromBUQuery(Dimension1Values, Dimension2Values, TrialBalanceData, StartDate, EndDate, AccountNoFilter, Dimension1Filter, Dimension2Filter)
        else
            InsertTrialBalanceFromQuery(Dimension1Values, Dimension2Values, TrialBalanceData, StartDate, EndDate, AccountNoFilter, Dimension1Filter, Dimension2Filter);

        if GlobalIncludeBudgetData then
            InsertBudgetDataFromQuery(GLAccount, TrialBalanceData, StartDate, EndDate);

        // The query only returns rows for the "Posting" G/L Accounts and nothing for the Total/End-Total accounts.
        // We synthesize them in a single pass over the buffer: first map each posting account to the totals whose
        // Totaling range contains it, then sweep the posting rows once, adding each row to every containing total.
        BuildAccountToTotalsMap(AccountNoFilter, AccountToTotals);
        DistributePostingRowsToTotals(TrialBalanceData, AccountToTotals, TempTotalsBuffer);
        MergeTotalsIntoBuffer(TempTotalsBuffer, TrialBalanceData);
    end;

    local procedure InsertTrialBalanceFromQuery(var Dimension1Values: Record "Dimension Value" temporary; var Dimension2Values: Record "Dimension Value" temporary; var TrialBalanceData: Record "EXR Trial Balance Buffer"; StartDate: Date; EndDate: Date; AccountNoFilter: Text; Dimension1Filter: Text; Dimension2Filter: Text)
    var
        EXRTrialBalanceQuery: Query "EXR Trial Balance";
    begin
        // We first get the balances at the ending date
        if AccountNoFilter <> '' then
            EXRTrialBalanceQuery.SetFilter(EXRTrialBalanceQuery.AccountNo, AccountNoFilter);
        if Dimension1Filter <> '' then
            EXRTrialBalanceQuery.SetFilter(EXRTrialBalanceQuery.DimensionValue1Code, Dimension1Filter);
        if Dimension2Filter <> '' then
            EXRTrialBalanceQuery.SetFilter(EXRTrialBalanceQuery.DimensionValue2Code, Dimension2Filter);
        EXRTrialBalanceQuery.SetFilter(EXRTrialBalanceQuery.PostingDate, '..%1', EndDate);
        EXRTrialBalanceQuery.Open();
        while EXRTrialBalanceQuery.Read() do begin
            TrialBalanceData."G/L Account No." := EXRTrialBalanceQuery.AccountNumber;
            TrialBalanceData."Dimension 1 Code" := EXRTrialBalanceQuery.DimensionValue1Code;
            TrialBalanceData."Dimension 2 Code" := EXRTrialBalanceQuery.DimensionValue2Code;
            // The balances at the ending date are filled in from the values returned in this query
            TrialBalanceData.Balance := EXRTrialBalanceQuery.Amount;
            TrialBalanceData."Balance (Debit)" := EXRTrialBalanceQuery.DebitAmount;
            TrialBalanceData."Balance (Credit)" := EXRTrialBalanceQuery.CreditAmount;
            TrialBalanceData."Balance (ACY)" := EXRTrialBalanceQuery.ACYAmount;
            TrialBalanceData."Balance (Debit) (ACY)" := EXRTrialBalanceQuery.ACYDebitAmount;
            TrialBalanceData."Balance (Credit) (ACY)" := EXRTrialBalanceQuery.ACYCreditAmount;
            // Net Change fields temporarily hold cumulative values up to the ending date,
            // the starting date values will be subtracted in the second query
            TrialBalanceData."Net Change" := EXRTrialBalanceQuery.Amount;
            TrialBalanceData."Net Change (Debit)" := EXRTrialBalanceQuery.DebitAmount;
            TrialBalanceData."Net Change (Credit)" := EXRTrialBalanceQuery.CreditAmount;
            TrialBalanceData."Net Change (ACY)" := EXRTrialBalanceQuery.ACYAmount;
            TrialBalanceData."Net Change (Debit) (ACY)" := EXRTrialBalanceQuery.ACYDebitAmount;
            TrialBalanceData."Net Change (Credit) (ACY)" := EXRTrialBalanceQuery.ACYCreditAmount;
            // Every combination the query returns has entries, so it represents real activity and is kept even when it
            // nets to zero. The second pass adjusts any that also have an opening balance.
            TrialBalanceData.Insert(true);
            InsertUsedDimensionValue(1, TrialBalanceData."Dimension 1 Code", Dimension1Values);
            InsertUsedDimensionValue(2, TrialBalanceData."Dimension 2 Code", Dimension2Values);
        end;
        EXRTrialBalanceQuery.Close();

        // And now we get the balances at the starting date and modify the ones we have already inserted
        EXRTrialBalanceQuery.SetFilter(EXRTrialBalanceQuery.PostingDate, '..%1', GetOpeningBalanceCutoff(StartDate));
        EXRTrialBalanceQuery.Open();
        while EXRTrialBalanceQuery.Read() do begin
            TrialBalanceData.SetRange("G/L Account No.", EXRTrialBalanceQuery.AccountNumber);
            TrialBalanceData.SetRange("Dimension 1 Code", EXRTrialBalanceQuery.DimensionValue1Code);
            TrialBalanceData.SetRange("Dimension 2 Code", EXRTrialBalanceQuery.DimensionValue2Code);
            if not TrialBalanceData.FindFirst() then begin
                // This shouldn't happen now that the first pass inserts every combination with entries up to the ending date, but we Init() and consider it regardless.
                TrialBalanceData.Init();
                TrialBalanceData."G/L Account No." := EXRTrialBalanceQuery.AccountNumber;
                TrialBalanceData."Dimension 1 Code" := EXRTrialBalanceQuery.DimensionValue1Code;
                TrialBalanceData."Dimension 2 Code" := EXRTrialBalanceQuery.DimensionValue2Code;
                TrialBalanceData.Insert(true);
            end;
            // The balances at starting date are filled in from the values returned in this query
            TrialBalanceData."Starting Balance" := EXRTrialBalanceQuery.Amount;
            TrialBalanceData."Starting Balance (Debit)" := EXRTrialBalanceQuery.DebitAmount;
            TrialBalanceData."Starting Balance (Credit)" := EXRTrialBalanceQuery.CreditAmount;
            TrialBalanceData."Starting Balance (ACY)" := EXRTrialBalanceQuery.ACYAmount;
            TrialBalanceData."Starting Balance (Debit) (ACY)" := EXRTrialBalanceQuery.ACYDebitAmount;
            TrialBalanceData."Starting Balance (Credit)(ACY)" := EXRTrialBalanceQuery.ACYCreditAmount;
            // Subtract cumulative values at the starting date to get the period net change (gross debit and credit)
            TrialBalanceData."Net Change" := TrialBalanceData."Net Change" - EXRTrialBalanceQuery.Amount;
            TrialBalanceData."Net Change (Debit)" := TrialBalanceData."Net Change (Debit)" - EXRTrialBalanceQuery.DebitAmount;
            TrialBalanceData."Net Change (Credit)" := TrialBalanceData."Net Change (Credit)" - EXRTrialBalanceQuery.CreditAmount;
            TrialBalanceData."Net Change (ACY)" := TrialBalanceData."Net Change (ACY)" - EXRTrialBalanceQuery.ACYAmount;
            TrialBalanceData."Net Change (Debit) (ACY)" := TrialBalanceData."Net Change (Debit) (ACY)" - EXRTrialBalanceQuery.ACYDebitAmount;
            TrialBalanceData."Net Change (Credit) (ACY)" := TrialBalanceData."Net Change (Credit) (ACY)" - EXRTrialBalanceQuery.ACYCreditAmount;
            TrialBalanceData.Modify();
            InsertUsedDimensionValue(1, TrialBalanceData."Dimension 1 Code", Dimension1Values);
            InsertUsedDimensionValue(2, TrialBalanceData."Dimension 2 Code", Dimension2Values);
        end;
    end;

    local procedure InsertTrialBalanceFromBUQuery(var Dimension1Values: Record "Dimension Value" temporary; var Dimension2Values: Record "Dimension Value" temporary; var TrialBalanceData: Record "EXR Trial Balance Buffer"; StartDate: Date; EndDate: Date; AccountNoFilter: Text; Dimension1Filter: Text; Dimension2Filter: Text)
    var
        EXRTrialBalanceBUQuery: Query "EXR Trial Balance BU";
    begin
        // We first get the balances at the ending date
        if AccountNoFilter <> '' then
            EXRTrialBalanceBUQuery.SetFilter(EXRTrialBalanceBUQuery.AccountNo, AccountNoFilter);
        if Dimension1Filter <> '' then
            EXRTrialBalanceBUQuery.SetFilter(EXRTrialBalanceBUQuery.DimensionValue1Code, Dimension1Filter);
        if Dimension2Filter <> '' then
            EXRTrialBalanceBUQuery.SetFilter(EXRTrialBalanceBUQuery.DimensionValue2Code, Dimension2Filter);
        EXRTrialBalanceBUQuery.SetFilter(EXRTrialBalanceBUQuery.PostingDate, '..%1', EndDate);
        EXRTrialBalanceBUQuery.Open();
        while EXRTrialBalanceBUQuery.Read() do begin
            TrialBalanceData."G/L Account No." := EXRTrialBalanceBUQuery.AccountNumber;
            TrialBalanceData."Dimension 1 Code" := EXRTrialBalanceBUQuery.DimensionValue1Code;
            TrialBalanceData."Dimension 2 Code" := EXRTrialBalanceBUQuery.DimensionValue2Code;
            TrialBalanceData."Business Unit Code" := EXRTrialBalanceBUQuery.BusinessUnitCode;
            TrialBalanceData.Balance := EXRTrialBalanceBUQuery.Amount;
            TrialBalanceData."Balance (Debit)" := EXRTrialBalanceBUQuery.DebitAmount;
            TrialBalanceData."Balance (Credit)" := EXRTrialBalanceBUQuery.CreditAmount;
            TrialBalanceData."Balance (ACY)" := EXRTrialBalanceBUQuery.ACYAmount;
            TrialBalanceData."Balance (Debit) (ACY)" := EXRTrialBalanceBUQuery.ACYDebitAmount;
            TrialBalanceData."Balance (Credit) (ACY)" := EXRTrialBalanceBUQuery.ACYCreditAmount;
            TrialBalanceData."Net Change" := EXRTrialBalanceBUQuery.Amount;
            TrialBalanceData."Net Change (Debit)" := EXRTrialBalanceBUQuery.DebitAmount;
            TrialBalanceData."Net Change (Credit)" := EXRTrialBalanceBUQuery.CreditAmount;
            TrialBalanceData."Net Change (ACY)" := EXRTrialBalanceBUQuery.ACYAmount;
            TrialBalanceData."Net Change (Debit) (ACY)" := EXRTrialBalanceBUQuery.ACYDebitAmount;
            TrialBalanceData."Net Change (Credit) (ACY)" := EXRTrialBalanceBUQuery.ACYCreditAmount;
            // Every combination the query returns has entries, so it represents real activity and is kept even when it
            // nets to zero. The second pass adjusts any that also have an opening balance.
            TrialBalanceData.Insert(true);
            InsertUsedDimensionValue(1, TrialBalanceData."Dimension 1 Code", Dimension1Values);
            InsertUsedDimensionValue(2, TrialBalanceData."Dimension 2 Code", Dimension2Values);
        end;
        EXRTrialBalanceBUQuery.Close();

        // And now we get the balances at the starting date and modify the ones we have already inserted
        EXRTrialBalanceBUQuery.SetFilter(EXRTrialBalanceBUQuery.PostingDate, '..%1', GetOpeningBalanceCutoff(StartDate));
        EXRTrialBalanceBUQuery.Open();
        while EXRTrialBalanceBUQuery.Read() do begin
            TrialBalanceData.SetRange("G/L Account No.", EXRTrialBalanceBUQuery.AccountNumber);
            TrialBalanceData.SetRange("Dimension 1 Code", EXRTrialBalanceBUQuery.DimensionValue1Code);
            TrialBalanceData.SetRange("Dimension 2 Code", EXRTrialBalanceBUQuery.DimensionValue2Code);
            TrialBalanceData.SetRange("Business Unit Code", EXRTrialBalanceBUQuery.BusinessUnitCode);
            if not TrialBalanceData.FindFirst() then begin
                // This shouldn't happen now that the first pass inserts every combination with entries up to the ending date, but we Init() and consider it regardless.
                TrialBalanceData.Init();
                TrialBalanceData."G/L Account No." := EXRTrialBalanceBUQuery.AccountNumber;
                TrialBalanceData."Dimension 1 Code" := EXRTrialBalanceBUQuery.DimensionValue1Code;
                TrialBalanceData."Dimension 2 Code" := EXRTrialBalanceBUQuery.DimensionValue2Code;
                TrialBalanceData."Business Unit Code" := EXRTrialBalanceBUQuery.BusinessUnitCode;
                TrialBalanceData.Insert(true);
            end;
            TrialBalanceData."Starting Balance" := EXRTrialBalanceBUQuery.Amount;
            TrialBalanceData."Starting Balance (Debit)" := EXRTrialBalanceBUQuery.DebitAmount;
            TrialBalanceData."Starting Balance (Credit)" := EXRTrialBalanceBUQuery.CreditAmount;
            TrialBalanceData."Starting Balance (ACY)" := EXRTrialBalanceBUQuery.ACYAmount;
            TrialBalanceData."Starting Balance (Debit) (ACY)" := EXRTrialBalanceBUQuery.ACYDebitAmount;
            TrialBalanceData."Starting Balance (Credit)(ACY)" := EXRTrialBalanceBUQuery.ACYCreditAmount;
            TrialBalanceData."Net Change" := TrialBalanceData."Net Change" - EXRTrialBalanceBUQuery.Amount;
            TrialBalanceData."Net Change (Debit)" := TrialBalanceData."Net Change (Debit)" - EXRTrialBalanceBUQuery.DebitAmount;
            TrialBalanceData."Net Change (Credit)" := TrialBalanceData."Net Change (Credit)" - EXRTrialBalanceBUQuery.CreditAmount;
            TrialBalanceData."Net Change (ACY)" := TrialBalanceData."Net Change (ACY)" - EXRTrialBalanceBUQuery.ACYAmount;
            TrialBalanceData."Net Change (Debit) (ACY)" := TrialBalanceData."Net Change (Debit) (ACY)" - EXRTrialBalanceBUQuery.ACYDebitAmount;
            TrialBalanceData."Net Change (Credit) (ACY)" := TrialBalanceData."Net Change (Credit) (ACY)" - EXRTrialBalanceBUQuery.ACYCreditAmount;
            TrialBalanceData.Modify();
            InsertUsedDimensionValue(1, TrialBalanceData."Dimension 1 Code", Dimension1Values);
            InsertUsedDimensionValue(2, TrialBalanceData."Dimension 2 Code", Dimension2Values);
        end;
    end;

    local procedure BuildAccountToTotalsMap(AccountNoFilter: Text; var AccountToTotals: Dictionary of [Code[20], List of [Code[20]]])
    var
        TotalAccount: Record "G/L Account";
        PostingAccount: Record "G/L Account";
    begin
        // For each Total/End-Total account we record which posting accounts fall inside its Totaling range. 
        TotalAccount.SetFilter("Account Type", '%1|%2', "G/L Account Type"::"End-Total", "G/L Account Type"::Total);
        if AccountNoFilter <> '' then
            TotalAccount.SetFilter("No.", AccountNoFilter);
        if not TotalAccount.FindSet() then
            exit;
        repeat
            if TotalAccount.Totaling <> '' then begin
                PostingAccount.Reset();
                PostingAccount.SetRange("Account Type", "G/L Account Type"::Posting);
                PostingAccount.SetFilter("No.", TotalAccount.Totaling);
                if PostingAccount.FindSet() then
                    repeat
                        AddTotalForAccount(AccountToTotals, PostingAccount."No.", TotalAccount."No.");
                    until PostingAccount.Next() = 0;
            end;
        until TotalAccount.Next() = 0;
    end;

    local procedure AddTotalForAccount(var AccountToTotals: Dictionary of [Code[20], List of [Code[20]]]; PostingAccountNo: Code[20]; TotalAccountNo: Code[20])
    var
        ContainingTotals: List of [Code[20]];
    begin
        if AccountToTotals.Get(PostingAccountNo, ContainingTotals) then
            ContainingTotals.Add(TotalAccountNo)
        else begin
            ContainingTotals.Add(TotalAccountNo);
            AccountToTotals.Add(PostingAccountNo, ContainingTotals);
        end;
    end;

    local procedure DistributePostingRowsToTotals(var TrialBalanceData: Record "EXR Trial Balance Buffer"; var AccountToTotals: Dictionary of [Code[20], List of [Code[20]]]; var TotalsBuffer: Record "EXR Trial Balance Buffer")
    var
        ContainingTotals: List of [Code[20]];
        TotalAccountNo: Code[20];
    begin
        // Single sweep over the posting rows; each row is added once to every total whose range contains its account.
        TrialBalanceData.Reset();
        if not TrialBalanceData.FindSet() then
            exit;
        repeat
            if AccountToTotals.Get(TrialBalanceData."G/L Account No.", ContainingTotals) then
                foreach TotalAccountNo in ContainingTotals do
                    AddRowToTotal(TotalAccountNo, TrialBalanceData, TotalsBuffer);
        until TrialBalanceData.Next() = 0;
    end;

    local procedure AddRowToTotal(TotalAccountNo: Code[20]; var SourceRow: Record "EXR Trial Balance Buffer"; var TotalsBuffer: Record "EXR Trial Balance Buffer")
    begin
        if not TotalsBuffer.Get(TotalAccountNo, SourceRow."Dimension 1 Code", SourceRow."Dimension 2 Code", SourceRow."Business Unit Code", SourceRow."Period Start") then begin
            TotalsBuffer.Init();
            TotalsBuffer."G/L Account No." := TotalAccountNo;
            TotalsBuffer."Dimension 1 Code" := SourceRow."Dimension 1 Code";
            TotalsBuffer."Dimension 2 Code" := SourceRow."Dimension 2 Code";
            TotalsBuffer."Business Unit Code" := SourceRow."Business Unit Code";
            TotalsBuffer."Period Start" := SourceRow."Period Start";
            TotalsBuffer.Insert();
        end;
        // LCY
        TotalsBuffer."Net Change" := TotalsBuffer."Net Change" + SourceRow."Net Change";
        TotalsBuffer."Net Change (Debit)" := TotalsBuffer."Net Change (Debit)" + SourceRow."Net Change (Debit)";
        TotalsBuffer."Net Change (Credit)" := TotalsBuffer."Net Change (Credit)" + SourceRow."Net Change (Credit)";
        TotalsBuffer.Balance := TotalsBuffer.Balance + SourceRow.Balance;
        TotalsBuffer."Balance (Debit)" := TotalsBuffer."Balance (Debit)" + SourceRow."Balance (Debit)";
        TotalsBuffer."Balance (Credit)" := TotalsBuffer."Balance (Credit)" + SourceRow."Balance (Credit)";
        TotalsBuffer."Starting Balance" := TotalsBuffer."Starting Balance" + SourceRow."Starting Balance";
        TotalsBuffer."Starting Balance (Debit)" := TotalsBuffer."Starting Balance (Debit)" + SourceRow."Starting Balance (Debit)";
        TotalsBuffer."Starting Balance (Credit)" := TotalsBuffer."Starting Balance (Credit)" + SourceRow."Starting Balance (Credit)";
        // ACY
        TotalsBuffer."Net Change (ACY)" := TotalsBuffer."Net Change (ACY)" + SourceRow."Net Change (ACY)";
        TotalsBuffer."Net Change (Debit) (ACY)" := TotalsBuffer."Net Change (Debit) (ACY)" + SourceRow."Net Change (Debit) (ACY)";
        TotalsBuffer."Net Change (Credit) (ACY)" := TotalsBuffer."Net Change (Credit) (ACY)" + SourceRow."Net Change (Credit) (ACY)";
        TotalsBuffer."Balance (ACY)" := TotalsBuffer."Balance (ACY)" + SourceRow."Balance (ACY)";
        TotalsBuffer."Balance (Debit) (ACY)" := TotalsBuffer."Balance (Debit) (ACY)" + SourceRow."Balance (Debit) (ACY)";
        TotalsBuffer."Balance (Credit) (ACY)" := TotalsBuffer."Balance (Credit) (ACY)" + SourceRow."Balance (Credit) (ACY)";
        TotalsBuffer."Starting Balance (ACY)" := TotalsBuffer."Starting Balance (ACY)" + SourceRow."Starting Balance (ACY)";
        TotalsBuffer."Starting Balance (Debit) (ACY)" := TotalsBuffer."Starting Balance (Debit) (ACY)" + SourceRow."Starting Balance (Debit) (ACY)";
        TotalsBuffer."Starting Balance (Credit)(ACY)" := TotalsBuffer."Starting Balance (Credit)(ACY)" + SourceRow."Starting Balance (Credit)(ACY)";
        // Budget
        TotalsBuffer."Budget (Net)" := TotalsBuffer."Budget (Net)" + SourceRow."Budget (Net)";
        TotalsBuffer."Budget (Bal. at Date)" := TotalsBuffer."Budget (Bal. at Date)" + SourceRow."Budget (Bal. at Date)";
        TotalsBuffer.Modify();
    end;

    local procedure MergeTotalsIntoBuffer(var TotalsBuffer: Record "EXR Trial Balance Buffer"; var TrialBalanceData: Record "EXR Trial Balance Buffer")
    begin
        TrialBalanceData.Reset();
        TotalsBuffer.Reset();
        if not TotalsBuffer.FindSet() then
            exit;
        repeat
            TrialBalanceData := TotalsBuffer;
            TrialBalanceData.CalculateBudgetComparisons();
            TrialBalanceData.CheckAllZero();
            if not TrialBalanceData."All Zero" then
                TrialBalanceData.Insert(true);
        until TotalsBuffer.Next() = 0;
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
        GLAccount: Record "G/L Account";
    begin
        GLAccount.SetFilter("Date Filter", GLAccountDateFilter);
        StartDate := GLAccount.GetRangeMin("Date Filter");
        EndDate := GLAccount.GetRangeMax("Date Filter");
        if StartDate = 0D then
            StartDate := WorkDate();
        if EndDate = 0D then
            EndDate := StartDate;
    end;

    local procedure GetOpeningBalanceCutoff(StartDate: Date): Date
    begin
        // We return the date immediately before the starting date, considering BC's date ordering and the presence of closing dates
        if StartDate = ClosingDate(StartDate) then
            exit(NormalDate(StartDate));
        exit(ClosingDate(StartDate - 1));
    end;
    #endregion

}
