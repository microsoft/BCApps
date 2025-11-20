// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.GeneralLedger.Account;

using Microsoft.Utilities;

table 180 "G/L Account Where-Used"
{
    Caption = 'G/L Account Where-Used';
    LookupPageID = "G/L Account Where-Used List";
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Entry No."; Integer)
        {
            Caption = 'Entry No.';
        }
        field(2; "Table ID"; Integer)
        {
            Caption = 'Table ID';
        }
        field(3; "Table Name"; Text[150])
        {
            Caption = 'Table Name';
        }
        field(5; "Field Name"; Text[150])
        {
            Caption = 'Field Name';
        }
        field(6; Line; Text[250])
        {
            Caption = 'Line';
        }
        field(7; "G/L Account No."; Code[20])
        {
            Caption = 'G/L Account No.';
        }
        field(8; "G/L Account Name"; Text[100])
        {
            Caption = 'G/L Account Name';
        }
        field(9; "Key 1"; Text[50])
        {
            Caption = 'Key 1';
        }
        field(10; "Key 2"; Text[50])
        {
            Caption = 'Key 2';
        }
        field(11; "Key 3"; Text[50])
        {
            Caption = 'Key 3';
        }
        field(12; "Key 4"; Text[50])
        {
            Caption = 'Key 4';
        }
    }

    keys
    {
        key(Key1; "Entry No.")
        {
            Clustered = true;
        }
        key(Key2; "Table Name")
        {
        }
    }

    fieldgroups
    {
    }

    procedure Caption(): Text
    begin
        exit(StrSubstNo('%1 %2', "G/L Account No.", "G/L Account Name"));
    end;

    procedure GetLastEntryNo(): Integer;
    var
        FindRecordManagement: Codeunit "Find Record Management";
    begin
        exit(FindRecordManagement.GetLastEntryIntFieldValue(Rec, FieldNo("Entry No.")))
    end;
}

