namespace System.Automation;

using Microsoft.Purchases.Document;
using Microsoft.Sales.Document;
using Microsoft.Utilities;
using System.Email;
using System.Environment.Configuration;
using System.Security.AccessControl;
using System.Security.User;

table 458 "Overdue Approval Entry"
{
    Caption = 'Overdue Approval Entry';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Table ID"; Integer)
        {
            Caption = 'Table ID';
        }
        field(2; "Document Type"; Enum "Approval Document Type")
        {
            Caption = 'Document Type';
        }
        field(3; "Document No."; Code[20])
        {
            Caption = 'Document No.';
            TableRelation = if ("Table ID" = const(36)) "Sales Header"."No." where("Document Type" = field("Document Type"))
            else
            if ("Table ID" = const(38)) "Purchase Header"."No." where("Document Type" = field("Document Type"));
        }
        field(4; "Sent to ID"; Code[50])
        {
            Caption = 'Sent to ID';
            TableRelation = "User Setup";
        }
        field(5; "Sent Time"; Time)
        {
            Caption = 'Sent Time';
        }
        field(6; "Sent Date"; Date)
        {
            Caption = 'Sent Date';
        }
        field(7; "E-Mail"; Text[100])
        {
            Caption = 'Email';
            ExtendedDatatype = EMail;

            trigger OnValidate()
            var
                MailManagement: Codeunit "Mail Management";
            begin
                MailManagement.ValidateEmailAddressField("E-Mail");
            end;
        }
        field(8; "Sent to Name"; Text[30])
        {
            Caption = 'Sent to Name';
        }
        field(9; "Sequence No."; Integer)
        {
            Caption = 'Sequence No.';
        }
        field(10; "Due Date"; Date)
        {
            Caption = 'Due Date';
        }
        field(11; "Approver ID"; Code[50])
        {
            Caption = 'Approver ID';
            DataClassification = EndUserIdentifiableInformation;
            TableRelation = User."User Name";
        }
        field(12; "Approval Code"; Code[20])
        {
            Caption = 'Approval Code';
        }
        field(13; "Approval Type"; Enum "Workflow Approval Type")
        {
            Caption = 'Approval Type';
        }
        field(14; "Limit Type"; Enum "Workflow Approval Limit Type")
        {
            Caption = 'Limit Type';
        }
        field(15; "Record ID to Approve"; RecordID)
        {
            Caption = 'Record ID to Approve';
            DataClassification = CustomerContent;
        }
    }

    keys
    {
        key(Key1; "Table ID", "Document Type", "Document No.", "Sequence No.", "Sent Date", "Sent Time", "Record ID to Approve")
        {
            Clustered = true;
        }
        key(Key2; "Approver ID")
        {
        }
    }

    fieldgroups
    {
    }

    trigger OnDelete()
    var
        NotificationEntry: Record "Notification Entry";
    begin
        NotificationEntry.SetRange(Type, NotificationEntry.Type::Overdue);
        NotificationEntry.SetRange("Triggered By Record", RecordId);
        NotificationEntry.DeleteAll(true);
    end;

    procedure ShowRecord()
    var
        PageManagement: Codeunit "Page Management";
        RecRef: RecordRef;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeShowRecord(Rec, IsHandled);
        if IsHandled then
            exit;

        if not RecRef.Get("Record ID to Approve") then
            exit;

        RecRef.SetRecFilter();
        PageManagement.PageRun(RecRef);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeShowRecord(var OverdueApprovalEntry: Record "Overdue Approval Entry"; var IsHandled: Boolean)
    begin
    end;
}

