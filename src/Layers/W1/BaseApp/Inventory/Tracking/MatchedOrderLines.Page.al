// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Tracking;

page 5818 "Matched Order Lines"
{
    ApplicationArea = Suite;
    Caption = 'Matched Order Lines';
    LinksAllowed = false;
    PageType = List;
    RefreshOnActivate = true;
    SourceTable = "Detailed Matched Order Line";
    SourceTableTemporary = true;

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                IndentationColumn = Rec.Indentation;
                IndentationControls = Line;
                ShowAsTree = true;
                ShowCaption = false;

                field(Line; Rec.Line)
                {
                    Caption = 'Line';
                    StyleExpr = LevelStyleExpr;
                    ToolTip = 'Specifies the document type, number, and line number of the matched order or receipt/shipment line.';
                }
                field("Line No."; Rec."Line No.")
                {
                    Caption = 'Line No.';
                    HideValue = (not ShowFromHeader) and not (Rec.Indentation = 0);
                    StyleExpr = LevelStyleExpr;
                }
                field(Type; Rec.Type)
                {
                    Caption = 'Type';
                    HideValue = StatusHideValue;
                    StyleExpr = LevelStyleExpr;
                }
                field("No."; Rec."No.")
                {
                    Caption = 'No.';
                    Style = Strong;
                    StyleExpr = LevelStyleExpr;
                }
                field(Description; Rec.Description)
                {
                    Caption = 'Description';
                    Style = Strong;
                    StyleExpr = LevelStyleExpr;
                }
                field("Description 2"; Rec."Description 2")
                {
                    Caption = 'Description 2';
                    Style = Strong;
                    StyleExpr = LevelStyleExpr;
                    Visible = false;
                }
                field(Quantity; Rec.Quantity)
                {
                    Caption = 'Quantity';
                    StyleExpr = LevelStyleExpr;
                    Visible = SourceIsOpenDocument;
                }
                field("Qty. Rcd. Not Invoiced"; Rec."Qty. Rcd. Not Invoiced")
                {
                    Caption = 'Qty. Rcd. Not Invoiced';
                    HideValue = not StatusHideValue;
                    StyleExpr = LevelStyleExpr;
                    Visible = SourceIsOpenDocument;
                }
                field("Qty. to Invoice"; Rec."Qty. to Invoice")
                {
                    Caption = 'Qty. to Invoice';
                    StyleExpr = LevelStyleExpr;
                    Editable = QtyToInvoiceEditable;
                    Visible = SourceIsOpenDocument;

                    trigger OnValidate()
                    begin
                        MatchedOrderLineMgmt.ValidateQtyToInvoice(MatchedOrderLineSource, Rec, xRec);
                        CurrPage.Update(false);
                    end;
                }
                field("Qty. to Invoice (Base)"; Rec."Qty. to Invoice (Base)")
                {
                    Caption = 'Qty. to Invoice (Base)';
                    StyleExpr = LevelStyleExpr;
                    Visible = false;
                }
                field("Qty. Invoiced"; Rec."Qty. Invoiced")
                {
                    Caption = 'Qty. Invoiced';
                    StyleExpr = LevelStyleExpr;
                    Visible = not SourceIsOpenDocument;
                }
                field("Qty. Invoiced (Base)"; Rec."Qty. Invoiced (Base)")
                {
                    Caption = 'Qty. Invoiced (Base)';
                    StyleExpr = LevelStyleExpr;
                    Visible = false;
                }
                field("Order No."; Rec."Order No.")
                {
                    Caption = 'Order No.';
                    HideValue = not StatusHideValue;
                    StyleExpr = LevelStyleExpr;
                }
                field("Order Line No."; Rec."Order Line No.")
                {
                    Caption = 'Order Line No.';
                    HideValue = not StatusHideValue;
                    StyleExpr = LevelStyleExpr;
                }
                field("Receipt on Invoice"; Rec."Receipt on Invoice")
                {
                    Caption = 'Receipt on Invoice';
                    HideValue = not StatusHideValue;
                    StyleExpr = LevelStyleExpr;
                    Visible = (MatchedOrderLineSource = "Matched Order Line Source"::"Purchase Invoice") or (MatchedOrderLineSource = "Matched Order Line Source"::"Posted Purchase Invoice");
                }
                field("Receipt/Shipment No."; Rec."Receipt/Shipment No.")
                {
                    Caption = 'Receipt/Shipment No.';
                    HideValue = not StatusHideValue;
                }
                field("Receipt/Shipment Line No."; Rec."Receipt/Shipment Line No.")
                {
                    Caption = 'Receipt/Shipment Line No.';
                    HideValue = not StatusHideValue;
                }
                field("Your Reference"; Rec."Your Reference")
                {
                    Caption = 'Your Reference';
                    StyleExpr = LevelStyleExpr;
                    Visible = SourceIsOpenDocument;
                }
                field("Vendor Order No."; Rec."Vendor Order No.")
                {
                    Caption = 'Vendor Order No.';
                    StyleExpr = LevelStyleExpr;
                    Visible = SourceIsOpenDocument;
                }
                field("Vendor Shipment No."; Rec."Vendor Shipment No.")
                {
                    Caption = 'Vendor Shipment No.';
                    StyleExpr = LevelStyleExpr;
                    Visible = SourceIsOpenDocument;
                }
                field("Vendor Invoice No."; Rec."Vendor Invoice No.")
                {
                    Caption = 'Vendor Invoice No.';
                    StyleExpr = LevelStyleExpr;
                    Visible = SourceIsOpenDocument;
                }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(ShowDocument)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Show Document';
                Image = View;
                ToolTip = 'View the document that this line is matched to.';

                trigger OnAction()
                begin
                    MatchedOrderLineMgmt.ShowDocument(MatchedOrderLineSource, Rec);
                    MatchedOrderLineMgmt.LoadLines(MatchedOrderLineSource, Rec, ShowFromHeader, SourceRecordSystemId);
                end;
            }

            action(GetOrderLines)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Get Order Lines';
                Image = GetLines;
                ToolTip = 'Retrieve and display the order lines to match to the selected document line.';
                Visible = SourceIsOpenDocument;

                trigger OnAction()
                begin
                    MatchedOrderLineMgmt.GetOrderLines(MatchedOrderLineSource, Rec);
                    MatchedOrderLineMgmt.LoadLines(MatchedOrderLineSource, Rec, ShowFromHeader, SourceRecordSystemId);
                end;
            }

            action(GetReceiptShipmentLines)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Get Receipt/Shipment Lines';
                Image = GetLines;
                ToolTip = 'Retrieve and display the receipt/shipment lines to match to the selected document line.';
                Visible = SourceIsOpenDocument;

                trigger OnAction()
                begin
                    MatchedOrderLineMgmt.GetReceiptShipmentLines(MatchedOrderLineSource, Rec);
                    MatchedOrderLineMgmt.LoadLines(MatchedOrderLineSource, Rec, ShowFromHeader, SourceRecordSystemId);
                end;
            }

            action(ItemTrackingEntries)
            {
                ApplicationArea = ItemTracking;
                Caption = 'Item &Tracking Entries';
                Image = ItemTrackingLedger;
                ToolTip = 'View serial, lot or package numbers that are assigned to items.';
                Visible = SourceIsOpenDocument;

                trigger OnAction()
                begin
                    MatchedOrderLineMgmt.ShowItemTrackingEntries(MatchedOrderLineSource, Rec);
                    MatchedOrderLineMgmt.LoadLines(MatchedOrderLineSource, Rec, ShowFromHeader, SourceRecordSystemId);
                end;
            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                Caption = 'Process';

                actionref(ShowDocument_Promoted; ShowDocument)
                {
                }
                actionref(GetOrderLines_Promoted; GetOrderLines)
                {
                }
                actionref(GetReceiptShipmentLines_Promoted; GetReceiptShipmentLines)
                {
                }
                actionref(ItemTrackingEntries_Promoted; ItemTrackingEntries)
                {
                }
            }
        }
    }

    trigger OnOpenPage()
    begin
        MatchedOrderLineMgmt.LoadLines(MatchedOrderLineSource, Rec, ShowFromHeader, SourceRecordSystemId);
    end;

    trigger OnAfterGetRecord()
    begin
        StatusHideValue := Rec."Order No." <> '';
        case Rec.Indentation of
            0:
                LevelStyleExpr := 'Strong';
            1:
                LevelStyleExpr := 'StandardAccent';
            else
                LevelStyleExpr := 'None';
        end;

        SourceIsOpenDocument := MatchedOrderLineSource in ["Matched Order Line Source"::"Purchase Invoice", "Matched Order Line Source"::"Purchase Credit Memo", "Matched Order Line Source"::"Sales Invoice", "Matched Order Line Source"::"Sales Credit Memo"];
        QtyToInvoiceEditable := not IsNullGuid(Rec."Matched Order Line SystemId") and (Rec."Receipt on Invoice" or not IsNullGuid(Rec."Matched Rcpt./Shpt. Line SysId"));
    end;

    trigger OnDeleteRecord(): Boolean
    begin
        exit(MatchedOrderLineMgmt.LineCanBeDeleted(Rec, SourceIsOpenDocument));
    end;

    var
        MatchedOrderLineMgmt: Codeunit "Matched Order Line Mgmt.";
        MatchedOrderLineSource: Enum "Matched Order Line Source";
        ShowFromHeader: Boolean;
        StatusHideValue: Boolean;
        QtyToInvoiceEditable: Boolean;
        SourceIsOpenDocument: Boolean;
        SourceRecordSystemId: Guid;
        LevelStyleExpr: Text;

    internal procedure InitializePage(MatchedOrderLineSource2: Enum "Matched Order Line Source"; ShowFromHeader2: Boolean; SourceRecordSystemId2: Guid)
    begin
        MatchedOrderLineSource := MatchedOrderLineSource2;
        ShowFromHeader := ShowFromHeader2;
        SourceRecordSystemId := SourceRecordSystemId2;
    end;
}