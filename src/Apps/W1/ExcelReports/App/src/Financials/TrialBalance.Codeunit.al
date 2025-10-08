namespace Microsoft.Finance.ExcelReports;
using Microsoft.Finance.GeneralLedger.Account;
using Microsoft.Finance.GeneralLedger.Ledger;
using Microsoft.Finance.Consolidation;
using Microsoft.Finance.Dimension;

codeunit 4410 "Trial Balance"
{
    var
        GlobalBreakdownByDimension: Boolean;
        GlobalBreakdownByBusinessUnit: Boolean;
        BlankLbl: Label '(BLANK)';

    internal procedure ConfigureTrialBalance(BreakdownByDimension: Boolean; BreakdownByBusinessUnit: Boolean)
    begin
        GlobalBreakdownByDimension := BreakdownByDimension;
        GlobalBreakdownByBusinessUnit := BreakdownByBusinessUnit;
    end;

    internal procedure InsertTrialBalanceReportData(var GLAccount: Record "G/L Account"; var Dimension1Values: Record "Dimension Value" temporary; var Dimension2Values: Record "Dimension Value" temporary; var TrialBalanceData: Record "EXR Trial Balance Buffer")
    var
        DimensionValue: Record "Dimension Value";
        BusinessUnitFilters, Dimension1Filters, Dimension2Filters : List of [Code[20]];
    begin
        Session.LogMessage('0000PYA', 'Started collecting trial balance data', Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::All, 'Category', 'Excel Reports');
        if not GLAccount.FindSet() then begin
            Session.LogMessage('0000PYD', 'Finished collecting trial balance data', Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::All, 'Category', 'Excel Reports');
            exit;
        end;
#if not CLEAN27
        if IsPerformantTrialBalanceFeatureActive() then
#endif
            // The feature currently doesn't consider breakdown for consolidation
            if (not GlobalBreakdownByBusinessUnit) and GlobalBreakdownByDimension then begin
                Session.LogMessage('0000PYC', 'Running query-based trial balance', Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::All, 'Category', 'Excel Reports');
                InsertTrialBalanceReportDataFromQuery(GLAccount, Dimension1Values, Dimension2Values, TrialBalanceData);
                Session.LogMessage('0000PYD', 'Finished collecting trial balance data', Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::All, 'Category', 'Excel Reports');
                exit;
            end;

        if GlobalBreakdownByDimension then begin
            DimensionValue.SetRange("Global Dimension No.", 1);
            InsertDimensionFiltersFromDimensionValues(DimensionValue, Dimension1Filters);
            DimensionValue.SetRange("Global Dimension No.", 2);
            InsertDimensionFiltersFromDimensionValues(DimensionValue, Dimension2Filters);
        end;
        if GlobalBreakdownByBusinessUnit then
            InsertBusinessUnitFilters(BusinessUnitFilters);

        Clear(TrialBalanceData);
        TrialBalanceData.DeleteAll();
        repeat
            InsertBreakdownForGLAccount(GLAccount, Dimension1Filters, Dimension2Filters, BusinessUnitFilters, TrialBalanceData, Dimension1Values, Dimension2Values);
        until GLAccount.Next() = 0;
        Session.LogMessage('0000PYD', 'Finished collecting trial balance data', Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::All, 'Category', 'Excel Reports');
    end;

#if not CLEAN27
    local procedure IsPerformantTrialBalanceFeatureActive() Active: Boolean
    begin
#pragma warning disable AL0432
        OnIsPerformantTrialBalanceFeatureActive(Active);
#pragma warning restore AL0432
    end;
#endif

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
        OnBeforeInsertDimensionFiltersFromDimensionValues(DimensionValue, DimensionFilters, IsHandled);
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
        if GlobalBreakdownByDimension then
            for i := 1 to Dimension1Filters.Count do
                for j := 1 to Dimension2Filters.Count do
                    if GlobalBreakdownByBusinessUnit then
                        for k := 1 to BusinessUnitCodeFilters.Count do
                            InsertGLAccountTotalsForFilters(Dimension1Filters.Get(i), Dimension2Filters.Get(j), BusinessUnitCodeFilters.Get(k), GLAccount, TrialBalanceData, Dimension1Values, Dimension2Values)
                    else
                        InsertGLAccountTotalsForFilters(Dimension1Filters.Get(i), Dimension2Filters.Get(j), GLAccount, TrialBalanceData, Dimension1Values, Dimension2Values)
        else
            if GlobalBreakdownByBusinessUnit then
                for i := 1 to BusinessUnitCodeFilters.Count do
                    InsertGLAccountTotalsForFilters(BusinessUnitCodeFilters.Get(i), GLAccount, TrialBalanceData)
            else
                InsertGLAccountTotalsForFilters(GLAccount, TrialBalanceData);
    end;

    local procedure InsertGLAccountTotalsForFilters(var GLAccount: Record "G/L Account"; var TrialBalanceData: Record "EXR Trial Balance Buffer")
    var
        TempDimension1Values: Record "Dimension Value" temporary;
        TempDimension2Values: Record "Dimension Value" temporary;
    begin
        InsertGLAccountTotalsForFilters('', '', '', GLAccount, TrialBalanceData, TempDimension1Values, TempDimension2Values);
    end;

    local procedure InsertGLAccountTotalsForFilters(BusinessUnitCode: Code[20]; var GLAccount: Record "G/L Account"; var TrialBalanceData: Record "EXR Trial Balance Buffer")
    var
        TempDimension1Values: Record "Dimension Value" temporary;
        TempDimension2Values: Record "Dimension Value" temporary;
    begin
        InsertGLAccountTotalsForFilters('', '', BusinessUnitCode, GLAccount, TrialBalanceData, TempDimension1Values, TempDimension2Values);
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
        if GlobalBreakdownByDimension then begin
            LocalGLAccount.SetFilter("Global Dimension 1 Filter", '= ''%1''', Dimension1ValueCode);
            LocalGLAccount.SetFilter("Global Dimension 2 Filter", '= ''%1''', Dimension2ValueCode);
        end;
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
            if GlobalBreakdownByDimension then begin
                InsertUsedDimensionValue(1, TrialBalanceData."Dimension 1 Code", Dimension1Values);
                InsertUsedDimensionValue(2, TrialBalanceData."Dimension 2 Code", Dimension2Values);
            end;
        end;
    end;

    internal procedure InsertConsolidatedTrialBalanceReportDataFromQuery(var GLAccount: Record "G/L Account"; var Dimension1Values: Record "Dimension Value" temporary; var Dimension2Values: Record "Dimension Value" temporary; var TrialBalanceData: Record "EXR Trial Balance Buffer")
    var
        LocalGLAccount: Record "G/L Account";
        EXRConsolidatedTrialBalanceQuery: Query "EXR Consolidated Trial Balance";
        StartDate, EndDate : Date;
    begin
        TrialBalanceData.DeleteAll();
        GetRangeDatesForGLAccountFilter(GLAccount.GetFilter("Date Filter"), StartDate, EndDate);

        // Get the balances at the ending date
        EXRConsolidatedTrialBalanceQuery.SetFilter(EXRConsolidatedTrialBalanceQuery.PostingDate, '..%1', EndDate);
        EXRConsolidatedTrialBalanceQuery.Open();
        while EXRConsolidatedTrialBalanceQuery.Read() do begin
            TrialBalanceData."G/L Account No." := EXRConsolidatedTrialBalanceQuery.AccountNumber;
            TrialBalanceData."Dimension 1 Code" := EXRConsolidatedTrialBalanceQuery.DimensionValue1Code;
            TrialBalanceData."Dimension 2 Code" := EXRConsolidatedTrialBalanceQuery.DimensionValue2Code;
            TrialBalanceData."Business Unit Code" := EXRConsolidatedTrialBalanceQuery.BusinessUnitCode;
            TrialBalanceData.Validate(Balance, EXRConsolidatedTrialBalanceQuery.Amount);
            TrialBalanceData.Validate("Balance (ACY)", EXRConsolidatedTrialBalanceQuery.ACYAmount);
            TrialBalanceData.Validate("Net Change", EXRConsolidatedTrialBalanceQuery.Amount);
            TrialBalanceData.Validate("Net Change (ACY)", EXRConsolidatedTrialBalanceQuery.ACYAmount);
            TrialBalanceData.Insert(true);
            InsertUsedDimensionValue(1, TrialBalanceData."Dimension 1 Code", Dimension1Values);
            InsertUsedDimensionValue(2, TrialBalanceData."Dimension 2 Code", Dimension2Values);
        end;
        EXRConsolidatedTrialBalanceQuery.Close();

        // Get the balances at the starting date and modify existing entries
        EXRConsolidatedTrialBalanceQuery.SetFilter(EXRConsolidatedTrialBalanceQuery.PostingDate, '..%1', StartDate - 1);
        EXRConsolidatedTrialBalanceQuery.Open();
        while EXRConsolidatedTrialBalanceQuery.Read() do begin
            TrialBalanceData.SetRange("G/L Account No.", EXRConsolidatedTrialBalanceQuery.AccountNumber);
            TrialBalanceData.SetRange("Dimension 1 Code", EXRConsolidatedTrialBalanceQuery.DimensionValue1Code);
            TrialBalanceData.SetRange("Dimension 2 Code", EXRConsolidatedTrialBalanceQuery.DimensionValue2Code);
            TrialBalanceData.SetRange("Business Unit Code", EXRConsolidatedTrialBalanceQuery.BusinessUnitCode);
            if not TrialBalanceData.FindFirst() then begin
                TrialBalanceData."G/L Account No." := EXRConsolidatedTrialBalanceQuery.AccountNumber;
                TrialBalanceData."Dimension 1 Code" := EXRConsolidatedTrialBalanceQuery.DimensionValue1Code;
                TrialBalanceData."Dimension 2 Code" := EXRConsolidatedTrialBalanceQuery.DimensionValue2Code;
                TrialBalanceData."Business Unit Code" := EXRConsolidatedTrialBalanceQuery.BusinessUnitCode;
                TrialBalanceData.Insert(true);
            end;
            TrialBalanceData.Validate("Starting Balance", EXRConsolidatedTrialBalanceQuery.Amount);
            TrialBalanceData.Validate("Starting Balance (ACY)", EXRConsolidatedTrialBalanceQuery.ACYAmount);
            TrialBalanceData.Validate("Net Change", TrialBalanceData."Net Change" - EXRConsolidatedTrialBalanceQuery.Amount);
            TrialBalanceData.Validate("Net Change (ACY)", TrialBalanceData."Net Change (ACY)" - EXRConsolidatedTrialBalanceQuery.ACYAmount);
            TrialBalanceData.Modify();
            InsertUsedDimensionValue(1, TrialBalanceData."Dimension 1 Code", Dimension1Values);
            InsertUsedDimensionValue(2, TrialBalanceData."Dimension 2 Code", Dimension2Values);
        end;

        // Handle End-Total accounts
        HandleEndTotalAccountsForConsolidatedReport(TrialBalanceData);
        TrialBalanceData.Reset();
    end;

    internal procedure InsertTrialBalanceBudgetReportDataFromQuery(var GLAccount: Record "G/L Account"; var Dimension1Values: Record "Dimension Value" temporary; var Dimension2Values: Record "Dimension Value" temporary; var TrialBalanceData: Record "EXR Trial Balance Buffer")
    var
        LocalGLAccount: Record "G/L Account";
        EXRTrialBalanceBudgetQuery: Query "EXR Trial Balance Budget";
        StartDate, EndDate : Date;
    begin
        TrialBalanceData.DeleteAll();
        GetRangeDatesForGLAccountFilter(GLAccount.GetFilter("Date Filter"), StartDate, EndDate);

        // Get the balances at the ending date
        EXRTrialBalanceBudgetQuery.SetFilter(EXRTrialBalanceBudgetQuery.PostingDate, '..%1', EndDate);
        EXRTrialBalanceBudgetQuery.Open();
        while EXRTrialBalanceBudgetQuery.Read() do begin
            TrialBalanceData."G/L Account No." := EXRTrialBalanceBudgetQuery.AccountNumber;
            TrialBalanceData."Dimension 1 Code" := EXRTrialBalanceBudgetQuery.DimensionValue1Code;
            TrialBalanceData."Dimension 2 Code" := EXRTrialBalanceBudgetQuery.DimensionValue2Code;
            TrialBalanceData.Validate(Balance, EXRTrialBalanceBudgetQuery.Amount);
            TrialBalanceData.Validate("Balance (ACY)", EXRTrialBalanceBudgetQuery.ACYAmount);
            TrialBalanceData.Validate("Net Change", EXRTrialBalanceBudgetQuery.Amount);
            TrialBalanceData.Validate("Net Change (ACY)", EXRTrialBalanceBudgetQuery.ACYAmount);
            TrialBalanceData.Insert(true);
            InsertUsedDimensionValue(1, TrialBalanceData."Dimension 1 Code", Dimension1Values);
            InsertUsedDimensionValue(2, TrialBalanceData."Dimension 2 Code", Dimension2Values);
        end;
        EXRTrialBalanceBudgetQuery.Close();

        // Get the balances at the starting date and modify existing entries
        EXRTrialBalanceBudgetQuery.SetFilter(EXRTrialBalanceBudgetQuery.PostingDate, '..%1', StartDate - 1);
        EXRTrialBalanceBudgetQuery.Open();
        while EXRTrialBalanceBudgetQuery.Read() do begin
            TrialBalanceData.SetRange("G/L Account No.", EXRTrialBalanceBudgetQuery.AccountNumber);
            TrialBalanceData.SetRange("Dimension 1 Code", EXRTrialBalanceBudgetQuery.DimensionValue1Code);
            TrialBalanceData.SetRange("Dimension 2 Code", EXRTrialBalanceBudgetQuery.DimensionValue2Code);
            if not TrialBalanceData.FindFirst() then begin
                TrialBalanceData."G/L Account No." := EXRTrialBalanceBudgetQuery.AccountNumber;
                TrialBalanceData."Dimension 1 Code" := EXRTrialBalanceBudgetQuery.DimensionValue1Code;
                TrialBalanceData."Dimension 2 Code" := EXRTrialBalanceBudgetQuery.DimensionValue2Code;
                TrialBalanceData.Insert(true);
            end;
            TrialBalanceData.Validate("Starting Balance", EXRTrialBalanceBudgetQuery.Amount);
            TrialBalanceData.Validate("Starting Balance (ACY)", EXRTrialBalanceBudgetQuery.ACYAmount);
            TrialBalanceData.Validate("Net Change", TrialBalanceData."Net Change" - EXRTrialBalanceBudgetQuery.Amount);
            TrialBalanceData.Validate("Net Change (ACY)", TrialBalanceData."Net Change (ACY)" - EXRTrialBalanceBudgetQuery.ACYAmount);
            TrialBalanceData.Modify();
            InsertUsedDimensionValue(1, TrialBalanceData."Dimension 1 Code", Dimension1Values);
            InsertUsedDimensionValue(2, TrialBalanceData."Dimension 2 Code", Dimension2Values);
        end;

        // Add budget data from G/L Account fields
        AddBudgetDataFromGLAccounts(GLAccount, TrialBalanceData);
        
        // Handle End-Total accounts
        HandleEndTotalAccounts(TrialBalanceData);
        TrialBalanceData.Reset();
    end;

    internal procedure InsertTrialBalanceByPeriodReportDataFromQuery(var GLAccount: Record "G/L Account"; var Dimension1Values: Record "Dimension Value" temporary; var Dimension2Values: Record "Dimension Value" temporary; var TrialBalanceData: Record "EXR Trial Balance Buffer")
    var
        LocalGLAccount: Record "G/L Account";
        EXRTrialBalanceByPeriodQuery: Query "EXR Trial Balance by Period";
        StartDate, EndDate : Date;
    begin
        TrialBalanceData.DeleteAll();
        GetRangeDatesForGLAccountFilter(GLAccount.GetFilter("Date Filter"), StartDate, EndDate);

        // Get the balances at the ending date
        EXRTrialBalanceByPeriodQuery.SetFilter(EXRTrialBalanceByPeriodQuery.PostingDate, '..%1', EndDate);
        EXRTrialBalanceByPeriodQuery.Open();
        while EXRTrialBalanceByPeriodQuery.Read() do begin
            TrialBalanceData."G/L Account No." := EXRTrialBalanceByPeriodQuery.AccountNumber;
            TrialBalanceData."Dimension 1 Code" := EXRTrialBalanceByPeriodQuery.DimensionValue1Code;
            TrialBalanceData."Dimension 2 Code" := EXRTrialBalanceByPeriodQuery.DimensionValue2Code;
            TrialBalanceData.Validate(Balance, EXRTrialBalanceByPeriodQuery.Amount);
            TrialBalanceData.Validate("Balance (ACY)", EXRTrialBalanceByPeriodQuery.ACYAmount);
            TrialBalanceData.Validate("Net Change", EXRTrialBalanceByPeriodQuery.Amount);
            TrialBalanceData.Validate("Net Change (ACY)", EXRTrialBalanceByPeriodQuery.ACYAmount);
            TrialBalanceData.Insert(true);
            InsertUsedDimensionValue(1, TrialBalanceData."Dimension 1 Code", Dimension1Values);
            InsertUsedDimensionValue(2, TrialBalanceData."Dimension 2 Code", Dimension2Values);
        end;
        EXRTrialBalanceByPeriodQuery.Close();

        // Get the balances at the starting date and modify existing entries
        EXRTrialBalanceByPeriodQuery.SetFilter(EXRTrialBalanceByPeriodQuery.PostingDate, '..%1', StartDate - 1);
        EXRTrialBalanceByPeriodQuery.Open();
        while EXRTrialBalanceByPeriodQuery.Read() do begin
            TrialBalanceData.SetRange("G/L Account No.", EXRTrialBalanceByPeriodQuery.AccountNumber);
            TrialBalanceData.SetRange("Dimension 1 Code", EXRTrialBalanceByPeriodQuery.DimensionValue1Code);
            TrialBalanceData.SetRange("Dimension 2 Code", EXRTrialBalanceByPeriodQuery.DimensionValue2Code);
            if not TrialBalanceData.FindFirst() then begin
                TrialBalanceData."G/L Account No." := EXRTrialBalanceByPeriodQuery.AccountNumber;
                TrialBalanceData."Dimension 1 Code" := EXRTrialBalanceByPeriodQuery.DimensionValue1Code;
                TrialBalanceData."Dimension 2 Code" := EXRTrialBalanceByPeriodQuery.DimensionValue2Code;
                TrialBalanceData.Insert(true);
            end;
            TrialBalanceData.Validate("Starting Balance", EXRTrialBalanceByPeriodQuery.Amount);
            TrialBalanceData.Validate("Starting Balance (ACY)", EXRTrialBalanceByPeriodQuery.ACYAmount);
            TrialBalanceData.Validate("Net Change", TrialBalanceData."Net Change" - EXRTrialBalanceByPeriodQuery.Amount);
            TrialBalanceData.Validate("Net Change (ACY)", TrialBalanceData."Net Change (ACY)" - EXRTrialBalanceByPeriodQuery.ACYAmount);
            TrialBalanceData.Modify();
            InsertUsedDimensionValue(1, TrialBalanceData."Dimension 1 Code", Dimension1Values);
            InsertUsedDimensionValue(2, TrialBalanceData."Dimension 2 Code", Dimension2Values);
        end;

        // Handle End-Total accounts
        HandleEndTotalAccounts(TrialBalanceData);
        TrialBalanceData.Reset();
    end;

    internal procedure InsertTrialBalancePrevYearReportDataFromQuery(var GLAccount: Record "G/L Account"; var Dimension1Values: Record "Dimension Value" temporary; var Dimension2Values: Record "Dimension Value" temporary; var TrialBalanceData: Record "EXR Trial Balance Buffer")
    var
        LocalGLAccount: Record "G/L Account";
        EXRTrialBalancePrevYearQuery: Query "EXR Trial Balance Prev Year";
        StartDate, EndDate : Date;
    begin
        TrialBalanceData.DeleteAll();
        GetRangeDatesForGLAccountFilter(GLAccount.GetFilter("Date Filter"), StartDate, EndDate);

        // Get the balances at the ending date
        EXRTrialBalancePrevYearQuery.SetFilter(EXRTrialBalancePrevYearQuery.PostingDate, '..%1', EndDate);
        EXRTrialBalancePrevYearQuery.Open();
        while EXRTrialBalancePrevYearQuery.Read() do begin
            TrialBalanceData."G/L Account No." := EXRTrialBalancePrevYearQuery.AccountNumber;
            TrialBalanceData."Dimension 1 Code" := EXRTrialBalancePrevYearQuery.DimensionValue1Code;
            TrialBalanceData."Dimension 2 Code" := EXRTrialBalancePrevYearQuery.DimensionValue2Code;
            TrialBalanceData.Validate(Balance, EXRTrialBalancePrevYearQuery.Amount);
            TrialBalanceData.Validate("Balance (ACY)", EXRTrialBalancePrevYearQuery.ACYAmount);
            TrialBalanceData.Validate("Net Change", EXRTrialBalancePrevYearQuery.Amount);
            TrialBalanceData.Validate("Net Change (ACY)", EXRTrialBalancePrevYearQuery.ACYAmount);
            TrialBalanceData.Insert(true);
            InsertUsedDimensionValue(1, TrialBalanceData."Dimension 1 Code", Dimension1Values);
            InsertUsedDimensionValue(2, TrialBalanceData."Dimension 2 Code", Dimension2Values);
        end;
        EXRTrialBalancePrevYearQuery.Close();

        // Get the balances at the starting date and modify existing entries
        EXRTrialBalancePrevYearQuery.SetFilter(EXRTrialBalancePrevYearQuery.PostingDate, '..%1', StartDate - 1);
        EXRTrialBalancePrevYearQuery.Open();
        while EXRTrialBalancePrevYearQuery.Read() do begin
            TrialBalanceData.SetRange("G/L Account No.", EXRTrialBalancePrevYearQuery.AccountNumber);
            TrialBalanceData.SetRange("Dimension 1 Code", EXRTrialBalancePrevYearQuery.DimensionValue1Code);
            TrialBalanceData.SetRange("Dimension 2 Code", EXRTrialBalancePrevYearQuery.DimensionValue2Code);
            if not TrialBalanceData.FindFirst() then begin
                TrialBalanceData."G/L Account No." := EXRTrialBalancePrevYearQuery.AccountNumber;
                TrialBalanceData."Dimension 1 Code" := EXRTrialBalancePrevYearQuery.DimensionValue1Code;
                TrialBalanceData."Dimension 2 Code" := EXRTrialBalancePrevYearQuery.DimensionValue2Code;
                TrialBalanceData.Insert(true);
            end;
            TrialBalanceData.Validate("Starting Balance", EXRTrialBalancePrevYearQuery.Amount);
            TrialBalanceData.Validate("Starting Balance (ACY)", EXRTrialBalancePrevYearQuery.ACYAmount);
            TrialBalanceData.Validate("Net Change", TrialBalanceData."Net Change" - EXRTrialBalancePrevYearQuery.Amount);
            TrialBalanceData.Validate("Net Change (ACY)", TrialBalanceData."Net Change (ACY)" - EXRTrialBalancePrevYearQuery.ACYAmount);
            TrialBalanceData.Modify();
            InsertUsedDimensionValue(1, TrialBalanceData."Dimension 1 Code", Dimension1Values);
            InsertUsedDimensionValue(2, TrialBalanceData."Dimension 2 Code", Dimension2Values);
        end;

        // Handle End-Total accounts
        HandleEndTotalAccounts(TrialBalanceData);
        TrialBalanceData.Reset();
    end;

    local procedure InsertTrialBalanceReportDataFromQuery(var GLAccount: Record "G/L Account"; var Dimension1Values: Record "Dimension Value" temporary; var Dimension2Values: Record "Dimension Value" temporary; var TrialBalanceData: Record "EXR Trial Balance Buffer")
    var
        LocalGLAccount: Record "G/L Account";
        EXRTrialBalanceQuery: Query "EXR Trial Balance";
        StartDate, EndDate : Date;
    begin
        TrialBalanceData.DeleteAll();
        // We get the dates of the first and last entries for the date filter in G/L Account,
        // the trial balance returns starting balance, net change, and ending balance with regard to such dates
        GetRangeDatesForGLAccountFilter(GLAccount.GetFilter("Date Filter"), StartDate, EndDate);

        // We first get the balances at the ending date
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
            TrialBalanceData.Insert(true);
            InsertUsedDimensionValue(1, TrialBalanceData."Dimension 1 Code", Dimension1Values);
            InsertUsedDimensionValue(2, TrialBalanceData."Dimension 2 Code", Dimension2Values);
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

        // Handle End-Total accounts
        HandleEndTotalAccounts(TrialBalanceData);
        TrialBalanceData.Reset();
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
    end;

    local procedure HandleEndTotalAccounts(var TrialBalanceData: Record "EXR Trial Balance Buffer")
    var
        LocalGLAccount: Record "G/L Account";
    begin
        // The query will just return entries for the "Posting" G/L Accounts and nothing for the End-Total accounts,
        // to address that, we calculate the sums from the contents that we now have in the temporary TrialBalanceData table
        LocalGLAccount.SetRange("Account Type", "G/L Account Type"::"End-Total");
        if LocalGLAccount.FindSet() then
            repeat
                if LocalGLAccount.Totaling <> '' then begin
                    TrialBalanceData.Reset();
                    TrialBalanceData.SetFilter("G/L Account No.", LocalGLAccount.Totaling);
                    TrialBalanceData.CalcSums(
                        // LCY
                        "Net Change", "Net Change (Debit)", "Net Change (Credit)",
                        Balance, "Balance (Debit)", "Balance (Credit)",
                        "Starting Balance", "Starting Balance (Debit)", "Starting Balance (Credit)",
                        // ACY
                        "Net Change (ACY)", "Net Change (Debit) (ACY)", "Net Change (Credit) (ACY)",
                        Balance, "Balance (Debit) (ACY)", "Balance (Credit) (ACY)",
                        "Starting Balance (ACY)", "Starting Balance (Debit) (ACY)", "Starting Balance (Credit)(ACY)"
                    );
                    TrialBalanceData."G/L Account No." := LocalGLAccount."No.";
                    TrialBalanceData.Insert(true);
                end
            until LocalGLAccount.Next() = 0;
    end;

    local procedure HandleEndTotalAccountsForConsolidatedReport(var TrialBalanceData: Record "EXR Trial Balance Buffer")
    var
        LocalGLAccount: Record "G/L Account";
        TempTrialBalanceData: Record "EXR Trial Balance Buffer" temporary;
        BusinessUnitCode: Code[20];
        Dimension1Code: Code[20];
        Dimension2Code: Code[20];
    begin
        // For consolidated reports, we need to handle End-Total accounts for each Business Unit/Dimension combination
        LocalGLAccount.SetRange("Account Type", "G/L Account Type"::"End-Total");
        if LocalGLAccount.FindSet() then
            repeat
                if LocalGLAccount.Totaling <> '' then begin
                    // Get unique combinations of Business Unit and Dimensions
                    TrialBalanceData.Reset();
                    if TrialBalanceData.FindSet() then
                        repeat
                            BusinessUnitCode := TrialBalanceData."Business Unit Code";
                            Dimension1Code := TrialBalanceData."Dimension 1 Code";
                            Dimension2Code := TrialBalanceData."Dimension 2 Code";
                            
                            // Check if we already created an End-Total for this combination
                            TempTrialBalanceData.SetRange("G/L Account No.", LocalGLAccount."No.");
                            TempTrialBalanceData.SetRange("Business Unit Code", BusinessUnitCode);
                            TempTrialBalanceData.SetRange("Dimension 1 Code", Dimension1Code);
                            TempTrialBalanceData.SetRange("Dimension 2 Code", Dimension2Code);
                            if TempTrialBalanceData.IsEmpty() then begin
                                // Calculate totals for this specific combination
                                TrialBalanceData.Reset();
                                TrialBalanceData.SetFilter("G/L Account No.", LocalGLAccount.Totaling);
                                TrialBalanceData.SetRange("Business Unit Code", BusinessUnitCode);
                                TrialBalanceData.SetRange("Dimension 1 Code", Dimension1Code);
                                TrialBalanceData.SetRange("Dimension 2 Code", Dimension2Code);
                                TrialBalanceData.CalcSums(
                                    // LCY
                                    "Net Change", "Net Change (Debit)", "Net Change (Credit)",
                                    Balance, "Balance (Debit)", "Balance (Credit)",
                                    "Starting Balance", "Starting Balance (Debit)", "Starting Balance (Credit)",
                                    // ACY
                                    "Net Change (ACY)", "Net Change (Debit) (ACY)", "Net Change (Credit) (ACY)",
                                    Balance, "Balance (Debit) (ACY)", "Balance (Credit) (ACY)",
                                    "Starting Balance (ACY)", "Starting Balance (Debit) (ACY)", "Starting Balance (Credit)(ACY)"
                                );
                                TrialBalanceData."G/L Account No." := LocalGLAccount."No.";
                                TrialBalanceData."Business Unit Code" := BusinessUnitCode;
                                TrialBalanceData."Dimension 1 Code" := Dimension1Code;
                                TrialBalanceData."Dimension 2 Code" := Dimension2Code;
                                TrialBalanceData.Insert(true);
                                
                                // Remember this combination to avoid duplicates
                                TempTrialBalanceData := TrialBalanceData;
                                TempTrialBalanceData.Insert();
                            end;
                        until TrialBalanceData.Next() = 0;
                end
            until LocalGLAccount.Next() = 0;
    end;

    local procedure AddBudgetDataFromGLAccounts(var GLAccount: Record "G/L Account"; var TrialBalanceData: Record "EXR Trial Balance Buffer")
    var
        LocalGLAccount: Record "G/L Account";
    begin
        // For budget reports, we need to add budget data from G/L Account fields
        LocalGLAccount.Copy(GLAccount);
        if LocalGLAccount.FindSet() then
            repeat
                TrialBalanceData.Reset();
                TrialBalanceData.SetRange("G/L Account No.", LocalGLAccount."No.");
                if TrialBalanceData.FindSet() then
                    repeat
                        // Apply the same filters as in the original logic
                        LocalGLAccount.SetFilter("Global Dimension 1 Filter", '= ''%1''', TrialBalanceData."Dimension 1 Code");
                        LocalGLAccount.SetFilter("Global Dimension 2 Filter", '= ''%1''', TrialBalanceData."Dimension 2 Code");
                        LocalGLAccount.CalcFields("Budgeted Amount", "Budget at Date");
                        TrialBalanceData.Validate("Budget (Net)", LocalGLAccount."Budgeted Amount");
                        TrialBalanceData.Validate("Budget (Bal. at Date)", LocalGLAccount."Budget at Date");
                        TrialBalanceData.CalculateBudgetComparisons();
                        TrialBalanceData.Modify();
                    until TrialBalanceData.Next() = 0;
            until LocalGLAccount.Next() = 0;
    end;

    [IntegrationEvent(true, false)]
    local procedure OnBeforeInsertDimensionFiltersFromDimensionValues(var DimensionValue: Record "Dimension Value"; var DimensionFilters: List of [Code[20]]; var IsHandled: Boolean)
    begin
    end;

#if not CLEAN27
    [Obsolete('This event is temporary to try the functionality before it''s officially released as a feature in feature management.', '27.0')]
    [IntegrationEvent(true, false)]
    local procedure OnIsPerformantTrialBalanceFeatureActive(var Active: Boolean)
    begin
    end;
#endif
}