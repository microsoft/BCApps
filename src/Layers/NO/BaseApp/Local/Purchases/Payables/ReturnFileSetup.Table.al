// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Purchases.Payables;

table 15000006 "Return File Setup"
{
    Caption = 'Return File Setup';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Agreement Code"; Code[10])
        {
            Caption = 'Agreement Code';
            TableRelation = "Remittance Agreement".Code;
        }
        field(2; "Line No."; Integer)
        {
            Caption = 'Line No.';
        }
        field(10; "Return File Name"; Text[250])
        {
            Caption = 'Return File Name';
            NotBlank = true;
        }
    }

    keys
    {
        key(Key1; "Agreement Code", "Line No.")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }
}

