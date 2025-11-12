// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Bank.BankAccount;

/// <summary>
/// Temporary buffer table for calculating and displaying bank account balance by periods.
/// Used for balance analysis and reporting by day, week, month, quarter, or year.
/// </summary>
/// <remarks>
/// Non-persisted buffer table for period-based balance calculations and chart display.
/// </remarks>
table 929 "Bank Account Balance Buffer"
{
    DataClassification = CustomerContent;

    fields
    {
        /// <summary>
        /// Type of period for balance aggregation (Day, Week, Month, Quarter, Year, Period).
        /// </summary>
        field(5; "Period Type"; Option)
        {
            Caption = 'Period Type';
            OptionMembers = Day,Week,Month,Quarter,Year,Period;
        }
        /// <summary>
        /// Display name of the period for user interface.
        /// </summary>
        field(6; "Period Name"; Text[50])
        {
            Caption = 'Period Name';
        }
        /// <summary>
        /// Starting date of the balance calculation period.
        /// </summary>
        field(7; "Period Start"; Date)
        {
            Caption = 'Period Start';
        }
        /// <summary>
        /// Ending date of the balance calculation period.
        /// </summary>
        field(8; "Period End"; Date)
        {
            Caption = 'Period End';
        }
        /// <summary>
        /// Net change amount in bank account currency for the period.
        /// </summary>
        field(10; "Net Change"; Decimal)
        {
            AutoFormatType = 1;
            Caption = 'Net Change';
        }
        /// <summary>
        /// Net change amount in local currency for the period.
        /// </summary>
        field(11; "Net Change (LCY)"; Decimal)
        {
            AutoFormatExpression = '';
            AutoFormatType = 1;
            Caption = 'Net Change (LCY)';
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
