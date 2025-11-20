namespace System.Automation;

using System;
using System.Telemetry;
using System.Utilities;

codeunit 1501 "Workflow Management"
{
    Permissions = TableData Workflow = R,
                  TableData "Workflow Step" = R,
                  TableData "Workflow Step Instance" = Rimd,
                  TableData "Workflow Table Relation Value" = rimd,
                  tabledata "Workflow Event" = r,
                  TableData "Workflow Event Queue" = rimd,
                  TableData "Workflow Step Argument" = rd,
                  TableData "Workflow - Record Change" = rimd,
                  TableData "Workflow Record Change Archive" = rimd,
                  TableData "Workflow Step Instance Archive" = rimd,
                  TableData "Workflow Step Argument Archive" = rimd,
                  tabledata "Workflow - Table Relation" = r;

    trigger OnRun()
    begin
    end;

    var
        WorkflowRecordManagement: Codeunit "Workflow Record Management";
        AlwaysTxt: Label '<Always>';
        CombinedConditionTxt: Label '%1; %2', Locked = true;

        // Telemetry strings
        WorkflowTelemetryCategoryTxt: Label 'Workflow', Locked = true;
        WorkflowEventStartTelemetryTxt: Label 'Workflow event: Start Scope', Locked = true;
        WorkflowUpgradeTxt: Label 'Skip executing workflow during upgrade.', Locked = true;
        WorkflowEventEndTelemetryTxt: Label 'Workflow event: End Scope', Locked = true;
        WorkflowStepFoundTelemetryTxt: Label 'Active workflow step instance was found for the provided function and the conditions were met', Locked = true;
        WorkflowStepConditionsNotMetTelemetryTxt: Label 'Active workflow step instances were found for the provided function, but the conditions were not met', Locked = true;
        WorkflowMatchingStepFoundTelemetryTxt: Label 'Matching workflow step instance found for the provided function', Locked = true;
        WorkflowInstanceCreatedTelemetryTxt: Label 'Workflow instance created', Locked = true;
        WorkflowNotFoundTelemetryTxt: Label 'No active workflow or step instance found', Locked = true;
        WorkflowStepNotFoundTelemetryTxt: Label 'No actionable workflow step was found for the provided function or the conditions were not met', Locked = true;
        WorkflowArchiveTelemetryTxt: Label 'Workflow is being archived', Locked = true;

    procedure TrackWorkflow(Variant: Variant; var WorkflowStepInstance: Record "Workflow Step Instance")
    var
        RecRef: RecordRef;
    begin
        WorkflowStepInstance.MoveForward(Variant);
        RecRef.GetTable(Variant);
        UpdateRelatedTableValues(RecRef);

        if IsWorkflowCompleted(WorkflowStepInstance) then
            ArchiveWorkflowInstance(WorkflowStepInstance);
    end;

    procedure FindWorkflowStepInstance(Variant: Variant; xVariant: Variant; var WorkflowStepInstance: Record "Workflow Step Instance"; FunctionName: Code[128]): Boolean
    begin
        exit(FindWorkflowStepInstanceWithOptionalWorkflowStart(Variant, xVariant, WorkflowStepInstance, FunctionName, true));
    end;

    procedure CanExecuteWorkflow(Variant: Variant; FunctionName: Code[128]): Boolean
    var
        WorkflowStepInstance: Record "Workflow Step Instance";
    begin
        exit(FindWorkflowStepInstanceWithOptionalWorkflowStart(Variant, Variant, WorkflowStepInstance, FunctionName, false));
    end;

    local procedure FindWorkflowStepInstanceWithOptionalWorkflowStart(Variant: Variant; xVariant: Variant; var WorkflowStepInstance: Record "Workflow Step Instance"; FunctionName: Code[128]; StartWorkflow: Boolean): Boolean
    var
        Workflow: Record Workflow;
        WorkflowRule: Record "Workflow Rule";
        WorkflowStepInstanceLoop: Record "Workflow Step Instance";
        WorkflowStepInstance2: Record "Workflow Step Instance";
        RecRef: RecordRef;
        xRecRef: RecordRef;
        ActiveStepInstanceFound: Boolean;
        TelemetryDimensions: Dictionary of [Text, Text];
    begin
        RecRef.GetTable(Variant);
        xRecRef.GetTable(xVariant);

        if not StartWorkflow then begin
            Workflow.SetRange(Enabled, true);
            if Workflow.IsEmpty() then begin
                // Example Scenario:
                //  1. Approval Workflow is enabled for Sales Order
                //  2. An Approval is sent for a Sales Order -> Step Instance is created
                //  3. The Workflow from (step 1) is disabled before the Approval (from step 2) is processed
                //
                // Disabled workflow can still have active workflow step instances (from before it was disabled, e.g. step 2)
                WorkflowStepInstanceLoop.ReadIsolation := WorkflowStepInstanceLoop.ReadIsolation::ReadUncommitted;
                WorkflowStepInstanceLoop.SetRange(Type, WorkflowStepInstanceLoop.Type::"Event");
                WorkflowStepInstanceLoop.SetRange(Status, WorkflowStepInstanceLoop.Status::Active);
                WorkflowStepInstanceLoop.SetRange("Function Name", FunctionName);
                OnFindWorkflowStepInstanceWithOptionalWorkflowStartOnAfterSetWorkflowStepInstanceLoopFi1tersWhenNotStartWorkFlow(RecRef, WorkflowStepInstanceLoop, FunctionName, StartWorkflow);
                if WorkflowStepInstanceLoop.IsEmpty() then
                    exit(false);
            end;
        end;

        WorkflowStepInstanceLoop.Reset(); // Reset will clear ReadIsolation and SetLoadFields
        WorkflowStepInstanceLoop.ReadIsolation := WorkflowStepInstanceLoop.ReadIsolation::ReadUncommitted;
        WorkflowStepInstanceLoop.SetLoadFields("Sequence No.", "Previous Workflow Step ID", Argument);
        WorkflowStepInstanceLoop.SetRange(Type, WorkflowStepInstanceLoop.Type::"Event");
        WorkflowStepInstanceLoop.SetRange(Status, WorkflowStepInstanceLoop.Status::Active);
        WorkflowStepInstanceLoop.SetRange("Function Name", FunctionName);
        WorkflowStepInstanceLoop.SetFilter("Previous Workflow Step ID", '<>%1', 0); // "Previous Workflow Step ID" is used as primary key in `WorkflowStepInstance2.Get` inside the loop below
        OnFindWorkflowStepInstanceWithOptionalWorkflowStartOnAfterSetWorkflowStepInstanceLoopFi1ters(RecRef, WorkflowStepInstanceLoop, FunctionName, StartWorkflow);
        WorkflowStepInstanceLoop.SetCurrentKey("Sequence No.");

        WorkflowStepInstance2.SetLoadFields(Status, "Record ID");
        WorkflowStepInstance2.ReadIsolation := WorkflowStepInstance2.ReadIsolation::ReadUncommitted;

        WorkflowStepInstance.ReadIsolation := WorkflowStepInstance.ReadIsolation::ReadUncommitted;

        // Example Scenario: There exists a sequence of workflow step instances like below
        // Step1 -> Step2.1 -> Step3
        //       \
        //        -> Step2.2
        //
        // Each of the step instances have properties:
        // Step1   - "Previous Workflow Step ID" = 0       - Status = Complete|Processing
        // Step2.1 - "Previous Workflow Step ID" = Step1   - Status = Active                - Condition = Met
        // Step2.2 - "Previous Workflow Step ID" = Step1   - Status = Active                - Condition = Not Met
        // Step3   - "Previous Workflow Step ID" = Step2.1
        //
        // Below Loop will find Step2.1 and return true
        if WorkflowStepInstanceLoop.FindSet() then
            repeat
                // below IF statements separated for performance reasons, no short-circuit evaluation in AL
                if WorkflowStepInstance2.Get(WorkflowStepInstanceLoop.ID, WorkflowStepInstanceLoop."Workflow Code", WorkflowStepInstanceLoop."Previous Workflow Step ID") then
                    if WorkflowStepInstance2.Status in [WorkflowStepInstance2.Status::Completed, WorkflowStepInstance2.Status::Processing] then
                        if Format(WorkflowStepInstance2."Record ID") = Format(RecRef.RecordId) then begin
                            ActiveStepInstanceFound := true;
                            WorkflowStepInstanceLoop.FindWorkflowRules(WorkflowRule);
                            if EvaluateCondition(RecRef, xRecRef, WorkflowStepInstanceLoop.Argument, WorkflowRule) then begin // Step2.1 in above example
                                WorkflowStepInstance.Get(WorkflowStepInstanceLoop.ID, WorkflowStepInstanceLoop."Workflow Code", WorkflowStepInstanceLoop."Workflow Step ID");
                                GetTelemetryDimensions(FunctionName, WorkflowStepInstance.ToString(), TelemetryDimensions);
                                Session.LogMessage('0000DZB', WorkflowStepFoundTelemetryTxt, Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, TelemetryDimensions);

                                exit(true);
                            end;
                        end;
            until WorkflowStepInstanceLoop.Next() = 0;

        // This occurs when there are active steps found, but the conditions were not met
        // e.g. If Step2.1 from above scenario doesn't exist, we will find Step2.2 and return false instead
        if ActiveStepInstanceFound then begin
            GetTelemetryDimensions(FunctionName, '', TelemetryDimensions);
            Session.LogMessage('0000DZC', WorkflowStepConditionsNotMetTelemetryTxt, Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, TelemetryDimensions);

            exit(false);
        end;

        WorkflowStepInstance.Reset();
        WorkflowStepInstance.ReadIsolation := WorkflowStepInstance.ReadIsolation::ReadUncommitted;
        // Example Scenario:
        // 1. Post Purchase Invoice (No. = 10804)
        // 2. Workflow is set up to automatically create a General Journal Line for posted Purchase Invoice
        // 3. RecRef is (about to be inserted) General Journal Line (table = 81, field 36 "Applies-to Doc. No." = 10804)
        // 4. "Workflow Table Relation Value" has one entry matching
        //     - Table ID = 122 (Purchase Invoice Header)
        //     - Field ID = 3   (No.)
        //     - Related Table ID = 81 (General Journal Line)
        //     - Related Field ID = 36 (Applies-to Doc. No.)
        //     - Value = 10804
        //
        // This scenario is not caught in the previous loop, because we can't know RecRef.RecordId in advance.
        // The corresponding Workflow Step Instance's "Record ID" field is, in fact, empty.
        if FindMatchingWorkflowStepInstance(RecRef, xRecRef, WorkflowStepInstance, FunctionName) then begin
            GetTelemetryDimensions(FunctionName, WorkflowStepInstance.ToString(), TelemetryDimensions);
            Session.LogMessage('0000DZD', WorkflowMatchingStepFoundTelemetryTxt, Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, TelemetryDimensions);

            exit(true);
        end;

        WorkflowStepInstance.Reset();
        WorkflowStepInstance.ReadIsolation := WorkflowStepInstance.ReadIsolation::ReadUncommitted;
        // When no workflow step instance is found, we check if a workflow is enabled for the provided function name and ready to start
        if FindWorkflow(RecRef, xRecRef, FunctionName, Workflow) then begin
            if StartWorkflow then begin
                InstantiateWorkflow(Workflow, FunctionName, WorkflowStepInstance);

                GetTelemetryDimensions(FunctionName, WorkflowStepInstance.ToString(), TelemetryDimensions);
                Session.LogMessage('0000DYR', WorkflowInstanceCreatedTelemetryTxt, Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, TelemetryDimensions);
            end;
            exit(true);
        end;

        exit(false);
    end;

    procedure MarkChildrenStatus(WorkflowStepInstance: Record "Workflow Step Instance"; NewStatus: Option)
    var
        ChildWorkflowStepInstance: Record "Workflow Step Instance";
    begin
        ChildWorkflowStepInstance.SetRange("Workflow Code", WorkflowStepInstance."Workflow Code");
        ChildWorkflowStepInstance.SetRange("Previous Workflow Step ID", WorkflowStepInstance."Workflow Step ID");
        ChildWorkflowStepInstance.SetRange(ID, WorkflowStepInstance.ID);
        ChildWorkflowStepInstance.SetFilter(Status, '<>%1', WorkflowStepInstance.Status::Processing);
        ChildWorkflowStepInstance.ModifyAll(Status, NewStatus, true);
    end;

    procedure MarkSiblingStatus(WorkflowStepInstance: Record "Workflow Step Instance"; NewStatus: Option)
    var
        SiblingWorkflowStepInstance: Record "Workflow Step Instance";
    begin
        SiblingWorkflowStepInstance.SetRange("Workflow Code", WorkflowStepInstance."Workflow Code");
        SiblingWorkflowStepInstance.SetRange(ID, WorkflowStepInstance.ID);
        SiblingWorkflowStepInstance.SetRange("Previous Workflow Step ID", WorkflowStepInstance."Previous Workflow Step ID");
        SiblingWorkflowStepInstance.SetFilter("Workflow Step ID", '<>%1', WorkflowStepInstance."Workflow Step ID");
        SiblingWorkflowStepInstance.SetFilter(Status, '<>%1', WorkflowStepInstance.Status::Processing);
        SiblingWorkflowStepInstance.ModifyAll(Status, NewStatus, true);
    end;

    procedure UpdateStatus(var WorkflowStepInstance: Record "Workflow Step Instance"; NewStatus: Option; ChildrenStatus: Option; SiblingsStatus: Option)
    begin
        WorkflowStepInstance.Status := NewStatus;
        WorkflowStepInstance.Modify(true);

        MarkChildrenStatus(WorkflowStepInstance, ChildrenStatus);

        MarkSiblingStatus(WorkflowStepInstance, SiblingsStatus);
    end;

    procedure FindWorkflow(RecRef: RecordRef; xRecRef: RecordRef; FunctionName: Code[128]; var Workflow: Record Workflow): Boolean
    var
        WorkflowStep: Record "Workflow Step";
        WorkflowRule: Record "Workflow Rule";
        WorkflowEvent: Record "Workflow Event";
    begin
        Workflow.SetRange(Enabled, true);
        if Workflow.IsEmpty() then
            exit(false);

        WorkflowEvent.SetRange("Table ID", RecRef.Number);
        WorkflowEvent.SetRange("Function Name", FunctionName);

        if WorkflowEvent.IsEmpty() then
            exit(false);

        WorkflowStep.SetLoadFields(WorkflowStep."Workflow Code", WorkflowStep.Argument);
        // Fields filtered with SetRange and primary key will be loaded automatically
        WorkflowStep.SetRange("Function Name", FunctionName);
        WorkflowStep.SetRange("Entry Point", true);
        WorkflowStep.SetRange(Type, WorkflowStep.Type::"Event");
        if WorkflowStep.FindSet() then
            repeat
                if Workflow.Get(WorkflowStep."Workflow Code") then
                    if Workflow.Enabled then begin
                        WorkflowStep.SetFilters(WorkflowRule);
                        if EvaluateCondition(RecRef, xRecRef, WorkflowStep.Argument, WorkflowRule) then begin
                            Workflow.Get(Workflow.Code);
                            exit(true);
                        end;
                    end;
            until WorkflowStep.Next() = 0;
        Clear(Workflow);
        exit(false);
    end;

    procedure WorkflowExists(Variant: Variant; xVariant: Variant; FunctionName: Code[128]): Boolean
    var
        Workflow: Record Workflow;
        RecordRef: RecordRef;
        xRecordRef: RecordRef;
    begin
        RecordRef.GetTable(Variant);
        xRecordRef.GetTable(xVariant);
        exit(FindWorkflow(RecordRef, xRecordRef, FunctionName, Workflow));
    end;

    local procedure InstantiateWorkflow(Workflow: Record Workflow; FunctionName: Text; var WorkflowStepInstance: Record "Workflow Step Instance")
    begin
        Workflow.CreateInstance(WorkflowStepInstance);
        WorkflowStepInstance.SetRange("Function Name", FunctionName);
        WorkflowStepInstance.FindFirst();
    end;

    local procedure UpdateRelatedTableValues(RecRef: RecordRef)
    var
        WorkflowTableRelationValue: Record "Workflow Table Relation Value";
    begin
        WorkflowTableRelationValue.SetRange("Record ID", RecRef.RecordId);
        if WorkflowTableRelationValue.FindSet(true) then
            repeat
                WorkflowTableRelationValue.UpdateRelationValue(RecRef);
            until WorkflowTableRelationValue.Next() = 0;
    end;

    local procedure FindMatchingWorkflowStepInstance(RecRef: RecordRef; xRecRef: RecordRef; var WorkflowStepInstance: Record "Workflow Step Instance"; FunctionName: Code[128]): Boolean
    var
        WorkflowRule: Record "Workflow Rule";
    begin
        WorkflowStepInstance.ReadIsolation := WorkflowStepInstance.ReadIsolation::ReadUncommitted;
        WorkflowStepInstance.SetLoadFields(Argument, "Original Workflow Code", "Original Workflow Step ID");
        WorkflowStepInstance.SetRange("Function Name", FunctionName);
        WorkflowStepInstance.SetRange(Type, WorkflowStepInstance.Type::"Event");
        WorkflowStepInstance.SetFilter(Status, '%1|%2', WorkflowStepInstance.Status::Active, WorkflowStepInstance.Status::Processing);
        if WorkflowStepInstance.FindSet() then
            repeat
                WorkflowStepInstance.FindWorkflowRules(WorkflowRule);
                if WorkflowStepInstance.MatchesRecordValues(RecRef) then
                    if EvaluateCondition(RecRef, xRecRef, WorkflowStepInstance.Argument, WorkflowRule) then
                        exit(true);
            until WorkflowStepInstance.Next() = 0;
        exit(false);
    end;

    local procedure EvaluateCondition(RecRef: RecordRef; xRecRef: RecordRef; ArgumentID: Guid; var WorkflowRule: Record "Workflow Rule"): Boolean
    var
        WorkflowStepArgument: Record "Workflow Step Argument";
        TempBlob: Codeunit "Temp Blob";
        Result: Boolean;
    begin
        if WorkflowStepArgument.Get(ArgumentID) and WorkflowStepArgument."Event Conditions".HasValue() then begin
            TempBlob.FromRecord(WorkflowStepArgument, WorkflowStepArgument.FieldNo("Event Conditions"));
            Result := EvaluateConditionOnTable(RecRef.RecordId, RecRef.Number, TempBlob) and
              EvaluateConditionsOnRelatedTables(RecRef, TempBlob);
        end else
            Result := true;

        Result := Result and EvaluateRules(RecRef, xRecRef, WorkflowRule);

        OnAfterEvaluateCondition(RecRef, xRecRef, ArgumentID, WorkflowRule, Result);
        exit(Result);
    end;

    local procedure EvaluateConditionOnTable(SourceRecordId: RecordID; TableId: Integer; TempBlob: Codeunit "Temp Blob"): Boolean
    var
        RequestPageParametersHelper: Codeunit "Request Page Parameters Helper";
        RecRef: RecordRef;
        LookupRecRef: RecordRef;
    begin
        RecRef.Open(TableId);

        if not RequestPageParametersHelper.ConvertParametersToFilters(RecRef, TempBlob, TextEncoding::UTF8) then
            exit(true);

        if not LookupRecRef.Get(SourceRecordId) then
            exit(false);

        LookupRecRef.SetView(RecRef.GetView(false));

        exit(LookupRecRef.Find());
    end;

    local procedure EvaluateRules(RecRef: RecordRef; xRecRef: RecordRef; var WorkflowRule: Record "Workflow Rule") Result: Boolean
    begin
        if RecRef.Number <> xRecRef.Number then
            exit(false);

        Result := true;
        if WorkflowRule.FindSet() then
            repeat
                Result := Result and WorkflowRule.EvaluateRule(RecRef, xRecRef);
            until (WorkflowRule.Next() = 0) or (not Result);

        exit(Result);
    end;

    local procedure IsWorkflowCompleted(WorkflowStepInstance: Record "Workflow Step Instance"): Boolean
    var
        CompletedWorkflowStepInstance: Record "Workflow Step Instance";
    begin
        CompletedWorkflowStepInstance.SetRange("Workflow Code", WorkflowStepInstance."Workflow Code");
        CompletedWorkflowStepInstance.SetRange(ID, WorkflowStepInstance.ID);
        CompletedWorkflowStepInstance.SetRange(Status, WorkflowStepInstance.Status::Active);
        exit(CompletedWorkflowStepInstance.IsEmpty);
    end;

    procedure ArchiveWorkflowInstance(WorkflowStepInstance: Record "Workflow Step Instance")
    var
        ToArchiveWorkflowStepInstance: Record "Workflow Step Instance";
        WorkflowStepInstanceArchive: Record "Workflow Step Instance Archive";
        ToArchiveWorkflowRecordChange: Record "Workflow - Record Change";
        WorkflowRecordChangeArchive: Record "Workflow Record Change Archive";
        ToArchiveWorkflowStepArgument: Record "Workflow Step Argument";
        TelemetryDimensions: Dictionary of [Text, Text];
    begin
        GetTelemetryDimensions(WorkflowStepInstance."Function Name", WorkflowStepInstance.ToString(), TelemetryDimensions);
        Session.LogMessage('0000DZF', WorkflowArchiveTelemetryTxt, Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, TelemetryDimensions);

        ToArchiveWorkflowStepInstance.SetRange("Workflow Code", WorkflowStepInstance."Workflow Code");
        ToArchiveWorkflowStepInstance.SetRange(ID, WorkflowStepInstance.ID);

        if ToArchiveWorkflowStepInstance.FindSet() then begin
            repeat
                WorkflowStepInstanceArchive.Init();
                WorkflowStepInstanceArchive.TransferFields(ToArchiveWorkflowStepInstance);
                if ToArchiveWorkflowStepArgument.Get(ToArchiveWorkflowStepInstance.Argument) then begin
                    WorkflowStepInstanceArchive.Argument := CreateWorkflowStepArgumentArchive(ToArchiveWorkflowStepArgument);
                    ToArchiveWorkflowStepArgument.Delete(true);
                end;
                WorkflowStepInstanceArchive.Insert();
            until ToArchiveWorkflowStepInstance.Next() = 0;

            ToArchiveWorkflowStepInstance.DeleteAll(true);
        end;

        ToArchiveWorkflowRecordChange.SetRange("Workflow Step Instance ID", WorkflowStepInstance.ID);

        if ToArchiveWorkflowRecordChange.FindSet() then begin
            repeat
                WorkflowRecordChangeArchive.Init();
                WorkflowRecordChangeArchive.TransferFields(ToArchiveWorkflowRecordChange);
                if not WorkflowRecordChangeArchive.Insert() then
                    WorkflowRecordChangeArchive.Modify();
            until ToArchiveWorkflowRecordChange.Next() = 0;

            ToArchiveWorkflowRecordChange.DeleteAll(true);
        end;
    end;

    local procedure EvaluateConditionsOnRelatedTables(RecRef: RecordRef; TempBlob: Codeunit "Temp Blob"): Boolean
    var
        WorkflowTableRelation: Record "Workflow - Table Relation";
        RequestPageParametersHelper: Codeunit "Request Page Parameters Helper";
        RecRefRelated: RecordRef;
        List: DotNet ArrayList;
    begin
        WorkflowTableRelation.SetRange("Table ID", RecRef.Number);

        if WorkflowTableRelation.FindSet() then begin
            List := List.ArrayList();
            repeat
                if not List.Contains(WorkflowTableRelation."Related Table ID") then begin
                    List.Add(WorkflowTableRelation."Related Table ID");
                    RecRefRelated.Open(WorkflowTableRelation."Related Table ID");
                    if RequestPageParametersHelper.ConvertParametersToFilters(RecRefRelated, TempBlob, TextEncoding::UTF8) then begin
                        ApplyRelationshipFilters(RecRef, RecRefRelated);
                        if RecRefRelated.IsEmpty() then
                            exit(false);
                    end;
                    RecRefRelated.Close();
                end;
            until WorkflowTableRelation.Next() = 0;
        end;

        exit(true);
    end;

    local procedure ApplyRelationshipFilters(RecRef: RecordRef; RecRefRelated: RecordRef)
    var
        WorkflowTableRelation: Record "Workflow - Table Relation";
        FieldRefSrc: FieldRef;
        FieldRefRelated: FieldRef;
    begin
        WorkflowTableRelation.SetRange("Table ID", RecRef.Number);
        WorkflowTableRelation.SetRange("Related Table ID", RecRefRelated.Number);
        if WorkflowTableRelation.FindSet() then
            repeat
                FieldRefRelated := RecRefRelated.Field(WorkflowTableRelation."Related Field ID");
                FieldRefSrc := RecRef.Field(WorkflowTableRelation."Field ID");
                FieldRefRelated.SetRange(FieldRefSrc.Value);
            until WorkflowTableRelation.Next() = 0
    end;

    procedure FindResponse(var ResponseWorkflowStepInstance: Record "Workflow Step Instance"; PreviousWorkflowStepInstance: Record "Workflow Step Instance"): Boolean
    begin
        ResponseWorkflowStepInstance.SetRange("Workflow Code", PreviousWorkflowStepInstance."Workflow Code");
        ResponseWorkflowStepInstance.SetRange(ID, PreviousWorkflowStepInstance.ID);
        ResponseWorkflowStepInstance.SetRange(Type, ResponseWorkflowStepInstance.Type::Response);
        ResponseWorkflowStepInstance.SetRange("Previous Workflow Step ID", PreviousWorkflowStepInstance."Workflow Step ID");
        exit(ResponseWorkflowStepInstance.FindFirst());
    end;

    procedure FindEventWorkflowStepInstance(var WorkflowStepInstance: Record "Workflow Step Instance"; FunctionName: Code[128]; Variant: Variant; xVariant: Variant): Boolean
    var
        Workflow: Record Workflow;
        WorkflowEvent: Record "Workflow Event";
        TelemetryDimensions: Dictionary of [Text, Text];
    begin
        Workflow.SetRange(Enabled, true);
        WorkflowStepInstance.ReadIsolation(WorkflowStepInstance.ReadIsolation::ReadUncommitted);
        if WorkflowStepInstance.IsEmpty() and Workflow.IsEmpty() then begin
            GetTelemetryDimensions(FunctionName, '', TelemetryDimensions);
            Session.LogMessage('0000DZE', WorkflowNotFoundTelemetryTxt, Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, TelemetryDimensions);
            exit(false);
        end;

        WorkflowEvent.Get(FunctionName);

        exit(FindWorkflowStepInstance(Variant, xVariant, WorkflowStepInstance, WorkflowEvent."Function Name"));
    end;

    procedure HandleEvent(FunctionName: Code[128]; Variant: Variant)
    begin
        HandleEventWithxRec(FunctionName, Variant, Variant);
    end;

    procedure HandleEventWithxRec(FunctionName: Code[128]; Variant: Variant; xVariant: Variant)
    var
        ActionableWorkflowStepInstance: Record "Workflow Step Instance";
        FeatureTelemetry: Codeunit "Feature Telemetry";
        RecRef: RecordRef;
        IsHandled: Boolean;
        TelemetryDimensions: Dictionary of [Text, Text];
    begin
        GetTelemetryDimensions(FunctionName, '', TelemetryDimensions);

        if GetExecutionContext() = ExecutionContext::Upgrade then begin
            Session.LogMessage('0000GG5', WorkflowUpgradeTxt, Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, TelemetryDimensions);
            exit;
        end;

        Session.LogMessage('0000DYS', WorkflowEventStartTelemetryTxt, Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, TelemetryDimensions);

        IsHandled := false;
        OnBeforeHandleEventWithxRec(FunctionName, Variant, xVariant, IsHandled);
        if IsHandled then
            exit;

        RecRef.GetTable(Variant);
        if RecRef.IsTemporary() then
            exit;

        if FindEventWorkflowStepInstance(ActionableWorkflowStepInstance, FunctionName, Variant, xVariant) then begin
            ExecuteResponses(Variant, xVariant, ActionableWorkflowStepInstance);
            FeatureTelemetry.LogUsage('0000GDQ', 'Workflows', 'Event processed');
        end;

        Session.LogMessage('0000DYV', WorkflowEventEndTelemetryTxt, Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, TelemetryDimensions);
    end;

    procedure HandleEventOnKnownWorkflowInstance(FunctionName: Code[128]; Variant: Variant; WorkflowStepInstanceID: Guid)
    begin
        HandleEventWithxRecOnKnownWorkflowInstance(FunctionName, Variant, Variant, WorkflowStepInstanceID)
    end;

    procedure HandleEventWithxRecOnKnownWorkflowInstance(FunctionName: Code[128]; Variant: Variant; xVariant: Variant; WorkflowStepInstanceID: Guid)
    var
        WorkflowStepInstance: Record "Workflow Step Instance";
        ActionableWorkflowStepInstance: Record "Workflow Step Instance";
        WorkflowRule: Record "Workflow Rule";
        RecRef: RecordRef;
        xRecRef: RecordRef;
        ActionableStepFound: Boolean;
        TelemetryDimensions: Dictionary of [Text, Text];
    begin
        GetTelemetryDimensions(FunctionName, '', TelemetryDimensions);
        Session.LogMessage('0000DYW', WorkflowEventStartTelemetryTxt, Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, TelemetryDimensions);

        RecRef.GetTable(Variant);
        xRecRef.GetTable(xVariant);

        WorkflowStepInstance.SetRange(ID, WorkflowStepInstanceID);
        WorkflowStepInstance.SetRange(Status, ActionableWorkflowStepInstance.Status::Active);
        WorkflowStepInstance.SetRange("Function Name", FunctionName);
        if WorkflowStepInstance.FindSet() then
            repeat
                WorkflowStepInstance.FindWorkflowRules(WorkflowRule);
                if EvaluateCondition(RecRef, xRecRef, WorkflowStepInstance.Argument, WorkflowRule) then begin
                    ActionableWorkflowStepInstance := WorkflowStepInstance;
                    ActionableStepFound := true;
                end;
            until (WorkflowStepInstance.Next() = 0) or ActionableStepFound;

        if ActionableStepFound then begin
            GetTelemetryDimensions(FunctionName, ActionableWorkflowStepInstance.ToString(), TelemetryDimensions);
            Session.LogMessage('0000DYX', WorkflowStepFoundTelemetryTxt, Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, TelemetryDimensions);

            ExecuteResponses(Variant, xVariant, ActionableWorkflowStepInstance);
        end else begin
            GetTelemetryDimensions(FunctionName, '', TelemetryDimensions);
            Session.LogMessage('0000DYY', WorkflowStepNotFoundTelemetryTxt, Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, TelemetryDimensions);
        end;

        GetTelemetryDimensions(FunctionName, '', TelemetryDimensions);
        Session.LogMessage('0000DYZ', WorkflowEventEndTelemetryTxt, Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, TelemetryDimensions);
    end;

    procedure ExecuteResponses(Variant: Variant; xVariant: Variant; ActionableWorkflowStepInstance: Record "Workflow Step Instance")
    var
        ResponseWorkflowStepInstance: Record "Workflow Step Instance";
        WorkflowResponseHandling: Codeunit "Workflow Response Handling";
        RecRef: RecordRef;
        Variant1: Variant;
    begin
        if not CanExecuteEvent(ActionableWorkflowStepInstance) then begin
            StoreEventForLaterProcessing(Variant, xVariant, ActionableWorkflowStepInstance);

            if ActionableWorkflowStepInstance.Status <> ActionableWorkflowStepInstance.Status::Completed then begin
                ActionableWorkflowStepInstance.Status := ActionableWorkflowStepInstance.Status::Processing;
                ActionableWorkflowStepInstance.Modify(true);
            end;

            exit;
        end;

        RecRef.GetTable(Variant);

        UpdateStatus(ActionableWorkflowStepInstance, ActionableWorkflowStepInstance.Status::Completed,
          ActionableWorkflowStepInstance.Status::Active, ActionableWorkflowStepInstance.Status::Ignored);

        UpdateStepAndRelatedTableData(ActionableWorkflowStepInstance, RecRef);

        ChangeStatusForResponsesAndEvents(ActionableWorkflowStepInstance);

        Variant1 := Variant;

        while FindResponse(ResponseWorkflowStepInstance, ActionableWorkflowStepInstance) do begin
            UpdateStepAndRelatedTableData(ResponseWorkflowStepInstance, RecRef);

            WorkflowResponseHandling.ExecuteResponse(Variant1, ResponseWorkflowStepInstance, xVariant);

            UpdateStatusForResponse(ResponseWorkflowStepInstance);

            ActionableWorkflowStepInstance := ResponseWorkflowStepInstance;
            Clear(ResponseWorkflowStepInstance);
        end;

        ExecuteQueuedEvents();

        if IsWorkflowCompleted(ActionableWorkflowStepInstance) then
            ArchiveWorkflowInstance(ActionableWorkflowStepInstance);
    end;

    internal procedure GetTelemetryDimensions(FunctionName: Text; SerializedWorkflowStepInstance: Text; var Dimensions: Dictionary of [Text, Text])
    begin
        Clear(Dimensions);

        Dimensions.Add('Category', WorkflowTelemetryCategoryTxt);

        if FunctionName <> '' then
            Dimensions.Add('FunctionName', FunctionName);

        if SerializedWorkflowStepInstance <> '' then
            Dimensions.Add('WorkflowStepInstance', SerializedWorkflowStepInstance);
    end;

    local procedure CanExecuteEvent(WorkflowStepInstance: Record "Workflow Step Instance"): Boolean
    var
        ProcessingWorkflowStepInstance: Record "Workflow Step Instance";
    begin
        ProcessingWorkflowStepInstance.SetRange(ID, WorkflowStepInstance.ID);
        ProcessingWorkflowStepInstance.SetRange(Status, WorkflowStepInstance.Status::Processing);
        ProcessingWorkflowStepInstance.SetFilter("Workflow Step ID", '<>%1', WorkflowStepInstance."Workflow Step ID");
        exit(ProcessingWorkflowStepInstance.IsEmpty);
    end;

    local procedure StoreEventForLaterProcessing(Variant: Variant; xVariant: Variant; WorkflowStepInstance: Record "Workflow Step Instance")
    var
        WorkflowEventQueue: Record "Workflow Event Queue";
        RecRef: RecordRef;
    begin
        RecRef.GetTable(Variant);

        WorkflowEventQueue.Init();
        WorkflowEventQueue."Session ID" := SessionId();
        WorkflowEventQueue."Step Record ID" := WorkflowStepInstance.RecordId;
        WorkflowEventQueue."Record ID" := RecRef.RecordId;
        WorkflowEventQueue."Record Index" := WorkflowRecordManagement.BackupRecord(Variant);
        WorkflowEventQueue."xRecord Index" := WorkflowRecordManagement.BackupRecord(xVariant);
        WorkflowEventQueue.Insert(true);
    end;

    local procedure ExecuteQueuedEvents()
    var
        WorkflowEventQueue: Record "Workflow Event Queue";
        WorkflowStepInstance: Record "Workflow Step Instance";
        WorkflowRule: Record "Workflow Rule";
        RecRef: RecordRef;
        xRecRef: RecordRef;
        Variant: Variant;
        xVariant: Variant;
    begin
        WorkflowEventQueue.SetRange("Session ID", SessionId());
        if WorkflowEventQueue.FindSet() then
            repeat
                WorkflowStepInstance.Get(WorkflowEventQueue."Step Record ID");
                if WorkflowStepInstance.Status = WorkflowStepInstance.Status::Processing then begin
                    WorkflowRecordManagement.RestoreRecord(WorkflowEventQueue."Record Index", Variant);
                    WorkflowRecordManagement.RestoreRecord(WorkflowEventQueue."xRecord Index", xVariant);
                    RecRef.GetTable(Variant);
                    xRecRef.GetTable(xVariant);
                    WorkflowStepInstance.FindWorkflowRules(WorkflowRule);
                    if EvaluateCondition(RecRef, xRecRef, WorkflowStepInstance.Argument, WorkflowRule) then begin
                        ExecuteResponses(RecRef, xRecRef, WorkflowStepInstance);
                        WorkflowEventQueue.Delete();
                    end;
                end;
            until WorkflowEventQueue.Next() = 0;
    end;

    procedure ChangeStatusForResponsesAndEvents(WorkflowStepInstance: Record "Workflow Step Instance")
    var
        MarkWorkflowStepInstance: Record "Workflow Step Instance";
        WorkflowEventQueue: Record "Workflow Event Queue";
    begin
        MarkWorkflowStepInstance.SetRange(ID, WorkflowStepInstance.ID);
        MarkWorkflowStepInstance.SetRange("Workflow Code", WorkflowStepInstance."Workflow Code");
        MarkWorkflowStepInstance.SetRange("Previous Workflow Step ID", WorkflowStepInstance."Workflow Step ID");
        if MarkWorkflowStepInstance.FindSet() then
            repeat
                if MarkWorkflowStepInstance.Type = MarkWorkflowStepInstance.Type::Response then begin
                    MarkWorkflowStepInstance.Status := MarkWorkflowStepInstance.Status::Processing;
                    MarkWorkflowStepInstance.Modify(true);
                    ChangeStatusForResponsesAndEvents(MarkWorkflowStepInstance);
                end else begin
                    // check if queued event
                    WorkflowEventQueue.SetRange("Session ID", SessionId());
                    WorkflowEventQueue.SetRange("Step Record ID", MarkWorkflowStepInstance."Record ID");
                    if WorkflowEventQueue.IsEmpty() then begin
                        MarkWorkflowStepInstance.Status := MarkWorkflowStepInstance.Status::Active;
                        MarkWorkflowStepInstance.Modify(true);
                    end;
                end;
            until MarkWorkflowStepInstance.Next() = 0;
    end;

    local procedure UpdateStepAndRelatedTableData(var WorkflowStepInstance: Record "Workflow Step Instance"; RecRef: RecordRef)
    begin
        WorkflowStepInstance."Record ID" := RecRef.RecordId;
        WorkflowStepInstance.Modify(true);

        UpdateRelatedTableValues(RecRef);

        if not WorkflowStepInstance.TableRelationValuesExist(RecRef) then
            WorkflowStepInstance.SetTableRelationValues(RecRef);
    end;

    local procedure UpdateStatusForResponse(var WorkflowStepInstance: Record "Workflow Step Instance")
    var
        NextWorkflowStepInstance: Record "Workflow Step Instance";
    begin
        if WorkflowStepInstance."Next Workflow Step ID" <> 0 then begin
            NextWorkflowStepInstance.Get(WorkflowStepInstance.ID,
              WorkflowStepInstance."Workflow Code", WorkflowStepInstance."Next Workflow Step ID");

            case NextWorkflowStepInstance.Type of
                NextWorkflowStepInstance.Type::"Event":
                    UpdateStatus(NextWorkflowStepInstance, NextWorkflowStepInstance.Status::Active,
                      NextWorkflowStepInstance.Status::Inactive, NextWorkflowStepInstance.Status::Ignored);
                NextWorkflowStepInstance.Type::Response:
                    UpdateStatus(NextWorkflowStepInstance, NextWorkflowStepInstance.Status::Completed,
                      NextWorkflowStepInstance.Status::Active, NextWorkflowStepInstance.Status::Ignored);
            end;
        end;
        UpdateStatus(WorkflowStepInstance, WorkflowStepInstance.Status::Completed,
          WorkflowStepInstance.Status::Active, WorkflowStepInstance.Status::Ignored);
    end;

    procedure EnabledWorkflowExist(TableNo: Integer; EventFilter: Text): Boolean
    var
        WorkflowDefinition: Query "Workflow Definition";
    begin
        WorkflowDefinition.SetRange(Table_ID, TableNo);
        WorkflowDefinition.SetRange(Entry_Point, true);
        WorkflowDefinition.SetRange(Enabled, true);
        WorkflowDefinition.SetRange(Template, false);
        WorkflowDefinition.SetRange(Type, WorkflowDefinition.Type::"Event");
        WorkflowDefinition.SetFilter(Function_Name, EventFilter);
        WorkflowDefinition.Open();
        exit(WorkflowDefinition.Read());
    end;

    procedure NavigateToWorkflows(TableNo: Integer; EventFilter: Text)
    var
        Workflow: Record Workflow;
        TempWorkflowBuffer: Record "Workflow Buffer" temporary;
        Workflows: Page Workflows;
        WorkflowDefinition: Query "Workflow Definition";
        "Count": Integer;
        WorkflowFilter: Text;
        CategoryFilter: Text;
    begin
        WorkflowDefinition.SetRange(Table_ID, TableNo);
        WorkflowDefinition.SetRange(Entry_Point, true);
        WorkflowDefinition.SetRange(Enabled, true);
        WorkflowDefinition.SetRange(Template, false);
        WorkflowDefinition.SetRange(Type, WorkflowDefinition.Type::"Event");
        WorkflowDefinition.SetFilter(Function_Name, EventFilter);
        WorkflowDefinition.Open();

        while WorkflowDefinition.Read() do begin
            Workflow.Get(WorkflowDefinition.Code);
            BuildFilter(WorkflowFilter, Workflow.Code);
            BuildFilter(CategoryFilter, Workflow.Category);
            Count += 1;
        end;

        if Count = 1 then begin
            Workflow.Get(WorkflowFilter);
            PAGE.RunModal(PAGE::Workflow, Workflow);
        end else begin
            TempWorkflowBuffer.InitBufferForWorkflows(TempWorkflowBuffer);
            TempWorkflowBuffer.SetFilter("Workflow Code", WorkflowFilter);
            TempWorkflowBuffer.SetFilter("Category Code", CategoryFilter);
            Workflows.SetWorkflowBufferRec(TempWorkflowBuffer);
            Workflows.RunModal();
        end;
    end;

    local procedure BuildFilter(var InitialFilter: Text; NewValue: Text)
    begin
        if StrPos(InitialFilter, NewValue) = 0 then begin
            if StrLen(InitialFilter) > 0 then
                InitialFilter += '|';
            InitialFilter += NewValue;
        end;
    end;

    local procedure CreateWorkflowStepArgumentArchive(ToArchiveWorkflowStepArgument: Record "Workflow Step Argument"): Guid
    var
        WorkflowStepArgumentArchive: Record "Workflow Step Argument Archive";
    begin
        WorkflowStepArgumentArchive.Init();
        WorkflowStepArgumentArchive.TransferFields(ToArchiveWorkflowStepArgument);
        WorkflowStepArgumentArchive."Original Record ID" := ToArchiveWorkflowStepArgument.RecordId;
        WorkflowStepArgumentArchive.Insert(true);

        exit(WorkflowStepArgumentArchive.ID);
    end;

    procedure BuildConditionDisplay(WorkflowStep: Record "Workflow Step") Condition: Text[100]
    var
        RuleAsText: Text;
    begin
        Condition := CopyStr(WorkflowStep.GetConditionAsDisplayText(), 1, MaxStrLen(Condition));
        RuleAsText := WorkflowStep.GetRuleAsDisplayText();
        if RuleAsText <> '' then
            if Condition = '' then
                Condition := CopyStr(RuleAsText, 1, MaxStrLen(Condition))
            else
                Condition := CopyStr(StrSubstNo(CombinedConditionTxt, Condition, RuleAsText), 1, MaxStrLen(Condition));

        if Condition = '' then
            Condition := AlwaysTxt;
    end;

    procedure ClearSupportedCombinations(FunctionName: Code[128]; WFEventResponseCombinationType: Option "Event",Response)
    var
        WFEventResponseCombination: Record "WF Event/Response Combination";
    begin
        WFEventResponseCombination.SetRange(Type, WFEventResponseCombinationType);
        WFEventResponseCombination.SetRange("Function Name", FunctionName);
        if not WFEventResponseCombination.IsEmpty() then
            WFEventResponseCombination.DeleteAll(true);

        WFEventResponseCombination.Reset();
        WFEventResponseCombination.SetRange("Predecessor Type", WFEventResponseCombinationType);
        WFEventResponseCombination.SetRange("Predecessor Function Name", FunctionName);
        if not WFEventResponseCombination.IsEmpty() then
            WFEventResponseCombination.DeleteAll(true);
    end;

    procedure GetWebhookClientLink(ClientId: Guid; ClientType: Text): Text
    var
        FlowServiceMgt: Codeunit "Flow Service Management";
    begin
        if not IsNullGuid(ClientId) then
            case ClientType of
                'Flow':
                    exit(FlowServiceMgt.GetFlowDetailsUrl(ClientId));
            end;

        exit('');
    end;

    procedure AnyWorkflowExists(): Boolean
    var
        Workflow: Record Workflow;
        ApprovalEntry: Record "Approval Entry";
    begin
        if Workflow.IsEmpty() then
            exit(false);
        if ApprovalEntry.IsEmpty() then
            exit(false);
        exit(true);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeHandleEventWithxRec(FunctionName: Code[128]; Variant: Variant; xVariant: Variant; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterEvaluateCondition(RecRef: RecordRef; xRecRef: RecordRef; ArgumentID: Guid; var WorkflowRule: Record "Workflow Rule"; var Result: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnFindWorkflowStepInstanceWithOptionalWorkflowStartOnAfterSetWorkflowStepInstanceLoopFi1tersWhenNotStartWorkFlow(RecordRef: RecordRef; var WorkflowStepInstanceLoop: Record "Workflow Step Instance"; FunctionName: Code[128]; StartWorkflow: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnFindWorkflowStepInstanceWithOptionalWorkflowStartOnAfterSetWorkflowStepInstanceLoopFi1ters(RecordRef: RecordRef; var WorkflowStepInstanceLoop: Record "Workflow Step Instance"; FunctionName: Code[128]; StartWorkflow: Boolean)
    begin
    end;
}

