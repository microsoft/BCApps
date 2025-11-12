namespace System.Integration.PowerBI;

using System;

interface "Power BI Service Provider"
{
    Access = Internal;

    procedure Initialize(AzureAccessToken: SecretText; PowerBIUrl: Text);

    procedure StartImport(BlobStream: Instream; ReportName: Text; Overwrite: Boolean; var ImportId: Guid; var OperationResult: DotNet OperationResult);

    procedure CheckUserLicense(var OperationResult: DotNet OperationResult);

    procedure GetImport(ImportID: Guid; var ImportState: Text; var ReturnedReport: DotNet ReturnedReport; var OperationResult: DotNet OperationResult);

    procedure UpdateDatasetParameters(DatasetId: Text; EnvironmentName: Text; CompanyName: Text; var OperationResult: DotNet OperationResult);

    procedure GetDatasource(DatasetId: Text; var DataSourceId: Guid; var GatewayId: Guid; var OperationResult: DotNet OperationResult);

    procedure UpdateDatasourceCredentials(DataSourceId: Guid; GatewayId: Guid; BusinessCentralAccessToken: SecretText; var OperationResult: DotNet OperationResult);

    procedure RefreshDataset(DatasetId: Text; var OperationResult: DotNet OperationResult);

    procedure GetReportsInMyWorkspace(var ReturnedReportList: DotNet ReturnedReportList; var OperationResult: DotNet OperationResult);

    procedure GetReportsInWorkspace(WorkspaceId: Guid; var ReturnedReportList: DotNet ReturnedReportList; var OperationResult: DotNet OperationResult);

    procedure GetWorkspaces(var ReturnedWorkspaceList: DotNet ReturnedWorkspaceList; var OperationResult: DotNet OperationResult);
}