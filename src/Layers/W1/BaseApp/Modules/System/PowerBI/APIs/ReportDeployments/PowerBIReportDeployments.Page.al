namespace System.Integration.PowerBI;
using System.Environment;

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
    AboutText = 'Deploy Power BI reports to your workspace, update them when new versions are available, and retry deployments that have failed. This experience is only available in evaluation companies.';

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
                    Enabled = IsEvaluationCompany;
                    ToolTip = 'Deploys the selected reports to your Power BI workspace. Only available in evaluation companies.';

                    trigger OnAction()
                    var
                        PowerBIDeployment: Record "Power BI Deployment";
                        SelectedBuffer: Record "Power BI Deployment Buffer";
                        PowerBIServiceMgt: Codeunit "Power BI Service Mgt.";
                    begin
                        SelectedBuffer.LoadReports();
                        CurrPage.SetSelectionFilter(SelectedBuffer);
                        if not SelectedBuffer.FindSet() then
                            Error(NoReportSelectedErr);

                        repeat
                            if not PowerBIDeployment.Get(SelectedBuffer."Report Id") then begin
                                PowerBIDeployment.Init();
                                PowerBIDeployment."Report Id" := SelectedBuffer."Report Id";
                                PowerBIDeployment.Insert(true);
                            end;
                        until SelectedBuffer.Next() = 0;

                        PowerBIServiceMgt.SynchronizeReportsInBackground('');
                        Rec.LoadReports();
                        CurrPage.Update(false);
                    end;
                }
                action(Update)
                {
                    ApplicationArea = All;
                    Caption = 'Update';
                    Image = UpdateXML;
                    Enabled = IsEvaluationCompany and CanUpdate;
                    ToolTip = 'Updates the selected reports to the latest available version. Only available in evaluation companies.';

                    trigger OnAction()
                    var
                        PowerBIDeployment: Record "Power BI Deployment";
                        SelectedBuffer: Record "Power BI Deployment Buffer";
                        PowerBIServiceMgt: Codeunit "Power BI Service Mgt.";
                    begin
                        SelectedBuffer.LoadReports();
                        CurrPage.SetSelectionFilter(SelectedBuffer);
                        if not SelectedBuffer.FindSet() then
                            Error(NoReportSelectedErr);

                        repeat
                            if SelectedBuffer."Deployment Status" = Enum::"Power BI Deployment Status"::"Update Available" then
                                if PowerBIDeployment.Get(SelectedBuffer."Report Id") then
                                    PowerBIDeployment.ResetDeployment();
                        until SelectedBuffer.Next() = 0;

                        PowerBIServiceMgt.SynchronizeReportsInBackground('');
                        Rec.LoadReports();
                        CurrPage.Update(false);
                    end;
                }
                action(Retry)
                {
                    ApplicationArea = All;
                    Caption = 'Retry';
                    Image = ResetStatus;
                    Enabled = IsEvaluationCompany and CanRetry;
                    ToolTip = 'Resets the failed deployment and retries from scratch. Only available in evaluation companies.';

                    trigger OnAction()
                    var
                        PowerBIDeployment: Record "Power BI Deployment";
                        SelectedBuffer: Record "Power BI Deployment Buffer";
                        PowerBIServiceMgt: Codeunit "Power BI Service Mgt.";
                    begin
                        SelectedBuffer.LoadReports();
                        CurrPage.SetSelectionFilter(SelectedBuffer);
                        if not SelectedBuffer.FindSet() then
                            Error(NoReportSelectedErr);

                        repeat
                            if SelectedBuffer."Deployment Status" = Enum::"Power BI Deployment Status"::Error then
                                if PowerBIDeployment.Get(SelectedBuffer."Report Id") then
                                    PowerBIDeployment.ResetDeployment();
                        until SelectedBuffer.Next() = 0;

                        PowerBIServiceMgt.SynchronizeReportsInBackground('');
                        Rec.LoadReports();
                        CurrPage.Update(false);
                    end;
                }
                action(DownloadPbix)
                {
                    ApplicationArea = All;
                    Caption = 'Download PBIX';
                    Image = ExportFile;
                    Enabled = IsEvaluationCompany;
                    ToolTip = 'Downloads the PBIX file of the selected report. Only available in evaluation companies.';

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
                    Enabled = IsEvaluationCompany;
                    ToolTip = 'Refreshes the deployment status of the reports. Only available in evaluation companies.';

                    trigger OnAction()
                    begin
                        Rec.LoadReports();
                        CurrPage.Update(false);
                    end;
                }
                action(ClearDeploymentRecords)
                {
                    ApplicationArea = All;
                    Caption = 'Clear Deployment Records';
                    Image = ClearLog;
                    Enabled = IsEvaluationCompany;
                    ToolTip = 'Deletes all data in Business Central about Power BI deployments (shown in this list). Reports already uploaded to the Power BI workspace are not removed. Only available in evaluation companies.';

                    trigger OnAction()
                    var
                        PowerBIDeployment: Record "Power BI Deployment";
                    begin
                        if not Confirm(ClearDeploymentRecordsQst) then
                            exit;
                        PowerBIDeployment.DeleteAllRecords();
                        Rec.LoadReports();
                        CurrPage.Update(false);
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
                Enabled = IsEvaluationCompany and CanOpenInPowerBI;
                ToolTip = 'Opens the deployed report in Power BI. Only available in evaluation companies.';

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
    var
        Company: Record Company;
    begin
        Company.Get(CompanyName());
        IsEvaluationCompany := Company."Evaluation Company";
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
        IsEvaluationCompany: Boolean;
        NoReportSelectedErr: Label 'No report has been selected for deployment.';
        DownloadDialogTitleLbl: Label 'Download Power BI Report';
        PbixFileFilterLbl: Label 'Power BI Files (*.pbix)|*.pbix';
        ClearDeploymentRecordsQst: Label 'This will wipe all local Power BI deployment tracking data for this company. Reports already in your Power BI workspace will not be removed. Continue?';
}
