// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.PowerBIReports;

using System.Environment.Configuration;
using System.Globalization;
using System.Integration.PowerBI;
using System.Utilities;

codeunit 36962 "Power BI Report Setup"
{
    procedure EnsureUserAcceptedPowerBITerms()
    var
        PowerBIContextSettings: Record "Power BI Context Settings";
        PowerBIEmbedSetupWizard: Page "Power BI Embed Setup Wizard";
        PowerBiNotSetupErr: Label 'Power BI is not set up. You need to set up Power BI in order to continue.';
    begin
        PowerBIContextSettings.SetRange(UserSID, UserSecurityId());
        if PowerBIContextSettings.IsEmpty() then begin
            PowerBIEmbedSetupWizard.SetContext('');
            if PowerBIEmbedSetupWizard.RunModal() <> Action::OK then;

            if PowerBIContextSettings.IsEmpty() then
                Error(PowerBiNotSetupErr);
        end;
    end;

    /// <summary>
    /// Ensures that everything related to the specified Power BI report setup is properly configured, or directs to the appropriate setup pages. It errors if after the different prompts the report is not set up or in the process of being deployed. Typically used as a validation step before opening an embedded Power BI report page.
    /// </summary>
    /// <param name="PBIReportSetup">The Power BI report setup to validate.</param>
    /// <returns>The GUID of the Power BI report as configured in the setup.</returns>
    procedure OpenPowerBIEmbeddedReportPageValidation(PBIReportSetup: Enum "PBI Report Setup"): Guid
    var
        PowerBIAssistedSetup: Page "PowerBI Assisted Setup";
        DeploySelectionPage: Page "PBI Report Deploy. Selection";
        ConfiguredReportId: Guid;
        ReportNotSetupErr: Label 'Your report has not been setup in PowerBI Reports Setup. You need to set up this report in order to view it.', Comment = '%1 = report name';
    begin
        EnsureUserAcceptedPowerBITerms();
        ConfiguredReportId := GetConfiguredReportId(PBIReportSetup);
        if not IsNullGuid(ConfiguredReportId) then
            exit(ConfiguredReportId);
        PromptOpeningReportDeploymentsWhenInProgress(PBIReportSetup);
        if PowerBIAssistedSetup.RunModal() = Action::OK then
            if PowerBIAssistedSetup.IsDeployOOBReportsSelected() then
                DeploySelectionPage.RunModal();
        ConfiguredReportId := GetConfiguredReportId(PBIReportSetup);
        if not IsNullGuid(ConfiguredReportId) then
            exit(ConfiguredReportId);
        PromptOpeningReportDeploymentsWhenInProgress(PBIReportSetup);
        Error(ReportNotSetupErr)
    end;

    local procedure GetConfiguredReportId(PBIReportSetup: Enum "PBI Report Setup"): Guid
    var
        PowerBIReportsSetup: Record "PowerBI Reports Setup";
        RecRef: RecordRef;
        ReportSetup: Interface "PBI Report Setup";
        ConfiguredReportId: Guid;
    begin
        PowerBIReportsSetup.GetOrCreate();
        RecRef.GetTable(PowerBIReportsSetup);
        ReportSetup := PBIReportSetup;
        ConfiguredReportId := RecRef.Field(ReportSetup.GetSetupReportIdFieldNo()).Value();
        exit(ConfiguredReportId)
    end;

    procedure GetReportIdAndEnsureSetup(ReportName: Text; FieldId: Integer) ReportId: Guid
    var
        AssistedSetup: Page "PowerBI Assisted Setup";
        FinanceAppNotSetupErr: Label 'Your %1 Report has not been setup in PowerBI Reports Setup. You need to set up this report in order to view it.', Comment = '%1 = report name';
    begin
        ReportId := GetReportId(FieldId);
        if IsNullGuid(ReportId) then begin
            if AssistedSetup.RunModal() = Action::OK then;
            ReportId := GetReportId(FieldId);
            if IsNullGuid(ReportId) then
                Error(FinanceAppNotSetupErr, ReportName);
        end;
    end;

    procedure FindReportSetup(DeployableReportType: Enum "Power BI Deployable Report"; var ReportSetup: Interface "PBI Report Setup"): Boolean
    var
        Ordinal: Integer;
    begin
        foreach Ordinal in Enum::"PBI Report Setup".Ordinals() do begin
            ReportSetup := Enum::"PBI Report Setup".FromInteger(Ordinal);
            if ReportSetup.GetDeployableReportType() = DeployableReportType then
                exit(true);
        end;
        Clear(ReportSetup);
        exit(false);
    end;

    local procedure IsReportBeingDeployed(ReportSetup: Interface "PBI Report Setup"): Boolean
    var
        PowerBIDeployment: Record "Power BI Deployment";
    begin
        if not PowerBIDeployment.Get(ReportSetup.GetDeployableReportType()) then
            exit(false);
        PowerBIDeployment.GetUploadStatus();
        exit(not (PowerBIDeployment.GetUploadStatus() in [
            Enum::"Power BI Upload Status"::Completed,
            Enum::"Power BI Upload Status"::Failed,
            Enum::"Power BI Upload Status"::Skipped,
            Enum::"Power BI Upload Status"::PendingDeletion]));
    end;

    local procedure PromptOpeningReportDeploymentsWhenInProgress(ReportSetup: Interface "PBI Report Setup"): Boolean
    var
        ConfirmMgt: Codeunit "Confirm Management";
        ReportDeployingQst: Label 'Your %1 report is being deployed to Power BI. Would you like to open the Power BI Report Deployments page to track the status?', Comment = '%1 = report name';
        DeployableReport: Interface "Power BI Deployable Report";
    begin
        DeployableReport := ReportSetup.GetDeployableReportType();
        if IsReportBeingDeployed(ReportSetup) then begin
            if ConfirmMgt.GetResponse(StrSubstNo(ReportDeployingQst, DeployableReport.GetReportName())) then
                Page.Run(Page::"Power BI Report Deployments");
            Error('');
        end;
    end;

    local procedure GetReportId(FieldId: Integer): Guid
    var
        PowerBiReportsSetup: Record "PowerBI Reports Setup";
        RecRef: RecordRef;
        FldRef: FieldRef;
    begin
        if PowerBiReportsSetup.Get() then begin
            RecRef.Get(PowerBiReportsSetup.RecordId());
            FldRef := RecRef.Field(FieldId);
            exit(FldRef.Value());
        end;
    end;

    procedure LookupPowerBIReport(var ReportId: Guid; var ReportName: Text[200]): Boolean
    var
        WorkspaceId: Guid;
        WorkspaceName: Text[200];
    begin
        if LookupPowerBIWorkspace(WorkspaceId, WorkspaceName) then
            if LookupPowerBIReport(WorkspaceId, WorkspaceName, ReportId, ReportName) then
                exit(true);
    end;

    local procedure LookupPowerBIReport(WorkspaceId: Guid; WorkspaceName: Text[200]; var ReportId: Guid; var ReportName: Text[200]): Boolean
    var
        TempPowerBISelectionElement: Record "Power BI Selection Element" temporary;
        PowerBIWorkspaceMgt: Codeunit "Power BI Workspace Mgt.";
    begin
        PowerBIWorkspaceMgt.AddReportsForWorkspace(TempPowerBISelectionElement, WorkspaceId, WorkspaceName);
        TempPowerBISelectionElement.SetRange(Type, TempPowerBISelectionElement.Type::Report);
        if not IsNullGuid(ReportId) then begin
            TempPowerBISelectionElement.SetRange(ID, ReportId);
            if TempPowerBISelectionElement.FindFirst() then;
            TempPowerBISelectionElement.SetRange(ID);
        end;
        if Page.RunModal(Page::"Power BI Selection Lookup", TempPowerBISelectionElement) = Action::LookupOK then begin
            ReportId := TempPowerBISelectionElement.ID;
            ReportName := TempPowerBISelectionElement.Name;
            exit(true);
        end;
    end;

    local procedure LookupPowerBIWorkspace(var WorkspaceId: Guid; var WorkspaceName: Text[200]): Boolean
    var
        TempPowerBISelectionElement: Record "Power BI Selection Element" temporary;
        PowerBIWorkspaceMgt: Codeunit "Power BI Workspace Mgt.";
    begin
        PowerBIWorkspaceMgt.AddSharedWorkspaces(TempPowerBISelectionElement);
        TempPowerBISelectionElement.SetRange(Type, TempPowerBISelectionElement.Type::Workspace);
        if not IsNullGuid(WorkspaceId) then begin
            TempPowerBISelectionElement.SetRange(ID, WorkspaceId);
            if TempPowerBISelectionElement.FindFirst() then;
            TempPowerBISelectionElement.SetRange(ID);
        end;
        if Page.RunModal(Page::"Power BI Selection Lookup", TempPowerBISelectionElement) = Action::LookupOK then begin
            WorkspaceId := TempPowerBISelectionElement.ID;
            WorkspaceName := TempPowerBISelectionElement.Name;
            exit(true);
        end;
    end;

    procedure InitializeEmbeddedAddin(PowerBIManagement: ControlAddIn PowerBIManagement; ReportId: Guid; ReportPageTok: Text)
    var
        Language: Codeunit Language;
        PowerBIServiceMgt: Codeunit "Power BI Service Mgt.";
        PowerBIEmbedReportUrlTemplateTxt: Label 'https://app.powerbi.com/reportEmbed?reportId=%1', Locked = true;
    begin
        PowerBiServiceMgt.InitializeAddinToken(PowerBIManagement);
        PowerBiManagement.SetLocale(Language.GetUserLanguageTag());
        PowerBIManagement.SetFiltersVisible(true);
        PowerBIManagement.SetPageSelectionVisible(ReportPageTok = '');

        PowerBIManagement.EmbedPowerBIReport(
            StrSubstNo(PowerBIEmbedReportUrlTemplateTxt, ReportId),
            ReportId,
            ReportPageTok);
    end;

    procedure ShowPowerBIErrorNotification(ErrorCategory: Text; ErrorMessage: Text)
    var
        PowerBIContextSettings: Record "Power BI Context Settings";
        NotificationLifecycleMgt: Codeunit "Notification Lifecycle Mgt.";
        Notify: Notification;
        ErrorNotificationMsg: Label 'An error occurred while loading Power BI. Your Power BI embedded content might not work. Here are the error details: "%1: %2"', Comment = '%1: a short error code. %2: a verbose error message in english';
    begin
        Notify.Id := CreateGuid();
        Notify.Message(StrSubstNo(ErrorNotificationMsg, ErrorCategory, ErrorMessage));
        Notify.Scope := NotificationScope::LocalScope;
        NotificationLifecycleMgt.SendNotification(Notify, PowerBIContextSettings.RecordId());
    end;

    procedure LogReportLoaded(CorrelationId: Guid)
    var
        PowerBIServiceMgt: Codeunit "Power BI Service Mgt.";
    begin
        PowerBIServiceMgt.LogVisualLoaded(CorrelationId, Enum::"Power BI Element Type"::Report);
    end;

    procedure LogError(Operation: Text; ErrorText: Text)
    var
        PowerBIServiceMgt: Codeunit "Power BI Service Mgt.";
    begin
        PowerBIServiceMgt.LogEmbedError(Operation);
    end;
}
