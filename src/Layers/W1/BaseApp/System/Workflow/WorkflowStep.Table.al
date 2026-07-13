namespace System.Automation;

using System.Utilities;

table 1502 "Workflow Step"
{
    Caption = 'Workflow Step';
    LookupPageID = "Workflow Steps";
    Permissions = tabledata "Workflow Step" = r,
                  TableData "Workflow Step Instance" = rimd,
                  TableData "Workflow Step Argument" = ri,
                  TableData "Workflow Rule" = rimd;
    ReplicateData = true;
    DataClassification = CustomerContent;

    fields
    {
        field(1; ID; Integer)
        {
            AutoIncrement = true;
            Caption = 'ID';
        }
        field(2; "Workflow Code"; Code[20])
        {
            Caption = 'Workflow Code';
            NotBlank = true;
            TableRelation = Workflow;
        }
        field(4; Description; Text[100])
        {
            Caption = 'Description';
        }
        field(9; "Entry Point"; Boolean)
        {
            Caption = 'Entry Point';
        }
        field(11; "Previous Workflow Step ID"; Integer)
        {
            Caption = 'Previous Workflow Step ID';
            TableRelation = "Workflow Step".ID where("Workflow Code" = field("Workflow Code"));

            trigger OnLookup()
            begin
                if LookupOtherWorkflowStepID("Previous Workflow Step ID") then
                    Validate("Previous Workflow Step ID");
            end;

            trigger OnValidate()
            begin
                if "Previous Workflow Step ID" = ID then
                    FieldError("Previous Workflow Step ID", StepIdsCannotBeTheSameErr);
            end;
        }
        field(12; "Next Workflow Step ID"; Integer)
        {
            Caption = 'Next Workflow Step ID';
            TableRelation = "Workflow Step".ID where("Workflow Code" = field("Workflow Code"));

            trigger OnLookup()
            begin
                if LookupOtherWorkflowStepID("Next Workflow Step ID") then
                    Validate("Next Workflow Step ID");
            end;

            trigger OnValidate()
            begin
                if "Next Workflow Step ID" = ID then
                    FieldError("Next Workflow Step ID", StepIdsCannotBeTheSameErr);
            end;
        }
        field(13; Type; Option)
        {
            Caption = 'Type';
            OptionCaption = 'Event,Response,Sub-Workflow';
            OptionMembers = "Event",Response,"Sub-Workflow";

            trigger OnValidate()
            begin
                "Function Name" := '';
            end;
        }
        field(14; "Function Name"; Code[128])
        {
            Caption = 'Function Name';
            TableRelation = if (Type = const(Event)) "Workflow Event"
            else
            if (Type = const(Response)) "Workflow Response"
            else
            if (Type = const("Sub-Workflow")) Workflow;

            trigger OnLookup()
            var
                Workflow: Record Workflow;
                WorkflowEvent: Record "Workflow Event";
                WorkflowResponse: Record "Workflow Response";
                WorkflowLookupCode: Code[20];
            begin
                case Type of
                    Type::"Event":
                        if PAGE.RunModal(0, WorkflowEvent) = ACTION::LookupOK then
                            Validate("Function Name", WorkflowEvent."Function Name");
                    Type::Response:
                        if PAGE.RunModal(0, WorkflowResponse) = ACTION::LookupOK then
                            Validate("Function Name", WorkflowResponse."Function Name");
                    Type::"Sub-Workflow":
                        begin
                            Workflow.Get("Workflow Code");
                            if Workflow.LookupOtherWorkflowCode(WorkflowLookupCode) then
                                Validate("Function Name", WorkflowLookupCode);
                        end;
                end;
            end;

            trigger OnValidate()
            var
                WorkflowStepArgument: Record "Workflow Step Argument";
                WorkflowRule: Record "Workflow Rule";
                EmptyGuid: Guid;
            begin
                case Type of
                    Type::"Sub-Workflow":
                        if "Function Name" = "Workflow Code" then
                            FieldError("Function Name", CannotReferToCurrentWorkflowErr);
                    else
                        if "Function Name" <> xRec."Function Name" then begin
                            if WorkflowStepArgument.Get(Argument) then begin
                                WorkflowStepArgument.Delete(true);
                                Clear(Argument);
                            end;
                            WorkflowRule.SetRange("Workflow Code", "Workflow Code");
                            WorkflowRule.SetRange("Workflow Step ID", ID);
                            WorkflowRule.SetRange("Workflow Step Instance ID", EmptyGuid);
                            if not WorkflowRule.IsEmpty() then
                                WorkflowRule.DeleteAll();
                        end;
                end;

                if (Type = Type::Response) and ("Function Name" <> '') then
                    CreateResponseArgument();
            end;
        }
        field(15; Argument; Guid)
        {
            Caption = 'Argument';
            TableRelation = "Workflow Step Argument" where(Type = field(Type));

            trigger OnValidate()
            var
                WorkflowStepArgument: Record "Workflow Step Argument";
            begin
                if WorkflowStepArgument.Get(xRec.Argument) then
                    WorkflowStepArgument.Delete(true);
            end;
        }
        field(16; "Sequence No."; Integer)
        {
            Caption = 'Sequence No.';
            InitValue = 1;
        }
    }

    keys
    {
        key(Key1; "Workflow Code", ID)
        {
            Clustered = true;
        }
        key(Key2; "Sequence No.")
        {
        }
        key(Key3; "Function Name", Type)
        {
        }
        key(Key4; "Entry Point", "Previous Workflow Step ID")
        {
        }
    }

    fieldgroups
    {
    }

    trigger OnDelete()
    var
        WorkflowStepArgument: Record "Workflow Step Argument";
        ChildWorkflowStep: Record "Workflow Step";
    begin
        CheckEditingIsAllowed();
        UpdateReferredNextStepsInstances();

        if WorkflowStepArgument.Get(Argument) then
            WorkflowStepArgument.Delete();
        DeleteStepRules();

        // Change Previous Workflow Step ID to not point to the deleted step
        ChildWorkflowStep.SetRange("Workflow Code", "Workflow Code");
        ChildWorkflowStep.SetRange("Previous Workflow Step ID", ID);
        if ChildWorkflowStep.FindSet() then
            repeat
                ChildWorkflowStep.Validate("Previous Workflow Step ID", "Previous Workflow Step ID");
                ChildWorkflowStep.Modify(true);
            until ChildWorkflowStep.Next() <> 1;
    end;

    trigger OnInsert()
    begin
        TestField("Workflow Code");
        CheckEditingIsAllowed();
    end;

    trigger OnModify()
    begin
        CheckEditingIsAllowed();
    end;

    trigger OnRename()
    begin
        CheckEditingIsAllowed();
    end;

    var
        CannotReferToCurrentWorkflowErr: Label 'cannot refer to the current workflow';
        StepIdsCannotBeTheSameErr: Label 'cannot be the same as ID', Comment = 'Example: Previous Workflow Step ID cannot be the same as ID.';
        ViewFilterDetailsTxt: Label '(View filter details)';
        CancelledErr: Label 'Cancelled.';
        ConfirmDeleteLinksQst: Label 'If you delete this workflow response, one or more other, linked workflow responses may stop working.\\Do you want to continue?';

    procedure CreateInstance(WorkflowInstanceID: Guid; WorkflowCode: Code[20]; PreviousWorkflowStepID: Integer; SubWorkflowStep: Record "Workflow Step")
    var
        WorkflowStepArgument: Record "Workflow Step Argument";
        WorkflowStepInstance: Record "Workflow Step Instance";
    begin
        OnBeforeCreateInstance(WorkflowCode);

        Rec.TestField(Rec.ID);
        WorkflowStepInstance.ID := WorkflowInstanceID;
        WorkflowStepInstance."Workflow Code" := WorkflowCode;
        WorkflowStepInstance."Workflow Step ID" := Rec.ID;
        WorkflowStepInstance.Description := Rec.Description;
        WorkflowStepInstance."Entry Point" := Rec."Entry Point";
        WorkflowStepInstance."Previous Workflow Step ID" := PreviousWorkflowStepID;
        WorkflowStepInstance."Next Workflow Step ID" := Rec."Next Workflow Step ID";
        WorkflowStepInstance.Type := Rec.Type;
        WorkflowStepInstance."Function Name" := Rec."Function Name";
        WorkflowStepInstance."Sequence No." := Rec."Sequence No.";

        // Avoid a deadlock when two processes are executting the following code
        // at same time (Get / Insert on the WorkflowStepArgument table)
        WorkflowStepArgument.LockTable(true);
        if WorkflowStepArgument.Get(Argument) then
            WorkflowStepInstance.Argument := WorkflowStepArgument.Clone();

        WorkflowStepInstance."Original Workflow Code" := SubWorkflowStep."Workflow Code";
        WorkflowStepInstance."Original Workflow Step ID" := SubWorkflowStep.ID;

        WorkflowStepInstance.Insert(true);
        InstantiateStepRules(WorkflowStepInstance.ID);
    end;

    procedure ConvertEventConditionsToFilters(RecRef: RecordRef)
    var
        WorkflowStepArgument: Record "Workflow Step Argument";
        TempBlob: Codeunit "Temp Blob";
        RequestPageParametersHelper: Codeunit "Request Page Parameters Helper";
    begin
        TestField(Type, Type::"Event");
        TestField("Function Name");

        if WorkflowStepArgument.Get(Argument) then begin
            WorkflowStepArgument.CalcFields("Event Conditions");

            TempBlob.FromRecord(WorkflowStepArgument, WorkflowStepArgument.FieldNo("Event Conditions"));

            RequestPageParametersHelper.ConvertParametersToFilters(RecRef, TempBlob, TextEncoding::UTF8);
        end;
    end;

    procedure DeleteEventConditions()
    var
        WorkflowStepArgument: Record "Workflow Step Argument";
        ZeroGUID: Guid;
    begin
        CheckEditingIsAllowed();

        TestField(Type, Type::"Event");
        TestField("Function Name");

        if WorkflowStepArgument.Get(Argument) then begin
            WorkflowStepArgument.Delete(true);
            Argument := ZeroGUID;
            Modify(true);
        end;

        DeleteStepRules();
    end;

    [Scope('OnPrem')]
    procedure OpenEventConditions()
    var
        WorkflowEvent: Record "Workflow Event";
        WorkflowStepArgument: Record "Workflow Step Argument";
        ReturnFilters: Text;
        CurrentEventFilters: Text;
        UserClickedOK: Boolean;
    begin
        TestField(Type, Type::"Event");
        TestField("Function Name");

        WorkflowEvent.Get("Function Name");

        if WorkflowStepArgument.Get(Argument) then
            CurrentEventFilters := WorkflowStepArgument.GetEventFilters()
        else
            CurrentEventFilters := WorkflowEvent.CreateDefaultRequestPageFilters();

        UserClickedOK := WorkflowEvent.RunRequestPage(ReturnFilters, CurrentEventFilters);
        if UserClickedOK and (ReturnFilters <> CurrentEventFilters) then begin
            CheckEditingIsAllowed();
            if ReturnFilters = WorkflowEvent.CreateDefaultRequestPageFilters() then
                DeleteEventConditions()
            else begin
                if IsNullGuid(Argument) then
                    CreateEventArgument(WorkflowStepArgument, Rec);
                WorkflowStepArgument.SetEventFilters(ReturnFilters);
            end;
        end;
    end;

    procedure OpenAdvancedEventConditions()
    var
        WorkflowEvent: Record "Workflow Event";
        WorkflowRule: Record "Workflow Rule";
        TempWorkflowRule: Record "Workflow Rule" temporary;
        WorkflowEventConditions: Page "Workflow Event Conditions";
    begin
        TestField(Type, Type::"Event");
        TestField("Function Name");

        WorkflowEvent.Get("Function Name");

        WorkflowRule.SetRange("Workflow Code", "Workflow Code");
        WorkflowRule.SetRange("Workflow Step ID", ID);
        if WorkflowRule.FindFirst() then
            TempWorkflowRule := WorkflowRule
        else begin
            TempWorkflowRule."Table ID" := WorkflowEvent."Table ID";
            TempWorkflowRule."Workflow Code" := "Workflow Code";
            TempWorkflowRule."Workflow Step ID" := ID;
        end;

        WorkflowEventConditions.SetRule(TempWorkflowRule);
        if WorkflowEventConditions.RunModal() = ACTION::LookupOK then begin
            WorkflowEventConditions.GetRecord(TempWorkflowRule);
            if TempWorkflowRule."Field No." = 0 then
                DeleteStepRules()
            else begin
                WorkflowRule.Copy(TempWorkflowRule);
                if not WorkflowRule.Insert(true) then
                    WorkflowRule.Modify(true);
            end;
        end;
    end;

    [Scope('OnPrem')]
    procedure CompareEventConditions(WorkflowStep: Record "Workflow Step"): Boolean
    var
        OtherWorkflowEvent: Record "Workflow Event";
        ThisWorkflowEvent: Record "Workflow Event";
        OtherRecRef: RecordRef;
        ThisRecRef: RecordRef;
    begin
        TestField(Type, Type::"Event");
        ThisWorkflowEvent.Get("Function Name");
        ThisRecRef.Open(ThisWorkflowEvent."Table ID");
        ConvertEventConditionsToFilters(ThisRecRef);

        WorkflowStep.TestField(Type, WorkflowStep.Type::"Event");
        OtherWorkflowEvent.Get(WorkflowStep."Function Name");
        OtherRecRef.Open(OtherWorkflowEvent."Table ID");
        WorkflowStep.ConvertEventConditionsToFilters(OtherRecRef);

        exit(ThisRecRef.GetFilters = OtherRecRef.GetFilters);
    end;

    procedure CompareEventRule(WorkflowStep: Record "Workflow Step"): Boolean
    var
        OtherWorkflowRule: Record "Workflow Rule";
        ThisWorkflowRule: Record "Workflow Rule";
    begin
        TestField("Workflow Code");
        TestField(ID);
        WorkflowStep.TestField("Workflow Code");
        WorkflowStep.TestField(ID);

        FindWorkflowRules(ThisWorkflowRule);
        WorkflowStep.FindWorkflowRules(OtherWorkflowRule);

        exit((ThisWorkflowRule.Count <= 1) and (ThisWorkflowRule.Count = OtherWorkflowRule.Count) and
          (ThisWorkflowRule."Field No." = OtherWorkflowRule."Field No.") and
          (ThisWorkflowRule.Operator = OtherWorkflowRule.Operator))
    end;

    procedure InsertAfterStep(var NewWorkflowStep: Record "Workflow Step")
    var
        ChildWorkflowStep: Record "Workflow Step";
    begin
        ChildWorkflowStep.SetRange("Workflow Code", "Workflow Code");
        ChildWorkflowStep.SetRange("Previous Workflow Step ID", ID);
        ChildWorkflowStep.ModifyAll("Previous Workflow Step ID", NewWorkflowStep.ID);

        NewWorkflowStep.TestField("Workflow Code", "Workflow Code");
        NewWorkflowStep.Validate("Previous Workflow Step ID", ID);
        NewWorkflowStep.Modify(true);
    end;

    local procedure CreateEventArgument(var WorkflowStepArgument: Record "Workflow Step Argument"; var WorkflowStep: Record "Workflow Step")
    begin
        WorkflowStep.TestField(Type, WorkflowStep.Type::"Event");

        WorkflowStepArgument.Init();
        WorkflowStepArgument.Type := WorkflowStepArgument.Type::"Event";
        WorkflowStepArgument.Insert(true);

        WorkflowStep.Argument := WorkflowStepArgument.ID;
        WorkflowStep.Modify(true);
    end;

    [Scope('OnPrem')]
    procedure LookupOtherWorkflowStepID(var LookupID: Integer): Boolean
    var
        TempWorkflowStepBuffer: Record "Workflow Step Buffer" temporary;
    begin
        TempWorkflowStepBuffer.PopulateLookupTable("Workflow Code");
        TempWorkflowStepBuffer.SetFilter("Event Step ID", '0|%1', LookupID);
        TempWorkflowStepBuffer.SetFilter("Response Step ID", '0|%1', LookupID);
        if TempWorkflowStepBuffer.FindFirst() then;
        TempWorkflowStepBuffer.Reset();
        if PAGE.RunModal(PAGE::"Workflow Steps", TempWorkflowStepBuffer) = ACTION::LookupOK then begin
            LookupID := TempWorkflowStepBuffer."Event Step ID" + TempWorkflowStepBuffer."Response Step ID";
            exit(true);
        end;
    end;

    procedure GetDescription(): Text[250]
    var
        WorkflowStep: Record "Workflow Step";
        WorkflowEvent: Record "Workflow Event";
        WorkflowStepArgument: Record "Workflow Step Argument";
        WorkflowResponseHandling: Codeunit "Workflow Response Handling";
    begin
        case Type of
            WorkflowStep.Type::"Event":
                if WorkflowEvent.Get("Function Name") then
                    exit(WorkflowEvent.Description);
            WorkflowStep.Type::Response:
                if WorkflowStepArgument.Get(Argument) then
                    exit(WorkflowResponseHandling.GetDescription(WorkflowStepArgument));
        end;
        exit('');
    end;

    local procedure CheckEditingIsAllowed()
    var
        Workflow: Record Workflow;
    begin
        Workflow.Get("Workflow Code");
        Workflow.CheckEditingIsAllowed();
    end;

    procedure ToString(): Text
    begin
        exit(StrSubstNo('%1,%2,%3', "Workflow Code", ID, Type));
    end;

    procedure FindByAttributes(WorkflowStepAttributes: Text)
    begin
        SetFilter("Workflow Code", '%1', SelectStr(1, WorkflowStepAttributes));
        SetFilter(ID, SelectStr(2, WorkflowStepAttributes));
        SetFilter(Type, SelectStr(3, WorkflowStepAttributes));
        FindFirst();
    end;

    [Scope('OnPrem')]
    procedure GetConditionAsDisplayText(): Text
    var
        WorkflowEvent: Record "Workflow Event";
        RecordRef: RecordRef;
    begin
        if Type <> Type::"Event" then
            exit;

        if not WorkflowEvent.Get("Function Name") then
            exit;

        RecordRef.Open(WorkflowEvent."Table ID");
        ConvertEventConditionsToFilters(RecordRef);

        if RecordRef.GetFilters <> '' then
            exit(RecordRef.GetFilters);

        if HasArgumentsContent() then
            exit(ViewFilterDetailsTxt);

        exit('');
    end;

    procedure GetRuleAsDisplayText(): Text
    var
        WorkflowRule: Record "Workflow Rule";
    begin
        if Type <> Type::"Event" then
            exit;

        WorkflowRule.SetRange("Workflow Code", "Workflow Code");
        WorkflowRule.SetRange("Workflow Step ID", ID);
        if WorkflowRule.FindFirst() then
            exit(WorkflowRule.GetDisplayText());

        exit('');
    end;

    local procedure CreateResponseArgument(): Boolean
    var
        WorkflowStepArgument: Record "Workflow Step Argument";
    begin
        TestField(Type, Type::Response);

        if IsNullGuid(Argument) or (not WorkflowStepArgument.Get(Argument)) then begin
            WorkflowStepArgument.Init();
            WorkflowStepArgument.Type := WorkflowStepArgument.Type::Response;
            WorkflowStepArgument."Response Function Name" := "Function Name";
            WorkflowStepArgument.Insert(true);
            Argument := WorkflowStepArgument.ID;
            exit(true);
        end;

        exit(false);
    end;

    local procedure HasArgumentsContent(): Boolean
    var
        WorkflowStepArgument: Record "Workflow Step Argument";
    begin
        if not WorkflowStepArgument.Get(Argument) then
            exit(false);

        exit(WorkflowStepArgument."Event Conditions".HasValue);
    end;

    procedure HasEventsInSubtree(var ChildWorkflowStep: Record "Workflow Step"): Boolean
    begin
        ChildWorkflowStep.SetRange("Workflow Code", "Workflow Code");
        ChildWorkflowStep.SetRange("Previous Workflow Step ID", ID);
        ChildWorkflowStep.SetRange(Type, ChildWorkflowStep.Type::"Event");
        if ChildWorkflowStep.FindFirst() then
            exit(true);

        ChildWorkflowStep.SetRange(Type);
        if ChildWorkflowStep.FindSet() then
            repeat
                if ChildWorkflowStep.HasEventsInSubtree(ChildWorkflowStep) then
                    exit(true);
            until ChildWorkflowStep.Next() = 0;

        exit(false);
    end;

    local procedure DeleteStepRules()
    var
        WorkflowRule: Record "Workflow Rule";
    begin
        if HasWorkflowRules() then begin
            SetFilters(WorkflowRule);
            WorkflowRule.DeleteAll();
        end;
    end;

    local procedure InstantiateStepRules(InstanceID: Guid)
    var
        WorkflowRule: Record "Workflow Rule";
        InstanceWorkflowRule: Record "Workflow Rule";
        ZeroGuid: Guid;
    begin
        WorkflowRule.SetRange("Workflow Code", "Workflow Code");
        WorkflowRule.SetRange("Workflow Step ID", ID);
        WorkflowRule.SetRange("Workflow Step Instance ID", ZeroGuid);
        if WorkflowRule.FindSet() then
            repeat
                InstanceWorkflowRule.Copy(WorkflowRule);
                InstanceWorkflowRule.ID := 0;
                InstanceWorkflowRule."Workflow Step Instance ID" := InstanceID;
                InstanceWorkflowRule.Insert(true);
            until WorkflowRule.Next() = 0;
    end;

    procedure FindWorkflowRules(var WorkflowRule: Record "Workflow Rule"): Boolean
    begin
        SetFilters(WorkflowRule);
        exit(WorkflowRule.FindSet());
    end;

    procedure HasWorkflowRules(): Boolean
    var
        WorkflowRule: Record "Workflow Rule";
    begin
        SetFilters(WorkflowRule);
        exit(not WorkflowRule.IsEmpty());
    end;

    procedure SetFilters(var WorkflowRule: Record "Workflow Rule")
    var
        ZeroGuid: Guid;
    begin
        TestField("Workflow Code");
        TestField(ID);
        WorkflowRule.SetRange("Workflow Code", "Workflow Code");
        WorkflowRule.SetRange("Workflow Step ID", ID);
        WorkflowRule.SetRange("Workflow Step Instance ID", ZeroGuid);
    end;

    procedure HasParentEvent(var WorkflowStep: Record "Workflow Step"): Boolean
    begin
        WorkflowStep.SetRange(ID, "Previous Workflow Step ID");
        WorkflowStep.SetRange("Workflow Code", "Workflow Code");
        WorkflowStep.SetRange(Type, WorkflowStep.Type::"Event");

        if WorkflowStep.FindFirst() then
            exit(true);

        WorkflowStep.SetRange(Type);
        if WorkflowStep.FindSet() then
            repeat
                if WorkflowStep.HasParentEvent(WorkflowStep) then
                    exit(true);
            until WorkflowStep.Next() = 0;

        exit(false);
    end;

    local procedure UpdateReferredNextStepsInstances()
    var
        ReferredWorkflowStep: Record "Workflow Step";
    begin
        if Type <> Type::Response then
            exit;

        ReferredWorkflowStep.SetRange("Workflow Code", "Workflow Code");
        ReferredWorkflowStep.SetRange("Next Workflow Step ID", ID);
        ReferredWorkflowStep.SetRange(Type, ReferredWorkflowStep.Type::Response);
        if not ReferredWorkflowStep.IsEmpty() then begin
            if not Confirm(ConfirmDeleteLinksQst, false) then
                Error(CancelledErr);
            ReferredWorkflowStep.ModifyAll("Next Workflow Step ID", 0);
        end;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCreateInstance(WorkflowCode: Code[20])
    begin
    end;
}

