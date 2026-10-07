namespace System.Automation;

using System.Security.AccessControl;

table 1530 "Workflow Step Instance Archive"
{
    Caption = 'Workflow Step Instance Archive';
    Permissions = TableData "Workflow Step Argument Archive" = md,
                  TableData "Workflow Record Change Archive" = md;
    ReplicateData = true;
    DataClassification = CustomerContent;

    fields
    {
        field(1; ID; Guid)
        {
            Caption = 'ID';
        }
        field(2; "Workflow Code"; Code[20])
        {
            Caption = 'Workflow Code';
        }
        field(3; "Workflow Step ID"; Integer)
        {
            Caption = 'Workflow Step ID';
        }
        field(4; Description; Text[100])
        {
            Caption = 'Description';
        }
        field(9; "Entry Point"; Boolean)
        {
            Caption = 'Entry Point';
        }
        field(11; "Record ID"; RecordID)
        {
            Caption = 'Record ID';
            DataClassification = CustomerContent;
        }
        field(12; "Created Date-Time"; DateTime)
        {
            Caption = 'Created Date-Time';
            Editable = false;
        }
        field(13; "Created By User ID"; Code[50])
        {
            Caption = 'Created By User ID';
            DataClassification = EndUserIdentifiableInformation;
            Editable = false;
        }
        field(14; "Last Modified Date-Time"; DateTime)
        {
            Caption = 'Last Modified Date-Time';
            Editable = false;
        }
        field(15; "Last Modified By User ID"; Code[50])
        {
            Caption = 'Last Modified By User ID';
            DataClassification = EndUserIdentifiableInformation;
            Editable = false;
            TableRelation = User."User Name";
        }
        field(17; Status; Option)
        {
            Caption = 'Status';
            OptionCaption = 'Inactive,Active,Completed,Ignored,Processing';
            OptionMembers = Inactive,Active,Completed,Ignored,Processing;
        }
        field(18; "Previous Workflow Step ID"; Integer)
        {
            Caption = 'Previous Workflow Step ID';
        }
        field(19; "Next Workflow Step ID"; Integer)
        {
            Caption = 'Next Workflow Step ID';
        }
        field(21; Type; Option)
        {
            Caption = 'Type';
            OptionCaption = 'Event,Response';
            OptionMembers = "Event",Response;
        }
        field(22; "Function Name"; Code[128])
        {
            Caption = 'Function Name';
        }
        field(23; Argument; Guid)
        {
            Caption = 'Argument';
        }
        field(30; "Original Workflow Code"; Code[20])
        {
            Caption = 'Original Workflow Code';
        }
        field(31; "Original Workflow Step ID"; Integer)
        {
            Caption = 'Original Workflow Step ID';
        }
        field(32; "Sequence No."; Integer)
        {
            Caption = 'Sequence No.';
        }
    }

    keys
    {
        key(Key1; ID, "Workflow Code", "Workflow Step ID")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }

    trigger OnDelete()
    var
        WorkflowStepArgumentArchive: Record "Workflow Step Argument Archive";
        WorkflowRecordChangeArchive: record "Workflow Record Change Archive";
    begin
        if WorkflowStepArgumentArchive.Get(Argument) then
            WorkflowStepArgumentArchive.Delete(true);

        WorkflowRecordChangeArchive.SetRange("Workflow Step Instance ID", Rec.ID);
        WorkflowRecordChangeArchive.DeleteAll();
    end;
}

