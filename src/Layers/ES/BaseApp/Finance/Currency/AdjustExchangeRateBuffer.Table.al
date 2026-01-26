// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.Currency;

/// <summary>
/// Temporary buffer table for accumulating exchange rate adjustment calculations.
/// Groups adjustment amounts by currency, posting group, and dimensions before journal entry creation.
/// </summary>
/// <remarks>
/// Used during exchange rate adjustment procedures to collect and summarize
/// adjustment amounts across multiple ledger entries. Supports dimension grouping
/// and intercompany partner segregation for accurate posting.
/// </remarks>
table 331 "Adjust Exchange Rate Buffer"
{
    Caption = 'Adjust Exchange Rate Buffer';
    ReplicateData = false;
    TableType = Temporary;
    DataClassification = CustomerContent;

    fields
    {
        /// <summary>
        /// Currency code for which adjustments are being calculated.
        /// </summary>
        field(1; "Currency Code"; Code[10])
        {
            Caption = 'Currency Code';
            DataClassification = SystemMetadata;
            TableRelation = Currency;
        }
        /// <summary>
        /// Posting group affecting the adjustment calculation grouping.
        /// </summary>
        field(2; "Posting Group"; Code[20])
        {
            Caption = 'Posting Group';
            DataClassification = SystemMetadata;
        }
        /// <summary>
        /// Base amount for adjustment calculations.
        /// </summary>
        field(3; AdjBase; Decimal)
        {
            AutoFormatExpression = Rec."Currency Code";
            AutoFormatType = 1;
            Caption = 'AdjBase';
            DataClassification = SystemMetadata;
        }
        /// <summary>
        /// Base amount in local currency for adjustment calculations.
        /// </summary>
        field(4; AdjBaseLCY; Decimal)
        {
            AutoFormatExpression = '';
            AutoFormatType = 1;
            Caption = 'AdjBaseLCY';
            DataClassification = SystemMetadata;
        }
        /// <summary>
        /// Total calculated adjustment amount.
        /// </summary>
        field(5; AdjAmount; Decimal)
        {
            AutoFormatExpression = '';
            AutoFormatType = 1;
            Caption = 'AdjAmount';
            DataClassification = SystemMetadata;
        }
        /// <summary>
        /// Total positive adjustment amounts representing gains.
        /// </summary>
        field(6; TotalGainsAmount; Decimal)
        {
            AutoFormatExpression = '';
            AutoFormatType = 1;
            Caption = 'TotalGainsAmount';
            DataClassification = SystemMetadata;
        }
        /// <summary>
        /// Total negative adjustment amounts representing losses.
        /// </summary>
        field(7; TotalLossesAmount; Decimal)
        {
            AutoFormatExpression = '';
            AutoFormatType = 1;
            Caption = 'TotalLossesAmount';
            DataClassification = SystemMetadata;
        }
        /// <summary>
        /// Dimension entry number for dimension-specific grouping.
        /// </summary>
        field(8; "Dimension Entry No."; Integer)
        {
            Caption = 'Dimension Entry No.';
            DataClassification = SystemMetadata;
        }
        /// <summary>
        /// Posting date for the adjustment entries.
        /// </summary>
        field(9; "Posting Date"; Date)
        {
            Caption = 'Posting Date';
            DataClassification = SystemMetadata;
        }
        /// <summary>
        /// Intercompany partner code for IC transaction grouping.
        /// </summary>
        field(10; "IC Partner Code"; Code[20])
        {
            Caption = 'IC Partner Code';
            DataClassification = SystemMetadata;
        }
        /// <summary>
        /// Index number for sorting and processing order.
        /// </summary>
        field(11; Index; Integer)
        {
            Caption = 'Index';
            DataClassification = SystemMetadata;
        }
        field(7000000; "Account No."; Code[20])
        {
            Caption = 'Account No.';
            DataClassification = SystemMetadata;
        }
    }

    keys
    {
        key(Key1; "Currency Code", "Posting Group", "Account No.", "Dimension Entry No.", "Posting Date", "IC Partner Code")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }
}
