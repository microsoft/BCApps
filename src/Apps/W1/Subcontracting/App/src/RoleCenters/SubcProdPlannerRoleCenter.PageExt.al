// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Manufacturing.Subcontracting;

using Microsoft.Inventory.Requisition;
using Microsoft.Inventory.Transfer;
using Microsoft.Manufacturing.RoleCenters;
using Microsoft.Purchases.Document;

pageextension 99001538 "Subc. Prod. Planner RoleCenter" extends "Production Planner Role Center"
{
    actions
    {
        addlast(sections)
        {
            group(Subcontracting)
            {
                Caption = 'Subcontracting';
                action("Subc. Subcontracting Worksheets")
                {
                    ApplicationArea = Manufacturing;
                    Caption = 'Subcontracting Worksheets';
                    RunObject = Page "Req. Wksh. Names";
                    RunPageView = where("Template Type" = const(Subcontracting),
                                            Recurring = const(false));
                    ToolTip = 'Calculate the needed production supply, find the production orders that have material ready to send to a subcontractor, and automatically create purchase orders for subcontracted operations from production order routings.';
                }
                action("Subc. Subcontracting Purch. Orders")
                {
                    ApplicationArea = Manufacturing;
                    Caption = 'Subcontracting Purchase Orders';
                    RunObject = Page "Purchase Order List";
                    RunPageView = where("Document Type" = const(Order),
                                        "Subcontracting Order" = const(true));
                    ToolTip = 'View the list of purchase orders that are subcontracting orders.';
                }
                action("Subc. Subcontracting Transfers")
                {
                    ApplicationArea = Manufacturing;
                    Caption = 'Subcontracting Transfers';
                    RunObject = Page "Transfer Orders";
                    RunPageView = where("Source Type" = const(Subcontracting),
                                        "Return Order" = const(false));
                    ToolTip = 'View the list of outbound transfer orders to subcontractors.';
                }
            }
        }
        addafter("Planning Works&heet")
        {
            action("Subc. Subcontracting Worksheet")
            {
                ApplicationArea = Manufacturing;
                Caption = 'Subcontracting Worksheet';
                Image = SubcontractingWorksheet;
                RunObject = Page "Subc. Subcontracting Worksheet";
                ToolTip = 'Calculate the needed production supply, find the production orders that have material ready to send to a subcontractor, and automatically create purchase orders for subcontracted operations from production order routings.';
            }
        }
    }
}