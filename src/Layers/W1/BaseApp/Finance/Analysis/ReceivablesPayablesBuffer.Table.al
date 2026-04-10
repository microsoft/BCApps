// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.Analysis;

/// <summary>
/// Temporary buffer table for receivables vs. payables cash flow analysis.
/// Stores period-based customer and vendor balance data for liquidity and cash flow reporting.
/// </summary>
table 927 "Receivables-Payables Buffer"
{
    DataClassification = SystemMetadata;

    fields
    {
        /// <summary>
        /// Period type for time-based receivables and payables analysis grouping.
        /// Determines the granularity of cash flow analysis periods for liquidity planning.
        /// </summary>
        field(5; "Period Type"; Option)
        {
            Caption = 'Period Type';
            OptionMembers = Day,Week,Month,Quarter,Year,Period;
            DataClassification = SystemMetadata;
        }
        /// <summary>
        /// Display name for the analysis period used in cash flow reports and matrix headers.
        /// Generated based on period type and date range for user-friendly presentation.
        /// </summary>
        field(6; "Period Name"; Text[50])
        {
            Caption = 'Period Name';
            ToolTip = 'Specifies the name of the period covered by the summary report of receivables for customers and payables for vendors.';
            DataClassification = SystemMetadata;
        }
        /// <summary>
        /// Start date of the cash flow analysis period for filtering and date calculations.
        /// Defines the beginning of the period for receivables and payables aggregation.
        /// </summary>
        field(7; "Period Start"; Date)
        {
            Caption = 'Period Start';
            ToolTip = 'Specifies the beginning of the period covered by the summary report of receivables for customers and payables for vendors.';
            DataClassification = SystemMetadata;
        }
        /// <summary>
        /// End date of the cash flow analysis period for filtering and date calculations.
        /// Defines the conclusion of the period for receivables and payables aggregation.
        /// </summary>
        field(8; "Period End"; Date)
        {
            Caption = 'Period End';
            DataClassification = SystemMetadata;
        }
        /// <summary>
        /// Total customer balances due within the analysis period for cash inflow analysis.
        /// Aggregated from customer ledger entries for receivables cash flow projections.
        /// </summary>
        field(10; "Cust. Balances Due"; Decimal)
        {
            Caption = 'Cust. Balances Due';
            ToolTip = 'Specifies the total amount your company is owed by customers. The program automatically calculates and updates the contents of the field, using entries in the Remaining Amt. (LCY) field in the Cust. Ledger Entry table.';
            AutoFormatExpression = '';
            AutoFormatType = 1;
            DataClassification = SystemMetadata;
        }
        /// <summary>
        /// Total vendor balances due within the analysis period for cash outflow analysis.
        /// Aggregated from vendor ledger entries for payables cash flow projections.
        /// </summary>
        field(11; "Vendor Balances Due"; Decimal)
        {
            Caption = 'Vendor Balances Due';
            ToolTip = 'Specifies the total amount your company owes its vendors. The program automatically calculates and updates the contents of the field, using entries in the Remaining Amt. (LCY) field in the Vendor Ledger Entry table.';
            AutoFormatExpression = '';
            AutoFormatType = 1;
            DataClassification = SystemMetadata;
        }
        /// <summary>
        /// Net receivables minus payables amount for cash flow impact analysis.
        /// Calculated as customer balances due minus vendor balances due for net cash position.
        /// </summary>
        field(12; "Receivables-Payables"; Decimal)
        {
            Caption = 'Receivables-Payables';
            ToolTip = 'Specifies expected payments from customers and to vendors. It does not include other transactions that affect liquidity or the liquid balance at the beginning of the period. Therefore, the amounts in the column do not represent the liquid balance at the close of the period.';
            AutoFormatExpression = '';
            AutoFormatType = 1;
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
