// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.Agent.PayablesAgent;

using Microsoft.eServices.EDocument;
using Microsoft.eServices.EDocument.Integration;
using Microsoft.eServices.EDocument.Processing.Import;
using Microsoft.EServices.EDocumentConnector.Microsoft365;
using System.Email;

/// <summary>
/// The only entry point to the stored Payables Agent setup. It loads the setup into "PA Detailed Setup" and saves it
/// back, knowing where each value is stored for the active Payables Agent version: "Payables Agent Setup" and, for v1,
/// the Outlook Setup and the E-Document Service the e-document pipeline reads. It also fills the values derived from
/// the version. Everything else in the app consumes "PA Detailed Setup"; logic on top of it lives in
/// "Payables Agent Setup" (codeunit). One of the codeunits allowed to reference "PA V1V2 Flag".
/// </summary>
codeunit 3343 "PA Setup"
{
    Access = Internal;
    InherentEntitlements = X;
    InherentPermissions = X;
    Permissions = tabledata "Payables Agent Setup" = RIMD, tabledata "Outlook Setup" = RIM;

    var
        PAV1V2Flag: Codeunit "PA V1V2 Flag";
        PayablesAgentProfileTok: Label 'Payables Agent', Locked = true;
        PayablesAgentV2ProfileTok: Label 'Payables Agent Profile', Locked = true;
        PayablesAgentPermissionSetTok: Label 'Payables Ag. - Run', Locked = true;
        PayablesAgentV2PermissionSetTok: Label 'Payables Ag. - RunV2', Locked = true;
        PayablesAgentEDocServiceTok: Label 'AGENT', Locked = true;

    #region Load

    /// <summary>
    /// Loads the setup. The stored setup is created when it does not exist yet.
    /// </summary>
    internal procedure GetSetup(var TempPADetailedSetup: Record "PA Detailed Setup")
    begin
        LoadSetup(TempPADetailedSetup, true);
    end;

    /// <summary>
    /// Loads the setup, optionally without creating the stored setup when it does not exist yet. When it does not
    /// exist and is not created, the configured and maintained values are blank; the derived values are still filled.
    /// </summary>
    /// <returns>True when the stored setup exists or was created.</returns>
    internal procedure GetSetup(var TempPADetailedSetup: Record "PA Detailed Setup"; InsertIfMissing: Boolean): Boolean
    begin
        exit(LoadSetup(TempPADetailedSetup, InsertIfMissing));
    end;

    #endregion

    #region Save

    /// <summary>
    /// Saves the configured and maintained values. Under v1 the configured values are first projected onto the
    /// Outlook Setup and the E-Document Service. The setup is reloaded afterwards. Starts a write transaction.
    /// </summary>
    /// <param name="Enabling">Whether the agent is enabled by this change (v1: drives the E-Document Service auto-import).</param>
    internal procedure ApplySetup(var TempPADetailedSetup: Record "PA Detailed Setup"; Enabling: Boolean)
    var
        PayablesAgentSetup: Record "Payables Agent Setup";
    begin
        if not PAV1V2Flag.IsV2Active() then
            SyncV1BackingTables(TempPADetailedSetup, Enabling);

        PayablesAgentSetup.GetOrCreateSetup();
        PayablesAgentSetup."Monitor Outlook" := TempPADetailedSetup."Monitor Outlook";
        PayablesAgentSetup."Email Review Policy" := TempPADetailedSetup."Email Review Policy";
        PayablesAgentSetup."Email Account Id" := TempPADetailedSetup."Email Account Id";
        PayablesAgentSetup."Email Folder" := TempPADetailedSetup."Email Folder";
        PayablesAgentSetup."Email Folder Id" := TempPADetailedSetup."Email Folder Id";
        PayablesAgentSetup."Email Monitoring Consent" := TempPADetailedSetup."Email Monitoring Consent";
        PayablesAgentSetup."User Security Id" := TempPADetailedSetup."User Security Id";
        PayablesAgentSetup."Last Activated" := TempPADetailedSetup."Last Activated";
        PayablesAgentSetup."Applied Instr. Config Hash" := TempPADetailedSetup."Applied Instr. Config Hash";
        PayablesAgentSetup."Last Sync At" := TempPADetailedSetup."Last Sync At";
        PayablesAgentSetup.Modify();

        GetSetup(TempPADetailedSetup);
    end;

    /// <summary>
    /// Saves the agent user the setup points to. Touches only the stored Payables Agent setup.
    /// </summary>
    internal procedure SaveUserSecurityId(UserSecurityId: Guid)
    var
        PayablesAgentSetup: Record "Payables Agent Setup";
    begin
        PayablesAgentSetup.GetOrCreateSetup();
        if PayablesAgentSetup."User Security Id" = UserSecurityId then
            exit;
        PayablesAgentSetup."User Security Id" := UserSecurityId;
        PayablesAgentSetup.Modify();
    end;

    /// <summary>
    /// Saves the hash of the configuration the agent instructions were applied with. Touches only the stored Payables
    /// Agent setup.
    /// </summary>
    internal procedure SaveAppliedInstrConfigHash(AppliedInstrConfigHash: Text[64])
    var
        PayablesAgentSetup: Record "Payables Agent Setup";
    begin
        PayablesAgentSetup.GetOrCreateSetup();
        if PayablesAgentSetup."Applied Instr. Config Hash" = AppliedInstrConfigHash then
            exit;
        PayablesAgentSetup."Applied Instr. Config Hash" := AppliedInstrConfigHash;
        PayablesAgentSetup.Modify();
    end;

    /// <summary>
    /// Deletes the stored setup of a company, for example of a company created by copying this one.
    /// </summary>
    internal procedure DeleteSetup(TargetCompanyName: Text[30])
    var
        PayablesAgentSetup: Record "Payables Agent Setup";
    begin
        PayablesAgentSetup.ChangeCompany(TargetCompanyName);
        PayablesAgentSetup.DeleteAll();
    end;

    #endregion

    #region Private

    local procedure LoadSetup(var TempPADetailedSetup: Record "PA Detailed Setup"; InsertIfMissing: Boolean) SetupExists: Boolean
    var
        PayablesAgentSetup: Record "Payables Agent Setup";
        OutlookSetup: Record "Outlook Setup";
    begin
        Clear(TempPADetailedSetup);
        TempPADetailedSetup.DeleteAll();

        SetupExists := PayablesAgentSetup.GetSetup(InsertIfMissing);
        TempPADetailedSetup."Monitor Outlook" := PayablesAgentSetup."Monitor Outlook";
        TempPADetailedSetup."Email Review Policy" := PayablesAgentSetup."Email Review Policy";
        TempPADetailedSetup."Email Account Id" := PayablesAgentSetup."Email Account Id";
        TempPADetailedSetup."Email Folder" := PayablesAgentSetup."Email Folder";
        TempPADetailedSetup."Email Folder Id" := PayablesAgentSetup."Email Folder Id";
        TempPADetailedSetup."Email Monitoring Consent" := PayablesAgentSetup."Email Monitoring Consent";
        TempPADetailedSetup."User Security Id" := PayablesAgentSetup."User Security Id";
        TempPADetailedSetup."Last Activated" := PayablesAgentSetup."Last Activated";
        TempPADetailedSetup."Applied Instr. Config Hash" := PayablesAgentSetup."Applied Instr. Config Hash";
        TempPADetailedSetup."Last Sync At" := PayablesAgentSetup."Last Sync At";
        TempPADetailedSetup."Agent Profile" := PayablesAgentV2ProfileTok;
        TempPADetailedSetup."Agent Permission Set" := PayablesAgentV2PermissionSetTok;
        TempPADetailedSetup."Supports Additional Fields" := false;

        // V1 overrides
        if not PAV1V2Flag.IsV2Active() then begin
            TempPADetailedSetup."Agent Profile" := PayablesAgentProfileTok;
            TempPADetailedSetup."Agent Permission Set" := PayablesAgentPermissionSetTok;
            TempPADetailedSetup."Supports Additional Fields" := true;
            if OutlookSetup.FindFirst() then begin
                TempPADetailedSetup."Email Account Id" := OutlookSetup."Email Account ID";
                TempPADetailedSetup."Email Folder" := OutlookSetup."Email Folder";
                TempPADetailedSetup."Email Folder Id" := OutlookSetup."Email Folder Id";
                TempPADetailedSetup."Last Sync At" := OutlookSetup."Last Sync At";
                TempPADetailedSetup."Email Monitoring Consent" := OutlookSetup."Consent Received";
            end;
        end;
    end;

    /// <summary>
    /// Projects the setup onto the v1 backing records
    /// </summary>
    local procedure SyncV1BackingTables(var TempPADetailedSetup: Record "PA Detailed Setup"; Enabling: Boolean)
    var
        OutlookSetup: Record "Outlook Setup";
        OutlookSetupExistedPreviously: Boolean;
        EmailAccountChanged: Boolean;
    begin
        OutlookSetupExistedPreviously := OutlookSetup.FindFirst();
        EmailAccountChanged := OutlookSetup."Email Account ID" <> TempPADetailedSetup."Email Account Id";
        OutlookSetup."Email Account ID" := TempPADetailedSetup."Email Account Id";
        OutlookSetup."Email Connector" := "Email Connector"::"Microsoft 365";
        OutlookSetup."Email Folder" := TempPADetailedSetup."Email Folder";
        OutlookSetup."Email Folder Id" := TempPADetailedSetup."Email Folder Id";
        OutlookSetup."Consent Received" := TempPADetailedSetup."Email Monitoring Consent";
        if EmailAccountChanged then
            OutlookSetup."Last Sync At" := 0DT;
        if OutlookSetupExistedPreviously then
            OutlookSetup.Modify()
        else
            OutlookSetup.Insert();

        SyncV1EDocumentService(TempPADetailedSetup, Enabling, EmailAccountChanged);
    end;

    local procedure SyncV1EDocumentService(var TempPADetailedSetup: Record "PA Detailed Setup"; Enabling: Boolean; ReactivateAutoImport: Boolean)
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
        if TempPADetailedSetup."Monitor Outlook" then begin
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
}
