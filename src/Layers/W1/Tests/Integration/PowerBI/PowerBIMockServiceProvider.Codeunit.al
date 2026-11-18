codeunit 139096 "Power BI Mock Service Provider" implements "Power BI Service Provider"
{
    Access = Internal;

    procedure Initialize(AzureAccessToken: SecretText; PowerBIUrl: Text)
    begin

    end;

    procedure StartImport(BlobInStream: Instream; ReportName: Text; Overwrite: Boolean; WorkspaceId: Guid; var ImportId: Guid; var OperationResult: DotNet OperationResult)
    begin
        CheckFailStep();

        LastTargetWorkspaceId := WorkspaceId;

        if FailStep = FailStep::StartImport then begin
            OperationFail(OperationResult);
            exit;
        end;

        ImportId := CreateGuid();
        GeneratedImportId := ImportId;
        OperationSuccess(OperationResult);
    end;

    procedure CheckUserLicense(var OperationResult: DotNet OperationResult)
    begin
        CheckFailStep();

        if FailStep = FailStep::CheckLicense then begin
            OperationFail(OperationResult);
            exit;
        end;

        OperationSuccess(OperationResult);
    end;

    procedure GetImport(ImportID: Guid; WorkspaceId: Guid; var ImportState: Text; var ReturnedReport: DotNet ReturnedReport; var OperationResult: DotNet OperationResult)
    begin
        CheckFailStep();

        LastTargetWorkspaceId := WorkspaceId;

        if FailStep = FailStep::GetImport then begin
            OperationFail(OperationResult);
            exit;
        end;

        if ImportID <> GeneratedImportId then
            Error('Import ID not expected.');

        ImportState := 'Successful';
        OperationSuccess(OperationResult);

        GeneratedDatasetId := CreateGuid() + 'DsId';
        GeneratedReportId := CreateGuid();
        ReturnedReport := ReturnedReport.ReturnedReport(GeneratedReportId, 'https://powerbi.com/report/foobar', 'Report Name', GeneratedDatasetId);
    end;

    procedure UpdateDatasetParameters(DatasetId: Text; Parameters: Dictionary of [Text, Text]; WorkspaceId: Guid; var OperationResult: DotNet OperationResult)
    begin
        CheckFailStep();

        LastTargetWorkspaceId := WorkspaceId;

        if FailStep = FailStep::UpdateParams then begin
            OperationFail(OperationResult);
            exit;
        end;

        if DatasetId <> GeneratedDatasetId then
            Error('Dataset ID not expected.');

        OperationSuccess(OperationResult);
    end;

    procedure GetDatasource(DatasetId: Text; WorkspaceId: Guid; var DataSourceId: Guid; var GatewayId: Guid; var OperationResult: DotNet OperationResult)
    begin
        CheckFailStep();

        LastTargetWorkspaceId := WorkspaceId;

        if FailStep = FailStep::GetDataSource then begin
            OperationFail(OperationResult);
            exit;
        end;

        if DatasetId <> GeneratedDatasetId then
            Error('Dataset ID not expected.');

        GeneratedDatasourceId := CreateGuid();
        GeneratedGatewayId := CreateGuid();
        DataSourceId := GeneratedDatasourceId;
        GatewayId := GeneratedGatewayId;

        OperationSuccess(OperationResult);
    end;

    procedure UpdateDatasourceCredentials(DataSourceId: Guid; GatewayId: Guid; BusinessCentralAccessToken: SecretText; var OperationResult: DotNet OperationResult)
    begin
        CheckFailStep();

        if FailStep = FailStep::UpdateCreds then begin
            OperationFail(OperationResult);
            exit;
        end;

        if DataSourceId <> GeneratedDatasourceId then
            Error('Datasource ID not expected.');

        if GatewayId <> GeneratedGatewayId then
            Error('Gateway ID not expected.');

        OperationSuccess(OperationResult);
    end;

    procedure RefreshDataset(DatasetId: Text; WorkspaceId: Guid; var OperationResult: DotNet OperationResult)
    begin
        CheckFailStep();

        LastTargetWorkspaceId := WorkspaceId;

        if FailStep = FailStep::RefreshDataset then begin
            OperationFail(OperationResult);
            exit;
        end;

        if DatasetId <> GeneratedDatasetId then
            Error('Dataset ID not expected.');

        OperationSuccess(OperationResult);
    end;

    procedure GetReportsInMyWorkspace(var ReturnedReportList: DotNet ReturnedReportList; var OperationResult: DotNet OperationResult)
    begin
        Error('Not implemented yet');
    end;

    procedure GetReportsInWorkspace(WorkspaceId: Guid; var ReturnedReportList: DotNet ReturnedReportList; var OperationResult: DotNet OperationResult)
    begin
        Error('Not implemented yet');
    end;

    procedure GetWorkspaces(var ReturnedWorkspaceList: DotNet ReturnedWorkspaceList; var OperationResult: DotNet OperationResult)
    var
        ReturnedWorkspace: DotNet ReturnedWorkspace;
        Index: Integer;
    begin
        ReturnedWorkspaceList := ReturnedWorkspaceList.ReturnedWorkspaceList();

        for Index := 1 to WorkspaceIds.Count() do begin
            ReturnedWorkspace := ReturnedWorkspace.ReturnedWorkspace(WorkspaceIds.Get(Index), WorkspaceNames.Get(Index));
            ReturnedWorkspaceList.Add(ReturnedWorkspace);
        end;

        OperationSuccess(OperationResult);
    end;

    procedure SetFailAtStep(InputStep: Option)
    begin
        FailStep := InputStep;
        CheckFailStep();
    end;

    procedure SetRetryDateTime(RetryAfterInput: DateTime)
    begin
        RetryAfter := RetryAfterInput;
    end;

    local procedure OperationSuccess(var OperationResult: DotNet OperationResult)
    begin
        OperationResult := OperationResult.OperationResult();
        OperationResult.Successful := true;
        OperationResult.ShouldRetry := false;
    end;

    local procedure OperationFail(var OperationResult: DotNet OperationResult)
    begin
        OperationResult := OperationResult.OperationResult();
        OperationResult.Successful := false;

        if RetryAfter = 0DT then
            OperationResult.ShouldRetry := false
        else begin
            OperationResult.ShouldRetry := true;
            OperationResult.RetryAfter := RetryAfter;
        end;
    end;

    procedure GetReportId(): Guid
    begin
        if IsNullGuid(GeneratedReportId) then
            Error('No Report ID');

        exit(GeneratedReportId);
    end;

    procedure GetLastTargetWorkspaceId(): Guid
    begin
        exit(LastTargetWorkspaceId);
    end;

    procedure AddWorkspace(WorkspaceId: Guid; WorkspaceName: Text)
    begin
        WorkspaceIds.Add(WorkspaceId);
        WorkspaceNames.Add(WorkspaceName);
    end;

    procedure ClearWorkspaces()
    begin
        Clear(WorkspaceIds);
        Clear(WorkspaceNames);
    end;

    local procedure CheckFailStep()
    begin
        if FailStep = FailStep::NotSet then
            Error('Fail step not set.');

        if not (FailStep in [FailStep::NotSet .. FailStep::Never]) then
            Error('Fail step outside valid range.');
    end;

    var
        FailStep: Option NotSet,CheckLicense,StartImport,GetImport,UpdateParams,GetDatasource,UpdateCreds,RefreshDataset,Never;
        GeneratedImportId: Guid;
        GeneratedReportId: Guid;
        GeneratedDatasetId: Text;
        GeneratedGatewayId: Guid;
        GeneratedDatasourceId: Guid;
        LastTargetWorkspaceId: Guid;
        WorkspaceIds: List of [Guid];
        WorkspaceNames: List of [Text];
        RetryAfter: DateTime;

}