// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Warehouse.Document;

using Microsoft.Warehouse.Journal;

page 7342 "Whse. Receipt Lines"
{
    Caption = 'Whse. Receipt Lines';
    Editable = false;
    PageType = List;
    SourceTable = "Warehouse Receipt Line";

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field("Source Document"; Rec."Source Document")
                {
                    ApplicationArea = Warehouse;
                    Visible = false;
                }
                field("Source No."; Rec."Source No.")
                {
                    ApplicationArea = Warehouse;
                }
                field("Source Line No."; Rec."Source Line No.")
                {
                    ApplicationArea = Warehouse;
                }
                field("Location Code"; Rec."Location Code")
                {
                    ApplicationArea = Location;
                    Visible = false;
                }
                field("Zone Code"; Rec."Zone Code")
                {
                    ApplicationArea = Warehouse;
                    Visible = false;
                }
                field("Bin Code"; Rec."Bin Code")
                {
                    ApplicationArea = Warehouse;
                    Visible = false;
                }
                field("Shelf No."; Rec."Shelf No.")
                {
                    ApplicationArea = Warehouse;
                    Visible = false;
                }
                field("Item No."; Rec."Item No.")
                {
                    ApplicationArea = Warehouse;
                }
                field("Variant Code"; Rec."Variant Code")
                {
                    ApplicationArea = Planning;
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = Warehouse;
                }
                field("Description 2"; Rec."Description 2")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies a second description of the item on the line.';
                }
                field(Quantity; Rec.Quantity)
                {
                    ApplicationArea = Warehouse;
                }
                field("Qty. (Base)"; Rec."Qty. (Base)")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies the quantity to be received, in the base unit of measure.';
                    Visible = false;
                }
                field("Qty. Outstanding"; Rec."Qty. Outstanding")
                {
                    ApplicationArea = Warehouse;
                }
                field("Qty. Outstanding (Base)"; Rec."Qty. Outstanding (Base)")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies the quantity that still needs to be handled, in the base unit of measure.';
                    Visible = false;
                }
                field("Qty. Received"; Rec."Qty. Received")
                {
                    ApplicationArea = Warehouse;
                }
                field("Qty. Received (Base)"; Rec."Qty. Received (Base)")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies the quantity received, in the base unit of measure.';
                    Visible = false;
                }
                field("Unit of Measure Code"; Rec."Unit of Measure Code")
                {
                    ApplicationArea = Warehouse;
                }
                field("Qty. per Unit of Measure"; Rec."Qty. per Unit of Measure")
                {
                    ApplicationArea = Warehouse;
                }
                field(Status; Rec.Status)
                {
                    ApplicationArea = Warehouse;
                }
                field("No."; Rec."No.")
                {
                    ApplicationArea = Warehouse;
                }
                field("Line No."; Rec."Line No.")
                {
                    ApplicationArea = Warehouse;
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
                action(ShowDocument)
                {
                    ApplicationArea = Warehouse;
                    Caption = 'Show Document';
                    Image = ViewOrder;
                    ShortCutKey = 'Return';
                    ToolTip = 'View the related warehouse document.';

                    trigger OnAction()
                    var
                        WhseRcptHeader: Record "Warehouse Receipt Header";
                        WMSManagement: Codeunit "WMS Management";
                    begin
                        WhseRcptHeader.Get(Rec."No.");
                        WMSManagement.CheckUserIsWhseEmployeeForLocation(WhseRcptHeader."Location Code", false);
                        PAGE.Run(PAGE::"Warehouse Receipt", WhseRcptHeader);
                    end;
                }
                action("&Show Source Document Line")
                {
                    ApplicationArea = Warehouse;
                    Caption = '&Show Source Document Line';
                    Image = ViewDocumentLine;
                    ToolTip = 'View the source document line that the receipts is related to. ';

                    trigger OnAction()
                    var
                        WMSMgt: Codeunit "WMS Management";
                    begin
                        WMSMgt.ShowSourceDocLine(
                          Rec."Source Type", Rec."Source Subtype", Rec."Source No.", Rec."Source Line No.", 0)
                    end;
                }
            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                Caption = 'Process', Comment = 'Generated from the PromotedActionCategories property index 1.';

                actionref("Show &Whse. Document_Promoted"; ShowDocument)
                {
                }
            }
        }
    }
}

