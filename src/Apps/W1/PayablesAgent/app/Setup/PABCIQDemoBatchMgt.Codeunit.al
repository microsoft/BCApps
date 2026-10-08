// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

#pragma warning disable AS0007
namespace Microsoft.Agent.PayablesAgent;

using Microsoft.eServices.EDocument;
using Microsoft.eServices.EDocument.Processing.Import;
using Microsoft.Purchases.Document;
using Microsoft.Purchases.History;
using System.Agents;

codeunit 3329 "PA BC IQ Demo Batch Mgt."
{
    Access = Internal;
    InherentEntitlements = X;
    InherentPermissions = X;
    Permissions = tabledata "Agent Task" = rimd,
                  tabledata "Agent Task File" = rimd,
                  tabledata "Agent Task Log Entry" = rimd,
                  tabledata "Agent Task Memory Entry" = rimd,
                  tabledata "Agent Task Message" = rimd,
                  tabledata "Agent Task Message Attachment" = rimd,
                  tabledata "Agent Task Timeline Step" = rimd,
                  tabledata "Agent User Int Request Details" = rimd,
                  tabledata "E-Doc. Data Storage" = rimd,
                  tabledata "E-Document" = rimd,
                  tabledata "E-Document Log" = r,
                  tabledata "PA BC IQ Demo Batch" = rimd,
                  tabledata "PA BC IQ Demo Batch Doc." = rimd,
                  tabledata "Purchase Header" = rimd,
                  tabledata "Purchase Line" = rimd,
                  tabledata "Purch. Inv. Header" = r;

    procedure SubmitInvoices()
    var
        DemoBatch: Record "PA BC IQ Demo Batch";
        DemoSetupMgt: Codeunit "PA BC IQ Demo Mgt.";
        PayablesAgentSetup: Codeunit "Payables Agent Setup";
        ResourceFiles: List of [Text];
        FileName: Text;
        AlreadyActivated: Boolean;
        Sequence: Integer;
    begin
        VerifyTargetCompany();
        if not DemoSetupMgt.IsConfigured() then
            Error(DemoSetupRequiredErr);
        if HasBatch() then
            Error(BatchExistsErr);

        ResourceFiles := GetResourceFiles();
        PreflightResources(ResourceFiles);
        PayablesAgentSetup.EnsureAgentActivated(AlreadyActivated);

        DemoBatch.Init();
        DemoBatch."Primary Key" := BatchPrimaryKeyTok;
        DemoBatch."Run ID" := CreateGuid();
        DemoBatch."Submitted At" := CurrentDateTime();
        DemoBatch."BC IQ Enabled" := DemoSetupMgt.IsBusinessCentralIQEnabled();
        DemoBatch."Expected Document Count" := ResourceFiles.Count();
        DemoBatch.Status := DemoBatch.Status::Submitting;
        DemoBatch.Insert(true);
        Commit();

        foreach FileName in ResourceFiles do begin
            Sequence += 1;
            SubmitResource(DemoBatch, Sequence, FileName);
        end;

        DemoBatch.Get(BatchPrimaryKeyTok);
        DemoBatch.Status := DemoBatch.Status::Submitted;
        DemoBatch."Last Error" := '';
        DemoBatch.Modify(true);
    end;

    procedure CleanupSubmittedInvoices()
    var
        DemoBatch: Record "PA BC IQ Demo Batch";
        DemoBatchDocument: Record "PA BC IQ Demo Batch Doc.";
    begin
        VerifyTargetCompany();
        if not DemoBatch.Get(BatchPrimaryKeyTok) then
            Error(NoBatchErr);

        VerifyCleanupIsSafe(DemoBatch);

        DemoBatchDocument.SetRange("Run ID", DemoBatch."Run ID");
        DemoBatchDocument.SetCurrentKey("Run ID", Sequence);
        DemoBatchDocument.Ascending(false);
        if DemoBatchDocument.FindSet() then
            repeat
                CleanupDocument(DemoBatchDocument);
            until DemoBatchDocument.Next() = 0;

        DemoBatchDocument.Reset();
        DemoBatchDocument.SetRange("Run ID", DemoBatch."Run ID");
        DemoBatchDocument.DeleteAll(true);
        DemoBatch.Delete(true);
    end;

    procedure HasBatch(): Boolean
    var
        DemoBatch: Record "PA BC IQ Demo Batch";
    begin
        exit(DemoBatch.Get(BatchPrimaryKeyTok));
    end;

    procedure EnsureNoBatch()
    begin
        if HasBatch() then
            Error(CleanBatchFirstErr);
    end;

    procedure GetBatchModeText(): Text
    var
        DemoBatch: Record "PA BC IQ Demo Batch";
    begin
        if not DemoBatch.Get(BatchPrimaryKeyTok) then
            exit(NotAvailableLbl);
        if DemoBatch."BC IQ Enabled" then
            exit(BCIQModeLbl);
        exit(BaselineModeLbl);
    end;

    procedure GetBatchCountText(): Text
    var
        DemoBatch: Record "PA BC IQ Demo Batch";
    begin
        if not DemoBatch.Get(BatchPrimaryKeyTok) then
            exit(NotAvailableLbl);
        exit(StrSubstNo(BatchCountLbl, DemoBatch."Submitted Document Count", DemoBatch."Expected Document Count"));
    end;

    procedure GetBatchSubmittedAt(): DateTime
    var
        DemoBatch: Record "PA BC IQ Demo Batch";
    begin
        if DemoBatch.Get(BatchPrimaryKeyTok) then
            exit(DemoBatch."Submitted At");
    end;

    procedure GetTaskStatusText(): Text
    var
        AgentTask: Record "Agent Task";
        DemoBatch: Record "PA BC IQ Demo Batch";
        DemoBatchDocument: Record "PA BC IQ Demo Batch Doc.";
        ActiveCount: Integer;
        CompletedCount: Integer;
        MissingCount: Integer;
        StoppedCount: Integer;
    begin
        if not DemoBatch.Get(BatchPrimaryKeyTok) then
            exit(NotAvailableLbl);

        DemoBatchDocument.SetRange("Run ID", DemoBatch."Run ID");
        DemoBatchDocument.SetFilter("Agent Task ID", '<>%1', 0);
        if DemoBatchDocument.FindSet() then
            repeat
                if not AgentTask.Get(DemoBatchDocument."Agent Task ID") then
                    MissingCount += 1
                else
                    case AgentTask.Status of
                        AgentTask.Status::Completed:
                            CompletedCount += 1;
                        AgentTask.Status::"Stopped by User",
                        AgentTask.Status::"Stopped by System":
                            StoppedCount += 1;
                        else
                            ActiveCount += 1;
                    end;
            until DemoBatchDocument.Next() = 0;

        exit(StrSubstNo(TaskStatusLbl, ActiveCount, CompletedCount, StoppedCount, MissingCount));
    end;

    local procedure SubmitResource(var DemoBatch: Record "PA BC IQ Demo Batch"; Sequence: Integer; FileName: Text)
    var
        AgentTask: Record "Agent Task";
        DemoBatchDocument: Record "PA BC IQ Demo Batch Doc.";
        EDocument: Record "E-Document";
        ResourcePath: Text;
        SourceDetails: Text;
        SubmissionError: Text;
    begin
        ResourcePath := ResourceFolderTok + FileName;
        SourceDetails := GetSourceDetails(DemoBatch."Run ID", FileName);

        DemoBatchDocument.Init();
        DemoBatchDocument."Run ID" := DemoBatch."Run ID";
        DemoBatchDocument.Sequence := Sequence;
        DemoBatchDocument."Resource Path" := CopyStr(ResourcePath, 1, MaxStrLen(DemoBatchDocument."Resource Path"));
        DemoBatchDocument."File Name" := CopyStr(FileName, 1, MaxStrLen(DemoBatchDocument."File Name"));
        DemoBatchDocument.Insert(true);
        Commit();

        if not TryImportResource(ResourcePath, FileName, SourceDetails, EDocument) then begin
            SubmissionError := GetLastErrorText();
            RecoverEDocument(SourceDetails, EDocument);
            UpdateBatchDocumentFromEDocument(DemoBatchDocument, EDocument);
            DemoBatchDocument."Submission Error" := CopyStr(SubmissionError, 1, MaxStrLen(DemoBatchDocument."Submission Error"));
            DemoBatchDocument.Modify(true);
            DemoBatch.Get(BatchPrimaryKeyTok);
            DemoBatch.Status := DemoBatch.Status::Partial;
            DemoBatch."Last Error" := CopyStr(StrSubstNo(ResourceSubmissionErr, FileName, SubmissionError), 1, MaxStrLen(DemoBatch."Last Error"));
            DemoBatch.Modify(true);
            Commit();
            Error(ResourceSubmissionErr, FileName, SubmissionError);
        end;

        AgentTask.SetRange("Company Name", CompanyName());
        AgentTask.SetRange("External ID", Format(EDocument."Entry No"));
        if not AgentTask.FindFirst() then
            Error(TaskNotCreatedErr, FileName);

        EDocument.Get(EDocument."Entry No");
        UpdateBatchDocumentFromEDocument(DemoBatchDocument, EDocument);
        DemoBatchDocument."Agent Task ID" := AgentTask.ID;
        DemoBatchDocument.Submitted := true;
        DemoBatchDocument.Modify(true);

        DemoBatch.Get(BatchPrimaryKeyTok);
        DemoBatch."Submitted Document Count" += 1;
        DemoBatch.Modify(true);
        Commit();
    end;

    [TryFunction]
    local procedure TryImportResource(ResourcePath: Text; FileName: Text; SourceDetails: Text; var EDocument: Record "E-Document")
    var
        PayablesAgentSetup: Codeunit "Payables Agent Setup";
        ResourceInStream: InStream;
    begin
        NavApp.GetResource(ResourcePath, ResourceInStream);
        PayablesAgentSetup.ImportInvoiceFile(FileName, SourceDetails, ResourceInStream, EDocument);
    end;

    local procedure RecoverEDocument(SourceDetails: Text; var EDocument: Record "E-Document")
    begin
        Clear(EDocument);
        EDocument.SetRange("Source Details", CopyStr(SourceDetails, 1, MaxStrLen(EDocument."Source Details")));
        if EDocument.FindLast() then;
    end;

    local procedure UpdateBatchDocumentFromEDocument(var DemoBatchDocument: Record "PA BC IQ Demo Batch Doc."; EDocument: Record "E-Document")
    begin
        if EDocument."Entry No" = 0 then
            exit;
        DemoBatchDocument."E-Document Entry No." := EDocument."Entry No";
        DemoBatchDocument."E-Document System ID" := EDocument.SystemId;
        DemoBatchDocument."Unstructured Storage Entry No." := EDocument."Unstructured Data Entry No.";
        DemoBatchDocument."Structured Storage Entry No." := EDocument."Structured Data Entry No.";
    end;

    local procedure PreflightResources(ResourceFiles: List of [Text])
    var
        FileName: Text;
        ResourcePath: Text;
    begin
        foreach FileName in ResourceFiles do begin
            ResourcePath := ResourceFolderTok + FileName;
            if not TryOpenResource(ResourcePath) then
                Error(ResourceMissingErr, ResourcePath, ResourceJunctionPathTok);
        end;
    end;

    [TryFunction]
    local procedure TryOpenResource(ResourcePath: Text)
    var
        ResourceInStream: InStream;
    begin
        NavApp.GetResource(ResourcePath, ResourceInStream);
    end;

    local procedure GetResourceFiles() ResourceFiles: List of [Text]
    begin
        ResourceFiles.Add('GB-T01-D_GB01D-C04.pdf');
        ResourceFiles.Add('GB-T04-D_GB04D-C04.pdf');
        ResourceFiles.Add('GB-T03-D_GB03D-C04.pdf');
        ResourceFiles.Add('06-June-GB-SVC-2606-H01.pdf');
        ResourceFiles.Add('07-July-GB-SVC-2607-H01.pdf');
        ResourceFiles.Add('08-August-GB-SVC-2608-H01.pdf');
        ResourceFiles.Add('09-September-GB-SVC-2609-H01.pdf');
        ResourceFiles.Add('10-October-GB-SVC-2610-N01.pdf');
    end;

    local procedure GetSourceDetails(RunID: Guid; FileName: Text): Text
    begin
        exit(StrSubstNo(SourceDetailsLbl, Format(RunID, 0, 4), FileName));
    end;

    local procedure VerifyCleanupIsSafe(DemoBatch: Record "PA BC IQ Demo Batch")
    var
        AgentTask: Record "Agent Task";
        DemoBatchDocument: Record "PA BC IQ Demo Batch Doc.";
        EDocument: Record "E-Document";
    begin
        DemoBatchDocument.SetRange("Run ID", DemoBatch."Run ID");
        if DemoBatchDocument.FindSet() then
            repeat
                if DemoBatchDocument."Agent Task ID" <> 0 then
                    if AgentTask.Get(DemoBatchDocument."Agent Task ID") then
                        if not (AgentTask.Status in [AgentTask.Status::Completed, AgentTask.Status::"Stopped by User", AgentTask.Status::"Stopped by System"]) then
                            Error(TasksStillActiveErr);

                if DemoBatchDocument."E-Document Entry No." <> 0 then
                    if EDocument.Get(DemoBatchDocument."E-Document Entry No.") then begin
                        VerifyEDocumentOwnership(DemoBatch, DemoBatchDocument, EDocument);
                        VerifyNotPosted(EDocument, DemoBatchDocument."File Name");
                    end;
            until DemoBatchDocument.Next() = 0;
    end;

    local procedure VerifyEDocumentOwnership(DemoBatch: Record "PA BC IQ Demo Batch"; DemoBatchDocument: Record "PA BC IQ Demo Batch Doc."; EDocument: Record "E-Document")
    var
        ExpectedSourceDetails: Text;
    begin
        ExpectedSourceDetails := GetSourceDetails(DemoBatch."Run ID", DemoBatchDocument."File Name");
        if (EDocument.SystemId <> DemoBatchDocument."E-Document System ID") or
           (EDocument."Source Details" <> CopyStr(ExpectedSourceDetails, 1, MaxStrLen(EDocument."Source Details")))
        then
            Error(TrackedRecordChangedErr, DemoBatchDocument."File Name");
    end;

    local procedure VerifyNotPosted(EDocument: Record "E-Document"; FileName: Text)
    var
        PurchInvHeader: Record "Purch. Inv. Header";
        DocumentRecordRef: RecordRef;
    begin
        if EDocument."Document Record ID".TableNo = 0 then
            exit;
        if EDocument."Document Record ID".TableNo = Database::"Purchase Header" then
            exit;
        if EDocument."Document Record ID".TableNo = Database::"Purch. Inv. Header" then begin
            DocumentRecordRef.Get(EDocument."Document Record ID");
            DocumentRecordRef.SetTable(PurchInvHeader);
            Error(PostedInvoiceErr, FileName, PurchInvHeader."No.");
        end;
        Error(UnexpectedDocumentTypeErr, FileName, EDocument."Document Record ID".TableNo);
    end;

    local procedure CleanupDocument(var DemoBatchDocument: Record "PA BC IQ Demo Batch Doc.")
    var
        AgentTask: Record "Agent Task";
        EDocument: Record "E-Document";
        PurchaseHeader: Record "Purchase Header";
        PurchaseHeaderSystemID: Guid;
        StructuredStorageEntryNo: Integer;
        UnstructuredStorageEntryNo: Integer;
    begin
        if DemoBatchDocument."E-Document Entry No." <> 0 then
            if EDocument.Get(DemoBatchDocument."E-Document Entry No.") then begin
                FindLinkedPurchaseHeader(EDocument, PurchaseHeader);
                if PurchaseHeader."No." <> '' then begin
                    PurchaseHeaderSystemID := PurchaseHeader.SystemId;
                    RevertEDocumentToDraftReady(EDocument);
                    if PurchaseHeader.GetBySystemId(PurchaseHeaderSystemID) then
                        PurchaseHeader.Delete(true);
                end;

                EDocument.Get(DemoBatchDocument."E-Document Entry No.");
                RevertEDocumentToUnprocessed(EDocument);
                EDocument.Get(DemoBatchDocument."E-Document Entry No.");
                UnstructuredStorageEntryNo := EDocument."Unstructured Data Entry No.";
                StructuredStorageEntryNo := EDocument."Structured Data Entry No.";
                EDocument.CleanupDocument();
                EDocument.Delete(false);
                DeleteUnreferencedDataStorage(UnstructuredStorageEntryNo);
                if StructuredStorageEntryNo <> UnstructuredStorageEntryNo then
                    DeleteUnreferencedDataStorage(StructuredStorageEntryNo);
            end;

        if DemoBatchDocument."Agent Task ID" <> 0 then
            if AgentTask.Get(DemoBatchDocument."Agent Task ID") then
                DeleteAgentTask(AgentTask);
    end;

    local procedure FindLinkedPurchaseHeader(EDocument: Record "E-Document"; var PurchaseHeader: Record "Purchase Header")
    begin
        Clear(PurchaseHeader);
        PurchaseHeader.SetRange("E-Document Link", EDocument.SystemId);
        if PurchaseHeader.FindFirst() then;
    end;

    local procedure RevertEDocumentToDraftReady(var EDocument: Record "E-Document")
    begin
        MoveEDocumentToStatus(EDocument, "Import E-Doc. Proc. Status"::"Draft Ready");
    end;

    local procedure RevertEDocumentToUnprocessed(var EDocument: Record "E-Document")
    begin
        MoveEDocumentToStatus(EDocument, "Import E-Doc. Proc. Status"::Unprocessed);
    end;

    local procedure MoveEDocumentToStatus(var EDocument: Record "E-Document"; DesiredStatus: Enum "Import E-Doc. Proc. Status")
    var
        EDocImportParameters: Record "E-Doc. Import Parameters" temporary;
        EDocImport: Codeunit "E-Doc. Import";
    begin
        EDocument.CalcFields("Import Processing Status");
        if EDocument."Import Processing Status" = DesiredStatus then
            exit;

        EDocImportParameters := EDocument.GetEDocumentService().GetDefaultImportParameters();
        EDocImportParameters."Step to Run / Desired Status" := EDocImportParameters."Step to Run / Desired Status"::"Desired E-Document Status";
        EDocImportParameters."Desired E-Document Status" := DesiredStatus;
        if not EDocImport.ProcessIncomingEDocument(EDocument, EDocImportParameters) then
            Error(EDocumentRevertErr, EDocument."Entry No", DesiredStatus);
        EDocument.Get(EDocument."Entry No");
    end;

    local procedure DeleteUnreferencedDataStorage(EntryNo: Integer)
    var
        EDocDataStorage: Record "E-Doc. Data Storage";
        EDocument: Record "E-Document";
        EDocumentLog: Record "E-Document Log";
    begin
        if EntryNo = 0 then
            exit;

        EDocument.SetRange("Unstructured Data Entry No.", EntryNo);
        if not EDocument.IsEmpty() then
            exit;
        EDocument.SetRange("Unstructured Data Entry No.");
        EDocument.SetRange("Structured Data Entry No.", EntryNo);
        if not EDocument.IsEmpty() then
            exit;
        EDocumentLog.SetRange("E-Doc. Data Storage Entry No.", EntryNo);
        if not EDocumentLog.IsEmpty() then
            exit;
        if EDocDataStorage.Get(EntryNo) then
            EDocDataStorage.Delete(true);
    end;

    local procedure DeleteAgentTask(var AgentTask: Record "Agent Task")
    var
        AgentTaskFile: Record "Agent Task File";
        AgentTaskLogEntry: Record "Agent Task Log Entry";
        AgentTaskMemoryEntry: Record "Agent Task Memory Entry";
        AgentTaskMessage: Record "Agent Task Message";
        AgentTaskMessageAttachment: Record "Agent Task Message Attachment";
        AgentTaskTimelineStep: Record "Agent Task Timeline Step";
        AgentUserIntRequestDetails: Record "Agent User Int Request Details";
    begin
        AgentTaskMessageAttachment.SetRange("Task ID", AgentTask.ID);
        AgentTaskMessageAttachment.DeleteAll(true);
        AgentTaskFile.SetRange("Task ID", AgentTask.ID);
        AgentTaskFile.DeleteAll(true);
        AgentTaskMessage.SetRange("Task ID", AgentTask.ID);
        AgentTaskMessage.DeleteAll(true);
        AgentTaskTimelineStep.SetRange("Task ID", AgentTask.ID);
        AgentTaskTimelineStep.DeleteAll(true);
        AgentUserIntRequestDetails.SetRange("Task ID", AgentTask.ID);
        AgentUserIntRequestDetails.DeleteAll(true);
        AgentTaskLogEntry.SetRange("Task ID", AgentTask.ID);
        AgentTaskLogEntry.DeleteAll(true);
        AgentTaskMemoryEntry.SetRange("Task ID", AgentTask.ID);
        AgentTaskMemoryEntry.DeleteAll(true);
        AgentTask.Delete(true);
    end;

    local procedure VerifyTargetCompany()
    begin
        if CompanyName() <> TargetCompanyNameTok then
            Error(WrongCompanyErr, TargetCompanyNameTok, CompanyName());
    end;

    var
        BatchPrimaryKeyTok: Label 'BATCH', Locked = true;
        TargetCompanyNameTok: Label 'CRONUS W1', Locked = true;
        ResourceFolderTok: Label 'BCIQDemoInvoices/', Locked = true;
        ResourceJunctionPathTok: Label 'app\.resources\BCIQDemoInvoices', Locked = true;
        SourceDetailsLbl: Label 'BC IQ demo %1 | %2', Locked = true, Comment = '%1 = run ID, %2 = file name';
        DemoSetupRequiredErr: Label 'Configure the BC IQ Payables Agent demo before submitting invoices.';
        BatchExistsErr: Label 'A demo invoice batch already exists. Clean Submitted Invoices before creating another batch.';
        NoBatchErr: Label 'No submitted demo invoice batch exists.';
        CleanBatchFirstErr: Label 'Clean Submitted Invoices before cleaning the company demo setup.';
        ResourceMissingErr: Label 'Demo resource %1 is not packaged. Create the local %2 junction before building and publishing Payables Agent.', Comment = '%1 = resource path, %2 = junction path';
        ResourceSubmissionErr: Label 'Submitting %1 failed: %2', Comment = '%1 = file name, %2 = error';
        TaskNotCreatedErr: Label 'Payables Agent did not create a task for %1.', Comment = '%1 = file name';
        TasksStillActiveErr: Label 'One or more demo tasks are still pending or running. Use Stop all tasks in the Agent side panel, wait until they stop, and run Clean Submitted Invoices again.';
        TrackedRecordChangedErr: Label 'The tracked E-Document for %1 no longer matches the submitted demo batch. Cleanup stopped.', Comment = '%1 = file name';
        PostedInvoiceErr: Label 'Demo file %1 created posted purchase invoice %2. Cleanup does not delete posted invoices.', Comment = '%1 = file name, %2 = posted invoice no.';
        UnexpectedDocumentTypeErr: Label 'Demo file %1 is linked to unexpected table %2. Cleanup stopped.', Comment = '%1 = file name, %2 = table no.';
        EDocumentRevertErr: Label 'E-Document %1 could not be moved to status %2 for cleanup.', Comment = '%1 = E-Document entry no., %2 = status';
        WrongCompanyErr: Label 'Run this action only in company %1. The current company is %2.', Comment = '%1 = required company, %2 = current company';
        NotAvailableLbl: Label 'Not available';
        BCIQModeLbl: Label 'BC IQ';
        BaselineModeLbl: Label 'Baseline';
        BatchCountLbl: Label '%1 of %2 submitted', Comment = '%1 = submitted count, %2 = expected count';
        TaskStatusLbl: Label '%1 active, %2 completed, %3 stopped, %4 missing', Comment = '%1 = active count, %2 = completed count, %3 = stopped count, %4 = missing count';
}
