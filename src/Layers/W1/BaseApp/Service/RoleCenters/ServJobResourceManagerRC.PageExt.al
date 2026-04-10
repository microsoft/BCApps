// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Service.RoleCenters;

using Microsoft.Projects.RoleCenters;
using Microsoft.Service.Resources;

pageextension 6462 "Serv. Job Resource Manager RC" extends "Job Resource Manager RC"
{
    actions
    {
        addafter("Work Types")
        {
            action("Resource Service Zones")
            {
                ApplicationArea = Jobs;
                Caption = 'Resource Service Zones';
                Image = Resource;
                RunObject = Page "Resource Service Zones";
                ToolTip = 'View the assignment of resources to service zones. When you allocate a resource to a service task that is to be performed at the customer site, you can select a resource that is located in the same service zone as the customer.';
            }
            action("Resource Locations")
            {
                ApplicationArea = Jobs;
                Caption = 'Resource Locations';
                Image = Resource;
                RunObject = Page "Resource Locations";
                ToolTip = 'View where resources are located or assign resources to locations.';
            }
        }
    }
}
