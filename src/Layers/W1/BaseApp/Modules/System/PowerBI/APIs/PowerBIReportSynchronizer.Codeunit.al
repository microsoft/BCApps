namespace System.Integration.PowerBI;

using System;
using System.Azure.Identity;
using System.Environment;
using System.Integration;
using System.Threading;
using System.Utilities;

/// <summary>
/// Encapsulates the logic to deploy and/or delete default Power BI reports. Should be run in background.
/// </summary>
codeunit 6325 "Power BI Report Synchronizer"
{
    TableNo = "Job Queue Entry";

    trigger OnRun()
    var
        PageId: Text[50];
        IsLastAttempt: Boolean;
    begin
        if not EnvironmentInformation.IsSaaSInfrastructure() then
            exit;
        PageId := CopyStr(Rec."Parameter String", 1, MaxStrLen(PageId));

        IsLastAttempt := Rec."No. of Attempts to Run" >= Rec."Maximum No. of Attempts to Run";

        DeleteMarkedDefaultReports();
        UploadOutOfTheBoxReport(PageId, IsLastAttempt);
        UploadCustomerReports(PageId, IsLastAttempt);

        Commit(); // Persist information on which synchronization steps were performed

        if UserNeedsToSynchronize(PageId) then
            Error(StillNeedToSynchronizeErr); // This will reschedule the job queue
    end;

    local procedure UploadOutOfTheBoxReport(PageId: Text[50]; IsLastAttempt: Boolean)
    begin
        if PageId = '' then begin
            Session.LogMessage('0000E1I', PageIdEmptyForDeploymentTxt, Verbosity::Warning, DataClassification::SystemMetadata,
                TelemetryScope::ExtensionPublisher, 'Category', PowerBIServiceMgt.GetPowerBiTelemetryCategory());
            exit;
        end;

        UploadOutOfTheBoxReportForContext(PageId, IsLastAttempt);
    end;

    local procedure DeleteMarkedDefaultReports()
    var
        PowerBIReportUploads: Record "Power BI Report Uploads";
        PowerBICustomerReports: Record "Power BI Customer Reports";
    begin
        // Deletes a batch of default reports that have been marked for deletion for the current user. Reports are
        // deleted from the user's Power BI workspace first, and then removed from the uploads table if that was
        // successful.
        // Should only be called as part of a background session to reduce perf impact.

        if GetReportsToDelete(PowerBIReportUploads) then
            if PowerBIReportUploads.FindSet() then
                repeat
                    PowerBICustomerReports.Reset();
                    PowerBICustomerReports.SetFilter(Id, PowerBIReportUploads."PBIX BLOB ID");
                    repeat
                        if PowerBICustomerReports.Id = PowerBIReportUploads."PBIX BLOB ID" then
                            PowerBICustomerReports.Delete();
                    until PowerBICustomerReports.Next() = 0;
                    PowerBIReportUploads.Delete();
                until PowerBIReportUploads.Next() = 0;
    end;

    [Scope('OnPrem')]
    procedure UserNeedsToSynchronize(Context: Text[50]): Boolean
    var
        PowerBIReportUploads: Record "Power BI Report Uploads";
        ReportsToUpload: List of [Guid];
    begin
        if not EnvironmentInformation.IsSaaSInfrastructure() then
            exit(false);

        // Upload
        if GetOutOfTheBoxReportsToUpload(Context, ReportsToUpload) then
            exit(true);

        if GetCustomerReportsToUpload(ReportsToUpload) then
            exit(true);

        // Delete
        if GetReportsToDelete(PowerBIReportUploads) then
            exit(true);

        exit(false)
    end;

    local procedure SelectDefaultReports(var PowerBIReportUploads: Record "Power BI Report Uploads"; Context: Text[50]; ReportName: Text)
    var
        PowerBIDefaultSelection: Record "Power BI Default Selection";
        PowerBIDisplayedElement: Record "Power BI Displayed Element";
    begin
        // Note that each report only gets auto-selection done one time - if the user later deselects it
        // we won't keep reselecting it.

        Session.LogMessage('0000ED3', StrSubstNo(PageIdTelemetryMsg, Context), Verbosity::Normal, DataClassification::SystemMetadata,
            TelemetryScope::ExtensionPublisher, 'Category', PowerBIServiceMgt.GetPowerBiTelemetryCategory());

        PowerBIReportUploads.Validate("Report Upload Status", PowerBIReportUploads."Report Upload Status"::Completed);

        if PowerBIDefaultSelection.Get(PowerBIReportUploads."PBIX BLOB ID", Context) then begin
            if not PowerBIDisplayedElement.Get(UserSecurityId(), PowerBIReportUploads."Uploaded Report ID") then begin
                PowerBIDisplayedElement.Init();
                PowerBIDisplayedElement.ElementId := PowerBIDisplayedElement.MakeReportKey(PowerBIReportUploads."Uploaded Report ID");
                PowerBIDisplayedElement.UserSID := UserSecurityId();
                PowerBIDisplayedElement.ElementType := PowerBIDisplayedElement.ElementType::Report;
                PowerBIDisplayedElement.ElementEmbedUrl := PowerBIReportUploads."Report Embed Url";
                PowerBIDisplayedElement.ElementName := CopyStr(ReportName, 1, MaxStrLen(PowerBIDisplayedElement.ElementName));
                PowerBIDisplayedElement.WorkspaceName := PowerBIWorkspaceMgt.GetMyWorkspaceLabel();
                PowerBIDisplayedElement.Context := PowerBIDefaultSelection.Context;
                PowerBIDisplayedElement.ShowPanesInExpandedMode := true;
                PowerBIDisplayedElement.ShowPanesInNormalMode := false;
                PowerBIDisplayedElement.Insert(true);
            end else
                if (PowerBIDisplayedElement.ElementEmbedUrl <> PowerBIReportUploads."Report Embed Url") then begin
                    PowerBIDisplayedElement.Validate(ElementEmbedUrl, PowerBIReportUploads."Report Embed Url");
                    PowerBIDisplayedElement.Modify(true);
                end;

            Session.LogMessage('0000GAZ', SelectedReportTelemetryMsg, Verbosity::Normal, DataClassification::SystemMetadata,
                TelemetryScope::ExtensionPublisher, 'Category', PowerBIServiceMgt.GetPowerBiTelemetryCategory());

            if PowerBIDefaultSelection.Selected then
                SelectReportIfNoneSelected(PowerBIReportUploads."Uploaded Report ID", PowerBIDefaultSelection.Context);
        end;
    end;

    local procedure SelectReportIfNoneSelected(UploadedReportId: Guid; Context: Text[30])
    var
        PowerBIContextSettings: Record "Power BI Context Settings";
    begin
        PowerBIContextSettings.CreateOrReadForCurrentUser(Context);

        if PowerBIContextSettings.SelectedElementId = '' then begin
            PowerBIContextSettings.SelectedElementId := Format(UploadedReportId);
            PowerBIContextSettings.SelectedElementType := Enum::"Power BI Element Type"::Report;
            PowerBIContextSettings.Modify(true);
        end;
    end;

    local procedure GetPowerBIBlob(var PowerBIBlob: Record "Power BI Blob"; BlobId: Guid): Boolean
    begin
        if not IsNullGuid(BlobId) then
            if PowerBIBlob.Get(BlobId) then
                exit(true);

        // This is most of the times expected, e.g. if we are determining if a blob is OutOfTheBox or Customer Uploaded
        Session.LogMessage('0000B61', StrSubstNo(BlobDoesNotExistTelemetryMsg, BlobId), Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', PowerBIServiceMgt.GetPowerBiTelemetryCategory());
        exit(false);
    end;

    local procedure GetOutOfTheBoxBlobIdForDeployment(Context: Text[50]): Guid
    var
        PowerBIBlob: Record "Power BI Blob";
        PowerBIDefaultSelection: Record "Power BI Default Selection";
        IntelligentCloud: Record "Intelligent Cloud";
        NullGuid: Guid;
    begin
        // Gets the blob id to be deployed for the given context.
        // Currently supports only one report for each context.

        PowerBIDefaultSelection.Reset();
        PowerBIDefaultSelection.SetFilter(Context, Context);

        if PowerBIDefaultSelection.IsEmpty() then
            exit(NullGuid);

        if PowerBIDefaultSelection.FindSet() then
            repeat
                PowerBIBlob.Reset();
                PowerBIBlob.SetRange(Id, PowerBIDefaultSelection.Id);
                PowerBIBlob.SetRange("GP Enabled", IntelligentCloud.Get());
                if not PowerBIBlob.IsEmpty() then
                    exit(PowerBIDefaultSelection.Id);
            until PowerBIDefaultSelection.Next() = 0;

        PowerBIBlob.SetRange("GP Enabled", false);
        if PowerBIBlob.FindFirst() then
            exit(PowerBIBlob.Id);

        exit(NullGuid);
    end;

    local procedure UploadOutOfTheBoxReportForContext(Context: Text[50]; IsLastAttempt: Boolean)
    var
        PowerBIBlob: Record "Power BI Blob";
        PowerBIReportUploads: Record "Power BI Report Uploads";
        BlobInStream: InStream;
        ReportsToUpload: List of [Guid];
        BlobId: Guid;
    begin
        // Be extra careful with BlobInStream: Assigning a stream variable to a DotNet stream does not prevent it from being disposed when it goes out of scope in AL.

        // OutOfTheBox
        PowerBIBlob.SetAutoCalcFields("Blob File");
        if GetOutOfTheBoxReportsToUpload(Context, ReportsToUpload) then begin
            Session.LogMessage('0000G1W', StrSubstNo(ReportUploadStartingMsg, ReportsToUpload.Count), Verbosity::Normal,
                DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', PowerBIServiceMgt.GetPowerBiTelemetryCategory());

            foreach BlobId in ReportsToUpload do begin
                PowerBIBlob.Get(BlobId); // Fails only in case of race conditions, which is OK
                PowerBIBlob."Blob File".CreateInStream(BlobInStream);

                PrepareUpload(PowerBIReportUploads, BlobId, PowerBIBlob."GP Enabled");
                UploadImport(BlobInStream, PowerBIBlob.Name, PowerBIReportUploads, IsLastAttempt, Context);
            end;
        end;
    end;

    local procedure UploadCustomerReports(Context: Text[50]; IsLastAttempt: Boolean)
    var
        PowerBIReportUploads: Record "Power BI Report Uploads";
        PowerBICustomerReports: Record "Power BI Customer Reports";
        BlobInStream: InStream;
        ReportsToUpload: List of [Guid];
        BlobId: Guid;
    begin
        // Be extra careful with BlobInStream: Assigning a stream variable to a DotNet stream does not prevent it from being disposed when it goes out of scope in AL.

        // Customer
        PowerBICustomerReports.SetAutoCalcFields("Blob File");
        if GetCustomerReportsToUpload(ReportsToUpload) then begin
            Session.LogMessage('0000G1X', StrSubstNo(ReportUploadStartingMsg, ReportsToUpload.Count), Verbosity::Normal,
                DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', PowerBIServiceMgt.GetPowerBiTelemetryCategory());

            foreach BlobId in ReportsToUpload do begin
                PowerBICustomerReports.Get(BlobId); // Fails only in case of race conditions, which is OK
                PowerBICustomerReports."Blob File".CreateInStream(BlobInStream);

                PrepareUpload(PowerBIReportUploads, BlobId, false);
                UploadImport(BlobInStream, PowerBICustomerReports.Name, PowerBIReportUploads, IsLastAttempt, Context);
            end;
        end;
    end;

    local procedure PrepareUpload(var PowerBIReportUploads: Record "Power BI Report Uploads"; BlobId: Guid; GPEnabled: Boolean)
    begin
        Clear(PowerBIReportUploads);

        if PowerBIReportUploads.Get(BlobId, UserSecurityId()) then begin
            Clear(PowerBIReportUploads."Retry After");
            exit;
        end;

        PowerBIReportUploads.Init();
        PowerBIReportUploads."User ID" := UserSecurityId();
        PowerBIReportUploads."PBIX BLOB ID" := BlobId;
        PowerBIReportUploads.IsGP := GPEnabled;
        PowerBIReportUploads.Insert(true);
    end;

    local procedure UploadImport(BlobInStream: InStream; BaseReportName: Text; var PowerBIReportUploads: Record "Power BI Report Uploads"; IsLastAttempt: Boolean; Context: Text[50])
    var
        PowerBIServiceProvider: Interface "Power BI Service Provider";
        DatasetId: Text;
        FinalReportName: Text;
    begin
        Session.LogMessage('0000DZ1', StrSubstNo(UploadingReportTelemetryMsg, PowerBIReportUploads."PBIX BLOB ID"), Verbosity::Normal,
            DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', PowerBIServiceMgt.GetPowerBiTelemetryCategory());

        PowerBIServiceMgt.CreateServiceProvider(PowerBIServiceProvider);
        FinalReportName := MakeReportNameForUpload(BaseReportName, EnvironmentInformation.GetEnvironmentName(), CompanyName());

        if PowerBIReportUploads."Report Upload Status" = PowerBIReportUploads."Report Upload Status"::NotStarted then
            StartImport(PowerBIServiceProvider, PowerBIReportUploads, BlobInStream, FinalReportName);

        if PowerBIReportUploads."Report Upload Status" = PowerBIReportUploads."Report Upload Status"::ImportStarted then
            GetImport(PowerBIServiceProvider, PowerBIReportUploads, DatasetId);

        if PowerBIReportUploads."Report Upload Status" = PowerBIReportUploads."Report Upload Status"::ImportFinished then
            UpdateParameters(PowerBIServiceProvider, PowerBIReportUploads, DatasetId);

        if PowerBIReportUploads."Report Upload Status" = PowerBIReportUploads."Report Upload Status"::ParametersUpdated then
            RefreshDataset(PowerBIServiceProvider, PowerBIReportUploads, DatasetId);

        if PowerBIReportUploads."Report Upload Status" = PowerBIReportUploads."Report Upload Status"::DataRefreshed then
            SelectDefaultReports(PowerBIReportUploads, Context, FinalReportName);

        if PowerBIReportUploads."Report Upload Status" <> PowerBIReportUploads."Report Upload Status"::Completed then
            if IsLastAttempt then
                PowerBIReportUploads.Validate("Report Upload Status", PowerBIReportUploads."Report Upload Status"::Failed);

        if not PowerBIReportUploads.Modify(true) then
            Session.LogMessage('0000KWS', NoProgressOnUploadTelemetryMsg, Verbosity::Normal,
                DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', PowerBIServiceMgt.GetPowerBiTelemetryCategory());
    end;

    local procedure StartImport(PowerBIServiceProvider: Interface "Power BI Service Provider"; var PowerBIReportUploads: Record "Power BI Report Uploads"; BlobInStream: InStream; ReportName: Text)
    var
        PowerBiBlob: Record "Power BI Blob";
        PowerBiCustomerReports: Record "Power BI Customer Reports";
        OperationResult: DotNet OperationResult;
        ImportId: Guid;
        Overwrite: Boolean;
    begin
        Session.LogMessage('0000G1Y', StrSubstNo(StartingImportTelemetryMsg, PowerBIReportUploads."PBIX BLOB ID"), Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', PowerBIServiceMgt.GetPowerBiTelemetryCategory());

        if PowerBiBlob.Get(PowerBIReportUploads."PBIX BLOB ID") then
            Overwrite := PowerBiBlob.Version > PowerBIReportUploads."Deployed Version"
        else
            if PowerBiCustomerReports.Get(PowerBIReportUploads."PBIX BLOB ID") then
                Overwrite := PowerBiCustomerReports.Version > PowerBIReportUploads."Deployed Version";

        PowerBIServiceProvider.StartImport(
            BlobInStream,
            ReportName,
            Overwrite,
            ImportId,
            OperationResult);

        if OperationResult.Successful then begin
            PowerBIReportUploads.Validate("Report Upload Status", PowerBIReportUploads."Report Upload Status"::ImportStarted);
            PowerBIReportUploads."Import ID" := ImportId;
        end else
            if OperationResult.ShouldRetry then
                PowerBIReportUploads.Validate("Retry After", OperationResult.RetryAfter)
            else
                PowerBIReportUploads.Validate("Report Upload Status", PowerBIReportUploads."Report Upload Status"::Failed);
    end;

    local procedure GetImport(PowerBIServiceProvider: Interface "Power BI Service Provider"; var PowerBIReportUploads: Record "Power BI Report Uploads"; var DatasetIdOut: Text)
    var
        OperationResult: DotNet OperationResult;
        ReturnedReport: DotNet ReturnedReport;
        ImportState: Text;
    begin
        Session.LogMessage('0000G1Z', StrSubstNo(StartRetrievingImportTelemetryMsg, PowerBIReportUploads."Import ID"), Verbosity::Normal, DataClassification::OrganizationIdentifiableInformation, TelemetryScope::ExtensionPublisher, 'Category', PowerBIServiceMgt.GetPowerBiTelemetryCategory());

        PowerBIServiceProvider.GetImport(PowerBIReportUploads."Import ID", ImportState, ReturnedReport, OperationResult);

        if OperationResult.Successful then begin
            PowerBIReportUploads.Validate("Report Upload Status", PowerBIReportUploads."Report Upload Status"::ImportFinished);
            PowerBIReportUploads."Report Embed Url" := ReturnedReport.EmbedUrl;
            PowerBIReportUploads."Uploaded Report ID" := ReturnedReport.ReportId;
            DatasetIdOut := ReturnedReport.DatasetId;
        end else
            if OperationResult.ShouldRetry then
                PowerBIReportUploads.Validate("Retry After", OperationResult.RetryAfter)
            else
                PowerBIReportUploads.Validate("Report Upload Status", PowerBIReportUploads."Report Upload Status"::Failed);
    end;

    local procedure UpdateParameters(PowerBIServiceProvider: Interface "Power BI Service Provider"; var PowerBIReportUploads: Record "Power BI Report Uploads"; DatasetId: Text)
    var
        UrlHelper: Codeunit "Url Helper";
        BusinessCentralAccessToken: SecretText;
        OperationResult: DotNet OperationResult;
        GatewayId: Guid;
        DataSourceId: Guid;
    begin
        // Update company and environment parameters
        Session.LogMessage('0000G20', StrSubstNo(UpdatingDatasetParametersTelemetryMsg, DatasetId, CompanyName(), EnvironmentInformation.GetEnvironmentName()), Verbosity::Normal,
            DataClassification::OrganizationIdentifiableInformation, TelemetryScope::ExtensionPublisher, 'Category', PowerBIServiceMgt.GetPowerBiTelemetryCategory());

        PowerBIServiceProvider.UpdateDatasetParameters(DatasetId, EnvironmentInformation.GetEnvironmentName(), CompanyName(), OperationResult);

        if (not OperationResult.Successful) and OperationResult.ShouldRetry then begin
            PowerBIReportUploads.Validate("Retry After", OperationResult.RetryAfter);
            Session.LogMessage('0000I20', UpdatingParametersFailedTelemetryMsg, Verbosity::Normal, DataClassification::OrganizationIdentifiableInformation, TelemetryScope::ExtensionPublisher, 'Category', PowerBIServiceMgt.GetPowerBiTelemetryCategory());
            exit;
        end; // If it fails and we should not retry, we should ignore the step and try to go ahead (e.g. for custom uploaded reports)

        BusinessCentralAccessToken := AzureAdMgt.GetAccessTokenAsSecretText(UrlHelper.GetFixedEndpointWebServiceUrl(), '', false);
        if BusinessCentralAccessToken.IsEmpty() then begin
            Session.LogMessage('0000B63', EmptyAccessTokenTelemetryMsg, Verbosity::Warning, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', PowerBIServiceMgt.GetPowerBiTelemetryCategory());
            PowerBIReportUploads.Validate("Report Upload Status", PowerBIReportUploads."Report Upload Status"::ParametersUpdated);
            exit;
        end;

        // Get datasource to update
        Clear(OperationResult);

        PowerBIServiceProvider.GetDatasource(DatasetId, DataSourceId, GatewayId, OperationResult);
        Session.LogMessage('0000G21', StrSubstNo(GettingDatasourceForDatasetTelemetryMsg, DatasetId), Verbosity::Normal,
            DataClassification::OrganizationIdentifiableInformation, TelemetryScope::ExtensionPublisher, 'Category', PowerBIServiceMgt.GetPowerBiTelemetryCategory());

        if not OperationResult.Successful then begin
            if OperationResult.ShouldRetry then
                PowerBIReportUploads.Validate("Retry After", OperationResult.RetryAfter)
            else
                // If it fails and we should not retry, we should ignore the step (and the dependend steps) and try to go ahead (e.g. for custom uploaded reports)
                PowerBIReportUploads.Validate("Report Upload Status", PowerBIReportUploads."Report Upload Status"::ParametersUpdated);

            Session.LogMessage('0000I21', UpdatingParametersFailedTelemetryMsg, Verbosity::Normal, DataClassification::OrganizationIdentifiableInformation, TelemetryScope::ExtensionPublisher, 'Category', PowerBIServiceMgt.GetPowerBiTelemetryCategory());
            exit;
        end;

        // Update datasource
        Clear(OperationResult);

        PowerBIServiceProvider.UpdateDatasourceCredentials(DataSourceId, GatewayId, BusinessCentralAccessToken, OperationResult);

        if not OperationResult.Successful then begin
            Session.LogMessage('0000I22', UpdatingParametersFailedTelemetryMsg, Verbosity::Normal, DataClassification::OrganizationIdentifiableInformation, TelemetryScope::ExtensionPublisher, 'Category', PowerBIServiceMgt.GetPowerBiTelemetryCategory());

            if OperationResult.ShouldRetry then begin
                PowerBIReportUploads.Validate("Retry After", OperationResult.RetryAfter);
                exit;
            end;
        end;

        PowerBIReportUploads.Validate("Report Upload Status", PowerBIReportUploads."Report Upload Status"::ParametersUpdated);
    end;

    local procedure RefreshDataset(PowerBIServiceProvider: Interface "Power BI Service Provider"; var PowerBIReportUploads: Record "Power BI Report Uploads"; DatasetId: Text)
    var
        OperationResult: DotNet OperationResult;
    begin
        Session.LogMessage('0000G22', StrSubstNo(RefreshingDatasetTelemetryMsg, DatasetId), Verbosity::Normal,
            DataClassification::OrganizationIdentifiableInformation, TelemetryScope::ExtensionPublisher, 'Category', PowerBIServiceMgt.GetPowerBiTelemetryCategory());

        PowerBIServiceProvider.RefreshDataset(DatasetId, OperationResult);

        if OperationResult.Successful then
            PowerBIReportUploads.Validate("Report Upload Status", PowerBIReportUploads."Report Upload Status"::DataRefreshed)
        else
            if OperationResult.ShouldRetry then
                PowerBIReportUploads.Validate("Retry After", OperationResult.RetryAfter)
            else
                PowerBIReportUploads.Validate("Report Upload Status", PowerBIReportUploads."Report Upload Status"::Failed);
    end;

    local procedure MakeReportNameForUpload(PbixReportName: Text; EnvironmentName: Text; CompanyNameIn: Text): Text
    begin
        exit(StrSubstNo(ReportEnvNameTxt, PbixReportName, EnvironmentName, CompanyNameIn));
    end;

    local procedure GetOutOfTheBoxReportsToUpload(Context: Text[50]; var ReportsToUpload: List of [Guid]): Boolean
    var
        PowerBIBlob: Record "Power BI Blob";
        PowerBIReportUploads: Record "Power BI Report Uploads";
        BlobId: Guid;
    begin
        Clear(ReportsToUpload);
        if Context = '' then
            exit(false);

        // OutOfTheBox reports
        BlobId := GetOutOfTheBoxBlobIdForDeployment(Context);
        if not GetPowerBIBlob(PowerBIBlob, BlobId) then
            exit(false);

        if not PowerBIReportUploads.Get(PowerBIBlob.Id, UserSecurityId()) then begin
            ReportsToUpload.Add(PowerBIBlob.Id);
            exit(true);
        end;

        if not (PowerBIReportUploads."Report Upload Status" in [PowerBIReportUploads."Report Upload Status"::Completed, PowerBIReportUploads."Report Upload Status"::Skipped,
                PowerBIReportUploads."Report Upload Status"::PendingDeletion, PowerBIReportUploads."Report Upload Status"::Failed]) then begin
            ReportsToUpload.Add(PowerBIBlob.Id);
            exit(true);
        end;

        exit(false);
    end;

    local procedure GetCustomerReportsToUpload(var ReportsToUpload: List of [Guid]): Boolean
    var
        PowerBICustomerReports: Record "Power BI Customer Reports";
        PowerBIReportUploads: Record "Power BI Report Uploads";
    begin
        Clear(ReportsToUpload);

        // Customer reports
        if PowerBICustomerReports.FindSet() then
            repeat
                if not PowerBIReportUploads.Get(PowerBICustomerReports.Id, UserSecurityId()) then begin
                    ReportsToUpload.Add(PowerBICustomerReports.Id);
                    exit(true);
                end;

                if not (PowerBIReportUploads."Report Upload Status" in [PowerBIReportUploads."Report Upload Status"::Completed, PowerBIReportUploads."Report Upload Status"::Skipped,
                        PowerBIReportUploads."Report Upload Status"::PendingDeletion, PowerBIReportUploads."Report Upload Status"::Failed]) then begin
                    ReportsToUpload.Add(PowerBICustomerReports.Id);
                    exit(true);
                end;
            until PowerBICustomerReports.Next() = 0;

        exit(ReportsToUpload.Count() > 0);
    end;

    local procedure GetReportsToDelete(var PowerBIReportUploads: Record "Power BI Report Uploads"): Boolean
    begin
        PowerBIReportUploads.Reset();
        PowerBIReportUploads.SetRange("User ID", UserSecurityId());
        PowerBIReportUploads.SetRange("Report Upload Status", PowerBIReportUploads."Report Upload Status"::PendingDeletion);

        exit(PowerBIReportUploads.FindSet());
    end;

    var
        PowerBIServiceMgt: Codeunit "Power BI Service Mgt.";
        PowerBIWorkspaceMgt: Codeunit "Power BI Workspace Mgt.";
        AzureAdMgt: Codeunit "Azure AD Mgt.";
        EnvironmentInformation: Codeunit "Environment Information";
        ReportEnvNameTxt: Label '%1 (%2 - %3)', Locked = true;
        StillNeedToSynchronizeErr: Label 'The synchronization of your Power BI reports did not complete. We will retry automatically, and this typically fixes the issue.';
        // Telemetry
        BlobDoesNotExistTelemetryMsg: Label 'Trying to upload a non-existing blob, with ID: %1.', Locked = true;
        UpdatingParametersFailedTelemetryMsg: Label 'Updating report parameters failed,', Locked = true;
        SelectedReportTelemetryMsg: Label 'Report selected.', Locked = true;
        PageIdTelemetryMsg: Label 'Checking if we need to select default reports for page id: %1.', Locked = true;
        ReportUploadStartingMsg: Label 'Starting to upload %1 Power BI Reports.', Locked = true;
        EmptyAccessTokenTelemetryMsg: Label 'Encountered an empty access token.', Locked = true;
        PageIdEmptyForDeploymentTxt: Label 'Page ID for Power BI deployment is empty.', Locked = true;
        StartRetrievingImportTelemetryMsg: Label 'Retrieving import id %1.', Locked = true;
        UploadingReportTelemetryMsg: Label 'Uploading report with internal blob ID: %1.', Locked = true;
        StartingImportTelemetryMsg: Label 'Starting actual import for internal blob ID: %1.', Locked = true;
        UpdatingDatasetParametersTelemetryMsg: Label 'Updating dataset %1 with company "%2" and environment "%3".', Locked = true;
        GettingDatasourceForDatasetTelemetryMsg: Label 'Getting datasource for dataset %1.', Locked = true;
        RefreshingDatasetTelemetryMsg: Label 'Refreshing dataset %1.', Locked = true;
        NoProgressOnUploadTelemetryMsg: Label 'Upload was not modified.', Locked = true;
}
