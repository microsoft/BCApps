namespace System.Security.User;

using Microsoft.Integration.Dataverse;
using Microsoft.Integration.SyncEngine;
using Microsoft.RoleCenters;
using System;
using System.Azure.Identity;
using System.Diagnostics;
using System.Environment;
using System.Environment.Configuration;
#if not CLEAN28
using System.Feedback;
#endif
using System.Privacy;

page 9062 "User Security Activities"
{
    Caption = 'User Security Activities';
    Editable = false;
    PageType = CardPart;
    RefreshOnActivate = true;
    SourceTable = "User Security Status";

    layout
    {
        area(content)
        {
            cuegroup(Control2)
            {
                ShowCaption = false;
                field("Users - To review"; Rec."Users - To review")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Users - To review';
                    DrillDownPageID = "User Security Status List";
                    Editable = false;
                    ToolTip = 'Specifies new users who have not yet been reviewed by an administrator.';
                }
                field("Users - Without Subscriptions"; UsersWithoutSubscriptions)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Users - Without Subscription Plans';
                    DrillDownPageID = "User Security Status List";
                    Editable = false;
                    ToolTip = 'Specifies users without subscription to use Business Central.';
                    Visible = SoftwareAsAService;
                }
                field(NumberOfPlans; NumberOfPlans)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Number of plans';
                    ToolTip = 'Specifies the number of plans.';
                    Visible = SoftwareAsAService;

                    trigger OnDrillDown()
                    begin
                        if not SoftwareAsAService then
                            exit;
                        PAGE.Run(PAGE::Plans)
                    end;
                }
            }
            cuegroup("Data Privacy")
            {
                Caption = 'Data Privacy';
                field(UnclassifiedFields; UnclassifiedFields)
                {
                    ApplicationArea = All;
                    Caption = 'Fields Missing Data Sensitivity';
                    ToolTip = 'Specifies the number fields with Data Sensitivity set to unclassified.';

                    trigger OnDrillDown()
                    var
                        DataSensitivity: Record "Data Sensitivity";
                    begin
                        DataSensitivity.SetRange("Company Name", CompanyName);
                        DataSensitivity.SetRange("Data Sensitivity", DataSensitivity."Data Sensitivity"::Unclassified);
                        PAGE.Run(PAGE::"Data Classification Worksheet", DataSensitivity);
                    end;
                }
            }
            cuegroup("Data Integration")
            {
                Caption = 'Data Integration';
                Visible = ShowDataIntegrationCues;
                field("CDS Integration Errors"; Rec."CDS Integration Errors")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Integration Errors';
                    DrillDownPageID = "Integration Synch. Error List";
                    ToolTip = 'Specifies the number of errors related to data integration.';
                    Visible = ShowDataIntegrationCues;
                    StyleExpr = IntegrationErrorsCue;
                }
                field("Coupled Data Synch Errors"; Rec."Coupled Data Synch Errors")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Coupled Data Synchronization Errors';
                    DrillDownPageID = "CRM Skipped Records";
                    ToolTip = 'Specifies the number of errors that occurred in the latest synchronization of coupled data between Business Central and Dynamics 365 Sales.';
                    Visible = ShowD365SIntegrationCues;
                    StyleExpr = CoupledErrorsCue;
                }
            }
            cuegroup("Monitored Fields Changes")
            {
                Caption = 'Monitor Fields Changes';

                field(MonitorEntriesNotifications; MonitorEntriesNotifications)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Entries Notifications';
                    ToolTip = 'Specifies new monitored changes to selected fields';
                    trigger OnDrillDown()
                    begin
                        Page.Run(Page::"Monitored Field Log Entries");
                    end;
                }
            }
#if not CLEAN28
            usercontrol(SATAsyncLoader; SatisfactionSurveyAsync)
            {
                ApplicationArea = Basic, Suite;
                Visible = false;
                ObsoleteReason = 'The Satisfaction Survey feature will be removed in a future release.';
                ObsoleteState = Pending;
                ObsoleteTag = '28.0';
            }
