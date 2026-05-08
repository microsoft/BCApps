// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Manufacturing.Subcontracting;

using Microsoft.Manufacturing.Setup;

pageextension 99001542 "Manufacturing Setup Subc." extends "Manufacturing Setup"
{
    layout
    {
        addlast(Content)
        {
            group(SubcontractingSetup)
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
                        ToolTip = 'Specifies the time to calculate the Receipt Date in Transfer Line. The calculation will be Due Date from Prod. Order Component minus the entered date formula.';
                    }
                    field("Subcontracting Template Name"; Rec."Subcontracting Template Name")
                    {
                        ApplicationArea = Manufacturing;
                        ToolTip = 'Specifies the name of the subcontracting journal template to be used for the direct creation of subcontracting orders from a released routing.';
                    }
                    field("Subcontracting Batch Name"; Rec."Subcontracting Batch Name")
                    {
                        ApplicationArea = Manufacturing;
                        ToolTip = 'Specifies the name of the subcontracting journal batch to be used for the direct creation of subcontracting orders from a released routing.';
                    }
                    field("Component Direct Unit Cost"; Rec."Component Direct Unit Cost")
                    {
                        ApplicationArea = Manufacturing;
                        ToolTip = 'Specifies which Direct Unit Cost of a Prod. Order Component is to be used in the subcontracting purchase order. Standard: Standard pricing is used when procuring the component. Prod. Order Component: The calculated Direct Unit Cost of the Prod. Order Component Line is transferred to the subcontracting purchase order.';
                    }
                    field(RefItemChargeToRcptSubLines; Rec.RefItemChargeToRcptSubLines)
                    {
                        ApplicationArea = Manufacturing;
                        ToolTip = 'Specifies whether to enable the item charge assignment to purchase receipt lines with subcontracting. When enabled, the item charge is posted as a new value entry of type "Direct Cost", when it is assigned to a purchase receipt line with referenced production order line. This created value entry is automatically assigned to a capacity entry of the prod order.';
                    }
                }
                group(SubcPurchaseProvision)
                {
                    Caption = 'Purchase Provision';
                    field("Rtng. Link Code Purch. Prov."; Rec."Rtng. Link Code Purch. Prov.")
                    {
                        ApplicationArea = Manufacturing;
                        ToolTip = 'Specifies the value of the Routing Link Code for purchase provision.';
                    }
                    field("Subc. Default Comp. Location"; Rec."Subc. Default Comp. Location")
                    {
                        ApplicationArea = Manufacturing;
                        ToolTip = 'Specifies the source used to determine the default location code for production order components in purchase provision. Purchase: the location code from the purchase order line is used. Company: the location code from the company information is used. Manufacturing: the location code from the manufacturing setup is used.';
                    }
                }
            }
        }
    }
}