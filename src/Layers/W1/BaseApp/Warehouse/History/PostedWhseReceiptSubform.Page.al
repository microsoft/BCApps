// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Warehouse.History;

using Microsoft.Warehouse.Journal;
using Microsoft.Warehouse.Structure;

page 7331 "Posted Whse. Receipt Subform"
{
    AutoSplitKey = true;
    Caption = 'Lines';
    DelayedInsert = true;
    Editable = false;
    LinksAllowed = false;
    MultipleNewLines = true;
    PageType = ListPart;
    SourceTable = "Posted Whse. Receipt Line";

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
                    ToolTip = 'Specifies the type of document that the line relates to.';
                }
                field("Source No."; Rec."Source No.")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies the number of the source document that the entry originates from.';
                }
                field("Due Date"; Rec."Due Date")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies the date that the receipt line was due.';
                }
                field("Shelf No."; Rec."Shelf No.")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies the shelf number of the item for informational use.';
                    Visible = false;
                }
                field("Zone Code"; Rec."Zone Code")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies the code of the zone on this posted receipt line.';
                    Visible = false;
                }
                field("Bin Code"; Rec."Bin Code")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies the bin where the items are picked or put away.';
                    Visible = false;
                }
                field("Cross-Dock Zone Code"; Rec."Cross-Dock Zone Code")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies the zone code used to create the cross-dock put-away for this line when the receipt was posted.';
                    Visible = false;
                }
                field("Cross-Dock Bin Code"; Rec."Cross-Dock Bin Code")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies the bin code used to create the cross-dock put-away for this line when the receipt was posted.';
                    Visible = false;
                }
                field("Item No."; Rec."Item No.")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies the number of the item that was received and posted.';
                }
                field("Variant Code"; Rec."Variant Code")
                {
                    ApplicationArea = Planning;
                    ToolTip = 'Specifies the variant of the item on the line.';
                    Visible = false;
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies the description of the item in the line.';
                }
                field("Description 2"; Rec."Description 2")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies a second description of the item in the line, if any.';
                    Visible = false;
                }
                field(Quantity; Rec.Quantity)
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies the quantity that was received.';
                }
                field("Qty. (Base)"; Rec."Qty. (Base)")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies the quantity that was received, in the base unit of measure.';
                    Visible = false;
                }
                field("Qty. Put Away"; Rec."Qty. Put Away")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies the quantity that is put away.';
                    Visible = false;
                }
                field("Qty. Cross-Docked"; Rec."Qty. Cross-Docked")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies the quantity of items that was in the Qty. To Cross-Dock field on the warehouse receipt line when it was posted.';
                    Visible = false;
                }
                field("Qty. Put Away (Base)"; Rec."Qty. Put Away (Base)")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies the quantity that is put away, in the base unit of measure.';
                    Visible = false;
                }
                field("Qty. Cross-Docked (Base)"; Rec."Qty. Cross-Docked (Base)")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies the base quantity of items in the Qty. To Cross-Dock (Base) field on the warehouse receipt line when it was posted.';
                    Visible = false;
                }
                field("Put-away Qty."; Rec."Put-away Qty.")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies the quantity on put-away instructions in the process of being put away.';
                    Visible = false;
                }
                field("Put-away Qty. (Base)"; Rec."Put-away Qty. (Base)")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies the quantity on put-away instructions, in the base unit of measure, in the process of being put away.';
                    Visible = false;
                }
                field("Unit of Measure Code"; Rec."Unit of Measure Code")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies how each unit of the item or resource is measured, such as in pieces or hours. By default, the value in the Base Unit of Measure field on the item or resource card is inserted.';
                }
            }
        }
    }

    actions
    {
        area(processing)
        {
            group("&Line")
            {
                Caption = '&Line';
                Image = Line;
                action("Posted Source Document")
                {
                    ApplicationArea = Warehouse;
                    Caption = 'Posted Source Document';
                    Image = PostedOrder;
                    ToolTip = 'Open the list of posted source documents.';

                    trigger OnAction()
                    begin
                        ShowPostedSourceDoc();
                    end;
                }
                action("Whse. Document Line")
                {
                    ApplicationArea = Warehouse;
                    Caption = 'Whse. Document Line';
                    Image = Line;
                    ToolTip = 'View the line on another warehouse document that the warehouse activity is for.';

                    trigger OnAction()
                    begin
                        ShowWhseLine();
                    end;
                }
                action("Bin Contents List")
                {
                    ApplicationArea = Warehouse;
                    Caption = 'Bin Contents List';
                    Image = BinContent;
                    ToolTip = 'View the contents of the selected bin and the parameters that define how items are routed through the bin.';

                    trigger OnAction()
                    begin
                        ShowBinContents();
                    end;
                }
            }
        }
    }

    var
        WMSMgt: Codeunit "WMS Management";

    local procedure ShowPostedSourceDoc()
    begin
        WMSMgt.ShowPostedSourceDocument(Rec."Posted Source Document", Rec."Posted Source No.", Rec."Source Document");
    end;

    local procedure ShowBinContents()
    var
        BinContent: Record "Bin Content";
    begin
        BinContent.ShowBinContents(Rec."Location Code", Rec."Item No.", Rec."Variant Code", Rec."Bin Code");
    end;

    local procedure ShowWhseLine()
    begin
        WMSMgt.ShowPostedWhseRcptLine(Rec."Whse. Receipt No.", Rec."Whse Receipt Line No.");
    end;

    procedure PutAwayCreate()
    var
        PostedWhseRcptHdr: Record "Posted Whse. Receipt Header";
        PostedWhseRcptLine: Record "Posted Whse. Receipt Line";
    begin
        PostedWhseRcptHdr.Get(Rec."No.");
        PostedWhseRcptLine.Copy(Rec);
        Rec.CreatePutAwayDoc(PostedWhseRcptLine, PostedWhseRcptHdr."Assigned User ID");
    end;
}

