namespace System.Automation;

table 1540 "Workflow User Group"
{
    Caption = 'Workflow User Group';
    DataCaptionFields = "Code", Description;
    LookupPageID = "Workflow User Groups";
    ReplicateData = true;
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Code"; Code[20])
        {
            Caption = 'Code';
            NotBlank = true;
        }
        field(2; Description; Text[100])
        {
            Caption = 'Description';
        }
    }

    keys
    {
        key(Key1; "Code")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }

    trigger OnDelete()
    var
        WorkflowUserGroupMember: Record "Workflow User Group Member";
    begin
        WorkflowUserGroupMember.SetRange("Workflow User Group Code", Code);
        if not WorkflowUserGroupMember.IsEmpty() then
            WorkflowUserGroupMember.DeleteAll(true);
    end;
}

