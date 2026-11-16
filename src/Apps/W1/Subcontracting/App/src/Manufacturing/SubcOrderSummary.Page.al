// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Manufacturing.Subcontracting;

using Microsoft.Manufacturing.Document;

page 20580 "Subc. Order Summary"
{
    PageType = CardPart;
    SourceTable = "Production Order";
    Caption = 'Subcontracting Summary';
    ApplicationArea = Subcontracting;
    Editable = false;
    InsertAllowed = false;
    ModifyAllowed = false;
    DeleteAllowed = false;
    RefreshOnActivate = true;

    layout
    {
        area(Content)
        {
            field(RoutingCount; RoutingCount)
            {
                Caption = 'Subcontracting Routing Lines';
                ToolTip = 'Specifies the number of routing lines across this production order whose current work center has a subcontractor. View the matching routing lines.';
                DrillDown = true;
                trigger OnDrillDown()
                begin
                    SummaryMgmt.ShowRouting(Rec);
                end;
            }
            field(PurchaseQuantity; PurchaseQuantity)
            {
                AutoFormatType = 0;
                Caption = 'Purch. Order Qty.';
                DecimalPlaces = 0 : 5;
                ToolTip = 'Specifies the raw sum of Quantity on linked purchase Order lines across all items, operations and document units of measure, including retained fully invoiced lines. This is not remaining quantity or unique finished output. View the matching lines.';
                DrillDown = true;
                trigger OnDrillDown()
                begin
                    SummaryMgmt.ShowPurchase(Rec);
                end;
            }
            field(ReceiptQuantity; ReceiptQuantity)
            {
                AutoFormatType = 0;
                Caption = 'Quantity Received';
                DecimalPlaces = 0 : 5;
                ToolTip = 'Specifies the raw signed sum of Quantity on linked posted purchase receipt lines, including negative corrections, across all items, operations and document units of measure. This is not unique finished output. View the matching receipt lines.';
                DrillDown = true;
                trigger OnDrillDown()
                begin
                    SummaryMgmt.ShowReceipts(Rec);
                end;
            }
            field(InvoiceQuantity; InvoiceQuantity)
            {
                AutoFormatType = 0;
                Caption = 'Quantity Invoiced';
                DecimalPlaces = 0 : 5;
                ToolTip = 'Specifies the raw signed sum of Quantity on linked posted purchase invoice lines across all items, operations and document units of measure, including signed corrections in that table. Credit memo and return sources are excluded. View the matching invoice lines.';
                DrillDown = true;
                trigger OnDrillDown()
                begin
                    SummaryMgmt.ShowInvoices(Rec);
                end;
            }
            field(FullyInvoiced; Format(FullyInvoiced))
            {
                Caption = 'Fully Invoiced';
                StyleExpr = InvoiceStyle;
                ToolTip = 'Specifies whether exact aggregate receipt and invoice quantities are equal and no linked purchase Order line has Quantity different from Quantity Invoiced. Empty totals qualify. Signed receipt and invoice corrections count; credit memo and return sources do not. This global quantity proxy does not prove per-receipt reconciliation, financial completeness or cost application.';
            }
            field(WIPAtSubcontractor; WIPAtSubcontractor)
            {
                AutoFormatType = 0;
                Caption = 'WIP Qty. (Base) at Subc.';
                DecimalPlaces = 0 : 5;
                ToolTip = 'Specifies the signed sum of non-transit WIP ledger Quantity (Base) for this production status and order. Each item contributes its own base units without conversion to a common unit or finished output. Current vendor or location setup does not restrict historical balances. View the matching entries.';
                DrillDown = true;
                trigger OnDrillDown()
                begin
                    SummaryMgmt.ShowWIP(Rec, false);
                end;
            }
            field(WIPInTransit; WIPInTransit)
            {
                AutoFormatType = 0;
                Caption = 'WIP Qty. (Base) in Transit';
                DecimalPlaces = 0 : 5;
                ToolTip = 'Specifies the signed sum of in-transit WIP ledger Quantity (Base) for this production status and order, including outbound and return transit. Each item contributes its own base units, not a common finished-output unit. View the matching entries.';
                DrillDown = true;
                trigger OnDrillDown()
                begin
                    SummaryMgmt.ShowWIP(Rec, true);
                end;
            }
            field(TransferCount; TransferCount)
            {
                Caption = 'Transfer Order Lines';
                ToolTip = 'Specifies the number of original forward transfer lines linked to this order, excluding derived lines. Multiple lines on one transfer order are counted separately. View exactly those lines.';
                DrillDown = true;
                trigger OnDrillDown()
                begin
                    SummaryMgmt.ShowTransfers(Rec, false);
                end;
            }
            field(ReturnTransferCount; ReturnTransferCount)
            {
                Caption = 'Return Transfer Order Lines';
                ToolTip = 'Specifies the number of original return transfer lines linked to this order, excluding derived lines. Multiple lines on one return transfer order are counted separately. View exactly those lines.';
                DrillDown = true;
                trigger OnDrillDown()
                begin
                    SummaryMgmt.ShowTransfers(Rec, true);
                end;
            }
        }
    }

    trigger OnAfterGetCurrRecord()
    begin
        RefreshSummary();
    end;

    local procedure RefreshSummary()
    var
        HasOpenLine: Boolean;
    begin
        RoutingCount := SummaryMgmt.GetRoutingCount(Rec);
        PurchaseQuantity := SummaryMgmt.GetPurchaseQuantity(Rec, HasOpenLine);
        ReceiptQuantity := SummaryMgmt.GetReceiptQuantity(Rec);
        InvoiceQuantity := SummaryMgmt.GetInvoiceQuantity(Rec);
        FullyInvoiced := SummaryMgmt.CanRead(Rec) and (ReceiptQuantity = InvoiceQuantity) and not HasOpenLine;
        WIPAtSubcontractor := SummaryMgmt.GetWIPQuantity(Rec, false);
        WIPInTransit := SummaryMgmt.GetWIPQuantity(Rec, true);
        TransferCount := SummaryMgmt.GetTransferCount(Rec, false);
        ReturnTransferCount := SummaryMgmt.GetTransferCount(Rec, true);
        if FullyInvoiced then
            InvoiceStyle := 'Favorable'
        else
            InvoiceStyle := 'Unfavorable';
    end;

    var
        SummaryMgmt: Codeunit "Subc. Order Summary Mgmt.";
        RoutingCount: Integer;
        PurchaseQuantity: Decimal;
        ReceiptQuantity: Decimal;
        InvoiceQuantity: Decimal;
        FullyInvoiced: Boolean;
        WIPAtSubcontractor: Decimal;
        WIPInTransit: Decimal;
        TransferCount: Integer;
        ReturnTransferCount: Integer;
        InvoiceStyle: Text;
}
