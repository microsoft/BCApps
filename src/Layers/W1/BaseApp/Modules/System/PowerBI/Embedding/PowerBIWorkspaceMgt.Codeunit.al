namespace System.Integration.PowerBI;

using System;

codeunit 6319 "Power BI Workspace Mgt."
{
    var
        PowerBIServiceMgt: Codeunit "Power BI Service Mgt.";
        PowerBIUrlMgt: Codeunit "Power BI Url Mgt";
        MyWorkspaceTxt: Label 'My Workspace', Comment = 'Workspace here is meant as "Power BI workspace". The wording "My Workspace" is used by Power BI.', MaxLength = 200;
        CouldNotAccessWorkspaceErr: Label 'There was a problem retrieving the reports in My Workspace. Make sure you can access Power BI from the browser and try again.', Comment = 'Workspace here is meant as "Power BI workspace". The wording "My Workspace" is used by Power BI.';

        //Telemetry
        FailedToInsertWorkspaceTelemetryMsg: Label 'Failed to insert workspace in buffer.', Locked = true;
        WorkspacesAddedTelemetryMsg: Label 'Workspaces added. Initial count: %1, final count: %2.', Locked = true;
        UrlTooLongTelemetryMsg: Label 'Parsing reports encountered a URL that is too long to be saved to ReportEmbedUrl. Length: %1.', Locked = true;
        FailedToInsertReportTelemetryMsg: Label 'Could not insert parsed report.', Locked = true;
        CouldntGetWorkspacesTelemetryMsg: Label 'Could not retrieve workspaces.', Locked = true;
        CouldntGetReportsTelemetryMsg: Label 'Could not retrieve reports from workspace %1.', Locked = true;

    procedure GetMyWorkspaceLabel(): Text[200]
    begin
        exit(MyWorkspaceTxt);
    end;

    procedure AddPersonalWorkspace(var TempPowerBISelectionElement: Record "Power BI Selection Element" temporary)
    begin
        TempPowerBISelectionElement.Init();
        TempPowerBISelectionElement.Type := TempPowerBISelectionElement.Type::Workspace;
        TempPowerBISelectionElement.Name := MyWorkspaceTxt;
        TempPowerBISelectionElement.WorkspaceName := TempPowerBISelectionElement.Name;
        TempPowerBISelectionElement.EmbedUrl := CopyStr(PowerBIServiceMgt.GetReportsUrl(), 1, MaxStrLen(TempPowerBISelectionElement.EmbedUrl));
        TempPowerBISelectionElement.Insert();
    end;

    procedure AddSharedWorkspaces(var TempPowerBISelectionElement: Record "Power BI Selection Element" temporary)
    var
        PowerBIServiceProvider: Interface "Power BI Service Provider";
        ReturnedWorkspace: DotNet ReturnedWorkspace;
        ReturnedWorkspaceList: DotNet ReturnedWorkspaceList;
        OperationResult: DotNet OperationResult;
        InitialCount: Integer;
    begin
        InitialCount := TempPowerBISelectionElement.Count();

        PowerBIServiceMgt.CreateServiceProvider(PowerBIServiceProvider);
        PowerBIServiceProvider.GetWorkspaces(ReturnedWorkspaceList, OperationResult);

        if not OperationResult.Successful then begin
            Session.LogMessage('0000J7E', CouldntGetWorkspacesTelemetryMsg, Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', PowerBIServiceMgt.GetPowerBiTelemetryCategory());
            exit;
        end;

        foreach ReturnedWorkspace in ReturnedWorkspaceList do begin
            TempPowerBISelectionElement.Init();

            Evaluate(TempPowerBISelectionElement.ID, ReturnedWorkspace.WorkspaceId);
            Evaluate(TempPowerBISelectionElement.WorkspaceID, ReturnedWorkspace.WorkspaceId);

            // report name
            TempPowerBISelectionElement.Name := CopyStr(ReturnedWorkspace.WorkspaceName, 1, MaxStrLen(TempPowerBISelectionElement.Name));
            TempPowerBISelectionElement.WorkspaceName := TempPowerBISelectionElement.Name;
            TempPowerBISelectionElement.Type := TempPowerBISelectionElement.Type::Workspace;
            TempPowerBISelectionElement.EmbedUrl := CopyStr(GetReportsUrlForWorkspace(TempPowerBISelectionElement), 1, MaxStrLen(TempPowerBISelectionElement.EmbedUrl));

            if not TempPowerBISelectionElement.Insert() then
                Session.LogMessage('0000F21', FailedToInsertWorkspaceTelemetryMsg, Verbosity::Error, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', PowerBIServiceMgt.GetPowerBiTelemetryCategory());
        end;

        Session.LogMessage('0000F20', StrSubstNo(WorkspacesAddedTelemetryMsg, InitialCount, TempPowerBISelectionElement.Count()), Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', PowerBIServiceMgt.GetPowerBiTelemetryCategory());
    end;

    local procedure GetReportsUrlForWorkspace(PowerBISelectionElement: Record "Power BI Selection Element" temporary): Text
    begin
        exit(PowerBIUrlMgt.GetPowerBISharedReportsUrl(PowerBISelectionElement.ID));
    end;

    procedure GetReportsAndWorkspaces(var TempPowerBISelectionElement: Record "Power BI Selection Element" temporary; EnglishContext: Text[30])
    var
        TempWorkspacePowerBISelectionElement: Record "Power BI Selection Element" temporary;
    begin
        TempPowerBISelectionElement.Reset();

        if not TempPowerBISelectionElement.IsEmpty() then
            exit;

        AddPersonalWorkspace(TempPowerBISelectionElement);
        AddSharedWorkspaces(TempPowerBISelectionElement);

        TempWorkspacePowerBISelectionElement.Copy(TempPowerBISelectionElement, true);
        TempWorkspacePowerBISelectionElement.SetRange(Type, TempPowerBISelectionElement.Type::Workspace);

        if TempWorkspacePowerBISelectionElement.FindSet() then
            repeat
                AddReportsForWorkspace(TempPowerBISelectionElement, TempWorkspacePowerBISelectionElement.ID, TempWorkspacePowerBISelectionElement.Name);
                FillEnabledColumn(TempPowerBISelectionElement, EnglishContext);
            until TempWorkspacePowerBISelectionElement.Next() = 0;
    end;

    procedure AddReportsForWorkspace(var TempPowerBISelectionElement: Record "Power BI Selection Element" temporary; WorkspaceID: Guid; WorkspaceName: Text[200])
    var
        PowerBIServiceProvider: Interface "Power BI Service Provider";
        ReturnedReport: DotNet ReturnedReport;
        ReturnedReportList: DotNet ReturnedReportList;
        OperationResult: DotNet OperationResult;
    begin
        PowerBIServiceMgt.CreateServiceProvider(PowerBIServiceProvider);

        if IsNullGuid(WorkspaceID) then begin
            PowerBIServiceProvider.GetReportsInMyWorkspace(ReturnedReportList, OperationResult);

            if not OperationResult.Successful then begin
                Session.LogMessage('0000J7F', CouldntGetWorkspacesTelemetryMsg, Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', PowerBIServiceMgt.GetPowerBiTelemetryCategory());
                Error(CouldNotAccessWorkspaceErr);
            end;
        end else begin
            PowerBIServiceProvider.GetReportsInWorkspace(WorkspaceID, ReturnedReportList, OperationResult);

            if not OperationResult.Successful then begin
                Session.LogMessage('0000J7G', StrSubstNo(CouldntGetReportsTelemetryMsg, WorkspaceID), Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', PowerBIServiceMgt.GetPowerBiTelemetryCategory());
                exit;
            end;
        end;

        foreach ReturnedReport in ReturnedReportList do begin
            TempPowerBISelectionElement.Init();

            Evaluate(TempPowerBISelectionElement.ID, ReturnedReport.ReportId);
            TempPowerBISelectionElement.Name := CopyStr(ReturnedReport.ReportName, 1, MaxStrLen(TempPowerBISelectionElement.Name));

            // report embedding url; if the url is too long, handle gracefully but issue an error message to telemetry
            if StrLen(ReturnedReport.EmbedUrl) > MaxStrLen(TempPowerBISelectionElement.EmbedUrl) then
                Session.LogMessage('0000BAV', StrSubstNo(UrlTooLongTelemetryMsg, StrLen(ReturnedReport.EmbedUrl)), Verbosity::Error, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', PowerBIServiceMgt.GetPowerBiTelemetryCategory());
            TempPowerBISelectionElement.Validate(EmbedUrl,
                CopyStr(ReturnedReport.EmbedUrl, 1, MaxStrLen(TempPowerBISelectionElement.EmbedUrl)));

            TempPowerBISelectionElement.Type := TempPowerBISelectionElement.Type::Report;
            TempPowerBISelectionElement.WorkspaceName := WorkspaceName;
            TempPowerBISelectionElement.WorkspaceID := WorkspaceID;

            if not TempPowerBISelectionElement.Insert() then
                Session.LogMessage('0000F2D', FailedToInsertReportTelemetryMsg, Verbosity::Warning, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', PowerBIServiceMgt.GetPowerBiTelemetryCategory());
        end;
    end;

    local procedure FillEnabledColumn(var TempPowerBISelectionElement: Record "Power BI Selection Element" temporary; EnglishContext: Text[30])
    var
        PowerBIDisplayedElement: Record "Power BI Displayed Element";
    begin
        TempPowerBISelectionElement.SetRange(TempPowerBISelectionElement.Type, TempPowerBISelectionElement.Type::Report);
        if TempPowerBISelectionElement.FindSet() then
            repeat
                TempPowerBISelectionElement.Enabled := PowerBIDisplayedElement.Get(UserSecurityId(), EnglishContext, PowerBIDisplayedElement.MakeReportKey(TempPowerBISelectionElement.ID), TempPowerBISelectionElement.Type);
                TempPowerBISelectionElement.Modify(true);
            until TempPowerBISelectionElement.Next() = 0;

        TempPowerBISelectionElement.SetRange(TempPowerBISelectionElement.Type);
    end;
}