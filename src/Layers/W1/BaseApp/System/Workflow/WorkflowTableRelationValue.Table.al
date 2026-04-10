namespace System.Automation;

using System.Reflection;

table 1506 "Workflow Table Relation Value"
{
    Caption = 'Workflow Table Relation Value';
    Permissions = TableData "Workflow Step Instance" = r,
                  tabledata "Workflow Table Relation Value" = ri;
    ReplicateData = true;
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Workflow Step Instance ID"; Guid)
        {
            Caption = 'Workflow Step Instance ID';
        }
        field(2; "Workflow Code"; Code[20])
        {
            Caption = 'Workflow Code';
        }
        field(3; "Workflow Step ID"; Integer)
        {
            Caption = 'Workflow Step ID';
        }
        field(4; "Table ID"; Integer)
        {
            Caption = 'Table ID';
            TableRelation = AllObjWithCaption."Object ID" where("Object Type" = const(Table));
        }
        field(5; "Field ID"; Integer)
        {
            Caption = 'Field ID';
            TableRelation = Field."No." where(TableNo = field("Table ID"));
        }
        field(6; "Related Table ID"; Integer)
        {
            Caption = 'Related Table ID';
            TableRelation = AllObjWithCaption."Object ID" where("Object Type" = const(Table));
        }
        field(7; "Related Field ID"; Integer)
        {
            Caption = 'Related Field ID';
            TableRelation = Field."No." where(TableNo = field("Related Table ID"));
        }
        field(8; Value; Text[250])
        {
            Caption = 'Value';
        }
        field(9; "Record ID"; RecordID)
        {
            Caption = 'Record ID';
            DataClassification = CustomerContent;
        }
    }

    keys
    {
        key(Key1; "Workflow Step Instance ID", "Workflow Code", "Workflow Step ID", "Table ID", "Field ID", "Related Table ID", "Related Field ID")
        {
            Clustered = true;
        }
        key(Key2; "Record ID")
        {
        }
    }

    fieldgroups
    {
    }

    procedure CreateNew(NextStepId: Integer; WorkflowStepInstance: Record "Workflow Step Instance"; WorkflowTableRelation: Record "Workflow - Table Relation"; RecRef: RecordRef)
    var
        FieldRef: FieldRef;
    begin
        if NextStepId = 0 then
            Error(WorkflowStepIdErr);

        Init();
        "Workflow Step Instance ID" := WorkflowStepInstance.ID;
        "Workflow Code" := WorkflowStepInstance."Workflow Code";
        "Workflow Step ID" := NextStepId;
        "Table ID" := WorkflowTableRelation."Table ID";
        "Field ID" := WorkflowTableRelation."Field ID";
        "Related Table ID" := WorkflowTableRelation."Related Table ID";
        "Related Field ID" := WorkflowTableRelation."Related Field ID";
        FieldRef := RecRef.Field(WorkflowTableRelation."Field ID");
        Value := FieldRef.Value();
        "Record ID" := RecRef.RecordId;
        Insert();
    end;

    procedure UpdateRelationValue(RecRef: RecordRef)
    var
        FieldRef: FieldRef;
    begin
        FieldRef := RecRef.Field("Field ID");

        if (Value <> Format(FieldRef.Value)) or ("Record ID" <> RecRef.RecordId) then begin
            Value := FieldRef.Value();
            "Record ID" := RecRef.RecordId;

            Modify();
        end;
    end;

    var
        WorkflowStepIdErr: Label 'Workflow Step ID must be set.';
}

