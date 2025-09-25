// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.Integration.Codespaces;

table 8431 "GitHub Repository Details"
{
    TableType = Temporary;

    fields
    {
        field(1; "Entry No."; Integer)
        {
            Caption = 'Entry No.';
        }
        field(10; "Repository ID"; BigInteger)
        {
            Caption = 'Repository ID';
        }
        field(20; "Repository Name"; Text[100])
        {
            Caption = 'Repository Name';
        }
        field(30; "Full Name"; Text[200])
        {
            Caption = 'Full Name';
        }
        field(40; Description; Text[250])
        {
            Caption = 'Description';
        }
        field(50; "HTML URL"; Text[250])
        {
            Caption = 'HTML URL';
        }
        field(80; Private; Boolean)
        {
            Caption = 'Private';
        }
        field(90; "Is Template"; Boolean)
        {
            Caption = 'Is Template';
        }
        field(160; "Owner Login"; Text[100])
        {
            Caption = 'Owner Login';
        }
        field(170; "Owner Type"; Text[20])
        {
            Caption = 'Owner Type';
        }
    }

    keys
    {
        key(PK; "Entry No.")
        {
            Clustered = true;
        }
    }
}