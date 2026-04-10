// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Tracking;

using Microsoft.Foundation.UOM;
using Microsoft.Inventory.Item;
using Microsoft.Inventory.Ledger;
using Microsoft.Inventory.Location;
using Microsoft.Purchases.Document;
using Microsoft.Purchases.History;
using Microsoft.Purchases.Posting;
using System.Text;

codeunit 5826 "Matched Order Line Mgmt."
{
    Access = Internal;
    Permissions = TableData "Posted Matched Order Line" = RIMD;

    internal procedure ProcessMatchedReceiptOnInvoice(var PurchaseLine: Record "Purchase Line")
    var
        MatchedOrderLine: Record "Matched Order Line";
        PurchaseHeaderOrder: Record "Purchase Header";
        PurchaseLineOrder: Record "Purchase Line";
        TempPurchaseHeader: Record "Purchase Header" temporary;
        PurchPost: Codeunit "Purch.-Post";
    begin
        PurchaseLine.SetLoadFields(SystemId);
        if PurchaseLine.FindSet() then
            repeat
                MatchedOrderLine.SetRange("Document Line SystemId", PurchaseLine.SystemId);
                MatchedOrderLine.SetFilter("Matched Order Line SystemId", '<>%1', NullGuid);
                MatchedOrderLine.SetRange("Matched Rcpt./Shpt. Line SysId", NullGuid);
                MatchedOrderLine.SetRange("Receipt on Invoice", true);
                if MatchedOrderLine.FindSet() then
                    repeat
                        PurchaseLineOrder.GetBySystemId(MatchedOrderLine."Matched Order Line SystemId");

                        PurchaseHeaderOrder.Get(PurchaseLineOrder."Document Type", PurchaseLineOrder."Document No.");
                        PurchaseHeaderOrder.TestField("Receipt on Invoice");
                        TempPurchaseHeader := PurchaseHeaderOrder;
                        if TempPurchaseHeader.Insert() then;

                        PurchaseLineOrder.Validate("Qty. to Receive", MatchedOrderLine."Qty. to Invoice");

                        // used to store from which purchase invoice line the order line is auto-received
                        PurchaseLineOrder."Invoicing From Line SystemId" := PurchaseLine.SystemId;
                        PurchaseLineOrder.Modify(true);
                    until MatchedOrderLine.Next() = 0;
            until PurchaseLine.Next() = 0;

        if TempPurchaseHeader.FindSet() then
            repeat
                PurchaseHeaderOrder.Get(TempPurchaseHeader."Document Type", TempPurchaseHeader."No.");
                PurchaseHeaderOrder.Receive := true;
                PurchaseHeaderOrder.Invoice := false;

                PurchPost.SetSuppressCommit(true);
                PurchPost.Run(PurchaseHeaderOrder);
                Clear(PurchPost);

                PurchaseLineOrder.SetRange("Document Type", TempPurchaseHeader."Document Type");
                PurchaseLineOrder.SetRange("Document No.", TempPurchaseHeader."No.");
                PurchaseLineOrder.ModifyAll("Invoicing From Line SystemId", NullGuid);
            until TempPurchaseHeader.Next() = 0;
        PurchaseLine.SetLoadFields();
    end;

    internal procedure InsertMatchedOrderLineReceipt(PurchaseLineOrder: Record "Purchase Line"; var PurchRcptLine: Record "Purch. Rcpt. Line")
    var
        MatchedOrderLine: Record "Matched Order Line";
    begin
        if PurchaseLineOrder."Invoicing From Line SystemId" = NullGuid then
            exit;

        MatchedOrderLine.Init();
        MatchedOrderLine."Document Line SystemId" := PurchaseLineOrder."Invoicing From Line SystemId";
        MatchedOrderLine."Matched Order Line SystemId" := PurchaseLineOrder.SystemId;
        MatchedOrderLine."Matched Rcpt./Shpt. Line SysId" := PurchRcptLine.SystemId;
        MatchedOrderLine."Qty. to Invoice" := PurchRcptLine.Quantity;
        MatchedOrderLine."Qty. to Invoice (Base)" := PurchRcptLine."Quantity (Base)";
        MatchedOrderLine."Receipt on Invoice" := true;
        MatchedOrderLine.Insert();
    end;

    internal procedure CheckMatchedOrderLine(var PurchaseHeader: Record "Purchase Header"; var PurchaseLine: Record "Purchase Line")
    var
        MatchedOrderLine: Record "Matched Order Line";
        PurchLineOrder: Record "Purchase Line";
        PurchRcptLine: Record "Purch. Rcpt. Line";
    begin
        if not (PurchaseHeader."Document Type" in [PurchaseHeader."Document Type"::Invoice, PurchaseHeader."Document Type"::Order]) then
            exit;

        if PurchaseHeader."Document Type" = PurchaseHeader."Document Type"::Order then
            if PurchaseHeader."Receipt on Invoice" and IsNullGuid(PurchaseLine."Invoicing From Line SystemId") then
                Error(ReceiptOnInvoicePostFromMatchedInvoiceErr, PurchaseHeader.FieldCaption("Receipt on Invoice"));

        if PurchaseHeader."Document Type" = PurchaseHeader."Document Type"::Invoice then begin
            if not PurchaseLine.IsMatchedToOrder() then
                exit;

            PurchLineOrder.GetBySystemId(PurchaseLine.SystemId);
            if PurchLineOrder."Prepayment %" <> 0 then
                Error(PrepaymentNotSupportedErr, PurchLineOrder."Document No.", PurchLineOrder."Line No.");

            if PurchLineOrder.Type = PurchLineOrder.Type::"Charge (Item)" then
                Error(ItemChargeNotSupportedErr, PurchLineOrder."Document No.", PurchLineOrder."Line No.");

            MatchedOrderLine.SetRange("Document Line SystemId", PurchaseLine.SystemId);
            MatchedOrderLine.SetFilter("Matched Rcpt./Shpt. Line SysId", '<> %1', NullGuid);
            if MatchedOrderLine.IsEmpty() then
                Error(MustBeMatchedToReceiptErr, PurchaseLine."Line No.");

            MatchedOrderLine.CalcSums("Qty. to Invoice");

            if MatchedOrderLine."Qty. to Invoice" <> PurchaseLine.Quantity then
                Error(QtySumMismatchErr, PurchaseLine."Line No.");

            if MatchedOrderLine.FindSet() then
                repeat
                    PurchRcptLine.GetBySystemId(MatchedOrderLine."Matched Rcpt./Shpt. Line SysId");
                    if MatchedOrderLine."Qty. to Invoice" > PurchRcptLine."Qty. Rcd. Not Invoiced" then
                        Error(QtyToInvoiceExceedsQtyReceivedNotInvoicedErr, PurchaseLine."Line No.", PurchRcptLine."Document No.", PurchRcptLine."Line No.");
                until MatchedOrderLine.Next() = 0;
        end;
    end;

    internal procedure SetMatchedReceiptLinesFilter(var PurchRcptLine: Record "Purch. Rcpt. Line"; PurchaseLineInvoice: Record "Purchase Line")
    var
        MatchedOrderLine: Record "Matched Order Line";
        PurchRcptLineSysIDFilter: Text;
    begin
        MatchedOrderLine.SetRange("Document Line SystemId", PurchaseLineInvoice.SystemId);
        MatchedOrderLine.SetFilter("Matched Rcpt./Shpt. Line SysId", '<> %1', NullGuid);
        if MatchedOrderLine.FindSet() then begin
            repeat
                PurchRcptLineSysIDFilter += Format(MatchedOrderLine."Matched Rcpt./Shpt. Line SysId") + '|';
            until MatchedOrderLine.Next() = 0;

            if StrLen(PurchRcptLineSysIDFilter) = 0 then
                exit;

            PurchRcptLineSysIDFilter := CopyStr(PurchRcptLineSysIDFilter, 1, StrLen(PurchRcptLineSysIDFilter) - 1);
            PurchRcptLine.SetFilter(SystemId, PurchRcptLineSysIDFilter);
        end;
    end;

    internal procedure SetQtyToBeInvoiced(var QtyToBeInvoiced: Decimal; var QtyToBeInvoicedBase: Decimal; PurchaseLineInvoice: Record "Purchase Line"; PurchRcptLine: Record "Purch. Rcpt. Line")
    var
        MatchedOrderLine: Record "Matched Order Line";
    begin
        MatchedOrderLine.SetRange("Document Line SystemId", PurchaseLineInvoice.SystemId);
        MatchedOrderLine.SetRange("Matched Rcpt./Shpt. Line SysId", PurchRcptLine.SystemId);
        if MatchedOrderLine.FindFirst() then begin
            QtyToBeInvoiced := MatchedOrderLine."Qty. to Invoice";
            QtyToBeInvoicedBase := MatchedOrderLine."Qty. to Invoice (Base)";
        end;
    end;

    internal procedure UpdateMatchedOrderLines(var TempPurchaseLine: Record "Purchase Line" temporary; var PurchaseHeader: Record "Purchase Header")
    var
        PostedMatchedOrderLine: Record "Posted Matched Order Line";
        PurchaseLineOrder: Record "Purchase Line";
        PurchRcptLine: Record "Purch. Rcpt. Line";
    begin
        TempPurchaseLine.SetFilter(Type, '<>%1', TempPurchaseLine.Type::" ");
        if TempPurchaseLine.FindSet() then
            repeat
                PostedMatchedOrderLine.SetRange("Document Line SystemId", TempPurchaseLine.SystemId);
                PostedMatchedOrderLine.SetFilter("Matched Rcpt./Shpt. Line SysId", '<> %1', NullGuid);
                if PostedMatchedOrderLine.FindSet() then
                    repeat
                        PurchRcptLine.GetBySystemId(PostedMatchedOrderLine."Matched Rcpt./Shpt. Line SysId");
                        PurchaseLineOrder.Get(PurchaseLineOrder."Document Type"::Order, PurchRcptLine."Order No.", PurchRcptLine."Order Line No.");

                        if PurchaseLineOrder.Type = PurchaseLineOrder.Type::"Charge (Item)" then
                            Error(ItemChargeNotSupportedErr, PurchaseLineOrder."Document No.", PurchaseLineOrder."Line No.");

                        if PurchaseLineOrder."Prepayment %" <> 0 then
                            Error(PrepaymentNotSupportedErr, PurchaseLineOrder."Document No.", PurchaseLineOrder."Line No.");

                        PurchaseLineOrder."Quantity Invoiced" += PostedMatchedOrderLine."Qty. Invoiced";
                        PurchaseLineOrder."Qty. Invoiced (Base)" += PostedMatchedOrderLine."Qty. Invoiced (Base)";
                        if Abs(PurchaseLineOrder."Quantity Invoiced") > Abs(PurchaseLineOrder."Quantity Received") then
                            Error(InvoiceMoreThanReceivedErr, PurchaseLineOrder."Document No.");

                        PurchaseLineOrder.InitQtyToInvoice();
                        PurchaseLineOrder.InitOutstanding();
                        PurchaseLineOrder.Modify();
                    until PostedMatchedOrderLine.Next() = 0;
            until TempPurchaseLine.Next() = 0;
    end;

    internal procedure InsertPostedMatchedOrderLines(var PurchInvLine: Record "Purch. Inv. Line"; PurchaseLine: Record "Purchase Line")
    var
        MatchedOrderLine, MatchedOrderLine2 : Record "Matched Order Line";
        PostedMatchedOrderLine: Record "Posted Matched Order Line";
    begin
        if not PurchaseLine.IsMatchedToOrder() then
            exit;

        MatchedOrderLine.SetRange("Document Line SystemId", PurchaseLine.SystemId);
        if MatchedOrderLine.FindSet() then
            repeat
                Clear(PostedMatchedOrderLine);
                PostedMatchedOrderLine.TransferFields(MatchedOrderLine);
                PostedMatchedOrderLine."Document Line SystemId" := PurchInvLine.SystemId;
                if IsNullGuid(MatchedOrderLine."Matched Rcpt./Shpt. Line SysId") then begin
                    MatchedOrderLine2.SetRange("Document Line SystemId", MatchedOrderLine."Document Line SystemId");
                    MatchedOrderLine2.SetRange("Matched Order Line SystemId", MatchedOrderLine."Matched Order Line SystemId");
                    MatchedOrderLine2.SetFilter("Matched Rcpt./Shpt. Line SysId", '<> %1', NullGuid);
                    MatchedOrderLine2.CalcSums("Qty. to Invoice", "Qty. to Invoice (Base)");
                    PostedMatchedOrderLine."Qty. Invoiced" := MatchedOrderLine2."Qty. to Invoice";
                    PostedMatchedOrderLine."Qty. Invoiced (Base)" := MatchedOrderLine2."Qty. to Invoice (Base)";
                end;
                if PostedMatchedOrderLine."Qty. Invoiced" <> 0 then
                    PostedMatchedOrderLine.Insert();
            until MatchedOrderLine.Next() = 0;

        MatchedOrderLine.DeleteAll();
    end;

    internal procedure IsLineMatchedToReceiptShipment(PurchaseLine: Record "Purchase Line"): Boolean
    var
        MatchedOrderLine: Record "Matched Order Line";
    begin
        MatchedOrderLine.SetRange("Document Line SystemId", PurchaseLine.SystemId);
        MatchedOrderLine.SetFilter("Matched Rcpt./Shpt. Line SysId", '<> %1', NullGuid);
        exit(not MatchedOrderLine.IsEmpty());
    end;

    internal procedure IsLineMatched(PurchaseLine: Record "Purchase Line"; ShowError: Boolean): Boolean
    begin
        case PurchaseLine."Document Type" of
            PurchaseLine."Document Type"::Invoice:
                if PurchaseLine.IsMatchedToOrder() then
                    if ShowError then
                        Error(PurchaseInvoiceLineMatchedErr)
                    else
                        exit(true);
            PurchaseLine."Document Type"::Order:
                if PurchaseLine.IsMatchedToInvoiceCreditMemo() then
                    if ShowError then
                        Error(PurchaseOrderLineMatchedErr)
                    else
                        exit(true);
        end;
    end;

    internal procedure DeleteMatchedOrderLines(var PurchaseLine: Record "Purchase Line")
    var
        MatchedOrderLine: Record "Matched Order Line";
    begin
        if PurchaseLine.IsTemporary() then
            exit;

        if PurchaseLine."Document Type" in [PurchaseLine."Document Type"::Invoice, PurchaseLine."Document Type"::Order] then begin
            if PurchaseLine."Document Type" = PurchaseLine."Document Type"::Invoice then
                MatchedOrderLine.SetRange("Document Line SystemId", PurchaseLine.SystemId);
            if PurchaseLine."Document Type" = PurchaseLine."Document Type"::Order then
                MatchedOrderLine.SetRange("Matched Order Line SystemId", PurchaseLine.SystemId);
            MatchedOrderLine.DeleteAll();
        end;
    end;

    internal procedure DeleteAllMatchedOrderLines(var PurchaseHeader: Record "Purchase Header")
    var
        MatchedOrderLine: Record "Matched Order Line";
        PurchaseLine: Record "Purchase Line";
        PurchaseLineSystemIDFilter: Text;
    begin
        if PurchaseHeader."Document Type" = PurchaseHeader."Document Type"::Order then begin
            PurchaseLine.SetRange("Document Type", PurchaseHeader."Document Type");
            PurchaseLine.SetRange("Document No.", PurchaseHeader."No.");
            if PurchaseLine.FindSet() then begin
                repeat
                    PurchaseLineSystemIDFilter += Format(PurchaseLine.SystemId) + '|';
                until PurchaseLine.Next() = 0;

                if StrLen(PurchaseLineSystemIDFilter) = 0 then
                    exit;

                PurchaseLineSystemIDFilter := CopyStr(PurchaseLineSystemIDFilter, 1, StrLen(PurchaseLineSystemIDFilter) - 1);
                MatchedOrderLine.SetFilter("Matched Order Line SystemId", PurchaseLineSystemIDFilter);
                MatchedOrderLine.DeleteAll();
            end;
        end;
    end;

    internal procedure DeleteMatchedLinesForPurchReceipt(var PurchRcptLine: Record "Purch. Rcpt. Line")
    var
        MatchedOrderLine: Record "Matched Order Line";
        PostedMatchedOrderLine: Record "Posted Matched Order Line";
    begin
        if PurchRcptLine.IsTemporary() then
            exit;

        MatchedOrderLine.SetRange("Matched Rcpt./Shpt. Line SysId", PurchRcptLine.SystemId);
        MatchedOrderLine.DeleteAll();

        PostedMatchedOrderLine.SetRange("Matched Rcpt./Shpt. Line SysId", PurchRcptLine.SystemId);
        PostedMatchedOrderLine.DeleteAll();
    end;

    internal procedure DeleteMatchedLinesFromPostedPurchaseInvoice(var PurchInvLine: Record "Purch. Inv. Line")
    var
        PostedMatchedOrderLine: Record "Posted Matched Order Line";
    begin
        if PurchInvLine.IsTemporary() then
            exit;

        PostedMatchedOrderLine.SetRange("Document Line SystemId", PurchInvLine.SystemId);
        PostedMatchedOrderLine.DeleteAll();
    end;

    internal procedure LoadLines(MatchedOrderLineSource: Enum "Matched Order Line Source"; var DetailedMatchedOrderLine: Record "Detailed Matched Order Line"; ShowFromHeader: Boolean; SourceRecordSystemId: Guid)
    begin
        if SourceRecordSystemId = NullGuid then
            exit;

        DetailedMatchedOrderLine.Reset();
        DetailedMatchedOrderLine.DeleteAll();
        Clear(DetailedMatchedOrderLine);
        case MatchedOrderLineSource of
            "Matched Order Line Source"::"Purchase Invoice":
                LoadLinesForPurchaseInvoice(DetailedMatchedOrderLine, ShowFromHeader, SourceRecordSystemId);
            "Matched Order Line Source"::"Posted Purchase Invoice":
                LoadLinesForPostedPurchaseInvoice(DetailedMatchedOrderLine, ShowFromHeader, SourceRecordSystemId);
        end;
    end;

    internal procedure LoadLinesForPurchaseInvoice(var DetailedMatchedOrderLine: Record "Detailed Matched Order Line"; ShowFromHeader: Boolean; SourceRecordSystemId: Guid)
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
    begin
        DetailedMatchedOrderLine.Reset();
        DetailedMatchedOrderLine.DeleteAll();
        Clear(DetailedMatchedOrderLine);

        if ShowFromHeader then begin
            PurchaseHeader.GetBySystemId(SourceRecordSystemId);
            PurchaseLine.SetRange("Document Type", PurchaseHeader."Document Type");
            PurchaseLine.SetRange("Document No.", PurchaseHeader."No.");
            if PurchaseLine.FindSet() then
                repeat
                    LoadOneLineForPurchaseInvoice(DetailedMatchedOrderLine, PurchaseLine.SystemId);
                until PurchaseLine.Next() = 0;
        end else
            LoadOneLineForPurchaseInvoice(DetailedMatchedOrderLine, SourceRecordSystemId);
    end;

    internal procedure LoadLinesForPostedPurchaseInvoice(var DetailedMatchedOrderLine: Record "Detailed Matched Order Line"; ShowFromHeader: Boolean; SourceRecordSystemId: Guid)
    var
        PurchInvHeader: Record "Purch. Inv. Header";
        PurchInvLine: Record "Purch. Inv. Line";
    begin
        if ShowFromHeader then begin
            PurchInvHeader.GetBySystemId(SourceRecordSystemId);
            PurchInvLine.SetRange("Document No.", PurchInvHeader."No.");
            if PurchInvLine.FindSet() then
                repeat
                    LoadOneLineForPostedPurchaseInvoice(DetailedMatchedOrderLine, PurchInvLine.SystemId);
                until PurchInvLine.Next() = 0;
        end else
            LoadOneLineForPostedPurchaseInvoice(DetailedMatchedOrderLine, SourceRecordSystemId);
    end;

    internal procedure LoadOneLineForPurchaseInvoice(var DetailedMatchedOrderLine: Record "Detailed Matched Order Line"; SourceLineSystemId: Guid)
    var
        MatchedOrderLine, MatchedOrderLine2 : Record "Matched Order Line";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLineInvoice, PurchaseLineOrder : Record "Purchase Line";
        PurchRcptLine: Record "Purch. Rcpt. Line";
        TempItemLedgEntry: Record "Item Ledger Entry" temporary;
        ReservationEntry: Record "Reservation Entry";
        ItemTrackingDocMgmt: Codeunit "Item Tracking Doc. Management";
    begin
        PurchaseLineInvoice.GetBySystemId(SourceLineSystemId);

        Clear(DetailedMatchedOrderLine);
        DetailedMatchedOrderLine.Indentation := 0;
        DetailedMatchedOrderLine."Document Line SystemId" := SourceLineSystemId;
        DetailedMatchedOrderLine.Line := StrSubstNo(InvoiceLineLbl, PurchaseLineInvoice."Document No.", PurchaseLineInvoice."Line No.");
        DetailedMatchedOrderLine."Line No." := PurchaseLineInvoice."Line No.";
        DetailedMatchedOrderLine.Type := PurchaseLineInvoice.Type;
        DetailedMatchedOrderLine."No." := PurchaseLineInvoice."No.";
        DetailedMatchedOrderLine.Description := PurchaseLineInvoice.Description;
        DetailedMatchedOrderLine."Description 2" := PurchaseLineInvoice."Description 2";
        DetailedMatchedOrderLine.Quantity := PurchaseLineInvoice.Quantity;
        DetailedMatchedOrderLine.Insert();

        MatchedOrderLine.SetRange("Document Line SystemId", PurchaseLineInvoice.SystemId);
        if MatchedOrderLine.FindSet() then begin
            DetailedMatchedOrderLine.HasSubLines := true;
            DetailedMatchedOrderLine.Modify();
            DetailedMatchedOrderLine.HasSubLines := false;
            repeat
                Clear(DetailedMatchedOrderLine);
                Clear(PurchRcptLine);

                DetailedMatchedOrderLine."Document Line SystemId" := MatchedOrderLine."Document Line SystemId";
                DetailedMatchedOrderLine."Matched Order Line SystemId" := MatchedOrderLine."Matched Order Line SystemId";
                DetailedMatchedOrderLine."Matched Rcpt./Shpt. Line SysId" := MatchedOrderLine."Matched Rcpt./Shpt. Line SysId";
                DetailedMatchedOrderLine."Line No." := PurchaseLineInvoice."Line No.";
                DetailedMatchedOrderLine.Type := PurchaseLineInvoice.Type;
                DetailedMatchedOrderLine."No." := PurchaseLineInvoice."No.";
                DetailedMatchedOrderLine."Receipt on Invoice" := MatchedOrderLine."Receipt on Invoice";

                DetailedMatchedOrderLine.Indentation := 1;
                if not PurchaseLineOrder.GetBySystemId(MatchedOrderLine."Matched Order Line SystemId") then begin
                    // Matched order line not found - delete the match
                    MatchedOrderLine2 := MatchedOrderLine;
                    MatchedOrderLine2.Delete();
                end else begin
                    if IsNullGuid(MatchedOrderLine."Matched Rcpt./Shpt. Line SysId") then begin
                        DetailedMatchedOrderLine.Line := StrSubstNo(OrderLineLbl, PurchaseLineOrder."Document No.", PurchaseLineOrder."Line No.");
                        DetailedMatchedOrderLine.Description := PurchaseLineOrder.Description;
                        DetailedMatchedOrderLine."Description 2" := PurchaseLineOrder."Description 2";
                        DetailedMatchedOrderLine."Order No." := PurchaseLineOrder."Document No.";
                        DetailedMatchedOrderLine."Order Line No." := PurchaseLineOrder."Line No.";
                        DetailedMatchedOrderLine.Quantity := PurchaseLineOrder.Quantity;
                        DetailedMatchedOrderLine."Qty. Rcd. Not Invoiced" := PurchaseLineOrder."Qty. Rcd. Not Invoiced";

                        if PurchaseHeader."No." <> PurchaseLineOrder."Document No." then
                            PurchaseHeader.Get(PurchaseLineOrder."Document Type", PurchaseLineOrder."Document No.");
                        DetailedMatchedOrderLine."Your Reference" := PurchaseHeader."Your Reference";
                        DetailedMatchedOrderLine."Vendor Order No." := PurchaseHeader."Vendor Order No.";
                        DetailedMatchedOrderLine."Vendor Shipment No." := PurchaseHeader."Vendor Shipment No.";
                        DetailedMatchedOrderLine."Vendor Invoice No." := PurchaseHeader."Vendor Invoice No.";
                        DetailedMatchedOrderLine."Vendor Cr. Memo No." := PurchaseHeader."Vendor Cr. Memo No.";

                        if DetailedMatchedOrderLine."Receipt on Invoice" then begin
                            if MatchedOrderLine."Qty. to Invoice" = 0 then begin
                                MatchedOrderLine."Qty. to Invoice" := PurchaseLineOrder."Qty. to Invoice";
                                MatchedOrderLine."Qty. to Invoice (Base)" := PurchaseLineOrder."Qty. to Invoice (Base)";
                                MatchedOrderLine.Modify();
                            end;
                            DetailedMatchedOrderLine."Qty. to Invoice" := MatchedOrderLine."Qty. to Invoice";
                            DetailedMatchedOrderLine."Qty. to Invoice (Base)" := MatchedOrderLine."Qty. to Invoice (Base)";

                            // Accumulate quantities to invoice for order lines matched to the same invoice line
                            UpdateQtyOnParentLines(DetailedMatchedOrderLine, true, DetailedMatchedOrderLine."Qty. to Invoice", DetailedMatchedOrderLine."Qty. to Invoice (Base)");
                        end;
                    end else begin
                        DetailedMatchedOrderLine.Indentation := 2;
                        if not PurchRcptLine.GetBySystemId(MatchedOrderLine."Matched Rcpt./Shpt. Line SysId") then begin
                            // Matched receipt line not found - delete the match
                            MatchedOrderLine2 := MatchedOrderLine;
                            MatchedOrderLine2.Delete();
                        end else begin
                            DetailedMatchedOrderLine.Line := StrSubstNo(RcptLineLbl, PurchRcptLine."Document No.", PurchRcptLine."Line No.");
                            DetailedMatchedOrderLine.Description := PurchRcptLine.Description;
                            DetailedMatchedOrderLine."Description 2" := PurchRcptLine."Description 2";
                            DetailedMatchedOrderLine."Order No." := PurchaseLineOrder."Document No.";
                            DetailedMatchedOrderLine."Order Line No." := PurchaseLineOrder."Line No.";
                            DetailedMatchedOrderLine."Receipt/Shipment No." := PurchRcptLine."Document No.";
                            DetailedMatchedOrderLine."Receipt/Shipment Line No." := PurchRcptLine."Line No.";
                            DetailedMatchedOrderLine.Quantity := PurchRcptLine.Quantity;
                            DetailedMatchedOrderLine."Qty. Rcd. Not Invoiced" := PurchRcptLine."Qty. Rcd. Not Invoiced";

                            TempItemLedgEntry.DeleteAll();
                            ItemTrackingDocMgmt.RetrieveEntriesFromShptRcpt(TempItemLedgEntry, Database::"Purch. Rcpt. Line", 0, PurchRcptLine."Document No.", '', 0, PurchRcptLine."Line No.");
                            if TempItemLedgEntry.FindSet() then begin
                                MatchedOrderLine."Qty. to Invoice" := 0;
                                MatchedOrderLine."Qty. to Invoice (Base)" := 0;

                                ReservationEntry.SetSourceFilter(Database::"Purchase Line", PurchaseLineInvoice."Document Type".AsInteger(), PurchaseLineInvoice."Document No.", PurchaseLineInvoice."Line No.", true);
                                repeat
                                    ReservationEntry.SetRange("Item Ledger Entry No.", TempItemLedgEntry."Entry No.");
                                    if ReservationEntry.FindSet() then
                                        repeat
                                            MatchedOrderLine."Qty. to Invoice" += ReservationEntry.Quantity;
                                            MatchedOrderLine."Qty. to Invoice (Base)" += ReservationEntry."Quantity (Base)";
                                        until ReservationEntry.Next() = 0;
                                until TempItemLedgEntry.Next() = 0;
                                MatchedOrderLine.Modify();
                            end else
                                if MatchedOrderLine."Qty. to Invoice" = 0 then begin
                                    MatchedOrderLine."Qty. to Invoice" := PurchRcptLine."Qty. Rcd. Not Invoiced";
                                    MatchedOrderLine."Qty. to Invoice (Base)" := PurchaseLineOrder.CalcBaseQty(MatchedOrderLine."Qty. to Invoice", MatchedOrderLine.FieldCaption("Qty. to Invoice"), MatchedOrderLine.FieldCaption("Qty. to Invoice (Base)"));
                                    MatchedOrderLine.Modify();
                                end;
                            DetailedMatchedOrderLine."Qty. to Invoice" := MatchedOrderLine."Qty. to Invoice";
                            DetailedMatchedOrderLine."Qty. to Invoice (Base)" := MatchedOrderLine."Qty. to Invoice (Base)";

                            // Accumulate quantities to invoice for receipt lines matched to the same order and invoice line
                            UpdateQtyOnParentLines(DetailedMatchedOrderLine, false, DetailedMatchedOrderLine."Qty. to Invoice", DetailedMatchedOrderLine."Qty. to Invoice (Base)");
                            UpdateQtyOnParentLines(DetailedMatchedOrderLine, true, DetailedMatchedOrderLine."Qty. to Invoice", DetailedMatchedOrderLine."Qty. to Invoice (Base)");
                        end;
                    end;
                    DetailedMatchedOrderLine.Insert();
                end;
            until MatchedOrderLine.Next() = 0;
        end;
    end;

    internal procedure LoadOneLineForPostedPurchaseInvoice(var DetailedMatchedOrderLine: Record "Detailed Matched Order Line"; SourceLineSystemId: Guid)
    var
        PostedMatchedOrderLine, PostedMatchedOrderLine2 : Record "Posted Matched Order Line";
        PurchaseLineOrder: Record "Purchase Line";
        PurchaseLineInvoice: Record "Purch. Inv. Line";
        PurchRcptLine: Record "Purch. Rcpt. Line";
    begin
        PurchaseLineInvoice.GetBySystemId(SourceLineSystemId);

        Clear(DetailedMatchedOrderLine);
        DetailedMatchedOrderLine.Indentation := 0;
        DetailedMatchedOrderLine."Document Line SystemId" := SourceLineSystemId;
        DetailedMatchedOrderLine.Line := StrSubstNo(InvoiceLineLbl, PurchaseLineInvoice."Document No.", PurchaseLineInvoice."Line No.");
        DetailedMatchedOrderLine."Line No." := PurchaseLineInvoice."Line No.";
        DetailedMatchedOrderLine.Type := PurchaseLineInvoice.Type;
        DetailedMatchedOrderLine."No." := PurchaseLineInvoice."No.";
        DetailedMatchedOrderLine.Description := PurchaseLineInvoice.Description;
        DetailedMatchedOrderLine."Description 2" := PurchaseLineInvoice."Description 2";
        DetailedMatchedOrderLine.Quantity := PurchaseLineInvoice.Quantity;
        DetailedMatchedOrderLine."Qty. Invoiced" := PurchaseLineInvoice.Quantity;
        DetailedMatchedOrderLine."Qty. Invoiced (Base)" := PurchaseLineInvoice."Quantity (Base)";
        DetailedMatchedOrderLine.Insert();

        PostedMatchedOrderLine.SetRange("Document Line SystemId", PurchaseLineInvoice.SystemId);
        if PostedMatchedOrderLine.FindSet() then begin
            DetailedMatchedOrderLine.HasSubLines := true;
            DetailedMatchedOrderLine.Modify();
            DetailedMatchedOrderLine.HasSubLines := false;
            repeat
                Clear(DetailedMatchedOrderLine);
                Clear(PurchRcptLine);

                DetailedMatchedOrderLine."Document Line SystemId" := PostedMatchedOrderLine."Document Line SystemId";
                DetailedMatchedOrderLine."Matched Order Line SystemId" := PostedMatchedOrderLine."Matched Order Line SystemId";
                DetailedMatchedOrderLine."Matched Rcpt./Shpt. Line SysId" := PostedMatchedOrderLine."Matched Rcpt./Shpt. Line SysId";
                DetailedMatchedOrderLine."Line No." := PurchaseLineInvoice."Line No.";
                DetailedMatchedOrderLine.Type := PurchaseLineInvoice.Type;
                DetailedMatchedOrderLine."No." := PurchaseLineInvoice."No.";
                DetailedMatchedOrderLine."Receipt on Invoice" := PostedMatchedOrderLine."Receipt on Invoice";
                DetailedMatchedOrderLine."Qty. Invoiced" := PostedMatchedOrderLine."Qty. Invoiced";
                DetailedMatchedOrderLine."Qty. Invoiced (Base)" := PostedMatchedOrderLine."Qty. Invoiced (Base)";

                if IsNullGuid(PostedMatchedOrderLine."Matched Rcpt./Shpt. Line SysId") then begin
                    DetailedMatchedOrderLine.Indentation := 1;

                    if PurchaseLineOrder.GetBySystemId(PostedMatchedOrderLine."Matched Order Line SystemId") then begin
                        DetailedMatchedOrderLine.Line := StrSubstNo(OrderLineLbl, PurchaseLineOrder."Document No.", PurchaseLineOrder."Line No.");
                        DetailedMatchedOrderLine.Description := PurchaseLineOrder.Description;
                        DetailedMatchedOrderLine."Description 2" := PurchaseLineOrder."Description 2";
                        DetailedMatchedOrderLine."Order No." := PurchaseLineOrder."Document No.";
                        DetailedMatchedOrderLine."Order Line No." := PurchaseLineOrder."Line No.";
                        DetailedMatchedOrderLine.Insert();
                    end else begin
                        PostedMatchedOrderLine2.SetRange("Document Line SystemId", PostedMatchedOrderLine."Document Line SystemId");
                        PostedMatchedOrderLine2.SetRange("Matched Order Line SystemId", PostedMatchedOrderLine."Matched Order Line SystemId");
                        PostedMatchedOrderLine2.SetFilter("Matched Rcpt./Shpt. Line SysId", '<> %1', NullGuid);
                        if PostedMatchedOrderLine2.FindFirst() then
                            if not PurchRcptLine.GetBySystemId(PostedMatchedOrderLine2."Matched Rcpt./Shpt. Line SysId") then begin
                                // Matched receipt line not found - delete the match
                                PostedMatchedOrderLine2 := PostedMatchedOrderLine;
                                PostedMatchedOrderLine2.Delete();
                            end else begin
                                DetailedMatchedOrderLine.Line := StrSubstNo(OrderLineLbl, PurchRcptLine."Order No.", PurchRcptLine."Order Line No.");
                                DetailedMatchedOrderLine.Description := PurchaseLineInvoice.Description;
                                DetailedMatchedOrderLine."Description 2" := PurchaseLineInvoice."Description 2";
                                DetailedMatchedOrderLine."Order No." := PurchRcptLine."Order No.";
                                DetailedMatchedOrderLine."Order Line No." := PurchRcptLine."Order Line No.";
                                DetailedMatchedOrderLine.Insert();
                            end;
                    end;
                end else begin
                    DetailedMatchedOrderLine.Indentation := 2;
                    if not PurchRcptLine.GetBySystemId(PostedMatchedOrderLine."Matched Rcpt./Shpt. Line SysId") then begin
                        // Matched receipt line not found - delete the match
                        PostedMatchedOrderLine2 := PostedMatchedOrderLine;
                        PostedMatchedOrderLine2.Delete();
                    end else begin
                        DetailedMatchedOrderLine.Line := StrSubstNo(RcptLineLbl, PurchRcptLine."Document No.", PurchRcptLine."Line No.");
                        DetailedMatchedOrderLine.Description := PurchRcptLine.Description;
                        DetailedMatchedOrderLine."Description 2" := PurchRcptLine."Description 2";
                        DetailedMatchedOrderLine."Order No." := PurchRcptLine."Order No.";
                        DetailedMatchedOrderLine."Order Line No." := PurchRcptLine."Order Line No.";
                        DetailedMatchedOrderLine."Receipt/Shipment No." := PurchRcptLine."Document No.";
                        DetailedMatchedOrderLine."Receipt/Shipment Line No." := PurchRcptLine."Line No.";
                        DetailedMatchedOrderLine.Insert();
                    end;
                end;
            until PostedMatchedOrderLine.Next() = 0;
        end;
    end;

    internal procedure GetOrderLines(MatchedOrderLineSource: Enum "Matched Order Line Source"; DetailedMatchedOrderLine: Record "Detailed Matched Order Line")
    begin
        case MatchedOrderLineSource of
            "Matched Order Line Source"::"Purchase Invoice":
                GetOrderLinesForPurchaseInvoice(DetailedMatchedOrderLine);
        end;
    end;

    internal procedure GetOrderLinesForPurchaseInvoice(var DetailedMatchedOrderLine: Record "Detailed Matched Order Line")
    var
        PurchaseHeaderOrder: Record "Purchase Header";
        PurchaseLineInvoice, PurchaseLineOrder : Record "Purchase Line";
        PurchRcptLine: Record "Purch. Rcpt. Line";
        PurchaseLines: Page "Purchase Lines";
    begin
        PurchaseLineInvoice.GetBySystemId(DetailedMatchedOrderLine."Document Line SystemId");
        PurchaseLineOrder.FilterGroup(-1);
        PurchaseLineOrder.SetFilter("Outstanding Quantity", '<>0');
        PurchaseLineOrder.SetFilter("Qty. Rcd. Not Invoiced", '<>0');
        PurchaseLineOrder.FilterGroup(2);
        PurchaseLineOrder.SetRange("Document Type", PurchaseLineOrder."Document Type"::Order);
        PurchaseLineOrder.SetRange("Buy-from Vendor No.", PurchaseLineInvoice."Buy-from Vendor No.");
        PurchaseLineOrder.SetRange("Pay-to Vendor No.", PurchaseLineInvoice."Pay-to Vendor No.");
        PurchaseLineOrder.SetRange(Type, PurchaseLineInvoice.Type);
        PurchaseLineOrder.SetRange("No.", PurchaseLineInvoice."No.");
        PurchaseLineOrder.SetRange("Location Code", PurchaseLineInvoice."Location Code");
        PurchaseLineOrder.SetRange("Variant Code", PurchaseLineInvoice."Variant Code");
        PurchaseLineOrder.SetRange("Unit of Measure Code", PurchaseLineInvoice."Unit of Measure Code");
        if PurchaseLineOrder.FindSet() then
            repeat
                PurchaseLineOrder.Mark(true);
            until PurchaseLineOrder.Next() = 0;
        PurchaseLineOrder.MarkedOnly(true);
        PurchaseLineOrder.FilterGroup(0);

        PurchaseLines.SetTableView(PurchaseLineOrder);
        PurchaseLines.LookupMode := true;
        if PurchaseLines.RunModal() = Action::LookupOK then begin
            PurchaseLines.SetSelectionFilter(PurchaseLineOrder);
            if PurchaseLineOrder.FindSet() then
                repeat
                    if PurchaseHeaderOrder."No." <> PurchaseLineOrder."Document No." then
                        PurchaseHeaderOrder.Get(PurchaseLineOrder."Document Type", PurchaseLineOrder."Document No.");

                    InsertMatchedOrderLine(PurchaseLineInvoice.SystemId, PurchaseLineOrder.SystemId, NullGuid, PurchaseLineOrder."Qty. Rcd. Not Invoiced", PurchaseLineOrder."Qty. Rcd. Not Invoiced (Base)", PurchaseHeaderOrder."Receipt on Invoice");

                    PurchRcptLine.SetRange("Order No.", PurchaseLineOrder."Document No.");
                    PurchRcptLine.SetRange("Order Line No.", PurchaseLineOrder."Line No.");
                    PurchRcptLine.SetFilter("Qty. Rcd. Not Invoiced", '<>0');
                    if PurchRcptLine.FindSet() then
                        repeat
                            ItemTrackingMgt.CopyMatchedItemTrkgToPurchLine(
                                PurchaseLineOrder,
                                PurchaseLineInvoice,
                                InsertMatchedOrderLine(
                                    PurchaseLineInvoice.SystemId,
                                    PurchaseLineOrder.SystemId,
                                    PurchRcptLine.SystemId,
                                    PurchRcptLine."Qty. Rcd. Not Invoiced",
                                    PurchaseLineOrder.CalcBaseQty(PurchRcptLine."Qty. Rcd. Not Invoiced", PurchaseLineOrder.FieldCaption("Qty. to Invoice"), PurchaseLineOrder.FieldCaption("Qty. to Invoice (Base)")),
                                    false),
                                false);
                        until PurchRcptLine.Next() = 0;
                until PurchaseLineOrder.Next() = 0;
        end;
    end;

    internal procedure GetReceiptShipmentLines(MatchedOrderLineSource: Enum "Matched Order Line Source"; DetailedMatchedOrderLine: Record "Detailed Matched Order Line")
    begin
        case MatchedOrderLineSource of
            "Matched Order Line Source"::"Purchase Invoice":
                GetPurchaseReceiptLines(DetailedMatchedOrderLine);
        end;
    end;

    internal procedure GetPurchaseReceiptLines(DetailedMatchedOrderLine: Record "Detailed Matched Order Line")
    var
        PurchaseHeaderOrder: Record "Purchase Header";
        PurchaseLineInvoice, PurchaseLineOrder : Record "Purchase Line";
        PurchRcptLine: Record "Purch. Rcpt. Line";
        GetReceiptLines: Page "Get Receipt Lines";
    begin
        PurchaseLineInvoice.GetBySystemId(DetailedMatchedOrderLine."Document Line SystemId");
        PurchRcptLine.FilterGroup(2);
        if IsNullGuid(DetailedMatchedOrderLine."Matched Order Line SystemId") then begin
            PurchRcptLine.SetRange("Buy-from Vendor No.", PurchaseLineInvoice."Buy-from Vendor No.");
            PurchRcptLine.SetRange("Pay-to Vendor No.", PurchaseLineInvoice."Pay-to Vendor No.");
            PurchRcptLine.SetRange(Type, PurchaseLineInvoice.Type);
            PurchRcptLine.SetRange("No.", PurchaseLineInvoice."No.");
            PurchRcptLine.SetRange("Location Code", PurchaseLineInvoice."Location Code");
            PurchRcptLine.SetRange("Variant Code", PurchaseLineInvoice."Variant Code");
            PurchRcptLine.SetRange("Unit of Measure Code", PurchaseLineInvoice."Unit of Measure Code");
        end else begin
            PurchaseLineOrder.GetBySystemId(DetailedMatchedOrderLine."Matched Order Line SystemId");
            PurchRcptLine.SetRange("Order No.", PurchaseLineOrder."Document No.");
            PurchRcptLine.SetRange("Order Line No.", PurchaseLineOrder."Line No.");
        end;
        PurchRcptLine.SetFilter("Qty. Rcd. Not Invoiced", '<>0');
        PurchRcptLine.FilterGroup(0);

        GetReceiptLines.SetTableView(PurchRcptLine);
        GetReceiptLines.SetSelectionOnly(true);
        GetReceiptLines.LookupMode := true;
        if GetReceiptLines.RunModal() = Action::LookupOK then begin
            GetReceiptLines.SetSelectionFilter(PurchRcptLine);
            if PurchRcptLine.FindSet() then
                repeat
                    if IsNullGuid(DetailedMatchedOrderLine."Matched Order Line SystemId") then begin
                        PurchaseLineOrder.Get(PurchaseLineOrder."Document Type"::Order, PurchRcptLine."Order No.", PurchRcptLine."Order Line No.");
                        PurchaseHeaderOrder.Get(PurchaseLineOrder."Document Type", PurchaseLineOrder."Document No.");
                        InsertMatchedOrderLine(PurchaseLineInvoice.SystemId, PurchaseLineOrder.SystemId, NullGuid, PurchaseLineOrder."Qty. Rcd. Not Invoiced", PurchaseLineOrder."Qty. Rcd. Not Invoiced (Base)", PurchaseHeaderOrder."Receipt on Invoice");
                    end;
                    ItemTrackingMgt.CopyMatchedItemTrkgToPurchLine(
                        PurchaseLineOrder,
                        PurchaseLineInvoice,
                        InsertMatchedOrderLine(
                            PurchaseLineInvoice.SystemId,
                            PurchaseLineOrder.SystemId,
                            PurchRcptLine.SystemId,
                            PurchRcptLine."Qty. Rcd. Not Invoiced",
                            PurchaseLineOrder.CalcBaseQty(PurchRcptLine."Qty. Rcd. Not Invoiced", PurchaseLineOrder.FieldCaption("Qty. to Invoice"), PurchaseLineOrder.FieldCaption("Qty. to Invoice (Base)")),
                            false),
                        false);
                until PurchRcptLine.Next() = 0;
        end;
    end;

    internal procedure ShowItemTrackingEntries(MatchedOrderLineSource: Enum "Matched Order Line Source"; DetailedMatchedOrderLine: Record "Detailed Matched Order Line")
    begin
        case MatchedOrderLineSource of
            "Matched Order Line Source"::"Purchase Invoice":
                ShowItemTrackingEntriesForPurchaseInvoice(DetailedMatchedOrderLine);
        end;
    end;

    internal procedure ShowItemTrackingEntriesForPurchaseInvoice(DetailedMatchedOrderLine: Record "Detailed Matched Order Line")
    var
        PurchaseLineInvoice: Record "Purchase Line";
        PurchRcptLine: Record "Purch. Rcpt. Line";
        ItemLedgerEntry: Record "Item Ledger Entry";
        PurchLineReserve: Codeunit "Purch. Line-Reserve";
        SelectionFilterManagement: Codeunit SelectionFilterManagement;
        RecRef: RecordRef;
    begin
        if not IsNullGuid(DetailedMatchedOrderLine."Matched Rcpt./Shpt. Line SysId") then begin
            PurchaseLineInvoice.GetBySystemId(DetailedMatchedOrderLine."Document Line SystemId");
            if PurchRcptLine.GetBySystemId(DetailedMatchedOrderLine."Matched Rcpt./Shpt. Line SysId") then begin
                ItemLedgerEntry.SetRange("Document Type", ItemLedgerEntry."Document Type"::"Purchase Receipt");
                ItemLedgerEntry.SetRange("Document No.", PurchRcptLine."Document No.");
                ItemLedgerEntry.SetRange("Document Line No.", PurchRcptLine."Line No.");
                if ItemLedgerEntry.FindSet() then
                    repeat
                        ItemLedgerEntry.Mark(true);
                    until ItemLedgerEntry.Next() = 0;
                ItemLedgerEntry.MarkedOnly(true);
                RecRef.GetTable(ItemLedgerEntry);

                PurchLineReserve.CallItemTracking(PurchaseLineInvoice, SelectionFilterManagement.GetSelectionFilter(RecRef, ItemLedgerEntry.FieldNo("Entry No.")));
            end;
        end;
    end;

    internal procedure ShowDocument(MatchedOrderLineSource: Enum "Matched Order Line Source"; DetailedMatchedOrderLine: Record "Detailed Matched Order Line")
    begin
        case MatchedOrderLineSource of
            "Matched Order Line Source"::"Purchase Invoice", "Matched Order Line Source"::"Posted Purchase Invoice":
                ShowPurchaseInvoiceDocument(DetailedMatchedOrderLine);
        end;
    end;

    internal procedure ShowPurchaseInvoiceDocument(DetailedMatchedOrderLine: Record "Detailed Matched Order Line")
    var
        PurchaseHeaderOrder: Record "Purchase Header";
        PurchaseLineOrder: Record "Purchase Line";
        PurchRcptHeader: Record "Purch. Rcpt. Header";
        PurchRcptLine: Record "Purch. Rcpt. Line";
    begin
        if not IsNullGuid(DetailedMatchedOrderLine."Matched Rcpt./Shpt. Line SysId") then begin
            if not PurchRcptLine.GetBySystemId(DetailedMatchedOrderLine."Matched Rcpt./Shpt. Line SysId") then
                exit;
            PurchRcptHeader.Get(PurchRcptLine."Document No.");
            Page.Run(Page::"Posted Purchase Receipt", PurchRcptHeader);
        end else
            if not IsNullGuid(DetailedMatchedOrderLine."Matched Order Line SystemId") then begin
                if not PurchaseLineOrder.GetBySystemId(DetailedMatchedOrderLine."Matched Order Line SystemId") then
                    exit;
                PurchaseHeaderOrder.Get(PurchaseLineOrder."Document Type", PurchaseLineOrder."Document No.");
                Page.Run(Page::"Purchase Order", PurchaseHeaderOrder);
            end;
    end;

    internal procedure ValidateQtyToInvoice(MatchedOrderLineSource: Enum "Matched Order Line Source"; var DetailedMatchedOrderLine: Record "Detailed Matched Order Line"; var xDetailedMatchedOrderLine: Record "Detailed Matched Order Line")
    var
        MatchedOrderLine: Record "Matched Order Line";
    begin
        if IsNullGuid(DetailedMatchedOrderLine."Matched Order Line SystemId") then
            exit;

        if DetailedMatchedOrderLine."Receipt on Invoice" then begin
            if DetailedMatchedOrderLine."Qty. to Invoice" > DetailedMatchedOrderLine.Quantity then
                Error(GreaterThanErr, DetailedMatchedOrderLine.FieldCaption("Qty. to Invoice"), DetailedMatchedOrderLine."Qty. to Invoice", DetailedMatchedOrderLine.FieldCaption(Quantity), DetailedMatchedOrderLine.Quantity);
        end else
            if DetailedMatchedOrderLine."Qty. to Invoice" > DetailedMatchedOrderLine."Qty. Rcd. Not Invoiced" then
                Error(GreaterThanErr, DetailedMatchedOrderLine.FieldCaption("Qty. to Invoice"), DetailedMatchedOrderLine."Qty. to Invoice", DetailedMatchedOrderLine.FieldCaption("Qty. Rcd. Not Invoiced"), DetailedMatchedOrderLine."Qty. Rcd. Not Invoiced");

        case MatchedOrderLineSource of
            "Matched Order Line Source"::"Purchase Invoice":
                ValidateQtyToInvoiceForPurchaseInvoice(DetailedMatchedOrderLine);
        end;

        MatchedOrderLine.SetRange("Document Line SystemId", DetailedMatchedOrderLine."Document Line SystemId");
        MatchedOrderLine.SetRange("Matched Order Line SystemId", DetailedMatchedOrderLine."Matched Order Line SystemId");
        if not IsNullGuid(DetailedMatchedOrderLine."Matched Rcpt./Shpt. Line SysId") then
            MatchedOrderLine.SetRange("Matched Rcpt./Shpt. Line SysId", DetailedMatchedOrderLine."Matched Rcpt./Shpt. Line SysId");

        if MatchedOrderLine.FindFirst() then begin
            MatchedOrderLine."Qty. to Invoice" := DetailedMatchedOrderLine."Qty. to Invoice";
            MatchedOrderLine."Qty. to Invoice (Base)" := DetailedMatchedOrderLine."Qty. to Invoice (Base)";
            MatchedOrderLine.Modify();
        end;

        UpdateQtyOnParentLines(DetailedMatchedOrderLine, false, DetailedMatchedOrderLine."Qty. to Invoice" - xDetailedMatchedOrderLine."Qty. to Invoice", DetailedMatchedOrderLine."Qty. to Invoice (Base)" - xDetailedMatchedOrderLine."Qty. to Invoice (Base)");
        UpdateQtyOnParentLines(DetailedMatchedOrderLine, true, DetailedMatchedOrderLine."Qty. to Invoice" - xDetailedMatchedOrderLine."Qty. to Invoice", DetailedMatchedOrderLine."Qty. to Invoice (Base)" - xDetailedMatchedOrderLine."Qty. to Invoice (Base)");
    end;

    internal procedure UpdateQtyOnParentLines(var DetailedMatchedOrderLine: Record "Detailed Matched Order Line"; UpdateInvoiceLine: Boolean; QtyToInvoiceDiff: Decimal; QtyToInvoiceBaseDiff: Decimal)
    var
        TempDetailedMatchedOrderLine: Record "Detailed Matched Order Line" temporary;
    begin
        TempDetailedMatchedOrderLine.Copy(DetailedMatchedOrderLine, true);

        TempDetailedMatchedOrderLine.SetRange("Document Line SystemId", DetailedMatchedOrderLine."Document Line SystemId");
        TempDetailedMatchedOrderLine.SetRange("Matched Rcpt./Shpt. Line SysId", NullGuid);
        if UpdateInvoiceLine then
            TempDetailedMatchedOrderLine.SetRange("Matched Order Line SystemId", NullGuid)
        else
            TempDetailedMatchedOrderLine.SetRange("Matched Order Line SystemId", DetailedMatchedOrderLine."Matched Order Line SystemId");

        if TempDetailedMatchedOrderLine.FindFirst() then begin
            TempDetailedMatchedOrderLine."Qty. to Invoice" += QtyToInvoiceDiff;
            TempDetailedMatchedOrderLine."Qty. to Invoice (Base)" += QtyToInvoiceBaseDiff;
            TempDetailedMatchedOrderLine.Modify();
        end;
    end;

    internal procedure ValidateQtyToInvoiceForPurchaseInvoice(var DetailedMatchedOrderLine: Record "Detailed Matched Order Line")
    var
        PurchaseLineOrder: Record "Purchase Line";
        PurchRcptLine: Record "Purch. Rcpt. Line";
        TempItemLedgEntry: Record "Item Ledger Entry" temporary;
        ItemTrackingDocMgmt: Codeunit "Item Tracking Doc. Management";
        UOMMgt: Codeunit "Unit of Measure Management";
    begin
        if IsNullGuid(DetailedMatchedOrderLine."Matched Order Line SystemId") then
            exit;

        PurchaseLineOrder.GetBySystemId(DetailedMatchedOrderLine."Matched Order Line SystemId");
        DetailedMatchedOrderLine."Qty. to Invoice" := UOMMgt.RoundAndValidateQty(DetailedMatchedOrderLine."Qty. to Invoice", PurchaseLineOrder."Qty. Rounding Precision", DetailedMatchedOrderLine.FieldCaption("Qty. to Invoice"));
        DetailedMatchedOrderLine."Qty. to Invoice (Base)" := PurchaseLineOrder.CalcBaseQty(DetailedMatchedOrderLine."Qty. to Invoice", DetailedMatchedOrderLine.FieldCaption("Qty. to Invoice"), DetailedMatchedOrderLine.FieldCaption("Qty. to Invoice (Base)"));

        if not IsNullGuid(DetailedMatchedOrderLine."Matched Rcpt./Shpt. Line SysId") then begin
            PurchRcptLine.GetBySystemId(DetailedMatchedOrderLine."Matched Rcpt./Shpt. Line SysId");
            ItemTrackingDocMgmt.RetrieveEntriesFromShptRcpt(TempItemLedgEntry, Database::"Purch. Rcpt. Line", 0, PurchRcptLine."Document No.", '', 0, PurchRcptLine."Line No.");
            TempItemLedgEntry.SetFilter("Item Tracking", '<>%1', TempItemLedgEntry."Item Tracking"::None);
            if not TempItemLedgEntry.IsEmpty() then
                Error(ItemTrackingExistsErr, DetailedMatchedOrderLine.FieldCaption("Qty. to Invoice"));
        end;
    end;

    internal procedure GetPurchaseOrderLines(PurchaseLine: Record "Purchase Line")
    var
        PurchaseHeaderInvoice, PurchaseHeaderOrder : Record "Purchase Header";
        PurchaseLineInvoice, PurchaseLineOrder : Record "Purchase Line";
        PurchRcptLine: Record "Purch. Rcpt. Line";
        PurchaseLines: Page "Purchase Lines";
        LineNo: Integer;
        Qty, QtyBase : Decimal;
    begin
        PurchaseHeaderInvoice.Get(PurchaseLine."Document Type", PurchaseLine."Document No.");

        LineNo := 10000;
        PurchaseLineInvoice.Reset();
        PurchaseLineInvoice.SetRange("Document Type", PurchaseHeaderInvoice."Document Type");
        PurchaseLineInvoice.SetRange("Document No.", PurchaseHeaderInvoice."No.");
        if PurchaseLineInvoice.FindLast() then
            LineNo += PurchaseLineInvoice."Line No.";

        PurchaseLineOrder.FilterGroup(-1);
        PurchaseLineOrder.SetFilter("Outstanding Quantity", '<>0');
        PurchaseLineOrder.SetFilter("Qty. Rcd. Not Invoiced", '<>0');
        PurchaseLineOrder.FilterGroup(2);
        PurchaseLineOrder.SetRange("Document Type", PurchaseHeaderInvoice."Document Type"::Order);
        PurchaseLineOrder.SetRange("Buy-from Vendor No.", PurchaseHeaderInvoice."Buy-from Vendor No.");
        PurchaseLineOrder.SetRange("Pay-to Vendor No.", PurchaseHeaderInvoice."Pay-to Vendor No.");
        if PurchaseLineOrder.FindSet() then
            repeat
                PurchaseLineOrder.Mark(true);
            until PurchaseLineOrder.Next() = 0;
        PurchaseLineOrder.MarkedOnly(true);
        PurchaseLineOrder.FilterGroup(0);

        PurchaseLines.SetTableView(PurchaseLineOrder);
        PurchaseLines.LookupMode := true;
        if PurchaseLines.RunModal() = Action::LookupOK then begin
            PurchaseLines.SetSelectionFilter(PurchaseLineOrder);
            if PurchaseLineOrder.FindSet() then
                repeat
                    PurchaseLineInvoice.Init();
                    PurchaseLineInvoice."Document Type" := PurchaseHeaderInvoice."Document Type";
                    PurchaseLineInvoice."Document No." := PurchaseHeaderInvoice."No.";
                    PurchaseLineInvoice."Line No." := LineNo;
                    LineNo += 10000;
                    PurchaseLineInvoice.Validate(Type, PurchaseLineOrder.Type);
                    PurchaseLineInvoice.Validate("No.", PurchaseLineOrder."No.");
                    PurchaseLineInvoice.Validate("Unit of Measure Code", PurchaseLineOrder."Unit of Measure Code");
                    PurchaseLineInvoice.Validate(Description, PurchaseLineOrder.Description);
                    PurchaseLineInvoice."Description 2" := PurchaseLineOrder."Description 2";
                    PurchaseLineInvoice.Validate("Direct Unit Cost", PurchaseLineOrder."Direct Unit Cost");
                    PurchaseLineInvoice.Validate("Location Code", PurchaseLineOrder."Location Code");
                    PurchaseLineInvoice.Insert(true);

                    if PurchaseHeaderOrder."No." <> PurchaseLineOrder."Document No." then
                        PurchaseHeaderOrder.Get(PurchaseLineOrder."Document Type", PurchaseLineOrder."Document No.");

                    if PurchaseLineOrder."Qty. Rcd. Not Invoiced" <> 0 then begin
                        Qty := PurchaseLineOrder."Qty. Rcd. Not Invoiced";
                        QtyBase := PurchaseLineOrder."Qty. Rcd. Not Invoiced (Base)";
                    end else begin
                        Qty := PurchaseLineOrder."Outstanding Quantity";
                        QtyBase := PurchaseLineOrder."Outstanding Qty. (Base)";
                    end;

                    InsertMatchedOrderLine(PurchaseLineInvoice.SystemId, PurchaseLineOrder.SystemId, NullGuid, Qty, QtyBase, PurchaseHeaderOrder."Receipt on Invoice");

                    PurchRcptLine.SetRange("Order No.", PurchaseLineOrder."Document No.");
                    PurchRcptLine.SetRange("Order Line No.", PurchaseLineOrder."Line No.");
                    PurchRcptLine.SetFilter("Qty. Rcd. Not Invoiced", '<>0');
                    if PurchRcptLine.FindSet() then
                        repeat
                            ItemTrackingMgt.CopyMatchedItemTrkgToPurchLine(
                                PurchaseLineOrder,
                                PurchaseLineInvoice,
                                InsertMatchedOrderLine(
                                    PurchaseLineInvoice.SystemId,
                                    PurchaseLineOrder.SystemId,
                                    PurchRcptLine.SystemId,
                                    PurchRcptLine."Qty. Rcd. Not Invoiced",
                                    PurchaseLineOrder.CalcBaseQty(PurchRcptLine."Qty. Rcd. Not Invoiced", PurchaseLineOrder.FieldCaption("Qty. to Invoice"), PurchaseLineOrder.FieldCaption("Qty. to Invoice (Base)")),
                                    false),
                                false);
                        until PurchRcptLine.Next() = 0;

                    // Late update quantity to avoid WMS errors
                    PurchaseLineInvoice.Validate(Quantity, Qty);
                    PurchaseLineInvoice.Modify(true);
                until PurchaseLineOrder.Next() = 0;
        end;
    end;

    internal procedure CheckReceiptOnInvoiceAllowed(PurchaseHeader: Record "Purchase Header")
    var
        Item: Record Item;
        ItemTrackingCode: record "Item Tracking Code";
        Location: Record Location;
        PurchaseLine: Record "Purchase Line";
        PurchRcptLine: Record "Purch. Rcpt. Line";
    begin
        PurchaseLine.SetRange("Document Type", PurchaseHeader."Document Type");
        PurchaseLine.SetRange("Document No.", PurchaseHeader."No.");
        PurchaseLine.SetLoadFields(Type, "No.", "Location Code");
        if PurchaseLine.FindSet() then
            repeat
                if Location.Get(PurchaseLine."Location Code") and Location."Directed Put-away and Pick" then
                    Error(ReceiptOnInvoiceLocationErr, PurchaseHeader.FieldCaption("Receipt on Invoice"), PurchaseLine."Location Code", PurchaseLine."Line No.");
                if PurchaseLine.Type = PurchaseLine.Type::Item then
                    if Item.Get(PurchaseLine."No.") and (Item."Item Tracking Code" <> '') then
                        if ItemTrackingCode.Get(Item."Item Tracking Code") and (ItemTrackingCode."SN Specific Tracking" or ItemTrackingCode."Lot Specific Tracking" or ItemTrackingCode."Package Specific Tracking") then
                            Error(ReceiptOnInvoiceItemTrackingErr, PurchaseHeader.FieldCaption("Receipt on Invoice"), PurchaseLine."No.", PurchaseLine."Line No.");

                PurchRcptLine.SetRange("Order No.", PurchaseLine."Document No.");
                PurchRcptLine.SetRange("Order Line No.", PurchaseLine."Line No.");
                if not PurchRcptLine.IsEmpty() then
                    Error(ReceiptOnInvoicePostedReceiptErr, PurchaseHeader.FieldCaption("Receipt on Invoice"), PurchaseLine."Line No.");
            until PurchaseLine.Next() = 0;
    end;

    internal procedure RefreshMatchedOrderLineReceipt(PurchaseHeader: Record "Purchase Header")
    var
        MatchedOrderLine: Record "Matched Order Line";
        PurchaseLine: Record "Purchase Line";
        PurchaseLineSystemIDFilter: Text;
    begin
        PurchaseLine.SetRange("Document Type", PurchaseHeader."Document Type");
        PurchaseLine.SetRange("Document No.", PurchaseHeader."No.");
        PurchaseLine.SetLoadFields(SystemId);
        if PurchaseLine.FindSet() then
            repeat
                PurchaseLineSystemIDFilter += Format(PurchaseLine.SystemId) + '|';
            until PurchaseLine.Next() = 0;

        if PurchaseLineSystemIDFilter = '' then
            exit;

        PurchaseLineSystemIDFilter := CopyStr(PurchaseLineSystemIDFilter, 1, StrLen(PurchaseLineSystemIDFilter) - 1);
        MatchedOrderLine.SetFilter("Matched Order Line SystemId", PurchaseLineSystemIDFilter);
        MatchedOrderLine.ModifyAll("Receipt on Invoice", PurchaseHeader."Receipt on Invoice");
    end;

    internal procedure CheckReceiptOnInvoiceAllowedForItem(Item: Record Item; PurchHeader: Record "Purchase Header")
    var
        ItemTrackingCode: Record "Item Tracking Code";
    begin
        if PurchHeader."Receipt on Invoice" and (Item."Item Tracking Code" <> '') then
            if ItemTrackingCode.Get(Item."Item Tracking Code") and (ItemTrackingCode."SN Specific Tracking" or ItemTrackingCode."Lot Specific Tracking" or ItemTrackingCode."Package Specific Tracking") then
                Error(ReceiptOnInvoiceItemTrackingLineValidationErr, Item."No.", PurchHeader.FieldCaption("Receipt on Invoice"));
    end;

    internal procedure CheckReceiptOnInvoiceAllowedForLocation("Location Code": Code[10]; PurchHeader: Record "Purchase Header")
    var
        Location: Record Location;
    begin
        if PurchHeader."Receipt on Invoice" then
            if Location.Get("Location Code") and Location."Directed Put-away and Pick" then
                Error(ReceiptOnInvoiceLocationLineValidationErr, "Location Code", PurchHeader.FieldCaption("Receipt on Invoice"));
    end;

    internal procedure LineCanBeDeleted(var DetailedMatchedOrderLine: Record "Detailed Matched Order Line"; SourceIsOpenDocument: Boolean): Boolean
    var
        PurchaseLine: Record "Purchase Line";
        Location: Record Location;
        TempDetailedMatchedOrderLine: Record "Detailed Matched Order Line" temporary;
    begin
        if not SourceIsOpenDocument then begin
            Message(DeletePostedLinesErr);
            exit(false);
        end;

        TempDetailedMatchedOrderLine.Copy(DetailedMatchedOrderLine, true);
        TempDetailedMatchedOrderLine.Reset();
        TempDetailedMatchedOrderLine.SetRange("Document Line SystemId", DetailedMatchedOrderLine."Document Line SystemId");
        TempDetailedMatchedOrderLine.SetFilter("Matched Order Line SystemId", '<>%1', NullGuid);
        if TempDetailedMatchedOrderLine.Count() <= 1 then
            if PurchaseLine.GetBySystemId(DetailedMatchedOrderLine."Document Line SystemId") and (PurchaseLine."Location Code" <> '') then
                if Location.Get(PurchaseLine."Location Code") and Location."Directed Put-away and Pick" then begin
                    Message(LocationRequiresReceiveErr, PurchaseLine."Location Code");
                    exit(false);
                end;

        exit(true);
    end;

    internal procedure ShowMatchedInvoiceLines(PurchaseLineOrder: Record "Purchase Line")
    var
        MatchedOrderLine: Record "Matched Order Line";
        PurchaseLine: Record "Purchase Line";
        PurchInvSystemIDFilter: Text;
    begin
        MatchedOrderLine.SetRange("Matched Order Line SystemId", PurchaseLineOrder.SystemId);
        MatchedOrderLine.SetFilter("Matched Rcpt./Shpt. Line SysId", NullGuid);
        if MatchedOrderLine.FindSet() then
            repeat
                PurchInvSystemIDFilter += Format(MatchedOrderLine."Document Line SystemId") + '|';
            until MatchedOrderLine.Next() = 0;

        if PurchInvSystemIDFilter <> '' then
            PurchInvSystemIDFilter := CopyStr(PurchInvSystemIDFilter, 1, StrLen(PurchInvSystemIDFilter) - 1)
        else
            PurchInvSystemIDFilter := NullGuid;

        PurchaseLine.SetFilter(SystemId, PurchInvSystemIDFilter);
        Page.RunModal(0, PurchaseLine);
    end;

    local procedure InsertMatchedOrderLine(DocumentLineSystemId: Guid; MatchedOrderLineSystemId: Guid; MatchedRcptShptLineSystemId: Guid; QtyToInvoice: Decimal; QtyToInvoiceBase: Decimal; ReceiptOnInvoice: Boolean) MatchedOrderLine: Record "Matched Order Line"
    begin
        // Get with 3 guids in PK does not work
        MatchedOrderLine.SetRange("Document Line SystemId", DocumentLineSystemId);
        MatchedOrderLine.SetRange("Matched Order Line SystemId", MatchedOrderLineSystemId);
        MatchedOrderLine.SetRange("Matched Rcpt./Shpt. Line SysId", MatchedRcptShptLineSystemId);
        if MatchedOrderLine.FindFirst() then
            exit;

        MatchedOrderLine."Document Line SystemId" := DocumentLineSystemId;
        MatchedOrderLine."Matched Order Line SystemId" := MatchedOrderLineSystemId;
        MatchedOrderLine."Matched Rcpt./Shpt. Line SysId" := MatchedRcptShptLineSystemId;
        MatchedOrderLine."Qty. to Invoice" := QtyToInvoice;
        MatchedOrderLine."Qty. to Invoice (Base)" := QtyToInvoiceBase;
        MatchedOrderLine."Receipt on Invoice" := ReceiptOnInvoice;
        MatchedOrderLine.Insert();
    end;

    var
        ItemTrackingMgt: Codeunit "Item Tracking Management";
        InvoiceMoreThanReceivedErr: Label 'You cannot invoice order %1 for more than you have received.', Comment = '%1 = Order No.';
        ItemTrackingExistsErr: Label 'You cannot change %1 for this line because item tracking exists.', Comment = ' %1 = Qty. To Invoice field name';
        QtySumMismatchErr: Label 'The quantity on the invoice line does not match the total quantity to invoice for the matched receipt lines. Line No.: %1', Comment = ' %1 = Line No.';
        QtyToInvoiceExceedsQtyReceivedNotInvoicedErr: Label 'Cannot post the line %1 because the quantity to invoice for a matched receipt line exceeds the quantity received not invoiced for that receipt line. Receipt No.: %2, Line No.: %3', Comment = '%1 = Line No.,  %2 = Receipt No., %3 = Receipt Line No.';
        ItemChargeNotSupportedErr: Label 'Matched order lines are not supported for item charge lines. Order No.: %1, Line No.: %2', Comment = '%1 = Order No., %2 = Line No.';
        PrepaymentNotSupportedErr: Label 'Matched order lines are not supported for prepayment lines. Order No.: %1, Line No.: %2', Comment = '%1 = Order No., %2 = Line No.';
        PurchaseInvoiceLineMatchedErr: Label 'The line is matched to an order line and cannot be modified.';
        PurchaseOrderLineMatchedErr: Label 'The line is matched to an invoice line and cannot be modified.';
        InvoiceLineLbl: Label 'Invoice %1 Line %2', Comment = '%1 = Document No., %2 = Line No.';
        OrderLineLbl: Label 'Order %1 Line %2', Comment = '%1 = Document No., %2 = Line No.';
        RcptLineLbl: Label 'Receipt %1 Line %2', Comment = '%1 = Document No., %2 = Line No.';
        GreaterThanErr: Label 'The %1 (%2) cannot be greater than the %3 (%4).', Comment = ' %1 = Qty. To Invoice field name, %2 = Qty. To Invoice value, %3 = Qty. Rcd. Not Invoiced field name, %4 = Qty. Rcd. Not Invoiced value';
        MustBeMatchedToReceiptErr: Label 'Line No. %1 must be matched to at least one receipt or shipment line.', Comment = ' %1 = Line No.';
        ReceiptOnInvoiceLocationErr: Label 'You cannot use %1 Directed Put-away and Pick Location %2 on Line %3.', Comment = '%1 = Receipt on Invoice field name, %2 = Location Code, %3 = Line No.';
        ReceiptOnInvoiceItemTrackingErr: Label 'You cannot use %1 because Item %2 on Line %3 requires item tracking.', Comment = '%1 = Receipt on Invoice field name, %2 = Item No., %3 = Line No.';
        ReceiptOnInvoiceLocationLineValidationErr: Label 'You cannot use Directed Put-away and Pick location %1 on purchase orders with %2 enabled.', Comment = '%1 = Location Code, %2 = Receipt on Invoice field name';
        ReceiptOnInvoiceItemTrackingLineValidationErr: Label 'You cannot use item %1 with specific tracking on purchase orders with %2 enabled.', Comment = '%1 = Item No., %2 = Receipt on Invoice field name';
        ReceiptOnInvoicePostedReceiptErr: Label 'You cannot use %1 because Line %2 already has posted receipts.', Comment = '%1 = Receipt on Invoice field name, %2 = Line No.';
        ReceiptOnInvoicePostFromMatchedInvoiceErr: Label 'Purchase Order with %1 selected can only be posted from matched purchase invoice', Comment = '%1 = Receipt on Invoice field name';
        DeletePostedLinesErr: Label 'You cannot delete posted document lines.';
        LocationRequiresReceiveErr: Label 'You cannot delete the last matched order line because %1 location requires Directed Put-away and Pick. Please delete the document line.', Comment = '%1 - Location Code';
        NullGuid: Guid;
}