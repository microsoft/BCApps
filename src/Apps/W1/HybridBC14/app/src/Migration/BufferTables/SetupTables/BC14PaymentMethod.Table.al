// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.DataMigration.BC14;

table 50192 "BC14 Payment Method"
{
    Caption = 'BC14 Payment Method';
    DataClassification = CustomerContent;
    ReplicateData = false;
    Extensible = false;

    fields
    {
        field(1; "Code"; Code[10])
        {
            Caption = 'Code';
        }
        field(2; "Description"; Text[100])
        {
            Caption = 'Description';
        }
        field(3; "Bal. Account Type"; Option)
        {
            Caption = 'Bal. Account Type';
            OptionMembers = "G/L Account","Bank Account";
            OptionCaption = 'G/L Account,Bank Account';
        }
        field(4; "Bal. Account No."; Code[20])
        {
            Caption = 'Bal. Account No.';
        }
        field(6; "Direct Debit"; Boolean)
        {
            Caption = 'Direct Debit';
        }
        field(7; "Direct Debit Pmt. Terms Code"; Code[10])
        {
            Caption = 'Direct Debit Pmt. Terms Code';
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
