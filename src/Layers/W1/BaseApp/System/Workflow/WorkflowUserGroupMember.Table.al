namespace System.Automation;

using System.Security.User;

table 1541 "Workflow User Group Member"
{
    Caption = 'Workflow User Group Member';
    ReplicateData = true;
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Workflow User Group Code"; Code[20])
        {
            Caption = 'Workflow User Group Code';
            TableRelation = "Workflow User Group".Code;
        }
        field(2; "User Name"; Code[50])
        {
            Caption = 'User Name';
            DataClassification = EndUserIdentifiableInformation;
            TableRelation = "User Setup"."User ID";

            trigger OnValidate()
            var
                UserSetup: Record "User Setup";
                WorkflowUserGroupMember: Record "Workflow User Group Member";
                SequenceNo: Integer;
            begin
                UserSetup.Get("User Name");

                if "Sequence No." = 0 then begin
                    SequenceNo := 1;
                    WorkflowUserGroupMember.SetCurrentKey("Workflow User Group Code", "Sequence No.");
                    WorkflowUserGroupMember.SetRange("Workflow User Group Code", "Workflow User Group Code");
                    if WorkflowUserGroupMember.FindLast() then
                        SequenceNo := WorkflowUserGroupMember."Sequence No." + 1;
                    Validate("Sequence No.", SequenceNo);
                end;
            end;
        }
        field(3; "Sequence No."; Integer)
        {
            Caption = 'Sequence No.';
            MinValue = 1;
        }
    }

    keys
    {
        key(Key1; "Workflow User Group Code", "User Name")
        {
            Clustered = true;
        }
        key(Key2; "Workflow User Group Code", "Sequence No.", "User Name")
        {
        }
    }

    fieldgroups
    {
    }
}

