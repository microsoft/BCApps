// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Projects.Project.Archive;

using System.Security.User;

page 5182 "Job Planning Archive Lines"
{
    AutoSplitKey = true;
    Caption = 'Project Planning Archive Lines';
    DataCaptionExpression = Caption();
    PageType = List;
    Editable = false;
    SourceTable = "Job Planning Line Archive";

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field("Job No."; Rec."Job No.")
                {
                    ApplicationArea = All;
                    Visible = false;
                }
                field("Job Task No."; Rec."Job Task No.")
                {
                    ApplicationArea = All;
                    Visible = false;
                }
                field("Line Type"; Rec."Line Type")
                {
                    ApplicationArea = Jobs;
                }
                field("Usage Link"; Rec."Usage Link")
                {
                    ApplicationArea = Jobs;
                    Visible = false;
                }
                field("Planning Date"; Rec."Planning Date")
                {
                    ApplicationArea = Jobs;
                }
                field("Planned Delivery Date"; Rec."Planned Delivery Date")
                {
                    ApplicationArea = Jobs;
                }
                field("Currency Date"; Rec."Currency Date")
                {
                    ApplicationArea = Jobs;
                    Visible = false;
                }
                field("Document No."; Rec."Document No.")
                {
                    ApplicationArea = Jobs;
                }
                field("Line No."; Rec."Line No.")
                {
                    ApplicationArea = Jobs;
                    Visible = false;
                }
                field(Type; Rec.Type)
                {
                    ApplicationArea = Jobs;
                }
                field("No."; Rec."No.")
                {
                    ApplicationArea = Jobs;
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = Jobs;
                }
                field("Description 2"; Rec."Description 2")
                {
                    ApplicationArea = Jobs;
                    Visible = false;
                }
                field("Price Calculation Method"; Rec."Price Calculation Method")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Cost Calculation Method"; Rec."Cost Calculation Method")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Gen. Bus. Posting Group"; Rec."Gen. Bus. Posting Group")
                {
                    ApplicationArea = Jobs;
                    Visible = false;
                }
                field("Gen. Prod. Posting Group"; Rec."Gen. Prod. Posting Group")
                {
                    ApplicationArea = Jobs;
                    Visible = false;
                }
                field("Variant Code"; Rec."Variant Code")
                {
                    ApplicationArea = Planning;
                    Visible = false;
                }
                field("Location Code"; Rec."Location Code")
                {
                    ApplicationArea = Location;
                    Visible = false;
                }
                field("Bin Code"; Rec."Bin Code")
                {
                    ApplicationArea = Warehouse;
                    Visible = false;
                }
                field("Work Type Code"; Rec."Work Type Code")
                {
                    ApplicationArea = Jobs;
                    Visible = false;
                }
                field("Unit of Measure Code"; Rec."Unit of Measure Code")
                {
                    ApplicationArea = Jobs;
                    Visible = false;
                }
                field(ReserveName; Rec.Reserve)
                {
                    ApplicationArea = Reservation;
                    Visible = false;
                }
                field(Quantity; Rec.Quantity)
                {
                    ApplicationArea = Jobs;
                }
                field("Reserved Quantity"; Rec."Reserved Quantity")
                {
                    ApplicationArea = Reservation;
                    Visible = false;
                }
                field("Quantity (Base)"; Rec."Quantity (Base)")
                {
                    ApplicationArea = Jobs;
                    ToolTip = 'Specifies the quantity expressed in the base units of measure.';
                    Visible = false;
                }
                field("Remaining Qty."; Rec."Remaining Qty.")
                {
                    ApplicationArea = Jobs;
                    Visible = false;
                }
                field("Direct Unit Cost (LCY)"; Rec."Direct Unit Cost (LCY)")
                {
                    ApplicationArea = Jobs;
                    Editable = false;
                    ToolTip = 'Specifies the cost, in the local currency, of one unit of the selected item or resource.';
                    Visible = false;
                }
                field("Unit Cost"; Rec."Unit Cost")
                {
                    ApplicationArea = Jobs;
                }
                field("Unit Cost (LCY)"; Rec."Unit Cost (LCY)")
                {
                    ApplicationArea = Jobs;
                    ToolTip = 'Specifies the cost, in LCY, of one unit of the item or resource on the line.';
                    Visible = false;
                }
                field("Total Cost"; Rec."Total Cost")
                {
                    ApplicationArea = Jobs;
                }
                field("Remaining Total Cost"; Rec."Remaining Total Cost")
                {
                    ApplicationArea = Jobs;
                    Visible = false;
                }
                field("Total Cost (LCY)"; Rec."Total Cost (LCY)")
                {
                    ApplicationArea = Jobs;
                    ToolTip = 'Specifies the total cost for the planning line. The amount is in the local currency.';
                    Visible = false;
                }
                field("Remaining Total Cost (LCY)"; Rec."Remaining Total Cost (LCY)")
                {
                    ApplicationArea = Jobs;
                    ToolTip = 'Specifies the remaining total cost (LCY) for the planning line. The amount is in the local currency.';
                    Visible = false;
                }
                field("Unit Price"; Rec."Unit Price")
                {
                    ApplicationArea = Jobs;
                }
                field("Unit Price (LCY)"; Rec."Unit Price (LCY)")
                {
                    ApplicationArea = Jobs;
                    ToolTip = 'Specifies the price, in LCY, of one unit of the item or resource. You can enter a price manually or have it entered according to the Price/Profit Calculation field on the related card.';
                    Visible = false;
                }
                field("Line Amount"; Rec."Line Amount")
                {
                    ApplicationArea = Jobs;
                }
                field("Remaining Line Amount"; Rec."Remaining Line Amount")
                {
                    ApplicationArea = Jobs;
                    Visible = false;
                }
                field("Line Amount (LCY)"; Rec."Line Amount (LCY)")
                {
                    ApplicationArea = Jobs;
                    ToolTip = 'Specifies the amount in the local currency that will be posted to the project ledger.';
                    Visible = false;
                }
                field("Remaining Line Amount (LCY)"; Rec."Remaining Line Amount (LCY)")
                {
                    ApplicationArea = Jobs;
                    ToolTip = 'Specifies the amount in the local currency that will be posted to the project ledger.';
                    Visible = false;
                }
                field("Line Discount Amount"; Rec."Line Discount Amount")
                {
                    ApplicationArea = Jobs;
                    Visible = false;
                }
                field("Line Discount %"; Rec."Line Discount %")
                {
                    ApplicationArea = Jobs;
                    Visible = false;
                }
                field("Total Price"; Rec."Total Price")
                {
                    ApplicationArea = Jobs;
                    Visible = false;
                }
                field("Total Price (LCY)"; Rec."Total Price (LCY)")
                {
                    ApplicationArea = Jobs;
                    ToolTip = 'Specifies the total price on the planning line. The total price is in the local currency.';
                    Visible = false;
                }
                field("Qty. Posted"; Rec."Qty. Posted")
                {
                    ApplicationArea = Jobs;
                    Visible = false;
                }
                field("Qty. to Transfer to Journal"; Rec."Qty. to Transfer to Journal")
                {
                    ApplicationArea = Jobs;
                }
                field("Posted Total Cost"; Rec."Posted Total Cost")
                {
                    ApplicationArea = Jobs;
                    Visible = false;
                }
                field("Posted Total Cost (LCY)"; Rec."Posted Total Cost (LCY)")
                {
                    ApplicationArea = Jobs;
                    ToolTip = 'Specifies the total cost (LCY) that has been posted to the project ledger, if the Usage Link check box has been selected.';
                    Visible = false;
                }
                field("Posted Line Amount"; Rec."Posted Line Amount")
                {
                    ApplicationArea = Jobs;
                    Visible = false;
                }
                field("Posted Line Amount (LCY)"; Rec."Posted Line Amount (LCY)")
                {
                    ApplicationArea = Jobs;
                    ToolTip = 'Specifies the amount in the local currency that has been posted to the project ledger. This field is only filled in if the Apply Usage Link check box selected on the project card.';
                    Visible = false;
                }
                field("Qty. to Transfer to Invoice"; Rec."Qty. to Transfer to Invoice")
                {
                    ApplicationArea = Jobs;
                    Visible = false;
                }
                field("Qty. to Invoice"; Rec."Qty. to Invoice")
                {
                    ApplicationArea = Jobs;
                    Visible = false;
                }
                field("User ID"; Rec."User ID")
                {
                    ApplicationArea = Jobs;
                    Visible = false;

                    trigger OnDrillDown()
                    var
                        UserMgt: Codeunit "User Management";
                    begin
                        UserMgt.DisplayUserInformation(Rec."User ID");
                    end;
                }
                field("Serial No."; Rec."Serial No.")
                {
                    ApplicationArea = ItemTracking;
                    Visible = false;
                }
                field("Lot No."; Rec."Lot No.")
                {
                    ApplicationArea = ItemTracking;
                    Visible = false;
                }
                field("Job Contract Entry No."; Rec."Job Contract Entry No.")
                {
                    ApplicationArea = Jobs;
                    Visible = false;
                }
                field("Ledger Entry Type"; Rec."Ledger Entry Type")
                {
                    ApplicationArea = Jobs;
                    Visible = false;
                }
                field("Ledger Entry No."; Rec."Ledger Entry No.")
                {
                    ApplicationArea = Jobs;
                    Visible = false;
                }
                field("System-Created Entry"; Rec."System-Created Entry")
                {
                    ApplicationArea = Jobs;
                    Visible = false;
                }
                field("Qty. Picked"; Rec."Qty. Picked")
                {
                    ApplicationArea = Warehouse;
                    Visible = false;
                }
                field("Qty. Picked (Base)"; Rec."Qty. Picked (Base)")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies the base quantity of the item you have picked for the project planning line.';
                    Visible = false;
                }
                field("Contract Line"; Rec."Contract Line")
                {
                    ApplicationArea = Warehouse;
                    Visible = false;
                }
            }
        }
        area(factboxes)
        {
            systempart(Control1900383207; Links)
            {
                ApplicationArea = RecordLinks;
                Visible = false;
            }
            systempart(Control1905767507; Notes)
            {
                ApplicationArea = Notes;
                Visible = false;
            }
        }
    }
}

