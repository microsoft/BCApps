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
        SourceNotAvailableTxt: Label 'The source of this task is no longer available.';
        PdfMimeTypeTok: Label 'application/pdf', Locked = true;
        AgentNotActiveErr: Label 'The Payables Agent is not active.', Comment = 'Payables Agent is a term, and should not be translated.';
        UploadTaskTitleLbl: Label 'Uploaded document %1', Comment = '%1 is the file name.';
        UploadTaskMessageLbl: Label 'A new document has been uploaded. Your task is to create a Purchase Invoice in Business Central.', Locked = true;
        EDocumentTaskTitleLbl: Label 'E-Document from %1', Comment = '%1 is the sender''s email address.';
        EDocumentTaskMessageLbl: Label 'A new electronic document %1 has been received. Your task is to create a Purchase Invoice in Business Central.', Locked = true, Comment = '%1 is the e-document entry number.';


    #region Load
    /// <summary>
    /// Loads the task worked on by an agent task.
    /// </summary>
    /// <returns>False when no task is bound to the agent task; the instance is then empty (typed as an upload).</returns>
    internal procedure Load(AgentTaskId: BigInteger): Boolean
    var
        TaskKey: BigInteger;
    begin
        ClearLoaded();
        if not TryGetKeyForAgentTask(AgentTaskId, TaskKey) then
            exit(false);
        exit(LoadByKey(TaskKey));
    end;

    /// <summary>
    /// Loads the task worked on by the current Payables Agent session.
    /// </summary>
    /// <returns>False when the session is not a Payables Agent session or no task is bound to it.</returns>
    internal procedure LoadCurrentSession(): Boolean
    var
        PayablesAgent: Codeunit "Payables Agent Metadata";
        AgentTaskId: BigInteger;
    begin
        ClearLoaded();
        if not PayablesAgent.IsPayablesAgentSession(AgentTaskId) then
            exit(false);
        exit(Load(AgentTaskId));
    end;

    /// <summary>
    /// Loads a task already resolved into an enriched record, such as a row of a task list. Does not read storage;
    /// use Refresh to re-read it.
    /// </summary>
    internal procedure LoadFromRecord(PADetailedTask: Record "PA Detailed Task")
    begin
        ClearLoaded();
        TempLoadedTask.TransferFields(PADetailedTask);
    end;

    /// <summary>
    /// Loads a Payables Agent task (v2).
    /// </summary>
    /// <returns>False under v1, or when the task no longer exists.</returns>
    internal procedure LoadFromPayablesAgentTask(PayablesAgentTask: Record "Payables Agent Task"): Boolean
    begin
        ClearLoaded();
        if not PAV1V2Flag.IsV2Active() then
            exit(false);
        exit(LoadByKey(PayablesAgentTask."Entry No."));
    end;

    /// <summary>
    /// Loads a task by its external id, also before an agent task exists for it. The external id is the one the agent
    /// task carries (see GetAgentTaskExternalId): the e-document entry no. (v1) or the Payables Agent task SystemId (v2).
    /// </summary>
    /// <returns>False when the external id does not identify a task of the active Payables Agent version.</returns>
    internal procedure Load(ExternalId: Text[2048]): Boolean
    var
        PayablesAgentTask: Record "Payables Agent Task";
        PayablesAgentTaskSystemId: Guid;
        EDocumentEntryNo: Integer;
    begin
        ClearLoaded();
        if PAV1V2Flag.IsV2Active() then begin
            if not Evaluate(PayablesAgentTaskSystemId, ExternalId) then
                exit(false);
            PayablesAgentTask.SetLoadFields("Entry No.");
            if not PayablesAgentTask.GetBySystemId(PayablesAgentTaskSystemId) then
                exit(false);
            exit(LoadByKey(PayablesAgentTask."Entry No."));
        end;
        if not Evaluate(EDocumentEntryNo, ExternalId) then
            exit(false);
        exit(LoadByKey(EDocumentEntryNo));
    end;

    /// <summary>
    /// Re-reads the loaded task from storage.
    /// </summary>
    internal procedure Refresh()
    begin
        if LoadByKey(TempLoadedTask."Entry No.") then;
    end;

    #endregion

    #region Create
    /// <summary>
    /// Creates a task for a PDF uploaded by a user, hands it to the agent and loads it into this instance.
    /// Under v1 the PDF is imported as an e-document of the agent's E-Document Service; the e-document pipeline then
    /// calls CreateTask. Under v2 a Payables Agent task is created and handed to the agent directly.
    /// </summary>
    internal procedure CreateFromUpload(FileName: Text; PdfInStream: InStream)
    var
        PayablesAgentTask: Record "Payables Agent Task";
        EDocument: Record "E-Document";
        EDocImport: Codeunit "E-Doc. Import";
        PADraftBasedSetup: Codeunit "PA Draft Based Setup";
    begin
        if PAV1V2Flag.IsV2Active() then begin
            InsertTask(0, InsertTaskData(CopyStr(FileName, 1, 250), PdfInStream), PayablesAgentTask);
            // Nothing else holds the uploaded file under v2, so an upload the agent does not take is rolled back.
            if not CreateTask("PA Source Type"::Upload, FormatSystemId(PayablesAgentTask.SystemId)) then
                Error(AgentNotActiveErr);
            exit;
        end;

        EDocImport.CreateFromType(EDocument, PADraftBasedSetup.GetOrCreateAgentEDocumentService(), "E-Doc. File Format"::PDF, FileName, PdfInStream);
        EDocument."Source Details" := CopyStr(FileName, 1, MaxStrLen(EDocument."Source Details"));
        EDocument.Modify();
        EDocImport.ProcessAutomaticallyIncomingEDocument(EDocument);
        if Load(Format(EDocument."Entry No")) then;
    end;

    /// <summary>
    /// Hands the task with the given external id to the agent and loads it into this instance. Called by every entry
    /// point once the backing record exists.
    /// </summary>
    /// <param name="PASourceType">Where the work came from, as known by the entry point. Only email-sourced work is
    /// checked against rejected senders.</param>
    /// <param name="ExternalId">External id of the task (see Load).</param>
    /// <returns>False when no task has that external id, or the agent did not take the task (see StartAgentTask).</returns>
    internal procedure CreateTask(PASourceType: Enum "PA Source Type"; ExternalId: Text[2048]): Boolean
    var
        Agent: Record Agent;
        AgentTask: Record "Agent Task";
        KnownSender: Record "PA Known Sender";
        PayablesAgentTask: Record "Payables Agent Task";
        PayablesAgentSetup: Codeunit "Payables Agent Setup";
        PATelemetry: Codeunit "PA Telemetry";
        PATrial: Codeunit "PA Trial";
        AgentTaskBuilder: Codeunit "Agent Task Builder";
        AgentTaskMessageBuilder: Codeunit "Agent Task Message Builder";
        RequiresReview: Boolean;
        ExcludeBilling: Boolean;
    begin
        if not Load(ExternalId) then
            exit(false);
        if TempLoadedTask."Agent Task ID" <> 0 then
            exit(false);
        ExternalId := GetAgentTaskExternalId();
        AgentTask.SetRange("Company Name", CompanyName());
        AgentTask.SetRange("External ID", ExternalId);
        if not AgentTask.IsEmpty() then
            exit(false);
        if not PayablesAgentSetup.GetAgent(Agent) then
            exit(false);
        if Agent.State = Agent.State::Disabled then
            exit(false);

        // A sender explicitly set to Reject is a blocklist: no agent task is created.
        if PASourceType = "PA Source Type"::Email then
            if KnownSender.GetForTask(this, KnownSender) then
                if KnownSender."Sender Policy" = "PA Sender Policy"::Reject then begin
                    PATelemetry.LogTaskSkippedSenderRejected(this);
                    exit(false);
                end;

        RequiresReview := PayablesAgentSetup.ShouldRequestReview(this);

        ExcludeBilling := false;
        if PATrial.IsActive() then begin
            PATrial.IncrementTrialInvoiceCount();
            PATelemetry.LogTrialTaskCreated(PATrial.GetTrialInvoiceCount(), PATrial.GetTrialInvoiceLimit());
            ExcludeBilling := true;
        end;

        AgentTaskMessageBuilder
            .Initialize(GetAgentTaskMessageFrom(), GetAgentTaskMessageText())
            .SetRequiresReview(RequiresReview)
            .SetMessageExternalID(ExternalId);
        AgentTask := AgentTaskBuilder
            .Initialize(Agent."User Security ID", GetAgentTaskTitle())
            .SetExternalId(ExternalId)
            .AddTaskMessage(AgentTaskMessageBuilder)
            .SetBillingContext(ExcludeBilling ? Enum::"Agent Task Billing Context"::Excluded : Enum::"Agent Task Billing Context"::Default)
            .Create();
        if PAV1V2Flag.IsV2Active() then
            if PayablesAgentTask.Get(TempLoadedTask."Entry No.") then begin
                PayablesAgentTask."Agent Task ID" := AgentTask.ID;
                PayablesAgentTask.Modify();
            end;
        Refresh();

        PATelemetry.LogTaskReceived(this, RequiresReview);
        exit(true);
    end;

    #endregion

    #region Telemetry

    /// <summary>
    /// Identifier of the backing record for telemetry: the e-document SystemId (v1, the same value the e-document
    /// import telemetry uses) or the Payables Agent task SystemId (v2). Lowercase, without braces.
    /// </summary>
    internal procedure GetTelemetryId(): Text
    var
        PayablesAgentTask: Record "Payables Agent Task";
        EDocument: Record "E-Document";
        BackingSystemId: Guid;
    begin
        if PAV1V2Flag.IsV2Active() then begin
            if PayablesAgentTask.Get(TempLoadedTask."Entry No.") then
                BackingSystemId := PayablesAgentTask.SystemId;
        end else
            if GetLoadedEDocument(EDocument) then
                BackingSystemId := EDocument.SystemId;
        if IsNullGuid(BackingSystemId) then
            exit('');
        exit(FormatSystemId(BackingSystemId));
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

    internal procedure GetSourceType(): Enum "PA Source Type"
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
    begin
        if PAV1V2Flag.IsV2Active() then begin
            if not PayablesAgentTask.Get(TempLoadedTask."Entry No.") then
                exit('');
            exit(DescribeSource(PayablesAgentTask));
        end;
        if TempLoadedTask."Source Type" = "PA Source Type"::Email then
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
    begin
        if PAV1V2Flag.IsV2Active() then begin
            if PayablesAgentTask.Get(TempLoadedTask."Entry No.") then
                OpenSource(PayablesAgentTask);
            exit;
        end;
        if TempLoadedTask."Source Type" = "PA Source Type"::Email then
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
        WebLink: Text;
    begin
        if PAV1V2Flag.IsV2Active() then begin
            if not PayablesAgentTask.Get(TempLoadedTask."Entry No.") then
                Error(SourceNotAvailableErr);
            OpenSourceEmail(PayablesAgentTask);
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
    begin
        if PAV1V2Flag.IsV2Active() then begin
            if not PayablesAgentTask.Get(TempLoadedTask."Entry No.") then
                Error(SourceNotAvailableErr);
            OpenSourcePdf(PayablesAgentTask);
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
    begin
        if not PAV1V2Flag.IsV2Active() then
            exit;
        if not PayablesAgentTask.Get(TempLoadedTask."Entry No.") then
            Error(TaskNotFoundErr);
        RegisterOutcome(PayablesAgentTask, OutcomeRecordId);
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
    begin
        if not PAV1V2Flag.IsV2Active() then
            exit;
        if not PayablesAgentTask.Get(TempLoadedTask."Entry No.") then
            Error(TaskNotFoundErr);
        PayablesAgentTask."Completed At" := CurrentDateTime();
        PayablesAgentTask.Modify();
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
            "PA Source Type"::Email:
                exit(Page::"PA Agent Email Task");
            "PA Source Type"::Upload:
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

    #endregion

    #region Private

    local procedure ClearLoaded()
    begin
        Clear(TempLoadedTask);
        Clear(LoadedEDocument);
        TempLoadedTask."Source Type" := "PA Source Type"::Upload;
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
            TempLoadedTask."Source Type" := "PA Source Type"::Email
        else
            TempLoadedTask."Source Type" := "PA Source Type"::Upload;
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
            TempLoadedTask."Source Type" := "PA Source Type"::Upload;
            exit;
        end;
        TempLoadedTask."Source Type" := "PA Source Type"::Email;
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

    /// <summary>
    /// The only procedure that reads a task from storage. The key is the Payables Agent task entry no. (v2) or the
    /// e-document entry no. (v1).
    /// </summary>
    local procedure LoadByKey(TaskKey: BigInteger): Boolean
    var
        PayablesAgentTask: Record "Payables Agent Task";
        EDocument: Record "E-Document";
    begin
        ClearLoaded();
        if TaskKey = 0 then
            exit(false);
        if PAV1V2Flag.IsV2Active() then begin
            if not PayablesAgentTask.Get(TaskKey) then
                exit(false);
            PopulateFromPayablesAgentTask(PayablesAgentTask);
            exit(true);
        end;
        if not EDocument.Get(TaskKey) then
            exit(false);
        PopulateFromEDocument(EDocument);
        TempLoadedTask."Agent Task ID" := FindAgentTaskIdForExternalId(Format(EDocument."Entry No"));
        PopulateAgentTaskStatus();
        exit(true);
    end;

    /// <summary>
    /// The key of the task an agent task works on: the Payables Agent task bound to it (v2), or the e-document whose
    /// entry no. the first message of the agent task carries as its external id (v1).
    /// </summary>
    local procedure TryGetKeyForAgentTask(AgentTaskId: BigInteger; var TaskKey: BigInteger): Boolean
    var
        PayablesAgentTask: Record "Payables Agent Task";
        AgentTaskMessage: Record "Agent Task Message";
        EDocumentEntryNo: Integer;
    begin
        if AgentTaskId = 0 then
            exit(false);
        if PAV1V2Flag.IsV2Active() then begin
            PayablesAgentTask.SetCurrentKey("Agent Task ID");
            PayablesAgentTask.SetRange("Agent Task ID", AgentTaskId);
            PayablesAgentTask.SetLoadFields("Entry No.");
            if not PayablesAgentTask.FindFirst() then
                exit(false);
            TaskKey := PayablesAgentTask."Entry No.";
            exit(true);
        end;
        AgentTaskMessage.SetRange("Task ID", AgentTaskId);
        AgentTaskMessage.SetFilter("External ID", '<>%1', '');
        if not AgentTaskMessage.FindFirst() then
            exit(false);
        if not Evaluate(EDocumentEntryNo, AgentTaskMessage."External ID") then
            exit(false);
        TaskKey := EDocumentEntryNo;
        exit(true);
    end;

    local procedure FindAgentTaskIdForExternalId(ExternalId: Text[2048]): BigInteger
    var
        AgentTask: Record "Agent Task";
    begin
        AgentTask.SetRange("Company Name", CompanyName());
        AgentTask.SetRange("External ID", ExternalId);
        AgentTask.SetLoadFields(ID);
        if AgentTask.FindFirst() then
            exit(AgentTask.ID);
        exit(0);
    end;

    /// <summary>
    /// External id of the agent task for the loaded task: the e-document entry no. (v1), or the Payables Agent task
    /// SystemId (v2), which is not numeric on purpose so it can never be mistaken for an e-document entry no.
    /// </summary>
    local procedure GetAgentTaskExternalId(): Text[2048]
    var
        PayablesAgentTask: Record "Payables Agent Task";
    begin
        if PAV1V2Flag.IsV2Active() then begin
            PayablesAgentTask.SetLoadFields(SystemId);
            if PayablesAgentTask.Get(TempLoadedTask."Entry No.") then
                exit(FormatSystemId(PayablesAgentTask.SystemId));
            exit('');
        end;
        exit(Format(TempLoadedTask."Entry No."));
    end;

    /// <summary>
    /// A SystemId as text: lowercase, without braces (the format the e-document telemetry uses too).
    /// </summary>
    local procedure FormatSystemId(SystemIdToFormat: Guid): Text[2048]
    begin
        exit(CopyStr(LowerCase(Format(SystemIdToFormat)).Replace('{', '').Replace('}', ''), 1, 2048));
    end;

    local procedure GetAgentTaskTitle(): Text[150]
    var
        EDocument: Record "E-Document";
    begin
        if PAV1V2Flag.IsV2Active() then
            exit(CopyStr(StrSubstNo(UploadTaskTitleLbl, TempLoadedTask."File Name"), 1, 150));
        if GetLoadedEDocument(EDocument) then;
        exit(CopyStr(StrSubstNo(EDocumentTaskTitleLbl, LowerCase(EDocument."Source Details")), 1, 150));
    end;

    local procedure GetAgentTaskMessageFrom(): Text[250]
    var
        EDocument: Record "E-Document";
    begin
        if PAV1V2Flag.IsV2Active() then
            exit(TempLoadedTask."File Name");
        if GetLoadedEDocument(EDocument) then;
        exit(CopyStr(EDocument."Source Details", 1, 250));
    end;

    local procedure GetAgentTaskMessageText(): Text
    begin
        if PAV1V2Flag.IsV2Active() then
            exit(UploadTaskMessageLbl);
        exit(StrSubstNo(EDocumentTaskMessageLbl, TempLoadedTask."Entry No."));
    end;

    local procedure RegisterOutcome(var PayablesAgentTask: Record "Payables Agent Task"; OutcomeRecordId: RecordId)
    begin
        PayablesAgentTask.Outcome := OutcomeRecordId;
        PayablesAgentTask.Modify();
    end;

    /// <summary>
    /// Describes what the task came from. An email source takes precedence over the PDF, because a PDF received by email
    /// is described by its email.
    /// </summary>
    local procedure DescribeSource(PayablesAgentTask: Record "Payables Agent Task"): Text
    begin
        if PayablesAgentTask."Source Data No." <> 0 then
            exit(DescribeEmailSource(PayablesAgentTask."Source Data No."));
        if PayablesAgentTask."Task Data No." <> 0 then
            exit(DescribePdfSource(PayablesAgentTask."Task Data No."));
        exit('');
    end;

    /// <summary>
    /// Opens what the task came from, using the same precedence as DescribeSource.
    /// </summary>
    local procedure OpenSource(PayablesAgentTask: Record "Payables Agent Task")
    begin
        if PayablesAgentTask."Source Data No." <> 0 then begin
            OpenSourceEmail(PayablesAgentTask);
            exit;
        end;
        if PayablesAgentTask."Task Data No." <> 0 then begin
            OpenSourcePdf(PayablesAgentTask);
            exit;
        end;
    end;

    local procedure OpenSourceEmail(PayablesAgentTask: Record "Payables Agent Task")
    var
        PayablesAgentTaskSource: Record "Payables Agent Task Source";
    begin
        if not PayablesAgentTaskSource.Get(PayablesAgentTask."Source Data No.") then
            Error(SourceNotAvailableErr);
        PayablesAgentTaskSource.SetRecFilter();
        Page.Run(Page::"PA Email Review", PayablesAgentTaskSource);
    end;

    local procedure OpenSourcePdf(PayablesAgentTask: Record "Payables Agent Task")
    var
        PayablesAgentTaskData: Record "Payables Agent Task Data";
    begin
        if not PayablesAgentTaskData.Get(PayablesAgentTask."Task Data No.") then
            Error(SourceNotAvailableErr);
        PayablesAgentTaskData.SetRecFilter();
        Page.Run(Page::"PDF Viewer", PayablesAgentTaskData);
    end;

    local procedure InsertTask(SourceDataNo: BigInteger; TaskDataNo: BigInteger; var PayablesAgentTask: Record "Payables Agent Task")
    begin
        PayablesAgentTask.Init();
        PayablesAgentTask."Entry No." := 0;
        PayablesAgentTask."Source Data No." := SourceDataNo;
        PayablesAgentTask."Task Data No." := TaskDataNo;
        PayablesAgentTask."Received At" := CurrentDateTime();
        PayablesAgentTask.Insert();
    end;

    local procedure InsertTaskData(FileName: Text[250]; PdfInStream: InStream): BigInteger
    var
        PayablesAgentTaskData: Record "Payables Agent Task Data";
    begin
        PayablesAgentTaskData.Init();
        PayablesAgentTaskData."Entry No." := 0;
        PayablesAgentTaskData."File Name" := FileName;
        PayablesAgentTaskData."File Content".ImportStream(PdfInStream, FileName, PdfMimeTypeTok);
        PayablesAgentTaskData.Insert();
        exit(PayablesAgentTaskData."Entry No.");
    end;

    local procedure DescribeEmailSource(SourceDataNo: BigInteger): Text
    var
        PayablesAgentTaskSource: Record "Payables Agent Task Source";
        EmailInbox: Record "Email Inbox";
    begin
        if not PayablesAgentTaskSource.Get(SourceDataNo) then
            exit(SourceNotAvailableTxt);
        EmailInbox.SetLoadFields("Sender Address", Description);
        if not EmailInbox.Get(PayablesAgentTaskSource."Email Inbox Id") then
            exit(SourceNotAvailableTxt);
        exit(StrSubstNo(EmailSourceTxt, EmailInbox."Sender Address", EmailInbox.Description));
    end;

    local procedure DescribePdfSource(TaskDataNo: BigInteger): Text
    var
        PayablesAgentTaskData: Record "Payables Agent Task Data";
    begin
        PayablesAgentTaskData.SetLoadFields("File Name");
        if not PayablesAgentTaskData.Get(TaskDataNo) then
            exit(SourceNotAvailableTxt);
        exit(StrSubstNo(PdfSourceTxt, PayablesAgentTaskData."File Name"));
    end;
    #endregion
}
