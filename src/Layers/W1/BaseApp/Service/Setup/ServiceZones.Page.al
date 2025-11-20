// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Service.Setup;

using Microsoft.Service.Resources;

page 6020 "Service Zones"
{
    ApplicationArea = Service;
    Caption = 'Service Zones';
    PageType = List;
    SourceTable = "Service Zone";
    UsageCategory = Administration;

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field("Code"; Rec.Code)
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies a code for the service zone.';
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies a description of the service zone.';
                }
            }
        }
        area(factboxes)
        {
            systempart(Control1900383207; Links)
            {
                ApplicationArea = RecordLinks;
                Visible = false;
            }
            systempart(Control1905767507; Notes)
            {
                ApplicationArea = Notes;
                Visible = false;
            }
        }
    }

    actions
    {
        area(navigation)
        {
            group("&Zone")
            {
                Caption = '&Zone';
                Image = Zones;
                action("Resource Service Zones")
                {
                    ApplicationArea = Service;
                    Caption = 'Resource Service Zones';
                    Image = Resource;
                    RunObject = Page "Resource Service Zones";
                    RunPageLink = "Service Zone Code" = field(Code);
                    RunPageView = sorting("Service Zone Code");
                    ToolTip = 'View the assignment of resources to service zones. When you allocate a resource to a service task that is to be performed at the customer site, you can select a resource that is located in the same service zone as the customer.';
                }
            }
        }
    }
}

