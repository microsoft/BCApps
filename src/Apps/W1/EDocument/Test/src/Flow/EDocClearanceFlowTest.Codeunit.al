// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.eServices.EDocument.Test;

using Microsoft.eServices.EDocument;
using Microsoft.eServices.EDocument.Integration;
using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Foundation.Reporting;
using Microsoft.Inventory.Item;
using Microsoft.Sales.Customer;
using Microsoft.Sales.Document;
using Microsoft.Sales.Setup;
using System.Automation;
using System.IO;
using System.Threading;

codeunit 139891 "E-Doc. Clearance Flow Test"
{
    Subtype = Test;
    TestType = IntegrationTest;
    EventSubscriberInstance = Manual;

    var
        Customer: Record Customer;
        ClearanceService: Record "E-Document Service";
        Assert: Codeunit Assert;
        LibraryEDoc: Codeunit "Library - E-Document";
        LibraryWorkflow: Codeunit "Library - Workflow";
        LibraryJobQueue: Codeunit "Library - Job Queue";
        EDocImplState: Codeunit "E-Doc. Impl. State";
        LibraryLowerPermission: Codeunit "Library - Lower Permissions";
        IsInitialized: Boolean;
        RestoreSyncServiceWorkflow: Boolean;
        SyncServiceOriginalWorkflow: Code[20];
        SyncServiceWorkflow: Code[20];
        IncorrectValueErr: Label 'Incorrect value found';

    [Test]
    procedure ExportThenSendClearanceFlowNoDoubleExportLogs()
    var
        EDocument: Record "E-Document";
        EDocumentLog: Record "E-Document Log";
        EDocumentServiceStatus: Record "E-Document Service Status";
        Logs: List of [Enum "E-Document Service Status"];
    begin
        // [FEATURE] [E-Document] [Clearance] [Flow]
        // [SCENARIO] When clearance workflow is configured as Export then Send,
        // the Export step should not create duplicate Exported logs because
        // CreateEDocument pre-exports the document before the workflow fires.

        // [GIVEN] A clearance workflow: EDocCreated -> Export(ClearanceService), EDocExported -> Send(ClearanceService)
        Initialize();
        BindSubscription(EDocImplState);
        EDocImplState.SetIsAsync();
        EDocImplState.SetOnGetResponseSuccess();

        // [WHEN] Team member posts sales invoice
        LibraryLowerPermission.SetTeamMember();
        LibraryEDoc.PostInvoice(Customer);
        EDocument.FindLast();

        // [WHEN] E-Document Created Flow job queue runs (triggers workflow)
        LibraryJobQueue.FindAndRunJobQueueEntryByRecordId(EDocument.RecordId);

        // [THEN] There should be only ONE Exported log entry for the clearance service (not two)
        EDocumentLog.SetRange("E-Doc. Entry No", EDocument."Entry No");
        EDocumentLog.SetRange("Service Code", ClearanceService.Code);
        EDocumentLog.SetRange(Status, Enum::"E-Document Service Status"::Exported);
        Assert.AreEqual(1, EDocumentLog.Count(), 'Expected exactly 1 Exported log for clearance service, but found duplicates');

        // [THEN] The clearance service should be in Pending Response (async send completed)
        EDocumentServiceStatus.Get(EDocument."Entry No", ClearanceService.Code);
        Assert.AreEqual(
            Enum::"E-Document Service Status"::"Pending Response",
            EDocumentServiceStatus.Status,
            IncorrectValueErr);

        // [THEN] Log sequence for clearance service should be: Exported, Pending Response
        Logs.Add(Enum::"E-Document Service Status"::Exported);
        Logs.Add(Enum::"E-Document Service Status"::"Pending Response");
        LibraryEDoc.AssertEDocumentLogs(EDocument, ClearanceService, Logs);

        UnbindSubscription(EDocImplState);
    end;

    [Test]
    procedure ClearanceFlowAsyncFullCycleSuccess()
    var
        EDocument: Record "E-Document";
        EDocumentServiceStatus: Record "E-Document Service Status";
        JobQueueEntry: Record "Job Queue Entry";
        Logs: List of [Enum "E-Document Service Status"];
    begin
        // [FEATURE] [E-Document] [Clearance] [Flow]
        // [SCENARIO] Full async clearance workflow cycle: Post, Export, Send, Pending Response, Sent
        // Verifies the entire clearance flow completes without duplicate logs

        // [GIVEN] A clearance workflow with async send
        Initialize();
        BindSubscription(EDocImplState);
        EDocImplState.SetIsAsync();
        EDocImplState.SetOnGetResponseSuccess();

        // [WHEN] Team member posts sales invoice
        LibraryLowerPermission.SetTeamMember();
        LibraryEDoc.PostInvoice(Customer);
        EDocument.FindLast();

        // [WHEN] E-Document Created Flow job queue runs
        LibraryJobQueue.FindAndRunJobQueueEntryByRecordId(EDocument.RecordId);

        // [THEN] Status should be Pending Response after send
        EDocumentServiceStatus.Get(EDocument."Entry No", ClearanceService.Code);
        Assert.AreEqual(
            Enum::"E-Document Service Status"::"Pending Response",
            EDocumentServiceStatus.Status,
            IncorrectValueErr);

        // [WHEN] Get Response background job runs successfully
        JobQueueEntry.FindJobQueueEntry(JobQueueEntry."Object Type to Run"::Codeunit, Codeunit::"E-Document Get Response");
        LibraryJobQueue.RunJobQueueDispatcher(JobQueueEntry);

        // [THEN] Clearance service status should be Sent
        EDocumentServiceStatus.Get(EDocument."Entry No", ClearanceService.Code);
        Assert.AreEqual(
            Enum::"E-Document Service Status"::Sent,
            EDocumentServiceStatus.Status,
            IncorrectValueErr);

        // [THEN] Document should be processed
        EDocument.Get(EDocument."Entry No");
        Assert.AreEqual(Enum::"E-Document Status"::Processed, EDocument.Status, IncorrectValueErr);

        // [THEN] Log sequence for clearance service: Exported, Pending Response, Sent
        Logs.Add(Enum::"E-Document Service Status"::Exported);
        Logs.Add(Enum::"E-Document Service Status"::"Pending Response");
        Logs.Add(Enum::"E-Document Service Status"::Sent);
        LibraryEDoc.AssertEDocumentLogs(EDocument, ClearanceService, Logs);

        UnbindSubscription(EDocImplState);
    end;

    [Test]
    procedure ClearanceFlowSyncSendSuccess()
    var
        SyncService: Record "E-Document Service";
        EDocument: Record "E-Document";
        EDocumentServiceStatus: Record "E-Document Service Status";
        Logs: List of [Enum "E-Document Service Status"];
    begin
        // [FEATURE] [E-Document] [Clearance] [Flow]
        // [SCENARIO] Clearance workflow with synchronous send completes in one step
        // Note: V2 determines sync/async by interface implementation, not a flag.
        // "Mock Sync" integration does NOT implement IDocumentResponseHandler, so it is truly synchronous.

        // [GIVEN] A clearance workflow with sync send using "Mock Sync" integration
        InitializeSyncService(SyncService);
        BindSubscription(EDocImplState);

        // [WHEN] Team member posts sales invoice
        LibraryLowerPermission.SetTeamMember();
        LibraryEDoc.PostInvoice(Customer);
        EDocument.FindLast();

        // [WHEN] E-Document Created Flow job queue runs
        LibraryJobQueue.FindAndRunJobQueueEntryByRecordId(EDocument.RecordId);

        // [THEN] Sync service status should be Sent (sync completes immediately)
        EDocumentServiceStatus.Get(EDocument."Entry No", SyncService.Code);
        Assert.AreEqual(
            Enum::"E-Document Service Status"::Sent,
            EDocumentServiceStatus.Status,
            IncorrectValueErr);

        // [THEN] Document should be processed
        EDocument.Get(EDocument."Entry No");
        Assert.AreEqual(Enum::"E-Document Status"::Processed, EDocument.Status, IncorrectValueErr);

        // [THEN] Log sequence: Exported, Sent
        Logs.Add(Enum::"E-Document Service Status"::Exported);
        Logs.Add(Enum::"E-Document Service Status"::Sent);
        LibraryEDoc.AssertEDocumentLogs(EDocument, SyncService, Logs);

        UnbindSubscription(EDocImplState);
        RestoreWorkflowIfNeeded();
    end;

    [Test]
    procedure ClearanceFlowSendErrorNoDoubleExport()
    var
        EDocument: Record "E-Document";
        EDocumentLog: Record "E-Document Log";
        EDocumentServiceStatus: Record "E-Document Service Status";
        Logs: List of [Enum "E-Document Service Status"];
    begin
        // [FEATURE] [E-Document] [Clearance] [Flow]
        // [SCENARIO] When sending fails in clearance workflow, export should still happen only once

        // [GIVEN] A clearance workflow where the send integration throws an error
        Initialize();
        BindSubscription(EDocImplState);
        EDocImplState.SetThrowIntegrationLoggedError();

        // [WHEN] Team member posts sales invoice
        LibraryLowerPermission.SetTeamMember();
        LibraryEDoc.PostInvoice(Customer);
        EDocument.FindLast();

        // [WHEN] E-Document Created Flow job queue runs
        LibraryJobQueue.FindAndRunJobQueueEntryByRecordId(EDocument.RecordId);

        // [THEN] Service status should be Sending Error
        EDocumentServiceStatus.Get(EDocument."Entry No", ClearanceService.Code);
        Assert.AreEqual(
            Enum::"E-Document Service Status"::"Sending Error",
            EDocumentServiceStatus.Status,
            IncorrectValueErr);

        // [THEN] Document should be in Error state
        EDocument.Get(EDocument."Entry No");
        Assert.AreEqual(Enum::"E-Document Status"::Error, EDocument.Status, IncorrectValueErr);

        // [THEN] There should still be only ONE Exported log (no double export)
        EDocumentLog.SetRange("E-Doc. Entry No", EDocument."Entry No");
        EDocumentLog.SetRange("Service Code", ClearanceService.Code);
        EDocumentLog.SetRange(Status, Enum::"E-Document Service Status"::Exported);
        Assert.AreEqual(1, EDocumentLog.Count(), 'Expected exactly 1 Exported log even when send fails');

        // [THEN] Log sequence: Exported, Sending Error
        Logs.Add(Enum::"E-Document Service Status"::Exported);
        Logs.Add(Enum::"E-Document Service Status"::"Sending Error");
        LibraryEDoc.AssertEDocumentLogs(EDocument, ClearanceService, Logs);

        UnbindSubscription(EDocImplState);
    end;

    [Test]
    procedure ClearanceFlowExportErrorDoesNotSend()
    var
        EDocument: Record "E-Document";
        EDocumentLog: Record "E-Document Log";
        EDocumentServiceStatus: Record "E-Document Service Status";
    begin
        // [FEATURE] [E-Document] [Clearance] [Flow]
        // [SCENARIO] When export fails, the send step should not execute

        // [GIVEN] A clearance workflow where format creation throws an error
        Initialize();
        EDocImplState.SetThrowRuntimeError();
        BindSubscription(EDocImplState);

        // [WHEN] Team member posts sales invoice
        LibraryLowerPermission.SetTeamMember();
        LibraryEDoc.PostInvoice(Customer);
        EDocument.FindLast();

        // [WHEN] E-Document Created Flow job queue runs
        LibraryJobQueue.FindAndRunJobQueueEntryByRecordId(EDocument.RecordId);

        // [THEN] Service status should be Export Error
        EDocumentServiceStatus.Get(EDocument."Entry No", ClearanceService.Code);
        Assert.AreEqual(
            Enum::"E-Document Service Status"::"Export Error",
            EDocumentServiceStatus.Status,
            IncorrectValueErr);

        // [THEN] No Send-related log should exist (Pending Response / Sent / Sending Error)
        EDocumentLog.SetRange("E-Doc. Entry No", EDocument."Entry No");
        EDocumentLog.SetRange("Service Code", ClearanceService.Code);
        EDocumentLog.SetFilter(Status, '%1|%2|%3',
            Enum::"E-Document Service Status"::"Pending Response",
            Enum::"E-Document Service Status"::Sent,
            Enum::"E-Document Service Status"::"Sending Error");
        Assert.AreEqual(0, EDocumentLog.Count(), 'Send should not execute when export fails');

        UnbindSubscription(EDocImplState);
    end;

    // Helper procedures 

    local procedure Initialize()
    var
        EDocument: Record "E-Document";
        EDocumentServiceStatus: Record "E-Document Service Status";
        DocumentSendingProfile: Record "Document Sending Profile";
        GeneralPostingSetup: Record "General Posting Setup";
        InventoryPostingSetup: Record "Inventory Posting Setup";
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesSetup: Record "Sales & Receivables Setup";
        TransformationRule: Record "Transformation Rule";
        Workflow: Record Workflow;
        LibraryERM: Codeunit "Library - ERM";
        WorkflowCode: Code[20];
    begin
        LibraryLowerPermission.SetOutsideO365Scope();
        Clear(EDocImplState);

        if IsInitialized then
            exit;

        EDocument.DeleteAll();
        EDocumentServiceStatus.DeleteAll();

        LibraryEDoc.SetupStandardVAT();
        LibraryEDoc.SetupStandardSalesScenario(Customer, ClearanceService, Enum::"E-Document Format"::"Mock", Enum::"Service Integration"::"Mock");

        // Ensure sales number series exist
        SalesSetup.Get();
        if SalesSetup."Invoice Nos." = '' then
            SalesSetup.Validate("Invoice Nos.", LibraryERM.CreateNoSeriesCode());
        if SalesSetup."Posted Invoice Nos." = '' then
            SalesSetup.Validate("Posted Invoice Nos.", LibraryERM.CreateNoSeriesCode());
        SalesSetup.Modify(false);

        // Create temp sales document to discover posting groups, then set up complete posting infrastructure
        LibraryEDoc.CreateSalesHeaderWithItem(Customer, SalesHeader, Enum::"Sales Document Type"::Invoice);
        SalesLine.SetRange("Document Type", SalesHeader."Document Type");
        SalesLine.SetRange("Document No.", SalesHeader."No.");
        SalesLine.FindFirst();

        // Ensure General Posting Setup has all required GL accounts and is not blocked
        if not GeneralPostingSetup.Get(SalesLine."Gen. Bus. Posting Group", SalesLine."Gen. Prod. Posting Group") then
            LibraryERM.CreateGeneralPostingSetup(GeneralPostingSetup, SalesLine."Gen. Bus. Posting Group", SalesLine."Gen. Prod. Posting Group");
        GeneralPostingSetup.Blocked := false;
        if GeneralPostingSetup."Sales Account" = '' then
            GeneralPostingSetup."Sales Account" := LibraryERM.CreateGLAccountNo();
        if GeneralPostingSetup."COGS Account" = '' then
            GeneralPostingSetup."COGS Account" := LibraryERM.CreateGLAccountNo();
        if GeneralPostingSetup."Inventory Adjmt. Account" = '' then
            GeneralPostingSetup."Inventory Adjmt. Account" := LibraryERM.CreateGLAccountNo();
        if GeneralPostingSetup."Direct Cost Applied Account" = '' then
            GeneralPostingSetup."Direct Cost Applied Account" := LibraryERM.CreateGLAccountNo();
        GeneralPostingSetup.Modify(true);

        // Ensure Inventory Posting Setup has Inventory Account
        Item.Get(SalesLine."No.");
        if not InventoryPostingSetup.Get('', Item."Inventory Posting Group") then begin
            InventoryPostingSetup.Init();
            InventoryPostingSetup."Location Code" := '';
            InventoryPostingSetup."Invt. Posting Group Code" := Item."Inventory Posting Group";
            InventoryPostingSetup.Insert();
        end;
        if InventoryPostingSetup."Inventory Account" = '' then
            InventoryPostingSetup."Inventory Account" := LibraryERM.CreateGLAccountNo();
        InventoryPostingSetup.Modify(true);

        // Clean up temp sales document
        SalesHeader.Delete(true);

        TransformationRule.DeleteAll();
        TransformationRule.CreateDefaultTransformations();

        // Override the workflow: replace simple flow with clearance flow (Export -> Send)
        DocumentSendingProfile.Get(Customer."Document Sending Profile");

        // Disable the simple flow before enabling clearance flow to avoid duplicate entry-point event conflict
        if Workflow.Get(DocumentSendingProfile."Electronic Service Flow") then begin
            Workflow.Validate(Enabled, false);
            Workflow.Modify(true);
        end;

        WorkflowCode := CreateClearanceFlow(ClearanceService.Code);
        DocumentSendingProfile."Electronic Service Flow" := WorkflowCode;
        DocumentSendingProfile.Modify();

        IsInitialized := true;
    end;

    local procedure InitializeSyncService(var SyncService: Record "E-Document Service")
    var
        DocumentSendingProfile: Record "Document Sending Profile";
        Workflow: Record Workflow;
        ServiceCode: Code[20];
        OriginalWorkflowCode: Code[20];
        SyncWorkflowCode: Code[20];
    begin
        // Ensure base setup is done first
        Initialize();
        LibraryLowerPermission.SetOutsideO365Scope();

        // Create a separate service with "Mock Sync" integration (does not implement IDocumentResponseHandler)
        ServiceCode := LibraryEDoc.CreateService(Enum::"E-Document Format"::"Mock", Enum::"Service Integration"::"Mock Sync");
        SyncService.Get(ServiceCode);

        // Swap workflows: disable async clearance flow, enable sync clearance flow
        DocumentSendingProfile.Get(Customer."Document Sending Profile");
        OriginalWorkflowCode := DocumentSendingProfile."Electronic Service Flow";

        if Workflow.Get(OriginalWorkflowCode) then begin
            Workflow.Validate(Enabled, false);
            Workflow.Modify(true);
        end;

        SyncWorkflowCode := CreateClearanceFlow(SyncService.Code);
        DocumentSendingProfile."Electronic Service Flow" := SyncWorkflowCode;
        DocumentSendingProfile.Modify();

        // Commit so the sync workflow is active during test execution
        Commit();

        // Schedule cleanup: restore original workflow after this test completes
        // We do this inline since we need to restore before the next test runs
        SyncServiceOriginalWorkflow := OriginalWorkflowCode;
        SyncServiceWorkflow := SyncWorkflowCode;
        RestoreSyncServiceWorkflow := true;
    end;

    local procedure RestoreWorkflowIfNeeded()
    var
        DocumentSendingProfile: Record "Document Sending Profile";
        Workflow: Record Workflow;
    begin
        if not RestoreSyncServiceWorkflow then
            exit;

        RestoreSyncServiceWorkflow := false;
        LibraryLowerPermission.SetOutsideO365Scope();

        // Disable sync workflow
        if Workflow.Get(SyncServiceWorkflow) then begin
            Workflow.Validate(Enabled, false);
            Workflow.Modify(true);
        end;

        // Re-enable original async clearance workflow
        DocumentSendingProfile.Get(Customer."Document Sending Profile");
        DocumentSendingProfile."Electronic Service Flow" := SyncServiceOriginalWorkflow;
        DocumentSendingProfile.Modify();

        if Workflow.Get(SyncServiceOriginalWorkflow) then begin
            Workflow.Validate(Enabled, true);
            Workflow.Modify(true);
        end;
    end;

    local procedure CreateClearanceFlow(ClearanceServiceCode: Code[20]): Code[20]
    var
        Workflow: Record Workflow;
        WorkflowStep: Record "Workflow Step";
        WorkflowStepArgument: Record "Workflow Step Argument";
        EDocWorkflowSetup: Codeunit "E-Document Workflow Setup";
        EDocCreatedEventID, ExportResponseID, ExportedEventID, SendResponseID : Integer;
    begin
        // Create clearance workflow:
        //   EDocCreated -> Export(Service) -> EDocExported -> Send(Service)
        LibraryWorkflow.CreateWorkflow(Workflow);
        Workflow.Category := 'EDOC';
        Workflow.Modify();

        // Step 1: Entry point event - EDocCreated
        EDocCreatedEventID := LibraryWorkflow.InsertEntryPointEventStep(Workflow, EDocWorkflowSetup.EDocCreated());

        // Step 2: Response - Export to Clearance Service
        ExportResponseID := LibraryWorkflow.InsertResponseStep(Workflow, EDocWorkflowSetup.ResponseEDocExport(), EDocCreatedEventID);
        WorkflowStep.Get(Workflow.Code, ExportResponseID);
        WorkflowStepArgument.Get(WorkflowStep.Argument);
        WorkflowStepArgument.Validate("E-Document Service", ClearanceServiceCode);
        WorkflowStepArgument.Modify();

        // Step 3: Event - EDocExported (non-entry-point subsequent event)
        ExportedEventID := InsertWorkflowEventStep(Workflow, EDocWorkflowSetup.EventEDocExported(), ExportResponseID);

        // Step 4: Response - Send to Clearance Service
        SendResponseID := LibraryWorkflow.InsertResponseStep(Workflow, EDocWorkflowSetup.EDocSendEDocResponseCode(), ExportedEventID);
        WorkflowStep.Get(Workflow.Code, SendResponseID);
        WorkflowStepArgument.Get(WorkflowStep.Argument);
        WorkflowStepArgument.Validate("E-Document Service", ClearanceServiceCode);
        WorkflowStepArgument.Modify();

        LibraryWorkflow.EnableWorkflow(Workflow);
        exit(Workflow.Code);
    end;

    local procedure InsertWorkflowEventStep(Workflow: Record Workflow; FunctionName: Code[128]; PreviousStepID: Integer): Integer
    var
        WorkflowStep: Record "Workflow Step";
        NextStepID: Integer;
    begin
        WorkflowStep.SetRange("Workflow Code", Workflow.Code);
        if WorkflowStep.FindLast() then
            NextStepID := WorkflowStep.ID + 1
        else
            NextStepID := 1;

        WorkflowStep.Init();
        WorkflowStep."Workflow Code" := Workflow.Code;
        WorkflowStep.ID := NextStepID;
        WorkflowStep.Type := WorkflowStep.Type::"Event";
        WorkflowStep."Function Name" := FunctionName;
        WorkflowStep."Previous Workflow Step ID" := PreviousStepID;
        WorkflowStep."Entry Point" := false;
        WorkflowStep.Insert(true);

        exit(NextStepID);
    end;
}
