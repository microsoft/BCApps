// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.VAT.Reporting;

/// <summary>
/// Links VAT entries to ECSL report lines for tracking which transactions are included in EU sales list reports.
/// Provides audit trail between source VAT entries and summarized ECSL reporting data.
/// </summary>
table 143 "ECSL VAT Report Line Relation"
{
    Caption = 'ECSL VAT Report Line Relation';
    DataClassification = CustomerContent;

    fields
    {
        /// <summary>
        /// VAT entry number that contributes to the ECSL report line totals.
        /// </summary>
        field(1; "VAT Entry No."; Integer)
        {
            Caption = 'VAT Entry No.';
        }
        /// <summary>
        /// ECSL report line number that includes this VAT entry in its calculations.
        /// </summary>
        field(2; "ECSL Line No."; Integer)
        {
            Caption = 'ECSL Line No.';
        }
        /// <summary>
        /// ECSL report number containing the related line and VAT entry.
        /// </summary>
        field(3; "ECSL Report No."; Code[20])
        {
            Caption = 'ECSL Report No.';
        }
    }

    keys
    {
        key(Key1; "VAT Entry No.", "ECSL Line No.", "ECSL Report No.")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }
}

