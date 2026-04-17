// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Manufacturing.Subcontracting;

using Microsoft.Inventory.Requisition;
using Microsoft.Manufacturing.RoleCenters;

pageextension 99001538 "Subc. Prod. Planner RoleCenter" extends "Production Planner Role Center"
{
    actions
    {
        addafter("RequisitionWorksheets")
        {
            action("Subc. Subcontracting Worksheets")
            {
                ApplicationArea = Manufacturing;
                Caption = 'Subcontracting Worksheets';
                RunObject = Page "Req. Wksh. Names";
                RunPageView = where("Template Type" = const(Subcontracting),
                                        Recurring = const(false));
                ToolTip = 'Calculate the needed production supply, find the production orders that have material ready to send to a subcontractor, and automatically create purchase orders for subcontracted operations from production order routings.';
            }
        }
        addafter("Planning Works&heet")
        {
            action("Subc. Subcontracting &Worksheet")
            {
                ApplicationArea = Manufacturing;
                Caption = 'Subcontracting &Worksheet';
                Image = SubcontractingWorksheet;
                RunObject = Page "Subc. Subcontracting Worksheet";
                ToolTip = 'Calculate the needed production supply, find the production orders that have material ready to send to a subcontractor, and automatically create purchase orders for subcontracted operations from production order routings.';
            }
        }
    }
}