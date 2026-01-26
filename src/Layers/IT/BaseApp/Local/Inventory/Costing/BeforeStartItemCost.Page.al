// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Costing;

page 12117 "Before Start Item Cost"
{
    ApplicationArea = Basic, Suite;
    Caption = 'Before Start Item Cost';
    DelayedInsert = true;
    PageType = List;
    SourceTable = "Before Start Item Cost";
    UsageCategory = Lists;

    layout
    {
        area(content)
        {
            repeater(Control1130000)
            {
                ShowCaption = false;
                field("Item No."; Rec."Item No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the item number that is assigned to the item in inventory.';
                }
                field("Starting Date"; Rec."Starting Date")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the start date of the item costs before you began using Microsoft Dynamics NAV in your organization.';
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the description of the item that was entered in the Item Card window.';
                }
                field("Base Unit of Measure"; Rec."Base Unit of Measure")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the standard unit of measure that was used to track the item in inventory before you began using Microsoft Dynamics NAV.';
                }
                field("Purchase Quantity"; Rec."Purchase Quantity")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the quantity of the item that was purchased before you began using Microsoft Dynamics NAV in your organization.';
                }
                field("Purchase Amount"; Rec."Purchase Amount")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the monetary valuation of the items purchased before you began using Microsoft Dynamics NAV in your organization.';
                }
                field("Production Quantity"; Rec."Production Quantity")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the quantity of an item that was in production before you began using Microsoft Dynamics NAV in your organization.';
                }
                field("Production Amount"; Rec."Production Amount")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the monetary valuation of an item that was in production before you began using Microsoft Dynamics NAV in your organization.';
                }
                field("Direct Components Amount"; Rec."Direct Components Amount")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the direct cost of the item, based on the component costs before you began using Microsoft Dynamics NAV.';
                }
                field("Direct Routing Amount"; Rec."Direct Routing Amount")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the direct cost associated with the routing of an item before you began using Microsoft Dynamics NAV in your organization.';
                }
                field("Overhead Routing Amount"; Rec."Overhead Routing Amount")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the overhead cost associated with the routing of an item before you began using Microsoft Dynamics NAV in your organization.';
                }
                field("Subcontracted Amount"; Rec."Subcontracted Amount")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the item costs associated with outsourcing operations to a subcontractor before you began using Microsoft Dynamics NAV.';
                }
            }
        }
    }

    actions
    {
    }
}

