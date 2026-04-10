namespace System.Automation;

using Microsoft.Utilities;
using System.Security.AccessControl;

table 457 "Posted Approval Comment Line"
{
    Caption = 'Posted Approval Comment Line';
    DrillDownPageID = "Posted Approval Comments";
    LookupPageID = "Posted Approval Comments";
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
        field(4; "Document No."; Code[20])
        {
            Caption = 'Document No.';
        }
        field(5; "User ID"; Code[50])
        {
            Caption = 'User ID';
            DataClassification = EndUserIdentifiableInformation;
            TableRelation = User."User Name";
        }
        field(6; "Date and Time"; DateTime)
        {
            Caption = 'Date and Time';
        }
        field(7; Comment; Text[80])
        {
            Caption = 'Comment';
        }
        field(8; "Posted Record ID"; RecordID)
        {
            Caption = 'Posted Record ID';
            DataClassification = CustomerContent;
        }
    }

    keys
    {
        key(Key1; "Entry No.")
        {
            Clustered = true;
        }
        key(Key2; "Table ID", "Document No.", "Date and Time")
        {
        }
    }

    fieldgroups
    {
    }

    trigger OnInsert()
    begin
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

