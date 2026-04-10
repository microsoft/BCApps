namespace System.Automation;

using System;
using System.Utilities;

table 1501 Workflow
{
    Caption = 'Workflow';
    DataCaptionFields = "Code", Description;
    DrillDownPageID = Workflow;
    Permissions = TableData "Workflow Step" = rimd,
                  TableData "Workflow Step Instance" = rm;
    ReplicateData = true;
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Code"; Code[20])
        {
            Caption = 'Code';
            NotBlank = true;

            trigger OnValidate()
            var
                Workflow: Record Workflow;
            begin
                CheckEditingIsAllowed();
                CheckWorkflowCodeDoesNotExistAsTemplate();
                if (xRec.Code = '') and Workflow.Get() then begin
                    Workflow.Delete();
                    Workflow.Code := Code;
                    Workflow.Insert();
                    Get(Code);
                end;
            end;
        }
        field(2; Description; Text[100])
        {
            Caption = 'Description';
        }
        field(3; Enabled; Boolean)
        {
            Caption = 'Enabled';

            trigger OnValidate()
            var
                Window: Dialog;
            begin
                if Template then
                    Error(CannotEditTemplateWorkflowErr);

                if Enabled then begin
                    Window.Open(ValidateWorkflowProgressMsg);

                    SetEntryPoint();
                    CheckEntryPointsAreEvents();
                    CheckEntryPointsAreNotSubWorkflows();
                    CheckSingleEntryPointAsRoot();
                    CheckOrphansNotExist();
                    CheckFunctionNames();
                    CheckSubWorkflowsEnabled();
                    CheckResponseOptions();
                    CheckEntryPointEventConditions();
                    CheckEventTableRelation();
                    CheckRecordChangedWorkflows();

                    Window.Close();
                end else begin
                    Window.Open(DisableReferringWorkflowsMsg);

                    CheckEditingReferringWorkflowsIsAllowed();
                    ClearEntryPointIfFirst();

                    Window.Close();
                end;
            end;
        }
        field(4; Template; Boolean)
        {
            Caption = 'Template';
            InitValue = false;

            trigger OnValidate()
            begin
                if xRec.Template and Template then
                    Error(CannotEditTemplateWorkflowErr);
            end;
        }
        field(5; Category; Code[20])
        {
            Caption = 'Category';
            TableRelation = "Workflow Category";
        }
    }

    keys
    {
        key(Key1; "Code")
        {
            Clustered = true;
        }
        key(Key2; Enabled)
        {
        }
        key(Key3; Template)
        {
        }
    }

    fieldgroups
    {
    }

    trigger OnDelete()
    begin
        CanDelete(true);
        DeleteWorkflowSteps();
    end;

    trigger OnRename()
    begin
        CheckEditingIsAllowed();
    end;

    var
        CannotDeleteEnabledWorkflowErr: Label 'Enabled workflows cannot be deleted.\\You must clear the Enabled field box before you delete the workflow.';
        CannotDeleteWorkflowWithActiveInstancesErr: Label 'You cannot delete the workflow because active workflow step instances exist.';
        CannotEditEnabledWorkflowErr: Label 'Enabled workflows cannot be edited.\\You must clear the Enabled field box before you edit the workflow.';
        CannotEditTemplateWorkflowErr: Label 'Workflow templates cannot be edited.\\You must create a workflow from the template to edit it.';
        DisableReferringWorkflowsErr: Label 'You cannot edit the %1 workflow because it is used as a sub-workflow in other workflows. You must first disable the workflows that use the %1 workflow.', Comment = '%1 = Workflow identifier (e.g. You cannot edit the MS-PIW workflow because it is used as a sub-workflow in other workflows. You must first disable the workflows that use the MS-PIW workflow.)';
        DisableReferringWorkflowsMsg: Label 'Other workflows where the workflow is used as a sub-workflow are being disabled.';
        DisableReferringWorkflowsQst: Label 'The %1 workflow is used as a sub-workflow in other workflows, which you must disable before you can edit the %1 workflow.\\Do you want to disable all workflows where the %1 workflow is used?', Comment = '%1 = Workflow Identifier (e.g. The MS-PIW workflow is used as a sub-workflow in other workflows, which you must disable before you can edit the MS-PIW workflow.\\Do you want to disable all workflows where the MS-PIW workflow is used?)';
        EventOnlyEntryPointsErr: Label 'Events can only be specified as entry points.';
        MissingFunctionNamesErr: Label 'All workflow steps must have valid function names.';
        MissingRespOptionsErr: Label 'Response options are missing in one or more workflow steps.';
        OneRootStepErr: Label 'Enabled workflows must have one step that is an entry point and does not have a value in the Previous Workflow Step ID field.';
        OrphanWorkflowStepsErr: Label 'There can be only one left-aligned workflow step.';
        SameEventConditionsErr: Label 'One or more entry-point steps exist that use the same event on table %1. You must specify unique event conditions on entry-point steps that use the same table.', Comment = '%1=Table Caption';
        SubWorkflowNotEnabledErr: Label 'You must enable the sub-workflow %1 before you can enable the %2 workflow.', Comment = '%1 and %2 = Workflow Identifiers (e.g. You must enable the sub-workflow MS-PIW before you can enable the MS-SIAPW workflow.)';
        ValidateWorkflowProgressMsg: Label 'The workflow is being validated.';
        WorkflowStepInstanceLinkErr: Label 'The %1 workflow cannot start because all ending steps in the %2 sub-workflow have a value in the Next Workflow Step ID field.\\Make sure that at least one step in the %2 sub-workflow does not have a value in the Next Workflow Step ID field.', Comment = '%1 and %2 = Workflow Identifiers (e.g. The MS-PIW workflow cannot start because all ending steps in the MS-SIAPW sub-workflow have a value in the Next Workflow Step ID field.\\Make sure that at least one step in the MS-SIAPW sub-workflow does not have a value in the Next Workflow Step ID field.)';
        ValidateTableRelationErr: Label 'You must define a table relation between all records used in events.';
        WorkflowExistsAsTemplateErr: Label 'The record already exists, as a workflow template.';
        WorkflowMustApplySavedValuesErr: Label 'The workflow does not contain a response to apply the saved values to.';
        WorkflowMustRevertValuesErr: Label 'The workflow does not contain a response to revert and save the changed field values.';
        CannotDeleteWorkflowTemplatesErr: Label 'You cannot delete a workflow template.';

    procedure CreateInstance(var WorkflowStepInstance: Record "Workflow Step Instance")
    var
        NextWorkflowStepQueue: DotNet Queue;
        LeafWorkflowStepQueue: DotNet Queue;
        WorkflowInstanceID: Guid;
        WorkflowInstanceCode: Code[20];
        WorkflowInstancePreviousStepID: Integer;
    begin
        WorkflowInstanceID := CreateGuid();
        WorkflowInstanceCode := Code;
        WorkflowInstancePreviousStepID := 0;

        NextWorkflowStepQueue := NextWorkflowStepQueue.Queue();

        CreateInstanceBreadthFirst(Code, WorkflowInstanceID, WorkflowInstanceCode,
          WorkflowInstancePreviousStepID, LeafWorkflowStepQueue, NextWorkflowStepQueue);

        UpdateWorkflowStepInstanceNextLinks(NextWorkflowStepQueue, WorkflowInstanceID);

        WorkflowStepInstance.SetRange(ID, WorkflowInstanceID);
        WorkflowStepInstance.SetRange("Entry Point", true);
    end;

    local procedure CreateInstanceBreadthFirst(WorkflowCode: Code[20]; InitialWorkflowInstanceID: Guid; InitialWorkflowInstanceCode: Code[20]; InitialWorkflowInstancePreviousStepID: Integer; var LeafWorkflowStepQueue: DotNet Queue; var NextWorkflowStepQueue: DotNet Queue)
    var
        ChildWorkflowStep: Record "Workflow Step";
        ParentWorkflowStep: Record "Workflow Step";
        ParentWorkflowStepInstance: Record "Workflow Step Instance";
        WorkflowStep: Record "Workflow Step";
        ParentWorkflowStepQueue: DotNet Queue;
        WorkflowInstanceID: Guid;
        WorkflowInstanceCode: Code[20];
        WorkflowInstancePreviousStepID: Integer;
    begin
        WorkflowStep.SetRange("Workflow Code", WorkflowCode);

        ParentWorkflowStepQueue := ParentWorkflowStepQueue.Queue();
        LeafWorkflowStepQueue := LeafWorkflowStepQueue.Queue();

        WorkflowStep.SetRange("Entry Point", true);

        if WorkflowStep.FindFirst() then begin
            WorkflowInstanceID := InitialWorkflowInstanceID;
            WorkflowInstanceCode := InitialWorkflowInstanceCode;
            WorkflowInstancePreviousStepID := InitialWorkflowInstancePreviousStepID;

            if WorkflowStep.Type = WorkflowStep.Type::"Sub-Workflow" then
                CreateInstanceBreadthFirst(CopyStr(WorkflowStep."Function Name", 1, 20), WorkflowInstanceID, WorkflowInstanceCode,
                  WorkflowInstancePreviousStepID, LeafWorkflowStepQueue, NextWorkflowStepQueue)
            else begin
                WorkflowStep.CreateInstance(
                  WorkflowInstanceID, WorkflowInstanceCode, WorkflowInstancePreviousStepID, WorkflowStep);

                UpdateWorkflowStepInstanceLeafLinks(ChildWorkflowStep, LeafWorkflowStepQueue, WorkflowInstanceID);

                if WorkflowStep."Next Workflow Step ID" > 0 then
                    NextWorkflowStepQueue.Enqueue(WorkflowStep.ToString());
            end;

            ParentWorkflowStepQueue.Enqueue(WorkflowStep.ToString());

            while ParentWorkflowStepQueue.Count > 0 do begin
                ParentWorkflowStep.FindByAttributes(ParentWorkflowStepQueue.Dequeue());

                if ParentWorkflowStep.Type <> ParentWorkflowStep.Type::"Sub-Workflow" then
                    FindWorkflowStepInstance(ParentWorkflowStepInstance, ParentWorkflowStep, WorkflowInstanceID);

                if not FindChildWorkflowSteps(ChildWorkflowStep, ParentWorkflowStep) then
                    LeafWorkflowStepQueue.Enqueue(ParentWorkflowStep.ToString())
                else
                    repeat
                        if ChildWorkflowStep.Type = ChildWorkflowStep.Type::"Sub-Workflow" then begin
                            WorkflowInstancePreviousStepID := ParentWorkflowStepInstance."Workflow Step ID";

                            CreateInstanceBreadthFirst(CopyStr(ChildWorkflowStep."Function Name", 1, 20), WorkflowInstanceID, WorkflowInstanceCode,
                              WorkflowInstancePreviousStepID, LeafWorkflowStepQueue, NextWorkflowStepQueue);
                        end else begin
                            ChildWorkflowStep.CreateInstance(
                              WorkflowInstanceID, WorkflowInstanceCode,
                              ParentWorkflowStepInstance."Workflow Step ID", ChildWorkflowStep);

                            UpdateWorkflowStepInstanceLeafLinks(ChildWorkflowStep, LeafWorkflowStepQueue, WorkflowInstanceID);

                            if ChildWorkflowStep."Next Workflow Step ID" > 0 then
                                NextWorkflowStepQueue.Enqueue(ChildWorkflowStep.ToString());
                        end;

                        ParentWorkflowStepQueue.Enqueue(ChildWorkflowStep.ToString());
                    until ChildWorkflowStep.Next() = 0;
            end;
        end;
    end;

    local procedure UpdateWorkflowStepInstanceLeafLinks(WorkflowStep: Record "Workflow Step"; var LeafWorkflowStepQueue: DotNet Queue; InstanceID: Guid)
    var
        LeafWorkflowStep: Record "Workflow Step";
        LeafWorkflowStepInstance: Record "Workflow Step Instance";
        NextWorkflowStepInstance: Record "Workflow Step Instance";
        PreviousWorkflowStep: Record "Workflow Step";
        WorkflowStepInstance: Record "Workflow Step Instance";
        LeafCount: Integer;
        LoopLeafCount: Integer;
        WorkflowStepInstanceIsUpdated: Boolean;
    begin
        if LeafWorkflowStepQueue.Count = 0 then
            exit;

        if not PreviousWorkflowStepIsSubWorkflow(PreviousWorkflowStep, WorkflowStep) then
            exit;

        FindWorkflowStepInstance(WorkflowStepInstance, WorkflowStep, InstanceID);
        LeafCount := LeafWorkflowStepQueue.Count();

        while LeafWorkflowStepQueue.Count > 0 do begin
            LeafWorkflowStep.FindByAttributes(LeafWorkflowStepQueue.Dequeue());
            FindWorkflowStepInstance(LeafWorkflowStepInstance, LeafWorkflowStep, InstanceID);

            if LeafWorkflowStepInstance."Next Workflow Step ID" > 0 then begin
                LoopLeafCount += 1;

                if FindNextWorkflowStepInstance(NextWorkflowStepInstance, WorkflowStep,
                     LeafWorkflowStepInstance.ID, LeafWorkflowStepInstance."Workflow Code")
                then begin
                    LeafWorkflowStepInstance.Validate("Next Workflow Step ID", NextWorkflowStepInstance."Workflow Step ID");
                    LeafWorkflowStepInstance.Modify(true);
                end;
            end else
                if WorkflowStepInstanceIsUpdated then begin
                    LeafWorkflowStepInstance.Validate("Next Workflow Step ID", WorkflowStepInstance."Workflow Step ID");
                    LeafWorkflowStepInstance.Modify(true);
                end else begin
                    WorkflowStepInstance.Validate("Previous Workflow Step ID", LeafWorkflowStepInstance."Workflow Step ID");
                    WorkflowStepInstance.Modify(true);
                    WorkflowStepInstanceIsUpdated := true;
                end;
        end;

        if (not WorkflowStepInstanceIsUpdated) or (LoopLeafCount >= LeafCount) then
            Error(WorkflowStepInstanceLinkErr, WorkflowStepInstance."Original Workflow Code", PreviousWorkflowStep."Function Name");
    end;

    local procedure UpdateWorkflowStepInstanceNextLinks(NextWorkflowStepQueue: DotNet Queue; InstanceID: Guid)
    var
        NextWorkflowStepInstance: Record "Workflow Step Instance";
        WorkflowStep: Record "Workflow Step";
        WorkflowStepInstance: Record "Workflow Step Instance";
    begin
        while NextWorkflowStepQueue.Count > 0 do begin
            WorkflowStep.FindByAttributes(NextWorkflowStepQueue.Dequeue());

            if FindWorkflowStepInstance(WorkflowStepInstance, WorkflowStep, InstanceID) then
                if FindNextWorkflowStepInstance(NextWorkflowStepInstance, WorkflowStep, InstanceID, WorkflowStepInstance."Workflow Code")
                then begin
                    FindLastResponseWorkflowStepInstanceBeforeEvent(NextWorkflowStepInstance, InstanceID, WorkflowStepInstance."Workflow Code");
                    WorkflowStepInstance.Validate("Next Workflow Step ID", NextWorkflowStepInstance."Workflow Step ID");
                    WorkflowStepInstance.Modify(true);
                end;
        end;
    end;

    local procedure PreviousWorkflowStepIsSubWorkflow(var PreviousWorkflowStep: Record "Workflow Step"; WorkflowStep: Record "Workflow Step"): Boolean
    begin
        PreviousWorkflowStep.Get(WorkflowStep."Workflow Code", WorkflowStep."Previous Workflow Step ID");
        exit(PreviousWorkflowStep.Type = PreviousWorkflowStep.Type::"Sub-Workflow");
    end;

    local procedure FindChildWorkflowSteps(var ChildWorkflowStep: Record "Workflow Step"; ParentWorkflowStep: Record "Workflow Step"): Boolean
    begin
        ChildWorkflowStep.SetRange("Workflow Code", ParentWorkflowStep."Workflow Code");
        ChildWorkflowStep.SetRange("Previous Workflow Step ID", ParentWorkflowStep.ID);
        exit(ChildWorkflowStep.FindSet());
    end;

    local procedure FindWorkflowStepInstance(var WorkflowStepInstance: Record "Workflow Step Instance"; WorkflowStep: Record "Workflow Step"; InstanceID: Guid): Boolean
    begin
        WorkflowStepInstance.SetRange(ID, InstanceID);
        WorkflowStepInstance.SetRange("Original Workflow Code", WorkflowStep."Workflow Code");
        WorkflowStepInstance.SetRange("Original Workflow Step ID", WorkflowStep.ID);
        WorkflowStepInstance.SetRange(Type, WorkflowStep.Type);
        exit(WorkflowStepInstance.FindFirst());
    end;

    local procedure FindNextWorkflowStepInstance(var WorkflowStepInstance: Record "Workflow Step Instance"; WorkflowStep: Record "Workflow Step"; InstanceID: Guid; WorkflowCode: Code[20]): Boolean
    begin
        WorkflowStepInstance.SetRange(ID, InstanceID);
        WorkflowStepInstance.SetRange("Workflow Code", WorkflowCode);
        WorkflowStepInstance.SetRange("Original Workflow Code", WorkflowStep."Workflow Code");
        WorkflowStepInstance.SetRange("Original Workflow Step ID", WorkflowStep."Next Workflow Step ID");
        exit(WorkflowStepInstance.FindFirst())
    end;

    local procedure FindLastResponseWorkflowStepInstanceBeforeEvent(var WorkflowStepInstance: Record "Workflow Step Instance"; InstanceID: Guid; WorkflowCode: Code[20])
    var
        NextWorkflowStepInstance: Record "Workflow Step Instance";
        IsLastStep: Boolean;
        WorkflowStepInstanceNumber: Integer;
        i: Integer;
    begin
        if WorkflowStepInstance.Type = WorkflowStepInstance.Type::"Event" then
            exit;
        NextWorkflowStepInstance := WorkflowStepInstance;
        NextWorkflowStepInstance.SetCurrentKey(ID, "Workflow Code", "Previous Workflow Step ID");
        NextWorkflowStepInstance.SetRange(ID, InstanceID);
        NextWorkflowStepInstance.SetRange("Workflow Code", WorkflowCode);
        WorkflowStepInstanceNumber := NextWorkflowStepInstance.Count - 1;
        repeat
            NextWorkflowStepInstance.SetRange("Previous Workflow Step ID", NextWorkflowStepInstance."Workflow Step ID");
            if not NextWorkflowStepInstance.FindFirst() then
                IsLastStep := true;
            i += 1;
        until (NextWorkflowStepInstance.Type = NextWorkflowStepInstance.Type::"Event") or IsLastStep or (i = WorkflowStepInstanceNumber);
        if IsLastStep then
            WorkflowStepInstance := NextWorkflowStepInstance
        else
            WorkflowStepInstance.Get(InstanceID, WorkflowCode, NextWorkflowStepInstance."Previous Workflow Step ID");
    end;

    local procedure DeleteWorkflowSteps()
    var
        WorkflowStep: Record "Workflow Step";
    begin
        WorkflowStep.SetRange("Workflow Code", Code);
        if not WorkflowStep.IsEmpty() then
            WorkflowStep.DeleteAll(true);
    end;

    local procedure SetEntryPoint()
    var
        WorkflowStep: Record "Workflow Step";
    begin
        WorkflowStep.SetRange("Workflow Code", Code);
        if not WorkflowStep.IsEmpty() then
            WorkflowStep.ModifyAll("Entry Point", false, true);

        WorkflowStep.SetRange("Previous Workflow Step ID", 0);
        if WorkflowStep.FindFirst() then begin
            WorkflowStep.Validate("Entry Point", true);
            WorkflowStep.Modify(true);
        end;
    end;

    local procedure ClearEntryPointIfFirst()
    var
        WorkflowStep: Record "Workflow Step";
    begin
        WorkflowStep.SetRange("Workflow Code", Code);
        if not WorkflowStep.IsEmpty() then
            WorkflowStep.ModifyAll("Entry Point", false, false);
    end;

    local procedure CheckEntryPointsAreEvents()
    var
        WorkflowStep: Record "Workflow Step";
    begin
        WorkflowStep.SetRange("Workflow Code", Code);
        WorkflowStep.SetRange("Entry Point", true);
        WorkflowStep.SetFilter(Type, '<>%1', WorkflowStep.Type::"Event");

        if not WorkflowStep.IsEmpty() then
            Error(EventOnlyEntryPointsErr);
    end;

    local procedure CheckEntryPointsAreNotSubWorkflows()
    var
        WorkflowStep: Record "Workflow Step";
    begin
        WorkflowStep.SetRange("Workflow Code", Code);
        WorkflowStep.SetRange("Entry Point", true);
        WorkflowStep.SetRange(Type, WorkflowStep.Type::"Sub-Workflow");

        if not WorkflowStep.IsEmpty() then
            Error(EventOnlyEntryPointsErr);
    end;

    local procedure CheckSingleEntryPointAsRoot()
    var
        WorkflowStep: Record "Workflow Step";
    begin
        WorkflowStep.SetRange("Workflow Code", Code);
        WorkflowStep.SetRange("Entry Point", true);
        WorkflowStep.SetRange("Previous Workflow Step ID", 0);

        if WorkflowStep.Count <> 1 then
            Error(OneRootStepErr);
    end;

    local procedure CheckOrphansNotExist()
    var
        PreviousWorkflowStep: Record "Workflow Step";
        WorkflowStep: Record "Workflow Step";
    begin
        WorkflowStep.SetRange("Workflow Code", Code);
        WorkflowStep.SetRange("Entry Point", false);

        WorkflowStep.SetRange("Previous Workflow Step ID", 0);
        if not WorkflowStep.IsEmpty() then
            Error(OrphanWorkflowStepsErr);

        WorkflowStep.SetFilter("Previous Workflow Step ID", '<>%1', 0);
        if WorkflowStep.FindSet() then
            repeat
                if not PreviousWorkflowStep.Get(Code, WorkflowStep."Previous Workflow Step ID") then
                    Error(OrphanWorkflowStepsErr);
            until WorkflowStep.Next() = 0;
    end;

    local procedure CheckFunctionNames()
    var
        WorkflowStep: Record "Workflow Step";
    begin
        WorkflowStep.SetRange("Workflow Code", Code);
        WorkflowStep.SetRange("Function Name", '');

        if not WorkflowStep.IsEmpty() then
            Error(MissingFunctionNamesErr);
    end;

    local procedure CheckSubWorkflowsEnabled()
    var
        Workflow: Record Workflow;
        WorkflowStep: Record "Workflow Step";
    begin
        WorkflowStep.SetRange("Workflow Code", Code);
        WorkflowStep.SetRange(Type, WorkflowStep.Type::"Sub-Workflow");

        if WorkflowStep.FindSet() then
            repeat
                Workflow.Get(WorkflowStep."Function Name");

                if not Workflow.Enabled then
                    Error(SubWorkflowNotEnabledErr, WorkflowStep."Function Name", Code);
            until WorkflowStep.Next() = 0;
    end;

    local procedure CheckResponseOptions()
    var
        WorkflowStep: Record "Workflow Step";
        WorkflowResponseHandling: Codeunit "Workflow Response Handling";
    begin
        WorkflowStep.SetRange("Workflow Code", Code);
        WorkflowStep.SetRange(Type, WorkflowStep.Type::Response);

        if WorkflowStep.FindSet() then
            repeat
                if not WorkflowResponseHandling.HasRequiredArguments(WorkflowStep) then
                    Error(MissingRespOptionsErr);
            until WorkflowStep.Next() = 0;
    end;

    local procedure CheckEntryPointEventConditions()
    var
        ThisWorkflowStep: Record "Workflow Step";
        ThisWorkflowDefinition: Query "Workflow Definition";
    begin
        ThisWorkflowDefinition.SetRange(Code, Code);
        ThisWorkflowDefinition.SetRange(Entry_Point, true);
        ThisWorkflowDefinition.SetRange(Type, ThisWorkflowDefinition.Type::"Event");
        ThisWorkflowDefinition.Open();

        while ThisWorkflowDefinition.Read() do begin
            ThisWorkflowStep.Get(ThisWorkflowDefinition.Code, ThisWorkflowDefinition.ID);
            CheckEntryPointsInSameWorkflow(ThisWorkflowStep, ThisWorkflowDefinition);
            CheckEntryPointsInOtherEnabledWorkflows(ThisWorkflowStep, ThisWorkflowDefinition);
        end;
    end;

    local procedure CheckEntryPointsInSameWorkflow(ThisWorkflowStep: Record "Workflow Step"; ThisWorkflowDefinition: Query "Workflow Definition")
    var
        OtherWorkflowStep: Record "Workflow Step";
        OtherWorkflowDefinition: Query "Workflow Definition";
    begin
        OtherWorkflowDefinition.SetRange(Code, ThisWorkflowDefinition.Code);
        OtherWorkflowDefinition.SetFilter(ID, '<>%1', ThisWorkflowDefinition.ID);
        OtherWorkflowDefinition.SetRange(Entry_Point, true);
        OtherWorkflowDefinition.SetRange(Type, OtherWorkflowDefinition.Type::"Event");
        OtherWorkflowDefinition.SetRange(Function_Name, ThisWorkflowDefinition.Function_Name);
        OtherWorkflowDefinition.SetRange(Table_ID, ThisWorkflowDefinition.Table_ID);
        OtherWorkflowDefinition.Open();

        while OtherWorkflowDefinition.Read() do begin
            OtherWorkflowStep.Get(OtherWorkflowDefinition.Code, OtherWorkflowDefinition.ID);
            CompareWorkflowStepArguments(ThisWorkflowStep, OtherWorkflowStep, ThisWorkflowDefinition, ThisWorkflowDefinition);
        end;
    end;

    local procedure CheckEntryPointsInOtherEnabledWorkflows(ThisWorkflowStep: Record "Workflow Step"; ThisWorkflowDefinition: Query "Workflow Definition")
    var
        OtherWorkflowStep: Record "Workflow Step";
        OtherWorkflowDefinition: Query "Workflow Definition";
    begin
        OtherWorkflowDefinition.SetFilter(Code, '<>%1', ThisWorkflowDefinition.Code);
        OtherWorkflowDefinition.SetRange(Enabled, true);
        OtherWorkflowDefinition.SetRange(Entry_Point, true);
        OtherWorkflowDefinition.SetRange(Type, OtherWorkflowDefinition.Type::"Event");
        OtherWorkflowDefinition.SetRange(Function_Name, ThisWorkflowDefinition.Function_Name);
        OtherWorkflowDefinition.SetRange(Table_ID, ThisWorkflowDefinition.Table_ID);
        OtherWorkflowDefinition.Open();

        while OtherWorkflowDefinition.Read() do begin
            OtherWorkflowStep.Get(OtherWorkflowDefinition.Code, OtherWorkflowDefinition.ID);
            CompareWorkflowStepArguments(ThisWorkflowStep, OtherWorkflowStep, ThisWorkflowDefinition, ThisWorkflowDefinition);
        end;
    end;

    local procedure CheckEventTableRelation()
    var
        WorkflowStep: Record "Workflow Step";
        NextWorkflowStep: Record "Workflow Step";
        WorkflowEvent: Record "Workflow Event";
        WorkflowTableRelation: Record "Workflow - Table Relation";
        CurrentTable: Integer;
        NextTable: Integer;
    begin
        WorkflowStep.SetRange("Workflow Code", Code);
        WorkflowStep.SetRange(Type, WorkflowStep.Type::"Event");
        if WorkflowStep.FindSet() then
            repeat
                WorkflowEvent.Get(WorkflowStep."Function Name");
                CurrentTable := WorkflowEvent."Table ID";
                if WorkflowStep.HasEventsInSubtree(NextWorkflowStep) then begin
                    WorkflowEvent.Get(NextWorkflowStep."Function Name");
                    NextTable := WorkflowEvent."Table ID";
                    if CurrentTable <> NextTable then begin
                        WorkflowTableRelation.SetRange("Table ID", CurrentTable);
                        WorkflowTableRelation.SetRange("Related Table ID", NextTable);
                        if WorkflowTableRelation.IsEmpty() then
                            Error(ValidateTableRelationErr);
                    end;
                end;
            until WorkflowStep.Next() = 0;
    end;

    local procedure CheckRecordChangedWorkflows()
    var
        WorkflowStep: Record "Workflow Step";
        WorkflowResponseHandling: Codeunit "Workflow Response Handling";
    begin
        WorkflowStep.SetRange("Workflow Code", Code);
        WorkflowStep.SetRange(Type, WorkflowStep.Type::Response);
        WorkflowStep.SetRange("Function Name", WorkflowResponseHandling.RevertValueForFieldCode());
        if not WorkflowStep.IsEmpty() then begin
            WorkflowStep.SetRange("Function Name", WorkflowResponseHandling.ApplyNewValuesCode());
            if WorkflowStep.IsEmpty() then
                Error(WorkflowMustApplySavedValuesErr);
        end;

        WorkflowStep.SetRange("Function Name", WorkflowResponseHandling.ApplyNewValuesCode());
        if not WorkflowStep.IsEmpty() then begin
            WorkflowStep.SetRange("Function Name", WorkflowResponseHandling.RevertValueForFieldCode());
            if WorkflowStep.IsEmpty() then
                Error(WorkflowMustRevertValuesErr);
        end;
    end;

    local procedure CompareWorkflowStepArguments(ThisWorkflowStep: Record "Workflow Step"; OtherWorkflowStep: Record "Workflow Step"; ThisWorkflowDefinition: Query "Workflow Definition"; OtherWorkflowDefinition: Query "Workflow Definition")
    var
        OtherWorkflowStepArgument: Record "Workflow Step Argument";
        ThisWorkflowStepArgument: Record "Workflow Step Argument";
        TableCaption: Text;
    begin
        TableCaption := GetTableCaption(ThisWorkflowDefinition.Table_ID);

        if ((not ThisWorkflowStepArgument.Get(ThisWorkflowDefinition.Argument)) and
            (not ThisWorkflowStep.HasWorkflowRules())) or
           ((not OtherWorkflowStepArgument.Get(OtherWorkflowDefinition.Argument)) and
            (not OtherWorkflowStep.HasWorkflowRules()))
        then
            Error(SameEventConditionsErr, TableCaption);

        if ThisWorkflowStepArgument.Equals(OtherWorkflowStepArgument) and
           ThisWorkflowStep.CompareEventConditions(OtherWorkflowStep) and
           ThisWorkflowStep.CompareEventRule(OtherWorkflowStep)
        then
            Error(SameEventConditionsErr, TableCaption);
    end;

    local procedure GetTableCaption(TableID: Integer): Text
    var
        RecRef: RecordRef;
    begin
        if TableID = 0 then
            exit('');

        RecRef.Open(TableID);
        exit(RecRef.Caption);
    end;

    local procedure CheckEditingReferringWorkflowsIsAllowed()
    var
        Workflow: Record Workflow;
        WorkflowStep: Record "Workflow Step";
        WorkflowDefinition: Query "Workflow Definition";
    begin
        WorkflowStep.SetRange(Type, WorkflowStep.Type::"Sub-Workflow");
        WorkflowStep.SetRange("Function Name", Code);

        if not WorkflowStep.IsEmpty() then
            if not Confirm(DisableReferringWorkflowsQst, false, Code) then
                Error(DisableReferringWorkflowsErr, Code);

        WorkflowDefinition.SetFilter(Code, '<>%1', Code);
        WorkflowDefinition.SetRange(Type, WorkflowDefinition.Type::"Sub-Workflow");
        WorkflowDefinition.SetRange(Function_Name, Code);
        WorkflowDefinition.SetRange(Enabled, true);
        WorkflowDefinition.Open();

        while WorkflowDefinition.Read() do begin
            Workflow.Get(WorkflowDefinition.Code);
            Workflow.Validate(Enabled, false);
            Workflow.Modify(true);
        end;
    end;

    procedure CheckEditingIsAllowed()
    var
        WorkflowSetup: Codeunit "Workflow Setup";
        AllowEditTemplate: Boolean;
    begin
        WorkflowSetup.OnAllowEditOfWorkflowTemplates(AllowEditTemplate);

        if Template and (not AllowEditTemplate) then
            Error(CannotEditTemplateWorkflowErr);
        if Enabled then
            Error(CannotEditEnabledWorkflowErr);
    end;

    local procedure CheckWorkflowCodeDoesNotExistAsTemplate()
    var
        Workflow: Record Workflow;
    begin
        Workflow.SetRange(Template, true);
        Workflow.SetRange(Code, Code);
        if not Workflow.IsEmpty() then
            Error(WorkflowExistsAsTemplateErr);
    end;

    procedure LookupOtherWorkflowCode(var LookupCode: Code[20]): Boolean
    var
        Workflow: Record Workflow;
    begin
        Workflow.SetFilter(Code, '<>%1', Code);

        if PAGE.RunModal(0, Workflow) = ACTION::LookupOK then begin
            LookupCode := Workflow.Code;
            exit(true);
        end;
    end;

    procedure InsertAfterFunctionName(FunctionName: Code[128]; NewFunctionName: Code[128]; NewEntryPoint: Boolean; NewType: Option)
    var
        WorkflowStep: Record "Workflow Step";
        NewWorkflowStep: Record "Workflow Step";
    begin
        WorkflowStep.SetRange("Workflow Code", Code);
        WorkflowStep.SetRange("Function Name", FunctionName);
        if WorkflowStep.FindSet() then
            repeat
                NewWorkflowStep.Init();
                NewWorkflowStep.Validate("Workflow Code", Code);
                NewWorkflowStep.Validate(Type, NewType);
                NewWorkflowStep.Validate("Function Name", NewFunctionName);
                NewWorkflowStep.Validate("Entry Point", NewEntryPoint);
                NewWorkflowStep.Insert(true);
                WorkflowStep.InsertAfterStep(NewWorkflowStep);
            until WorkflowStep.Next() = 0;
    end;

    [Scope('OnPrem')]
    procedure ExportToBlob(var TempBlob: Codeunit "Temp Blob")
    var
        OutStream: OutStream;
    begin
        Clear(TempBlob);
        TempBlob.CreateOutStream(OutStream);
        XMLPORT.Export(XMLPORT::"Import / Export Workflow", OutStream, Rec);
    end;

    [Scope('OnPrem')]
    procedure ImportFromBlob(var TempBlob: Codeunit "Temp Blob")
    var
        ImportExportWorkflow: XMLport "Import / Export Workflow";
        InStream: InStream;
    begin
        TempBlob.CreateInStream(InStream);
        ImportExportWorkflow.SetSource(InStream);
        ImportExportWorkflow.InitWorkflow(Code);
        ImportExportWorkflow.SetTableView(Rec);
        ImportExportWorkflow.Import();
    end;

    procedure CanDelete(ThrowErrors: Boolean): Boolean
    var
        WorkflowStepInstance: Record "Workflow Step Instance";
        WorkflowSetup: Codeunit "Workflow Setup";
        AllowDeleteTemplate: Boolean;
    begin
        if Enabled then
            exit(ThrowOrReturnFalse(ThrowErrors, CannotDeleteEnabledWorkflowErr));

        WorkflowStepInstance.SetRange("Workflow Code", Code);
        WorkflowStepInstance.SetRange(Status, WorkflowStepInstance.Status::Inactive, WorkflowStepInstance.Status::Active);
        if not WorkflowStepInstance.IsEmpty() then
            exit(ThrowOrReturnFalse(ThrowErrors, CannotDeleteWorkflowWithActiveInstancesErr));

        WorkflowSetup.OnAllowEditOfWorkflowTemplates(AllowDeleteTemplate);
        if Template and not (AllowDeleteTemplate) then
            exit(ThrowOrReturnFalse(ThrowErrors, CannotDeleteWorkflowTemplatesErr));

        exit(true);
    end;

    local procedure ThrowOrReturnFalse(ShouldThrow: Boolean; Message: Text): Boolean
    begin
        if ShouldThrow then
            Error(Message);

        exit(false);
    end;
}

