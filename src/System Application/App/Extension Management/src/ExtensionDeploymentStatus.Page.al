// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.Apps;

using System.Environment;

/// <summary>
/// Displays the deployment status for extensions that are deployed or are scheduled for deployment.
/// </summary>
page 2508 "Extension Deployment Status"
{
    Extensible = false;
    Editable = false;
    PageType = List;
    RefreshOnActivate = true;
    SourceTable = "NAV App Tenant Operation";
    ContextSensitiveHelpPage = 'ui-extensions';
    Permissions = tabledata "Nav App Tenant Operation" = r;
    UsageCategory = Administration;
    ApplicationArea = All;
    Caption = 'Extension Installation Status';

    layout
    {
        area(Content)
        {
            repeater(Group)
            {
                field(Name; AppName)
                {
                    ApplicationArea = All;
                    Caption = 'Name';
                    ToolTip = 'Specifies the name of the app.';
                }
                field(Publisher; AppPublisher)
                {
                    ApplicationArea = All;
                    Caption = 'Publisher';
                    ToolTip = 'Specifies the name of the app Publisher.';
                }
                field("Operation Type"; OperationType)
                {
                    ApplicationArea = All;
                    Caption = 'Operation Type';
                    ToolTip = 'Specifies the deployment type.';
                    OptionCaption = 'Upload,Install';
                }
                field(Status; Rec.Status)
                {
                    ApplicationArea = All;
                    Caption = 'Status';
                    ToolTip = 'Specifies the deployment status.';
                }
                field(Schedule; DeploymentSchedule)
                {
                    ApplicationArea = All;
                    Caption = 'Schedule';
                    ToolTip = 'Specifies the deployment schedule.';
                    Width = 12;
                }
                field(AppVersion; Version)
                {
                    ApplicationArea = All;
                    Caption = 'App Version';
                    ToolTip = 'Specifies the version of the app.';
                    Width = 6;
                }
                field("Started On"; Rec."Started On")
                {
                    ApplicationArea = All;
                    Caption = 'Started Date';
                    ToolTip = 'Specifies the deployment start date.';
                }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(View)
            {
                ApplicationArea = All;
                ToolTip = 'Specifies the status of the deployment.';
                Image = View;
                Scope = Repeater;
                ShortcutKey = 'Return';

                trigger OnAction()
                var
                    ExtnDeploymentStatusDetail: Page "Extn Deployment Status Detail";
                begin
                    ExtnDeploymentStatusDetail.SetRecord(Rec);
                    ExtnDeploymentStatusDetail.SetOperationRecord(Rec);
                    ExtnDeploymentStatusDetail.Update();
                    ExtnDeploymentStatusDetail.Run();
                end;
            }
            action(Refresh)
            {
                ApplicationArea = All;
                ToolTip = 'Refresh the deployment details.';
                Image = Refresh;

                trigger OnAction()
                var
                    NavAppTenantOperationTable: Record "NAV App Tenant Operation";
                    ExtensionOperationImpl: Codeunit "Extension Operation Impl";
                begin
                    NavAppTenantOperationTable.Copy(Rec);
                    NavAppTenantOperationTable.SetFilter(Status, '%1|%2|%3', NavAppTenantOperationTable.Status::Unknown, NavAppTenantOperationTable.Status::NotFound, NavAppTenantOperationTable.Status::InProgress);
                    if NavAppTenantOperationTable.FindSet() then
                        repeat
                            ExtensionOperationImpl.RefreshStatus(NavAppTenantOperationTable."Operation ID");
                        until NavAppTenantOperationTable.Next() = 0;
                end;
            }
            action("Upload Extension")
            {
                ApplicationArea = All;
                Caption = 'Upload Extension';
                Image = Import;
                RunObject = page "Upload And Deploy Extension";
                ToolTip = 'Upload an extension to your application.';
                Ellipsis = true;
                Visible = IsSaaS;
            }
        }
        area(Navigation)
        {
            action(ExtensionManagement)
            {
                Caption = 'Extension Management';
                ApplicationArea = All;
                ToolTip = 'Open the Extension Management page.';
                Image = Setup;
                RunObject = Page "Extension Management";
            }
        }
        area(Promoted)
        {
            actionref(Refresh_Promoted; Refresh) { }
            actionref(View_Promoted; View) { }
        }
    }

    trigger OnAfterGetRecord()
    var
        ExtensionOperationImpl: Codeunit "Extension Operation Impl";
    begin
        if Rec."Operation Type" = 0 then
            OperationType := OperationType::Install
        else
            OperationType := OperationType::Upload;

        ExtensionOperationImpl.GetDeployOperationInfo(Rec."Operation ID", Version, DeploymentSchedule, AppPublisher, AppName, Rec.Description);

        if Rec.Status = Rec.Status::InProgress then
            ExtensionOperationImpl.RefreshStatus(Rec."Operation ID");
    end;

    trigger OnOpenPage()
    begin
        Rec.SetCurrentKey("Started On");
        Rec.Ascending(false);

        DetermineEnvironmentConfigurations();
    end;

    local procedure DetermineEnvironmentConfigurations()
    var
        EnvironmentInformation: Codeunit "Environment Information";
    begin
        IsSaaS := EnvironmentInformation.IsSaaS();
    end;

    var
        Version: Text;
        DeploymentSchedule: Text;
        AppPublisher: Text;
        AppName: Text;
        OperationType: Option Upload,Install;
        IsSaaS: Boolean;
}


