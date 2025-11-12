// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Projects.Resources.Resource;

using Microsoft.Service.Analysis;
using Microsoft.Service.Resources;

pageextension 6455 "Serv. Resource Card" extends "Resource Card"
{
    actions
    {
        addafter("Units of Measure")
        {
            action("S&kills")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'S&kills';
                Image = Skills;
                RunObject = Page "Resource Skills";
                RunPageLink = Type = const(Resource),
                                "No." = field("No.");
                ToolTip = 'View the assignment of skills to the resource. You can use skill codes to allocate skilled resources to service items or items that need special skills for servicing.';
            }
            action("Resource L&ocations")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Resource L&ocations';
                Image = Resource;
                RunObject = Page "Resource Locations";
                RunPageLink = "Resource No." = field("No.");
                RunPageView = sorting("Resource No.");
                ToolTip = 'View where resources are located or assign resources to locations.';
            }
        }
        addafter("Resource &Allocated per Job")
        {
            action("Resource Allocated per Service &Order")
            {
                ApplicationArea = Service;
                Caption = 'Resource Allocated per Service &Order';
                Image = ViewServiceOrder;
                RunObject = Page "Res. Alloc. per Service Order";
                RunPageLink = "Resource Filter" = field("No.");
                ToolTip = 'View the service order allocations of the resource.';
            }
        }
        addafter("Plan&ning")
        {
            group(Service)
            {
                Caption = 'Service';
                Image = ServiceZone;
                action("Service &Zones")
                {
                    ApplicationArea = Service;
                    Caption = 'Service &Zones';
                    Image = ServiceZone;
                    RunObject = Page "Resource Service Zones";
                    RunPageLink = "Resource No." = field("No.");
                    ToolTip = 'View the different service zones that you can assign to customers and resources. When you allocate a resource to a service task that is to be performed at the customer site, you can select a resource that is located in the same service zone as the customer.';
                }
            }
        }
        addafter("Units of Measure_Promoted")
        {
            actionref("S&kills_Promoted"; "S&kills")
            {
            }
            actionref("Resource L&ocations_Promoted"; "Resource L&ocations")
            {
            }
        }
    }
}
