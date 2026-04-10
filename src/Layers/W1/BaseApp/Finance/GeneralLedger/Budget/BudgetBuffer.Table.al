// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.GeneralLedger.Budget;

using Microsoft.Finance.GeneralLedger.Account;

/// <summary>
/// Temporary buffer table for efficient Excel integration and budget data transformation operations.
/// Optimizes multi-dimensional budget data processing during import/export workflows with flattened structure.
/// </summary>
/// <remarks>
/// Usage: Excel import/export, budget aggregation, and dimensional data transformation scenarios.
/// Performance: Temporary table with optimized keys for batch processing and dimensional sorting.
/// Integration: Works with Export/Import Budget Excel reports for seamless offline budget editing.
/// </remarks>
table 371 "Budget Buffer"
{
    Caption = 'Budget Buffer';
    ReplicateData = false;
    DataClassification = CustomerContent;

    fields
    {
        /// <summary>
        /// G/L Account number for budget aggregation and Excel integration scenarios.
        /// </summary>
        field(1; "G/L Account No."; Code[20])
        {
            Caption = 'G/L Account No.';
            DataClassification = SystemMetadata;
            TableRelation = "G/L Account";
        }
        /// <summary>
        /// First dimension value code for flattened dimensional analysis in buffer operations.
        /// </summary>
        field(2; "Dimension Value Code 1"; Code[20])
        {
            Caption = 'Dimension Value Code 1';
            DataClassification = SystemMetadata;
        }
        /// <summary>
        /// Second dimension value code for flattened dimensional analysis in buffer operations.
        /// </summary>
        field(3; "Dimension Value Code 2"; Code[20])
        {
            Caption = 'Dimension Value Code 2';
            DataClassification = SystemMetadata;
        }
        /// <summary>
        /// Third dimension value code for flattened dimensional analysis in buffer operations.
        /// </summary>
        field(4; "Dimension Value Code 3"; Code[20])
        {
            Caption = 'Dimension Value Code 3';
            DataClassification = SystemMetadata;
        }
        /// <summary>
        /// Fourth dimension value code for flattened dimensional analysis in buffer operations.
        /// </summary>
        field(5; "Dimension Value Code 4"; Code[20])
        {
            Caption = 'Dimension Value Code 4';
            DataClassification = SystemMetadata;
        }
        /// <summary>
        /// Fifth dimension value code for flattened dimensional analysis in buffer operations.
        /// </summary>
        field(6; "Dimension Value Code 5"; Code[20])
        {
            Caption = 'Dimension Value Code 5';
            DataClassification = SystemMetadata;
        }
        /// <summary>
        /// Sixth dimension value code for flattened dimensional analysis in buffer operations.
        /// </summary>
        field(7; "Dimension Value Code 6"; Code[20])
        {
            Caption = 'Dimension Value Code 6';
            DataClassification = SystemMetadata;
        }
        /// <summary>
        /// Seventh dimension value code for flattened dimensional analysis in buffer operations.
        /// </summary>
        field(8; "Dimension Value Code 7"; Code[20])
        {
            Caption = 'Dimension Value Code 7';
            DataClassification = SystemMetadata;
        }
        /// <summary>
        /// Eighth dimension value code for flattened dimensional analysis in buffer operations.
        /// </summary>
        field(9; "Dimension Value Code 8"; Code[20])
        {
            Caption = 'Dimension Value Code 8';
            DataClassification = SystemMetadata;
        }
        /// <summary>
        /// Budget period date for temporal aggregation and Excel integration workflows.
        /// </summary>
        field(10; Date; Date)
        {
            Caption = 'Date';
            DataClassification = SystemMetadata;
        }
        /// <summary>
        /// Aggregated budget amount for the specified account and dimension combination.
        /// </summary>
        field(11; Amount; Decimal)
        {
            AutoFormatExpression = '';
            AutoFormatType = 1;
            Caption = 'Amount';
            DataClassification = SystemMetadata;
        }
    }

    keys
    {
        key(Key1; "G/L Account No.", "Dimension Value Code 1", "Dimension Value Code 2", "Dimension Value Code 3", "Dimension Value Code 4", "Dimension Value Code 5", "Dimension Value Code 6", "Dimension Value Code 7", "Dimension Value Code 8", Date)
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }
}