#endif
        }
    }

    actions
    {
    }

    trigger OnOpenPage()
    var
        UserSecurityStatus: Record "User Security Status";
        DataSensitivity: Record "Data Sensitivity";
        IntegrationSynchJobErrors: Record "Integration Synch. Job Errors";
        CRMIntegrationRecord: Record "CRM Integration Record";
        EnvironmentInfo: Codeunit "Environment Information";
        RoleCenterNotificationMgt: Codeunit "Role Center Notification Mgt.";
        ConfPersonalizationMgt: Codeunit "Conf./Personalization Mgt.";
        CDSIntegrationMgt: Codeunit "CDS Integration Mgt.";
        MonitorSensitiveField: codeunit "Monitor Sensitive Field";
        CRMIntegrationManagement: Codeunit "CRM Integration Management";
    begin
        SoftwareAsAService := EnvironmentInfo.IsSaaS();
        if SoftwareAsAService then
            NumberOfPlans := GetNumberOfPlans();
        UserSecurityStatus.LoadUsers();
        Rec.Reset();
        if not Rec.Get() then begin
            Rec.Init();
            Rec.Insert();
        end;

        DataSensitivity.SetRange("Company Name", CompanyName);
        DataSensitivity.SetRange("Data Sensitivity", DataSensitivity."Data Sensitivity"::Unclassified);
        UnclassifiedFields := DataSensitivity.Count();

        RoleCenterNotificationMgt.ShowNotifications();
        ConfPersonalizationMgt.RaiseOnOpenRoleCenterEvent();
        IntegrationSynchJobErrors.SetDataIntegrationUIElementsVisible(ShowDataIntegrationCues);
        ShowD365SIntegrationCues := CRMIntegrationManagement.IsIntegrationEnabled() or CDSIntegrationMgt.IsIntegrationEnabled();

        if IntegrationSynchJobErrors.IsEmpty() then
            IntegrationErrorsCue := 'Favorable'
        else
            IntegrationErrorsCue := 'Unfavorable';
        CRMIntegrationRecord.SetRange(Skipped, true);
        if CRMIntegrationRecord.IsEmpty() then
            CoupledErrorsCue := 'Favorable'
        else
            CoupledErrorsCue := 'Unfavorable';

        if PageNotifier.IsAvailable() then begin
            PageNotifier := PageNotifier.Create();
            PageNotifier.NotifyPageReady();
        end;

        MonitorEntriesNotifications := MonitorSensitiveField.GetNotificationCount();
        MonitorSensitiveField.ShowPromoteMonitorSensitiveFieldNotification();
    end;

    trigger OnAfterGetRecord()
    var
        UserSecurityStatus: Record "User Security Status";
        AzureADPlan: Codeunit "Azure AD Plan";
    begin
        UsersWithoutSubscriptions := 0;

        if UserSecurityStatus.FindSet() then
            repeat
                if UserSecurityStatus."User Security ID" <> '00000000-0000-0000-0000-000000000000' then
                    if not AzureADPlan.DoesUserHavePlans(UserSecurityStatus."User Security ID") then
                        UsersWithoutSubscriptions := UsersWithoutSubscriptions + 1;
            until UserSecurityStatus.Next() = 0;
    end;

    var
        [RunOnClient]
        [WithEvents]
        PageNotifier: DotNet PageNotifier;
        SoftwareAsAService: Boolean;
        NumberOfPlans: Integer;
        UnclassifiedFields: Integer;
        ShowD365SIntegrationCues: Boolean;
        ShowDataIntegrationCues: Boolean;
        UsersWithoutSubscriptions: Integer;
        MonitorEntriesNotifications: Integer;
        IntegrationErrorsCue: Text;
        CoupledErrorsCue: Text;

    local procedure GetNumberOfPlans(): Integer
    var
        AzureADPlan: Codeunit "Azure AD Plan";
    begin
        if not SoftwareAsAService then
            exit(0);
        exit(AzureADPlan.GetAvailablePlansCount());
    end;
}

