// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.Agent.PayablesAgent;

using Microsoft.Purchases.Document;
using Microsoft.Purchases.History;
using Microsoft.Utilities;
using System.Agents;
using System.Agents.TaskPane;
using System.Utilities;

// Projects task/source entities into page rows and owns navigation/formatting for the agent workspace.
codeunit 3330 "PA Task Presentation"
{
    Access = Internal;
    InherentEntitlements = X;
    InherentPermissions = X;
    Permissions = tabledata "Agent Task" = R, tabledata "Agent Task Message" = R;

    var
        AgentExperience: Codeunit "PA Agent Experience";
        TaskNameTxt: Label 'Task %1', Comment = '%1 = list row number';
        RejectedSourceNameTxt: Label 'Rejected source %1', Comment = '%1 = list row number';
        EmailSourceTxt: Label 'Email from %1: %2', Comment = '%1 = sender, %2 = subject';
        PdfSourceTxt: Label 'PDF file %1', Comment = '%1 = file name';
        PurchaseDocumentTxt: Label 'Purchase %1 %2', Comment = '%1 = document type, %2 = number';
        PostedInvoiceTxt: Label 'Posted purchase invoice %1', Comment = '%1 = document number';
        PostedCreditMemoTxt: Label 'Posted purchase credit memo %1', Comment = '%1 = document number';
        NoOutcomeErr: Label 'The outcome is no longer available.';
        SourceNotAvailableErr: Label 'The source of this task is no longer available.';
        AgentTaskNotFoundErr: Label 'The agent task is no longer available.';
        SourceTextUnavailableMsg: Label 'There is no extracted source text, and this source cannot be extracted.';
        ExtractSourceTextQst: Label 'There is no extracted source text. Do you want to extract it now?';
        ReplaceSourceTextQst: Label 'Extracted source text already exists. Do you want to replace it?';
        SourceTextMsg: Label '%1', Comment = '%1 = extracted source text';
        OutlookWebLinkTok: Label 'https://outlook.office365.com/owa/?ItemID=%1&exvsurl=1&viewmodel=ReadMessageItem', Locked = true;

    internal procedure GetTasks(var TempTasks: Record "PA Detailed Task" temporary)
    var
        Tasks: Codeunit "PA Task Collection";
        SourceIds: List of [Guid];
        TaskIds: List of [BigInteger];
    begin
        TempTasks.Reset();
        TempTasks.DeleteAll();
        Tasks.GetTaskIds(TaskIds);
        InsertTasks(TempTasks, TaskIds);
        Tasks.GetRejectedSourceIds(SourceIds);
        InsertRejectedSources(TempTasks, SourceIds);
    end;

    internal procedure PopulateListRow(var TempTask: Record "PA Detailed Task" temporary; Task: Codeunit "Payables Agent Task")
    var
        AgentTask: Record "Agent Task";
        RowNo: BigInteger;
    begin
        RowNo := TempTask."Entry No.";
        ClearTaskRow(TempTask);
        TempTask."Entry No." := RowNo;
        TempTask."Task Id" := Task.GetSourceId();
        TempTask."Agent Task ID" := Task.GetAgentTaskId();
        TempTask.Outcome := Task.GetOutcome();
        TempTask."Created At" := Task.GetCreatedAt();
        TempTask."Updated At" := Task.GetUpdatedAt();
        TempTask."Agent Task Status" := Task.GetAgentTaskStatus();
        TempTask."Source Type" := Task.GetSourceType();
        TempTask."Email From" := CopyStr(Task.GetEmailFrom(), 1, MaxStrLen(TempTask."Email From"));
        TempTask."Email Subject" := CopyStr(Task.GetEmailSubject(), 1, MaxStrLen(TempTask."Email Subject"));
        TempTask."File Name" := CopyStr(Task.GetFileName(), 1, MaxStrLen(TempTask."File Name"));
        TempTask."Has Pdf" := Task.HasPdf();
        TempTask."Sender Name" := CopyStr(Task.GetSenderName(), 1, MaxStrLen(TempTask."Sender Name"));
        TempTask."Email Received At" := Task.GetEmailReceivedAt();
        TempTask."Email External Id" := CopyStr(Task.GetEmailExternalId(), 1, MaxStrLen(TempTask."Email External Id"));
        TempTask."Has Agent Task" := true;
        TempTask.State := Task.GetState();
        TempTask."Can Extract Text" := Task.CanExtractText();
        TempTask."Can Register Outcome" := Task.CanRegisterOutcome();
        TempTask.Version := Task.GetVersion();
        TempTask."Intake Status" := Task.GetIntakeStatus();

        TempTask.Name := CopyStr(StrSubstNo(TaskNameTxt, RowNo), 1, MaxStrLen(TempTask.Name));
        if AgentTask.Get(TempTask."Agent Task ID") then
            if AgentTask.Title <> '' then
                TempTask.Name := CopyStr(AgentTask.Title, 1, MaxStrLen(TempTask.Name));
        PopulateDescriptions(TempTask);
    end;

    internal procedure PopulateRejectedSourceRow(var TempTask: Record "PA Detailed Task" temporary; Source: Codeunit "PA Task Source")
    var
        RowNo: BigInteger;
    begin
        RowNo := TempTask."Entry No.";
        ClearTaskRow(TempTask);
        TempTask."Entry No." := RowNo;
        TempTask."Task Id" := Source.GetId();
        TempTask."Created At" := Source.GetCreatedAt();
        TempTask."Updated At" := Source.GetUpdatedAt();
        TempTask."Source Type" := Source.GetSourceType();
        TempTask."Email From" := CopyStr(Source.GetEmailFrom(), 1, MaxStrLen(TempTask."Email From"));
        TempTask."Email Subject" := CopyStr(Source.GetEmailSubject(), 1, MaxStrLen(TempTask."Email Subject"));
        TempTask."File Name" := CopyStr(Source.GetFileName(), 1, MaxStrLen(TempTask."File Name"));
        TempTask."Has Pdf" := Source.HasPdf();
        TempTask."Sender Name" := CopyStr(Source.GetSenderName(), 1, MaxStrLen(TempTask."Sender Name"));
        TempTask."Email Received At" := Source.GetEmailReceivedAt();
        TempTask."Email External Id" := CopyStr(Source.GetEmailExternalId(), 1, MaxStrLen(TempTask."Email External Id"));
        TempTask.State := "PA Task State"::Rejected;
        TempTask.Version := Source.GetVersion();
        TempTask."Intake Status" := Source.GetIntakeStatus();
        TempTask."Rejection Reason" := CopyStr(Source.GetRejectionReason(), 1, MaxStrLen(TempTask."Rejection Reason"));
        TempTask.Name := CopyStr(StrSubstNo(RejectedSourceNameTxt, RowNo), 1, MaxStrLen(TempTask.Name));
        PopulateDescriptions(TempTask);
    end;

    internal procedure DrillDownByState(State: Enum "PA Task State")
    var
        TempTasks: Record "PA Detailed Task" temporary;
        Tasks: Codeunit "PA Task Collection";
        TasksPage: Page "Payables Agent Tasks";
        SourceIds: List of [Guid];
        TaskIds: List of [BigInteger];
    begin
        if State = "PA Task State"::Rejected then begin
            Tasks.GetRejectedSourceIds(SourceIds);
            InsertRejectedSources(TempTasks, SourceIds);
        end else begin
            Tasks.GetTaskIdsByState(State, TaskIds);
            InsertTasks(TempTasks, TaskIds);
        end;
        TasksPage.SetTasks(TempTasks);
        TasksPage.Run();
    end;

    internal procedure GetMessagePageId(MessageId: Guid): Integer
    var
        Message: Record "Agent Task Message";
        Task: Codeunit "Payables Agent Task";
    begin
        Message.SetRange(ID, MessageId);
        if not Message.FindFirst() then
            exit(0);
        if not Task.Load(Message."Task ID") then
            exit(0);
        case Task.GetSourceType() of
            "PA Source Type"::Email:
                exit(Page::"PA Agent Email Task");
            "PA Source Type"::Upload:
                exit(Page::"PA Agent Upload Task");
        end;
        exit(0);
    end;

    internal procedure OpenSource(var Task: Codeunit "Payables Agent Task")
    begin
        if AgentExperience.IsActive() and Task.CanExtractText() then begin
            ShowSourceText(Task);
            exit;
        end;
        if Task.GetSourceType() = "PA Source Type"::Email then
            OpenSourceEmail(Task)
        else
            OpenSourcePdf(Task);
    end;

    internal procedure OpenSourceEmail(Task: Codeunit "Payables Agent Task")
    var
        EmailPage: Page "PA Email Review";
    begin
        if Task.GetSourceType() <> "PA Source Type"::Email then
            Error(SourceNotAvailableErr);
        EmailPage.SetTask(Task);
        EmailPage.Run();
    end;

    internal procedure OpenSourcePdf(Task: Codeunit "Payables Agent Task")
    begin
        if not Task.HasPdf() then
            Error(SourceNotAvailableErr);
        ViewSourcePdf(Task);
    end;

    internal procedure ViewSourcePdf(Task: Codeunit "Payables Agent Task")
    var
        Blob: Codeunit "Temp Blob";
        Stream: InStream;
        FileName: Text;
    begin
        if not Task.GetSourcePdf(Blob, FileName) then
            Error(SourceNotAvailableErr);
        Blob.CreateInStream(Stream);
        if File.ViewFromStream(Stream, FileName, true) then
            exit;
        DownloadSourcePdf(Task);
    end;

    internal procedure DownloadSourcePdf(Task: Codeunit "Payables Agent Task")
    var
        Blob: Codeunit "Temp Blob";
        Stream: InStream;
        FileName: Text;
    begin
        if not Task.GetSourcePdf(Blob, FileName) then
            Error(SourceNotAvailableErr);
        Blob.CreateInStream(Stream);
        DownloadFromStream(Stream, '', '', '', FileName);
    end;

    internal procedure GetEmailWebLink(Task: Codeunit "Payables Agent Task"): Text
    var
        ExternalId: Text;
    begin
        ExternalId := Task.GetEmailExternalId();
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

    internal procedure ExtractSourceText(var Task: Codeunit "Payables Agent Task")
    begin
        if not Task.CanExtractText() then
            Error(SourceNotAvailableErr);
        if Task.GetSourceText() <> '' then
            if not Confirm(ReplaceSourceTextQst, false) then
                exit;
        ExtractAndShowSourceText(Task);
    end;

    local procedure ShowSourceText(var Task: Codeunit "Payables Agent Task")
    var
        SourceText: Text;
    begin
        SourceText := Task.GetSourceText();
        if SourceText <> '' then begin
            Message(SourceTextMsg, SourceText);
            exit;
        end;
        if not Task.CanExtractText() then begin
            Message(SourceTextUnavailableMsg);
            exit;
        end;
        if not Confirm(ExtractSourceTextQst, false) then
            exit;
        ExtractAndShowSourceText(Task);
    end;

    local procedure ExtractAndShowSourceText(var Task: Codeunit "Payables Agent Task")
    var
        PdfTextExtraction: Codeunit "PA PDF Text Extraction";
    begin
        PdfTextExtraction.ExtractText(Task);
        Message(SourceTextMsg, Task.GetSourceText());
    end;

    internal procedure OpenOutcome(Task: Codeunit "Payables Agent Task")
    var
        PageManagement: Codeunit "Page Management";
        Outcome: RecordId;
        OutcomeRef: RecordRef;
    begin
        Outcome := Task.GetOutcome();
        if Outcome.TableNo = 0 then
            Error(NoOutcomeErr);
        if not OutcomeRef.Get(Outcome) then
            Error(NoOutcomeErr);
        PageManagement.PageRun(OutcomeRef);
    end;

    local procedure InsertTasks(var TempTasks: Record "PA Detailed Task" temporary; TaskIds: List of [BigInteger])
    var
        Task: Codeunit "Payables Agent Task";
        TaskId: BigInteger;
    begin
        foreach TaskId in TaskIds do
            if Task.Load(TaskId) then begin
                TempTasks.Init();
                TempTasks."Entry No." := TempTasks.Count() + 1;
                PopulateListRow(TempTasks, Task);
                TempTasks.Insert();
            end;
    end;

    local procedure InsertRejectedSources(var TempTasks: Record "PA Detailed Task" temporary; SourceIds: List of [Guid])
    var
        Source: Codeunit "PA Task Source";
        SourceId: Guid;
    begin
        foreach SourceId in SourceIds do
            if Source.Load(SourceId) then begin
                TempTasks.Init();
                TempTasks."Entry No." := TempTasks.Count() + 1;
                PopulateRejectedSourceRow(TempTasks, Source);
                TempTasks.Insert();
            end;
    end;

    local procedure ClearTaskRow(var TempTask: Record "PA Detailed Task" temporary)
    var
        RowNo: BigInteger;
    begin
        RowNo := TempTask."Entry No.";
        Clear(TempTask);
        TempTask."Entry No." := RowNo;
    end;

    local procedure PopulateDescriptions(var TempTask: Record "PA Detailed Task" temporary)
    begin
        TempTask."Source Description" := CopyStr(DescribeSource(TempTask), 1, MaxStrLen(TempTask."Source Description"));
        TempTask."Result Description" := CopyStr(DescribeOutcome(TempTask.Outcome), 1, MaxStrLen(TempTask."Result Description"));
        TempTask."Vendor No." := OutcomeVendorNo(TempTask.Outcome);
    end;

    local procedure DescribeSource(Data: Record "PA Detailed Task"): Text
    begin
        if Data."Source Type" = "PA Source Type"::Email then
            exit(StrSubstNo(EmailSourceTxt, Data."Email From", Data."Email Subject"));
        if Data."Has Pdf" then
            exit(StrSubstNo(PdfSourceTxt, Data."File Name"));
        exit('');
    end;

    local procedure DescribeOutcome(Outcome: RecordId): Text
    var
        PurchaseHeader: Record "Purchase Header";
        PostedInvoice: Record "Purch. Inv. Header";
        PostedCreditMemo: Record "Purch. Cr. Memo Hdr.";
    begin
        case Outcome.TableNo of
            0:
                exit('');
            Database::"Purchase Header":
                if PurchaseHeader.Get(Outcome) then
                    exit(StrSubstNo(PurchaseDocumentTxt, PurchaseHeader."Document Type", PurchaseHeader."No."));
            Database::"Purch. Inv. Header":
                if PostedInvoice.Get(Outcome) then
                    exit(StrSubstNo(PostedInvoiceTxt, PostedInvoice."No."));
            Database::"Purch. Cr. Memo Hdr.":
                if PostedCreditMemo.Get(Outcome) then
                    exit(StrSubstNo(PostedCreditMemoTxt, PostedCreditMemo."No."));
        end;
        exit(Format(Outcome));
    end;

    local procedure OutcomeVendorNo(Outcome: RecordId): Code[20]
    var
        PurchaseHeader: Record "Purchase Header";
        PostedInvoice: Record "Purch. Inv. Header";
        PostedCreditMemo: Record "Purch. Cr. Memo Hdr.";
    begin
        case Outcome.TableNo of
            Database::"Purchase Header":
                if PurchaseHeader.Get(Outcome) then
                    exit(PurchaseHeader."Buy-from Vendor No.");
            Database::"Purch. Inv. Header":
                if PostedInvoice.Get(Outcome) then
                    exit(PostedInvoice."Buy-from Vendor No.");
            Database::"Purch. Cr. Memo Hdr.":
                if PostedCreditMemo.Get(Outcome) then
                    exit(PostedCreditMemo."Buy-from Vendor No.");
        end;
        exit('');
    end;
}
