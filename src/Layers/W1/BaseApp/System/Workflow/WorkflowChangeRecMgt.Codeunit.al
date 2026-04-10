namespace System.Automation;

codeunit 1531 "Workflow Change Rec Mgt."
{
    Permissions = TableData "Workflow - Record Change" = rimd;

    trigger OnRun()
    begin
    end;

    var
        ValueMismatchMsg: Label 'The current value of the field is different from the value before the change.';
        NoRecordChangesFoundMsg: Label 'No record changes exist to apply the saved values to using the current options.';

    procedure RevertValueForField(var Variant: Variant; xVariant: Variant; WorkflowStepInstance: Record "Workflow Step Instance")
    var
        WorkflowStepArgument: Record "Workflow Step Argument";
        WorkflowRecordChange: Record "Workflow - Record Change";
        RecRef: RecordRef;
        OldValue: Text;
        NewValue: Text;
    begin
        RecRef.GetTable(Variant);

        WorkflowStepArgument.Get(WorkflowStepInstance.Argument);

        OldValue := GetValueFromField(xVariant, WorkflowStepArgument."Field No.");
        NewValue := GetValueFromField(Variant, WorkflowStepArgument."Field No.");

        if OldValue = NewValue then
            exit;

        CreateChangeRecord(RecRef, OldValue, NewValue, WorkflowStepArgument."Field No.", WorkflowStepInstance, WorkflowRecordChange);

        SetValueForField(RecRef, WorkflowStepArgument."Field No.", OldValue);

        RecRef.Modify(true);

        RecRef.SetTable(Variant);
    end;

    procedure ApplyNewValues(Variant: Variant; WorkflowStepInstance: Record "Workflow Step Instance")
    var
        ApprovalEntry: Record "Approval Entry";
        WorkflowRecordChange: Record "Workflow - Record Change";
        WorkflowStepArgument: Record "Workflow Step Argument";
        RecRef: RecordRef;
    begin
        RecRef.GetTable(Variant);

        case RecRef.Number of
            DATABASE::"Approval Entry":
                begin
                    ApprovalEntry.Get(RecRef.RecordId);
                    WorkflowRecordChange.SetRange("Workflow Step Instance ID", WorkflowStepInstance.ID);
                    WorkflowRecordChange.SetRange("Record ID", ApprovalEntry."Record ID to Approve");
                    WorkflowRecordChange.SetRange(Inactive, false);
                end;
            DATABASE::"Workflow - Record Change":
                begin
                    WorkflowRecordChange.Get(RecRef.RecordId);
                    WorkflowRecordChange.SetRange("Workflow Step Instance ID", WorkflowStepInstance.ID);
                    WorkflowRecordChange.SetRange("Record ID", WorkflowRecordChange."Record ID");
                    WorkflowRecordChange.SetRange(Inactive, false);
                end;
            else begin
                    WorkflowRecordChange.SetRange("Workflow Step Instance ID", WorkflowStepInstance.ID);
                    WorkflowRecordChange.SetRange("Record ID", RecRef.RecordId);
                    WorkflowRecordChange.SetRange(Inactive, false);
                end
        end;

        if WorkflowStepArgument.Get(WorkflowStepInstance.Argument) then
            if WorkflowStepArgument."Field No." <> 0 then begin
                WorkflowRecordChange.SetRange("Table No.", WorkflowStepArgument."Table No.");
                WorkflowRecordChange.SetRange("Field No.", WorkflowStepArgument."Field No.");
            end;

        if WorkflowRecordChange.FindSet() then
            repeat
                ApplyNewValueFromChangeRecord(WorkflowRecordChange);
            until WorkflowRecordChange.Next() = 0
        else
            Message(NoRecordChangesFoundMsg);
    end;

    procedure DiscardNewValues(Variant: Variant; WorkflowStepInstance: Record "Workflow Step Instance")
    var
        ApprovalEntry: Record "Approval Entry";
        WorkflowRecordChange: Record "Workflow - Record Change";
        RecRef: RecordRef;
    begin
        RecRef.GetTable(Variant);

        case RecRef.Number of
            DATABASE::"Approval Entry":
                begin
                    ApprovalEntry.Get(RecRef.RecordId);
                    RecRef.Get(ApprovalEntry."Record ID to Approve");
                end;
            DATABASE::"Workflow - Record Change":
                begin
                    WorkflowRecordChange.Get(RecRef.RecordId);
                    RecRef.Get(WorkflowRecordChange."Record ID");
                end;
        end;

        WorkflowRecordChange.SetRange("Table No.", RecRef.Number);
        WorkflowRecordChange.SetRange("Record ID", RecRef.RecordId);
        WorkflowRecordChange.SetRange("Workflow Step Instance ID", WorkflowStepInstance.ID);
        WorkflowRecordChange.ModifyAll(Inactive, true, true);
    end;

    local procedure CreateChangeRecord(RecRef: RecordRef; OldValue: Text; NewValue: Text; FieldNo: Integer; WorkflowStepInstance: Record "Workflow Step Instance"; var WorkflowRecordChange: Record "Workflow - Record Change")
    begin
        Clear(WorkflowRecordChange);
        WorkflowRecordChange."Table No." := RecRef.Number;
        WorkflowRecordChange."Field No." := FieldNo;
        WorkflowRecordChange."Old Value" := CopyStr(OldValue, 1, 250);
        WorkflowRecordChange."New Value" := CopyStr(NewValue, 1, 250);
        WorkflowRecordChange."Record ID" := RecRef.RecordId;
        WorkflowRecordChange."Workflow Step Instance ID" := WorkflowStepInstance.ID;
        WorkflowRecordChange.Insert(true);
    end;

    local procedure ApplyNewValueFromChangeRecord(WorkflowRecordChange: Record "Workflow - Record Change")
    var
        RecRef: RecordRef;
    begin
        RecRef.Get(WorkflowRecordChange."Record ID");

        if WorkflowRecordChange."Old Value" = GetValueFromField(RecRef, WorkflowRecordChange."Field No.") then begin
            SetValueForField(RecRef, WorkflowRecordChange."Field No.", WorkflowRecordChange."New Value");
            RecRef.Modify(true);
            WorkflowRecordChange.Inactive := true;
            WorkflowRecordChange.Modify(true);
        end else
            Message(ValueMismatchMsg);
    end;

    local procedure GetValueFromField(Variant: Variant; FieldId: Integer): Text
    var
        RecRef: RecordRef;
        FieldRef: FieldRef;
    begin
        RecRef.GetTable(Variant);
        FieldRef := RecRef.Field(FieldId);
        exit(Format(FieldRef.Value, 0, 9));
    end;

    local procedure SetValueForField(var RecRef: RecordRef; FieldId: Integer; NewValue: Text)
    var
        FieldRef: FieldRef;
    begin
        FieldRef := RecRef.Field(FieldId);
        Evaluate(FieldRef, NewValue, 9);
    end;
}

