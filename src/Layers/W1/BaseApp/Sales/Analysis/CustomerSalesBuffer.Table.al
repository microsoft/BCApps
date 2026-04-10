// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Sales.Analysis;

/// <summary>
/// Provides temporary storage for customer sales data used in period-based sales analysis.
/// </summary>
table 923 "Customer Sales Buffer"
{
    DataClassification = SystemMetadata;

    fields
    {
        /// <summary>
        /// Specifies the time period granularity used for grouping the sales data, such as day, week, month, quarter, year, or accounting period.
        /// </summary>
        field(5; "Period Type"; Option)
        {
            Caption = 'Period Type';
            OptionMembers = Day,Week,Month,Quarter,Year,Period;
            DataClassification = SystemMetadata;
        }
        /// <summary>
        /// Specifies the display name of the period, such as the month name or week number.
        /// </summary>
        field(6; "Period Name"; Text[50])
        {
            Caption = 'Period Name';
            ToolTip = 'Specifies the name of the period that you want to view.';
            DataClassification = SystemMetadata;
        }
        /// <summary>
        /// Specifies the first date of the analysis period.
        /// </summary>
        field(7; "Period Start"; Date)
        {
            Caption = 'Period Start';
            ToolTip = 'Specifies the starting date of the period that you want to view.';
            DataClassification = SystemMetadata;
        }
        /// <summary>
        /// Specifies the last date of the analysis period.
        /// </summary>
        field(8; "Period End"; Date)
        {
            Caption = 'Period End';
            DataClassification = SystemMetadata;
        }
        /// <summary>
        /// Stores the outstanding balance due from the customer in local currency for the period.
        /// </summary>
        field(10; "Balance Due (LCY)"; Decimal)
        {
            Caption = 'Balance Due (LCY)';
            DataClassification = SystemMetadata;
            AutoFormatType = 1;
            AutoFormatExpression = '';
        }
        /// <summary>
        /// Stores the total sales amount in local currency for the period.
        /// </summary>
        field(11; "Sales (LCY)"; Decimal)
        {
            Caption = 'Sales (LCY)';
            DataClassification = SystemMetadata;
            AutoFormatType = 1;
            AutoFormatExpression = '';
        }
        /// <summary>
        /// Stores the profit amount in local currency for the period, calculated as sales minus cost.
        /// </summary>
        field(12; "Profit (LCY)"; Decimal)
        {
            Caption = 'Profit (LCY)';
            DataClassification = SystemMetadata;
            AutoFormatType = 1;
            AutoFormatExpression = '';
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
