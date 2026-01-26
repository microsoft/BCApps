// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Purchases.Payables;

table 15000005 "Return File"
{
    Caption = 'Return File';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Line No."; Integer)
        {
            Caption = 'Line No.';
        }
        field(10; "File Name"; Text[250])
        {
            Caption = 'File Name';
            NotBlank = true;
        }
        field(11; Date; Date)
        {
            Caption = 'Date';
            Editable = false;
        }
        field(12; Time; Time)
        {
            Caption = 'Time';
            Editable = false;
        }
        field(13; Size; Integer)
        {
            Caption = 'Size';
        }
        field(20; Import; Boolean)
        {
            Caption = 'Import';
            InitValue = true;
        }
        field(30; "Agreement Code"; Code[10])
        {
            Caption = 'Agreement Code';
            TableRelation = "Remittance Agreement".Code;
        }
        field(31; Format; Option)
        {
            Caption = 'Format';
            OptionCaption = 'Telepay,BBS,Pain002,CAMT054';
            OptionMembers = Telepay,BBS,Pain002,CAMT054;
        }
    }

    keys
    {
        key(Key1; "Line No.")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }
}

