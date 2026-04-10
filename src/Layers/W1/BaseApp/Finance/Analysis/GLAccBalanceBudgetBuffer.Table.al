// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.Analysis;

/// <summary>
/// Temporary buffer table for G/L account balance and budget comparison analysis.
/// Stores period-based actual vs. budget data for financial analysis reports and matrix displays.
/// </summary>
table 922 "G/L Acc. Balance/Budget Buffer"
{
    DataClassification = SystemMetadata;

    fields
    {
        /// <summary>
        /// Period type for time-based analysis grouping and matrix column generation.
        /// Determines the granularity of budget vs. actual comparison periods.
        /// </summary>
        field(5; "Period Type"; Option)
        {
            Caption = 'Period Type';
            OptionMembers = Day,Week,Month,Quarter,Year,Period;
            DataClassification = SystemMetadata;
        }
        /// <summary>
        /// Display name for the analysis period used in reports and matrix headers.
        /// Generated based on period type and date range for user-friendly presentation.
        /// </summary>
        field(6; "Period Name"; Text[50])
        {
            Caption = 'Period Name';
            ToolTip = 'Specifies the name of the period that you want to view.';
            DataClassification = SystemMetadata;
        }
        /// <summary>
        /// Start date of the analysis period for filtering and date range calculations.
        /// Defines the beginning of the period for balance and budget aggregation.
        /// </summary>
        field(7; "Period Start"; Date)
        {
            Caption = 'Period Start';
            ToolTip = 'Specifies the starting date of the period that you want to view.';
            DataClassification = SystemMetadata;
        }
        /// <summary>
        /// End date of the analysis period for filtering and date range calculations.
        /// Defines the conclusion of the period for balance and budget aggregation.
        /// </summary>
        field(8; "Period End"; Date)
        {
            Caption = 'Period End';
            DataClassification = SystemMetadata;
        }
        /// <summary>
        /// Total debit amount for G/L accounts within the analysis period.
        /// Aggregated from G/L entries for budget vs. actual variance analysis.
        /// </summary>
        field(10; "Debit Amount"; Decimal)
        {
            AutoFormatExpression = '';
            AutoFormatType = 1;
            Caption = 'Debit Amount';
            ToolTip = 'Specifies the total of the debit entries that have been posted to the account.';
            DataClassification = SystemMetadata;
        }
        /// <summary>
        /// Total credit amount for G/L accounts within the analysis period.
        /// Aggregated from G/L entries for budget vs. actual variance analysis.
        /// </summary>
        field(11; "Credit Amount"; Decimal)
        {
            AutoFormatExpression = '';
            AutoFormatType = 1;
            Caption = 'Credit Amount';
            ToolTip = 'Specifies the total of the credit entries that have been posted to the account.';
            DataClassification = SystemMetadata;
        }
        /// <summary>
        /// Net change amount calculated as debit minus credit amounts.
        /// Represents the net effect on account balance for the analysis period.
        /// </summary>
        field(12; "Net Change"; Decimal)
        {
            AutoFormatExpression = '';
            AutoFormatType = 1;
            Caption = 'Net Change';
            ToolTip = 'Specifies the net change in the account balance during the time period in the Date Filter field.';
            DataClassification = SystemMetadata;
        }
        /// <summary>
        /// Total budgeted debit amount for G/L accounts within the analysis period.
        /// Aggregated from G/L budget entries for comparison with actual amounts.
        /// </summary>
        field(13; "Budgeted Debit Amount"; Decimal)
        {
            AutoFormatExpression = '';
            AutoFormatType = 1;
            Caption = 'Budgeted Debit Amount';
            ToolTip = 'Specifies the total of the budget debit entries that have been posted to the account.';
            DataClassification = SystemMetadata;
        }
        /// <summary>
        /// Total budgeted credit amount for G/L accounts within the analysis period.
        /// Aggregated from G/L budget entries for comparison with actual amounts.
        /// </summary>
        field(14; "Budgeted Credit Amount"; Decimal)
        {
            AutoFormatExpression = '';
            AutoFormatType = 1;
            Caption = 'Budgeted Credit Amount';
            ToolTip = 'Specifies the total of the budget credit entries that have been posted to the account.';
            DataClassification = SystemMetadata;
        }
        /// <summary>
        /// Net budgeted amount calculated as budgeted debit minus credit amounts.
        /// Represents the planned net effect on account balance for variance analysis.
        /// </summary>
        field(15; "Budgeted Amount"; Decimal)
        {
            AutoFormatExpression = '';
            AutoFormatType = 1;
            Caption = 'Budgeted Amount';
            ToolTip = 'Specifies the total of the budget entries that have been posted to the account.';
            DataClassification = SystemMetadata;
        }
        /// <summary>
        /// Percentage comparison of actual balance to budgeted amount.
        /// Calculated as (Net Change / Budgeted Amount) * 100 for variance analysis.
        /// </summary>
        field(16; "Balance/Budget Pct."; Decimal)
        {
            AutoFormatType = 0;
            Caption = 'Balance/Budget (%)';
            ToolTip = 'Specifies a summary of the debit and credit balances and the budgeted amounts for different time periods for the account that you select in the chart of accounts.';
            DataClassification = SystemMetadata;
        }
    }

    keys
    {
        key(Key1; "Period Type", "Period Start")
        {
            Clustered = true;
        }
    }
}
