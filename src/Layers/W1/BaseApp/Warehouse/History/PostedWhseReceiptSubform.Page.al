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
                }
                field("Source No."; Rec."Source No.")
                {
                    ApplicationArea = Warehouse;
                }
                field("Due Date"; Rec."Due Date")
                {
                    ApplicationArea = Warehouse;
                }
                field("Shelf No."; Rec."Shelf No.")
                {
                    ApplicationArea = Warehouse;
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
                field("Cross-Dock Zone Code"; Rec."Cross-Dock Zone Code")
                {
                    ApplicationArea = Warehouse;
                    Visible = false;
                }
                field("Cross-Dock Bin Code"; Rec."Cross-Dock Bin Code")
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
                    Visible = false;
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = Warehouse;
                }
                field("Description 2"; Rec."Description 2")
                {
                    ApplicationArea = Warehouse;
                    Visible = false;
                }
                field(Quantity; Rec.Quantity)
                {
                    ApplicationArea = Warehouse;
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
                    Visible = false;
                }
                field("Qty. Cross-Docked"; Rec."Qty. Cross-Docked")
                {
                    ApplicationArea = Warehouse;
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

