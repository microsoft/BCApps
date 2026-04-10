// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.FixedAssets.Insurance;

using Microsoft.Foundation.AuditCodes;
using Microsoft.Utilities;
using System.Security.AccessControl;

table 5636 "Insurance Register"
{
    Caption = 'Insurance Register';
    LookupPageID = "Insurance Registers";
    DataClassification = CustomerContent;

    fields
    {
        field(1; "No."; Integer)
        {
            Caption = 'No.';
            ToolTip = 'Specifies the number of the involved entry or record, according to the specified number series.';
        }
        field(2; "From Entry No."; Integer)
        {
            Caption = 'From Entry No.';
            ToolTip = 'Specifies the first item entry number in the register.';
            TableRelation = "Ins. Coverage Ledger Entry";
        }
        field(3; "To Entry No."; Integer)
        {
            Caption = 'To Entry No.';
            ToolTip = 'Specifies the last insurance entry number in the register.';
            TableRelation = "Ins. Coverage Ledger Entry";
        }
        field(4; "Creation Date"; Date)
        {
            Caption = 'Creation Date';
            ToolTip = 'Specifies the date when the entries in the register were posted.';
        }
        field(5; "Source Code"; Code[10])
        {
            Caption = 'Source Code';
            ToolTip = 'Specifies the source code that specifies where the entry was created.';
            TableRelation = "Source Code";
        }
        field(6; "User ID"; Code[50])
        {
            Caption = 'User ID';
            ToolTip = 'Specifies the ID of the user who posted the entry, to be used, for example, in the change log.';
            DataClassification = EndUserIdentifiableInformation;
            TableRelation = User."User Name";
        }
        field(7; "Journal Batch Name"; Code[10])
        {
            Caption = 'Journal Batch Name';
            ToolTip = 'Specifies the name of the journal batch, a personalized journal layout, that the entries were posted from.';
        }
        field(9; "Creation Time"; Time)
        {
            Caption = 'Creation Time';
            ToolTip = 'Specifies the time when the entries in the register were posted.';
        }
    }

    keys
    {
        key(Key1; "No.")
        {
            Clustered = true;
        }
        key(Key2; "Creation Date")
        {
        }
        key(Key3; "Source Code", "Journal Batch Name", "Creation Date")
        {
        }
    }

    fieldgroups
    {
    }

    procedure GetLastEntryNo(): Integer;
    var
        FindRecordManagement: Codeunit "Find Record Management";
    begin
        exit(FindRecordManagement.GetLastEntryIntFieldValue(Rec, FieldNo("No.")))
    end;

}

