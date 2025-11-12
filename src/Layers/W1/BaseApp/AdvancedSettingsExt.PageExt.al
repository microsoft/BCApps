// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace System.Environment.Configuration;

using System.Automation;
using System.Environment;
using System.Utilities;
using Microsoft.Utilities;

pageextension 9202 "Advanced Settings Ext." extends "Advanced Settings"
{
    layout
    {
        addbefore(Header)
        {
            group(StandardBanner)
            {
                Editable = false;
                Visible = TopBannerVisible;

                field(MediaResourcesStandard; MediaResourcesStandard."Media Reference")
                {
                    ToolTip = 'Standard Banner';
                    ApplicationArea = All;
                    ShowCaption = false;
                }
            }
        }

        addafter(Header)
        {
            grid(BaseAppRow)
            {
                ShowCaption = false;
                GridLayout = Rows;

                group(ServiceConnectionsGroup)
                {
                    InstructionalText = 'Set up and manage use of external services.';
                    ShowCaption = false;

                    field(ServiceConnections; ServiceConnectionsLbl)
                    {
                        ShowCaption = false;
                        ApplicationArea = All;
                        DrillDown = true;
                        Caption = 'Service Connections';
                        ToolTip = 'Open the Service Connections page.';

                        trigger OnDrillDown()
                        begin
                            Page.Run(Page::"Service Connections");
                            CurrPage.Close();
                        end;
                    }
                }

                group(WorkflowsGroup)
                {
                    ShowCaption = false;
                    InstructionalText = 'Manage automation of business processes.';

                    field(Workflows; WorkflowsLbl)
                    {
                        ShowCaption = false;
                        ApplicationArea = All;
                        DrillDown = true;
                        Caption = 'Workflows';
                        ToolTip = 'Open the Workflow management page.';

                        trigger OnDrillDown()
                        begin
                            Page.Run(Page::Workflows);
                            CurrPage.Close();
                        end;
                    }
                }
            }
        }
    }

    var
        MediaRepositoryStandard: Record "Media Repository";
        MediaResourcesStandard: Record "Media Resources";
        TopBannerVisible: Boolean;
        ServiceConnectionsLbl: Label 'Service Connections';
        WorkflowsLbl: Label 'Workflows';

    trigger OnOpenPage()
    begin
        LoadTopBanners();
    end;

    local procedure LoadTopBanners()
    begin
        if MediaRepositoryStandard.Get('AssistedSetup-NoText-400px.png', Format(CurrentClientType)) then
            if MediaResourcesStandard.Get(MediaRepositoryStandard."Media Resources Ref") then
                TopBannerVisible := MediaResourcesStandard."Media Reference".HasValue;
    end;
}
