// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.Agent.PayablesAgent;

using Microsoft.eServices.EDocument;
using Microsoft.eServices.EDocument.Integration;
using Microsoft.eServices.EDocument.Processing.Import;
using Microsoft.EServices.EDocumentConnector.Microsoft365;
using System.Agents;
using System.Email;

// Applies configuration and backing monitoring together; editable proposals may be invalid until applied.
codeunit 3343 "PA Setup"
{
    Access = Internal;
    InherentEntitlements = X;
    InherentPermissions = X;
    Permissions = tabledata "Payables Agent Setup" = RIMD, tabledata "Outlook Setup" = RIM, tabledata Agent = R;

    var
        PayablesAgentSetupRecord: Record "Payables Agent Setup";
        OutlookSetup: Record "Outlook Setup";
        PAV1V2Flag: Codeunit "PA V1V2 Flag";
        IsV2: Boolean;
        OutlookSetupExists: Boolean;
        AgentUserNameLbl: Label 'Payables Agent', Comment = 'User name of the agent.', Locked = true;
        PayablesAgentProfileTok: Label 'Payables Agent', Locked = true;
        PayablesAgentV2ProfileTok: Label 'Payables Agent Profile', Locked = true;
        PayablesAgentPermissionSetTok: Label 'Payables Ag. - Run', Locked = true;
        PayablesAgentV2PermissionSetTok: Label 'Payables Agent - Run', Locked = true;
        AgentInstructionsTok: Label '_DraftBasedPayablesAgent/Prompts/PayablesAgent-AgentInstructions.md', Locked = true;
        AgentDrivenInstructionsTok: Label '_DraftBasedPayablesAgent/Prompts/PayablesAgent-AgentInstructions-AgentDriven.md', Locked = true;
        AgentInstructionsV2Tok: Label 'Prompts/PayablesAgent-AgentInstructions-V2.md', Locked = true;
        PayablesAgentEDocServiceTok: Label 'AGENT', Locked = true;
        MonitoringNotSupportedErr: Label 'Email monitoring is not available for this version of the Payables Agent.';
        MailboxRequiredErr: Label 'Select a mailbox before enabling email monitoring.';
        ConsentRequiredErr: Label 'Email monitoring requires privacy consent.';
        ReviewPolicyRequiredErr: Label 'Select an email review policy before enabling email monitoring.';
        EnabledAgentRequiredErr: Label 'Email monitoring requires an enabled Payables Agent.';
        MailboxUnavailableErr: Label 'The selected Microsoft 365 mailbox is no longer available.';

    internal procedure GetSetup()
    begin
        if GetSetup(true) then;
    end;

    internal procedure GetSetup(InsertIfMissing: Boolean): Boolean
    var
        Exists: Boolean;
    begin
        Clear(PayablesAgentSetupRecord);
        Clear(OutlookSetup);
        IsV2 := PAV1V2Flag.IsV2Active();
        Exists := PayablesAgentSetupRecord.GetSetup(InsertIfMissing);
        OutlookSetupExists := false;
        if not IsV2 then
            OutlookSetupExists := OutlookSetup.FindFirst();
        exit(Exists);
    end;

    // A read-only lookup: neither the stored setup nor this editable proposal is changed.
    internal procedure TryFindAgent(var Agent: Record Agent): Boolean
    var
        StoredSetup: Record "Payables Agent Setup";
    begin
        Clear(Agent);
        if StoredSetup.GetSetup(false) then
            if Agent.Get(StoredSetup."User Security Id") then
                exit(true);
        Agent.SetRange("User Name", AgentUserName());
        exit(Agent.FindFirst());
    end;

    // Explicitly repairs the persisted agent association without overwriting an editable proposal.
    internal procedure FindAgentAndReconcileSetup(var Agent: Record Agent): Boolean
    var
        StoredSetup: Record "Payables Agent Setup";
        AgentUserId: Guid;
        Found: Boolean;
    begin
        StoredSetup.GetOrCreateSetup();
        Found := TryFindAgent(Agent);
        if Found then
            AgentUserId := Agent."User Security ID";
        SaveUserSecurityId(AgentUserId);
        exit(Found);
    end;

    internal procedure IsStoredAgentEnabled(): Boolean
    var
        StoredSetup: Record "Payables Agent Setup";
        Agent: Record Agent;
    begin
        if not StoredSetup.GetSetup(false) then
            exit(false);
        if not Agent.Get(StoredSetup."User Security Id") then
            exit(false);
        exit(Agent.State = Agent.State::Enabled);
    end;

    internal procedure AgentUserName(): Code[50]
    begin
        exit(CopyStr(AgentUserNameLbl + ' - ' + CompanyName(), 1, 50));
    end;

    internal procedure GetPageRecord(): Record "Payables Agent Setup"
    var
        PageRecord: Record "Payables Agent Setup";
    begin
        // Project logical settings only, without storage system fields or obsolete backing references.
        PageRecord.Id := PayablesAgentSetupRecord.Id;
        PageRecord."Monitor Outlook" := PayablesAgentSetupRecord."Monitor Outlook";
        PageRecord."Email Review Policy" := PayablesAgentSetupRecord."Email Review Policy";
        PageRecord."User Security Id" := PayablesAgentSetupRecord."User Security Id";
        PageRecord."Last Activated" := PayablesAgentSetupRecord."Last Activated";
        PageRecord."Applied Instr. Config Hash" := PayablesAgentSetupRecord."Applied Instr. Config Hash";
        PageRecord."Email Account Id" := GetEmailAccountId();
        PageRecord."Email Folder" := GetEmailFolder();
        PageRecord."Email Folder Id" := GetEmailFolderId();
        PageRecord."Email Monitoring Consent" := GetEmailMonitoringConsent();
        PageRecord."Last Sync At" := GetLastSyncAt();
        exit(PageRecord);
    end;

    // Clears an editable proposal without persisting it. Evaluation cleanup applies this before deleting setup.
    internal procedure ResetProposal()
    begin
        Clear(PayablesAgentSetupRecord);
        Clear(OutlookSetup);
        IsV2 := PAV1V2Flag.IsV2Active();
        OutlookSetupExists := not IsV2;
    end;

    internal procedure GetMonitorOutlook(): Boolean
    begin
        exit(PayablesAgentSetupRecord."Monitor Outlook");
    end;

    internal procedure SetMonitorOutlook(Value: Boolean)
    begin
        PayablesAgentSetupRecord."Monitor Outlook" := Value;
    end;

    internal procedure GetEmailReviewPolicy(): Enum "PA Email Review Policy"
    begin
        exit(PayablesAgentSetupRecord."Email Review Policy");
    end;

    internal procedure SetEmailReviewPolicy(Value: Enum "PA Email Review Policy")
    begin
        PayablesAgentSetupRecord."Email Review Policy" := Value;
    end;

    internal procedure SetMailboxSelection(AccountId: Guid; FolderName: Text[2048]; FolderId: Text[2048])
    begin
        IsV2 := PAV1V2Flag.IsV2Active();
        PayablesAgentSetupRecord."Email Account Id" := AccountId;
        PayablesAgentSetupRecord."Email Folder" := FolderName;
        PayablesAgentSetupRecord."Email Folder Id" := FolderId;
        if not IsV2 then begin
            OutlookSetup."Email Account ID" := AccountId;
            OutlookSetup."Email Folder" := FolderName;
            OutlookSetup."Email Folder Id" := FolderId;
            OutlookSetupExists := true;
        end;
    end;

    internal procedure GetEmailAccountId(): Guid
    begin
        if not IsV2 and OutlookSetupExists then
            exit(OutlookSetup."Email Account ID");
        exit(PayablesAgentSetupRecord."Email Account Id");
    end;

    internal procedure GetEmailFolder(): Text[2048]
    begin
        if not IsV2 and OutlookSetupExists then
            exit(OutlookSetup."Email Folder");
        exit(PayablesAgentSetupRecord."Email Folder");
    end;

    internal procedure GetEmailFolderId(): Text[2048]
    begin
        if not IsV2 and OutlookSetupExists then
            exit(OutlookSetup."Email Folder Id");
        exit(PayablesAgentSetupRecord."Email Folder Id");
    end;

    internal procedure GetEmailMonitoringConsent(): Boolean
    begin
        if not IsV2 and OutlookSetupExists then
            exit(OutlookSetup."Consent Received");
        exit(PayablesAgentSetupRecord."Email Monitoring Consent");
    end;

    internal procedure SetEmailMonitoringConsent(Value: Boolean)
    begin
        PayablesAgentSetupRecord."Email Monitoring Consent" := Value;
        if not IsV2 then
            OutlookSetup."Consent Received" := Value;
    end;

    internal procedure GetLastSyncAt(): DateTime
    begin
        if not IsV2 and OutlookSetupExists then
            exit(OutlookSetup."Last Sync At");
        exit(PayablesAgentSetupRecord."Last Sync At");
    end;

    internal procedure GetUserSecurityId(): Guid
    begin
        exit(PayablesAgentSetupRecord."User Security Id");
    end;

    internal procedure SetUserSecurityId(Value: Guid)
    begin
        PayablesAgentSetupRecord."User Security Id" := Value;
    end;

    internal procedure GetLastActivated(): DateTime
    begin
        exit(PayablesAgentSetupRecord."Last Activated");
    end;

    internal procedure SetLastActivated(Value: DateTime)
    begin
        PayablesAgentSetupRecord."Last Activated" := Value;
    end;

    internal procedure GetAppliedInstrConfigHash(): Text[64]
    begin
        exit(PayablesAgentSetupRecord."Applied Instr. Config Hash");
    end;

    internal procedure SetAppliedInstrConfigHash(Value: Text[64])
    begin
        PayablesAgentSetupRecord."Applied Instr. Config Hash" := Value;
    end;

    internal procedure GetAgentProfile(): Text[30]
    begin
        if IsV2 then
            exit(PayablesAgentV2ProfileTok);
        exit(PayablesAgentProfileTok);
    end;

    internal procedure GetAgentPermissionSet(): Code[20]
    begin
        if IsV2 then
            exit(PayablesAgentV2PermissionSetTok);
        exit(PayablesAgentPermissionSetTok);
    end;

    internal procedure GetAgentInstructionsResource(AgentDrivenLineMatching: Boolean): Text // TODO: Shouldnt receive this as param
    begin
        if PAV1V2Flag.IsV2Active() then
            exit(AgentInstructionsV2Tok);
        if AgentDrivenLineMatching then
            exit(AgentDrivenInstructionsTok);
        exit(AgentInstructionsTok);
    end;

    internal procedure SupportsEmailMonitoring(): Boolean
    begin
        exit(not PAV1V2Flag.IsV2Active());
    end;

    internal procedure SupportsAdditionalFields(): Boolean
    begin
        exit(not IsV2);
    end;

    internal procedure PrepareForApply(Enabling: Boolean)
    begin
        IsV2 := PAV1V2Flag.IsV2Active();
        if not Enabling then
            SetMonitorOutlook(false);
        if not GetMonitorOutlook() then
            exit;
        if not SupportsEmailMonitoring() then
            Error(MonitoringNotSupportedErr);
        if GetEmailReviewPolicy() = "PA Email Review Policy"::Unset then
            Error(ReviewPolicyRequiredErr);
        if IsNullGuid(GetEmailAccountId()) then
            Error(MailboxRequiredErr);
    end;

    // No Commit: backing configuration and persisted state participate in the caller's transaction.
    internal procedure ApplySetup(Enabling: Boolean)
    var
        StoredSetup: Record "Payables Agent Setup";
        Agent: Record Agent;
        TempEmailAccount: Record "Email Account" temporary;
        EmailAccount: Codeunit "Email Account";
    begin
        PrepareForApply(Enabling);
        if GetMonitorOutlook() then begin
            if not GetEmailMonitoringConsent() then
                Error(ConsentRequiredErr);
            if not Agent.Get(GetUserSecurityId()) then
                Error(EnabledAgentRequiredErr);
            if Agent.State <> Agent.State::Enabled then
                Error(EnabledAgentRequiredErr);
            EmailAccount.GetAllAccounts(false, TempEmailAccount);
            if not TempEmailAccount.Get(GetEmailAccountId(), "Email Connector"::"Microsoft 365") then
                Error(MailboxUnavailableErr);
        end;
        if not IsV2 then
            SyncV1BackingTables(Enabling)
        else
            DisableImport(); // Stop any remaining old importer when monitoring is off after a version switch.

        StoredSetup.GetOrCreateSetup();
        StoredSetup."Monitor Outlook" := PayablesAgentSetupRecord."Monitor Outlook";
        StoredSetup."Email Review Policy" := PayablesAgentSetupRecord."Email Review Policy";
        StoredSetup."Email Account Id" := GetEmailAccountId();
        StoredSetup."Email Folder" := GetEmailFolder();
        StoredSetup."Email Folder Id" := GetEmailFolderId();
        StoredSetup."Email Monitoring Consent" := GetEmailMonitoringConsent();
        StoredSetup."User Security Id" := PayablesAgentSetupRecord."User Security Id";
        StoredSetup."Last Activated" := PayablesAgentSetupRecord."Last Activated";
        StoredSetup."Applied Instr. Config Hash" := PayablesAgentSetupRecord."Applied Instr. Config Hash";
        StoredSetup."Last Sync At" := GetLastSyncAt();
        StoredSetup.Modify();
        GetSetup();
    end;

    internal procedure SaveUserSecurityId(UserSecurityId: Guid)
    var
        StoredSetup: Record "Payables Agent Setup";
    begin
        StoredSetup.GetOrCreateSetup();
        if StoredSetup."User Security Id" = UserSecurityId then
            exit;
        StoredSetup."User Security Id" := UserSecurityId;
        StoredSetup.Modify();
    end;

    internal procedure SaveAppliedInstrConfigHash(AppliedInstrConfigHash: Text[64])
    var
        StoredSetup: Record "Payables Agent Setup";
    begin
        StoredSetup.GetOrCreateSetup();
        if StoredSetup."Applied Instr. Config Hash" = AppliedInstrConfigHash then
            exit;
        StoredSetup."Applied Instr. Config Hash" := AppliedInstrConfigHash;
        StoredSetup.Modify();
    end;

    internal procedure DeleteSetup(TargetCompanyName: Text[30])
    var
        StoredSetup: Record "Payables Agent Setup";
    begin
        StoredSetup.ChangeCompany(TargetCompanyName);
        StoredSetup.DeleteAll();
    end;

    local procedure SyncV1BackingTables(Enabling: Boolean)
    var
        StoredOutlookSetup: Record "Outlook Setup";
        OutlookSetupExistedPreviously: Boolean;
        EmailAccountChanged: Boolean;
    begin
        OutlookSetupExistedPreviously := StoredOutlookSetup.FindFirst();
        EmailAccountChanged := StoredOutlookSetup."Email Account ID" <> GetEmailAccountId();
        StoredOutlookSetup."Email Account ID" := GetEmailAccountId();
        StoredOutlookSetup."Email Connector" := "Email Connector"::"Microsoft 365";
        StoredOutlookSetup."Email Folder" := GetEmailFolder();
        StoredOutlookSetup."Email Folder Id" := GetEmailFolderId();
        StoredOutlookSetup."Consent Received" := GetEmailMonitoringConsent();
        if EmailAccountChanged then
            StoredOutlookSetup."Last Sync At" := 0DT;
        if OutlookSetupExistedPreviously then
            StoredOutlookSetup.Modify()
        else
            StoredOutlookSetup.Insert();

        OutlookSetup := StoredOutlookSetup;
        OutlookSetupExists := true;
        SyncV1EDocumentService(Enabling, EmailAccountChanged);
    end;

    local procedure DisableImport()
    var
        EDocumentService: Record "E-Document Service";
    begin
        if EDocumentService.Get(PayablesAgentEDocServiceTok) then begin
            EDocumentService.Validate("Auto Import", false);
            EDocumentService.Modify();
        end;
    end;

    local procedure SyncV1EDocumentService(Enabling: Boolean; ReactivateAutoImport: Boolean)
    var
        EDocumentService: Record "E-Document Service";
        StoredOutlookSetup: Record "Outlook Setup";
        SupportedType: Record "E-Doc. Service Supported Type";
    begin
        if not Enabling then begin
            DisableImport();
            exit;
        end;
        if not EDocumentService.Get(PayablesAgentEDocServiceTok) then begin
            EDocumentService.Code := PayablesAgentEDocServiceTok;
            EDocumentService.Insert(true);
        end;
        SupportedType.InsertDefaultIfMissing(EDocumentService.Code, "E-Document Type"::"Purchase Invoice", "E-Doc. Supp. Type Direction"::Incoming);
        SupportedType.InsertDefaultIfMissing(EDocumentService.Code, "E-Document Type"::"Purchase Credit Memo", "E-Doc. Supp. Type Direction"::Incoming);
        EDocumentService.Validate("Automatic Import Processing", "E-Doc. Automatic Processing"::No);
        EDocumentService.Validate("Import Process", "E-Document Import Process"::"Version 2.0");
        Clear(EDocumentService."Import Start Time");
        EDocumentService."Import Minutes between runs" := 1;
        EDocumentService."Verify Purch. Total Amounts" := true;
        EDocumentService.Modify();
        if ReactivateAutoImport then
            EDocumentService.Validate("Auto Import", false);
        if GetMonitorOutlook() then begin
            EDocumentService.Validate("Service Integration V2", "Service Integration"::Outlook);
            EDocumentService.Validate("Auto Import", true);
            StoredOutlookSetup.FindFirst();
            StoredOutlookSetup.Validate(Enabled, true);
            StoredOutlookSetup.Modify();
        end else
            EDocumentService.Validate("Auto Import", false);
        EDocumentService.Modify();
    end;
}
