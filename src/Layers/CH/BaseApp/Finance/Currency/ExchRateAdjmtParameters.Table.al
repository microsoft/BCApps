// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.Currency;

/// <summary>
/// Stores parameters for exchange rate adjustment processing operations.
/// Defines the scope, timing, and options for currency revaluation procedures.
/// </summary>
/// <remarks>
/// Temporary table used to pass parameters between exchange rate adjustment procedures.
/// Contains date ranges, posting options, and account type selections for adjustment processing.
/// </remarks>
table 596 "Exch. Rate Adjmt. Parameters"
{
    Caption = 'Exch. Rate Adjmt. Parameters';
    ReplicateData = false;
    TableType = Temporary;
    DataClassification = CustomerContent;

    fields
    {
        /// <summary>
        /// Unique identifier for the parameter record.
        /// </summary>
        field(1; "Primary Key"; Code[10])
        {
            Caption = 'Primary Key';
            DataClassification = SystemMetadata;
        }
        /// <summary>
        /// Starting date for the exchange rate adjustment period.
        /// </summary>
        field(2; "Start Date"; Date)
        {
            Caption = 'Start Date';
            DataClassification = SystemMetadata;
        }
        /// <summary>
        /// Ending date for the exchange rate adjustment period.
        /// </summary>
        field(3; "End Date"; Date)
        {
            Caption = 'End Date';
            DataClassification = SystemMetadata;
        }
        /// <summary>
        /// Date when the adjustment entries will be posted.
        /// </summary>
        field(4; "Posting Date"; Date)
        {
            Caption = 'Posting Date';
            DataClassification = SystemMetadata;
        }
        /// <summary>
        /// Description text for the adjustment posting entries.
        /// </summary>
        field(5; "Posting Description"; Text[100])
        {
            Caption = 'Posting Description';
            DataClassification = SystemMetadata;
        }
        /// <summary>
        /// Document number for the adjustment entries.
        /// </summary>
        field(6; "Document No."; Code[20])
        {
            Caption = 'Document No.';
            DataClassification = SystemMetadata;
        }
        /// <summary>
        /// Indicates whether bank account balances should be adjusted.
        /// </summary>
        field(7; "Adjust Bank Accounts"; Boolean)
        {
            Caption = 'Adjust Bank Accounts';
            DataClassification = SystemMetadata;
        }
        /// <summary>
        /// Indicates whether customer balances should be adjusted.
        /// </summary>
        field(8; "Adjust Customers"; Boolean)
        {
            Caption = 'Adjust Customers';
            DataClassification = SystemMetadata;
        }
        /// <summary>
        /// Indicates whether vendor balances should be adjusted.
        /// </summary>
        field(9; "Adjust Vendors"; Boolean)
        {
            Caption = 'Adjust Vendors';
            DataClassification = SystemMetadata;
        }
        /// <summary>
        /// Indicates whether G/L account balances should be adjusted.
        /// </summary>
        field(10; "Adjust G/L Accounts"; Boolean)
        {
            Caption = 'Adjust G/L Accounts';
            DataClassification = SystemMetadata;
        }
        /// <summary>
        /// Indicates whether VAT entries should be adjusted.
        /// </summary>
        field(11; "Adjust VAT Entries"; Boolean)
        {
            Caption = 'Adjust VAT Entries';
            DataClassification = SystemMetadata;
        }
        /// <summary>
        /// Indicates whether adjustments should be calculated per individual entry.
        /// </summary>
        field(12; "Adjust Per Entry"; Boolean)
        {
            Caption = 'Adjust Per Entry';
            DataClassification = SystemMetadata;
        }
        /// <summary>
        /// Indicates whether employee balances should be adjusted.
        /// </summary>
        field(13; "Adjust Employees"; Boolean)
        {
            Caption = 'Adjust Employees';
            DataClassification = SystemMetadata;
        }
        /// <summary>
        /// Specifies how dimensions are handled during adjustment posting.
        /// </summary>
        field(14; "Dimension Posting"; Enum "Exch. Rate Adjmt. Dimensions")
        {
            Caption = 'Dimension Posting';
            DataClassification = SystemMetadata;
        }
        /// <summary>
        /// Filter for limiting adjustment processing to specific currencies.
        /// </summary>
        field(20; "Currency Filter"; Text[2048])
        {
            FieldClass = FlowFilter;
        }
        /// <summary>
        /// Filter for limiting adjustment processing to specific bank accounts.
        /// </summary>
        field(21; "Bank Account Filter"; Text[2048])
        {
            FieldClass = FlowFilter;
        }
        /// <summary>
        /// Filter for limiting adjustment processing to specific customers.
        /// </summary>
        field(22; "Customer Filter"; Text[2048])
        {
            FieldClass = FlowFilter;
        }
        /// <summary>
        /// Filter for limiting adjustment processing to specific vendors.
        /// </summary>
        field(23; "Vendor Filter"; Text[2048])
        {
            FieldClass = FlowFilter;
        }
        /// <summary>
        /// Filter for limiting adjustment processing to specific employees.
        /// </summary>
        field(24; "Employee Filter"; Text[2048])
        {
            FieldClass = FlowFilter;
        }
        /// <summary>
        /// Journal template for posting adjustment entries.
        /// </summary>
        field(27; "Journal Template Name"; Code[10])
        {
            Caption = 'Journal Template Name';
            DataClassification = SystemMetadata;
        }
        /// <summary>
        /// Journal batch for posting adjustment entries.
        /// </summary>
        field(28; "Journal Batch Name"; Code[10])
        {
            Caption = 'Journal Batch Name';
            DataClassification = SystemMetadata;
        }
        /// <summary>
        /// Indicates whether the user interface should be hidden during processing.
        /// </summary>
        field(29; "Hide UI"; Boolean)
        {
            Caption = 'Hide UI';
            DataClassification = SystemMetadata;
        }
        /// <summary>
        /// Indicates whether to preview posting without actually posting entries.
        /// </summary>
        field(30; "Preview Posting"; Boolean)
        {
            Caption = 'Preview Posting';
            DataClassification = SystemMetadata;
        }
        field(11000; "Valuation Method"; Integer)
        {
            Caption = 'Valuation Method';
            DataClassification = SystemMetadata;
        }
        field(11001; "Valuation Period End Date"; Date)
        {
            Caption = 'Valuation Period End Date';
            DataClassification = SystemMetadata;
        }
        field(11002; "Due Date To"; Date)
        {
            Caption = 'Due Date To';
            DataClassification = SystemMetadata;
        }
    }

    keys
    {
        key(key1; "Primary Key")
        {
            Clustered = true;
        }
    }
}