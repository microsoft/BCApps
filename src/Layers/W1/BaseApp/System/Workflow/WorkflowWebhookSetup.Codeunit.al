namespace System.Automation;

using System.Reflection;

codeunit 1540 "Workflow Webhook Setup"
{

    trigger OnRun()
    begin
    end;

    var
        CustomerApprovalDescriptionTxt: Label 'Customer Approval Workflow', Locked = true;
        FinCategoryTxt: Label 'FIN', Locked = true;
        GeneralJournalBatchApprovalDescriptionTxt: Label 'General Journal Batch Approval Workflow', Locked = true;
        GeneralJournaLineApprovalDescriptionTxt: Label 'General Journal Line Approval Workflow', Locked = true;
        ItemApprovalDescriptionTxt: Label 'Item Approval Workflow', Locked = true;
        PurchaseDocCategoryTxt: Label 'PURCHDOC', Locked = true;
        PurchaseDocApprovalDescriptionTxt: Label 'Purchase Document Approval Workflow', Locked = true;
        PurchPayCategoryTxt: Label 'PURCH', Locked = true;
        SalesDocCategoryTxt: Label 'SALESDOC', Locked = true;
        SalesDocApprovalDescriptionTxt: Label 'Sales Document Approval Workflow', Locked = true;
        SalesMktCategoryTxt: Label 'SALES', Locked = true;
        UnsupportedWorkflowEventCodeErr: Label 'Unsupported workflow event code ''%1''.', Comment = '%1=Workflow event code';
        VendorApprovalDescriptionTxt: Label 'Vendor Approval Workflow', Locked = true;
        RequisitionWkshBatchApprovalDescriptionTxt: Label 'Requisition Worksheet Batch Approval Workflow', Locked = true;

    [Scope('OnPrem')]
    procedure CreateWorkflowDefinition(EventCode: Code[128]; Name: Text[100]; EventConditions: Text; ResponseUserID: Code[50]): Code[20]
    var
        WorkflowEventHandling: Codeunit "Workflow Event Handling";
    begin
        case EventCode of
            WorkflowEventHandling.RunWorkflowOnSendCustomerForApprovalCode():
                exit(CreateCustomerApprovalWorkflow(Name, EventConditions, ResponseUserID));
            WorkflowEventHandling.RunWorkflowOnSendItemForApprovalCode():
                exit(CreateItemApprovalWorkflow(Name, EventConditions, ResponseUserID));
            WorkflowEventHandling.RunWorkflowOnSendGeneralJournalBatchForApprovalCode():
                exit(CreateGeneralJournalBatchApprovalWorkflow(Name, EventConditions, ResponseUserID));
            WorkflowEventHandling.RunWorkflowOnSendGeneralJournalLineForApprovalCode():
                exit(CreateGeneralJournalLineApprovalWorkflow(Name, EventConditions, ResponseUserID));
            WorkflowEventHandling.RunWorkflowOnSendRequisitionWkshBatchForApprovalCode():
                exit(CreateRequisitionWkshBatchApprovalWorkflow(Name, EventConditions, ResponseUserID));
            WorkflowEventHandling.RunWorkflowOnSendPurchaseDocForApprovalCode():
                exit(CreatePurchaseDocumentApprovalWorkflow(Name, EventConditions, ResponseUserID));
            WorkflowEventHandling.RunWorkflowOnSendSalesDocForApprovalCode():
                exit(CreateSalesDocumentApprovalWorkflow(Name, EventConditions, ResponseUserID));
            WorkflowEventHandling.RunWorkflowOnSendVendorForApprovalCode():
                exit(CreateVendorApprovalWorkflow(Name, EventConditions, ResponseUserID));
            else
                Error(UnsupportedWorkflowEventCodeErr, EventCode);
        end;
    end;

    local procedure CreateApprovalWorkflow(WorkflowCode: Code[20]; Name: Text[100]; Category: Code[20]; EventCode: Code[128]; EventConditions: Text; ResponseUserID: Code[50])
    var
        DummyWorkflowWebhookEntry: Record "Workflow Webhook Entry";
        WorkflowResponseHandling: Codeunit "Workflow Response Handling";
        WorkflowWebhookEvents: Codeunit "Workflow Webhook Events";
        WorkflowWebhookResponses: Codeunit "Workflow Webhook Responses";
        EmptyUserID: Code[50];
        NotificationEventConditions: Text;
        ParentStepID: Integer;
        StepID: Integer;
    begin
        EmptyUserID := '';
        Clear(NotificationEventConditions);

        InitializeWorkflow(WorkflowCode, Name, Category);

        StepID := CreateEventStep(WorkflowCode, true, 0, EventCode, 1, EventConditions);
        StepID := CreateResponseStep(WorkflowCode, StepID, WorkflowResponseHandling.RestrictRecordUsageCode(), 0, EmptyUserID);
        StepID := CreateResponseStep(WorkflowCode, StepID, WorkflowResponseHandling.SetStatusToPendingApprovalCode(), 0, EmptyUserID);
        StepID := CreateResponseStep(WorkflowCode, StepID, WorkflowWebhookResponses.SendNotificationToWebhookCode(), 0, ResponseUserID);
        ParentStepID := StepID;

        NotificationEventConditions := CreateEventCondition(DummyWorkflowWebhookEntry.Response::Continue);
        StepID := CreateEventStep(WorkflowCode, false, ParentStepID, WorkflowWebhookEvents.WorkflowWebhookResponseReceivedEventCode(), 2,
            NotificationEventConditions);
        StepID := CreateResponseStep(WorkflowCode, StepID, WorkflowResponseHandling.AllowRecordUsageCode(), 0, EmptyUserID);
        StepID := CreateResponseStep(WorkflowCode, StepID, WorkflowResponseHandling.ReleaseDocumentCode(), 0, EmptyUserID);

        NotificationEventConditions := CreateEventCondition(DummyWorkflowWebhookEntry.Response::Reject);
        StepID := CreateEventStep(WorkflowCode, false, ParentStepID, WorkflowWebhookEvents.WorkflowWebhookResponseReceivedEventCode(), 3,
            NotificationEventConditions);
        StepID := CreateResponseStep(WorkflowCode, StepID, WorkflowResponseHandling.OpenDocumentCode(), 0, EmptyUserID);

        NotificationEventConditions := CreateEventCondition(DummyWorkflowWebhookEntry.Response::Cancel);
        StepID := CreateEventStep(WorkflowCode, false, ParentStepID, WorkflowWebhookEvents.WorkflowWebhookResponseReceivedEventCode(), 4,
            NotificationEventConditions);
        StepID := CreateResponseStep(WorkflowCode, StepID, WorkflowResponseHandling.AllowRecordUsageCode(), 0, EmptyUserID);
        StepID := CreateResponseStep(WorkflowCode, StepID, WorkflowResponseHandling.OpenDocumentCode(), 0, EmptyUserID);
    end;

    local procedure CreateCustomerItemApprovalWorkflow(WorkflowCode: Code[20]; Name: Text[100]; Category: Code[20]; EventCode: Code[128]; EventConditions: Text; ResponseUserID: Code[50])
    var
        DummyWorkflowWebhookEntry: Record "Workflow Webhook Entry";
        WorkflowResponseHandling: Codeunit "Workflow Response Handling";
        WorkflowWebhookEvents: Codeunit "Workflow Webhook Events";
        WorkflowWebhookResponses: Codeunit "Workflow Webhook Responses";
        EmptyUserID: Code[50];
        NotificationEventConditions: Text;
        ParentStepID: Integer;
        StepID: Integer;
    begin
        EmptyUserID := '';
        Clear(NotificationEventConditions);

        InitializeWorkflow(WorkflowCode, Name, Category);

        StepID := CreateEventStep(WorkflowCode, true, 0, EventCode, 1, EventConditions);
        StepID := CreateResponseStep(WorkflowCode, StepID, WorkflowResponseHandling.RestrictRecordUsageCode(), 0, EmptyUserID);
        StepID := CreateResponseStep(WorkflowCode, StepID, WorkflowWebhookResponses.SendNotificationToWebhookCode(), 0, ResponseUserID);
        ParentStepID := StepID;

        NotificationEventConditions := CreateEventCondition(DummyWorkflowWebhookEntry.Response::Continue);
        StepID := CreateEventStep(WorkflowCode, false, ParentStepID, WorkflowWebhookEvents.WorkflowWebhookResponseReceivedEventCode(), 2,
            NotificationEventConditions);
        StepID := CreateResponseStep(WorkflowCode, StepID, WorkflowResponseHandling.AllowRecordUsageCode(), 0, EmptyUserID);

        NotificationEventConditions := CreateEventCondition(DummyWorkflowWebhookEntry.Response::Reject);
        StepID := CreateEventStep(WorkflowCode, false, ParentStepID, WorkflowWebhookEvents.WorkflowWebhookResponseReceivedEventCode(), 3,
            NotificationEventConditions);

        NotificationEventConditions := CreateEventCondition(DummyWorkflowWebhookEntry.Response::Cancel);
        StepID := CreateEventStep(WorkflowCode, false, ParentStepID, WorkflowWebhookEvents.WorkflowWebhookResponseReceivedEventCode(), 4,
            NotificationEventConditions);
        StepID := CreateResponseStep(WorkflowCode, StepID, WorkflowResponseHandling.AllowRecordUsageCode(), 0, EmptyUserID);
    end;

    local procedure CreateGeneralJournalBatchApprovalWorkflowSteps(WorkflowCode: Code[20]; Name: Text[100]; Category: Code[20]; EventCode: Code[128]; EventConditions: Text; ResponseUserID: Code[50])
    var
        WorkflowStep: Record "Workflow Step";
        WorkflowStepArgument: Record "Workflow Step Argument";
        WorkflowResponseHandling: Codeunit "Workflow Response Handling";
        WorkflowWebhookResponses: Codeunit "Workflow Webhook Responses";
        WorkflowEventHandling: Codeunit "Workflow Event Handling";
        WorkflowSetup: Codeunit "Workflow Setup";
        EmptyUserID: Code[50];
        ParentStepID: Integer;
        StepID: Integer;
        BalancedCodeParentStepID: Integer;
    begin
        EmptyUserID := '';

        InitializeWorkflow(WorkflowCode, Name, Category);

        StepID := CreateEventStep(WorkflowCode, true, 0, EventCode, 1, EventConditions);
        StepID := CreateResponseStep(WorkflowCode, StepID, WorkflowResponseHandling.CheckGeneralJournalBatchBalanceCode(), 0, EmptyUserID);
        BalancedCodeParentStepID := StepID;
        StepID := CreateEventStep(WorkflowCode, false, StepID, WorkflowEventHandling.RunWorkflowOnGeneralJournalBatchBalancedCode(), 0, '');
        StepID := CreateResponseStep(WorkflowCode, StepID, WorkflowResponseHandling.RestrictRecordUsageCode(), 0, EmptyUserID);
        StepID := CreateResponseStep(WorkflowCode, StepID, WorkflowWebhookResponses.SendNotificationToWebhookCode(), 0, ResponseUserID);
        ParentStepID := StepID;

        CreateGeneralJournalWorkflowNotificationSteps(WorkflowCode, ParentStepID);

        StepID :=
          CreateEventStep(
            WorkflowCode, false, BalancedCodeParentStepID, WorkflowEventHandling.RunWorkflowOnGeneralJournalBatchNotBalancedCode(), 0,
            '');
        StepID := CreateResponseStep(WorkflowCode, StepID, WorkflowResponseHandling.ShowMessageCode(), 0, EmptyUserID);

        WorkflowStep.SetRange(ID, StepID);
        WorkflowStep.FindFirst();
        WorkflowStepArgument.Get(WorkflowStep.Argument);
        WorkflowStepArgument.Message := WorkflowSetup.GetGeneralJournalBatchIsNotBalancedMsg();
        WorkflowStepArgument.Modify(true);
    end;

    local procedure CreateGeneralJournalLineApprovalWorkflowSteps(WorkflowCode: Code[20]; Name: Text[100]; Category: Code[20]; EventCode: Code[128]; EventConditions: Text; ResponseUserID: Code[50])
    var
        WorkflowResponseHandling: Codeunit "Workflow Response Handling";
        WorkflowWebhookResponses: Codeunit "Workflow Webhook Responses";
        EmptyUserID: Code[50];
        ParentStepID: Integer;
        StepID: Integer;
    begin
        EmptyUserID := '';

        InitializeWorkflow(WorkflowCode, Name, Category);

        StepID := CreateEventStep(WorkflowCode, true, 0, EventCode, 1, EventConditions);
        StepID := CreateResponseStep(WorkflowCode, StepID, WorkflowResponseHandling.RestrictRecordUsageCode(), 0, EmptyUserID);
        StepID := CreateResponseStep(WorkflowCode, StepID, WorkflowWebhookResponses.SendNotificationToWebhookCode(), 0, ResponseUserID);
        ParentStepID := StepID;

        CreateGeneralJournalWorkflowNotificationSteps(WorkflowCode, ParentStepID);
    end;

    local procedure CreateRequisitionWkshBatchApprovalWorkflowSteps(WorkflowCode: Code[20]; Name: Text[100]; Category: Code[20]; EventCode: Code[128]; EventConditions: Text; ResponseUserID: Code[50])
    var
        WorkflowResponseHandling: Codeunit "Workflow Response Handling";
        WorkflowWebhookResponses: Codeunit "Workflow Webhook Responses";
        EmptyUserID: Code[50];
        ParentStepID: Integer;
        StepID: Integer;
    begin
        EmptyUserID := '';

        InitializeWorkflow(WorkflowCode, Name, Category);

        StepID := CreateEventStep(WorkflowCode, true, 0, EventCode, 1, EventConditions);
        StepID := CreateResponseStep(WorkflowCode, StepID, WorkflowResponseHandling.RestrictRecordUsageCode(), 0, EmptyUserID);
        StepID := CreateResponseStep(WorkflowCode, StepID, WorkflowWebhookResponses.SendNotificationToWebhookCode(), 0, ResponseUserID);
        ParentStepID := StepID;

        CreateRequisitionWkshWorkflowNotificationSteps(WorkflowCode, ParentStepID);
    end;

    local procedure CreateArgumentForEvent(EventConditions: Text): Guid
    var
        WorkflowStepArgument: Record "Workflow Step Argument";
        OutStream: OutStream;
    begin
        WorkflowStepArgument.Init();
        WorkflowStepArgument.ID := CreateGuid();
        WorkflowStepArgument.Type := WorkflowStepArgument.Type::"Event";

        if EventConditions <> '' then begin
            WorkflowStepArgument."Event Conditions".CreateOutStream(OutStream, TextEncoding::UTF8);
            OutStream.WriteText(EventConditions);
        end;

        WorkflowStepArgument.Insert();
        exit(WorkflowStepArgument.ID);
    end;

    local procedure CreateArgumentForResponse(FunctionName: Code[128]; ResponseUserID: Code[50]): Guid
    var
        WorkflowStepArgument: Record "Workflow Step Argument";
    begin
        WorkflowStepArgument.Init();
        WorkflowStepArgument.ID := CreateGuid();
        WorkflowStepArgument.Type := WorkflowStepArgument.Type::Response;
        WorkflowStepArgument."Response Function Name" := FunctionName;

        if ResponseUserID <> '' then begin
            WorkflowStepArgument."Response Type" := WorkflowStepArgument."Response Type"::"User ID";
            WorkflowStepArgument."Response User ID" := ResponseUserID;
        end;

        WorkflowStepArgument.Insert();
        exit(WorkflowStepArgument.ID);
    end;

    local procedure CreateEventCondition(ResponseArgument: Option): Text
    var
        WorkflowWebhookEntry: Record "Workflow Webhook Entry";
        RequestPageParametersHelper: Codeunit "Request Page Parameters Helper";
        EventConditions: FilterPageBuilder;
    begin
        Clear(WorkflowWebhookEntry);
        WorkflowWebhookEntry.SetFilter(Response, '=%1', ResponseArgument);

        Clear(EventConditions);
        EventConditions.SetView(EventConditions.AddTable(GetTableCaption(DATABASE::"Workflow Webhook Entry"),
            DATABASE::"Workflow Webhook Entry"), WorkflowWebhookEntry.GetView());

        exit(RequestPageParametersHelper.GetViewFromDynamicRequestPage(EventConditions, '', DATABASE::"Workflow Webhook Entry"));
    end;

    local procedure CreateEventStep(WorkflowCode: Code[20]; IsEntryPoint: Boolean; PreviousStepID: Integer; FunctionName: Code[128]; SequenceNumber: Integer; EventConditions: Text): Integer
    var
        WorkflowStep: Record "Workflow Step";
    begin
        WorkflowStep.Init();
        WorkflowStep."Workflow Code" := WorkflowCode;
        WorkflowStep."Entry Point" := IsEntryPoint;
        WorkflowStep."Previous Workflow Step ID" := PreviousStepID;
        WorkflowStep.Type := WorkflowStep.Type::"Event";
        WorkflowStep."Function Name" := FunctionName;
        WorkflowStep.Argument := CreateArgumentForEvent(EventConditions);
        WorkflowStep."Sequence No." := SequenceNumber;
        WorkflowStep.Insert();

        exit(WorkflowStep.ID);
    end;

    local procedure CreateResponseStep(WorkflowCode: Code[20]; PreviousStepID: Integer; FunctionName: Code[128]; SequenceNumber: Integer; ResponseUserID: Code[50]): Integer
    var
        WorkflowStep: Record "Workflow Step";
    begin
        WorkflowStep.Init();
        WorkflowStep."Workflow Code" := WorkflowCode;
        WorkflowStep."Entry Point" := false;
        WorkflowStep."Previous Workflow Step ID" := PreviousStepID;
        WorkflowStep.Type := WorkflowStep.Type::Response;
        WorkflowStep."Function Name" := FunctionName;
        WorkflowStep.Argument := CreateArgumentForResponse(FunctionName, ResponseUserID);
        WorkflowStep."Sequence No." := SequenceNumber;

        WorkflowStep.Insert();
        exit(WorkflowStep.ID);
    end;

    local procedure CreateCustomerApprovalWorkflow(Name: Text[100]; EventConditions: Text; ResponseUserID: Code[50]) WorkflowCode: Code[20]
    var
        Workflow: Record Workflow;
        WorkflowEventHandling: Codeunit "Workflow Event Handling";
    begin
        WorkflowCode := 'MS-CUSTAW-WH-01';
        while Workflow.Get(WorkflowCode) do
            WorkflowCode := IncStr(WorkflowCode);

        if Name = '' then
            Name := CustomerApprovalDescriptionTxt;

        CreateCustomerItemApprovalWorkflow(WorkflowCode, Name, SalesMktCategoryTxt,
          WorkflowEventHandling.RunWorkflowOnSendCustomerForApprovalCode(), EventConditions, ResponseUserID);

        exit(WorkflowCode);
    end;

    local procedure CreateGeneralJournalWorkflowNotificationSteps(WorkflowCode: Code[20]; ParentStepId: Integer)
    var
        DummyWorkflowWebhookEntry: Record "Workflow Webhook Entry";
        WorkflowResponseHandling: Codeunit "Workflow Response Handling";
        WorkflowWebhookEvents: Codeunit "Workflow Webhook Events";
        EmptyUserID: Code[50];
        NotificationEventConditions: Text;
        StepID: Integer;
    begin
        EmptyUserID := '';

        NotificationEventConditions := CreateEventCondition(DummyWorkflowWebhookEntry.Response::Continue);
        StepID := CreateEventStep(WorkflowCode, false, ParentStepId, WorkflowWebhookEvents.WorkflowWebhookResponseReceivedEventCode(), 2,
            NotificationEventConditions);
        StepID := CreateResponseStep(WorkflowCode, StepID, WorkflowResponseHandling.AllowRecordUsageCode(), 0, EmptyUserID);

        NotificationEventConditions := CreateEventCondition(DummyWorkflowWebhookEntry.Response::Reject);
        StepID := CreateEventStep(WorkflowCode, false, ParentStepId, WorkflowWebhookEvents.WorkflowWebhookResponseReceivedEventCode(), 3,
            NotificationEventConditions);

        NotificationEventConditions := CreateEventCondition(DummyWorkflowWebhookEntry.Response::Cancel);
        StepID := CreateEventStep(WorkflowCode, false, ParentStepId, WorkflowWebhookEvents.WorkflowWebhookResponseReceivedEventCode(), 4,
            NotificationEventConditions);
    end;

    local procedure CreateGeneralJournalBatchApprovalWorkflow(Name: Text[100]; EventConditions: Text; ResponseUserID: Code[50]) WorkflowCode: Code[20]
    var
        Workflow: Record Workflow;
        WorkflowEventHandling: Codeunit "Workflow Event Handling";
    begin
        WorkflowCode := 'MS-GJBAW-WH-01';
        while Workflow.Get(WorkflowCode) do
            WorkflowCode := IncStr(WorkflowCode);

        if Name = '' then
            Name := GeneralJournalBatchApprovalDescriptionTxt;

        CreateGeneralJournalBatchApprovalWorkflowSteps(WorkflowCode, Name, FinCategoryTxt,
          WorkflowEventHandling.RunWorkflowOnSendGeneralJournalBatchForApprovalCode(), EventConditions, ResponseUserID);

        exit(WorkflowCode);
    end;

    local procedure CreateGeneralJournalLineApprovalWorkflow(Name: Text[100]; EventConditions: Text; ResponseUserID: Code[50]) WorkflowCode: Code[20]
    var
        Workflow: Record Workflow;
        WorkflowEventHandling: Codeunit "Workflow Event Handling";
    begin
        WorkflowCode := 'MS-GJLAW-WH-01';
        while Workflow.Get(WorkflowCode) do
            WorkflowCode := IncStr(WorkflowCode);

        if Name = '' then
            Name := GeneralJournaLineApprovalDescriptionTxt;

        CreateGeneralJournalLineApprovalWorkflowSteps(WorkflowCode, Name, FinCategoryTxt,
          WorkflowEventHandling.RunWorkflowOnSendGeneralJournalLineForApprovalCode(), EventConditions, ResponseUserID);

        exit(WorkflowCode);
    end;

    local procedure CreateRequisitionWkshWorkflowNotificationSteps(WorkflowCode: Code[20]; ParentStepId: Integer)
    var
        DummyWorkflowWebhookEntry: Record "Workflow Webhook Entry";
        WorkflowResponseHandling: Codeunit "Workflow Response Handling";
        WorkflowWebhookEvents: Codeunit "Workflow Webhook Events";
        EmptyUserID: Code[50];
        NotificationEventConditions: Text;
        StepID: Integer;
    begin
        EmptyUserID := '';

        NotificationEventConditions := CreateEventCondition(DummyWorkflowWebhookEntry.Response::Continue);
        StepID := CreateEventStep(WorkflowCode, false, ParentStepId, WorkflowWebhookEvents.WorkflowWebhookResponseReceivedEventCode(), 2, NotificationEventConditions);
        StepID := CreateResponseStep(WorkflowCode, StepID, WorkflowResponseHandling.AllowRecordUsageCode(), 0, EmptyUserID);

        NotificationEventConditions := CreateEventCondition(DummyWorkflowWebhookEntry.Response::Reject);
        StepID := CreateEventStep(WorkflowCode, false, ParentStepId, WorkflowWebhookEvents.WorkflowWebhookResponseReceivedEventCode(), 3, NotificationEventConditions);

        NotificationEventConditions := CreateEventCondition(DummyWorkflowWebhookEntry.Response::Cancel);
        StepID := CreateEventStep(WorkflowCode, false, ParentStepId, WorkflowWebhookEvents.WorkflowWebhookResponseReceivedEventCode(), 4, NotificationEventConditions);
    end;

    local procedure CreateRequisitionWkshBatchApprovalWorkflow(Name: Text[100]; EventConditions: Text; ResponseUserID: Code[50]) WorkflowCode: Code[20]
    var
        Workflow: Record Workflow;
        WorkflowEventHandling: Codeunit "Workflow Event Handling";
    begin
        WorkflowCode := 'MS-RWBAW-WH-01';
        while Workflow.Get(WorkflowCode) do
            WorkflowCode := IncStr(WorkflowCode);

        if Name = '' then
            Name := RequisitionWkshBatchApprovalDescriptionTxt;

        CreateRequisitionWkshBatchApprovalWorkflowSteps(WorkflowCode, Name, PurchPayCategoryTxt, WorkflowEventHandling.RunWorkflowOnSendRequisitionWkshBatchForApprovalCode(), EventConditions, ResponseUserID);

        exit(WorkflowCode);
    end;

    local procedure CreateItemApprovalWorkflow(Name: Text[100]; EventConditions: Text; ResponseUserID: Code[50]) WorkflowCode: Code[20]
    var
        Workflow: Record Workflow;
        WorkflowEventHandling: Codeunit "Workflow Event Handling";
    begin
        WorkflowCode := 'MS-ITEMAW-WH-01';
        while Workflow.Get(WorkflowCode) do
            WorkflowCode := IncStr(WorkflowCode);

        if Name = '' then
            Name := ItemApprovalDescriptionTxt;

        CreateCustomerItemApprovalWorkflow(WorkflowCode, Name, SalesMktCategoryTxt,
          WorkflowEventHandling.RunWorkflowOnSendItemForApprovalCode(), EventConditions, ResponseUserID);

        exit(WorkflowCode);
    end;

    local procedure CreatePurchaseDocumentApprovalWorkflow(Name: Text[100]; EventConditions: Text; ResponseUserID: Code[50]) WorkflowCode: Code[20]
    var
        Workflow: Record Workflow;
        WorkflowEventHandling: Codeunit "Workflow Event Handling";
    begin
        WorkflowCode := 'MS-PDAW-WH-01';
        while Workflow.Get(WorkflowCode) do
            WorkflowCode := IncStr(WorkflowCode);

        if Name = '' then
            Name := PurchaseDocApprovalDescriptionTxt;

        CreateApprovalWorkflow(WorkflowCode, Name, PurchaseDocCategoryTxt,
          WorkflowEventHandling.RunWorkflowOnSendPurchaseDocForApprovalCode(), EventConditions, ResponseUserID);

        exit(WorkflowCode);
    end;

    local procedure CreateSalesDocumentApprovalWorkflow(Name: Text[100]; EventConditions: Text; ResponseUserID: Code[50]) WorkflowCode: Code[20]
    var
        Workflow: Record Workflow;
        WorkflowEventHandling: Codeunit "Workflow Event Handling";
    begin
        WorkflowCode := 'MS-SDAW-WH-01';
        while Workflow.Get(WorkflowCode) do
            WorkflowCode := IncStr(WorkflowCode);

        if Name = '' then
            Name := SalesDocApprovalDescriptionTxt;

        CreateApprovalWorkflow(WorkflowCode, Name, SalesDocCategoryTxt,
          WorkflowEventHandling.RunWorkflowOnSendSalesDocForApprovalCode(), EventConditions, ResponseUserID);

        exit(WorkflowCode);
    end;

    local procedure CreateVendorApprovalWorkflow(Name: Text[100]; EventConditions: Text; ResponseUserID: Code[50]) WorkflowCode: Code[20]
    var
        Workflow: Record Workflow;
        WorkflowEventHandling: Codeunit "Workflow Event Handling";
    begin
        WorkflowCode := 'MS-VENDAW-WH-01';
        while Workflow.Get(WorkflowCode) do
            WorkflowCode := IncStr(WorkflowCode);

        if Name = '' then
            Name := VendorApprovalDescriptionTxt;

        CreateCustomerItemApprovalWorkflow(WorkflowCode, Name, PurchPayCategoryTxt,
          WorkflowEventHandling.RunWorkflowOnSendVendorForApprovalCode(), EventConditions, ResponseUserID);

        exit(WorkflowCode);
    end;

    local procedure GetTableCaption(TableID: Integer): Text
    var
        TableMetadata: Record "Table Metadata";
    begin
        TableMetadata.Get(TableID);
        exit(TableMetadata.Caption);
    end;

    local procedure InitializeWorkflow(WorkflowCode: Text[20]; Name: Text[100]; Category: Code[20])
    var
        Workflow: Record Workflow;
        WorkflowEvent: Record "Workflow Event";
        WorkflowSetup: Codeunit "Workflow Setup";
        WorkflowWebhookEvents: Codeunit "Workflow Webhook Events";
    begin
        if not WorkflowEvent.Get(WorkflowWebhookEvents.WorkflowWebhookResponseReceivedEventCode()) then
            WorkflowSetup.InitWorkflow();

        Workflow.Init();
        Workflow.Code := WorkflowCode;
        Workflow.Description := Name;
        Workflow.Enabled := false;
        Workflow.Template := false;
        Workflow.Category := Category;
        Workflow.Insert();
    end;

    procedure GetSalesDocCategoryTxt(): Code[20]
    begin
        exit(SalesDocCategoryTxt);
    end;

    procedure GetPurchaseDocCategoryTxt(): Code[20]
    begin
        exit(PurchaseDocCategoryTxt);
    end;

    procedure GetPurchPayCategoryTxt(): Code[20]
    begin
        exit(PurchaseDocCategoryTxt);
    end;

    procedure GetFinCategoryTxt(): Code[20]
    begin
        exit(FinCategoryTxt);
    end;

    procedure GetSalesMktCategoryTxt(): Code[20]
    begin
        exit(SalesMktCategoryTxt);
    end;

    procedure GetUnsupportedWorkflowEventCodeErr(): Text
    begin
        exit(UnsupportedWorkflowEventCodeErr);
    end;
}

