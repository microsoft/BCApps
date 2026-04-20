// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.PowerBIReports;

using System.Integration.PowerBI;

page 36968 "PBI Report Deploy. Selection"
{
    PageType = NavigatePage;
    Caption = 'Deploy Power BI Reports';
    SourceTable = "Power BI Deployment Buffer";
    SourceTableTemporary = true;
    InsertAllowed = false;
    DeleteAllowed = false;

    layout
    {
        area(Content)
        {
            group(IntroGroup)
            {
                ShowCaption = false;
                InstructionalText = 'Select which reports to deploy to your Power BI workspace. Reports that are already scheduled or deployed cannot be selected.';
            }
            repeater(Reports)
            {
                field(Deploy; Rec.Deploy)
                {
                    ApplicationArea = All;
                    Caption = 'Deploy';
                    ToolTip = 'Specifies whether to deploy this report.';
                    Editable = DeployEditable;
                }
                field(ReportName; Rec."Report Name")
                {
                    ApplicationArea = All;
                    Editable = false;
                    Caption = 'Report Name';
                    ToolTip = 'Specifies the name of the Power BI report.';
                }
                field(DeploymentStatus; Rec."Deployment Status")
                {
                    ApplicationArea = All;
                    Editable = false;
                    Caption = 'Status';
                    ToolTip = 'Specifies the current deployment status.';
                    StyleExpr = StatusStyle;
                }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(DeployAction)
            {
                ApplicationArea = All;
                Caption = 'Deploy';
                Image = Approve;
                InFooterBar = true;
                ToolTip = 'Deploy the selected reports to your Power BI workspace.';

                trigger OnAction()
                begin
                    DeploySelectedReports();
                    CurrPage.Close();
                end;
            }
            action(SkipAction)
            {
                ApplicationArea = All;
                Caption = 'Skip';
                Image = Cancel;
                InFooterBar = true;
                ToolTip = 'Skip report deployment.';

                trigger OnAction()
                begin
                    CurrPage.Close();
                end;
            }
        }
    }

    trigger OnOpenPage()
    begin
        Rec.LoadReports();
        if Rec.FindSet() then
            repeat
                if Rec."Deployment Status" = Enum::"Power BI Deployment Status"::"Not Installed" then begin
                    Rec.Deploy := true;
                    Rec.Modify();
                end;
            until Rec.Next() = 0;
        if Rec.FindFirst() then;
    end;

    trigger OnAfterGetRecord()
    begin
        DeployEditable := Rec."Deployment Status" = Enum::"Power BI Deployment Status"::"Not Installed";

        case Rec."Deployment Status" of
            Enum::"Power BI Deployment Status"::"Not Installed":
                StatusStyle := 'Standard';
            Enum::"Power BI Deployment Status"::Error:
                StatusStyle := 'Unfavorable';
            Enum::"Power BI Deployment Status"::"Up to Date":
                StatusStyle := 'Favorable';
            Enum::"Power BI Deployment Status"::"Update Available":
                StatusStyle := 'Attention';
            else
                StatusStyle := 'Ambiguous';
        end;
    end;

    var
        DeployEditable: Boolean;
        StatusStyle: Text;

    local procedure DeploySelectedReports()
    var
        PowerBIDeployment: Record "Power BI Deployment";
        PowerBIServiceMgt: Codeunit "Power BI Service Mgt.";
        HasSelections: Boolean;
    begin
        Rec.SetRange(Deploy, true);
        if Rec.FindSet() then
            repeat
                if not PowerBIDeployment.Get(Rec."Report Id") then begin
                    PowerBIDeployment.Init();
                    PowerBIDeployment."Report Id" := Rec."Report Id";
                    PowerBIDeployment.Insert(true);
                    HasSelections := true;
                end;
            until Rec.Next() = 0;

        if HasSelections then
            PowerBIServiceMgt.SynchronizeReportsInBackground('');

        Rec.SetRange(Deploy);
    end;
}
