namespace System.Integration.PowerBI;

using System.Environment;
using System.Integration;

/// <summary>
/// Wraps a Power BI Blob (system table 2000000144) record as an uploadable report.
/// Handles default selection after upload completes.
/// </summary>
codeunit 6323 "Power BI System Table Report" implements "Power BI Uploadable Report"
{
    Access = Internal;

    var
        PowerBIBlob: Record "Power BI Blob";
        PageIdTelemetryMsg: Label 'Checking if we need to select default reports for page id: %1.', Locked = true;
        SelectedReportTelemetryMsg: Label 'Report selected.', Locked = true;

    internal procedure SetBlobId(BlobId: Guid)
    begin
        PowerBIBlob.SetAutoCalcFields("Blob File");
        PowerBIBlob.Get(BlobId);
    end;

    procedure GetReportKey(): Text[100]
    begin
        exit(Format(PowerBIBlob.Id));
    end;

    procedure GetReportName(): Text[100]
    begin
        exit(CopyStr(PowerBIBlob.Name, 1, 100));
    end;

    procedure GetStream(var InStr: InStream)
    begin
        PowerBIBlob."Blob File".CreateInStream(InStr);
    end;

    procedure GetReportVersion(): Integer
    begin
        exit(PowerBIBlob.Version);
    end;

    procedure GetUploadTracker(var UploadTracker: Interface "Power BI Upload Tracker")
    var
        SystemTracker: Codeunit "Power BI System Upload Tracker";
    begin
        SystemTracker.SetGPEnabled(PowerBIBlob."GP Enabled");
        UploadTracker := SystemTracker;
    end;

    procedure FinalizeUpload(var UploadTracker: Interface "Power BI Upload Tracker"; Context: Text[50]; UploadReportName: Text)
    var
        PowerBIDefaultSelection: Record "Power BI Default Selection";
        PowerBIDisplayedElement: Record "Power BI Displayed Element";
        PowerBIContextSettings: Record "Power BI Context Settings";
        PowerBIWorkspaceMgt: Codeunit "Power BI Workspace Mgt.";
        PowerBIServiceMgt: Codeunit "Power BI Service Mgt.";
    begin
        Session.LogMessage('0000ED3', StrSubstNo(PageIdTelemetryMsg, Context), Verbosity::Normal, DataClassification::SystemMetadata,
            TelemetryScope::ExtensionPublisher, 'Category', PowerBIServiceMgt.GetPowerBiTelemetryCategory());

        if PowerBIDefaultSelection.Get(PowerBIBlob.Id, Context) then begin
            if not PowerBIDisplayedElement.Get(UserSecurityId(), UploadTracker.GetUploadedReportId()) then begin
                PowerBIDisplayedElement.Init();
                PowerBIDisplayedElement.ElementId := PowerBIDisplayedElement.MakeReportKey(UploadTracker.GetUploadedReportId());
                PowerBIDisplayedElement.UserSID := UserSecurityId();
                PowerBIDisplayedElement.ElementType := PowerBIDisplayedElement.ElementType::Report;
                PowerBIDisplayedElement.ElementEmbedUrl := UploadTracker.GetEmbedUrl();
                PowerBIDisplayedElement.ElementName := CopyStr(UploadReportName, 1, MaxStrLen(PowerBIDisplayedElement.ElementName));
                PowerBIDisplayedElement.WorkspaceName := PowerBIWorkspaceMgt.GetMyWorkspaceLabel();
                PowerBIDisplayedElement.Context := PowerBIDefaultSelection.Context;
                PowerBIDisplayedElement.ShowPanesInExpandedMode := true;
                PowerBIDisplayedElement.ShowPanesInNormalMode := false;
                PowerBIDisplayedElement.Insert(true);
            end else
                if (PowerBIDisplayedElement.ElementEmbedUrl <> UploadTracker.GetEmbedUrl()) then begin
                    PowerBIDisplayedElement.Validate(ElementEmbedUrl, UploadTracker.GetEmbedUrl());
                    PowerBIDisplayedElement.Modify(true);
                end;

            Session.LogMessage('0000GAZ', SelectedReportTelemetryMsg, Verbosity::Normal, DataClassification::SystemMetadata,
                TelemetryScope::ExtensionPublisher, 'Category', PowerBIServiceMgt.GetPowerBiTelemetryCategory());

            if PowerBIDefaultSelection.Selected then begin
                PowerBIContextSettings.CreateOrReadForCurrentUser(PowerBIDefaultSelection.Context);

                if PowerBIContextSettings.SelectedElementId = '' then begin
                    PowerBIContextSettings.SelectedElementId := Format(UploadTracker.GetUploadedReportId());
                    PowerBIContextSettings.SelectedElementType := Enum::"Power BI Element Type"::Report;
                    PowerBIContextSettings.Modify(true);
                end;
            end;
        end;
    end;

    procedure GetDatasetParameters() Parameters: Dictionary of [Text, Text]
    var
        EnvironmentInformation: Codeunit "Environment Information";
    begin
        Parameters.Add('Company Name', CompanyName());
        Parameters.Add('Environment', EnvironmentInformation.GetEnvironmentName());
    end;
}
