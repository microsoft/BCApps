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
using System.Environment;
using System.Privacy;
using System.Reflection;
using System.Security.AccessControl;
using System.Security.User;

/// <summary>
/// SDK for the Payables Agent setup: reads the setup, obtains consent, validates the mailbox, configures the agent
/// and applies the setup, adapting to whether the setup is backed by the Outlook Setup and E-Document Service (v1)
/// or self-contained (v2). Together with "PA Task" and "PA Task Collection", the only code that branches on
/// "PA V1V2 Flag".
/// </summary>
codeunit 3343 "PA Setup"
{
    Access = Internal;
    InherentEntitlements = X;
    InherentPermissions = X;
    Permissions = tabledata "Payables Agent Setup" = RIM, tabledata Agent = R, tabledata "Outlook Setup" = RIM;

    #region Setup - Get

    /// <summary>
    /// The persisted Payables Agent setup. Under v1 the mailbox configuration and consent still live on the Outlook
    /// Setup record, so they are read across; under v2 the setup already owns everything.
    /// </summary>
    internal procedure GetSetup(var PayablesAgentSetup: Record "Payables Agent Setup")
    var
        OutlookSetup: Record "Outlook Setup";
    begin
        PayablesAgentSetup.GetSetup();
        if PAV1V2Flag.IsV2Active() then
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
    /// When incoming emails need a human review before the agent processes them.
    /// </summary>
    internal procedure GetEmailReviewPolicy(): Enum "PA Email Review Policy"
    var
        PayablesAgentSetup: Record "Payables Agent Setup";
    begin
        GetSetup(PayablesAgentSetup);
        exit(PayablesAgentSetup."Email Review Policy");
    end;

    internal procedure GetReviewIncomingInvoice(): Boolean
    var
        PayablesAgentSetup: Record "Payables Agent Setup";
    begin
        GetSetup(PayablesAgentSetup);
        exit(PayablesAgentSetup."Review Incoming Invoice");
    end;

    /// <summary>
    /// When the agent was last activated. Blank when it was activated before this was recorded.
    /// </summary>
    internal procedure GetLastActivated(): DateTime
    var
        PayablesAgentSetup: Record "Payables Agent Setup";
    begin
        GetSetup(PayablesAgentSetup);
        exit(PayablesAgentSetup."Last Activated");
    end;

    /// <summary>
    /// The profile assigned to the agent on activation: the v2 task-based role center when v2 is active, otherwise
    /// the v1 draft-based profile.
    /// </summary>
    internal procedure GetDefaultProfile(var TempAllProfile: Record "All Profile" temporary)
    var
        Agent: Codeunit Agent;
        ModuleInfo: ModuleInfo;
    begin
        NavApp.GetCurrentModuleInfo(ModuleInfo);
        if PAV1V2Flag.IsV2Active() then
            Agent.PopulateDefaultProfile(PayablesAgentV2ProfileTok, ModuleInfo.Id, TempAllProfile)
        else
            Agent.PopulateDefaultProfile(PayablesAgentProfileTok, ModuleInfo.Id, TempAllProfile);
    end;

    /// <summary>
    /// The permission sets the agent gets on activation: "Payables Ag. - RunV2" for the v2 task-based flow when v2 is
    /// active, otherwise the v1 draft-based "Payables Ag. - Run".
    /// </summary>
    internal procedure GetDefaultAccessControls(var TempAccessControlBuffer: Record "Access Control Buffer" temporary)
    var
        ModuleInfo: ModuleInfo;
    begin
        NavApp.GetCurrentModuleInfo(ModuleInfo);
        TempAccessControlBuffer.Init();
        TempAccessControlBuffer."Company Name" := CopyStr(CompanyName(), 1, MaxStrLen(TempAccessControlBuffer."Company Name"));
        TempAccessControlBuffer.Scope := TempAccessControlBuffer.Scope::System;
        TempAccessControlBuffer."App ID" := ModuleInfo.Id;
        if PAV1V2Flag.IsV2Active() then
            TempAccessControlBuffer."Role ID" := PayablesAgentV2PermissionSetTok
        else
            TempAccessControlBuffer."Role ID" := PayablesAgentPermissionSetTok;
        TempAccessControlBuffer.Insert();
    end;

    /// <summary>
    /// Whether a mailbox folder (rather than the whole mailbox) is monitored. Under v1 the folder is read from the
    /// Outlook Setup the e-document pipeline uses; without that record no folder is monitored (fail closed: a
    /// configured folder skips sender review).
    /// </summary>
    internal procedure MonitoredFolderConfigured(): Boolean
    var
        PayablesAgentSetup: Record "Payables Agent Setup";
        OutlookSetup: Record "Outlook Setup";
    begin
        if not PAV1V2Flag.IsV2Active() then begin
            if not OutlookSetup.FindFirst() then
                exit(false);
            exit(OutlookSetup."Email Folder" <> '');
        end;
        GetSetup(PayablesAgentSetup);
        exit(PayablesAgentSetup."Email Folder" <> '');
    end;

    /// <summary>
    /// Whether the agent exists and is enabled.
    /// </summary>
    internal procedure IsAgentEnabled(): Boolean
    var
        Agent: Record Agent;
        PayablesAgentSetup: Record "Payables Agent Setup";
    begin
        PayablesAgentSetup.GetSetup();
        if not Agent.Get(PayablesAgentSetup."User Security Id") then
            exit(false);
        exit(Agent.State = Agent.State::Enabled);
    end;

    /// <summary>
    /// Fills the update parameters with the current setup: the agent framework setup buffer and the setup.
    /// </summary>
    internal procedure LoadParameters(var PASetupUpdateParameters: Codeunit "PA Setup Update Parameters")
    var
        Agent: Record Agent;
        PayablesAgentSetupRec: Record "Payables Agent Setup";
        TempAgentSetupBuffer: Record "Agent Setup Buffer";
        PayablesAgentSetup: Codeunit "Payables Agent Setup";
        AgentSetup: Codeunit "Agent Setup";
    begin
        // Skipping configuring the Agent framework records is valid in tests
        if not PASetupUpdateParameters.GetSkipAgentConfiguration() then begin
            if PayablesAgentSetup.GetAgent(Agent) then;
            AgentSetup.GetSetupRecord(
                TempAgentSetupBuffer,
                Agent."User Security ID",
                "Agent Metadata Provider"::"Payables Agent",
                PayablesAgentSetup.AgentUserName(),
                PayablesAgentSetup.AgentDisplayName(),
                PayablesAgentSetup.AgentSummary()
            );
            PASetupUpdateParameters.SetAgentSetupBuffer(TempAgentSetupBuffer);
        end;

        GetSetup(PayablesAgentSetupRec);
        PASetupUpdateParameters.SetDesiredSetup(PayablesAgentSetupRec);
    end;

    /// <summary>
    /// Whether the setup offers configuring the additional purchase line fields of the e-document purchase drafts.
    /// </summary>
    internal procedure SupportsAdditionalFieldsSetup(): Boolean
    begin
        exit(not PAV1V2Flag.IsV2Active());
    end;

    #endregion

    #region Setup - Interactive

    /// <summary>
    /// Lets the user pick the Microsoft 365 mailbox to monitor.
    /// </summary>
    /// <returns>True when a mailbox was picked; the account id and address are then updated.</returns>
    internal procedure SelectEmailAccount(var EmailAccountId: Guid; var EmailAddress: Text): Boolean
    var
        TempEmailAccount: Record "Email Account" temporary;
        OutlookIntegration: Codeunit "Outlook Integration Impl.";
    begin
        TempEmailAccount."Account Id" := EmailAccountId;
        TempEmailAccount.Connector := "Email Connector"::"Microsoft 365";
        if not OutlookIntegration.SelectEmailAccount(TempEmailAccount) then
            exit(false);
        EmailAccountId := TempEmailAccount."Account Id";
        EmailAddress := TempEmailAccount."Email Address";
        exit(true);
    end;

    /// <summary>
    /// Opens the configuration of the additional purchase line fields (v1 purchase drafts). Commits.
    /// </summary>
    /// <returns>True when the configuration was confirmed.</returns>
    internal procedure OpenAdditionalFieldsSetup(): Boolean
    var
        PADraftBasedSetup: Codeunit "PA Draft Based Setup";
        EDocAdditionalFieldsSetup: Page "EDoc Additional Fields Setup";
    begin
        if PAV1V2Flag.IsV2Active() then
            exit(false);
        EDocAdditionalFieldsSetup.SetEDocumentService(PADraftBasedSetup.GetOrCreateAgentEDocumentService());
        Commit();
        EDocAdditionalFieldsSetup.LookupMode := true;
        exit(EDocAdditionalFieldsSetup.RunModal() = Action::LookupOK);
    end;

    /// <summary>
    /// Obtains the user's consent for the agent to monitor the mailbox, using the standard Microsoft-service consent
    /// experience, and records it on the desired setup. Runs modally, so it must run before any write transaction.
    /// </summary>
    /// <returns>False when consent is declined.</returns>
    internal procedure ObtainConsent(var PASetupUpdateParameters: Codeunit "PA Setup Update Parameters"): Boolean
    var
        TempPayablesAgentSetup: Record "Payables Agent Setup" temporary;
        CustomerConsentMgt: Codeunit "Customer Consent Mgt.";
    begin
        TempPayablesAgentSetup := PASetupUpdateParameters.GetDesiredSetup();
        if TempPayablesAgentSetup."Email Monitoring Consent" then
            exit(true);
        if not CustomerConsentMgt.ConfirmUserConsentToMicrosoftService() then
            exit(false);
        TempPayablesAgentSetup."Email Monitoring Consent" := true;
        PASetupUpdateParameters.SetDesiredSetup(TempPayablesAgentSetup);
        exit(true);
    end;

    /// <summary>
    /// Checks that the desired mailbox is selected and, in SaaS, reachable. Must run before any write transaction
    /// (Codeunit.Run is used for the reachability check).
    /// </summary>
    internal procedure ValidateMailbox(var PASetupUpdateParameters: Codeunit "PA Setup Update Parameters")
    var
        EnvironmentInformation: Codeunit "Environment Information";
        PAValidateSetup: Codeunit "PA Validate Setup";
        ErrorAccountNotConnecting: ErrorInfo;
    begin
        if not PASetupUpdateParameters.MonitorEmail() then
            exit;
        if IsNullGuid(PASetupUpdateParameters.GetDesiredSetup()."Email Account Id") then
            Error(ActivateWithoutMailboxNameErr);

        // SaaS only requirement. The setup already carries the mailbox configuration.
        if not EnvironmentInformation.IsSaaS() then
            exit;
        PAValidateSetup.ConfigureSetupToValidate(PASetupUpdateParameters.GetDesiredSetup());
        if not PAValidateSetup.Run() then begin
            ErrorAccountNotConnecting.Title(EmailConnectionErr);
            ErrorAccountNotConnecting.Message(StrSubstNo(EmailConnectionMessageErr, PASetupUpdateParameters.GetEmailAccount()."Email Address"));
            ErrorAccountNotConnecting.PageNo := Page::"Email Accounts";
            ErrorAccountNotConnecting.AddNavigationAction(EmailConnectionNavigationActionLbl);
            Error(ErrorAccountNotConnecting);
        end;
    end;

    #endregion

    #region Setup - Set

    /// <summary>
    /// Applies the desired setup. Under v1 it is first projected onto the Outlook Setup and the E-Document Service
    /// the e-document pipeline reads. Then the agent framework records are configured (unless skipped) and the
    /// Payables Agent setup is persisted; the persisted setup is written back to the parameters.
    /// Starts write transactions.
    /// </summary>
    internal procedure ApplySetup(var PASetupUpdateParameters: Codeunit "PA Setup Update Parameters")
    var
        PayablesAgentSetup: Record "Payables Agent Setup";
        TempPayablesAgentSetup: Record "Payables Agent Setup" temporary;
    begin
        TempPayablesAgentSetup := PASetupUpdateParameters.GetDesiredSetup();
        if not PAV1V2Flag.IsV2Active() then
            SyncV1BackingTables(TempPayablesAgentSetup, PASetupUpdateParameters.Enabling());

        PayablesAgentSetup.GetSetup();
        PayablesAgentSetup.TransferFields(TempPayablesAgentSetup, false);
        if not PASetupUpdateParameters.GetSkipAgentConfiguration() then // Skipping the agent's configuration is valid in tests
            PayablesAgentSetup."User Security Id" := ConfigureAgent(PASetupUpdateParameters, PayablesAgentSetup."Applied Instr. Config Hash");
        PayablesAgentSetup.Modify();

        PASetupUpdateParameters.SetDesiredSetup(PayablesAgentSetup);
    end;

    /// <summary>
    /// Gives the users that have recently created posted purchase invoices access to the agent of the applied setup.
    /// </summary>
    internal procedure GrantAccessToEligibleUsers(var PASetupUpdateParameters: Codeunit "PA Setup Update Parameters")
    var
        PayablesAgentSetup: Codeunit "Payables Agent Setup";
    begin
        PayablesAgentSetup.InsertAccessControlForEligibleUsers(PASetupUpdateParameters.GetDesiredSetup()."User Security Id");
    end;

    #endregion

    #region Private

    local procedure ConfigureAgent(var PASetupUpdateParameters: Codeunit "PA Setup Update Parameters"; var AppliedInstrConfigHash: Text[64]): Guid
    var
        AgentAdminPS: Record "Aggregate Permission Set";
        AccessControl: Record "Access Control";
        TempModifiedAgentAccessControl: Record "Agent Access Control" temporary;
        TempAgentSetupBuffer: Record "Agent Setup Buffer";
        AgentSetup: Codeunit "Agent Setup";
        PayablesAgentSetup: Codeunit "Payables Agent Setup";
        UserPermissions: Codeunit "User Permissions";
        CurrentModuleInfo: ModuleInfo;
        AgentUserId: Guid;
        AgentAdminPermissionSetTok: Label 'Payables Ag. - Adm.', Locked = true;
    begin
        PASetupUpdateParameters.GetAgentSetupBuffer(TempAgentSetupBuffer);
        AgentUserId := AgentSetup.SaveChanges(TempAgentSetupBuffer);
        // We assign the necessary permission sets to the users depending on whether or not users are able to modify the agent
        NavApp.GetCurrentModuleInfo(CurrentModuleInfo);
        Clear(AgentAdminPS);
        AgentAdminPS.SetRange("App ID", CurrentModuleInfo.Id);
        AgentAdminPS.SetRange("Role ID", AgentAdminPermissionSetTok);
        AgentAdminPS.FindFirst();
        Clear(TempModifiedAgentAccessControl);
        if TempModifiedAgentAccessControl.FindSet() then
            repeat
                if TempModifiedAgentAccessControl."Can Configure Agent" then
                    if (not UserPermissions.IsSuper(TempModifiedAgentAccessControl."User Security ID")) and (not UserPermissions.HasUserPermissionSetAssigned(TempModifiedAgentAccessControl."User Security ID", CompanyName(), AgentAdminPermissionSetTok, AccessControl.Scope::System, CurrentModuleInfo.Id)) then
                        // If the user is allowed to configure the agent, we assign the admin permission set
                        UserPermissions.AssignPermissionSets(TempModifiedAgentAccessControl."User Security ID", CompanyName(), AgentAdminPS);
            until TempModifiedAgentAccessControl.Next() = 0;

        // Apply agent instructions and capture the hash; ApplySetup persists it in the single final Modify() so
        // there is no nested row modification of Payables Agent Setup.
        if not IsNullGuid(AgentUserId) then
            AppliedInstrConfigHash := PayablesAgentSetup.ApplyAgentInstructions(AgentUserId);
        exit(AgentUserId);
    end;

    /// <summary>
    /// Projects the setup onto the v1 backing records (Outlook Setup and the E-Document Service).
    /// </summary>
    local procedure SyncV1BackingTables(var PayablesAgentSetup: Record "Payables Agent Setup"; Enabling: Boolean)
    var
        OutlookSetup: Record "Outlook Setup";
        OutlookSetupExistedPreviously: Boolean;
        EmailAccountChanged: Boolean;
    begin
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

        SyncV1EDocumentService(PayablesAgentSetup, Enabling, EmailAccountChanged);
    end;

    local procedure SyncV1EDocumentService(var PayablesAgentSetup: Record "Payables Agent Setup"; Enabling: Boolean; ReactivateAutoImport: Boolean)
    var
        EDocumentService: Record "E-Document Service";
        OutlookSetup: Record "Outlook Setup";
        PADraftBasedSetup: Codeunit "PA Draft Based Setup";
    begin
        // If we intend to disable the agent, we need to disable the E-Document Service's auto-import as well
        if not Enabling then begin
            if EDocumentService.Get(PayablesAgentEDocServiceTok) then begin
                EDocumentService.Validate("Auto Import", false);
                EDocumentService.Modify();
            end;
            exit;
        end;
        EDocumentService := PADraftBasedSetup.GetOrCreateAgentEDocumentService();
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

    #endregion

    var
        PAV1V2Flag: Codeunit "PA V1V2 Flag";
        PayablesAgentProfileTok: Label 'Payables Agent', Locked = true;
        PayablesAgentV2ProfileTok: Label 'Payables Agent V2', Locked = true;
        PayablesAgentPermissionSetTok: Label 'Payables Ag. - Run', Locked = true;
        PayablesAgentV2PermissionSetTok: Label 'Payables Ag. - RunV2', Locked = true;
        PayablesAgentEDocServiceTok: Label 'AGENT', Locked = true;
        ActivateWithoutMailboxNameErr: Label 'To activate the agent with the current settings, a mailbox must be selected first.';
        EmailConnectionErr: Label 'Failed to connect to the email mailbox.';
        EmailConnectionMessageErr: Label 'Connection to mailbox failed. Please review the email account configuration for email %1', Comment = '%1 - Email account name';
        EmailConnectionNavigationActionLbl: Label 'Show email accounts';
}
