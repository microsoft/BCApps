// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Bank.Payment;

/// <summary>
/// Table 1209 "Credit Trans Re-export History" tracks the history of credit transfer file re-exports.
/// Maintains an audit trail of when payment files are re-exported, including date/time stamps
/// and user information for compliance and tracking purposes.
/// </summary>
table 1209 "Credit Trans Re-export History"
{
    Caption = 'Credit Trans Re-export History';
    DataClassification = CustomerContent;

    fields
    {
        /// <summary>
        /// Unique sequential number for the re-export history entry.
        /// </summary>
        field(1; "No."; Integer)
        {
            AutoIncrement = true;
            Caption = 'No.';
        }
        /// <summary>
        /// Credit transfer register number that was re-exported.
        /// </summary>
        field(2; "Credit Transfer Register No."; Integer)
        {
            Caption = 'Credit Transfer Register No.';
            TableRelation = "Credit Transfer Register";
        }
        /// <summary>
        /// Date and time when the re-export occurred.
        /// </summary>
        field(3; "Re-export Date"; DateTime)
        {
            Caption = 'Re-export Date';
        }
        /// <summary>
        /// User who performed the re-export operation.
        /// </summary>
        field(4; "Re-exported By"; Code[50])
        {
            Caption = 'Re-exported By';
            DataClassification = EndUserIdentifiableInformation;
        }
    }

    keys
    {
        key(Key1; "No.")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }

    trigger OnInsert()
    begin
        "Re-export Date" := CurrentDateTime;
        "Re-exported By" := UserId;
    end;
}

