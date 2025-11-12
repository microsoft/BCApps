namespace System.Automation;

using System.Security.AccessControl;

table 1504 "Workflow Step Instance"
{
    Caption = 'Workflow Step Instance';
    Permissions = tabledata Workflow = r,
                  tabledata "Workflow Event" = r,
                  TableData "Workflow Step Instance" = rd,
                  TableData "Workflow - Table Relation" = r,
                  TableData "Workflow Table Relation Value" = rimd,
                  TableData "Workflow Rule" = rd,
                  TableData "Workflow Step Instance Archive" = rimd;
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
            TableRelation = "Workflow Step"."Workflow Code";
        }
        field(3; "Workflow Step ID"; Integer)
        {
            Caption = 'Workflow Step ID';
            TableRelation = "Workflow Step".ID where("Workflow Code" = field("Workflow Code"));
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
            TableRelation = User."User Name";
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
            TableRelation = if (Type = const(Event)) "Workflow Event"
            else
            if (Type = const(Response)) "Workflow Response";
        }
        field(23; Argument; Guid)
        {
            Caption = 'Argument';
            TableRelation = "Workflow Step Argument" where(Type = field(Type));
        }
        field(30; "Original Workflow Code"; Code[20])
        {
            Caption = 'Original Workflow Code';
            TableRelation = "Workflow Step"."Workflow Code";
        }
        field(31; "Original Workflow Step ID"; Integer)
        {
            Caption = 'Original Workflow Step ID';
            TableRelation = "Workflow Step".ID where("Workflow Code" = field("Original Workflow Code"));
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
        key(Key2; "Sequence No.")
        {
        }
        key(Key3; "Workflow Code", ID, "Workflow Step ID")
        {
        }
        key(Key4; "Function Name")
        {
            IncludedFields = Status, Type;
        }
        key(Key5; "Record ID")
        {
            IncludedFields = Status, Type, "Function Name";
        }
        key(Key6; Type, Status, "Function Name", "Previous Workflow Step ID")
        {
        }
    }

    fieldgroups
    {
    }

    trigger OnDelete()
    var
        WorkflowTableRelationValue: Record "Workflow Table Relation Value";
    begin
        WorkflowTableRelationValue.SetRange("Workflow Step Instance ID", ID);
        WorkflowTableRelationValue.SetRange("Workflow Code", "Workflow Code");
        if not WorkflowTableRelationValue.IsEmpty() then
            WorkflowTableRelationValue.DeleteAll();
        DeleteStepInstanceRules();
        RemoveRecordRestrictions();
    end;

    trigger OnInsert()
    begin
        "Created Date-Time" := RoundDateTime(CurrentDateTime, 60000);
        "Created By User ID" := UserId();
    end;

    trigger OnModify()
    begin
        "Last Modified Date-Time" := RoundDateTime(CurrentDateTime, 60000);
        "Last Modified By User ID" := UserId;
    end;

    var
        ActiveInstancesWillBeArchivedQst: Label 'Are you sure you want to archive all workflow step instances in the workflow?';
        NothingToArchiveMsg: Label 'There is nothing to archive.';

    procedure MoveForward(Variant: Variant)
    var
        NextWorkflowStepInstance: Record "Workflow Step Instance";
        WorkflowMgt: Codeunit "Workflow Management";
        RecRef: RecordRef;
    begin
        RecRef.GetTable(Variant);
        "Record ID" := RecRef.RecordId;

        if "Next Workflow Step ID" > 0 then begin
            WorkflowMgt.UpdateStatus(Rec, Status::Completed, Status::Inactive, Status::Ignored);
            NextWorkflowStepInstance.Get(ID, "Workflow Code", "Next Workflow Step ID");

            case NextWorkflowStepInstance.Type of
                NextWorkflowStepInstance.Type::"Event":
                    WorkflowMgt.UpdateStatus(NextWorkflowStepInstance, Status::Active, Status::Inactive, Status::Ignored);
                NextWorkflowStepInstance.Type::Response:
                    WorkflowMgt.UpdateStatus(NextWorkflowStepInstance, Status::Completed, Status::Active, Status::Ignored);
            end;
        end else
            WorkflowMgt.UpdateStatus(Rec, Status::Completed, Status::Active, Status::Ignored);

        if not TableRelationValuesExist(RecRef) then
            SetTableRelationValues(RecRef);
    end;

    procedure TableRelationValuesExist(RecRef: RecordRef): Boolean
    var
        WorkflowTableRelationValue: Record "Workflow Table Relation Value";
    begin
        WorkflowTableRelationValue.SetRange("Workflow Step Instance ID", ID);
        WorkflowTableRelationValue.SetRange("Table ID", RecRef.Number);
        exit(not WorkflowTableRelationValue.IsEmpty);
    end;

    procedure SetTableRelationValues(RecRef: RecordRef)
    var
        WorkflowTableRelation: Record "Workflow - Table Relation";
        WorkflowTableRelationValue: Record "Workflow Table Relation Value";
        WorkflowInstance: Query "Workflow Instance";
    begin
        WorkflowTableRelation.SetRange("Table ID", RecRef.Number);
        if WorkflowTableRelation.FindSet() then
            repeat
                WorkflowInstance.SetRange(Code, "Workflow Code");
                WorkflowInstance.SetRange(Instance_ID, ID);
                WorkflowInstance.SetFilter(Status, '<>%1|%2', Status::Completed, Status::Ignored);
                WorkflowInstance.Open();

                while WorkflowInstance.Read() do
                    WorkflowTableRelationValue.CreateNew(WorkflowInstance.Step_ID, Rec, WorkflowTableRelation, RecRef);
            until WorkflowTableRelation.Next() = 0;
    end;

    procedure MatchesRecordValues(RecRef: RecordRef): Boolean
    var
        WorkflowTableRelationValue: Record "Workflow Table Relation Value";
        FieldRef: FieldRef;
        SkipRecord: Boolean;
        ComparisonValue: Text;
    begin
        WorkflowTableRelationValue.ReadIsolation := ReadIsolation::ReadUncommitted;
        WorkflowTableRelationValue.SetRange("Workflow Step Instance ID", ID);
        WorkflowTableRelationValue.SetRange("Workflow Code", "Workflow Code");
        WorkflowTableRelationValue.SetRange("Workflow Step ID", "Workflow Step ID");
        WorkflowTableRelationValue.SetRange("Related Table ID", RecRef.Number);
        if WorkflowTableRelationValue.FindSet() then begin
            repeat
                FieldRef := RecRef.Field(WorkflowTableRelationValue."Related Field ID");
                if WorkflowTableRelationValue."Field ID" <> 0 then
                    ComparisonValue := WorkflowTableRelationValue.Value
                else
                    ComparisonValue := Format(WorkflowTableRelationValue."Record ID");
                if Format(FieldRef.Value) <> ComparisonValue then
                    SkipRecord := true;
            until (WorkflowTableRelationValue.Next() = 0) or SkipRecord;
            exit(not SkipRecord);
        end;

        exit(false);
    end;

    procedure ArchiveActiveInstances(Workflow: Record Workflow)
    var
        WorkflowStepInstanceArchive: Record "Workflow Step Instance Archive";
    begin
        Workflow.CopyFilter(Code, "Workflow Code");
        if not FindSet() then
            Message(NothingToArchiveMsg)
        else
            if Confirm(ActiveInstancesWillBeArchivedQst) then begin
                repeat
                    WorkflowStepInstanceArchive.TransferFields(Rec, true);
                    WorkflowStepInstanceArchive.Insert(true);
                until Next() = 0;
                DeleteAll(true);
            end;
    end;

    procedure ToString(): Text
    begin
        exit(StrSubstNo('%1,%2,%3,%4,%5,%6',
            ID, "Workflow Code", "Workflow Step ID", Type, "Original Workflow Code", "Original Workflow Step ID"));
    end;

    local procedure DeleteStepInstanceRules()
    var
        WorkflowRule: Record "Workflow Rule";
    begin
        if FindWorkflowRules(WorkflowRule) then
            WorkflowRule.DeleteAll();
    end;

    local procedure RemoveRecordRestrictions()
    var
        WorkflowStepInstance: Record "Workflow Step Instance";
        Workflow: Record "Workflow";
        RecordRestrictionMgt: Codeunit "Record Restriction Mgt.";
        EmptyRecordID: RecordId;
        RecRef: RecordRef;
    begin
        if "Record ID" = EmptyRecordID then
            exit;
        if not Workflow.Get("Workflow Code") then
            exit;
        if Workflow.Enabled then
            exit;
        WorkflowStepInstance.SetRange("Record ID", "Record ID");
        WorkflowStepInstance.SetFilter(SystemId, '<>%1', SystemId);
        if not WorkflowStepInstance.IsEmpty() then
            exit;
        if not RecRef.Get("Record ID") then
            exit;
        RecordRestrictionMgt.AllowRecordUsage(RecRef);
    end;

    procedure FindWorkflowRules(var WorkflowRule: Record "Workflow Rule"): Boolean
    begin
        WorkflowRule.ReadIsolation := ReadIsolation::ReadUncommitted;
        WorkflowRule.SetRange("Workflow Code", "Workflow Code");
        WorkflowRule.SetRange("Workflow Step ID", "Workflow Step ID");
        WorkflowRule.SetRange("Workflow Step Instance ID", ID);
        exit(not WorkflowRule.IsEmpty);
    end;

    procedure BuildTempWorkflowTree(WorkflowInstanceId: Guid)
    var
        NewStepId: Integer;
    begin
        if not IsTemporary then
            exit;

        CreateTree(Rec, WorkflowInstanceId, 0, NewStepId);

        SetRange(ID, WorkflowInstanceId);
        SetRange("Workflow Step ID");
        if FindSet() then;
    end;

    local procedure CreateTree(var TempWorkflowStepInstance: Record "Workflow Step Instance" temporary; WorkflowInstanceId: Guid; OriginalStepId: Integer; var NewStepId: Integer)
    var
        WorkflowStepInstance: Record "Workflow Step Instance";
    begin
        if OriginalStepId <> 0 then
            CreateNode(TempWorkflowStepInstance, WorkflowInstanceId, OriginalStepId, NewStepId);

        WorkflowStepInstance.SetLoadFields("Workflow Step ID");
        WorkflowStepInstance.SetRange(ID, WorkflowInstanceId);
        WorkflowStepInstance.SetRange("Previous Workflow Step ID", OriginalStepId);
        WorkflowStepInstance.SetCurrentKey("Sequence No.");

        if WorkflowStepInstance.FindSet() then
            repeat
                NewStepId += 1;
                CreateTree(TempWorkflowStepInstance, WorkflowInstanceId, WorkflowStepInstance."Workflow Step ID", NewStepId);
            until WorkflowStepInstance.Next() = 0;
    end;

    local procedure CreateNode(var TempWorkflowStepInstance: Record "Workflow Step Instance" temporary; WorkflowInstanceId: Guid; OriginalStepId: Integer; NewStepId: Integer)
    var
        SrcWorkflowStepInstance: Record "Workflow Step Instance";
    begin
        if NewStepId = 0 then
            Error(WorkflowStepIdErr);

        SrcWorkflowStepInstance.SetRange(ID, WorkflowInstanceId);
        SrcWorkflowStepInstance.SetRange("Workflow Step ID", OriginalStepId);
        SrcWorkflowStepInstance.FindFirst();

        Clear(TempWorkflowStepInstance);
        TempWorkflowStepInstance.Init();
        TempWorkflowStepInstance.Copy(SrcWorkflowStepInstance);
        TempWorkflowStepInstance."Workflow Step ID" := NewStepId;
        TempWorkflowStepInstance.Insert();
    end;

    var
        WorkflowStepIdErr: Label 'Workflow Step ID must be set.';
}

