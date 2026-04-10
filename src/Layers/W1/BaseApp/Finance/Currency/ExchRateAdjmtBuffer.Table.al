// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.Currency;

/// <summary>
/// Temporary buffer table for storing calculated exchange rate adjustment amounts.
/// Groups adjustment data by currency, posting group, and dimensions for processing.
/// </summary>
/// <remarks>
/// Used during exchange rate adjustment procedures to accumulate and calculate
/// adjustment amounts before creating journal entries. Supports grouping by various criteria
/// and includes integration events for extensibility.
/// </remarks>
table 595 "Exch. Rate Adjmt. Buffer"
{
    Caption = 'Exch. Rate Adjmt. Buffer';
    TableType = Temporary;
    DataClassification = CustomerContent;

    fields
    {
        /// <summary>
        /// Unique identifier for grouping related adjustment records.
        /// </summary>
        field(1; "Group ID"; Guid)
        {
            Caption = 'Group ID';
            DataClassification = SystemMetadata;
        }
        /// <summary>
        /// Currency code for the adjustment calculation.
        /// </summary>
        field(2; "Currency Code"; Code[10])
        {
            Caption = 'Currency Code';
            DataClassification = SystemMetadata;
            TableRelation = Currency;
        }
        /// <summary>
        /// Posting group affecting the adjustment calculation.
        /// </summary>
        field(3; "Posting Group"; Code[20])
        {
            Caption = 'Posting Group';
            DataClassification = SystemMetadata;
        }
        /// <summary>
        /// Account number being adjusted for exchange rate changes.
        /// </summary>
        field(4; "Account No."; Code[20])
        {
            Caption = 'Account No.';
            DataClassification = SystemMetadata;
        }
        /// <summary>
        /// Dimension entry number for dimension-specific adjustments.
        /// </summary>
        field(5; "Dimension Entry No."; Integer)
        {
            Caption = 'Dimension Entry No.';
            DataClassification = SystemMetadata;
        }
        /// <summary>
        /// Posting date for the adjustment entries.
        /// </summary>
        field(6; "Posting Date"; Date)
        {
            Caption = 'Posting Date';
            DataClassification = SystemMetadata;
        }
        /// <summary>
        /// Intercompany partner code for IC transactions.
        /// </summary>
        field(7; "IC Partner Code"; Code[20])
        {
            Caption = 'IC Partner Code';
            DataClassification = SystemMetadata;
        }
        /// <summary>
        /// Index number for sorting and processing order.
        /// </summary>
        field(8; Index; Integer)
        {
            Caption = 'Index';
            DataClassification = SystemMetadata;
        }
        /// <summary>
        /// Entry number for reference tracking.
        /// </summary>
        field(9; "Entry No."; Integer)
        {
            Caption = 'Entry No.';
            DataClassification = SystemMetadata;
        }
        /// <summary>
        /// Base amount used for adjustment calculations.
        /// </summary>
        field(10; "Adjmt. Base"; Decimal)
        {
            AutoFormatExpression = Rec."Currency Code";
            AutoFormatType = 1;
            Caption = 'AdjBase';
            DataClassification = SystemMetadata;
        }
        /// <summary>
        /// Base amount in local currency for adjustment calculations.
        /// </summary>
        field(11; "Adjmt. Base (LCY)"; Decimal)
        {
            AutoFormatExpression = '';
            AutoFormatType = 1;
            Caption = 'Adjmt. Base (LCY)';
            DataClassification = SystemMetadata;
        }
        /// <summary>
        /// Total calculated adjustment amount.
        /// </summary>
        field(12; "Adjmt. Amount"; Decimal)
        {
            AutoFormatExpression = '';
            AutoFormatType = 1;
            Caption = 'Adjmt. Amount';
            DataClassification = SystemMetadata;
        }
        /// <summary>
        /// Positive adjustment amount representing gains.
        /// </summary>
        field(13; "Gains Amount"; Decimal)
        {
            AutoFormatExpression = '';
            AutoFormatType = 1;
            Caption = 'Gains Amount';
            DataClassification = SystemMetadata;
        }
        /// <summary>
        /// Negative adjustment amount representing losses.
        /// </summary>
        field(14; "Losses Amount"; Decimal)
        {
            AutoFormatExpression = '';
            AutoFormatType = 1;
            Caption = 'Losses Amount';
            DataClassification = SystemMetadata;
        }
    }

    keys
    {
        key(Key1; "Group ID")
        {
            Clustered = true;
        }
        key(Key2; "Currency Code", "Posting Group", "Account No.", "Dimension Entry No.", "Posting Date", "IC Partner Code")
        {
        }
    }

    fieldgroups
    {
    }

    /// <summary>
    /// Generates a unique primary key for the buffer record.
    /// </summary>
    procedure BuildPrimaryKey()
    begin
        "Group ID" := CreateGuid();

        OnAfterBuildPrimaryKey(Rec);
    end;

    /// <summary>
    /// Integration event raised after building the primary key for the buffer record.
    /// Enables custom logic to be executed after key generation.
    /// </summary>
    /// <param name="ExchRateAdjmtBuffer">Buffer record after primary key generation</param>
    [IntegrationEvent(false, false)]
    local procedure OnAfterBuildPrimaryKey(var ExchRateAdjmtBuffer: Record "Exch. Rate Adjmt. Buffer")
    begin
    end;
}
