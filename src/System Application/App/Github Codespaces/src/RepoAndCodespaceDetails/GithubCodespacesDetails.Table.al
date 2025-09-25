// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.Integration.Codespaces;

table 8434 "GitHub Codespaces Details"
{
    TableType = Temporary;

    fields
    {
        field(1; "Entry No."; Integer)
        {
            Caption = 'Entry No.';
        }
        field(10; "Codespace ID"; BigInteger)
        {
            Caption = 'Codespace ID';
        }
        field(20; Name; Text[100])
        {
            Caption = 'Codespace Name';
        }
        field(30; "Display Name"; Text[100])
        {
            Caption = 'Display Name';
        }
        field(40; "Repository Name"; Text[100])
        {
            Caption = 'Repository Name';
        }
        field(50; "Repository Full Name"; Text[200])
        {
            Caption = 'Repository Full Name';
        }
        field(60; "Owner Login"; Text[100])
        {
            Caption = 'Owner Login';
        }
        field(70; State; Text[20])
        {
            Caption = 'State';
        }
        field(80; "Web URL"; Text[250])
        {
            Caption = 'Web URL';
        }
        field(90; "Machine Display Name"; Text[50])
        {
            Caption = 'Machine Type';
        }
        field(100; "Created At"; DateTime)
        {
            Caption = 'Created At';
        }
        field(110; "Updated At"; DateTime)
        {
            Caption = 'Updated At';
        }
        field(120; "Last Used At"; DateTime)
        {
            Caption = 'Last Used At';
        }
        field(130; "Git Status"; Text[50])
        {
            Caption = 'Git Status';
        }
        field(140; Location; Text[50])
        {
            Caption = 'Location';
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