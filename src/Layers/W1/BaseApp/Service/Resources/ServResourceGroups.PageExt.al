// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Projects.Resources.Resource;

using Microsoft.Service.Analysis;

pageextension 6457 "Serv. Resource Groups" extends "Resource Groups"
{
    actions
    {
        addafter("Res. Group All&ocated per Job")
        {
            action("Res. Group Allocated per Service &Order")
            {
                ApplicationArea = Jobs;
                Caption = 'Res. Group Allocated per Service &Order';
                Image = ViewServiceOrder;
                RunObject = Page "Res. Gr. Alloc. per Serv Order";
                RunPageLink = "Resource Group Filter" = field("No.");
                ToolTip = 'View the service order allocations of the resource group.';
            }
        }
    }
}
