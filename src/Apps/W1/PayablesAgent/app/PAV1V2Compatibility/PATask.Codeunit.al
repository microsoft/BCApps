// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.Agent.PayablesAgent;

using Microsoft.eServices.EDocument;
using Microsoft.Purchases.Document;
using Microsoft.Utilities;
using System.Agents;
using System.Email;
using System.Utilities;

/// <summary>
/// SDK for a single Payables Agent task. An instance holds one loaded task (see the Load procedures) and exposes what
/// can be read about it and done with it, adapting to whether the task is backed by an e-document (v1) or a Payables
/// Agent task (v2). Together with "PA Task Collection" and "PA Setup", the only code that branches on "PA V1V2 Flag".
/// </summary>
codeunit 3341 "PA Task"
{
    Access = Internal;
    InherentEntitlements = X;
    InherentPermissions = X;
    Permissions = tabledata "Agent Task" = R, tabledata "Agent Task Message" = R, tabledata "E-Document" = R, tabledata "E-Doc. Data Storage" = R, tabledata "Email Inbox" = R, tabledata "Payables Agent Task" = R, tabledata "Payables Agent Task Source" = R, tabledata "Payables Agent Task Data" = R;

    var
        TempLoadedTask: Record "PA Detailed Task" temporary;
        LoadedEDocument: Record "E-Document";
        PAV1V2Flag: Codeunit "PA V1V2 Flag";
        EmailFromTxt: Label '%1 <%2>', Comment = '%1 = sender name, %2 = sender email address';
        EmailSourceTxt: Label 'Email from %1: %2', Comment = '%1 = sender, %2 = email subject';
        PdfSourceTxt: Label 'PDF file %1', Comment = '%1 = file name';
        PurchaseDocumentTxt: Label 'Purchase %1 %2', Comment = '%1 = purchase document type, such as Invoice, %2 = document number';
        TaskTitleLbl: Label 'Invoice %1 from %2', Comment = '%1 is the invoice number, %2 is the vendor name.';
        NoOutcomeErr: Label 'This task has no outcome to open.';
        SourceNotAvailableErr: Label 'The source of this task is no longer available.';
        TaskNotFoundErr: Label 'The task does not exist.';
        OutlookWebLinkTok: Label 'https://outlook.office365.com/owa/?ItemID=%1&exvsurl=1&viewmodel=ReadMessageItem', Locked = true;

    #region Load

    /// <summary>
    /// Loads the task worked on by an agent task.
    /// </summary>
    /// <returns>False when no task is bound to the agent task; the instance is then empty (typed as an upload).</returns>
    internal procedure Load(AgentTaskId: BigInteger): Boolean
    var
        PayablesAgentTask: Record "Payables Agent Task";
        EDocument: Record "E-Document";
    begin
        ClearLoaded();
        if AgentTaskId = 0 then
            exit(false);

        if PAV1V2Flag.IsV2Active() then begin
            PayablesAgentTask.SetCurrentKey("Agent Task ID");
            PayablesAgentTask.SetRange("Agent Task ID", AgentTaskId);
            if not PayablesAgentTask.FindFirst() then
                exit(false);
            PopulateFromPayablesAgentTask(PayablesAgentTask);
            exit(true);
        end;

        if not TryGetEDocumentForAgentTask(AgentTaskId, EDocument) then
            exit(false);
        PopulateFromEDocument(EDocument);
        TempLoadedTask."Agent Task ID" := AgentTaskId;
        PopulateAgentTaskStatus();
        exit(true);
    end;

    /// <summary>
    /// Loads the task worked on by the current Payables Agent session.
    /// </summary>
    /// <returns>False when the session is not a Payables Agent session or no task is bound to it.</returns>
    internal procedure LoadCurrentSession(): Boolean
    var
        PayablesAgent: Codeunit "Payables Agent";
        AgentTaskId: BigInteger;
    begin
        ClearLoaded();
        if not PayablesAgent.IsPayablesAgentSession(AgentTaskId) then
            exit(false);
        exit(Load(AgentTaskId));
    end;

    /// <summary>
    /// Loads a task already resolved into an enriched record, such as a row of a task list.
    /// </summary>
    internal procedure LoadFromRecord(PADetailedTask: Record "PA Detailed Task")
    begin
        ClearLoaded();
        TempLoadedTask.TransferFields(PADetailedTask);
    end;

    /// <summary>
    /// Loads a Payables Agent task (v2). For use by the facades only.
    /// </summary>
    internal procedure LoadFromPayablesAgentTask(PayablesAgentTask: Record "Payables Agent Task")
    begin
        ClearLoaded();
        PopulateFromPayablesAgentTask(PayablesAgentTask);
    end;

    /// <summary>
    /// v1 bridge for the e-document pipeline: loads an e-document as a task before an agent task exists for it (for
    /// example while deciding whether and how to create the agent task). Not for use under v2.
    /// </summary>
    internal procedure LoadForEDocument(EDocument: Record "E-Document")
    begin
        ClearLoaded();
        PopulateFromEDocument(EDocument);
    end;

    /// <summary>
    /// Re-reads the loaded task from where it is persisted.
    /// </summary>
    internal procedure Refresh()
    var
        PayablesAgentTask: Record "Payables Agent Task";
        EDocument: Record "E-Document";
    begin
        if PAV1V2Flag.IsV2Active() then begin
            if PayablesAgentTask.Get(TempLoadedTask."Entry No.") then
                LoadFromPayablesAgentTask(PayablesAgentTask);
            exit;
        end;
        if TempLoadedTask."Agent Task ID" <> 0 then begin
            if Load(TempLoadedTask."Agent Task ID") then;
            exit;
        end;
        if TryGetEDocumentFromRecordId(TempLoadedTask."Source Record Id", EDocument) then
            LoadForEDocument(EDocument);
    end;

    #endregion

    #region Read

    /// <summary>
    /// Copies the loaded task into an enriched record.
    /// </summary>
    internal procedure GetRecord(var PADetailedTask: Record "PA Detailed Task")
    begin
        PADetailedTask.TransferFields(TempLoadedTask);
    end;

    internal procedure GetAgentTaskId(): BigInteger
    begin
        exit(TempLoadedTask."Agent Task ID");
    end;

    internal procedure GetSourceType(): Enum "PA Agent Source Type"
    begin
        exit(TempLoadedTask."Source Type");
    end;

    /// <summary>
    /// The record the task is backed by: the e-document (v1) or the Payables Agent task (v2).
    /// </summary>
    internal procedure GetSourceRecordId(): RecordId
    begin
        exit(TempLoadedTask."Source Record Id");
    end;

    internal procedure HasPdf(): Boolean
    begin
        exit(TempLoadedTask."Has Pdf");
    end;

    internal procedure GetFileName(): Text
    begin
        exit(TempLoadedTask."File Name");
    end;

    /// <summary>
    /// The sender of the source email as "Name &lt;address&gt;". Blank when there is no email.
    /// </summary>
    internal procedure GetEmailFrom(): Text
    begin
        exit(TempLoadedTask."Email From");
    end;

    internal procedure GetEmailSubject(): Text
    begin
        exit(TempLoadedTask."Email Subject");
    end;

    /// <summary>
    /// The sender address of the source email, read from the Email module. Blank when there is no email inbox
    /// attached or the inbox row is no longer available.
    /// </summary>
    internal procedure GetSenderAddress(): Text[250]
    var
        EmailInbox: Record "Email Inbox";
    begin
        if TempLoadedTask."Email Inbox Id" = 0 then
            exit('');
        EmailInbox.SetLoadFields("Sender Address");
        if not EmailInbox.Get(TempLoadedTask."Email Inbox Id") then
            exit('');
        exit(CopyStr(EmailInbox."Sender Address", 1, 250));
    end;

    /// <summary>
    /// Body of the source email, read live from the Email module. Blank when there is no email or it is gone.
    /// </summary>
    internal procedure GetSourceEmailBody(): Text
    var
        EmailInbox: Record "Email Inbox";
        EmailMessage: Codeunit "Email Message";
    begin
        if TempLoadedTask."Email Inbox Id" = 0 then
            exit('');
        if not EmailInbox.Get(TempLoadedTask."Email Inbox Id") then
            exit('');
        if EmailMessage.Get(EmailInbox."Message Id") then
            exit(EmailMessage.GetBody());
        exit('');
    end;

    /// <summary>
    /// Outlook on the web link of the source email. Blank when there is no email or no external message id.
    /// </summary>
    internal procedure GetSourceEmailWebLink(): Text
    var
        EmailInbox: Record "Email Inbox";
    begin
        if TempLoadedTask."Email Inbox Id" = 0 then
            exit('');
        EmailInbox.SetLoadFields("External Message Id");
        if not EmailInbox.Get(TempLoadedTask."Email Inbox Id") then
            exit('');
        if EmailInbox."External Message Id" = '' then
            exit('');
        exit(StrSubstNo(OutlookWebLinkTok, EmailInbox."External Message Id"));
    end;

    /// <summary>
    /// Reads a header of the source email. Under v1 the email is the one stored on the e-document
    /// ("Mail Message Id"); under v2 it is the one of the task's email inbox row.
    /// </summary>
    /// <returns>False when there is no email, it is gone, or it has no such header.</returns>
    internal procedure TryGetEmailHeader(HeaderName: Text; var HeaderValue: Text): Boolean
    var
        EmailInbox: Record "Email Inbox";
        EDocument: Record "E-Document";
        EmailMessage: Codeunit "Email Message";
        MessageId: Guid;
    begin
        if PAV1V2Flag.IsV2Active() then begin
            if TempLoadedTask."Email Inbox Id" = 0 then
                exit(false);
            EmailInbox.SetLoadFields("Message Id");
            if not EmailInbox.Get(TempLoadedTask."Email Inbox Id") then
                exit(false);
            MessageId := EmailInbox."Message Id";
        end else begin
            if not GetLoadedEDocument(EDocument) then
                exit(false);
            MessageId := EDocument."Mail Message Id";
        end;
        if IsNullGuid(MessageId) then
            exit(false);
        if not EmailMessage.Get(MessageId) then
            exit(false);
        exit(EmailMessage.GetHeader(HeaderName, HeaderValue));
    end;

    /// <summary>
    /// Copies the source PDF content from where it is persisted.
    /// </summary>
    /// <returns>False when the task has no source PDF.</returns>
    internal procedure GetSourcePdf(var TempBlob: Codeunit "Temp Blob"; var FileName: Text): Boolean
    var
        EDocument: Record "E-Document";
        EDocumentDataStorage: Record "E-Doc. Data Storage";
        PayablesAgentTaskData: Record "Payables Agent Task Data";
    begin
        if TempLoadedTask."Task Data No." <> 0 then begin
            if not PayablesAgentTaskData.Get(TempLoadedTask."Task Data No.") then
                exit(false);
            if not PayablesAgentTaskData."File Content".HasValue() then
                exit(false);
            PayablesAgentTaskData.GetFileContent(TempBlob);
            FileName := PayablesAgentTaskData."File Name";
            exit(true);
        end;
        if not GetLoadedEDocument(EDocument) then
            exit(false);
        EDocumentDataStorage.ReadIsolation := IsolationLevel::ReadUncommitted;
        if not EDocumentDataStorage.Get(EDocument."Unstructured Data Entry No.") then
            exit(false);
        TempBlob := EDocumentDataStorage.GetTempBlob();
        FileName := EDocumentDataStorage.Name;
        exit(true);
    end;

    /// <summary>
    /// Describes what the task came from. An email source takes precedence over the PDF.
    /// </summary>
    internal procedure DescribeSource(): Text
    var
        PayablesAgentTask: Record "Payables Agent Task";
        PATaskMgt: Codeunit "PA Task Mgt.";
    begin
        if PAV1V2Flag.IsV2Active() then begin
            if not PayablesAgentTask.Get(TempLoadedTask."Entry No.") then
                exit('');
            exit(PATaskMgt.DescribeSource(PayablesAgentTask));
        end;
        if TempLoadedTask."Source Type" = "PA Agent Source Type"::Email then
            exit(StrSubstNo(EmailSourceTxt, TempLoadedTask."Email From", TempLoadedTask."Email Subject"));
        if TempLoadedTask."File Name" <> '' then
            exit(StrSubstNo(PdfSourceTxt, TempLoadedTask."File Name"));
        exit('');
    end;

    /// <summary>
    /// Describes the record registered as the task outcome. Blank when there is no outcome.
    /// </summary>
    internal procedure DescribeOutcome(): Text
    var
        PurchaseHeader: Record "Purchase Header";
    begin
        if TempLoadedTask.Outcome.TableNo = 0 then
            exit('');
        if TempLoadedTask.Outcome.TableNo <> Database::"Purchase Header" then
            exit(Format(TempLoadedTask.Outcome));

        PurchaseHeader.SetLoadFields("Document Type", "No.");
        if not PurchaseHeader.Get(TempLoadedTask.Outcome) then
            exit(Format(TempLoadedTask.Outcome));
        exit(StrSubstNo(PurchaseDocumentTxt, PurchaseHeader."Document Type", PurchaseHeader."No."));
    end;

    #endregion

    #region Act

    /// <summary>
    /// Opens what the task came from. A task that came from an email opens the email.
    /// </summary>
    internal procedure OpenSource()
    var
        PayablesAgentTask: Record "Payables Agent Task";
        PATaskMgt: Codeunit "PA Task Mgt.";
    begin
        if PAV1V2Flag.IsV2Active() then begin
            if PayablesAgentTask.Get(TempLoadedTask."Entry No.") then
                PATaskMgt.OpenSource(PayablesAgentTask);
            exit;
        end;
        if TempLoadedTask."Source Type" = "PA Agent Source Type"::Email then
            OpenSourceEmail()
        else
            OpenSourcePdf();
    end;

    /// <summary>
    /// Opens the email the task came from: the email review page (v2) or Outlook on the web (v1).
    /// </summary>
    internal procedure OpenSourceEmail()
    var
        PayablesAgentTask: Record "Payables Agent Task";
        PATaskMgt: Codeunit "PA Task Mgt.";
        WebLink: Text;
    begin
        if PAV1V2Flag.IsV2Active() then begin
            if not PayablesAgentTask.Get(TempLoadedTask."Entry No.") then
                Error(SourceNotAvailableErr);
            PATaskMgt.OpenSourceEmail(PayablesAgentTask);
            exit;
        end;
        WebLink := GetSourceEmailWebLink();
        if WebLink = '' then
            Error(SourceNotAvailableErr);
        Hyperlink(WebLink);
    end;

    /// <summary>
    /// Opens the source PDF in a page: the PDF viewer (v2) or the client file viewer (v1).
    /// </summary>
    internal procedure OpenSourcePdf()
    var
        PayablesAgentTask: Record "Payables Agent Task";
        PATaskMgt: Codeunit "PA Task Mgt.";
    begin
        if PAV1V2Flag.IsV2Active() then begin
            if not PayablesAgentTask.Get(TempLoadedTask."Entry No.") then
                Error(SourceNotAvailableErr);
            PATaskMgt.OpenSourcePdf(PayablesAgentTask);
            exit;
        end;
        ViewSourcePdf();
    end;

    /// <summary>
    /// Opens the source PDF in the client file viewer, from where it is persisted.
    /// </summary>
    internal procedure ViewSourcePdf()
    var
        EDocument: Record "E-Document";
        PayablesAgentTaskData: Record "Payables Agent Task Data";
    begin
        if TempLoadedTask."Task Data No." <> 0 then begin
            if PayablesAgentTaskData.Get(TempLoadedTask."Task Data No.") then
                PayablesAgentTaskData.ViewFileContent();
            exit;
        end;
        if GetLoadedEDocument(EDocument) then
            EDocument.ViewSourceFile();
    end;

    /// <summary>
    /// Downloads the source PDF from where it is persisted.
    /// </summary>
    internal procedure DownloadSourcePdf()
    var
        EDocument: Record "E-Document";
        PayablesAgentTaskData: Record "Payables Agent Task Data";
    begin
        if TempLoadedTask."Task Data No." <> 0 then begin
            if PayablesAgentTaskData.Get(TempLoadedTask."Task Data No.") then
                PayablesAgentTaskData.DownloadFileContent();
            exit;
        end;
        if GetLoadedEDocument(EDocument) then
            EDocument.ViewSourceFile();
    end;

    /// <summary>
    /// Registers the record the task produced as its outcome, and refreshes the loaded task. Under v1 the outcome is
    /// the e-document's purchase draft, so nothing is registered.
    /// </summary>
    internal procedure RegisterOutcome(OutcomeRecordId: RecordId)
    var
        PayablesAgentTask: Record "Payables Agent Task";
        PATaskMgt: Codeunit "PA Task Mgt.";
    begin
        if not PAV1V2Flag.IsV2Active() then
            exit;
        if not PayablesAgentTask.Get(TempLoadedTask."Entry No.") then
            Error(TaskNotFoundErr);
        PATaskMgt.RegisterOutcome(PayablesAgentTask, OutcomeRecordId);
        Refresh();
    end;

    /// <summary>
    /// Opens the default page of the record registered as the task outcome.
    /// </summary>
    internal procedure OpenOutcome()
    var
        PageManagement: Codeunit "Page Management";
        OutcomeRecordRef: RecordRef;
    begin
        if TempLoadedTask.Outcome.TableNo = 0 then
            Error(NoOutcomeErr);
        if not OutcomeRecordRef.Get(TempLoadedTask.Outcome) then
            Error(NoOutcomeErr);
        PageManagement.PageRun(OutcomeRecordRef);
    end;

    /// <summary>
    /// Marks the task as completed, and refreshes the loaded task. Under v1 completion is tracked by the e-document,
    /// so nothing is recorded.
    /// </summary>
    internal procedure Complete()
    var
        PayablesAgentTask: Record "Payables Agent Task";
        PATaskMgt: Codeunit "PA Task Mgt.";
    begin
        if not PAV1V2Flag.IsV2Active() then
            exit;
        if not PayablesAgentTask.Get(TempLoadedTask."Entry No.") then
            Error(TaskNotFoundErr);
        PATaskMgt.Complete(PayablesAgentTask);
        Refresh();
    end;

    /// <summary>
    /// Adds the sender of the loaded task to the known-senders list if it is not there yet.
    /// </summary>
    internal procedure RecordKnownSender()
    var
        PAKnownSender: Record "PA Known Sender";
    begin
        PAKnownSender.InsertIfNew(this);
    end;

    #endregion

    #region Not bound to a loaded task

    /// <summary>
    /// Creates a task for an uploaded PDF and hands it to the agent.
    /// </summary>
    internal procedure CreateTaskFromPdf(FileName: Text; PdfInStream: InStream)
    var
        EDocument: Record "E-Document";
        PayablesAgentTask: Record "Payables Agent Task";
        PADraftBasedSetup: Codeunit "PA Draft Based Setup";
        PATaskMgt: Codeunit "PA Task Mgt.";
        EDocImport: Codeunit "E-Doc. Import";
    begin
        if PAV1V2Flag.IsV2Active() then begin
            // TODOPAV2: create the agent task for the new Payables Agent task once v2 ingestion is wired.
            PATaskMgt.CreateTask(CopyStr(FileName, 1, 250), PdfInStream, PayablesAgentTask);
            exit;
        end;
        EDocImport.CreateFromType(EDocument, PADraftBasedSetup.GetOrCreateAgentEDocumentService(), "E-Doc. File Format"::PDF, FileName, PdfInStream);
        EDocument."Source Details" := CopyStr(FileName, 1, MaxStrLen(EDocument."Source Details"));
        EDocument.Modify();
        EDocImport.ProcessAutomaticallyIncomingEDocument(EDocument);
    end;

    /// <summary>
    /// Page shown for an agent task message: the email review card for an email-sourced task, otherwise the
    /// uploaded-PDF card.
    /// </summary>
    internal procedure GetMessagePageId(MessageId: Guid): Integer
    var
        AgentTaskMessage: Record "Agent Task Message";
        PATask: Codeunit "PA Task";
    begin
        AgentTaskMessage.SetRange(ID, MessageId);
        if not AgentTaskMessage.FindFirst() then
            exit(0);
        if PATask.Load(AgentTaskMessage."Task ID") then;
        case PATask.GetSourceType() of
            "PA Agent Source Type"::Email:
                exit(Page::"PA Agent Email Task");
            "PA Agent Source Type"::Upload:
                exit(Page::"PA Agent Upload Task");
        end;
        exit(0);
    end;

    /// <summary>
    /// Sets the title of an agent task from the invoice it works on.
    /// </summary>
    internal procedure SetTitle(AgentTaskId: BigInteger; InvoiceNo: Text[50]; VendorName: Text[100])
    var
        AgentTask: Record "Agent Task";
    begin
        if AgentTask.Get(AgentTaskId) then begin
            AgentTask.Title := CopyStr(StrSubstNo(TaskTitleLbl, InvoiceNo, VendorName), 1, MaxStrLen(AgentTask.Title));
            AgentTask.Modify(true);
        end;
    end;

    /// <summary>
    /// Whether the e-document import pipeline is what feeds the agent (v1). The draft-based e-document subscribers
    /// stay inert when this returns false.
    /// </summary>
    internal procedure IsEDocumentPipelineActive(): Boolean
    begin
        exit(not PAV1V2Flag.IsV2Active());
    end;

    #endregion

    #region Private

    local procedure ClearLoaded()
    begin
        Clear(TempLoadedTask);
        Clear(LoadedEDocument);
        TempLoadedTask."Source Type" := "PA Agent Source Type"::Upload;
    end;

    /// <summary>
    /// The e-document backing the loaded task (v1): the one it was loaded with, else the one its source record id
    /// points to.
    /// </summary>
    local procedure GetLoadedEDocument(var EDocument: Record "E-Document"): Boolean
    begin
        if LoadedEDocument."Entry No" <> 0 then begin
            EDocument := LoadedEDocument;
            exit(true);
        end;
        exit(TryGetEDocumentFromRecordId(TempLoadedTask."Source Record Id", EDocument));
    end;

    local procedure PopulateFromPayablesAgentTask(PayablesAgentTask: Record "Payables Agent Task")
    var
        PayablesAgentTaskSource: Record "Payables Agent Task Source";
        PayablesAgentTaskData: Record "Payables Agent Task Data";
    begin
        TempLoadedTask.TransferFields(PayablesAgentTask);
        TempLoadedTask."Source Record Id" := PayablesAgentTask.RecordId();
        TempLoadedTask."Has Pdf" := PayablesAgentTask."Task Data No." <> 0;
        if PayablesAgentTask."Source Data No." <> 0 then
            TempLoadedTask."Source Type" := "PA Agent Source Type"::Email
        else
            TempLoadedTask."Source Type" := "PA Agent Source Type"::Upload;
        if PayablesAgentTaskData.Get(PayablesAgentTask."Task Data No.") then
            TempLoadedTask."File Name" := PayablesAgentTaskData."File Name";
        if PayablesAgentTaskSource.Get(PayablesAgentTask."Source Data No.") then begin
            TempLoadedTask."Email Inbox Id" := PayablesAgentTaskSource."Email Inbox Id";
            PopulateEmail();
        end;
        TempLoadedTask."Vendor No." := GetOutcomeVendorNo();
        PopulateAgentTaskStatus();
    end;

    local procedure PopulateFromEDocument(EDocument: Record "E-Document")
    var
        EDocumentDataStorage: Record "E-Doc. Data Storage";
    begin
        LoadedEDocument := EDocument;
        TempLoadedTask."Entry No." := EDocument."Entry No";
        TempLoadedTask."Source Record Id" := EDocument.RecordId();
        TempLoadedTask."File Name" := CopyStr(EDocument."Source Details", 1, MaxStrLen(TempLoadedTask."File Name"));
        if (EDocument."Unstructured Data Entry No." <> 0) and EDocumentDataStorage.Get(EDocument."Unstructured Data Entry No.") then
            TempLoadedTask."Has Pdf" := EDocumentDataStorage."File Format" = Enum::"E-Doc. File Format"::PDF;

        if EDocument."Outlook Mail Message Id" = '' then begin
            TempLoadedTask."Source Type" := "PA Agent Source Type"::Upload;
            exit;
        end;
        TempLoadedTask."Source Type" := "PA Agent Source Type"::Email;
        // Email is read from the Email module in both versions. For v1 the inbox row the connector created is
        // resolved by the external (Outlook) message id stored on the e-document.
        TempLoadedTask."Email Inbox Id" := ResolveEmailInboxId(EDocument."Outlook Mail Message Id");
        PopulateEmail();
    end;

    local procedure PopulateEmail()
    var
        EmailInbox: Record "Email Inbox";
    begin
        if TempLoadedTask."Email Inbox Id" = 0 then
            exit;
        if not EmailInbox.Get(TempLoadedTask."Email Inbox Id") then
            exit;
        TempLoadedTask."Email From" := CopyStr(StrSubstNo(EmailFromTxt, EmailInbox."Sender Name", EmailInbox."Sender Address"), 1, MaxStrLen(TempLoadedTask."Email From"));
        TempLoadedTask."Email Subject" := CopyStr(EmailInbox.Description, 1, MaxStrLen(TempLoadedTask."Email Subject"));
    end;

    local procedure PopulateAgentTaskStatus()
    var
        AgentTask: Record "Agent Task";
    begin
        Clear(TempLoadedTask."Agent Task Status");
        if TempLoadedTask."Agent Task ID" = 0 then
            exit;
        AgentTask.SetLoadFields(Status);
        if AgentTask.Get(TempLoadedTask."Agent Task ID") then
            TempLoadedTask."Agent Task Status" := AgentTask.Status;
    end;

    /// <summary>
    /// The vendor of the Purchase Invoice registered as the outcome. Blank for any other outcome.
    /// </summary>
    local procedure GetOutcomeVendorNo(): Code[20]
    var
        PurchaseHeader: Record "Purchase Header";
    begin
        if TempLoadedTask.Outcome.TableNo <> Database::"Purchase Header" then
            exit('');
        PurchaseHeader.SetLoadFields("Document Type", "Buy-from Vendor No.");
        if not PurchaseHeader.Get(TempLoadedTask.Outcome) then
            exit('');
        if PurchaseHeader."Document Type" <> PurchaseHeader."Document Type"::Invoice then
            exit('');
        exit(PurchaseHeader."Buy-from Vendor No.");
    end;

    /// <summary>
    /// The e-document an agent task works on (v1): the first message of the task carries the e-document entry
    /// number as its external id.
    /// </summary>
    local procedure TryGetEDocumentForAgentTask(AgentTaskId: BigInteger; var EDocument: Record "E-Document"): Boolean
    var
        AgentTaskMessage: Record "Agent Task Message";
        EDocumentEntryNo: Integer;
    begin
        AgentTaskMessage.SetRange("Task ID", AgentTaskId);
        AgentTaskMessage.SetFilter("External ID", '<>%1', '');
        if not AgentTaskMessage.FindFirst() then
            exit(false);
        if not Evaluate(EDocumentEntryNo, AgentTaskMessage."External ID") then
            exit(false);
        exit(EDocument.Get(EDocumentEntryNo));
    end;

    local procedure TryGetEDocumentFromRecordId(SourceRecordId: RecordId; var EDocument: Record "E-Document"): Boolean
    var
        RecRef: RecordRef;
    begin
        if SourceRecordId.TableNo() <> Database::"E-Document" then
            exit(false);
        if not RecRef.Get(SourceRecordId) then
            exit(false);
        RecRef.SetTable(EDocument);
        exit(true);
    end;

    /// <summary>
    /// The surviving Email Inbox row for an external (Outlook) message id: the lowest Id among rows that share it.
    /// Returns 0 when no row remains.
    /// </summary>
    local procedure ResolveEmailInboxId(ExternalMessageId: Text): BigInteger
    var
        EmailInbox: Record "Email Inbox";
    begin
        if ExternalMessageId = '' then
            exit(0);
        EmailInbox.ReadIsolation(IsolationLevel::ReadCommitted);
        EmailInbox.SetCurrentKey(Id);
        EmailInbox.SetAscending(Id, true);
        EmailInbox.SetRange("External Message Id", CopyStr(ExternalMessageId, 1, MaxStrLen(EmailInbox."External Message Id")));
        EmailInbox.SetLoadFields(Id);
        if EmailInbox.FindFirst() then
            exit(EmailInbox.Id);
        exit(0);
    end;

    #endregion
}
