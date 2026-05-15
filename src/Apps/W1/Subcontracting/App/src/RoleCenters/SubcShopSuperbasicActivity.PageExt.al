// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Manufacturing.Subcontracting;

using Microsoft.Inventory.Transfer;
using Microsoft.Manufacturing.RoleCenters;
using Microsoft.Purchases.Document;

pageextension 99001546 "Subc. ShopSuperbasicActivity" extends "Shop Super. basic Activities"
{
    layout
    {
        addlast(content)
        {
            cuegroup(SubcontractingCuegroup)
            {
                Caption = 'Subcontracting';
                field("Subcontracting Purchase Orders"; Rec."Subcontracting Purchase Orders")
                {
                    ApplicationArea = Manufacturing;
                    DrillDownPageId = "Purchase Order List";
                    ToolTip = 'Specifies the number of open purchase orders that are subcontracting orders.';
                }
                field("Subc. Purch. Lines Outstd."; Rec."Subc. Purch. Lines Outstd.")
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Specifies the number of outstanding subcontracting purchase order lines that have not yet been fully received.';
                    Visible = false;
                }
                field("Subc. Purch. Lines Total"; Rec."Subc. Purch. Lines Total")
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Specifies the total number of subcontracting purchase order lines.';
                    Visible = false;
                }
                field("Transfers to Subcontractor"; Rec."Transfers to Subcontractor")
                {
                    ApplicationArea = Manufacturing;
                    DrillDownPageId = "Transfer Orders";
                    ToolTip = 'Specifies the number of transfer orders to subcontractors.';
                }
                field("Returns from Subcontractor"; Rec."Returns from Subcontractor")
                {
                    ApplicationArea = Manufacturing;
                    DrillDownPageId = "Transfer Orders";
                    ToolTip = 'Specifies the number of transfer orders that are returns from subcontractors.';
                }
            }
            cuegroup(SubcontractingActionsCuegroup)
            {
                Caption = 'Subcontracting - Operations';

                actions
                {
                    action("Subc. Edit Subcontracting Worksheet")
                    {
                        ApplicationArea = Manufacturing;
                        Caption = 'Edit Subcontracting Worksheet';
                        RunObject = Page "Subc. Subcontracting Worksheet";
                        ToolTip = 'Plan outsourcing of operation on released production orders.';
                    }
                }
            }
        }
    }
}
