namespace System.Integration.PowerBI;

using System.Integration;

/// <summary>
/// Collects all reports that need uploading from all sources and provides a unified iterator.
/// </summary>
codeunit 6327 "Power BI Report Aggregator"
{
    Access = Internal;

    var
        PowerBIServiceMgt: Codeunit "Power BI Service Mgt.";
        PendingSystemBlobs: List of [Guid];
        PendingCustomerReports: List of [Guid];
        PendingDeployableReports: List of [Integer];
        SystemIndex: Integer;
        CustomerIndex: Integer;
        DeployableIndex: Integer;
        BlobDoesNotExistTelemetryMsg: Label 'Trying to upload a non-existing blob, with ID: %1.', Locked = true;
        PageIdEmptyForDeploymentTxt: Label 'Page ID for Power BI deployment is empty.', Locked = true;

    procedure LoadAllPending(Context: Text[50]): Boolean
    begin
        Clear(PendingSystemBlobs);
        Clear(PendingCustomerReports);
        Clear(PendingDeployableReports);
        SystemIndex := 0;
        CustomerIndex := 0;
        DeployableIndex := 0;

        LoadOutOfTheBoxReports(Context);
        LoadCustomerReports();
        LoadDeployableReports();

        exit((PendingSystemBlobs.Count() > 0) or (PendingCustomerReports.Count() > 0) or (PendingDeployableReports.Count() > 0));
    end;

    procedure Next(var Report: Interface "Power BI Uploadable Report"): Boolean
    var
        SystemTableReport: Codeunit "Power BI System Table Report";
        CustomerReport: Codeunit "Power BI Customer Report";
        DeployableReportImpl: Codeunit "PBI Deployable Report Impl.";
    begin
        SystemIndex += 1;
        if SystemIndex <= PendingSystemBlobs.Count() then begin
            SystemTableReport.SetBlobId(PendingSystemBlobs.Get(SystemIndex));
            Report := SystemTableReport;
            exit(true);
        end;

        CustomerIndex += 1;
        if CustomerIndex <= PendingCustomerReports.Count() then begin
            CustomerReport.SetReportId(PendingCustomerReports.Get(CustomerIndex));
            Report := CustomerReport;
            exit(true);
        end;

        DeployableIndex += 1;
        if DeployableIndex <= PendingDeployableReports.Count() then begin
            DeployableReportImpl.SetReport(Enum::"Power BI Deployable Report".FromInteger(PendingDeployableReports.Get(DeployableIndex)));
            Report := DeployableReportImpl;
            exit(true);
        end;

        exit(false);
    end;

    procedure PendingCount(): Integer
    begin
        exit(PendingSystemBlobs.Count() + PendingCustomerReports.Count() + PendingDeployableReports.Count());
    end;

    local procedure LoadOutOfTheBoxReports(Context: Text[50])
    var
        PowerBIBlob: Record "Power BI Blob";
        PowerBIReportUploads: Record "Power BI Report Uploads";
        BlobId: Guid;
    begin
        Clear(PendingSystemBlobs);

        if Context = '' then begin
            Session.LogMessage('0000E1I', PageIdEmptyForDeploymentTxt, Verbosity::Warning, DataClassification::SystemMetadata,
                TelemetryScope::ExtensionPublisher, 'Category', PowerBIServiceMgt.GetPowerBiTelemetryCategory());
            exit;
        end;

        BlobId := GetOutOfTheBoxBlobIdForDeployment(Context);
        if not GetPowerBIBlob(PowerBIBlob, BlobId) then
            exit;

        if not PowerBIReportUploads.Get(PowerBIBlob.Id, UserSecurityId()) then begin
            PendingSystemBlobs.Add(PowerBIBlob.Id);
            exit;
        end;

        if not (PowerBIReportUploads."Report Upload Status" in [
            PowerBIReportUploads."Report Upload Status"::Completed,
            PowerBIReportUploads."Report Upload Status"::Skipped,
            PowerBIReportUploads."Report Upload Status"::PendingDeletion,
            PowerBIReportUploads."Report Upload Status"::Failed])
        then
            PendingSystemBlobs.Add(PowerBIBlob.Id);
    end;

    local procedure LoadCustomerReports()
    var
        PowerBICustomerReports: Record "Power BI Customer Reports";
        PowerBIReportUploads: Record "Power BI Report Uploads";
    begin
        Clear(PendingCustomerReports);

        if PowerBICustomerReports.FindSet() then
            repeat
                if not PowerBIReportUploads.Get(PowerBICustomerReports.Id, UserSecurityId()) then
                    PendingCustomerReports.Add(PowerBICustomerReports.Id)
                else
                    if not (PowerBIReportUploads."Report Upload Status" in [
                        PowerBIReportUploads."Report Upload Status"::Completed,
                        PowerBIReportUploads."Report Upload Status"::Skipped,
                        PowerBIReportUploads."Report Upload Status"::PendingDeletion,
                        PowerBIReportUploads."Report Upload Status"::Failed])
                    then
                        PendingCustomerReports.Add(PowerBICustomerReports.Id);
            until PowerBICustomerReports.Next() = 0;
    end;

    local procedure LoadDeployableReports()
    var
        PowerBIDeployment: Record "Power BI Deployment";
        UploadStatus: Enum "Power BI Upload Status";
    begin
        Clear(PendingDeployableReports);

        // Only reports that have been selected for deployment will have a record in the "Power BI Deployment" table
        if not PowerBIDeployment.FindSet() then
            exit;

        repeat
            // Skip records whose enum ordinal is no longer defined (the defining extension may have been uninstalled)
            if Enum::"Power BI Deployable Report".Ordinals().Contains(PowerBIDeployment."Report Id".AsInteger()) then begin
                UploadStatus := PowerBIDeployment.GetUploadStatus();

                // Only pick up reports that are not yet in a terminal state.
                // Version upgrades are handled explicitly via the Update action on the Deployments page.
                if not (UploadStatus in [
                    Enum::"Power BI Upload Status"::Completed,
                    Enum::"Power BI Upload Status"::Skipped,
                    Enum::"Power BI Upload Status"::PendingDeletion,
                    Enum::"Power BI Upload Status"::Failed])
                then
                    PendingDeployableReports.Add(PowerBIDeployment."Report Id".AsInteger());
            end;
        until PowerBIDeployment.Next() = 0;
    end;

    local procedure GetOutOfTheBoxBlobIdForDeployment(Context: Text[50]): Guid
    var
        PowerBIBlob: Record "Power BI Blob";
        PowerBIDefaultSelection: Record "Power BI Default Selection";
        IntelligentCloud: Record "Intelligent Cloud";
        NullGuid: Guid;
    begin
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

    local procedure GetPowerBIBlob(var PowerBIBlob: Record "Power BI Blob"; BlobId: Guid): Boolean
    begin
        if not IsNullGuid(BlobId) then
            if PowerBIBlob.Get(BlobId) then
                exit(true);

        Session.LogMessage('0000B61', StrSubstNo(BlobDoesNotExistTelemetryMsg, BlobId), Verbosity::Normal, DataClassification::SystemMetadata,
            TelemetryScope::ExtensionPublisher, 'Category', PowerBIServiceMgt.GetPowerBiTelemetryCategory());
        exit(false);
    end;
}
