// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.AuditFileExport;

table 11010 "Data Exp. Primary Key Buffer"
{
    Caption = 'Data Exp. Primary Key Buffer';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Table No."; Integer)
        {
            Caption = 'Table No.';
        }
        field(2; "Index Value 1"; Text[30])
        {
            Caption = 'Index Value 1';
        }
        field(3; "Index Value 2"; Text[30])
        {
            Caption = 'Index Value 2';
        }
        field(4; "Index Value 3"; Text[30])
        {
            Caption = 'Index Value 3';
        }
        field(5; "Index Value 4"; Text[30])
        {
            Caption = 'Index Value 4';
        }
        field(6; "Index Value 5"; Text[30])
        {
            Caption = 'Index Value 5';
        }
        field(7; "Index Value 6"; Text[30])
        {
            Caption = 'Index Value 6';
        }
        field(8; "Index Value 7"; Text[30])
        {
            Caption = 'Index Value 7';
        }
        field(9; "Best Key Index"; Integer)
        {
            Caption = 'Best Key Index';
        }
    }

    keys
    {
        key(Key1; "Table No.", "Index Value 1", "Index Value 2", "Index Value 3", "Index Value 4", "Index Value 5", "Index Value 6", "Index Value 7")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }
}

