// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.Analysis;

/// <summary>
/// Temporary buffer table for G/L account balance calculations and period-based analysis.
/// Stores calculated balance data for reporting and analysis across different time periods.
/// </summary>
/// <remarks>
/// Used by G/L account analysis and balance reporting functionality.
/// Provides period-based aggregation of G/L account balances with debit/credit breakdown.
/// </remarks>
table 926 "G/L Acc. Balance Buffer"
{
    DataClassification = SystemMetadata;

    fields
    {
        /// <summary>
        /// Type of period used for balance calculation and grouping.
        /// </summary>
        field(5; "Period Type"; Option)
        {
            Caption = 'Period Type';
            OptionMembers = Day,Week,Month,Quarter,Year,Period;
            DataClassification = SystemMetadata;
        }
        /// <summary>
        /// Descriptive name of the period for balance calculation.
        /// </summary>
        field(6; "Period Name"; Text[50])
        {
            Caption = 'Period Name';
            ToolTip = 'Specifies the name of the period shown in the line.';
            DataClassification = SystemMetadata;
        }
        /// <summary>
        /// Starting date of the period for balance calculation.
        /// </summary>
        field(7; "Period Start"; Date)
        {
            Caption = 'Period Start';
            ToolTip = 'Specifies the start date of the period defined on the line for the bank account balance.';
            DataClassification = SystemMetadata;
        }
        /// <summary>
        /// Ending date of the period for balance calculation.
        /// </summary>
        field(8; "Period End"; Date)
        {
            Caption = 'Period End';
            DataClassification = SystemMetadata;
        }
        /// <summary>
        /// Total debit amount for the period and account.
        /// </summary>
        field(10; "Debit Amount"; Decimal)
        {
            Caption = 'Debit Amount';
            ToolTip = 'Specifies the debit amount for the period on the line.';
            DataClassification = SystemMetadata;
            AutoFormatType = 1;
            AutoFormatExpression = '';
        }
        /// <summary>
        /// Total credit amount for the period and account.
        /// </summary>
        field(11; "Credit Amount"; Decimal)
        {
            Caption = 'Credit Amount';
            ToolTip = 'Specifies the credit amount for the period on the line.';
            DataClassification = SystemMetadata;
            AutoFormatType = 1;
            AutoFormatExpression = '';
        }
        /// <summary>
        /// Net change amount (debits minus credits) for the period and account.
        /// </summary>
        field(12; "Net Change"; Decimal)
        {
            Caption = 'Net Change';
            ToolTip = 'Specifies changes in the actual general ledger amount.';
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
