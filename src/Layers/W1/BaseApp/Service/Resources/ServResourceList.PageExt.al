// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Projects.Resources.Resource;

using Microsoft.Service.Analysis;

pageextension 6456 "Serv. Resource List" extends "Resource List"
{
    actions
    {
        addafter("Resource &Capacity")
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
    }
}
