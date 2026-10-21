// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.Agent.PayablesAgent;

using Microsoft.Purchases.Document;
using Microsoft.Purchases.History;
using Microsoft.Utilities;
using System.Agents;
using System.Utilities;

// Interprets the shared task data contract for pages; it never receives a task backing record.
codeunit 3330 "PA Task Presentation"
{
    Access = Internal;
    InherentEntitlements = X;
    InherentPermissions = X;
    Permissions = tabledata "Agent Task" = R, tabledata "Agent Task Message" = R;

    internal procedure GetTasks(var TempTasks: Record "PA Detailed Task" temporary)
    var
        Tasks: Codeunit "PA Task Collection";
    begin
        Tasks.GetTasks(TempTasks);
        PopulateRows(TempTasks);
    end;

    internal procedure PopulateListRow(var TempTask: Record "PA Detailed Task" temporary; Task: Codeunit "Payables Agent Task")
    var
        AgentTask: Record "Agent Task";
        RowNo: BigInteger;
    begin
        RowNo := TempTask."Entry No.";
        Task.GetRecord(TempTask);
        TempTask."Entry No." := RowNo;
        TempTask.Name := CopyStr(StrSubstNo(TaskNameTxt, RowNo), 1, MaxStrLen(TempTask.Name));
        if AgentTask.Get(TempTask."Agent Task ID") then
            if AgentTask.Title <> '' then
                TempTask.Name := CopyStr(AgentTask.Title, 1, MaxStrLen(TempTask.Name));
        TempTask."Source Description" := CopyStr(DescribeSource(TempTask), 1, MaxStrLen(TempTask."Source Description"));
        TempTask."Result Description" := CopyStr(DescribeOutcome(TempTask.Outcome), 1, MaxStrLen(TempTask."Result Description"));
        TempTask."Vendor No." := OutcomeVendorNo(TempTask.Outcome);
    end;

    internal procedure DrillDownByState(State: Enum "PA Task State")
    var
        TempTasks: Record "PA Detailed Task" temporary;
        Tasks: Codeunit "PA Task Collection";
        TasksPage: Page "Payables Agent Tasks";
    begin
        Tasks.GetTasksByState(State, TempTasks);
        PopulateRows(TempTasks);
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

    internal procedure OpenSource(Task: Codeunit "Payables Agent Task")
    begin
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
    var
        PdfPage: Page "PDF Viewer";
    begin
        if not Task.HasPdf() then
            Error(SourceNotAvailableErr);
        PdfPage.SetTask(Task);
        PdfPage.Run();
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
        Data: Record "PA Detailed Task" temporary;
    begin
        Task.GetRecord(Data);
        if Data."Email External Id" = '' then
            exit('');
        exit(StrSubstNo(OutlookWebLinkTok, Data."Email External Id"));
    end;

    internal procedure OpenOutcome(Task: Codeunit "Payables Agent Task")
    var
        Data: Record "PA Detailed Task" temporary;
        PageManagement: Codeunit "Page Management";
        OutcomeRef: RecordRef;
    begin
        Task.GetRecord(Data);
        if Data.Outcome.TableNo = 0 then
            Error(NoOutcomeErr);
        if not OutcomeRef.Get(Data.Outcome) then
            Error(NoOutcomeErr);
        PageManagement.PageRun(OutcomeRef);
    end;

    local procedure PopulateRows(var TempTasks: Record "PA Detailed Task" temporary)
    var
        Task: Codeunit "Payables Agent Task";
    begin
        if TempTasks.FindSet() then
            repeat
                if Task.Load(TempTasks."Task Id") then begin
                    PopulateListRow(TempTasks, Task);
                    TempTasks.Modify();
                end;
            until TempTasks.Next() = 0;
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

    var
        TaskNameTxt: Label 'Task %1', Comment = '%1 = list row number';
        EmailSourceTxt: Label 'Email from %1: %2', Comment = '%1 = sender, %2 = subject';
        PdfSourceTxt: Label 'PDF file %1', Comment = '%1 = file name';
        PurchaseDocumentTxt: Label 'Purchase %1 %2', Comment = '%1 = document type, %2 = number';
        PostedInvoiceTxt: Label 'Posted purchase invoice %1', Comment = '%1 = document number';
        PostedCreditMemoTxt: Label 'Posted purchase credit memo %1', Comment = '%1 = document number';
        NoOutcomeErr: Label 'The outcome is no longer available.';
        SourceNotAvailableErr: Label 'The source of this task is no longer available.';
        OutlookWebLinkTok: Label 'https://outlook.office365.com/owa/?ItemID=%1&exvsurl=1&viewmodel=ReadMessageItem', Locked = true;
}
