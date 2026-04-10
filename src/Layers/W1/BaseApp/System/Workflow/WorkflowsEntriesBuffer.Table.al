namespace System.Automation;

using System.Environment;

table 832 "Workflows Entries Buffer"
{
    Caption = 'Workflows Entries Buffer';
    ReplicateData = false;
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Created by Application"; Option)
        {
            Caption = 'Created by Application';
            DataClassification = SystemMetadata;
            OptionCaption = 'Power Automate,Dynamics 365,Dynamics NAV';
            OptionMembers = "Microsoft Flow","Dynamics 365","Dynamics NAV";
        }
        field(2; "Entry No."; Integer)
        {
            Caption = 'Entry No.';
            DataClassification = SystemMetadata;
        }
        field(3; "Workflow Step Instance ID"; Guid)
        {
            Caption = 'Workflow Step Instance ID';
            DataClassification = SystemMetadata;
        }
        field(4; "Record ID"; RecordID)
        {
            Caption = 'Record ID';
            DataClassification = CustomerContent;
        }
        field(5; "Initiated By User ID"; Code[50])
        {
            Caption = 'Initiated By User ID';
            DataClassification = SystemMetadata;
        }
        field(6; "To Be Approved By User ID"; Code[50])
        {
            Caption = 'To Be Approved By User ID';
            DataClassification = SystemMetadata;
        }
        field(7; "Date-Time Initiated"; DateTime)
        {
            Caption = 'Date-Time Initiated';
            DataClassification = SystemMetadata;
        }
        field(8; "Last Date-Time Modified"; DateTime)
        {
            Caption = 'Last Date-Time Modified';
            DataClassification = SystemMetadata;
        }
        field(9; "Last Modified By User ID"; Code[50])
        {
            Caption = 'Last Modified By User ID';
            DataClassification = SystemMetadata;
        }
        field(10; Status; Enum "Approval Status")
        {
            Caption = 'Status';
            DataClassification = SystemMetadata;
        }
        field(11; Response; Option)
        {
            Caption = 'Response';
            DataClassification = SystemMetadata;
            OptionCaption = 'NotExpected,Pending,Cancel,Continue,Reject, ';
            OptionMembers = NotExpected,Pending,Cancel,Continue,Reject," ";
        }
        field(12; Amount; Integer)
        {
            Caption = 'Amount';
            DataClassification = SystemMetadata;
        }
        field(13; "Due Date"; Date)
        {
            Caption = 'Due Date';
            DataClassification = SystemMetadata;
        }
    }

    keys
    {
        key(Key1; "Workflow Step Instance ID")
        {
            Clustered = true;
        }
        key(Key2; "Entry No.")
        {
        }
        key(Key3; "Record ID", "Last Date-Time Modified")
        {
        }
    }

    fieldgroups
    {
    }

    procedure AddWorkflowWebhookEntry(WorkflowWebhookEntry: Record "Workflow Webhook Entry"; var WorkflowsCounter: Integer)
    begin
        if not Get(WorkflowWebhookEntry."Workflow Step Instance ID") then begin
            WorkflowsCounter := WorkflowsCounter + 1;
            Init();
            "Created by Application" := "Created by Application"::"Microsoft Flow";
            "Entry No." := WorkflowWebhookEntry."Entry No.";
            "Workflow Step Instance ID" := WorkflowWebhookEntry."Workflow Step Instance ID";
            "Record ID" := WorkflowWebhookEntry."Record ID";
            "Initiated By User ID" := WorkflowWebhookEntry."Initiated By User ID";
            "Date-Time Initiated" := WorkflowWebhookEntry."Date-Time Initiated";
            "Last Date-Time Modified" := WorkflowWebhookEntry."Last Date-Time Modified";
            "Last Modified By User ID" := WorkflowWebhookEntry."Last Modified By User ID";
            Response := WorkflowWebhookEntry.Response;
            Status := Status::" ";
            Insert();
        end;
    end;

    procedure AddApprovalEntry(ApprovalEntry: Record "Approval Entry"; var WorkflowsCounter: Integer)
    var
        EnvironmentInfo: Codeunit "Environment Information";
    begin
        if not Get(ApprovalEntry."Workflow Step Instance ID") then begin
            WorkflowsCounter := WorkflowsCounter + 1;
            Init();
            if EnvironmentInfo.IsSaaS() then
                "Created by Application" := "Created by Application"::"Dynamics 365"
            else
                "Created by Application" := "Created by Application"::"Dynamics NAV";
            "Entry No." := WorkflowsCounter;
            "Workflow Step Instance ID" := ApprovalEntry."Workflow Step Instance ID";
            "Record ID" := ApprovalEntry."Record ID to Approve";
            "Initiated By User ID" := ApprovalEntry."Sender ID";
            "To Be Approved By User ID" := ApprovalEntry."Approver ID";
            "Date-Time Initiated" := ApprovalEntry."Date-Time Sent for Approval";
            "Last Date-Time Modified" := ApprovalEntry."Last Date-Time Modified";
            "Last Modified By User ID" := ApprovalEntry."Last Modified By User ID";
            Status := ApprovalEntry.Status;
            Response := Response::" ";
            "Due Date" := ApprovalEntry."Due Date";
            Insert();
        end;
    end;
}

