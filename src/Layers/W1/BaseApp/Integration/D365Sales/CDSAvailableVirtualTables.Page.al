// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Integration.D365Sales;

using Microsoft.Integration.Dataverse;

page 5372 "CDS Available Virtual Tables"
{
    PageType = List;
    Caption = 'Available Virtual Tables - Dataverse';
    AnalysisModeEnabled = false;
    SourceTable = "CDS Av. Virtual Table Buffer";
    SourceTableTemporary = true;
    SourceTableView = sorting("Phsyical Name");
    Extensible = false;
    InsertAllowed = false;
    DeleteAllowed = false;
    Editable = false;

    layout
    {
        area(Content)
        {
            repeater(Control2)
            {
                field(Name; Rec."Phsyical Name")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the physical name of the virtual table.';
                }
                field("Display Name"; Rec."Display Name")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the display name of the virtual table.';
                }
                field("API Route"; Rec."API Route")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the API route of the virtual table.';
                }
                field(Visible; Rec.Visible)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the visibility of the virtual table.';
                }
                field("In Process"; Rec."In Process")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies whether the enabling of virtual table is in process.';
                }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(Enable)
            {
                ApplicationArea = All;
                Caption = 'Enable';
                Image = Setup;
                ToolTip = 'Enables the selected virtual tables in Dataverse environment.';
                Enabled = not Rec.Visible and not Rec."In Process";

                trigger OnAction()
                var
                    CDSIntegrationImpl: Codeunit "CDS Integration Impl.";
                    FilterList: List of [Text];
                begin
                    CurrPage.SetSelectionFilter(Rec);
                    Rec.SetRange(Visible, false);
                    Rec.SetRange(Rec."In Process", false);
                    if Rec.FindSet() then
                        repeat
                            FilterList.Add(Rec."CDS Entity Logical Name");
                        until Rec.Next() = 0;

                    CDSIntegrationImpl.ScheduleEnablingVirtualTables(FilterList);
                    Rec.ModifyAll("In Process", true);
                    SendNotification();

                    Rec.Reset();
                    Rec.SetCurrentKey("Phsyical Name");
                    Rec.SetAscending(Rec."Phsyical Name", true);
                    Rec.FindSet();
                end;
            }
            action(Refresh)
            {
                ApplicationArea = All;
                Caption = 'Refresh';
                Image = Refresh;
                ToolTip = 'Refreshes the list of available virtual tables from Dataverse environment.';

                trigger OnAction()
                var
                    CDSIntegrationImpl: Codeunit "CDS Integration Impl.";
                begin
                    Rec.DeleteAll();
                    CDSIntegrationImpl.LoadAvailableVirtualTables(Rec, false);
                end;
            }
            action("Open in Dataverse")
            {
                ApplicationArea = Suite;
                Caption = 'Open in Dataverse';
                Image = Link;
                ToolTip = 'Manage available virtual tables in your Dataverse environment.';

                trigger OnAction()
                var
                    CDSConnectionSetup: Record "CDS Connection Setup";
                    CDSIntegrationImpl: Codeunit "CDS Integration Impl.";
                    EntityListUrl: Text;
                begin
                    if CDSConnectionSetup.Get() then
                        EntityListUrl := CDSIntegrationImpl.GetCRMEntityListUrl(CDSConnectionSetup, VirtualTableEntityNameTxt, VirtualTableAppNameTxt);
                    Hyperlink(EntityListUrl);
                end;
            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                Caption = 'Process';

                actionref("Enable_Promoted"; Enable)
                {
                }
                actionref("Refresh_Promoted"; Refresh)
                {
                }
                actionref("Open in Dataverse_Promoted"; "Open in Dataverse")
                {
                }
            }
        }
    }

    trigger OnOpenPage()
    var
        CDSIntegrationImpl: Codeunit "CDS Integration Impl.";
    begin
        if Rec.IsEmpty() then
            CDSIntegrationImpl.LoadAvailableVirtualTables(Rec, false);
    end;

    var
        EnablingJobScheduledNotificationLbl: Label 'A job queue entry has been scheduled to enable the selected virtual tables in the Dataverse environment. You can close this page and continue working.';
        DetailsTxt: Label 'Details';
        VirtualTableEntityNameTxt: Label 'dyn365bc_businesscentralentity', Locked = true;
        VirtualTableAppNameTxt: Label 'dyn365bc_BusinessCentralConfiguration', Locked = true;

    local procedure SendNotification()
    var
        ScheduledJobNotification: Notification;
    begin
        ScheduledJobNotification.Message(EnablingJobScheduledNotificationLbl);
        ScheduledJobNotification.Scope(NotificationScope::LocalScope);
        ScheduledJobNotification.AddAction(DetailsTxt, Codeunit::"CDS Integration Impl.", 'OpenEnableVirtualTablesJobFromNotification');
        ScheduledJobNotification.Send();
    end;
}