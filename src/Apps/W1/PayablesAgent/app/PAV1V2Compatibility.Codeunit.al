// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

#pragma warning disable AS0007
namespace Microsoft.Agent.PayablesAgent;

using Microsoft.eServices.EDocument;
using Microsoft.eServices.EDocument.Integration;
using Microsoft.eServices.EDocument.Processing.Import;
using Microsoft.EServices.EDocumentConnector.Microsoft365;
using System.Agents;
using System.Email;
using System.Environment.Configuration;
using System.Privacy;
using System.Reflection;
using System.Telemetry;

/// <summary>
/// Single home for logic that must adapt depending on whether Payables Agent v2 is active.
/// The active-flag check is private on purpose; each adaptation we actually need gets its own
/// internal procedure shaped as `if v2 then [v2 behavior] else [v1 behavior]`. Add procedures
/// here one at a time, as concrete needs arise — this file is the only place that knows the flag.
/// </summary>
codeunit 3339 "PA V1V2 Compatibility"
{
    Access = Internal;
    InherentEntitlements = X;
    InherentPermissions = X;
    Permissions = tabledata "Payables Agent Setup" = R, tabledata Agent = R, tabledata "Agent Task" = R, tabledata "Agent Task Message" = R, tabledata "E-Document" = R, tabledata "E-Doc. Data Storage" = R, tabledata "Email Inbox" = R, tabledata "Outlook Setup" = RIM, tabledata "Payables Agent Task" = R, tabledata "Payables Agent Task Source" = R, tabledata "Payables Agent Task Data" = R;

    /// <summary>
    /// Populates the default profile assigned to the agent on activation: the v2 task-based role center
    /// when v2 is active, otherwise the v1 draft-based profile.
    /// </summary>
    internal procedure GetDefaultProfile(var TempAllProfile: Record "All Profile" temporary)
    var
        Agent: Codeunit Agent;
        ModuleInfo: ModuleInfo;
    begin
        NavApp.GetCurrentModuleInfo(ModuleInfo);
        if IsPayablesAgentV2Active() then
            Agent.PopulateDefaultProfile(PayablesAgentV2ProfileTok, ModuleInfo.Id, TempAllProfile)
        else
            Agent.PopulateDefaultProfile(PayablesAgentProfileTok, ModuleInfo.Id, TempAllProfile);
    end;

    /// <summary>
    /// Standardizes the v1 representation of a task's source (an e-document) into a Payables Agent Task Source,
    /// so callers can work against the v2 shape. Resolves the email inbox row for an email-sourced e-document;
    /// leaves the source empty for a non-email (uploaded) e-document.
    /// </summary>
    internal procedure BuildTaskSourceFromEDocument(EDocument: Record "E-Document"; var PayablesAgentTaskSource: Record "Payables Agent Task Source")
    begin
        Clear(PayablesAgentTaskSource);
        if EDocument."Outlook Mail Message Id" = '' then
            exit;
        PayablesAgentTaskSource."Email Inbox Id" := ResolveEmailInboxId(EDocument."Outlook Mail Message Id");
    end;

    /// <summary>
    /// Loads the v1 setup state into the Payables Agent setup so the page works entirely against it. Under v2 the
    /// setup already owns everything; under v1 the mailbox configuration and consent live on the Outlook Setup
    /// record, so they are read across.
    /// </summary>
    internal procedure LoadSetup(var PayablesAgentSetup: Record "Payables Agent Setup")
    var
        OutlookSetup: Record "Outlook Setup";
    begin
        if IsPayablesAgentV2Active() then
            exit;
        if not OutlookSetup.FindFirst() then
            exit;
        PayablesAgentSetup."Email Account Id" := OutlookSetup."Email Account ID";
        PayablesAgentSetup."Email Folder" := OutlookSetup."Email Folder";
        PayablesAgentSetup."Email Folder Id" := OutlookSetup."Email Folder Id";
        PayablesAgentSetup."Last Sync At" := OutlookSetup."Last Sync At";
        PayablesAgentSetup."Email Monitoring Consent" := OutlookSetup."Consent Received";
    end;

    /// <summary>
    /// Obtains the user's consent for the agent to monitor the mailbox, using the standard Microsoft-service
    /// consent experience, and records it on the Payables Agent setup. Returns false when consent is declined.
    /// </summary>
    internal procedure ObtainEmailMonitoringConsent(var PayablesAgentSetup: Record "Payables Agent Setup"): Boolean
    var
        CustomerConsentMgt: Codeunit "Customer Consent Mgt.";
    begin
        if PayablesAgentSetup."Email Monitoring Consent" then
            exit(true);
        if not CustomerConsentMgt.ConfirmUserConsentToMicrosoftService() then
            exit(false);
        PayablesAgentSetup."Email Monitoring Consent" := true;
        exit(true);
    end;

    /// <summary>
    /// Applies the Payables Agent setup to the v1 backing records (Outlook Setup and the E-Document Service). This
    /// starts write transactions. Under v2 the setup is self-contained and this is a no-op.
    /// </summary>
    internal procedure ApplySetupToV1Tables(var PayablesAgentSetup: Record "Payables Agent Setup"; Enabling: Boolean)
    var
        OutlookSetup: Record "Outlook Setup";
        OutlookSetupExistedPreviously: Boolean;
        EmailAccountChanged: Boolean;
    begin
        if IsPayablesAgentV2Active() then
            exit;

        OutlookSetupExistedPreviously := OutlookSetup.FindFirst();
        EmailAccountChanged := OutlookSetup."Email Account ID" <> PayablesAgentSetup."Email Account Id";
        OutlookSetup."Email Account ID" := PayablesAgentSetup."Email Account Id";
        OutlookSetup."Email Connector" := "Email Connector"::"Microsoft 365";
        OutlookSetup."Email Folder" := PayablesAgentSetup."Email Folder";
        OutlookSetup."Email Folder Id" := PayablesAgentSetup."Email Folder Id";
        OutlookSetup."Consent Received" := PayablesAgentSetup."Email Monitoring Consent";
        if EmailAccountChanged then
            OutlookSetup."Last Sync At" := 0DT;
        if OutlookSetupExistedPreviously then
            OutlookSetup.Modify()
        else
            OutlookSetup.Insert();

        ApplyEDocumentServiceSetup(PayablesAgentSetup, Enabling, EmailAccountChanged);
    end;

    local procedure ApplyEDocumentServiceSetup(var PayablesAgentSetup: Record "Payables Agent Setup"; Enabling: Boolean; ReactivateAutoImport: Boolean)
    var
        EDocumentService: Record "E-Document Service";
        OutlookSetup: Record "Outlook Setup";
        PayablesAgentSetupCU: Codeunit "Payables Agent Setup";
    begin
        // If we intend to disable the agent, we need to disable the E-Document Service's auto-import as well
        if not Enabling then begin
            if EDocumentService.Get(PayablesAgentEDocServiceTok) then begin
                EDocumentService.Validate("Auto Import", false);
                EDocumentService.Modify();
            end;
            exit;
        end;
        EDocumentService := PayablesAgentSetupCU.GetOrCreateAgentEDocumentService();
        // We configure the default E-Document Service settings
        EDocumentService.Validate("Automatic Import Processing", "E-Doc. Automatic Processing"::No);
        EDocumentService.Validate("Import Process", "E-Document Import Process"::"Version 2.0");
        Clear(EDocumentService."Import Start Time");
        EDocumentService."Import Minutes between runs" := 1;
        EDocumentService."Verify Purch. Total Amounts" := true;
        EDocumentService.Modify();
        if ReactivateAutoImport then
            EDocumentService.Validate("Auto Import", false);
        // If monitoring outlook is requested, we set the integration, auto-import and configure the Outlook Setup
        if PayablesAgentSetup."Monitor Outlook" then begin
            EDocumentService.Validate("Service Integration V2", "Service Integration"::Outlook);
            EDocumentService.Validate("Auto Import", true);
            OutlookSetup.FindFirst();
            OutlookSetup.Validate(Enabled, true);
            OutlookSetup.Modify();
        end
        else
            EDocumentService.Validate("Auto Import", false);
        EDocumentService.Modify();
    end;

    /// <summary>
    /// Page shown for an agent task message's source: the email review card for an email-sourced task, otherwise
    /// the uploaded-PDF card. The source is resolved the same way for both versions (see GetAgentTaskSourceType).
    /// </summary>
    internal procedure GetAgentTaskMessagePageId(AgentUserId: Guid; MessageId: Guid) PageId: Integer
    var
        AgentTaskMessage: Record "Agent Task Message";
    begin
        AgentTaskMessage.SetRange(ID, MessageId);
        if not AgentTaskMessage.FindFirst() then
            exit(0);
        case GetAgentTaskSourceType(AgentTaskMessage) of
            "PA Agent Source Type"::Email:
                exit(Page::"PA Agent Email Task");
            "PA Agent Source Type"::Upload:
                exit(Page::"PA Agent Upload Task");
        end;
    end;

    [EventSubscriber(ObjectType::Page, Page::"Inbound E-Documents", OnOpenPageEvent, '', false, false)]
    local procedure OnOpenInboundEDocumentsPage(var Rec: Record "E-Document")
    var
        EDocument: Record "E-Document";
        PayablesAgent: Codeunit "Payables Agent";
    begin
        // Under v2 the agent does not work from the Inbound E-Documents page, so no filtering is applied.
        if IsPayablesAgentV2Active() then
            exit;

        // Event to ensure agent can only see e-documents that are relevant to their session.
        EDocument := PayablesAgent.GetCurrentSessionsEDocument();
        if EDocument."Entry No" = 0 then
            exit;
        Rec.SetRange("Entry No", EDocument."Entry No");
    end;

    /// <summary>
    /// Whether an agent task message's source is an email or an uploaded/manual PDF. Resolves against the
    /// e-document (v1) or the Payables Agent task (v2).
    /// </summary>
    internal procedure GetAgentTaskSourceType(AgentTaskMessage: Record "Agent Task Message"): Enum "PA Agent Source Type"
    var
        EDocument: Record "E-Document";
        PayablesAgentTask: Record "Payables Agent Task";
    begin
        if IsPayablesAgentV2Active() then begin
            if TryGetTaskForMessage(AgentTaskMessage, PayablesAgentTask) then
                if PayablesAgentTask."Source Data No." <> 0 then
                    exit("PA Agent Source Type"::Email);
            exit("PA Agent Source Type"::Upload);
        end;
        if TryGetEDocumentForMessage(AgentTaskMessage, EDocument) then
            if EDocument."Outlook Mail Message Id" <> '' then
                exit("PA Agent Source Type"::Email);
        exit("PA Agent Source Type"::Upload);
    end;

    /// <summary>
    /// Fills the display buffer for an agent task message's source, resolving against the e-document (v1) or the
    /// Payables Agent task (v2). The buffer carries only scalars and handles; the email body and the PDF stay in
    /// their persisted stores and are reached through the buffer's own procedures.
    /// </summary>
    internal procedure LoadPADetailedTask(AgentTaskMessage: Record "Agent Task Message"; var PADetailedTask: Record "PA Detailed Task")
    begin
        Clear(PADetailedTask);
        PADetailedTask."Source Type" := GetAgentTaskSourceType(AgentTaskMessage);
        if IsPayablesAgentV2Active() then
            LoadPADetailedTaskFromPATask(AgentTaskMessage, PADetailedTask)
        else
            LoadPADetailedTaskFromEDocument(AgentTaskMessage, PADetailedTask);
    end;

    /// <summary>
    /// Body of the source email, read live from the Email module. Blank when there is no email or it is gone.
    /// </summary>
    internal procedure GetSourceEmailBody(PADetailedTask: Record "PA Detailed Task"): Text
    var
        EmailInbox: Record "Email Inbox";
        EmailMessage: Codeunit "Email Message";
    begin
        if PADetailedTask."Email Inbox Id" = 0 then
            exit('');
        if not EmailInbox.Get(PADetailedTask."Email Inbox Id") then
            exit('');
        if EmailMessage.Get(EmailInbox."Message Id") then
            exit(EmailMessage.GetBody());
        exit('');
    end;

    /// <summary>
    /// Outlook on the web link of the source email. Blank when there is no email or no external message id.
    /// </summary>
    internal procedure GetSourceEmailWebLink(PADetailedTask: Record "PA Detailed Task"): Text
    var
        EmailInbox: Record "Email Inbox";
    begin
        if PADetailedTask."Email Inbox Id" = 0 then
            exit('');
        EmailInbox.SetLoadFields("External Message Id");
        if not EmailInbox.Get(PADetailedTask."Email Inbox Id") then
            exit('');
        if EmailInbox."External Message Id" = '' then
            exit('');
        exit(StrSubstNo(OutlookWebLinkTok, EmailInbox."External Message Id"));
    end;

    /// <summary>
    /// Opens the source PDF from where it is persisted: the Payables Agent task data (v2) or the e-document (v1).
    /// </summary>
    internal procedure ViewSourcePdf(PADetailedTask: Record "PA Detailed Task")
    var
        EDocument: Record "E-Document";
        PayablesAgentTaskData: Record "Payables Agent Task Data";
    begin
        if PADetailedTask."Task Data No." <> 0 then begin
            if PayablesAgentTaskData.Get(PADetailedTask."Task Data No.") then
                PayablesAgentTaskData.ViewFileContent();
            exit;
        end;
        if TryGetEDocumentFromRecordId(PADetailedTask."Source Record Id", EDocument) then
            EDocument.ViewSourceFile();
    end;

    /// <summary>
    /// Downloads the source PDF from where it is persisted.
    /// </summary>
    internal procedure DownloadSourcePdf(PADetailedTask: Record "PA Detailed Task")
    var
        EDocument: Record "E-Document";
        PayablesAgentTaskData: Record "Payables Agent Task Data";
    begin
        if PADetailedTask."Task Data No." <> 0 then begin
            if PayablesAgentTaskData.Get(PADetailedTask."Task Data No.") then
                PayablesAgentTaskData.DownloadFileContent();
            exit;
        end;
        if TryGetEDocumentFromRecordId(PADetailedTask."Source Record Id", EDocument) then
            EDocument.ViewSourceFile();
    end;

    local procedure LoadPADetailedTaskFromPATask(AgentTaskMessage: Record "Agent Task Message"; var PADetailedTask: Record "PA Detailed Task")
    var
        PayablesAgentTask: Record "Payables Agent Task";
        PayablesAgentTaskSource: Record "Payables Agent Task Source";
        PayablesAgentTaskData: Record "Payables Agent Task Data";
        EmailInbox: Record "Email Inbox";
    begin
        if not TryGetTaskForMessage(AgentTaskMessage, PayablesAgentTask) then
            exit;
        PADetailedTask."Source Data No." := PayablesAgentTask."Source Data No.";
        PADetailedTask."Task Data No." := PayablesAgentTask."Task Data No.";
        PADetailedTask."Source Record Id" := PayablesAgentTask.RecordId();
        PADetailedTask."Has Pdf" := PayablesAgentTask."Task Data No." <> 0;
        if PayablesAgentTaskData.Get(PayablesAgentTask."Task Data No.") then
            PADetailedTask."File Name" := PayablesAgentTaskData."File Name";
        if PayablesAgentTaskSource.Get(PayablesAgentTask."Source Data No.") then begin
            PADetailedTask."Email Inbox Id" := PayablesAgentTaskSource."Email Inbox Id";
            if EmailInbox.Get(PADetailedTask."Email Inbox Id") then begin
                PADetailedTask."Email From" := CopyStr(StrSubstNo(EmailFromTxt, EmailInbox."Sender Name", EmailInbox."Sender Address"), 1, MaxStrLen(PADetailedTask."Email From"));
                PADetailedTask."Email Subject" := CopyStr(EmailInbox.Description, 1, MaxStrLen(PADetailedTask."Email Subject"));
            end;
        end;
    end;

    local procedure LoadPADetailedTaskFromEDocument(AgentTaskMessage: Record "Agent Task Message"; var PADetailedTask: Record "PA Detailed Task")
    var
        EDocument: Record "E-Document";
        EDocumentDataStorage: Record "E-Doc. Data Storage";
        EmailInbox: Record "Email Inbox";
    begin
        if not TryGetEDocumentForMessage(AgentTaskMessage, EDocument) then
            exit;
        PADetailedTask."Source Record Id" := EDocument.RecordId();
        PADetailedTask."File Name" := CopyStr(EDocument."Source Details", 1, MaxStrLen(PADetailedTask."File Name"));
        if (EDocument."Unstructured Data Entry No." <> 0) and EDocumentDataStorage.Get(EDocument."Unstructured Data Entry No.") then
            PADetailedTask."Has Pdf" := EDocumentDataStorage."File Format" = Enum::"E-Doc. File Format"::PDF;

        // Email is read from the Email module in both versions. For v1 we resolve the inbox row the connector
        // created, by the external (Outlook) message id stored on the e-document.
        if EDocument."Outlook Mail Message Id" = '' then
            exit;
        PADetailedTask."Email Inbox Id" := ResolveEmailInboxId(EDocument."Outlook Mail Message Id");
        if EmailInbox.Get(PADetailedTask."Email Inbox Id") then begin
            PADetailedTask."Email From" := CopyStr(StrSubstNo(EmailFromTxt, EmailInbox."Sender Name", EmailInbox."Sender Address"), 1, MaxStrLen(PADetailedTask."Email From"));
            PADetailedTask."Email Subject" := CopyStr(EmailInbox.Description, 1, MaxStrLen(PADetailedTask."Email Subject"));
        end;
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

    local procedure TryGetEDocumentForMessage(AgentTaskMessage: Record "Agent Task Message"; var EDocument: Record "E-Document"): Boolean
    var
        EDocumentEntryNo: Integer;
    begin
        if not Evaluate(EDocumentEntryNo, AgentTaskMessage."External ID") then
            exit(false);
        exit(EDocument.Get(EDocumentEntryNo));
    end;

    local procedure TryGetTaskForMessage(AgentTaskMessage: Record "Agent Task Message"; var PayablesAgentTask: Record "Payables Agent Task"): Boolean
    begin
        PayablesAgentTask.SetRange("Agent Task ID", AgentTaskMessage."Task ID");
        exit(PayablesAgentTask.FindFirst());
    end;

    /// <summary>
    /// Single hardcoded source of truth for whether Payables Agent v2 is active. While this returns false,
    /// every branch in this codeunit stays on the v1 behavior.
    /// </summary>
    internal procedure IsPayablesAgentV2Active(): Boolean
    begin
        exit(false);
    end;

    var
        PayablesAgentProfileTok: Label 'Payables Agent', Locked = true;
        PayablesAgentV2ProfileTok: Label 'Payables Agent V2', Locked = true;
        EmailFromTxt: Label '%1 <%2>', Comment = '%1 = sender name, %2 = sender email address';
        OutlookWebLinkTok: Label 'https://outlook.office365.com/owa/?ItemID=%1&exvsurl=1&viewmodel=ReadMessageItem', Locked = true;
}
