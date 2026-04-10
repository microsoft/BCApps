// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.FinancialReports;

/// <summary>
/// Temporary buffer table for account schedule KPI data aggregation and analysis.
/// Stores calculated financial metrics including actual, budget, and forecast values for KPI reporting.
/// </summary>
/// <remarks>
/// Primary usage: KPI calculation processing, financial data aggregation for dashboards.
/// Integration: Links with Account Schedule system and dimension analysis functionality.
/// Extensibility: Standard table extension patterns for additional KPI metrics and calculation methods.
/// </remarks>
table 197 "Acc. Sched. KPI Buffer"
{
    Caption = 'Acc. Sched. KPI Buffer';
    ReplicateData = false;
    DataClassification = CustomerContent;

    fields
    {
        /// <summary>
        /// Sequential record number for buffer table organization and identification.
        /// </summary>
        field(1; "No."; Integer)
        {
            Caption = 'No.';
            ToolTip = 'Specifies the number of the involved entry or record, according to the specified number series.';
            DataClassification = SystemMetadata;
        }
        /// <summary>
        /// Date associated with the KPI calculation period for temporal analysis.
        /// </summary>
        field(2; Date; Date)
        {
            Caption = 'Date';
            ToolTip = 'Specifies the date on which the KPI figures are calculated.';
            DataClassification = SystemMetadata;
        }
        /// <summary>
        /// Indicates whether the period is closed for preventing further modifications.
        /// </summary>
        field(3; "Closed Period"; Boolean)
        {
            Caption = 'Closed Period';
            ToolTip = 'Specifies whether the fiscal year is closed.';
            DataClassification = SystemMetadata;
        }
        /// <summary>
        /// Account schedule name identifying the source template for KPI calculations.
        /// </summary>
        field(4; "Account Schedule Name"; Code[10])
        {
            Caption = 'Row Definition Name';
            ToolTip = 'Specifies the name of the account schedule that the KPI web service is based on.';
            DataClassification = SystemMetadata;
        }
        /// <summary>
        /// KPI identifier code for tracking specific performance indicators within the system.
        /// </summary>
        field(5; "KPI Code"; Code[10])
        {
            Caption = 'KPI Code';
            ToolTip = 'Specifies a code for the financial report KPI web service.';
            DataClassification = SystemMetadata;
        }
        /// <summary>
        /// Descriptive name of the KPI for display and identification purposes.
        /// </summary>
        field(6; "KPI Name"; Text[50])
        {
            Caption = 'KPI Name';
            ToolTip = 'Specifies a name of the account-schedule KPI web service.';
            DataClassification = SystemMetadata;
        }
        /// <summary>
        /// Net change amount for actual transactions within the calculation period.
        /// </summary>
        field(7; "Net Change Actual"; Decimal)
        {
            AutoFormatExpression = '';
            AutoFormatType = 1;
            Caption = 'Net Change Actual';
            ToolTip = 'Specifies changes in the actual general ledger amount, for closed accounting periods, up until the date in the Date field.';
            DataClassification = SystemMetadata;
        }
        /// <summary>
        /// Balance amount for actual transactions as of the calculation date.
        /// </summary>
        field(8; "Balance at Date Actual"; Decimal)
        {
            AutoFormatExpression = '';
            AutoFormatType = 1;
            Caption = 'Balance at Date Actual';
            ToolTip = 'Specifies the actual general ledger balance, based on closed accounting periods, on the date in the Date field.';
            DataClassification = SystemMetadata;
        }
        /// <summary>
        /// Net change amount from budget entries within the calculation period.
        /// </summary>
        field(9; "Net Change Budget"; Decimal)
        {
            AutoFormatExpression = '';
            AutoFormatType = 1;
            Caption = 'Net Change Budget';
            ToolTip = 'Specifies changes in the budgeted general ledger amount, based on the general ledger budget, up until the date in the Date field.';
            DataClassification = SystemMetadata;
        }
        /// <summary>
        /// Balance amount from budget entries as of the calculation date.
        /// </summary>
        field(10; "Balance at Date Budget"; Decimal)
        {
            AutoFormatExpression = '';
            AutoFormatType = 1;
            Caption = 'Balance at Date Budget';
            ToolTip = 'Specifies the budgeted general ledger balance, based on the general ledger budget, on the date in the Date field.';
            DataClassification = SystemMetadata;
        }
        /// <summary>
        /// Net change amount for actual transactions from the corresponding period in the previous year.
        /// </summary>
        field(11; "Net Change Actual Last Year"; Decimal)
        {
            AutoFormatExpression = '';
            AutoFormatType = 1;
            Caption = 'Net Change Actual Last Year';
            ToolTip = 'Specifies actual changes in the general ledger amount, based on closed accounting periods, up until the date in the Date field in the previous accounting year.';
            DataClassification = SystemMetadata;
        }
        /// <summary>
        /// Balance amount for actual transactions as of the corresponding date in the previous year.
        /// </summary>
        field(12; "Balance at Date Act. Last Year"; Decimal)
        {
            AutoFormatExpression = '';
            AutoFormatType = 1;
            Caption = 'Balance at Date Act. Last Year';
            ToolTip = 'Specifies the actual general ledger balance, based on closed accounting periods, on the date in the Date field in the previous accounting year.';
            DataClassification = SystemMetadata;
        }
        /// <summary>
        /// Net change amount from budget entries for the corresponding period in the previous year.
        /// </summary>
        field(13; "Net Change Budget Last Year"; Decimal)
        {
            AutoFormatExpression = '';
            AutoFormatType = 1;
            Caption = 'Net Change Budget Last Year';
            ToolTip = 'Specifies budgeted changes in the general ledger amount, based on the general ledger budget, up until the date in the Date field in the previous year.';
            DataClassification = SystemMetadata;
        }
        /// <summary>
        /// Balance amount from budget entries as of the corresponding date in the previous year.
        /// </summary>
        field(14; "Balance at Date Bud. Last Year"; Decimal)
        {
            AutoFormatExpression = '';
            AutoFormatType = 1;
            Caption = 'Balance at Date Bud. Last Year';
            ToolTip = 'Specifies the budgeted general ledger balance, based on the general ledger budget, on the date in the Date field in the previous accounting year.';
            DataClassification = SystemMetadata;
        }
        /// <summary>
        /// Net change amount from forecast entries within the calculation period.
        /// </summary>
        field(15; "Net Change Forecast"; Decimal)
        {
            AutoFormatExpression = '';
            AutoFormatType = 1;
            Caption = 'Net Change Forecast';
            ToolTip = 'Specifies forecasted changes in the general ledger amount, based on open accounting periods, up until the date in the Date field.';
            DataClassification = SystemMetadata;
        }
        /// <summary>
        /// Balance amount from forecast entries as of the calculation date.
        /// </summary>
        field(16; "Balance at Date Forecast"; Decimal)
        {
            AutoFormatExpression = '';
            AutoFormatType = 1;
            Caption = 'Balance at Date Forecast';
            ToolTip = 'Specifies the forecasted general ledger balance, based on open accounting periods, on the date in the Date field.';
            DataClassification = SystemMetadata;
        }
        /// <summary>
        /// Dimension set identifier for linking KPI data with dimension analysis.
        /// </summary>
        field(17; "Dimension Set ID"; Integer)
        {
            Caption = 'Dimension Set ID';
            ToolTip = 'Specifies a reference to a combination of dimension values. The actual values are stored in the Dimension Set Entry table.';
            DataClassification = SystemMetadata;
        }
    }

    keys
    {
        key(Key1; "No.")
        {
            Clustered = true;
        }
        key(Key2; "Account Schedule Name", "KPI Code", "Dimension Set ID")
        {
        }
    }

    fieldgroups
    {
    }

    /// <summary>
    /// Adds a calculated value to the appropriate KPI field based on column layout configuration.
    /// Determines whether to update actual, budget, forecast, or comparative values.
    /// </summary>
    /// <param name="ColumnLayout">Column layout record defining calculation parameters and data source</param>
    /// <param name="Value">Decimal value to add to the appropriate KPI metric field</param>
    procedure AddColumnValue(ColumnLayout: Record "Column Layout"; Value: Decimal)
    var
        PreviousFiscalYearFormula: DateFormula;
    begin
        Evaluate(PreviousFiscalYearFormula, '<-1Y>');
        if ColumnLayout."Column Type" = ColumnLayout."Column Type"::"Net Change" then
            if ColumnLayout."Ledger Entry Type" = ColumnLayout."Ledger Entry Type"::Entries then
                if Format(ColumnLayout."Comparison Date Formula") = Format(PreviousFiscalYearFormula) then
                    "Net Change Actual Last Year" += Value
                else
                    "Net Change Actual" += Value
            else
                if Format(ColumnLayout."Comparison Date Formula") = Format(PreviousFiscalYearFormula) then
                    "Net Change Budget Last Year" += Value
                else
                    "Net Change Budget" += Value
        else
            if ColumnLayout."Ledger Entry Type" = ColumnLayout."Ledger Entry Type"::Entries then
                if Format(ColumnLayout."Comparison Date Formula") = Format(PreviousFiscalYearFormula) then
                    "Balance at Date Act. Last Year" += Value
                else
                    "Balance at Date Actual" += Value
            else
                if Format(ColumnLayout."Comparison Date Formula") = Format(PreviousFiscalYearFormula) then
                    "Balance at Date Bud. Last Year" += Value
                else
                    "Balance at Date Budget" += Value;
    end;

    /// <summary>
    /// Retrieves the appropriate KPI value based on column layout configuration and calculation parameters.
    /// Returns actual, budget, forecast, or comparative values depending on column type and date formula.
    /// </summary>
    /// <param name="ColumnLayout">Column layout record defining which value type to retrieve</param>
    /// <returns>Decimal value from the appropriate KPI field matching the column layout criteria</returns>
    procedure GetColumnValue(ColumnLayout: Record "Column Layout") Result: Decimal
    var
        PreviousFiscalYearFormula: DateFormula;
    begin
        Evaluate(PreviousFiscalYearFormula, '<-1Y>');
        if ColumnLayout."Column Type" = ColumnLayout."Column Type"::"Net Change" then
            if ColumnLayout."Ledger Entry Type" = ColumnLayout."Ledger Entry Type"::Entries then
                if Format(ColumnLayout."Comparison Date Formula") = Format(PreviousFiscalYearFormula) then
                    Result := "Net Change Actual Last Year"
                else
                    Result := "Net Change Actual"
            else
                if Format(ColumnLayout."Comparison Date Formula") = Format(PreviousFiscalYearFormula) then
                    Result := "Net Change Budget Last Year"
                else
                    Result := "Net Change Budget"
        else
            if ColumnLayout."Ledger Entry Type" = ColumnLayout."Ledger Entry Type"::Entries then
                if Format(ColumnLayout."Comparison Date Formula") = Format(PreviousFiscalYearFormula) then
                    Result := "Balance at Date Act. Last Year"
                else
                    Result := "Balance at Date Actual"
            else
                if Format(ColumnLayout."Comparison Date Formula") = Format(PreviousFiscalYearFormula) then
                    Result := "Balance at Date Bud. Last Year"
                else
                    Result := "Balance at Date Budget";
        exit(Result)
    end;
}
