// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.FinancialReports;

using Microsoft.Foundation.Enums;

/// <summary>
/// Manages trial balance data loading, navigation, and drill-down functionality.
/// Provides management layer for trial balance interface operations and period navigation.
/// </summary>
/// <remarks>
/// Management codeunit for trial balance page functionality. Handles data loading from account
/// schedules, period navigation controls, and drill-down operations into detailed ledger entries.
/// Coordinates with account schedule management for calculation and formatting operations.
/// </remarks>
codeunit 1318 "Trial Balance Mgt."
{

    trigger OnRun()
    begin
    end;

    var
        ColumnLayoutArr: array[9, 2] of Record "Column Layout";
        AccScheduleLineArr: array[9] of Record "Acc. Schedule Line";
        AccScheduleLine: Record "Acc. Schedule Line";
        TempColumnLayout: Record "Column Layout" temporary;
        AccSchedManagement: Codeunit AccSchedManagement;
        PeriodType: Enum "Analysis Period Type";
        CurrentColumnLayoutName: Code[10];
        CurrentAccScheduleName: Code[10];
        LessRowsThanExpectedErr: Label 'The Trial Balance chart is not set up correctly. There are fewer rows in the account schedules than expected.';
        MoreRowsThanExpectedErr: Label 'The Trial Balance chart is not set up correctly. There are more rows in the account schedules than expected.';

    /// <summary>
    /// Loads trial balance data into display arrays for interface presentation.
    /// Initializes period settings and populates arrays with account schedule calculations.
    /// </summary>
    /// <param name="DescriptionsArr">Array of account descriptions to populate</param>
    /// <param name="ValuesArr">Array of account values to populate</param>
    /// <param name="PeriodCaptionTxt">Array of period captions to populate</param>
    /// <param name="NoOfColumns">Number of columns to display</param>
    procedure LoadData(var DescriptionsArr: array[9] of Text[100]; var ValuesArr: array[9, 2] of Decimal; var PeriodCaptionTxt: array[2] of Text; NoOfColumns: Integer)
    begin
        PeriodType := PeriodType::"Accounting Period";
        Initialize();
        AccSchedManagement.FindPeriod(AccScheduleLine, '', PeriodType);
        UpdateArrays(DescriptionsArr, ValuesArr, PeriodCaptionTxt, NoOfColumns);
    end;

    /// <summary>
    /// Checks whether trial balance setup is properly configured.
    /// Validates existence of required account schedule and column layout configurations.
    /// </summary>
    /// <returns>True if setup is complete, false if configuration is missing</returns>
    procedure SetupIsInPlace(): Boolean
    var
        TrialBalanceSetup: Record "Trial Balance Setup";
    begin
        if not TrialBalanceSetup.Get() then
            exit(false);
        if TrialBalanceSetup."Account Schedule Name" = '' then
            exit(false);
        if TrialBalanceSetup."Column Layout Name" = '' then
            exit(false);
        exit(true);
    end;

    local procedure Initialize()
    var
        TrialBalanceSetup: Record "Trial Balance Setup";
    begin
        OnBeforeInitialize();

        TrialBalanceSetup.Get();
        TrialBalanceSetup.TestField("Account Schedule Name");
        TrialBalanceSetup.TestField("Column Layout Name");

        CurrentColumnLayoutName := TrialBalanceSetup."Column Layout Name";
        CurrentAccScheduleName := TrialBalanceSetup."Account Schedule Name";

        AccSchedManagement.CopyColumnsToTemp(CurrentColumnLayoutName, TempColumnLayout);
        AccSchedManagement.OpenSchedule(CurrentAccScheduleName, AccScheduleLine);
        AccSchedManagement.OpenColumns(CurrentColumnLayoutName, TempColumnLayout);
        AccSchedManagement.CheckAnalysisView(CurrentAccScheduleName, CurrentColumnLayoutName, true);
    end;

    local procedure UpdateArrays(var DescriptionsArr: array[9] of Text[100]; var ValuesArr: array[9, 2] of Decimal; var PeriodCaptionTxt: array[2] of Text; NoOfColumns: Integer)
    var
        Offset: Integer;
        Counter: Integer;
        FromDate: Date;
        ToDate: Date;
        FiscalStartDate: Date;
        I: Integer;
        TempNoOfColumns: Integer;
    begin
        Clear(PeriodCaptionTxt);
        Counter := 0;

        if AccScheduleLine.FindSet() then
            repeat
                Counter := Counter + 1;
                if Counter > ArrayLen(ValuesArr, 1) then
                    Error(MoreRowsThanExpectedErr);

                DescriptionsArr[Counter] := AccScheduleLine.Description;

                if NoOfColumns = 1 then
                    Offset := 1
                else
                    Offset := 2;

                if NoOfColumns > Offset then
                    TempNoOfColumns := Offset
                else
                    TempNoOfColumns := NoOfColumns;

                if AccScheduleLine.Totaling = '' then
                    for I := Offset - NoOfColumns + 1 to Offset do
                        ValuesArr[Counter, I] := 0;

                if TempColumnLayout.FindSet() then
                    repeat
                        ValuesArr[Counter, Offset] := AccSchedManagement.CalcCell(AccScheduleLine, TempColumnLayout, false);
                        ColumnLayoutArr[Counter, Offset] := TempColumnLayout;
                        AccScheduleLineArr[Counter] := AccScheduleLine;
                        AccSchedManagement.CalcColumnDates(TempColumnLayout, FromDate, ToDate, FiscalStartDate);
                        PeriodCaptionTxt[Offset] := StrSubstNo('%1: %2..%3', TempColumnLayout."Column Header", FromDate, ToDate);
                        Offset := Offset - 1;
                        TempNoOfColumns := TempNoOfColumns - 1;
                    until (TempColumnLayout.Next() = 0) or (TempNoOfColumns = 0);
            until AccScheduleLine.Next() = 0;

        OnUpdateArraysOnBeforeCheckArrayLen(Counter);
        if Counter < ArrayLen(ValuesArr, 1) then
            Error(LessRowsThanExpectedErr);
    end;

    /// <summary>
    /// Performs drill-down operation on trial balance data for detailed analysis.
    /// Opens detailed ledger entries for the selected account and period combination.
    /// </summary>
    /// <param name="RowNo">Row number in trial balance matrix</param>
    /// <param name="ColumnNo">Column number in trial balance matrix</param>
    procedure DrillDown(RowNo: Integer; ColumnNo: Integer)
    begin
        TempColumnLayout := ColumnLayoutArr[RowNo, ColumnNo];
        AccScheduleLine := AccScheduleLineArr[RowNo];
        AccSchedManagement.DrillDown(TempColumnLayout, AccScheduleLine, "Analysis Period Type"::Month.AsInteger());
    end;

    /// <summary>
    /// Navigates to the next period and updates trial balance data arrays.
    /// Advances the current period and recalculates all displayed values.
    /// </summary>
    /// <param name="DescriptionsArr">Array of account descriptions to update</param>
    /// <param name="ValuesArr">Array of account values to update</param>
    /// <param name="PeriodCaptionTxt">Array of period captions to update</param>
    /// <param name="NoOfColumns">Number of columns to display</param>
    procedure NextPeriod(var DescriptionsArr: array[9] of Text[100]; var ValuesArr: array[9, 2] of Decimal; var PeriodCaptionTxt: array[2] of Text; NoOfColumns: Integer)
    begin
        UpdatePeriod(DescriptionsArr, ValuesArr, PeriodCaptionTxt, '>=', NoOfColumns);
    end;

    /// <summary>
    /// Navigates to the previous period and updates trial balance data arrays.
    /// Moves back to the previous period and recalculates all displayed values.
    /// </summary>
    /// <param name="DescriptionsArr">Array of account descriptions to update</param>
    /// <param name="ValuesArr">Array of account values to update</param>
    /// <param name="PeriodCaptionTxt">Array of period captions to update</param>
    /// <param name="NoOfColumns">Number of columns to display</param>
    procedure PreviousPeriod(var DescriptionsArr: array[9] of Text[100]; var ValuesArr: array[9, 2] of Decimal; var PeriodCaptionTxt: array[2] of Text; NoOfColumns: Integer)
    begin
        UpdatePeriod(DescriptionsArr, ValuesArr, PeriodCaptionTxt, '<=', NoOfColumns);
    end;

    local procedure UpdatePeriod(var DescriptionsArr: array[9] of Text[100]; var ValuesArr: array[9, 2] of Decimal; var PeriodCaptionTxt: array[2] of Text; SearchText: Text[3]; NoOfColumns: Integer)
    begin
        AccSchedManagement.FindPeriod(AccScheduleLine, SearchText, PeriodType);
        UpdateArrays(DescriptionsArr, ValuesArr, PeriodCaptionTxt, NoOfColumns);
    end;

    /// <summary>
    /// Integration event raised before initializing trial balance setup and configuration.
    /// Allows customization of trial balance initialization process.
    /// </summary>
    [IntegrationEvent(true, false)]
    local procedure OnBeforeInitialize()
    begin
    end;

    /// <summary>
    /// Integration event raised during array updates before checking array length validation.
    /// Allows custom processing during trial balance data array population.
    /// </summary>
    /// <param name="Counter">Current array counter position</param>
    [IntegrationEvent(false, false)]
    local procedure OnUpdateArraysOnBeforeCheckArrayLen(Counter: Integer)
    begin
    end;
}

