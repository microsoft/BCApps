// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.eServices.EDocument.Processing.Import.Purchase;

using Microsoft.Purchases.Document;

page 6116 "Candidate Order Lines for Inv."
{
    ApplicationArea = All;
    Caption = 'Available Purchase Order Lines';
    PageType = Worksheet;
    SourceTable = "Purchase Line";
    Editable = false;
    InsertAllowed = false;
    DeleteAllowed = false;
    SourceTableView = where("Document Type" = const("Purchase Document Type"::Order));

    layout
    {
        area(Content)
        {
            group(LineInInvoice)
            {
                Caption = 'Received invoice line';
                field(EDocumentPurchaseLineDescription; EDocumentPurchaseLine.Description)
                {
                    ApplicationArea = All;
                    Caption = 'Description';
                    ToolTip = 'Specifies the description of the e-document line.';
                }
                field(EDocumentPurchaseLineQuantity; EDocumentPurchaseLine.Quantity)
                {
                    ApplicationArea = All;
                    Caption = 'Quantity';
                    ToolTip = 'Specifies the quantity of the e-document line.';
                }

            }
            group(CurrentlyMatchedLine)
            {
                Caption = 'Currently matched order line';
                Visible = InvoiceLineMatched;
                field(OrderNo; MatchedOrderLine."Document No.")
                {
                    ApplicationArea = All;
                    Caption = 'Order No.';
                    ToolTip = 'Specifies the document number of the purchase order.';

                    trigger OnDrillDown()
                    var
                        PurchaseHeader: Record "Purchase Header";
                    begin
                        if not PurchaseHeader.Get("Purchase Document Type"::Order, MatchedOrderLine."No.") then
                            exit;
                        Page.Run(Page::"Purchase Order", PurchaseHeader);
                    end;
                }
                field(OrderLineDescription; MatchedOrderLine.Description)
                {
                    ApplicationArea = All;
                    Caption = 'Description';
                    ToolTip = 'Specifies the description of the purchase line.';
                }
                field(OrderLineQuantityToReceive; MatchedOrderLine."Qty. to Receive")
                {
                    ApplicationArea = All;
                    Caption = 'Quantity Received';
                    ToolTip = 'Specifies the quantity that is remaining to be received.';
                }
                field(OrderLineQuantityToInvoice; MatchedOrderLine."Quantity Invoiced")
                {
                    ApplicationArea = All;
                    Caption = 'Quantity Invoiced';
                    ToolTip = 'Specifies the quantity that is remaining to be invoiced.';
                }
            }
            repeater(Lines)
            {
                Caption = 'Existing order lines';
                field("Document No."; Rec."Document No.")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the document number of the purchase order.';
                    StyleExpr = StyleExpr;
                    LookupPageId = "Purchase Order List";
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the description of the purchase line.';
                    StyleExpr = StyleExpr;
                }
                field("Quantity Received"; Rec."Quantity Received")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the quantity that has already been received.';
                }
                field("Quantity to Receive"; Rec."Qty. to Receive")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the quantity to receive.';
                }
                field("Quantity Invoiced"; Rec."Quantity Invoiced")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the quantity that has already been invoiced.';
                }
                field("Quantity to Invoice"; Rec."Qty. to Invoice")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the quantity to invoice.';
                }
            }
        }
    }
    actions
    {
        area(Navigation)
        {
            action(OpenOrder)
            {
                ApplicationArea = All;
                Caption = 'Open Order';
                ToolTip = 'Opens the purchase order that is currently matched to the invoice line.';
                Image = ViewOrder;
                Scope = Repeater;

                trigger OnAction()
                var
                    PurchaseHeader: Record "Purchase Header";
                begin
                    if not PurchaseHeader.Get("Purchase Document Type"::Order, Rec."Document No.") then
                        exit;
                    Page.Run(Page::"Purchase Order", PurchaseHeader);
                end;
            }
        }
    }

    var
        EDocumentPurchaseLine: Record "E-Document Purchase Line";
        MatchedOrderLine: Record "Purchase Line";
        InvoiceLineMatched: Boolean;
        StyleExpr: Text;
        NoOrderLinesMsg: Label 'No purchase order lines available for matching.';

    trigger OnOpenPage()
    var
        LocalEDocumentPurchaseLine: Record "E-Document Purchase Line";
    begin
        InvoiceLineMatched := not IsNullGuid(MatchedOrderLine.SystemId);
        if Rec.FindSet() then
            repeat
                LocalEDocumentPurchaseLine.SetRange("[BC] Order Line SystemId", Rec.SystemId);
                if not LocalEDocumentPurchaseLine.FindFirst() then
                    Rec.Mark(true);
                if EDocumentPurchaseLine.SystemId = LocalEDocumentPurchaseLine.SystemId then
                    Rec.Mark(true);
            until Rec.Next() = 0;
        Rec.MarkedOnly(true);
        if Rec.IsEmpty() then
            Message(NoOrderLinesMsg);
    end;

    trigger OnAfterGetRecord()
    begin
        Clear(StyleExpr);
        if EDocumentPurchaseLine."[BC] Order Line SystemId" = Rec.SystemId then
            StyleExpr := 'Strong';
    end;

    internal procedure SetEDocumentPurchaseLine(EDocumentPurchaseLineToMatch: Record "E-Document Purchase Line")
    var
        EDocumentPurchaseHeader: Record "E-Document Purchase Header";
    begin
        EDocumentPurchaseHeader.Get(EDocumentPurchaseLineToMatch."E-Document Entry No.");
        Rec.SetRange("Pay-to Vendor No.", EDocumentPurchaseHeader."[BC] Vendor No.");
        EDocumentPurchaseLine := EDocumentPurchaseLineToMatch;
        if MatchedOrderLine.GetBySystemId(EDocumentPurchaseLine."[BC] Order Line SystemId") then;
    end;

}