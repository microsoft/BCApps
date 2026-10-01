namespace System.Integration.PowerBI;
using System.Threading;

page 6347 "Power BI Report Deployments"
{
    ApplicationArea = All;
    Caption = 'Power BI Report Deployments';
    PageType = List;
    SourceTable = "Power BI Deployment Buffer";
    UsageCategory = Administration;
    InsertAllowed = false;
    DeleteAllowed = false;
    ModifyAllowed = false;
    AnalysisModeEnabled = false;
    AboutTitle = 'About Power BI report deployments';
    AboutText = 'Deploy Power BI reports to your workspace, update them when new versions are available, and retry deployments that have failed.';

    layout
    {
        area(content)
        {
            repeater(Reports)
            {
                field(ReportName; Rec."Report Name")
                {
                    ApplicationArea = All;
                    Caption = 'Report Name';
                    ToolTip = 'Specifies the name of the deployable Power BI report.';
                }
                field(DeploymentStatus; Rec."Deployment Status")
                {
                    ApplicationArea = All;
                    Caption = 'Deployment Status';
                    ToolTip = 'Specifies the deployment status of the report.';
                    StyleExpr = StatusStyle;

                    trigger OnDrillDown()
                    var
                        DeploymentState: Record "Power BI Deployment State";
                        DeploymentStepsPage: Page "Power BI Deployment Steps";
                    begin
                        DeploymentState.SetRange("Report Id", Rec."Report Id");
                        DeploymentStepsPage.SetTableView(DeploymentState);
                        DeploymentStepsPage.RunModal();
                    end;
                }
                field(CurrentStep; CurrentStepText)
                {
                    ApplicationArea = All;
                    Editable = false;
                    Caption = 'Current Deployment Step';
                    ToolTip = 'Specifies the current pipeline step for reports that are installing or in error.';
                }
                field(DeployedVersion; Rec."Deployed Version")
                {
                    ApplicationArea = All;
                    Caption = 'Deployed Version';
                    ToolTip = 'Specifies the version of the report currently deployed to Power BI.';
                }
                field(AvailableVersion; Rec."Available Version")
                {
                    ApplicationArea = All;
                    Caption = 'Available Version';
                    ToolTip = 'Specifies the latest version of the report available for deployment.';
                }
                field(LastDeployed; Rec."Last Deployed")
                {
                    ApplicationArea = All;
                    Caption = 'Last Deployed';
                    ToolTip = 'Specifies the date and time when the report was last successfully deployed.';
                }
                field(DeployedWorkspaceName; Rec."Deployed Workspace Name")
                {
                    ApplicationArea = All;
                    Caption = 'Deployed Workspace';
                    ToolTip = 'Specifies the Power BI workspace that the report was last deployed to. This can differ from the workspace configured on the Company Information page, if the workspace was changed after the report was deployed.';
                }
            }
        }
    }

    actions
    {
        area(processing)
        {
            group(DeploymentActions)
            {
                Caption = 'Deployment';

                action(Deploy)
                {
                    ApplicationArea = All;
                    Caption = 'Deploy';
                    Image = Setup;
                    ToolTip = 'Installs the selected reports in your Power BI workspace, or replaces them with a fresh copy if they are already deployed.';

                    trigger OnAction()
                    var
                        SelectedBuffer: Record "Power BI Deployment Buffer";
                        TempSelection: Record "Power BI Deployment Buffer" temporary;
                        PowerBIWorkspaceMgt: Codeunit "Power BI Workspace Mgt.";
                        InProgressCount: Integer;
                        ReplaceCount: Integer;
                    begin
                        PowerBIWorkspaceMgt.CheckTargetWorkspaceAllowsDeployment();
                        GetSelectedReports(SelectedBuffer);
                        TempSelection.LoadSelection(SelectedBuffer);

                        InProgressCount := TempSelection.CountForOutcome(Enum::"Power BI Deployment Outcome"::"In Progress");
                        if InProgressCount > 0 then
                            Message(DeploymentInProgressMsg, InProgressCount);
                        TempSelection.RemoveOutcome(Enum::"Power BI Deployment Outcome"::"In Progress");

                        ReplaceCount := TempSelection.CountForOutcome(Enum::"Power BI Deployment Outcome"::Finished);
                        if ReplaceCount > 0 then
                            if not Confirm(StrSubstNo(ReplaceDeployedReportQst, ReplaceCount)) then
                                exit;

                        if TempSelection.IsEmpty() then begin
                            if InProgressCount = 0 then
                                Message(NothingToDeployMsg);
                            RefreshReports();
                            exit;
                        end;

                        QueueAndSynchronize(TempSelection);
                        RefreshReports();
                    end;
                }
                action(Update)
                {
                    ApplicationArea = All;
                    Caption = 'Update';
                    Image = UpdateXML;
                    Enabled = CanUpdate;
                    ToolTip = 'Updates the selected reports to the latest available version.';

                    trigger OnAction()
                    var
                        SelectedBuffer: Record "Power BI Deployment Buffer";
                        TempSelection: Record "Power BI Deployment Buffer" temporary;
                        PowerBIWorkspaceMgt: Codeunit "Power BI Workspace Mgt.";
                    begin
                        PowerBIWorkspaceMgt.CheckTargetWorkspaceAllowsDeployment();
                        GetSelectedReports(SelectedBuffer);
                        TempSelection.LoadSelection(SelectedBuffer);

                        TempSelection.SetRange("Deployment Status", Enum::"Power BI Deployment Status"::"Update Available");

                        if TempSelection.IsEmpty() then begin
                            Message(NoUpdateAvailableMsg);
                            exit;
                        end;

                        QueueAndSynchronize(TempSelection);
                        RefreshReports();
                    end;
                }
                action(Retry)
                {
                    ApplicationArea = All;
                    Caption = 'Retry';
                    Image = ResetStatus;
                    Enabled = CanRetry;
                    ToolTip = 'Resets the failed deployment and retries from scratch.';

                    trigger OnAction()
                    var
                        SelectedBuffer: Record "Power BI Deployment Buffer";
                        TempSelection: Record "Power BI Deployment Buffer" temporary;
                        PowerBIWorkspaceMgt: Codeunit "Power BI Workspace Mgt.";
                    begin
                        PowerBIWorkspaceMgt.CheckTargetWorkspaceAllowsDeployment();
                        GetSelectedReports(SelectedBuffer);
                        TempSelection.LoadSelection(SelectedBuffer);

                        TempSelection.SetRange(Outcome, Enum::"Power BI Deployment Outcome"::Failed);

                        if TempSelection.IsEmpty() then begin
                            Message(NothingToRetryMsg);
                            exit;
                        end;

                        QueueAndSynchronize(TempSelection);
                        RefreshReports();
                    end;
                }
                action(DownloadPbix)
                {
                    ApplicationArea = All;
                    Caption = 'Download PBIX';
                    Image = ExportFile;
                    ToolTip = 'Downloads the PBIX file of the selected report.';

                    trigger OnAction()
                    var
                        DeployableReport: Interface "Power BI Deployable Report";
                        BlobInStream: InStream;
                        FileName: Text;
                    begin
                        DeployableReport := Rec."Report Id";
                        DeployableReport.GetStream(BlobInStream);
                        FileName := DeployableReport.GetReportName() + '.pbix';
                        DownloadFromStream(BlobInStream, DownloadDialogTitleLbl, '', PbixFileFilterLbl, FileName);
                    end;
                }
                action(Refresh)
                {
                    ApplicationArea = All;
                    Caption = 'Reload';
                    Image = Refresh;
                    ToolTip = 'Refreshes the deployment status of the reports.';

                    trigger OnAction()
                    begin
                        RefreshReports();
                    end;
                }
                action(ClearDeploymentRecords)
                {
                    ApplicationArea = All;
                    Caption = 'Clear Deployment Records';
                    Image = ClearLog;
                    ToolTip = 'Deletes all data in Business Central about Power BI deployments (shown in this list). Reports already uploaded to the Power BI workspace are not removed.';

                    trigger OnAction()
                    var
                        PowerBIDeployment: Record "Power BI Deployment";
                    begin
                        if not Confirm(ClearDeploymentRecordsQst) then
                            exit;
                        PowerBIDeployment.DeleteAllRecords();
                        RefreshReports();
                    end;
                }
            }
        }
        area(navigation)
        {
            action(OpenInPowerBI)
            {
                ApplicationArea = All;
                Caption = 'Open in Power BI';
                Image = Open;
                Enabled = CanOpenInPowerBI;
                ToolTip = 'Opens the deployed report in Power BI.';

                trigger OnAction()
                var
                    PowerBIDeployment: Record "Power BI Deployment";
                    PowerBIUrlMgt: Codeunit "Power BI Url Mgt";
                begin
                    PowerBIDeployment.Get(Rec."Report Id");
                    Hyperlink(PowerBIUrlMgt.GetPowerBIReportUrl(PowerBIDeployment."Uploaded Report ID"));
                end;
            }
            group(NavigateActions)
            {
                Caption = 'Navigate';

                action(ShowDeploymentJobQueue)
                {
                    ApplicationArea = All;
                    Caption = 'Deployment Job Queue Entries';
                    Image = JobListSetup;
                    ToolTip = 'Opens the job queue entries that carry out the deployments, so you can check whether the background job is running, waiting for another entry, or in error.';

                    trigger OnAction()
                    var
                        JobQueueEntry: Record "Job Queue Entry";
                    begin
                        JobQueueEntry.SetRange("Object Type to Run", JobQueueEntry."Object Type to Run"::Codeunit);
                        JobQueueEntry.SetRange("Object ID to Run", Codeunit::"Power BI Report Synchronizer");
                        Page.Run(Page::"Job Queue Entries", JobQueueEntry);
                    end;
                }
            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                Caption = 'Deployment';

                actionref(Deploy_Promoted; Deploy)
                {
                }
                actionref(Update_Promoted; Update)
                {
                }
                actionref(Retry_Promoted; Retry)
                {
                }
                actionref(DownloadPbix_Promoted; DownloadPbix)
                {
                }
                actionref(Refresh_Promoted; Refresh)
                {
                }
                actionref(ClearDeploymentRecords_Promoted; ClearDeploymentRecords)
                {
                }
                actionref(OpenInPowerBI_Promoted; OpenInPowerBI)
                {
                }
            }
            group(Category_Category2)
            {
                Caption = 'Navigate';
            }
        }
    }

    trigger OnOpenPage()
    begin
        Rec.LoadReports();
    end;

    trigger OnAfterGetRecord()
    begin
        case Rec."Deployment Status" of
            Enum::"Power BI Deployment Status"::Error:
                StatusStyle := 'Unfavorable';
            Enum::"Power BI Deployment Status"::"Up to Date":
                StatusStyle := 'Favorable';
            Enum::"Power BI Deployment Status"::"Update Available":
                StatusStyle := 'Attention';
            Enum::"Power BI Deployment Status"::Installing,
            Enum::"Power BI Deployment Status"::Queued:
                StatusStyle := 'Ambiguous';
            else
                StatusStyle := 'Standard';
        end;
        case Rec."Deployment Status" of
            Enum::"Power BI Deployment Status"::Installing,
            Enum::"Power BI Deployment Status"::Error,
            Enum::"Power BI Deployment Status"::Queued:
                CurrentStepText := Rec."Current Step";
            else
                CurrentStepText := '';
        end;
    end;

    trigger OnAfterGetCurrRecord()
    begin
        CanUpdate := Rec."Deployment Status" = Enum::"Power BI Deployment Status"::"Update Available";
        CanRetry := Rec."Deployment Status" = Enum::"Power BI Deployment Status"::Error;
        CanOpenInPowerBI := not IsNullGuid(Rec."Uploaded Report ID");
    end;

    var
        StatusStyle: Text;
        CurrentStepText: Text;
        CanUpdate: Boolean;
        CanRetry: Boolean;
        CanOpenInPowerBI: Boolean;
        NoReportSelectedErr: Label 'No report has been selected for deployment.';
        DeploymentInProgressMsg: Label 'A deployment is already in progress for %1 of the selected reports, they were not re-deployed.', Comment = '%1 = the number of reports that are currently being deployed';
        ReplaceDeployedReportQst: Label 'Deploying replaces the %1 selected report(s) that are already deployed with a fresh copy in your Power BI workspace, instead of updating them in place. To move a deployed report to its latest available version, use the Update action.\Do you want to continue?', Comment = '%1 = the number of reports that are already deployed';
        NoUpdateAvailableMsg: Label 'There are no updates available for the selected reports.';
        NothingToRetryMsg: Label 'There are no failed deployments to retry among the selected reports.';
        NothingToDeployMsg: Label 'None of the selected reports can be deployed.';
        DownloadDialogTitleLbl: Label 'Download Power BI Report';
        PbixFileFilterLbl: Label 'Power BI Files (*.pbix)|*.pbix';
        ClearDeploymentRecordsQst: Label 'This will wipe all local Power BI deployment tracking data for this company. Reports already in your Power BI workspace will not be removed. Continue?';

    local procedure RefreshReports()
    begin
        Rec.LoadReports();
        CurrPage.Update(false);
    end;

    local procedure QueueAndSynchronize(var TempSelection: Record "Power BI Deployment Buffer" temporary)
    var
        PowerBIDeployment: Record "Power BI Deployment";
        PowerBIServiceMgt: Codeunit "Power BI Service Mgt.";
    begin
        if not TempSelection.FindSet() then
            exit;

        repeat
            PowerBIDeployment.QueueForDeployment(TempSelection."Report Id");
        until TempSelection.Next() = 0;

        PowerBIServiceMgt.SynchronizeReportsInBackground('');
    end;

    local procedure GetSelectedReports(var SelectedBuffer: Record "Power BI Deployment Buffer")
    begin
        SelectedBuffer.Copy(Rec, true);
        CurrPage.SetSelectionFilter(SelectedBuffer);
        if not SelectedBuffer.FindSet() then
            Error(NoReportSelectedErr);
    end;

}
