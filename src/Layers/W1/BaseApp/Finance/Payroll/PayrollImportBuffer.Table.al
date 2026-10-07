// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.Payroll;

/// <summary>
/// Temporary buffer table for staging payroll transaction data during import processing.
/// Used by Import Payroll XMLport to store parsed payroll file data before mapping to G/L entries.
/// </summary>
/// <remarks>
/// Non-replicated buffer table with SystemMetadata classification for temporary processing.
/// Used in conjunction with Data Exchange Framework for payroll file imports.
/// </remarks>
table 1662 "Payroll Import Buffer"
{
    Caption = 'Payroll Import Buffer';
    ReplicateData = false;
    DataClassification = CustomerContent;

    fields
    {
        /// <summary>
        /// Auto-incrementing unique identifier for buffer entries.
        /// </summary>
        field(1; "Entry No."; Integer)
        {
            AutoIncrement = true;
            Caption = 'Entry No.';
            DataClassification = SystemMetadata;
        }
        /// <summary>
        /// Transaction posting date from payroll file.
        /// </summary>
        field(10; "Transaction date"; Date)
        {
            Caption = 'Transaction date';
            DataClassification = SystemMetadata;
        }
        /// <summary>
        /// External account number from payroll system.
        /// </summary>
        field(11; "Account No."; Code[20])
        {
            Caption = 'Account No.';
            DataClassification = SystemMetadata;
        }
        /// <summary>
        /// Transaction amount from payroll file.
        /// </summary>
        field(12; Amount; Decimal)
        {
            AutoFormatExpression = '';
            AutoFormatType = 1;
            Caption = 'Amount';
            DataClassification = SystemMetadata;
        }
        /// <summary>
        /// Transaction description from payroll file.
        /// </summary>
        field(13; Description; Text[100])
        {
            Caption = 'Description';
            DataClassification = SystemMetadata;
        }
    }

    keys
    {
        key(Key1; "Entry No.")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }
}
