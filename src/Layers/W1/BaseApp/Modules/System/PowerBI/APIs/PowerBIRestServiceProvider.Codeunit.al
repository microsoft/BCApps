namespace System.Integration.PowerBI;

using System;

codeunit 6321 "Power BI Rest Service Provider" implements "Power BI Service Provider"
{
    Access = Internal;

    var
        PowerBiRestServiceWrapper: DotNet PowerBiRestServiceWrapper;
        NotInitializedErr: Label 'The Power BI Service has not been initialized.';

    procedure Initialize(AzureAccessToken: SecretText; PowerBIUrl: Text)
    begin
        PowerBiRestServiceWrapper := PowerBiRestServiceWrapper.PowerBiRestServiceWrapper(AzureAccessToken, PowerBIUrl);
    end;

    procedure StartImport(BlobStream: Instream; ReportName: Text; Overwrite: Boolean; var ImportId: Guid; var OperationResult: DotNet OperationResult)
    begin
        EnsureServiceWrapper();
        OperationResult := PowerBiRestServiceWrapper.StartImport(
                BlobStream,
                ReportName,
                Overwrite,
                ImportId);
    end;

    procedure CheckUserLicense(var OperationResult: DotNet OperationResult)
    begin
        EnsureServiceWrapper();
        OperationResult := PowerBiRestServiceWrapper.CheckUserLicense();
    end;

    procedure GetImport(ImportID: Guid; var ImportState: Text; var ReturnedReport: DotNet ReturnedReport; var OperationResult: DotNet OperationResult)
    begin
        EnsureServiceWrapper();
        OperationResult := PowerBiRestServiceWrapper.GetImport(ImportID, ImportState, ReturnedReport);
    end;

    procedure UpdateDatasetParameters(DatasetId: Text; EnvironmentName: Text; CompanyNameInput: Text; var OperationResult: DotNet OperationResult)
    begin
        EnsureServiceWrapper();
        OperationResult := PowerBiRestServiceWrapper.UpdateDatasetParameters(DatasetId, CompanyNameInput, EnvironmentName);
    end;

    procedure GetDatasource(DatasetId: Text; var DataSourceId: Guid; var GatewayId: Guid; var OperationResult: DotNet OperationResult)
    begin
        EnsureServiceWrapper();
        OperationResult := PowerBiRestServiceWrapper.GetDatasource(DatasetId, DataSourceId, GatewayId);
    end;

    procedure UpdateDatasourceCredentials(DataSourceId: Guid; GatewayId: Guid; BusinessCentralAccessToken: SecretText; var OperationResult: DotNet OperationResult)
    begin
        EnsureServiceWrapper();
        OperationResult := PowerBiRestServiceWrapper.UpdateDatasourceCredentials(DataSourceId, GatewayId, BusinessCentralAccessToken);
    end;

    procedure RefreshDataset(DatasetId: Text; var OperationResult: DotNet OperationResult)
    begin
        EnsureServiceWrapper();
        OperationResult := PowerBiRestServiceWrapper.RefreshDataset(DatasetId);
    end;

    procedure GetReportsInMyWorkspace(var ReturnedReportList: DotNet ReturnedReportList; var OperationResult: DotNet OperationResult)
    begin
        EnsureServiceWrapper();

        // TODO: this is temporary because at the moment the overload without timeout does not work
        OperationResult := PowerBiRestServiceWrapper.GetReportsInMyWorkspace(ReturnedReportList, 1000 * 1000);
    end;

    procedure GetReportsInWorkspace(WorkspaceId: Guid; var ReturnedReportList: DotNet ReturnedReportList; var OperationResult: DotNet OperationResult)
    begin
        EnsureServiceWrapper();
        OperationResult := PowerBiRestServiceWrapper.GetReportsInWorkspace(WorkspaceId, ReturnedReportList);
    end;

    procedure GetWorkspaces(var ReturnedWorkspaceList: DotNet ReturnedWorkspaceList; var OperationResult: DotNet OperationResult)
    begin
        EnsureServiceWrapper();
        OperationResult := PowerBiRestServiceWrapper.GetWorkspaces(ReturnedWorkspaceList);
    end;

    local procedure EnsureServiceWrapper()
    begin
        if IsNull(PowerBiRestServiceWrapper) then
            Error(NotInitializedErr);
    end;

}