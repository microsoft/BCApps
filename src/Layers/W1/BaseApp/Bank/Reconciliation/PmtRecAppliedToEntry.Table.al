// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Bank.Reconciliation;

using Microsoft.Finance.GeneralLedger.Journal;

table 185 "Pmt. Rec. Applied-to Entry"
{
    Caption = 'Payment Reconciliation Applied-to Entry';
    ReplicateData = false;
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Entry No."; Integer)
        {
            Caption = 'Entry No.';
        }
        field(2; "Entry Type"; Enum "Gen. Journal Source Type")
        {
            Caption = 'Entry Type';
        }
        field(3; "Bank Account No."; Code[20])
        {
            Caption = 'Bank Account No.';
        }
        field(4; "Statement No."; Code[20])
        {
            Caption = 'Statement No.';
        }
        field(5; "Statement Line No."; Integer)
        {
            Caption = 'Statement Line No.';
        }
        field(6; "Applied by Entry No."; Integer)
        {
            Caption = 'Applied by Entry No.';
        }
        field(7; "Amount"; Decimal)
        {
            Caption = 'Amount';
        }
    }
    keys
    {
        key(Key1; "Entry No.", "Entry Type", "Bank Account No.", "Statement No.", "Statement Line No.", "Applied by Entry No.")
        {
            Clustered = true;
        }
    }
}
