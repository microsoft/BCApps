// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.ReceivablesPayables;

using Microsoft.Finance.GeneralLedger.Journal;

/// <summary>
/// Stores parameters for invoice posting operations across sales and purchase documents.
/// Temporary table used to pass posting configuration and document information between procedures.
/// </summary>
/// <remarks>
/// Used by invoice posting engines to maintain consistent document and source code information.
/// Supports automatic document numbering, external document reference tracking, and tax type specification.
/// Integrates with General Journal document types for proper classification.
/// </remarks>
table 56 "Invoice Posting Parameters"
{
    Caption = 'Invoice Posting Parameters';
    TableType = Temporary;
    DataClassification = CustomerContent;

    fields
    {
        /// <summary>
        /// Unique code identifier for the parameter record.
        /// </summary>
        field(1; "Code"; Code[10])
        {
            Caption = 'Code';
            DataClassification = SystemMetadata;
        }
        /// <summary>
        /// Document type for the invoice posting operation.
        /// </summary>
        field(2; "Document Type"; Enum "Gen. Journal Document Type")
        {
            Caption = 'Document Type';
            DataClassification = SystemMetadata;
        }
        /// <summary>
        /// Document number assigned to the posted invoice.
        /// </summary>
        field(3; "Document No."; Code[20])
        {
            Caption = 'Document No.';
            DataClassification = SystemMetadata;
        }
        /// <summary>
        /// External document number reference from the original invoice document.
        /// </summary>
        field(4; "External Document No."; Code[35])
        {
            Caption = 'External Document No.';
            DataClassification = SystemMetadata;
        }
        /// <summary>
        /// Automatically generated document number from number series.
        /// </summary>
        field(5; "Auto Document No."; Code[20])
        {
            Caption = 'Auto Document No.';
            DataClassification = SystemMetadata;
        }
        /// <summary>
        /// Source code identifying the origin of the posting operation.
        /// </summary>
        field(6; "Source Code"; Code[10])
        {
            Caption = 'Source Code';
            DataClassification = SystemMetadata;
        }
        /// <summary>
        /// Tax type option for specialized tax handling requirements.
        /// </summary>
        field(10; "Tax Type"; Option)
        {
            Caption = 'Tax Type';
            DataClassification = SystemMetadata;
            OptionCaption = 'None,VAT,Sales Tax';
            OptionMembers = "None","VAT","Sales Tax";
        }
    }

    keys
    {
        key(Key1; "Code")
        {
            Clustered = true;
        }
    }
}

