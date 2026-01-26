// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Costing;

page 12130 "Lifo Band List"
{
    ApplicationArea = Basic, Suite;
    Caption = 'LIFO Band';
    Editable = false;
    PageType = List;
    SourceTable = "Lifo Band";
    UsageCategory = Lists;

    layout
    {
        area(content)
        {
            repeater(Control1130001)
            {
                ShowCaption = false;
                field("Entry No."; Rec."Entry No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the entry number that is assigned to the LIFO band entry.';
                    Visible = false;
                }
                field("Item No."; Rec."Item No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the item number that is assigned to the item in inventory.';
                }
                field("Lifo Category"; Rec."Lifo Category")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the code for the Last In, First Out (LIFO) category that is assigned to each item.';
                }
                field("Competence Year"; Rec."Competence Year")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the date that is used to determine the LIFO valuation period.';
                }
                field("Increment Quantity"; Rec."Increment Quantity")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the increase or decrease in quantity of an item after inventory valuation.';
                }
                field("Absorbed Quantity"; Rec."Absorbed Quantity")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the quantity of items, that are applied to the previous year''s outstanding increment quantity, during the year-end inventory valuation process.';
                }
                field("Residual Quantity"; Rec."Residual Quantity")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the quantity of items left in inventory after year-end adjustments have been applied.';
                }
                field("Year Average Cost"; Rec."Year Average Cost")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the average cost of the item during the year.';
                }
                field(CMP; Rec.CMP)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the current market price (CMP) of the inventory item.';
                }
                field(Definitive; Rec.Definitive)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the status of the year-end inventory cost associated with this entry.';
                }
                field("Increment Value"; Rec."Increment Value")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the value of items left in inventory after year-end adjustments have been applied.';
                }
                field("Qty not Invoiced"; Rec."Qty not Invoiced")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the quantity of the item that has not yet been invoiced.';
                }
                field("Amount not Invoiced"; Rec."Amount not Invoiced")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the amount of the item that has not yet been invoiced.';
                }
                field(Positive; Rec.Positive)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies if the increment quantity is a positive adjustment to inventory.';
                }
                field("Closed by Entry No."; Rec."Closed by Entry No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the entry number that was applied to close the entry.';
                }
                field("Invoiced Quantity"; Rec."Invoiced Quantity")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the quantity of the item that has been invoiced.';
                }
                field("Invoiced Amount"; Rec."Invoiced Amount")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the amount of the item that has been invoiced.';
                }
            }
        }
    }

    actions
    {
    }
}

