namespace System.Integration.PowerBI;

/// <summary>
/// Temporary table used by the Power BI Report Deployments page to display the list of deployable reports with their current status.
/// </summary>
table 6318 "Power BI Deployment Buffer"
{
    Caption = 'Power BI Deployment Buffer';
    TableType = Temporary;
    Access = Public;
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
        field(9; "Deployed Workspace Name"; Text[200])
        {
            Caption = 'Deployed Workspace Name';
            DataClassification = CustomerContent;
        }
        field(10; Outcome; Enum "Power BI Deployment Outcome")
        {
            Caption = 'Outcome';
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
        ReportEnum: Enum "Power BI Deployable Report";
        Ordinals: List of [Integer];
        OrdinalValue: Integer;
    begin
        Rec.Reset();
        Rec.DeleteAll();
        Ordinals := Enum::"Power BI Deployable Report".Ordinals();

        foreach OrdinalValue in Ordinals do begin
            ReportEnum := Enum::"Power BI Deployable Report".FromInteger(OrdinalValue);
            LoadReport(ReportEnum);
            Rec.Insert();
        end;

        if Rec.FindFirst() then;
    end;

    procedure LoadSelection(var SelectedDeploymentBuffer: Record "Power BI Deployment Buffer")
    var
        TempSourceBuffer: Record "Power BI Deployment Buffer";
    begin
        Rec.Reset();
        Rec.DeleteAll();

        TempSourceBuffer.Copy(SelectedDeploymentBuffer, true);
        if TempSourceBuffer.FindSet() then
            repeat
                LoadReport(TempSourceBuffer."Report Id");
                Rec.Insert();
            until TempSourceBuffer.Next() = 0;

        Rec.Reset();
        if Rec.FindFirst() then;
    end;

    procedure CountForOutcome(OutcomeToCount: Enum "Power BI Deployment Outcome"): Integer
    var
        TempDeploymentBuffer: Record "Power BI Deployment Buffer";
    begin
        TempDeploymentBuffer.Copy(Rec, true);
        TempDeploymentBuffer.Reset();
        TempDeploymentBuffer.SetRange(Outcome, OutcomeToCount);
        exit(TempDeploymentBuffer.Count());
    end;

    internal procedure RemoveOutcome(OutcomeToRemove: Enum "Power BI Deployment Outcome")
    var
        TempDeploymentBuffer: Record "Power BI Deployment Buffer";
    begin
        TempDeploymentBuffer.Copy(Rec, true);
        TempDeploymentBuffer.Reset();
        TempDeploymentBuffer.SetRange(Outcome, OutcomeToRemove);
        TempDeploymentBuffer.DeleteAll();
    end;

    local procedure LoadReport(ReportEnum: Enum "Power BI Deployable Report")
    var
        PowerBIDeployment: Record "Power BI Deployment";
        LatestState: Record "Power BI Deployment State";
        DeployableReport: Interface "Power BI Deployable Report";
        HasDeploymentRecord: Boolean;
    begin
        DeployableReport := ReportEnum;

        Rec.Init();
        Rec."Report Id" := ReportEnum;
        Rec."Report Name" := DeployableReport.GetReportName();
        Rec."Available Version" := DeployableReport.GetVersion();

        Clear(PowerBIDeployment);
        HasDeploymentRecord := PowerBIDeployment.Get(ReportEnum);
        if HasDeploymentRecord then begin
            if PowerBIDeployment."Deployed Version" <> 0 then
                Rec."Deployed Version" := Format(PowerBIDeployment."Deployed Version");

            Rec."Uploaded Report ID" := PowerBIDeployment."Uploaded Report ID";
            Rec."Deployed Workspace Name" := PowerBIDeployment."Deployed Workspace Name";
            Rec."Last Deployed" := PowerBIDeployment.GetLatestCompletedState()."Reached At";
            if PowerBIDeployment.GetLatestStateRecord(LatestState) then
                Rec."Current Step" := Format(LatestState."Status Reached");
        end;

        Rec."Deployment Status" := PowerBIDeployment.GetDeploymentStatus();
        Rec.Outcome := PowerBIDeployment.GetDeploymentOutcome(Rec."Deployment Status");
    end;
}
