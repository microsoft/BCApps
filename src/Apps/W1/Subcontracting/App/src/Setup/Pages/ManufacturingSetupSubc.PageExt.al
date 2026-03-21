// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Manufacturing.Subcontracting;

using Microsoft.Manufacturing.Setup;

pageextension 99001540 "Manufacturing Setup Subc." extends "Manufacturing Setup"
{
    layout
    {
        addlast(Content)
        {
            group(Subcontracting)
            {
                Caption = 'Subcontracting';

                group(SubcGeneral)
                {
                    Caption = 'General';
                    field("Create Prod. Order Info Line"; Rec."Create Prod. Order Info Line")
                    {
                        ApplicationArea = Manufacturing;
                        ToolTip = 'Specifies whether an additional Information Line of the Production Order Line will be created in a Subcontracting Purchase Order.';
                    }
                    field("Subc. Inb. Whse. Handling Time"; Rec."Subc. Inb. Whse. Handling Time")
                    {
                        ApplicationArea = Manufacturing;
                        ToolTip = 'Specifies the time to calculate the Receipt Date in Transfer Line. The Calculation will be Due Date from Prod. Order Component minus the entered date formula.';
                    }
                }
                group(SubcSubcontracting)
                {
                    Caption = 'Subcontracting';
                    field("Subcontracting Template Name"; Rec."Subcontracting Template Name")
                    {
                        ApplicationArea = Manufacturing;
                        ToolTip = 'Specifies the name of the subcontracting journal template to be used for the direct creation of subcontracting orders from an released routing.';
                    }
                    field("Subcontracting Batch Name"; Rec."Subcontracting Batch Name")
                    {
                        ApplicationArea = Manufacturing;
                        ToolTip = 'Specifies the name of the subcontracting journal batch to be used for the direct creation of subcontracting orders from an released routing.';
                    }
                    field("Component Direct Unit Cost"; Rec."Component Direct Unit Cost")
                    {
                        ApplicationArea = Manufacturing;
                        ToolTip = 'Specifies which Direct Unit Cost of an Prod. Order Component is to be used in the subcontracting purchase order. Standard: Standard pricing is used when procuring the component. Prod. Order Component: The calculated Direct Unit Cost of the Prod. Order Component Line is transferred to the subcontracting purchase order.';
                    }
                    field(RefItemChargeToRcptSubLines; Rec.RefItemChargeToRcptSubLines)
                    {
                        ApplicationArea = Manufacturing;
                        ToolTip = 'Specifies whether to enable the item charge assignment to purchase receipt lines with subcontracting. When enabled, the item charge is posted as new a value entry of type "Direct Cost", when it is assigned to a purchase receipt line with referenced production order line. This created value entry is automatically assigned to a capacity entry of the prod order.';
                    }
                }
                group(SubcProvision)
                {
                    Caption = 'Purchase Provision';
                    field("Rtng. Link Code Purch. Prov."; Rec."Rtng. Link Code Purch. Prov.")
                    {
                        ApplicationArea = Manufacturing;
                        ToolTip = 'Specifies the value of the Routing Link Code for purchase provision.';
                    }
                    field("Direct Transfer"; Rec."Direct Transfer")
                    {
                        ApplicationArea = Manufacturing;
                        ToolTip = 'Specifies that the transfer for subcontracting components does not use an in-transit location. When you transfer directly, the Qty. to Receive field will be locked with the same value as the quantity to ship.';
                    }
                    field("Subc. Comp. at Location"; Rec."Subc. Comp. at Location")
                    {
                        ApplicationArea = Manufacturing;
                        ToolTip = 'Specifies which location code is to be used as the transfer-from location when creating a transfer order of external production components (provision).';
                    }
                }
            }
        }
    }
}