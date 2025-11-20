// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Bank.Reconciliation;

table 2711 "Bank Acc. Rec. Match Buffer"
{
    Caption = 'Bank Account Reconciliation Many-to-One Matchings';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Ledger Entry No."; Integer)
        {
            Caption = 'Bank Account Ledger Entry No.';
            Editable = false;
        }
        field(2; "Statement No."; Code[20])
        {
            Caption = 'Statement No.';
            Editable = false;
        }
        field(3; "Statement Line No."; Integer)
        {
            Caption = 'Statement Line No.';
            Editable = false;
        }
        field(4; "Bank Account No."; Code[20])
        {
            Caption = 'Bank Account No.';
            Editable = false;
        }
        field(5; "Match ID"; Integer)
        {
            Caption = 'Match ID';
            Editable = false;
        }
        field(6; "Is Processed"; Boolean)
        {
            Caption = 'Is Processed';
            Editable = false;
        }
    }

    keys
    {
        key(key1; "Statement No.", "Statement Line No.", "Bank Account No.", "Match ID")
        {
            Clustered = true;
        }
        key(Key2; "Ledger Entry No.")
        {

        }
        key(Key3; "Bank Account No.", "Statement No.", "Statement Line No.")
        {
        }
    }

    trigger OnDelete()
    begin

    end;
}
