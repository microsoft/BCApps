namespace System.Integration.PowerBI;

using System;
using System.Azure.Identity;
using System.Environment;
using System.Utilities;

/// <summary>
/// Executes exactly one upload step for a single report within a Codeunit.Run() boundary,
/// isolating errors so the caller can capture failure details via GetLastErrorText().
/// The synchronizer owns the step sequence loop and calls this codeunit once per step.
/// </summary>
codeunit 6334 "Power BI Upload Step Runner"
{
    Access = Internal;

    var
        PowerBIServiceMgt: Codeunit "Power BI Service Mgt.";
        AzureAdMgt: Codeunit "Azure AD Mgt.";
        EnvironmentInformation: Codeunit "Environment Information";
        GlobalReport: Interface "Power BI Uploadable Report";
        GlobalUploadTracker: Interface "Power BI Upload Tracker";
        GlobalContext: Text[50];
        IsConfigured: Boolean;
        ReportEnvNameTxt: Label '%1 (%2 - %3)', Locked = true;
        StartingImportTelemetryMsg: Label 'Starting actual import for internal blob ID: %1.', Locked = true;
        StartRetrievingImportTelemetryMsg: Label 'Retrieving import id %1.', Locked = true;
        UpdatingDatasetParametersTelemetryMsg: Label 'Updating dataset %1 with company "%2" and environment "%3".', Locked = true;
        GettingDatasourceForDatasetTelemetryMsg: Label 'Getting datasource for dataset %1.', Locked = true;
        RefreshingDatasetTelemetryMsg: Label 'Refreshing dataset %1.', Locked = true;
        UpdatingParametersFailedTelemetryMsg: Label 'Updating report parameters failed,', Locked = true;
        EmptyAccessTokenTelemetryMsg: Label 'Encountered an empty access token.', Locked = true;
        NotConfiguredErr: Label 'Power BI Upload Step Runner was not configured before execution. Call Configure() first.', Locked = true;
        PowerBIImportRequestFailedErr: Label 'Power BI import request failed.';
        PowerBIImportRetrievalFailedErr: Label 'Power BI import retrieval failed.';
        PowerBIDatasetRefreshFailedErr: Label 'Power BI dataset refresh failed.';

    trigger OnRun()
    var
        PowerBIServiceProvider: Interface "Power BI Service Provider";
        BlobInStream: InStream;
        FinalReportName: Text;
    begin
        // Configure() must always be called before OnRun(). If this error fires, the caller has a bug.
        if not IsConfigured then
            Error(NotConfiguredErr);

        PowerBIServiceMgt.CreateServiceProvider(PowerBIServiceProvider);
        FinalReportName := MakeReportNameForUpload(GlobalReport.GetReportName(), EnvironmentInformation.GetEnvironmentName(), CompanyName());

        case GlobalUploadTracker.GetStatus() of
            Enum::"Power BI Upload Status"::NotStarted:
                begin
                    GlobalReport.GetStream(BlobInStream);
                    StartImport(PowerBIServiceProvider, BlobInStream, FinalReportName);
                end;
            Enum::"Power BI Upload Status"::ImportStarted:
                GetImport(PowerBIServiceProvider);
            Enum::"Power BI Upload Status"::ImportFinished:
                UpdateParameters(PowerBIServiceProvider);
            Enum::"Power BI Upload Status"::ParametersUpdated:
                RefreshDataset(PowerBIServiceProvider);
            Enum::"Power BI Upload Status"::DataRefreshed:
                begin
                    GlobalReport.FinalizeUpload(GlobalUploadTracker, GlobalContext, FinalReportName);
                    GlobalUploadTracker.TransitionTo(Enum::"Power BI Upload Status"::Completed);
                end;
        end;

        GlobalUploadTracker.Save();
    end;

    internal procedure Configure(
        var NewReport: Interface "Power BI Uploadable Report";
        var NewUploadTracker: Interface "Power BI Upload Tracker";
        NewContext: Text[50])
    begin
        GlobalReport := NewReport;
        GlobalUploadTracker := NewUploadTracker;
        GlobalContext := NewContext;
        IsConfigured := true;
    end;

    local procedure StartImport(PowerBIServiceProvider: Interface "Power BI Service Provider"; BlobInStream: InStream; ReportName: Text)
    var
        OperationResult: DotNet OperationResult;
        ImportId: Guid;
        Overwrite: Boolean;
    begin
        Session.LogMessage('0000G1Y', StrSubstNo(StartingImportTelemetryMsg, GlobalReport.GetReportKey()), Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', PowerBIServiceMgt.GetPowerBiTelemetryCategory());

        Overwrite := GlobalUploadTracker.ShouldOverwrite(GlobalReport.GetReportVersion());

        PowerBIServiceProvider.StartImport(
            BlobInStream,
            ReportName,
            Overwrite,
            ImportId,
            OperationResult);

        if OperationResult.Successful then begin
            GlobalUploadTracker.TransitionTo(Enum::"Power BI Upload Status"::ImportStarted);
            GlobalUploadTracker.SetImportId(ImportId);
        end else
            if OperationResult.ShouldRetry then
                GlobalUploadTracker.ScheduleRetry(GetRetryAfterOrDefault(OperationResult.RetryAfter))
            else
                Error(PowerBIImportRequestFailedErr);
    end;

    local procedure GetImport(PowerBIServiceProvider: Interface "Power BI Service Provider")
    var
        OperationResult: DotNet OperationResult;
        ReturnedReport: DotNet ReturnedReport;
        ImportState: Text;
    begin
        Session.LogMessage('0000G1Z', StrSubstNo(StartRetrievingImportTelemetryMsg, GlobalUploadTracker.GetImportId()), Verbosity::Normal, DataClassification::OrganizationIdentifiableInformation, TelemetryScope::ExtensionPublisher, 'Category', PowerBIServiceMgt.GetPowerBiTelemetryCategory());

        PowerBIServiceProvider.GetImport(GlobalUploadTracker.GetImportId(), ImportState, ReturnedReport, OperationResult);

        if OperationResult.Successful then begin
            GlobalUploadTracker.TransitionTo(Enum::"Power BI Upload Status"::ImportFinished);
            GlobalUploadTracker.SetImportResult(ReturnedReport.ReportId, ReturnedReport.EmbedUrl, ReturnedReport.DatasetId);
        end else
            if OperationResult.ShouldRetry then
                GlobalUploadTracker.ScheduleRetry(GetRetryAfterOrDefault(OperationResult.RetryAfter))
            else
                Error(PowerBIImportRetrievalFailedErr);
    end;

    local procedure UpdateParameters(PowerBIServiceProvider: Interface "Power BI Service Provider")
    var
        UrlHelper: Codeunit "Url Helper";
        BusinessCentralAccessToken: SecretText;
        NewParameters: Dictionary of [Text, Text];
        OperationResult: DotNet OperationResult;
        GatewayId: Guid;
        DataSourceId: Guid;
        DatasetId: Text;
        EnvironmentValue: Text;
        CompanyValue: Text;
    begin
        DatasetId := GlobalUploadTracker.GetDatasetId();
        NewParameters := GlobalReport.GetDatasetParameters();

        // Update company and environment parameters
        Session.LogMessage('0000G20', StrSubstNo(UpdatingDatasetParametersTelemetryMsg, DatasetId, CompanyValue, EnvironmentValue), Verbosity::Normal,
            DataClassification::OrganizationIdentifiableInformation, TelemetryScope::ExtensionPublisher, 'Category', PowerBIServiceMgt.GetPowerBiTelemetryCategory());

        PowerBIServiceProvider.UpdateDatasetParameters(DatasetId, NewParameters, OperationResult);

        if (not OperationResult.Successful) and OperationResult.ShouldRetry then begin
            GlobalUploadTracker.ScheduleRetry(GetRetryAfterOrDefault(OperationResult.RetryAfter));
            Session.LogMessage('0000I20', UpdatingParametersFailedTelemetryMsg, Verbosity::Normal, DataClassification::OrganizationIdentifiableInformation, TelemetryScope::ExtensionPublisher, 'Category', PowerBIServiceMgt.GetPowerBiTelemetryCategory());
            exit;
        end; // If it fails and we should not retry, we should ignore the step and try to go ahead (e.g. for custom uploaded reports)

        BusinessCentralAccessToken := AzureAdMgt.GetAccessTokenAsSecretText(UrlHelper.GetFixedEndpointWebServiceUrl(), '', false);
        if BusinessCentralAccessToken.IsEmpty() then begin
            Session.LogMessage('0000B63', EmptyAccessTokenTelemetryMsg, Verbosity::Warning, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', PowerBIServiceMgt.GetPowerBiTelemetryCategory());
            GlobalUploadTracker.TransitionTo(Enum::"Power BI Upload Status"::ParametersUpdated);
            exit;
        end;

        // Get datasource to update
        Clear(OperationResult);

        PowerBIServiceProvider.GetDatasource(DatasetId, DataSourceId, GatewayId, OperationResult);
        Session.LogMessage('0000G21', StrSubstNo(GettingDatasourceForDatasetTelemetryMsg, DatasetId), Verbosity::Normal,
            DataClassification::OrganizationIdentifiableInformation, TelemetryScope::ExtensionPublisher, 'Category', PowerBIServiceMgt.GetPowerBiTelemetryCategory());

        if not OperationResult.Successful then begin
            if OperationResult.ShouldRetry then
                GlobalUploadTracker.ScheduleRetry(GetRetryAfterOrDefault(OperationResult.RetryAfter))
            else
                // If it fails and we should not retry, we should ignore the step (and the dependent steps) and try to go ahead (e.g. for custom uploaded reports)
                GlobalUploadTracker.TransitionTo(Enum::"Power BI Upload Status"::ParametersUpdated);

            Session.LogMessage('0000I21', UpdatingParametersFailedTelemetryMsg, Verbosity::Normal, DataClassification::OrganizationIdentifiableInformation, TelemetryScope::ExtensionPublisher, 'Category', PowerBIServiceMgt.GetPowerBiTelemetryCategory());
            exit;
        end;

        // Update datasource
        Clear(OperationResult);

        PowerBIServiceProvider.UpdateDatasourceCredentials(DataSourceId, GatewayId, BusinessCentralAccessToken, OperationResult);

        if not OperationResult.Successful then begin
            Session.LogMessage('0000I22', UpdatingParametersFailedTelemetryMsg, Verbosity::Normal, DataClassification::OrganizationIdentifiableInformation, TelemetryScope::ExtensionPublisher, 'Category', PowerBIServiceMgt.GetPowerBiTelemetryCategory());

            if OperationResult.ShouldRetry then begin
                GlobalUploadTracker.ScheduleRetry(GetRetryAfterOrDefault(OperationResult.RetryAfter));
                exit;
            end;
        end;

        GlobalUploadTracker.TransitionTo(Enum::"Power BI Upload Status"::ParametersUpdated);
    end;

    local procedure RefreshDataset(PowerBIServiceProvider: Interface "Power BI Service Provider")
    var
        OperationResult: DotNet OperationResult;
        DatasetId: Text;
    begin
        DatasetId := GlobalUploadTracker.GetDatasetId();

        Session.LogMessage('0000G22', StrSubstNo(RefreshingDatasetTelemetryMsg, DatasetId), Verbosity::Normal,
            DataClassification::OrganizationIdentifiableInformation, TelemetryScope::ExtensionPublisher, 'Category', PowerBIServiceMgt.GetPowerBiTelemetryCategory());

        PowerBIServiceProvider.RefreshDataset(DatasetId, OperationResult);

        if OperationResult.Successful then
            GlobalUploadTracker.TransitionTo(Enum::"Power BI Upload Status"::DataRefreshed)
        else
            if OperationResult.ShouldRetry then
                GlobalUploadTracker.ScheduleRetry(GetRetryAfterOrDefault(OperationResult.RetryAfter))
            else
                Error(PowerBIDatasetRefreshFailedErr);
    end;

    local procedure GetRetryAfterOrDefault(RetryAfter: DateTime): DateTime
    begin
        if RetryAfter <> 0DT then
            exit(RetryAfter);
        exit(CurrentDateTime());
    end;

    local procedure MakeReportNameForUpload(PbixReportName: Text; EnvironmentName: Text; CompanyNameIn: Text): Text
    begin
        exit(StrSubstNo(ReportEnvNameTxt, PbixReportName, EnvironmentName, CompanyNameIn));
    end;

}
