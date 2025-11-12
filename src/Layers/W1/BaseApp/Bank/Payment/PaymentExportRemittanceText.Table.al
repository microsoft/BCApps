// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Bank.Payment;

/// <summary>
/// Stores remittance text lines associated with payment export data entries.
/// This table contains the text information that is included in payment files for remittance purposes.
/// </summary>
table 1229 "Payment Export Remittance Text"
{
    Caption = 'Payment Export Remittance Text';
    DataClassification = CustomerContent;

    fields
    {
        /// <summary>
        /// Specifies the entry number of the payment export data record this remittance text belongs to.
        /// This field links the remittance text to a specific payment export entry.
        /// </summary>
        field(1; "Pmt. Export Data Entry No."; Integer)
        {
            Caption = 'Pmt. Export Data Entry No.';
            TableRelation = "Payment Export Data";
        }
        /// <summary>
        /// Specifies the line number for multiple remittance text lines within the same payment export entry.
        /// This field allows multiple text lines to be associated with a single payment.
        /// </summary>
        field(2; "Line No."; Integer)
        {
            Caption = 'Line No.';
        }
        /// <summary>
        /// Contains the remittance text that will be included in the payment file.
        /// This field stores the actual text content for remittance information.
        /// </summary>
        field(3; Text; Text[140])
        {
            Caption = 'Text';
        }
    }

    keys
    {
        key(Key1; "Pmt. Export Data Entry No.", "Line No.")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }
}

