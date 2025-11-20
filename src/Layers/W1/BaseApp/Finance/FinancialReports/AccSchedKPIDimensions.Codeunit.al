// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.FinancialReports;

using Microsoft.CashFlow.Account;
using Microsoft.CashFlow.Forecast;
using Microsoft.CostAccounting.Account;
using Microsoft.CostAccounting.Budget;
using Microsoft.CostAccounting.Ledger;
using Microsoft.Finance.Analysis;
using Microsoft.Finance.GeneralLedger.Account;
using Microsoft.Finance.GeneralLedger.Budget;
using Microsoft.Finance.GeneralLedger.Ledger;

codeunit 9 "Acc. Sched. KPI Dimensions"
{
    TableNo = "Acc. Schedule Line";

    trigger OnRun()
    begin
    end;

    var
        AccSchedName: Record "Acc. Schedule Name";
        AccScheduleLine: Record "Acc. Schedule Line";
        TempAccSchedKPIBuffer: Record "Acc. Sched. KPI Buffer" temporary;
        AccSchedManagement: Codeunit AccSchedManagement;
        StartDate: Date;
        EndDate: Date;
        CallLevel: Integer;
        CallingAccSchedLineID: Integer;
        CallingColumnLayoutID: Integer;

        IllegalValErr: Label 'You have entered an illegal value or a nonexistent row number.';
        GeneralErr: Label '%1\\ %2 %3 %4.', Locked = true;
        ErrorOccurredErr: Label 'The error occurred when the program tried to calculate:\';
        AccSchedLineErr: Label 'Acc. Sched. Line: Row No. = %1, Line No. = %2, Totaling = %3\', Comment = '%1 = Row No., %2= Line No., %3 = Totaling';
        ColumnErr: Label 'Acc. Sched. Column: Column No. = %1, Line No. = %2, Formula  = %3', Comment = '%1 = Column No., %2= Line No., %3 = Formula';
        CircularRefErr: Label 'Because of circular references, the program cannot calculate a formula.';

    procedure GetCellDataWithDimensions(var AccSchedLine: Record "Acc. Schedule Line"; var ColumnLayout: Record "Column Layout"; var TempAccSchedKPIBuffer2: Record "Acc. Sched. KPI Buffer" temporary)
    var
        LastDataLineNo: Integer;
    begin
        TempAccSchedKPIBuffer.Init();
        TempAccSchedKPIBuffer.TransferFields(TempAccSchedKPIBuffer2, false);
        if not TempAccSchedKPIBuffer.Insert() then
            TempAccSchedKPIBuffer.Modify();

        TempAccSchedKPIBuffer2.Reset();
        if TempAccSchedKPIBuffer2.FindLast() then;
        LastDataLineNo := TempAccSchedKPIBuffer2."No.";

        AccScheduleLine.CopyFilters(AccSchedLine);
        StartDate := AccScheduleLine.GetRangeMin("Date Filter");
        if EndDate <> AccScheduleLine.GetRangeMax("Date Filter") then
            EndDate := AccScheduleLine.GetRangeMax("Date Filter");

        CallLevel := 0;
        CallingAccSchedLineID := AccSchedLine."Line No.";
        CallingColumnLayoutID := ColumnLayout."Line No.";

        ColumnLayout.FindSet();
        repeat
            AddCellValueDimensions(AccSchedLine, ColumnLayout, TempAccSchedKPIBuffer2);
        until ColumnLayout.Next() = 0;

        TempAccSchedKPIBuffer2.Reset();
        if TempAccSchedKPIBuffer2.FindLast() then;
        if TempAccSchedKPIBuffer2."No." = LastDataLineNo then begin
            TempAccSchedKPIBuffer2.Init();
            TempAccSchedKPIBuffer2."No." += 1;
            TempAccSchedKPIBuffer2.Date := TempAccSchedKPIBuffer.Date;
            TempAccSchedKPIBuffer2."Closed Period" := TempAccSchedKPIBuffer."Closed Period";
            TempAccSchedKPIBuffer2."Account Schedule Name" := TempAccSchedKPIBuffer."Account Schedule Name";
            TempAccSchedKPIBuffer2."KPI Code" := TempAccSchedKPIBuffer."KPI Code";
            TempAccSchedKPIBuffer2."KPI Name" := TempAccSchedKPIBuffer."KPI Name";
            TempAccSchedKPIBuffer2.Insert();
        end;
    end;

    local procedure AddCellValueDimensions(AccSchedLine: Record "Acc. Schedule Line"; ColumnLayout: Record "Column Layout"; var AccSchedKPIBuffer: Record "Acc. Sched. KPI Buffer")
    var
        GLAcc: Record "G/L Account";
        CostType: Record "Cost Type";
        CFAccount: Record "Cash Flow Account";
        IsExpression: Boolean;
    begin
        if AccSchedLine.Totaling = '' then
            exit;

        if AccSchedName.Name <> AccSchedLine."Schedule Name" then
            AccSchedName.Get(AccSchedLine."Schedule Name");

        IsExpression :=
          AccSchedLine."Totaling Type" in
          [AccSchedLine."Totaling Type"::Formula, AccSchedLine."Totaling Type"::"Set Base For Percent"];

        if IsExpression then
            EvalExprWithDimensions(AccSchedLine.Totaling, AccSchedLine, ColumnLayout, AccSchedKPIBuffer)
        else begin
            if (StartDate = 0D) or (EndDate = 0D) or (EndDate = DMY2Date(31, 12, 9999)) then // Period Error
                exit;

            AccSchedManagement.SetStartDateEndDate(StartDate, EndDate);

            if AccSchedLine."Totaling Type" in
               [AccSchedLine."Totaling Type"::"Posting Accounts",
                AccSchedLine."Totaling Type"::"Total Accounts"]
            then begin
                AccSchedLine.CopyFilters(AccScheduleLine);
                AccSchedManagement.SetGLAccRowFilters(GLAcc, AccSchedLine);
                AccSchedManagement.SetGLAccColumnFilters(GLAcc, AccSchedLine, ColumnLayout);

                if (AccSchedLine."Totaling Type" = AccSchedLine."Totaling Type"::"Posting Accounts") and
                   (StrLen(AccSchedLine.Totaling) <= MaxStrLen(GLAcc.Totaling)) and (StrPos(AccSchedLine.Totaling, '*') = 0)
                then begin
                    GLAcc."Account Type" := GLAcc."Account Type"::Total;
                    GLAcc.Totaling := AccSchedLine.Totaling;
                    AddGLAccDimensions(GLAcc, AccSchedLine, ColumnLayout, AccSchedKPIBuffer);
                end else begin
                    GLAcc.SetLoadFields(Totaling, "Account Type");
                    if GLAcc.Find('-') then
                        repeat
                            AddGLAccDimensions(GLAcc, AccSchedLine, ColumnLayout, AccSchedKPIBuffer);
                        until GLAcc.Next() = 0;
                end;
            end;

            if AccSchedLine."Totaling Type" in
               [AccSchedLine."Totaling Type"::"Cost Type",
                AccSchedLine."Totaling Type"::"Cost Type Total"]
            then begin
                AccSchedLine.CopyFilters(AccScheduleLine);
                AccSchedManagement.SetCostTypeRowFilters(CostType, AccSchedLine, ColumnLayout);
                AccSchedManagement.SetCostTypeColumnFilters(CostType, AccSchedLine, ColumnLayout);

                if (AccSchedLine."Totaling Type" = AccSchedLine."Totaling Type"::"Cost Type") and
                   (StrLen(AccSchedLine.Totaling) <= MaxStrLen(GLAcc.Totaling)) and (StrPos(AccSchedLine.Totaling, '*') = 0)
                then begin
                    CostType.Type := CostType.Type::Total;
                    CostType.Totaling := AccSchedLine.Totaling;
                    AddCostTypeDimensions(CostType, AccSchedLine, ColumnLayout, AccSchedKPIBuffer);
                end else
                    if CostType.Find('-') then
                        repeat
                            AddCostTypeDimensions(CostType, AccSchedLine, ColumnLayout, AccSchedKPIBuffer);
                        until CostType.Next() = 0;
            end;

            if AccSchedLine."Totaling Type" in
               [AccSchedLine."Totaling Type"::"Cash Flow Entry Accounts",
                AccSchedLine."Totaling Type"::"Cash Flow Total Accounts"]
            then begin
                AccSchedLine.CopyFilters(AccScheduleLine);
                AccSchedManagement.SetCFAccRowFilter(CFAccount, AccSchedLine);
                AccSchedManagement.SetCFAccColumnFilter(CFAccount, AccSchedLine, ColumnLayout);
                if (AccSchedLine."Totaling Type" = AccSchedLine."Totaling Type"::"Cash Flow Entry Accounts") and
                   (StrLen(AccSchedLine.Totaling) <= 30)
                then begin
                    CFAccount."Account Type" := CFAccount."Account Type"::Total;
                    CFAccount.Totaling := AccSchedLine.Totaling;
                    AddCFAccountDimensions(CFAccount, AccSchedLine, ColumnLayout, AccSchedKPIBuffer);
                end else
                    if CFAccount.Find('-') then
                        repeat
                            AddCFAccountDimensions(CFAccount, AccSchedLine, ColumnLayout, AccSchedKPIBuffer);
                        until CFAccount.Next() = 0;
            end;
        end;
    end;

    local procedure AddGLAccDimensions(var GLAcc: Record "G/L Account"; var AccSchedLine: Record "Acc. Schedule Line"; ColumnLayout: Record "Column Layout"; var AccSchedKPIBuffer: Record "Acc. Sched. KPI Buffer")
    var
        AnalysisViewEntry: Record "Analysis View Entry";
        GLEntryDimensions: Query "G/L Entry Dimensions";
        GLBudgetEntryDimensions: Query "G/L Budget Entry Dimensions";
        AnalysisViewEntryDimensions: Query "Analysis View Entry Dimensions";
        AnalysisViewBudgEntryDims: Query "Analysis View Budg. Entry Dims";
        FilterText: Text;
        AmountType: Enum "Account Schedule Amount Type";
        AmountToAdd: Decimal;
    begin
        if ConflictAmountType(AccSchedLine, ColumnLayout."Amount Type", AmountType) then
            exit;

        case ColumnLayout."Ledger Entry Type" of
            ColumnLayout."Ledger Entry Type"::Entries:
                if AccSchedName."Analysis View Name" = '' then begin
                    GLEntryDimensions.SetFilter(Posting_Date, GLAcc.GetFilter("Date Filter"));
                    if GLAcc.Totaling = '' then
                        GLEntryDimensions.SetRange(G_L_Account_No, GLAcc."No.")
                    else
                        GLEntryDimensions.SetFilter(G_L_Account_No, GLAcc.Totaling);
                    GLEntryDimensions.SetFilter(
                      Business_Unit_Code, AccSchedLine.GetFilter("Business Unit Filter"));

                    FilterText := CombineFilters(
                        AccSchedLine.GetFilter("Dimension 1 Filter"),
                        AccSchedManagement.GetDimTotalingFilter(1, AccSchedLine."Dimension 1 Totaling"), '&');
                    GLEntryDimensions.SetFilter(Global_Dimension_1_Code, FilterText);

                    FilterText := CombineFilters(
                        AccSchedLine.GetFilter("Dimension 2 Filter"),
                        AccSchedManagement.GetDimTotalingFilter(2, AccSchedLine."Dimension 2 Totaling"), '&');
                    GLEntryDimensions.SetFilter(Global_Dimension_2_Code, FilterText);

                    GLEntryDimensions.Open();
                    while GLEntryDimensions.Read() do begin
                        case AmountType of
                            AmountType::"Net Amount":
                                AmountToAdd := GLEntryDimensions.Sum_Amount;
                            AmountType::"Debit Amount":
                                AmountToAdd := GLEntryDimensions.Sum_Debit_Amount;
                            AmountType::"Credit Amount":
                                AmountToAdd := GLEntryDimensions.Sum_Credit_Amount;
                        end;
                        if PassToResult(AccSchedLine.Show, GLEntryDimensions.Sum_Amount) then
                            CheckAddDimsToResult(
                              AccSchedKPIBuffer, ColumnLayout, GLEntryDimensions.Dimension_Set_ID, AmountToAdd);
                    end;
                    GLEntryDimensions.Close();
                end else begin
                    if GLAcc.Totaling = '' then
                        FilterText := GLAcc."No."
                    else
                        FilterText := GLAcc.Totaling;

                    FilterAnalysisViewEntriesDim(
                      AnalysisViewEntryDimensions, AccSchedName."Analysis View Name",
                      AnalysisViewEntry."Account Source"::"G/L Account", FilterText,
                      GLAcc.GetFilter("Date Filter"), AccSchedLine);

                    AnalysisViewEntryDimensions.Open();
                    while AnalysisViewEntryDimensions.Read() do begin
                        case AmountType of
                            AmountType::"Net Amount":
                                AmountToAdd := AnalysisViewEntryDimensions.Sum_Amount;
                            AmountType::"Debit Amount":
                                AmountToAdd := AnalysisViewEntryDimensions.Sum_Debit_Amount;
                            AmountType::"Credit Amount":
                                AmountToAdd := AnalysisViewEntryDimensions.Sum_Credit_Amount;
                        end;
                        if PassToResult(AccSchedLine.Show, AnalysisViewEntryDimensions.Sum_Amount) then
                            CheckAddDimsToResult(AccSchedKPIBuffer, ColumnLayout, 0, AmountToAdd);
                    end;
                    AnalysisViewEntryDimensions.Close();
                end;
            ColumnLayout."Ledger Entry Type"::"Budget Entries":
                if AccSchedName."Analysis View Name" = '' then begin
                    GLBudgetEntryDimensions.SetFilter(Budget_Name, AccSchedLine.GetFilter("G/L Budget Filter"));
                    GLBudgetEntryDimensions.SetFilter(Date, GLAcc.GetFilter("Date Filter"));

                    if GLAcc.Totaling = '' then
                        GLBudgetEntryDimensions.SetRange(G_L_Account_No, GLAcc."No.")
                    else
                        GLBudgetEntryDimensions.SetFilter(G_L_Account_No, GLAcc.Totaling);
                    GLBudgetEntryDimensions.SetFilter(
                      Business_Unit_Code, AccSchedLine.GetFilter("Business Unit Filter"));

                    FilterText := CombineFilters(
                        AccSchedLine.GetFilter("Dimension 1 Filter"),
                        AccSchedManagement.GetDimTotalingFilter(1, AccSchedLine."Dimension 1 Totaling"), '&');
                    GLBudgetEntryDimensions.SetFilter(Global_Dimension_1_Code, FilterText);

                    FilterText := CombineFilters(
                        AccSchedLine.GetFilter("Dimension 2 Filter"),
                        AccSchedManagement.GetDimTotalingFilter(2, AccSchedLine."Dimension 2 Totaling"), '&');
                    GLBudgetEntryDimensions.SetFilter(Global_Dimension_2_Code, FilterText);

                    GLBudgetEntryDimensions.Open();
                    while GLBudgetEntryDimensions.Read() do begin
                        case AmountType of
                            AmountType::"Net Amount":
                                AmountToAdd := GLBudgetEntryDimensions.Sum_Amount;
                            AmountType::"Debit Amount":
                                begin
                                    AmountToAdd := GLBudgetEntryDimensions.Sum_Amount;
                                    if AmountToAdd < 0 then
                                        AmountToAdd := 0;
                                end;
                            AmountType::"Credit Amount":
                                begin
                                    AmountToAdd := -GLBudgetEntryDimensions.Sum_Amount;
                                    if AmountToAdd < 0 then
                                        AmountToAdd := 0;
                                end;
                        end;
                        if PassToResult(AccSchedLine.Show, GLBudgetEntryDimensions.Sum_Amount) then
                            CheckAddDimsToResult(
                              AccSchedKPIBuffer, ColumnLayout, GLBudgetEntryDimensions.Dimension_Set_ID, AmountToAdd);
                    end;
                    GLBudgetEntryDimensions.Close();
                end else begin
                    if GLAcc.Totaling = '' then
                        AnalysisViewBudgEntryDims.SetRange(G_L_Account_No, GLAcc."No.")
                    else
                        AnalysisViewBudgEntryDims.SetFilter(G_L_Account_No, GLAcc.Totaling);
                    AnalysisViewBudgEntryDims.SetRange(Analysis_View_Code, AccSchedName."Analysis View Name");
                    AnalysisViewBudgEntryDims.SetFilter(Budget_Name, AccSchedLine.GetFilter("G/L Budget Filter"));
                    AnalysisViewBudgEntryDims.SetFilter(Posting_Date, GLAcc.GetFilter("Date Filter"));
                    AnalysisViewBudgEntryDims.SetFilter(
                      Business_Unit_Code, AccSchedLine.GetFilter("Business Unit Filter"));

                    FilterText := CombineFilters(
                        AccSchedLine.GetFilter("Dimension 1 Filter"),
                        AccSchedManagement.GetDimTotalingFilter(1, AccSchedLine."Dimension 1 Totaling"), '&');
                    AnalysisViewBudgEntryDims.SetFilter(Dimension_1_Value_Code, FilterText);

                    FilterText := CombineFilters(
                        AccSchedLine.GetFilter("Dimension 2 Filter"),
                        AccSchedManagement.GetDimTotalingFilter(2, AccSchedLine."Dimension 2 Totaling"), '&');
                    AnalysisViewBudgEntryDims.SetFilter(Dimension_2_Value_Code, FilterText);

                    FilterText := CombineFilters(
                        AccSchedLine.GetFilter("Dimension 3 Filter"),
                        AccSchedManagement.GetDimTotalingFilter(3, AccSchedLine."Dimension 3 Totaling"), '&');
                    AnalysisViewBudgEntryDims.SetFilter(Dimension_3_Value_Code, FilterText);

                    FilterText := CombineFilters(
                        AccSchedLine.GetFilter("Dimension 4 Filter"),
                        AccSchedManagement.GetDimTotalingFilter(4, AccSchedLine."Dimension 4 Totaling"), '&');
                    AnalysisViewBudgEntryDims.SetFilter(Dimension_4_Value_Code, FilterText);

                    AnalysisViewBudgEntryDims.Open();
                    while AnalysisViewBudgEntryDims.Read() do begin
                        case AmountType of
                            AmountType::"Net Amount":
                                AmountToAdd := AnalysisViewBudgEntryDims.Sum_Amount;
                            AmountType::"Debit Amount":
                                begin
                                    AmountToAdd := AnalysisViewBudgEntryDims.Sum_Amount;
                                    if AmountToAdd < 0 then
                                        AmountToAdd := 0;
                                end;
                            AmountType::"Credit Amount":
                                begin
                                    AmountToAdd := -AnalysisViewBudgEntryDims.Sum_Amount;
                                    if AmountToAdd < 0 then
                                        AmountToAdd := 0;
                                end;
                        end;
                        if PassToResult(AccSchedLine.Show, AnalysisViewBudgEntryDims.Sum_Amount) then
                            CheckAddDimsToResult(AccSchedKPIBuffer, ColumnLayout, 0, AmountToAdd);
                    end;
                    AnalysisViewBudgEntryDims.Close();
                end;
        end;
    end;

    local procedure AddCostTypeDimensions(var CostType: Record "Cost Type"; var AccSchedLine: Record "Acc. Schedule Line"; ColumnLayout: Record "Column Layout"; var AccSchedKPIBuffer: Record "Acc. Sched. KPI Buffer")
    var
        CostEntry: Record "Cost Entry";
        CostBudgetEntry: Record "Cost Budget Entry";
        AmountType: Enum "Account Schedule Amount Type";
        TestBalance: Boolean;
        Balance: Decimal;
        AmountToAdd: Decimal;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeAddCostTypeDimensions(CostType, AccSchedLine, ColumnLayout, AccSchedKPIBuffer, IsHandled, TempAccSchedKPIBuffer);
        if IsHandled then
            exit;

        if ConflictAmountType(AccSchedLine, ColumnLayout."Amount Type", AmountType) then
            exit;

        TestBalance := AccSchedLine.Show in
          [AccSchedLine.Show::"When Negative Balance", AccSchedLine.Show::"When Positive Balance"];
        if ColumnLayout."Ledger Entry Type" = ColumnLayout."Ledger Entry Type"::Entries then begin
            if CostType.Totaling = '' then
                CostEntry.SetRange("Cost Type No.", CostType."No.")
            else
                CostEntry.SetFilter("Cost Type No.", CostType.Totaling);
            CostType.CopyFilter("Date Filter", CostEntry."Posting Date");
            AccSchedLine.CopyFilter("Cost Center Filter", CostEntry."Cost Center Code");
            AccSchedLine.CopyFilter("Cost Object Filter", CostEntry."Cost Object Code");
            CostEntry.FilterGroup(2);
            CostEntry.SetFilter(
              CostEntry."Cost Center Code",
              AccSchedManagement.GetDimTotalingFilter(5, AccSchedLine."Cost Center Totaling"));
            CostEntry.SetFilter(
              CostEntry."Cost Object Code",
              AccSchedManagement.GetDimTotalingFilter(6, AccSchedLine."Cost Object Totaling"));
            CostEntry.FilterGroup(0);

            case AmountType of
                AmountType::"Net Amount":
                    begin
                        CostEntry.CalcSums(Amount);
                        AmountToAdd := CostEntry.Amount;
                        Balance := AmountToAdd;
                    end;
                AmountType::"Debit Amount":
                    begin
                        if TestBalance then begin
                            CostEntry.CalcSums("Debit Amount", Amount);
                            Balance := CostEntry.Amount;
                        end else
                            CostEntry.CalcSums("Debit Amount");
                        AmountToAdd := CostEntry."Debit Amount";
                    end;
                AmountType::"Credit Amount":
                    begin
                        if TestBalance then begin
                            CostEntry.CalcSums("Credit Amount", Amount);
                            Balance := CostEntry.Amount;
                        end else
                            CostEntry.CalcSums("Credit Amount");
                        AmountToAdd := CostEntry."Credit Amount";
                    end;
            end;
            if not TestBalance then
                CheckAddDimsToResult(AccSchedKPIBuffer, ColumnLayout, 0, AmountToAdd)
            else
                if PassToResult(AccSchedLine.Show, Balance) then
                    CheckAddDimsToResult(AccSchedKPIBuffer, ColumnLayout, 0, AmountToAdd);
        end;

        if ColumnLayout."Ledger Entry Type" = ColumnLayout."Ledger Entry Type"::"Budget Entries" then begin
            CostBudgetEntry.SetCurrentKey("Budget Name", "Cost Type No.", "Cost Center Code", "Cost Object Code", Date);
            if CostType.Totaling = '' then
                CostBudgetEntry.SetRange("Cost Type No.", CostType."No.")
            else
                CostBudgetEntry.SetFilter("Cost Type No.", CostType.Totaling);
            CostType.CopyFilter("Date Filter", CostBudgetEntry.Date);
            AccSchedLine.CopyFilter("Cost Budget Filter", CostBudgetEntry."Budget Name");
            AccSchedLine.CopyFilter("Cost Center Filter", CostBudgetEntry."Cost Center Code");
            AccSchedLine.CopyFilter("Cost Object Filter", CostBudgetEntry."Cost Object Code");
            CostBudgetEntry.FilterGroup(2);
            CostBudgetEntry.SetFilter("Cost Center Code", AccSchedManagement.GetDimTotalingFilter(5, AccSchedLine."Cost Center Totaling"));
            CostBudgetEntry.SetFilter("Cost Object Code", AccSchedManagement.GetDimTotalingFilter(6, AccSchedLine."Cost Object Totaling"));
            CostBudgetEntry.FilterGroup(0);
            CostBudgetEntry.CalcSums(Amount);
            case AmountType of
                AmountType::"Net Amount":
                    AmountToAdd := CostBudgetEntry.Amount;
                AmountType::"Debit Amount":
                    if CostBudgetEntry.Amount > 0 then
                        AmountToAdd := CostBudgetEntry.Amount;
                AmountType::"Credit Amount":
                    if CostBudgetEntry.Amount < 0 then
                        AmountToAdd := CostBudgetEntry.Amount;
            end;
            if not TestBalance then
                CheckAddDimsToResult(AccSchedKPIBuffer, ColumnLayout, 0, AmountToAdd)
            else
                if PassToResult(AccSchedLine.Show, CostBudgetEntry.Amount) then
                    CheckAddDimsToResult(AccSchedKPIBuffer, ColumnLayout, 0, AmountToAdd);
        end;
    end;

    local procedure AddCFAccountDimensions(var CFAccount: Record "Cash Flow Account"; var AccSchedLine: Record "Acc. Schedule Line"; ColumnLayout: Record "Column Layout"; var AccSchedKPIBuffer: Record "Acc. Sched. KPI Buffer")
    var
        AnalysisViewEntry: Record "Analysis View Entry";
        CFForecastEntryDimensions: Query "CF Forecast Entry Dimensions";
        AnalysisViewEntryDimensions: Query "Analysis View Entry Dimensions";
        FilterText: Text;
        AmountType: Enum "Account Schedule Amount Type";
        AmountToAdd: Decimal;
    begin
        if ConflictAmountType(AccSchedLine, ColumnLayout."Amount Type", AmountType) then
            exit;

        if ColumnLayout."Ledger Entry Type" = ColumnLayout."Ledger Entry Type"::Entries then
            if AccSchedName."Analysis View Name" = '' then begin
                if CFAccount.Totaling = '' then
                    CFForecastEntryDimensions.SetRange(Cash_Flow_Account_No, CFAccount."No.")
                else
                    CFForecastEntryDimensions.SetFilter(Cash_Flow_Account_No, CFAccount.Totaling);

                CFForecastEntryDimensions.SetFilter(Cash_Flow_Date, CFAccount.GetFilter("Date Filter"));
                CFForecastEntryDimensions.SetFilter(
                  Cash_Flow_Forecast_No, AccSchedLine.GetFilter("Cash Flow Forecast Filter"));

                FilterText := CombineFilters(
                    AccSchedLine.GetFilter("Dimension 1 Filter"), AccSchedLine."Dimension 1 Totaling", '&');
                CFForecastEntryDimensions.SetFilter(Global_Dimension_1_Code, FilterText);

                FilterText := CombineFilters(
                    AccSchedLine.GetFilter("Dimension 2 Filter"), AccSchedLine."Dimension 2 Totaling", '&');
                CFForecastEntryDimensions.SetFilter(Global_Dimension_2_Code, FilterText);

                CFForecastEntryDimensions.Open();
                while CFForecastEntryDimensions.Read() do begin
                    if AmountType = AmountType::"Net Amount" then
                        AmountToAdd := CFForecastEntryDimensions.Sum_Amount_LCY
                    else
                        AmountToAdd := 0;
                    CheckAddDimsToResult(
                      AccSchedKPIBuffer, ColumnLayout, CFForecastEntryDimensions.Dimension_Set_ID,
                      AmountToAdd);
                end;
                CFForecastEntryDimensions.Close();
            end else begin
                if CFAccount.Totaling = '' then
                    FilterText := CFAccount."No."
                else
                    FilterText := CFAccount.Totaling;

                FilterAnalysisViewEntriesDim(
                  AnalysisViewEntryDimensions, AccSchedName."Analysis View Name",
                  AnalysisViewEntry."Account Source"::"Cash Flow Account", FilterText,
                  CFAccount.GetFilter("Date Filter"), AccSchedLine);
                AnalysisViewEntryDimensions.SetFilter(
                  Cash_Flow_Forecast_No, AccSchedLine.GetFilter("Cash Flow Forecast Filter"));

                AnalysisViewEntryDimensions.Open();
                while AnalysisViewEntryDimensions.Read() do begin
                    if AmountType = AmountType::"Net Amount" then
                        AmountToAdd := AnalysisViewEntryDimensions.Sum_Amount
                    else
                        AmountToAdd := 0;
                    CheckAddDimsToResult(AccSchedKPIBuffer, ColumnLayout, 0, AmountToAdd);
                end;
                AnalysisViewEntryDimensions.Close();
            end;
    end;

    local procedure EvalExprWithDimensions(Expression: Text[250]; AccSchedLine: Record "Acc. Schedule Line"; ColumnLayout: Record "Column Layout"; var AccSchedKPIBuffer: Record "Acc. Sched. KPI Buffer")
    var
        TempAccSchedKPIBufferDim: Record "Acc. Sched. KPI Buffer" temporary;
        SrcAccSchedLineFilter: Text;
        Value: Decimal;
    begin
        SrcAccSchedLineFilter := GetAccSchedLineFormulaFilter(Expression, AccSchedLine);
        GetExpressionDimensions(AccSchedKPIBuffer, TempAccSchedKPIBufferDim, SrcAccSchedLineFilter);
        if TempAccSchedKPIBufferDim.FindSet() then
            repeat
                Value :=
                  EvalExprWithDimFilter(TempAccSchedKPIBufferDim."Dimension Set ID", Expression, AccSchedLine, ColumnLayout, AccSchedKPIBuffer);
                CheckAddDimsToResult(
                  AccSchedKPIBuffer, ColumnLayout, TempAccSchedKPIBufferDim."Dimension Set ID", Value);
            until TempAccSchedKPIBufferDim.Next() = 0;
    end;

    local procedure GetExpressionDimensions(var TempAccSchedKPIBufferExisting: Record "Acc. Sched. KPI Buffer" temporary; var TempAccSchedKPIBufferResulting: Record "Acc. Sched. KPI Buffer" temporary; LineFilter: Text)
    begin
        TempAccSchedKPIBufferExisting.SetFilter(TempAccSchedKPIBufferExisting."KPI Code", LineFilter);
        if TempAccSchedKPIBufferExisting.FindSet() then
            repeat
                if (TempAccSchedKPIBufferExisting."Net Change Actual" <> 0) or (TempAccSchedKPIBufferExisting."Balance at Date Actual" <> 0) or
                   (TempAccSchedKPIBufferExisting."Net Change Budget" <> 0) or (TempAccSchedKPIBufferExisting."Balance at Date Budget" <> 0) or
                   (TempAccSchedKPIBufferExisting."Net Change Actual Last Year" <> 0) or (TempAccSchedKPIBufferExisting."Balance at Date Act. Last Year" <> 0) or
                   (TempAccSchedKPIBufferExisting."Net Change Budget Last Year" <> 0) or (TempAccSchedKPIBufferExisting."Balance at Date Bud. Last Year" <> 0)
                then
                    AddDimsToBuffer(TempAccSchedKPIBufferResulting, TempAccSchedKPIBufferExisting."Dimension Set ID")
            until TempAccSchedKPIBufferExisting.Next() = 0;
        TempAccSchedKPIBufferExisting.SetRange("KPI Code");
    end;

    local procedure GetCellValueWithDimFilter(var TempAccSchedKPIBufferExisting: Record "Acc. Sched. KPI Buffer" temporary; AccSchedLine: Record "Acc. Schedule Line"; ColumnLayout: Record "Column Layout"; DimSetID: Integer) Result: Decimal
    begin
        TempAccSchedKPIBufferExisting.SetRange("Account Schedule Name", AccSchedLine."Schedule Name");
        TempAccSchedKPIBufferExisting.SetRange("KPI Code", AccSchedLine."Row No.");
        TempAccSchedKPIBufferExisting.SetRange("Dimension Set ID", DimSetID);
        if TempAccSchedKPIBufferExisting.FindFirst() then
            Result := TempAccSchedKPIBufferExisting.GetColumnValue(ColumnLayout);

        TempAccSchedKPIBufferExisting.SetRange("Account Schedule Name");
        TempAccSchedKPIBufferExisting.SetRange("KPI Code");
        TempAccSchedKPIBufferExisting.SetRange("Dimension Set ID");
    end;

    local procedure GetAccSchedLineFormulaFilter(Expression: Text; AccSchedLine: Record "Acc. Schedule Line") ResultingFilter: Text
    var
        FilterPart: Text;
        i: Integer;
        j: Integer;
        IsFilter: Boolean;
        FoundFilterPart: Boolean;
    begin
        Expression := DelChr(Expression, '<>', ' ');
        if StrLen(Expression) > 0 then begin
            Expression := ConvertStr(Expression, '+-*/^%()', ';;;;;;;;');
            i := StrLen(Expression);
            while i > 0 do begin
                if Expression[i] <> ';' then begin
                    FoundFilterPart := false;
                    j := i - 1;
                    repeat
                        if j = 0 then
                            FoundFilterPart := true;
                        if not FoundFilterPart then
                            FoundFilterPart := Expression[j] = ';';

                        if FoundFilterPart then begin
                            FilterPart := CopyStr(Expression, j + 1, i - j);
                            AccSchedLine.SetRange("Schedule Name", AccSchedLine."Schedule Name");
                            AccSchedLine.SetFilter("Row No.", FilterPart);
                            IsFilter :=
                              (StrPos(FilterPart, '..') +
                               StrPos(FilterPart, '|') +
                               StrPos(FilterPart, '<') +
                               StrPos(FilterPart, '>') +
                               StrPos(FilterPart, '&') +
                               StrPos(FilterPart, '=') > 0);
                            if (StrLen(FilterPart) <= 10) or IsFilter then
                                if AccSchedLine.FindFirst() then
                                    ResultingFilter := CombineFilters(ResultingFilter, FilterPart, '|');
                            i := j;
                        end else
                            j -= 1;
                    until FoundFilterPart;
                end;
                i -= 1;
            end;
        end;
    end;

    local procedure EvalExprWithDimFilter(DimSetID: Integer; Expression: Text[250]; AccSchedLine: Record "Acc. Schedule Line"; ColumnLayout: Record "Column Layout"; var ExistingAccSchedKPIBuffer: Record "Acc. Sched. KPI Buffer"): Decimal
    var
        Result: Decimal;
        Parantheses: Integer;
        Operator: Char;
        LeftOperand: Text[250];
        RightOperand: Text[250];
        LeftResult: Decimal;
        RightResult: Decimal;
        i: Integer;
        IsExpression: Boolean;
        IsFilter: Boolean;
        Operators: Text[8];
        OperatorNo: Integer;
        AccSchedLineID: Integer;
    begin
        Result := 0;

        CallLevel := CallLevel + 1;
        if CallLevel > 25 then
            ShowError(CircularRefErr, AccSchedLine, ColumnLayout);

        Expression := DelChr(Expression, '<>', ' ');
        if StrLen(Expression) > 0 then begin
            Parantheses := 0;
            IsExpression := false;
            Operators := '+-*/^%';
            OperatorNo := 1;
            repeat
                i := StrLen(Expression);
                repeat
                    if Expression[i] = '(' then
                        Parantheses := Parantheses + 1
                    else
                        if Expression[i] = ')' then
                            Parantheses := Parantheses - 1;
                    if (Parantheses = 0) and (Expression[i] = Operators[OperatorNo]) then
                        IsExpression := true
                    else
                        i := i - 1;
                until IsExpression or (i <= 0);
                if not IsExpression then
                    OperatorNo := OperatorNo + 1;
            until (OperatorNo > StrLen(Operators)) or IsExpression;
            if IsExpression then begin
                if i > 1 then
                    LeftOperand := CopyStr(Expression, 1, i - 1)
                else
                    LeftOperand := '';
                if i < StrLen(Expression) then
                    RightOperand := CopyStr(Expression, i + 1)
                else
                    RightOperand := '';
                Operator := Expression[i];
                LeftResult :=
                  EvalExprWithDimFilter(
                    DimSetID, LeftOperand, AccSchedLine, ColumnLayout, ExistingAccSchedKPIBuffer);
                RightResult :=
                  EvalExprWithDimFilter(
                    DimSetID, RightOperand, AccSchedLine, ColumnLayout, ExistingAccSchedKPIBuffer);
                case Operator of
                    '^':
                        Result := Power(LeftResult, RightResult);
                    '%':
                        if RightResult = 0 then // Division Error
                            Result := 0
                        else
                            Result := 100 * LeftResult / RightResult;
                    '*':
                        Result := LeftResult * RightResult;
                    '/':
                        if RightResult = 0 then // Division Error
                            Result := 0
                        else
                            Result := LeftResult / RightResult;
                    '+':
                        Result := LeftResult + RightResult;
                    '-':
                        Result := LeftResult - RightResult;
                end;
            end else
                if (Expression[1] = '(') and (Expression[StrLen(Expression)] = ')') then
                    Result :=
                      EvalExprWithDimFilter(
                        DimSetID, CopyStr(Expression, 2, StrLen(Expression) - 2),
                        AccSchedLine, ColumnLayout, ExistingAccSchedKPIBuffer)
                else begin
                    IsFilter :=
                      (StrPos(Expression, '..') +
                       StrPos(Expression, '|') +
                       StrPos(Expression, '<') +
                       StrPos(Expression, '>') +
                       StrPos(Expression, '&') +
                       StrPos(Expression, '=') > 0);
                    if (StrLen(Expression) > 10) and (not IsFilter) then
                        Evaluate(Result, Expression)
                    else begin
                        AccSchedLine.SetRange("Schedule Name", AccSchedLine."Schedule Name");
                        AccSchedLine.SetFilter("Row No.", Expression);
                        AccSchedLineID := AccSchedLine."Line No.";
                        if AccSchedLine.Find('-') then
                            repeat
                                if AccSchedLine."Line No." <> AccSchedLineID then
                                    Result +=
                                      GetCellValueWithDimFilter(ExistingAccSchedKPIBuffer, AccSchedLine, ColumnLayout, DimSetID);
                            until AccSchedLine.Next() = 0
                        else
                            if IsFilter or (not Evaluate(Result, Expression)) then
                                ShowError(IllegalValErr, AccSchedLine, ColumnLayout);
                    end;
                end;
        end;
        CallLevel := CallLevel - 1;
        exit(Result);
    end;

    local procedure ShowError(MessageLine: Text[100]; var AccSchedLine: Record "Acc. Schedule Line"; var ColumnLayout: Record "Column Layout")
    begin
        AccSchedLine.SetRange("Schedule Name", AccSchedLine."Schedule Name");
        AccSchedLine.SetRange("Line No.", CallingAccSchedLineID);
        if AccSchedLine.FindFirst() then;
        ColumnLayout.SetRange("Column Layout Name", ColumnLayout."Column Layout Name");
        ColumnLayout.SetRange("Line No.", CallingColumnLayoutID);
        if ColumnLayout.FindFirst() then;
        Error(GeneralErr,
          MessageLine,
          ErrorOccurredErr,
          StrSubstNo(AccSchedLineErr, AccSchedLine."Row No.", AccSchedLine."Line No.", AccSchedLine.Totaling),
          StrSubstNo(ColumnErr, ColumnLayout."Column No.", ColumnLayout."Line No.", ColumnLayout.Formula));
    end;

    procedure ConflictAmountType(AccSchedLine: Record "Acc. Schedule Line"; ColumnLayoutAmtType: Enum "Account Schedule Amount Type"; var AmountType: Enum "Account Schedule Amount Type"): Boolean
    begin
        if (ColumnLayoutAmtType = AccSchedLine."Amount Type") or
           (AccSchedLine."Amount Type" = AccSchedLine."Amount Type"::"Net Amount")
        then
            AmountType := ColumnLayoutAmtType
        else
            if ColumnLayoutAmtType = ColumnLayoutAmtType::"Net Amount" then
                AmountType := AccSchedLine."Amount Type"
            else
                exit(true);
        exit(false);
    end;

    procedure CombineFilters(FilterPart1: Text; FilterPart2: Text; CombineSymbol: Text[1]): Text
    begin
        PrepareFilterPart(FilterPart1);
        PrepareFilterPart(FilterPart2);

        if (FilterPart1 <> '') and (FilterPart2 <> '') then
            exit(StrSubstNo('%1%2%3', FilterPart1, CombineSymbol, FilterPart2));

        if FilterPart1 <> '' then
            exit(FilterPart1);

        if FilterPart2 <> '' then
            exit(FilterPart2);

        exit('');
    end;

    procedure PrepareFilterPart(var FilterText: Text)
    begin
        FilterText := DelChr(FilterText, '<>', ' ');
        if FilterText <> '' then
            if (FilterText[1] <> '(') and (FilterText[StrLen(FilterText)] <> ')') then
                FilterText := StrSubstNo('(%1)', FilterText);
    end;

    local procedure CheckAddDimsToResult(var AccSchedKPIBuffer: Record "Acc. Sched. KPI Buffer"; ColumnLayout: Record "Column Layout"; DimensionSetID: Integer; Amount: Decimal)
    begin
        if Amount = 0 then
            exit;

        AccSchedKPIBuffer.SetRange("Account Schedule Name", TempAccSchedKPIBuffer."Account Schedule Name");
        AccSchedKPIBuffer.SetRange("KPI Code", TempAccSchedKPIBuffer."KPI Code");
        AccSchedKPIBuffer.SetRange("Dimension Set ID", DimensionSetID);
        if not AccSchedKPIBuffer.FindFirst() then begin
            AccSchedKPIBuffer.Reset();
            if AccSchedKPIBuffer.FindLast() then;
            AccSchedKPIBuffer.Init();
            AccSchedKPIBuffer."No." += 1;
            AccSchedKPIBuffer.Date := TempAccSchedKPIBuffer.Date;
            AccSchedKPIBuffer."Closed Period" := TempAccSchedKPIBuffer."Closed Period";
            AccSchedKPIBuffer."Account Schedule Name" := TempAccSchedKPIBuffer."Account Schedule Name";
            AccSchedKPIBuffer."KPI Code" := TempAccSchedKPIBuffer."KPI Code";
            AccSchedKPIBuffer."KPI Name" := TempAccSchedKPIBuffer."KPI Name";
            AccSchedKPIBuffer."Dimension Set ID" := DimensionSetID;
            AccSchedKPIBuffer.AddColumnValue(ColumnLayout, Amount);
            AccSchedKPIBuffer.Insert();
        end else begin
            AccSchedKPIBuffer.AddColumnValue(ColumnLayout, Amount);
            AccSchedKPIBuffer.Modify();
        end;
        AccSchedKPIBuffer.SetRange("Account Schedule Name");
        AccSchedKPIBuffer.SetRange("KPI Code");
        AccSchedKPIBuffer.SetRange("Dimension Set ID");
    end;

    local procedure AddDimsToBuffer(var TempAccSchedKPIBufferResulting: Record "Acc. Sched. KPI Buffer" temporary; DimensionSetID: Integer)
    begin
        TempAccSchedKPIBufferResulting.SetRange("Dimension Set ID", DimensionSetID);
        if not TempAccSchedKPIBufferResulting.FindFirst() then begin
            TempAccSchedKPIBufferResulting.Reset();
            if TempAccSchedKPIBufferResulting.FindLast() then;
            TempAccSchedKPIBufferResulting."No." += 1;
            TempAccSchedKPIBufferResulting."Dimension Set ID" := DimensionSetID;
            TempAccSchedKPIBufferResulting.Insert();
        end;
        TempAccSchedKPIBufferResulting.SetRange("Dimension Set ID");
    end;

    procedure PostProcessAmount(AccSchedLine: Record "Acc. Schedule Line"; Amount: Decimal): Decimal
    begin
        if AccSchedLine."Show Opposite Sign" then
            exit(-Amount);
        exit(Amount);
    end;

    procedure PassToResult(AccSchedLineShow: Enum "Acc. Schedule Line Show"; Balance: Decimal) BalanceIsOK: Boolean
    begin
        BalanceIsOK := true;
        case AccSchedLineShow of
            AccSchedLineShow::"When Positive Balance":
                if Balance > 0 then
                    BalanceIsOK := true
                else
                    BalanceIsOK := false;
            AccSchedLineShow::"When Negative Balance":
                if Balance < 0 then
                    BalanceIsOK := true
                else
                    BalanceIsOK := false;
        end;
        exit(BalanceIsOK);
    end;

    local procedure FilterAnalysisViewEntriesDim(var AnalysisViewEntryDimensions: Query "Analysis View Entry Dimensions"; AnalysisViewName: Code[10]; AccountSource: Enum "Analysis Account Source"; AccountFilter: Text; DateFilter: Text; AccScheduleLine2: Record "Acc. Schedule Line")
    begin
        AnalysisViewEntryDimensions.SetRange(Analysis_View_Code, AnalysisViewName);
        AnalysisViewEntryDimensions.SetRange(Account_Source, AccountSource);
        AnalysisViewEntryDimensions.SetFilter(Account_No, AccountFilter);
        AnalysisViewEntryDimensions.SetFilter(Business_Unit_Code, AccScheduleLine2.GetFilter("Business Unit Filter"));
        AnalysisViewEntryDimensions.SetFilter(Posting_Date, DateFilter);

        AnalysisViewEntryDimensions.SetFilter(Dimension_1_Value_Code,
          CombineFilters(
            AccScheduleLine2.GetFilter("Dimension 1 Filter"),
            AccSchedManagement.GetDimTotalingFilter(1, AccScheduleLine2."Dimension 1 Totaling"), '&'));
        AnalysisViewEntryDimensions.SetFilter(Dimension_2_Value_Code,
          CombineFilters(
            AccScheduleLine2.GetFilter("Dimension 2 Filter"),
            AccSchedManagement.GetDimTotalingFilter(2, AccScheduleLine2."Dimension 2 Totaling"), '&'));
        AnalysisViewEntryDimensions.SetFilter(Dimension_3_Value_Code,
          CombineFilters(
            AccScheduleLine2.GetFilter("Dimension 3 Filter"),
            AccSchedManagement.GetDimTotalingFilter(3, AccScheduleLine2."Dimension 3 Totaling"), '&'));
        AnalysisViewEntryDimensions.SetFilter(Dimension_4_Value_Code,
          CombineFilters(
            AccScheduleLine2.GetFilter("Dimension 4 Filter"),
            AccSchedManagement.GetDimTotalingFilter(4, AccScheduleLine2."Dimension 4 Totaling"), '&'));
    end;

    procedure SetTempAccSchedKPIBuffer(var NewTempAccSchedKPIBuffer: Record "Acc. Sched. KPI Buffer" temporary)
    begin
        TempAccSchedKPIBuffer.Copy(NewTempAccSchedKPIBuffer, true);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeAddCostTypeDimensions(var CostType: Record "Cost Type"; var AccSchedLine: Record "Acc. Schedule Line"; ColumnLayout: Record "Column Layout"; var AccSchedKPIBuffer: Record "Acc. Sched. KPI Buffer"; var IsHandled: Boolean; var TempAccSchedKPIBuffer: Record "Acc. Sched. KPI Buffer" temporary)
    begin
    end;
}

