namespace System.Automation;

using Microsoft.Finance.Currency;
using Microsoft.Utilities;
using System.Security.AccessControl;

table 456 "Posted Approval Entry"
{
    Caption = 'Posted Approval Entry';
    DrillDownPageId = "Posted Approval Entries";
    LookupPageId = "Posted Approval Entries";
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Table ID"; Integer)
        {
            Caption = 'Table ID';
        }
        field(3; "Document No."; Code[20])
        {
            Caption = 'Document No.';
        }
        field(4; "Sequence No."; Integer)
        {
            Caption = 'Sequence No.';
        }
        field(5; "Approval Code"; Code[20])
        {
            Caption = 'Approval Code';
        }
        field(6; "Sender ID"; Code[50])
        {
            Caption = 'Sender ID';
            DataClassification = EndUserIdentifiableInformation;
            TableRelation = User."User Name";
        }
        field(7; "Salespers./Purch. Code"; Code[20])
        {
            Caption = 'Salespers./Purch. Code';
        }
        field(8; "Approver ID"; Code[50])
        {
            Caption = 'Approver ID';
            DataClassification = EndUserIdentifiableInformation;
            TableRelation = User."User Name";
        }
        field(9; Status; Enum "Approval Status")
        {
            Caption = 'Status';
        }
        field(10; "Date-Time Sent for Approval"; DateTime)
        {
            Caption = 'Date-Time Sent for Approval';
        }
        field(11; "Last Date-Time Modified"; DateTime)
        {
            Caption = 'Last Date-Time Modified';
        }
        field(12; "Last Modified By ID"; Code[50])
        {
            Caption = 'Last Modified By ID';
            DataClassification = EndUserIdentifiableInformation;
            TableRelation = User."User Name";
        }
        field(13; Comment; Boolean)
        {
            CalcFormula = exist("Posted Approval Comment Line" where("Table ID" = field("Table ID"),
                                                                      "Document No." = field("Document No."),
                                                                      "Posted Record ID" = field("Posted Record ID")));
            Caption = 'Comment';
            Editable = false;
            FieldClass = FlowField;
        }
        field(14; "Due Date"; Date)
        {
            Caption = 'Due Date';
        }
        field(15; Amount; Decimal)
        {
            AutoFormatExpression = Rec."Currency Code";
            AutoFormatType = 1;
            Caption = 'Amount';
        }
        field(16; "Amount (LCY)"; Decimal)
        {
            AutoFormatType = 1;
            Caption = 'Amount (LCY)';
        }
        field(17; "Currency Code"; Code[10])
        {
            Caption = 'Currency Code';
            TableRelation = Currency;
        }
        field(18; "Approval Type"; Enum "Workflow Approval Type")
        {
            Caption = 'Approval Type';
        }
        field(19; "Limit Type"; Enum "Workflow Approval Limit Type")
        {
            Caption = 'Limit Type';
        }
        field(20; "Available Credit Limit (LCY)"; Decimal)
        {
            Caption = 'Available Credit Limit (LCY)';
            AutoFormatType = 1;
        }
        field(22; "Posted Record ID"; RecordID)
        {
            Caption = 'Posted Record ID';
            DataClassification = CustomerContent;
        }
        field(23; "Delegation Date Formula"; DateFormula)
        {
            Caption = 'Delegation Date Formula';
        }
        field(26; "Number of Approved Requests"; Integer)
        {
            Caption = 'Number of Approved Requests';
        }
        field(27; "Number of Rejected Requests"; Integer)
        {
            Caption = 'Number of Rejected Requests';
        }
        field(28; "Iteration No."; Integer)
        {
            Caption = 'Iteration No.';
        }
        field(29; "Entry No."; Integer)
        {
            AutoIncrement = true;
            Caption = 'Entry No.';
        }
    }

    keys
    {
        key(Key1; "Entry No.")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }

    trigger OnDelete()
    var
        PostedApprovalCommentLine: Record "Posted Approval Comment Line";
    begin
        PostedApprovalCommentLine.SetRange("Posted Record ID", "Posted Record ID");
        PostedApprovalCommentLine.DeleteAll();
    end;

    procedure ShowRecord()
    var
        PageManagement: Codeunit "Page Management";
        RecRef: RecordRef;
    begin
        if not RecRef.Get("Posted Record ID") then
            exit;
        RecRef.SetRecFilter();
        PageManagement.PageRun(RecRef);
    end;
}
