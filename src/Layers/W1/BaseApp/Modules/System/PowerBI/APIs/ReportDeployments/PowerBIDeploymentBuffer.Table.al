namespace System.Integration.PowerBI;

/// <summary>
/// Temporary table used by the Power BI Report Deployments page to display
/// the list of deployable reports with their current status.
/// All population and status-derivation logic is in table procedures.
/// </summary>
table 6318 "Power BI Deployment Buffer"
{
    Caption = 'Power BI Deployment Buffer';
    TableType = Temporary;
    Access = Internal;
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "Report Id"; Enum "Power BI Deployable Report")
        {
            Caption = 'Report Id';
            DataClassification = SystemMetadata;
        }
        field(2; "Report Name"; Text[200])
        {
            Caption = 'Report Name';
            DataClassification = SystemMetadata;
        }
        field(3; "Deployment Status"; Enum "Power BI Deployment Status")
        {
            Caption = 'Deployment Status';
            DataClassification = SystemMetadata;
        }
        field(4; "Deployed Version"; Text[100])
        {
            Caption = 'Deployed Version';
            DataClassification = SystemMetadata;
        }
        field(5; "Available Version"; Integer)
        {
            Caption = 'Available Version';
            DataClassification = SystemMetadata;
        }
        field(6; "Last Deployed"; DateTime)
        {
            Caption = 'Last Deployed';
            DataClassification = SystemMetadata;
        }
        field(7; "Current Step"; Text[100])
        {
            Caption = 'Current Step';
            DataClassification = SystemMetadata;
        }
        field(8; "Uploaded Report ID"; Guid)
        {
            Caption = 'Uploaded Report ID';
            DataClassification = SystemMetadata;
        }
    }

    keys
    {
        key(PK; "Report Id")
        {
            Clustered = true;
        }
    }

    procedure LoadReports()
    var
        PowerBIDeployment: Record "Power BI Deployment";
        LatestState: Record "Power BI Deployment State";
        DeployableReport: Interface "Power BI Deployable Report";
        ReportEnum: Enum "Power BI Deployable Report";
        Ordinals: List of [Integer];
        OrdinalValue: Integer;
        HasDeploymentRecord: Boolean;
    begin
        Rec.DeleteAll();
        Ordinals := Enum::"Power BI Deployable Report".Ordinals();

        foreach OrdinalValue in Ordinals do begin
            ReportEnum := Enum::"Power BI Deployable Report".FromInteger(OrdinalValue);
            DeployableReport := ReportEnum;

            Rec.Init();
            Rec."Report Id" := ReportEnum;
            Rec."Report Name" := DeployableReport.GetReportName();
            Rec."Available Version" := DeployableReport.GetVersion();

            HasDeploymentRecord := PowerBIDeployment.Get(ReportEnum);
            if HasDeploymentRecord then begin
                if PowerBIDeployment."Deployed Version" <> 0 then
                    Rec."Deployed Version" := Format(PowerBIDeployment."Deployed Version");

                Rec."Uploaded Report ID" := PowerBIDeployment."Uploaded Report ID";
                Rec."Last Deployed" := PowerBIDeployment.GetLatestCompletedState()."Reached At";
                if PowerBIDeployment.GetLatestStateRecord(LatestState) then
                    Rec."Current Step" := Format(LatestState."Status Reached");
            end;
            Rec."Deployment Status" := DeriveDeploymentStatus(PowerBIDeployment, HasDeploymentRecord);
            Rec.Insert();
        end;

        if Rec.FindFirst() then;
    end;

    local procedure DeriveDeploymentStatus(PowerBIDeployment: Record "Power BI Deployment"; HasDeploymentRecord: Boolean): Enum "Power BI Deployment Status"
    var
        UploadStatus: Enum "Power BI Upload Status";
    begin
        if not HasDeploymentRecord then
            exit(Enum::"Power BI Deployment Status"::"Not Installed");

        UploadStatus := PowerBIDeployment.GetUploadStatus();

        if UploadStatus = Enum::"Power BI Upload Status"::Failed then
            exit(Enum::"Power BI Deployment Status"::Error);

        if PowerBIDeployment."Deployed Version" = 0 then
            case UploadStatus of
                Enum::"Power BI Upload Status"::NotStarted:
                    exit(Enum::"Power BI Deployment Status"::Queued);
                else
                    exit(Enum::"Power BI Deployment Status"::Installing);
            end;

        if Rec."Available Version" > PowerBIDeployment."Deployed Version" then
            exit(Enum::"Power BI Deployment Status"::"Update Available");

        exit(Enum::"Power BI Deployment Status"::"Up to Date");
    end;
}
