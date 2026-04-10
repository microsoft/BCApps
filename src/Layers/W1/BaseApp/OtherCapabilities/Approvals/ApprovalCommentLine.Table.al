// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace System.Automation;

using Microsoft.Utilities;
using System.Security.AccessControl;

table 455 "Approval Comment Line"
{
    Caption = 'Approval Comment Line';
    DrillDownPageID = "Approval Comments";
    LookupPageID = "Approval Comments";
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Entry No."; Integer)
        {
            Caption = 'Entry No.';
            Editable = false;
        }
        field(2; "Table ID"; Integer)
        {
            Caption = 'Table ID';
            Editable = false;
        }
        field(3; "Document Type"; Enum "Approval Document Type")
        {
            Caption = 'Document Type';
            Editable = false;
        }
        field(4; "Document No."; Code[20])
        {
            Caption = 'Document No.';
            Editable = false;
        }
        field(5; "User ID"; Code[50])
        {
            Caption = 'User ID';
            DataClassification = EndUserIdentifiableInformation;
            Editable = false;
            TableRelation = User."User Name";
        }
        field(6; "Date and Time"; DateTime)
        {
            Caption = 'Date and Time';
            Editable = false;
        }
        field(7; Comment; Text[80])
        {
            Caption = 'Comment';
        }
        field(8; "Record ID to Approve"; RecordID)
        {
            Caption = 'Record ID to Approve';
            DataClassification = CustomerContent;
        }
        field(9; "Workflow Step Instance ID"; Guid)
        {
            Caption = 'Workflow Step Instance ID';
        }
    }

    keys
    {
        key(Key1; "Entry No.")
        {
            Clustered = true;
        }
        key(Key2; "Table ID", "Document Type", "Document No.", "Record ID to Approve")
        {
        }
        key(Key3; "Workflow Step Instance ID")
        {
        }
    }

    fieldgroups
    {
    }

    trigger OnInsert()
    begin
        Evaluate("Table ID", GetFilter("Table ID"));
        Evaluate("Record ID to Approve", GetFilter("Record ID to Approve"));
        "User ID" := CopyStr(UserId(), 1, MaxStrLen("User ID"));
        "Date and Time" := CreateDateTime(Today, Time);
        if "Entry No." = 0 then
            "Entry No." := GetLastEntryNo() + 1;
    end;

    procedure GetLastEntryNo(): Integer;
    var
        FindRecordManagement: Codeunit "Find Record Management";
    begin
        exit(FindRecordManagement.GetLastEntryIntFieldValue(Rec, FieldNo("Entry No.")))
    end;
}

