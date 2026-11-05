// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.Agent.PayablesAgent;

using Microsoft.Utilities;
using System.Agents;
using System.Agents.TaskPane;
using System.Utilities;

// Rebuilds scoped task/source projections and owns human navigation and formatting.
codeunit 3330 "PA Work Item Presentation"
{
    Access = Internal;
    InherentEntitlements = X;
    InherentPermissions = X;
    Permissions = tabledata "Agent Task" = R, tabledata "Agent Task Message" = R;

    var
        WorkItemNameTxt: Label 'Work item %1', Comment = '%1 = list row number';
        RejectedWorkItemNameTxt: Label 'Rejected work item %1', Comment = '%1 = list row number';
        EmailSourceTxt: Label 'Email from %1: %2', Comment = '%1 = sender, %2 = subject';
        PdfSourceTxt: Label 'PDF file %1', Comment = '%1 = file name';
        PurchaseDocumentTxt: Label 'Purchase %1 %2', Comment = '%1 = document type, %2 = number';
        PostedInvoiceTxt: Label 'Posted purchase invoice %1', Comment = '%1 = document number';
        PostedCreditMemoTxt: Label 'Posted purchase credit memo %1', Comment = '%1 = document number';
        NoOutcomeErr: Label 'The outcome is no longer available.';
        SourceNotAvailableErr: Label 'The source of this work item is no longer available.';
        AgentTaskNotFoundErr: Label 'The agent task is no longer available.';
        OutlookWebLinkTok: Label 'https://outlook.office365.com/owa/?ItemID=%1&exvsurl=1&viewmodel=ReadMessageItem', Locked = true;

    internal procedure LoadAllRows(var TempRows: Record "PA Work Item List Row" temporary)
    var
        WorkItems: Codeunit "PA Work Item Collection";
    begin
        TempRows.Reset();
        TempRows.DeleteAll();
        WorkItems.OpenAll();
        InsertCollectionRows(TempRows, WorkItems);
    end;

    internal procedure LoadRowsByState(State: Enum "PA Work Item State"; var TempRows: Record "PA Work Item List Row" temporary)
    var
        WorkItems: Codeunit "PA Work Item Collection";
    begin
        TempRows.Reset();
        TempRows.DeleteAll();
        WorkItems.OpenByState(State);
        InsertCollectionRows(TempRows, WorkItems);
    end;

    internal procedure PopulateRow(var TempRow: Record "PA Work Item List Row" temporary; WorkItem: Codeunit "PA Work Item")
    begin
        ClearWorkItemRow(TempRow);
        TempRow."Work Item ID" := WorkItem.GetId();
        TempRow."Created At" := WorkItem.GetCreatedAt();
        TempRow."Updated At" := WorkItem.GetUpdatedAt();
        TempRow."Source Type" := WorkItem.GetSourceType();
        TempRow."Email From" := CopyStr(WorkItem.GetEmailFrom(), 1, MaxStrLen(TempRow."Email From"));
        TempRow."Email Subject" := CopyStr(WorkItem.GetEmailSubject(), 1, MaxStrLen(TempRow."Email Subject"));
        TempRow."File Name" := CopyStr(WorkItem.GetFileName(), 1, MaxStrLen(TempRow."File Name"));
        TempRow."Has Pdf" := WorkItem.HasPdf();
        TempRow."Sender Name" := CopyStr(WorkItem.GetSenderName(), 1, MaxStrLen(TempRow."Sender Name"));
        TempRow."Email Received At" := WorkItem.GetEmailReceivedAt();
        TempRow."Email External Id" := CopyStr(WorkItem.GetEmailExternalId(), 1, MaxStrLen(TempRow."Email External Id"));
        TempRow."Agent Task ID" := WorkItem.GetAgentTaskId();
        TempRow."Has Agent Task" := WorkItem.HasAgentTask();
        TempRow.Outcome := WorkItem.GetOutcome();
        TempRow.State := WorkItem.GetState();
        TempRow."Admission Status" := WorkItem.GetAdmissionStatus();
        TempRow."Rejection Reason" := CopyStr(WorkItem.GetRejectionReason(), 1, MaxStrLen(TempRow."Rejection Reason"));
        TempRow."Can Extract Text" := WorkItem.CanExtractText();
        TempRow."Can Register Outcome" := WorkItem.CanRegisterOutcome();
        if WorkItem.HasAgentTask() then
            TempRow."Agent Task Status" := WorkItem.GetAgentTaskStatus();
        TempRow.Name := CopyStr(StrSubstNo(WorkItemNameTxt, TempRow."Entry No."), 1, MaxStrLen(TempRow.Name));
        if TempRow.State = "PA Work Item State"::Rejected then
            TempRow.Name := CopyStr(StrSubstNo(RejectedWorkItemNameTxt, TempRow."Entry No."), 1, MaxStrLen(TempRow.Name));
        if WorkItem.GetTitle() <> '' then
            TempRow.Name := CopyStr(WorkItem.GetTitle(), 1, MaxStrLen(TempRow.Name));
        PopulateDescriptions(TempRow);
    end;

    internal procedure DrillDownByState(State: Enum "PA Work Item State")
    var
        TasksPage: Page "Payables Agent Work Items";
    begin
        TasksPage.OpenByState(State);
        TasksPage.Run();
    end;

    internal procedure GetMessagePageId(MessageId: Guid): Integer
    var
        Message: Record "Agent Task Message";
        WorkItem: Codeunit "PA Work Item";
    begin
        Message.SetRange(ID, MessageId);
        if not Message.FindFirst() then
            exit(0);
        if not WorkItem.LoadByAgentTaskId(Message."Task ID") then
            exit(0);
        case WorkItem.GetSourceType() of
            "PA Source Type"::Email:
                exit(Page::"PA Agent Email Task");
            "PA Source Type"::Upload:
                exit(Page::"PA Agent Upload Task");
        end;
        exit(0);
    end;

    internal procedure OpenSource(WorkItem: Codeunit "PA Work Item")
    begin
        if WorkItem.GetSourceType() = "PA Source Type"::Email then
            OpenSourceEmail(WorkItem)
        else
            OpenSourcePdf(WorkItem);
    end;

    internal procedure OpenSourceEmail(WorkItem: Codeunit "PA Work Item")
    var
        EmailPage: Page "PA Email Review";
    begin
        if WorkItem.GetSourceType() <> "PA Source Type"::Email then
            Error(SourceNotAvailableErr);
        EmailPage.SetWorkItem(WorkItem);
        EmailPage.Run();
    end;

    internal procedure OpenSourcePdf(WorkItem: Codeunit "PA Work Item")
    begin
        if not WorkItem.HasPdf() then
            Error(SourceNotAvailableErr);
        ViewSourcePdf(WorkItem);
    end;

    internal procedure ViewSourcePdf(WorkItem: Codeunit "PA Work Item")
    var
        Blob: Codeunit "Temp Blob";
        Stream: InStream;
        FileName: Text;
    begin
        if not WorkItem.GetSourcePdf(Blob, FileName) then
            Error(SourceNotAvailableErr);
        Blob.CreateInStream(Stream);
        if File.ViewFromStream(Stream, FileName, true) then
            exit;
        DownloadSourcePdf(WorkItem);
    end;

    internal procedure DownloadSourcePdf(WorkItem: Codeunit "PA Work Item")
    var
        Blob: Codeunit "Temp Blob";
        Stream: InStream;
        FileName: Text;
    begin
        if not WorkItem.GetSourcePdf(Blob, FileName) then
            Error(SourceNotAvailableErr);
        Blob.CreateInStream(Stream);
        DownloadFromStream(Stream, '', '', '', FileName);
    end;

    internal procedure GetEmailWebLink(WorkItem: Codeunit "PA Work Item"): Text
    var
        ExternalId: Text;
    begin
        ExternalId := WorkItem.GetEmailExternalId();
        if ExternalId = '' then
            exit('');
        exit(StrSubstNo(OutlookWebLinkTok, ExternalId));
    end;

    internal procedure OpenAgentTask(AgentTaskId: BigInteger)
    var
        AgentTask: Record "Agent Task";
        AgentTaskManagement: Codeunit "Agent Task";
        TaskPane: Codeunit "Task Pane";
    begin
        if AgentTaskId = 0 then
            exit;
        if not AgentTask.Get(AgentTaskId) then
            Error(AgentTaskNotFoundErr);
        if AgentTask."Agent Substate" = AgentTask."Agent Substate"::Archived then
            AgentTaskManagement.OpenAgentTaskLogEntries(AgentTaskId)
        else
            TaskPane.ShowTask(AgentTaskId);
    end;

    internal procedure OpenOutcome(WorkItem: Codeunit "PA Work Item")
    var
        PageManagement: Codeunit "Page Management";
        Outcome: RecordId;
        OutcomeRef: RecordRef;
    begin
        Outcome := WorkItem.GetOutcome();
        if Outcome.TableNo = 0 then
            Error(NoOutcomeErr);
        if not OutcomeRef.Get(Outcome) then
            Error(NoOutcomeErr);
        PageManagement.PageRun(OutcomeRef);
    end;

    local procedure InsertCollectionRows(var TempRows: Record "PA Work Item List Row" temporary; var WorkItems: Codeunit "PA Work Item Collection")
    var
        WorkItem: Codeunit "PA Work Item";
        RowNo: BigInteger;
    begin
        while WorkItems.Next(WorkItem) do begin
            RowNo += 1;
            TempRows.Init();
            TempRows."Entry No." := RowNo;
            PopulateRow(TempRows, WorkItem);
            TempRows.Insert();
        end;
    end;

    local procedure ClearWorkItemRow(var TempRow: Record "PA Work Item List Row" temporary)
    var
        RowNo: BigInteger;
    begin
        RowNo := TempRow."Entry No.";
        Clear(TempRow);
        TempRow."Entry No." := RowNo;
    end;

    local procedure PopulateDescriptions(var TempRow: Record "PA Work Item List Row" temporary)
    var
        Facts: Record "PA Purchase Outcome Facts" temporary;
        PurchaseOutcomes: Codeunit "PA Purchase Outcomes";
    begin
        TempRow."Source Description" := CopyStr(DescribeSource(TempRow), 1, MaxStrLen(TempRow."Source Description"));
        if PurchaseOutcomes.TryGetFacts(TempRow.Outcome, Facts) then begin
            TempRow."Vendor No." := Facts."Vendor No.";
            TempRow."Result Description" := CopyStr(DescribeOutcome(Facts), 1, MaxStrLen(TempRow."Result Description"));
        end else
            if TempRow.Outcome.TableNo <> 0 then
                TempRow."Result Description" := CopyStr(Format(TempRow.Outcome), 1, MaxStrLen(TempRow."Result Description"));
    end;

    local procedure DescribeSource(Data: Record "PA Work Item List Row"): Text
    begin
        if Data."Source Type" = "PA Source Type"::Email then
            exit(StrSubstNo(EmailSourceTxt, Data."Email From", Data."Email Subject"));
        if Data."Has Pdf" then
            exit(StrSubstNo(PdfSourceTxt, Data."File Name"));
        exit('');
    end;

    local procedure DescribeOutcome(Facts: Record "PA Purchase Outcome Facts" temporary): Text
    begin
        if not Facts.Posted then
            exit(StrSubstNo(PurchaseDocumentTxt, Facts."Document Type", Facts."Document No."));
        if Facts."Document Type" = Facts."Document Type"::"Credit Memo" then
            exit(StrSubstNo(PostedCreditMemoTxt, Facts."Document No."));
        exit(StrSubstNo(PostedInvoiceTxt, Facts."Document No."));
    end;
}
