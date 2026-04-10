// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.FinancialReports;

/// <summary>
/// Temporary table storing calculated cell values for account schedule displays with error tracking.
/// Used for buffering account schedule calculation results and managing display formatting.
/// </summary>
/// <remarks>
/// Primary usage: Account schedule calculation buffering, cell value storage for matrix displays.
/// Integration: Links with Account Schedule Management and Account Schedule Overview page functionality.
/// Extensibility: Standard table extension patterns for additional cell properties and calculation metadata.
/// </remarks>
table 342 "Acc. Sched. Cell Value"
{
    Caption = 'Acc. Sched. Cell Value';
    TableType = Temporary;
    DataClassification = CustomerContent;

    fields
    {
        /// <summary>
        /// Row number identifying the account schedule line position in the display matrix.
        /// </summary>
        field(1; "Row No."; Integer)
        {
            Caption = 'Row No.';
        }
        /// <summary>
        /// Column number identifying the column layout position in the display matrix.
        /// </summary>
        field(2; "Column No."; Integer)
        {
            Caption = 'Column No.';
        }
        /// <summary>
        /// Calculated decimal value for the intersection of account schedule line and column layout.
        /// </summary>
        field(3; Value; Decimal)
        {
            AutoFormatType = 1;
            AutoFormatExpression = '';
            Caption = 'Value';
        }
        /// <summary>
        /// Indicates whether a calculation error occurred when computing this cell value.
        /// </summary>
        field(4; "Has Error"; Boolean)
        {
            Caption = 'Has Error';
        }
        /// <summary>
        /// Indicates whether a period-related error occurred during date range calculations for this cell.
        /// </summary>
        field(5; "Period Error"; Boolean)
        {
            Caption = 'Period Error';
        }
    }

    keys
    {
        key(Key1; "Row No.", "Column No.")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }
}
