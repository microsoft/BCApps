// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.Deferral;

/// <summary>
/// Archive table for deferral line records, storing historical deferral schedule details.
/// Maintains detailed deferral line history when documents are archived for audit and reference purposes.
/// </summary>
table 5128 "Deferral Line Archive"
{
    Caption = 'Deferral Line Archive';
    DataClassification = CustomerContent;

    fields
    {
        /// <summary>
        /// Type of source document (Purchase, Sales, or G/L) that initiated this archived deferral line.
        /// Links to parent Deferral Header Archive record.
        /// </summary>
        field(1; "Deferral Doc. Type"; Enum "Deferral Document Type")
        {
            Caption = 'Deferral Doc. Type';
            TableRelation = "Deferral Header Archive"."Deferral Doc. Type";
        }
        /// <summary>
        /// Document type ID from the archived source document.
        /// Links to parent Deferral Header Archive record.
        /// </summary>
        field(4; "Document Type"; Integer)
        {
            Caption = 'Document Type';
            TableRelation = "Deferral Header Archive"."Document Type";
        }
        /// <summary>
        /// Document number from the archived source document.
        /// Links to parent Deferral Header Archive record.
        /// </summary>
        field(5; "Document No."; Code[20])
        {
            Caption = 'Document No.';
            TableRelation = "Deferral Header Archive"."Document No.";
        }
        /// <summary>
        /// Line number within the archived source document.
        /// Links to parent Deferral Header Archive record.
        /// </summary>
        field(6; "Line No."; Integer)
        {
            Caption = 'Line No.';
            TableRelation = "Deferral Header Archive"."Line No.";
        }
        /// <summary>
        /// Date when this archived deferral amount was scheduled to be recognized.
        /// </summary>
        field(7; "Posting Date"; Date)
        {
            Caption = 'Posting Date';
        }
        /// <summary>
        /// Description of the archived deferral line.
        /// </summary>
        field(8; Description; Text[100])
        {
            Caption = 'Description';
        }
        /// <summary>
        /// Amount that was scheduled to be recognized in the archived document currency.
        /// </summary>
        field(9; Amount; Decimal)
        {
            AutoFormatExpression = Rec."Currency Code";
            AutoFormatType = 1;
            Caption = 'Amount';
        }
        /// <summary>
        /// Amount that was scheduled to be recognized in local currency (LCY) at the time of archiving.
        /// </summary>
        field(10; "Amount (LCY)"; Decimal)
        {
            AutoFormatExpression = '';
            AutoFormatType = 1;
            Caption = 'Amount (LCY)';
        }
        /// <summary>
        /// Currency code of the archived source document.
        /// </summary>
        field(11; "Currency Code"; Code[10])
        {
            Caption = 'Currency Code';
        }
        /// <summary>
        /// Version number of the archived document.
        /// </summary>
        field(5047; "Version No."; Integer)
        {
            Caption = 'Version No.';
        }
        /// <summary>
        /// Document number occurrence for handling duplicate document numbers.
        /// </summary>
        field(5048; "Doc. No. Occurrence"; Integer)
        {
            Caption = 'Doc. No. Occurrence';
        }
    }

    keys
    {
        key(Key1; "Deferral Doc. Type", "Document Type", "Document No.", "Doc. No. Occurrence", "Version No.", "Line No.", "Posting Date")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }
}
