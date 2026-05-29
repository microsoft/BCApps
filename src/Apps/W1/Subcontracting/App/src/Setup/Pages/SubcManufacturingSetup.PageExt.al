// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Manufacturing.Subcontracting;

using Microsoft.Manufacturing.Setup;

pageextension 99001542 "Subc. Manufacturing Setup" extends "Manufacturing Setup"
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
                    field("Subc. Comp. Transfer Lead Time"; Rec."Subc. Comp. Transfer Lead Time")
                    {
                        ApplicationArea = Manufacturing;
                        ToolTip = 'Specifies the lead time for transferring components to the subcontractor. This time is subtracted from the production component due date to calculate the transfer order receipt date.';
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
                }
                group(SubcPurchaseProvision)
                {
                    Caption = 'Purchase Provision';
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