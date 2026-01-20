// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Manufacturing.Subcontracting;

using Microsoft.Manufacturing.Document;

page 99001502 "Subc. Routing Info Factbox"
{
    ApplicationArea = Manufacturing;
    Caption = 'Subcontracting Routing Details';
    Editable = false;
    PageType = CardPart;
    SourceTable = "Prod. Order Routing Line";
    layout
    {
        area(Content)
        {
            field(ShowSubcontractor; SubcontractingFactboxMgmt.GetSubcontractorNo(Rec))
            {
                Caption = 'Subcontractor';
                ToolTip = 'Specifies the assigned Subcontractor No. of this Prod. Order Routing Line.';
                trigger OnDrillDown()
                begin
                    ShowSubcontractorFromRouting();
                end;
            }
            field(ShowQtyInSubcontractingOrder; SubcontractingFactboxMgmt.GetPurchOrderQtyFromRoutingLine(Rec))
            {
                AutoFormatType = 0;
                Caption = 'Order Quantity';
                DecimalPlaces = 0 : 5;
                ToolTip = 'Specifies the depended Quantity in Subcontracting Orders of this Prod. Order Routing Line.';
                trigger OnDrillDown()
                begin
                    ShowPurchaseOrders();
                end;
            }
            field(ShowQtyShippedRequest; SubcontractingFactboxMgmt.GetPurchReceiptQtyFromRoutingLine(Rec))
            {
                AutoFormatType = 0;
                Caption = 'Quantity received';
                DecimalPlaces = 0 : 5;
                ToolTip = 'Specifies the depended Quantity received in Subcontracting Receipts of this Prod. Order Routing Line.';
                trigger OnDrillDown()
                begin
                    ShowPurchaseReceipts();
                end;
            }
            field(ShowQtyInvoicedRequest; SubcontractingFactboxMgmt.GetPurchInvoicedQtyFromRoutingLine(Rec))
            {
                AutoFormatType = 0;
                Caption = 'Quantity invoiced';
                DecimalPlaces = 0 : 5;
                ToolTip = 'Specifies the depended Quantity invoiced in Subcontracting Invoices of this Prod. Order Routing Line.';
                trigger OnDrillDown()
                begin
                    ShowPurchaseInvoices();
                end;
            }
            field(ShowNoOfTransferOrdersFromProdOrderComp; SubcontractingFactboxMgmt.GetNoOfTransferLinesFromRouting(Rec))
            {
                AutoFormatType = 0;
                Caption = 'Transfer Order Lines';
                DecimalPlaces = 0 : 5;
                ToolTip = 'Specifies the number of transfer order lines assigned to this routing line.';
                trigger OnDrillDown()
                var
                begin
                    SubcontractingFactboxMgmt.ShowTransferOrdersAndReturnOrder(Rec, true, false);
                end;
            }
            field(ShowNoOfReturnTransferOrdersFromProdOrderComp; SubcontractingFactboxMgmt.GetNoOfReturnTransferLinesFromRouting(Rec))
            {
                AutoFormatType = 0;
                Caption = 'Return Transfer Order Lines';
                DecimalPlaces = 0 : 5;
                ToolTip = 'Specifies the number of Return transfer order lines assigned to this routing line.';
                trigger OnDrillDown()
                var
                begin
                    SubcontractingFactboxMgmt.ShowTransferOrdersAndReturnOrder(Rec, true, true);
                end;
            }
            field(ShowNoOfLinkedComp; SubcontractingFactboxMgmt.GetNoOfLinkedComponentsFromRouting(Rec))
            {
                AutoFormatType = 0;
                Caption = 'Components';
                DecimalPlaces = 0 : 5;
                ToolTip = 'Specifies the number of components linked to this routing line.';
                trigger OnDrillDown()
                var
                begin
                    ShowProdOrderComponents();
                end;
            }
        }
    }
    local procedure ShowSubcontractorFromRouting()
    begin
        SubcontractingFactboxMgmt.ShowSubcontractor(Rec);
    end;

    local procedure ShowPurchaseOrders()
    begin
        SubcontractingFactboxMgmt.ShowPurchaseOrderLinesFromRouting(Rec);
    end;

    local procedure ShowPurchaseReceipts()
    begin
        SubcontractingFactboxMgmt.ShowPurchaseReceiptLinesFromRouting(Rec);
    end;

    local procedure ShowPurchaseInvoices()
    begin
        SubcontractingFactboxMgmt.ShowPurchaseInvoiceLinesFromRouting(Rec);
    end;

    local procedure ShowProdOrderComponents()
    begin
        SubcontractingFactboxMgmt.ShowProdOrderComponents(Rec);
    end;

    var
        SubcontractingFactboxMgmt: Codeunit "Subc. Factbox Mgmt.";
}