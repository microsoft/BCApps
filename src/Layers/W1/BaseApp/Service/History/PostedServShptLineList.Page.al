// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Service.History;

page 5949 "Posted Serv. Shpt. Line List"
{
    Caption = 'Posted Serv. Shpt. Line List';
    Editable = false;
    PageType = List;
    SourceTable = "Service Shipment Line";

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field("Posting Date"; Rec."Posting Date")
                {
                    ApplicationArea = Service;
                }
                field("Line No."; Rec."Line No.")
                {
                    ApplicationArea = Service;
                }
                field("Service Item Line No."; Rec."Service Item Line No.")
                {
                    ApplicationArea = Service;
                }
                field("Document No."; Rec."Document No.")
                {
                    ApplicationArea = Service;
                }
                field(Type; Rec.Type)
                {
                    ApplicationArea = Service;
                }
                field("No."; Rec."No.")
                {
                    ApplicationArea = Service;
                }
                field("Service Item Serial No."; Rec."Service Item Serial No.")
                {
                    ApplicationArea = ItemTracking;
                }
                field("Location Code"; Rec."Location Code")
                {
                    ApplicationArea = Location;
                    Visible = false;
                }
                field("Order Date"; Rec."Order Date")
                {
                    ApplicationArea = Service;
                }
                field("Customer No."; Rec."Customer No.")
                {
                    ApplicationArea = Service;
                }
                field("Ship-to Code"; Rec."Ship-to Code")
                {
                    ApplicationArea = Service;
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = Service;
                }
                field("Description 2"; Rec."Description 2")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies an additional description of the item, resource, or cost.';
                    Visible = false;
                }
                field("Unit of Measure Code"; Rec."Unit of Measure Code")
                {
                    ApplicationArea = Service;
                }
                field(Quantity; Rec.Quantity)
                {
                    ApplicationArea = Service;
                }
                field("Unit Price"; Rec."Unit Price")
                {
                    ApplicationArea = Service;
                }
                field("Line Discount %"; Rec."Line Discount %")
                {
                    ApplicationArea = Service;
                }
                field("Component Line No."; Rec."Component Line No.")
                {
                    ApplicationArea = Service;
                }
                field("Replaced Item No."; Rec."Replaced Item No.")
                {
                    ApplicationArea = Service;
                }
                field("Spare Part Action"; Rec."Spare Part Action")
                {
                    ApplicationArea = Service;
                    Visible = false;
                }
                field("Fault Reason Code"; Rec."Fault Reason Code")
                {
                    ApplicationArea = Service;
                    Visible = false;
                }
                field("Exclude Warranty"; Rec."Exclude Warranty")
                {
                    ApplicationArea = Service;
                }
                field(Warranty; Rec.Warranty)
                {
                    ApplicationArea = Service;
                }
                field("Contract No."; Rec."Contract No.")
                {
                    ApplicationArea = Service;
                }
                field("Contract Disc. %"; Rec."Contract Disc. %")
                {
                    ApplicationArea = Service;
                }
                field("Warranty Disc. %"; Rec."Warranty Disc. %")
                {
                    ApplicationArea = Service;
                }
                field("Unit Cost (LCY)"; Rec."Unit Cost (LCY)")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the cost, in LCY, of one unit of the item or resource on the line.';
                }
                field("Work Type Code"; Rec."Work Type Code")
                {
                    ApplicationArea = Service;
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

    actions
    {
        area(navigation)
        {
            group("&Line")
            {
                Caption = '&Line';
                Image = Line;
                action("&Show Document")
                {
                    ApplicationArea = Service;
                    Caption = '&Show Document';
                    Image = View;
                    RunObject = Page "Posted Service Shipment";
                    RunPageLink = "No." = field("Document No.");
                    ShortCutKey = 'Shift+F7';
                    ToolTip = 'Open the document that the information on the line comes from.';
                }
            }
        }
    }
}

